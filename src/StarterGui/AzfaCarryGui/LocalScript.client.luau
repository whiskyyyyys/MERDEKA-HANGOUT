local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = script.Parent
local promptFrame = gui:WaitForChild("AzfaPromtFrame")
local dropFrame = gui:WaitForChild("AzfaDropFrame")

local promptTitle = promptFrame:WaitForChild("Title")
local promptText = promptFrame:WaitForChild("Text")
local promptButtonFrame = promptFrame:WaitForChild("AzfaButton")
local acceptButton = promptButtonFrame:WaitForChild("AzfaAcceptButton")
local declineButton = promptButtonFrame:WaitForChild("AzfaDeclineButton")

local playerNameLabel = dropFrame:WaitForChild("PlayerName")
local avatarImage = dropFrame:WaitForChild("AvatarImage")
local dropButtonFrame = dropFrame:WaitForChild("AzfaButton")
local downButton = dropButtonFrame:WaitForChild("DownButton")

local CarryReplic = ReplicatedStorage:WaitForChild("CarryReplic")
local CarryRemotes = CarryReplic:WaitForChild("CarryRemotes")
local CarryRemote = CarryRemotes:WaitForChild("CarryRemote")

local currentRequesterUserId = nil
local currentCarryOtherUserId = nil

local acceptBusy = false
local declineBusy = false
local downBusy = false

local promptOriginalSize = promptFrame.Size
local dropOriginalPos = dropFrame.Position

local originalCameraSubject = nil
local originalCameraType = nil

gui.Enabled = true
promptFrame.Visible = false
dropFrame.Visible = false
promptText.RichText = false
avatarImage.ScaleType = Enum.ScaleType.Crop

local function getThumbnail(userId)
	if typeof(userId) ~= "number" or userId <= 0 then
		return ""
	end

	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(
			userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size420x420
		)
	end)

	return ok and content or ""
end

local function tweenObject(instance, info, props)
	local tween = TweenService:Create(instance, info, props)
	tween:Play()
	return tween
end

local function setCarryCameraToPlayerRoot(userId)
	local otherPlayer = Players:GetPlayerByUserId(userId)
	if not otherPlayer or not otherPlayer.Character then
		return
	end

	local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if not originalCameraSubject then
		originalCameraSubject = camera.CameraSubject
	end
	if not originalCameraType then
		originalCameraType = camera.CameraType
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = root
end

local function restoreOwnCamera()
	local myCharacter = LocalPlayer.Character
	local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")

	camera.CameraType = Enum.CameraType.Custom
	if myHumanoid then
		camera.CameraSubject = myHumanoid
	elseif originalCameraSubject then
		camera.CameraSubject = originalCameraSubject
	end

	originalCameraSubject = nil
	originalCameraType = nil
end

local function hidePrompt(immediate)
	currentRequesterUserId = nil

	if immediate then
		promptFrame.Visible = false
		promptFrame.Size = promptOriginalSize
		return
	end

	if not promptFrame.Visible then
		return
	end

	local closeSize = UDim2.new(
		promptOriginalSize.X.Scale * 0.92,
		promptOriginalSize.X.Offset,
		promptOriginalSize.Y.Scale * 0.92,
		promptOriginalSize.Y.Offset
	)

	local tween = tweenObject(
		promptFrame,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = closeSize }
	)

	tween.Completed:Once(function()
		promptFrame.Visible = false
		promptFrame.Size = promptOriginalSize
	end)
end

local function showPrompt(fromUserId, fromName)
	gui.Enabled = true
	currentRequesterUserId = fromUserId

	promptTitle.Text = "Carry Request"
	promptText.Text = string.format("%s ingin menggendongmu. Terima?", fromName or "Player")

	promptFrame.Size = UDim2.new(
		promptOriginalSize.X.Scale * 0.92,
		promptOriginalSize.X.Offset,
		promptOriginalSize.Y.Scale * 0.92,
		promptOriginalSize.Y.Offset
	)
	promptFrame.Visible = true
	dropFrame.Visible = false

	tweenObject(
		promptFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = promptOriginalSize }
	)
end

local function hideDrop(immediate)
	currentCarryOtherUserId = nil

	if immediate then
		dropFrame.Visible = false
		dropFrame.Position = dropOriginalPos
		return
	end

	if not dropFrame.Visible then
		return
	end

	local hidePos = UDim2.new(1.15, 0, dropOriginalPos.Y.Scale, dropOriginalPos.Y.Offset)

	local tween = tweenObject(
		dropFrame,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = hidePos }
	)

	tween.Completed:Once(function()
		dropFrame.Visible = false
		dropFrame.Position = dropOriginalPos
	end)
end

local function showDrop(otherUserId, otherName)
	gui.Enabled = true
	currentCarryOtherUserId = otherUserId

	playerNameLabel.Text = otherName or "Player"

	local thumb = getThumbnail(otherUserId)
	if thumb ~= "" then
		avatarImage.Image = thumb
	else
		avatarImage.Image = ""
	end

	local startPos = UDim2.new(1.15, 0, dropOriginalPos.Y.Scale, dropOriginalPos.Y.Offset)
	dropFrame.Position = startPos
	dropFrame.Visible = true
	promptFrame.Visible = false

	tweenObject(
		dropFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = dropOriginalPos }
	)
end

acceptButton.Activated:Connect(function()
	if acceptBusy or not currentRequesterUserId then
		return
	end

	acceptBusy = true
	CarryRemote:FireServer("CarryResponse", true, currentRequesterUserId)
	hidePrompt()

	task.delay(0.35, function()
		acceptBusy = false
	end)
end)

declineButton.Activated:Connect(function()
	if declineBusy or not currentRequesterUserId then
		return
	end

	declineBusy = true
	CarryRemote:FireServer("CarryResponse", false, currentRequesterUserId)
	hidePrompt()

	task.delay(0.35, function()
		declineBusy = false
	end)
end)

downButton.Activated:Connect(function()
	if downBusy then
		return
	end

	downBusy = true
	CarryRemote:FireServer("DropCarry")

	task.delay(0.35, function()
		downBusy = false
	end)
end)

CarryRemote.OnClientEvent:Connect(function(action, data)
	if type(action) ~= "string" then
		return
	end

	data = data or {}

	if action == "ShowCarryRequest" then
		showPrompt(data.requesterUserId, data.requesterName)
		return
	end

	if action == "HideCarryRequest" then
		hidePrompt()
		return
	end

	if action == "CarryStarted" then
		hidePrompt()
		showDrop(data.otherUserId, data.otherName)

		if data.role == "carried" and data.otherUserId then
			setCarryCameraToPlayerRoot(data.otherUserId)
		end
		return
	end

	if action == "CarryEnded" then
		hidePrompt()
		hideDrop()
		restoreOwnCamera()
		return
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	hidePrompt(true)
	hideDrop(true)
	restoreOwnCamera()
end)