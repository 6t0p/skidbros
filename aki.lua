-- ═══════════════════════════════════════════════════════════════════════════════
--  SKID HUB - 99 Nights in the Forest Edition
--  Migrated UI Architecture from Skid-Hub.lua + Feature Logic from fine.lua
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════════════════════
local CONFIG = {
    VERSION = "1.0.0",
    TITLE = "Skid Hub",
    DISCORD = "https://discord.gg/tJg2vfWEz6",
    VALID_KEY = "mommy",
    -- LOGO PLACEHOLDER - Replace with actual asset ID when available
    LOGO = "PLACEHOLDER", -- Set to rbxassetid://YOUR_LOGO_ID_HERE
    FOLDER = "SkidHub/99Nights",
    WINDOW_SIZE = {640, 380},
    SIDEBAR_WIDTH = 210,
}

-- ═══════════════════════════════════════════════════════════════════════════════
--  DEPENDENCIES
-- ═══════════════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════════════════
--  GRADIENT HELPER (from Skid-Hub)
-- ═══════════════════════════════════════════════════════════════════════════════
local function gradient(t)
    local r = ""
    local c = {
        Color3.fromRGB(120, 220, 255),
        Color3.fromRGB(70, 180, 255),
        Color3.fromRGB(0, 140, 255),
        Color3.fromRGB(0, 100, 255),
        Color3.fromRGB(80, 120, 255),
    }
    local clean = t:gsub("[^%w]", "")
    local len = #clean
    local index = 1
    for i = 1, #t do
        local ch = t:sub(i, i)
        if ch:match("[%w]") then
            local x = (index - 1) / math.max(len - 1, 1)
            local pos = x * (#c - 1)
            local low = math.clamp(math.floor(pos) + 1, 1, #c)
            local high = math.clamp(low + 1, 1, #c)
            local c1, c2 = c[low], c[high]
            local blend = pos % 1
            local rR = c1.R + (c2.R - c1.R) * blend
            local rG = c1.G + (c2.G - c1.G) * blend
            local rB = c1.B + (c2.B - c1.B) * blend
            r = r .. string.format(
                '<font color="rgb(%d,%d,%d)">%s</font>',
                math.floor(rR * 255), math.floor(rG * 255), math.floor(rB * 255), ch
            )
            index = index + 1
        else
            r = r .. ch
        end
    end
    return r
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  AUTHENTICATION / KEY SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════
local function InitializeKeySystem(callback)
    local old = PlayerGui:FindFirstChild("SkidHubKeySystem")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SkidHubKeySystem"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromHex("#0A0515")
    overlay.BackgroundTransparency = 0.45
    overlay.BorderSizePixel = 0
    overlay.Parent = gui

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(380, 220)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromHex("#110820")
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.Parent = overlay

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 16)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromHex("#8844DD")
    cardStroke.Transparency = 0.3
    cardStroke.Thickness = 2
    cardStroke.Parent = card

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#1B8FFF")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#CC44FF")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#1B8FFF")),
    })
    strokeGradient.Rotation = 0
    strokeGradient.Parent = cardStroke

    task.spawn(function()
        local rot = 0
        while card and card.Parent do
            rot = (rot + 2) % 360
            strokeGradient.Rotation = rot
            task.wait(0.03)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 32)
    title.Position = UDim2.fromOffset(20, 20)
    title.BackgroundTransparency = 1
    title.Text = gradient("Skid Hub")
    title.TextColor3 = Color3.fromHex("#F0E8FF")
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.RichText = true
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.fromOffset(20, 52)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your key to continue"
    subtitle.TextColor3 = Color3.fromHex("#9B72CC")
    subtitle.TextSize = 13
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = card

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -40, 0, 44)
    input.Position = UDim2.fromOffset(20, 80)
    input.BackgroundColor3 = Color3.fromHex("#1A1229")
    input.BackgroundTransparency = 0.2
    input.BorderSizePixel = 0
    input.Text = ""
    input.PlaceholderText = "Enter key..."
    input.PlaceholderColor3 = Color3.fromHex("#6D28D9")
    input.TextColor3 = Color3.fromHex("#F0E8FF")
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.Parent = card

    local inputPadding = Instance.new("UIPadding")
    inputPadding.PaddingLeft = UDim.new(0, 15)
    inputPadding.Parent = input

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 10)
    inputCorner.Parent = input

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromHex("#2A1040")
    inputStroke.Transparency = 0.5
    inputStroke.Thickness = 1
    inputStroke.Parent = input

    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -40, 0, 42)
    buttonContainer.Position = UDim2.fromOffset(20, 135)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = card

    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonContainer

    local checkBtn = Instance.new("TextButton")
    checkBtn.Name = "CheckKey"
    checkBtn.Size = UDim2.new(0.5, -5, 1, 0)
    checkBtn.BackgroundColor3 = Color3.fromHex("#8844DD")
    checkBtn.BackgroundTransparency = 0.2
    checkBtn.BorderSizePixel = 0
    checkBtn.Text = "Check Key"
    checkBtn.TextColor3 = Color3.fromHex("#FFFFFF")
    checkBtn.TextSize = 14
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.AutoButtonColor = false
    checkBtn.Parent = buttonContainer

    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 10)
    checkCorner.Parent = checkBtn

    local checkGradient = Instance.new("UIGradient")
    checkGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#8844DD")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#6622BB")),
    })
    checkGradient.Parent = checkBtn

    local getBtn = Instance.new("TextButton")
    getBtn.Name = "GetKey"
    getBtn.Size = UDim2.new(0.5, -5, 1, 0)
    getBtn.BackgroundColor3 = Color3.fromHex("#2A1040")
    getBtn.BackgroundTransparency = 0.3
    getBtn.BorderSizePixel = 0
    getBtn.Text = "Get Key"
    getBtn.TextColor3 = Color3.fromHex("#9B72CC")
    getBtn.TextSize = 14
    getBtn.Font = Enum.Font.GothamBold
    getBtn.AutoButtonColor = false
    getBtn.Parent = buttonContainer

    local getCorner = Instance.new("UICorner")
    getCorner.CornerRadius = UDim.new(0, 10)
    getCorner.Parent = getBtn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.fromOffset(20, 185)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromHex("#9B72CC")
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Parent = card

    local toastHolder = Instance.new("Frame")
    toastHolder.Name = "Notifications"
    toastHolder.Size = UDim2.fromOffset(300, 100)
    toastHolder.Position = UDim2.new(0.5, 0, 1, -20)
    toastHolder.AnchorPoint = Vector2.new(0.5, 1)
    toastHolder.BackgroundTransparency = 1
    toastHolder.Parent = gui

    local toastLayout = Instance.new("UIListLayout")
    toastLayout.Padding = UDim.new(0, 8)
    toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.Parent = toastHolder

    local function showToast(titleText, messageText, duration)
        local toast = Instance.new("Frame")
        toast.Size = UDim2.new(1, 0, 0, 60)
        toast.BackgroundColor3 = Color3.fromHex("#110820")
        toast.BackgroundTransparency = 0.1
        toast.BorderSizePixel = 0
        toast.Parent = toastHolder

        local toastCorner = Instance.new("UICorner")
        toastCorner.CornerRadius = UDim.new(0, 8)
        toastCorner.Parent = toast

        local toastStroke = Instance.new("UIStroke")
        toastStroke.Color = Color3.fromHex("#8844DD")
        toastStroke.Transparency = 0.5
        toastStroke.Thickness = 1
        toastStroke.Parent = toast

        local toastTitle = Instance.new("TextLabel")
        toastTitle.Size = UDim2.new(1, -20, 0, 24)
        toastTitle.Position = UDim2.fromOffset(10, 8)
        toastTitle.BackgroundTransparency = 1
        toastTitle.Text = titleText
        toastTitle.TextColor3 = Color3.fromHex("#F0E8FF")
        toastTitle.TextSize = 16
        toastTitle.Font = Enum.Font.GothamBold
        toastTitle.Parent = toast

        local toastMsg = Instance.new("TextLabel")
        toastMsg.Size = UDim2.new(1, -20, 0, 20)
        toastMsg.Position = UDim2.fromOffset(10, 32)
        toastMsg.BackgroundTransparency = 1
        toastMsg.Text = messageText
        toastMsg.TextColor3 = Color3.fromHex("#9B72CC")
        toastMsg.TextSize = 13
        toastMsg.Font = Enum.Font.Gotham
        toastMsg.Parent = toast

        toast.Position = UDim2.new(0, 0, 0, 10)
        toast.BackgroundTransparency = 1
        toastTitle.TextTransparency = 1
        toastMsg.TextTransparency = 1

        TweenService:Create(toast, TweenInfo.new(0.2), {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0.1
        }):Play()
        TweenService:Create(toastTitle, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        TweenService:Create(toastMsg, TweenInfo.new(0.2), {TextTransparency = 0}):Play()

        task.delay(duration or 2, function()
            if not toast.Parent then return end
            local fade = TweenInfo.new(0.2)
            TweenService:Create(toast, fade, {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 10)}):Play()
            TweenService:Create(toastTitle, fade, {TextTransparency = 1}):Play()
            TweenService:Create(toastMsg, fade, {TextTransparency = 1}):Play()
            task.wait(0.2)
            if toast.Parent then toast:Destroy() end
        end)
    end

    local function tween(obj, props)
        TweenService:Create(obj, TweenInfo.new(0.14), props):Play()
    end

    checkBtn.MouseEnter:Connect(function() tween(checkBtn, {BackgroundTransparency = 0}) end)
    checkBtn.MouseLeave:Connect(function() tween(checkBtn, {BackgroundTransparency = 0.2}) end)
    getBtn.MouseEnter:Connect(function() tween(getBtn, {BackgroundTransparency = 0.1}) end)
    getBtn.MouseLeave:Connect(function() tween(getBtn, {BackgroundTransparency = 0.3}) end)

    input.Focused:Connect(function()
        tween(inputStroke, {Color = Color3.fromHex("#8844DD"), Transparency = 0.2})
    end)
    input.FocusLost:Connect(function()
        tween(inputStroke, {Color = Color3.fromHex("#2A1040"), Transparency = 0.5})
    end)

    local function verifyKey()
        if input.Text == CONFIG.VALID_KEY then
            status.TextColor3 = Color3.fromHex("#00CC66")
            status.Text = "Key verified!"
            showToast("Success", "Key verified! Loading...", 1.5)
            
            task.wait(0.5)
            
            local fadeOut = TweenInfo.new(0.3)
            TweenService:Create(card, fadeOut, {BackgroundTransparency = 1}):Play()
            TweenService:Create(overlay, fadeOut, {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            
            gui:Destroy()
            callback()
        else
            status.TextColor3 = Color3.fromHex("#FF4444")
            status.Text = "Invalid key."
            showToast("Error", "Invalid key.", 1.5)
        end
    end

    checkBtn.MouseButton1Click:Connect(verifyKey)
    input.FocusLost:Connect(function(enterPressed) if enterPressed then verifyKey() end end)

    getBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(CONFIG.DISCORD)
            status.TextColor3 = Color3.fromHex("#00CC66")
            status.Text = "Discord invite copied!"
            showToast("Copied", "Discord invite copied!", 1.5)
        end
    end)

    card.Size = UDim2.fromOffset(360, 200)
    card.BackgroundTransparency = 1
    tween(card, {Size = UDim2.fromOffset(380, 220), BackgroundTransparency = 0.1})
    
    input:CaptureFocus()
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  LOADING SCREEN
-- ═══════════════════════════════════════════════════════════════════════════════
local function ShowLoadingScreen(callback)
    local TS = TweenService
    local loadGui = Instance.new("ScreenGui")
    loadGui.Name = "SkidHubLoader"
    loadGui.ResetOnSpawn = false
    loadGui.DisplayOrder = 99999
    loadGui.IgnoreGuiInset = true
    loadGui.Parent = PlayerGui

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1
    overlay.Parent = loadGui

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 340, 0, 110)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.58, 0)
    card.BackgroundColor3 = Color3.fromHex("#07101A")
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = loadGui
    
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cardStroke.Thickness = 2
    cardStroke.Transparency = 1
    cardStroke.Parent = card

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#1B8FFF")),
        ColorSequenceKeypoint.new(0.33, Color3.fromHex("#78DCFF")),
        ColorSequenceKeypoint.new(0.66, Color3.fromHex("#CC44FF")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#1B8FFF")),
    })
    strokeGrad.Rotation = 0
    strokeGrad.Parent = cardStroke

    task.spawn(function()
        local a = 0
        while loadGui.Parent do
            a = (a + 2) % 360
            strokeGrad.Rotation = a
            task.wait(0.03)
        end
    end)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 28)
    titleLbl.Position = UDim2.new(0, 10, 0, 10)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = gradient("Skid Hub")
    titleLbl.TextColor3 = Color3.fromHex("#78DCFF")
    titleLbl.TextSize = 16
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.RichText = true
    titleLbl.ZIndex = 3
    titleLbl.Parent = card

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -20, 0, 18)
    statusLbl.Position = UDim2.new(0, 10, 0, 36)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Starting..."
    statusLbl.TextColor3 = Color3.fromHex("#8ABBEA")
    statusLbl.TextSize = 12
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.ZIndex = 3
    statusLbl.Parent = card

    local barTrack = Instance.new("Frame")
    barTrack.Size = UDim2.new(1, -20, 0, 8)
    barTrack.Position = UDim2.new(0, 10, 0, 62)
    barTrack.BackgroundColor3 = Color3.fromHex("#0D1E2F")
    barTrack.BorderSizePixel = 0
    barTrack.ZIndex = 3
    barTrack.Parent = card
    Instance.new("UICorner", barTrack).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromHex("#1B8FFF")
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 4
    barFill.Parent = barTrack
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#1B8FFF")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#78DCFF")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#CC44FF")),
    })
    fillGrad.Parent = barFill

    local pctLbl = Instance.new("TextLabel")
    pctLbl.Size = UDim2.new(1, -20, 0, 18)
    pctLbl.Position = UDim2.new(0, 10, 0, 76)
    pctLbl.BackgroundTransparency = 1
    pctLbl.Text = "0%"
    pctLbl.TextColor3 = Color3.fromHex("#78DCFF")
    pctLbl.TextSize = 11
    pctLbl.Font = Enum.Font.GothamBold
    pctLbl.TextXAlignment = Enum.TextXAlignment.Right
    pctLbl.ZIndex = 3
    pctLbl.Parent = card

    TS:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.55}):Play()
    TS:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0
    }):Play()
    TS:Create(cardStroke, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {Transparency = 0}):Play()

    local function setProgress(pct, status, speed)
        local dur = speed or 0.3
        statusLbl.Text = status
        pctLbl.Text = math.floor(pct * 100) .. "%"
        TS:Create(barFill, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
        }):Play()
    end

    task.spawn(function()
        setProgress(0.08, "Connecting...", 0.2)
        local pingStart = os.clock()
        local pingDone = false
        
        task.spawn(function()
            pcall(function()
                game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua", true)
            end)
            pingDone = true
        end)

        local animated = 0.08
        repeat
            task.wait(0.05)
            animated = math.min(animated + 0.012, 0.30)
            setProgress(animated, "Measuring connection...", 0.12)
        until pingDone

        local pingTime = math.clamp(os.clock() - pingStart, 0.05, 5)
        local fillSpeed = math.clamp(pingTime * 0.35, 0.15, 1.8)
        local quality = pingTime < 0.3 and "Fast" or pingTime < 1.0 and "Good" or "Slow"

        setProgress(0.35, "Connection: " .. quality .. " (" .. math.floor(pingTime * 1000) .. "ms)", fillSpeed * 0.5)
        task.wait(fillSpeed * 0.4)
        setProgress(0.55, "Loading services...", fillSpeed * 0.6)
        task.wait(fillSpeed * 0.3)
        setProgress(0.72, "Building hub...", fillSpeed * 0.5)
        task.wait(fillSpeed * 0.25)
        setProgress(0.88, "Finalizing...", fillSpeed * 0.4)
        task.wait(fillSpeed * 0.2)
        setProgress(1.0, "Ready!", 0.25)
        task.wait(0.35)

        TS:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0.44, 0),
            BackgroundTransparency = 1
        }):Play()
        TS:Create(cardStroke, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Transparency = 1}):Play()
        TS:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        loadGui:Destroy()
        callback()
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  MAIN UI
-- ═══════════════════════════════════════════════════════════════════════════════
local function InitializeMainUI()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.54/main.lua"))()
    end)

    if not success then
        warn("Failed to load WindUI:", WindUI)
        return
    end

    pcall(function()
        WindUI:AddTheme({
            Name = "Skid Hub Purple",
            Dialog = Color3.fromHex("#110820"),
            Outline = Color3.fromHex("#2A1040"),
            Text = Color3.fromHex("#F0E8FF"),
            Placeholder = Color3.fromHex("#9B72CC"),
            Background = Color3.fromHex("#0A0515"),
            Button = Color3.fromHex("#8844DD"),
            Icon = WindUI:Gradient({
                ["0"] = { Color = Color3.fromHex("#CC88FF"), Transparency = 0 },
                ["25"] = { Color = Color3.fromHex("#AA55EE"), Transparency = 0 },
                ["50"] = { Color = Color3.fromHex("#8844DD"), Transparency = 0 },
                ["75"] = { Color = Color3.fromHex("#6622BB"), Transparency = 0 },
                ["100"] = { Color = Color3.fromHex("#5078FF"), Transparency = 0 },
            }, { Rotation = 20 })
        })
    end)

    local Window = WindUI:CreateWindow({
        Title = gradient("Skid Hub"),
        Author = "Skid Hub Developments",
        Icon = CONFIG.LOGO ~= "PLACEHOLDER" and CONFIG.LOGO or "snowflake",
        Folder = CONFIG.FOLDER,
        Size = UDim2.fromOffset(CONFIG.WINDOW_SIZE[1], CONFIG.WINDOW_SIZE[2]),
        Transparent = true,
        Resizable = true,
        Theme = "Skid Hub Purple",
        SideBarWidth = CONFIG.SIDEBAR_WIDTH,
        Background = "rbxassetid://124138067839032",
        BackgroundTransparency = 0.65,
        HideSearchBar = false,
        ScrollBarEnabled = true,
    })

    if not Window then
        warn("[Skid Hub] Window failed to create.")
        return
    end

    pcall(function() Window:SetBackgroundImageTransparency(0.65) end)

    pcall(function()
        Window:Tag({
            Title = "v" .. CONFIG.VERSION,
            Color = WindUI:Gradient({
                ["0"] = { Color = Color3.fromHex("#1B8FFF"), Transparency = 0 },
                ["100"] = { Color = Color3.fromHex("#78DCFF"), Transparency = 0 },
            }, { Rotation = 45 }),
            Radius = 13,
        })
    end)

    pcall(function()
        Window:Tag({
            Title = "Freemium",
            Color = WindUI:Gradient({
                ["0"] = { Color = Color3.fromHex("#00CC66"), Transparency = 0 },
                ["100"] = { Color = Color3.fromHex("#AAFF44"), Transparency = 0 },
            }, { Rotation = 45 }),
            Radius = 13,
        })
    end)

    pcall(function()
        Window:EditOpenButton({
            Title = "Skid Hub",
            CornerRadius = UDim.new(0, 16),
            StrokeThickness = 2,
            Color = ColorSequence.new(Color3.fromHex("#1B8FFF"), Color3.fromHex("#78DCFF")),
            OnlyMobile = false,
            Enabled = true,
            Draggable = true,
        })
    end)

    local bgVisible = true
    pcall(function()
        Window:AddTopbarButton({
            Icon = "eye",
            Callback = function()
                bgVisible = not bgVisible
                pcall(function()
                    Window:SetBackgroundImageTransparency(bgVisible and 0.65 or 1)
                end)
            end,
        })
    end)

    local function notify(text)
        WindUI:Notify({ Title = "Skid Hub", Content = text, Duration = 3 })
    end

    -- ══════════════════════════════════════════
    --  FEATURE VARIABLES
    -- ═════════════════════════════════════════=
    local killAuraToggle = false
    local chopAuraToggle = false
    local auraRadius = 50
    local currentammount = 0

    local toolsDamageIDs = {
        ["Old Axe"] = "3_7367831688",
        ["Good Axe"] = "112_7367831688",
        ["Strong Axe"] = "116_7367831688",
        ["Chainsaw"] = "647_8992824875",
        ["Spear"] = "196_8999010016"
    }

    local autoFeedToggle = false
    local selectedFood = {}
    local hungerThreshold = 75
    local alimentos = {"Apple", "Berry", "Carrot", "Cake", "Chili", "Cooked Morsel", "Cooked Steak"}

    local ie = {"Bandage", "Bolt", "Broken Fan", "Broken Microwave", "Cake", "Carrot", "Chair", "Coal", "Coin Stack",
        "Cooked Morsel", "Cooked Steak", "Fuel Canister", "Iron Body", "Leather Armor", "Log", "MadKit", "Metal Chair",
        "MedKit", "Old Car Engine", "Old Flashlight", "Old Radio", "Revolver", "Revolver Ammo", "Rifle", "Rifle Ammo",
        "Morsel", "Sheet Metal", "Steak", "Tyre", "Washing Machine"}
    local me = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist", "Crossbow Cultist", "Alien"}

    local junkItems = {"Tyre", "Bolt", "Broken Fan", "Broken Microwave", "Sheet Metal", "Old Radio", "Washing Machine", "Old Car Engine"}
    local selectedJunkItems = {}
    local fuelItems = {"Log", "Chair", "Coal", "Fuel Canister", "Oil Barrel"}
    local selectedFuelItems = {}
    local foodItems = {"Cake", "Cooked Steak", "Cooked Morsel", "Steak", "Morsel", "Berry", "Carrot"}
    local selectedFoodItems = {}
    local medicalItems = {"Bandage", "MedKit"}
    local selectedMedicalItems = {}
    local equipmentItems = {"Revolver", "Rifle", "Leather Body", "Iron Body", "Revolver Ammo", "Rifle Ammo", "Giant Sack", "Good Sack", "Strong Axe", "Good Axe"}
    local selectedEquipmentItems = {}

    local isCollecting = false
    local originalPosition = nil
    local junkToggleEnabled = false
    local fuelToggleEnabled = false
    local foodToggleEnabled = false
    local medicalToggleEnabled = false
    local equipmentToggleEnabled = false
    local junkLoopRunning = false
    local fuelLoopRunning = false
    local foodLoopRunning = false
    local medicalLoopRunning = false
    local equipmentLoopRunning = false

    local campfireFuelItems = {"Log", "Coal", "Chair", "Fuel Canister", "Oil Barrel", "Biofuel"}
    local campfireDropPos = Vector3.new(0, 19, 0)
    local selectedCampfireItem = nil
    local autoUpgradeCampfireEnabled = false

    local scrapjunkItems = {"Log", "Chair", "Tyre", "Bolt", "Broken Fan", "Broken Microwave", "Sheet Metal", "Old Radio", "Washing Machine", "Old Car Engine"}
    local autoScrapPos = Vector3.new(21, 20, -5)
    local selectedScrapItem = nil
    local autoScrapItemsEnabled = false

    local autocookItems = {"Morsel", "Steak", "Elvis Steak"}
    local autoCookEnabledItems = {}
    local autoCookEnabled = false

    local flyToggle = false
    local flySpeed = 1
    local FLYING = false
    local flyKeyDown, flyKeyUp, mfly1, mfly2

    local selectedItems = {}
    local selectedMobs = {}
    local espItemsEnabled = false
    local espMobsEnabled = false
    local espConnections = {}

    local instantInteractEnabled = false
    local instantInteractConnection
    local originalHoldDurations = {}
    local torchLoop = nil
    local noclipConnection = nil
    local infJumpConnection = nil

    -- ══════════════════════════════════════════
    --  UTILITY FUNCTIONS
    -- ═════════════════════════════════════════=
    local function getAnyToolWithDamageID(isChopAura)
        for toolName, damageID in pairs(toolsDamageIDs) do
            if isChopAura and toolName ~= "Old Axe" and toolName ~= "Good Axe" and toolName ~= "Strong Axe" then
                continue
            end
            local tool = LP:FindFirstChild("Inventory") and LP.Inventory:FindFirstChild(toolName)
            if tool then
                return tool, damageID
            end
        end
        return nil, nil
    end

    local function equipTool(tool)
        if tool then
            ReplicatedStorage:WaitForChild("RemoteEvents").EquipItemHandle:FireServer("FireAllClients", tool)
        end
    end

    local function unequipTool(tool)
        if tool then
            ReplicatedStorage:WaitForChild("RemoteEvents").UnequipItemHandle:FireServer("FireAllClients", tool)
        end
    end

    function wiki(nome)
        local c = 0
        for _, i in ipairs(Workspace.Items:GetChildren()) do
            if i.Name == nome then
                c = c + 1
            end
        end
        return c
    end

    function ghn()
        return math.floor(LP.PlayerGui.Interface.StatBars.HungerBar.Bar.Size.X.Scale * 100)
    end

    function feed(nome)
        for _, item in ipairs(Workspace.Items:GetChildren()) do
            if item.Name == nome then
                ReplicatedStorage.RemoteEvents.RequestConsumeItem:InvokeServer(item)
                break
            end
        end
    end

    local function moveItemToPos(item, position)
        if not item or not item:IsDescendantOf(workspace) or (not item:IsA("BasePart") and not item:IsA("Model")) then return end
        local part = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")) or item
        if not part or not part:IsA("BasePart") then return end

        if item:IsA("Model") and not item.PrimaryPart then
            pcall(function() item.PrimaryPart = part end)
        end

        pcall(function()
            ReplicatedStorage:WaitForChild("RemoteEvents").RequestStartDraggingItem:FireServer(item)
            if item:IsA("Model") then
                item:SetPrimaryPartCFrame(CFrame.new(position))
            else
                part.CFrame = CFrame.new(position)
            end
            ReplicatedStorage:WaitForChild("RemoteEvents").StopDraggingItem:FireServer(item)
        end)
    end

    local function getChests()
        local chests = {}
        local chestNames = {}
        local index = 1
        for _, item in ipairs(workspace:WaitForChild("Items"):GetChildren()) do
            if item.Name:match("^Item Chest") and not item:GetAttribute("8721081708ed") then
                table.insert(chests, item)
                table.insert(chestNames, "Chest " .. index)
                index = index + 1
            end
        end
        return chests, chestNames
    end

    local function getMobs()
        local mobs = {}
        local mobNames = {}
        local index = 1
        for _, character in ipairs(workspace:WaitForChild("Characters"):GetChildren()) do
            if character.Name:match("^Lost Child") and character:GetAttribute("Lost") == true then
                table.insert(mobs, character)
                table.insert(mobNames, character.Name)
                index = index + 1
            end
        end
        return mobs, mobNames
    end

    function tp1()
        local char = LP.Character or LP.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(0.43132782, 15.77634621, -1.88620758, -0.270917892, 0.102997094, 0.957076371, 0.639657021, 0.762253821, 0.0990355015, -0.719334781, 0.639031112, -0.272391081)
    end

    local function tp2()
        local targetPart = workspace:FindFirstChild("Map")
            and workspace.Map:FindFirstChild("Landmarks")
            and workspace.Map.Landmarks:FindFirstChild("Stronghold")
            and workspace.Map.Landmarks.Stronghold:FindFirstChild("Functional")
            and workspace.Map.Landmarks.Stronghold.Functional:FindFirstChild("EntryDoors")
            and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors:FindFirstChild("DoorRight")
            and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors.DoorRight:FindFirstChild("Model")
        if targetPart then
            local children = targetPart:GetChildren()
            local destination = children[5]
            if destination and destination:IsA("BasePart") then
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = destination.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
    end

    local function smoothPullToItem(startPos, endPos, duration)
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local startTime = tick()
        
        spawn(function()
            while tick() - startTime < duration do
                if not hrp or not hrp.Parent then break end
                local elapsed = tick() - startTime
                local progress = elapsed / duration
                local eased = progress < 0.5 and 2 * progress * progress or 1 - math.pow(-2 * progress + 2, 2) / 2
                local currentPos = startPos.Position:lerp(endPos.Position, eased)
                hrp.CFrame = CFrame.new(currentPos)
                wait()
            end
            if hrp and hrp.Parent then
                hrp.CFrame = endPos
            end
        end)
        wait(duration)
    end

    local function bypassBringSystem(items, stopFlag)
        if isCollecting then return end
        isCollecting = true
        local char = LP.Character
        if not char then isCollecting = false return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then isCollecting = false return end
        
        originalPosition = hrp.CFrame
        
        for _, itemName in ipairs(items) do
            if stopFlag and not stopFlag() then break end
            
            local itemsFound = {}
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) then
                    local itemPart = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
                    if itemPart and itemPart.Parent ~= char then
                        table.insert(itemsFound, {item = item, part = itemPart})
                    end
                end
            end
            
            for _, itemData in ipairs(itemsFound) do
                if stopFlag and not stopFlag() then break end
                local item = itemData.item
                local itemPart = itemData.part
                if itemPart and itemPart.Parent then
                    local itemPos = itemPart.CFrame + Vector3.new(0, 5, 0)
                    smoothPullToItem(hrp.CFrame, itemPos, 1.2)
                    
                    pcall(function()
                        ReplicatedStorage:WaitForChild("RemoteEvents").RequestStartDraggingItem:FireServer(item)
                    end)
                    
                    task.wait(0.3)
                    
                    smoothPullToItem(hrp.CFrame, originalPosition, 1.0)
                    
                    pcall(function()
                        ReplicatedStorage:WaitForChild("RemoteEvents").StopDraggingItem:FireServer(item)
                    end)
                end
                task.wait(0.5)
            end
        end
        
        if hrp and hrp.Parent then
            hrp.CFrame = originalPosition
        end
        isCollecting = false
    end

    local function NOFLY()
        FLYING = false
        if flyKeyDown then flyKeyDown:Disconnect() end
        if flyKeyUp then flyKeyUp:Disconnect() end
        if mfly1 then mfly1:Disconnect() end
        if mfly2 then mfly2:Disconnect() end
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            LP.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
        end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
    end

    local function UnMobileFly()
        pcall(function()
            FLYING = false
            local root = LP.Character and LP.Character:WaitForChild("HumanoidRootPart")
            if not root then return end
            if root:FindFirstChild("BodyVelocity") then root:FindFirstChild("BodyVelocity"):Destroy() end
            if root:FindFirstChild("BodyGyro") then root:FindFirstChild("BodyGyro"):Destroy() end
            if LP.Character:FindFirstChildWhichIsA("Humanoid") then
                LP.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
            end
        end)
    end

    local function MobileFly()
        UnMobileFly()
        FLYING = true
        local char = LP.Character
        if not char then return end
        local root = char:WaitForChild("HumanoidRootPart")
        local camera = workspace.CurrentCamera
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "BodyVelocity"
        bv.Parent = root
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.new(0, 0, 0)

        local bg = Instance.new("BodyGyro")
        bg.Name = "BodyGyro"
        bg.Parent = root
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 1000
        bg.D = 50

        mfly1 = LP.CharacterAdded:Connect(function(newChar)
            local newRoot = newChar:WaitForChild("HumanoidRootPart")
            local newBv = Instance.new("BodyVelocity")
            newBv.Name = "BodyVelocity"
            newBv.Parent = newRoot
            newBv.MaxForce = Vector3.new(0, 0, 0)
            newBv.Velocity = Vector3.new(0, 0, 0)
            local newBg = Instance.new("BodyGyro")
            newBg.Name = "BodyGyro"
            newBg.Parent = newRoot
            newBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            newBg.P = 1000
            newBg.D = 50
        end)

        local controlModule = require(LP.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        
        mfly2 = RunService.RenderStepped:Connect(function()
            local currentChar = LP.Character
            if not currentChar then return end
            local currentRoot = currentChar:WaitForChild("HumanoidRootPart")
            local humanoid = currentChar:FindFirstChildWhichIsA("Humanoid")
            if not humanoid or not currentRoot then return end
            
            local bvObj = currentRoot:FindFirstChild("BodyVelocity")
            local bgObj = currentRoot:FindFirstChild("BodyGyro")
            if not bvObj or not bgObj then return end
            
            bvObj.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bgObj.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            humanoid.PlatformStand = true
            bgObj.CFrame = camera.CoordinateFrame
            bvObj.Velocity = Vector3.new(0, 0, 0)

            local direction = controlModule:GetMoveVector()
            if direction.X ~= 0 then
                bvObj.Velocity = bvObj.Velocity + camera.CFrame.RightVector * (direction.X * (flySpeed * 50))
            end
            if direction.Z ~= 0 then
                bvObj.Velocity = bvObj.Velocity - camera.CFrame.LookVector * (direction.Z * (flySpeed * 50))
            end
        end)
    end

    local function sFLY()
        repeat task.wait() until LP.Character and LP.Character:WaitForChild("HumanoidRootPart") and LP.Character:FindFirstChildOfClass("Humanoid")
        local T = LP.Character:WaitForChild("HumanoidRootPart")
        local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local SPEED = 0

        local function FLY()
            FLYING = true
            local BG = Instance.new('BodyGyro')
            local BV = Instance.new('BodyVelocity')
            BG.P = 9e4
            BG.Parent = T
            BV.Parent = T
            BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.CFrame = T.CFrame
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            
            task.spawn(function()
                while FLYING do
                    task.wait()
                    if not flyToggle and LP.Character:FindFirstChildOfClass('Humanoid') then
                        LP.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
                    end
                    
                    local moveVector = Vector3.new(CONTROL.L + CONTROL.R, 0, CONTROL.F + CONTROL.B)
                    if moveVector.Magnitude > 0 or CONTROL.Q + CONTROL.E ~= 0 then
                        SPEED = flySpeed
                    elseif SPEED ~= 0 then
                        SPEED = 0
                    end
                    
                    if moveVector.Magnitude > 0 or CONTROL.Q + CONTROL.E ~= 0 then
                        BV.Velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + 
                            ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - 
                            workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
                        lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                    elseif SPEED ~= 0 then
                        BV.Velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + 
                            ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).p) - 
                            workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
                    else
                        BV.Velocity = Vector3.new(0, 0, 0)
                    end
                    BG.CFrame = workspace.CurrentCamera.CoordinateFrame
                end
                
                CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                SPEED = 0
                BG:Destroy()
                BV:Destroy()
                if LP.Character:FindFirstChildOfClass('Humanoid') then
                    LP.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
                end
            end)
        end

        flyKeyDown = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local KEY = input.KeyCode.Name
                if KEY == "W" then CONTROL.F = flySpeed
                elseif KEY == "S" then CONTROL.B = -flySpeed
                elseif KEY == "A" then CONTROL.L = -flySpeed
                elseif KEY == "D" then CONTROL.R = flySpeed
                elseif KEY == "E" then CONTROL.Q = flySpeed * 2
                elseif KEY == "Q" then CONTROL.E = -flySpeed * 2
                end
                pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
            end
        end)

        flyKeyUp = UIS.InputEnded:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local KEY = input.KeyCode.Name
                if KEY == "W" then CONTROL.F = 0
                elseif KEY == "S" then CONTROL.B = 0
                elseif KEY == "A" then CONTROL.L = 0
                elseif KEY == "D" then CONTROL.R = 0
                elseif KEY == "E" then CONTROL.Q = 0
                elseif KEY == "Q" then CONTROL.E = 0
                end
            end
        end)
        
        FLY()
    end

    function createESPText(part, text, color)
        if part:FindFirstChild("ESPTexto") then return end
        local esp = Instance.new("BillboardGui")
        esp.Name = "ESPTexto"
        esp.Adornee = part
        esp.Size = UDim2.new(0, 100, 0, 20)
        esp.StudsOffset = Vector3.new(0, 2.5, 0)
        esp.AlwaysOnTop = true
        esp.MaxDistance = 300

        local label = Instance.new("TextLabel")
        label.Parent = esp
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color or Color3.fromRGB(255, 255, 0)
        label.TextStrokeTransparency = 0.2
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        esp.Parent = part
    end

    local function Aesp(nome, tipo)
        local container = tipo == "item" and workspace:FindFirstChild("Items") or workspace:FindFirstChild("Characters")
        local color = tipo == "item" and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 0)
        if not container then return end
        
        for _, obj in ipairs(container:GetChildren()) do
            if obj.Name == nome then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    createESPText(part, obj.Name, color)
                end
            end
        end
    end

    local function Desp(nome, tipo)
        local container = tipo == "item" and workspace:FindFirstChild("Items") or workspace:FindFirstChild("Characters")
        if not container then return end
        
        for _, obj in ipairs(container:GetChildren()) do
            if obj.Name == nome then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    for _, gui in ipairs(part:GetChildren()) do
                        if gui:IsA("BillboardGui") and gui.Name == "ESPTexto" then
                            gui:Destroy()
                        end
                    end
                end
            end
        end
    end

    local function killAuraLoop()
        while killAuraToggle do
            local char = LP.Character or LP.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local tool, damageID = getAnyToolWithDamageID(false)
                if tool and damageID then
                    equipTool(tool)
                    for _, mob in ipairs(Workspace.Characters:GetChildren()) do
                        if mob:IsA("Model") then
                            local part = mob:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                pcall(function()
                                    ReplicatedStorage:WaitForChild("RemoteEvents").ToolDamageObject:InvokeServer(
                                        mob, tool, damageID, CFrame.new(part.Position)
                                    )
                                end)
                            end
                        end
                    end
                    task.wait(0.1)
                else
                    task.wait(1)
                end
            else
                task.wait(0.5)
            end
        end
    end

    local function chopAuraLoop()
        while chopAuraToggle do
            local char = LP.Character or LP.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local tool, baseDamageID = getAnyToolWithDamageID(true)
                if tool and baseDamageID then
                    equipTool(tool)
                    currentammount = currentammount + 1
                    local trees = {}
                    local map = Workspace:FindFirstChild("Map")
                    if map then
                        if map:FindFirstChild("Foliage") then
                            for _, obj in ipairs(map.Foliage:GetChildren()) do
                                if obj:IsA("Model") and obj.Name == "Small Tree" then
                                    table.insert(trees, obj)
                                end
                            end
                        end
                        if map:FindFirstChild("Landmarks") then
                            for _, obj in ipairs(map.Landmarks:GetChildren()) do
                                if obj:IsA("Model") and obj.Name == "Small Tree" then
                                    table.insert(trees, obj)
                                end
                            end
                        end
                    end
                    for _, tree in ipairs(trees) do
                        local trunk = tree:FindFirstChild("Trunk")
                        if trunk and trunk:IsA("BasePart") and (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                            task.spawn(function()
                                local alreadyHit = false
                                while chopAuraToggle and tree and tree.Parent and not alreadyHit do
                                    alreadyHit = true
                                    currentammount = currentammount + 1
                                    pcall(function()
                                        ReplicatedStorage:WaitForChild("RemoteEvents").ToolDamageObject:InvokeServer(
                                            tree, tool, tostring(currentammount) .. "_7367831688",
                                            CFrame.new(-2.962610244751, 4.5547881126404, -75.950843811035)
                                        )
                                    end)
                                    task.wait(0.5)
                                end
                            end)
                        end
                    end
                    task.wait(0.1)
                else
                    task.wait(1)
                end
            else
                task.wait(0.5)
            end
        end
    end

    -- ══════════════════════════════════════════
    --  TABS
    -- ═════════════════════════════════════════=
    local Tabs = {}
    
    -- Introduction Tab
    Tabs.Intro = Window:Tab({ Title = gradient("Introduction"), Icon = "house" })
    
    local DiscordAPI = "https://discord.com/api/v10/invites/tJg2vfWEz6?with_counts=true&with_expiration=true"
    
    Tabs.Intro:Section({ Title = "— Welcome to Skid Hub —" })
    Tabs.Intro:Paragraph({ Title = gradient("Community"), Desc = "" })
    
    local function LoadDiscordInfo()
        local ok, result = pcall(function()
            return HttpService:JSONDecode((function()
                local data = {Url = DiscordAPI, Method = "GET", Headers = {["User-Agent"] = "RobloxBot/1.0", ["Accept"] = "application/json"}}
                if syn and syn.request then return syn.request(data).Body
                elseif request then return request(data).Body
                else return game:HttpGet(DiscordAPI, true) end
            end)())
        end)
        
        if ok and result and result.guild then
            local DiscordInfo = Tabs.Intro:Paragraph({
                Title = result.guild.name,
                Desc = "Members : " .. tostring(result.approximate_member_count) .. "\nOnline : " .. tostring(result.approximate_presence_count),
                Image = "https://cdn.discordapp.com/icons/" .. result.guild.id .. "/" .. result.guild.icon .. ".png?size=1024",
                ImageSize = 42
            })
            
            Tabs.Intro:Button({
                Title = "Refresh Discord Info",
                Callback = function()
                    local ok2, updated = pcall(function()
                        return HttpService:JSONDecode((function()
                            local data = {Url = DiscordAPI, Method = "GET"}
                            if syn and syn.request then return syn.request(data).Body
                            elseif request then return request(data).Body
                            else return game:HttpGet(DiscordAPI, true) end
                        end)())
                    end)
                    if ok2 and updated and updated.guild then
                        DiscordInfo:SetDesc("Members : " .. tostring(updated.approximate_member_count) .. "\nOnline : " .. tostring(updated.approximate_presence_count))
                        notify("Discord info updated")
                    else
                        notify("Failed to update Discord info")
                    end
                end
            })
        else
            Tabs.Intro:Paragraph({ Title = "Discord unavailable", Desc = "Could not fetch server statistics." })
        end
    end

    Tabs.Intro:Button({ Title = "Copy Discord Invite", Callback = function() setclipboard(CONFIG.DISCORD); notify("Discord invite copied") end })
    LoadDiscordInfo()
    
    Tabs.Intro:Paragraph({ Title = gradient("Information"), Desc = "" })
    Tabs.Intro:Paragraph({
        Title = "→ Skid Hub is a scripting assistant hub for 99 Nights in the Forest.\n→ Designed to help with grinding and automation.\n→ Free to use and constantly updated.",
        Desc = ""
    })
    Tabs.Intro:Paragraph({ Title = gradient("Features"), Desc = "" })
    Tabs.Intro:Paragraph({
        Title = "→ Combat: Kill Aura, Chop Aura\n→ Automation: Auto Feed, Auto Campfire, Auto Scrap, Auto Cook\n→ ESP: Item & Mob ESP\n→ Bring: Collect items automatically\n→ Teleport: Quick travel locations\n→ Player: Fly, Speed, Noclip\n→ Environment: Vision settings",
        Desc = ""
    })

    -- Combat Tab
    Tabs.Combat = Window:Tab({ Title = "Combat", Icon = "sword" })
    Tabs.Combat:Section({ Title = "Aura", Icon = "zap" })
    
    Tabs.Combat:Toggle({
        Title = "Kill Aura",
        Value = false,
        Callback = function(state)
            killAuraToggle = state
            if state then
                task.spawn(killAuraLoop)
            else
                local tool, _ = getAnyToolWithDamageID(false)
                unequipTool(tool)
            end
        end
    })

    Tabs.Combat:Toggle({
        Title = "Chop Aura",
        Value = false,
        Callback = function(state)
            chopAuraToggle = state
            if state then
                task.spawn(chopAuraLoop)
            else
                local tool, _ = getAnyToolWithDamageID(true)
                unequipTool(tool)
            end
        end
    })

    Tabs.Combat:Section({ Title = "Settings", Icon = "settings" })
    Tabs.Combat:Slider({
        Title = "Aura Radius",
        Value = { Min = 10, Max = 500, Default = 50 },
        Callback = function(value)
            auraRadius = math.clamp(value, 10, 500)
        end
    })

    -- Main Tab
    Tabs.Main = Window:Tab({ Title = "Main", Icon = "align-left" })
    Tabs.Main:Section({ Title = "Auto Feed", Icon = "utensils" })
    
    Tabs.Main:Dropdown({
        Title = "Select Food",
        Desc = "Choose the food",
        Values = alimentos,
        Value = selectedFood,
        Multi = true,
        Callback = function(value)
            selectedFood = value
        end
    })

    Tabs.Main:Input({
        Title = "Feed %",
        Desc = "Eat when hunger reaches this %",
        Value = tostring(hungerThreshold),
        Placeholder = "Ex: 75",
        Numeric = true,
        Callback = function(value)
            local n = tonumber(value)
            if n then
                hungerThreshold = math.clamp(n, 0, 100)
            end
        end
    })

    Tabs.Main:Toggle({
        Title = "Auto Feed",
        Value = false,
        Callback = function(state)
            autoFeedToggle = state
            if state then
                task.spawn(function()
                    while autoFeedToggle do
                        task.wait(0.075)
                        if wiki(selectedFood) == 0 then
                            autoFeedToggle = false
                            notify("Auto Food: Food is gone")
                            break
                        end
                        if ghn() <= hungerThreshold then
                            feed(selectedFood)
                        end
                    end
                end)
            end
        end
    })

    Tabs.Main:Section({ Title = "Misc", Icon = "settings" })
    
    Tabs.Main:Toggle({
        Title = "Instant Interact",
        Value = false,
        Callback = function(state)
            instantInteractEnabled = state
            if state then
                originalHoldDurations = {}
                instantInteractConnection = task.spawn(function()
                    while instantInteractEnabled do
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") then
                                if originalHoldDurations[obj] == nil then
                                    originalHoldDurations[obj] = obj.HoldDuration
                                end
                                obj.HoldDuration = 0
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            else
                instantInteractEnabled = false
                for obj, value in pairs(originalHoldDurations) do
                    if obj and obj:IsA("ProximityPrompt") then
                        obj.HoldDuration = value
                    end
                end
                originalHoldDurations = {}
            end
        end
    })

    Tabs.Main:Toggle({
        Title = "Auto Stun Deer",
        Value = false,
        Callback = function(state)
            if state then
                torchLoop = RunService.RenderStepped:Connect(function()
                    pcall(function()
                        local remote = ReplicatedStorage:FindFirstChild("RemoteEvents")
                            and ReplicatedStorage.RemoteEvents:FindFirstChild("DeerHitByTorch")
                        local deer = workspace:FindFirstChild("Characters")
                            and workspace.Characters:FindFirstChild("Deer")
                        if remote and deer then
                            remote:InvokeServer(deer)
                        end
                    end)
                    task.wait(0.1)
                end)
            else
                if torchLoop then
                    torchLoop:Disconnect()
                    torchLoop = nil
                end
            end
        end
    })

    -- Auto Tab
    Tabs.Auto = Window:Tab({ Title = "Auto", Icon = "wrench" })
    Tabs.Auto:Section({ Title = "Auto Upgrade Campfire", Icon = "flame" })
    
    Tabs.Auto:Dropdown({
        Title = "Select Fuel Item",
        Desc = "Choose the item to fuel campfire",
        Values = campfireFuelItems,
        Multi = false,
        AllowNone = true,
        Callback = function(option)
            selectedCampfireItem = option
        end
    })

    Tabs.Auto:Toggle({
        Title = "Auto Upgrade Campfire",
        Value = false,
        Callback = function(state)
            autoUpgradeCampfireEnabled = state
            if state then
                task.spawn(function()
                    while autoUpgradeCampfireEnabled do
                        if selectedCampfireItem then
                            for _, item in ipairs(workspace:WaitForChild("Items"):GetChildren()) do
                                if item.Name == selectedCampfireItem then
                                    moveItemToPos(item, campfireDropPos)
                                end
                            end
                        end
                        task.wait(2)
                    end
                end)
            end
        end
    })

    Tabs.Auto:Section({ Title = "Auto Scrap Items", Icon = "cog" })
    
    Tabs.Auto:Dropdown({
        Title = "Select Scrap Item",
        Desc = "Choose the item to scrap",
        Values = scrapjunkItems,
        Multi = false,
        AllowNone = true,
        Callback = function(option)
            selectedScrapItem = option
        end
    })

    Tabs.Auto:Toggle({
        Title = "Auto Scrap Item",
        Value = false,
        Callback = function(state)
            autoScrapItemsEnabled = state
            if state then
                task.spawn(function()
                    while autoScrapItemsEnabled do
                        if selectedScrapItem then
                            for _, item in ipairs(workspace:WaitForChild("Items"):GetChildren()) do
                                if item.Name == selectedScrapItem then
                                    moveItemToPos(item, autoScrapPos)
                                end
                            end
                        end
                        task.wait(2)
                    end
                end)
            end
        end
    })

    Tabs.Auto:Section({ Title = "Auto Cook Food", Icon = "fire" })
    
    Tabs.Auto:Dropdown({
        Title = "Select Food to Cook",
        Values = autocookItems,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            for _, itemName in ipairs(autocookItems) do
                autoCookEnabledItems[itemName] = table.find(options, itemName) ~= nil
            end
        end
    })

    Tabs.Auto:Toggle({
        Title = "Auto Cook Food",
        Value = false,
        Callback = function(state)
            autoCookEnabled = state
        end
    })

    coroutine.wrap(function()
        while true do
            if autoCookEnabled then
                for itemName, enabled in pairs(autoCookEnabledItems) do
                    if enabled then
                        for _, item in ipairs(Workspace:WaitForChild("Items"):GetChildren()) do
                            if item.Name == itemName then
                                moveItemToPos(item, campfireDropPos)
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)()

    -- ESP Tab
    Tabs.ESP = Window:Tab({ Title = "ESP", Icon = "eye" })
    Tabs.ESP:Section({ Title = "Item ESP", Icon = "package" })
    
    Tabs.ESP:Dropdown({
        Title = "Select Items to ESP",
        Values = ie,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            selectedItems = options
            if espItemsEnabled then
                for _, name in ipairs(ie) do
                    if table.find(selectedItems, name) then
                        Aesp(name, "item")
                    else
                        Desp(name, "item")
                    end
                end
            else
                for _, name in ipairs(ie) do
                    Desp(name, "item")
                end
            end
        end
    })

    Tabs.ESP:Toggle({
        Title = "Enable Item ESP",
        Value = false,
        Callback = function(state)
            espItemsEnabled = state
            for _, name in ipairs(ie) do
                if state and table.find(selectedItems, name) then
                    Aesp(name, "item")
                else
                    Desp(name, "item")
                end
            end

            if state then
                if not espConnections["Items"] then
                    local container = workspace:FindFirstChild("Items")
                    if container then
                        espConnections["Items"] = container.ChildAdded:Connect(function(obj)
                            if table.find(selectedItems, obj.Name) then
                                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    createESPText(part, obj.Name, Color3.fromRGB(0, 255, 0))
                                end
                            end
                        end)
                    end
                end
            else
                if espConnections["Items"] then
                    espConnections["Items"]:Disconnect()
                    espConnections["Items"] = nil
                end
            end
        end
    })

    Tabs.ESP:Section({ Title = "Mob ESP", Icon = "user" })
    
    Tabs.ESP:Dropdown({
        Title = "Select Mobs to ESP",
        Values = me,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            selectedMobs = options
            if espMobsEnabled then
                for _, name in ipairs(me) do
                    if table.find(selectedMobs, name) then
                        Aesp(name, "mob")
                    else
                        Desp(name, "mob")
                    end
                end
            else
                for _, name in ipairs(me) do
                    Desp(name, "mob")
                end
            end
        end
    })

    Tabs.ESP:Toggle({
        Title = "Enable Mob ESP",
        Value = false,
        Callback = function(state)
            espMobsEnabled = state
            for _, name in ipairs(me) do
                if state and table.find(selectedMobs, name) then
                    Aesp(name, "mob")
                else
                    Desp(name, "mob")
                end
            end

            if state then
                if not espConnections["Mobs"] then
                    local container = workspace:FindFirstChild("Characters")
                    if container then
                        espConnections["Mobs"] = container.ChildAdded:Connect(function(obj)
                            if table.find(selectedMobs, obj.Name) then
                                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    createESPText(part, obj.Name, Color3.fromRGB(255, 255, 0))
                                end
                            end
                        end)
                    end
                end
            else
                if espConnections["Mobs"] then
                    espConnections["Mobs"]:Disconnect()
                    espConnections["Mobs"] = nil
                end
            end
        end
    })

    -- Bring Tab
    Tabs.Bring = Window:Tab({ Title = "Bring", Icon = "package" })
    
    Tabs.Bring:Section({ Title = "Junk Items", Icon = "trash" })
    Tabs.Bring:Dropdown({
        Title = "Select Junk Items",
        Values = junkItems,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            selectedJunkItems = options
        end
    })
    Tabs.Bring:Toggle({
        Title = "Bring Junk Items",
        Default = false,
        Callback = function(state)
            junkToggleEnabled = state
            if state then
                if #selectedJunkItems > 0 then
                    junkLoopRunning = true
                    spawn(function()
                        while junkLoopRunning and junkToggleEnabled do
                            if #selectedJunkItems > 0 and junkToggleEnabled then
                                bypassBringSystem(selectedJunkItems, function() return junkToggleEnabled end)
                            end
                            local waitTime = 0
                            while waitTime < 3 and junkToggleEnabled and junkLoopRunning do
                                wait(0.1)
                                waitTime = waitTime + 0.1
                            end
                        end
                        junkLoopRunning = false
                    end)
                else
                    junkToggleEnabled = false
                end
            else
                junkLoopRunning = false
            end
        end
    })

    Tabs.Bring:Section({ Title = "Fuel Items", Icon = "flame" })
    Tabs.Bring:Dropdown({
        Title = "Select Fuel Items",
        Values = fuelItems,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            selectedFuelItems = options
        end
    })
    Tabs.Bring:Toggle({
        Title = "Bring Fuel Items",
        Default = false,
        Callback = function(state)
            fuelToggleEnabled = state
            if state then
                if #selectedFuelItems > 0 then
                    fuelLoopRunning = true
                    spawn(function()
                        while fuelLoopRunning and fuelToggleEnabled do
                            if #selectedFuelItems > 0 and fuelToggleEnabled then
                                bypassBringSystem(selectedFuelItems, function() return fuelToggleEnabled end)
                            end
                            local waitTime = 0
                            while waitTime < 3 and fuelToggleEnabled and fuelLoopRunning do
                                wait(0.1)
                                waitTime = waitTime + 0.1
                            end
                        end
                        fuelLoopRunning = false
                    end)
                else
                    fuelToggleEnabled = false
                end
            else
                fuelLoopRunning = false
            end
        end
    })

    Tabs.Bring:Section({ Title = "Food Items", Icon = "utensils" })
    Tabs.Bring:Dropdown({
        Title = "Select Food Items",
        Values = foodItems,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            selectedFoodItems = options
        end
    })
    Tabs.Bring:Toggle({
        Title = "Bring Food Items",
        Default = false,
        Callback = function(state)
            foodToggleEnabled = state
            if state then
                if #selectedFoodItems > 0 then
                    foodLoopRunning = true
                    spawn(function()
                        while foodLoopRunning and foodToggleEnabled do
                            if #selectedFoodItems > 0 and foodToggleEnabled then
                                bypassBringSystem(selectedFoodItems, function() return foodToggleEnabled end)
                            end
                            local waitTime = 0
                            while waitTime < 3 and foodToggleEnabled and foodLoopRunning do
                                wait(0.1)
                                waitTime = waitTime + 0.1
                            end
                        end
                        foodLoopRunning = false
                    end)
                else
                    foodToggleEnabled = false
                end
            else
                foodLoopRunning = false
            end
        end
    })

    Tabs.Bring:Section({ Title = "Medical Items", Icon = "bandage" })
    Tabs.Bring:Dropdown({
        Title = "Select Medical Items",
        Values = medicalItems,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            selectedMedicalItems = options
        end
    })
    Tabs.Bring:Toggle({
        Title = "Bring Medical Items",
        Default = false,
        Callback = function(state)
            medicalToggleEnabled = state
            if state then
                if #selectedMedicalItems > 0 then
                    medicalLoopRunning = true
                    spawn(function()
                        while medicalLoopRunning and medicalToggleEnabled do
                            if #selectedMedicalItems > 0 and medicalToggleEnabled then
                                bypassBringSystem(selectedMedicalItems, function() return medicalToggleEnabled end)
                            end
                            local waitTime = 0
                            while waitTime < 3 and medicalToggleEnabled and medicalLoopRunning do
                                wait(0.1)
                                waitTime = waitTime + 0.1
                            end
                        end
                        medicalLoopRunning = false
                    end)
                else
                    medicalToggleEnabled = false
                end
            else
                medicalLoopRunning = false
            end
        end
    })

    Tabs.Bring:Section({ Title = "Equipment", Icon = "sword" })
    Tabs.Bring:Dropdown({
        Title = "Select Equipment",
        Values = equipmentItems,
        Multi = true,
        AllowNone = true,
        Callback = function(options)
            selectedEquipmentItems = options
        end
    })
    Tabs.Bring:Toggle({
        Title = "Bring Equipment",
        Default = false,
        Callback = function(state)
            equipmentToggleEnabled = state
            if state then
                if #selectedEquipmentItems > 0 then
                    equipmentLoopRunning = true
                    spawn(function()
                        while equipmentLoopRunning and equipmentToggleEnabled do
                            if #selectedEquipmentItems > 0 and equipmentToggleEnabled then
                                bypassBringSystem(selectedEquipmentItems, function() return equipmentToggleEnabled end)
                            end
                            local waitTime = 0
                            while waitTime < 3 and equipmentToggleEnabled and equipmentLoopRunning do
                                wait(0.1)
                                waitTime = waitTime + 0.1
                            end
                        end
                        equipmentLoopRunning = false
                    end)
                else
                    equipmentToggleEnabled = false
                end
            else
                equipmentLoopRunning = false
            end
        end
    })

    -- Teleport Tab
    Tabs.Teleport = Window:Tab({ Title = "Teleport", Icon = "map" })
    Tabs.Teleport:Section({ Title = "Locations", Icon = "map-pin" })
    
    Tabs.Teleport:Button({
        Title = "Teleport to Campfire",
        Callback = function()
            tp1()
        end
    })

    Tabs.Teleport:Button({
        Title = "Teleport to Stronghold",
        Callback = function()
            tp2()
        end
    })

    Tabs.Teleport:Section({ Title = "Lost Children", Icon = "users" })
    
    local currentMobs, currentMobNames = getMobs()
    local selectedMob = currentMobNames[1]
    
    local MobDropdown = Tabs.Teleport:Dropdown({
        Title = "Select Child",
        Values = currentMobNames,
        Multi = false,
        AllowNone = true,
        Callback = function(options)
            selectedMob = options[#options] or currentMobNames[1]
        end
    })

    Tabs.Teleport:Button({
        Title = "Refresh List",
        Callback = function()
            currentMobs, currentMobNames = getMobs()
            if #currentMobNames > 0 then
                selectedMob = currentMobNames[1]
                MobDropdown:Refresh(currentMobNames)
            else
                selectedMob = nil
                MobDropdown:Refresh({"No child found"})
            end
        end
    })

    Tabs.Teleport:Button({
        Title = "Teleport to Child",
        Callback = function()
            if selectedMob and currentMobs then
                for i, name in ipairs(currentMobNames) do
                    if name == selectedMob then
                        local targetMob = currentMobs[i]
                        if targetMob then
                            local part = targetMob.PrimaryPart or targetMob:FindFirstChildWhichIsA("BasePart")
                            if part and LP.Character then
                                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
    })

    Tabs.Teleport:Section({ Title = "Chests", Icon = "box" })
    
    local currentChests, currentChestNames = getChests()
    local selectedChest = currentChestNames[1]
    
    local ChestDropdown = Tabs.Teleport:Dropdown({
        Title = "Select Chest",
        Values = currentChestNames,
        Multi = false,
        AllowNone = true,
        Callback = function(options)
            selectedChest = options[#options] or currentChestNames[1]
        end
    })

    Tabs.Teleport:Button({
        Title = "Refresh List",
        Callback = function()
            currentChests, currentChestNames = getChests()
            if #currentChestNames > 0 then
                selectedChest = currentChestNames[1]
                ChestDropdown:Refresh(currentChestNames)
            else
                selectedChest = nil
                ChestDropdown:Refresh({"No chests found"})
            end
        end
    })

    Tabs.Teleport:Button({
        Title = "Teleport to Chest",
        Callback = function()
            if selectedChest and currentChests then
                local chestIndex = 1
                for i, name in ipairs(currentChestNames) do
                    if name == selectedChest then
                        chestIndex = i
                        break
                    end
                end
                local targetChest = currentChests[chestIndex]
                if targetChest then
                    local part = targetChest.PrimaryPart or targetChest:FindFirstChildWhichIsA("BasePart")
                    if part and LP.Character then
                        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                        end
                    end
                end
            end
        end
    })

    -- Player Tab
    Tabs.Player = Window:Tab({ Title = "Player", Icon = "user" })
    Tabs.Player:Section({ Title = "Fly", Icon = "plane" })
    
    Tabs.Player:Slider({
        Title = "Fly Speed",
        Value = { Min = 1, Max = 20, Default = 1 },
        Callback = function(value)
            flySpeed = value
        end
    })

    Tabs.Player:Toggle({
        Title = "Enable Fly",
        Value = false,
        Callback = function(state)
            flyToggle = state
            if flyToggle then
                if UIS.TouchEnabled then
                    MobileFly()
                else
                    sFLY()
                end
            else
                NOFLY()
                UnMobileFly()
            end
        end
    })

    Tabs.Player:Section({ Title = "Movement", Icon = "move" })
    
    local speed = 16
    local function setSpeed(val)
        local humanoid = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = val end
    end

    Tabs.Player:Slider({
        Title = "Speed",
        Value = { Min = 16, Max = 150, Default = 16 },
        Callback = function(value)
            speed = value
        end
    })

    Tabs.Player:Toggle({
        Title = "Enable Speed",
        Value = false,
        Callback = function(state)
            setSpeed(state and speed or 16)
        end
    })

    Tabs.Player:Toggle({
        Title = "Noclip",
        Value = false,
        Callback = function(state)
            if state then
                noclipConnection = RunService.Stepped:Connect(function()
                    local char = LP.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
            end
        end
    })

    Tabs.Player:Toggle({
        Title = "Infinite Jump",
        Value = false,
        Callback = function(state)
            if state then
                infJumpConnection = UIS.JumpRequest:Connect(function()
                    local char = LP.Character
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                if infJumpConnection then
                    infJumpConnection:Disconnect()
                    infJumpConnection = nil
                end
            end
        end
    })

    -- Environment Tab
    Tabs.Environment = Window:Tab({ Title = "Environment", Icon = "sun" })
    Tabs.Environment:Section({ Title = "Vision", Icon = "eye" })
    
    local originalParents = {Sky = nil, Bloom = nil, CampfireEffect = nil}
    local function storeOriginalParents()
        local sky = Lighting:FindFirstChild("Sky")
        local bloom = Lighting:FindFirstChild("Bloom")
        local campfireEffect = Lighting:FindFirstChild("CampfireEffect")
        if sky and not originalParents.Sky then originalParents.Sky = sky.Parent end
        if bloom and not originalParents.Bloom then originalParents.Bloom = bloom.Parent end
        if campfireEffect and not originalParents.CampfireEffect then originalParents.CampfireEffect = campfireEffect.Parent end
    end
    storeOriginalParents()

    local originalColorCorrectionParent = nil
    local function storeColorCorrectionParent()
        local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
        if colorCorrection and not originalColorCorrectionParent then
            originalColorCorrectionParent = colorCorrection.Parent
        end
    end
    storeColorCorrectionParent()

    Tabs.Environment:Toggle({
        Title = "Disable Fog",
        Value = false,
        Callback = function(state)
            if state then
                local sky = Lighting:FindFirstChild("Sky")
                local bloom = Lighting:FindFirstChild("Bloom")
                local campfireEffect = Lighting:FindFirstChild("CampfireEffect")
                if sky then sky.Parent = nil end
                if bloom then bloom.Parent = nil end
                if campfireEffect then campfireEffect.Parent = nil end
            else
                local sky = game:FindFirstChild("Sky", true) or Lighting:FindFirstChild("Sky")
                local bloom = game:FindFirstChild("Bloom", true) or Lighting:FindFirstChild("Bloom")
                local campfireEffect = game:FindFirstChild("CampfireEffect", true) or Lighting:FindFirstChild("CampfireEffect")
                if sky then sky.Parent = originalParents.Sky or Lighting end
                if bloom then bloom.Parent = originalParents.Bloom or Lighting end
                if campfireEffect then campfireEffect.Parent = originalParents.CampfireEffect or Lighting end
            end
        end
    })

    Tabs.Environment:Toggle({
        Title = "Disable Night Campfire Effect",
        Value = false,
        Callback = function(state)
            if state then
                local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
                if colorCorrection then
                    if not originalColorCorrectionParent then
                        originalColorCorrectionParent = colorCorrection.Parent
                    end
                    colorCorrection.Parent = nil
                end
            else
                local colorCorrection = Lighting:FindFirstChild("ColorCorrection") or game:FindFirstChild("ColorCorrection", true)
                if colorCorrection then
                    colorCorrection.Parent = Lighting
                end
            end
        end
    })

    local originalLightingValues = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ShadowSoftness = Lighting.ShadowSoftness,
        GlobalShadows = Lighting.GlobalShadows,
        Technology = Lighting.Technology
    }

    Tabs.Environment:Toggle({
        Title = "Fullbright",
        Value = false,
        Callback = function(state)
            if state then
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                Lighting.ShadowSoftness = 0
                Lighting.GlobalShadows = false
                Lighting.Technology = Enum.Technology.Compatibility
            else
                Lighting.Brightness = originalLightingValues.Brightness
                Lighting.Ambient = originalLightingValues.Ambient
                Lighting.OutdoorAmbient = originalLightingValues.OutdoorAmbient
                Lighting.ShadowSoftness = originalLightingValues.ShadowSoftness
                Lighting.GlobalShadows = originalLightingValues.GlobalShadows
                Lighting.Technology = originalLightingValues.Technology
            end
        end
    })

    -- Select Introduction tab by default
    pcall(function() Window:SelectTab(1) end)

    -- RightShift toggle
    task.spawn(function()
        local pGui = LP:WaitForChild("PlayerGui")
        local windGui
        for _ = 1, 80 do
            task.wait(0.1)
            for _, sg in ipairs(pGui:GetChildren()) do
                if sg:IsA("ScreenGui") then
                    for _, d in ipairs(sg:GetDescendants()) do
                        if d:IsA("Frame") and d.AbsoluteSize.X >= 400 then
                            windGui = sg
                            break
                        end
                    end
                end
                if windGui then break end
            end
            if windGui then break end
        end
        if not windGui then return end
        
        local mainFrame
        for _, child in ipairs(windGui:GetDescendants()) do
            if child:IsA("Frame") and child.Visible then
                if not mainFrame or child.AbsoluteSize.X > mainFrame.AbsoluteSize.X then
                    mainFrame = child
                end
            end
        end
        if not mainFrame then return end

        local hubVisible = true
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                hubVisible = not hubVisible
                mainFrame.Visible = hubVisible
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  MAIN EXECUTION FLOW
-- ═══════════════════════════════════════════════════════════════════════════════
InitializeKeySystem(function()
    ShowLoadingScreen(function()
        InitializeMainUI()
    end)
end)