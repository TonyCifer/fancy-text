local SHAKE_SPEED = 35

local rng = Random.new()

local shake_data = setmetatable({}, { __mode = "k" })

return {
	Init = function(char_inst, index, trove)
		shake_data[char_inst] = {
			o_pos = char_inst.Position,
			shake_timer = 0,
		}

		trove:Add(function()
			shake_data[char_inst] = nil
		end)
	end,

	Update = function(char_inst, index, dt, trove)
		local data = shake_data[char_inst]
		if not data then
			return
		end

		data.shake_timer += dt

		if data.shake_timer < (1 / SHAKE_SPEED) then
			return
		end

		data.shake_timer = 0

		local random_x = rng:NextInteger(-1, 1)
		local random_y = rng:NextInteger(-1, 1)
		char_inst.Position = UDim2.fromOffset(data.o_pos.X.Offset + random_x, data.o_pos.Y.Offset + random_y)
	end,
}

