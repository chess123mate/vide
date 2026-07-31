local graph = require "./graph"
local create_node = graph.create_node
local push_scope_as_child_of = graph.push_scope_as_child_of
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node

local function derive<T>(source: () -> T): () -> T
    local scope = get_scope() or error("derive() must be called in a scope", 2)
    local node = create_node(scope, source, false :: any)
    evaluate_node(node)
    return function()
        push_scope_as_child_of(node)
        return node.cache
    end
end

return derive
