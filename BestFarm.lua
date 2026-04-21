-- Ждем загрузку игры
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local lp = game.Players.LocalPlayer
local root = lp.Character:WaitForChild("HumanoidRootPart")
local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")

task.wait(10)
loadstring(game:HttpGet("https://rawscripts.net/raw/Pet-Simulator-99!-Cheat-Menu-17428"))()

-- 1. ХУК ФУНКЦИЙ (Заменяем код анимации на пустоту)
for _, v in pairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "Play") and type(v.Play) == "function" then
        -- Ищем функцию Play внутри модулей, связанных с яйцами
        local info = getinfo(v.Play)
        if info.source:find("Egg") or info.source:find("Hatch") then
            v.Play = function() return end
        end
    elseif type(v) == "function" then
        local info = getinfo(v)
        if info.name == "PlayEggAnimation" or info.name == "ShowHatch" then
            hookfunction(v, function() return end)
        end
    end
end

-- 2. ПРИНУДИТЕЛЬНОЕ УДАЛЕНИЕ ВСЕХ ЧЕРНЫХ ЭКРАНОВ И ТЕКСТА
task.spawn(function()
    while task.wait() do
        local pGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            -- Ищем всё, что перекрывает экран (ZIndex выше 100 обычно у анимаций)
            for _, gui in pairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name:find("Egg") or gui.Name:find("Hatch") or gui.Name:find("Scene")) then
                    gui:Destroy()
                end
            end
        end
    end
end)

-- 3. РАЗБЛОКИРОВКА ИНТЕРФЕЙСА (Main)
-- Чтобы кнопки не исчезали во время открытия
task.spawn(function()
    local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"))
    game:GetService("RunService").RenderStepped:Connect(function()
        if Library.Variables then
            Library.Variables.OpeningEgg = false
        end
    end)
end)


-- 1. ТЕЛЕПОРТ В ПОРТАЛ (с задержкой для прогрузки)
task.spawn(function()
    local portal = workspace.__THINGS.Instances.EasterHatchEvent:WaitForChild("Teleports", 20):WaitForChild("Enter", 5)
    if portal then
        root.CFrame = portal.CFrame
        print("[✓] Телепортирован к входу в ивент")
    else
        print("[!] Вход в ивент не найден")
    end
end)
-- 2. ОЖИДАНИЕ ПЕРЕХОДА И ВКЛЮЧЕНИЕ АВТОФАРМА
task.wait(3)
pcall(function()
    Network.AutoFarm_Request:InvokeServer(true)
end)


-- 4. ТЕЛЕПОРТ В ЦЕНТР БЛОКА (BREAK_ZONE 7) + 5 по Y
task.spawn(function()
    -- Ждем появления зоны, так как ивент-локи грузятся отдельно
    local zonePath = workspace.__THINGS.__INSTANCE_CONTAINER.Active:WaitForChild("EasterHatchEvent", 20):WaitForChild("BREAK_ZONES", 10):WaitForChild("7", 10)
    
    if zonePath then
        task.wait(1)
        root.CFrame = zonePath.CFrame * CFrame.new(0, 5, 0)
    end
end)

-- 5. ЗАПУСК ТВОЕГО БЫСТРОГО ФАРМА
_G.MegaFarmSystem = true
local ignoredZones = {} 

