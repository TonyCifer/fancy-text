local TextLayoutManager = require(script.Parent.TextLayoutManager)
local TextCharacter = require(script.Parent.TextCharacter)
local IconCharacter = require(script.Parent.IconCharacter)
local EffectParser = require(script.Parent.EffectParser)
local Util = require(script.Parent.Dependencies.Util)

local RESIZE_DEBOUNCE_TIME = 0.2 -- seconds to wait after the last resize before re-laying out

local TextRenderer = {}
TextRenderer.__index = TextRenderer

function TextRenderer.new(container, config, text, trove)
	local self = setmetatable({}, TextRenderer)

	self._container = container
	self._config = config
	self._text = text
	self._trove = trove

	-- Everything created by a layout pass (character instances, effect Init state)
	-- lives in its own sub-trove so a resize can Clean() and rebuild it without
	-- touching the structural stuff (UIScale, resize connections) in self._trove.
	self._render_trove = trove:Extend()

	self._characters = {}
	self._effect_args = {}
	self._global_char_index = 0

	-- Flat list of pending effect updates, rebuilt each layout pass. Update()
	-- iterates this instead of walking every character's effect list per frame,
	-- so characters with no effects cost nothing at runtime.
	self._update_list = {}

	self:_Init()

	return self
end

function TextRenderer:_Init()
	for c in string.gmatch(self._text, ".") do
		table.insert(self._characters, TextCharacter.new(c, self._config, self._container))
	end

	if self._config.Scale then
		local inner = self._trove:Add(Instance.new("Frame"))
		inner.Size = UDim2.fromScale(1, 1)
		inner.BackgroundTransparency = 1
		inner.Parent = self._container

		local scale = self._trove:Add(Instance.new("UIScale"))
		scale.Scale = Util.GetUIScale()
		scale.Parent = inner

		self._render_container = inner
		self._ui_scale = scale
	end

	local parser = EffectParser.new(self._characters)

	parser:RegisterTagCallback("icon", function(args, is_opening)
		if #args == 0 then
			warn("[FancyText]: <icon> tag requires an icon name argument")
			return nil
		end

		local icon_name = args[1]
		local y_offset = tonumber(args[2])
		return { IconCharacter.new(icon_name, self._config, self._container, y_offset) }
	end)

	parser:Parse()

	-- Only resolve font data/sizing for characters that survived parsing (i.e. are
	-- actually going to be rendered) - see TextCharacter:Resolve for why this can't
	-- happen eagerly in TextCharacter.new.
	for _, char_obj in self._characters do
		if char_obj.Resolve then
			char_obj:Resolve()
		end
	end
end

function TextRenderer:Render()
	-- wait for container to have valid size if using alignment
	self._trove:Add(task.spawn(function()
		if
			(self._config.TextAlign and (self._config.TextAlign == "Center" or self._config.TextAlign == "Right"))
			or (
				self._config.VerticalAlign
				and (self._config.VerticalAlign == "Center" or self._config.VerticalAlign == "Bottom")
			)
		then
			while self._container.AbsoluteSize.X == 0 and self._container.AbsoluteSize.Y == 0 do
				self._container:GetPropertyChangedSignal("AbsoluteSize"):Wait()
			end
		end

		self:_Layout()
		self:_ListenForResize()
	end))
end

