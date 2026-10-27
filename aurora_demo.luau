--[[
    aurora_demo.luau — Aurora UI dashboard for Roblox executors
    Requires ui_lib.luau (same folder or set LIB_URL).

    Run:
        loadstring(readfile("aurora_demo.luau"))()

    The demo is fully responsive:
      * desktop  — sidebar + two-column dashboard + floating toasts
      * tablet   — narrower sidebar + stacked/2-column adaptive cards
      * mobile   — drawer navigation, full-width cards, 2x2 stats, compact header

    Set LIB_URL if the library is hosted on GitHub and readfile("ui_lib.luau")
    is not available.
]]

local LIB_URL = "https://raw.githubusercontent.com/user/ui-lib/main/ui_lib.luau"

local function getEnvironment()
    local ok, env = pcall(function()
        return getgenv()
    end)
    if ok and type(env) == "table" then
        return env
    end
    return _G
end

local ENV = getEnvironment()

local function resolveLibrary()
    local injected = rawget(ENV, "AuroraUILib")
    if type(injected) == "table" and injected.Window then
        return injected
    end
    local ok, result = pcall(function()
        return loadstring(readfile("ui_lib.luau"))()
    end)
    if ok and type(result) == "table" and result.Window then
        return result
    end
    return loadstring(game:HttpGet(LIB_URL))()
end

local UI = resolveLibrary()
pcall(function()
    local existing = rawget(ENV, "AuroraDemo")
    if type(existing) == "table" and type(existing.destroy) == "function" then
        existing:destroy()
    end
end)
local U = UI.Util
local A = UI.Animator
local Icons = UI.Icons
local Theme = UI.Theme
local Page = UI.Page
local Widgets = UI.Widgets

-- ---------------------------------------------------------------- palette
local C = {
    bg = Color3.fromRGB(6, 8, 17),
    surface = Color3.fromRGB(12, 17, 29),
    elevated = Color3.fromRGB(16, 22, 38),
    card = Color3.fromRGB(13, 18, 31),
    cardSoft = Color3.fromRGB(17, 23, 39),
    text = Color3.fromRGB(238, 244, 255),
    secondary = Color3.fromRGB(132, 145, 172),
    muted = Color3.fromRGB(88, 101, 127),
    success = Color3.fromRGB(61, 220, 151),
    warning = Color3.fromRGB(255, 184, 77),
    danger = Color3.fromRGB(255, 100, 112),
    info = Color3.fromRGB(94, 169, 255),
    white = Color3.fromRGB(255, 255, 255),
    black = Color3.fromRGB(0, 0, 0),
}

local ACCENTS = {
    { name = "Aqua", color = Color3.fromRGB(64, 211, 235) },
    { name = "Violet", color = Color3.fromRGB(139, 104, 255) },
    { name = "Blue", color = Color3.fromRGB(86, 120, 255) },
    { name = "Mint", color = Color3.fromRGB(57, 218, 178) },
    { name = "Rose", color = Color3.fromRGB(238, 92, 158) },
}

local previousTheme = {
    mode = Theme.currentMode(),
    colors = {},
    transparency = {},
    radius = {},
}
for key, value in pairs(Theme.Colors) do
    previousTheme.colors[key] = value
end
for key, value in pairs(Theme.Transparency) do
    previousTheme.transparency[key] = value
end
for key, value in pairs(Theme.Radius) do
    previousTheme.radius[key] = value
end

Theme.patch({
    Colors = {
        background = C.bg,
        surface = C.surface,
        surfaceElevated = C.elevated,
        control = C.white,
        text = C.text,
        textSecondary = C.secondary,
        accent = ACCENTS[1].color,
        success = C.success,
        warning = C.warning,
        danger = C.danger,
        border = C.white,
        shadow = C.black,
        onAccent = C.white,
        overlay = C.black,
    },
    Transparency = {
        window = 0.04,
        surface = 0.12,
        surfaceElevated = 0.10,
        control = 0.08,
        border = 0.86,
        text = 0,
        textSecondary = 0.02,
        noise = 0.94,
        shadow = 0.76,
        backdrop = 0.50,
        hover = 0.06,
        disabled = 0.55,
    },
    Radius = {
        sm = 8,
        md = 12,
        lg = 14,
        xl = 20,
    },
})

-- ---------------------------------------------------------------- utilities
local function shallow(tbl)
    local out = {}
    for key, value in pairs(tbl) do
        out[key] = value
    end
    return out
end

local function applyCorner(instance, radius)
    U.roundCorners(instance, radius)
end

local function makeLabel(parent, properties)
    local defaults = {
        Parent = parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Theme.Typography.Font,
        TextColor3 = C.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
        RichText = false,
    }
    for key, value in pairs(properties or {}) do
        defaults[key] = value
    end
    return U.make("TextLabel", defaults)
end

local function makeIcon(parent, glyph, size, color, position, boxSize)
    return makeLabel(parent, {
        Name = "Icon",
        Text = Icons.get(glyph, glyph),
        Font = Theme.Typography.FontBold,
        TextColor3 = color or C.text,
        TextSize = size or 14,
        Position = position or UDim2.fromOffset(0, 0),
        Size = boxSize or UDim2.fromOffset(18, 18),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
end

local function makeStroke(parent, color, transparency)
    return U.make("UIStroke", {
        Parent = parent,
        Color = color or C.white,
        Transparency = transparency == nil and 0.86 or transparency,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
    })
end

local appBin = U.newBin()
local accentBindings = {}

local function accentBind(callback)
    table.insert(accentBindings, callback)
    pcall(callback, Theme.Colors.accent, Theme)
end

local function refreshAccents()
    for _, callback in ipairs(accentBindings) do
        pcall(callback, Theme.Colors.accent, Theme)
    end
end

appBin:add(Theme.onChange(function()
    refreshAccents()
end))

local function glassCard(parent, radius, colorKey, transparency, wash)
    local frame = U.make("Frame", {
        Parent = parent,
        BackgroundColor3 = Theme.Colors[colorKey or "surfaceElevated"] or C.elevated,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    })
    local handle = U.applyGlass(frame, {
        radius = radius or 14,
        colorKey = colorKey or "surfaceElevated",
        transparency = transparency or 0.10,
        wash = wash ~= false,
        noise = true,
    })
    appBin:add(handle)
    return frame, handle
end

local function addGlow(parent, position, size, color, baseTransparency)
    local layers = U.viewport().X < 760 and 4 or 7
    for index = 1, layers do
        local scale = 1 - (index - 1) * 0.105
        local glow = U.make("Frame", {
            Name = "Glow" .. index,
            Parent = parent,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = position,
            Size = UDim2.fromOffset(size.X * scale, size.Y * scale),
            BackgroundColor3 = color,
            BackgroundTransparency = math.clamp((baseTransparency or 0.86) + (index - 1) * 0.022, 0, 1),
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 1,
        })
        applyCorner(glow, math.min(size.X, size.Y))
    end
end

local function setupWallpaper(root)
    local wallpaper = U.make("Frame", {
        Name = "Wallpaper",
        Parent = root,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 1,
    })

    addGlow(wallpaper, UDim2.fromScale(0.18, 0.12), Vector2.new(980, 980), Color3.fromRGB(94, 44, 255), 0.88)
    addGlow(wallpaper, UDim2.fromScale(0.82, 0.24), Vector2.new(820, 820), Color3.fromRGB(16, 138, 200), 0.91)
    addGlow(wallpaper, UDim2.fromScale(0.62, 0.92), Vector2.new(900, 900), Color3.fromRGB(31, 69, 255), 0.92)
    addGlow(wallpaper, UDim2.fromScale(0.06, 0.82), Vector2.new(620, 620), Color3.fromRGB(200, 44, 170), 0.95)

    local noise = U.make("ImageLabel", {
        Name = "WallpaperNoise",
        Parent = wallpaper,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "rbxassetid://9968344106",
        ImageColor3 = C.white,
        ImageTransparency = 0.90,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(70, 70),
        Active = false,
        ZIndex = 3,
    })
    noise.Name = "WallpaperNoise"

    local shade = U.make("Frame", {
        Name = "Shade",
        Parent = wallpaper,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.black,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 4,
    })
    U.make("UIGradient", {
        Parent = shade,
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.36),
            NumberSequenceKeypoint.new(0.45, 0.56),
            NumberSequenceKeypoint.new(1, 0.72),
        }),
    })

    return wallpaper
end

