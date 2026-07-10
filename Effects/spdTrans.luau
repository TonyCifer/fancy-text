local MIN_SPEED = 3
local DISPLAY_DELAY = 3

local SPRING_SPEED = 7
local SPRING_DAMPER = 0.8

local RunService = game:GetService("RunService")

return {
	Init = function(char_inst: TextLabel, index, trove)
		local player = game.Players.LocalPlayer
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		-- only do this Init once for the entire Text
		if not (index == 1) then
			return
		end

		local spring = _G.Spring.new(0)
		spring.Speed = SPRING_SPEED
		spring.Damper = SPRING_DAMPER

		local time_still = 0

		trove:Add(RunService.RenderStepped:Connect(function(dt)
			local speed = hrp.AssemblyLinearVelocity.Magnitude
			if speed <= MIN_SPEED then
				time_still += dt

				if time_still >= DISPLAY_DELAY then
					time_still = 0
					spring.Target = 0
				end
			else
				time_still = 0
				spring.Target = 1
			end

			char_inst.Parent:SetAttribute("TimeIdle", spring.Position)
		end))

		trove:Add(function()
			if char_inst.Parent then
				char_inst.Parent:SetAttribute("TimeIdle", nil)
			end
		end)
	end,

	Update = function(char_inst, index, dt, trove, spring)
		local target = char_inst.Parent:GetAttribute("TimeIdle") or 1

		if char_inst:IsA("ImageLabel") then
			char_inst.ImageTransparency = target
		else
			char_inst.TextTransparency = target
		end
	end,
}
