local flags = require "./flags"
local implicit_effect = require "./implicit_effect"
local _, is_action = require "./action"()
local graph = require "./graph"
local register_destroy = graph.register_destroy
local get_scope = graph.get_scope
local push_cleanup = graph.push_cleanup
type Node<T> = graph.Node<T>

type Array<V> = { V }
type ArrayOrV<V> = {ArrayOrV<V>} | V
type Map<K, V> = { [K]: V }

type Cache = {
    -- event listeners to connect after properties are set
    events: Array<
        | string -- 1. event name
        | () -> () -- 2. listener
    >,

    -- actions to run after events are connected
    actions: Map<
        number, -- priority
        Array<(Instance) -> ()> -- action callbacks
    >,

    -- what to parent the instance to after running actions
    parent: unknown,

    -- cache to detect duplicate property setting at same nesting depth
    nested_debug: Map<
        number, -- depth
        Map<string, true> -- set of property names
    >,

    -- each nested layer occupies two indexes: 1. table ref 2. nested depth
    -- e.g. { t1 = { t3 = {} }, t2 = {} } -> { t1, 1, t2, 1, t3, 2 }
    nested_stack: { {} | number }
}

local free_cache: Cache?
local cache_lazy_init_mt = {
    __index = function(self, i)
        local t = {}
        self[i] = t
        return t
    end
}
local function borrow_cache(): Cache
    if free_cache then
        local cache = free_cache
        free_cache = nil
        return cache
    else
        return {
            events = {},
            actions = setmetatable({} :: any, cache_lazy_init_mt),
            parent = nil,
            nested_debug = flags.strict and setmetatable({} :: any, cache_lazy_init_mt),
            nested_stack = {}
        }
    end
end

local function process_properties(properties: Map<unknown, unknown>, instance: Instance, cache: Cache, depth: number)
    local strict = flags.strict
    for property, value in properties do
        if type(property) == "string" then
            if strict then -- check for duplicate property assignment at nesting depth
                local nested_debug = cache.nested_debug
                if not nested_debug then
                    -- This can happen if we switched from non-strict to strict mode (typically in testing)
                    nested_debug = setmetatable({} :: any, cache_lazy_init_mt)
                    cache.nested_debug = nested_debug
                end
                if nested_debug[depth][property] then
                    error(`duplicate property {property} at depth {depth}`, 0)
                end
                nested_debug[depth][property] = true
            end

            if property == "Parent" then
                cache.parent = value
                continue
            end

            if type(value) == "function" then
                if typeof((instance :: any)[property]) == "RBXScriptSignal" then
                    table.insert(cache.events, property) -- add event name to buffer
                    table.insert(cache.events, value :: () -> ()) -- add event listener to buffer
                else
                    implicit_effect.property(instance, property, value :: () -> ()) -- create implicit effect for property
                end
            else
                (instance :: any)[property] = value -- set property
            end
        elseif type(property) == "number" then
            if type(value) == "function" then
                implicit_effect.children(instance, value :: () -> ArrayOrV<Instance>) -- bind children
            elseif type(value) == "table" then
                if is_action(value) then
                    table.insert(cache.actions[(value :: any).priority], (value :: any).callback :: () -> ()) -- add action to buffer
                elseif flags.defer_nested_properties then
                    table.insert(cache.nested_stack, value :: {})
                    table.insert(cache.nested_stack, depth + 1) -- push table to stack for later processing
                else
                    process_properties(value :: Map<unknown, unknown>, instance, cache, depth + 1)
                end
            elseif type(value) == "userdata" then
                (value :: Instance).Parent = instance -- parent child
            end
        else
            error(`Invalid property '{tostring(property)}'`, 0)
        end
    end
end

-- applies table of nested properties to an instance using full vide semantics
local function apply<T>(instance: T & Instance, properties: {}?, children: { unknown }?, destroy: boolean): T
    if not instance then
        error("attempt to call apply with no instance", 2)
    end
    if not properties then
        if not children then
            error("attempt to call apply with no properties and no children", 2)
        end
        properties = children :: { [unknown]: unknown }
    elseif children then
        table.insert(properties :: any, children)
    end
    local scope = get_scope()

    local cache = borrow_cache()
    local events = cache.events
    local actions = cache.actions
    local nested_stack = cache.nested_stack

    -- process all properties
    local depth = 1
    repeat
        process_properties(properties :: any, instance, cache, depth)
        depth = table.remove(nested_stack) :: number
        properties = table.remove(nested_stack) :: {}
    until not properties

    local num_events = #events
    local cons = num_events > 0 and table.create(num_events / 2)
    for i = 1, num_events, 2 do
        local event_name = events[i]
        local event_listener = events[i + 1]
        table.insert(cons, (instance :: any)[event_name]:Connect(event_listener))
    end
    table.clear(events)

    for _, queued in actions do
        for _, callback in queued do
            callback(instance)
        end
    end
    table.clear(actions)

    local parent = cache.parent
    if parent then
        if type(parent) == "function" then
            implicit_effect.parent(instance, parent :: () -> Instance)
        else
            (instance :: Instance).Parent = parent :: Instance
        end
    end

    local clean = if destroy
        then function() instance:Destroy() end
        else function()
            if cons then
                for _, con in cons do
                    con:Disconnect()
                end
            end
            if parent then
                instance.Parent = nil
            end
        end
    if scope then
        push_cleanup(scope, clean)
    elseif cons then
        clean()
        error("create/apply with arguments requiring cleanup, but called without a scope", 2)
    end

    cache.parent = nil
    if flags.strict then
        local nested_debug = cache.nested_debug
        if nested_debug then
            table.clear(nested_debug)
        end
    end
    table.clear(nested_stack)

    free_cache = cache -- return cache

    return instance
end

return apply
