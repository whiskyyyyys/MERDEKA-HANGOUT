local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

local AutoFishingRemote = ReplicatedStorage:WaitForChild("SetAutoFishing", 10)
if not AutoFishingRemote then
	AutoFishingRemote = Instance.new("RemoteEvent")
	AutoFishingRemote.Name = "SetAutoFishing"
	AutoFishingRemote.Parent = ReplicatedStorage
end

local MinigameController = require(script.Parent.Modules.MinigameController)
local ResultController = require(script.Parent.Modules.ResultController)
local CameraEffectController = require(script.Parent.Modules.CameraEffectController)
local UIVisibilityController = require(script.Parent.Modules.UIVisibilityController)

local fishingGui = playerGui:WaitForChild("Fishing")
if fishingGui:IsA("ScreenGui") then
	fishingGui.ResetOnSpawn = false
end
local minigame = MinigameController.new(fishingGui)
local resultController = ResultController.new(fishingGui)
local cameraEffect = CameraEffectController.new()
local uiVisibility = UIVisibilityController.new(playerGui)

local BITE_WAIT_TIME = 5
local CAST_RESPONSE_TIMEOUT = 4

local isFishing = false
local isWaitingBite = false
local isRodEquipped = false
local castRequestId = 0
local lastTargetPos = nil
local isAutoFishing = false

local autoButton = minigame.autoButton

local function setAutoFishingState(state)
	isAutoFishing = state
	minigame:SetAutoModeUI(state)
	AutoFishingRemote:FireServer(state)
end

-- Logika Cek Akses Auto Fishing
local GROUP_ID = 152660069
local adminIds = {1332452869001052215, 585682641777590288, 420925406137286656, 1056973095157649500, 1451601271613165783}

local function hasAutoAccess()
	-- 50 Jam = 3000 menit
	local playTimeMins = player:GetAttribute("PlayTimeMinutes") or 0
	if playTimeMins >= 3000 then return true end
	
	-- Admin check
	for _, id in ipairs(adminIds) do
		if player.UserId == id then return true end
	end
	
	local isAuth = false
	pcall(function()
		local role = player:GetRoleInGroup(GROUP_ID)
		if role and role ~= "Guest" then
			local lowerRole = string.lower(role)
			if lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo") or lowerRole:match("admin") or lowerRole:match("mod") or lowerRole:match("dev") then
				isAuth = true
			end
		end
	end)
	
	return isAuth
end

if not hasAutoAccess() then
	autoButton.Visible = false
end

local function doAutoFish()
	if not isAutoFishing then return end
	if isFishing or isWaitingBite then return end
	
	-- Pastikan depan kita adalah air
	if not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Tembak raycast ke depan dan agak ke bawah
	local rayOrigin = hrp.Position
	local rayDirection = hrp.CFrame.LookVector * 40 + Vector3.new(0, -15, 0)
	
	local rayParams = RaycastParams.new()
	rayParams.IgnoreWater = false
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = {workspace.Terrain}

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result and result.Material == Enum.Material.Water then
		lastTargetPos = result.Position
		isFishing = true
		castRequestId += 1
		local thisRequestId = castRequestId

		remotes.RequestCast:FireServer(result.Position)

		task.delay(CAST_RESPONSE_TIMEOUT, function()
			if castRequestId == thisRequestId and isFishing then
				isFishing = false
				task.delay(1.5, doAutoFish)
			end
		end)
	else
		-- Berhenti karena tidak melihat air
		isAutoFishing = false
		minigame:SetAutoModeUI(false)
		
		local StarterGui = game:GetService("StarterGui")
		StarterGui:SetCore("SendNotification", {
			Title = "Auto Fishing Berhenti";
			Text = "Harus menghadap ke air!";
			Duration = 3;
		})
	end
end

autoButton.Activated:Connect(function()
	local newState = not isAutoFishing
	setAutoFishingState(newState)
	
	if isAutoFishing then
		-- Panggil langsung kalau sebelumnya lagi diam
		if not isFishing and not isWaitingBite then
			doAutoFish()
		end
	else
		if minigame.isActive then
			-- Jika dimatikan di tengah auto minigame, kembali ke manual
			setAutoFishingState(false)
		end
	end
end)

local function setCharacterFrozen(frozen)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if frozen then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end

local function getWaterPositionFromScreenPoint(screenPos)
	local unitRay = camera:ViewportPointToRay(screenPos.X, screenPos.Y)

	local rayParams = RaycastParams.new()
	rayParams.IgnoreWater = false
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = {workspace.Terrain}

	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
	if result then
		return result.Position
	end
	return nil
end

local function tryCastAt(screenPos)
	if not isRodEquipped or isFishing or isWaitingBite or minigame.isActive then return end

	local targetPos = getWaterPositionFromScreenPoint(screenPos)
	if not targetPos then return end
	
	lastTargetPos = targetPos

	isFishing = true
	castRequestId += 1
	local thisRequestId = castRequestId

	remotes.RequestCast:FireServer(targetPos)

	task.delay(CAST_RESPONSE_TIMEOUT, function()
		if castRequestId == thisRequestId and isFishing then
			isFishing = false
		end
	end)
end

local function onMinigameComplete(hitCount)
	remotes.SubmitCatchResult:FireServer(hitCount)
end

