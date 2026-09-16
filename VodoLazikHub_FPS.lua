--[[
    VodoLazik AIM / ESP / FULLBRIGHT
    Roblox Luau - mobile friendly

    Changes in this version:
    • Aim snaps instantly (no Lerp / no smoothing)
    • Smaller responsive menu for phones
    • ESP rebuilt with Highlight + BillboardGui so it is visible reliably
    • Attached 2D Box + Chams ESP for players and NPCs
    • Tracer is kept as a normal GUI element
    • Color palette with presets + hue/saturation controls
    • Movement tab: physics-safe Bhop + Auto-Jump, Jump Hack, Fly, Infinity Jump, NoClip
    • ESP uses a black 2D box + live green health bar
    • Sliders are touch friendly
    • FOV circle stays centered and resizes correctly
    • Optional executor file configs are kept

    For testing in your own Roblox experience.
    LocalScript -> StarterPlayer > StarterPlayerScripts
]]

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function getCamera()
    local current = workspace.CurrentCamera
    if current then
        Camera = current
    end
    return Camera
end

--// CONFIG
local Config = {
    SilentAim = false,
    VisibilityCheck = true,
    DistanceCheck = true,
    Distance = 500,
    Bhop = false,
    BhopSpeed = 25,
    BhopAutoJump = true,
    JumpHack = false,
    JumpPower = 60,
    Fly = false,
    FlySpeed = 30,
    InfinityJump = false,
    Noclip = false,
    AntiPing = false,
    FOV = 120,
    HitChance = 100,

    FOVCircle = true,
    FOVNumSides = 64,
    FOVThickness = 2,

    ESPBox = true,
    ESPHealth = false,
    ESPChams = false,
    ESPTracer = false,
    ESPColor = Color3.fromRGB(0, 170, 255),
    ColorPreset = "Cyan",

    FullBright = false,
    Brightness = 2,
    ClockTime = 14,
    Fog = true,

    ConfigName = "default"
}

local DefaultConfig = {}
for key, value in pairs(Config) do
    DefaultConfig[key] = value
end

--// FILE CONFIG
local CONFIG_FOLDER = "VodoLazikConfigs"
local LAST_CONFIG_FILE = CONFIG_FOLDER .. "/last.txt"
local BUTTON_POSITION_FILE = CONFIG_FOLDER .. "/button_position.json"
local BUTTON_LOCK_FILE = CONFIG_FOLDER .. "/button_lock.txt"

local DEFAULT_BUTTON_X = 14
local DEFAULT_BUTTON_Y_FROM_BOTTOM = 58

local function canUseFiles()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
        and typeof(makefolder) == "function"
end

local function serializeValue(value)
    if typeof(value) == "Color3" then
        return {
            __type = "Color3",
            R = value.R,
            G = value.G,
            B = value.B
        }
    end
    return value
end

local function deserializeValue(value)
    if type(value) == "table" and value.__type == "Color3" then
        return Color3.new(value.R, value.G, value.B)
    end
    return value
end

local function encodeConfig()
    local data = {}
    for key, value in pairs(Config) do
        data[key] = serializeValue(value)
    end
    return HttpService:JSONEncode(data)
end

local function decodeConfig(text)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)

    if not ok or type(data) ~= "table" then
        return false
    end

    for key, value in pairs(data) do
        if Config[key] ~= nil then
            Config[key] = deserializeValue(value)
        end
    end

    return true
end

local function saveConfig(name)
    if not canUseFiles() then
        return false, "File API unavailable"
    end

    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
    end)

    local file = CONFIG_FOLDER .. "/" .. name .. ".json"

    local ok, err = pcall(function()
        writefile(file, encodeConfig())
        writefile(LAST_CONFIG_FILE, name)
    end)

    return ok, err
end

local function loadConfig(name)
    if not canUseFiles() then
        return false
    end

    local file = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile(file) then
        return false
    end

    local ok, text = pcall(readfile, file)
    if not ok then
        return false
    end

    return decodeConfig(text)
end

if canUseFiles() then
    pcall(function()
        if isfile(LAST_CONFIG_FILE) then
            local last = readfile(LAST_CONFIG_FILE)
            if last and last ~= "" then
                Config.ConfigName = last
                loadConfig(last)
            end
        end
    end)
end

--// GUI ROOT
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VodoLazikInterface"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.Enabled = true
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

ScreenGui.Parent = PlayerGui
ScreenGui.Enabled = true

--// MAIN MENU
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(420, 310)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(13, 15, 18)
Main.BackgroundTransparency = 0.03
Main.Visible = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 50, 58)
MainStroke.Transparency = 0.15
MainStroke.Parent = Main

local UIScale = Instance.new("UIScale")
UIScale.Scale = 1
UIScale.Parent = Main

local function updateMenuScale()
    local camera = getCamera()
    if not camera then
        UIScale.Scale = 0.85
        return
    end

    local viewport = camera.ViewportSize
    if viewport.X <= 1 or viewport.Y <= 1 then
        UIScale.Scale = 0.85
        return
    end

    local scaleX = (viewport.X * 0.92) / 420
    local scaleY = (viewport.Y * 0.86) / 310
    UIScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.65, 1)
end

updateMenuScale()

task.spawn(function()
    for _ = 1, 120 do
        local camera = getCamera()
        if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
            updateMenuScale()
            break
        end
        RunService.RenderStepped:Wait()
    end
end)

--// TOP BAR
local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 48)
Top.ZIndex = 90
Top.BackgroundTransparency = 1
Top.Parent = Main

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.fromOffset(32, 32)
Avatar.Position = UDim2.fromOffset(10, 8)
Avatar.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
Avatar.Parent = Top

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = Avatar

pcall(function()
    Avatar.Image = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size100x100
    )
end)

local Nick = Instance.new("TextLabel")
Nick.Size = UDim2.fromOffset(130, 18)
Nick.Position = UDim2.fromOffset(50, 7)
Nick.BackgroundTransparency = 1
Nick.Text = LocalPlayer.DisplayName
Nick.TextColor3 = Color3.fromRGB(240, 240, 240)
Nick.Font = Enum.Font.GothamBold
Nick.TextSize = 12
Nick.TextXAlignment = Enum.TextXAlignment.Left
Nick.Parent = Top

