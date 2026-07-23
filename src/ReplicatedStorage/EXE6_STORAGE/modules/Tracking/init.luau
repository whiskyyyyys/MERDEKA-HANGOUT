local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local collection_service = game:GetService("CollectionService")
local tween_service = game:GetService("TweenService")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local modules = storage.modules

local Alerts = require(modules.Alerts)
local ClassIcons = require(modules.ClassIcons)
local MainModule = require(modules.MainModule)
local Utilities = require(modules.Utilities)

local client = players.LocalPlayer
local ui = client.PlayerGui:WaitForChild("EXE6")

local folder = ui.Tracking

local BadgeIndex = {}

local module = {}

function CheckValidity(recipient)
	if recipient:HasTag("Exe6PlayerUnavailable") then
		Alerts.BannerNotify({
			Header = "Player is unavailable.",
			Description = recipient.DisplayName .. " is unavailable.",
			Involved = {recipient.UserId},
			Icon = "rbxassetid://11419666512",
		})

		return
	end

	return true
end

function CreateBadge(AttachTo, UserId)	
	local Badge = script.TrackingBadge:Clone()
	
	BadgeIndex[AttachTo] = Badge

	Badge.Adornee = AttachTo
	Badge.Parent = folder
	Badge.Shadow.Badge.scale.Scale = .6

	if UserId then
		Badge.Shadow.Badge.Photo.Icon.Visible = false
		Badge.Shadow.Badge.Photo.Image = Utilities.GetPlayerThumbnail(UserId)
	else
		Badge.Shadow.Badge.Photo.Image = ""
		Badge.Shadow.Badge.Photo.Icon.Visible = true
		Badge.Shadow.Badge.Photo.Icon.Image = ClassIcons.GetClassIcon(AttachTo.ClassName)
	end

	Badge.Shadow.Badge.MouseButton1Click:Connect(function()
		MainModule.LiveTrack(true, AttachTo, BadgeIndex[AttachTo].Shadow)
	end)

	Badge.Shadow.Badge.MouseButton2Click:Connect(function()
		local Option = MainModule.PromptOptions({
			Header = AttachTo.Name,
			Options = {
				{Name = "Stop Tracking", Icon = "rbxassetid://12966825204"},
				{Name = "Live Track", Icon = "rbxassetid://11422924261"}
			}
		})

		if Option == "Stop Tracking" then
			module.SetTrack(AttachTo, false)

		elseif Option == "Live Track" then
			MainModule.LiveTrack(true, AttachTo, BadgeIndex[AttachTo].Shadow)
		end
	end)

	Badge.Shadow.Badge.TouchLongPress:Connect(function()
		local Option = MainModule.PromptOptions({
			Header = AttachTo.Name,
			Options = {
				{Name = "Stop Tracking", Icon = "rbxassetid://12966825204"},
				{Name = "Live Track", Icon = "rbxassetid://11422924261"}
			},
			Mobile = true
		})

		if Option == "Stop Tracking" then
			module.SetTrack(AttachTo, false)

		elseif Option == "Live Track" then
			MainModule.LiveTrack(true, AttachTo, BadgeIndex[AttachTo].Shadow)
		end
	end)

	--

	Badge.Shadow.Badge.MouseEnter:Connect(function()
		tween_service:Create(Badge.Shadow, info, {ImageTransparency = 0}):Play()
	end)

	Badge.Shadow.Badge.InputEnded:Connect(function()
		tween_service:Create(Badge.Shadow, info, {ImageTransparency = 1}):Play()
	end)

	--

	tween_service:Create(Badge.Shadow.Badge.scale, info, {Scale = 1}):Play()
end

