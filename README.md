# ui_lib.luau — Liquid Glass UI for Roblox executors

Один файл, без `require`, без Rojo, без Studio-плагинов и внешних зависимостей.
Стиль — Apple Liquid Glass (iOS 26 / macOS Tahoe): многослойное стекло, зерно,
световой rim сверху, тёмная кромка снизу, акцентное «преломление», мягкие
цветные тени и анимации 150/250/400 мс.

> **Важно:** Roblox не даёт настоящий backdrop-blur для ScreenGui. Здесь он
> имитируется полупрозрачностью, noise-текстурой, градиентами, rim-light и
> слоями тени. Никакого `UIShadow` (его нет в базовом Roblox API) не используется.

---

## Установка

```lua
-- локальный файл
local UI = loadstring(readfile("ui_lib.luau"))()

-- или с GitHub
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/user/ui-lib/main/ui_lib.luau"))()
```

`loadstring` должен возвращать таблицу `UI`. Если ваш экзекьютор не поддерживает
`readfile`, используйте вариант с `game:HttpGet`.

---

## Aurora Dashboard Demo

В комплекте есть готовый дашборд по референсу: `aurora_demo.luau`.
Это не замена библиотеки, а приложение поверх неё — с сайдбаром, поиском,
профилем, статистикой, Quick Controls, System Status, Theme Preview,
Recent Activity, карточкой уведомлений, плавающими toast-карточками и
адаптивной вёрсткой.

```lua
-- положите ui_lib.luau и aurora_demo.luau в workspace экзекьютора
loadstring(readfile("aurora_demo.luau"))()
```

Демо само подхватывает `ui_lib.luau`:

1. пробует `loadstring(readfile("ui_lib.luau"))()`;
2. если файла нет — `game:HttpGet(LIB_URL)`;
3. `LIB_URL` находится в первых строках `aurora_demo.luau`.

Если библиотека уже загружена вручную, можно передать её через
`getgenv().AuroraUILib` (или глобальную `AuroraUILib`):

```lua
getgenv().AuroraUILib = UI
loadstring(readfile("aurora_demo.luau"))()
```

### Адаптивность

| Ширина экрана | Поведение |
|---|---|
| `< 760` | мобильный режим: сайдбар превращается в drawer, поиск открывается иконкой, статистика 2×2, все карточки в одну колонку |
| `760–1239` | компактный desktop: сайдбар на месте, карточки адаптируются, toast-карточки закреплены справа/поверх контента |
| `>= 1240` | полноширинный desktop: слева окно, справа отдельная колонка toast-уведомлений |
| внутренняя ширина `>= 640` | две колонки контента (Quick Controls + Activity / Status + Theme + Notifications) |
| внутренняя ширина `>= 860` | четыре stat-карточки в ряд |

Мобильные элементы:

- hamburger → drawer с навигацией и карточкой пользователя;
- иконка поиска → отдельная строка поиска под шапкой;
- кнопки закрытия/сворачивания увеличены до 32 px;
- все карточки, списки и страницы скроллятся;
- toast-уведомления на мобильном показываются под шапкой, а не поверх кнопок управления;
- на старте в мобильном режиме показывается один toast, а не три;
- `Restore Window` появляется после minimize/close и возвращает окно.

### Что внутри демо

- тёмная палитра `Aurora`: графит + cyan accent, 5 пресетов accent;
- кастомные glass-карточки, stat-карточки, status-строки, activity-строки;
- кастомные primary/secondary кнопки с градиентом, hover, press и rim;
- библиотечные `toggle`, `slider`, `dropdown` внутри Quick Controls;
- кастомный message input с send-кнопкой и toast-подтверждением;
- страницы Settings / Components / Themes / Notifications / Profile / About;
- переключение accent без пересоздания интерфейса;
- floating toasts Success/Info/Warning с закрытием и auto-dismiss;
- minimize/close → restore pill;
- `app:destroy()` полностью очищает GUI и возвращает прежнюю тему.

Публичные методы демо:

