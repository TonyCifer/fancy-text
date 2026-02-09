local TweenService = game:GetService("TweenService")

local TYPEWRITE_SPEED = 0.02 -- Multiplier (0 - 1]
local DROP_AMT = -10 -- How much it drops down on init
local GROW_AMT = 15 -- How much it grows then shrinks on init

return {
	Init = function(char_inst, index, trove)
		local o_pos = char_inst:GetAttribute("OrigPos") or char_inst.Position
		local o_size;
		if char_inst:IsA("TextLabel") then
			o_size = char_inst.TextSize
			char_inst.TextSize += GROW_AMT
			char_inst.TextTransparency = 1
		elseif char_inst:IsA("ImageLabel") then
			char_inst.ImageTransparency = 1
		end

		char_inst.Visible = false

		trove:Add(task.delay(index * TYPEWRITE_SPEED, function()
			char_inst.Position = char_inst.Position + UDim2.fromOffset(0, DROP_AMT)
			char_inst.Visible = true

			if char_inst:IsA("TextLabel") then
				TweenService:Create(char_inst, TweenInfo.new(0.5), {
					TextSize = o_size,
					Position = o_pos, 
					TextTransparency = 0
				}):Play()
			elseif char_inst:IsA("ImageLabel") then
				TweenService:Create(char_inst, TweenInfo.new(0.5), {
					Position = o_pos, 
					ImageTransparency = 0
				}):Play()
			end
		end))
	end,
}