local Status = Instance.new("TextLabel")
Status.Size = UDim2.fromOffset(130, 15)
Status.Position = UDim2.fromOffset(50, 25)
Status.BackgroundTransparency = 1
Status.Text = "Developer"
Status.TextColor3 = Color3.fromRGB(0, 190, 255)
Status.Font = Enum.Font.Gotham
Status.TextSize = 9
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Top

local Title = Instance.new("TextLabel")
Title.Size = UDim2.fromOffset(130, 28)
Title.Position = UDim2.new(0.5, -65, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "VodoLazik"
Title.TextColor3 = Color3.fromRGB(70, 190, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -40, 0, 9)
Close.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(220, 220, 220)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 20
Close.AutoButtonColor = false
Close.Parent = Top

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = Close

--// SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 92, 1, -48)
Sidebar.Position = UDim2.fromOffset(0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
Sidebar.BackgroundTransparency = 0.05
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -102, 1, -58)
Content.Position = UDim2.fromOffset(97, 53)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(70, 170, 220)
Content.CanvasSize = UDim2.fromOffset(0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.Parent = Main

local CurrentCategory = "Combat"
local CategoryButtons = {}
local updateContent

local Categories = {
    {"Combat", "A"},
    {"Visuals", "V"},
    {"Movement", "M"},
    {"Misc", "O"},
    {"Performance", "P"},
    {"Config", "C"}
}

local function createCategory(name, icon, index)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -12, 0, 38)
    Button.Position = UDim2.fromOffset(6, 8 + ((index - 1) * 43))
    Button.BackgroundColor3 = Color3.fromRGB(28, 60, 75)
    Button.BackgroundTransparency = index == 1 and 0 or 1
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.fromOffset(25, 38)
    Icon.Position = UDim2.fromOffset(2, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = icon
    Icon.TextColor3 = Color3.fromRGB(80, 185, 240)
    Icon.Font = Enum.Font.GothamBold
    Icon.TextSize = 12
    Icon.Parent = Button

    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, -27, 1, 0)
    Text.Position = UDim2.fromOffset(27, 0)
    Text.BackgroundTransparency = 1
    Text.Text = name
    Text.TextColor3 = index == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 195, 205)
    Text.Font = Enum.Font.GothamMedium
    Text.TextSize = 10
    Text.TextXAlignment = Enum.TextXAlignment.Left
    Text.Parent = Button

    Button.MouseButton1Click:Connect(function()
        CurrentCategory = name

        for _, data in pairs(CategoryButtons) do
            data.Button.BackgroundTransparency = 1
            data.Text.TextColor3 = Color3.fromRGB(190, 195, 205)
        end

        Button.BackgroundTransparency = 0
        Button.BackgroundColor3 = Color3.fromRGB(28, 60, 75)
        Text.TextColor3 = Color3.fromRGB(255, 255, 255)

        if updateContent then
            updateContent()
        end
    end)

    CategoryButtons[name] = {
        Button = Button,
        Text = Text
    }
end

for index, data in ipairs(Categories) do
    createCategory(data[1], data[2], index)
end

--// UI HELPERS
local function clearContent()
    for _, child in ipairs(Content:GetChildren()) do
        child:Destroy()
    end
end

local function createPanel(title, height)
    local Panel = Instance.new("Frame")
    Panel.Size = UDim2.new(1, -8, 0, height)
    Panel.BackgroundColor3 = Color3.fromRGB(18, 21, 25)
    Panel.BackgroundTransparency = 0.04
    Panel.Parent = Content

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Panel

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(40, 44, 50)
    Stroke.Transparency = 0.45
    Stroke.Parent = Panel

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 26)
    Label.Position = UDim2.fromOffset(12, 5)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(245, 245, 245)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Panel

    return Panel
end

local function createToggle(parent, text, y, getter, setter)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 32)
    Button.Position = UDim2.fromOffset(10, y)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(205, 208, 215)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.fromOffset(32, 17)
    Switch.Position = UDim2.new(1, -32, 0.5, -8)
    Switch.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
    Switch.Parent = Button

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.fromOffset(11, 11)
    Circle.Position = UDim2.fromOffset(3, 3)
    Circle.BackgroundColor3 = Color3.fromRGB(150, 155, 160)
    Circle.Parent = Switch

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local function refresh()
        local state = getter()
        Switch.BackgroundColor3 = state and Color3.fromRGB(0, 150, 210) or Color3.fromRGB(45, 48, 54)
        Circle.Position = state and UDim2.new(1, -14, 0, 3) or UDim2.fromOffset(3, 3)
    end

    Button.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()
end

local function createSlider(parent, text, y, minValue, maxValue, getter, setter)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -20, 0, 46)
    Container.Position = UDim2.fromOffset(10, y)
    Container.BackgroundTransparency = 1
    Container.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 0, 17)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(205, 208, 215)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local Value = Instance.new("TextLabel")
    Value.Size = UDim2.new(0.35, 0, 0, 17)
    Value.Position = UDim2.new(0.65, 0, 0, 0)
    Value.BackgroundTransparency = 1
    Value.TextColor3 = Color3.fromRGB(120, 195, 240)
    Value.Font = Enum.Font.GothamBold
    Value.TextSize = 10
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.Parent = Container

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 0, 6)
    Bar.Position = UDim2.fromOffset(0, 27)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 48, 55)
    Bar.Active = true
    Bar.Parent = Container

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 160, 220)
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(12, 12)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new(0, 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(220, 240, 250)
    Knob.Parent = Bar

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local dragging = false

    local function refresh()
        local current = math.clamp(tonumber(getter()) or minValue, minValue, maxValue)
        local alpha = (current - minValue) / (maxValue - minValue)
        Label.Text = text
        Value.Text = tostring(math.floor(current + 0.5))
        Fill.Size = UDim2.new(alpha, 0, 1, 0)
        Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
    end

    local function setFromX(x)
        local width = math.max(Bar.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - Bar.AbsolutePosition.X) / width, 0, 1)
        local value = minValue + ((maxValue - minValue) * alpha)
        setter(value)
        refresh()
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    Bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)

    refresh()
end

local function createButton(parent, text, y, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 34)
    Button.Position = UDim2.fromOffset(10, y)
    Button.BackgroundColor3 = Color3.fromRGB(25, 50, 63)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(230, 240, 245)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 10
    Button.AutoButtonColor = false
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    Button.MouseButton1Click:Connect(callback)
end

