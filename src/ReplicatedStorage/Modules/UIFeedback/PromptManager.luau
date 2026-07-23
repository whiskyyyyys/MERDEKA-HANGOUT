local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Modules.nevermore.Promise)

local PromptManager = {}

function PromptManager.displaySelectionPrompt(_, currentSelection)
	-- Minimal fallback: no popup system in this project.
	return Promise.resolve(false, currentSelection, currentSelection)
end

return PromptManager