local function bindTool(tool)
	if not tool:GetAttribute("IsFishingRod") then return end

	tool.Equipped:Connect(function()
		isRodEquipped = true
		if hasAutoAccess() then
			minigame:ShowAutoIdle()
		end
	end)
	tool.Unequipped:Connect(function()
		isRodEquipped = false
		isFishing = false
		isWaitingBite = false
		cameraEffect:Stop()
		setCharacterFrozen(false)
		minigame:HideAutoIdle()
		
		-- Matikan auto jika pancingan dilepas
		if isAutoFishing then
			setAutoFishingState(false)
		end
	end)
	if tool.Parent and tool.Parent:IsA("Model") then
		isRodEquipped = true
		if hasAutoAccess() then
			minigame:ShowAutoIdle()
		end
	end
end

-- ==========================================
-- LOGIKA RESUME AFK AUTO FISHING
-- ==========================================
task.spawn(function()
	if player:GetAttribute("ResumeAutoFishing") then
		player:SetAttribute("ResumeAutoFishing", nil)
		
		local char = player.Character or player.CharacterAdded:Wait()
		local humanoid = char:WaitForChild("Humanoid", 10)
		if not humanoid then return end
		
		-- Beri waktu agar Backpack dimuat
		task.wait(2)
		
		local rod = nil
		for _, tool in ipairs(player.Backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("IsFishingRod") then
				rod = tool
				break
			end
		end
		
		if rod then
			humanoid:EquipTool(rod)
			task.wait(1)
			-- Start auto fishing immediately
			setAutoFishingState(true)
			doAutoFish()
		end
	end
end)

local function onCharacterAdded(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			bindTool(child)
		end
	end)
	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			bindTool(child)
		end
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryCastAt(Vector2.new(input.Position.X, input.Position.Y))
	elseif input.KeyCode == Enum.KeyCode.Space then
		if minigame.isActive then
			minigame:AttemptHit()
		end
	end
end)

UserInputService.TouchTap:Connect(function(touchPositions, gameProcessed)
	if gameProcessed then return end
	local pos = touchPositions[1]
	if pos then
		tryCastAt(pos)
	end
end)

remotes.CastResult.OnClientEvent:Connect(function(isWater)
	isFishing = false
	castRequestId += 1

	if not isWater then
		return
	end

	isWaitingBite = true
	cameraEffect:Play(BITE_WAIT_TIME, function()
		isWaitingBite = false
		uiVisibility:HideOthers()
		setCharacterFrozen(true)
		minigame:Start(onMinigameComplete, isAutoFishing)
	end)
end)

remotes.FishCaught.OnClientEvent:Connect(function(payload)
	-- Animasi Ikan Melompat Keluar dari Air
	if lastTargetPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local rootPart = player.Character.HumanoidRootPart
		print("[FishingClient] Memulai animasi ikan dari", lastTargetPos, "ke", rootPart.Position)
		
		-- Buat part ikan fake (sekarang kita buat terlihat bentuk kotak/ikan kecil)
		local fishPart = Instance.new("Part")
		fishPart.Name = "AnimatedFish"
		fishPart.Size = Vector3.new(1.5, 1.5, 1.5)
		fishPart.Color = Color3.fromRGB(0, 150, 255)
		fishPart.Material = Enum.Material.Neon
		fishPart.Transparency = 1 -- Sembunyikan kotak fisik agar hanya UI yang terlihat

		fishPart.Anchored = true
		fishPart.CanCollide = false
		fishPart.Position = lastTargetPos - Vector3.new(0, 1, 0) 
		fishPart.Parent = workspace
		
		-- Buat gambar ikan via BillboardGui
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 150, 0, 150) -- Gunakan ukuran pasti dalam pixel
		billboard.AlwaysOnTop = true
		billboard.Parent = fishPart
		
		local img = nil
		if payload.iconId and payload.iconId ~= "" then
			img = Instance.new("ImageLabel")
			img.Size = UDim2.fromScale(1, 1)
			img.BackgroundTransparency = 1
			img.Image = payload.iconId
			img.Parent = billboard
		end

		-- Tween lompatan melengkung
		local midPos = lastTargetPos:Lerp(rootPart.Position, 0.5) + Vector3.new(0, 15, 0)
		local endPos = rootPart.Position + Vector3.new(0, 1, 0)

		local t1 = TweenService:Create(fishPart, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = midPos})
		local t2 = TweenService:Create(fishPart, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = endPos})
		
		local function finishAnimation()
			fishPart:Destroy()
			resultController:HandleCatch(payload, function()
				uiVisibility:RestoreOthers()
				setCharacterFrozen(false)
			end)
			
			-- AUTO LOOP
			if isAutoFishing then
				task.delay(2, function()
					if resultController.resultFrame.Visible then
						resultController:_dismiss()
						task.delay(0.5, doAutoFish)
					end
				end)
			end
		end
		
		t1:Play()
		t1.Completed:Once(function()
			t2:Play()
			t2.Completed:Once(function()
				-- Efek saat ditangkap (fade out / hancur)
				if img then
					local fadeTween = TweenService:Create(img, TweenInfo.new(0.15), {ImageTransparency = 1, Size = UDim2.fromScale(0, 0)})
					fadeTween:Play()
					fadeTween.Completed:Once(finishAnimation)
				else
					finishAnimation()
				end
			end)
		end)
	else
		-- Fallback: Jika tidak bisa dianimasikan, langsung munculkan GUI
		resultController:HandleCatch(payload, function()
			uiVisibility:RestoreOthers()
			setCharacterFrozen(false)
		end)
		
		-- AUTO LOOP
		if isAutoFishing then
			task.delay(2, function()
				if resultController.resultFrame.Visible then
					resultController:_dismiss()
					task.delay(0.5, doAutoFish)
				end
			end)
		end
	end
end)	