local function makeControlButton(parent, glyph, dangerHover)
    local button = U.make("TextButton", {
        Name = "WindowControl",
        Parent = parent,
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 20,
    })
    applyCorner(button, 9)
    makeLabel(button, {
        Name = "Glyph",
        Text = glyph,
        Font = Theme.Typography.FontBold,
        TextColor3 = C.secondary,
        TextSize = 16,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 21,
    })
    appBin:connect(button.MouseEnter, function()
        A.tween(button, "controlHover", {
            BackgroundColor3 = dangerHover and C.danger or C.white,
            BackgroundTransparency = dangerHover and 0.82 or 0.90,
        }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    appBin:connect(button.MouseLeave, function()
        A.tween(button, "controlHover", {
            BackgroundColor3 = C.white,
            BackgroundTransparency = 1,
        }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    local feedback = U.feedback(button, {
        radius = 9,
        pressScale = 0.94,
        hoverScale = 1,
    })
    appBin:add(feedback)
    return button
end

local function makeSearchField(parent)
    local field = U.make("Frame", {
        Name = "SearchField",
        Parent = parent,
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(260, 34),
        ZIndex = 5,
    })
    applyCorner(field, 9)
    local glass = U.applyGlass(field, {
        radius = 9,
        colorKey = "surfaceElevated",
        transparency = 0.36,
        noise = false,
        wash = false,
    })
    appBin:add(glass)
    local icon = makeLabel(field, {
        Name = "SearchIcon",
        Text = Icons.search,
        Font = Theme.Typography.FontBold,
        TextColor3 = C.secondary,
        TextSize = 13,
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.fromOffset(16, 34),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 3,
    })
    local box = U.make("TextBox", {
        Name = "SearchInput",
        Parent = field,
        Position = UDim2.fromOffset(33, 0),
        Size = UDim2.new(1, -44, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        PlaceholderText = "Search...",
        PlaceholderColor3 = C.muted,
        TextColor3 = C.text,
        Font = Theme.Typography.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 3,
    })
    local focus = U.focusRing(field, 9)
    appBin:add(focus)
    appBin:connect(box.Focused, function()
        focus:setFocused(true)
    end)
    appBin:connect(box.FocusLost, function()
        focus:setFocused(false)
    end)
    return field, box, icon
end

-- ---------------------------------------------------------------- screen
local gui = U.createScreenGui("AuroraUI")
local root = U.make("Frame", {
    Name = "AuroraRoot",
    Parent = gui,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 10,
})

local wallpaper = setupWallpaper(root)
local app = {}

local window = U.make("Frame", {
    Name = "AuroraWindow",
    Parent = root,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 20,
})
local shadow = U.softShadow(window, {
    radius = 22,
    transparency = 0.72,
})
local windowScale = U.make("UIScale", {
    Name = "WindowScale",
    Parent = window,
    Scale = 1,
})
local glass = U.make("Frame", {
    Name = "Glass",
    Parent = window,
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
    ZIndex = 20,
})
local glassHandle = U.applyGlass(glass, {
    radius = 20,
    colorKey = "surface",
    transparencyKey = "window",
    wash = true,
})
appBin:add(glassHandle)

-- ---------------------------------------------------------------- sidebar
local sidebar = U.make("Frame", {
    Name = "Sidebar",
    Parent = glass,
    Size = UDim2.new(0, 228, 1, 0),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = 0.38,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 100,
})
local sidebarLine = U.make("Frame", {
    Name = "SidebarLine",
    Parent = sidebar,
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = C.white,
    BackgroundTransparency = 0.92,
    BorderSizePixel = 0,
    ZIndex = 26,
})
local sidebarTone = U.make("Frame", {
    Name = "SidebarTone",
    Parent = sidebar,
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.elevated,
    BackgroundTransparency = 0.94,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 24,
})
U.make("UIGradient", {
    Parent = sidebarTone,
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.96),
        NumberSequenceKeypoint.new(0.55, 0.98),
        NumberSequenceKeypoint.new(1, 1),
    }),
})

local brand = U.make("Frame", {
    Name = "Brand",
    Parent = sidebar,
    Position = UDim2.fromOffset(18, 20),
    Size = UDim2.new(1, -36, 0, 44),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 28,
})
local brandLogo = U.make("Frame", {
    Name = "BrandLogo",
    Parent = brand,
    Position = UDim2.fromOffset(0, 1),
    Size = UDim2.fromOffset(40, 40),
    BackgroundColor3 = ACCENTS[1].color,
    BorderSizePixel = 0,
    ZIndex = 29,
})
applyCorner(brandLogo, 20)
local brandGradient = U.make("UIGradient", {
    Parent = brandLogo,
    Rotation = 45,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ACCENTS[1].color:Lerp(C.white, 0.12)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(62, 54, 190)),
    }),
})
makeLabel(brandLogo, {
    Name = "LogoText",
    Text = "✦",
    Font = Theme.Typography.FontBold,
    TextColor3 = C.white,
    TextSize = 20,
    Size = UDim2.fromScale(1, 1),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 30,
})
local brandTitle = makeLabel(brand, {
    Name = "BrandTitle",
    Text = "Aurora UI",
    Font = Theme.Typography.FontBold,
    TextColor3 = C.text,
    TextSize = 15,
    Position = UDim2.fromOffset(50, 5),
    Size = UDim2.new(1, -50, 0, 18),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 30,
})
local brandSubtitle = makeLabel(brand, {
    Name = "BrandSubtitle",
    Text = "v1.0.0",
    TextColor3 = C.secondary,
    TextSize = 10,
    Position = UDim2.fromOffset(50, 23),
    Size = UDim2.new(1, -50, 0, 14),
    ZIndex = 30,
})
accentBind(function(accent)
    brandLogo.BackgroundColor3 = accent
    brandGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent:Lerp(C.white, 0.12)),
        ColorSequenceKeypoint.new(1, accent:Lerp(Color3.fromRGB(42, 36, 120), 0.42)),
    })
end)

local navScroll = U.make("ScrollingFrame", {
    Name = "Navigation",
    Parent = sidebar,
    Position = UDim2.fromOffset(10, 86),
    Size = UDim2.new(1, -20, 1, -196),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 0,
    ClipsDescendants = true,
    ZIndex = 28,
})
U.make("UIListLayout", {
    Parent = navScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
})

local userCard = U.make("Frame", {
    Name = "UserCard",
    Parent = sidebar,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 12, 1, -14),
    Size = UDim2.new(1, -24, 0, 70),
    BackgroundColor3 = C.elevated,
    BorderSizePixel = 0,
    ZIndex = 29,
})
applyCorner(userCard, 13)
local userGlass = U.applyGlass(userCard, {
    radius = 13,
    colorKey = "surfaceElevated",
    transparency = 0.34,
    noise = false,
    wash = false,
})
appBin:add(userGlass)
appBin:add(userGlass)
local userAvatar = U.make("Frame", {
    Name = "Avatar",
    Parent = userCard,
    Position = UDim2.fromOffset(12, 16),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = ACCENTS[1].color,
    BorderSizePixel = 0,
    ZIndex = 31,
})
applyCorner(userAvatar, 19)
U.make("UIGradient", {
    Parent = userAvatar,
    Rotation = 45,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 155, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(83, 91, 240)),
    }),
})
makeLabel(userAvatar, {
    Name = "Initial",
    Text = "U",
    Font = Theme.Typography.FontBold,
    TextColor3 = C.white,
    TextSize = 15,
    Size = UDim2.fromScale(1, 1),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 32,
})
local onlineDot = U.make("Frame", {
    Name = "OnlineDot",
    Parent = userAvatar,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, 1, 1, 1),
    Size = UDim2.fromOffset(10, 10),
    BackgroundColor3 = C.success,
    BorderSizePixel = 0,
    ZIndex = 33,
})
applyCorner(onlineDot, 5)
makeStroke(onlineDot, C.bg, 0.35)
makeLabel(userCard, {
    Name = "UserName",
    Text = "User123",
    Font = Theme.Typography.FontMedium,
    TextColor3 = C.text,
    TextSize = 13,
    Position = UDim2.fromOffset(60, 16),
    Size = UDim2.new(1, -96, 0, 18),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 32,
})
makeLabel(userCard, {
    Name = "UserPlan",
    Text = "Premium",
    TextColor3 = C.secondary,
    TextSize = 10,
    Position = UDim2.fromOffset(60, 34),
    Size = UDim2.new(1, -96, 0, 14),
    ZIndex = 32,
})
local userChevron = makeLabel(userCard, {
    Name = "Chevron",
    Text = Icons.chevronRight,
    Font = Theme.Typography.FontBold,
    TextColor3 = C.muted,
    TextSize = 14,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(14, 20),
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 32,
})
local userHover = U.make("TextButton", {
    Name = "UserHover",
    Parent = userCard,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    Active = true,
    ZIndex = 34,
})

-- ---------------------------------------------------------------- content shell
local contentWrap = U.make("Frame", {
    Name = "ContentWrap",
    Parent = glass,
    Position = UDim2.new(0, 228, 0, 0),
    Size = UDim2.new(1, -228, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 22,
})

local header = U.make("Frame", {
    Name = "Header",
    Parent = contentWrap,
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundTransparency = 0.72,
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ZIndex = 30,
})
U.make("UIGradient", {
    Parent = header,
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.52),
        NumberSequenceKeypoint.new(1, 0.82),
    }),
})
local headerLine = U.make("Frame", {
    Name = "HeaderLine",
    Parent = header,
    Position = UDim2.new(0, 0, 0, 63),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.white,
    BackgroundTransparency = 0.92,
    BorderSizePixel = 0,
    ZIndex = 31,
})
local headerTitle = makeLabel(header, {
    Name = "HeaderTitle",
    Text = "Dashboard",
    Font = Theme.Typography.FontMedium,
    TextColor3 = C.secondary,
    TextSize = 12,
    Position = UDim2.fromOffset(20, 0),
    Size = UDim2.new(1, -380, 1, 0),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 32,
})

local searchField, searchInput = makeSearchField(header)

local minimizeButton = makeControlButton(header, "−", false)
local closeButton = makeControlButton(header, "×", true)
local hamburger = makeControlButton(header, "☰", false)
local searchToggle = makeControlButton(header, Icons.search, false)
hamburger.Visible = false
searchToggle.Visible = false

local mobileSearch = U.make("Frame", {
    Name = "MobileSearch",
    Parent = contentWrap,
    Position = UDim2.fromOffset(0, 64),
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 31,
})
local mobileSearchField, mobileSearchInput = makeSearchField(mobileSearch)
mobileSearchField.Size = UDim2.new(1, -24, 0, 36)
mobileSearchField.Position = UDim2.fromOffset(12, 5)

local body = U.make("Frame", {
    Name = "Body",
    Parent = contentWrap,
    Position = UDim2.fromOffset(0, 64),
    Size = UDim2.new(1, 0, 1, -64),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 22,
})

local homeScroll = U.make("ScrollingFrame", {
    Name = "HomeScroll",
    Parent = body,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0),
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.88,
    ClipsDescendants = true,
    ZIndex = 23,
})
local board = U.make("Frame", {
    Name = "Board",
    Parent = homeScroll,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 800),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 24,
})

local pageHost = U.make("Frame", {
    Name = "PageHost",
    Parent = body,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 23,
})

local drawerScrim = U.make("TextButton", {
    Name = "DrawerScrim",
    Parent = glass,
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.black,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    Active = false,
    Visible = false,
    ZIndex = 90,
})

-- ---------------------------------------------------------------- actions
local appWidgets = {}

local function trackWidget(widget)
    if widget then
        table.insert(appWidgets, widget)
    end
    return widget
end

