local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

local MinigameController = require(script.Parent.Modules.MinigameController)
local ResultController = require(script.Parent.Modules.ResultController)
local CameraEffectController = require(script.Parent.Modules.CameraEffectController)
local UIVisibilityController = require(script.Parent.Modules.UIVisibilityController)

local fishingGui = playerGui:WaitForChild("Fishing")
fishingGui.ResetOnSpawn = false
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
	end)
	tool.Unequipped:Connect(function()
		isRodEquipped = false
		isFishing = false
		isWaitingBite = false
		cameraEffect:Stop()
		setCharacterFrozen(false)
	end)
	if tool.Parent and tool.Parent:IsA("Model") then
		isRodEquipped = true
	end
end

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
		minigame:Start(onMinigameComplete)
	end)
end)

remotes.FishCaught.OnClientEvent:Connect(function(payload)
	resultController:HandleCatch(payload, function()
		uiVisibility:RestoreOthers()
		setCharacterFrozen(false)
	end)
end)	