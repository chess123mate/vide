local graph = require "./graph"
local create_node = graph.create_node
local push_scope_as_child_of = graph.push_scope_as_child_of
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node

local function derive<T>(source: () -> T): () -> T
    local scope = get_scope() or error("Must be called in a scope", 2)

    local effect = scope.effect
    scope.effect = false

    local node = create_node(scope, source, false :: any)
    local ok, result = xpcall(evaluate_node, debug.traceback, node)

    scope.effect = effect

    if not ok then error(result, 2) end

    return function()
        push_scope_as_child_of(node)
        return node.cache
    end
end

return derive
