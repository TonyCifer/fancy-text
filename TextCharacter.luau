local textservice = game:GetService("TextService")

local Config = require(script.Parent.Config)

local function get_custom_char_data(char: string, font_size: number, custom_font: string)
	local font_data = assert(
		Config.FontsFolder:FindFirstChild(custom_font),
		`[FancyText]: Custom Font: {custom_font} doesn't exist or isn't a module.`
	)

	font_data = require(font_data)

	local char_code = string.byte(char)
	local char_data = font_data.Characters[char_code]
	local o_size = font_data.OriginalSize
	local scale = font_size / o_size

	if char == `\\` or char == "\n" or char == "\r" or char == "\t" then
		return nil
	end

	if not char_data then
		error(`[FancyText]: Tried getting CharacterData for {char_code}; doesn't exist.`)
	end

	if not o_size then
		error(`[FancyText]: FontData for {custom_font} doesn't have an OriginalSize.`)
	end

	if not font_data.Atlas then
		error(`[FancyText]: FontData for {custom_font} doesn't have an Atlas.`)
	end

	return {
		Atlas = font_data.Atlas,
		UnscaledWidth = char_data.width,
		UnscaledHeight = char_data.height,
		Width = char_data.width * scale,
		Height = char_data.height * scale,
		XAdvance = char_data.xadvance * scale,
		XOffset = char_data.xoffset * scale,
		YOffset = char_data.yoffset * scale,
		X = char_data.x,
		Y = char_data.y,
	}
end

local TextCharacter = {}
TextCharacter.__index = TextCharacter

function TextCharacter.new(char: string, config, container: GuiObject)
	local self = setmetatable({}, TextCharacter)

	self._effects = {}
	self._effect_params = {} -- store parameters for each effect
	self._char = char
	self._font_size = config.FontSize
	self._config = config
	self._container = container
	self._instance = nil

	if config.CustomFont then
		self._custom_font_data = get_custom_char_data(char, config.FontSize, config.CustomFont)
	end

	self:_Init()

	return self
end

function TextCharacter:_Init()
	-- newlines and other control characters have zero size
	if self._char == "\n" or self._char == "\r" or self._char == "\t" then
		self._size = Vector2.new(0, 0)
		return
	end

	local custom = self:GetCustomFontData()
	if custom then
		self._size = Vector2.new(custom.Width, custom.Height)
	else
		-- GetTextSize only accepts Enum.Font, not FontFace
		local font = self._config.Font or Enum.Font.SourceSans
		self._size = textservice:GetTextSize(self._char, self._font_size, font, self._container.AbsoluteSize)
	end
end

function TextCharacter:CreateInstance(line_start_x, x_pos, line_height, trove)
	local custom = self:GetCustomFontData()
	local size = self:GetSize()
	local text_color = self._config.TextColor

	if custom then
		self._instance = trove:Add(Instance.new("ImageLabel"))
		self._instance.BackgroundTransparency = 1
		self._instance.Name = self._char
		self._instance.Image = custom.Atlas
		self._instance.ImageColor3 = text_color
		self._instance.Size = UDim2.fromOffset(size.X, size.Y)
		self._instance.ImageRectOffset = Vector2.new(custom.X, custom.Y)
		self._instance.ImageRectSize = Vector2.new(custom.UnscaledWidth, custom.UnscaledHeight)
		self._instance.Position = UDim2.fromOffset(line_start_x + x_pos + custom.XOffset, line_height + custom.YOffset)
		self._instance.Parent = self._container
	else
		self._instance = trove:Add(Instance.new("TextLabel"))
		self._instance.BackgroundTransparency = 1
		self._instance.Name = self._char
		self._instance.Text = self._char
		self._instance.TextSize = self._font_size
		self._instance.TextColor3 = text_color
		self._instance.RichText = true
		self._instance.Size = UDim2.fromOffset(size.X, size.Y)
		self._instance.Position = UDim2.fromOffset(line_start_x + x_pos, line_height)
		self._instance.TextStrokeTransparency = self._config.TextStrokeTransparency
		self._instance.TextStrokeColor3 = self._config.TextStrokeColor
		self._instance.TextTransparency = self._config.TextTransparency

		if self._config.Font then
			self._instance.Font = self._config.Font
		elseif self._config.FontFace then
			self._instance.FontFace = self._config.FontFace
		end

		if self._config.TextSizeConstraint then
			local constraint = Instance.new("UITextSizeConstraint")
			constraint.MinTextSize = self._config.TextSizeConstraint[1]
			constraint.MaxTextSize = self._config.TextSizeConstraint[2]
			constraint.Parent = self._instance
		end

		self._instance.Parent = self._container
	end
end

function TextCharacter:AddEffect(effect_name, params)
	table.insert(self._effects, effect_name)
	self._effect_params[effect_name] = params or {}
end

function TextCharacter:GetEffects()
	return self._effects
end

function TextCharacter:GetEffectParams(effect_name)
	return self._effect_params[effect_name]
end

function TextCharacter:GetChar()
	return self._char
end

function TextCharacter:GetInstance()
	return self._instance
end

function TextCharacter:GetSize()
	return self._size
end

function TextCharacter:GetCustomFontData()
	return self._custom_font_data
end

return TextCharacter
