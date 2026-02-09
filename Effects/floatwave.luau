local WAVE_AMP = 2
local WAVE_FREQ = 2.5
local WAVE_SPACING = 1

return {
	Init = function(char_inst: TextLabel, index, trove)
		char_inst:SetAttribute("OrigPos", char_inst.Position)
		char_inst:SetAttribute("CharIndex", index)
	end,

	Update = function(char_inst: TextLabel, dt)
		local orig_pos = char_inst:GetAttribute("OrigPos")
		local char_index = char_inst:GetAttribute("CharIndex")
		
		local sine = math.sin((tick() * WAVE_FREQ) + (char_index * WAVE_SPACING))
		local cos = math.cos((tick() * WAVE_FREQ) + (char_index * WAVE_SPACING))
		local x_offset = cos * (WAVE_AMP * 0.5)
		local y_offset = sine * WAVE_AMP
		char_inst.Position = UDim2.fromOffset(orig_pos.X.Offset + x_offset, orig_pos.Y.Offset + y_offset)
	end
}