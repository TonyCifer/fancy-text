-- FancyText showcase: one row per effect, plus a PlayEffect lifecycle demo.
-- Drop this in StarterPlayerScripts (LocalScript) with FancyText in ReplicatedStorage.
--
-- Tag syntax: effects toggle - <wave>on<wave> off. Params are space-separated: <col 255 170 0>.
-- Escapes: \n (literal backslash-n) or a real newline both break lines.

local Players = game:GetService("Players")
local FancyText = require(game.ReplicatedStorage:WaitForChild("FancyText"))

local sg = Instance.new("ScreenGui")
sg.Name = "FancyTextShowcase"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0, 640, 1, -20)
scroll.Position = UDim2.fromOffset(10, 10)
scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
scroll.BackgroundTransparency = 0.15
scroll.ScrollBarThickness = 6
scroll.Parent = sg

local rows = {
	-- looping motion
	{ "wave",         "<wave>Riding the wave<wave>" },
	{ "floatwave",    "<floatwave>gentle floating drift<floatwave>" },
	{ "jitter",       "<jitter>nervous jittery text<jitter>" },
	{ "shake",        "<shake>SHAKING!<shake> and <shake 20 3>harder!<shake>" }, -- <shake speed intensity>
	{ "flicker",      "<flicker>br0ken n3on s1gn<flicker>" },
	-- looping color
	{ "rainbow",      "<rainbow>taste the rainbow<rainbow>" },
	{ "demonic",      "<demonic>YOU SHOULDN'T BE HERE<demonic>" }, -- <demonic speed min max>
	-- static styling
	{ "b (bold)",     "normal vs <b>bolder<b> text" },
	{ "col",          "<col 255 170 0>orange<col> and <col 0 200 255>cyan<col>" }, -- <col r g b>
	{ "shadow",       "<shadow 3 3 120 0 200>purple drop shadow<shadow>" }, -- <shadow ox oy r g b>
	{ "gradient",     "<gradient 0.5 255 60 60>half red gradient<gradient>" }, -- <gradient percent r g b [ar ag ab] [flip]>
	{ "gradientWave", "<gradientWave 0.6 60 120 255>shimmer sweep<gradientWave>" },
	-- entrances
	{ "typewrite",    "<typewrite>typed in one by one...<typewrite>" }, -- <typewrite speed>
	{ "fi (fade-in)", "<fi 0.5>fades & falls into place<fi>" }, -- <fi delay_seconds>
	-- stacking + layout
	{ "combo",        "<shadow 2 2><wave><rainbow>ALL AT ONCE<rainbow><wave><shadow>" },
	{ "multiline",    "line one\\n<wave><col 255 120 180>line two waving<col><wave>" },
	-- also available: <icon name [y_offset]> - needs Config.IconsFolder set to a folder of ImageLabels
}

local ROW_H = 52
for i, row in rows do
	local name, text = row[1], row[2]

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(120, ROW_H)
	label.Position = UDim2.fromOffset(8, (i - 1) * ROW_H)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(130, 130, 140)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.Text = name
	label.Parent = scroll

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -140, 0, ROW_H)
	holder.Position = UDim2.fromOffset(132, (i - 1) * ROW_H)
	holder.BackgroundTransparency = 1
	holder.Parent = scroll

	FancyText.MakeText(holder, text, { FontSize = 24, TextAlign = "Left", VerticalAlign = "Center", Scale = false })
end

-- Lifecycle: MakeText returns a trove; trove:PlayEffect(name, params, auto_clean)
-- triggers an effect on demand. fall/fade/clickpop report delay+duration, so
-- auto_clean = true destroys everything once the exit transition finishes.
local life_label = Instance.new("TextLabel")
life_label.Size = UDim2.fromOffset(120, ROW_H)
life_label.Position = UDim2.fromOffset(8, #rows * ROW_H)
life_label.BackgroundTransparency = 1
life_label.TextColor3 = Color3.fromRGB(130, 130, 140)
life_label.TextXAlignment = Enum.TextXAlignment.Left
life_label.Font = Enum.Font.Code
life_label.TextSize = 14
life_label.Text = "PlayEffect"
life_label.Parent = scroll

local life = Instance.new("Frame")
life.Size = UDim2.new(1, -140, 0, ROW_H)
life.Position = UDim2.fromOffset(132, #rows * ROW_H)
life.BackgroundTransparency = 1
life.Parent = scroll

task.spawn(function()
	while life.Parent do
		local trove = FancyText.MakeText(life, "<typewrite><col 120 255 120>enter... then PlayEffect('fall')<col><typewrite>",
			{ FontSize = 22, TextAlign = "Left", VerticalAlign = "Center", Scale = false })
		task.wait(3.5)
		if trove then trove:PlayEffect("fall", nil, true) end
		task.wait(1.8)
	end
end)

scroll.CanvasSize = UDim2.fromOffset(0, (#rows + 1) * ROW_H + 10)
