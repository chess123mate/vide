local action = require "./action"()
local cleanup = require "./cleanup"

local function changed<T>(property: string, callback: (T) -> ())
    return action(function(instance)
        cleanup(instance:GetPropertyChangedSignal(property):Connect(function()
            callback(instance[property])
        end))
        callback(instance[property])
    end)
end

return changed
