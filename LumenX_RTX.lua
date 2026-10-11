--[[
    LumenX RTX Engine [UI Library Edition]
    Active Presets: Photorealism DSLR & Golden Hour Sunset
--]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Safe UI Parenting
local TargetParent = nil
if gethui then
    TargetParent = gethui()
elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
    TargetParent = game:GetService("CoreGui")
else
    TargetParent = LocalPlayer:WaitForChild("PlayerGui")
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 2
        })
    end)
end

-- Dedicated Effects Folder
local RTXFolder = Lighting:FindFirstChild("LumenX_RTX")
if not RTXFolder then
    RTXFolder = Instance.new("Folder")
    RTXFolder.Name = "LumenX_RTX"
    RTXFolder.Parent = Lighting
end

-- Game Defaults
local originalLighting = {
    Brightness = Lighting.Brightness,
    ExposureCompensation = Lighting.ExposureCompensation,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    ClockTime = Lighting.ClockTime,
    ShadowSoftness = Lighting.ShadowSoftness
}

-- Presets Data
local PRESETS = {
    Photorealism = {
        Brightness = 2.6,
        Exposure = 0.18,
        Ambient = Color3.fromRGB(12, 14, 20),
        OutdoorAmbient = Color3.fromRGB(40, 45, 55),
        ClockTime = 16.2,
        ShadowSoftness = 0.1,
        Bloom = { Intensity = 0.45, Size = 24, Threshold = 0.78 },
        CC = { Brightness = 0.03, Contrast = 0.38, Saturation = 0.22, Tint = Color3.fromRGB(255, 246, 235) },
        Atmosphere = { Density = 0.28, Offset = 0.4, Color = Color3.fromRGB(195, 175, 160), Glare = 0.55, Haze = 1.2 },
        SunRays = { Intensity = 0.25, Spread = 0.9 }
    },
    GoldenHour = {
        Brightness = 2.8,
        Exposure = 0.22,
        Ambient = Color3.fromRGB(25, 18, 15),
        OutdoorAmbient = Color3.fromRGB(75, 50, 40),
        ClockTime = 17.2,
        ShadowSoftness = 0.08,
        Bloom = { Intensity = 0.65, Size = 30, Threshold = 0.7 },
        CC = { Brightness = 0.04, Contrast = 0.42, Saturation = 0.35, Tint = Color3.fromRGB(255, 225, 190) },
        Atmosphere = { Density = 0.32, Offset = 0.5, Color = Color3.fromRGB(230, 160, 120), Glare = 0.85, Haze = 1.5 },
        SunRays = { Intensity = 0.38, Spread = 0.95 }
    }
}

-- Safe Sky Cleanup
local function clearCustomSky()
    local customSky = Lighting:FindFirstChild("RTX_CustomSky")
    if customSky then
        customSky:Destroy()
    end
end

-- Skybox Applier
local function applySkybox(skyData)
    clearCustomSky()
    local sky = Instance.new("Sky")
    sky.Name = "RTX_CustomSky"
    
    if type(skyData) == "string" then
        local asset = "rbxassetid://" .. skyData:gsub("%D", "")
        sky.SkyboxBk = asset; sky.SkyboxDn = asset; sky.SkyboxFt = asset
        sky.SkyboxLf = asset; sky.SkyboxRt = asset; sky.SkyboxUp = asset
    elseif type(skyData) == "table" then
        sky.SkyboxBk = skyData.Bk; sky.SkyboxDn = skyData.Dn; sky.SkyboxFt = skyData.Ft
        sky.SkyboxLf = skyData.Lf; sky.SkyboxRt = skyData.Rt; sky.SkyboxUp = skyData.Up
    end

    sky.Parent = Lighting
    notify("Skybox", "Applied Custom Skybox")
end

