local DEFAULT_OFFSET_X = 2
local DEFAULT_OFFSET_Y = 2

return {
	Init = function(char_inst: ImageLabel | TextLabel, index, trove, params)
		local offset_x = DEFAULT_OFFSET_X
		local offset_y = DEFAULT_OFFSET_Y
		if params then
			offset_x = tonumber(params[1]) or DEFAULT_OFFSET_X
			offset_y = tonumber(params[2]) or DEFAULT_OFFSET_Y
		end

		local shadow = trove:Add(char_inst:Clone())
		shadow.Name = char_inst.Name .. "_Shadow"
		shadow.Size = char_inst.Size
		shadow.ZIndex = char_inst.ZIndex - 1

		trove:Add(task.defer(function()
			shadow.Position = char_inst.Position
			shadow.Parent = char_inst.Parent
			shadow.Visible = char_inst.Visible
		end))

		if char_inst:IsA("TextLabel") then
			shadow.TextColor3 = Color3.fromRGB(0, 0, 0)
			shadow.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			shadow.TextTransparency = char_inst.TextTransparency
		elseif char_inst:IsA("ImageLabel") then
			shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
			shadow.ImageTransparency = char_inst.ImageTransparency
		end

		char_inst.ZIndex += 1

		-- Keep shadow synced with character visibility even before Update runs
		trove:Add(char_inst:GetPropertyChangedSignal("Visible"):Connect(function()
			shadow.Visible = char_inst.Visible
		end))

		return {
			shadow = shadow,
			offset_x = offset_x,
			offset_y = offset_y,
		}
	end,

	Update = function(char_inst, index, dt, trove, shadow_data)
		local shadow = shadow_data.shadow
		local offset_x = shadow_data.offset_x
		local offset_y = shadow_data.offset_y

		shadow.Visible = char_inst.Visible

		if char_inst:IsA("TextLabel") then
			shadow.TextColor3 = Color3.fromRGB(0, 0, 0)
			shadow.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			shadow.TextTransparency = char_inst.TextTransparency
		elseif char_inst:IsA("ImageLabel") then
			shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
			shadow.ImageTransparency = char_inst.ImageTransparency
		end

		shadow.Position = char_inst.Position + UDim2.fromOffset(offset_x, offset_y)
	end,
}
