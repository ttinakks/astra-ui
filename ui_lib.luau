--[[
    ui_lib.luau — Liquid Glass UI Library for Roblox executors
    Version 1.0.0

    Single-file library. No require(), no external modules, no Studio-only APIs.
    Load with:
        local UI = loadstring(readfile("ui_lib.luau"))()
        local UI = loadstring(game:HttpGet("https://.../ui_lib.luau"))()

    Notes:
    * Roblox does not expose a real backdrop-blur for ScreenGui. The glass is
      simulated with layered translucency, visible noise grain, accent wash,
      a bright top rim, a dark lower edge and soft shadow stacks.
    * Every visual component is destroyable. Every user callback is guarded so
      one broken callback cannot take down the whole interface.
    * Parent is always assigned last through Util.make().
]]

local _mods = {}
local _cache = {}
local _loading = {}

local function _get(name)
    local cached = _cache[name]
    if cached ~= nil then
        return cached
    end
    local ctor = _mods[name]
    if type(ctor) ~= "function" then
        error("[ui_lib] unknown module: " .. tostring(name), 2)
    end
    if _loading[name] then
        error("[ui_lib] circular module dependency: " .. tostring(name), 2)
    end
    _loading[name] = true
    local ok, result = pcall(ctor)
    _loading[name] = nil
    if not ok then
        error("[ui_lib] failed to build module " .. tostring(name) .. ": " .. tostring(result), 2)
    end
    _cache[name] = result
    return result
end

--====================================================================--
-- THEME
--====================================================================--
_mods["Theme"] = function()
    local Theme = {}

    local DARK_COLORS = {
        background = Color3.fromRGB(10, 10, 15),
        surface = Color3.fromRGB(26, 26, 31),
        surfaceElevated = Color3.fromRGB(38, 38, 45),
        control = Color3.fromRGB(255, 255, 255),
        text = Color3.fromRGB(245, 245, 247),
        textSecondary = Color3.fromRGB(155, 155, 165),
        accent = Color3.fromRGB(10, 132, 255),
        success = Color3.fromRGB(48, 209, 88),
        warning = Color3.fromRGB(255, 159, 10),
        danger = Color3.fromRGB(255, 69, 58),
        border = Color3.fromRGB(255, 255, 255),
        shadow = Color3.fromRGB(3, 3, 8),
        onAccent = Color3.fromRGB(255, 255, 255),
        overlay = Color3.fromRGB(0, 0, 0),
    }

    local LIGHT_COLORS = {
        background = Color3.fromRGB(245, 245, 247),
        surface = Color3.fromRGB(255, 255, 255),
        surfaceElevated = Color3.fromRGB(255, 255, 255),
        control = Color3.fromRGB(0, 0, 0),
        text = Color3.fromRGB(28, 28, 30),
        textSecondary = Color3.fromRGB(110, 110, 115),
        accent = Color3.fromRGB(10, 132, 255),
        success = Color3.fromRGB(52, 199, 89),
        warning = Color3.fromRGB(255, 149, 0),
        danger = Color3.fromRGB(255, 59, 48),
        border = Color3.fromRGB(0, 0, 0),
        shadow = Color3.fromRGB(44, 44, 53),
        onAccent = Color3.fromRGB(255, 255, 255),
        overlay = Color3.fromRGB(0, 0, 0),
    }

    local DARK_TRANSPARENCY = {
        window = 0.08,
        surface = 0.24,
        surfaceElevated = 0.12,
        control = 0.10,
        border = 0.82,
        text = 0.00,
        textSecondary = 0.20,
        noise = 0.93,
        shadow = 0.78,
        backdrop = 0.48,
        hover = 0.06,
        disabled = 0.55,
    }

    local LIGHT_TRANSPARENCY = {
        window = 0.04,
        surface = 0.16,
        surfaceElevated = 0.07,
        control = 0.05,
        border = 0.88,
        text = 0.00,
        textSecondary = 0.16,
        noise = 0.95,
        shadow = 0.86,
        backdrop = 0.35,
        hover = 0.05,
        disabled = 0.50,
    }

    Theme.Colors = {
        background = DARK_COLORS.background,
        surface = DARK_COLORS.surface,
        surfaceElevated = DARK_COLORS.surfaceElevated,
        control = DARK_COLORS.control,
        text = DARK_COLORS.text,
        textSecondary = DARK_COLORS.textSecondary,
        accent = DARK_COLORS.accent,
        success = DARK_COLORS.success,
        warning = DARK_COLORS.warning,
        danger = DARK_COLORS.danger,
        border = DARK_COLORS.border,
        shadow = DARK_COLORS.shadow,
        onAccent = DARK_COLORS.onAccent,
        overlay = DARK_COLORS.overlay,
    }

    Theme.Transparency = {
        window = DARK_TRANSPARENCY.window,
        surface = DARK_TRANSPARENCY.surface,
        surfaceElevated = DARK_TRANSPARENCY.surfaceElevated,
        control = DARK_TRANSPARENCY.control,
        border = DARK_TRANSPARENCY.border,
        text = DARK_TRANSPARENCY.text,
        textSecondary = DARK_TRANSPARENCY.textSecondary,
        noise = DARK_TRANSPARENCY.noise,
        shadow = DARK_TRANSPARENCY.shadow,
        backdrop = DARK_TRANSPARENCY.backdrop,
        hover = DARK_TRANSPARENCY.hover,
        disabled = DARK_TRANSPARENCY.disabled,
    }

    Theme.Typography = {
        Font = Enum.Font.Gotham,
        FontMedium = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
        Size = {
            caption = 11,
            small = 13,
            body = 15,
            title = 20,
            display = 28,
        },
    }

    Theme.Spacing = {
        xs = 4,
        sm = 8,
        md = 12,
        lg = 16,
        xl = 24,
    }

    Theme.Radius = {
        sm = 8,
        md = 12,
        lg = 16,
        xl = 24,
    }

    Theme.Animation = {
        fast = 0.15,
        normal = 0.25,
        slow = 0.40,
    }

    -- Lower-case aliases are intentional: both Theme.Colors and Theme.colors
    -- point at the same mutable table, so custom components can use either.
    Theme.colors = Theme.Colors
    Theme.transparency = Theme.Transparency
    Theme.typography = Theme.Typography
    Theme.spacing = Theme.Spacing
    Theme.radius = Theme.Radius
    Theme.animation = Theme.Animation

    Theme.Version = "1.0.0"
    Theme._mode = "dark"
    Theme._listeners = {}

    local function is_table(value)
        return type(value) == "table"
    end

    local function clear_table(target)
        for key in pairs(target) do
            target[key] = nil
        end
    end

    local function replace_table(target, source)
        clear_table(target)
        for key, value in pairs(source) do
            target[key] = value
        end
    end

    local function merge_table(target, source)
        for key, value in pairs(source) do
            if is_table(value) and is_table(target[key]) then
                merge_table(target[key], value)
            else
                target[key] = value
            end
        end
    end

    local function normalize_patch(patch)
        if not is_table(patch) then
            return nil
        end
        local out = {}
        for key, value in pairs(patch) do
            local mapped = key
            if key == "colors" then
                mapped = "Colors"
            elseif key == "transparency" then
                mapped = "Transparency"
            elseif key == "typography" then
                mapped = "Typography"
            elseif key == "spacing" then
                mapped = "Spacing"
            elseif key == "radius" then
                mapped = "Radius"
            elseif key == "animation" then
                mapped = "Animation"
            end
            out[mapped] = value
        end
        return out
    end

    function Theme.onChange(callback)
        if type(callback) ~= "function" then
            return function() end
        end
        table.insert(Theme._listeners, callback)
        local connected = true
        return function()
            if not connected then
                return
            end
            connected = false
            for index = #Theme._listeners, 1, -1 do
                if Theme._listeners[index] == callback then
                    table.remove(Theme._listeners, index)
                    break
                end
            end
        end
    end

    local function notify()
        local snapshot = {}
        for index, callback in ipairs(Theme._listeners) do
            snapshot[index] = callback
        end
        for _, callback in ipairs(snapshot) do
            local ok, err = pcall(callback, Theme)
            if not ok then
                Theme.lastError = tostring(err)
            end
        end
    end

    local function set_mode_internal(mode)
        if mode ~= "light" and mode ~= "dark" then
            return false
        end
        local accent = Theme.Colors.accent
        if mode == "light" then
            replace_table(Theme.Colors, LIGHT_COLORS)
            replace_table(Theme.Transparency, LIGHT_TRANSPARENCY)
        else
            replace_table(Theme.Colors, DARK_COLORS)
            replace_table(Theme.Transparency, DARK_TRANSPARENCY)
        end
        Theme.Colors.accent = accent
        Theme._mode = mode
        return true
    end

    function Theme.patch(patch)
        local normalized = normalize_patch(patch)
        if not normalized then
            return Theme
        end

        local mode = normalized.Mode
        normalized.Mode = nil
        if mode then
            set_mode_internal(mode)
        end

        if normalized.Accent ~= nil then
            local accent = normalized.Accent
            if typeof(accent) == "Color3" then
                Theme.Colors.accent = accent
            end
            normalized.Accent = nil
        end

        for key, value in pairs(normalized) do
            if key == "Colors" or key == "Transparency" or key == "Typography"
                or key == "Spacing" or key == "Radius" or key == "Animation" then
                if is_table(value) then
                    merge_table(Theme[key], value)
                end
            elseif key == "Mode" then
                set_mode_internal(value)
            end
        end

        Theme.colors = Theme.Colors
        Theme.transparency = Theme.Transparency
        Theme.typography = Theme.Typography
        Theme.spacing = Theme.Spacing
        Theme.radius = Theme.Radius
        Theme.animation = Theme.Animation
        notify()
        return Theme
    end

    function Theme.setMode(mode)
        if not set_mode_internal(mode) then
            return Theme
        end
        notify()
        return Theme
    end

    function Theme.setAccent(color)
        if typeof(color) ~= "Color3" then
            return Theme
        end
        Theme.Colors.accent = color
        notify()
        return Theme
    end

    function Theme.reset()
        set_mode_internal("dark")
        Theme.Typography.Font = Enum.Font.Gotham
        Theme.Typography.FontMedium = Enum.Font.GothamMedium
        Theme.Typography.FontBold = Enum.Font.GothamBold
        Theme.Typography.Size.caption = 11
        Theme.Typography.Size.small = 13
        Theme.Typography.Size.body = 15
        Theme.Typography.Size.title = 20
        Theme.Typography.Size.display = 28
        notify()
        return Theme
    end

    function Theme.currentMode()
        return Theme._mode
    end

    function Theme.get(path)
        if path == nil then
            return Theme
        end
        local current = Theme
        for part in tostring(path):gmatch("[^%.]+") do
            if not is_table(current) then
                return nil
            end
            current = current[part]
        end
        return current
    end

    return Theme
end

--====================================================================--
-- ANIMATOR
--====================================================================--
_mods["Animator"] = function()
    local TweenService = game:GetService("TweenService")
    local Theme = _get("Theme")

    local Animator = {}
    local active = setmetatable({}, { __mode = "k" })

    local STYLE_BY_NAME = {
        Linear = Enum.EasingStyle.Linear,
        Sine = Enum.EasingStyle.Sine,
        Quad = Enum.EasingStyle.Quad,
        Cubic = Enum.EasingStyle.Cubic,
        Quart = Enum.EasingStyle.Quart,
        Quint = Enum.EasingStyle.Quint,
        Expo = Enum.EasingStyle.Exponential,
        Back = Enum.EasingStyle.Back,
        Bounce = Enum.EasingStyle.Bounce,
        Elastic = Enum.EasingStyle.Elastic,
    }

    local DIRECTION_BY_NAME = {
        In = Enum.EasingDirection.In,
        Out = Enum.EasingDirection.Out,
        InOut = Enum.EasingDirection.InOut,
    }

    local function resolve_easing(easing)
        if easing == nil then
            return Enum.EasingStyle.Quad, Enum.EasingDirection.Out
        end
        if typeof(easing) == "EnumItem" then
            return easing, Enum.EasingDirection.Out
        end
        if type(easing) == "table" then
            local style = easing.Style or easing.style or Enum.EasingStyle.Quad
            local direction = easing.Direction or easing.direction or Enum.EasingDirection.Out
            if type(style) == "string" then
                style = STYLE_BY_NAME[style] or Enum.EasingStyle.Quad
            end
            if type(direction) == "string" then
                direction = DIRECTION_BY_NAME[direction] or Enum.EasingDirection.Out
            end
            return style, direction
        end
        if type(easing) == "string" then
            local direction = Enum.EasingDirection.Out
            local styleName = easing
            local inOut = easing:match("^(.-)InOut$")
            local inOnly = easing:match("^(.-)In$")
            local outOnly = easing:match("^(.-)Out$")
            if inOut then
                styleName = inOut
                direction = Enum.EasingDirection.InOut
            elseif outOnly then
                styleName = outOnly
                direction = Enum.EasingDirection.Out
            elseif inOnly then
                styleName = inOnly
                direction = Enum.EasingDirection.In
            end
            return STYLE_BY_NAME[styleName] or Enum.EasingStyle.Quad, direction
        end
        return Enum.EasingStyle.Quad, Enum.EasingDirection.Out
    end

    local function slot_map(instance, create)
        local map = active[instance]
        if map == nil and create then
            map = {}
            active[instance] = map
        end
        return map
    end

    function Animator.tween(instance, slot, properties, duration, easing)
        if not instance or type(properties) ~= "table" then
            return nil
        end
        slot = slot or "default"
        local map = slot_map(instance, true)
        local previous = map[slot]
        if previous then
            pcall(function()
                previous:Cancel()
            end)
            map[slot] = nil
        end

        local seconds = tonumber(duration)
        if seconds == nil then
            seconds = Theme.Animation.normal
        end
        seconds = math.max(0, seconds)

        if seconds <= 0 then
            for key, value in pairs(properties) do
                pcall(function()
                    instance[key] = value
                end)
            end
            if next(map) == nil then
                active[instance] = nil
            end
            return nil
        end

        local style, direction = resolve_easing(easing)
        local info = TweenInfo.new(seconds, style, direction, 0, false, 0)
        local ok, tween = pcall(function()
            return TweenService:Create(instance, info, properties)
        end)
        if not ok or not tween then
            -- Some executor builds reject newer properties (UIStroke, etc.).
            -- Applying them instantly is a safe, still-functional fallback.
            for key, value in pairs(properties) do
                pcall(function()
                    instance[key] = value
                end)
            end
            return nil
        end

        map[slot] = tween
        tween.Completed:Connect(function()
            local current = active[instance]
            if current and current[slot] == tween then
                current[slot] = nil
                if next(current) == nil then
                    active[instance] = nil
                end
            end
        end)
        tween:Play()
        return tween
    end

    function Animator.cancel(instance, slot)
        local map = active[instance]
        if not map then
            return
        end
        slot = slot or "default"
        local tween = map[slot]
        if tween then
            pcall(function()
                tween:Cancel()
            end)
            map[slot] = nil
        end
        if next(map) == nil then
            active[instance] = nil
        end
    end

    function Animator.cancelAll(instance)
        local map = active[instance]
        if not map then
            return
        end
        for slot, tween in pairs(map) do
            pcall(function()
                tween:Cancel()
            end)
            map[slot] = nil
        end
        active[instance] = nil
    end

    function Animator.has(instance, slot)
        local map = active[instance]
        return map ~= nil and map[slot or "default"] ~= nil
    end

    return Animator
end

