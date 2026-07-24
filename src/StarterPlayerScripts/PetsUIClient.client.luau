local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

-- Cari ScreenGui Pets buatan user
local petsGui = playerGui:WaitForChild("Pets")

-- ==========================================
-- MEMBANGUN UI AESTHETIC SECARA DINAMIS
-- ==========================================

-- Container Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "PetsContainer"
mainFrame.Size = UDim2.new(0, 500, 0, 350)
local openPos = UDim2.new(0.5, 0, 0.5, 0)
local closePos = UDim2.new(0.5, 0, -0.5, 0) -- Mulai dari atas layar
mainFrame.Position = closePos
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 255)
mainFrame.BackgroundTransparency = 0.05
mainFrame.Parent = petsGui
mainFrame.Visible = false -- Sembunyikan default (terserah user memunculkannya lewat tombolnya sendiri, tapi kita tambahkan tombol close nanti)

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 15)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(220, 220, 230)
uiStroke.Thickness = 2
uiStroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "My Pets"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(60, 60, 70)
title.Parent = mainFrame

-- Tombol Close X
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 15)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100) -- Merah lembut
closeBtn.Parent = mainFrame

local isMenuOpen = false

local function closeMenu()
	if not isMenuOpen then return end
	isMenuOpen = false
	local t = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = closePos})
	t:Play()
	t.Completed:Wait()
	mainFrame.Visible = false
end

local function openMenu()
	if isMenuOpen then return end
	isMenuOpen = true
	mainFrame.Visible = true
	TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = openPos}):Play()
end

-- Animasi Hover Tombol X
closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 0, 0)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play()
end)

closeBtn.MouseButton1Click:Connect(closeMenu)

-- Tombol Buka Menu (Berjaga-jaga jika tombol user belum berfungsi)
local openBtn = petsGui:FindFirstChildWhichIsA("TextButton", true) or petsGui:FindFirstChildWhichIsA("ImageButton", true)
if openBtn then
	openBtn.MouseButton1Click:Connect(function()
		if isMenuOpen then
			closeMenu()
		else
			openMenu()
		end
	end)
end

-- Scroll View
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "PetList"
scroll.Size = UDim2.new(1, -40, 1, -110)
scroll.Position = UDim2.new(0, 20, 0, 50)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 210)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = mainFrame

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 100, 0, 120)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 5)
uiPadding.PaddingLeft = UDim.new(0, 5)
uiPadding.Parent = scroll

-- Action Panel (Tombol Equip/Unequip)
local actionPanel = Instance.new("Frame")
actionPanel.Name = "ActionPanel"
actionPanel.Size = UDim2.new(1, -40, 0, 45)
actionPanel.Position = UDim2.new(0, 20, 1, -55)
actionPanel.BackgroundTransparency = 1
actionPanel.Parent = mainFrame

local equipBtn = Instance.new("TextButton")
equipBtn.Name = "EquipBtn"
equipBtn.Size = UDim2.new(1, 0, 1, 0)
equipBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
equipBtn.Text = "Select a Pet"
equipBtn.Font = Enum.Font.GothamBold
equipBtn.TextSize = 16
equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
equipBtn.AutoButtonColor = false
equipBtn.Parent = actionPanel

local equipCorner = Instance.new("UICorner")
equipCorner.CornerRadius = UDim.new(0, 8)
equipCorner.Parent = equipBtn

-- ==========================================
-- LOGIC INVENTORY PET
-- ==========================================

local ownedPets = {}
local equippedPet = ""
local selectedPet = ""
local petFrames = {}
local rotationConnections = {}

local function clearRotation()
	for _, conn in rotationConnections do
		conn:Disconnect()
	end
	table.clear(rotationConnections)
end

local function updateEquipButton()
	if selectedPet == "" then
		equipBtn.Text = "Select a Pet"
		equipBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	elseif selectedPet == equippedPet then
		equipBtn.Text = "Unequip"
		equipBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	else
		equipBtn.Text = "Equip"
		equipBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
	end
end

equipBtn.MouseButton1Click:Connect(function()
	if selectedPet == "" then return end
	
	-- Animasi klik
	local ts = TweenService:Create(equipBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.95, 0, 0.9, 0)})
	ts:Play()
	ts.Completed:Wait()
	TweenService:Create(equipBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 1, 0)}):Play()
	
	local targetPet = selectedPet
	if selectedPet == equippedPet then
		targetPet = "" -- unequip
	end
	
	-- Minta server untuk equip
	remotes.PetEquip:FireServer(targetPet)
end)

