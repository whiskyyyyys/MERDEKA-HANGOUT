local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cmdr = require(script.Parent.Cmdr)

local Hooks = script.Hooks
local CustomCommands = script.CustomCommands
local Types = script.Types

Cmdr:RegisterDefaultCommands()
Cmdr:RegisterCommandsIn(CustomCommands)
Cmdr:RegisterHooksIn(Hooks)
Cmdr:RegisterTypesIn(Types)