```lua
local app = loadstring(readfile("aurora_demo.luau"))()

app:setPage("settings")          -- home | settings | components | themes | notifications | profile | about
app:setDrawer(true)              -- mobile drawer
app:setMobileSearch(true)        -- мобильная строка поиска
app:setAccent(color, index)      -- accent из ACCENTS
app:cycleAccent()                -- следующий preset
app:toast("success", "Title", "Text", 3000)
app:minimize()
app:close()
app:restore()
app:isOpen()
app:getGui()
app:destroy()
```

> Демо использует только тёмную тему. Светлая тема библиотеки остаётся
> доступной через `UI.Theme.setMode("light")`, но кастомная Aurora-палитра
> рассчитана на тёмное стекло. При желании цвета `C` и `ACCENTS` в начале
> `aurora_demo.luau` заменяются на свои.

### Проверка Aurora в экзекьюторе

1. **1536×1024** — окно слева, три toast-карточки справа на wallpaper-полосе,
   четыре stat-карточки в ряд, две колонки контента.
2. **1280×720** — две колонки, статистика 2×2, toast-карточки справа,
   контент скроллится.
3. **1024×768** — две колонки, toast-карточки ниже шапки и не перекрывают
   кнопки minimize/close; сайдбар остаётся.
4. **390×844** — сайдбар скрыт, hamburger открывает drawer, иконка поиска
   открывает строку поиска, статистика 2×2, карточки в одну колонку,
   стартовый toast один, а не три.
5. Nav: Home / Settings / Components / Themes / Notifications / Profile / About
   переключают страницы и закрывают drawer на телефоне.
6. Quick Controls: Primary/Secondary кнопки, toggle, slider, dropdown и
   message input работают мышью и touch; dropdown открывается поверх окна.
7. Theme Preview: пять swatch-кнопок и «Change Theme» меняют accent без
   пересоздания интерфейса.
8. Minimize/Close прячут окно, появляется `Restore Window`; restore возвращает
   окно, позицию и toast-стек.
9. Проверьте верхний safe-area: окно и тосты должны начинаться ниже topbar
   (`GuiService:GetGuiInset()` учтён в layout).
10. `app:destroy()` должен убрать ScreenGui, остановить таймеры и вернуть
    прежнюю тему библиотеки.

---

## Быстрый старт

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/user/ui-lib/main/ui_lib.luau"))()

local win = UI.Window.new({
    Title = "Kimi Hub",
    Subtitle = "v1.0.0",
    Size = UDim2.fromOffset(720, 480),
    Icon = "⚡",
})

local main = win:addTab({ Name = "Main", Icon = "🏠" })
local settings = win:addTab({ Name = "Settings", Icon = "⚙" })

main:heading("Welcome")
main:paragraph("Configure your experience below.")

main:section("Features", function(s)
    s:toggle({
        Text = "Auto Farm",
        Description = "Farm mobs automatically",
        Value = false,
        OnChange = function(v) print(v) end,
    })
    s:toggle({ Text = "Kill Aura", Value = false, OnChange = function(v) print(v) end })
end)

main:section("Combat", function(s)
    s:slider({ Text = "Range", Min = 1, Max = 50, Value = 20, OnChange = function(v) print(v) end })
    s:dropdown({
        Text = "Weapon",
        Options = { { Text = "Sword" }, { Text = "Bow" } },
        OnChange = function(v) print(v) end,
    })
    s:keybind({ Text = "Toggle Aura", Value = Enum.KeyCode.Q, OnChange = function(k) print(k) end })
    s:colorpicker({ Text = "Highlight", Value = Color3.fromRGB(10, 132, 255), OnChange = function(c) print(c) end })
end)

main:card({ Title = "Discord", Description = "Join our community", Icon = "💬", OnClick = function() print("open") end })

settings:tabs({
    Tabs = { { Text = "General" }, { Text = "Appearance" } },
    OnChange = function(i) print(i) end,
})