--====================================================================--
-- UTIL
--====================================================================--
_mods["Util"] = function()
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local TextService = game:GetService("TextService")
    local Players = game:GetService("Players")
    local Theme = _get("Theme")
    local Animator = _get("Animator")

    local Util = {}
    local fallbackGui = nil

    local function set_property(instance, key, value)
        pcall(function()
            instance[key] = value
        end)
    end

    function Util.make(class_name, properties, children)
        local instance = Instance.new(class_name)
        if type(properties) == "table" then
            for key, value in pairs(properties) do
                if key ~= "Parent" then
                    set_property(instance, key, value)
                end
            end
        end
        if children ~= nil then
            if typeof(children) == "Instance" then
                children.Parent = instance
            elseif type(children) == "table" then
                for _, child in ipairs(children) do
                    if typeof(child) == "Instance" then
                        child.Parent = instance
                    end
                end
            end
        end
        -- Parent is deliberately assigned last. A few executor UI wrappers
        -- perform expensive invalidation when an instance is parented and then
        -- mutated, so every property is set before this line.
        if type(properties) == "table" and properties.Parent ~= nil then
            instance.Parent = properties.Parent
        end
        return instance
    end

    Util.new = Util.make

    function Util.newBin()
        local Bin = {
            _items = {},
            _cleaned = false,
        }

        function Bin:add(item)
            if item == nil or self._cleaned then
                return item
            end
            if type(item) == "function" or typeof(item) == "Instance"
                or typeof(item) == "RBXScriptConnection" or type(item) == "table" then
                table.insert(self._items, item)
            end
            return item
        end

        function Bin:connect(signal, callback)
            if not signal or type(callback) ~= "function" then
                return nil
            end
            local connection = signal:Connect(callback)
            self:add(connection)
            return connection
        end

        function Bin:addAll(items)
            if type(items) == "table" then
                for _, item in ipairs(items) do
                    self:add(item)
                end
            end
        end

        function Bin:clean()
            if self._cleaned then
                return
            end
            self._cleaned = true
            for index = #self._items, 1, -1 do
                local item = self._items[index]
                self._items[index] = nil
                local itemType = type(item)
                if itemType == "function" then
                    pcall(item)
                elseif itemType == "table" then
                    if type(item.destroy) == "function" then
                        pcall(item.destroy, item)
                    elseif type(item.Disconnect) == "function" then
                        pcall(item.Disconnect, item)
                    elseif type(item.Cancel) == "function" then
                        pcall(item.Cancel, item)
                    end
                elseif typeof(item) == "RBXScriptConnection" then
                    pcall(function()
                        item:Disconnect()
                    end)
                elseif typeof(item) == "Instance" then
                    pcall(function()
                        item:Destroy()
                    end)
                end
            end
        end

        function Bin:destroy()
            self:clean()
        end

        return Bin
    end

    function Util.roundCorners(gui, radius)
        if not gui then
            return nil
        end
        local corner = gui:FindFirstChildOfClass("UICorner")
        if not corner then
            corner = Util.make("UICorner", {
                CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 12),
                Parent = gui,
            })
        else
            corner.CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 12)
        end
        return corner
    end

    local function alpha_sequence(points)
        local keypoints = {}
        for _, point in ipairs(points) do
            table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2]))
        end
        return NumberSequence.new(keypoints)
    end

    function Util.applyGlass(gui, options)
        if not gui then
            return nil
        end
        options = options or {}
        local radius = options.radius or Theme.Radius.lg
        local colorKey = options.colorKey or "surface"
        local transparencyKey = options.transparencyKey or colorKey
        local explicitTransparency = options.transparency
        local baseColor = options.background or Theme.Colors[colorKey] or Theme.Colors.surface
        local baseTransparency = explicitTransparency
        if baseTransparency == nil then
            baseTransparency = Theme.Transparency[transparencyKey]
            if baseTransparency == nil then
                baseTransparency = Theme.Transparency.surface
            end
        end

        set_property(gui, "BackgroundColor3", baseColor)
        set_property(gui, "BackgroundTransparency", baseTransparency)
        set_property(gui, "BorderSizePixel", 0)

        local corner = Util.roundCorners(gui, radius)

        local fx = Util.make("Frame", {
            Name = "GlassFX",
            Parent = gui,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = false,
            ZIndex = 0,
        })
        Util.roundCorners(fx, radius)

        local tone = nil
        if options.tone ~= false then
            tone = Util.make("Frame", {
                Name = "Tone",
                Parent = fx,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 1,
            })
            Util.make("UIGradient", {
                Parent = tone,
                Rotation = 90,
                Transparency = alpha_sequence({
                    { 0, 0.925 },
                    { 0.45, 0.955 },
                    { 1, 0.985 },
                }),
            })
        end

        local wash = nil
        if options.wash ~= false then
            wash = Util.make("Frame", {
                Name = "AccentWash",
                Parent = fx,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Theme.Colors.accent,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 2,
            })
            Util.make("UIGradient", {
                Parent = wash,
                Rotation = 90,
                Transparency = alpha_sequence({
                    { 0, 0.955 },
                    { 0.55, 0.982 },
                    { 1, 0.994 },
                }),
            })
        end

        local noise = nil
        if options.noise ~= false then
            noise = Util.make("ImageLabel", {
                Name = "Noise",
                Parent = fx,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = "rbxassetid://9968344106", -- subtle grain; missing asset is harmless
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ImageTransparency = Theme.Transparency.noise,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(64, 64),
                SliceCenter = Rect.new(8, 8, 56, 56),
                Active = false,
                ZIndex = 3,
            })
        end

        local rimTop = nil
        local rimBottom = nil
        if options.rim ~= false then
            rimTop = Util.make("Frame", {
                Name = "RimTop",
                Parent = fx,
                Position = UDim2.new(0, 1, 0, 0),
                Size = UDim2.new(1, -2, 0, 1),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 5,
            })
            Util.make("UIGradient", {
                Parent = rimTop,
                Transparency = alpha_sequence({
                    { 0, 1 },
                    { 0.12, 0.58 },
                    { 0.5, 0.42 },
                    { 0.88, 0.58 },
                    { 1, 1 },
                }),
            })
            rimBottom = Util.make("Frame", {
                Name = "RimBottom",
                Parent = fx,
                Position = UDim2.new(0, 1, 1, -1),
                Size = UDim2.new(1, -2, 0, 1),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 5,
            })
            Util.make("UIGradient", {
                Parent = rimBottom,
                Transparency = alpha_sequence({
                    { 0, 1 },
                    { 0.18, 0.90 },
                    { 0.5, 0.84 },
                    { 0.82, 0.90 },
                    { 1, 1 },
                }),
            })
        end

        local stroke = Util.make("UIStroke", {
            Parent = gui,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Theme.Colors.border,
            Thickness = options.strokeThickness or 1,
            Transparency = Theme.Transparency.border,
            LineJoinMode = Enum.LineJoinMode.Round,
        })
        Util.make("UIGradient", {
            Parent = stroke,
            Transparency = alpha_sequence({
                { 0, 0.55 },
                { 0.45, 0.90 },
                { 1, 0.94 },
            }),
        })

        local handle = {
            frame = gui,
            fx = fx,
            stroke = stroke,
            tone = tone,
            wash = wash,
            noise = noise,
            rimTop = rimTop,
            rimBottom = rimBottom,
            colorKey = colorKey,
            transparencyKey = transparencyKey,
            explicitTransparency = explicitTransparency,
            baseTransparency = baseTransparency,
            radius = radius,
            destroyed = false,
            _accentOverride = nil,
        }

        local function accent_color()
            return handle._accentOverride or Theme.Colors.accent
        end

        local function update_theme()
            if handle.destroyed then
                return
            end
            local duration = Theme.Animation.normal
            local color = options.background or Theme.Colors[handle.colorKey] or Theme.Colors.surface
            local targetTransparency = handle.explicitTransparency
            if targetTransparency == nil then
                targetTransparency = Theme.Transparency[handle.transparencyKey]
                if targetTransparency == nil then
                    targetTransparency = Theme.Transparency.surface
                end
            end
            handle.baseTransparency = targetTransparency
            Animator.tween(gui, "glassBackground", {
                BackgroundColor3 = color,
                BackgroundTransparency = targetTransparency,
            }, duration, Enum.EasingStyle.Quad)
            Animator.tween(stroke, "glassStroke", {
                Color = Theme.Colors.border,
                Transparency = Theme.Transparency.border,
            }, duration, Enum.EasingStyle.Quad)
            if wash then
                Animator.tween(wash, "glassWash", {
                    BackgroundColor3 = accent_color(),
                }, duration, Enum.EasingStyle.Quad)
            end
            if noise then
                Animator.tween(noise, "glassNoise", {
                    ImageTransparency = Theme.Transparency.noise,
                }, duration, Enum.EasingStyle.Quad)
            end
        end

        function handle:setAccent(color)
            if typeof(color) ~= "Color3" then
                return self
            end
            self._accentOverride = color
            if wash then
                Animator.tween(wash, "glassWash", {
                    BackgroundColor3 = color,
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            end
            return self
        end

        function handle:setTransparency(value)
            local number = tonumber(value)
            if number == nil then
                return self
            end
            number = math.clamp(number, 0, 1)
            self.baseTransparency = number
            Animator.tween(gui, "glassHover", {
                BackgroundTransparency = number,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            return self
        end

        function handle:getTransparency()
            return self.baseTransparency
        end

        function handle:setRadius(value)
            self.radius = value
            if corner then
                corner.CornerRadius = typeof(value) == "UDim" and value or UDim.new(0, value)
            end
            local fxCorner = fx:FindFirstChildOfClass("UICorner")
            if fxCorner then
                fxCorner.CornerRadius = typeof(value) == "UDim" and value or UDim.new(0, value)
            end
            return self
        end

        function handle:setColorKey(key)
            if key then
                self.colorKey = key
                update_theme()
            end
            return self
        end

        function handle:setBackground(color, transparency)
            if typeof(color) == "Color3" then
                options.background = color
            end
            if transparency ~= nil then
                self.explicitTransparency = transparency
            end
            update_theme()
            return self
        end

        function handle:destroy()
            if self.destroyed then
                return
            end
            self.destroyed = true
            if self._themeConnection then
                pcall(self._themeConnection)
                self._themeConnection = nil
            end
        end

        handle._themeConnection = Theme.onChange(update_theme)
        return handle
    end

    function Util.softShadow(parent, options)
        options = options or {}
        local radius = options.radius or Theme.Radius.xl
        local color = options.color or Theme.Colors.shadow
        local baseTransparency = options.transparency or Theme.Transparency.shadow
        local layers = {}
        local bin = Util.newBin()
        local definitions = {
            { x = -12, y = 8, w = 24, h = 28, transparency = math.min(0.98, baseTransparency + 0.16) },
            { x = -7, y = 10, w = 14, h = 22, transparency = math.min(0.96, baseTransparency + 0.08) },
            { x = -2, y = 10, w = 4, h = 16, transparency = math.max(0.70, baseTransparency - 0.02) },
        }
        for _, definition in ipairs(definitions) do
            local layer = Util.make("Frame", {
                Parent = parent,
                Position = UDim2.new(0, definition.x, 0, definition.y),
                Size = UDim2.new(1, definition.w, 1, definition.h),
                BackgroundColor3 = color,
                BackgroundTransparency = definition.transparency,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 1,
            })
            Util.roundCorners(layer, radius + 8)
            local gradient = Util.make("UIGradient", {
                Parent = layer,
                Rotation = 90,
                Transparency = alpha_sequence({
                    { 0, definition.transparency + 0.02 },
                    { 0.55, definition.transparency },
                    { 1, 1 },
                }),
            })
            table.insert(layers, layer)
            bin:add(layer)
            bin:add(gradient)
        end

        local handle = { layers = layers }
        function handle:setVisible(visible)
            for _, layer in ipairs(layers) do
                pcall(function()
                    layer.Visible = visible
                end)
            end
        end
        function handle:destroy()
            bin:destroy()
        end
        bin:add(Theme.onChange(function()
            for _, layer in ipairs(layers) do
                Animator.tween(layer, "shadowColor", {
                    BackgroundColor3 = Theme.Colors.shadow,
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            end
        end))
        return handle
    end

    function Util.focusRing(gui, radius)
        if not gui then
            return nil
        end
        local ring = Util.make("Frame", {
            Name = "FocusRing",
            Parent = gui,
            Position = UDim2.fromOffset(-2, -2),
            Size = UDim2.new(1, 4, 1, 4),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 60,
        })
        Util.roundCorners(ring, (radius or Theme.Radius.md) + 3)
        local stroke = Util.make("UIStroke", {
            Parent = ring,
            Color = Theme.Colors.accent,
            Thickness = 1.5,
            Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Round,
        })
        local bin = Util.newBin()
        local focused = false

        local handle = {}
        function handle:setFocused(value)
            focused = value and true or false
            Animator.tween(stroke, "focusRing", {
                Transparency = focused and 0.15 or 1,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
        end
        function handle:getFocused()
            return focused
        end
        function handle:destroy()
            bin:destroy()
        end

        bin:connect(gui.SelectionGained, function()
            handle:setFocused(true)
        end)
        bin:connect(gui.SelectionLost, function()
            handle:setFocused(false)
        end)
        bin:add(Theme.onChange(function()
            Animator.tween(stroke, "focusRingColor", {
                Color = Theme.Colors.accent,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
        end))
        return handle
    end

    function Util.feedback(gui, options)
        options = options or {}
        if not gui then
            return nil
        end
        local scale = gui:FindFirstChild("UILibScale")
        if not scale then
            scale = Util.make("UIScale", {
                Name = "UILibScale",
                Parent = gui,
                Scale = 1,
            })
        end
        local ring = Util.focusRing(gui, options.radius or Theme.Radius.md)
        local bin = Util.newBin()
        local hovered = false
        local pressed = false
        local enabled = true
        local hoverScale = options.hoverScale or 1.005
        local pressScale = options.pressScale or 0.97

        local function apply_scale()
            local target = 1
            if pressed then
                target = pressScale
            elseif hovered then
                target = hoverScale
            end
            Animator.tween(scale, "feedbackScale", {
                Scale = target,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
        end

        local handle = { scale = scale, ring = ring }
        function handle:setEnabled(value)
            enabled = value and true or false
            if not enabled then
                hovered = false
                pressed = false
                apply_scale()
            end
        end
        function handle:isHovered()
            return hovered
        end
        function handle:isPressed()
            return pressed
        end
        function handle:destroy()
            bin:destroy()
            if ring then
                ring:destroy()
            end
        end

        if gui:IsA("GuiButton") then
            bin:connect(gui.MouseEnter, function()
                if not enabled then
                    return
                end
                hovered = true
                apply_scale()
                if type(options.onHover) == "function" then
                    pcall(options.onHover, true)
                end
            end)
            bin:connect(gui.MouseLeave, function()
                hovered = false
                pressed = false
                apply_scale()
                if type(options.onHover) == "function" then
                    pcall(options.onHover, false)
                end
            end)
            bin:connect(gui.MouseButton1Down, function()
                if not enabled then
                    return
                end
                pressed = true
                apply_scale()
            end)
            bin:connect(gui.MouseButton1Up, function()
                pressed = false
                apply_scale()
            end)
        end
        return handle
    end

    function Util.clampToViewport(position, size)
        local viewport = Util.viewport()
        local width = size.X.Scale * viewport.X + size.X.Offset
        local height = size.Y.Scale * viewport.Y + size.Y.Offset
        local x = position.X.Scale * viewport.X + position.X.Offset
        local y = position.Y.Scale * viewport.Y + position.Y.Offset
        local padding = 8
        local maxX = math.max(padding, viewport.X - width - padding)
        local maxY = math.max(padding, viewport.Y - height - padding)
        x = math.clamp(x, padding, maxX)
        y = math.clamp(y, padding, maxY)
        return UDim2.fromOffset(x, y)
    end

    function Util.viewport()
        local ok, camera = pcall(function()
            return workspace.CurrentCamera
        end)
        if ok and camera then
            local viewport = camera.ViewportSize
            if viewport and viewport.X > 0 and viewport.Y > 0 then
                return viewport
            end
        end
        local guiService = game:GetService("GuiService")
        local ok2, visible = pcall(function()
            return guiService:GetVisibleSize()
        end)
        if ok2 and visible then
            return visible
        end
        return Vector2.new(1280, 720)
    end

    function Util.guiOf(instance)
        local current = instance
        while current do
            if current:IsA("ScreenGui") then
                return current
            end
            current = current.Parent
        end
        return nil
    end

    function Util.popupLayer(instance)
        local gui = instance
        if not gui then
            return nil
        end
        if not gui:IsA("ScreenGui") then
            gui = Util.guiOf(gui)
        end
        if not gui then
            return nil
        end
        local existing = gui:FindFirstChild("UILibPopupLayer")
        if existing then
            return existing
        end
        return Util.make("Frame", {
            Name = "UILibPopupLayer",
            Parent = gui,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 10000,
        })
    end

    function Util.createScreenGui(name)
        local screenGui = Util.make("ScreenGui", {
            Name = name or "UILibScreen",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 999,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Enabled = true,
        })

        -- gethui() is available in Synapse X, Wave, Delta and most modern
        -- executors. Krnl and Fluxus may return nil or reject protected parents,
        -- so every step is guarded and CoreGui/PlayerGui is used as fallback.
        if type(protect_gui) == "function" then
            pcall(protect_gui, screenGui)
        end
        if type(syn) == "table" and type(syn.protect_gui) == "function" then
            pcall(syn.protect_gui, screenGui)
        end

        local parent = nil
        if type(gethui) == "function" then
            local ok, result = pcall(gethui)
            if ok and result then
                parent = result
            end
        end

        if parent then
            local ok = pcall(function()
                screenGui.Parent = parent
            end)
            if ok and screenGui.Parent then
                return screenGui
            end
        end

        local okCore = pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
        end)
        if okCore and screenGui.Parent then
            return screenGui
        end

        local PlayersService = Players
        local player = PlayersService.LocalPlayer
        if player then
            local okPlayer = pcall(function()
                screenGui.Parent = player:WaitForChild("PlayerGui", 5)
            end)
            if okPlayer and screenGui.Parent then
                return screenGui
            end
        end

        pcall(function()
            screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end)
        return screenGui
    end

    function Util.ensureScreenGui()
        if fallbackGui and fallbackGui.Parent then
            return fallbackGui
        end
        fallbackGui = Util.createScreenGui("UILibFallbackScreen")
        return fallbackGui
    end

    function Util.isDescendantOf(instance, ancestor)
        if not instance or not ancestor then
            return false
        end
        local current = instance
        while current do
            if current == ancestor then
                return true
            end
            current = current.Parent
        end
        return false
    end

    function Util.markNoDrag(instance)
        if not instance then
            return
        end
        pcall(function()
            instance:SetAttribute("UILibNoDrag", true)
        end)
    end

    function Util.isNoDrag(instance)
        local current = instance
        while current do
            local ok, value = pcall(function()
                return current:GetAttribute("UILibNoDrag")
            end)
            if ok and value then
                return true
            end
            current = current.Parent
        end
        return false
    end

    function Util.mousePosition(input)
        if input and input.UserInputType == Enum.UserInputType.Touch then
            return Vector2.new(input.Position.X, input.Position.Y)
        end
        return UserInputService:GetMouseLocation()
    end

    function Util.hexToColor(hex)
        if type(hex) ~= "string" then
            return nil
        end
        local value = hex:gsub("#", ""):gsub("%s", "")
        if #value == 3 then
            value = value:sub(1, 1):rep(2) .. value:sub(2, 2):rep(2) .. value:sub(3, 3):rep(2)
        end
        if #value ~= 6 or value:find("[^%x]") then
            return nil
        end
        local r = tonumber(value:sub(1, 2), 16)
        local g = tonumber(value:sub(3, 4), 16)
        local b = tonumber(value:sub(5, 6), 16)
        if not r or not g or not b then
            return nil
        end
        return Color3.fromRGB(r, g, b)
    end

    function Util.colorToHex(color)
        if typeof(color) ~= "Color3" then
            return "#000000"
        end
        local r = math.floor(math.clamp(color.R, 0, 1) * 255 + 0.5)
        local g = math.floor(math.clamp(color.G, 0, 1) * 255 + 0.5)
        local b = math.floor(math.clamp(color.B, 0, 1) * 255 + 0.5)
        return string.format("#%02X%02X%02X", r, g, b)
    end

    function Util.readableText(color)
        if typeof(color) ~= "Color3" then
            return Theme.Colors.text
        end
        local luminance = 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
        if luminance > 0.62 then
            return Color3.fromRGB(20, 20, 22)
        end
        return Color3.fromRGB(255, 255, 255)
    end

    function Util.reportError(err)
        if type(Util.onError) == "function" then
            pcall(Util.onError, tostring(err))
        end
    end

    function Util.safeCall(callback, ...)
        if type(callback) ~= "function" then
            return true
        end
        local results = table.pack(pcall(callback, ...))
        if not results[1] then
            Util.reportError(results[2])
            return false, results[2]
        end
        return true, table.unpack(results, 2, results.n)
    end

    function Util.debounce(callback, delaySeconds)
        local token = 0
        return function(...)
            token = token + 1
            local current = token
            local packed = table.pack(...)
            task.delay(delaySeconds or 0.1, function()
                if token == current then
                    callback(table.unpack(packed, 1, packed.n))
                end
            end)
        end
    end

    function Util.textWidth(text, fontSize, font)
        local ok, size = pcall(function()
            return TextService:GetTextSize(
                tostring(text or ""),
                fontSize or Theme.Typography.Size.small,
                font or Theme.Typography.Font,
                Vector2.new(10000, 1000)
            )
        end)
        if ok and size then
            return size.X
        end
        return #tostring(text or "") * ((fontSize or 13) * 0.58)
    end

    function Util.setText(instance, text)
        if instance then
            instance.Text = tostring(text or "")
        end
    end

    return Util
end

--====================================================================--
-- ICONS
--====================================================================--
_mods["Icons"] = function()
    local Icons = {
        chevronRight = "▸",
        chevronDown = "⌄",
        chevronUp = "⌃",
        chevronLeft = "◂",
        close = "×",
        check = "✓",
        plus = "+",
        minus = "−",
        settings = "⚙",
        menu = "☰",
        search = "🔍",
        folder = "📁",
        palette = "🎨",
        volume = "🔊",
        mute = "🔇",
        bell = "🔔",
        bolt = "⚡",
        lock = "🔒",
        unlock = "🔓",
        user = "👤",
        users = "👥",
        download = "⬇",
        upload = "⬆",
        play = "▶",
        pause = "⏸",
        stop = "⏹",
        previous = "⏮",
        next = "⏭",
        timer = "⏱",
        clipboard = "📋",
        trash = "🗑",
        edit = "✎",
        refresh = "🔄",
        star = "⭐",
        heart = "❤",
        warning = "⚠",
        info = "ℹ",
        home = "⌂",
        grid = "▦",
        list = "☰",
        arrowLeft = "←",
        arrowRight = "→",
        arrowUp = "↑",
        arrowDown = "↓",
        arrowUpRight = "↗",
        arrowDownRight = "↘",
        dot = "•",
        drag = "⠿",
        expand = "⤢",
        collapse = "⤡",
        power = "⏻",
        shield = "🛡",
        flame = "🔥",
        rocket = "🚀",
        sparkles = "✨",
        globe = "🌐",
        link = "🔗",
        terminal = "⌨",
        code = "</>",
        bug = "🐞",
        dice = "🎲",
        gift = "🎁",
        key = "🔑",
        camera = "📷",
        image = "🖼",
        music = "🎵",
        video = "🎬",
        moon = "🌙",
        sun = "☀",
        cloud = "☁",
        wifi = "📶",
        battery = "🔋",
        chart = "📊",
        pin = "📍",
        bookmark = "🔖",
        filter = "⧩",
        sort = "↕",
        copy = "⧉",
        paste = "📑",
        save = "💾",
        logout = "⏏",
        plusCircle = "⊕",
        minusCircle = "⊖",
        checkCircle = "✔",
        xCircle = "✖",
        spinner = "◌",
        dotCircle = "◉",
        circle = "○",
        square = "□",
        squareFilled = "■",
        triangle = "△",
        diamond = "◆",
        eye = "◉",
        eyeOff = "◌",
        command = "⌘",
        shift = "⇧",
        enter = "↵",
        backspace = "⌫",
        tab = "⇥",
        escape = "⎋",
        controller = "🎮",
        mouse = "🖱",
        monitor = "🖥",
        cpu = "🧠",
        database = "🗄",
        box = "📦",
        map = "🗺",
        compass = "🧭",
        flag = "🏁",
        trophy = "🏆",
        crown = "♛",
        ghost = "👻",
        robot = "🤖",
        alien = "👾",
        skull = "☠",
        fire = "♨",
        snow = "❄",
        drop = "💧",
        leaf = "🍃",
        coin = "◎",
        gem = "♦",
        cart = "🛒",
        tag = "🏷",
        calendar = "📅",
        clock = "🕒",
        mail = "✉",
        chat = "💬",
        phone = "📱",
        location = "📍",
        share = "⇪",
        export = "↥",
        import = "↧",
        undo = "↶",
        redo = "↷",
        more = "⋯",
        moreVertical = "⋮",
        grip = "⠿",
    }

    function Icons.get(name, fallback)
        if name == nil then
            return fallback or ""
        end
        return Icons[name] or fallback or tostring(name)
    end

    function Icons.has(name)
        return Icons[name] ~= nil
    end

    function Icons.list()
        local names = {}
        for name in pairs(Icons) do
            if type(Icons[name]) == "string" then
                table.insert(names, name)
            end
        end
        table.sort(names)
        return names
    end

    return Icons
end

--====================================================================--
-- WIDGETS
--====================================================================--
_mods["Widgets"] = function()
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Theme = _get("Theme")
    local Util = _get("Util")
    local Animator = _get("Animator")
    local Icons = _get("Icons")

    local Widgets = {}
    local activeKeybind = nil

    local function theme_bind(bin, callback)
        bin:add(Theme.onChange(callback))
    end

    local function tween(instance, slot, properties, duration, easing)
        return Animator.tween(
            instance,
            slot,
            properties,
            duration or Theme.Animation.normal,
            easing or Enum.EasingStyle.Quad
        )
    end

    local function fire(callback, ...)
        return Util.safeCall(callback, ...)
    end

    local function make_label(parent, properties)
        local defaults = {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = Theme.Typography.Font,
            TextColor3 = Theme.Colors.text,
            TextSize = Theme.Typography.Size.small,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = false,
            RichText = false,
        }
        if type(properties) == "table" then
            for key, value in pairs(properties) do
                defaults[key] = value
            end
        end
        return Util.make("TextLabel", defaults)
    end

    local function make_button(parent, properties)
        local defaults = {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            TextTransparency = 1,
            Selectable = true,
            Active = true,
        }
        if type(properties) == "table" then
            for key, value in pairs(properties) do
                defaults[key] = value
            end
        end
        return Util.make("TextButton", defaults)
    end

    local function normalize_options(options)
        local normalized = {}
        for index, option in ipairs(options or {}) do
            if type(option) == "table" then
                table.insert(normalized, {
                    Text = tostring(option.Text or option.Name or option.Value or ("Option " .. index)),
                    Value = option.Value ~= nil and option.Value or option.Text or index,
                    Icon = option.Icon,
                })
            else
                table.insert(normalized, {
                    Text = tostring(option),
                    Value = option,
                })
            end
        end
        return normalized
    end

    local function key_name(value)
        if value == nil then
            return "None"
        end
        if typeof(value) == "EnumItem" then
            local name = value.Name
            local map = {
                LeftShift = "L-Shift",
                RightShift = "R-Shift",
                LeftControl = "L-Ctrl",
                RightControl = "R-Ctrl",
                LeftAlt = "L-Alt",
                RightAlt = "R-Alt",
                Space = "Space",
                Return = "Enter",
                Backquote = "`",
                CapsLock = "Caps",
                Unknown = "None",
            }
            return map[name] or name
        end
        return tostring(value)
    end

    local function safe_disconnect(connection)
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    local WIDGET_NAMES = {
        "button", "toggle", "slider", "dropdown", "textinput", "keybind",
        "colorpicker", "card", "badge", "chip", "avatar", "progress",
        "spinner", "stat", "tabs", "list", "tooltip", "separator",
        "grid", "accordion", "row",
    }

    function Widgets._decorate(scope)
        scope._children = scope._children or {}
        scope._bin = scope._bin or Util.newBin()
        scope._destroyed = false

        function scope:_track(widget)
            if widget == nil then
                return nil
            end
            table.insert(self._children, widget)
            if widget._instance then
                widget._instance.LayoutOrder = #self._children
            end
            return widget
        end

        function scope:_trackInstance(instance)
            if instance then
                table.insert(self._children, { _instance = instance, destroy = function(item)
                    if item._instance then
                        item._instance:Destroy()
                    end
                end })
            end
            return instance
        end

        local function as_options(value)
            if type(value) == "function" then
                return { Callback = value }
            end
            return value or {}
        end

        for _, name in ipairs(WIDGET_NAMES) do
            if name ~= "card" then
                scope[name] = function(self, options)
                    local widget = Widgets[name](self._parent, as_options(options) or {})
                    self:_track(widget)
                    return widget
                end
            end
        end

        scope.card = function(self, options)
            local widget
            if type(options) == "function" then
                widget = Widgets.cardContainer(self._parent, { Callback = options })
            else
                widget = Widgets.card(self._parent, options or {})
            end
            self:_track(widget)
            return widget
        end

        scope.section = function(self, title, callback)
            local options
            if type(title) == "table" then
                options = title
            else
                options = { Title = title, Content = callback }
            end
            local widget = Widgets.section(self._parent, options)
            self:_track(widget)
            return widget
        end

        scope.row = function(self, callback, options)
            local settings = options or {}
            if type(callback) == "table" then
                settings = callback
                callback = settings.Callback
            elseif type(callback) == "function" then
                settings.Callback = callback
            end
            local widget = Widgets.row(self._parent, settings)
            self:_track(widget)
            return widget
        end

        function scope:_disposeChildren()
            for index = #self._children, 1, -1 do
                local child = self._children[index]
                self._children[index] = nil
                if type(child) == "table" then
                    if type(child.destroy) == "function" then
                        pcall(child.destroy, child)
                    elseif child._instance then
                        pcall(function()
                            child._instance:Destroy()
                        end)
                    end
                elseif typeof(child) == "Instance" then
                    pcall(function()
                        child:Destroy()
                    end)
                end
            end
        end

        function scope:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            self:_disposeChildren()
            self._bin:destroy()
            if self._instance then
                Animator.cancelAll(self._instance)
                pcall(function()
                    self._instance:Destroy()
                end)
            end
        end

        function scope:getFrame()
            return self._instance or self._parent
        end

        return scope
    end

    function Widgets._row_finish(scope, gap)
        local gapValue = gap or 10
        local widgets = {}
        for _, child in ipairs(scope._children) do
            if child._instance and not child._autoWidth and child._height
                and child._rowFinalize ~= false and child._rowFlex ~= false then
                table.insert(widgets, child)
            end
        end
        local count = #widgets
        if count == 0 then
            return
        end
        for index, widget in ipairs(widgets) do
            local height = widget._height or 44
            widget._instance.Size = UDim2.new(
                1 / count,
                -(gapValue * (count - 1)) / count,
                0,
                height
            )
            widget._instance.LayoutOrder = index
        end
    end

    --==============================================================--
    -- BUTTON
    --==============================================================--
    function Widgets.button(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local variant = options.Variant or "secondary"
        local disabled = options.Disabled == true
        local root = make_button(parent, {
            Name = "Button",
            Size = options.Width or UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme.Colors.surfaceElevated,
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            Parent = parent,
        })
        Util.roundCorners(root, Theme.Radius.md)
        Util.markNoDrag(root)

        local colorKeys = {
            primary = "accent",
            secondary = "surfaceElevated",
            danger = "danger",
        }
        local glass = nil
        if variant ~= "ghost" then
            glass = Util.applyGlass(root, {
                radius = Theme.Radius.md,
                colorKey = colorKeys[variant] or "surfaceElevated",
                transparency = variant == "primary" and 0.02 or (variant == "danger" and 0.02 or 0.12),
                noise = variant ~= "secondary",
                wash = true,
            })
            bin:add(glass)
        else
            root.BackgroundColor3 = Theme.Colors.control
            root.BackgroundTransparency = 1
        end

        local content = Util.make("Frame", {
            Name = "Content",
            Parent = root,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        local layout = Util.make("UIListLayout", {
            Parent = content,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        local iconLabel = nil
        if options.Icon and options.Icon ~= "" then
            iconLabel = make_label(content, {
                Name = "Icon",
                Text = Icons.get(options.Icon, options.Icon),
                Font = Theme.Typography.FontBold,
                TextSize = Theme.Typography.Size.body,
                Size = UDim2.fromOffset(18, 20),
                TextXAlignment = Enum.TextXAlignment.Center,
                LayoutOrder = 1,
            })
        end
        local textLabel = make_label(content, {
            Name = "Label",
            Text = tostring(options.Text or "Button"),
            Font = variant == "primary" and Theme.Typography.FontBold or Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.small,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = 2,
        })

        local baseTransparency = glass and glass:getTransparency() or 1
        local hovered = false
        local feedback

        local function text_color()
            if variant == "primary" or variant == "danger" then
                return Theme.Colors.onAccent
            end
            return Theme.Colors.text
        end

        local function update_texts()
            local color = text_color()
            if iconLabel then
                tween(iconLabel, "buttonText", { TextColor3 = color }, Theme.Animation.fast)
            end
            tween(textLabel, "buttonText", { TextColor3 = color }, Theme.Animation.fast)
        end

        local function set_hover_state(state)
            hovered = state
            if disabled then
                return
            end
            if glass then
                local target = baseTransparency
                if state then
                    target = math.max(0, baseTransparency - 0.10)
                end
                glass:setTransparency(target)
                tween(glass.stroke, "buttonStroke", {
                    Transparency = state and 0.55 or Theme.Transparency.border,
                }, Theme.Animation.fast)
            else
                tween(root, "buttonGhost", {
                    BackgroundTransparency = state and 0.93 or 1,
                }, Theme.Animation.fast)
            end
            if state and variant ~= "ghost" and variant ~= "secondary" then
                local base = Theme.Colors[colorKeys[variant]] or Theme.Colors.accent
                tween(root, "buttonTint", {
                    BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.05),
                }, Theme.Animation.fast)
            elseif variant ~= "ghost" then
                tween(root, "buttonTint", {
                    BackgroundColor3 = Theme.Colors[colorKeys[variant]] or Theme.Colors.surfaceElevated,
                }, Theme.Animation.fast)
            end
        end

        feedback = Util.feedback(root, {
            radius = Theme.Radius.md,
            pressScale = 0.97,
            hoverScale = 1.005,
            onHover = set_hover_state,
        })
        bin:add(feedback)

        local function apply_disabled()
            root.Active = not disabled
            root.Selectable = not disabled
            pcall(function()
                root.Interactable = not disabled
            end)
            if feedback then
                feedback:setEnabled(not disabled)
            end
            local targetTransparency = disabled and 0.55 or 1
            tween(textLabel, "buttonDisabled", {
                TextTransparency = disabled and 0.45 or 0,
            }, Theme.Animation.fast)
            if iconLabel then
                tween(iconLabel, "buttonDisabled", {
                    TextTransparency = disabled and 0.45 or 0,
                }, Theme.Animation.fast)
            end
            if glass then
                glass:setTransparency(disabled and 0.48 or baseTransparency)
            else
                root.BackgroundTransparency = targetTransparency
            end
        end

        bin:connect(root.Activated, function()
            if disabled then
                return
            end
            fire(options.OnClick)
        end)

        bin:connect(root.MouseButton1Down, function()
            if disabled or not glass then
                return
            end
            glass:setTransparency(math.min(0.9, baseTransparency + 0.055))
        end)
        bin:connect(root.MouseButton1Up, function()
            if disabled or not glass then
                return
            end
            glass:setTransparency(hovered and math.max(0, baseTransparency - 0.10) or baseTransparency)
        end)

        theme_bind(bin, function()
            update_texts()
            if variant == "ghost" then
                root.BackgroundColor3 = Theme.Colors.control
            elseif glass then
                glass:setAccent(Theme.Colors.accent)
            end
            set_hover_state(hovered)
        end)

        update_texts()
        apply_disabled()

        local widget = {
            _instance = root,
            _height = 40,
            root = root,
            glass = glass,
            label = textLabel,
        }

        function widget:setText(text)
            textLabel.Text = tostring(text or "")
            return self
        end

        function widget:setIcon(icon)
            local glyph = Icons.get(icon, icon or "")
            if glyph == "" then
                if iconLabel then
                    iconLabel.Visible = false
                end
                return self
            end
            if not iconLabel then
                iconLabel = make_label(content, {
                    Name = "Icon",
                    Text = glyph,
                    Font = Theme.Typography.FontBold,
                    TextSize = Theme.Typography.Size.body,
                    Size = UDim2.fromOffset(18, 20),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    LayoutOrder = 1,
                })
                textLabel.LayoutOrder = 2
            end
            iconLabel.Visible = true
            iconLabel.Text = glyph
            update_texts()
            return self
        end

        function widget:setDisabled(value)
            disabled = value == true
            apply_disabled()
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            Animator.cancelAll(root)
            bin:destroy()
            if glass then
                glass:destroy()
            end
            root:Destroy()
        end

        return widget
    end

    --==============================================================--
    -- TOGGLE
    --==============================================================--
    function Widgets.toggle(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local value = options.Value == true
        local disabled = options.Disabled == true
        local height = options.Description and 58 or 50
        local root = make_button(parent, {
            Name = "Toggle",
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme.Colors.control,
            BackgroundTransparency = 1,
            Parent = parent,
        })
        Util.roundCorners(root, Theme.Radius.md)
        Util.markNoDrag(root)

        local textX = 12
        local title = make_label(root, {
            Name = "Title",
            Text = tostring(options.Text or "Toggle"),
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(textX, options.Description and 8 or 0),
            Size = UDim2.new(1, -86, 0, options.Description and 19 or height),
        })
        local description = nil
        if options.Description then
            description = make_label(root, {
                Name = "Description",
                Text = tostring(options.Description),
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                Position = UDim2.fromOffset(textX, 30),
                Size = UDim2.new(1, -86, 0, 16),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
        end

        local track = Util.make("Frame", {
            Name = "Track",
            Parent = root,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(44, 24),
            BackgroundColor3 = Theme.Colors.accent,
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        Util.roundCorners(track, 12)
        local trackStroke = Util.make("UIStroke", {
            Parent = track,
            Color = Theme.Colors.border,
            Transparency = 0.84,
            Thickness = 1,
        })
        local thumb = Util.make("Frame", {
            Name = "Thumb",
            Parent = track,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(20, 20),
            BackgroundColor3 = Theme.Colors.text,
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        Util.roundCorners(thumb, 10)
        local thumbStroke = Util.make("UIStroke", {
            Parent = thumb,
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.86,
            Thickness = 1,
        })

        local feedback = Util.feedback(root, {
            radius = Theme.Radius.md,
            pressScale = 1,
            hoverScale = 1,
            onHover = function(state)
                if disabled then
                    return
                end
                tween(root, "toggleHover", {
                    BackgroundTransparency = state and 0.955 or 1,
                }, Theme.Animation.fast)
            end,
        })
        bin:add(feedback)

        local function off_color()
            return Theme.currentMode() == "light" and Color3.fromRGB(174, 174, 178) or Color3.fromRGB(99, 99, 108)
        end

        local function update(animated)
            local duration = animated and Theme.Animation.normal or 0
            tween(track, "toggleTrack", {
                BackgroundColor3 = value and Theme.Colors.accent or off_color(),
                BackgroundTransparency = value and 0.18 or 0.78,
            }, duration)
            tween(thumb, "toggleThumb", {
                Position = value and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                BackgroundColor3 = value and Theme.Colors.accent or Theme.Colors.text,
            }, duration)
            tween(trackStroke, "toggleTrackStroke", {
                Color = value and Theme.Colors.accent or Theme.Colors.border,
                Transparency = value and 0.62 or 0.84,
            }, duration)
            tween(thumbStroke, "toggleThumbStroke", {
                Transparency = value and 0.52 or 0.86,
            }, duration)
            tween(title, "toggleTitle", {
                TextColor3 = disabled and Theme.Colors.textSecondary or Theme.Colors.text,
                TextTransparency = disabled and 0.35 or 0,
            }, duration)
            if description then
                tween(description, "toggleDesc", {
                    TextColor3 = Theme.Colors.textSecondary,
                    TextTransparency = disabled and 0.45 or Theme.Transparency.textSecondary,
                }, duration)
            end
        end

        local function apply_disabled()
            root.Active = not disabled
            root.Selectable = not disabled
            pcall(function()
                root.Interactable = not disabled
            end)
            feedback:setEnabled(not disabled)
            update(true)
        end

        local function set_value(newValue, silent)
            value = newValue == true
            update(true)
            if not silent then
                fire(options.OnChange, value)
            end
        end

        bin:connect(root.Activated, function()
            if disabled then
                return
            end
            set_value(not value, false)
        end)

        theme_bind(bin, function()
            update(true)
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            track = track,
            thumb = thumb,
        }

        function widget:get()
            return value
        end

        function widget:set(newValue, silent)
            set_value(newValue, silent)
            return self
        end

        function widget:toggle(silent)
            set_value(not value, silent)
            return self
        end

        function widget:setDisabled(state)
            disabled = state == true
            apply_disabled()
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            Animator.cancelAll(root)
            bin:destroy()
            root:Destroy()
        end

        update(false)
        apply_disabled()
        return widget
    end

    --==============================================================--
    -- SLIDER
    --==============================================================--
    function Widgets.slider(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local minimum = tonumber(options.Min) or 0
        local maximum = tonumber(options.Max) or 100
        if maximum <= minimum then
            maximum = minimum + 1
        end
        local value = math.clamp(tonumber(options.Value) or minimum, minimum, maximum)
        local suffix = options.Suffix or ""
        local step = tonumber(options.Step)
        if step == nil then
            step = (minimum % 1 == 0 and maximum % 1 == 0) and 1 or 0.01
        end
        step = math.max(step, 0.0001)
        local disabled = options.Disabled == true
        local height = 70
        local root = Util.make("Frame", {
            Name = "Slider",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })

        local title = make_label(root, {
            Name = "Title",
            Text = tostring(options.Text or "Slider"),
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(12, 1),
            Size = UDim2.new(0.62, -12, 0, 20),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local valueLabel = make_label(root, {
            Name = "Value",
            Text = "",
            Font = Theme.Typography.FontMedium,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.caption,
            Position = UDim2.new(0.62, 0, 0, 1),
            Size = UDim2.new(0.38, -12, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Right,
        })

        local trackBack = Util.make("Frame", {
            Name = "Track",
            Parent = root,
            Position = UDim2.new(0, 12, 0, 47),
            Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        Util.roundCorners(trackBack, 3)
        local fill = Util.make("Frame", {
            Name = "Fill",
            Parent = trackBack,
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Theme.Colors.accent,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        Util.roundCorners(fill, 3)
        local thumb = Util.make("Frame", {
            Name = "Thumb",
            Parent = root,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 12, 0, 50),
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = Theme.Colors.text,
            BorderSizePixel = 0,
            ZIndex = 4,
        })
        Util.roundCorners(thumb, 8)
        local thumbStroke = Util.make("UIStroke", {
            Parent = thumb,
            Color = Theme.Colors.accent,
            Transparency = 0.28,
            Thickness = 2,
        })

        local hit = make_button(root, {
            Name = "Hit",
            Position = UDim2.new(0, 0, 0, 30),
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = root,
        })

        local tooltip = Util.make("Frame", {
            Name = "ValueTooltip",
            Parent = root,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.fromOffset(52, 22),
            BackgroundColor3 = Theme.Colors.surfaceElevated,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 20,
        })
        Util.roundCorners(tooltip, 7)
        Util.make("UIStroke", {
            Parent = tooltip,
            Color = Theme.Colors.border,
            Transparency = 0.76,
            Thickness = 1,
        })
        local tooltipLabel = make_label(tooltip, {
            Name = "TooltipLabel",
            Text = "",
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.caption,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
        })

        local dragging = false
        local dragConnections = {}
        local hovering = false
        local feedback = Util.feedback(hit, {
            radius = 8,
            pressScale = 1,
            hoverScale = 1,
        })
        bin:add(feedback)

        local function format_value(number)
            local rounded
            if step >= 1 then
                rounded = math.floor(number + 0.5)
            else
                rounded = math.floor(number / step + 0.5) * step
            end
            if rounded % 1 == 0 then
                return tostring(math.floor(rounded)) .. suffix
            end
            return string.format("%.2f", rounded) .. suffix
        end

        local function update_visuals()
            local fraction = (value - minimum) / (maximum - minimum)
            fraction = math.clamp(fraction, 0, 1)
            fill.Size = UDim2.fromScale(fraction, 1)
            thumb.Position = UDim2.new(fraction, 12, 0, 50)
            local text = format_value(value)
            valueLabel.Text = text
            tooltipLabel.Text = text
            local viewport = Util.viewport()
            local tooltipX = 12 + fraction * math.max(1, (root.AbsoluteSize.X - 24))
            tooltipX = math.clamp(tooltipX, 26, math.max(26, root.AbsoluteSize.X - 26))
            tooltip.Position = UDim2.new(0, tooltipX, 0, 20)
            tooltip.Visible = (hovering or dragging) and not disabled
        end

        local function quantize(number)
            local result = minimum + math.floor(((number - minimum) / step) + 0.5) * step
            result = math.clamp(result, minimum, maximum)
            if step >= 1 then
                return math.floor(result + 0.5)
            end
            return math.floor(result * 1000 + 0.5) / 1000
        end

        local function set_from_x(x, silent)
            local track = trackBack.AbsolutePosition
            local width = math.max(1, trackBack.AbsoluteSize.X)
            local fraction = math.clamp((x - track.X) / width, 0, 1)
            local nextValue = quantize(minimum + fraction * (maximum - minimum))
            local changed = nextValue ~= value
            value = nextValue
            update_visuals()
            if changed and not silent then
                fire(options.OnChange, value)
            end
        end

        local function stop_drag()
            dragging = false
            for _, connection in ipairs(dragConnections) do
                safe_disconnect(connection)
            end
            table.clear(dragConnections)
            update_visuals()
        end

        local function begin_drag(input)
            if disabled or dragging then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            dragging = true
            set_from_x(Util.mousePosition(input).X, false)
            update_visuals()
            table.insert(dragConnections, UserInputService.InputChanged:Connect(function(changed)
                if changed.UserInputType == Enum.UserInputType.MouseMovement
                    or changed.UserInputType == Enum.UserInputType.Touch then
                    set_from_x(Util.mousePosition(changed).X, false)
                end
            end))
            table.insert(dragConnections, UserInputService.InputEnded:Connect(function(ended)
                if ended.UserInputType == Enum.UserInputType.MouseButton1
                    or ended.UserInputType == Enum.UserInputType.Touch then
                    stop_drag()
                end
            end))
        end

        bin:connect(hit.InputBegan, begin_drag)
        bin:connect(hit.MouseEnter, function()
            hovering = true
            update_visuals()
        end)
        bin:connect(hit.MouseLeave, function()
            hovering = false
            update_visuals()
        end)
        bin:connect(trackBack.InputBegan, function(input)
            if not dragging then
                begin_drag(input)
            end
        end)

        theme_bind(bin, function()
            tween(title, "sliderTitle", {
                TextColor3 = disabled and Theme.Colors.textSecondary or Theme.Colors.text,
            }, Theme.Animation.normal)
            tween(valueLabel, "sliderValue", {
                TextColor3 = Theme.Colors.textSecondary,
            }, Theme.Animation.normal)
            tween(trackBack, "sliderTrack", {
                BackgroundColor3 = Theme.Colors.textSecondary,
            }, Theme.Animation.normal)
            tween(fill, "sliderFill", {
                BackgroundColor3 = Theme.Colors.accent,
            }, Theme.Animation.normal)
            tween(thumb, "sliderThumb", {
                BackgroundColor3 = Theme.Colors.text,
            }, Theme.Animation.normal)
            tween(thumbStroke, "sliderThumbStroke", {
                Color = Theme.Colors.accent,
            }, Theme.Animation.normal)
            tween(tooltip, "sliderTooltip", {
                BackgroundColor3 = Theme.Colors.surfaceElevated,
            }, Theme.Animation.normal)
            tween(tooltipLabel, "sliderTooltipText", {
                TextColor3 = Theme.Colors.text,
            }, Theme.Animation.normal)
            update_visuals()
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            track = trackBack,
            fill = fill,
            thumb = thumb,
        }

        function widget:getValue()
            return value
        end

        function widget:setValue(newValue, silent)
            value = quantize(tonumber(newValue) or minimum)
            update_visuals()
            if not silent then
                fire(options.OnChange, value)
            end
            return self
        end

        function widget:setRange(newMin, newMax)
            minimum = tonumber(newMin) or minimum
            maximum = tonumber(newMax) or maximum
            if maximum <= minimum then
                maximum = minimum + 1
            end
            widget:setValue(value, true)
            return self
        end

        function widget:setDisabled(state)
            disabled = state == true
            hit.Active = not disabled
            hit.Selectable = not disabled
            feedback:setEnabled(not disabled)
            update_visuals()
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            stop_drag()
            Animator.cancelAll(root)
            bin:destroy()
            root:Destroy()
        end

        update_visuals()
        return widget
    end

    --==============================================================--
    -- DROPDOWN
    --==============================================================--
    function Widgets.dropdown(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local popupBin = Util.newBin()
        local currentOptions = normalize_options(options.Options)
        local selectedValue = options.Value
        local disabled = options.Disabled == true
        local height = 50
        local openState = false
        local menu = nil
        local menuShadow = nil
        local menuOverlay = nil
        local menuScroll = nil
        local menuLayout = nil
        local menuTargetHeight = 0
        local menuWidth = 200
        local renderConnection = nil
        local escapeConnection = nil
        local closeToken = 0
        local openThemeConnection = nil

        local root = make_button(parent, {
            Name = "Dropdown",
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme.Colors.background,
            Parent = parent,
        })
        Util.markNoDrag(root)
        local glass = Util.applyGlass(root, {
            radius = Theme.Radius.md,
            colorKey = "background",
            transparency = 0.42,
            noise = true,
            wash = false,
        })
        bin:add(glass)

        local titleLabel = make_label(root, {
            Name = "Title",
            Text = tostring(options.Text or "Select"),
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(0.55, -20, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local selectedLabel = make_label(root, {
            Name = "Selected",
            Text = "",
            Font = Theme.Typography.Font,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.small,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -36, 0.5, 0),
            Size = UDim2.new(0.42, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local chevron = make_label(root, {
            Name = "Chevron",
            Text = Icons.chevronDown,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.body,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(16, 20),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2,
        })
        local feedback = Util.feedback(root, {
            radius = Theme.Radius.md,
            pressScale = 0.995,
            hoverScale = 1,
            onHover = function(state)
                if disabled or openState then
                    return
                end
                glass:setTransparency(state and 0.32 or 0.42)
            end,
        })
        bin:add(feedback)

        local function selected_option()
            for _, option in ipairs(currentOptions) do
                if option.Value == selectedValue then
                    return option
                end
            end
            return nil
        end

        local function refresh_label()
            local option = selected_option()
            if option then
                selectedLabel.Text = option.Text
                selectedLabel.TextColor3 = Theme.Colors.text
                selectedLabel.TextTransparency = 0
            else
                selectedLabel.Text = options.Placeholder or "Select..."
                selectedLabel.TextColor3 = Theme.Colors.textSecondary
            end
            chevron.Rotation = openState and 180 or 0
        end

        local function disconnect_menu()
            if renderConnection then
                safe_disconnect(renderConnection)
                renderConnection = nil
            end
            if escapeConnection then
                safe_disconnect(escapeConnection)
                escapeConnection = nil
            end
            if openThemeConnection then
                pcall(openThemeConnection)
                openThemeConnection = nil
            end
        end

        local function position_menu()
            if not menu or not menu.Parent then
                return
            end
            local viewport = Util.viewport()
            local absolute = root.AbsolutePosition
            local size = root.AbsoluteSize
            menuWidth = math.max(160, size.X)
            local targetHeight = menuTargetHeight
            local x = math.clamp(absolute.X, 8, math.max(8, viewport.X - menuWidth - 8))
            local y = absolute.Y + size.Y + 6
            if y + targetHeight > viewport.Y - 8 then
                y = absolute.Y - targetHeight - 6
            end
            y = math.clamp(y, 8, math.max(8, viewport.Y - targetHeight - 8))
            if menuShadow then
                menuShadow.Position = UDim2.fromOffset(x + 2, y + 8)
            end
            menu.Position = UDim2.fromOffset(x, y)
        end

        local function destroy_menu()
            closeToken = closeToken + 1
            openState = false
            disconnect_menu()
            if menu then
                Animator.cancelAll(menu)
                if menuShadow then
                    menuShadow:Destroy()
                end
                menu:Destroy()
            end
            if menuOverlay then
                menuOverlay:Destroy()
            end
            if menuScroll then
                menuScroll:Destroy()
            end
            menu = nil
            menuShadow = nil
            menuOverlay = nil
            menuScroll = nil
            menuLayout = nil
            popupBin:destroy()
            popupBin = Util.newBin()
            if chevron then
                tween(chevron, "dropdownChevron", { Rotation = 0 }, Theme.Animation.fast)
            end
            if glass and not disabled then
                glass:setTransparency(0.42)
            end
        end

        local function choose_option(option, index)
            selectedValue = option.Value
            refresh_label()
            fire(options.OnChange, option.Value, option, index)
            destroy_menu()
        end

        local function close_menu()
            if not openState then
                return
            end
            openState = false
            local token = closeToken + 1
            closeToken = token
            disconnect_menu()
            if menu then
                tween(menu, "dropdownClose", {
                    Size = UDim2.fromOffset(menuWidth, 0),
                }, Theme.Animation.fast)
                tween(menu, "dropdownCloseTransparency", {
                    BackgroundTransparency = 1,
                }, Theme.Animation.fast)
                if menuShadow then
                    tween(menuShadow, "dropdownShadowClose", {
                        Size = UDim2.fromOffset(menuWidth + 8, 0),
                        BackgroundTransparency = 1,
                    }, Theme.Animation.fast)
                end
            end
            task.delay(Theme.Animation.fast, function()
                if token == closeToken then
                    destroy_menu()
                end
            end)
            if chevron then
                tween(chevron, "dropdownChevron", { Rotation = 0 }, Theme.Animation.fast)
            end
            if glass and not disabled then
                glass:setTransparency(0.42)
            end
        end

        local function build_menu()
            local layer = Util.popupLayer(root)
            if not layer then
                return
            end
            menuOverlay = make_button(layer, {
                Name = "DropdownOutside",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ZIndex = 1,
                Parent = layer,
            })
            local menuX = root.AbsolutePosition.X
            local menuY = root.AbsolutePosition.Y + root.AbsoluteSize.Y + 6
            menuWidth = math.max(160, root.AbsoluteSize.X)
            local count = math.max(1, #currentOptions)
            menuTargetHeight = math.min(224, count * 36 + 10)
            menuShadow = Util.make("Frame", {
                Name = "DropdownShadow",
                Parent = layer,
                Position = UDim2.fromOffset(menuX + 2, menuY + 8),
                Size = UDim2.fromOffset(menuWidth + 8, 0),
                BackgroundColor3 = Theme.Colors.shadow,
                BackgroundTransparency = 0.76,
                BorderSizePixel = 0,
                ZIndex = 2,
            })
            Util.roundCorners(menuShadow, Theme.Radius.md + 4)
            menu = Util.make("Frame", {
                Name = "DropdownMenu",
                Parent = layer,
                Position = UDim2.fromOffset(menuX, menuY),
                Size = UDim2.fromOffset(menuWidth, 0),
                BackgroundColor3 = Theme.Colors.surfaceElevated,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Active = true,
                ZIndex = 3,
            })
            Util.roundCorners(menu, Theme.Radius.md)
            local menuGlass = Util.applyGlass(menu, {
                radius = Theme.Radius.md,
                colorKey = "surfaceElevated",
                transparency = 0.04,
                wash = true,
            })
            popupBin:add(menuGlass)

            menuScroll = Util.make("ScrollingFrame", {
                Name = "Options",
                Parent = menu,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Colors.textSecondary,
                ScrollBarImageTransparency = 0.55,
                ClipsDescendants = true,
                ZIndex = 4,
            })
            local padding = Util.make("UIPadding", {
                Parent = menuScroll,
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
            })
            menuLayout = Util.make("UIListLayout", {
                Parent = menuScroll,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            popupBin:add(padding)
            popupBin:add(menuLayout)

            for index, option in ipairs(currentOptions) do
                local optionButton = make_button(menuScroll, {
                    Name = "Option_" .. index,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Theme.Colors.control,
                    BackgroundTransparency = 1,
                    LayoutOrder = index,
                    Parent = menuScroll,
                })
                Util.roundCorners(optionButton, 8)
                if option.Icon then
                    make_label(optionButton, {
                        Name = "Icon",
                        Text = Icons.get(option.Icon, option.Icon),
                        Font = Theme.Typography.FontBold,
                        TextSize = 14,
                        Position = UDim2.fromOffset(10, 0),
                        Size = UDim2.fromOffset(18, 34),
                        TextXAlignment = Enum.TextXAlignment.Center,
                    })
                end
                make_label(optionButton, {
                    Name = "Label",
                    Text = option.Text,
                    Font = Theme.Typography.FontMedium,
                    TextSize = Theme.Typography.Size.small,
                    TextColor3 = option.Value == selectedValue and Theme.Colors.accent or Theme.Colors.text,
                    Position = UDim2.fromOffset(option.Icon and 36 or 10, 0),
                    Size = UDim2.new(1, -52, 1, 0),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                if option.Value == selectedValue then
                    make_label(optionButton, {
                        Name = "Check",
                        Text = Icons.check,
                        Font = Theme.Typography.FontBold,
                        TextSize = 14,
                        TextColor3 = Theme.Colors.accent,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -10, 0.5, 0),
                        Size = UDim2.fromOffset(16, 20),
                        TextXAlignment = Enum.TextXAlignment.Center,
                    })
                end
                popupBin:connect(optionButton.MouseEnter, function()
                    tween(optionButton, "optionHover", {
                        BackgroundTransparency = 0.93,
                    }, Theme.Animation.fast)
                end)
                popupBin:connect(optionButton.MouseLeave, function()
                    tween(optionButton, "optionHover", {
                        BackgroundTransparency = 1,
                    }, Theme.Animation.fast)
                end)
                popupBin:connect(optionButton.Activated, function()
                    choose_option(option, index)
                end)
            end

            openState = true
            refresh_label()
            position_menu()
            menu.Visible = true
            menuShadow.Visible = true
            tween(menu, "dropdownOpen", {
                Size = UDim2.fromOffset(menuWidth, menuTargetHeight),
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            tween(menuShadow, "dropdownShadowOpen", {
                Size = UDim2.fromOffset(menuWidth + 8, menuTargetHeight + 4),
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            renderConnection = RunService.RenderStepped:Connect(position_menu)
            escapeConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then
                    return
                end
                if input.KeyCode == Enum.KeyCode.Escape then
                    close_menu()
                end
            end)
            popupBin:connect(menuOverlay.Activated, function()
                close_menu()
            end)
            openThemeConnection = Theme.onChange(function()
                if not menu then
                    return
                end
                if chevron then
                    chevron.TextColor3 = Theme.Colors.textSecondary
                end
                refresh_label()
            end)
            glass:setTransparency(0.28)
            tween(chevron, "dropdownChevron", { Rotation = 180 }, Theme.Animation.fast)
        end

        local function open_menu()
            if openState or disabled then
                return
            end
            if activeKeybind and type(activeKeybind.cancel) == "function" then
                pcall(activeKeybind.cancel, activeKeybind)
            end
            build_menu()
        end

        bin:connect(root.Activated, function()
            if openState then
                close_menu()
            else
                open_menu()
            end
        end)

        theme_bind(bin, function()
            refresh_label()
            local option = selected_option()
            tween(chevron, "dropdownChevronColor", {
                TextColor3 = Theme.Colors.textSecondary,
            }, Theme.Animation.normal)
            tween(titleLabel, "dropdownTitle", {
                TextColor3 = Theme.Colors.text,
                TextTransparency = disabled and 0.4 or 0,
            }, Theme.Animation.normal)
            tween(selectedLabel, "dropdownSelected", {
                TextColor3 = option and Theme.Colors.text or Theme.Colors.textSecondary,
                TextTransparency = disabled and 0.45 or 0,
            }, Theme.Animation.normal)
            if disabled then
                tween(chevron, "dropdownChevronDisabled", {
                    TextTransparency = 0.45,
                }, Theme.Animation.normal)
            else
                tween(chevron, "dropdownChevronDisabled", {
                    TextTransparency = 0,
                }, Theme.Animation.normal)
            end
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            glass = glass,
        }

        function widget:getValue()
            return selectedValue
        end

        function widget:setValue(value, silent)
            selectedValue = value
            refresh_label()
            if not silent then
                local option = selected_option()
                fire(options.OnChange, selectedValue, option)
            end
            return self
        end

        function widget:setOptions(newOptions)
            currentOptions = normalize_options(newOptions)
            refresh_label()
            if openState then
                close_menu()
            end
            return self
        end

        function widget:open()
            open_menu()
            return self
        end

        function widget:close()
            close_menu()
            return self
        end

        function widget:setDisabled(state)
            disabled = state == true
            root.Active = not disabled
            root.Selectable = not disabled
            feedback:setEnabled(not disabled)
            if disabled then
                close_menu()
            end
            if disabled then
                titleLabel.TextTransparency = 0.4
                selectedLabel.TextTransparency = 0.45
                chevron.TextTransparency = 0.45
            else
                titleLabel.TextTransparency = 0
                selectedLabel.TextTransparency = 0
                chevron.TextTransparency = 0
            end
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            destroy_menu()
            bin:destroy()
            Animator.cancelAll(root)
            root:Destroy()
        end

        refresh_label()
        if disabled then
            titleLabel.TextTransparency = 0.4
            selectedLabel.TextTransparency = 0.45
            chevron.TextTransparency = 0.45
            feedback:setEnabled(false)
        end
        return widget
    end

    --==============================================================--
    -- TEXT INPUT
    --==============================================================--
    function Widgets.textinput(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local height = 72
        local showErrors = false
        local changeToken = 0
        local root = Util.make("Frame", {
            Name = "TextInput",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local field = Util.make("Frame", {
            Name = "Field",
            Parent = root,
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = Theme.Colors.background,
            BorderSizePixel = 0,
        })
        local glass = Util.applyGlass(field, {
            radius = Theme.Radius.md,
            colorKey = "background",
            transparency = 0.55,
            noise = false,
            wash = false,
        })
        bin:add(glass)
        local focus = Util.focusRing(field, Theme.Radius.md)
        bin:add(focus)

        if options.Icon then
            make_label(field, {
                Name = "Icon",
                Text = Icons.get(options.Icon, options.Icon),
                Font = Theme.Typography.FontBold,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = 14,
                Position = UDim2.fromOffset(13, 0),
                Size = UDim2.fromOffset(18, 44),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 2,
            })
        end

        local leftPadding = options.Icon and 40 or 14
        local textBox = Util.make("TextBox", {
            Name = "Input",
            Parent = field,
            Position = UDim2.fromOffset(leftPadding, 0),
            Size = UDim2.new(1, -(leftPadding + 14), 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = tostring(options.Value or ""),
            PlaceholderText = tostring(options.Placeholder or ""),
            PlaceholderColor3 = Theme.Colors.textSecondary,
            TextColor3 = Theme.Colors.text,
            Font = Theme.Typography.Font,
            TextSize = Theme.Typography.Size.small,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ClearTextOnFocus = false,
            MultiLine = false,
            TextEditable = options.Disabled ~= true,
            Selectable = options.Disabled ~= true,
            ZIndex = 2,
        })

        local errorLabel = make_label(root, {
            Name = "Error",
            Text = tostring(options.ErrorText or ""),
            TextColor3 = Theme.Colors.danger,
            TextSize = Theme.Typography.Size.caption,
            Position = UDim2.fromOffset(4, 47),
            Size = UDim2.new(1, -8, 0, 17),
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local errorVisible = false

        local function set_error(message)
            if message and tostring(message) ~= "" then
                errorVisible = true
                errorLabel.Text = tostring(message)
                tween(errorLabel, "inputError", { TextTransparency = 0 }, Theme.Animation.fast)
                Animator.tween(glass.stroke, "inputErrorStroke", {
                    Color = Theme.Colors.danger,
                    Transparency = 0.30,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            else
                errorVisible = false
                tween(errorLabel, "inputError", { TextTransparency = 1 }, Theme.Animation.fast)
                Animator.tween(glass.stroke, "inputErrorStroke", {
                    Color = Theme.Colors.border,
                    Transparency = Theme.Transparency.border,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            end
        end

        local function validate()
            if type(options.Validator) ~= "function" then
                set_error(nil)
                return true
            end
            local ok, result = pcall(options.Validator, textBox.Text)
            if not ok then
                set_error("Validation failed")
                return false
            end
            if result and tostring(result) ~= "" then
                set_error(tostring(result))
                return false
            end
            set_error(nil)
            return true
        end

        local function notify_change()
            if type(options.OnChange) == "function" then
                fire(options.OnChange, textBox.Text)
            end
        end

        local function schedule_change()
            changeToken = changeToken + 1
            local token = changeToken
            task.delay(0.12, function()
                if token ~= changeToken then
                    return
                end
                if showErrors then
                    validate()
                end
                notify_change()
            end)
        end

        bin:connect(textBox:GetPropertyChangedSignal("Text"), schedule_change)
        bin:connect(textBox.Focused, function()
            focus:setFocused(true)
        end)
        bin:connect(textBox.FocusLost, function(enterPressed)
            focus:setFocused(false)
            showErrors = true
            validate()
            notify_change()
            if enterPressed then
                pcall(function()
                    textBox:ReleaseFocus()
                end)
            end
        end)

        theme_bind(bin, function()
            Animator.tween(textBox, "inputText", {
                TextColor3 = Theme.Colors.text,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(textBox, "inputPlaceholder", {
                PlaceholderColor3 = Theme.Colors.textSecondary,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(errorLabel, "inputErrorColor", {
                TextColor3 = Theme.Colors.danger,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            if errorVisible then
                set_error(errorLabel.Text)
            end
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            field = field,
            textBox = textBox,
        }

        function widget:get()
            return textBox.Text
        end

        function widget:set(text, silent)
            textBox.Text = tostring(text or "")
            if not silent then
                notify_change()
            end
            if showErrors then
                validate()
            end
            return self
        end

        function widget:setError(message)
            showErrors = true
            set_error(message)
            return self
        end

        function widget:validate()
            showErrors = true
            return validate()
        end

        function widget:focus()
            pcall(function()
                textBox:CaptureFocus()
            end)
            return self
        end

        function widget:setDisabled(state)
            local disabled = state == true
            textBox.TextEditable = not disabled
            textBox.Selectable = not disabled
            field.BackgroundTransparency = disabled and 0.35 or glass:getTransparency()
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            Animator.cancelAll(root)
            bin:destroy()
            glass:destroy()
            root:Destroy()
        end

        return widget
    end

    --==============================================================--
    -- KEYBIND
    --==============================================================--
    function Widgets.keybind(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local value = options.Value
        local capturing = false
        local captureConnection = nil
        local height = 54
        local root = Util.make("Frame", {
            Name = "Keybind",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local title = make_label(root, {
            Name = "Title",
            Text = tostring(options.Text or "Keybind"),
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -158, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local chip = make_button(root, {
            Name = "KeyChip",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(132, 30),
            BackgroundColor3 = Theme.Colors.background,
            Parent = root,
        })
        Util.markNoDrag(chip)
        local chipGlass = Util.applyGlass(chip, {
            radius = 9,
            colorKey = "background",
            transparency = 0.42,
            noise = false,
            wash = false,
        })
        bin:add(chipGlass)
        local keyLabel = make_label(chip, {
            Name = "Key",
            Text = key_name(value),
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.caption,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2,
        })
        local feedback = Util.feedback(chip, {
            radius = 9,
            pressScale = 0.97,
            hoverScale = 1,
            onHover = function(state)
                if capturing then
                    return
                end
                chipGlass:setTransparency(state and 0.30 or 0.42)
            end,
        })
        bin:add(feedback)

        local widget

        local function disconnect_capture()
            safe_disconnect(captureConnection)
            captureConnection = nil
        end

        local function finish_capture()
            capturing = false
            disconnect_capture()
            if activeKeybind == widget then
                activeKeybind = nil
            end
            keyLabel.Text = key_name(value)
            tween(keyLabel, "keybindColor", { TextColor3 = Theme.Colors.text }, Theme.Animation.fast)
            Animator.tween(chipGlass.stroke, "keybindStroke", {
                Color = Theme.Colors.border,
                Transparency = Theme.Transparency.border,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            chipGlass:setTransparency(0.42)
        end

        local function cancel_capture()
            if not capturing then
                return
            end
            finish_capture()
        end

        local function start_capture()
            if options.Disabled then
                return
            end
            if activeKeybind and activeKeybind ~= widget then
                pcall(activeKeybind.cancel)
            end
            capturing = true
            activeKeybind = widget
            keyLabel.Text = "Press any key..."
            tween(keyLabel, "keybindColor", { TextColor3 = Theme.Colors.accent }, Theme.Animation.fast)
            Animator.tween(chipGlass.stroke, "keybindStroke", {
                Color = Theme.Colors.accent,
                Transparency = 0.18,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            chipGlass:setTransparency(0.22)
            disconnect_capture()
            captureConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not capturing then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.Keyboard
                    and input.UserInputType ~= Enum.UserInputType.Gamepad1 then
                    return
                end
                if input.KeyCode == Enum.KeyCode.Unknown then
                    return
                end
                if gameProcessed then
                    return
                end
                if input.KeyCode == Enum.KeyCode.Escape then
                    finish_capture()
                    return
                end
                value = input.KeyCode
                finish_capture()
                fire(options.OnChange, value)
            end)
        end

        bin:connect(chip.Activated, function()
            if capturing then
                cancel_capture()
            else
                start_capture()
            end
        end)

        theme_bind(bin, function()
            tween(title, "keybindTitle", {
                TextColor3 = Theme.Colors.text,
            }, Theme.Animation.normal)
            tween(keyLabel, "keybindKey", {
                TextColor3 = capturing and Theme.Colors.accent or Theme.Colors.text,
            }, Theme.Animation.normal)
        end)

        widget = {
            _instance = root,
            _height = height,
            root = root,
            cancel = cancel_capture,
            _autoWidth = false,
        }

        function widget:getValue()
            return value
        end

        function widget:setValue(newValue, silent)
            value = newValue
            keyLabel.Text = key_name(value)
            if not silent then
                fire(options.OnChange, value)
            end
            return self
        end

        function widget:startCapture()
            start_capture()
            return self
        end

        function widget:cancelCapture()
            cancel_capture()
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            cancel_capture()
            Animator.cancelAll(root)
            bin:destroy()
            chipGlass:destroy()
            root:Destroy()
        end

        bin:add(function()
            cancel_capture()
        end)

        return widget
    end

    --==============================================================--
    -- COLOR PICKER
    --==============================================================--
    function Widgets.colorpicker(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local initial = options.Value
        if typeof(initial) ~= "Color3" then
            initial = Theme.Colors.accent
        end
        local hue, saturation, brightness = initial:ToHSV()
        local expanded = options.Expanded == true
        local collapsedHeight = 54
        local expandedHeight = 266
        local height = expanded and expandedHeight or collapsedHeight
        local dragConnectionChanged = nil
        local dragConnectionEnded = nil
        local hexFocused = false
        local root = Util.make("Frame", {
            Name = "ColorPicker",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        })
        local header = make_button(root, {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Theme.Colors.control,
            BackgroundTransparency = 1,
            Parent = root,
        })
        Util.markNoDrag(header)
        local headerCorner = Util.roundCorners(header, Theme.Radius.md)

        local swatch = Util.make("Frame", {
            Name = "Swatch",
            Parent = header,
            Position = UDim2.fromOffset(12, 15),
            Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = initial,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        Util.roundCorners(swatch, 7)
        local swatchStroke = Util.make("UIStroke", {
            Parent = swatch,
            Color = Theme.Colors.border,
            Transparency = 0.64,
            Thickness = 1,
        })
        local title = make_label(header, {
            Name = "Title",
            Text = tostring(options.Text or "Color"),
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(42, 0),
            Size = UDim2.new(1, -152, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local hexPreview = make_label(header, {
            Name = "HexPreview",
            Text = Util.colorToHex(initial),
            Font = Theme.Typography.Font,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.caption,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -34, 0.5, 0),
            Size = UDim2.fromOffset(92, 20),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 2,
        })
        local chevron = make_label(header, {
            Name = "Chevron",
            Text = Icons.chevronDown,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.body,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(16, 20),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2,
        })

        local panel = Util.make("Frame", {
            Name = "Panel",
            Parent = root,
            Position = UDim2.fromOffset(0, 52),
            Size = UDim2.new(1, 0, 0, 214),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = expanded,
            ClipsDescendants = false,
        })
        local square = Util.make("Frame", {
            Name = "SaturationValue",
            Parent = panel,
            Position = UDim2.fromOffset(12, 4),
            Size = UDim2.new(1, -24, 0, 132),
            BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 2,
        })
        Util.roundCorners(square, 8)
        local whiteOverlay = Util.make("Frame", {
            Name = "White",
            Parent = square,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 1,
        })
        Util.make("UIGradient", {
            Parent = whiteOverlay,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        })
        local blackOverlay = Util.make("Frame", {
            Name = "Black",
            Parent = square,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        Util.make("UIGradient", {
            Parent = blackOverlay,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        })
        local cursor = Util.make("Frame", {
            Name = "Cursor",
            Parent = square,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(saturation, 1 - brightness),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 6,
        })
        Util.roundCorners(cursor, 7)
        Util.make("UIStroke", {
            Parent = cursor,
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Transparency = 0.08,
        })
        local squareHit = make_button(square, {
            Name = "Hit",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 8,
            Parent = square,
        })

        local hueBar = Util.make("Frame", {
            Name = "Hue",
            Parent = panel,
            Position = UDim2.fromOffset(12, 148),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 2,
        })
        Util.roundCorners(hueBar, 7)
        Util.make("UIGradient", {
            Parent = hueBar,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
        })
        local hueThumb = Util.make("Frame", {
            Name = "HueThumb",
            Parent = hueBar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(hue, 0.5),
            Size = UDim2.fromOffset(5, 20),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 5,
        })
        Util.roundCorners(hueThumb, 3)
        Util.make("UIStroke", {
            Parent = hueThumb,
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.45,
            Thickness = 1,
        })
        local hueHit = make_button(hueBar, {
            Name = "Hit",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 8,
            Parent = hueBar,
        })

        local hexLabel = make_label(panel, {
            Name = "HexLabel",
            Text = "HEX",
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.caption,
            Position = UDim2.fromOffset(12, 172),
            Size = UDim2.fromOffset(36, 30),
            ZIndex = 2,
        })
        local hexField = Util.make("Frame", {
            Name = "HexField",
            Parent = panel,
            Position = UDim2.new(1, -126, 0, 172),
            Size = UDim2.fromOffset(114, 30),
            BackgroundColor3 = Theme.Colors.background,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        Util.roundCorners(hexField, 8)
        local hexGlass = Util.applyGlass(hexField, {
            radius = 8,
            colorKey = "background",
            transparency = 0.48,
            noise = false,
            wash = false,
        })
        bin:add(hexGlass)
        local hexBox = Util.make("TextBox", {
            Name = "HexBox",
            Parent = hexField,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = Util.colorToHex(initial),
            PlaceholderText = "#0A84FF",
            PlaceholderColor3 = Theme.Colors.textSecondary,
            TextColor3 = Theme.Colors.text,
            Font = Theme.Typography.Font,
            TextSize = Theme.Typography.Size.caption,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            ZIndex = 3,
        })

        local deleting = false

        local function current_color()
            return Color3.fromHSV(hue, saturation, brightness)
        end

        local function update_visuals()
            local color = current_color()
            square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            cursor.Position = UDim2.fromScale(saturation, 1 - brightness)
            hueThumb.Position = UDim2.fromScale(hue, 0.5)
            swatch.BackgroundColor3 = color
            if not hexFocused then
                hexBox.Text = Util.colorToHex(color)
            end
            hexPreview.Text = Util.colorToHex(color)
        end

        local function emit()
            fire(options.OnChange, current_color())
        end

        local function stop_drag()
            safe_disconnect(dragConnectionChanged)
            safe_disconnect(dragConnectionEnded)
            dragConnectionChanged = nil
            dragConnectionEnded = nil
        end

        local function begin_drag(updateCallback)
            stop_drag()
            updateCallback(nil)
            dragConnectionChanged = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    updateCallback(input)
                end
            end)
            dragConnectionEnded = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    stop_drag()
                end
            end)
        end

        local function update_from_square(input)
            local position = Util.mousePosition(input)
            local absolute = square.AbsolutePosition
            local size = square.AbsoluteSize
            saturation = math.clamp((position.X - absolute.X) / math.max(1, size.X), 0, 1)
            brightness = 1 - math.clamp((position.Y - absolute.Y) / math.max(1, size.Y), 0, 1)
            update_visuals()
            emit()
        end

        local function update_from_hue(input)
            local position = Util.mousePosition(input)
            local absolute = hueBar.AbsolutePosition
            local size = hueBar.AbsoluteSize
            local nextHue = math.clamp((position.X - absolute.X) / math.max(1, size.X), 0, 0.99999)
            hue = nextHue
            update_visuals()
            emit()
        end

        bin:connect(squareHit.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            begin_drag(function(current)
                update_from_square(current or input)
            end)
        end)
        bin:connect(hueHit.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            begin_drag(function(current)
                update_from_hue(current or input)
            end)
        end)

        local function set_expanded(state, silent)
            if deleting then
                return
            end
            expanded = state and true or false
            chevron.Rotation = expanded and 180 or 0
            if expanded then
                panel.Visible = true
                tween(root, "colorHeight", { Size = UDim2.new(1, 0, 0, expandedHeight) }, Theme.Animation.normal)
            else
                tween(root, "colorHeight", { Size = UDim2.new(1, 0, 0, collapsedHeight) }, Theme.Animation.normal)
                task.delay(Theme.Animation.normal, function()
                    if not expanded and not deleting then
                        panel.Visible = false
                    end
                end)
            end
            if not silent then
                fire(options.OnToggle, expanded)
            end
        end

        bin:connect(header.Activated, function()
            if options.Disabled then
                return
            end
            set_expanded(not expanded)
        end)
        bin:connect(header.MouseEnter, function()
            tween(header, "colorHeaderHover", { BackgroundTransparency = 0.955 }, Theme.Animation.fast)
        end)
        bin:connect(header.MouseLeave, function()
            tween(header, "colorHeaderHover", { BackgroundTransparency = 1 }, Theme.Animation.fast)
        end)

        bin:connect(hexBox.Focused, function()
            hexFocused = true
        end)
        bin:connect(hexBox.FocusLost, function(enterPressed)
            hexFocused = false
            local parsed = Util.hexToColor(hexBox.Text)
            if parsed then
                hue, saturation, brightness = parsed:ToHSV()
                update_visuals()
                emit()
            else
                hexBox.Text = Util.colorToHex(current_color())
            end
            if enterPressed then
                pcall(function()
                    hexBox:ReleaseFocus()
                end)
            end
        end)

        theme_bind(bin, function()
            tween(title, "colorTitle", { TextColor3 = Theme.Colors.text }, Theme.Animation.normal)
            tween(hexPreview, "colorHexPreview", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            tween(chevron, "colorChevron", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            Animator.tween(hexBox, "colorHexText", {
                TextColor3 = Theme.Colors.text,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(hexBox, "colorHexPlaceholder", {
                PlaceholderColor3 = Theme.Colors.textSecondary,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            tween(hexLabel, "colorHexLabel", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            tween(swatchStroke, "colorSwatchStroke", { Color = Theme.Colors.border }, Theme.Animation.normal)
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            expandedHeight = expandedHeight,
        }

        function widget:getValue()
            return current_color()
        end

        function widget:setValue(color, silent)
            if typeof(color) ~= "Color3" then
                return self
            end
            hue, saturation, brightness = color:ToHSV()
            update_visuals()
            if not silent then
                emit()
            end
            return self
        end

        function widget:expand()
            set_expanded(true, true)
            return self
        end

        function widget:collapse()
            set_expanded(false, true)
            return self
        end

        function widget:toggle()
            set_expanded(not expanded, true)
            return self
        end

        function widget:isExpanded()
            return expanded
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            deleting = true
            stop_drag()
            Animator.cancelAll(root)
            bin:destroy()
            root:Destroy()
        end

        update_visuals()
        return widget
    end

    --==============================================================--
    -- SECTION
    --==============================================================--
    local function add_error_text(scope, err)
        local label = make_label(scope._parent, {
            Name = "RenderError",
            Text = "Unable to render: " .. tostring(err),
            TextColor3 = Theme.Colors.danger,
            TextSize = Theme.Typography.Size.caption,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            TextYAlignment = Enum.TextYAlignment.Top,
        })
        scope:_trackInstance(label)
        return label
    end

    function Widgets.section(parent, options)
        options = options or {}
        local collapsible = options.Collapsible ~= false
        local expanded = options.Expanded ~= false or not collapsible
        local root = Util.make("Frame", {
            Name = "Section",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Colors.surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        })
        local glass = Util.applyGlass(root, {
            radius = Theme.Radius.lg,
            colorKey = "surface",
            transparency = Theme.Transparency.surface,
            wash = true,
        })

        local body = Util.make("Frame", {
            Name = "Body",
            Parent = root,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        local bodyLayout = Util.make("UIListLayout", {
            Parent = body,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),
        })

        local header = make_button(body, {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = Theme.Colors.control,
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Parent = body,
            ZIndex = 3,
        })
        Util.roundCorners(header, Theme.Radius.lg)
        local titleX = 14
        local iconLabel = nil
        if options.Icon then
            iconLabel = make_label(header, {
                Name = "Icon",
                Text = Icons.get(options.Icon, options.Icon),
                Font = Theme.Typography.FontBold,
                TextColor3 = Theme.Colors.accent,
                TextSize = 14,
                Position = UDim2.fromOffset(14, 0),
                Size = UDim2.fromOffset(18, 46),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 2,
            })
            titleX = 40
        end
        local title = make_label(header, {
            Name = "Title",
            Text = tostring(options.Title or "Section"),
            Font = Theme.Typography.FontBold,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(titleX, 0),
            Size = UDim2.new(1, -(titleX + 44), 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local arrow = nil
        if collapsible then
            arrow = make_label(header, {
                Name = "Arrow",
                Text = Icons.chevronDown,
                Font = Theme.Typography.FontBold,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.body,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(18, 20),
                TextXAlignment = Enum.TextXAlignment.Center,
                Rotation = expanded and 0 or -90,
                ZIndex = 2,
            })
        end

        local content = Util.make("Frame", {
            Name = "Content",
            Parent = body,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 2,
            Visible = expanded,
            ClipsDescendants = true,
            ZIndex = 2,
        })
        local contentPadding = Util.make("UIPadding", {
            Parent = content,
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
        })
        local contentLayout = Util.make("UIListLayout", {
            Parent = content,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })

        local scope = {
            _parent = content,
            _instance = root,
            _height = 46,
            _autoWidth = false,
            _rowFlex = false,
        }
        Widgets._decorate(scope)
        scope._bin:add(glass)
        scope._bin:add(contentPadding)
        scope._bin:add(contentLayout)
        scope._bin:add(bodyLayout)
        scope.glass = glass

        local contentHeight = 0
        local animating = false
        local collapsing = false

        local function measure_content()
            local layoutHeight = 0
            pcall(function()
                layoutHeight = contentLayout.AbsoluteContentSize.Y
            end)
            if layoutHeight > 0 then
                contentHeight = layoutHeight + 17
            elseif contentHeight <= 0 then
                contentHeight = math.max(80, #scope._children * 46)
            end
            return contentHeight
        end

        local function refresh_measure()
            measure_content()
        end

        scope._bin:connect(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            task.defer(refresh_measure)
        end)

        local function set_expanded(state, silent)
            if not collapsible or animating then
                return
            end
            state = state and true or false
            if state == expanded then
                return
            end
            expanded = state
            if arrow then
                tween(arrow, "sectionArrow", { Rotation = expanded and 0 or -90 }, Theme.Animation.normal)
            end
            if expanded then
                local target = math.max(60, measure_content())
                content.Visible = true
                content.AutomaticSize = Enum.AutomaticSize.None
                content.Size = UDim2.new(1, 0, 0, 0)
                animating = true
                tween(content, "sectionHeight", {
                    Size = UDim2.new(1, 0, 0, target),
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                task.delay(Theme.Animation.normal + 0.02, function()
                    animating = false
                    if scope._destroyed then
                        return
                    end
                    if expanded then
                        content.AutomaticSize = Enum.AutomaticSize.Y
                        content.Size = UDim2.new(1, 0, 0, 0)
                    end
                end)
            else
                collapsing = true
                local target = content.AbsoluteSize.Y
                if target <= 0 then
                    target = measure_content()
                end
                content.AutomaticSize = Enum.AutomaticSize.None
                content.Size = UDim2.new(1, 0, 0, target)
                animating = true
                tween(content, "sectionHeight", {
                    Size = UDim2.new(1, 0, 0, 0),
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                task.delay(Theme.Animation.normal + 0.02, function()
                    animating = false
                    collapsing = false
                    if scope._destroyed then
                        return
                    end
                    if not expanded then
                        content.Visible = false
                        content.Size = UDim2.new(1, 0, 0, 0)
                    end
                end)
            end
            if not silent then
                fire(options.OnToggle, expanded)
            end
        end

        scope._bin:connect(header.Activated, function()
            if collapsible then
                set_expanded(not expanded)
            end
        end)
        if collapsible then
            scope._bin:connect(header.MouseEnter, function()
                tween(header, "sectionHeaderHover", { BackgroundTransparency = 0.955 }, Theme.Animation.fast)
            end)
            scope._bin:connect(header.MouseLeave, function()
                tween(header, "sectionHeaderHover", { BackgroundTransparency = 1 }, Theme.Animation.fast)
            end)
        else
            header.Active = false
            header.Selectable = false
        end

        theme_bind(scope._bin, function()
            tween(title, "sectionTitle", { TextColor3 = Theme.Colors.text }, Theme.Animation.normal)
            if iconLabel then
                tween(iconLabel, "sectionIcon", { TextColor3 = Theme.Colors.accent }, Theme.Animation.normal)
            end
            if arrow then
                tween(arrow, "sectionArrowColor", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            end
            glass:setAccent(Theme.Colors.accent)
        end)

        function scope:setTitle(text)
            title.Text = tostring(text or "")
            return self
        end

        function scope:setExpanded(state)
            set_expanded(state)
            return self
        end

        function scope:expand()
            set_expanded(true)
            return self
        end

        function scope:collapse()
            set_expanded(false)
            return self
        end

        function scope:toggleExpanded()
            set_expanded(not expanded)
            return self
        end

        function scope:isExpanded()
            return expanded
        end

        function scope:refreshHeight()
            measure_content()
            if expanded then
                content.AutomaticSize = Enum.AutomaticSize.Y
                content.Size = UDim2.new(1, 0, 0, 0)
            end
            return self
        end

        local callback = options.Content or options.Callback
        if type(callback) == "function" then
            local ok, err = xpcall(callback, debug.traceback, scope)
            if not ok then
                add_error_text(scope, err)
            end
        end
        task.defer(refresh_measure)

        if not expanded then
            content.Visible = false
            content.Size = UDim2.new(1, 0, 0, 0)
        end

        return scope
    end

    --==============================================================--
    -- CARD CONTAINER (page:card(function ... end))
    --==============================================================--
    function Widgets.cardContainer(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local root = Util.make("Frame", {
            Name = "CardContainer",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Colors.surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        })
        local glass = Util.applyGlass(root, {
            radius = Theme.Radius.lg,
            colorKey = "surface",
            transparency = Theme.Transparency.surface,
            wash = true,
        })
        bin:add(glass)
        local body = Util.make("Frame", {
            Name = "Body",
            Parent = root,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        local padding = Util.make("UIPadding", {
            Parent = body,
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
        })
        local layout = Util.make("UIListLayout", {
            Parent = body,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })
        bin:add(padding)
        bin:add(layout)

        if options.Title then
            local title = make_label(body, {
                Name = "CardTitle",
                Text = tostring(options.Title),
                Font = Theme.Typography.FontBold,
                TextSize = Theme.Typography.Size.body,
                Size = UDim2.new(1, 0, 0, 22),
                LayoutOrder = -1,
            })
            bin:add(Theme.onChange(function()
                Animator.tween(title, "cardContainerTitle", {
                    TextColor3 = Theme.Colors.text,
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            end))
        end

        local scope = {
            _parent = body,
            _instance = root,
            _bin = bin,
            _height = 64,
            _rowFinalize = false,
            _rowFlex = false,
        }
        Widgets._decorate(scope)
        scope.glass = glass

        local callback = options.Content or options.Callback
        if type(callback) == "function" then
            local ok, err = xpcall(callback, debug.traceback, scope)
            if not ok then
                add_error_text(scope, err)
            end
        end
        return scope
    end

    --==============================================================--
    -- CARD
    --==============================================================--
    function Widgets.card(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local clickable = type(options.OnClick) == "function"
        local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
        local height = hasDescription and 76 or 64
        local root = make_button(parent, {
            Name = "Card",
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme.Colors.surfaceElevated,
            Active = clickable,
            Selectable = clickable,
            Parent = parent,
        })
        Util.markNoDrag(root)
        local glass = Util.applyGlass(root, {
            radius = Theme.Radius.lg,
            colorKey = "surfaceElevated",
            transparency = 0.18,
            wash = true,
        })
        bin:add(glass)
        local feedback = Util.feedback(root, {
            radius = Theme.Radius.lg,
            pressScale = clickable and 0.985 or 1,
            hoverScale = 1,
            onHover = function(state)
                if not clickable then
                    return
                end
                glass:setTransparency(state and 0.08 or 0.18)
            end,
        })
        bin:add(feedback)

        local iconFrame = nil
        if options.Icon then
            iconFrame = Util.make("Frame", {
                Name = "IconFrame",
                Parent = root,
                Position = UDim2.fromOffset(14, 0),
                Size = UDim2.fromOffset(36, 36),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.Colors.accent,
                BackgroundTransparency = 0.82,
                BorderSizePixel = 0,
                ZIndex = 2,
            })
            iconFrame.Position = UDim2.new(0, 14, 0.5, 0)
            Util.roundCorners(iconFrame, 11)
            make_label(iconFrame, {
                Name = "Icon",
                Text = Icons.get(options.Icon, options.Icon),
                Font = Theme.Typography.FontBold,
                TextColor3 = Theme.Colors.accent,
                TextSize = 16,
                Size = UDim2.fromScale(1, 1),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 3,
            })
        end
        local textX = options.Icon and 62 or 16
        local title = make_label(root, {
            Name = "Title",
            Text = tostring(options.Title or "Card"),
            Font = Theme.Typography.FontBold,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(textX, hasDescription and 15 or 0),
            Size = UDim2.new(1, -(textX + 46), 0, hasDescription and 20 or height),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local description = nil
        if hasDescription then
            description = make_label(root, {
                Name = "Description",
                Text = tostring(options.Description),
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                Position = UDim2.fromOffset(textX, 37),
                Size = UDim2.new(1, -(textX + 46), 0, 18),
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 2,
            })
        end
        local rightContainer = Util.make("Frame", {
            Name = "Right",
            Parent = root,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(80, 30),
            BackgroundTransparency = 1,
            ZIndex = 3,
        })
        local rightLabel = nil
        if type(options.RightContent) == "string" then
            rightLabel = make_label(rightContainer, {
                Name = "RightText",
                Text = options.RightContent,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                Size = UDim2.fromScale(1, 1),
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 3,
            })
        elseif typeof(options.RightContent) == "Instance" then
            options.RightContent.Parent = rightContainer
        elseif type(options.RightContent) == "function" then
            pcall(options.RightContent, rightContainer)
        elseif clickable then
            rightLabel = make_label(rightContainer, {
                Name = "Arrow",
                Text = Icons.chevronRight,
                TextColor3 = Theme.Colors.textSecondary,
                Font = Theme.Typography.FontBold,
                TextSize = 16,
                Size = UDim2.fromScale(1, 1),
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 3,
            })
        end

        bin:connect(root.Activated, function()
            if not clickable or options.Disabled then
                return
            end
            fire(options.OnClick)
        end)

        theme_bind(bin, function()
            tween(title, "cardTitle", { TextColor3 = Theme.Colors.text }, Theme.Animation.normal)
            if description then
                tween(description, "cardDescription", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            end
            if rightLabel then
                tween(rightLabel, "cardRight", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            end
            if iconFrame then
                tween(iconFrame, "cardIconFrame", { BackgroundColor3 = Theme.Colors.accent }, Theme.Animation.normal)
            end
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            glass = glass,
        }

        function widget:setTitle(text)
            title.Text = tostring(text or "")
            return self
        end

        function widget:setDescription(text)
            if description then
                description.Text = tostring(text or "")
            end
            return self
        end

        function widget:setRight(value)
            if rightLabel then
                rightLabel.Text = tostring(value or "")
            end
            return self
        end

        function widget:setDisabled(state)
            options.Disabled = state == true
            root.Active = not options.Disabled and clickable
            root.Selectable = not options.Disabled and clickable
            feedback:setEnabled(not options.Disabled)
            tween(title, "cardDisabled", { TextTransparency = options.Disabled and 0.45 or 0 }, Theme.Animation.fast)
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            Animator.cancelAll(root)
            bin:destroy()
            glass:destroy()
            root:Destroy()
        end

        return widget
    end

    --==============================================================--
    -- BADGE
    --==============================================================--
    function Widgets.badge(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local color = typeof(options.Color) == "Color3" and options.Color or Theme.Colors.accent
        local text = tostring(options.Text or "Badge")
        local fontSize = Theme.Typography.Size.caption
        local textWidth = Util.textWidth(text, fontSize, Theme.Typography.FontMedium)
        local width = math.ceil(textWidth + 22 + (options.Icon and 18 or 0))
        local root = Util.make("Frame", {
            Name = "Badge",
            Parent = parent,
            Size = UDim2.fromOffset(width, 22),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.80,
            BorderSizePixel = 0,
        })
        Util.roundCorners(root, 11)
        local stroke = Util.make("UIStroke", {
            Parent = root,
            Color = color,
            Transparency = 0.66,
            Thickness = 1,
        })
        local x = 9
        if options.Icon then
            make_label(root, {
                Name = "Icon",
                Text = Icons.get(options.Icon, options.Icon),
                Font = Theme.Typography.FontBold,
                TextColor3 = color,
                TextSize = 11,
                Position = UDim2.fromOffset(x, 0),
                Size = UDim2.fromOffset(14, 22),
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            x = x + 16
        end
        local label = make_label(root, {
            Name = "Label",
            Text = text,
            Font = Theme.Typography.FontMedium,
            TextColor3 = color,
            TextSize = fontSize,
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.new(1, -(x + 8), 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        local widget = {
            _instance = root,
            _height = 22,
            _autoWidth = true,
            root = root,
        }

        function widget:setText(value)
            local nextText = tostring(value or "")
            label.Text = nextText
            local nextWidth = math.ceil(
                Util.textWidth(nextText, fontSize, Theme.Typography.FontMedium)
                + 22 + (options.Icon and 18 or 0)
            )
            root.Size = UDim2.fromOffset(nextWidth, 22)
            return self
        end

        function widget:setColor(value)
            if typeof(value) == "Color3" then
                color = value
                root.BackgroundColor3 = value
                stroke.Color = value
                label.TextColor3 = value
            end
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            bin:destroy()
            root:Destroy()
        end

        theme_bind(bin, function()
            if not options.Color then
                tween(root, "badgeBackground", { BackgroundColor3 = Theme.Colors.accent }, Theme.Animation.normal)
                tween(stroke, "badgeStroke", { Color = Theme.Colors.accent }, Theme.Animation.normal)
                tween(label, "badgeLabel", { TextColor3 = Theme.Colors.accent }, Theme.Animation.normal)
            end
        end)
        return widget
    end

    --==============================================================--
    -- CHIP
    --==============================================================--
    function Widgets.chip(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local removable = options.Removable == true
        local text = tostring(options.Text or "Chip")
        local textWidth = Util.textWidth(text, Theme.Typography.Size.caption, Theme.Typography.FontMedium)
        local width = math.ceil(textWidth + 24 + (options.Icon and 18 or 0) + (removable and 22 or 0))
        local root = Util.make("Frame", {
            Name = "Chip",
            Parent = parent,
            Size = UDim2.fromOffset(width, 26),
            BackgroundColor3 = Theme.Colors.control,
            BackgroundTransparency = 0.94,
            BorderSizePixel = 0,
        })
        Util.roundCorners(root, 13)
        Util.make("UIStroke", {
            Parent = root,
            Color = Theme.Colors.border,
            Transparency = 0.86,
            Thickness = 1,
        })
        local x = 10
        if options.Icon then
            make_label(root, {
                Name = "Icon",
                Text = Icons.get(options.Icon, options.Icon),
                Font = Theme.Typography.FontBold,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = 11,
                Position = UDim2.fromOffset(x, 0),
                Size = UDim2.fromOffset(14, 26),
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            x = x + 17
        end
        local label = make_label(root, {
            Name = "Label",
            Text = text,
            Font = Theme.Typography.FontMedium,
            TextColor3 = Theme.Colors.text,
            TextSize = Theme.Typography.Size.caption,
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.new(1, -(x + (removable and 28 or 8)), 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local scale = Util.make("UIScale", { Parent = root, Scale = 1 })
        local closeButton = nil
        local widget
        if removable then
            closeButton = make_button(root, {
                Name = "Remove",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(20, 20),
                BackgroundTransparency = 1,
                Parent = root,
            })
            make_label(closeButton, {
                Name = "X",
                Text = Icons.close,
                Font = Theme.Typography.FontBold,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = 13,
                Size = UDim2.fromScale(1, 1),
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            bin:connect(closeButton.MouseEnter, function()
                tween(closeButton, "chipCloseHover", { BackgroundTransparency = 0.92 }, Theme.Animation.fast)
            end)
            bin:connect(closeButton.MouseLeave, function()
                tween(closeButton, "chipCloseHover", { BackgroundTransparency = 1 }, Theme.Animation.fast)
            end)
            bin:connect(closeButton.Activated, function()
                if options.OnRemove then
                    fire(options.OnRemove)
                end
                tween(scale, "chipRemove", { Scale = 0.9 }, Theme.Animation.fast)
                task.delay(Theme.Animation.fast, function()
                    widget:destroy()
                end)
            end)
        end

        widget = {
            _instance = root,
            _height = 26,
            _autoWidth = true,
            root = root,
        }

        function widget:setText(value)
            local nextText = tostring(value or "")
            label.Text = nextText
            local nextWidth = math.ceil(
                Util.textWidth(nextText, Theme.Typography.Size.caption, Theme.Typography.FontMedium)
                + 24 + (options.Icon and 18 or 0) + (removable and 22 or 0)
            )
            root.Size = UDim2.fromOffset(nextWidth, 26)
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            Animator.cancelAll(root)
            bin:destroy()
            root:Destroy()
        end

        theme_bind(bin, function()
            tween(label, "chipLabel", { TextColor3 = Theme.Colors.text }, Theme.Animation.normal)
            tween(root, "chipBackground", { BackgroundColor3 = Theme.Colors.control }, Theme.Animation.normal)
        end)
        return widget
    end

    --==============================================================--
    -- AVATAR
    --==============================================================--
    function Widgets.avatar(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local status = options.Status or "offline"
        local height = 46
        local root = Util.make("Frame", {
            Name = "Avatar",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local imageFrame = Util.make("Frame", {
            Name = "AvatarCircle",
            Parent = root,
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(38, 38),
            BackgroundColor3 = Theme.Colors.surfaceElevated,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        })
        Util.roundCorners(imageFrame, 19)
        local imageStroke = Util.make("UIStroke", {
            Parent = imageFrame,
            Color = Theme.Colors.border,
            Transparency = 0.82,
            Thickness = 1,
        })
        local initials = make_label(imageFrame, {
            Name = "Initials",
            Text = "",
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = 13,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        local imageLabel = Util.make("ImageLabel", {
            Name = "Image",
            Parent = imageFrame,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = options.Image or "",
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 2,
        })
        local dot = Util.make("Frame", {
            Name = "Status",
            Parent = imageFrame,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 1, 1, 1),
            Size = UDim2.fromOffset(11, 11),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BorderSizePixel = 0,
            ZIndex = 5,
        })
        Util.roundCorners(dot, 6)
        Util.make("UIStroke", {
            Parent = dot,
            Color = Theme.Colors.background,
            Thickness = 2,
            Transparency = 0.1,
        })
        local nameLabel = make_label(root, {
            Name = "Name",
            Text = tostring(options.Name or "User"),
            Font = Theme.Typography.FontMedium,
            TextSize = Theme.Typography.Size.small,
            Position = UDim2.fromOffset(62, options.Name and 10 or 0),
            Size = UDim2.new(1, -74, 0, 18),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local statusLabel = make_label(root, {
            Name = "StatusText",
            Text = "",
            Font = Theme.Typography.Font,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.caption,
            Position = UDim2.fromOffset(62, 27),
            Size = UDim2.new(1, -74, 0, 14),
        })

        local function status_color(value)
            if value == "online" then
                return Theme.Colors.success
            elseif value == "idle" then
                return Theme.Colors.warning
            elseif value == "dnd" then
                return Theme.Colors.danger
            end
            return Theme.Colors.textSecondary
        end

        local function update_status()
            dot.BackgroundColor3 = status_color(status)
            statusLabel.Text = status == "online" and "Online"
                or status == "idle" and "Idle"
                or status == "dnd" and "Do Not Disturb"
                or "Offline"
            statusLabel.TextColor3 = status == "offline" and Theme.Colors.textSecondary or dot.BackgroundColor3
        end

        local function update_initials(name)
            local source = tostring(name or "")
            local first = source:sub(1, 1)
            if first == "" then
                first = "?"
            end
            initials.Text = first:upper()
        end

        update_status()
        update_initials(options.Name)

        theme_bind(bin, function()
            tween(nameLabel, "avatarName", { TextColor3 = Theme.Colors.text }, Theme.Animation.normal)
            tween(initials, "avatarInitials", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            tween(imageFrame, "avatarFrame", { BackgroundColor3 = Theme.Colors.surfaceElevated }, Theme.Animation.normal)
            tween(imageStroke, "avatarStroke", { Color = Theme.Colors.border }, Theme.Animation.normal)
            tween(dot, "avatarStatus", { BackgroundColor3 = status_color(status) }, Theme.Animation.normal)
            tween(statusLabel, "avatarStatusText", {
                TextColor3 = status == "offline" and Theme.Colors.textSecondary or status_color(status),
            }, Theme.Animation.normal)
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            imageLabel = imageLabel,
        }

        function widget:setStatus(value)
            status = value or "offline"
            update_status()
            return self
        end

        function widget:setImage(image)
            imageLabel.Image = tostring(image or "")
            return self
        end

        function widget:setName(name)
            nameLabel.Text = tostring(name or "User")
            update_initials(name)
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            bin:destroy()
            root:Destroy()
        end
        return widget
    end

    --==============================================================--
    -- PROGRESS
    --==============================================================--
    function Widgets.progress(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local value = math.clamp(tonumber(options.Value) or 0, 0, 1)
        local color = typeof(options.Color) == "Color3" and options.Color or Theme.Colors.accent
        local showPercent = options.ShowPercent ~= false
        local height = 28
        local root = Util.make("Frame", {
            Name = "Progress",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local track = Util.make("Frame", {
            Name = "Track",
            Parent = root,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = showPercent and UDim2.new(1, -46, 0, 6) or UDim2.new(1, 0, 0, 6),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
        })
        Util.roundCorners(track, 3)
        local fill = Util.make("Frame", {
            Name = "Fill",
            Parent = track,
            Size = UDim2.fromScale(value, 1),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        })
        Util.roundCorners(fill, 3)
        local percent = nil
        if showPercent then
            percent = make_label(root, {
                Name = "Percent",
                Text = tostring(math.floor(value * 100 + 0.5)) .. "%",
                Font = Theme.Typography.FontMedium,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(40, 18),
                TextXAlignment = Enum.TextXAlignment.Right,
            })
        end

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            fill = fill,
        }

        function widget:setValue(newValue)
            value = math.clamp(tonumber(newValue) or 0, 0, 1)
            tween(fill, "progress", { Size = UDim2.fromScale(value, 1) }, Theme.Animation.normal)
            if percent then
                percent.Text = tostring(math.floor(value * 100 + 0.5)) .. "%"
            end
            return self
        end

        function widget:getValue()
            return value
        end

        function widget:setColor(newColor)
            if typeof(newColor) == "Color3" then
                color = newColor
                fill.BackgroundColor3 = color
            end
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            Animator.cancelAll(root)
            bin:destroy()
            root:Destroy()
        end

        theme_bind(bin, function()
            tween(track, "progressTrack", { BackgroundColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            if percent then
                tween(percent, "progressPercent", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            end
            if not options.Color then
                tween(fill, "progressFill", { BackgroundColor3 = Theme.Colors.accent }, Theme.Animation.normal)
            end
        end)
        return widget
    end

    --==============================================================--
    -- SPINNER
    --==============================================================--
    function Widgets.spinner(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local size = tonumber(options.Size) or 20
        local color = typeof(options.Color) == "Color3" and options.Color or Theme.Colors.accent
        local root = Util.make("Frame", {
            Name = "Spinner",
            Parent = parent,
            Size = UDim2.fromOffset(size, size),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local rotor = Util.make("Frame", {
            Name = "Rotor",
            Parent = root,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local dots = {}
        local dotSize = math.max(2, size * 0.12)
        local center = size / 2
        local radius = size / 2 - dotSize
        for index = 1, 8 do
            local angle = (index - 1) / 8 * math.pi * 2
            local x = center + math.cos(angle) * radius - dotSize / 2
            local y = center + math.sin(angle) * radius - dotSize / 2
            local dot = Util.make("Frame", {
                Name = "Dot" .. index,
                Parent = rotor,
                Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(dotSize, dotSize),
                BackgroundColor3 = color,
                BackgroundTransparency = 0.82 - (index - 1) * 0.075,
                BorderSizePixel = 0,
            })
            Util.roundCorners(dot, dotSize / 2)
            table.insert(dots, dot)
        end
        local angle = 0
        local connection = RunService.RenderStepped:Connect(function(delta)
            angle = (angle + delta * 300) % 360
            rotor.Rotation = angle
        end)
        local widget = {
            _instance = root,
            _height = size,
            _autoWidth = true,
            root = root,
        }

        function widget:setColor(newColor)
            if typeof(newColor) == "Color3" then
                color = newColor
                for _, dot in ipairs(dots) do
                    dot.BackgroundColor3 = color
                end
            end
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            if connection then
                connection:Disconnect()
                connection = nil
            end
            bin:destroy()
            root:Destroy()
        end

        bin:add(Theme.onChange(function()
            if not options.Color then
                for index, dot in ipairs(dots) do
                    Animator.tween(dot, "spinnerDot" .. index, {
                        BackgroundColor3 = Theme.Colors.accent,
                    }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                end
            end
        end))
        return widget
    end

    --==============================================================--
    -- STAT
    --==============================================================--
    function Widgets.stat(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local height = 82
        local root = Util.make("Frame", {
            Name = "Stat",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme.Colors.surfaceElevated,
            BorderSizePixel = 0,
        })
        local glass = Util.applyGlass(root, {
            radius = Theme.Radius.lg,
            colorKey = "surfaceElevated",
            transparency = 0.22,
            wash = true,
        })
        bin:add(glass)
        local label = make_label(root, {
            Name = "Label",
            Text = tostring(options.Label or "Stat"),
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = Theme.Typography.Size.caption,
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 15),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local valueLabel = make_label(root, {
            Name = "Value",
            Text = tostring(options.Value or "0"),
            Font = Theme.Typography.FontBold,
            TextSize = Theme.Typography.Size.title,
            Position = UDim2.fromOffset(14, 28),
            Size = UDim2.new(1, -28, 0, 29),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local deltaLabel = nil
        if options.Delta ~= nil and tostring(options.Delta) ~= "" then
            local positive = options.DeltaPositive
            if positive == nil then
                positive = not tostring(options.Delta):match("^%-")
            end
            deltaLabel = make_label(root, {
                Name = "Delta",
                Text = tostring(options.Delta),
                Font = Theme.Typography.FontMedium,
                TextColor3 = positive and Theme.Colors.success or Theme.Colors.danger,
                TextSize = Theme.Typography.Size.caption,
                Position = UDim2.fromOffset(14, 57),
                Size = UDim2.new(1, -28, 0, 14),
                ZIndex = 2,
            })
        end

        theme_bind(bin, function()
            tween(label, "statLabel", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            tween(valueLabel, "statValue", { TextColor3 = Theme.Colors.text }, Theme.Animation.normal)
            if deltaLabel then
                local positive = not tostring(deltaLabel.Text):match("^%-")
                tween(deltaLabel, "statDelta", {
                    TextColor3 = positive and Theme.Colors.success or Theme.Colors.danger,
                }, Theme.Animation.normal)
            end
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
        }

        function widget:setValue(value)
            valueLabel.Text = tostring(value or "")
            return self
        end

        function widget:setDelta(delta, positive)
            if deltaLabel then
                deltaLabel.Text = tostring(delta or "")
                deltaLabel.TextColor3 = positive and Theme.Colors.success or Theme.Colors.danger
            end
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            bin:destroy()
            glass:destroy()
            root:Destroy()
        end
        return widget
    end

    --==============================================================--
    -- TABS
    --==============================================================--
    function Widgets.tabs(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local tabs = options.Tabs or {}
        local value = math.clamp(tonumber(options.Value) or 1, 1, math.max(1, #tabs))
        local height = 40
        local root = Util.make("Frame", {
            Name = "Tabs",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme.Colors.background,
            BorderSizePixel = 0,
        })
        local glass = Util.applyGlass(root, {
            radius = 11,
            colorKey = "background",
            transparency = 0.52,
            noise = false,
            wash = false,
        })
        bin:add(glass)
        local count = math.max(1, #tabs)
        local active = Util.make("Frame", {
            Name = "Active",
            Parent = root,
            Position = UDim2.new((value - 1) / count, 3, 0, 3),
            Size = UDim2.new(1 / count, -6, 1, -6),
            BackgroundColor3 = Theme.Colors.accent,
            BackgroundTransparency = 0.80,
            BorderSizePixel = 0,
            ZIndex = 1,
        })
        Util.roundCorners(active, 8)
        local buttons = {}
        local labels = {}

        local function update(animated)
            local duration = animated and Theme.Animation.normal or 0
            tween(active, "tabsActive", {
                Position = UDim2.new((value - 1) / count, 3, 0, 3),
                Size = UDim2.new(1 / count, -6, 1, -6),
                BackgroundColor3 = Theme.Colors.accent,
            }, duration)
            for index, data in ipairs(buttons) do
                local activeState = index == value
                tween(data.label, "tabsLabel", {
                    TextColor3 = activeState and Theme.Colors.text or Theme.Colors.textSecondary,
                }, duration)
                if data.icon then
                    tween(data.icon, "tabsIcon", {
                        TextColor3 = activeState and Theme.Colors.text or Theme.Colors.textSecondary,
                    }, duration)
                end
                tween(data.button, "tabsButton", {
                    BackgroundTransparency = 1,
                }, duration)
            end
        end

        for index, tab in ipairs(tabs) do
            local button = make_button(root, {
                Name = "Tab" .. index,
                Position = UDim2.new((index - 1) / count, 0, 0, 0),
                Size = UDim2.new(1 / count, 0, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = index,
                Parent = root,
                ZIndex = 3,
            })
            local content = Util.make("Frame", {
                Parent = button,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ZIndex = 3,
            })
            Util.make("UIListLayout", {
                Parent = content,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            local iconLabel = nil
            if tab.Icon then
                iconLabel = make_label(content, {
                    Name = "Icon",
                    Text = Icons.get(tab.Icon, tab.Icon),
                    Font = Theme.Typography.FontBold,
                    TextSize = 12,
                    Size = UDim2.fromOffset(14, 18),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    LayoutOrder = 1,
                })
            end
            local label = make_label(content, {
                Name = "Label",
                Text = tostring(tab.Text or ("Tab " .. index)),
                Font = Theme.Typography.FontMedium,
                TextSize = Theme.Typography.Size.caption,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 1, 0),
                LayoutOrder = 2,
            })
            table.insert(buttons, { button = button, label = label, icon = iconLabel })
            bin:connect(button.MouseEnter, function()
                if index ~= value then
                    tween(button, "tabHover", { BackgroundTransparency = 0.94 }, Theme.Animation.fast)
                end
            end)
            bin:connect(button.MouseLeave, function()
                tween(button, "tabHover", { BackgroundTransparency = 1 }, Theme.Animation.fast)
            end)
            bin:connect(button.Activated, function()
                if options.Disabled then
                    return
                end
                local old = value
                value = index
                update(true)
                if old ~= value then
                    fire(options.OnChange, value, tabs[value])
                end
            end)
        end

        theme_bind(bin, function()
            update(true)
        end)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
            active = active,
        }

        function widget:setValue(index, silent)
            local nextValue = math.clamp(tonumber(index) or 1, 1, count)
            if nextValue == value then
                return self
            end
            value = nextValue
            update(true)
            if not silent then
                fire(options.OnChange, value, tabs[value])
            end
            return self
        end

        function widget:getValue()
            return value
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            Animator.cancelAll(root)
            bin:destroy()
            glass:destroy()
            root:Destroy()
        end

        update(false)
        return widget
    end

    --==============================================================--
    -- LIST
    --==============================================================--
    function Widgets.list(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local items = options.Items or {}
        local selectedIndex = options.Value
        local root = Util.make("Frame", {
            Name = "List",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local layout = Util.make("UIListLayout", {
            Parent = root,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        bin:add(layout)
        local itemBins = {}
        local itemWidgets = {}

        local function clear_items()
            for _, item in ipairs(itemWidgets) do
                pcall(item.destroy, item)
            end
            itemWidgets = {}
            for _, itemBin in ipairs(itemBins) do
                itemBin:destroy()
            end
            itemBins = {}
        end

        local function build_items()
            clear_items()
            for index, item in ipairs(items) do
                if type(item) ~= "table" then
                    item = { Text = tostring(item) }
                end
                local itemBin = Util.newBin()
                table.insert(itemBins, itemBin)
                local hasDescription = item.Description ~= nil and tostring(item.Description) ~= ""
                local itemHeight = hasDescription and 60 or 52
                local row = make_button(root, {
                    Name = "Item" .. index,
                    Size = UDim2.new(1, 0, 0, itemHeight),
                    BackgroundColor3 = Theme.Colors.surfaceElevated,
                    LayoutOrder = index,
                    Parent = root,
                })
                Util.markNoDrag(row)
                local rowGlass = Util.applyGlass(row, {
                    radius = Theme.Radius.md,
                    colorKey = "surfaceElevated",
                    transparency = 0.55,
                    noise = false,
                    wash = false,
                    rim = false,
                })
                itemBin:add(rowGlass)
                itemBin:add(row)
                if index == selectedIndex then
                    Animator.tween(rowGlass.stroke, "listSelected", {
                        Color = Theme.Colors.accent,
                        Transparency = 0.48,
                    }, 0, Enum.EasingStyle.Quad)
                    rowGlass:setTransparency(0.40)
                end
                local textX = 12
                if item.Icon then
                    local iconFrame = Util.make("Frame", {
                        Name = "IconFrame",
                        Parent = row,
                        Position = UDim2.new(0, 12, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.fromOffset(30, 30),
                        BackgroundColor3 = Theme.Colors.accent,
                        BackgroundTransparency = 0.84,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                    })
                    Util.roundCorners(iconFrame, 9)
                    make_label(iconFrame, {
                        Name = "Icon",
                        Text = Icons.get(item.Icon, item.Icon),
                        Font = Theme.Typography.FontBold,
                        TextColor3 = Theme.Colors.accent,
                        TextSize = 13,
                        Size = UDim2.fromScale(1, 1),
                        TextXAlignment = Enum.TextXAlignment.Center,
                    })
                    textX = 52
                end
                local rowTitle = make_label(row, {
                    Name = "Title",
                    Text = tostring(item.Text or "Item"),
                    Font = Theme.Typography.FontMedium,
                    TextSize = Theme.Typography.Size.small,
                    Position = UDim2.fromOffset(textX, hasDescription and 10 or 0),
                    Size = UDim2.new(1, -(textX + 50), 0, hasDescription and 18 or itemHeight),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 2,
                })
                local rowDescription = nil
                if hasDescription then
                    rowDescription = make_label(row, {
                        Name = "Description",
                        Text = tostring(item.Description),
                        TextColor3 = Theme.Colors.textSecondary,
                        TextSize = Theme.Typography.Size.caption,
                        Position = UDim2.fromOffset(textX, 30),
                        Size = UDim2.new(1, -(textX + 50), 0, 16),
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 2,
                    })
                end
                local right = make_label(row, {
                    Name = "Right",
                    Text = tostring(item.Right or Icons.chevronRight),
                    Font = Theme.Typography.FontBold,
                    TextColor3 = Theme.Colors.textSecondary,
                    TextSize = 14,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(28, 24),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 2,
                })
                itemBin:connect(row.MouseEnter, function()
                    rowGlass:setTransparency(0.38)
                end)
                itemBin:connect(row.MouseLeave, function()
                    rowGlass:setTransparency(index == selectedIndex and 0.40 or 0.55)
                end)
                itemBin:connect(row.Activated, function()
                    selectedIndex = index
                    for otherIndex, otherWidget in ipairs(itemWidgets) do
                        if otherWidget.setSelected then
                            otherWidget:setSelected(otherIndex == selectedIndex)
                        end
                    end
                    fire(options.OnSelect, item, index)
                end)
                itemBin:add(Theme.onChange(function()
                    tween(rowTitle, "listTitle", { TextColor3 = Theme.Colors.text }, Theme.Animation.normal)
                    if rowDescription then
                        tween(rowDescription, "listDescription", {
                            TextColor3 = Theme.Colors.textSecondary,
                        }, Theme.Animation.normal)
                    end
                    tween(right, "listRight", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
                end))
                rowTitle.TextColor3 = Theme.Colors.text
                if rowDescription then
                    rowDescription.TextColor3 = Theme.Colors.textSecondary
                end
                table.insert(itemWidgets, {
                    row = row,
                    glass = rowGlass,
                    index = index,
                    setSelected = function(self, state)
                        Animator.tween(rowGlass.stroke, "listSelected", {
                            Color = state and Theme.Colors.accent or Theme.Colors.border,
                            Transparency = state and 0.48 or Theme.Transparency.border,
                        }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                        rowGlass:setTransparency(state and 0.40 or 0.55)
                    end,
                    destroy = function(self)
                        itemBin:destroy()
                    end,
                })
            end
        end

        build_items()

        local widget = {
            _instance = root,
            _height = #items * 58,
            root = root,
        }

        function widget:setItems(newItems)
            items = newItems or {}
            build_items()
            return self
        end

        function widget:getSelected()
            return selectedIndex
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            clear_items()
            bin:destroy()
            root:Destroy()
        end
        return widget
    end

    --==============================================================--
    -- TOOLTIP
    --==============================================================--
    function Widgets.tooltip(parent, options)
        options = options or {}
        local target = options.Target
        local bin = Util.newBin()
        local bubble = nil
        local bubbleGlass = nil
        local showToken = 0
        local visible = false
        local text = tostring(options.Text or "")

        local function hide()
            showToken = showToken + 1
            if not bubble then
                return
            end
            visible = false
            Animator.tween(bubble, "tooltipHide", {
                BackgroundTransparency = 1,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            local scale = bubble:FindFirstChild("UILibScale")
            if scale then
                Animator.tween(scale, "tooltipScale", { Scale = 0.94 }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            end
            task.delay(Theme.Animation.fast, function()
                if not visible and bubble and bubble.Parent then
                    bubble.Visible = false
                end
            end)
        end

        local function show()
            if not target or not target.Parent then
                return
            end
            local layer = Util.popupLayer(target)
            if not layer then
                return
            end
            if not bubble then
                bubble = Util.make("Frame", {
                    Name = "Tooltip",
                    Parent = layer,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.fromOffset(120, 28),
                    BackgroundColor3 = Theme.Colors.background,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 12001,
                })
                Util.roundCorners(bubble, 8)
                bubbleGlass = Util.applyGlass(bubble, {
                    radius = 8,
                    colorKey = "background",
                    transparency = 0.06,
                    noise = false,
                    wash = false,
                })
                Util.make("UIScale", { Name = "UILibScale", Parent = bubble, Scale = 0.94 })
            end
            local padding = 10
            local width = math.min(280, math.ceil(Util.textWidth(text, Theme.Typography.Size.caption, Theme.Typography.Font) + padding * 2))
            bubble.Size = UDim2.fromOffset(width, 28)
            local label = bubble:FindFirstChild("TooltipText")
            if not label then
                label = make_label(bubble, {
                    Name = "TooltipText",
                    Text = text,
                    Font = Theme.Typography.Font,
                    TextSize = Theme.Typography.Size.caption,
                    TextColor3 = Theme.Colors.text,
                    Position = UDim2.fromOffset(padding, 0),
                    Size = UDim2.new(1, -padding * 2, 1, 0),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 3,
                })
            end
            label.Text = text
            local viewport = Util.viewport()
            local targetPosition = target.AbsolutePosition
            local targetSize = target.AbsoluteSize
            local x = targetPosition.X + targetSize.X / 2 - width / 2
            local y = targetPosition.Y - 34
            if y < 6 then
                y = targetPosition.Y + targetSize.Y + 6
            end
            x = math.clamp(x, 6, math.max(6, viewport.X - width - 6))
            bubble.Position = UDim2.fromOffset(x, y)
            bubble.Visible = true
            visible = true
            bubble.BackgroundTransparency = 0
            local scale = bubble:FindFirstChild("UILibScale")
            if scale then
                scale.Scale = 0.94
                Animator.tween(scale, "tooltipScale", { Scale = 1 }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            end
        end

        if target then
            bin:connect(target.MouseEnter, function()
                local token = showToken + 1
                showToken = token
                task.delay(0.22, function()
                    if token == showToken then
                        show()
                    end
                end)
            end)
            bin:connect(target.MouseLeave, hide)
            bin:connect(target.AncestryChanged, function(_, parent)
                if not parent then
                    hide()
                end
            end)
            bin:add(Theme.onChange(function()
                if bubble and bubbleGlass then
                    bubbleGlass:setAccent(Theme.Colors.accent)
                    local label = bubble:FindFirstChild("TooltipText")
                    if label then
                        Animator.tween(label, "tooltipText", {
                            TextColor3 = Theme.Colors.text,
                        }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                    end
                end
            end))
        end

        local widget = {
            _height = 0,
            _autoWidth = true,
            _instance = nil,
        }

        function widget:setText(value)
            text = tostring(value or "")
            if bubble then
                show()
            end
            return self
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            showToken = showToken + 1
            bin:destroy()
            if bubble then
                bubble:Destroy()
            end
            if bubbleGlass then
                bubbleGlass:destroy()
            end
        end
        return widget
    end

    --==============================================================--
    -- SEPARATOR
    --==============================================================--
    function Widgets.separator(parent, options)
        options = options or {}
        local bin = Util.newBin()
        local hasText = options.Text ~= nil and tostring(options.Text) ~= ""
        local height = hasText and 22 or 13
        local root = Util.make("Frame", {
            Name = "Separator",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local leftLine = Util.make("Frame", {
            Name = "Left",
            Parent = root,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0.5, 0, 0, 1),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BackgroundTransparency = 0.86,
            BorderSizePixel = 0,
        })
        local rightLine = Util.make("Frame", {
            Name = "Right",
            Parent = root,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0.5, 0, 0, 1),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BackgroundTransparency = 0.86,
            BorderSizePixel = 0,
        })
        local label = nil
        local function layout()
            if not hasText then
                leftLine.Position = UDim2.new(0, 0, 0.5, 0)
                leftLine.Size = UDim2.new(1, 0, 0, 1)
                rightLine.Visible = false
                return
            end
            if not label then
                return
            end
            local totalWidth = root.AbsoluteSize.X
            local textWidth = Util.textWidth(label.Text, Theme.Typography.Size.caption, Theme.Typography.FontMedium)
            local gap = 10
            local halfText = textWidth / 2 + gap
            local center = totalWidth / 2
            leftLine.Position = UDim2.fromOffset(0, 0)
            leftLine.Size = UDim2.new(0, math.max(0, center - halfText), 0, 1)
            leftLine.Position = UDim2.new(0, 0, 0.5, 0)
            rightLine.Position = UDim2.new(0, math.min(totalWidth, center + halfText), 0.5, 0)
            rightLine.Size = UDim2.new(0, math.max(0, center - halfText), 0, 1)
            rightLine.Visible = true
        end
        if hasText then
            label = make_label(root, {
                Name = "Text",
                Text = tostring(options.Text),
                Font = Theme.Typography.FontMedium,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(0, math.ceil(Util.textWidth(tostring(options.Text), Theme.Typography.Size.caption, Theme.Typography.FontMedium) + 4), 0, 16),
                TextXAlignment = Enum.TextXAlignment.Center,
            })
        end
        bin:connect(root:GetPropertyChangedSignal("AbsoluteSize"), layout)
        theme_bind(bin, function()
            tween(leftLine, "separatorLine", { BackgroundColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            tween(rightLine, "separatorLine", { BackgroundColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            if label then
                tween(label, "separatorText", { TextColor3 = Theme.Colors.textSecondary }, Theme.Animation.normal)
            end
        end)
        task.defer(layout)

        local widget = {
            _instance = root,
            _height = height,
            root = root,
        }

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            bin:destroy()
            root:Destroy()
        end
        return widget
    end

    --==============================================================--
    -- GRID
    --==============================================================--
    function Widgets.grid(parent, options)
        options = options or {}
        local columns = math.max(1, math.floor(tonumber(options.Columns) or 2))
        local gap = tonumber(options.Gap) or 10
        local cellHeight = tonumber(options.CellHeight) or 88
        local root = Util.make("Frame", {
            Name = "Grid",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local gridLayout = Util.make("UIGridLayout", {
            Parent = root,
            CellSize = UDim2.new(1 / columns, -(gap * (columns - 1)) / columns, 0, cellHeight),
            CellPadding = UDim2.fromOffset(gap, gap),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirectionMaxCells = columns,
        })
        local cells = {}
        local widget = {
            _instance = root,
            _height = cellHeight,
            _autoWidth = false,
            root = root,
            _cells = cells,
            _bin = Util.newBin(),
        }

        function widget:cell(callback)
            local cell = Util.make("Frame", {
                Name = "Cell" .. (#cells + 1),
                Parent = root,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = #cells + 1,
            })
            local scope = {
                _parent = cell,
                _instance = cell,
                _height = cellHeight,
            }
            Widgets._decorate(scope)
            table.insert(cells, scope)
            if type(callback) == "function" then
                local ok, err = xpcall(callback, debug.traceback, scope)
                if not ok then
                    add_error_text(scope, err)
                end
            end
            return scope
        end

        function widget:addCell(callback)
            return self:cell(callback)
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            for _, cell in ipairs(cells) do
                pcall(cell.destroy, cell)
            end
            cells = {}
            self._bin:destroy()
            root:Destroy()
        end

        local children = options.Children
        if type(children) == "function" then
            local ok, err = xpcall(children, debug.traceback, widget)
            if not ok then
                local errorCell = widget:cell(nil)
                add_error_text(errorCell, err)
            end
        elseif type(children) == "table" then
            for _, child in ipairs(children) do
                if type(child) == "function" then
                    widget:cell(child)
                elseif type(child) == "table" then
                    widget:cell(function(scope)
                        local kind = child.Type or child.Widget or "card"
                        local spec = {}
                        for key, value in pairs(child) do
                            if key ~= "Type" and key ~= "Widget" then
                                spec[key] = value
                            end
                        end
                        if type(Widgets[kind]) == "function" then
                            local created = Widgets[kind](scope._parent, spec)
                            scope:_track(created)
                        end
                    end)
                end
            end
        end
        widget._bin:add(gridLayout)
        return widget
    end

    --==============================================================--
    -- ACCORDION
    --==============================================================--
    function Widgets.accordion(parent, options)
        options = options or {}
        local items = options.Items or {}
        local sections = {}
        local root = Util.make("Frame", {
            Name = "Accordion",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local layout = Util.make("UIListLayout", {
            Parent = root,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        local bin = Util.newBin()
        bin:add(layout)

        local function make_section(item, index)
            local section
            section = Widgets.section(root, {
                Title = item.Title or ("Section " .. index),
                Icon = item.Icon,
                Expanded = item.Expanded == true,
                Collapsible = true,
                Content = item.Content,
                OnToggle = function(state)
                    if options.Exclusive and state then
                        for _, other in ipairs(sections) do
                            if other ~= section and other.isExpanded and other:isExpanded() then
                                other:collapse()
                            end
                        end
                    end
                end,
            })
            section._instance.LayoutOrder = index
            table.insert(sections, section)
            return section
        end

        for index, item in ipairs(items) do
            if type(item) ~= "table" then
                item = { Title = tostring(item) }
            end
            make_section(item, index)
        end

        local widget = {
            _instance = root,
            _height = #items * 46,
            root = root,
        }

        function widget:add(item)
            table.insert(items, item)
            local section = make_section(item, #items)
            return section
        end

        function widget:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            for _, section in ipairs(sections) do
                pcall(section.destroy, section)
            end
            sections = {}
            bin:destroy()
            root:Destroy()
        end
        return widget
    end

    --==============================================================--
    -- ROW
    --==============================================================--
    function Widgets.row(parent, options)
        options = options or {}
        local gap = tonumber(options.Gap) or 10
        local root = Util.make("Frame", {
            Name = "Row",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        local layout = Util.make("UIListLayout", {
            Parent = root,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, gap),
            VerticalAlignment = Enum.VerticalAlignment.Top,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        })
        local scope = {
            _parent = root,
            _instance = root,
            _height = 40,
            _isRow = true,
        }
        Widgets._decorate(scope)
        scope._bin:add(layout)
        local callback = options.Callback or options.Content
        if type(callback) == "function" then
            local ok, err = xpcall(callback, debug.traceback, scope)
            if not ok then
                add_error_text(scope, err)
            end
        end
        Widgets._row_finish(scope, gap)
        return scope
    end

    return Widgets
end

--====================================================================--
-- PAGE
--====================================================================--
_mods["Page"] = function()
    local Theme = _get("Theme")
    local Util = _get("Util")
    local Animator = _get("Animator")
    local Widgets = _get("Widgets")

    local Page = {}

    local function styled_label(parent, text, size, color, font, height)
        return Util.make("TextLabel", {
            Parent = parent,
            Text = tostring(text or ""),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = font or Theme.Typography.Font,
            TextSize = size or Theme.Typography.Size.small,
            TextColor3 = color or Theme.Colors.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            RichText = false,
            Size = UDim2.new(1, 0, 0, height or 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LineHeight = 1.12,
        })
    end

    function Page.wrap(parent)
        assert(parent ~= nil, "[ui_lib] Page.wrap(parent) requires a parent")

        local scroll = Util.make("ScrollingFrame", {
            Name = "Page",
            Parent = parent,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Colors.textSecondary,
            ScrollBarImageTransparency = 0.62,
            ClipsDescendants = true,
            Active = true,
            ZIndex = 1,
        })
        pcall(function()
            scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
        end)

        local padding = Util.make("UIPadding", {
            Parent = scroll,
            PaddingTop = UDim.new(0, 22),
            PaddingBottom = UDim.new(0, 26),
            PaddingLeft = UDim.new(0, 24),
            PaddingRight = UDim.new(0, 24),
        })
        local layout = Util.make("UIListLayout", {
            Parent = scroll,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        })

        local page = {
            _parent = scroll,
            _instance = scroll,
            _scroll = scroll,
            _layout = layout,
            _padding = padding,
            _textRegistry = {},
            _dividerRegistry = {},
            _seq = 0,
        }
        Widgets._decorate(page)
        page._bin:add(padding)
        page._bin:add(layout)
        page._bin:add(Theme.onChange(function()
            scroll.ScrollBarImageColor3 = Theme.Colors.textSecondary
            scroll.ScrollBarImageTransparency = 0.62
            for _, entry in ipairs(page._textRegistry) do
                local target = entry.label
                if target and target.Parent then
                    Animator.tween(target, "pageText_" .. entry.role, {
                        TextColor3 = entry.color or Theme.Colors[entry.colorKey or "text"],
                        TextTransparency = entry.colorKey == "textSecondary"
                            and Theme.Transparency.textSecondary or 0,
                    }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                end
            end
            for _, line in ipairs(page._dividerRegistry) do
                if line.Parent then
                    Animator.tween(line, "pageDivider", {
                        BackgroundColor3 = Theme.Colors.textSecondary,
                    }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                end
            end
        end))

        local function next_order()
            page._seq = page._seq + 1
            return page._seq
        end

        -- Widgets normally order themselves by child count, while the page
        -- also owns labels/dividers using its own sequence. Keep both on one
        -- sequence so a heading created after a section cannot get the same
        -- LayoutOrder as that section.
        local base_track = page._track
        function page:_track(widget)
            local tracked = base_track(self, widget)
            self._seq = self._seq + 1
            if widget and widget._instance then
                widget._instance.LayoutOrder = self._seq
            end
            return tracked
        end

        local function register_label(label, colorKey, role)
            table.insert(page._textRegistry, {
                label = label,
                colorKey = colorKey,
                role = role or tostring(next_order()),
            })
            return label
        end

        function page:heading(text)
            local label = styled_label(
                self._parent,
                text,
                Theme.Typography.Size.display,
                Theme.Colors.text,
                Theme.Typography.FontBold
            )
            label.Name = "Heading"
            label.LayoutOrder = next_order()
            self:_trackInstance(label)
            register_label(label, "text", "heading")
            return label
        end

        function page:paragraph(text)
            local label = styled_label(
                self._parent,
                text,
                Theme.Typography.Size.small,
                Theme.Colors.textSecondary,
                Theme.Typography.Font
            )
            label.Name = "Paragraph"
            label.TextColor3 = Theme.Colors.textSecondary
            label.TextTransparency = Theme.Transparency.textSecondary
            label.LayoutOrder = next_order()
            self:_trackInstance(label)
            register_label(label, "textSecondary", "paragraph")
            return label
        end

        function page:divider()
            local holder = Util.make("Frame", {
                Name = "Divider",
                Parent = self._parent,
                Size = UDim2.new(1, 0, 0, 13),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = next_order(),
            })
            local line = Util.make("Frame", {
                Name = "Line",
                Parent = holder,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Colors.textSecondary,
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
            })
            self:_trackInstance(holder)
            table.insert(self._dividerRegistry, line)
            return holder
        end

        function page:spacer(amount)
            local height = tonumber(amount) or 8
            local holder = Util.make("Frame", {
                Name = "Spacer",
                Parent = self._parent,
                Size = UDim2.new(1, 0, 0, math.max(0, height)),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = next_order(),
            })
            self:_trackInstance(holder)
            return holder
        end

        function page:clear()
            self:_disposeChildren()
            self._textRegistry = {}
            self._dividerRegistry = {}
            self._seq = 0
            pcall(function()
                self._scroll.CanvasPosition = Vector2.new(0, 0)
            end)
            return self
        end

        function page:scrollToTop(animated)
            if animated then
                Animator.tween(self._scroll, "pageCanvas", {
                    CanvasPosition = Vector2.new(0, 0),
                }, Theme.Animation.slow, Enum.EasingStyle.Cubic)
            else
                self._scroll.CanvasPosition = Vector2.new(0, 0)
            end
            return self
        end

        function page:getScrollFrame()
            return self._scroll
        end

        return page
    end

    return Page
end

--====================================================================--
-- NOTIFICATIONS
--====================================================================--
_mods["Notifications"] = function()
    local Theme = _get("Theme")
    local Util = _get("Util")
    local Animator = _get("Animator")
    local Icons = _get("Icons")

    local Notifications = {}
    local state = {
        window = nil,
        holder = nil,
        fallbackHolder = nil,
        items = {},
        seq = 0,
        max = 5,
    }

    local function type_color(kind)
        if kind == "success" then
            return Theme.Colors.success
        elseif kind == "warning" then
            return Theme.Colors.warning
        elseif kind == "danger" then
            return Theme.Colors.danger
        end
        return Theme.Colors.accent
    end

    local function type_icon(kind)
        if kind == "success" then
            return Icons.checkCircle
        elseif kind == "warning" then
            return Icons.warning
        elseif kind == "danger" then
            return Icons.xCircle
        end
        return Icons.info
    end

    local function new_holder(parent)
        local holder = Util.make("Frame", {
            Name = "UILibNotifications",
            Parent = parent,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16),
            Size = UDim2.fromOffset(330, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 80,
        })
        Util.make("UIListLayout", {
            Parent = holder,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        })
        return holder
    end

    local function get_holder()
        if state.holder and state.holder.Parent then
            return state.holder
        end
        if state.window and state.window._wrapper and state.window._wrapper.Parent then
            state.holder = new_holder(state.window._wrapper)
            return state.holder
        end
        if state.fallbackHolder and state.fallbackHolder.Parent then
            return state.fallbackHolder
        end
        local gui = Util.ensureScreenGui()
        state.fallbackHolder = new_holder(gui)
        return state.fallbackHolder
    end

    local function remove_item(item, instant)
        if not item or item.removed then
            return
        end
        item.removed = true
        if item.timer then
            pcall(task.cancel, item.timer)
            item.timer = nil
        end
        Animator.cancelAll(item.card)
        if instant then
            item.bin:destroy()
            item.glass:destroy()
            item.card:Destroy()
        else
            local scale = item.scale
            if scale then
                Animator.tween(scale, "notificationOut", {
                    Scale = 0.90,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            end
            task.delay(Theme.Animation.fast, function()
                if item.card then
                    item.bin:destroy()
                    item.glass:destroy()
                    item.card:Destroy()
                end
            end)
        end
        for index = #state.items, 1, -1 do
            if state.items[index] == item then
                table.remove(state.items, index)
                break
            end
        end
    end

    function Notifications._attach(window, parent)
        if state.window ~= window then
            Notifications.clear()
            if state.holder then
                state.holder:Destroy()
            end
            state.window = window
            state.holder = parent:FindFirstChild("UILibNotifications")
            if not state.holder then
                state.holder = new_holder(parent)
            end
        end
        return state.holder
    end

    function Notifications._detach(window)
        if state.window ~= window then
            return
        end
        Notifications.clear(true)
        if state.holder then
            state.holder:Destroy()
        end
        state.holder = nil
        state.window = nil
    end

    function Notifications._setVisible(visible)
        local holder = state.holder
        if holder then
            holder.Visible = visible and true or false
        end
        if state.fallbackHolder then
            state.fallbackHolder.Visible = visible and true or false
        end
    end

    function Notifications.clear(instant)
        local snapshot = {}
        for index, item in ipairs(state.items) do
            snapshot[index] = item
        end
        for _, item in ipairs(snapshot) do
            remove_item(item, instant == true)
        end
        state.items = {}
    end

    function Notifications.push(options)
        options = options or {}
        local holder = get_holder()
        if not holder then
            return nil
        end
        while #state.items >= state.max do
            remove_item(state.items[1], true)
        end

        local kind = options.Type or "info"
        local color = type_color(kind)
        local hasText = options.Text ~= nil and tostring(options.Text) ~= ""
        local height = hasText and 72 or 54
        local duration = tonumber(options.Duration)
        if duration == nil then
            duration = 3500
        end
        state.seq = state.seq + 1

        local bin = Util.newBin()
        local card = Util.make("Frame", {
            Name = "Notification",
            Parent = holder,
            Size = UDim2.fromOffset(330, height),
            BackgroundColor3 = Theme.Colors.surfaceElevated,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = state.seq,
            ZIndex = 81,
        })
        local glass = Util.applyGlass(card, {
            radius = 14,
            colorKey = "surfaceElevated",
            transparency = 0.04,
            wash = true,
        })
        bin:add(glass)
        local scale = Util.make("UIScale", {
            Name = "UILibScale",
            Parent = card,
            Scale = 0.94,
        })

        local iconFrame = Util.make("Frame", {
            Name = "Icon",
            Parent = card,
            Position = UDim2.fromOffset(12, 13),
            Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        Util.roundCorners(iconFrame, 10)
        local iconGlyph = options.Icon and Icons.get(options.Icon, options.Icon) or type_icon(kind)
        local iconLabel = Util.make("TextLabel", {
            Name = "Glyph",
            Parent = iconFrame,
            Text = iconGlyph,
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = color,
            TextSize = 14,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 3,
        })
        local title = Util.make("TextLabel", {
            Name = "Title",
            Parent = card,
            Text = tostring(options.Title or "Notification"),
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.text,
            TextSize = Theme.Typography.Size.small,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(52, hasText and 12 or 0),
            Size = UDim2.new(1, -84, 0, hasText and 19 or height),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
        })
        local textLabel = nil
        if hasText then
            textLabel = Util.make("TextLabel", {
                Name = "Text",
                Parent = card,
                Text = tostring(options.Text),
                BackgroundTransparency = 1,
                Font = Theme.Typography.Font,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Position = UDim2.fromOffset(52, 32),
                Size = UDim2.new(1, -70, 0, 30),
                ZIndex = 2,
            })
        end
        local closeButton = Util.make("TextButton", {
            Name = "Close",
            Parent = card,
            Text = "",
            BackgroundTransparency = 1,
            BackgroundColor3 = Theme.Colors.control,
            AutoButtonColor = false,
            Position = UDim2.new(1, -30, 0, 8),
            Size = UDim2.fromOffset(22, 22),
            ZIndex = 3,
        })
        Util.roundCorners(closeButton, 7)
        Util.make("TextLabel", {
            Name = "X",
            Parent = closeButton,
            Text = Icons.close,
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = 13,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        local progress = Util.make("Frame", {
            Name = "Progress",
            Parent = card,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.fromScale(1, 0.004),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        progress.Size = UDim2.new(1, 0, 0, 2)

        local item = {
            card = card,
            bin = bin,
            glass = glass,
            scale = scale,
            timer = nil,
            removed = false,
        }
        table.insert(state.items, item)

        function item:dismiss()
            remove_item(self, false)
        end

        function item:destroy()
            remove_item(self, true)
        end

        bin:connect(closeButton.MouseEnter, function()
            Animator.tween(closeButton, "notifCloseHover", {
                BackgroundTransparency = 0.88,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
        end)
        bin:connect(closeButton.MouseLeave, function()
            Animator.tween(closeButton, "notifCloseHover", {
                BackgroundTransparency = 1,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
        end)
        bin:connect(closeButton.Activated, function()
            item:dismiss()
        end)
        bin:add(Theme.onChange(function()
            local currentColor = type_color(kind)
            Animator.tween(title, "notificationTitle", {
                TextColor3 = Theme.Colors.text,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            if textLabel then
                Animator.tween(textLabel, "notificationText", {
                    TextColor3 = Theme.Colors.textSecondary,
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            end
            Animator.tween(iconFrame, "notificationIconBg", {
                BackgroundColor3 = currentColor,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(iconLabel, "notificationIcon", {
                TextColor3 = currentColor,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(progress, "notificationProgressColor", {
                BackgroundColor3 = currentColor,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
        end))

        task.defer(function()
            if item.removed then
                return
            end
            Animator.tween(scale, "notificationIn", {
                Scale = 1,
            }, Theme.Animation.normal, Enum.EasingStyle.Back)
        end)

        if duration > 0 then
            item.timer = task.delay(duration / 1000, function()
                item:dismiss()
            end)
            Animator.tween(progress, "notificationProgress", {
                Size = UDim2.new(0, 0, 0, 2),
            }, duration / 1000, Enum.EasingStyle.Linear)
        end
        return item
    end

    return Notifications
end

--====================================================================--
-- MODAL
--====================================================================--
_mods["Modal"] = function()
    local UserInputService = game:GetService("UserInputService")
    local Theme = _get("Theme")
    local Util = _get("Util")
    local Animator = _get("Animator")
    local Page = _get("Page")
    local Widgets = _get("Widgets")
    local Icons = _get("Icons")

    local Modal = {}
    local defaultGui = nil
    local activeModals = {}

    function Modal._setDefaultGui(gui)
        if gui and gui:IsA("ScreenGui") then
            defaultGui = gui
        end
    end

    local function resolve_gui(options)
        if options.Parent and typeof(options.Parent) == "Instance" and options.Parent:IsA("ScreenGui") then
            return options.Parent
        end
        if options.Window and options.Window._gui and options.Window._gui.Parent then
            return options.Window._gui
        end
        if defaultGui and defaultGui.Parent then
            return defaultGui
        end
        return Util.ensureScreenGui()
    end

    function Modal.new(options)
        options = options or {}
        local gui = resolve_gui(options)
        local viewport = Util.viewport()
        local width = math.clamp(tonumber(options.Width) or 540, 300, math.max(300, viewport.X - 32))
        local height = math.clamp(tonumber(options.Height) or 420, 240, math.max(240, viewport.Y - 40))
        local actions = options.Actions or {}
        local actionHeight = #actions > 0 and 68 or 0
        local closed = false
        local destroying = false
        local closeToken = 0

        local layer = Util.make("Frame", {
            Name = "UILibModalLayer",
            Parent = gui,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 20000,
        })
        local backdrop = Util.make("TextButton", {
            Name = "Backdrop",
            Parent = layer,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Colors.overlay,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Active = true,
            ZIndex = 1,
        })
        local noise = Util.make("ImageLabel", {
            Name = "BackdropNoise",
            Parent = backdrop,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = "rbxassetid://9968344106",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 0.94,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.fromOffset(64, 64),
            SliceCenter = Rect.new(8, 8, 56, 56),
            Active = false,
            ZIndex = 2,
        })
        local wash = Util.make("Frame", {
            Name = "BackdropWash",
            Parent = backdrop,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Colors.accent,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 2,
        })
        Util.make("UIGradient", {
            Parent = wash,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.975),
                NumberSequenceKeypoint.new(1, 1),
            }),
        })

        local shadowLayers = {}
        for index = 1, 3 do
            local spread = index * 7
            local shadowLayer = Util.make("Frame", {
                Name = "ModalShadow" .. index,
                Parent = layer,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(width + spread * 2, height + spread * 2 + 10),
                BackgroundColor3 = Theme.Colors.shadow,
                BackgroundTransparency = 0.88 + index * 0.025,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 2,
            })
            Util.roundCorners(shadowLayer, Theme.Radius.xl + 6)
            table.insert(shadowLayers, shadowLayer)
        end

        local card = Util.make("Frame", {
            Name = "Modal",
            Parent = layer,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(width, height),
            BackgroundColor3 = Theme.Colors.surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = true,
            ZIndex = 5,
        })
        local glass = Util.applyGlass(card, {
            radius = Theme.Radius.xl,
            colorKey = "surface",
            transparency = 0.04,
            wash = true,
        })
        local scale = Util.make("UIScale", { Name = "UILibScale", Parent = card, Scale = 0.94 })

        local title = Util.make("TextLabel", {
            Name = "Title",
            Parent = card,
            Text = tostring(options.Title or "Dialog"),
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.text,
            TextSize = Theme.Typography.Size.title,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(24, 17),
            Size = UDim2.new(1, -88, 0, 28),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 3,
        })
        local closeButton = Util.make("TextButton", {
            Name = "Close",
            Parent = card,
            Text = "",
            BackgroundColor3 = Theme.Colors.control,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Position = UDim2.new(1, -50, 0, 18),
            Size = UDim2.fromOffset(28, 28),
            ZIndex = 4,
        })
        Util.roundCorners(closeButton, 9)
        local closeGlyph = Util.make("TextLabel", {
            Name = "X",
            Parent = closeButton,
            Text = Icons.close,
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = 15,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        local headerLine = Util.make("Frame", {
            Name = "HeaderLine",
            Parent = card,
            Position = UDim2.fromOffset(20, 60),
            Size = UDim2.new(1, -40, 0, 1),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        local contentFrame = Util.make("Frame", {
            Name = "Content",
            Parent = card,
            Position = UDim2.fromOffset(0, 62),
            Size = UDim2.new(1, 0, 1, -(62 + actionHeight)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        local page = Page.wrap(contentFrame)
        local pageScroll = page:getScrollFrame()
        pageScroll.ZIndex = 3

        local actionFrame = nil
        local actionRow = nil
        local actionLayout = nil
        local actionTopLine = nil
        local actionWidgets = {}
        if actionHeight > 0 then
            actionFrame = Util.make("Frame", {
                Name = "Actions",
                Parent = card,
                Position = UDim2.new(0, 0, 1, -actionHeight),
                Size = UDim2.new(1, 0, 0, actionHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 4,
            })
            actionTopLine = Util.make("Frame", {
                Name = "TopLine",
                Parent = actionFrame,
                Position = UDim2.fromOffset(20, 0),
                Size = UDim2.new(1, -40, 0, 1),
                BackgroundColor3 = Theme.Colors.textSecondary,
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
            })
            actionRow = Util.make("Frame", {
                Name = "ActionRow",
                Parent = actionFrame,
                Position = UDim2.fromOffset(20, 16),
                Size = UDim2.new(1, -40, 0, 38),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            actionLayout = Util.make("UIListLayout", {
                Parent = actionRow,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
        end

        local modal = {
            _gui = gui,
            _layer = layer,
            _card = card,
            _page = page,
            Page = page,
            _closed = false,
        }

        local modalBin = Util.newBin()
        modalBin:add(Theme.onChange(function()
            local duration = Theme.Animation.normal
            Animator.tween(title, "modalTitle", {
                TextColor3 = Theme.Colors.text,
            }, duration, Enum.EasingStyle.Quad)
            Animator.tween(closeGlyph, "modalCloseGlyph", {
                TextColor3 = Theme.Colors.textSecondary,
            }, duration, Enum.EasingStyle.Quad)
            Animator.tween(headerLine, "modalLine", {
                BackgroundColor3 = Theme.Colors.textSecondary,
            }, duration, Enum.EasingStyle.Quad)
            if actionTopLine then
                Animator.tween(actionTopLine, "modalLine", {
                    BackgroundColor3 = Theme.Colors.textSecondary,
                }, duration, Enum.EasingStyle.Quad)
            end
            Animator.tween(backdrop, "modalBackdropColor", {
                BackgroundColor3 = Theme.Colors.overlay,
            }, duration, Enum.EasingStyle.Quad)
            Animator.tween(wash, "modalWash", {
                BackgroundColor3 = Theme.Colors.accent,
            }, duration, Enum.EasingStyle.Quad)
            for index, shadowLayer in ipairs(shadowLayers) do
                Animator.tween(shadowLayer, "modalShadow" .. index, {
                    BackgroundColor3 = Theme.Colors.shadow,
                }, duration, Enum.EasingStyle.Quad)
            end
        end))

        local function destroy_now()
            if destroying then
                return
            end
            destroying = true
            modalBin:destroy()
            for _, widget in ipairs(actionWidgets) do
                pcall(widget.destroy, widget)
            end
            actionWidgets = {}
            page:destroy()
            glass:destroy()
            Animator.cancelAll(card)
            layer:Destroy()
            for index = #activeModals, 1, -1 do
                if activeModals[index] == modal then
                    table.remove(activeModals, index)
                end
            end
        end

        local function close()
            if closed or destroying then
                return
            end
            closed = true
            modal._closed = true
            closeToken = closeToken + 1
            local token = closeToken
            Animator.tween(scale, "modalScale", {
                Scale = 0.94,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            Animator.tween(backdrop, "modalBackdrop", {
                BackgroundTransparency = 1,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            task.delay(Theme.Animation.fast + 0.03, function()
                if token == closeToken then
                    destroy_now()
                    if type(options.OnClose) == "function" then
                        Util.safeCall(options.OnClose)
                    end
                end
            end)
        end

        function modal:close()
            close()
            return self
        end

        function modal:destroy()
            if destroying then
                return
            end
            closeToken = closeToken + 1
            destroy_now()
            return self
        end

        function modal:setTitle(value)
            title.Text = tostring(value or "")
            return self
        end

        function modal:getPage()
            return page
        end

        function modal:isOpen()
            return not closed and not destroying
        end

        for index, action in ipairs(actions) do
            local button = Widgets.button(actionRow, {
                Text = action.Text or ("Action " .. index),
                Variant = action.Variant or (index == #actions and "primary" or "secondary"),
                Icon = action.Icon,
                OnClick = function()
                    local keepOpen = action.Close == false
                    Util.safeCall(action.OnClick, modal)
                    if not keepOpen then
                        close()
                    end
                end,
            })
            button._instance.Size = UDim2.fromOffset(112, 36)
            button._instance.LayoutOrder = index
            button._height = 36
            table.insert(actionWidgets, button)
        end

        modalBin:connect(closeButton.MouseEnter, function()
            Animator.tween(closeButton, "modalCloseHover", {
                BackgroundTransparency = 0.88,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
        end)
        modalBin:connect(closeButton.MouseLeave, function()
            Animator.tween(closeButton, "modalCloseHover", {
                BackgroundTransparency = 1,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
        end)
        modalBin:connect(closeButton.Activated, function()
            close()
        end)
        modalBin:connect(backdrop.Activated, function()
            if options.CloseOnBackdrop ~= false then
                close()
            end
        end)
        modalBin:connect(UserInputService.InputBegan, function(input, gameProcessed)
            if gameProcessed then
                return
            end
            if input.KeyCode == Enum.KeyCode.Escape then
                close()
            end
        end)

        table.insert(activeModals, modal)

        local contentCallback = options.Content
        if type(contentCallback) == "function" then
            local ok, err = xpcall(contentCallback, debug.traceback, page)
            if not ok then
                page:paragraph("Unable to render content: " .. tostring(err))
            end
        elseif type(contentCallback) == "string" then
            page:paragraph(contentCallback)
        end

        task.defer(function()
            if closed or destroying then
                return
            end
            Animator.tween(backdrop, "modalBackdrop", {
                BackgroundTransparency = Theme.Transparency.backdrop,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(scale, "modalScale", {
                Scale = 1,
            }, Theme.Animation.normal, Enum.EasingStyle.Back)
        end)

        modalBin:connect(layer.AncestryChanged, function(_, parent)
            if not parent and not destroying then
                destroy_now()
            end
        end)

        return modal
    end

    function Modal.destroyFor(gui)
        local snapshot = {}
        for _, modal in ipairs(activeModals) do
            if gui == nil or modal._gui == gui then
                table.insert(snapshot, modal)
            end
        end
        for _, modal in ipairs(snapshot) do
            pcall(modal.destroy, modal)
        end
    end

    function Modal.closeAll()
        Modal.destroyFor(nil)
    end

    return Modal
end

--====================================================================--
-- CONTEXT MENU
--====================================================================--
_mods["ContextMenu"] = function()
    local UserInputService = game:GetService("UserInputService")
    local Theme = _get("Theme")
    local Util = _get("Util")
    local Animator = _get("Animator")
    local Icons = _get("Icons")

    local ContextMenu = {}
    local activeMenu = nil

    local function close_active()
        if activeMenu then
            local menu = activeMenu
            activeMenu = nil
            pcall(menu._close, menu)
        end
    end

    function ContextMenu.attach(target, options)
        options = options or {}
        if not target or typeof(target) ~= "Instance" then
            return nil
        end
        local items = options.Items or {}
        local menuObject = {
            Target = target,
            _items = items,
            _layer = nil,
            _menu = nil,
            _shadow = nil,
            _overlay = nil,
            _bin = Util.newBin(),
            _open = false,
            _destroyed = false,
            _position = nil,
            _escape = nil,
            _closeToken = 0,
            _menuBin = nil,
        }

        local function destroy_menu()
            menuObject._closeToken = menuObject._closeToken + 1
            menuObject._open = false
            if menuObject._menuBin then
                menuObject._menuBin:destroy()
                menuObject._menuBin = nil
            end
            if menuObject._escape then
                pcall(function()
                    menuObject._escape:Disconnect()
                end)
                menuObject._escape = nil
            end
            if menuObject._menu then
                Animator.cancelAll(menuObject._menu)
                menuObject._menu:Destroy()
                menuObject._menu = nil
            end
            if menuObject._shadow then
                menuObject._shadow:Destroy()
                menuObject._shadow = nil
            end
            if menuObject._overlay then
                menuObject._overlay:Destroy()
                menuObject._overlay = nil
            end
            menuObject._layer = nil
        end

        local function close(animated)
            if not menuObject._open then
                return
            end
            menuObject._open = false
            if activeMenu == menuObject then
                activeMenu = nil
            end
            local token = menuObject._closeToken + 1
            menuObject._closeToken = token
            if menuObject._escape then
                pcall(function()
                    menuObject._escape:Disconnect()
                end)
                menuObject._escape = nil
            end
            if animated and menuObject._menu then
                local scale = menuObject._menu:FindFirstChild("UILibScale")
                if scale then
                    Animator.tween(scale, "contextScale", {
                        Scale = 0.94,
                    }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                end
                Animator.tween(menuObject._menu, "contextFade", {
                    BackgroundTransparency = 1,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                task.delay(Theme.Animation.fast, function()
                    if token == menuObject._closeToken then
                        destroy_menu()
                    end
                end)
            else
                destroy_menu()
            end
        end

        menuObject._close = close

        local function build(position)
            local layer = Util.popupLayer(target)
            if not layer then
                return
            end
            if menuObject._open then
                close(false)
            end
            close_active()
            activeMenu = menuObject
            menuObject._layer = layer
            menuObject._position = position
            local menuBin = Util.newBin()
            menuObject._menuBin = menuBin
            local viewport = Util.viewport()
            local menuWidth = options.Width or 198
            local rowHeight = 33
            local totalHeight = 10
            for _, item in ipairs(items) do
                if item.Separator then
                    totalHeight = totalHeight + 9
                elseif item.Visible ~= false then
                    totalHeight = totalHeight + rowHeight
                end
            end
            local menuHeight = math.min(totalHeight, viewport.Y - 20)
            local x = math.clamp(position.X, 8, math.max(8, viewport.X - menuWidth - 8))
            local y = math.clamp(position.Y, 8, math.max(8, viewport.Y - menuHeight - 8))

            menuObject._overlay = Util.make("TextButton", {
                Name = "ContextOutside",
                Parent = layer,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Active = true,
                ZIndex = 3001,
            })
            menuObject._shadow = Util.make("Frame", {
                Name = "ContextShadow",
                Parent = layer,
                Position = UDim2.fromOffset(x + 3, y + 8),
                Size = UDim2.fromOffset(menuWidth + 8, menuHeight + 4),
                BackgroundColor3 = Theme.Colors.shadow,
                BackgroundTransparency = 0.78,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 3002,
            })
            Util.roundCorners(menuObject._shadow, 14)
            local menu = Util.make("Frame", {
                Name = "ContextMenu",
                Parent = layer,
                Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(menuWidth, menuHeight),
                BackgroundColor3 = Theme.Colors.surfaceElevated,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Active = true,
                ZIndex = 3003,
            })
            Util.roundCorners(menu, 12)
            menuObject._menu = menu
            local scale = Util.make("UIScale", { Name = "UILibScale", Parent = menu, Scale = 0.94 })
            local glass = Util.applyGlass(menu, {
                radius = 12,
                colorKey = "surfaceElevated",
                transparency = 0.03,
                wash = true,
            })
            menuBin:add(glass)

            local scroll = Util.make("ScrollingFrame", {
                Name = "Items",
                Parent = menu,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Colors.textSecondary,
                ScrollBarImageTransparency = 0.55,
                ClipsDescendants = true,
                ZIndex = 3004,
            })
            Util.make("UIPadding", {
                Parent = scroll,
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
            })
            local layout = Util.make("UIListLayout", {
                Parent = scroll,
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
            })
            local order = 0
            local itemLabels = {}
            for index, item in ipairs(items) do
                if item.Separator then
                    order = order + 1
                    local separatorHolder = Util.make("Frame", {
                        Name = "Separator" .. index,
                        Parent = scroll,
                        Size = UDim2.new(1, 0, 0, 9),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = order,
                    })
                    Util.make("Frame", {
                        Name = "Line",
                        Parent = separatorHolder,
                        Position = UDim2.new(0, 10, 0.5, 0),
                        Size = UDim2.new(1, -20, 0, 1),
                        BackgroundColor3 = Theme.Colors.textSecondary,
                        BackgroundTransparency = 0.88,
                        BorderSizePixel = 0,
                    })
                elseif item.Visible ~= false then
                    order = order + 1
                    local danger = item.Danger == true
                    local itemColor = danger and Theme.Colors.danger or Theme.Colors.text
                    local row = Util.make("TextButton", {
                        Name = "Item" .. index,
                        Parent = scroll,
                        Size = UDim2.new(1, 0, 0, rowHeight),
                        BackgroundColor3 = Theme.Colors.control,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        LayoutOrder = order,
                        Active = true,
                        ZIndex = 3005,
                    })
                    Util.roundCorners(row, 8)
                    local xText = 11
                    local iconLabel = nil
                    if item.Icon then
                        iconLabel = Util.make("TextLabel", {
                            Name = "Icon",
                            Parent = row,
                            Text = Icons.get(item.Icon, item.Icon),
                            BackgroundTransparency = 1,
                            Font = Theme.Typography.FontBold,
                            TextColor3 = itemColor,
                            TextSize = 13,
                            Position = UDim2.fromOffset(10, 0),
                            Size = UDim2.fromOffset(18, rowHeight),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 3006,
                        })
                        xText = 36
                    end
                    local itemLabel = Util.make("TextLabel", {
                        Name = "Label",
                        Parent = row,
                        Text = tostring(item.Text or "Action"),
                        BackgroundTransparency = 1,
                        Font = Theme.Typography.FontMedium,
                        TextColor3 = itemColor,
                        TextSize = Theme.Typography.Size.small,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Position = UDim2.fromOffset(xText, 0),
                        Size = UDim2.new(1, -(xText + 10), 1, 0),
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 3006,
                    })
                    table.insert(itemLabels, {
                        label = itemLabel,
                        icon = iconLabel,
                        danger = danger,
                    })
                    local rowConnection = row.MouseEnter:Connect(function()
                        Animator.tween(row, "contextHover", {
                            BackgroundTransparency = danger and 0.90 or 0.93,
                        }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                    end)
                    local leaveConnection = row.MouseLeave:Connect(function()
                        Animator.tween(row, "contextHover", {
                            BackgroundTransparency = 1,
                        }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                    end)
                    local clickConnection = row.Activated:Connect(function()
                        local callback = item.OnClick
                        close(true)
                        if type(callback) == "function" then
                            Util.safeCall(callback, item)
                        end
                    end)
                    menuBin:add(rowConnection)
                    menuBin:add(leaveConnection)
                    menuBin:add(clickConnection)
                    menuBin:add(row)
                end
            end

            menuBin:add(scroll)
            menuBin:add(layout)
            menuBin:connect(menuObject._overlay.Activated, function()
                close(true)
            end)
            menuObject._escape = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then
                    return
                end
                if input.KeyCode == Enum.KeyCode.Escape then
                    close(true)
                end
            end)
            task.defer(function()
                if menuObject._menu == menu then
                    Animator.tween(scale, "contextScale", {
                        Scale = 1,
                    }, Theme.Animation.fast, Enum.EasingStyle.Back)
                end
            end)
            menuBin:add(Theme.onChange(function()
                for _, entry in ipairs(itemLabels) do
                    local color = entry.danger and Theme.Colors.danger or Theme.Colors.text
                    Animator.tween(entry.label, "contextLabelColor", {
                        TextColor3 = color,
                    }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                    if entry.icon then
                        Animator.tween(entry.icon, "contextIconColor", {
                            TextColor3 = color,
                        }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                    end
                end
            end))
            menuObject._open = true
        end

        local openConnection = target.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or menuObject._destroyed then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                local position = UserInputService:GetMouseLocation()
                build(position)
            end
        end)
        menuObject._bin:add(openConnection)
        menuObject._bin:connect(target.AncestryChanged, function(_, parent)
            if not parent and not menuObject._destroyed then
                menuObject:destroy()
            end
        end)

        function menuObject:open(position)
            build(position or UserInputService:GetMouseLocation())
            return self
        end

        function menuObject:close()
            close(true)
            return self
        end

        function menuObject:setItems(newItems)
            items = newItems or {}
            self._items = items
            if self._open then
                local lastPosition = self._position or UserInputService:GetMouseLocation()
                close(false)
                if not self._destroyed and target and target.Parent then
                    build(lastPosition)
                end
            end
            return self
        end

        function menuObject:destroy()
            if self._destroyed then
                return
            end
            self._destroyed = true
            close(false)
            self._bin:destroy()
            target = nil
        end

        return menuObject
    end

    function ContextMenu.closeAll()
        close_active()
    end

    return ContextMenu
end

--====================================================================--
-- WINDOW
--====================================================================--
_mods["Window"] = function()
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Theme = _get("Theme")
    local Util = _get("Util")
    local Animator = _get("Animator")
    local Page = _get("Page")
    local Notifications = _get("Notifications")
    local Modal = _get("Modal")
    local ContextMenu = _get("ContextMenu")
    local Icons = _get("Icons")

    local Window = {}

    local function apply_initial_theme(options)
        if options.Theme ~= nil then
            if type(options.Theme) == "string" then
                Theme.setMode(options.Theme)
            elseif type(options.Theme) == "table" then
                Theme.patch(options.Theme)
            end
        end
        if options.Accent ~= nil and typeof(options.Accent) == "Color3" then
            Theme.setAccent(options.Accent)
        end
        if options.Mode ~= nil and type(options.Mode) == "string" then
            Theme.setMode(options.Mode)
        end
    end

    local function size_from_udim2(value, fallback, viewport)
        if value == nil then
            return fallback
        end
        return Vector2.new(
            value.X.Scale * viewport.X + value.X.Offset,
            value.Y.Scale * viewport.Y + value.Y.Offset
        )
    end

    local function tween_color(instance, slot, property, color, duration)
        Animator.tween(instance, slot, {
            [property] = color,
        }, duration or Theme.Animation.normal, Enum.EasingStyle.Quad)
    end

    function Window.new(options)
        options = options or {}
        apply_initial_theme(options)

        local viewport = Util.viewport()
        local requested = size_from_udim2(options.Size, Vector2.new(720, 480), viewport)
        local maxWidth = math.max(200, viewport.X - 24)
        local maxHeight = math.max(180, viewport.Y - 24)
        local width = math.min(requested.X, maxWidth)
        local height = math.min(requested.Y, maxHeight)
        width = math.max(width, math.min(360, maxWidth))
        height = math.max(height, math.min(260, maxHeight))
        local sidebarWidth = math.clamp(width * 0.25, 148, 184)
        local headerHeight = 54

        local gui = Util.createScreenGui("UILibWindow")
        local root = Util.make("Frame", {
            Name = "UILibRoot",
            Parent = gui,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 10,
        })
        pcall(function()
            root.Interactable = false
        end)

        local wrapper = Util.make("Frame", {
            Name = "Window",
            Parent = root,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = options.Position or UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(width, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 10,
        })
        local shadow = Util.softShadow(wrapper, {
            radius = Theme.Radius.xl,
            transparency = Theme.Transparency.shadow,
        })

        local glass = Util.make("Frame", {
            Name = "Glass",
            Parent = wrapper,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Colors.surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = true,
            ZIndex = 10,
        })
        local glassHandle = Util.applyGlass(glass, {
            radius = Theme.Radius.xl,
            colorKey = "surface",
            transparencyKey = "window",
            wash = true,
        })
        local wrapperScale = Util.make("UIScale", {
            Name = "WindowScale",
            Parent = wrapper,
            Scale = 1,
        })

        local bin = Util.newBin()
        local window = {
            _gui = gui,
            _root = root,
            _wrapper = wrapper,
            _glass = glass,
            _bin = bin,
            _pages = {},
            _tabs = {},
            _activeTab = nil,
            _destroyed = false,
            _minimized = false,
            _closed = false,
            _normalSize = UDim2.fromOffset(width, height),
            _notifications = nil,
            _destroying = false,
            _dragChanged = nil,
            _dragEnded = nil,
            _closeToken = 0,
        }

        Util.onError = function(message)
            if window._destroyed then
                return
            end
            local text = tostring(message or "Unknown error")
            if #text > 220 then
                text = text:sub(1, 217) .. "..."
            end
            Notifications.push({
                Title = "Action failed",
                Text = text,
                Type = "danger",
                Duration = 5200,
            })
        end

        local header = Util.make("Frame", {
            Name = "Header",
            Parent = glass,
            Size = UDim2.new(1, 0, 0, headerHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        })
        local headerTint = Util.make("Frame", {
            Name = "HeaderTint",
            Parent = header,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Colors.control,
            BackgroundTransparency = 0.965,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 1,
        })
        Util.make("UIGradient", {
            Parent = headerTint,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.94),
                NumberSequenceKeypoint.new(1, 0.985),
            }),
        })
        local headerLine = Util.make("Frame", {
            Name = "HeaderLine",
            Parent = glass,
            Position = UDim2.new(0, 0, 0, headerHeight),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BackgroundTransparency = 0.87,
            BorderSizePixel = 0,
            ZIndex = 6,
        })

        local iconFrame = Util.make("Frame", {
            Name = "IconFrame",
            Parent = header,
            Position = UDim2.fromOffset(16, 12),
            Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = Theme.Colors.accent,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            ZIndex = 4,
        })
        Util.roundCorners(iconFrame, 10)
        local iconLabel = Util.make("TextLabel", {
            Name = "Icon",
            Parent = iconFrame,
            Text = Icons.get(options.Icon, options.Icon or "✦"),
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.accent,
            TextSize = 15,
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 5,
        })
        local hasSubtitle = options.Subtitle ~= nil and tostring(options.Subtitle) ~= ""
        local titleLabel = Util.make("TextLabel", {
            Name = "Title",
            Parent = header,
            Text = tostring(options.Title or "Interface"),
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.text,
            TextSize = Theme.Typography.Size.body,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(56, hasSubtitle and 6 or 0),
            Size = UDim2.new(1, -148, 0, hasSubtitle and 20 or headerHeight),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 4,
        })
        local subtitleLabel = nil
        if hasSubtitle then
            subtitleLabel = Util.make("TextLabel", {
                Name = "Subtitle",
                Parent = header,
                Text = tostring(options.Subtitle),
                BackgroundTransparency = 1,
                Font = Theme.Typography.Font,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(56, 26),
                Size = UDim2.new(1, -148, 0, 14),
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 4,
            })
        end

        local dragArea = Util.make("TextButton", {
            Name = "DragArea",
            Parent = header,
            Size = UDim2.new(1, -86, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Active = true,
            ZIndex = 5,
        })
        local function control_button(name, symbol, xOffset, dangerOnHover)
            local button = Util.make("TextButton", {
                Name = name,
                Parent = header,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, xOffset, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                BackgroundColor3 = Theme.Colors.control,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Active = true,
                ZIndex = 10,
            })
            Util.roundCorners(button, 9)
            local glyph = Util.make("TextLabel", {
                Name = "Glyph",
                Parent = button,
                Text = symbol,
                BackgroundTransparency = 1,
                Font = Theme.Typography.FontBold,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = 16,
                Size = UDim2.fromScale(1, 1),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 11,
            })
            bin:connect(button.MouseEnter, function()
                Animator.tween(button, "windowControlHover", {
                    BackgroundTransparency = 0.90,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                if dangerOnHover then
                    Animator.tween(button, "windowControlColor", {
                        BackgroundColor3 = Theme.Colors.danger,
                        BackgroundTransparency = 0.82,
                    }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                    tween_color(glyph, "windowControlGlyph", "TextColor3", Theme.Colors.danger, Theme.Animation.fast)
                end
            end)
            bin:connect(button.MouseLeave, function()
                Animator.tween(button, "windowControlHover", {
                    BackgroundTransparency = 1,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                Animator.tween(button, "windowControlColor", {
                    BackgroundColor3 = Theme.Colors.control,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                tween_color(glyph, "windowControlGlyph", "TextColor3", Theme.Colors.textSecondary, Theme.Animation.fast)
            end)
            return button, glyph
        end
        local minimizeButton, minimizeGlyph = control_button("Minimize", "−", -42, false)
        local closeButton, closeGlyph = control_button("Close", Icons.close, -10, true)

        local sidebar = Util.make("Frame", {
            Name = "Sidebar",
            Parent = glass,
            Position = UDim2.new(0, 0, 0, headerHeight),
            Size = UDim2.new(0, sidebarWidth, 1, -headerHeight),
            BackgroundColor3 = Theme.Colors.background,
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 2,
        })
        local sidebarLine = Util.make("Frame", {
            Name = "SidebarLine",
            Parent = glass,
            Position = UDim2.new(0, sidebarWidth, 0, headerHeight),
            Size = UDim2.fromOffset(1, height - headerHeight),
            BackgroundColor3 = Theme.Colors.textSecondary,
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = 6,
        })
        local navTitle = Util.make("TextLabel", {
            Name = "NavTitle",
            Parent = glass,
            Text = "NAVIGATION",
            BackgroundTransparency = 1,
            Font = Theme.Typography.FontBold,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(18, headerHeight + 16),
            Size = UDim2.new(0, sidebarWidth - 30, 0, 14),
            ZIndex = 4,
        })
        local navScroll = Util.make("ScrollingFrame", {
            Name = "Navigation",
            Parent = glass,
            Position = UDim2.new(0, 8, 0, headerHeight + 38),
            Size = UDim2.new(0, sidebarWidth - 16, 1, -(headerHeight + 38 + 42)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 0,
            ClipsDescendants = true,
            ZIndex = 3,
        })
        local navPadding = Util.make("UIPadding", {
            Parent = navScroll,
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 4),
        })
        local navLayout = Util.make("UIListLayout", {
            Parent = navScroll,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
        })
        bin:add(navPadding)
        bin:add(navLayout)
        local footer = Util.make("TextLabel", {
            Name = "Footer",
            Parent = glass,
            Text = "ui_lib 1.0.0",
            BackgroundTransparency = 1,
            Font = Theme.Typography.Font,
            TextColor3 = Theme.Colors.textSecondary,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 18, 1, -14),
            Size = UDim2.new(0, sidebarWidth - 30, 0, 14),
            ZIndex = 4,
        })

        local contentFrame = Util.make("Frame", {
            Name = "Content",
            Parent = glass,
            Position = UDim2.new(0, sidebarWidth, 0, headerHeight),
            Size = UDim2.new(1, -sidebarWidth, 1, -headerHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = false,
            ZIndex = 2,
        })

        local function apply_theme()
            if window._destroyed then
                return
            end
            tween_color(titleLabel, "windowText", "TextColor3", Theme.Colors.text)
            if subtitleLabel then
                tween_color(subtitleLabel, "windowText", "TextColor3", Theme.Colors.textSecondary)
            end
            tween_color(navTitle, "windowText", "TextColor3", Theme.Colors.textSecondary)
            tween_color(footer, "windowText", "TextColor3", Theme.Colors.textSecondary)
            tween_color(minimizeGlyph, "windowText", "TextColor3", Theme.Colors.textSecondary)
            tween_color(closeGlyph, "windowText", "TextColor3", Theme.Colors.textSecondary)
            Animator.tween(sidebar, "windowSidebar", {
                BackgroundColor3 = Theme.Colors.background,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(sidebarLine, "windowLine", {
                BackgroundColor3 = Theme.Colors.textSecondary,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(headerLine, "windowLine", {
                BackgroundColor3 = Theme.Colors.textSecondary,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(headerTint, "windowHeaderTint", {
                BackgroundColor3 = Theme.Colors.control,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            Animator.tween(iconFrame, "windowAccent", {
                BackgroundColor3 = Theme.Colors.accent,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            tween_color(iconLabel, "windowAccentText", "TextColor3", Theme.Colors.accent)
            for _, tab in ipairs(window._tabs) do
                if tab.pill then
                    Animator.tween(tab.pill, "tabPill", {
                        BackgroundColor3 = Theme.Colors.accent,
                    }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                end
                if tab.iconLabel then
                    tween_color(tab.iconLabel, "tabText", "TextColor3",
                        tab.active and Theme.Colors.text or Theme.Colors.textSecondary)
                end
                tween_color(tab.label, "tabText", "TextColor3",
                    tab.active and Theme.Colors.text or Theme.Colors.textSecondary)
            end
            glassHandle:setAccent(Theme.Colors.accent)
        end
        bin:add(Theme.onChange(apply_theme))

        local function set_tab_active(tab, active)
            tab.active = active
            if active then
                tab.pill.Visible = true
                Animator.tween(tab.pill, "tabPillShow", {
                    BackgroundTransparency = 0.80,
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                Animator.tween(tab.button, "tabHoverBackground", {
                    BackgroundTransparency = 1,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            else
                Animator.tween(tab.pill, "tabPillShow", {
                    BackgroundTransparency = 1,
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                task.delay(Theme.Animation.normal, function()
                    if not tab.active and tab.pill.Parent then
                        tab.pill.Visible = false
                    end
                end)
            end
            tween_color(tab.label, "tabText", "TextColor3",
                active and Theme.Colors.text or Theme.Colors.textSecondary)
            if tab.iconLabel then
                tween_color(tab.iconLabel, "tabText", "TextColor3",
                    active and Theme.Colors.text or Theme.Colors.textSecondary)
            end
        end

        local function create_tab_button(tab, index)
            local button = Util.make("TextButton", {
                Name = "Tab_" .. tostring(index),
                Parent = navScroll,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.Colors.control,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Selectable = true,
                Active = true,
                LayoutOrder = index,
                ZIndex = 3,
            })
            Util.roundCorners(button, 10)
            local pill = Util.make("Frame", {
                Name = "ActivePill",
                Parent = button,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Theme.Colors.accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Visible = false,
                Active = false,
                ZIndex = 1,
            })
            Util.roundCorners(pill, 10)
            local iconLabel = nil
            if tab.icon and tab.icon ~= "" then
                iconLabel = Util.make("TextLabel", {
                    Name = "Icon",
                    Parent = button,
                    Text = Icons.get(tab.icon, tab.icon),
                    BackgroundTransparency = 1,
                    Font = Theme.Typography.FontBold,
                    TextColor3 = Theme.Colors.textSecondary,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.fromOffset(18, 38),
                    ZIndex = 2,
                })
            end
            local label = Util.make("TextLabel", {
                Name = "Label",
                Parent = button,
                Text = tostring(tab.name),
                BackgroundTransparency = 1,
                Font = Theme.Typography.FontMedium,
                TextColor3 = Theme.Colors.textSecondary,
                TextSize = Theme.Typography.Size.caption,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(iconLabel and 34 or 13, 0),
                Size = UDim2.new(1, iconLabel and -46 or -25, 1, 0),
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 2,
            })
            local feedback = Util.feedback(button, {
                radius = 10,
                pressScale = 1,
                hoverScale = 1,
                onHover = function(state)
                    if tab.active then
                        return
                    end
                    Animator.tween(button, "tabHoverBackground", {
                        BackgroundTransparency = state and 0.955 or 1,
                    }, Theme.Animation.fast, Enum.EasingStyle.Quad)
                end,
            })
            bin:add(feedback)
            bin:connect(button.Activated, function()
                if window._destroyed then
                    return
                end
                window:selectTab(index)
            end)
            tab.button = button
            tab.pill = pill
            tab.iconLabel = iconLabel
            tab.label = label
        end

        function window:addTab(tabOptions)
            tabOptions = tabOptions or {}
            if self._destroyed then
                return nil
            end
            local page = Page.wrap(contentFrame)
            local name = tostring(tabOptions.Name or ("Tab " .. (#self._tabs + 1)))
            local tab = {
                name = name,
                icon = tabOptions.Icon,
                page = page,
                index = #self._tabs + 1,
                active = false,
            }
            table.insert(self._tabs, tab)
            create_tab_button(tab, tab.index)
            page._scroll.Visible = false
            if #self._tabs == 1 then
                self:selectTab(1)
            end
            return page
        end

        function window:selectTab(indexOrName)
            if self._destroyed then
                return nil
            end
            local target = nil
            if type(indexOrName) == "number" then
                target = self._tabs[indexOrName]
            elseif type(indexOrName) == "string" then
                for _, tab in ipairs(self._tabs) do
                    if tab.name == indexOrName then
                        target = tab
                        break
                    end
                end
            end
            if not target then
                return nil
            end
            if self._activeTab == target then
                return target.page
            end
            if self._activeTab then
                self._activeTab.page._scroll.Visible = false
                set_tab_active(self._activeTab, false)
            end
            self._activeTab = target
            target.page._scroll.Visible = true
            set_tab_active(target, true)
            if type(options.OnTabChange) == "function" then
                Util.safeCall(options.OnTabChange, target.index, target.page)
            end
            return target.page
        end

        function window:content()
            return self._activeTab and self._activeTab.page or nil
        end

        local function stop_drag()
            if window._dragChanged then
                pcall(function()
                    window._dragChanged:Disconnect()
                end)
                window._dragChanged = nil
            end
            if window._dragEnded then
                pcall(function()
                    window._dragEnded:Disconnect()
                end)
                window._dragEnded = nil
            end
        end

        local function begin_drag(input)
            if window._minimized or window._closed or window._destroyed then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            stop_drag()
            local startPointer = Util.mousePosition(input)
            local startPosition = wrapper.AbsolutePosition
            local currentViewport = Util.viewport()
            window._dragChanged = UserInputService.InputChanged:Connect(function(changed)
                if changed.UserInputType ~= Enum.UserInputType.MouseMovement
                    and changed.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                local pointer = Util.mousePosition(changed)
                local size = wrapper.AbsoluteSize
                local x = startPosition.X + pointer.X - startPointer.X
                local y = startPosition.Y + pointer.Y - startPointer.Y
                x = math.clamp(x, 6, math.max(6, currentViewport.X - size.X - 6))
                y = math.clamp(y, 6, math.max(6, currentViewport.Y - size.Y - 6))
                wrapper.Position = UDim2.fromOffset(x, y)
            end)
            window._dragEnded = UserInputService.InputEnded:Connect(function(ended)
                if ended.UserInputType == Enum.UserInputType.MouseButton1
                    or ended.UserInputType == Enum.UserInputType.Touch then
                    stop_drag()
                end
            end)
        end
        bin:connect(dragArea.InputBegan, begin_drag)
        bin:add(stop_drag)

        local normalSize = UDim2.fromOffset(width, height)

        local function set_body_visible(visible)
            sidebar.Visible = visible
            contentFrame.Visible = visible
            sidebarLine.Visible = visible
            navTitle.Visible = visible
            navScroll.Visible = visible
            footer.Visible = visible
        end

        function window:minimize()
            if self._destroyed or self._closed then
                return self
            end
            if self._minimized then
                return self
            end
            stop_drag()
            self._minimized = true
            self._normalSize = wrapper.Size
            Notifications._setVisible(false)
            minimizeGlyph.Text = "▢"
            local compactSize = UDim2.fromOffset(math.min(330, width), headerHeight)
            Animator.tween(wrapper, "windowSize", {
                Size = compactSize,
            }, Theme.Animation.normal, Enum.EasingStyle.Quad)
            task.delay(Theme.Animation.normal + 0.02, function()
                if self._minimized and not self._destroyed then
                    set_body_visible(false)
                end
            end)
            if type(options.OnMinimize) == "function" then
                Util.safeCall(options.OnMinimize, true)
            end
            return self
        end

        function window:restore()
            if self._destroyed then
                return self
            end
            if self._closed then
                self._closed = false
                gui.Enabled = true
                Animator.tween(wrapperScale, "windowScale", {
                    Scale = 1,
                }, Theme.Animation.normal, Enum.EasingStyle.Back)
            end
            if self._minimized then
                self._minimized = false
                set_body_visible(true)
                minimizeGlyph.Text = "−"
                local targetSize = self._normalSize or normalSize
                local currentViewport = Util.viewport()
                local targetWidth = math.min(targetSize.X.Offset, math.max(300, currentViewport.X - 24))
                local targetHeight = math.min(targetSize.Y.Offset, math.max(200, currentViewport.Y - 24))
                Animator.tween(wrapper, "windowSize", {
                    Size = UDim2.fromOffset(targetWidth, targetHeight),
                }, Theme.Animation.normal, Enum.EasingStyle.Quad)
                Notifications._setVisible(true)
                if type(options.OnMinimize) == "function" then
                    Util.safeCall(options.OnMinimize, false)
                end
            elseif not self._closed then
                Notifications._setVisible(true)
            end
            return self
        end

        function window:close()
            if self._destroyed or self._closed then
                return self
            end
            stop_drag()
            self._closed = true
            self._closeToken = self._closeToken + 1
            local token = self._closeToken
            Notifications._setVisible(false)
            Animator.tween(wrapperScale, "windowScale", {
                Scale = 0.94,
            }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            task.delay(Theme.Animation.fast + 0.02, function()
                if token == self._closeToken and self._closed and not self._destroyed then
                    gui.Enabled = false
                    if type(options.OnClose) == "function" then
                        Util.safeCall(options.OnClose)
                    end
                end
            end)
            return self
        end

        function window:setTheme(theme)
            if type(theme) == "string" then
                Theme.setMode(theme)
            elseif type(theme) == "table" then
                Theme.patch(theme)
            end
            return self
        end

        function window:setAccent(color)
            if typeof(color) == "Color3" then
                Theme.setAccent(color)
            end
            return self
        end

        function window:setTitle(text)
            titleLabel.Text = tostring(text or "")
            return self
        end

        function window:setSubtitle(text)
            local value = tostring(text or "")
            if not subtitleLabel then
                if value == "" then
                    return self
                end
                subtitleLabel = Util.make("TextLabel", {
                    Name = "Subtitle",
                    Parent = header,
                    Text = value,
                    BackgroundTransparency = 1,
                    Font = Theme.Typography.Font,
                    TextColor3 = Theme.Colors.textSecondary,
                    TextSize = Theme.Typography.Size.caption,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.fromOffset(56, 26),
                    Size = UDim2.new(1, -148, 0, 14),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 4,
                })
                titleLabel.Position = UDim2.fromOffset(56, 6)
                titleLabel.Size = UDim2.new(1, -148, 0, 20)
            else
                subtitleLabel.Text = value
            end
            return self
        end

        function window:setIcon(icon)
            iconLabel.Text = Icons.get(icon, icon or "")
            return self
        end

        function window:getGui()
            return gui
        end

        function window:getFrame()
            return wrapper
        end

        function window:isMinimized()
            return self._minimized
        end

        function window:isClosed()
            return self._closed
        end

        function window:destroy()
            if self._destroying or self._destroyed then
                return
            end
            self._destroying = true
            self._destroyed = true
            self._closeToken = self._closeToken + 1
            stop_drag()
            Notifications._detach(self)
            pcall(function()
                Modal.destroyFor(gui)
            end)
            pcall(function()
                ContextMenu.closeAll()
            end)
            for _, tab in ipairs(self._tabs) do
                pcall(tab.page.destroy, tab.page)
            end
            self._tabs = {}
            self._pages = {}
            self._activeTab = nil
            Animator.cancelAll(wrapper)
            Animator.cancelAll(glass)
            bin:destroy()
            if shadow then
                shadow:destroy()
            end
            if glassHandle then
                glassHandle:destroy()
            end
            pcall(function()
                gui:Destroy()
            end)
        end

        minimizeButton.Activated:Connect(function()
            if window._minimized then
                window:restore()
            else
                window:minimize()
            end
        end)
        closeButton.Activated:Connect(function()
            window:close()
        end)

        local function clamp_to_viewport()
            if window._destroyed or window._minimized or window._closed then
                return
            end
            local viewportNow = Util.viewport()
            local currentSize = wrapper.AbsoluteSize
            local newWidth = math.min(currentSize.X, math.max(300, viewportNow.X - 24))
            local newHeight = math.min(currentSize.Y, math.max(200, viewportNow.Y - 24))
            if math.abs(newWidth - currentSize.X) > 1 or math.abs(newHeight - currentSize.Y) > 1 then
                normalSize = UDim2.fromOffset(newWidth, newHeight)
                window._normalSize = normalSize
                Animator.tween(wrapper, "windowSize", {
                    Size = normalSize,
                }, Theme.Animation.fast, Enum.EasingStyle.Quad)
            end
            local absolute = wrapper.AbsolutePosition
            local x = math.clamp(absolute.X, 6, math.max(6, viewportNow.X - newWidth - 6))
            local y = math.clamp(absolute.Y, 6, math.max(6, viewportNow.Y - newHeight - 6))
            wrapper.Position = UDim2.fromOffset(x, y)
        end

        local camera = workspace.CurrentCamera
        if camera then
            bin:connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                task.defer(clamp_to_viewport)
            end)
        end
        set_body_visible(true)
        apply_theme()
        clamp_to_viewport()

        -- Notifications live inside the window wrapper, above the glass and
        -- outside its clipping, so they move with the window and never get cut
        -- by the rounded window corners.
        window._notifications = Notifications._attach(window, wrapper)
        Modal._setDefaultGui(gui)

        if options.Minimized == true then
            window:minimize()
        end

        return window
    end

    return Window
end

--====================================================================--
-- PUBLIC API
--====================================================================--
local UI = {
    version = "1.0.0",
    Window = _get("Window"),
    Page = _get("Page"),
    Widgets = _get("Widgets"),
    Theme = _get("Theme"),
    Animator = _get("Animator"),
    Util = _get("Util"),
    Icons = _get("Icons"),
    Notifications = _get("Notifications"),
    Modal = _get("Modal"),
    ContextMenu = _get("ContextMenu"),
}

UI.create = UI.Window.new

return UI