--// CONTENT
updateContent = function()
    clearContent()

    local panel

    if CurrentCategory == "Combat" then
        panel = createPanel("Aim Assist / FOV", 350)

        createToggle(panel, "Enable Aim", 36,
            function() return Config.SilentAim end,
            function(v) Config.SilentAim = v end)

        createToggle(panel, "Visibility Check", 69,
            function() return Config.VisibilityCheck end,
            function(v) Config.VisibilityCheck = v end)

        createToggle(panel, "Distance Check", 102,
            function() return Config.DistanceCheck end,
            function(v) Config.DistanceCheck = v end)

        createSlider(panel, "Distance", 137, 50, 2000,
            function() return Config.Distance end,
            function(v) Config.Distance = v end)

        createSlider(panel, "FOV", 183, 20, 500,
            function() return Config.FOV end,
            function(v) Config.FOV = v end)

        createSlider(panel, "Hit Chance", 229, 0, 100,
            function() return Config.HitChance end,
            function(v) Config.HitChance = v end)

        createToggle(panel, "FOV Circle", 275,
            function() return Config.FOVCircle end,
            function(v) Config.FOVCircle = v end)

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -20, 0, 45)
        info.Position = UDim2.fromOffset(10, 310)
        info.BackgroundTransparency = 1
        info.TextWrapped = true
        info.TextColor3 = Color3.fromRGB(135, 140, 148)
        info.Font = Enum.Font.Gotham
        info.TextSize = 9
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.Text = "Silent Aim: камера мгновенно доворачивается к выбранной цели в пределах FOV."
        info.Parent = panel

    elseif CurrentCategory == "Visuals" then
        panel = createPanel("ESP / Colors", 445)

        createToggle(panel, "2D Box", 36,
            function() return Config.ESPBox end,
            function(v) Config.ESPBox = v end)

        createToggle(panel, "Chams", 69,
            function() return Config.ESPChams end,
            function(v) Config.ESPChams = v end)

        createToggle(panel, "Health", 102,
            function() return Config.ESPHealth end,
            function(v) Config.ESPHealth = v end)

        createToggle(panel, "Tracer", 135,
            function() return Config.ESPTracer end,
            function(v) Config.ESPTracer = v end)

        local paletteTitle = Instance.new("TextLabel")
        paletteTitle.Size = UDim2.new(1, -20, 0, 24)
        paletteTitle.Position = UDim2.fromOffset(10, 175)
        paletteTitle.BackgroundTransparency = 1
        paletteTitle.Text = "COLOR PALETTE"
        paletteTitle.TextColor3 = Color3.fromRGB(220, 225, 230)
        paletteTitle.Font = Enum.Font.GothamBold
        paletteTitle.TextSize = 10
        paletteTitle.TextXAlignment = Enum.TextXAlignment.Left
        paletteTitle.Parent = panel

        local colors = {
            {"Red", Color3.fromRGB(255, 70, 70)},
            {"Orange", Color3.fromRGB(255, 145, 0)},
            {"Yellow", Color3.fromRGB(255, 220, 40)},
            {"Green", Color3.fromRGB(70, 255, 100)},
            {"Cyan", Color3.fromRGB(0, 200, 255)},
            {"Blue", Color3.fromRGB(70, 120, 255)},
            {"Purple", Color3.fromRGB(180, 90, 255)},
            {"Pink", Color3.fromRGB(255, 80, 180)},
            {"White", Color3.fromRGB(245, 245, 245)},
        }

        for i, item in ipairs(colors) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local b = Instance.new("TextButton")
            b.Size = UDim2.fromOffset(68, 28)
            b.Position = UDim2.fromOffset(10 + col * 73, 202 + row * 34)
            b.BackgroundColor3 = item[2]
            b.Text = item[1]
            b.TextColor3 = (item[1] == "Yellow" or item[1] == "White") and Color3.fromRGB(20,20,20) or Color3.fromRGB(255,255,255)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 8
            b.AutoButtonColor = false
            b.Parent = panel
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = b
            b.MouseButton1Click:Connect(function()
                Config.ESPColor = item[2]
                Config.ColorPreset = item[1]
            end)
        end

        createSlider(panel, "Hue", 310, 0, 360,
            function() return select(1, Color3.toHSV(Config.ESPColor)) * 360 end,
            function(v)
                local _, sat, val = Color3.toHSV(Config.ESPColor)
                Config.ESPColor = Color3.fromHSV((v % 360) / 360, sat, val)
                Config.ColorPreset = "Custom"
            end)

        createSlider(panel, "Saturation", 356, 0, 100,
            function() local _, sat = Color3.toHSV(Config.ESPColor); return sat * 100 end,
            function(v)
                local hue, _, val = Color3.toHSV(Config.ESPColor)
                Config.ESPColor = Color3.fromHSV(hue, math.clamp(v / 100, 0, 1), val)
                Config.ColorPreset = "Custom"
            end)

    elseif CurrentCategory == "Movement" then
        panel = createPanel("Movement", 405)

        createToggle(panel, "Bhop", 36,
            function() return Config.Bhop end,
            function(v) Config.Bhop = v end)

        createSlider(panel, "Bhop Speed", 72, 1, 30,
            function() return Config.BhopSpeed end,
            function(v) Config.BhopSpeed = math.clamp(v, 1, 30) end)

        createToggle(panel, "Auto-Jump (Bhop)", 118,
            function() return Config.BhopAutoJump end,
            function(v) Config.BhopAutoJump = v end)

        createToggle(panel, "Jump Hack", 151,
            function() return Config.JumpHack end,
            function(v) Config.JumpHack = v end)

        createSlider(panel, "Jump Power", 187, 1, 20,
            function() return Config.JumpPower end,
            function(v) Config.JumpPower = math.clamp(v, 1, 20) end)

        createToggle(panel, "Fly", 233,
            function() return Config.Fly end,
            function(v) Config.Fly = v end)

        createSlider(panel, "Fly Speed", 269, 1, 30,
            function() return Config.FlySpeed end,
            function(v) Config.FlySpeed = math.clamp(v, 1, 30) end)

        createToggle(panel, "Infinity Jump", 315,
            function() return Config.InfinityJump end,
            function(v) Config.InfinityJump = v end)

        createToggle(panel, "NoClip", 348,
            function() return Config.Noclip end,
            function(v) Config.Noclip = v end)

    elseif CurrentCategory == "Misc" then
        panel = createPanel("Lighting", 220)

        createToggle(panel, "FullBright", 36,
            function() return Config.FullBright end,
            function(v) Config.FullBright = v end)

        createSlider(panel, "Brightness", 73, 0, 10,
            function() return Config.Brightness end,
            function(v) Config.Brightness = v end)

        createSlider(panel, "ClockTime", 119, 0, 24,
            function() return Config.ClockTime end,
            function(v) Config.ClockTime = v end)

        createToggle(panel, "Remove Fog", 166,
            function() return Config.Fog end,
            function(v) Config.Fog = v end)

    elseif CurrentCategory == "Performance" then
        panel = createPanel("Performance / Anti-Ping", 245)

        createToggle(panel, "Anti-Ping", 36,
            function() return Config.AntiPing end,
            function(v) Config.AntiPing = v end)

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -20, 0, 105)
        info.Position = UDim2.fromOffset(10, 82)
        info.BackgroundTransparency = 1
        info.TextWrapped = true
        info.TextColor3 = Color3.fromRGB(145, 150, 158)
        info.Font = Enum.Font.Gotham
        info.TextSize = 9
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.Text = "Anti-Ping снижает лишнюю нагрузку от самого интерфейса и ESP.\n\nОн уменьшает частоту тяжёлых визуальных обновлений, когда функция включена.\n\nВажно: настоящий сетевой ping зависит от сервера и интернет-соединения. Клиентский скрипт не может физически уменьшить задержку до сервера."
        info.Parent = panel

    elseif CurrentCategory == "Config" then
        panel = createPanel("Config System", 260)

        local NameBox = Instance.new("TextBox")
        NameBox.Size = UDim2.new(1, -20, 0, 32)
        NameBox.Position = UDim2.fromOffset(10, 38)
        NameBox.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
        NameBox.PlaceholderText = "Config name"
        NameBox.Text = Config.ConfigName
        NameBox.TextColor3 = Color3.fromRGB(235, 235, 235)
        NameBox.PlaceholderColor3 = Color3.fromRGB(100, 105, 110)
        NameBox.Font = Enum.Font.Gotham
        NameBox.TextSize = 10
        NameBox.ClearTextOnFocus = false
        NameBox.Parent = panel

        local BoxCorner = Instance.new("UICorner")
        BoxCorner.CornerRadius = UDim.new(0, 7)
        BoxCorner.Parent = NameBox

        createButton(panel, "Save Config", 78, function()
            local name = NameBox.Text:gsub("[^%w_%-%s]", "")
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then name = "default" end
            Config.ConfigName = name
            saveConfig(name)
            NameBox.Text = name
        end)

        createButton(panel, "Load Config", 118, function()
            local name = NameBox.Text
            if name == "" then name = "default" end
            if loadConfig(name) then
                Config.ConfigName = name
                updateContent()
            end
        end)

        createButton(panel, "Reset Config", 158, function()
            for key, value in pairs(DefaultConfig) do Config[key] = value end
            updateContent()
        end)

        local Info = Instance.new("TextLabel")
        Info.Size = UDim2.new(1, -20, 0, 45)
        Info.Position = UDim2.fromOffset(10, 205)
        Info.BackgroundTransparency = 1
        Info.TextWrapped = true
        Info.TextColor3 = Color3.fromRGB(135, 140, 148)
        Info.Font = Enum.Font.Gotham
        Info.TextSize = 9
        Info.TextXAlignment = Enum.TextXAlignment.Left
        Info.TextYAlignment = Enum.TextYAlignment.Top
        Info.Text = canUseFiles() and "File configs: READY" or "File configs: unavailable in normal Roblox Studio"
        Info.Parent = panel
    end

    if panel then panel.LayoutOrder = 1 end