UI.Notifications.push({ Title = "Loaded", Text = "UI ready", Type = "success", Duration = 3000 })
```

---

## Полный пример

```lua
local UI = loadstring(readfile("ui_lib.luau"))()

local win = UI.Window.new({
    Title = "Nebula",
    Subtitle = "Liquid Glass",
    Size = UDim2.fromOffset(780, 520),
    Icon = "✦",
    Accent = Color3.fromRGB(10, 132, 255),
})

local page = win:addTab({ Name = "Dashboard", Icon = "⌂" })

page:heading("Dashboard")
page:paragraph("A small demo of every component. Theme updates animate without rebuilding the UI.")

page:row(function(r)
    r:button({ Text = "Primary", Variant = "primary", OnClick = function() end })
    r:button({ Text = "Secondary", Variant = "secondary", OnClick = function() end })
    r:button({ Text = "Ghost", Variant = "ghost", OnClick = function() end })
end)

page:section("Controls", function(s)
    s:toggle({ Text = "Enabled", Description = "Animated switch", Value = true })
    s:slider({ Text = "Volume", Min = 0, Max = 100, Value = 65, Suffix = "%" })
    s:dropdown({
        Text = "Mode",
        Options = {
            { Text = "Balanced", Value = "balanced", Icon = "⚖" },
            { Text = "Performance", Value = "performance", Icon = "⚡" },
        },
        Value = "balanced",
    })
    s:textinput({
        Placeholder = "Display name",
        Value = "",
        Validator = function(text)
            if #text < 3 then return "Minimum 3 characters" end
            return nil
        end,
    })
    s:keybind({ Text = "Menu key", Value = Enum.KeyCode.RightShift })
    s:colorpicker({ Text = "Accent", Value = Color3.fromRGB(10, 132, 255) })
end)

page:row(function(r)
    r:stat({ Label = "Players", Value = "1,248", Delta = "+12.4%", DeltaPositive = true })
    r:progress({ Value = 0.68, ShowPercent = true })
end)

page:tabs({ Tabs = { { Text = "Overview" }, { Text = "Details", Icon = "☰" } } })
page:list({
    Items = {
        { Icon = "👤", Text = "Profile", Description = "Account and identity", Right = "›" },
        { Icon = "🔒", Text = "Security", Description = "Keys and sessions", Right = "›" },
    },
    OnSelect = function(item, index) end,
})
page:separator({ Text = "More" })
page:accordion({
    Items = {
        { Title = "Advanced", Content = function(s) s:toggle({ Text = "Unsafe mode" }) end },
    },
})
page:grid({
    Columns = 2,
    Children = {
        function(cell) cell:card({ Title = "Card A", Description = "Grid cell", Icon = "⚡" }) end,
        function(cell) cell:card({ Title = "Card B", Description = "Grid cell", Icon = "🎨" }) end,
    },
})

local dialog = UI.Modal.new({
    Title = "Confirm action",
    Content = function(modalPage)
        modalPage:paragraph("This action cannot be undone.")
        modalPage:badge({ Text = "DANGER", Color = Color3.fromRGB(255, 69, 58) })
    end,
    Actions = {
        { Text = "Cancel", Variant = "secondary" },
        { Text = "Continue", Variant = "danger", OnClick = function() end },
    },
})

local menu = UI.ContextMenu.attach(win:getFrame(), {
    Items = {
        { Text = "Refresh", Icon = "🔄", OnClick = function() end },
        { Separator = true },
        { Text = "Remove", Icon = "🗑", Danger = true, OnClick = function() end },
    },
})
```

---

## Публичный API

### `UI`
| Поле | Описание |
|---|---|
| `UI.Window` | фабрика окна |
| `UI.Page` | `Page.wrap(parent)` для кастомных контейнеров |
| `UI.Widgets` | низкоуровневые фабрики (parent-first) |
| `UI.Theme` | токены и режимы |
| `UI.Animator` | tween-менеджер |
| `UI.Util` | утилиты, стекло, cleanup |
| `UI.Icons` | 130+ Unicode-иконок |
| `UI.Notifications` | стек уведомлений |
| `UI.Modal` | модальные окна |
| `UI.ContextMenu` | контекстные меню |
| `UI.create` | алиас `UI.Window.new` |
| `UI.version` | `"1.0.0"` |

### Theme
```lua
UI.Theme.patch({
    Colors = { accent = Color3.fromRGB(255, 90, 0) },
    Radius = { lg = 18 },
    Animation = { normal = 0.22 },
})

