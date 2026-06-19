-- ==========================================================
--              TSUM [BETA] - Полный скрипт
--              Баланс | ESP | Телепорт | Покупка
--                  Фон "Love is..." 800x214
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== НАСТРОЙКИ ====================
local Settings = {
    ESPEnabled = true,               -- Включить ESP
    TeleportEnabled = true,          -- Включить телепорт
    AutoBuyEnabled = false,          -- Автопокупка (отключи, чтобы не банили)
    LegendaryKeyword = "Legendary",  -- Ключевое слово для поиска
    UpdateInterval = 0.5,            -- Интервал обновления (сек)
    TeleportCooldown = 2,            -- Задержка между телепортами (сек)
    BuyCooldown = 3,                 -- Задержка между покупками (сек)
}

-- ==========================================================
--                  1. UI С ФОНОМ "Love is..."
-- ==========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoveIsUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Фоновое изображение (800x214)
local background = Instance.new("ImageLabel")
background.Size = UDim2.new(1, 0, 1, 0)     -- Растянуть на весь экран
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundTransparency = 1        -- Прозрачный фон (сама картинка)
background.ImageTransparency = 0             -- Картинка полностью видна
background.ZIndex = 0                        -- Самый нижний слой
-- ===== ВСТАВЬ СВОЙ ID КАРТИНКИ =====
-- background.Image = "rbxassetid://1234567890"   -- через Roblox
-- или внешняя ссылка (рискованно):
-- background.Image = "https://i.imgur.com/твой_код.jpg"
-- Если внешняя ссылка не грузится, используй rbxassetid
background.Image = "rbxassetid://1234567890"  -- ЗАМЕНИ НА СВОЙ ID
background.Parent = screenGui

-- Панель управления (полупрозрачная, чтобы фон был виден)
local uiFrame = Instance.new("Frame")
uiFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
uiFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
uiFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
uiFrame.BackgroundTransparency = 0.4          -- Прозрачность, чтобы видеть фон
uiFrame.BorderSizePixel = 2
uiFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
uiFrame.Active = true
uiFrame.Draggable = true
uiFrame.ZIndex = 1
uiFrame.Parent = screenGui

-- Заголовок "Love is..."
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Love is..."
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.BackgroundColor3 = Color3.fromRGB(0, 0, 0, 0.5)
title.Font = Enum.Font.GothamBold
title.TextSize = 30
title.TextScaled = false
title.ZIndex = 2
title.Parent = uiFrame

-- Информация о балансе (будет обновляться)
local balanceLabel = Instance.new("TextLabel")
balanceLabel.Size = UDim2.new(1, 0, 0, 30)
balanceLabel.Position = UDim2.new(0, 0, 0, 55)
balanceLabel.Text = "💰 Баланс: Загрузка..."
balanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
balanceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0, 0.3)
balanceLabel.Font = Enum.Font.Gotham
balanceLabel.TextSize = 18
balanceLabel.ZIndex = 2
balanceLabel.Parent = uiFrame

-- Кнопка закрытия UI
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 5)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 24
closeBtn.ZIndex = 2
closeBtn.Parent = uiFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Переключение видимости UI по Insert
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

-- ==========================================================
--                  2. ОСНОВНЫЕ ФУНКЦИИ
-- ==========================================================

-- 2.1 Получение баланса
local function getBalance()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Coins")
        if cash then
            return cash.Value
        end
    end
    -- Попытка через RemoteFunction
    local remote = ReplicatedStorage:FindFirstChild("GetBalance")
    if remote and remote:IsA("RemoteFunction") then
        local success, result = pcall(function()
            return remote:InvokeServer()
        end)
        if success then return result end
    end
    return nil
end

-- 2.2 Поиск легендарок в стоке
local function findLegendaryInStock()
    local legendaries = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and string.find(obj.Name, Settings.LegendaryKeyword) then
            table.insert(legendaries, obj)
        end
    end
    return legendaries
end

-- 2.3 ESP (подсветка)
local espObjects = {}

local function createESP(item)
    if espObjects[item] then return end
    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(255, 215, 0)
    box.Thickness = 2
    box.Filled = false
    box.Visible = true
    
    local text = Drawing.new("Text")
    text.Text = item.Name
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Visible = true
    
    espObjects[item] = { box = box, text = text }
end

