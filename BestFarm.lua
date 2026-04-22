print("Injected: Part 1 (GUI & Stats)")

-- 1. ОЖИДАНИЕ ЗАГРУЗКИ
if not game:IsLoaded() then game.Loaded:Wait() end
local lp = game.Players.LocalPlayer
if not lp.Character then lp.CharacterAdded:Wait() end

-- 2. СЕРВИСЫ И МОДУЛИ
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local root = lp.Character:WaitForChild("HumanoidRootPart")
local Net = require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Network"))
local Library = ReplicatedStorage:WaitForChild("Library")
local Save = require(Library.Client.Save)
local AutoFarmCmds = require(Library.Client.AutoFarmCmds)

-- 3. ФУНКЦИЯ КОНФИГА (ОБЯЗАТЕЛЬНО ТУТ)
local function getCfg(category, value, default)
    if getgenv().Config and getgenv().Config[category] and getgenv().Config[category][value] ~= nil then
        return getgenv().Config[category][value]
    end
    return default
end

loadstring(game:HttpGet("https://rawscripts.net/raw/Pet-Simulator-99!-Cheat-Menu-17428"))()

-- 5. СОЗДАНИЕ ГУИ СТАТУСА
local function createNotify()
    local sg = Instance.new("ScreenGui", lp:WaitForChild("PlayerGui"))
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
local statusGui, mainTxt, eggTxt = createNotify()

-- 6. ТРЕКЕР ТОКЕНОВ И ВРЕМЕНИ
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

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function createStatsGui()
    local sg = Instance.new("ScreenGui", lp.PlayerGui)
    sg.Name = "TokenStatsGui"
    sg.ResetOnSpawn = false
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 350, 0, 230)
    frame.Position = UDim2.new(1, -360, 0.5, -115)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency = 0.3
    Instance.new("UICorner", frame)
    local list = Instance.new("UIListLayout", frame); list.Padding = UDim.new(0, 5); list.HorizontalAlignment = "Center"

    local labels = {}
    for id, info in pairs(tokenStats) do
        local lab = Instance.new("TextLabel", frame)
        lab.Size = UDim2.new(0.9, 0, 0, 25); lab.BackgroundTransparency = 1; lab.Font = "Code"; lab.TextSize = 13; lab.TextXAlignment = "Left"
        lab.TextColor3 = Color3.new(1,1,1) -- Цвет настроится в цикле обновления
        labels[id] = lab
    end
    
    local eggLabel = Instance.new("TextLabel", frame)
    eggLabel.Size = UDim2.new(0.9, 0, 0, 25); eggLabel.BackgroundTransparency = 1; eggLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    eggLabel.Font = "GothamBold"; eggLabel.TextSize = 14; eggLabel.TextXAlignment = "Left"

    local timeLabel = Instance.new("TextLabel", frame)
    timeLabel.Size = UDim2.new(0.9, 0, 0, 25); timeLabel.BackgroundTransparency = 1; timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    timeLabel.Font = "Code"; timeLabel.TextSize = 13; timeLabel.TextXAlignment = "Left"

    return sg, labels, eggLabel, timeLabel
end

local statsGui, labels, eggLabel, timeLabel = createStatsGui()