UI.Theme.setMode("light") -- "dark" | "light"
UI.Theme.setAccent(Color3.fromRGB(10, 132, 255))
UI.Theme.reset()
UI.Theme.currentMode() -- "dark" | "light"
UI.Theme.get("Colors.accent")
local disconnect = UI.Theme.onChange(function(theme) end)
disconnect()
```
Токены:
`Colors` (`background`, `surface`, `surfaceElevated`, `control`, `text`,
`textSecondary`, `accent`, `success`, `warning`, `danger`, `border`, `shadow`,
`onAccent`, `overlay`), `Transparency`, `Typography` (`Font`, `FontMedium`,
`FontBold`, `Size.caption/small/body/title/display`), `Spacing` (`xs/sm/md/lg/xl`),
`Radius` (`sm/md/lg/xl`), `Animation` (`fast/normal/slow`).

### Animator
```lua
UI.Animator.tween(instance, "slot", { BackgroundTransparency = 0.1 }, 0.25, Enum.EasingStyle.Quad)
UI.Animator.cancel(instance, "slot")
UI.Animator.cancelAll(instance)
UI.Animator.has(instance, "slot")
```
Один слот = один активный tween. Новый tween в том же слоте отменяет старый.

### Util
```lua
UI.Util.make("Frame", { Size = UDim2.fromOffset(10, 10), Parent = parent })
local bin = UI.Util.newBin()
bin:add(connection); bin:add(instance); bin:add(function() end); bin:destroy()

UI.Util.roundCorners(frame, 16)
local glass = UI.Util.applyGlass(frame, { radius = 16, colorKey = "surface", wash = true })
-- glass:setAccent(color), glass:setTransparency(n), glass:setRadius(r), glass:destroy()

