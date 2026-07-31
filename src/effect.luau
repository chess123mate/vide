local graph = require "./graph"
local create_node = graph.create_node
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node

local function effect<T>(callback: (T) -> T, initial_value: T)
    local scope = get_scope() or error("effect() must be called in a scope", 2)
    local node = create_node(scope, callback, initial_value)
    evaluate_node(node)
end

return effect :: (<T>(callback: (T) -> T, initial_value: T) -> ()) & ((callback: () -> ()) -> ())
