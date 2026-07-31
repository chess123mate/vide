local root = require "./root"
local apply = require "./apply"

local function mount<T>(component: () -> T, target: Instance, ...): () -> ()
    if not target then error("missing target instance", 2) end
    return root(function(...)
        local result = component(...) or error("component did not return an Instance")
        apply(target, {result})
        return result
    end, ...)
end

return mount ::
    (<T>(component: () -> T, target: Instance) -> (() -> (), T)) & ((component: () -> ()) -> () -> ())
