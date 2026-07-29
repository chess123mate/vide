local graph = require "./graph"
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local destroy = graph.destroy
local get_scope = graph.get_scope

local function branch<T>(fn: () -> T): (() -> (), T)
    local current = get_scope() or error(`cannot use branch() outside a stable or reactive scope`, 2)
    local parent = current.owner or error(`current scope is not owned by a scope`, 2)

    local node = create_node(parent, false, false)

    local destroy = function()
        destroy(node)
    end

    push_scope(node)

    local function handleResults(ok, result, ...)
        pop_scope()

        if not ok then
            destroy()
            error(`error while running branch():\n\n{result}`, 3)
        end

        return destroy, result, ...
    end

    return handleResults(xpcall(fn, debug.traceback))
end

return branch