local function buildInventory()
	-- Bersihkan list lama
	for _, frame in petFrames do
		frame:Destroy()
	end
	table.clear(petFrames)
	clearRotation()
	
	for i, petName in ownedPets do
		local card = Instance.new("TextButton")
		card.Name = "Pet_" .. petName
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		card.Text = ""
		card.AutoButtonColor = false
		card.Parent = scroll
		
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card
		
		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = (petName == equippedPet) and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(230, 230, 235)
		cardStroke.Thickness = (petName == equippedPet) and 3 or 1
		cardStroke.Parent = card
		
		if petName == selectedPet then
			card.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
		end
		
		-- Label "EQUIPPED"
		if petName == equippedPet then
			local eqLabel = Instance.new("TextLabel")
			eqLabel.Size = UDim2.new(1, 0, 0, 15)
			eqLabel.Position = UDim2.new(0, 0, 0, 2)
			eqLabel.BackgroundTransparency = 1
			eqLabel.Text = "EQUIPPED"
			eqLabel.Font = Enum.Font.GothamBold
			eqLabel.TextSize = 10
			eqLabel.TextColor3 = Color3.fromRGB(70, 200, 100)
			eqLabel.ZIndex = 2
			eqLabel.Parent = card
		end
		
		-- Nama Pet
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 25)
		nameLabel.Position = UDim2.new(0, 0, 1, -25)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = petName:gsub("_", " ")
		nameLabel.Font = Enum.Font.GothamMedium
		nameLabel.TextSize = 12
		nameLabel.TextColor3 = Color3.fromRGB(80, 80, 90)
		nameLabel.Parent = card
		
		-- ViewportFrame
		local vp = Instance.new("ViewportFrame")
		vp.Size = UDim2.new(1, -10, 1, -35)
		vp.Position = UDim2.new(0, 5, 0, 5)
		vp.BackgroundTransparency = 1
		vp.Parent = card
		
		local cam = Instance.new("Camera")
		cam.FieldOfView = 70
		vp.CurrentCamera = cam
		vp.Parent = card
		
		-- Load model pet secara lokal
		task.spawn(function()
			-- Meminta model dari ReplicatedStorage/ServerStorage tidak bisa dari client secara langsung jika di ServerStorage.
			-- TAPI karena client hanya punya akses ke ReplicatedStorage, kita asumsikan modelnya digandakan ke ReplicatedStorage ATAU kita gunakan dummy parts.
			-- SEBAGAI SOLUSI: Player sebenarnya bisa melihat model di Workspace jika sudah ada yang spawn.
			-- Karena kita butuh ViewportFrame, idealnya server meletakkan folder Pets di ReplicatedStorage. 
			-- TAPI user merequest "saya taruh di serverstorage". 
			-- Jika di ServerStorage, client TIDAK BISA melihatnya. 
			-- Solusinya: Saat script ini jalan, kita cari apakah petnya sudah ada di Workspace/Player, atau kita minta server kirim model.
			-- Paling simpel: kita minta user nanti (di chat) untuk pindahkan model Pets ke ReplicatedStorage agar UI bisa render 3D-nya. 
			-- Untuk sementara, kita taruh teks "No 3D" jika model tidak ditemukan di ReplicatedStorage.
			
			local repPets = ReplicatedStorage:FindFirstChild("Pets")
			if repPets then
				local model = repPets:FindFirstChild(petName)
				if model then
					local clone = model:Clone()
					clone.Parent = vp
					
					local cf, size = clone:GetBoundingBox()
					local maxDim = math.max(size.X, size.Y, size.Z)
					local dist = maxDim * 1.5
					
					local angle = 0
					local conn = RunService.RenderStepped:Connect(function(dt)
						angle = angle + math.rad(30 * dt)
						local camCf = CFrame.new(cf.Position + Vector3.new(math.sin(angle)*dist, dist*0.3, math.cos(angle)*dist), cf.Position)
						cam.CFrame = camCf
					end)
					table.insert(rotationConnections, conn)
				end
			else
				local text = Instance.new("TextLabel")
				text.Size = UDim2.new(1,0,1,0)
				text.BackgroundTransparency = 1
				text.Text = "3D N/A\n(Move Pets to\nReplicatedStorage)"
				text.TextScaled = true
				text.TextColor3 = Color3.fromRGB(200,200,200)
				text.Font = Enum.Font.Gotham
				text.Parent = vp
			end
		end)
		
		card.MouseButton1Click:Connect(function()
			selectedPet = petName
			buildInventory()
		end)
		
		table.insert(petFrames, card)
	end
	
	updateEquipButton()
end

-- Dengarkan balasan data pet
remotes.PetDataResponse.OnClientEvent:Connect(function(owned, equipped)
	ownedPets = owned
	equippedPet = equipped
	
	-- Jika pet yang di-select belum dimiliki lagi, reset
	local stillOwns = false
	for _, p in ownedPets do
		if p == selectedPet then stillOwns = true end
	end
	if not stillOwns then selectedPet = "" end
	
	buildInventory()
end)

-- Notifikasi pembelian pet
remotes.PetPurchased.OnClientEvent:Connect(function(success, message)
	-- Gunakan UI CashReward/Notifikasi yang ada (atau buat Text sederhana)
	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(0, 300, 0, 50)
	notif.Position = UDim2.new(0.5, 0, 0.8, 0)
	notif.AnchorPoint = Vector2.new(0.5, 0.5)
	notif.BackgroundColor3 = success and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(255, 80, 80)
	notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	notif.Text = message
	notif.Font = Enum.Font.GothamBold
	notif.TextSize = 16
	notif.Parent = petsGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif
	
	TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, 0, 0.75, 0)}):Play()
	task.delay(3, function()
		local t = TweenService:Create(notif, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1})
		t:Play()
		t.Completed:Wait()
		notif:Destroy()
	end)
end)

-- Request data awal saat login
task.spawn(function()
	task.wait(2)
	remotes.PetDataRequest:FireServer()
end)

print("[PetsUIClient] Sistem UI Pet aesthetic berhasil dimuat!")
