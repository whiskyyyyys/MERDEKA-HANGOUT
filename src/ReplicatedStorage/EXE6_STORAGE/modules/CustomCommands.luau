local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")
local tween_service = game:GetService("TweenService")
local user_service = game:GetService("UserService")

local fast = TweenInfo.new(.25, Enum.EasingStyle.Exponential)
local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(1, Enum.EasingStyle.Exponential)

local two = TweenInfo.new(1.5, Enum.EasingStyle.Exponential)
local two_delay = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
local two_rev = TweenInfo.new(.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true)

local client = players.LocalPlayer
local storage = replicated_storage.EXE6_STORAGE
local events = storage.events

local ui = client.PlayerGui:WaitForChild("EXE6")

local main_frame = ui.main_frame
local navigation = main_frame.content.navigation
local screen = main_frame.content.screen

local home = screen.home
local people = screen.people
local bans = screen.bans
local announcement = screen.announcements
local activity_audits = screen.activity_audits
local utilitiesPage = screen.utilities

local Scroll = utilitiesPage.scroll.scroll

type ParameterType = "Player" | "Slider" | "Textbox" | "Boolean" | "Enum"

local MainModule
local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)

local module = {}
module.Commands = {}

function module.GetCommands()
	return module.Commands
end

function module.GetCommand(name: string)
	return module.Commands[name]
end

function module:RegisterCommand(Name)	
	local self = {}
	setmetatable(self, module)

	self.Alias = Name
	self.Description = "No description yet."
	self.Icon = "rbxassetid://11419714821"

	self.Access = {"Team"}
	self.Event = nil
	self.Parameters = {}

	function self:AddParameter(type: ParameterType, configuration)
		if not configuration.Name then
			warn("Unable to register property; Configuration is invalid.")
			return
		end

		if type == "Player" then

			table.insert(self.Parameters, {
				Name = configuration.Name,
				ParamType = type,

				SelectionRange = configuration.SelectionRange or NumberRange.new(1),
			})

		elseif type == "Slider" then

			table.insert(self.Parameters, {
				Name = configuration.Name,
				ParamType = type,

				SliderDefault = configuration.SliderDefault or 0,
				SliderIncrement = configuration.SliderIncrement or .1,
				SliderRange = configuration.SliderRange or NumberRange.new(0, 100),
			})

		elseif type == "Textbox"  then

			table.insert(self.Parameters, {
				Name = configuration.Name,
				ParamType = type,
				
				StartingText = configuration.StartingText or ""
			})


		elseif type == "Boolean" then

			table.insert(self.Parameters, {
				Name = configuration.Name,
				ParamType = type,
				
				StartingValue = configuration.StartingValue or false
			})

		elseif type == "Enum" then
			if not configuration["Items"] then
				warn("Unable to register property; Missing Item Table")
				return;
			end

			table.insert(self.Parameters, {
				Name = configuration.Name,
				ParamType = type,

				SelectionRange = configuration.SelectionRange or NumberRange.new(0, 5),
				Items = configuration.Items
			})

		end
	end

	module.Commands[Name] = self

	return self
end

return module