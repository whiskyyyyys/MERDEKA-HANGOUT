-- ============================================================
-- TangkapAyamClient.client.luau
-- Memberikan efek mabuk/pusing saat main Tangkap Ayam
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local minigamesFolder = ReplicatedStorage:WaitForChild("Minigames")
local ayamFolder = minigamesFolder:WaitForChild("TangkapAyam")
local eventsFolder = ayamFolder:WaitForChild("Events")
local DrunkEffectEvent = eventsFolder:WaitForChild("DrunkEffectEvent")

local isDrunk = false
local renderConnection = nil

local blurEffect = nil
local colorEffect = nil

local function startDrunkEffect()
	if isDrunk then return end
	isDrunk = true
	
	-- Efek visual blur halus & warna
	if not blurEffect then
		blurEffect = Instance.new("BlurEffect")
		blurEffect.Size = 0
		blurEffect.Parent = Lighting
	end
	
	if not colorEffect then
		colorEffect = Instance.new("ColorCorrectionEffect")
		colorEffect.TintColor = Color3.fromRGB(255, 255, 255)
		colorEffect.Parent = Lighting
	end
	
	TweenService:Create(blurEffect, TweenInfo.new(1.5), {Size = 2.5}):Play()
	TweenService:Create(colorEffect, TweenInfo.new(1.5), {TintColor = Color3.fromRGB(245, 255, 245)}):Play()
	
	local camera = workspace.CurrentCamera
	local startTime = os.clock()
	
	-- Efek kamera berayun lembut (drunk/dizzy effect halus)
	renderConnection = RunService.RenderStepped:Connect(function()
		if not isDrunk then return end
		local elapsed = os.clock() - startTime
		
		-- Ayunan kamera sangat halus & lembut (tidak bikin pusing/mual)
		local roll = math.sin(elapsed * 1.8) * 0.035 -- Kemiringan lembut ~2 derajat
		local pitch = math.cos(elapsed * 1.2) * 0.015
		
		camera.CFrame = camera.CFrame * CFrame.Angles(pitch, 0, roll)
		
		-- Atur kecepatan jalan tetap nyaman
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 17
		end
	end)
end

local function stopDrunkEffect()
	if not isDrunk then return end
	isDrunk = false
	
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	
	if blurEffect then
		TweenService:Create(blurEffect, TweenInfo.new(1), {Size = 0}):Play()
	end
	
	if colorEffect then
		TweenService:Create(colorEffect, TweenInfo.new(1), {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	end
	
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = 16
	end
	
	task.delay(1, function()
		if not isDrunk then
			if blurEffect then blurEffect:Destroy() blurEffect = nil end
			if colorEffect then colorEffect:Destroy() colorEffect = nil end
		end
	end)
end

DrunkEffectEvent.OnClientEvent:Connect(function(state)
	if state then
		startDrunkEffect()
	else
		stopDrunkEffect()
	end
end)

print("[TangkapAyamClient] Loaded!")
