print("fast hatch ready")

task.wait(35)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_InvokeCustomFromClient")
local THREADS = 30
local DELAY = 0.02 
local function hatch()
    remote:InvokeServer("EasterHatchEvent", "HatchRequest")
    if math.random() < 0.125 then
        remote:InvokeServer("EasterHatchEvent", "HatchRequest", math.random(1, 3))
    end
end
for i = 1, THREADS do
    task.spawn(function()
        while true do
            hatch()
            task.wait(DELAY)
        end
    end)
end
