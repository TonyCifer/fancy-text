# FancyText

A powerful and flexible text rendering module for Roblox that supports custom fonts, text effects, inline icons, and rich formatting through BBCode-style tags. Perfect for creating dynamic UI text with animations, colors, and special effects.

## Features

- [x] **Custom Fonts** - Import TTF fonts using TTFToRoblox
- [x] **Built-in Fonts** - Support for Roblox Enum.Font and FontFace
- [x] **Text Effects** - 11+ built-in effects (shake, wave, rainbow, typewriter, etc.)
- [x] **Inline Icons** - Embed ImageLabels within text
- [x] **Text Alignment** - Left, Right, and Center alignment
- [x] **UI Scaling** - Automatic scaling relative to 1920x1080
- [x] **Word Wrapping** - Intelligent word wrapping with custom fonts
- [x] **BBCode Tags** - Toggle effects on/off with `<effect>` tags
- [x] **Extensible** - Easy to create custom effects
- [ ] Improved performance optimizations

## Demo

```lua
local FancyText = require(path.to.FancyText)

-- Simple text with effects
local config = {
    FontSize = 30,
    TextColor = Color3.fromRGB(255, 255, 255),
    TextAlign = "Center",
}

local trove = FancyText.MakeText(
    container,
    "Hello <rainbow>World<rainbow>!",
    config
)

-- Clean up when done
trove:Destroy()
```

## Built-in Effects

- `rainbow` - Animated rainbow color cycling
- `shake` - Random character shaking
- `wave` - Sine wave motion
- `floatwave` - Floating wave motion
- `jitter` - Random jittering
- `col R G B` - Set text color (RGB 0-255) e.g. <col 255 255 255>
- `typewrite` - Typewriter reveal effect
- More effects in the Effects folder

## Icons

If you want to use inline icons with `<icon>` tags:

```lua
local config = {
    FontSize = 30,
    IconsFolder = game.ReplicatedStorage.Assets.Icons, -- Folder containing ImageLabels
}

local trove = FancyText.MakeText(
    container,
    "Collect <icon Coin> coins!",
    config
)
```

## Importing Custom Fonts with TTFToRoblox

FancyText supports custom TTF fonts through the TTFToRoblox tool, which converts TrueType fonts into bitmap atlases that Roblox can render.

### Step 1: Convert Your Font

1. Place your `.ttf` font file in the same directory as `TTFToRoblox.exe`
2. Run the executable and select your font file, or drag-and-drop your TTF file onto `TTFToRoblox.exe`
3. The tool will generate two files:
   - `yourfont.png` - Atlas texture containing all characters
   - `yourfont.lua` - Character metadata (positions, sizes, offsets)

**How it works:**

- TTFToRoblox uses BMFont to rasterize the TTF font at 64px size
- Characters 32-126 (printable ASCII) are rendered to a 2048x2048 PNG atlas
- A Lua module is generated with character metrics (x, y, width, height, offsets, advance)

### Step 3: Upload to Roblox

1. Upload `yourfont.png` to Roblox as an Image asset
2. Copy the asset ID (e.g., `rbxassetid://1234567890`)
3. Open `yourfont.lua` and replace `"rbxassetid://0"` with your asset ID:

```lua
return {
    Atlas = "rbxassetid://1234567890", -- Your uploaded image ID
    OriginalSize = 64,
    Characters = {
        -- Character data...
    }
}
```

### Step 4: Add to FancyText

1. Place `yourfont.lua` (or rename it) into the `FancyText/Fonts/` folder
2. Use it in your config:

```lua
local config = {
    CustomFont = "yourfont", -- Name of the module in Fonts folder
    FontSize = 30,
}

local trove = FancyText.MakeText(container, "Custom Font Text!", config)
```

## Creating Custom Effects

Effects are modular Lua files in the `Effects/` folder. Each effect can have `Init` and/or `Update` functions:

```lua
-- Effects/MyEffect.luau
local MyEffect = {}

-- Called once per character when effect is first applied
function MyEffect.Init(char_instance: GuiObject, char_index: number, trove, params: {string})
    -- params are any arguments passed after effect name
    -- Example: <myeffect arg1 arg2> → params = {"arg1", "arg2"}

    -- Return data to persist between Update calls
    return {
        start_time = tick()
    }
end

-- Called every frame while character is visible
function MyEffect.Update(char_instance: GuiObject, char_index: number, dt: number, trove, effect_data, params: {string})
    -- effect_data is what Init returned
    -- Modify char_instance properties here

    local elapsed = tick() - effect_data.start_time
    char_instance.Position = char_instance.Position + UDim2.fromOffset(0, math.sin(elapsed * 5) * 2)
end

return MyEffect
```

**Tips:**

- Use `char_index` to create cascading/staggered effects
- Store state in the returned table from `Init`
- `dt` is delta time in seconds (for frame-rate independent animations)
- Use `params` to make effects configurable via tags: `<shake 10>` → `params = {"10"}`

## API Reference

### FancyText.MakeText

```lua
FancyText.MakeText(
    container: GuiObject,
    text: string,
    config: Config?
) -> Trove
```

Creates and renders text with effects in the specified container.

**Parameters:**

- `container` - GuiObject to render text into
- `text` - Text string with optional BBCode-style tags
- `config` - Configuration table (optional, uses defaults if nil)

**Returns:**

- `Trove` - Trove object for cleanup (call `:Destroy()` when done)

### FancyText.GetTextWithoutTags

```lua
FancyText.GetTextWithoutTags(text: string) -> string
```

Strips all tags from text and returns plain text.

```lua
local plain = FancyText.GetTextWithoutTags("Hello <rainbow>World<rainbow>!")
-- Returns: "Hello World!"
```

### FancyText.GetTextLengthWithoutTags

```lua
FancyText.GetTextLengthWithoutTags(text: string) -> number
```

Returns the length of text excluding tags.

```lua
local length = FancyText.GetTextLengthWithoutTags("Hello <shake>World<shake>!")
-- Returns: 12
```

## License

This project is open source and available for use in your Roblox projects.
