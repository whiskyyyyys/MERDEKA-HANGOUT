local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local Players = game:GetService("Players")

local SkinConfig = require(ReplicatedStorage.Modules.SkinConfig)

local ROD_TOOL_NAME = "RodDefault"

local skinRodFolder = ServerStorage:WaitForChild("SkinRod")
local rodTemplate = skinRodFolder:WaitForChild(ROD_TOOL_NAME)

-- ===== Starter rod ke StarterPack (sudah ada sebelumnya) =====

local existingInPack = StarterPack:FindFirstChild(ROD_TOOL_NAME)
if not existingInPack then
	local clone = rodTemplate:Clone()
	clone:SetAttribute("IsFishingRod", true) -- FIX
	clone.Parent = StarterPack
end

local function giveIfMissing(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	if not backpack then return end

	local function hasRodWithAttribute(container)
		if not container then return false end
		for _, tool in container:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute("IsFishingRod") then
				return true
			end
		end
		return false
	end

	if not hasRodWithAttribute(backpack) and not hasRodWithAttribute(character) then
		local clone = rodTemplate:Clone()
		clone:SetAttribute("IsFishingRod", true)
		clone.Parent = backpack
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		giveIfMissing(player)
	end)
end)

for _, player in Players:GetPlayers() do
	giveIfMissing(player)
end

-- ===== BARU: clone model viewport tiap skin ke ReplicatedStorage =====
-- Cuma buat ditampilkan di ViewportFrame client, BUKAN Tool asli yang bisa dipakai.
-- Nama folder hasil di ReplicatedStorage pakai skin.name (konsisten dengan SkinConfig).

local viewportFolder = ReplicatedStorage:FindFirstChild("SkinViewportModels")
if not viewportFolder then
	viewportFolder = Instance.new("Folder")
	viewportFolder.Name = "SkinViewportModels"
	viewportFolder.Parent = ReplicatedStorage
end

local function anchorAllParts(instance)
	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
end

for _, skin in SkinConfig.SKINS do
	if not viewportFolder:FindFirstChild(skin.name) then
		local toolTemplate = skinRodFolder:FindFirstChild(skin.name)
		if toolTemplate then
			local modelInsideTool = toolTemplate:FindFirstChild(skin.viewportModelName)
			if modelInsideTool then
				local clone = modelInsideTool:Clone()
				clone.Name = skin.name
				anchorAllParts(clone)
				clone.Parent = viewportFolder
			else
				warn("[StarterPackBootstrap] Model viewport '" .. skin.viewportModelName .. "' tidak ditemukan di dalam Tool '" .. skin.name .. "'")
			end
		else
			warn("[StarterPackBootstrap] Tool skin '" .. skin.name .. "' tidak ditemukan di ServerStorage.SkinRod")
		end
	end
end