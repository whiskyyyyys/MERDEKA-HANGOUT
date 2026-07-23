local tween_service = game:GetService("TweenService")
local input_service = game:GetService("UserInputService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local run_service = game:GetService("RunService")
local collection_service = game:GetService("CollectionService")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(1, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)

local back = TweenInfo.new(.5, Enum.EasingStyle.Back)

local client = players.LocalPlayer

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local Configuration = require(storage.modules.Configuration)
local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)
local Leaflet = require(storage.modules.Leaflet)

local ui = script.Parent
local announcement = ui.announcement

function ApplyAccentColor()
	for i, elements in pairs(ui:GetDescendants()) do
		if elements:HasTag("Exe6PrimaryThemeImageColor3") then
			elements.ImageColor3 = Configuration.Interface.Theme
		end

		if elements:HasTag("Exe6PrimaryThemeTextColor3") then
			elements.TextColor3 = Configuration.Interface.Theme
		end


		if elements:HasTag("Exe6SecondaryThemeImageColor3") then
			elements.ImageColor3 = Utilities.AdjustColor(Configuration.Interface.Theme)
		end

		if elements:HasTag("Exe6SecondaryThemeTextColor3") then
			elements.TextColor3 = Utilities.AdjustColor(Configuration.Interface.Theme)
		end

		if elements:HasTag("Exe6PrimaryThemeBackgroundColor3") then
			elements.BackgroundColor3 = Configuration.Interface.Theme
		end

		if elements:HasTag("Exe6PrimarySpeculars") then
			local Specular = Utilities.GetSpecularHighlightsAndShadows(Configuration.Interface.Theme, 1.4, .3)
			local Keypoints = {
				ColorSequenceKeypoint.new(0, Specular.Highlight),
				ColorSequenceKeypoint.new(.5, Specular.Shadows),
				ColorSequenceKeypoint.new(1, Specular.Highlight)
			}

			elements.Color = ColorSequence.new(Keypoints)
		end
	end
end

ApplyAccentColor()

events.ui.AlertsModuleEvent.OnClientEvent:Connect(function(func, data)
	Alerts[func](data)
end)

events.Activities.Announcement.OnClientEvent:Connect(function(audience, data)
	if not table.find(audience, players.LocalPlayer.UserId) then return end

	Alerts.PromptAnnounce(data)
end)

Leaflet:Apply(announcement, {
	MinSize = Vector2.new(450, 350),
	MaxSize = Vector2.new(700, 800),
	LockedZIndex = true,
	NormalizeSize = false
})

-- RESIZE HANDLES

function NormalizedCursorPosition(button)
	local mouseLocation = input_service:GetMouseLocation()
	local guiInset = game:GetService("GuiService"):GetGuiInset().Y

	local buttonPosition = button.AbsolutePosition
	local buttonSize = button.AbsoluteSize

	local correctedMouseY = mouseLocation.Y - guiInset

	local relativeX = (mouseLocation.X - buttonPosition.X) / buttonSize.X
	local relativeY = (correctedMouseY - buttonPosition.Y) / buttonSize.Y

	local finalX = 1 - math.clamp(relativeX, 0, 1)
	local finalY = 1 - math.clamp(relativeY, 0, 1)

	return Vector2.new(finalX, finalY)
end

local ResizeHandles = collection_service:GetTagged("Exe6ResizeHandle")

for i, button in pairs(ResizeHandles) do
	if button:IsA("ImageButton") then

		button.InputChanged:Connect(function(input)
			local normals = NormalizedCursorPosition(button)

			tween_service:Create(button.icon, info, {
				Size = UDim2.fromOffset(20 + (normals.X * 30), 20 + (normals.Y * 30))}):Play()
		end)

		button.InputEnded:Connect(function()
			tween_service:Create(button.icon, info, {Size = UDim2.fromOffset(18, 18)}):Play()
		end)

	end
end

-- Dynamic Strokes

local cam = workspace.CurrentCamera
local CurrentRotation = 0

function CalculateShortestRotation(from, to)
	local diff = (to - from + 540) % 360 - 180

	return from + diff
end

function UpdateDynamicSpeculars()
	if not Configuration.Interface.DynamicSpecularEffect then return end

	local look = cam.CFrame.LookVector
	local yaw = math.deg(math.atan2(-look.X, -look.Z)) % 360

	local targetRotation = CalculateShortestRotation(CurrentRotation, yaw)
	CurrentRotation = targetRotation % 360

	for _, gradient in ipairs(collection_service:GetTagged("Exe6DynamicSpeculars")) do
		gradient.Rotation = CurrentRotation
	end
end

run_service.RenderStepped:Connect(UpdateDynamicSpeculars)