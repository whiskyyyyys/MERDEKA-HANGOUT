local module = {
	["Spin"] = {
		["SpinTime"] = 5, --How many rounds will it go and give the prize?
		["SpinTimeForReward"] = 60*5, -- Write the number of minutes it will take instead of 5
		["Rewards"] = {
			["Reward1"] = {
				["Reward"] = "Cash", -- leaderstats.Cash change to your currency/diamonds
				["Amount"] = 25,
				["TextColor"] = Color3.fromRGB(115, 255, 131),
				["Rarity"] = 34,
			},
			["Reward2"] = {
				["Reward"] = "Cash",
				["Amount"] = 50,
				["TextColor"] = Color3.fromRGB(115, 255, 131),
				["Rarity"] = 25,
			},
			["Reward3"] = {
				["Reward"] = "Cash",
				["Amount"] = 250,
				["TextColor"] = Color3.fromRGB(115, 255, 131),
				["Rarity"] = 17,
			},
			["Reward4"] = {
				["Reward"] = "Cash",
				["Amount"] = 1000,
				["TextColor"] = Color3.fromRGB(115, 255, 131),
				["Rarity"] = 15,
			},
			["Reward5"] = {
				["Reward"] = "Gems",-- leaderstats.Gems change to your diamond/currency
				["Amount"] = 25,
				["TextColor"] = Color3.fromRGB(199, 108, 255),
				["Rarity"] = 5,
			},
			["Reward6"] = {
				["Reward"] = "Gems",
				["Amount"] = 50,
				["TextColor"] = Color3.fromRGB(199, 108, 255),
				["Rarity"] = 3,
			},
			["Reward7"] = {
				["Reward"] = "Gems",
				["Amount"] = 250,
				["TextColor"] = Color3.fromRGB(199, 108, 255),
				["Rarity"] = 1,
			},
		},
	},
}

module.getRandomReward = function()
	local totalChance = 0
	for _, rewardData in pairs(module.Spin.Rewards) do
		totalChance = totalChance + rewardData.Rarity
	end

	local randomValue = math.random() * totalChance
	local accumulatedChance = 0

	for rewardName, rewardData in pairs(module.Spin.Rewards) do
		accumulatedChance = accumulatedChance + rewardData.Rarity
		if randomValue <= accumulatedChance then
			return rewardName
		end
	end

	return nil
end

return module



-- more uncopylocked! our discord https://discord.gg/uUv64J5sPZ