end

updateContent()

--// VodoLazikHub FPS PANEL / MENU BUTTON
-- Compact draggable FPS/menu button. Tap = menu, drag = move.
local MenuOpen = false
local openMenu, closeMenu, toggleMenu

local FPSPanel = Instance.new("TextButton")
FPSPanel.Name = "VodoLazikFPSPanel"
FPSPanel.Size = UDim2.fromOffset(235, 42)
FPSPanel.Position = UDim2.new(0, 12, 1, -54)
FPSPanel.AnchorPoint = Vector2.new(0, 0)
FPSPanel.BackgroundColor3 = Color3.fromRGB(10, 14, 19)
FPSPanel.BackgroundTransparency = 0.04
FPSPanel.BorderSizePixel = 0
FPSPanel.Text = ""
FPSPanel.AutoButtonColor = false
FPSPanel.Active = true
FPSPanel.ClipsDescendants = true
FPSPanel.ZIndex = 50
FPSPanel.Parent = ScreenGui

local FPSPanelCorner = Instance.new("UICorner")
FPSPanelCorner.CornerRadius = UDim.new(0, 9)
FPSPanelCorner.Parent = FPSPanel

local FPSPanelStroke = Instance.new("UIStroke")
FPSPanelStroke.Color = Color3.fromRGB(0, 145, 255)
FPSPanelStroke.Thickness = 1.5
FPSPanelStroke.Transparency = 0.05
FPSPanelStroke.Parent = FPSPanel

local FPSGlow = Instance.new("Frame")
FPSGlow.Name = "Glow"
FPSGlow.Size = UDim2.new(1, -12, 0, 2)
FPSGlow.Position = UDim2.fromOffset(6, 2)
FPSGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
FPSGlow.BorderSizePixel = 0
FPSGlow.ZIndex = 51
FPSGlow.Parent = FPSPanel

local FPSGlowCorner = Instance.new("UICorner")
FPSGlowCorner.CornerRadius = UDim.new(1, 0)
FPSGlowCorner.Parent = FPSGlow

local HubTitle = Instance.new("TextLabel")
HubTitle.Name = "HubTitle"
HubTitle.Size = UDim2.new(1, -95, 1, 0)
HubTitle.Position = UDim2.fromOffset(12, 0)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "VodoLazikHub"
HubTitle.TextColor3 = Color3.fromRGB(55, 150, 255)
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextSize = 14
HubTitle.TextXAlignment = Enum.TextXAlignment.Left
HubTitle.TextYAlignment = Enum.TextYAlignment.Center
HubTitle.ZIndex = 52
HubTitle.Parent = FPSPanel

