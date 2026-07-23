local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local groupId = 152660069 -- GROUP ID

local function checkAndPrompt()
	task.wait(25) -- Settings awalanyaa 30 detik/ 10 atau berapa
	if player then
		local success, isMember = pcall(function()
			return player:IsInGroup(groupId)
		end)
		if success then
			if not isMember then
				GroupService:PromptJoinAsync(groupId)
			else
			end
		else
			warn("Gagal mengecek status group (error koneksi Roblox).")
		end
	end
end

checkAndPrompt()