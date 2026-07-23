-- ============================================================
-- SettingsClient.client.luau
-- Logika UI untuk Menu Settings (Music, SFX, Graphic, VFX)
-- ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local settingsGui = script.Parent
local settingsF = settingsGui:WaitForChild("SettingsF")

local closeFrame = settingsF:WaitForChild("CloseFrame")
local musicFrame = settingsF:WaitForChild("MusicFrame")
local sfxFrame = settingsF:WaitForChild("SfxFrame")
local graphicFrame = settingsF:WaitForChild("GraphicFrame")
local vfxFrame = settingsF:WaitForChild("VfxFrame")

local closeBtn = closeFrame:WaitForChild("CloseButton")
local musicBtn = musicFrame:WaitForChild("OnOff")
local sfxBtn = sfxFrame:WaitForChild("OnOff")
local graphicBtn = graphicFrame:WaitForChild("HighLow")
local vfxBtn = vfxFrame:WaitForChild("OnOff")

-- Set status awal langsung tertutup!
settingsGui.Enabled = false
settingsF.Visible = false

-- Setup Efek Blur
local blurEffect = Lighting:FindFirstChild("SettingsBlur")
if not blurEffect then
	blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "SettingsBlur"
	blurEffect.Size = 0
	blurEffect.Parent = Lighting
end

-- Setup Skala Animasi Frame
local frameScale = settingsF:FindFirstChild("UIScale")
if not frameScale then
	frameScale = Instance.new("UIScale")
	frameScale.Parent = settingsF
end
frameScale.Scale = 1 -- Kembalikan ke 1 karena sekarang pakai Position

-- Tambahkan ToggleEvent untuk sinkronisasi MainMenu
local toggleEvent = settingsGui:FindFirstChild("ToggleEvent")
if not toggleEvent then
	toggleEvent = Instance.new("BindableEvent")
	toggleEvent.Name = "ToggleEvent"
	toggleEvent.Parent = settingsGui
end

-- Set atribut default di player jika belum ada
if player:GetAttribute("MusicEnabled") == nil then player:SetAttribute("MusicEnabled", true) end
if player:GetAttribute("SfxEnabled") == nil then player:SetAttribute("SfxEnabled", true) end
if player:GetAttribute("VfxEnabled") == nil then player:SetAttribute("VfxEnabled", true) end
if player:GetAttribute("GraphicLevel") == nil then player:SetAttribute("GraphicLevel", "High") end

-- Animasi Tombol
local function animateClick(button)
	local originalSize = button.Size
	local uiScale = button:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = button
	end
	
	TweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.8}):Play()
	task.wait(0.1)
	TweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- Update tampilan tombol ON/OFF
local function updateOnOffButton(button, isEnabled)
	if isEnabled then
		button.Text = "ON"
		button.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
	else
		button.Text = "OFF"
		button.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Merah
	end
end

-- Update tampilan tombol High/Low
local function updateHighLowButton(button, level)
	if level == "High" then
		button.Text = "HIGH"
		button.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
	else
		button.Text = "LOW"
		button.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Merah
	end
end

-- Terapkan tampilan awal
updateOnOffButton(musicBtn, player:GetAttribute("MusicEnabled"))
updateOnOffButton(sfxBtn, player:GetAttribute("SfxEnabled"))
updateOnOffButton(vfxBtn, player:GetAttribute("VfxEnabled"))
updateHighLowButton(graphicBtn, player:GetAttribute("GraphicLevel"))

local isAnimating = false
local isOpen = false

local function setSettingsState(state)
	if isAnimating or isOpen == state then return end
	isAnimating = true
	isOpen = state

	if state then
		settingsGui.Enabled = true
		settingsF.Visible = true
		settingsF.Position = UDim2.new(0.5, 0, -0.5, 0) -- Dari luar layar atas
		TweenService:Create(settingsF, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		TweenService:Create(blurEffect, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 24}):Play()
		task.wait(0.4)
	else
		TweenService:Create(settingsF, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
		TweenService:Create(blurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0}):Play()
		task.wait(0.3)
		settingsGui.Enabled = false
	end
	isAnimating = false
end

toggleEvent.Event:Connect(setSettingsState)

-- Tombol Close
closeBtn.MouseButton1Click:Connect(function()
	animateClick(closeBtn)
	setSettingsState(false)
end)

-- Tombol Music
musicBtn.MouseButton1Click:Connect(function()
	animateClick(musicBtn)
	local newState = not player:GetAttribute("MusicEnabled")
	player:SetAttribute("MusicEnabled", newState)
	updateOnOffButton(musicBtn, newState)
	
	-- Matikan/Nyalakan semua lagu di workspace atau SoundService
	for _, sound in ipairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") and (sound.Name:lower():match("music") or sound.Name:lower():match("bgm")) then
			sound.Volume = newState and 0.5 or 0
		end
	end
end)

-- Tombol SFX
sfxBtn.MouseButton1Click:Connect(function()
	animateClick(sfxBtn)
	local newState = not player:GetAttribute("SfxEnabled")
	player:SetAttribute("SfxEnabled", newState)
	updateOnOffButton(sfxBtn, newState)
end)

-- Tombol VFX
vfxBtn.MouseButton1Click:Connect(function()
	animateClick(vfxBtn)
	local newState = not player:GetAttribute("VfxEnabled")
	player:SetAttribute("VfxEnabled", newState)
	updateOnOffButton(vfxBtn, newState)
end)

-- Tombol Graphic
graphicBtn.MouseButton1Click:Connect(function()
	animateClick(graphicBtn)
	local current = player:GetAttribute("GraphicLevel")
	local newState = (current == "High") and "Low" or "High"
	player:SetAttribute("GraphicLevel", newState)
	updateHighLowButton(graphicBtn, newState)
	
	-- Manipulasi grafis dasar (matikan bayangan global jika Low)
	if newState == "Low" then
		Lighting.GlobalShadows = false
	else
		Lighting.GlobalShadows = true
	end
end)

print("[SettingsClient] Script berhasil dimuat dan UI fungsional!")
