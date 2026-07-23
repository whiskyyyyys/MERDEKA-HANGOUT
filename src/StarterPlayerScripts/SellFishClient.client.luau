local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

-- Trigger jual sekarang murni dari ProximityPrompt di Workspace (server-side),
-- client cuma perlu dengerin hasilnya buat notifikasi.
remotes.SellFishResult.OnClientEvent:Connect(function(success, amount, message)
	if success then
		print("Berhasil jual", message, "seharga", amount)
	else
		print("Gagal jual ikan:", message)
	end
end)