task.spawn(function()
    local Things = workspace:WaitForChild("__THINGS")
    local Breakables = Things:WaitForChild("Breakables")
    local Orbs = Things:WaitForChild("Orbs")
    local Pets = Things:WaitForChild("Pets")
    
    -- Безопасный поиск папки ивента
    local Active = Things:WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active")
    local EasterEvent = Active:WaitForChild("EasterHatchEvent", 20)
    
    if not EasterEvent then
        print("![ОШИБКА]: Папка EasterHatchEvent не появилась. Зайди в локацию ивента!")
        return
    end
    
    local ZonesFolder = EasterEvent:WaitForChild("BREAK_ZONES")
    print("[СИСТЕМА]: Скрипт запущен. Начинаю анализ зон в " .. EasterEvent.Name)

    local function getZoneOfPart(part)
        for _, zone in pairs(ZonesFolder:GetChildren()) do
            local size = zone.Size
            local pos = zone.Position
            local pPos = part.Position
            if pPos.X >= pos.X - size.X/2 and pPos.X <= pos.X + size.X/2 and
               pPos.Z >= pos.Z - size.Z/2 and pPos.Z <= pos.Z + size.Z/2 then
                return zone.Name
            end
        end
        return nil
    end

    while _G.MegaFarmSystem do
        pcall(function()
            -- 1. Сбор сфер
            local orbIds = {}
            for _, o in pairs(Orbs:GetChildren()) do 
                table.insert(orbIds, tonumber(o.Name)) 
                o:Destroy() 
            end
            if #orbIds > 0 then Network["Orbs: Collect"]:FireServer(orbIds) end
            
            -- 2. Атака
            local allTargets = Breakables:GetChildren()
            local petIds = {}
            for _, p in pairs(Pets:GetChildren()) do table.insert(petIds, p.Name) end

            if #allTargets > 0 and #petIds > 0 then
                local data = {}
                for _, pId in ipairs(petIds) do
                    local target = allTargets[math.random(1, #allTargets)]
                    local zoneName = getZoneOfPart(target)

                    -- Если нашли новую зону, которую еще не проверяли
                    if zoneName and ignoredZones[zoneName] == nil then
                        ignoredZones[zoneName] = "checking" -- Статус проверки
                        print("[АНАЛИЗ]: Проверяю зону " .. zoneName .. "...")

                        task.delay(2, function()
                            if target and target.Parent == Breakables then
                                ignoredZones[zoneName] = true
                                -- Считаем сколько всего в блэклисте
                                local count = 0
                                for _, v in pairs(ignoredZones) do if v == true then count += 1 end end
                                print("![БЛЭКЛИСТ]: Зона " .. zoneName .. " НЕ ломается. (Всего в бане: " .. count .. "/20)")
                            else
                                ignoredZones[zoneName] = false
                                print("[УСПЕХ]: Зона " .. zoneName .. " доступна для фарма.")
                            end
                        end)
                    end

                    -- Атакуем только если зона подтверждена как рабочая (false) 
                    -- или пока она еще проверяется (чтобы нанести тот самый пробный удар)
                    if not zoneName or ignoredZones[zoneName] == false or ignoredZones[zoneName] == "checking" then
                        data[pId] = target.Name
                    end
                end
                
                if next(data) then
                    Network.Breakables_JoinPetBulk:FireServer(data)
                end
            end
        end)
        task.wait(0.2)
    end
end)

-- (Твой остальной код с AutoFarmCmds без изменений)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local AutoFarmCmds = require(Library.Client.AutoFarmCmds)

-- Функция для твоего хаба
_G.AutoFarmEnabled = true -- Эту переменную привяжи к кнопке

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


-- 3. ТЕЛЕПОРТ НА ЛОКАЦИЮ ИВЕНТА
task.wait(15)
pcall(function()
    local hatchZone = workspace.__THINGS.__INSTANCE_CONTAINER.Active.EasterHatchEvent["1 | Cloud Meadow"].INTERACT.HatchingZone
    if hatchZone then
        root.CFrame = hatchZone.CFrame
        print("[✓] Телепортирован в HatchingZone")
    end
end)
task.wait(1)
local RS = game:GetService("ReplicatedStorage")

local network     = RS:WaitForChild("Network", 10)
local invokeRemote = network:WaitForChild("Instancing_InvokeCustomFromClient", 10)
local fireRemote  = network:FindFirstChild("Instancing_FireCustomFromClient")

local instanceID = "EasterHatchEvent"
local hatchArg   = "HatchRequest"
local count      = 0
local running    = true

-- МЕТОД 1: FireServer потоки (быстрые, но с минимальной паузой 0.05)
local args = {
    "EasterHatchEvent",
    "HatchRequest"
}

local network = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Instancing_InvokeCustomFromClient")

-- Создаем бесконечный цикл
while true do
    network:InvokeServer(unpack(args))
    task.wait(0.1) -- Задержка в 0.1 секунды, чтобы игра не крашнулась и сервер не кикнул за спам
end