local function updateESP()
    if not Settings.ESPEnabled then
        for _, esp in pairs(espObjects) do
            esp.box.Visible = false
            esp.text.Visible = false
        end
        return
    end
    
    local items = findLegendaryInStock()
    local currentItems = {}
    
    for _, item in pairs(items) do
        local pos = item:GetPivot().Position
        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
        
        if onScreen then
            createESP(item)
            local esp = espObjects[item]
            local distance = (LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position - pos).Magnitude
            esp.text.Text = string.format("%s [%.0fm]", item.Name, distance)
            esp.text.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
            esp.text.Visible = true
            
            local size = 3
            esp.box.Size = Vector2.new(size * 20, size * 30)
            esp.box.Position = Vector2.new(screenPos.X - size * 10, screenPos.Y - size * 15)
            esp.box.Visible = true
            
            currentItems[item] = true
        end
    end
    
    for item, esp in pairs(espObjects) do
        if not currentItems[item] then
            esp.box.Visible = false
            esp.text.Visible = false
        end
    end
end

-- 2.4 Телепорт к легендарке (с задержкой)
local lastTeleportTime = 0
local function teleportToItem(item)
    if not Settings.TeleportEnabled then return end
    local now = tick()
    if now - lastTeleportTime < Settings.TeleportCooldown then
        print("⏳ Подожди " .. Settings.TeleportCooldown .. " сек перед следующим телепортом")
        return
    end
    if not LocalPlayer.Character then return end
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local targetPos = item:GetPivot().Position
    humanoidRootPart.CFrame = CFrame.new(targetPos)
    lastTeleportTime = now
    print("🚀 Телепорт к:", item.Name)
end

-- 2.5 Покупка легендарки (с задержкой)
local lastBuyTime = 0
local function buyLegendary(item)
    local now = tick()
    if now - lastBuyTime < Settings.BuyCooldown then
        print("⏳ Подожди " .. Settings.BuyCooldown .. " сек перед следующей покупкой")
        return
    end
    
    -- Пытаемся найти Remote
    local remote = ReplicatedStorage:FindFirstChild("BuyItem")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(item)
        lastBuyTime = now
        print("🛒 Покупка отправлена:", item.Name)
        return
    elseif remote and remote:IsA("RemoteFunction") then
        remote:InvokeServer(item)
        lastBuyTime = now
        print("🛒 Покупка отправлена:", item.Name)
        return
    end
    
    -- Если Remote не найден, пробуем ClickDetector
    local clickDetector = item:FindFirstChild("ClickDetector")
    if clickDetector then
        fireclickdetector(clickDetector)
        lastBuyTime = now
        print("🛒 Покупка через клик:", item.Name)
    else
        print("❌ Не удалось купить, нет Remote или ClickDetector")
    end
end

-- ==========================================================
--                  3. ГЛАВНЫЙ ЦИКЛ
-- ==========================================================
local function mainLoop()
    -- Баланс
    local balance = getBalance()
    if balance then
        balanceLabel.Text = "💰 Баланс: " .. balance
    else
        balanceLabel.Text = "💰 Баланс: Не найден"
    end
    
    -- Поиск легендарок
    local legendaries = findLegendaryInStock()
    if #legendaries > 0 then
        -- Можно вывести в консоль
        -- print("🔍 Найдено легендарок:", #legendaries)
    end
end

-- Запускаем обновление ESP каждый кадр
RunService.RenderStepped:Connect(updateESP)

-- Запускаем основной цикл с задержкой
spawn(function()
    while task.wait(Settings.UpdateInterval) do
        mainLoop()
    end
end)

-- ==========================================================
--                  4. ГОРЯЧИЕ КЛАВИШИ
-- ==========================================================
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Клавиша E: телепорт к ближайшей легендарке
    if input.KeyCode == Enum.KeyCode.E then
        local legendaries = findLegendaryInStock()
        if #legendaries > 0 then
            teleportToItem(legendaries[1])
        else
            print("❌ Легендарок не найдено для телепорта")
        end
    end
    
    -- Клавиша Q: покупка ближайшей легендарки
    if input.KeyCode == Enum.KeyCode.Q then
        local legendaries = findLegendaryInStock()
        if #legendaries > 0 then
            buyLegendary(legendaries[1])
        else
            print("❌ Легендарок не найдено для покупки")
        end
    end
end)

-- ==========================================================
--                  5. ЗАВЕРШЕНИЕ
-- ==========================================================
print("✅ Скрипт 'Love is...' загружен!")
print("🔹 E - Телепорт к легендарке")
print("🔹 Q - Купить легендарку")
print("🔹 Insert - Скрыть/показать UI")