local function makeButton(parent, options)
    options = options or {}
    local primary = options.Variant == "primary"
    local ghost = options.Variant == "ghost"
    local width = options.Width or 160
    local height = options.Height or 38
    local root = U.make("TextButton", {
        Name = options.Name or "Button",
        Parent = parent,
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = primary and Theme.Colors.accent or C.elevated,
        BackgroundTransparency = primary and 0 or (ghost and 1 or 0.10),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = options.ZIndex or 5,
    })
    applyCorner(root, 10)
    local gradient = nil
    local stroke = makeStroke(root, primary and Theme.Colors.accent or C.white, primary and 0.48 or 0.90)
    local hover = U.make("Frame", {
        Name = "Hover",
        Parent = root,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 2,
    })
    applyCorner(hover, 10)
    if primary then
        gradient = U.make("UIGradient", {
            Parent = root,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Colors.accent:Lerp(C.white, 0.14)),
                ColorSequenceKeypoint.new(1, Theme.Colors.accent),
            }),
        })
    end

    local content = U.make("Frame", {
        Name = "Content",
        Parent = root,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    local alignLeft = options.Align == "left"
    if alignLeft then
        U.make("UIPadding", {
            Parent = content,
            PaddingLeft = UDim.new(0, 13),
            PaddingRight = UDim.new(0, 32),
        })
    else
        U.make("UIPadding", {
            Parent = content,
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        })
    end
    U.make("UIListLayout", {
        Parent = content,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = alignLeft and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 7),
    })
    if options.Icon then
        makeLabel(content, {
            Name = "ButtonIcon",
            Text = Icons.get(options.Icon, options.Icon),
            Font = Theme.Typography.FontBold,
            TextColor3 = primary and C.white or C.secondary,
            TextSize = 13,
            Size = UDim2.fromOffset(16, 18),
            TextXAlignment = Enum.TextXAlignment.Center,
            LayoutOrder = 1,
        })
    end
    local textLabel = makeLabel(content, {
        Name = "ButtonText",
        Text = options.Text or "Button",
        Font = Theme.Typography.FontMedium,
        TextColor3 = primary and C.white or C.text,
        TextSize = 12,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        LayoutOrder = 2,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local chevron = nil
    if options.Chevron then
        chevron = makeLabel(root, {
            Name = "Chevron",
            Text = Icons.chevronRight,
            Font = Theme.Typography.FontBold,
            TextColor3 = C.white,
            TextSize = 14,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -11, 0.5, 0),
            Size = UDim2.fromOffset(14, 18),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 4,
        })
    end

    local feedback = U.feedback(root, {
        radius = 10,
        pressScale = 0.97,
        hoverScale = 1.004,
        onHover = function(isHovered)
            if primary or options.Variant == "danger" then
                A.tween(hover, "buttonHover", {
                    BackgroundTransparency = isHovered and 0.90 or 1,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                A.tween(stroke, "buttonStroke", {
                    Transparency = isHovered and 0.26 or 0.48,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            else
                A.tween(root, "buttonHover", {
                    BackgroundTransparency = isHovered and 0.02 or (ghost and 1 or 0.10),
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            end
        end,
    })
    appBin:add(feedback)

    appBin:connect(root.Activated, function()
        if options.Disabled then
            return
        end
        if type(options.OnClick) == "function" then
            U.safeCall(options.OnClick)
        end
    end)

    if primary then
        accentBind(function(accent)
            root.BackgroundColor3 = accent
            if gradient then
                gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, accent:Lerp(C.white, 0.14)),
                    ColorSequenceKeypoint.new(1, accent),
                })
            end
            stroke.Color = accent
            if chevron then
                chevron.TextColor3 = C.white
            end
        end)
    end

    local object = {
        root = root,
        text = textLabel,
        stroke = stroke,
        gradient = gradient,
        _height = height,
    }
    function object:setText(text)
        textLabel.Text = tostring(text or "")
        return self
    end
    function object:destroy()
        if feedback then
            feedback:destroy()
        end
        root:Destroy()
    end
    return object
end

-- ---------------------------------------------------------------- navigation
local NAV_ITEMS = {
    { id = "home", label = "Home", icon = "home" },
    { id = "settings", label = "Settings", icon = "settings" },
    { id = "components", label = "Components", icon = "grid" },
    { id = "themes", label = "Themes", icon = "palette" },
    { id = "notifications", label = "Notifications", icon = "bell", badge = "3" },
    { id = "profile", label = "Profile", icon = "user" },
    { id = "about", label = "About", icon = "info" },
}

local navButtons = {}
local activePageId = "home"

local function makeNavButton(item, index)
    local root = U.make("TextButton", {
        Name = "Nav_" .. item.id,
        Parent = navScroll,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        LayoutOrder = index,
        ZIndex = 30,
    })
    applyCorner(root, 10)
    local pill = U.make("Frame", {
        Name = "ActivePill",
        Parent = root,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Colors.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        Active = false,
        ZIndex = 1,
    })
    applyCorner(pill, 10)
    local bar = U.make("Frame", {
        Name = "ActiveBar",
        Parent = root,
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(3, 18),
        BackgroundColor3 = Theme.Colors.accent,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 4,
    })
    applyCorner(bar, 2)
    local iconLabel = makeLabel(root, {
        Name = "Icon",
        Text = Icons.get(item.icon, item.icon),
        Font = Theme.Typography.FontBold,
        TextColor3 = C.secondary,
        TextSize = 14,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.fromOffset(18, 42),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 3,
    })
    local label = makeLabel(root, {
        Name = "Label",
        Text = item.label,
        Font = Theme.Typography.FontMedium,
        TextColor3 = C.secondary,
        TextSize = 12,
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -84, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3,
    })
    local badge = nil
    if item.badge then
        badge = U.make("Frame", {
            Name = "Badge",
            Parent = root,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(22, 18),
            BackgroundColor3 = C.white,
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        applyCorner(badge, 8)
        makeLabel(badge, {
            Name = "BadgeText",
            Text = item.badge,
            Font = Theme.Typography.FontBold,
            TextColor3 = C.text,
            TextSize = 10,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 4,
        })
    end

    local active = false
    local object = {}
    function object:setActive(state, animated)
        active = state and true or false
        local duration = animated and Theme.Animation.normal or 0
        if active then
            pill.Visible = true
            bar.Visible = true
            A.tween(pill, "navPill", {
                BackgroundTransparency = 0.84,
            }, duration, Enum.EasingStyle.Quad)
        else
            A.tween(pill, "navPill", {
                BackgroundTransparency = 1,
            }, duration, Enum.EasingStyle.Quad)
            bar.Visible = false
            task.delay(duration, function()
                if not active and pill.Parent then
                    pill.Visible = false
                end
            end)
        end
        A.tween(label, "navText", {
            TextColor3 = active and C.text or C.secondary,
        }, duration, Enum.EasingStyle.Quad)
        A.tween(iconLabel, "navIcon", {
            TextColor3 = active and C.text or C.secondary,
        }, duration, Enum.EasingStyle.Quad)
        A.tween(root, "navHover", {
            BackgroundTransparency = 1,
        }, duration, Enum.EasingStyle.Quad)
    end

    appBin:connect(root.MouseEnter, function()
        if active then
            return
        end
        A.tween(root, "navHover", {
            BackgroundTransparency = 0.95,
        }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    appBin:connect(root.MouseLeave, function()
        if active then
            return
        end
        A.tween(root, "navHover", {
            BackgroundTransparency = 1,
        }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    local feedback = U.feedback(root, {
        radius = 10,
        pressScale = 1,
        hoverScale = 1,
    })
    appBin:add(feedback)
    appBin:connect(root.Activated, function()
        if app and app.setPage then
            app:setPage(item.id)
        end
    end)
    accentBind(function(accent)
        pill.BackgroundColor3 = accent
        bar.BackgroundColor3 = accent
        if badge then
            badge.BackgroundColor3 = accent
        end
        if active then
            label.TextColor3 = C.text
            iconLabel.TextColor3 = C.text
        end
    end)

    local entry = {
        item = item,
        root = root,
        label = label,
        icon = iconLabel,
        pill = pill,
        bar = bar,
        badge = badge,
        active = false,
        setActive = object.setActive,
    }
    function entry:setActive(state, animated)
        self.active = state and true or false
        object.setActive(self, state, animated)
    end
    navButtons[item.id] = entry
    return entry
end

for index, item in ipairs(NAV_ITEMS) do
    makeNavButton(item, index)
end

-- ---------------------------------------------------------------- home cards
local homeCards = {}
local session = {
    accentIndex = 1,
    volume = 70,
    message = "",
    page = "home",
}

local function makeCard(parent, name, colorKey, transparency)
    local card = U.make("Frame", {
        Name = name,
        Parent = parent,
        BackgroundColor3 = C.elevated,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 25,
    })
    local handle = U.applyGlass(card, {
        radius = 14,
        colorKey = colorKey or "surfaceElevated",
        transparency = transparency or 0.10,
        wash = true,
        noise = true,
    })
    appBin:add(handle)
    return card, handle
end

local function makeSectionHeader(card, titleText, subtitleText, rightText)
    local title = makeLabel(card, {
        Name = "CardTitle",
        Text = titleText,
        Font = Theme.Typography.FontMedium,
        TextColor3 = C.text,
        TextSize = 13,
        Position = UDim2.fromOffset(16, 13),
        Size = UDim2.new(1, rightText and -130 or -32, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3,
    })
    local subtitle = nil
    if subtitleText then
        subtitle = makeLabel(card, {
            Name = "CardSubtitle",
            Text = subtitleText,
            TextColor3 = C.secondary,
            TextSize = 10,
            Position = UDim2.fromOffset(16, 32),
            Size = UDim2.new(1, -32, 0, 14),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 3,
        })
    end
    local right = nil
    if rightText then
        right = makeLabel(card, {
            Name = "CardRight",
            Text = rightText,
            Font = Theme.Typography.FontMedium,
            TextColor3 = Theme.Colors.accent,
            TextSize = 10,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -16, 0, 22),
            Size = UDim2.fromOffset(90, 16),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 3,
        })
        accentBind(function(accent)
            if right then
                right.TextColor3 = accent
            end
        end)
    end
    return title, subtitle, right
end

-- profile -----------------------------------------------------------
local profileCard = U.make("Frame", {
    Name = "ProfileCard",
    Parent = board,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 25,
})
local profileAvatar = U.make("Frame", {
    Name = "ProfileAvatar",
    Parent = profileCard,
    Position = UDim2.fromOffset(18, 20),
    Size = UDim2.fromOffset(64, 64),
    BackgroundColor3 = Color3.fromRGB(122, 88, 255),
    BorderSizePixel = 0,
    ZIndex = 26,
})
applyCorner(profileAvatar, 32)
local profileGradient = U.make("UIGradient", {
    Parent = profileAvatar,
    Rotation = 45,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(197, 139, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(67, 101, 245)),
    }),
})
makeLabel(profileAvatar, {
    Name = "AvatarInitial",
    Text = "U",
    Font = Theme.Typography.FontBold,
    TextColor3 = C.white,
    TextSize = 24,
    Size = UDim2.fromScale(1, 1),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 27,
})
local profileDot = U.make("Frame", {
    Name = "Online",
    Parent = profileAvatar,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, 2, 1, 2),
    Size = UDim2.fromOffset(13, 13),
    BackgroundColor3 = C.success,
    BorderSizePixel = 0,
    ZIndex = 28,
})
applyCorner(profileDot, 7)
makeStroke(profileDot, C.surface, 0.2)
makeLabel(profileCard, {
    Name = "Welcome",
    Text = "Welcome back,",
    TextColor3 = C.secondary,
    TextSize = 11,
    Position = UDim2.fromOffset(100, 21),
    Size = UDim2.new(1, -130, 0, 15),
    ZIndex = 26,
})
local profileName = makeLabel(profileCard, {
    Name = "Name",
    Text = "User123",
    Font = Theme.Typography.FontBold,
    TextColor3 = C.text,
    TextSize = 24,
    Position = UDim2.fromOffset(100, 35),
    Size = UDim2.new(1, -220, 0, 30),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 26,
})
local profileSubtitle = makeLabel(profileCard, {
    Name = "Subtitle",
    Text = "Good to see you again. Here's what's new today.",
    TextColor3 = C.secondary,
    TextSize = 10,
    Position = UDim2.fromOffset(100, 67),
    Size = UDim2.new(1, -130, 0, 15),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 26,
})
local premiumPill = U.make("Frame", {
    Name = "PremiumPill",
    Parent = profileCard,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 20),
    Size = UDim2.fromOffset(74, 24),
    BackgroundColor3 = Theme.Colors.accent,
    BackgroundTransparency = 0.82,
    BorderSizePixel = 0,
    ZIndex = 27,
})
applyCorner(premiumPill, 12)
local premiumLabel = makeLabel(premiumPill, {
    Name = "PremiumText",
    Text = "PREMIUM",
    Font = Theme.Typography.FontBold,
    TextColor3 = Theme.Colors.accent,
    TextSize = 9,
    Size = UDim2.fromScale(1, 1),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 28,
})
accentBind(function(accent)
    premiumPill.BackgroundColor3 = accent
    premiumLabel.TextColor3 = accent
end)
homeCards.profile = profileCard

-- stats -------------------------------------------------------------
local statData = {
    { label = "Total Users", value = "12,394", delta = "↗ 12%", glyph = "users" },
    { label = "Active Sessions", value = "3,248", delta = "↗ 8%", glyph = "box" },
    { label = "Performance", value = "98%", delta = "↗ 2%", glyph = "bolt" },
    { label = "Uptime", value = "99.9%", delta = "↗ 0.1%", glyph = "clock" },
}
local statCards = {}
for index, data in ipairs(statData) do
    local card = makeCard(board, "Stat" .. index, "surfaceElevated", 0.08)
    local iconFrame = U.make("Frame", {
        Name = "StatIconFrame",
        Parent = card,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = Theme.Colors.accent,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 26,
    })
    applyCorner(iconFrame, 9)
    local icon = makeLabel(iconFrame, {
        Name = "StatIcon",
        Text = Icons.get(data.glyph, data.glyph),
        Font = Theme.Typography.FontBold,
        TextColor3 = Theme.Colors.accent,
        TextSize = 14,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 27,
    })
    local label = makeLabel(card, {
        Name = "StatLabel",
        Text = data.label,
        TextColor3 = C.secondary,
        TextSize = 10,
        Position = UDim2.fromOffset(14, 56),
        Size = UDim2.new(1, -28, 0, 14),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 26,
    })
    local value = makeLabel(card, {
        Name = "StatValue",
        Text = data.value,
        Font = Theme.Typography.FontBold,
        TextColor3 = C.text,
        TextSize = 22,
        Position = UDim2.fromOffset(14, 70),
        Size = UDim2.new(1, -82, 0, 29),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 26,
    })
    local delta = makeLabel(card, {
        Name = "StatDelta",
        Text = data.delta,
        Font = Theme.Typography.FontMedium,
        TextColor3 = C.success,
        TextSize = 10,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -13, 0, 86),
        Size = UDim2.fromOffset(66, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 26,
    })
    accentBind(function(accent)
        iconFrame.BackgroundColor3 = accent
        icon.TextColor3 = accent
    end)
    table.insert(statCards, card)
end
homeCards.stats = statCards

-- quick controls ----------------------------------------------------
local quickCard = makeCard(board, "QuickControls", "surfaceElevated", 0.06)
makeSectionHeader(quickCard, "Quick Controls", "Try out some of the available components.")
local quickBody = U.make("Frame", {
    Name = "QuickBody",
    Parent = quickCard,
    Position = UDim2.fromOffset(16, 54),
    Size = UDim2.new(1, -32, 0, 278),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 26,
})

local primaryButton = makeButton(quickBody, {
    Name = "Primary",
    Text = "Primary Button",
    Variant = "primary",
    Icon = "play",
    Chevron = true,
    Align = "left",
    Width = 170,
    Height = 36,
    ZIndex = 27,
    OnClick = function()
        if app.toast then
            app:toast("success", "Action complete", "Primary action executed successfully.", 4200)
        end
    end,
})
primaryButton.root.Position = UDim2.fromOffset(0, 0)

local secondaryButton = makeButton(quickBody, {
    Name = "Secondary",
    Text = "Secondary Button",
    Variant = "secondary",
    Width = 160,
    Height = 36,
    ZIndex = 27,
    OnClick = function()
        if app.toast then
            app:toast("info", "Secondary action", "Nothing critical happened.", 3500)
        end
    end,
})
secondaryButton.root.Position = UDim2.fromOffset(0, 0)

local quickToggle = trackWidget(Widgets.toggle(quickBody, {
    Text = "Enable Feature",
    Description = "Toggle this setting to see the effect.",
    Value = true,
    OnChange = function(state)
        if state then
            -- intentionally quiet; the switch itself is the feedback
        end
    end,
}))
quickToggle._instance.Position = UDim2.fromOffset(0, 46)
quickToggle._instance.Size = UDim2.new(1, 0, 0, 58)
quickToggle._instance.BackgroundColor3 = C.white
quickToggle._instance.BackgroundTransparency = 1

local quickSlider = trackWidget(Widgets.slider(quickBody, {
    Text = "Volume",
    Min = 0,
    Max = 100,
    Value = session.volume,
    Step = 1,
    Suffix = "%",
    OnChange = function(value)
        session.volume = value
    end,
}))
quickSlider._instance.Position = UDim2.fromOffset(0, 108)
quickSlider._instance.Size = UDim2.new(1, 0, 0, 70)

local quickDropdown = trackWidget(Widgets.dropdown(quickBody, {
    Text = "Select Option",
    Options = {
        { Text = "Option 1", Value = "one" },
        { Text = "Option 2", Value = "two" },
        { Text = "Option 3", Value = "three" },
    },
    Value = "one",
    OnChange = function(value)
        if app.toast then
            app:toast("info", "Selection changed", "Selected " .. tostring(value) .. ".", 3000)
        end
    end,
}))
quickDropdown._instance.Position = UDim2.fromOffset(0, 184)
quickDropdown._instance.Size = UDim2.new(1, 0, 0, 50)

local messageFrame = U.make("Frame", {
    Name = "MessageField",
    Parent = quickBody,
    Position = UDim2.fromOffset(0, 240),
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = C.elevated,
    BorderSizePixel = 0,
    ZIndex = 28,
})
applyCorner(messageFrame, 10)
local messageGlass = U.applyGlass(messageFrame, {
    radius = 10,
    colorKey = "surfaceElevated",
    transparency = 0.34,
    noise = false,
    wash = false,
})
appBin:add(messageGlass)
local messageBox = U.make("TextBox", {
    Name = "MessageInput",
    Parent = messageFrame,
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -50, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    PlaceholderText = "Type a message...",
    PlaceholderColor3 = C.muted,
    TextColor3 = C.text,
    Font = Theme.Typography.Font,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 29,
})
local messageFocus = U.focusRing(messageFrame, 10)
appBin:add(messageFocus)
appBin:connect(messageBox.Focused, function()
    messageFocus:setFocused(true)
end)
appBin:connect(messageBox.FocusLost, function(enterPressed)
    messageFocus:setFocused(false)
    if enterPressed then
        local text = messageBox.Text
        if text ~= "" then
            session.message = text
            messageBox.Text = ""
            if app.toast then
                app:toast("success", "Message sent", text, 3000)
            end
        end
    end
end)
local sendButton = U.make("TextButton", {
    Name = "Send",
    Parent = messageFrame,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -6, 0.5, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Theme.Colors.accent,
    BackgroundTransparency = 0.84,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    Active = true,
    ZIndex = 30,
})
applyCorner(sendButton, 8)
local sendIcon = makeLabel(sendButton, {
    Name = "SendIcon",
    Text = "➤",
    Font = Theme.Typography.FontBold,
    TextColor3 = Theme.Colors.accent,
    TextSize = 12,
    Size = UDim2.fromScale(1, 1),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 31,
})
accentBind(function(accent)
    sendButton.BackgroundColor3 = accent
    sendIcon.TextColor3 = accent
end)
appBin:connect(sendButton.Activated, function()
    local text = messageBox.Text
    if text ~= "" then
        session.message = text
        messageBox.Text = ""
        if app.toast then
            app:toast("success", "Message sent", text, 3000)
        end
    end
end)
homeCards.quick = quickCard

-- system status -----------------------------------------------------
local statusCard = makeCard(board, "SystemStatus", "surfaceElevated", 0.08)
makeSectionHeader(statusCard, "System Status", "Everything looks good!")
local statusRows = {
    { label = "API Connection", icon = "link", status = "Online" },
    { label = "Database", icon = "database", status = "Online" },
    { label = "Services", icon = "cloud", status = "Online" },
    { label = "Game Server", icon = "controller", status = "Running" },
}
for index, data in ipairs(statusRows) do
    local row = U.make("Frame", {
        Name = "StatusRow" .. index,
        Parent = statusCard,
        Position = UDim2.fromOffset(14, 57 + (index - 1) * 43),
        Size = UDim2.new(1, -28, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 26,
    })
    local iconFrame = U.make("Frame", {
        Name = "IconFrame",
        Parent = row,
        Position = UDim2.fromOffset(0, 5),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 27,
    })
    applyCorner(iconFrame, 8)
    local icon = makeLabel(iconFrame, {
        Name = "Icon",
        Text = Icons.get(data.icon, data.icon),
        Font = Theme.Typography.FontBold,
        TextColor3 = C.secondary,
        TextSize = 11,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 28,
    })
    local label = makeLabel(row, {
        Name = "Label",
        Text = data.label,
        TextColor3 = C.text,
        TextSize = 11,
        Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -110, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 27,
    })
    local dot = U.make("Frame", {
        Name = "Dot",
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -47, 0.5, 0),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = C.success,
        BorderSizePixel = 0,
        ZIndex = 27,
    })
    applyCorner(dot, 3)
    makeLabel(row, {
        Name = "Status",
        Text = data.status,
        TextColor3 = C.success,
        TextSize = 10,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(42, 14),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 27,
    })
end
homeCards.status = statusCard

-- theme preview -----------------------------------------------------
local themeCard = makeCard(board, "ThemePreview", "surfaceElevated", 0.08)
makeSectionHeader(themeCard, "Theme Preview", "Current theme: Dark Glass")
local swatchButtons = {}
local swatchHolder = U.make("Frame", {
    Name = "Swatches",
    Parent = themeCard,
    Position = UDim2.fromOffset(16, 55),
    Size = UDim2.new(1, -32, 0, 30),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 26,
})
for index, preset in ipairs(ACCENTS) do
    local swatch = U.make("TextButton", {
        Name = "Swatch" .. index,
        Parent = swatchHolder,
        Position = UDim2.fromOffset((index - 1) * 35, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = preset.color,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 27,
    })
    applyCorner(swatch, 14)
    local ring = makeStroke(swatch, C.white, index == 1 and 0.30 or 0.82)
    ring.Thickness = 2
    local object = { root = swatch, ring = ring, index = index, color = preset.color }
    local swatchColor = preset.color
    local swatchIndex = index
    appBin:connect(swatch.Activated, function()
        if app.setAccent then
            app:setAccent(swatchColor, swatchIndex)
        end
    end)
    table.insert(swatchButtons, object)
end

local themeButton = makeButton(themeCard, {
    Text = "Change Theme",
    Variant = "secondary",
    Icon = "refresh",
    Width = 160,
    Height = 34,
    ZIndex = 27,
    OnClick = function()
        if app.cycleAccent then
            app:cycleAccent()
        end
    end,
})
themeButton.root.Position = UDim2.fromOffset(16, 100)
homeCards.theme = themeCard

-- recent activity ---------------------------------------------------
local activityCard = makeCard(board, "RecentActivity", "surfaceElevated", 0.08)
makeSectionHeader(activityCard, "Recent Activity", "Here's what's been happening recently.", "View all")
local activities = {
    { title = "New user registered", time = "2 minutes ago", icon = "user", color = C.success },
    { title = "System update completed", time = "12 minutes ago", icon = "settings", color = C.accent },
    { title = "Theme changed", time = "1 hour ago", icon = "palette", color = C.warning },
}
for index, data in ipairs(activities) do
    local row = U.make("TextButton", {
        Name = "Activity" .. index,
        Parent = activityCard,
        Position = UDim2.fromOffset(12, 55 + (index - 1) * 50),
        Size = UDim2.new(1, -24, 0, 44),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 26,
    })
    applyCorner(row, 9)
    local iconFrame = U.make("Frame", {
        Name = "IconFrame",
        Parent = row,
        Position = UDim2.fromOffset(8, 7),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = data.color,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 27,
    })
    applyCorner(iconFrame, 9)
    makeLabel(iconFrame, {
        Name = "Icon",
        Text = Icons.get(data.icon, data.icon),
        Font = Theme.Typography.FontBold,
        TextColor3 = data.color,
        TextSize = 11,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 28,
    })
    makeLabel(row, {
        Name = "Title",
        Text = data.title,
        TextColor3 = C.text,
        TextSize = 11,
        Position = UDim2.fromOffset(48, 7),
        Size = UDim2.new(1, -90, 0, 16),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 27,
    })
    makeLabel(row, {
        Name = "Time",
        Text = data.time,
        TextColor3 = C.secondary,
        TextSize = 9,
        Position = UDim2.fromOffset(48, 23),
        Size = UDim2.new(1, -90, 0, 13),
        ZIndex = 27,
    })
    makeLabel(row, {
        Name = "Chevron",
        Text = Icons.chevronRight,
        Font = Theme.Typography.FontBold,
        TextColor3 = C.muted,
        TextSize = 13,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(14, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 27,
    })
    appBin:connect(row.MouseEnter, function()
        A.tween(row, "activityHover", { BackgroundTransparency = 0.94 }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    appBin:connect(row.MouseLeave, function()
        A.tween(row, "activityHover", { BackgroundTransparency = 1 }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    local activityTitle = data.title
    local activityTime = data.time
    appBin:connect(row.Activated, function()
        if app.toast then
            app:toast("info", activityTitle, activityTime, 3000)
        end
    end)
end
homeCards.activity = activityCard

-- notifications card ------------------------------------------------
local notificationCard = makeCard(board, "NotificationsCard", "surfaceElevated", 0.08)
makeSectionHeader(notificationCard, "Notifications", "Stay updated with important events.")
local miniNotifications = {
    { title = "Success", text = "Your changes have been saved.", time = "2m", type = "success", icon = "checkCircle" },
    { title = "Info", text = "New update available.", time = "12m", type = "info", icon = "info" },
    { title = "Warning", text = "Some features may be limited.", time = "1h", type = "warning", icon = "warning" },
}
for index, data in ipairs(miniNotifications) do
    local color = data.type == "success" and C.success or (data.type == "warning" and C.warning or C.info)
    local row = U.make("Frame", {
        Name = "MiniNotification" .. index,
        Parent = notificationCard,
        Position = UDim2.fromOffset(14, 55 + (index - 1) * 48),
        Size = UDim2.new(1, -28, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 26,
    })
    local iconFrame = U.make("Frame", {
        Name = "IconFrame",
        Parent = row,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        ZIndex = 27,
    })
    applyCorner(iconFrame, 8)
    makeLabel(iconFrame, {
        Name = "Icon",
        Text = Icons.get(data.icon, data.icon),
        Font = Theme.Typography.FontBold,
        TextColor3 = color,
        TextSize = 11,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 28,
    })
    makeLabel(row, {
        Name = "Title",
        Text = data.title,
        Font = Theme.Typography.FontMedium,
        TextColor3 = C.text,
        TextSize = 10,
        Position = UDim2.fromOffset(34, 4),
        Size = UDim2.new(1, -74, 0, 14),
        ZIndex = 27,
    })
    makeLabel(row, {
        Name = "Text",
        Text = data.text,
        TextColor3 = C.secondary,
        TextSize = 9,
        Position = UDim2.fromOffset(34, 19),
        Size = UDim2.new(1, -74, 0, 12),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 27,
    })
    makeLabel(row, {
        Name = "Time",
        Text = data.time,
        TextColor3 = C.muted,
        TextSize = 9,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(24, 14),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 27,
    })
end
homeCards.notifications = notificationCard

-- ---------------------------------------------------------------- toasts
local toastHolder = U.make("Frame", {
    Name = "Toasts",
    Parent = root,
    Position = UDim2.fromOffset(0, 16),
    Size = UDim2.fromOffset(300, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 200,
})
U.make("UIListLayout", {
    Parent = toastHolder,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Top,
})
local toastItems = {}
local toastSequence = 0

local function toastColor(kind)
    if kind == "success" then
        return C.success
    elseif kind == "warning" then
        return C.warning
    elseif kind == "danger" then
        return C.danger
    end
    return C.info
end

local function toastIcon(kind)
    if kind == "success" then
        return "checkCircle"
    elseif kind == "warning" then
        return "warning"
    elseif kind == "danger" then
        return "xCircle"
    end
    return "info"
end

local function removeToast(item, instant)
    if not item or item.removed then
        return
    end
    item.removed = true
    if item.timer then
        pcall(task.cancel, item.timer)
        item.timer = nil
    end
    A.cancelAll(item.card)
    for index = #toastItems, 1, -1 do
        if toastItems[index] == item then
            table.remove(toastItems, index)
            break
        end
    end
    local function finish()
        item.bin:destroy()
        item.glass:destroy()
        item.card:Destroy()
    end
    if instant then
        finish()
    else
        A.tween(item.scale, "toastOut", {
            Scale = 0.90,
        }, Theme.Animation.fast, Enum.EasingStyle.Quad)
        task.delay(Theme.Animation.fast, finish)
    end
end

local function pushToast(kind, titleText, bodyText, duration)
    local color = toastColor(kind)
    while #toastItems >= 4 do
        removeToast(toastItems[1], true)
    end
    toastSequence = toastSequence + 1
    local itemBin = U.newBin()
    local card = U.make("Frame", {
        Name = "Toast",
        Parent = toastHolder,
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundColor3 = C.elevated,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = toastSequence,
        ZIndex = 201,
    })
    local glass = U.applyGlass(card, {
        radius = 14,
        colorKey = "surfaceElevated",
        transparency = 0.03,
        wash = true,
        noise = true,
    })
    itemBin:add(glass)
    local scale = U.make("UIScale", { Parent = card, Scale = 0.94 })
    local iconFrame = U.make("Frame", {
        Name = "IconFrame",
        Parent = card,
        Position = UDim2.fromOffset(11, 19),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 202,
    })
    applyCorner(iconFrame, 9)
    makeLabel(iconFrame, {
        Name = "Icon",
        Text = Icons.get(toastIcon(kind), toastIcon(kind)),
        Font = Theme.Typography.FontBold,
        TextColor3 = color,
        TextSize = 11,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 203,
    })
    local titleLabel = makeLabel(card, {
        Name = "Title",
        Text = titleText,
        Font = Theme.Typography.FontMedium,
        TextColor3 = C.text,
        TextSize = 11,
        Position = UDim2.fromOffset(49, 13),
        Size = UDim2.new(1, -78, 0, 16),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 202,
    })
    local bodyLabel = makeLabel(card, {
        Name = "Text",
        Text = bodyText,
        TextColor3 = C.secondary,
        TextSize = 9,
        Position = UDim2.fromOffset(49, 30),
        Size = UDim2.new(1, -64, 0, 22),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 202,
    })
    local close = U.make("TextButton", {
        Name = "Close",
        Parent = card,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 8),
        Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 204,
    })
    applyCorner(close, 6)
    makeLabel(close, {
        Name = "X",
        Text = Icons.close,
        Font = Theme.Typography.FontBold,
        TextColor3 = C.secondary,
        TextSize = 12,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 205,
    })
    local item = {
        kind = kind,
        card = card,
        bin = itemBin,
        glass = glass,
        scale = scale,
        timer = nil,
        removed = false,
    }
    table.insert(toastItems, item)
    itemBin:connect(close.MouseEnter, function()
        A.tween(close, "toastCloseHover", { BackgroundTransparency = 0.88 }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    itemBin:connect(close.MouseLeave, function()
        A.tween(close, "toastCloseHover", { BackgroundTransparency = 1 }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    end)
    itemBin:connect(close.Activated, function()
        removeToast(item, false)
    end)
    itemBin:add(Theme.onChange(function()
        titleLabel.TextColor3 = C.text
        bodyLabel.TextColor3 = C.secondary
    end))
    task.defer(function()
        if not item.removed then
            A.tween(scale, "toastIn", { Scale = 1 }, Theme.Animation.normal, Enum.EasingStyle.Back)
        end
    end)
    if duration and duration > 0 then
        item.timer = task.delay(duration / 1000, function()
            removeToast(item, false)
        end)
    end
    return item
end

-- ---------------------------------------------------------------- restore pill
local restorePill = U.make("TextButton", {
    Name = "RestorePill",
    Parent = root,
    Position = UDim2.fromOffset(16, 16),
    Size = UDim2.fromOffset(176, 42),
    BackgroundColor3 = C.elevated,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    Active = true,
    Visible = false,
    ZIndex = 220,
})
applyCorner(restorePill, 12)
local restoreGlass = U.applyGlass(restorePill, {
    radius = 12,
    colorKey = "surfaceElevated",
    transparency = 0.04,
    wash = true,
    noise = true,
})
appBin:add(restoreGlass)
makeLabel(restorePill, {
    Name = "RestoreIcon",
    Text = "▣",
    Font = Theme.Typography.FontBold,
    TextColor3 = Theme.Colors.accent,
    TextSize = 14,
    Position = UDim2.fromOffset(13, 0),
    Size = UDim2.fromOffset(18, 42),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 221,
})
makeLabel(restorePill, {
    Name = "RestoreText",
    Text = "Restore Window",
    TextColor3 = C.text,
    TextSize = 11,
    Position = UDim2.fromOffset(38, 0),
    Size = UDim2.new(1, -50, 1, 0),
    ZIndex = 221,
})
local restoreScale = U.make("UIScale", { Parent = restorePill, Scale = 0.92 })
local restoreFeedback = U.feedback(restorePill, {
    radius = 12,
    pressScale = 0.97,
    hoverScale = 1,
})
appBin:add(restoreFeedback)
local restoreIcon = restorePill:FindFirstChild("RestoreIcon")
accentBind(function(accent)
    if restoreIcon then
        restoreIcon.TextColor3 = accent
    end
end)

-- ---------------------------------------------------------------- secondary pages
local pageViews = {}
local pageOrder = { "settings", "components", "themes", "notifications", "profile", "about" }

local function newPage(id)
    local page = Page.wrap(pageHost)
    page._scroll.Visible = false
    page._scroll.ZIndex = 24
    pageViews[id] = page
    return page
end

local function buildSettingsPage()
    local p = newPage("settings")
    p:heading("Settings")
    p:paragraph("Tune Aurora to your setup. Everything here is local to this session.")
    p:section("Interface", function(s)
        s:toggle({
            Text = "Reduce transparency",
            Description = "Less glass, more contrast.",
            Value = false,
            OnChange = function(state)
                if state and app.toast then
                    app:toast("info", "Interface", "Reduced transparency is a demo setting.", 3000)
                end
            end,
        })
        s:toggle({ Text = "Show FPS", Value = true })
        s:dropdown({
            Text = "Language",
            Options = { { Text = "English", Value = "en" }, { Text = "Русский", Value = "ru" } },
            Value = "en",
        })
    end)
    p:section("Audio", function(s)
        s:slider({ Text = "UI Volume", Min = 0, Max = 100, Value = 70, Suffix = "%" })
        s:toggle({ Text = "Mute interface sounds", Value = false })
    end)
    p:section("Navigation", function(s)
        s:tabs({ Tabs = { { Text = "Comfort" }, { Text = "Compact" }, { Text = "Spacious" } } })
    end)
end

local function buildComponentsPage()
    local p = newPage("components")
    p:heading("Components")
    p:paragraph("A quick gallery of the UI primitives used by Aurora.")
    p:section("Buttons", function(s)
        s:row(function(r)
            r:button({
                Text = "Primary",
                Variant = "primary",
                Icon = "play",
                OnClick = function()
                    if app.toast then
                        app:toast("success", "Primary", "Primary button pressed.", 2600)
                    end
                end,
            })
            r:button({ Text = "Secondary", Variant = "secondary" })
            r:button({ Text = "Ghost", Variant = "ghost" })
        end)
    end)
    p:section("Inputs", function(s)
        s:toggle({ Text = "Demo switch", Description = "A toggle description.", Value = true })
        s:slider({ Text = "Range", Min = 0, Max = 100, Value = 64, Suffix = "%" })
        s:dropdown({ Text = "Weapon", Options = { { Text = "Sword" }, { Text = "Bow" } } })
        s:textinput({ Placeholder = "Type something...", Value = "" })
        s:keybind({ Text = "Toggle menu", Value = Enum.KeyCode.RightShift })
        s:colorpicker({ Text = "Highlight", Value = ACCENTS[1].color })
    end)
    p:section("Feedback", function(s)
        s:badge({ Text = "NEW", Color = ACCENTS[1].color })
        s:progress({ Value = 0.72, ShowPercent = true })
        s:avatar({ Name = "User123", Status = "online" })
        s:stat({ Label = "Performance", Value = "98%", Delta = "+2%", DeltaPositive = true })
    end)
    p:section("Data", function(s)
        s:tabs({ Tabs = { { Text = "Overview" }, { Text = "Details" } } })
        s:list({
            Items = {
                { Icon = "user", Text = "Profile", Description = "Account", Right = "›" },
                { Icon = "shield", Text = "Security", Description = "Keys", Right = "›" },
            },
            OnSelect = function(item)
                if app.toast then
                    app:toast("info", item.Text, "List item selected.", 2500)
                end
            end,
        })
    end)
end

local function buildThemesPage()
    local p = newPage("themes")
    p:heading("Themes")
    p:paragraph("Change the accent without rebuilding the interface. The glass, nav and controls animate together.")
    p:section("Accent presets", function(s)
        for index, preset in ipairs(ACCENTS) do
            local presetColor = preset.color
            local presetIndex = index
            s:button({
                Text = preset.name,
                Variant = index == session.accentIndex and "primary" or "secondary",
                Icon = "palette",
                OnClick = function()
                    if app.setAccent then
                        app:setAccent(presetColor, presetIndex)
                    end
                end,
            })
        end
    end)
    p:section("Preview", function(s)
        s:row(function(r)
            r:badge({ Text = "LIVE", Color = Theme.Colors.accent })
            r:chip({ Text = "Liquid Glass", Icon = "sparkles" })
        end)
        s:progress({ Value = 0.84, ShowPercent = true })
    end)
end

local function buildNotificationsPage()
    local p = newPage("notifications")
    p:heading("Notifications")
    p:paragraph("The floating cards at the top-right are app-level toasts. Trigger a few from here.")
    p:row(function(r)
        r:button({
            Text = "Success toast",
            Variant = "primary",
            Icon = "check",
            OnClick = function()
                if app.toast then
                    app:toast("success", "Success", "Operation completed successfully.", 4000)
                end
            end,
        })
        r:button({
            Text = "Warning toast",
            Variant = "secondary",
            Icon = "warning",
            OnClick = function()
                if app.toast then
                    app:toast("warning", "Warning", "Some features may be limited.", 4000)
                end
            end,
        })
    end)
    p:section("Latest", function(s)
        s:list({
            Items = {
                { Icon = "checkCircle", Text = "Success", Description = "Your changes have been saved.", Right = "2m" },
                { Icon = "info", Text = "Info", Description = "New update available.", Right = "12m" },
                { Icon = "warning", Text = "Warning", Description = "Some features may be limited.", Right = "1h" },
            },
        })
    end)
end

local function buildProfilePage()
    local p = newPage("profile")
    p:heading("Profile")
    p:paragraph("A compact account view built with the same primitives.")
    p:row(function(r)
        r:avatar({ Name = "User123", Status = "online" })
        r:stat({ Label = "Sessions", Value = "24", Delta = "+4", DeltaPositive = true })
    end)
    p:section("Account", function(s)
        s:textinput({ Placeholder = "Display name", Value = "User123", Icon = "user" })
        s:dropdown({ Text = "Plan", Options = { { Text = "Premium" }, { Text = "Free" } }, Value = "Premium" })
        s:button({ Text = "Save profile", Variant = "primary" })
    end)
    p:section("Activity", function(s)
        s:progress({ Value = 0.66, ShowPercent = true })
        s:badge({ Text = "12 days active", Color = C.success })
    end)
    p:paragraph("Your account has been active for 12 days this month.")
end

local function buildAboutPage()
    local p = newPage("about")
    p:heading("About Aurora")
    p:paragraph("Aurora UI is a responsive Liquid Glass demo for Roblox executors. It uses one local UI library file, no external modules, and a single ScreenGui.")
    p:separator({ Text = "BUILD" })
    p:row(function(r)
        r:badge({ Text = "v1.0.0" })
        r:badge({ Text = "Luau", Color = C.success })
        r:badge({ Text = "Responsive", Color = C.info })
    end)
    p:card({
        Title = "Desktop + mobile",
        Description = "Sidebar navigation on desktop, drawer navigation on mobile, adaptive card grid.",
        Icon = "monitor",
        OnClick = function()
            if app.toast then
                app:toast("info", "Responsive", "Resize the viewport to see the layout adapt.", 3500)
            end
        end,
    })
    p:paragraph("Theme changes animate through the shared Animator. Every card, button and toast has its own cleanup path.")
end

buildSettingsPage()
buildComponentsPage()
buildThemesPage()
buildNotificationsPage()
buildProfilePage()
buildAboutPage()

-- ---------------------------------------------------------------- layout
local isMobileLayout = false
local drawerOpen = false
local mobileSearchOpen = false
local sidebarWidth = 228
local appVisible = true

local PAGE_LABELS = {
    home = "Dashboard",
    settings = "Settings",
    components = "Components",
    themes = "Themes",
    notifications = "Notifications",
    profile = "Profile",
    about = "About",
}

local function pageLabel(id)
    return PAGE_LABELS[id] or "Dashboard"
end

local function getInsets()
    local guiService = game:GetService("GuiService")
    local ok, topLeft, bottomRight = pcall(function()
        return guiService:GetGuiInset()
    end)
    if ok and topLeft then
        return topLeft.Y or 0, (bottomRight and bottomRight.Y) or 0
    end
    return 0, 0
end

local function setSidebarState(animated)
    if isMobileLayout then
        local targetX = drawerOpen and 0 or -sidebarWidth
        if animated then
            A.tween(sidebar, "drawerSlide", {
                Position = UDim2.fromOffset(targetX, 0),
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
        else
            sidebar.Position = UDim2.fromOffset(targetX, 0)
        end
        drawerScrim.Visible = drawerOpen
        drawerScrim.Active = drawerOpen
        if animated then
            A.tween(drawerScrim, "drawerScrim", {
                BackgroundTransparency = drawerOpen and 0.45 or 1,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
        else
            drawerScrim.BackgroundTransparency = drawerOpen and 0.45 or 1
        end
        if appVisible then
            toastHolder.Visible = not drawerOpen
        end
    else
        drawerOpen = false
        sidebar.Position = UDim2.fromOffset(0, 0)
        drawerScrim.Visible = false
        drawerScrim.Active = false
    end
end

local function setDrawer(open, animated)
    if not isMobileLayout then
        drawerOpen = false
        setSidebarState(false)
        return
    end
    open = open and true or false
    if open == drawerOpen then
        setSidebarState(animated ~= false)
        return
    end
    drawerOpen = open
    setSidebarState(animated ~= false)
end

local function layoutHome(contentW, mobile)
    local pad = mobile and 12 or 22
    local gap = mobile and 10 or 14
    local innerW = math.max(220, contentW - pad * 2)
    local columns = innerW >= 860 and 4 or 2
    local statsRows = math.ceil(4 / columns)
    local statW = math.floor((innerW - (columns - 1) * gap) / columns)
    local profileH = mobile and 118 or 106
    local statsH = 102
    local quickH = 350
    local statusH = 232
    local themeH = 152
    local activityH = 216
    local notifH = 216

    profileCard.Position = UDim2.fromOffset(pad, pad)
    profileCard.Size = UDim2.fromOffset(innerW, profileH)

    local statsTop = pad + profileH + gap
    for index, card in ipairs(statCards) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        card.Position = UDim2.fromOffset(pad + column * (statW + gap), statsTop + row * (statsH + gap))
        card.Size = UDim2.fromOffset(statW, statsH)
    end

    local statsBottom = statsTop + statsRows * statsH + (statsRows - 1) * gap
    local contentTop = statsBottom + gap
    local twoCol = (not mobile) and innerW >= 640
    local boardHeight
    local quickWidth
    if twoCol then
        local leftW = math.floor((innerW - gap) * 0.66)
        local rightW = innerW - leftW - gap
        quickWidth = leftW
        quickCard.Position = UDim2.fromOffset(pad, contentTop)
        quickCard.Size = UDim2.fromOffset(leftW, quickH)
        activityCard.Position = UDim2.fromOffset(pad, contentTop + quickH + gap)
        activityCard.Size = UDim2.fromOffset(leftW, activityH)
        statusCard.Position = UDim2.fromOffset(pad + leftW + gap, contentTop)
        statusCard.Size = UDim2.fromOffset(rightW, statusH)
        themeCard.Position = UDim2.fromOffset(pad + leftW + gap, contentTop + statusH + gap)
        themeCard.Size = UDim2.fromOffset(rightW, themeH)
        notificationCard.Position = UDim2.fromOffset(
            pad + leftW + gap,
            contentTop + statusH + gap + themeH + gap
        )
        notificationCard.Size = UDim2.fromOffset(rightW, notifH)
        local leftBottom = contentTop + quickH + gap + activityH
        local rightBottom = contentTop + statusH + gap + themeH + gap + notifH
        boardHeight = math.max(leftBottom, rightBottom) + pad
    else
        quickWidth = innerW
        local y = contentTop
        quickCard.Position = UDim2.fromOffset(pad, y)
        quickCard.Size = UDim2.fromOffset(innerW, quickH)
        y = y + quickH + gap
        statusCard.Position = UDim2.fromOffset(pad, y)
        statusCard.Size = UDim2.fromOffset(innerW, statusH)
        y = y + statusH + gap
        activityCard.Position = UDim2.fromOffset(pad, y)
        activityCard.Size = UDim2.fromOffset(innerW, activityH)
        y = y + activityH + gap
        themeCard.Position = UDim2.fromOffset(pad, y)
        themeCard.Size = UDim2.fromOffset(innerW, themeH)
        y = y + themeH + gap
        notificationCard.Position = UDim2.fromOffset(pad, y)
        notificationCard.Size = UDim2.fromOffset(innerW, notifH)
        y = y + notifH
        boardHeight = y + pad
    end

    quickBody.Size = UDim2.new(1, -32, 0, 278)
    quickBody.Position = UDim2.fromOffset(16, 54)
    local quickInner = math.max(220, quickWidth - 32)
    local primaryW = math.floor(quickInner * 0.56)
    local secondaryW = quickInner - primaryW - 8
    primaryButton.root.Size = UDim2.fromOffset(primaryW, 36)
    primaryButton.root.Position = UDim2.fromOffset(0, 0)
    secondaryButton.root.Size = UDim2.fromOffset(secondaryW, 36)
    secondaryButton.root.Position = UDim2.fromOffset(primaryW + 8, 0)
    themeButton.root.Size = UDim2.new(1, -32, 0, 34)
    themeButton.root.Position = UDim2.fromOffset(16, 100)

    board.Size = UDim2.new(1, 0, 0, boardHeight)
    homeScroll.CanvasSize = UDim2.fromOffset(0, boardHeight)
end

local function applyLayout()
    if app._destroyed then
        return
    end
    local vp = U.viewport()
    local topInset, bottomInset = getInsets()
    local mobile = vp.X < 760
    isMobileLayout = mobile
    local toastOutside = vp.X >= 1240 and not mobile
    local margin = mobile and 6 or 16
    local windowY = margin + topInset
    local width
    local height
    if mobile then
        width = math.max(300, vp.X - 12)
        height = math.max(420, vp.Y - margin * 2 - topInset - bottomInset)
    else
        width = math.min(1320, toastOutside and (vp.X - 350) or (vp.X - 32))
        width = math.max(720, width)
        height = vp.Y - margin * 2 - topInset - bottomInset
    end

    window.Position = UDim2.fromOffset(margin, windowY)
    window.Size = UDim2.fromOffset(width, height)

    sidebarWidth = mobile and 244 or (width < 1050 and 204 or 228)
    local headerH = mobile and 56 or 64
    local contentW = width - (mobile and 0 or sidebarWidth)

    sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
    if mobile then
        sidebar.Position = UDim2.fromOffset(drawerOpen and 0 or -sidebarWidth, 0)
        contentWrap.Position = UDim2.fromOffset(0, 0)
        contentWrap.Size = UDim2.fromScale(1, 1)
    else
        sidebar.Position = UDim2.fromOffset(0, 0)
        contentWrap.Position = UDim2.fromOffset(sidebarWidth, 0)
        contentWrap.Size = UDim2.new(1, -sidebarWidth, 1, 0)
    end

    header.Size = UDim2.new(1, 0, 0, headerH)
    headerLine.Position = UDim2.new(0, 0, 0, headerH - 1)
    headerTitle.Position = UDim2.fromOffset(mobile and 50 or 18, 0)
    headerTitle.Size = UDim2.new(1, mobile and -150 or -380, 1, 0)
    headerTitle.Text = pageLabel(activePageId)

    local controlSize = mobile and 32 or 28
    closeButton.Size = UDim2.fromOffset(controlSize, controlSize)
    minimizeButton.Size = UDim2.fromOffset(controlSize, controlSize)
    searchToggle.Size = UDim2.fromOffset(controlSize, controlSize)
    hamburger.Size = UDim2.fromOffset(controlSize, controlSize)
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.Position = UDim2.new(1, mobile and -12 or -14, 0.5, 0)
    minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
    minimizeButton.Position = UDim2.new(1, mobile and -50 or -48, 0.5, 0)
    searchToggle.AnchorPoint = Vector2.new(1, 0.5)
    searchToggle.Position = UDim2.new(1, mobile and -88 or -82, 0.5, 0)
    hamburger.AnchorPoint = Vector2.new(0, 0.5)
    hamburger.Position = UDim2.new(0, 12, 0.5, 0)
    hamburger.Visible = mobile
    searchToggle.Visible = mobile

    local showSearch = (not mobile) and contentW >= 600
    searchField.Visible = showSearch
    headerTitle.Visible = mobile or not showSearch
    if showSearch then
        local searchW = math.clamp(math.floor(contentW * 0.31), 180, 264)
        searchField.Size = UDim2.fromOffset(searchW, 34)
        searchField.Position = UDim2.fromOffset(contentW - 84 - searchW, math.floor((headerH - 34) / 2))
    end

    mobileSearch.Visible = mobile and mobileSearchOpen
    mobileSearch.Position = UDim2.fromOffset(0, headerH)
    mobileSearch.Size = UDim2.new(1, 0, 0, 46)
    mobileSearchField.Size = UDim2.new(1, -24, 0, 36)
    mobileSearchField.Position = UDim2.fromOffset(12, 5)

    local bodyTop = headerH + (mobile and mobileSearchOpen and 46 or 0)
    body.Position = UDim2.fromOffset(0, bodyTop)
    body.Size = UDim2.new(1, 0, 1, -bodyTop)

    if mobile then
        drawerScrim.Visible = drawerOpen
        drawerScrim.Active = drawerOpen
        if drawerOpen then
            sidebar.Position = UDim2.fromOffset(0, 0)
        end
    else
        drawerOpen = false
        mobileSearchOpen = false
        drawerScrim.Visible = false
        drawerScrim.Active = false
        if appVisible then
            toastHolder.Visible = true
        end
    end

    layoutHome(contentW, mobile)

    local toastWidth = mobile and (vp.X - 16) or 300
    local toastX = mobile and 8 or (vp.X - toastWidth - 16)
    local toastY = mobile
        and (windowY + 64 + (mobileSearchOpen and 46 or 0))
        or (toastOutside and windowY or (windowY + headerH + 10))
    toastHolder.Size = UDim2.fromOffset(toastWidth, 0)
    toastHolder.Position = UDim2.fromOffset(toastX, toastY)

    restorePill.Size = UDim2.fromOffset(mobile and 166 or 176, 42)
    restorePill.Position = UDim2.fromOffset(
        mobile and 10 or 16,
        vp.Y - bottomInset - (mobile and 54 or 58)
    )
end

-- ---------------------------------------------------------------- public methods
function app:toast(kind, titleText, bodyText, duration)
    if self._destroyed then
        return nil
    end
    return pushToast(kind, titleText, bodyText, duration)
end

function app:setPage(id)
    if self._destroyed then
        return self
    end
    local target = nil
    for _, item in ipairs(NAV_ITEMS) do
        if item.id == id then
            target = item
            break
        end
    end
    if not target then
        return self
    end
    activePageId = id
    session.page = id
    for _, item in ipairs(NAV_ITEMS) do
        local button = navButtons[item.id]
        if button then
            button:setActive(item.id == id, true)
        end
    end
    headerTitle.Text = pageLabel(id)
    if id == "home" then
        homeScroll.Visible = true
        pageHost.Visible = false
        for _, page in pairs(pageViews) do
            page._scroll.Visible = false
        end
    else
        homeScroll.Visible = false
        pageHost.Visible = true
        for key, page in pairs(pageViews) do
            local visible = key == id
            page._scroll.Visible = visible
            if visible then
                page:scrollToTop(false)
            end
        end
    end
    if isMobileLayout then
        setDrawer(false)
    end
    return self
end

function app:setDrawer(open)
    if self._destroyed then
        return self
    end
    setDrawer(open, true)
    return self
end

function app:setMobileSearch(open)
    if self._destroyed or not isMobileLayout then
        return self
    end
    mobileSearchOpen = open and true or false
    applyLayout()
    if mobileSearchOpen then
        pcall(function()
            mobileSearchInput:CaptureFocus()
        end)
    end
    return self
end

function app:setAccent(color, index, silent)
    if self._destroyed or typeof(color) ~= "Color3" then
        return self
    end
    local targetIndex = index
    if not targetIndex then
        for i, preset in ipairs(ACCENTS) do
            if preset.color == color then
                targetIndex = i
                break
            end
        end
    end
    session.accentIndex = targetIndex or session.accentIndex
    Theme.setAccent(color)
    for _, swatch in ipairs(swatchButtons) do
        A.tween(swatch.ring, "swatchRing", {
            Transparency = swatch.index == session.accentIndex and 0.18 or 0.82,
        }, Theme.Animation.normal, Enum.EasingStyle.Quad)
    end
    if not silent and appVisible then
        local name = ACCENTS[session.accentIndex] and ACCENTS[session.accentIndex].name or "Custom"
        pushToast("info", "Theme updated", name .. " accent applied.", 3000)
    end
    return self
end

function app:cycleAccent()
    local nextIndex = (session.accentIndex % #ACCENTS) + 1
    local preset = ACCENTS[nextIndex]
    return self:setAccent(preset.color, nextIndex)
end

function app:minimize()
    if not appVisible or self._destroyed then
        return self
    end
    appVisible = false
    setDrawer(false, false)
    toastHolder.Visible = true
    A.tween(windowScale, "windowScale", {
        Scale = 0.96,
    }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    task.delay(Theme.Animation.fast + 0.02, function()
        if appVisible or self._destroyed then
            return
        end
        window.Visible = false
        restorePill.Visible = true
        restoreScale.Scale = 0.92
        A.tween(restoreScale, "restoreIn", {
            Scale = 1,
        }, Theme.Animation.normal, Enum.EasingStyle.Back)
    end)
    return self
end

function app:close()
    if not appVisible or self._destroyed then
        return self
    end
    appVisible = false
    setDrawer(false, false)
    A.tween(windowScale, "windowScale", {
        Scale = 0.96,
    }, Theme.Animation.fast, Enum.EasingStyle.Quad)
    task.delay(Theme.Animation.fast + 0.02, function()
        if appVisible or self._destroyed then
            return
        end
        window.Visible = false
        wallpaper.Visible = false
        toastHolder.Visible = false
        restorePill.Visible = true
        restoreScale.Scale = 0.92
        A.tween(restoreScale, "restoreIn", {
            Scale = 1,
        }, Theme.Animation.normal, Enum.EasingStyle.Back)
    end)
    return self
end

function app:restore()
    if self._destroyed then
        return self
    end
    if appVisible then
        restorePill.Visible = false
        return self
    end
    appVisible = true
    wallpaper.Visible = true
    toastHolder.Visible = true
    restorePill.Visible = false
    window.Visible = true
    applyLayout()
    windowScale.Scale = 0.96
    A.tween(windowScale, "windowScale", {
        Scale = 1,
    }, Theme.Animation.normal, Enum.EasingStyle.Back)
    return self
end

function app:isOpen()
    return appVisible
end

function app:getGui()
    return gui
end

function app:destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    for index = #toastItems, 1, -1 do
        removeToast(toastItems[index], true)
    end
    for _, page in pairs(pageViews) do
        pcall(page.destroy, page)
    end
    pageViews = {}
    for _, widget in ipairs(appWidgets) do
        pcall(widget.destroy, widget)
    end
    appWidgets = {}
    appBin:destroy()
    if previousTheme.mode then
        Theme.setMode(previousTheme.mode)
    end
    Theme.patch({
        Colors = previousTheme.colors,
        Transparency = previousTheme.transparency,
        Radius = previousTheme.radius,
    })
    if shadow then
        shadow:destroy()
    end
    if glassHandle then
        glassHandle:destroy()
    end
    A.cancelAll(window)
    if rawget(ENV, "AuroraDemo") == self then
        pcall(function()
            ENV.AuroraDemo = nil
        end)
    end
    pcall(function()
        gui:Destroy()
    end)
end

-- ---------------------------------------------------------------- wiring
appBin:connect(minimizeButton.Activated, function()
    app:minimize()
end)
appBin:connect(closeButton.Activated, function()
    app:close()
end)
appBin:connect(hamburger.Activated, function()
    app:setDrawer(not drawerOpen)
end)
appBin:connect(searchToggle.Activated, function()
    app:setMobileSearch(not mobileSearchOpen)
end)
appBin:connect(drawerScrim.Activated, function()
    app:setDrawer(false)
end)
appBin:connect(restorePill.Activated, function()
    app:restore()
end)
appBin:connect(userHover.Activated, function()
    app:setPage("profile")
end)
appBin:connect(userHover.MouseEnter, function()
    userGlass:setTransparency(0.24)
end)
appBin:connect(userHover.MouseLeave, function()
    userGlass:setTransparency(0.34)
end)

local function handleSearchLost(enterPressed)
    local text = searchInput.Text
    if text == "" and mobileSearchInput then
        text = mobileSearchInput.Text
    end
    if enterPressed and text ~= "" and appVisible then
        pushToast("info", "Search", "Search is a visual demo for \"" .. tostring(text) .. "\".", 3200)
    end
end
appBin:connect(searchInput.FocusLost, handleSearchLost)
appBin:connect(mobileSearchInput.FocusLost, function(enterPressed)
    handleSearchLost(enterPressed)
    if isMobileLayout then
        app:setMobileSearch(false)
    end
end)

local camera = workspace.CurrentCamera
if camera then
    appBin:connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
        task.defer(applyLayout)
    end)
end

-- initial state
appVisible = true
setDrawer(false, false)
applyLayout()
app:setPage("home")
if U.viewport().X < 760 then
    pushToast("success", "Success", "Operation completed successfully.", 5500)
else
    pushToast("success", "Success", "Operation completed successfully.", 0)
    pushToast("info", "Info", "New update is available.", 0)
    pushToast("warning", "Warning", "Some features may be limited.", 0)
end

pcall(function()
    ENV.AuroraDemo = app
end)
return app



