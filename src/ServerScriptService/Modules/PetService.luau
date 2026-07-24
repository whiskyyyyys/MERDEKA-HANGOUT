local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Modules.PlayerDataService)
local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

local PetService = {}
local activePets = {} -- [Player] = PetModel

-- Fungsi untuk memberikan PrimaryPart ke Model jika belum punya
local function ensurePrimaryPart(model)
	if model.PrimaryPart then return model.PrimaryPart end
	
	-- Coba cari part yang cocok sebagai pusat
	local center = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Body") or model:FindFirstChildWhichIsA("BasePart")
	
	if center then
		model.PrimaryPart = center
	else
		-- Kalau bener-bener gak ada, buat part dummy transparan
		center = Instance.new("Part")
		center.Name = "PrimaryRoot"
		center.Size = Vector3.new(1, 1, 1)
		center.Transparency = 1
		center.CanCollide = false
		center.Massless = true
		
		-- Hitung bounding box untuk taruh di tengah
		local cf, size = model:GetBoundingBox()
		center.CFrame = cf
		center.Parent = model
		model.PrimaryPart = center
		
		-- Weld ke semua part lain
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") and child ~= center then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = center
				weld.Part1 = child
				weld.Parent = center
			end
		end
	end
	
	return center
end

function PetService.DespawnPet(player)
	if activePets[player] then
		activePets[player]:Destroy()
		activePets[player] = nil
	end
end

function PetService.SpawnPet(player, petName)
	PetService.DespawnPet(player)
	
	if not petName or petName == "" then return end
	
	local petsFolder = ServerStorage:FindFirstChild("Pets")
	if not petsFolder then return end
	
	local petTemplate = petsFolder:FindFirstChild(petName)
	if not petTemplate then return end
	
	local char = player.Character
	if not char then return end
	
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local petClone = petTemplate:Clone()
	
	-- Pastikan model memiliki PrimaryPart
	local petRoot = ensurePrimaryPart(petClone)
	
	-- Unanchor semua dan matikan collision agar tidak mengganggu player
	for _, child in petClone:GetDescendants() do
		if child:IsA("BasePart") then
			child.Anchored = false
			child.CanCollide = false
			child.Massless = true
			-- Jika belum di-weld dengan benar, paksa weld ke root (untuk model rusak)
			if child ~= petRoot and child:GetRootPart() == child then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = petRoot
				weld.Part1 = child
				weld.Parent = petRoot
			end
		end
	end
	
	-- Buat Attachment di Player
	local playerAttachment = Instance.new("Attachment")
	playerAttachment.Name = "PetAttachment"
	-- Atur posisi offset: Di belakang agak ke kanan, dan posisinya lebih rendah (setinggi badan)
	playerAttachment.Position = Vector3.new(1.5, 1.5, 4.5) 
	playerAttachment.Parent = rootPart
	
	-- Buat Attachment di Pet
	local petAttachment = Instance.new("Attachment")
	-- Putar attachment 90 derajat di sumbu Y agar model pet menghadap ke depan
	petAttachment.CFrame = CFrame.Angles(0, math.rad(90), 0)
	petAttachment.Parent = petRoot
	
	-- AlignPosition untuk mengikuti dengan mulus
	local alignPos = Instance.new("AlignPosition")
	alignPos.Attachment0 = petAttachment
	alignPos.Attachment1 = playerAttachment
	alignPos.MaxForce = 100000 -- Cukup kuat tapi tidak kaku
	alignPos.MaxVelocity = 25 -- Kecepatan maksimal dibatasi agar tidak teleport
	alignPos.Responsiveness = 8 -- Sangat mulus (ketinggalan natural)
	alignPos.Parent = petRoot
	
	-- AlignOrientation agar menghadap ke arah yang sama dengan player
	local alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = petAttachment
	alignOri.Attachment1 = playerAttachment
	alignOri.MaxTorque = 100000
	alignOri.MaxAngularVelocity = 10 -- Rotasi maksimal dibatasi
	alignOri.Responsiveness = 8 -- Putaran sangat smooth
	alignOri.Parent = petRoot
	
	-- Animasi melayang (Bobbing) naik turun terus menerus
	local TweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local bobTween = TweenService:Create(playerAttachment, tweenInfo, {
		Position = playerAttachment.Position + Vector3.new(0, 1.2, 0)
	})
	bobTween:Play()
	
	petClone.Parent = char
	activePets[player] = petClone
end

-- Menangani request data pet dari client
remotes.PetDataRequest.OnServerEvent:Connect(function(player)
	local owned = PlayerDataService.GetOwnedPets(player)
	local equipped = PlayerDataService.GetEquippedPet(player)
	remotes.PetDataResponse:FireClient(player, owned, equipped)
end)

-- Menangani equip/unequip dari client
remotes.PetEquip.OnServerEvent:Connect(function(player, petName)
	local hasPet = false
	if petName == "" then
		hasPet = true
	else
		hasPet = PlayerDataService.IsPetOwned(player, petName)
	end
	
	if hasPet then
		PlayerDataService.SetEquippedPet(player, petName)
		
		-- Update visual di game
		PetService.SpawnPet(player, petName)
		
		-- Kirim update ke client agar UI refresh
		local owned = PlayerDataService.GetOwnedPets(player)
		remotes.PetDataResponse:FireClient(player, owned, petName)
	end
end)

-- Spawn pet kembali saat karakter respawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(1) -- Tunggu karakter selesai dimuat
		local equipped = PlayerDataService.GetEquippedPet(player)
		if equipped ~= "" then
			PetService.SpawnPet(player, equipped)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PetService.DespawnPet(player)
end)

return PetService