-- Engine Loader
local function loadPreset(presetName)
    local config = PRESETS[presetName] or PRESETS.Photorealism
    RTXFolder:ClearAllChildren()
    clearCustomSky()

    Lighting.GlobalShadows = true
    Lighting.Brightness = config.Brightness
    Lighting.ExposureCompensation = config.Exposure
    Lighting.Ambient = config.Ambient
    Lighting.OutdoorAmbient = config.OutdoorAmbient
    Lighting.ClockTime = config.ClockTime
    Lighting.ShadowSoftness = config.ShadowSoftness

    local cc = Instance.new("ColorCorrectionEffect", RTXFolder)
    cc.Name = "RTX_CC"
    cc.Brightness = config.CC.Brightness
    cc.Contrast = config.CC.Contrast
    cc.Saturation = config.CC.Saturation
    cc.TintColor = config.CC.Tint

    local bloom = Instance.new("BloomEffect", RTXFolder)
    bloom.Name = "RTX_Bloom"
    bloom.Intensity = config.Bloom.Intensity
    bloom.Size = config.Bloom.Size
    bloom.Threshold = config.Bloom.Threshold

    local atm = Instance.new("Atmosphere", RTXFolder)
    atm.Name = "RTX_Atmosphere"
    atm.Density = config.Atmosphere.Density
    atm.Offset = config.Atmosphere.Offset
    atm.Color = config.Atmosphere.Color
    atm.Glare = config.Atmosphere.Glare
    atm.Haze = config.Atmosphere.Haze

    if config.SunRays then
        local sun = Instance.new("SunRaysEffect", RTXFolder)
        sun.Name = "RTX_SunRays"
        sun.Intensity = config.SunRays.Intensity
        sun.Spread = config.SunRays.Spread
    end

    notify("LumenX Engine", "Loaded Preset: " .. presetName)
end

-- Tweak Functions
local dayNightConn = nil
local function toggleDayNightCycle()
    if dayNightConn then
        dayNightConn:Disconnect()
        dayNightConn = nil
        notify("Dynamic Cycle", "Day-Night Cycle: PAUSED")
    else
        dayNightConn = RunService.Heartbeat:Connect(function(dt)
            Lighting.ClockTime = (Lighting.ClockTime + (dt * 0.15)) % 24
        end)
        notify("Dynamic Cycle", "Day-Night Cycle: RUNNING")
    end
end

local contrastLevels = { 0.25, 0.40, 0.55 }
local contrastIdx = 1
local function cycleContrast()
    contrastIdx = (contrastIdx % #contrastLevels) + 1
    local cc = RTXFolder:FindFirstChild("RTX_CC")
    if cc then
        cc.Contrast = contrastLevels[contrastIdx]
        notify("Contrast", "Contrast Level: " .. tostring(contrastLevels[contrastIdx]))
    end
end

local lightsBoosted = false
local function boostWorkspaceLights()
    lightsBoosted = not lightsBoosted
    task.spawn(function()
        local count = 0
        local descendants = Workspace:GetDescendants()
        for i = 1, #descendants do
            local obj = descendants[i]
            if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                pcall(function()
                    if lightsBoosted then
                        obj.Brightness = obj.Brightness * 2.2
                        obj.Range = obj.Range * 1.5
                    else
                        obj.Brightness = obj.Brightness / 2.2
                        obj.Range = obj.Range / 1.5
                    end
                    count = count + 1
                end)
            end
        end
        notify("Light Booster", lightsBoosted and ("Boosted " .. tostring(count) .. " Lights") or "Restored Lights")
    end)
end

local function applyOceanWater()
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterColor = Color3.fromRGB(8, 75, 110)
            terrain.WaterTransparency = 0.4
            terrain.WaterReflectance = 1.0
            terrain.WaterWaveSize = 0.32
            terrain.WaterWaveSpeed = 20
        end
    end)
    notify("Water Engine", "Ocean Physics Applied")
end

local function resetLighting()
    if dayNightConn then
        dayNightConn:Disconnect()
        dayNightConn = nil
    end
    RTXFolder:ClearAllChildren()
    clearCustomSky()

    for prop, val in pairs(originalLighting) do
        pcall(function() Lighting[prop] = val end)
    end
    notify("LumenX Engine", "Restored Game Defaults")
end

-- Touch Drag Handler
local function makeDraggable(guiObject, handleObject)
    local handle = handleObject or guiObject
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- UI LIBRARY CONSTRUCTION
local uiName = "LumenX_UILibrary_UI"
if TargetParent:FindFirstChild(uiName) then
    TargetParent[uiName]:Destroy()