UI.Util.softShadow(parent, { radius = 24 })
UI.Util.focusRing(frame, 12)
UI.Util.feedback(button, { pressScale = 0.97, hoverScale = 1.005 })
UI.Util.clampToViewport(position, size)
UI.Util.guiOf(instance)
UI.Util.popupLayer(instance)
UI.Util.hexToColor("#0A84FF")
UI.Util.colorToHex(color)
UI.Util.safeCall(callback, ...)
```

### Window
```lua
local win = UI.Window.new({
    Title = "Title",
    Subtitle = "subtitle",
    Size = UDim2.fromOffset(720, 480),
    Position = UDim2.fromScale(0.5, 0.5),
    Icon = "⚡",
    Theme = "dark",             -- или таблица для Theme.patch
    Accent = Color3.fromRGB(10, 132, 255),
    OnClose = function() end,
    OnMinimize = function(minimized) end,
    OnTabChange = function(index, page) end,
})
```
| Метод | Описание |
|---|---|
| `win:addTab({ Name, Icon })` | создаёт вкладку и возвращает `Page` |
| `win:selectTab(indexOrName)` | активирует вкладку |
| `win:content()` | текущая `Page` |
| `win:minimize()` / `win:restore()` | свернуть/развернуть; `restore` также открывает после `close` |
| `win:close()` | анимационно скрывает UI; объекты живы |
| `win:destroy()` | уничтожает страницы, уведомления, модалки, popup-слой и ScreenGui |
| `win:setTheme("light"|"dark"|table)` | тема |
| `win:setAccent(color)` | глобальный акцент |
| `win:setTitle(text)` / `win:setSubtitle(text)` / `win:setIcon(icon)` | заголовок |
| `win:getGui()` / `win:getFrame()` | ScreenGui / корневой Frame |
| `win:isMinimized()` / `win:isClosed()` | состояние |

Окно создаёт ScreenGui через `gethui()` → `protect_gui` / `syn.protect_gui` →
`CoreGui` → `PlayerGui`; все вызовы защищены `pcall`. `ResetOnSpawn = false`,
`IgnoreGuiInset = true`, `DisplayOrder = 999`.

### Page
`win:addTab` возвращает `Page`. Также доступен `UI.Page.wrap(parent)`.
| Метод | Описание |
|---|---|
| `page:heading(text)` | заголовок 28 px |
| `page:paragraph(text)` | абзац 13 px |
| `page:divider()` | линия |
| `page:spacer(n)` | вертикальный отступ |
| `page:section(title, callback)` | стеклянная секция; callback получает scope |
| `page:card(table)` / `page:card(callback)` | карточка-кнопка или контейнер |
| `page:row(callback)` | горизонтальный ряд с равными колонками |
| `page:clear()` | удалить всё содержимое страницы |
| `page:scrollToTop(animated)` | скролл вверх |
| `page:getScrollFrame()` | ScrollingFrame |
| `page:destroy()` | очистка |

Все виджет-методы ниже доступны и у `page`, и у scope внутри `section`,
`card(function ... end)`, `row(function ... end)`, `grid` cell.

### Widgets

#### Button
```lua
local b = page:button({ Text = "Run", Icon = "play", Variant = "primary", OnClick = function() end, Disabled = false })
```
`Variant`: `"primary" | "secondary" | "ghost" | "danger"`.
Методы: `setText`, `setIcon`, `setDisabled`, `destroy`. Поля: `root`, `glass`.

#### Toggle
```lua
local t = page:toggle({ Text = "Enabled", Description = "optional", Value = false, OnChange = function(v) end })
```
Методы: `get`, `set(value, silent)`, `toggle(silent)`, `setDisabled`, `destroy`.

#### Slider
```lua
local s = page:slider({ Text = "Range", Min = 1, Max = 50, Value = 20, Suffix = "", OnChange = function(v) end })
```
Методы: `getValue`, `setValue(value, silent)`, `setRange(min, max)`, `setDisabled`, `destroy`.
Поддерживается `Step` (по умолчанию 1 для целых границ, иначе 0.01).

#### Dropdown
```lua
local d = page:dropdown({
    Text = "Weapon",
    Options = { { Text = "Sword", Value = "sword" }, { Text = "Bow", Value = "bow", Icon = "🏹" } },
    Value = "sword",
    Placeholder = "Select...",
    OnChange = function(value, option, index) end,
})
```
Методы: `getValue`, `setValue(value, silent)`, `setOptions`, `open`, `close`, `setDisabled`, `destroy`.
Меню открывается overlay-слоем над окном, следует за полем и закрывается кликом снаружи / Escape.

#### Text input
```lua
local ti = page:textinput({
    Placeholder = "Name",
    Value = "",
    Icon = "user",
    Validator = function(text)
        if #text < 3 then return "Too short" end
        return nil
    end,
    OnChange = function(text) end,
})
```
Методы: `get`, `set(text, silent)`, `setError(text)`, `validate()`, `focus()`, `setDisabled`, `destroy`.

#### Keybind
```lua
local k = page:keybind({ Text = "Toggle", Value = Enum.KeyCode.Q })
```
Методы: `getValue`, `setValue(key, silent)`, `startCapture`, `cancelCapture`, `destroy`.
Escape всегда отменяет захват.

#### Color picker
```lua
local cp = page:colorpicker({ Text = "Accent", Value = Color3.fromRGB(10, 132, 255), Expanded = false })
```
Методы: `getValue`, `setValue(color, silent)`, `expand`, `collapse`, `toggle`, `isExpanded`, `destroy`.
HSV-квадрат, hue-полоса и hex-поле с валидацией.

#### Section
```lua
local sec = page:section("Features", function(s) end)
-- или
local sec = page:section({ Title = "Features", Icon = "⚡", Collapsible = true, Expanded = true,
    Content = function(s) end })