-- 7. ЦИКЛ ОБНОВЛЕНИЯ СТАТИСТИКИ
task.spawn(function()
    local function getData()
        local s = Save.Get()
        if not s or not s.Inventory then return {}, {} end
        return s.Inventory.Misc or {}, s.Inventory.Pet or {}
    end

    local sMisc, sPets = getData()
    for _, item in pairs(sMisc) do if tokenStats[item.id] then tokenStats[item.id].start = item._am or 0 end end
    for _, pet in pairs(sPets) do initialPetCount = initialPetCount + (pet._am or 1) end

    while task.wait(1) do
        local cMisc, cPets = getData()
        local elapsed = tick() - startTime
        timeLabel.Text = "Session Time: " .. formatTime(elapsed)

        for id, lab in pairs(labels) do
            local found = false
            for _, item in pairs(cMisc) do
                if item.id == id then
                    local stats = tokenStats[id]
                    stats.current = item._am or 0
                    local session = stats.current - stats.start
                    lab.Text = string.format("%s: %s | +%d | %.2f/s", stats.label, (stats.current > 1000 and string.format("%.1fK", stats.current/1000) or tostring(stats.current)), session, session/elapsed)
                    found = true break
                end
            end
            if not found then lab.Text = tokenStats[id].label .. ": 0 | 0 | 0/s" end
        end
        
        local currentTotalPets = 0
        for _, pet in pairs(cPets) do currentTotalPets = currentTotalPets + (pet._am or 1) end
        sessionEggs = currentTotalPets - initialPetCount
        eggLabel.Text = "Session Eggs: " .. tostring(sessionEggs)
    end
end)
-- 1. ТЕЛЕПОРТ В ПОРТАЛ (Твоя оригинальная задержка)
task.spawn(function()
    local portal = workspace.__THINGS.Instances.EasterHatchEvent:WaitForChild("Teleports", 20):WaitForChild("Enter", 5)
    if portal then
        root.CFrame = portal.CFrame
    end
end)

task.wait(3)
pcall(function()
    Net.Invoke("AutoFarm_Request", true)
end)

-- 2. ТВОЯ ОРИГИНАЛЬНАЯ ЛОГИКА ПОИСКА ЗОН
task.spawn(function()
    if getCfg("FarmSettings", "MegaFarm", true) then
        local zonePath = workspace.__THINGS.__INSTANCE_CONTAINER.Active:WaitForChild("EasterHatchEvent", 20):WaitForChild("BREAK_ZONES", 10):WaitForChild("7", 10)
        if zonePath then
            task.wait(3)
            root.CFrame = zonePath.CFrame * CFrame.new(0, 5, 0)
            if mainTxt then mainTxt.Text = "📍 Активация автофарма..." end
        end
    end
end)
-- [[ ЧАСТЬ 2: ФАРМ И ЛОГИКА ЗОН ]]
local ignoredZones = {} 
local testingTarget = nil 
local confirmedCount = 0 
local countdownStarted = false 

task.spawn(function()
    local Things = workspace:WaitForChild("__THINGS")
    local Breakables = Things:WaitForChild("Breakables")
    local Pets = Things:WaitForChild("Pets")
    local Orbs = Things:WaitForChild("Orbs")
    
    -- Ищем ивент ОДИН РАЗ перед циклом
    local EasterEvent = Things.__INSTANCE_CONTAINER.Active:WaitForChild("EasterHatchEvent", 30)
    local ZonesFolder = EasterEvent:WaitForChild("BREAK_ZONES", 10)

    if not ZonesFolder then 
        warn("!!! ЗОНЫ НЕ НАЙДЕНЫ, ПЕРЕЗАПУСТИ ИВЕНТ !!!")
        return 
    end

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

    while true do
        if getCfg("FarmSettings", "MegaFarm", true) then
            pcall(function()
                -- 1. Сбор сфер
                local orbIds = {}
                for _, o in pairs(Orbs:GetChildren()) do table.insert(orbIds, tonumber(o.Name)) o:Destroy() end
                if #orbIds > 0 then Net.Fire("Orbs: Collect", orbIds) end
                
                local petIds = {}
                for _, p in pairs(Pets:GetChildren()) do table.insert(petIds, p.Name) end
                local allTargets = Breakables:GetChildren()

                -- 2. ТВОЯ ПРОВЕРКА ЗОН
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
                                    confirmedCount = confirmedCount + 1
                                    if mainTxt then mainTxt.Text = "✅ Найдено зон: " .. confirmedCount .. "/4" end
                                    
                                    if confirmedCount >= 4 and not countdownStarted then
                                        countdownStarted = true
                                        task.spawn(function()
                                            for i = 10, 1, -1 do
                                                if mainTxt then mainTxt.Text = "🚀 Автофарм запущен! Закроюсь через " .. i end
                                                task.wait(1)
                                            end
                                            if statusGui then statusGui:Destroy() end
                                        end)
                                    end
                                end
                                testingTarget = nil
                            end)
                            break
                        end
                    end
                end

                -- 3. АТАКА ПЕТОВ
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

                if next(data) then Net.Fire("Breakables_JoinPetBulk", data) end
            end)
        end
        task.wait(0.2)
    end