end

local sg = Instance.new("ScreenGui", TargetParent)
sg.Name = uiName
sg.ResetOnSpawn = false

-- Floating Toggle Button
local toggle = Instance.new("TextButton", sg)
toggle.Size = UDim2.new(0, 60, 0, 60)
toggle.Position = UDim2.new(0.05, 0, 0.3, 0)
toggle.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
toggle.Text = "LumenX\nRTX"
toggle.TextColor3 = Color3.fromRGB(0, 225, 255)
toggle.Font = Enum.Font.SourceSansBold
toggle.TextSize = 12
toggle.Active = true
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 14)
makeDraggable(toggle)

-- Main Library Window Frame
local mainWindow = Instance.new("Frame", sg)
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, 320, 0, 240)
mainWindow.Position = UDim2.new(0.05, 70, 0.3, 0)
mainWindow.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
mainWindow.Visible = false
mainWindow.ClipsDescendants = true
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 10)
makeDraggable(mainWindow)

-- Header Bar
local header = Instance.new("Frame", mainWindow)
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = Color3.fromRGB(24, 24, 32)

local headerTitle = Instance.new("TextLabel", header)
headerTitle.Size = UDim2.new(1, -10, 1, 0)
headerTitle.Position = UDim2.new(0, 10, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "LumenX RTX Engine (UI Edition)"
headerTitle.TextColor3 = Color3.fromRGB(0, 225, 255)
headerTitle.Font = Enum.Font.SourceSansBold
headerTitle.TextSize = 12
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
makeDraggable(mainWindow, header)

-- Left Sidebar Navigation
local sidebar = Instance.new("ScrollingFrame", mainWindow)
sidebar.Size = UDim2.new(0, 100, 1, -28)
sidebar.Position = UDim2.new(0, 0, 0, 28)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
sidebar.CanvasSize = UDim2.new(0, 0, 0, 220)
sidebar.ScrollBarThickness = 2

local sidebarLayout = Instance.new("UIListLayout", sidebar)
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local sidebarPadding = Instance.new("UIPadding", sidebar)
sidebarPadding.PaddingTop = UDim.new(0, 6)

-- Right Content Container
local contentContainer = Instance.new("Frame", mainWindow)
contentContainer.Size = UDim2.new(1, -100, 1, -28)
contentContainer.Position = UDim2.new(0, 100, 0, 28)
contentContainer.BackgroundTransparency = 1

local activeTab = nil
local activeTabBtn = nil

-- Create Tab Handler
local function createTab(tabName, icon, canvasHeight)
    local tabScroll = Instance.new("ScrollingFrame", contentContainer)
    tabScroll.Size = UDim2.new(1, 0, 1, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.Visible = false
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, canvasHeight or 220)
    tabScroll.ScrollBarThickness = 3

    local layout = Instance.new("UIListLayout", tabScroll)
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local pad = Instance.new("UIPadding", tabScroll)
    pad.PaddingTop = UDim.new(0, 6)

    -- Sidebar Tab Button
    local tabBtn = Instance.new("TextButton", sidebar)
    tabBtn.Size = UDim2.new(0, 90, 0, 28)
    tabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    tabBtn.Text = icon .. " " .. tabName
    tabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    tabBtn.Font = Enum.Font.SourceSansSemibold
    tabBtn.TextSize = 11
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

    local function selectThisTab()
        if activeTab then
            activeTab.Visible = false
        end
        if activeTabBtn then
            activeTabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            activeTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        end

        tabScroll.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 180)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

        activeTab = tabScroll
        activeTabBtn = tabBtn
    end

    tabBtn.MouseButton1Click:Connect(selectThisTab)

    return tabScroll, tabBtn, selectThisTab
end

