local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))

Cmdr:SetActivationKeys({ Enum.KeyCode.F4 })

-- =======================================
-- TOMBOL ADMIN UNTUK MOBILE
-- =======================================
local player = Players.LocalPlayer
local GROUP_ID = 152660069
local adminIds = {1332452869001052215, 585682641777590288, 420925406137286656, 1056973095157649500, 1451601271613165783}

local isAuth = false
for _, id in ipairs(adminIds) do
	if player.UserId == id then isAuth = true break end
end

if not isAuth then
	pcall(function()
		local role = player:GetRoleInGroup(GROUP_ID)
		if role and role ~= "Guest" then
			local lowerRole = string.lower(role)
			if lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo") or lowerRole:match("admin") or lowerRole:match("mod") or lowerRole:match("dev") then
				isAuth = true
			end
		end
	end)
end

if isAuth then
	local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
	
	local cmdrIcon = Icon.new()
	cmdrIcon:setImage("rbxassetid://81170854564432") -- Icon terminal/admin
	cmdrIcon:setRight()
	cmdrIcon:modifyTheme({"IconImageScale", "Value", 0.9, "Deselected"})
	cmdrIcon:modifyTheme({"IconImageScale", "Value", 0.9, "Selected"})
	
	cmdrIcon:bindEvent("toggled", function(icon, isSelected)
		if isSelected then
			Cmdr:Toggle()
			task.delay(0.1, function()
				icon:deselect()
			end)
		end
	end)
end