end)

-- 3. TP HATCHING ZONE (Твой оригинальный возврат через 15 сек)
task.spawn(function()
    task.wait(15)
    -- Летим к яйцам только если AutoHatch включен
    if getCfg("EasterSettings", "AutoHatch", true) then
        pcall(function()
            local hatchZone = workspace.__THINGS.__INSTANCE_CONTAINER.Active.EasterHatchEvent["1 | Cloud Meadow"].INTERACT.HatchingZone
            if hatchZone then
                root.CFrame = hatchZone.CFrame
                print("[✓] Телепортирован в HatchingZone")
            end
        end)
    end
end)

-- ==========================================================
-- 3. АВТО-УДАЧА И МЕНЕДЖЕР АПГРЕЙДОВ
-- ==========================================================
task.spawn(function()
    local upgradeTracks = {"CooldownAndAmount", "HatchSpeed", "Luck", "ShinyLuck"}
    local boosts = { "Huge", "Titanic", "Gargantuan" }
    local tokenMapping = {
        ["Spring Bluebell Token"] = "Bluebell", ["Spring Red Tulip Token"] = "RedTulip",
        ["Spring Pink Rose Token"] = "PinkRose", ["Spring Yellow Sunflower Token"] = "Sunflower"
    }

    while true do
        if getCfg("EasterSettings", "AutoManager", true) then
            pcall(function()
                for _, track in ipairs(upgradeTracks) do
                    local upgradeId = "Easter2026Egg5" .. track 
                    repeat task.wait(0.1) until not Net.Invoke("EventUpgrades: Purchase", upgradeId)
                end
            end)
        end

        if getCfg("EasterSettings", "AutoLuck", true) then
            pcall(function()
                local inv = Save.Get().Inventory.Misc or {}
                local reserve = getCfg("EasterSettings", "TokenReserve", 5000)
                for _, item in pairs(inv) do
                    local key = tokenMapping[item.id]
                    if key and (item._am or 0) > reserve then
                        for _, bType in ipairs(boosts) do
                            Net.Invoke("Easter2026ChanceMachine_AddTime", bType, key, item._am)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
        task.wait(180)
    end
end)

-- ==========================================================
-- 4. АГРЕССИВНОЕ ОТКРЫТИЕ ЯИЦ (ФИНАЛ)
-- ==========================================================
task.spawn(function()
    task.wait(10)
    local eggRemote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_InvokeCustomFromClient")
    
    while true do
        if getCfg("EasterSettings", "AutoHatch", true) then
            local threads = getCfg("EasterSettings", "HatchThreads", 30)
            for i = 1, threads do
                task.spawn(function()
                    pcall(function()
                        eggRemote:InvokeServer("EasterHatchEvent", "HatchRequest")
                        if math.random() < 0.125 then
                            eggRemote:InvokeServer("EasterHatchEvent", "HatchRequest", math.random(1, 3))
                        end
                    end)
                end)
            end
        end
        task.wait(getCfg("EasterSettings", "HatchDelay", 0.01))
    end
end)

-- ==========================================================
-- 5. API АВТОФАРМА (ИСПРАВЛЕНО)
-- ==========================================================
task.spawn(function()
    while true do
        local wantEnabled = getCfg("FarmSettings", "AutoFarmAPI", true)
        if wantEnabled then
            if not AutoFarmCmds.IsEnabled() then pcall(function() AutoFarmCmds.Enable() end) end
        else
            if AutoFarmCmds.IsEnabled() then pcall(function() AutoFarmCmds.Disable() end) end
        end
        task.wait(1)
    end
end)
