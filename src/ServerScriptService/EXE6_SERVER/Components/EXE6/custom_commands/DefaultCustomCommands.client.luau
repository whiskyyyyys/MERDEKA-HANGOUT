local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local client = players.LocalPlayer

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local CustomCommands = require(storage.modules.CustomCommands)

--// REGISTERED CUSTOM COMMANDS

local ToolsCC = CustomCommands:RegisterCommand("Tools")
ToolsCC.Alias = "Tools"
ToolsCC.Description = "Distribute Tools."
ToolsCC.Icon = "rbxassetid://11432855214"
ToolsCC.Event = storage.utilities.custom_commands.Tools

ToolsCC:AddParameter("Enum", {
	Name = "Tools",
	Items = storage.utilities.tools:GetChildren(),
	SelectionRange = NumberRange.new(1, math.clamp(#storage.utilities.tools:GetChildren(), 1, 999))
})

ToolsCC:AddParameter("Player", {
	Name = "Recipient",
	SelectionRange = NumberRange.new(1, players.MaxPlayers)
})

--

local ClearToolsCC = CustomCommands:RegisterCommand("Clear Tools")
ClearToolsCC.Description = "Clears the backpack of a player."
ClearToolsCC.Icon = "rbxassetid://11326877264"
ClearToolsCC.Event = storage.utilities.custom_commands.ClearTools

ClearToolsCC:AddParameter("Player", {
	Name = "Recipient",
	SelectionRange = NumberRange.new(1, players.MaxPlayers)
})

--

local TimeCC = CustomCommands:RegisterCommand("Time")
TimeCC.Description = "Change in-game time."
TimeCC.Icon = "rbxassetid://11963371162"
TimeCC.Event = storage.utilities.custom_commands.ChangeTime

TimeCC:AddParameter("Boolean", {
	Name = "Animate"
})

TimeCC:AddParameter("Slider", {
	Name = "Time",
	SliderRange = NumberRange.new(1, 24),
	SliderDefault = game.Lighting.ClockTime,
	SliderIncrement = .01,
})

--

local ClearAccessoriesCC = CustomCommands:RegisterCommand("Clear Accessories")
ClearAccessoriesCC.Alias = "Clear Accessories"
ClearAccessoriesCC.Description = "Clear all of the accessories of a player."
ClearAccessoriesCC.Icon = "rbxassetid://11432846321"
ClearAccessoriesCC.Event = storage.utilities.custom_commands.ClearAccessories

ClearAccessoriesCC:AddParameter("Boolean", {
	Name = "IncludeHair",
	StartingValue = true
})

ClearAccessoriesCC:AddParameter("Player", {
	Name = "Recipient",
	SelectionRange = NumberRange.new(1, players.MaxPlayers)
})


--

local FlingCC = CustomCommands:RegisterCommand("Fling")
FlingCC.Alias = "Fling"
FlingCC.Description = "Send them out."
FlingCC.Icon = "rbxassetid://97980406805013"
FlingCC.Event = storage.utilities.custom_commands.Fling

FlingCC:AddParameter("Player", {
	Name = "Victim",
	SelectionRange = NumberRange.new(1, players.MaxPlayers)
})

FlingCC:AddParameter("Slider", {
	Name = "Force",
	SliderRange = NumberRange.new(200, 2000),
	SliderDefault = 1000,
	SliderIncrement = 10
})