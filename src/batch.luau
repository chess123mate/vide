local flags = require "./flags"
local graph = require "./graph"

local function batch(setter: () -> ())
    if flags.batch then
        setter()
        return
    end

    local from = graph.get_update_queue_length()
    flags.batch = true

    local ok, err: string? = xpcall(setter, debug.traceback)

    flags.batch = false
    graph.flush_update_queue(from)

    if not ok then error(`error occured while batching updates: {err}`, 2) end
end

return batch
