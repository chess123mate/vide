type Action = {
    callback: (Instance) -> ()
}

local ActionMT = table.freeze {}

local function is_action(v: any)
    return getmetatable(v) == ActionMT
end

local function action(callback: (Instance) -> ()): Action
    return table.freeze(setmetatable({
        callback = callback
    }, ActionMT))
end

return function()
    return action, is_action
end
