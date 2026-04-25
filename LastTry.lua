print("injected")
-- Ждем загрузку игры
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local lp = game.Players.LocalPlayer
local root = lp.Character:WaitForChild("HumanoidRootPart")
local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
task.wait(2)
loadstring(game:HttpGet("https://rawscripts.net/raw/Pet-Simulator-99!-Cheat-Menu-17428"))()
task.wait(2)
-- БЛОК СОЗДАНИЯ ГУИ (Вставь в начало)
local function createNotify()
    local sg = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    sg.Name = "FarmStatusGui"
    sg.ResetOnSpawn = false

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 320, 0, 75)
    frame.Position = UDim2.new(0.5, -160, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    
    local main = Instance.new("TextLabel", frame)
    main.Size = UDim2.new(1, 0, 0.6, 0)
    main.BackgroundTransparency = 1
    main.TextColor3 = Color3.new(1, 1, 1)
    main.Font = Enum.Font.GothamBold
    main.TextSize = 16
    main.Text = "🔍 Инициализация..."

    local sub = Instance.new("TextLabel", frame)
    sub.Size = UDim2.new(1, 0, 0.4, 0)
    sub.Position = UDim2.new(0, 0, 0.55, 0)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = Color3.fromRGB(255, 215, 0)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.Text = "🥚 Ожидание открытия яиц..." 
    
    return sg, main, sub
end
local gui, mainTxt, eggTxt = createNotify()

-- 1. ДАННЫЕ ДЛЯ ТРЕКЕРА
local startTime = tick()
local initialPetCount = 0
local sessionEggs = 0
local tokenStats = {
    ["Spring Pink Rose Token"] = {start = 0, current = 0, label = "Pink Rose"},
    ["Spring Yellow Sunflower Token"] = {start = 0, current = 0, label = "Yellow Sunfl."},
    ["Spring Red Tulip Token"] = {start = 0, current = 0, label = "Red Tulip"},
    ["Spring Bluebell Token"] = {start = 0, current = 0, label = "Bluebell"},
    ["Spring Egg Token"] = {start = 0, current = 0, label = "Egg Token"}
}

-- Функция для форматирования времени
local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- 2. ГУИ СТАТИСТИКИ (Справа по центру + Время)
local function createStatsGui()
    local sg = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
    sg.Name = "TokenStatsGui"
    sg.ResetOnSpawn = false

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 350, 0, 230) -- Еще чуть выше для времени
    frame.Position = UDim2.new(1, -360, 0.5, -115) -- Справа по центру
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency = 0.3
    Instance.new("UICorner", frame)

    local list = Instance.new("UIListLayout", frame)
    list.Padding = UDim.new(0, 5)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function createLine(id, color)
        local lab = Instance.new("TextLabel", frame)
        lab.Size = UDim2.new(0.9, 0, 0, 25)
        lab.BackgroundTransparency = 1
        lab.TextColor3 = color
        lab.Font = Enum.Font.Code
        lab.TextSize = 13
        lab.TextXAlignment = Enum.TextXAlignment.Left
        lab.Text = tokenStats[id].label .. ": 0 | 0 | 0/s"
        return lab
    end

    local labels = {
        ["Spring Pink Rose Token"] = createLine("Spring Pink Rose Token", Color3.fromRGB(255, 150, 200)),
        ["Spring Yellow Sunflower Token"] = createLine("Spring Yellow Sunflower Token", Color3.fromRGB(255, 255, 100)),
        ["Spring Red Tulip Token"] = createLine("Spring Red Tulip Token", Color3.fromRGB(255, 100, 100)),
        ["Spring Bluebell Token"] = createLine("Spring Bluebell Token", Color3.fromRGB(100, 200, 255)),
        ["Spring Egg Token"] = createLine("Spring Egg Token", Color3.fromRGB(255, 255, 255))
    }
    
    local spacer = Instance.new("Frame", frame)
    spacer.Size = UDim2.new(1, 0, 0, 5)
    spacer.BackgroundTransparency = 1

    local eggLabel = Instance.new("TextLabel", frame)
    eggLabel.Size = UDim2.new(0.9, 0, 0, 25)
    eggLabel.BackgroundTransparency = 1
    eggLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    eggLabel.Font = Enum.Font.GothamBold
    eggLabel.TextSize = 14
    eggLabel.TextXAlignment = Enum.TextXAlignment.Left
    eggLabel.Text = "Session Eggs: 0"

    -- НОВАЯ СТРОКА: Session Time
    local timeLabel = Instance.new("TextLabel", frame)
    timeLabel.Size = UDim2.new(0.9, 0, 0, 25)
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    timeLabel.Font = Enum.Font.Code
    timeLabel.TextSize = 13
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Text = "Session Time: 00:00:00"

    return sg, labels, eggLabel, timeLabel
