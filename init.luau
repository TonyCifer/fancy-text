local RunService = game:GetService("RunService")

local Util = require(script.Dependencies.Util)
local Trove = require(script.Dependencies.Trove)
local TextRenderer = require(script.TextRenderer)

local Config = require(script.Config)
export type Config = Config.Config

local FancyText = {}

function FancyText.MakeText(container: GuiObject, text: string, config: Config?): Trove.Trove
	assert(container and container:IsA("GuiObject"), "[FancyText]: First argument must be a GuiObject.")
	assert(text and type(text) == "string" or text == "", "[FancyText]: Second argument must be a non-empty string.")

	local succ, valid_config = pcall(function()
		return Util.ValidateConfig(config)
	end)

	if not succ then
		warn(`[FancyText]: Config invalid: {valid_config}`)
		return
	end

	local trove = Trove.new()

	local text_renderer = TextRenderer.new(container, valid_config, text, trove)
	text_renderer:Render()

	trove:Add(RunService.RenderStepped:Connect(function(dt)
		text_renderer:Update(dt)
	end))

	return trove
end

function FancyText.GetTextLengthWithoutTags(msg: string): number
	return string.len(string.gsub(msg, "<.->", ""))
end

function FancyText.GetTextWithoutTags(msg: string): string
	return string.gsub(msg, "<.->", "")
end

return FancyText