local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.Size = UDim2.fromOffset(1, 25)
Divider.Position = UDim2.new(1, -88, 0.5, -12)
Divider.BackgroundColor3 = Color3.fromRGB(35, 130, 220)
Divider.BackgroundTransparency = 0.15
Divider.BorderSizePixel = 0
Divider.ZIndex = 52
Divider.Parent = FPSPanel

local FPSCaption = Instance.new("TextLabel")
FPSCaption.Name = "FPSCaption"
FPSCaption.Size = UDim2.fromOffset(34, 15)
FPSCaption.Position = UDim2.new(1, -79, 0, 5)
FPSCaption.BackgroundTransparency = 1
FPSCaption.Text = "FPS:"
FPSCaption.TextColor3 = Color3.fromRGB(175, 185, 200)
FPSCaption.Font = Enum.Font.GothamBold
FPSCaption.TextSize = 9
FPSCaption.TextXAlignment = Enum.TextXAlignment.Left
FPSCaption.ZIndex = 52
FPSCaption.Parent = FPSPanel

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Name = "FPSValue"
FPSLabel.Size = UDim2.fromOffset(55, 19)
FPSLabel.Position = UDim2.new(1, -79, 0, 18)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "--"
FPSLabel.TextColor3 = Color3.fromRGB(20, 170, 255)
FPSLabel.Font = Enum.Font.GothamBlack
FPSLabel.TextSize = 15
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.ZIndex = 52
FPSLabel.Parent = FPSPanel

local FPSDot = Instance.new("Frame")
FPSDot.Name = "FPSDot"
FPSDot.Size = UDim2.fromOffset(6, 6)
FPSDot.Position = UDim2.new(1, -12, 0.5, -3)
FPSDot.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
FPSDot.BorderSizePixel = 0
FPSDot.ZIndex = 52
FPSDot.Parent = FPSPanel

local FPSDotCorner = Instance.new("UICorner")
FPSDotCorner.CornerRadius = UDim.new(1, 0)
FPSDotCorner.Parent = FPSDot

local fpsPanelDragging = false
local fpsPanelMoved = false
local fpsDragStart = nil
local fpsStartPosition = nil

local function updateFPSPanelSize()
    local viewport = Camera.ViewportSize
    local width = math.clamp(viewport.X * 0.58, 205, 245)
    local height = math.clamp(viewport.Y * 0.052, 38, 44)
    FPSPanel.Size = UDim2.fromOffset(width, height)

    if not fpsPanelDragging then
        local x = math.clamp(FPSPanel.Position.X.Offset, 0, math.max(viewport.X - width, 0))
        local y = math.clamp(FPSPanel.Position.Y.Offset, 0, math.max(viewport.Y - height, 0))
        FPSPanel.Position = UDim2.fromOffset(x, y)
    end

    HubTitle.TextSize = math.clamp(height * 0.34, 12, 15)
    FPSCaption.TextSize = math.clamp(height * 0.22, 8, 10)
    FPSLabel.TextSize = math.clamp(height * 0.37, 13, 16)
end

local function clampFPSPanelPosition(x, y)
    local viewport = Camera.ViewportSize
    local maxX = math.max(viewport.X - FPSPanel.AbsoluteSize.X, 0)
    local maxY = math.max(viewport.Y - FPSPanel.AbsoluteSize.Y, 0)
    return math.clamp(x, 0, maxX), math.clamp(y, 0, maxY)
end

FPSPanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        fpsPanelDragging = true
        fpsPanelMoved = false
        fpsDragStart = input.Position
        fpsStartPosition = FPSPanel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not fpsPanelDragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - fpsDragStart
        if delta.Magnitude > 5 then
            fpsPanelMoved = true
        end

        local x, y = clampFPSPanelPosition(
            fpsStartPosition.X.Offset + delta.X,
            fpsStartPosition.Y.Offset + delta.Y
        )
        FPSPanel.Position = UDim2.fromOffset(x, y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not fpsPanelDragging then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        fpsPanelDragging = false
    end
end)

FPSPanel.Activated:Connect(function()
    if not fpsPanelMoved then
        toggleMenu()
    end
    fpsPanelMoved = false
end)

updateFPSPanelSize()

--// REAL CLIENT FPS COUNTER
-- RenderStepped is used because it runs once per rendered client frame.
local FPSFrames = 0
local FPSElapsed = 0
local FPSAccumulator = 0
local LastFPS = 60

local function updateRealFPS(deltaTime)
    if deltaTime <= 0 then return end

    FPSFrames += 1
    FPSElapsed += deltaTime

    if FPSElapsed >= 0.25 then
        local measured = FPSFrames / FPSElapsed
        FPSAccumulator = FPSAccumulator == 0 and measured
            or (FPSAccumulator * 0.55 + measured * 0.45)
        LastFPS = math.clamp(math.floor(FPSAccumulator + 0.5), 1, 999)
        FPSLabel.Text = tostring(LastFPS)
        FPSFrames = 0
        FPSElapsed = 0
    end
end

-- Keep the panel on-screen after resolution/orientation changes.
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFPSPanelSize)

--// FOV CIRCLE
local FOVGui = Instance.new("Frame")
FOVGui.Name = "FOVCircle"
FOVGui.AnchorPoint = Vector2.new(0.5, 0.5)
FOVGui.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
FOVGui.BackgroundTransparency = 1
FOVGui.BorderSizePixel = 0
FOVGui.Parent = ScreenGui
FOVGui.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
FOVGui.Position = UDim2.fromOffset(0, 0)
FOVGui.Visible = Config.FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(0, 170, 255)
FOVStroke.Thickness = Config.FOVThickness
FOVStroke.Parent = FOVGui

--// ESP
local ESPCache = {}

local function getCharacter(player)
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not root or not head then return nil end
    return character, humanoid, root, head
end