```
Методы: `setTitle`, `setExpanded`, `expand`, `collapse`, `toggleExpanded`, `isExpanded`, `refreshHeight`, `destroy`.
Внутри доступны все виджеты. Не путать `section:toggleExpanded()` с `section:toggle({...})` (последний создаёт switch).

#### Card
```lua
local c = page:card({
    Title = "Discord",
    Description = "Join our community",
    Icon = "💬",
    RightContent = "›", -- строка / Instance / function(parent)
    OnClick = function() end,
})
```
Методы: `setTitle`, `setDescription`, `setRight`, `setDisabled`, `destroy`.

#### Badge / Chip
```lua
page:badge({ Text = "NEW", Color = Color3.fromRGB(10, 132, 255) })
page:chip({ Text = "Beta", Icon = "⚡", Removable = true, OnRemove = function() end })
```
Badge: `setText`, `setColor`, `destroy`.
Chip: `setText`, `destroy`.

#### Avatar
```lua
page:avatar({ Image = "rbxassetid://...", Name = "alice", Status = "online" })
```
Status: `"online" | "idle" | "dnd" | "offline"`.
Методы: `setStatus`, `setImage`, `setName`, `destroy`.

#### Progress / Spinner / Stat
```lua
page:progress({ Value = 0.7, Color = Color3.fromRGB(48,209,88), ShowPercent = true })
page:spinner({ Size = 20 })
page:stat({ Label = "Players", Value = "128", Delta = "+12%", DeltaPositive = true })
```
Progress: `setValue`, `getValue`, `setColor`, `destroy`.
Spinner: `setColor`, `destroy`.
Stat: `setValue`, `setDelta`, `destroy`.

#### Tabs
```lua
local tabs = page:tabs({ Tabs = { { Text = "General" }, { Text = "Appearance", Icon = "🎨" } },
    Value = 1, OnChange = function(index, tab) end })
```
Методы: `setValue(index, silent)`, `getValue`, `destroy`.

#### List
```lua
local list = page:list({
    Items = { { Icon = "👤", Text = "Profile", Description = "Optional", Right = "›" } },
    Value = 1,
    OnSelect = function(item, index) end,
})
```
Методы: `setItems`, `getSelected`, `destroy`.

#### Tooltip
```lua
local tip = page:tooltip({ Text = "Help", Target = someGuiObject })
```
Методы: `setText`, `destroy`. Показывается через 220 мс при hover, следует экранным границам.

#### Separator
```lua
page:separator()             -- линия
page:separator({ Text = "OR" }) -- линия с текстом по центру
```
Метод: `destroy`.

#### Grid
```lua
local grid = page:grid({
    Columns = 2,
    Gap = 10,
    CellHeight = 88, -- опционально
    Children = {
        function(cell) cell:card({ Title = "A" }) end,
        { Type = "stat", Label = "B", Value = "2" }, -- альтернативный spec
    },
})
```
Методы: `cell(callback)`, `addCell(callback)`, `destroy`.
`Children` также может быть функцией `function(grid) grid:cell(...) end`.

#### Accordion
```lua
local acc = page:accordion({
    Items = {
        { Title = "One", Icon = "⚡", Expanded = false, Content = function(s) end },
    },
    Exclusive = false,
})
```
Методы: `add(item)`, `destroy`.

#### Row
`page:row(function(r) ... end)` — scope с виджетами; колонки делятся поровну.
Опция `Gap` доступна при прямом вызове `UI.Widgets.row(parent, { Gap = 12, Callback = fn })`.

### Notifications
```lua
local n = UI.Notifications.push({
    Title = "Loaded",
    Text = "UI ready",
    Icon = "check",
    Type = "success", -- info | success | warning | danger
    Duration = 3000,  -- ms; 0 = не закрывать автоматически
})
n:dismiss()
n:destroy()
UI.Notifications.clear()
```
Стек до 5 карточек, новые появляются снизу, старые сдвигаются вверх.
Авто-закрытие использует `task.delay`, ручное — `task.cancel`.

### Modal
```lua
local modal = UI.Modal.new({
    Title = "Confirm",
    Content = function(page)
        page:paragraph("Are you sure?")
    end,
    Actions = {
        { Text = "Cancel", Variant = "secondary" },
        { Text = "Delete", Variant = "danger", OnClick = function(modal) end },
    },
    Width = 540,
    Height = 420,
    CloseOnBackdrop = true,
    OnClose = function() end,
})
```
Методы: `close`, `destroy`, `setTitle`, `getPage`, `isOpen`.
Клик по backdrop и Escape закрывают; карточка перехватывает клики.
`Content` также может быть строкой.

### ContextMenu
```lua
local menu = UI.ContextMenu.attach(target, {
    Width = 198,
    Items = {
        { Text = "Copy", Icon = "⧉", OnClick = function() end },
        { Separator = true },
        { Text = "Delete", Icon = "🗑", Danger = true, OnClick = function() end },
    },
})
```
Методы: `open(positionVector2)`, `close`, `setItems`, `destroy`.
ПКМ по target открывает меню; клик вне и Escape закрывают.

---

## Liquid Glass: как это устроено

Для каждой стеклянной поверхности:

1. Полупрозрачный фон `surface` (Transparency 0.04–0.55 в зависимости от слоя).
2. Внутренний `GlassFX`:
   - белый градиент `Tone` (очень мягкий, 7–2%);
   - accent-wash 2–5%;
   - noise `rbxassetid://9968344106` с `ScaleType.Tile`, `TileSize = 64`;
   - верхний rim 1 px с горизонтальным затуханием;
   - нижняя тёмная кромка 1 px.