-- Lays out (or re-lays-out) all characters: recomputes the UIScale factor, re-wraps
-- lines against the container's current size, and repositions/recreates character
-- instances. Safe to call multiple times - each call cleans up the previous pass's
-- instances and effect state via self._render_trove before rebuilding.
function TextRenderer:_Layout()
	local ui_scale = self._config.Scale and Util.GetUIScale() or 1
	local container_size = self._container.AbsoluteSize

	-- Recreating instances below can itself change the container's AbsoluteSize
	-- (e.g. if it has AutomaticSize enabled), which would re-fire the resize
	-- listener that called us. Skip the reflow if nothing actually changed since
	-- the last layout so that settles into a no-op instead of looping forever.
	if self._last_layout_size == container_size and self._last_layout_scale == ui_scale then
		return
	end
	self._last_layout_size = container_size
	self._last_layout_scale = ui_scale

	self._render_trove:Clean()
	self._effect_args = {}
	self._global_char_index = 0
	table.clear(self._update_list)

	-- Effects receive the character's index in self._characters (not the rendered
	-- index) - precompute it once per layout so _FlushLine doesn't have to search.
	self._char_index = {}
	for i, char_obj in self._characters do
		self._char_index[char_obj] = i
	end

	if self._ui_scale then
		self._ui_scale.Scale = ui_scale
		-- Compensate the render container so its rendered size equals the
		-- label exactly: a fromScale(1,1) frame under a UIScale > 1 inflates
		-- AutomaticSize ancestors in a runaway feedback loop (label grows →
		-- inner grows → label grows), which pushed text off-center above 1080p.
		self._render_container.Size = UDim2.fromScale(1 / ui_scale, 1 / ui_scale)
	end

	-- Effect Inits must not run until after the vertical offset below is applied,
	-- or they capture pre-offset positions (e.g. shake's o_pos). _FlushLine only
	-- queues them here; they run at the end of this layout pass.
	self._pending_inits = {}

	local layout_mgr =
		TextLayoutManager.new(self._characters, self._container, self._config.CustomFont ~= nil, ui_scale)

	local total_height = layout_mgr:Init(function(...)
		self:_FlushLine(...)
	end)

	-- Calculate and apply vertical offset
	local vertical_offset = 0
	if self._config.VerticalAlign == "Center" then
		local container_height = self._config.Scale and (self._container.AbsoluteSize.Y / ui_scale)
			or self._container.AbsoluteSize.Y
		vertical_offset = math.max(0, (container_height - total_height) / 2)
	elseif self._config.VerticalAlign == "Bottom" then
		local container_height = self._config.Scale and (self._container.AbsoluteSize.Y / ui_scale)
			or self._container.AbsoluteSize.Y
		vertical_offset = math.max(0, container_height - total_height)
	end

	-- Apply vertical offset (before effect Inits run, so they see final positions)
	if vertical_offset > 0 then
		for _, char_obj in self._characters do
			local instance = char_obj:GetInstance()
			if instance then
				instance.Position = instance.Position + UDim2.fromOffset(0, vertical_offset)
			end
		end
	end

	-- Now run the effect Inits queued by _FlushLine
	for _, pending in self._pending_inits do
		local effect_module = pending.effect_module
		local char_inst = pending.char_inst

		if effect_module.Init then
			local effect_name = pending.effect_name
			if not self._effect_args[effect_name] then
				self._effect_args[effect_name] = {}
			end

			self._effect_args[effect_name][char_inst] = effect_module.Init(
				char_inst,
				pending.global_index,
				self._render_trove,
				pending.char_obj:GetEffectParams(effect_name)
			)
		end

		if effect_module.Update then
			table.insert(self._update_list, {
				instance = char_inst,
				char_obj = pending.char_obj,
				effect_name = pending.effect_name,
				update = effect_module.Update,
				index = self._char_index[pending.char_obj],
			})
		end
	end
end

-- Re-runs _Layout() whenever the viewport changes (window resize, device rotation,
-- split-screen, etc.), debounced so a burst of resize events only triggers one
-- reflow after things settle. Deliberately does NOT listen to the container's own
-- AbsoluteSize - recreating instances can itself change a container's AbsoluteSize
-- (e.g. if it has AutomaticSize enabled), which turned into a self-triggering loop.
-- ViewportSize only changes for genuine external reasons (resize/rotate/etc.), so
-- it can't be fed back into by our own writes.
function TextRenderer:_ListenForResize()
	local reflow_pending = false
	local alive = true

	self._trove:Add(function()
		alive = false
	end)

	local function request_reflow()
		if reflow_pending then
			return
		end
		reflow_pending = true

		task.delay(RESIZE_DEBOUNCE_TIME, function()
			reflow_pending = false
			if alive then
				self:_Layout()
			end
		end)
	end

	-- workspace.CurrentCamera can be swapped out (e.g. by camera scripts), so
	-- re-hook ViewportSize whenever that happens rather than assuming it's stable.
	local camera_conn = nil
	local function hook_camera()
		if camera_conn then
			camera_conn:Disconnect()
		end

		local cam = workspace.CurrentCamera
		if cam then
			camera_conn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(request_reflow)
		end
	end

	hook_camera()
	self._trove:Add(function()
		if camera_conn then
			camera_conn:Disconnect()
		end
	end)
	self._trove:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), hook_camera)
