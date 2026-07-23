local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

local refreshIcon = Icon.new()
refreshIcon:setImage("rbxassetid://91570817648544") -- Icon Refresh HD (Material Design)
-- Tip dihapus karena versinya tidak support
refreshIcon:setLeft()
refreshIcon:modifyTheme({"IconImageScale", "Value", 0.9, "Deselected"})
refreshIcon:modifyTheme({"IconImageScale", "Value", 0.9, "Selected"})

refreshIcon:bindEvent("toggled", function(icon, isSelected)
	if isSelected then
		print("[CharacterRefreshClient] Tombol refresh dipencet!")
		remotes.RequestCharacterRefresh:FireServer()
		task.wait(0.5)
		icon:deselect()
	end
end)
