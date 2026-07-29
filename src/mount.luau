local root = require "./root"
local apply = require "./apply"
local action = require "./action"
local cleanup = require "./cleanup"

local function mount<T>(component: () -> T, target: Instance): () -> ()
    if not target then error("missing target instance", 2) end
    return root(function()
        local result = component() or error("component did not return an Instance")
        if typeof(result) == "Instance" then
            cleanup(function()
                result.Parent = nil
            end)
        end
        apply(target, {result})
    end)
end

return mount :: (<T>(component: () -> T, target: Instance) -> () -> ()) & ((component: () -> ()) -> () -> ())