ui.modal_frame.live_track.Tracking:GetPropertyChangedSignal("Value"):Connect(function()
	for i, Badge in pairs(ui.Tracking:GetChildren()) do
		if ui.modal_frame.live_track.Tracking.Value == Badge.Adornee then
			tween_service:Create(Badge.Shadow.Badge, info, {ImageColor3 = Color3.fromRGB(0, 230, 73)}):Play()
		else
			tween_service:Create(Badge.Shadow.Badge, info, {ImageColor3 = Color3.fromRGB(27, 27, 27)}):Play()
		end
	end
end)

function RemoveBadge(AttachedTo)
	BadgeIndex[AttachedTo] = nil
	
	for i, Badge in pairs(folder:GetChildren()) do
		if Badge.Adornee == AttachedTo then
			Badge:Destroy()
		end
	end
end

local TrackTag = "Exe6Tracking"

function module.SetTrack(Object, State)
	if not Object or not Object:IsA("Instance") then return end

	if State then
		for i, v in pairs(folder:GetChildren()) do
			if v.Adornee == Object then
				return
			end
		end
	end

	if Object:IsA("BasePart") then
		if State then
			Object:AddTag(TrackTag)
			CreateBadge(Object)
		else
			Object:RemoveTag(TrackTag)
			RemoveBadge(Object)
		end

	elseif Object:IsA("Model") then
		local humanoid = Object:FindFirstChild("Humanoid")
		local player = players:GetPlayerFromCharacter(Object)

		if humanoid and player then
			if not CheckValidity(player) then return end

			if State then
				Object:AddTag(TrackTag)
				CreateBadge(Object, player.UserId)

				player.CharacterAdded:Connect(function(char)
					char:AddTag(TrackTag)
					CreateBadge(Object, player.UserId)
				end)
			else
				Object:RemoveTag(TrackTag)
				RemoveBadge(Object)
			end

		else
			if State then
				Object:AddTag(TrackTag)
				CreateBadge(Object)
			else
				Object:RemoveTag(TrackTag)
				RemoveBadge(Object)
			end
		end
	end
end

function module.IsTracking(Object)
	return Object:HasTag(TrackTag)
end

function module.StopTrackingAllObjects()
	local Objects = collection_service:GetTagged(TrackTag)

	for i, v in pairs(Objects) do
		v:RemoveTag(TrackTag)
		RemoveBadge(v)
	end
end

function module.GetAllTrackableObjects()
	local results = {}

	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("BasePart") then
			local modelAncestor = descendant:FindFirstAncestorOfClass("Model")

			if not modelAncestor then
				if not descendant:HasTag(TrackTag) then
					table.insert(results, descendant)
				end
			end

		elseif descendant:IsA("Model") then
			if descendant:HasTag(TrackTag) then continue end
			if descendant:FindFirstChildOfClass("Humanoid") then continue end
			if #descendant:GetDescendants() == 0 then continue end

			local hasPart = descendant:FindFirstChildWhichIsA("BasePart", true)

			if hasPart then
				table.insert(results, descendant)
			end
		end
	end

	return results
end

function module.GetGuideDistance(Object)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local objCFrame

	if Object:IsA("BasePart") then
		objCFrame = Object.CFrame

	elseif Object:IsA("Model") then
		if Object.PrimaryPart then
			objCFrame = Object:GetPrimaryPartCFrame()
		else
			objCFrame = Object:GetModelCFrame()
		end
	else
		return
	end

	local camCFrame = camera.CFrame
	local camPos = camCFrame.Position
	local objPos = objCFrame.Position

	local offset = objPos - camPos
	local distance = math.round(offset.Magnitude)
	local relative = camCFrame:VectorToObjectSpace(offset)

	local x, y, z = relative.X, relative.Y, relative.Z
	local absX, absY, absZ = math.abs(x), math.abs(y), math.abs(z)

	local direction
	if absZ >= absX and absZ >= absY then
		direction = z > 0 and "behind" or "ahead"

	elseif absX >= absY and absX >= absZ then
		direction = x > 0 and "to your right" or "to your left"

	else
		direction = y > 0 and "above" or "below"
	end

	return distance, direction
end

return module