3. `UIStroke` 1 px с градиентной прозрачностью.
4. Мягкая цветная тень (3 слоя) у окон, модалок, меню и уведомлений.
5. Скругления 8/12/16/24.
6. Все hover/press/theme-переходы идут через `Animator` (200–250 мс, ease-out-quad).
7. Press — `UIScale = 0.97`; hover — уплотнение фона и усиление rim; focus — accent ring.

Noise asset можно заменить: найдите `9968344106` в `ui_lib.luau`. Если ассет
недоступен/модерирован, слой просто не отрисуется, остальная имитация стекла
продолжит работать. Для зерна используется `ScaleType.Tile`, а не `Slice`:
`Slice` растягивает 9-slice-текстуру и не даёт равномерного grain-эффекта.
Если нужен именно `Slice`, замените `Enum.ScaleType.Tile` на
`Enum.ScaleType.Slice` в `Util.applyGlass` и в backdrop модалки.

---

## Совместимость с экзекьюторами

| API | Поведение |
|---|---|
| `gethui()` | используется, если доступен (Synapse X, Wave, Delta). Если возвращает nil — fallback. |
| `protect_gui` / `syn.protect_gui` | вызываются через `pcall` до parent. |
| `CoreGui` | если доступен; иначе `PlayerGui`. |
| `writefile` | не используется. |
| `task.delay/defer/cancel` | стандартный Roblox `task`; используется для анимаций и уведомлений. |
| `UIStroke`, `UIGradient`, `UICorner` | базовые UI-инстансы; при отсутствии отдельных свойств они ставятся через `pcall`. |
| `TextBox.TextEditable`, `ElasticBehavior`, `LineJoinMode` | опциональные свойства, защищены `pcall`/`Util.make`. |

Ограничения по экзекьюторам:

- **Krnl / Fluxus:** `gethui` может вернуть nil или не разрешить parent в CoreGui.
  Библиотека уйдёт в `PlayerGui`; UI останется рабочим, но некоторые игры
  пересоздают PlayerGui при респавне. `ResetOnSpawn = false` помогает.
- **Synapse X / Wave / Delta:** `gethui` + `protect_gui` дают самый стабильный
  вариант — UI не попадает в `PlayerGui` и не мигает при телепортах/респавне.
