local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local FishConfig = require(ReplicatedStorage.Modules.FishConfig)

local sellButtonPart = workspace:WaitForChild("ButtonSellFish")
local prompt = sellButtonPart:WaitForChild("ProximityPrompt")

local DEFAULT_OBJECT_TEXT = prompt.ObjectText
local DEFAULT_ACTION_TEXT = prompt.ActionText

-- Ini cuma ngubah teks LOCAL buat player ini sendiri (gak ganggu prompt pemain lain),
-- karena diubah dari LocalScript.
local function updatePromptForTool(tool)
	if not tool then
		prompt.ObjectText = DEFAULT_OBJECT_TEXT
		prompt.ActionText = DEFAULT_ACTION_TEXT
		return
	end

	local rarity = tool:GetAttribute("Rarity")
	local weightKg = tool:GetAttribute("WeightKg")
	if not rarity or not weightKg then
		prompt.ObjectText = DEFAULT_OBJECT_TEXT
		prompt.ActionText = DEFAULT_ACTION_TEXT
		return
	end

	local pricePerKg = FishConfig.SELL_PRICE_PER_KG[rarity]
	if not pricePerKg then return end

	local price = math.floor((weightKg * pricePerKg) + 0.5)
	prompt.ObjectText = tool.Name .. " (" .. weightKg .. " kg)"
	prompt.ActionText = "Jual seharga " .. price
end

local function isFishTool(tool)
	return tool:IsA("Tool") and tool:GetAttribute("Rarity") ~= nil and tool:GetAttribute("WeightKg") ~= nil
end

local function onCharacterAdded(character)
	character.ChildAdded:Connect(function(child)
		if isFishTool(child) then
			updatePromptForTool(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if isFishTool(child) then
			updatePromptForTool(nil)
		end
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)