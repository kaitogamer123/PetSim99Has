print("injected")
-- Ждем загрузку игры
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local lp = game.Players.LocalPlayer
local root = lp.Character:WaitForChild("HumanoidRootPart")
local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")

task.wait(5)
loadstring(game:HttpGet("https://rawscripts.net/raw/Pet-Simulator-99!-Cheat-Menu-17428"))()
task.wait(3)

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
-- 2. ОЖИДАНИЕ ПЕРЕХОДА И ВКЛЮЧЕНИЕ АВТОФАРМА
task.wait(7)
pcall(function()
    Network.AutoFarm_Request:InvokeServer(true)
end)


task.spawn(function()
    -- Ждем появления зоны, так как ивент-локи грузятся отдельно
    local zonePath = workspace.__THINGS.__INSTANCE_CONTAINER.Active:WaitForChild("EasterHatchEvent", 20):WaitForChild("BREAK_ZONES", 10):WaitForChild("7", 10)
    
    if zonePath then
        task.wait(3)
        root.CFrame = zonePath.CFrame * CFrame.new(0, 5, 0)
        mainTxt.Text = "📍 Активация автофарма..."
    end
end)

_G.MegaFarmSystem = false 
task.wait(0.5)
_G.MegaFarmSystem = true

local ignoredZones = {} 
local testingTarget = nil 
local lastLogTime = 0
local confirmedCount = 0 -- Переменная для счета зон
local countdownStarted = false -- Чтобы отсчет не запустился дважды

task.spawn(function()
    local Things = workspace:WaitForChild("__THINGS")
    local Breakables = Things:WaitForChild("Breakables")
    local Pets = Things:WaitForChild("Pets")
    local Orbs = Things:WaitForChild("Orbs")
    
    local EasterEvent = Things.__INSTANCE_CONTAINER.Active:WaitForChild("EasterHatchEvent", 20)
    local ZonesFolder = EasterEvent:WaitForChild("BREAK_ZONES")

    local function getZoneOfPart(part)
        local hp = part:FindFirstChild("Hitbox") or part:FindFirstChildWhichIsA("BasePart")
        if not hp then return nil end
        local pPos = hp.Position
        for _, zone in pairs(ZonesFolder:GetChildren()) do
            local size, pos = zone.Size, zone.Position
            if pPos.X >= pos.X - size.X/2 - 10 and pPos.X <= pos.X + size.X/2 + 10 and
               pPos.Z >= pos.Z - size.Z/2 - 10 and pPos.Z <= pos.Z + size.Z/2 + 10 then
                return zone.Name
            end
        end
        return nil
    end

    while _G.MegaFarmSystem do
        pcall(function()
            -- 1. Сбор сфер
            local orbIds = {}
            for _, o in pairs(Orbs:GetChildren()) do table.insert(orbIds, tonumber(o.Name)) o:Destroy() end
            if #orbIds > 0 then Network["Orbs: Collect"]:FireServer(orbIds) end
            
            local petIds = {}
            for _, p in pairs(Pets:GetChildren()) do table.insert(petIds, p.Name) end
            local allTargets = Breakables:GetChildren()

            -- 2. ТЕСТ ЗОН И ОБНОВЛЕНИЕ ГУИ
            if not testingTarget then
                for _, t in pairs(allTargets) do
                    local zName = getZoneOfPart(t)
                    if zName and ignoredZones[zName] == nil then
                        testingTarget = t
                        ignoredZones[zName] = "checking"
                        
                        task.delay(5, function() 
                            if testingTarget and testingTarget.Parent == Breakables then
                                ignoredZones[zName] = true
                            else
                                ignoredZones[zName] = false
                                confirmedCount = confirmedCount + 1 -- Плюсуем зону
                                
                                -- ОБНОВЛЯЕМ ТЕКСТ В ГУИ
                                if confirmedCount < 4 then
                                    mainTxt.Text = "✅ Найдено зон: " .. confirmedCount .. "/4"
                                else
                                    -- ЗАПУСКАЕМ ОТСЧЕТ, КОГДА НАШЛИ 4
                                    if not countdownStarted then
                                        countdownStarted = true
                                        task.spawn(function()
                                            for i = 10, 1, -1 do
                                                mainTxt.Text = "🚀 Автофарм запущен! Закроюсь через " .. i
                                                task.wait(1)
                                            end
                                            gui:Destroy()
                                        end)
                                    end
                                end
                            end
                            testingTarget = nil
                        end)
                        break
                    end
                end
            end

            local data = {}
            local validTargets = {}
            for _, t in pairs(allTargets) do
                local zName = getZoneOfPart(t)
                if not zName or ignoredZones[zName] == false then
                    table.insert(validTargets, t)
                end
            end

            for _, pId in ipairs(petIds) do
                if testingTarget then
                    data[pId] = testingTarget.Name
                elseif #validTargets > 0 then
                    data[pId] = validTargets[math.random(1, #validTargets)].Name
                end
            end

            if next(data) then
                Network.Breakables_JoinPetBulk:FireServer(data)
            end

            if tick() - lastLogTime >= 1 then
                lastLogTime = tick()
            end
        end)
        task.wait(0.2)
    end
end)



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local AutoFarmCmds = require(Library.Client.AutoFarmCmds)

_G.AutoFarmEnabled = true

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

-- 3. TP HATCHING ZONE
task.wait(20)
pcall(function()
    local hatchZone = workspace.__THINGS.__INSTANCE_CONTAINER.Active.EasterHatchEvent["1 | Cloud Meadow"].INTERACT.HatchingZone
    if hatchZone then
        root.CFrame = hatchZone.CFrame
        print("[✓] Телепортирован в HatchingZone")
    end
end)
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
    local DELAY = 0.01 -- Задержка между запросами в каждом потоке

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
