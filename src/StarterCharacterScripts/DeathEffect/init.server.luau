-- StarterCharacterScripts > ButterflyDeathEffect (Server Script)
print("Free Respawn effect by YGF Studio")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")

local player = Players:GetPlayerFromCharacter(character)
local particleTemplate = script:WaitForChild("DeathParticle") 

-- [[ 🛠️ PENGAMAN SPAWN (YANG SUDAH DIPERBAIKI) ]]
-- Paksa tubuh terlihat saat spawn, TAPI JANGAN HumanoidRootPart
for _, obj in ipairs(character:GetDescendants()) do
	if (obj:IsA("BasePart") or obj:IsA("Decal")) and obj.Name ~= "HumanoidRootPart" then
		obj.Transparency = 0 
	end
end

-- Pastikan RootPart benar-benar bening
rootPart.Transparency = 1

-- [[ ⚙️ KONFIGURASI WAKTU ]]
local FADE_DURATION = 3.0      
local TOTAL_RESPAWN_TIME = 4.5 

-- Fungsi Setup Partikel
local function setupEmitter(parentPart, amountRate)
	local emitter = particleTemplate:Clone()
	emitter.Parent = parentPart
	emitter.Rate = amountRate 
	emitter.Enabled = false 
	return emitter
end

humanoid.BreakJointsOnDeath = false
local hasDied = false

humanoid.Died:Connect(function()
	if hasDied then return end
	hasDied = true

	-- [[ 🛡️ THREAD 1: RESPAWN TIMER ]]
	task.spawn(function()
		task.wait(TOTAL_RESPAWN_TIME)
		if player then
			player:LoadCharacter()
		else
			local p = Players:GetPlayerFromCharacter(character)
			if p then p:LoadCharacter() end
		end
	end)

	-- [[ 🦋 THREAD 2: VISUAL EFEK ]]
	rootPart.Anchored = true
	local activeEmitters = {} 

	for _, obj in ipairs(character:GetDescendants()) do
		-- Filter: Hanya fisik, BUKAN RootPart
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			obj.CanCollide = false
			obj.Anchored = true

			-- Hitung Rate
			local rate = 5
			if obj.Name:find("Torso") then rate = 40
			elseif obj.Name == "Head" then rate = 15 end

			local emitter = setupEmitter(obj, rate)
			table.insert(activeEmitters, emitter)

			-- Nyalakan
			emitter.Enabled = true 
			print("Free Respawn effect by YGF Studio")
			
			-- Pudar Perlahan
			local tween = TweenService:Create(obj, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Transparency = 1})
			tween:Play()

		elseif obj:IsA("Decal") then
			local tween = TweenService:Create(obj, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Transparency = 1})
			tween:Play()
		end
	end

	if head then
		for _, gui in ipairs(head:GetChildren()) do
			if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then gui:Destroy() end
		end
	end

	task.wait(FADE_DURATION)

	for _, emitter in ipairs(activeEmitters) do
		emitter.Enabled = false
	end
end)

--Free Effect Respawn by YGF Studio