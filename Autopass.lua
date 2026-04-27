local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local AutoFarmCmds = require(Library.Client.AutoFarmCmds)

local lp = game.Players.LocalPlayer
local root = lp.Character:WaitForChild("HumanoidRootPart")
local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")

task.spawn(function()
    while true do
        if _G.AutoFarmEnabled then
            -- Если автофарм еще не включен - включаем его официально
            if not AutoFarmCmds.IsEnabled() then
                pcall(function()
                    AutoFarmCmds.Enable()
                end)
            end
        else
            -- Если ты выключил чит - выключаем и автофарм игры
            if AutoFarmCmds.IsEnabled() then
                pcall(function()
                    AutoFarmCmds.Disable()
                end)
            end
        end
        task.wait(1) -- Проверяем статус раз в секунду
    end
end)

