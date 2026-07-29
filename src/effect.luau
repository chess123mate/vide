local graph = require "./graph"
local create_node = graph.create_node
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node

local function effect<T>(callback: (T) -> T, initial_value: T)
	local scope = get_scope() or error("Must be called in a scope", 2)

	local effect = scope.effect
	scope.effect = false

    local node = create_node(scope, callback, initial_value)
    local ok, result = xpcall(evaluate_node, debug.traceback, node)

    scope.effect = effect

    if not ok then error(result, 2) end
end

return effect :: (<T>(callback: (T) -> T, initial_value: T) -> ()) & ((callback: () -> ()) -> ())
