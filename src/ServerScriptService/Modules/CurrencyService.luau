local Players = game:GetService("Players")

local CurrencyService = {}

local ATTRIBUTE_NAME = "CGF"
local remotesRef = nil

function CurrencyService.GetCoins(player)
	return player:GetAttribute(ATTRIBUTE_NAME) or 0
end

function CurrencyService.AddCoins(player, amount)
	local current = CurrencyService.GetCoins(player)
	local newTotal = current + amount
	player:SetAttribute(ATTRIBUTE_NAME, newTotal)
	if remotesRef then
		remotesRef.CoinUpdated:FireClient(player, newTotal)
	end
	return newTotal
end

function CurrencyService.Init(remotes)
	remotesRef = remotes

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute(ATTRIBUTE_NAME, 0)
		remotes.CoinUpdated:FireClient(player, 0)
		-- TODO: kalau mau permanen, load dari DataStore/ProfileService di sini
	end)

	for _, player in Players:GetPlayers() do
		if player:GetAttribute(ATTRIBUTE_NAME) == nil then
			player:SetAttribute(ATTRIBUTE_NAME, 0)
		end
	end
end

return CurrencyService