end

local statsGui, labels, eggLabel, timeLabel = createStatsGui()

-- 3. ЛОГИКА ОБНОВЛЕНИЯ
task.spawn(function()
    local Save = require(game:GetService("ReplicatedStorage").Library.Client.Save)
    
    local function getData()
        local s = Save.Get()
        if not s or not s.Inventory then return {}, {} end
        local inv = s.Inventory
        return inv.Misc or {}, inv.Pet or {}
    end

    -- Стартовые значения
    local sMisc, sPets = getData()
    for _, item in pairs(sMisc) do
        if tokenStats[item.id] then tokenStats[item.id].start = item._am or 0 end
    end
    for _, pet in pairs(sPets) do
        initialPetCount = initialPetCount + (pet._am or 1)
    end

    while task.wait(1) do
        local cMisc, cPets = getData()
        local elapsed = tick() - startTime
        
        -- Обновляем Время
        timeLabel.Text = "Session Time: " .. formatTime(elapsed)

        -- Обновляем Токены
        for _, item in pairs(cMisc) do
            local stats = tokenStats[item.id]
            if stats then
                stats.current = item._am or 0
                local session = stats.current - stats.start
                local perSec = session / elapsed
                
                labels[item.id].Text = string.format(
                    "%s: %s | +%d | %.2f/s", 
                    stats.label, 
                    (stats.current > 1000 and string.format("%.1fK", stats.current/1000) or tostring(stats.current)),
                    session, 
                    perSec
                )
            end
        end
        
        -- Обновляем Яйца
        local currentTotalPets = 0
        for _, pet in pairs(cPets) do
            currentTotalPets = currentTotalPets + (pet._am or 1)
        end
        sessionEggs = currentTotalPets - initialPetCount
        eggLabel.Text = "Session Eggs: " .. tostring(sessionEggs)
    end
end)


-- 1. ТЕЛЕПОРТ В ПОРТАЛ (с задержкой для прогрузки)
task.spawn(function()
    local portal = workspace.__THINGS.Instances.EasterHatchEvent:WaitForChild("Teleports", 20):WaitForChild("Enter", 5)
    if portal then
        root.CFrame = portal.CFrame
            else
        print("[!] Вход в ивент не найден")
    end
end)


task.wait(3)
-- 2. ОЖИДАНИЕ ПЕРЕХОДА И ВКЛЮЧЕНИЕ АВТОФАРМА
--------------

