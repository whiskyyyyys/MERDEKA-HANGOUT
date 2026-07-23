local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local productFunctions = {}

productFunctions[1758610448] = function(receipt, player)
	local PlayerStats = player:FindFirstChild("PlayerStats")
	local Spin = PlayerStats and PlayerStats:FindFirstChild("Spin")

	if Spin then
		Spin.Value += 1
		return true
	end
end

productFunctions[1758610447] = function(receipt, player)
	local PlayerStats = player:FindFirstChild("PlayerStats")
	local Spin = PlayerStats and PlayerStats:FindFirstChild("Spin")

	if Spin then
		Spin.Value += 3
		return true
	end
end

productFunctions[1758610444] = function(receipt, player)
	local PlayerStats = player:FindFirstChild("PlayerStats")
	local Spin = PlayerStats and PlayerStats:FindFirstChild("Spin")

	if Spin then
		Spin.Value += 10
		return true
	end
end

local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId

	local player = Players:GetPlayerByUserId(userId)
	if player then
		-- Get the handler function associated with the developer product ID and attempt to run it
		local handler = productFunctions[productId]
		local success, result = pcall(handler, receiptInfo, player)
		if success then
			-- The user has received their benefits
			-- Return "PurchaseGranted" to confirm the transaction
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Failed to process receipt:", receiptInfo, result)
		end
	end

	-- The user's benefits couldn't be awarded
	-- Return "NotProcessedYet" to try again next time the user joins
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = processReceipt


-- more uncopylocked! our discord https://discord.gg/uUv64J5sPZ