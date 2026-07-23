local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ZONE_NAME = "SpinMachine"
local MAX_DISTANCE = 15 -- Jarak maksimum untuk membuka Spin GUI

-- Buat efek Blur untuk menu Spin jika belum ada
local spinBlur = Lighting:FindFirstChild("SpinBlur")
if not spinBlur then
	spinBlur = Instance.new("BlurEffect")
	spinBlur.Name = "SpinBlur"
	spinBlur.Size = 0
	spinBlur.Parent = Lighting
end

local isGuiOpen = false

local function setGuiState(state)
	if isGuiOpen == state then return end
	
	local spinGui = playerGui:FindFirstChild("SpinGui")
	if not spinGui then return end
	
	local spinFrame = spinGui:FindFirstChild("Spin")
	if not spinFrame then return end
	
	local camera = workspace.CurrentCamera
	isGuiOpen = state

	if state then
		spinGui.Enabled = true
		spinFrame.Visible = true
		
		-- Setup ukuran awal animasi pop-up
		spinFrame.Size = UDim2.fromScale(0, 0)
		spinFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		spinFrame.Position = UDim2.fromScale(0.5, 0.5)
		
		TweenService:Create(spinFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
		TweenService:Create(camera, TweenInfo.new(0.3), {FieldOfView = 85}):Play()
		TweenService:Create(spinBlur, TweenInfo.new(0.3), {Size = 24}):Play()
	else
		-- Animasi menutup
		TweenService:Create(spinFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)}):Play()
		local camTween = TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 70})
		camTween:Play()
		TweenService:Create(spinBlur, TweenInfo.new(0.2), {Size = 0}):Play()
		
		camTween.Completed:Once(function()
			spinFrame.Visible = false
			spinGui.Enabled = false
		end)
	end
end

local cachedSpinMachine = nil
local warningShown = false

-- Fungsi untuk mencari Spin Machine
local function findSpinMachine()
	if cachedSpinMachine and cachedSpinMachine.Parent then return cachedSpinMachine end
	
	local found = workspace:FindFirstChild(ZONE_NAME, true)
	if not found then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if string.match(string.lower(obj.Name), "spin") and (obj:IsA("BasePart") or obj:IsA("Model")) then
				found = obj
				break
			end
		end
	end
	
	if found and not warningShown then
		print("[SpinZoneClient] Spin Machine ditemukan: " .. found.Name)
		warningShown = true
	end
	
	cachedSpinMachine = found
	return found
end

-- Deteksi jarak secara berkala
task.spawn(function()
	while task.wait(0.5) do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		
		if rootPart then
			local spinMachine = findSpinMachine()
			
			if spinMachine then
				local targetPos
				if spinMachine:IsA("BasePart") then
					targetPos = spinMachine.Position
				elseif spinMachine:IsA("Model") then
					if spinMachine.PrimaryPart then
						targetPos = spinMachine.PrimaryPart.Position
					else
						local firstPart = spinMachine:FindFirstChildWhichIsA("BasePart", true)
						if firstPart then targetPos = firstPart.Position end
					end
				end

				if targetPos then
					-- Jika jaraknya kurang dari 30 studs, buka GUI
					local distance = (rootPart.Position - targetPos).Magnitude
					if distance <= 30 then
						setGuiState(true)
					else
						setGuiState(false)
					end
				else
					setGuiState(false)
				end
			else
				setGuiState(false)
				if not warningShown then
					warn("[SpinZoneClient] GAGAL: Tidak ada part atau model bernama 'Spin' atau 'SpinMachine' di Workspace!")
					warningShown = true
				end
			end
		end
	end
end)

print("[SpinZoneClient] Script deteksi zone SpinMachine berjalan.")
