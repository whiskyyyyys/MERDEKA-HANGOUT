local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- Konfigurasi
local NORMAL_SPEED = 16
local SPRINT_SPEED = 24
local NORMAL_FOV = 70
local SPRINT_FOV = 80

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local isSprinting = false

local function setSprint(active)
	if isSprinting == active then return end
	isSprinting = active
	
	-- Ubah Kecepatan
	humanoid.WalkSpeed = active and SPRINT_SPEED or NORMAL_SPEED
	
	-- Animasi Kamera Nge-zoom Out sedikit (Kesan Cepat)
	TweenService:Create(camera, tweenInfo, {
		FieldOfView = active and SPRINT_FOV or NORMAL_FOV
	}):Play()
end

local function handleSprintAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		setSprint(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		setSprint(false)
	end
	return Enum.ContextActionResult.Pass
end

-- Bind Action untuk Keyboard (Shift Kiri/Kanan) dan memunculkan tombol otomatis untuk Mobile (Touch)
ContextActionService:BindAction("SprintAction", handleSprintAction, true, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)

-- Kustomisasi Tombol Mobile
ContextActionService:SetTitle("SprintAction", "Lari")
ContextActionService:SetPosition("SprintAction", UDim2.new(1, -90, 0.5, -40))

-- Saat karakter mati/reset, lepas binding
humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("SprintAction")
end)
