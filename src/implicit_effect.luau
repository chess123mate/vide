local graph = require "./graph"
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node
local push_cleanup = graph.push_cleanup
local register_destroy = graph.register_destroy

local implicit_effect_child
local function implicit_effect_property(instance, property, source: () -> unknown)
    local scope = get_scope() or error("cannot have implicit effects without a scope", 0)
    local node = create_node(scope, function()
        instance[property] = source()
    end)
    evaluate_node(node)
    return node
end

-- todo: investigate if "count" method used in indexes() and values() can improve performance here
local function update_children_effect(p: {
    instance: Instance,
    cur_children_set: { [Instance]: true },
    new_children_set: { [Instance]: true },
    source: () -> Instance | { Instance }
})
    local instance = p.instance
    local cur_children_set: { [Instance]: true } = p.cur_children_set -- cache of all children parented before update
    local new_children_set: { [Instance]: true } = p.new_children_set -- cache of all children parented after update

    local new_children = p.source() -- all (and only) children that should be parented after this update
    local cons

    local function process_child(child: Instance | { Instance })
        local type_ = type(child)
        if type_ == "userdata" then
            if new_children_set[child] then return end -- stops redundant reparenting

            new_children_set[child] = true -- record child set from this update

            if not cur_children_set[child] then
                child.Parent = instance -- if child wasn't already parented then parent it
            else
                cur_children_set[child] = nil -- remove child from cache if it was already in cache
            end
        elseif type_ == "table" then
            for property, value in child do
                if type(property) == "number" then
                    process_child(value)
                    continue
                end
                -- Copied the following from process_properties
                if type(value) == "function" then
                    if typeof((instance :: any)[property]) == "RBXScriptSignal" then
                        cons = cons or {}
                        table.insert(cons, instance[property]:Connect(value))
                    else
                        implicit_effect_property(instance, property, value :: () -> ()) -- create implicit effect for property
                    end
                else
                    (instance :: any)[property] = value -- set property
                end
            end
        elseif type_ == "function" then
            implicit_effect_child(instance, child)
        end
    end

    process_child(new_children)
    for child in cur_children_set do
        child.Parent = nil -- unparent all children that weren't in the new children set
    end
    table.clear(cur_children_set) -- clear cache, preserve capacity
    p.cur_children_set, p.new_children_set = new_children_set, cur_children_set

    if cons then
        local scope = get_scope() or error("cannot have implicit effects without a scope", 0)
        push_cleanup(scope, function()
            for _, con in cons do
                con:Disconnect()
            end
        end)
    end

    return p
end

implicit_effect_child = function(instance, children)
    -- Note: children now supports key-value pairs (for further modifying instance), though these changes are not reverted if the key-value pair disappears
    local scope = get_scope() or error("cannot have implicit effects without a scope", 0)
    local node = create_node(scope, update_children_effect, {
        instance = instance,
        cur_children_set = {},
        new_children_set = {},
        source = children
    })
    evaluate_node(node)
    register_destroy(node, function()
        for child in node.cache.cur_children_set do
            child.Parent = nil
        end
    end)
    return node
end

return {
    property = implicit_effect_property,

    parent = function(instance, parent)
        local scope = get_scope() or error("cannot have implicit effects without a scope", 0)
        local node = create_node(scope, function()
            instance.Parent = parent()
        end)
        evaluate_node(node)
        return node
    end,

    children = implicit_effect_child,
}