local function makeESPData(key)
    if ESPCache[key] then return ESPCache[key] end
    local data = {}

    data.highlight = Instance.new("Highlight")
    data.highlight.Name = "VodoLazikChams"
    data.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    data.highlight.FillTransparency = 0.72
    data.highlight.OutlineTransparency = 0
    data.highlight.Enabled = false
    data.highlight.Parent = workspace

    -- 2D box is a screen projection that is recalculated every ESP tick,
    -- so it stays attached to the character instead of being left behind.
    data.box = Instance.new("Frame")
    data.box.Name = "VodoLazik2DBox"
    data.box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    data.box.BackgroundTransparency = 0.78
    data.box.BorderSizePixel = 0
    data.box.Visible = false
    data.box.Parent = ScreenGui

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 2)
    boxCorner.Parent = data.box

    data.edges = {}
    for i = 1, 4 do
        local edge = Instance.new("Frame")
        edge.BorderSizePixel = 0
        edge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        edge.Parent = data.box
        data.edges[i] = edge
    end

    -- Thin green health bar placed to the left of the 2D box.
    data.healthBack = Instance.new("Frame")
    data.healthBack.Name = "HealthBack"
    data.healthBack.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    data.healthBack.BorderSizePixel = 0
    data.healthBack.Visible = false
    data.healthBack.Parent = ScreenGui

    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(0, 2)
    healthCorner.Parent = data.healthBack

    data.healthFill = Instance.new("Frame")
    data.healthFill.Name = "HealthBar"
    data.healthFill.BackgroundColor3 = Color3.fromRGB(55, 220, 80)
    data.healthFill.BorderSizePixel = 0
    data.healthFill.AnchorPoint = Vector2.new(0, 1)
    data.healthFill.Position = UDim2.new(0, 0, 1, 0)
    data.healthFill.Size = UDim2.new(1, 0, 1, 0)
    data.healthFill.Parent = data.healthBack

    local healthFillCorner = Instance.new("UICorner")
    healthFillCorner.CornerRadius = UDim.new(0, 2)
    healthFillCorner.Parent = data.healthFill

    data.tracer = Instance.new("Frame")
    data.tracer.Name = "VodoLazikTracer"
    data.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    data.tracer.BorderSizePixel = 0
    data.tracer.Size = UDim2.fromOffset(0, 1)
    data.tracer.Visible = false
    data.tracer.Parent = ScreenGui

    ESPCache[key] = data
    return data
end

local function hideESP(data)
    data.highlight.Enabled = false
    data.box.Visible = false
    data.healthBack.Visible = false
    data.tracer.Visible = false
end

local function setBox(data, center, size, healthPercent)
    local w = math.clamp(size.X, 12, 600)
    local h = math.clamp(size.Y, 16, 800)
    local x = center.X - w / 2
    local y = center.Y - h / 2
    local t = 2

    data.box.Position = UDim2.fromOffset(x, y)
    data.box.Size = UDim2.fromOffset(w, h)
    data.box.Visible = Config.ESPBox

    -- Black ESP theme with a very subtle dark outline.
    data.box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    data.box.BackgroundTransparency = 0.78
    for _, edge in ipairs(data.edges) do
        edge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    end

    data.edges[1].Position = UDim2.fromOffset(0, 0)
    data.edges[1].Size = UDim2.fromOffset(w, t)
    data.edges[2].Position = UDim2.fromOffset(0, h - t)
    data.edges[2].Size = UDim2.fromOffset(w, t)
    data.edges[3].Position = UDim2.fromOffset(0, 0)
    data.edges[3].Size = UDim2.fromOffset(t, h)
    data.edges[4].Position = UDim2.fromOffset(w - t, 0)
    data.edges[4].Size = UDim2.fromOffset(t, h)

    data.healthBack.Position = UDim2.fromOffset(x - 6, y)
    data.healthBack.Size = UDim2.fromOffset(3, h)
    data.healthBack.Visible = Config.ESPHealth

    local hp = math.clamp(tonumber(healthPercent) or 0, 0, 1)
    data.healthFill.Size = UDim2.new(1, 0, hp, 0)
    data.healthFill.BackgroundColor3 = Color3.fromRGB(55, 220, 80)
end

local function updateESPModel(model, displayName)
    local camera = getCamera()
    if not camera then
        return
    end
    local data = makeESPData(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not root or not head then
        hideESP(data)
        return
    end

    local distance = (camera.CFrame.Position - root.Position).Magnitude
    if Config.DistanceCheck and distance > Config.Distance then
        hideESP(data)
        return
    end

    -- Project the model's actual bounding box so the 2D box follows the whole body.
    local cf, bounds = model:GetBoundingBox()
    local half = bounds * 0.5
    local corners = {
        cf * Vector3.new(-half.X, -half.Y, -half.Z),
        cf * Vector3.new(-half.X, -half.Y,  half.Z),
        cf * Vector3.new(-half.X,  half.Y, -half.Z),
        cf * Vector3.new(-half.X,  half.Y,  half.Z),
        cf * Vector3.new( half.X, -half.Y, -half.Z),
        cf * Vector3.new( half.X, -half.Y,  half.Z),
        cf * Vector3.new( half.X,  half.Y, -half.Z),
        cf * Vector3.new( half.X,  half.Y,  half.Z),
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local visibleCorner = false
    for _, worldPoint in ipairs(corners) do
        local screenPoint, onScreen = camera:WorldToViewportPoint(worldPoint)
        if screenPoint.Z > 0 then
            minX = math.min(minX, screenPoint.X)
            minY = math.min(minY, screenPoint.Y)
            maxX = math.max(maxX, screenPoint.X)
            maxY = math.max(maxY, screenPoint.Y)
            if onScreen then
                visibleCorner = true
            end
        end
    end

    if not visibleCorner or minX == math.huge then
        hideESP(data)
        return
    end

    local boxWidth = math.max(maxX - minX, 12)
    local boxHeight = math.max(maxY - minY, 16)
    local center = Vector2.new((minX + maxX) * 0.5, (minY + maxY) * 0.5)
    local maxHealth = math.max(humanoid.MaxHealth, 1)
    local healthPercent = humanoid.Health / maxHealth

    data.highlight.Adornee = model
    data.highlight.FillColor = Config.ESPColor
    data.highlight.OutlineColor = Config.ESPColor
    data.highlight.FillTransparency = Config.ESPChams and 0.72 or 1
    data.highlight.Enabled = Config.ESPChams

    setBox(data, center, Vector2.new(boxWidth, boxHeight), healthPercent)

    if Config.ESPTracer then
        local screen = camera.ViewportSize
        local from = Vector2.new(screen.X / 2, screen.Y - 5)
        local to = Vector2.new(center.X, maxY)
        local diff = to - from
        data.tracer.Visible = true
        data.tracer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        data.tracer.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
        data.tracer.Size = UDim2.fromOffset(math.max(diff.Magnitude, 1), 1)
        data.tracer.Rotation = math.deg(math.atan2(diff.Y, diff.X))
    else
        data.tracer.Visible = false
    end
end

local function updateESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if character then updateESPModel(character, player.DisplayName) end
end

local NPCModels = {}
local function isNPCModel(obj)
    if not obj:IsA("Model") or Players:GetPlayerFromCharacter(obj) then return false end
    return obj:FindFirstChildOfClass("Humanoid") ~= nil
        and obj:FindFirstChild("HumanoidRootPart") ~= nil
        and obj:FindFirstChild("Head") ~= nil
end

local function addNPCIfValid(obj)
    if isNPCModel(obj) then NPCModels[obj] = true end
end

for _, obj in ipairs(workspace:GetDescendants()) do addNPCIfValid(obj) end
workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj:IsA("Model") then addNPCIfValid(obj) end
        local model = obj:FindFirstAncestorOfClass("Model")
        if model then addNPCIfValid(model) end
    end)
end)
workspace.DescendantRemoving:Connect(function(obj)
    NPCModels[obj] = nil
    ESPCache[obj] = nil
end)