end

function TextRenderer:_FlushLine(chars_to_render, line_width, line_height)
	if #chars_to_render == 0 then
		return
	end

	-- left alignment uses 0 (default)
	local line_start_x = 0

	local container_width = self._config.Scale and (self._container.AbsoluteSize.X / Util.GetUIScale())
		or self._container.AbsoluteSize.X

	if self._config.TextAlign == "Center" then
		line_start_x = (container_width - line_width) / 2
	elseif self._config.TextAlign == "Right" then
		line_start_x = math.max(0, container_width - line_width)
	end

	for i, char_line_data in chars_to_render do
		local char_obj = char_line_data.CharObj
		local x_pos = char_line_data.XPos

		char_obj:CreateInstance(line_start_x, x_pos, line_height, self._render_trove, self._render_container)

		self._global_char_index += 1

		for _, effect_name in char_obj:GetEffects() do
			local effect_module = Util.GetEffectModule(effect_name)
			if not effect_module then
				continue
			end

			table.insert(self._pending_inits, {
				effect_module = effect_module,
				effect_name = effect_name,
				char_obj = char_obj,
				char_inst = char_obj:GetInstance(),
				global_index = self._global_char_index,
			})
		end
	end
end

-- Manually triggers an effect on all currently rendered characters right now, instead of
-- waiting on a tag-driven delay - e.g. call this from a button's click handler to start an
-- exit transition on demand. Runs the effect's Init immediately and registers it on each
-- character so the normal Update loop above carries the tween forward from here.
--
-- If auto_clean is true and the effect's Init returns numeric `delay`/`duration` fields
-- (as fall/fade already do), the whole trove (the same one MakeText/FromLabel returned)
-- is automatically cleaned once every character's transition should be finished.
function TextRenderer:PlayEffect(effect_name: string, params: { string }?, auto_clean: boolean?)
	local effect_module = Util.GetEffectModule(effect_name)
	if not effect_module then
		warn(`[FancyText]: Can't find effect module: {effect_name}`)
		return
	end

	if not self._effect_args[effect_name] then
		self._effect_args[effect_name] = {}
	end

	local max_end_time = 0
	local has_estimate = false

	for i, char_obj in self._characters do
		local char_inst = char_obj:GetInstance()
		if not char_inst then
			continue
		end

		char_obj:AddEffect(effect_name, params or {})

		if effect_module.Init then
			local data = effect_module.Init(char_inst, i, self._render_trove, params or {})
			self._effect_args[effect_name][char_inst] = data

			if type(data) == "table" and type(data.delay) == "number" and type(data.duration) == "number" then
				has_estimate = true
				max_end_time = math.max(max_end_time, data.delay + data.duration)
			end
		end

		if effect_module.Update then
			table.insert(self._update_list, {
				instance = char_inst,
				char_obj = char_obj,
				effect_name = effect_name,
				update = effect_module.Update,
				index = i,
			})
		end
	end

	if auto_clean then
		if has_estimate then
			task.delay(max_end_time, function()
				self._trove:Clean()
			end)
		else
			warn(`[FancyText]: Can't auto-clean - effect '{effect_name}' doesn't report delay/duration`)
		end
	end
end

function TextRenderer:Update(dt)
	if #self._update_list == 0 then
		return
	end

	-- All characters share the container's ancestor chain, so check it once per
	-- renderer instead of walking up to 10 parents per character per frame.
	if not Util.GuiObjectIsVisible(self._container, 10) then
		return
	end

	for _, entry in self._update_list do
		local instance = entry.instance

		if not instance or instance.Visible == false then
			continue
		end

		local args_bucket = self._effect_args[entry.effect_name]
		entry.update(
			instance,
			entry.index,
			dt,
			self._render_trove,
			args_bucket and args_bucket[instance],
			entry.char_obj:GetEffectParams(entry.effect_name)
		)
	end
end

return TextRenderer
