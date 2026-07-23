local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

local coinIcon = Icon.new()
coinIcon:setLabel("CGF: 0")

-- taruh di kanan atas topbar; kalau method ini gak ada di versi Icon kamu,
-- kasih tau errornya, aku sesuaikan ke API alignment yang benar
if coinIcon.setRight then
	coinIcon:setRight()
end

remotes.CoinUpdated.OnClientEvent:Connect(function(newAmount)
	coinIcon:setLabel("CGF: " .. tostring(newAmount))
end)