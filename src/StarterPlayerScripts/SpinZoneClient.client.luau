local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ZONE_NAME = "SpinMachine"
local MAX_DISTANCE = 10 -- Jarak maksimum untuk membuka Spin GUI

-- Buat efek Blur untuk menu Spin jika belum ada
local spinBlur = Lighting:FindFirstChild("SpinBlur")
if not spinBlur then
	spinBlur = Instance.new("BlurEffect")
	spinBlur.Name = "SpinBlur"
	spinBlur.Size = 0
	spinBlur.Parent = Lighting
end

local isGuiOpen = false
local hiddenGuis = {}

local function setGuiState(state)
	if isGuiOpen == state then return end
	
	local spinGui = playerGui:FindFirstChild("SpinGui")
	if not spinGui then return end
	
	local spinFrame = spinGui:FindFirstChild("Spin")
	if not spinFrame then return end
	
	local camera = workspace.CurrentCamera
	isGuiOpen = state

	if state then
		-- Sembunyikan UI bawaan Roblox (Chat, Leaderboard, dll)
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
		
		-- Sembunyikan semua UI custom buatan player (kecuali SpinGui)
		table.clear(hiddenGuis)
		for _, gui in playerGui:GetChildren() do
			if gui:IsA("ScreenGui") and gui.Name ~= "SpinGui" and gui.Enabled then
				hiddenGuis[gui] = true
				gui.Enabled = false
			end
		end
	
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
			
			-- Kembalikan UI bawaan Roblox
			pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			end)
			
			-- Kembalikan semua UI custom
			for gui, _ in hiddenGuis do
				if gui and gui.Parent then
					gui.Enabled = true
				end
			end
			table.clear(hiddenGuis)
		end)
	end
end

local spinMachines = {}
local hasSearched = false

-- Fungsi untuk mencari SEMUA Spin Machine di map (dijalankan berulang jika belum ketemu satupun)
local function getSpinMachines()
	if hasSearched and #spinMachines > 0 then return spinMachines end
	
	table.clear(spinMachines)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if string.lower(obj.Name) == "spinmachine" and (obj:IsA("BasePart") or obj:IsA("Model")) then
			table.insert(spinMachines, obj)
		end
	end
	
	if #spinMachines > 0 then
		hasSearched = true
		print("[SpinZoneClient] Ditemukan " .. #spinMachines .. " area SpinMachine di map.")
	end
	
	return spinMachines
end

-- Deteksi jarak secara berkala
task.spawn(function()
	while task.wait(0.5) do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		
		if rootPart then
			local machines = getSpinMachines()
			local closestDistance = math.huge
			local isNearAny = false
			
			for _, machine in ipairs(machines) do
				local targetPos
				if machine:IsA("BasePart") then
					targetPos = machine.Position
				elseif machine:IsA("Model") then
					if machine.PrimaryPart then
						targetPos = machine.PrimaryPart.Position
					else
						local firstPart = machine:FindFirstChildWhichIsA("BasePart", true)
						if firstPart then targetPos = firstPart.Position end
					end
				end

				if targetPos then
					local distance = (rootPart.Position - targetPos).Magnitude
					if distance < closestDistance then
						closestDistance = distance
					end
				end
			end
			
			if closestDistance <= MAX_DISTANCE then
				setGuiState(true)
			else
				setGuiState(false)
			end
		end
	end
end)

print("[SpinZoneClient] Script deteksi zone SpinMachine berjalan.")
