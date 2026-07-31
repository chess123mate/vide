local flags = require "./flags"
local graph = require "./graph"
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local destroy = graph.destroy

local refs = {}

local function root<T...>(fn: (destroy: () -> ()) -> T..., ...): (() -> (), T...)
    local node = create_node(false, false, false)

    refs[node] = true -- prevent gc of root node
    local destroy = function()
        if not refs[node] then
            if flags.warn_on_repeated_root_destroy then
                warn("root already destroyed", debug.traceback())
            end
            return
        end
        refs[node] = nil
        destroy(node)
    end

    push_scope(node)

    local function handleResults(ok, result, ...)
        pop_scope()
        if not ok then
            destroy()
            error(`error while running root():\n\n{result}`, 3)
        end
        return destroy, result, ...
    end
    return handleResults(xpcall(fn, debug.traceback, destroy, ...))
end

return root :: <T...>(fn: (destroy: () -> ()) -> T...) -> (() -> (), T...)
