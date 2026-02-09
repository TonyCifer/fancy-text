local TextLayoutManager = require(script.Parent.TextLayoutManager)
local TextCharacter = require(script.Parent.TextCharacter)
local IconCharacter = require(script.Parent.IconCharacter)
local EffectParser = require(script.Parent.EffectParser)
local Util = require(script.Parent.Dependencies.Util)

local TextRenderer = {}
TextRenderer.__index = TextRenderer

function TextRenderer.new(container, config, text, trove)
	local self = setmetatable({}, TextRenderer)

	self._container = container
	self._config = config
	self._text = text
	self._trove = trove

	self._characters = {}
	self._effect_args = {}
	self._global_char_index = 0

	self:_Init()

	return self
end

function TextRenderer:_Init()
	for c in string.gmatch(self._text, ".") do
		table.insert(self._characters, TextCharacter.new(c, self._config, self._container))
	end

	if self._config.Scale then
		local scale = self._trove:Add(Instance.new("UIScale"))
		scale.Scale = Util.GetUIScale()
		scale.Parent = self._container
	end

	local parser = EffectParser.new(self._characters)

	parser:RegisterTagCallback("icon", function(args, is_opening)
		if #args == 0 then
			warn("[FancyText]: <icon> tag requires an icon name argument")
			return nil
		end

		local icon_name = args[1]
		return { IconCharacter.new(icon_name, self._config, self._container) }
	end)

	parser:Parse()
end

function TextRenderer:Render()
	-- wait for container to have valid size if using alignment
	self._trove:Add(task.spawn(function()
		if self._config.TextAlign and (self._config.TextAlign == "Center" or self._config.TextAlign == "Right") then
			while self._container.AbsoluteSize.X == 0 and self._container.AbsoluteSize.Y == 0 do
				task.wait()
			end
		end

		local ui_scale = self._config.Scale and Util.GetUIScale() or 1
		local layout_mgr =
			TextLayoutManager.new(self._characters, self._container, self._config.CustomFont ~= nil, ui_scale)

		layout_mgr:Init(function(...)
			self:_FlushLine(...)
		end)
	end))
end

function TextRenderer:_FlushLine(chars_to_render, line_width, line_height)
	if #chars_to_render == 0 then
		return
	end

	-- left alignment uses 0 (default)
	local line_start_x = 0

	if self._config.TextAlign == "Center" then
		if self._config.CustomFont then
			local container_width = self._config.Scale and (self._container.AbsoluteSize.X / Util.GetUIScale())
				or self._container.AbsoluteSize.X

			line_start_x = math.max(0, (container_width - line_width) / 2)
		else
			line_start_x = math.max(0, (self._container.AbsoluteSize.X - line_width) / 2)
		end
	elseif self._config.TextAlign == "Right" then
		if self._config.CustomFont then
			local container_width = self._config.Scale and (self._container.AbsoluteSize.X / Util.GetUIScale())
				or self._container.AbsoluteSize.X

			line_start_x = math.max(0, container_width - line_width)
		else
			line_start_x = math.max(0, self._container.AbsoluteSize.X - line_width)
		end
	end

	for i, char_line_data in chars_to_render do
		local char_obj = char_line_data.CharObj
		local x_pos = char_line_data.XPos

		char_obj:CreateInstance(line_start_x, x_pos, line_height, self._trove)

		self._global_char_index += 1

		for _, effect_name in char_obj:GetEffects() do
			local effect_module = Util.GetEffectModule(effect_name)
			if not effect_module then
				continue
			end

			if effect_module.Init then
				if not self._effect_args[effect_name] then
					self._effect_args[effect_name] = {}
				end

				local char_inst = char_obj:GetInstance()
				local params = char_obj:GetEffectParams(effect_name)

				self._effect_args[effect_name][char_inst] =
					effect_module.Init(char_inst, self._global_char_index, self._trove, params)
			end
		end
	end
end

function TextRenderer:Update(dt)
	for i, char_obj in self._characters do
		local instance = char_obj:GetInstance()

		-- if up to 3 parent's up are visible, continue
		if not instance or not Util.GuiObjectIsVisible(instance, 3) then
			continue
		end

		for _, effect_name in char_obj:GetEffects() do
			local effect_module = Util.GetEffectModule(effect_name)
			if not effect_module then
				continue
			end

			if not self._effect_args[effect_name] then
				self._effect_args[effect_name] = {}
			end

			if effect_module.Update then
				local params = char_obj:GetEffectParams(effect_name)
				effect_module.Update(instance, i, dt, self._trove, self._effect_args[effect_name][instance], params)
			end
		end
	end
end

return TextRenderer
