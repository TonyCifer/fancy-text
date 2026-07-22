-- One-shot pop: each character jumps in a random direction (+ a bit of rotation)
-- and springs back to rest. Meant for PlayEffect(...) triggers from button clicks.
-- Init reports { delay, duration } so callers can pass auto_clean = true and let
-- FancyText clean the trove once every character has settled.

local TweenService = game:GetService("TweenService")

local DEFAULT_DISTANCE = 12 -- pixels of initial displacement
local DEFAULT_ROTATION = 18 -- max degrees of initial spin
local DEFAULT_DURATION = 0.35
local STAGGER = 0.02 -- per-character delay for a wave feel

local TWEEN_INFO = TweenInfo.new(
	DEFAULT_DURATION,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

local rng = Random.new()

return {
	Init = function(char_inst: TextLabel, index, trove, params)
		local distance = (params and tonumber(params[1])) or DEFAULT_DISTANCE
		local rotation = (params and tonumber(params[2])) or DEFAULT_ROTATION
		local duration = (params and tonumber(params[3])) or DEFAULT_DURATION

		local orig_pos = char_inst:GetAttribute("OrigPos") or char_inst.Position
		local orig_rot = char_inst.Rotation

		local angle = rng:NextNumber(0, math.pi * 2)
		local offset = Vector2.new(math.cos(angle), math.sin(angle)) * distance
		local spin = rng:NextNumber(-rotation, rotation)

		local delay = index * STAGGER

		char_inst.Position = orig_pos + UDim2.fromOffset(offset.X, offset.Y)
		char_inst.Rotation = orig_rot + spin

		local info = if duration == DEFAULT_DURATION
			then TWEEN_INFO
			else TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		task.delay(delay, function()
			if not char_inst.Parent then
				return
			end
			TweenService:Create(char_inst, info, {
				Position = orig_pos,
				Rotation = orig_rot,
			}):Play()
		end)

		return {
			delay = delay,
			duration = duration,
		}
	end,

	Update = function() end, -- tween-driven; nothing to do per frame
}