Players.PlayerRemoving:Connect(function(player)
    local data = ESPCache[player.Character]
    if data then for _, object in pairs(data) do pcall(function() object:Destroy() end) end end
    ESPCache[player.Character] = nil
end)

local function cleanupESP()
    for key, data in pairs(ESPCache) do
        if typeof(key) == "Instance" and not key:IsDescendantOf(workspace) then
            for _, object in pairs(data) do pcall(function() object:Destroy() end) end
            ESPCache[key] = nil
        end
    end
end

--// AIM
local function visibleTarget(character, targetPart)
    local camera = getCamera()
    if not camera then
        return false
    end
    if not Config.VisibilityCheck then
        return true
    end

    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        character
    }

    return workspace:Raycast(origin, direction, params) == nil
end

local function getBestTarget()
    local camera = getCamera()
    if not camera then
        return nil, nil
    end
    local bestPlayer = nil
    local bestPart = nil
    local bestScreenDistance = math.huge

    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character, humanoid, root, head = getCharacter(player)

            if character then
                local screenPosition, onScreen = camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local screenDistance = (
                        Vector2.new(screenPosition.X, screenPosition.Y) - center
                    ).Magnitude

                    if screenDistance <= Config.FOV then
                        local worldDistance = (root.Position - camera.CFrame.Position).Magnitude
                        local distanceOK = not Config.DistanceCheck or worldDistance <= Config.Distance

                        if distanceOK
                            and visibleTarget(character, head)
                            and screenDistance < bestScreenDistance then
                            bestScreenDistance = screenDistance
                            bestPlayer = player
                            bestPart = head
                        end
                    end
                end
            end
        end
    end

    return bestPlayer, bestPart
end

--// LIGHTING
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

local function updateLighting()
    if Config.FullBright then
        Lighting.Brightness = Config.Brightness
        Lighting.ClockTime = Config.ClockTime
        Lighting.GlobalShadows = false

        if Config.Fog then
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = OriginalLighting.FogEnd
        end
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.FogEnd = OriginalLighting.FogEnd
    end
end

--// MENU CONTROLS
openMenu = function()
    if MenuOpen then
        return
    end

    MenuOpen = true
    updateMenuScale()
    Main.Visible = true
end

closeMenu = function()
    if not MenuOpen then
        return
    end

    MenuOpen = false
    Main.Visible = false
end

toggleMenu = function()
    if MenuOpen then
        closeMenu()
    else
        openMenu()
    end
end

Close.ZIndex = 100
Close.Active = true
Close.Activated:Connect(closeMenu)

--// RENDER LOOP
local LightingTimer = 0
local ESPTimer = 0
local AimTimer = 0
local BhopHumanoid = nil
local BhopOriginalSpeed = nil
local BhopRoot = nil
local NoclipConnection = nil
local JumpConnection = nil
local JumpCooldown = 0
local JumpHackActive = false
local JumpHackTime = 0
local InfinityJumpUntil = 0
local FlyVertical = 0
local OriginalCollision = {}

-- Mobile-friendly Fly vertical controls.
local FlyControls = Instance.new("Frame")
FlyControls.Name = "VodoLazikFlyControls"
FlyControls.Size = UDim2.fromOffset(116, 54)
FlyControls.AnchorPoint = Vector2.new(1, 0.5)
FlyControls.Position = UDim2.new(1, -12, 0.5, 0)
FlyControls.BackgroundTransparency = 1
FlyControls.Visible = false
FlyControls.Parent = ScreenGui

local function makeFlyButton(name, text, x)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromOffset(52, 52)
    button.Position = UDim2.fromOffset(x, 0)
    button.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
    button.BackgroundTransparency = 0.12
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(235, 240, 245)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 22
    button.AutoButtonColor = false
    button.Parent = FlyControls

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 65, 75)
    stroke.Thickness = 1
    stroke.Parent = button

    return button
end

local FlyUpButton = makeFlyButton("FlyUp", "▲", 0)
local FlyDownButton = makeFlyButton("FlyDown", "▼", 58)

local function bindFlyVerticalButton(button, value)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            FlyVertical = value
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if FlyVertical == value then
                FlyVertical = 0
            end
        end
    end)
end

bindFlyVerticalButton(FlyUpButton, 1)
bindFlyVerticalButton(FlyDownButton, -1)

local function getMovementCharacter()
    local character = LocalPlayer.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid and root and humanoid.Health > 0 then
        return character, humanoid, root
    end
end

