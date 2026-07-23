local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

local cooldowns = {}
local COOLDOWN_TIME = 5

remotes.RequestCharacterRefresh.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if cooldowns[player] and (now - cooldowns[player]) < COOLDOWN_TIME then
		return
	end
	cooldowns[player] = now

	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local success, newDesc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	
	if success and newDesc then
		-- Lebih halus: ubah baju/aksesoris di tempat tanpa respawn karakter
		local applySuccess, err = pcall(function()
			-- Pertahankan bentuk tubuh (Blocky) dan ukuran tubuh (Scale) yang sekarang
			local currentDesc = humanoid:GetAppliedDescription()
			if currentDesc then
				-- Pertahankan Scale dari live Humanoid values agar lebih akurat
				local function getScale(name, default)
					local val = humanoid:FindFirstChild(name)
					return val and val.Value or default
				end
				
				newDesc.HeightScale = getScale("BodyHeightScale", currentDesc.HeightScale)
				newDesc.WidthScale = getScale("BodyWidthScale", currentDesc.WidthScale)
				newDesc.DepthScale = getScale("BodyDepthScale", currentDesc.DepthScale)
				newDesc.HeadScale = getScale("HeadScale", currentDesc.HeadScale)
				newDesc.BodyTypeScale = getScale("BodyTypeScale", currentDesc.BodyTypeScale)
				newDesc.ProportionScale = getScale("BodyProportionScale", currentDesc.ProportionScale)
				
				-- Pertahankan Body Parts (agar tetap kotak/blocky jika game memaksa demikian)
				newDesc.Head = currentDesc.Head
				newDesc.Torso = currentDesc.Torso
				newDesc.LeftArm = currentDesc.LeftArm
				newDesc.RightArm = currentDesc.RightArm
				newDesc.LeftLeg = currentDesc.LeftLeg
				newDesc.RightLeg = currentDesc.RightLeg
			end
			
			humanoid:ApplyDescription(newDesc)
		end)
		if not applySuccess then
			warn("[CharacterRefresh] ApplyDescription gagal: " .. tostring(err))
			-- Paksa fallback
			success = false
		else
			print("[CharacterRefresh] Berhasil merefresh outfit " .. player.Name)
		end
	end
	
	if not success or not newDesc then
		print("[CharacterRefresh] Menggunakan metode LoadCharacter fallback untuk " .. player.Name)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local savedCFrame = hrp and hrp.CFrame
		
		player:LoadCharacter()
		local newCharacter = player.Character or player.CharacterAdded:Wait()
		task.wait(0.1)
		
		if savedCFrame and newCharacter and newCharacter:FindFirstChild("HumanoidRootPart") then
			newCharacter:PivotTo(savedCFrame)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)