local RunService = game:GetService("RunService")
local lp = game.Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- 1. НАСТРОЙКИ
local targetCFrame = CFrame.new(-18505.6094, -7.72793388, -29109.084, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local fixedY = targetCFrame.Y - 3.5
local offset = 3.5

-- 2. ПОИСК СУЩЕСТВУЮЩИХ ПАДОВ (чтобы не спавнить новые)

local staticYPad = workspace:FindFirstChild("FollowPad_XZ")

-- Если вдруг их нет (первый запуск), создаем один раз


if not staticYPad then
    staticYPad = Instance.new("Part", workspace)
    staticYPad.Name = "FollowPad_XZ"
    staticYPad.Size = Vector3.new(14, 1, 14)
    staticYPad.Anchored = true
    staticYPad.CanCollide = true
    staticYPad.Transparency = 0.5
    staticYPad.BrickColor = BrickColor.new("Electric blue")
    staticYPad.Material = Enum.Material.Neon
end

-- 3. ФУНКЦИЯ ТЕЛЕПОРТА И ЧИСТКИ (Вызывается скриптом)
local function executeAction()
    -- Телепорт игрока
    hrp.CFrame = targetCFrame
    
    -- Чистка (удаление текстур/партов)
    pcall(function()
        local active = workspace.__THINGS.__INSTANCE_CONTAINER.Active:FindFirstChild("EasterHatchEvent")
        if active then
            if active:FindFirstChild("ZONE_GROUND") then active.ZONE_GROUND:Destroy() end
            local meadow = active:FindFirstChild("1 | Cloud Meadow")
            if meadow then
                if meadow:FindFirstChild("PARTS_LOD") then meadow.PARTS_LOD:Destroy() end
                if meadow.INTERACT:FindFirstChild("DisplayZone") then meadow.INTERACT.DisplayZone:Destroy() end
                if meadow.INTERACT:FindFirstChild("HatchingZone") then meadow.INTERACT.HatchingZone:Destroy() end
                meadow:Destroy()
            end
        end
        local fake = workspace.__THINGS:FindFirstChild("__FAKE_INSTANCE_GROUND")
        if fake and fake:FindFirstChild("EasterHatchEvent") then fake.EasterHatchEvent:Destroy() end
    end)
    print("Действие выполнено: ТП и чистка завершены.")
end

-- 4. GUI КНОПКА (ОСТАВИЛ ДЛЯ РУЧНОГО ВЫЗОВА)
local screenGui = lp.PlayerGui:FindFirstChild("TeleportGui") or Instance.new("ScreenGui", lp.PlayerGui)
screenGui.Name = "TeleportGui"
local tpBtn = screenGui:FindFirstChild("TPBtn") or Instance.new("TextButton", screenGui)
tpBtn.Name = "TPBtn"
tpBtn.Size = UDim2.new(0, 140, 0, 40)
tpBtn.Position = UDim2.new(1, -160, 0, 20)
tpBtn.Text = "TP TO START"
tpBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tpBtn.TextColor3 = Color3.new(1, 1, 1)
tpBtn.Font = Enum.Font.SourceSansBold
tpBtn.TextSize = 18

tpBtn.MouseButton1Click:Connect(executeAction)

-- 5. ЛОГИКА ДВИЖЕНИЯ
RunService.RenderStepped:Connect(function()
    if hrp and hrp.Parent then

        staticYPad.CFrame = CFrame.new(hrp.Position.X, fixedY, hrp.Position.Z)
        if hrp.AssemblyLinearVelocity.Y < -0.1 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end
end)

executeAction()

---------------
local lp = game.Players.LocalPlayer
local root = lp.Character:WaitForChild("HumanoidRootPart")
local Things = workspace:WaitForChild("__THINGS")
local EasterEvent = Things.__INSTANCE_CONTAINER.Active:WaitForChild("EasterHatchEvent")
local ZonesFolder = EasterEvent:WaitForChild("BREAK_ZONES")

-- 1. ТИХАЯ АКТИВАЦИЯ ИГРОВОГО АВТОФАРМА
task.spawn(function()
    local oldCF = root.CFrame
    local zone41 = ZonesFolder:WaitForChild("41", 10)
    if zone41 then
        root.CFrame = zone41.CFrame * CFrame.new(0, 5, 0)
        task.wait(2)
        pcall(function()
            require(game:GetService("ReplicatedStorage").Library.Client.AutoFarmCmds).Enable()
        end)
        task.wait(2)
        root.CFrame = oldCF
    end
end)

_G.MegaFarmSystem = true

-- 2. ФУНКЦИЯ ОПРЕДЕЛЕНИЯ ЗОНЫ
local function getZoneOfPart(part)
    local hp = part:FindFirstChild("Hitbox") or part:FindFirstChildWhichIsA("BasePart")
    if not hp then return nil end
    local pPos = hp.Position
    for i = 41, 34, -1 do
        local zone = ZonesFolder:FindFirstChild(tostring(i))
        if zone then
            local size, pos = zone.Size, zone.Position
            if pPos.X >= pos.X - size.X/2 - 10 and pPos.X <= pos.X + size.X/2 + 10 and
               pPos.Z >= pos.Z - size.Z/2 - 10 and pPos.Z <= pos.Z + size.Z/2 + 10 then
                return tostring(i)
            end
        end
    end
end

-- 3. ГЛАВНЫЙ ЦИКЛ ФАРМА СУНДУКОВ
task.spawn(function()
    local Network = require(game:GetService("ReplicatedStorage").Library.Client.Network)
    while _G.MegaFarmSystem do
        pcall(function()
            -- Сбор сфер
            local orbIds = {}
            for _, o in pairs(Things.Orbs:GetChildren()) do 
                table.insert(orbIds, tonumber(o.Name)) 
                o:Destroy() 
            end
            if #orbIds > 0 then Network.Fire("Orbs: Collect", orbIds) end
            
            -- Выбор приоритетного сундука (от 41 к 34)
            local target = nil
            local breakables = Things.Breakables:GetChildren()
            for i = 41, 34, -1 do
                for _, b in pairs(breakables) do
                    if getZoneOfPart(b) == tostring(i) then 
                        target = b 
                        break 
                    end
                end
                if target then break end
            end

            -- Атака петами
            if target then
                local data = {}
                for _, p in pairs(Things.Pets:GetChildren()) do 
                    data[p.Name] = target.Name 
                end
                if next(data) then
                    Network.Fire("Breakables_JoinPetBulk", data)
                end
            end
        end)
        task.wait(0.3) -- Скорость проверки сундуков
    end
end)


-- 3. TP HATCHING ZONE
task.wait(20)
pcall(function()
    local hatchZone = workspace.__THINGS.__INSTANCE_CONTAINER.Active.EasterHatchEvent["1 | Cloud Meadow"].INTERACT.HatchingZone
    if hatchZone then
        root.CFrame = hatchZone.CFrame
        print("[✓] Телепортирован в HatchingZone")
    end
end)
executeAction()
task.wait(1)
-- ==========================================================
-- 6. ФИНАЛЬНЫЙ БЛОК: ОТКРЫТИЕ ЯИЦ (АГРЕССИВНЫЙ MULTI-THREAD)
-- ==========================================================

task.spawn(function()
    task.wait(2) 
    
    if eggTxt then 
        eggTxt.Text = "🥚 Быстрое открытие яиц: МАКСИМУМ" 
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_InvokeCustomFromClient")
    
    -- НАСТРОЙКИ СКОРОСТИ
    local THREADS = 30 -- Количество одновременных потоков
    local DELAY = 0.0 -- Задержка между запросами в каждом потоке

    -- Функция одного «удара» по серверу
    local function hatch()
        pcall(function()
            -- Основной запрос на открытие
            remote:InvokeServer("EasterHatchEvent", "HatchRequest")
            
            -- Дополнительный рандомный запрос (как у тебя в коде)
            if math.random() < 0.125 then
                remote:InvokeServer("EasterHatchEvent", "HatchRequest", math.random(1, 3))
            end
        end)
    end

    -- Запуск многопоточности
    print("--- [HATCHER]: Запуск " .. THREADS .. " потоков открытия... ---")
    
    for i = 1, THREADS do
        task.spawn(function()
            -- Каждый поток работает независимо и максимально быстро
            while true do
                hatch()
                task.wait(DELAY)
            end
        end)
    end
end)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_InvokeCustomFromClient")