-- Keyboard + mobile jump request. JumpRequest is also used by Roblox's mobile jump button.
JumpConnection = UserInputService.JumpRequest:Connect(function()
    local _, humanoid, root = getMovementCharacter()
    if not humanoid or not root then return end

    -- Infinity Jump: immediately restore upward velocity after every jump request.
    if Config.InfinityJump then
        InfinityJumpUntil = os.clock() + 0.12
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(velocity.X, 48, velocity.Z)
    end

    -- Jump Hack: every manual jump starts a smooth CFrame jump arc.
    if Config.JumpHack and not Config.Fly then
        JumpHackActive = true
        JumpHackTime = 0
        JumpCooldown = 0.12
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    if Config.Fly then
        -- Pressing jump while flying means UP. Release returns to level flight.
        FlyVertical = 1
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space and FlyVertical == 1 then
        FlyVertical = 0
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    local camera = getCamera()
    if not camera then return end

    local viewport = camera.ViewportSize
    if viewport.X <= 1 or viewport.Y <= 1 then return end

    -- REAL CLIENT FPS
    updateRealFPS(deltaTime)

    -- FOV: outline only, no fill.
    FOVGui.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)
    FOVGui.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    FOVGui.Visible = Config.FOVCircle
    FOVGui.BackgroundTransparency = 1
    FOVStroke.Thickness = math.clamp(math.floor(Config.FOVThickness + 0.5), 1, 8)

    -- Instant aim.
    AimTimer += deltaTime
    local aimInterval = Config.AntiPing and 0.025 or 0.016
    if Config.SilentAim and AimTimer >= aimInterval then
        AimTimer = 0
        if math.random(1, 100) <= math.clamp(math.floor(Config.HitChance + 0.5), 0, 100) then
            local target, targetPart = getBestTarget()
            if target and targetPart then
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
            end
        end
    end

    -- ESP players + NPCs.
    ESPTimer += deltaTime
    local espInterval = Config.AntiPing and 0.08 or 0.03
    if ESPTimer >= espInterval then
        ESPTimer = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then updateESP(player) end
        end
        for model in pairs(NPCModels) do
            if model:IsDescendantOf(workspace) then
                updateESPModel(model, model.Name)
            else
                NPCModels[model] = nil
            end
        end
        cleanupESP()
    end

    -- MOVEMENT
    local character, humanoid, root = getMovementCharacter()

    if character and humanoid and root then
        -- Bhop: horizontal CFrame movement. Auto-Jump is independent.
        if Config.Bhop then
            if BhopHumanoid ~= humanoid then
                BhopHumanoid = humanoid
                BhopOriginalSpeed = humanoid.WalkSpeed
                BhopRoot = root
            end

            local moveDirection = humanoid.MoveDirection
            if moveDirection.Magnitude > 0.01 then
                local speed = math.clamp(tonumber(Config.BhopSpeed) or 25, 1, 30)
                local step = speed * math.min(deltaTime, 1 / 30)
                root.CFrame = root.CFrame + moveDirection.Unit * step
            end

            -- Auto-Jump ON = automatic jumping. OFF = completely normal jump input.
            if Config.BhopAutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
            end
        elseif BhopHumanoid then
            if BhopHumanoid.Parent and BhopOriginalSpeed then
                BhopHumanoid.WalkSpeed = BhopOriginalSpeed
            end
            BhopHumanoid, BhopOriginalSpeed, BhopRoot = nil, nil, nil
        end

        -- Jump Hack: smooth CFrame arc, activated by the normal jump button/key.
        -- Maximum configured power is 20.
        if Config.JumpHack and not Config.Fly then
            JumpCooldown -= deltaTime

            if JumpHackActive then
                JumpHackTime += deltaTime
                local power = math.clamp(tonumber(Config.JumpPower) or 20, 1, 20)
                local duration = 0.62
                local t = math.clamp(JumpHackTime / duration, 0, 1)

                -- Parabolic arc: rises, reaches the top, then comes back down.
                local height = power * 0.32
                local previousT = math.clamp((JumpHackTime - deltaTime) / duration, 0, 1)
                local previousHeight = 4 * height * previousT * (1 - previousT)
                local currentHeight = 4 * height * t * (1 - t)
                local verticalStep = currentHeight - previousHeight

                if math.abs(verticalStep) > 0.0001 then
                    root.CFrame = root.CFrame + Vector3.new(0, verticalStep, 0)
                end
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

                if t >= 1 then
                    JumpHackActive = false
                    JumpHackTime = 0
                end
            end
        else
            JumpHackActive = false
            JumpHackTime = 0
            JumpCooldown = 0
        end

        -- Infinity Jump reinforcement. This prevents Roblox from cancelling the jump immediately.
        if Config.InfinityJump and os.clock() < InfinityJumpUntil and not Config.Fly then
            local velocity = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, 42), velocity.Z)
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        -- Fly: camera-relative CFrame flight with horizontal + vertical movement.
        if Config.Fly then
            FlyControls.Visible = true

            local speed = math.clamp(tonumber(Config.FlySpeed) or 30, 1, 30)
            local step = speed * math.min(deltaTime, 1 / 30)
            local moveDirection = humanoid.MoveDirection

            -- Horizontal movement follows the mobile thumbstick / WASD.
            if moveDirection.Magnitude > 0.01 then
                root.CFrame = root.CFrame + moveDirection.Unit * step
            end

            -- Vertical movement: mobile buttons, Space, Ctrl, or the normal mobile jump button.
            local vertical = FlyVertical
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                vertical = 1
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.C) then
                vertical = -1
            end

            if vertical ~= 0 then
                root.CFrame = root.CFrame + Vector3.new(0, vertical * step, 0)
            end

            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        else
            FlyControls.Visible = false
            FlyVertical = 0
            if humanoid:GetState() == Enum.HumanoidStateType.Physics then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end

        -- NoClip only changes CanCollide; it does not teleport the character.
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if Config.Noclip then
                    if OriginalCollision[part] == nil then
                        OriginalCollision[part] = part.CanCollide
                    end
                    part.CanCollide = false
                elseif OriginalCollision[part] ~= nil then
                    part.CanCollide = OriginalCollision[part]
                    OriginalCollision[part] = nil
                end
            end
        end
    elseif not Config.Noclip and next(OriginalCollision) then
        for part, wasCollidable in pairs(OriginalCollision) do
            if part and part.Parent then part.CanCollide = wasCollidable end
            OriginalCollision[part] = nil
        end
    end

    -- LIGHTING
    LightingTimer += deltaTime
    if LightingTimer >= 0.1 then
        LightingTimer = 0
        pcall(updateLighting)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    BhopHumanoid, BhopOriginalSpeed, BhopRoot = nil, nil, nil
    JumpHackActive = false
    JumpHackTime = 0
    InfinityJumpUntil = 0
    FlyVertical = 0
    task.wait(1)
    Camera = workspace.CurrentCamera or Camera
end)

updateLighting()
updateMenuScale()


