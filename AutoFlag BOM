local lp = game.Players.LocalPlayer
local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")

local function PlaceFlag()
    local args = {"Coins Flag", "33ca54bee6434c91b8703448c8369ade", 20}
    pcall(function()
        Network:WaitForChild("FlexibleFlags_Consume"):InvokeServer(unpack(args))
    end)
end

local function ExecuteFlagRoutine()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    local activeContainer = workspace:WaitForChild("__THINGS"):WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active")
    local eventFolder = activeContainer:WaitForChild("EasterHatchEvent")
    local breakZones = eventFolder:WaitForChild("BREAK_ZONES")

    if breakZones then
        local zones = {"2", "7", "12", "17"}
        for _, zoneName in ipairs(zones) do
            local zonePath = breakZones:FindFirstChild(zoneName)
            if zonePath then
                root.CFrame = zonePath.CFrame * CFrame.new(0, 5, 0)
                task.wait(1) 
                PlaceFlag()
                task.wait(3.5)
            end
        end
    end
    
    task.wait(3)
    root.CFrame = CFrame.new(-18468.873, 15.255, -29149.523)
end

task.spawn(function()
    while true do
        pcall(ExecuteFlagRoutine)
        task.wait(6000)
    end
end)
