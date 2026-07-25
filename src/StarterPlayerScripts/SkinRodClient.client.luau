local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()
local SkinConfig = require(ReplicatedStorage.Modules.SkinConfig)

local viewportModelsFolder = ReplicatedStorage:WaitForChild("SkinViewportModels")

local fishingGui = playerGui:WaitForChild("Fishing")
local skinRodGui = fishingGui:WaitForChild("SkinRod")
local skinsRodFrame = skinRodGui:WaitForChild("SkinsRodFrame")

local navbar = skinsRodFrame:WaitForChild("Navbar")
local scrollingFrame = skinsRodFrame:WaitForChild("ScrollingFrame")
local card1Template = scrollingFrame:WaitForChild("Card1")

local closeFrame = skinsRodFrame:WaitForChild("CloseFrame")
local closeButton = closeFrame:WaitForChild("CloseButton")

skinRodGui.Enabled = true

local buttonFrame = skinRodGui:FindFirstChild("ButtonFrame", true)
local openButton = buttonFrame and buttonFrame:FindFirstChild("Button", true)

card1Template.Visible = false

local currentCards = {}

local defaultPos = skinsRodFrame.Position
local hiddenPos = UDim2.new(defaultPos.X.Scale, defaultPos.X.Offset, -0.5, 0)
skinsRodFrame.Position = hiddenPos
skinsRodFrame.Visible = false

local isMenuOpen = false

local function openSkinFrame()
	if isMenuOpen then return end
	isMenuOpen = true
	skinsRodFrame.Visible = true
	remotes.SkinRodDataRequest:FireServer()
	
	TweenService:Create(skinsRodFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = defaultPos}):Play()
end

local function closeSkinFrame()
	if not isMenuOpen then return end
	isMenuOpen = false
	
	local t = TweenService:Create(skinsRodFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = hiddenPos})
	t:Play()
	t.Completed:Wait()
	skinsRodFrame.Visible = false
end

if openButton then
	openButton.Activated:Connect(openSkinFrame)
else
	warn("[SkinRodClient] Tombol buka (ButtonFrame > Button) tidak ditemukan di dalam ScreenGui SkinRod")
end

-- Hover animation untuk close button
local defaultCloseSize = closeButton.Size
closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), {Size = UDim2.new(defaultCloseSize.X.Scale * 1.1, defaultCloseSize.X.Offset * 1.1, defaultCloseSize.Y.Scale * 1.1, defaultCloseSize.Y.Offset * 1.1)}):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), {Size = defaultCloseSize}):Play()
end)
closeButton.Activated:Connect(closeSkinFrame)

local function clearCards()
	for _, card in currentCards do
		card:Destroy()
	end
	currentCards = {}
end

-- Render model 3D skin ke dalam ViewportFrame card
local function populateViewport(viewportFrame, skinName)
	for _, child in viewportFrame:GetChildren() do
		if child:IsA("Camera") or child:IsA("Model") or child:IsA("BasePart") then
			child:Destroy()
		end
	end

	local modelTemplate = viewportModelsFolder:FindFirstChild(skinName)
	if not modelTemplate then return end

	local clone = modelTemplate:Clone()
	clone.Parent = viewportFrame

	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local ok, cframe, size = pcall(function()
		return clone:GetBoundingBox()
	end)

	if ok and cframe then
		local maxSize = math.max(size.X, size.Y, size.Z, 1)
		local distance = maxSize * 1.8
		camera.CFrame = CFrame.new(
			cframe.Position + Vector3.new(distance * 0.6, distance * 0.4, distance * 0.6),
			cframe.Position
		)
	end
end

-- Cuma tampilkan Equip/Equipped, karena yang muncul di sini SELALU yang sudah dimiliki.
-- Skin yang belum dibeli difilter dan tidak dibuat card-nya sama sekali.
local function updateButtonState(button, isEquipped)
	button.Text = isEquipped and "Equipped" or "Equip"
end

local function buildCards(payload)
	clearCards()

	local ownedSet = {}
	for _, owned in payload.owned do
		ownedSet[owned] = true
	end

	for _, skin in payload.skins do
		-- FIX: skip skin yang belum dimiliki, tidak ditampilkan sama sekali
		if ownedSet[skin.name] then
			local card = card1Template:Clone()
			card.Name = "Card_" .. skin.name
			card.Visible = true
			card.Parent = scrollingFrame

			local nameLabel = card:FindFirstChild("NameSkins", true)
			if nameLabel then
				nameLabel.Text = skin.name
			end

			local viewportFrame = card:FindFirstChildWhichIsA("ViewportFrame", true)
			if viewportFrame then
				populateViewport(viewportFrame, skin.name)
			end

			local button = card:FindFirstChild("EquipUnequipButton", true)
			local isEquipped = payload.equipped == skin.name

			if button then
				updateButtonState(button, isEquipped)

				button.Activated:Connect(function()
					remotes.SkinRodEquip:FireServer(skin.name)
				end)
			end

			table.insert(currentCards, card)
		end
	end
end

remotes.SkinRodDataResponse.OnClientEvent:Connect(function(payload)
	buildCards(payload)
end)

remotes.SkinRodResult.OnClientEvent:Connect(function(success, message)
	print(success and ("[Skin] " .. message) or ("[Skin] Gagal: " .. message))
end)	