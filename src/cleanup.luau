local graph = require "./graph"
local get_scope = graph.get_scope
local push_cleanup = graph.push_cleanup

local function cleanup(value: unknown)
    local scope = get_scope() or error("cannot call cleanup() outside a scope", 2)

    local type_ = typeof(value)
    push_cleanup(scope,
        if type_ == "function" then value
        elseif type_ == "RBXScriptConnection" then function() value:Disconnect() end
        elseif type_ == "thread" then function() task.cancel(value) end
        elseif type_ == "Instance" then function() value:Destroy() end
        elseif value.Disconnect then function() value:Disconnect() end
        elseif value.Destroy then function() value:Destroy() end
        elseif value.destroy then function() value:destroy() end
        elseif value.disconnect then function() value:disconnect() end
        else error("cannot cleanup given object", 2))
end

type Destroyable = { destroy: (any) -> () } | { Destroy: (any) -> () }
type Disconnectable = { disconnect: (any) -> () } | { Disconnect: (any) -> () }

return cleanup ::
    ( (callback: () -> ()) -> () ) &
    ( (thread: thread) -> () ) &
    ( (instance: Destroyable) -> () ) &
    ( (connection: Disconnectable) -> () ) &
    ( (instance: Instance) -> () ) &
    ( (connection: RBXScriptConnection) -> () )