-- Create Category Section Header Label
local function createSectionHeader(tabScroll, titleText)
    local label = Instance.new("TextLabel", tabScroll)
    label.Size = UDim2.new(0, 195, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = titleText
    label.TextColor3 = Color3.fromRGB(0, 225, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Center
    return label
end

-- Create Button Element
local function createTabButton(tabScroll, text, color, callback)
    local btn = Instance.new("TextButton", tabScroll)
    btn.Size = UDim2.new(0, 195, 0, 32)
    btn.BackgroundColor3 = color or Color3.fromRGB(32, 32, 44)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Create Info Card Element
local function createCard(tabScroll, titleText, descText)
    local card = Instance.new("Frame", tabScroll)
    card.Size = UDim2.new(0, 195, 0, 46)
    card.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local title = Instance.new("TextLabel", card)
    title.Size = UDim2.new(1, -10, 0, 18)
    title.Position = UDim2.new(0, 5, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(0, 225, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    local desc = Instance.new("TextLabel", card)
    desc.Size = UDim2.new(1, -10, 0, 20)
    desc.Position = UDim2.new(0, 5, 0, 20)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(180, 180, 190)
    desc.Font = Enum.Font.SourceSans
    desc.TextSize = 10
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left

    return card
end

-- BUILD ALL TABS
local presetsTab, pBtn, selectPresetsTab = createTab("Presets", "🎨", 180)
local lightingTab, lBtn = createTab("Lighting", "💡", 220)
local effectsTab, eBtn = createTab("Effects", "🌊", 220)
local updatesTab, uBtn = createTab("Updates", "📜", 180)
local creditsTab, cBtn = createTab("Credits", "👥", 240)
local systemTab, sBtn = createTab("System", "⚙️", 180)

-- 1. PRESETS TAB (Only Active Day Presets Included)
createSectionHeader(presetsTab, "☀️ Active Day Presets")
createTabButton(presetsTab, "📸 Photorealism DSLR", Color3.fromRGB(20, 80, 70), function() loadPreset("Photorealism") end)
createTabButton(presetsTab, "🌅 Golden Hour Sunset", Color3.fromRGB(90, 55, 20), function() loadPreset("GoldenHour") end)

-- 2. LIGHTING TAB
createTabButton(lightingTab, "🔄 Dynamic Day-Night", Color3.fromRGB(35, 60, 80), toggleDayNightCycle)
createTabButton(lightingTab, "🎨 Cycle Contrast Punch", Color3.fromRGB(50, 45, 65), cycleContrast)
createTabButton(lightingTab, "💡 Boost Lamp Glow", Color3.fromRGB(60, 50, 25), boostWorkspaceLights)

-- 3. EFFECTS TAB
createTabButton(effectsTab, "🌊 Enhance Ocean Water", Color3.fromRGB(20, 65, 90), applyOceanWater)

-- Custom Asset Textbox
local inputFrame = Instance.new("Frame", effectsTab)
inputFrame.Size = UDim2.new(0, 195, 0, 32)
inputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 6)

local textBox = Instance.new("TextBox", inputFrame)
textBox.Size = UDim2.new(1, -10, 1, 0)
textBox.Position = UDim2.new(0, 5, 0, 0)
textBox.BackgroundTransparency = 1
textBox.PlaceholderText = "Paste Sky Asset ID..."
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
textBox.Font = Enum.Font.SourceSans
textBox.TextSize = 11

textBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and textBox.Text ~= "" then
        applySkybox(textBox.Text)
    end
end)

-- 4. UPDATES TAB
createCard(updatesTab, "v1.0 Initial Release", "Official V1 UI Library release featuring Photorealism & Golden Hour presets.")
createCard(updatesTab, "Presets Available", "Photorealism & Golden Hour active.")
createCard(updatesTab, "Information.", "Cyberpunk & Ultra Night Shader Will Coming Soon!")

-- 5. CREDITS TAB
createCard(creditsTab, "Developer - Maxwell", "Scripted & Optimized for Mobile Executors (Delta, CodeX, Arceus X).")
createCard(creditsTab, "UI Design", "Custom UI Library with Sidebar Navigation & Section Labeling.")
createCard(creditsTab, "Compatibility", "Built using gethui() protection & thread-safe task.spawn loops.")

-- 6. SYSTEM TAB
createTabButton(systemTab, "🔴 Restore Game Defaults", Color3.fromRGB(90, 30, 30), resetLighting)

-- Open Default First Tab Safely
selectPresetsTab()

toggle.MouseButton1Click:Connect(function()
    mainWindow.Visible = not mainWindow.Visible
end)

-- Initialize Engine
loadPreset("Photorealism")