- **Mobile-экзекьюторы:** drag окна, slider и colorpicker используют Touch
  (`InputChanged` / `InputEnded`), а не только Mouse.
- **Старые сборки Roblox:** если `TextBox.TextEditable` или `UIStroke.LineJoinMode`
  отсутствуют, соответствующее свойство просто не применится; критичных ошибок нет.

---

## Чеклист первого запуска в экзекьюторе

1. Выполните:
   ```lua
   local UI = loadstring(readfile("ui_lib.luau"))()
   print(type(UI), UI.version)
   ```
   Ожидается `table 1.0.0`.
2. Создайте окно. Проверьте, что оно появилось по центру и не смещено
   относительно topbar (`IgnoreGuiInset = true`).
3. Потяните окно за заголовок; на телефоне — за ту же область пальцем.
   Отпустите палец/мышь за пределами окна — drag должен корректно завершиться.
4. Наведите на кнопку: фон уплотняется, rim светлеет, масштаб мягко меняется.
   Нажмите: масштаб 0.97, затем возврат.
5. Проверьте все темы: `UI.Theme.setMode("light")`, затем `"dark"`,
   `UI.Theme.setAccent(Color3.fromRGB(255, 90, 0))`. Текст и стекло должны
   обновиться без пересоздания окна.
6. Переключите toggle, подвигайте slider (мышь и touch), откройте dropdown,
   выберите пункт, закройте кликом вне. Нажмите keybind и введите клавишу;
   Escape должен отменить захват.
7. В colorpicker подвиньте курсор по HSV-квадрату и hue-полосе, введите
   `#RRGGBB` в hex-поле. Невалидный hex должен откатиться.
8. В textinput введите короткое значение — появится красная рамка и текст
   ошибки; исправьте — ошибка исчезнет.
9. Разверните/сверните секцию, прокрутите страницу колесом и тачем.
   Проверьте, что нижний контент не обрезан.
10. Откройте dropdown: он должен быть поверх окна, следовать за полем при drag
    и закрываться по клику снаружи.
11. Вызовите `UI.Notifications.push` 6 раз подряд. Должно остаться 5 карточек,
    старые исчезают, новые появляются снизу. Дождитесь `Duration` — карточка
    должна закрыться сама; закройте вручную — таймер не должен сработать повторно.
12. Откройте `UI.Modal.new`: backdrop затемняет фон, клик по backdrop/Escape
    закрывает, кнопки действий работают. Проверьте, что клик по самой карточке
    модалку не закрывает.
13. ПКМ по окну: контекстное меню появляется у курсора, не выходит за экран,
    закрывается кликом вне/Escape.
14. Нажмите minimize, затем restore; закройте (close) и снова restore.
    После `win:destroy()` в `CoreGui`/`PlayerGui` не должно остаться
    `UILibWindow`/`UILibPopupLayer`.
15. Убедитесь, что в консоли нет ошибок от `TweenService`, `UIStroke`,
    `TextLabel`, `ScrollingFrame` и `task.cancel`.
16. Если окно не появилось: проверьте `gethui`/`CoreGui` и попробуйте
    принудительно `PlayerGui` (в `Util.createScreenGui` уже есть fallback).
17. Если noise-текстура не видна, проверьте asset `9968344106`; это не ломает
    стекло, но убирает зерно.

---

## Заметки

- `Window:close()` не уничтожает объект: `win:restore()` снова показывает UI.
  Для полной очистки — `win:destroy()`.
- `win:setAccent()` и `win:setTheme()` меняют глобальную тему `UI.Theme`;
  это осознанно, чтобы все окна и компоненты обновлялись синхронно.
- Все пользовательские callback-и оборачиваются в `pcall`. Ошибка показывается
  уведомлением «Action failed», а не роняет UI.
- `UI.Widgets.*` — низкоуровневые фабрики с сигнатурой `(parent, options)`.
  Для обычного использования применяйте методы `Page`/scope.
- В коде нет `print`, `TODO`, `require(script...)` и внешних модулей.
