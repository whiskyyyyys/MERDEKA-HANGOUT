local PlayersService = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local BackpackGui = script.Parent:WaitForChild("BackpackGui")
local SlotTemplate = BackpackGui.BackpackSlot
local BackpackButton = BackpackGui.BackpackButton
local SelectionUi = BackpackGui.SelectionUI
local ToolTip = BackpackGui.ToolTip
local InventoryUI = BackpackGui.InventoryMain
local HintUI = BackpackGui.Hint

local BackpackManager = require(script.Parent:WaitForChild("BackpackManager"))

local InventoryOpenedSignal = nil
local InventoryClosedSignal = nil

local KeyboardEnabled = false
local TouchEnabled = false
local MouseEnabled = false

function LargeScreenDetected() -- Change or remove if you have tool slots with custom sizes in mind.
	SlotTemplate.Button.ToolNum.Size = UDim2.fromOffset(24, 27)
	BackpackButton.Size = UDim2.fromOffset(93, 78)
	ToolTip.Size = UDim2.fromOffset(130, 35)

	SlotTemplate.Button.ToolName.TextSize = 24
	ToolTip.TipText.TextSize = 22
	SlotTemplate.Button.CooldownText.TextSize = 40

	InventoryUI.Size = UDim2.fromOffset(939,604)
	InventoryUI.TextBox.TextSize = 28

	HintUI.Size = UDim2.fromOffset(215,61)
	HintUI.Background.HintText.TextSize = 37
	
	BackpackManager.Settings.IconScale = 1.8
	BackpackManager.Settings.HotbarYOffset += 25
	BackpackManager.Settings.InventoryYOffset += 135
	BackpackManager.Settings.BackpackButtonXOffset += 60
	BackpackManager.Settings.ToolTipYOffset -= 10
end

function SmallScreenDetected()  -- Change or remove if you have the inventory with a custom size in mind.
	InventoryUI.Size = UDim2.fromOffset(401, 218)
	BackpackManager.Settings.InventoryYOffset -= 40
	HintUI.Background.HintIcon.Size = UDim2.fromOffset(22, 22)
	HintUI.Size = UDim2.fromOffset(104, 30)
end

function NoKeyboardDetected()
	BackpackManager.Settings.ShowToolNumber = false
end

function disableOrganizingOnMobileDevices()
	BackpackManager.Settings.CanOrganize = false
	
	InventoryOpenedSignal = BackpackManager.InventoryOpened:Connect(function()
		BackpackManager.Settings.CanOrganize = true
	end)

	InventoryClosedSignal = BackpackManager.InventoryClosed:Connect(function()
		BackpackManager.Settings.CanOrganize = false
	end)

end

local function isKeyboardEnabled()
	KeyboardEnabled = UserInputService.KeyboardEnabled
	
	if not UserInputService.KeyboardEnabled then
		NoKeyboardDetected()
	else
		BackpackManager.Settings.ShowToolNumber = true
	end
end

local function isMobileScreen()  -- You may need to change this if you want to change the "CanOrganize" setting.
	TouchEnabled = UserInputService.TouchEnabled
	MouseEnabled = UserInputService.MouseEnabled
	
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		disableOrganizingOnMobileDevices()
	else
		BackpackManager.Settings.CanOrganize = true
		if InventoryClosedSignal then InventoryClosedSignal:Disconnect() end
		if InventoryOpenedSignal then InventoryOpenedSignal:Disconnect() end
	end
end

if GuiService:IsTenFootInterface() then 
	LargeScreenDetected()
end

if GuiService.ViewportDisplaySize == Enum.DisplaySize.Small then
	SmallScreenDetected()
end

isKeyboardEnabled()
isMobileScreen() 

local function KeyboardChanged()
	if UserInputService.KeyboardEnabled == KeyboardEnabled then return end
	isKeyboardEnabled()
	BackpackManager:ResetGui()
end

local function TouchScreenChanged()
	if UserInputService.TouchEnabled == TouchEnabled and UserInputService.MouseEnabled == MouseEnabled then return end
	isMobileScreen()
	BackpackManager:ResetGui()
end

UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(KeyboardChanged)
-- INJECT FAVORITE BUTTON KE SLOT TEMPLATE
local favBtn = Instance.new("TextButton")
favBtn.Name = "FavoriteBtn"
favBtn.Size = UDim2.new(0, 26, 0, 26)
favBtn.Position = UDim2.new(1, -30, 0, 4)
favBtn.BackgroundTransparency = 1
favBtn.Text = "★"
favBtn.TextScaled = true
favBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
favBtn.TextStrokeTransparency = 0.5
favBtn.Font = Enum.Font.FredokaOne
favBtn.ZIndex = 15
favBtn.Visible = false -- Sembunyikan default (hanya muncul buat ikan)
favBtn.Parent = SlotTemplate.Button

local RemotesUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RemotesUtil"))
local remotes = RemotesUtil.Get()

BackpackManager.ToolAdded:Connect(function(tool, container)
	if not tool:GetAttribute("Rarity") then return end
	
	task.defer(function()
		task.wait(0.2)
		if not container or not container.Parent then return end
		
		for _, btn in ipairs(container:GetDescendants()) do
			if btn.Name == "FavoriteBtn" and not btn:GetAttribute("Setup") then
				local toolNameLabel = btn.Parent:FindFirstChild("ToolName")
				if toolNameLabel and toolNameLabel.Text == tool.Name then
					btn:SetAttribute("Setup", true)
					btn.Visible = true
					
					local function updateIcon()
						if tool:GetAttribute("IsFavorited") then
							btn.TextColor3 = Color3.fromRGB(255, 215, 0) -- Emas
						else
							btn.TextColor3 = Color3.fromRGB(150, 150, 150) -- Abu-abu
						end
					end
					updateIcon()
					
					local conn = tool:GetAttributeChangedSignal("IsFavorited"):Connect(updateIcon)
					btn.Destroying:Connect(function() conn:Disconnect() end)
					
					btn.Activated:Connect(function()
						local newState = not tool:GetAttribute("IsFavorited")
						tool:SetAttribute("IsFavorited", newState)
						remotes.ToggleFavoriteFish:FireServer(tool, newState)
					end)
					
					return -- Selesai mengikat tombol ini
				end
			end
		end
	end)
end)

BackpackManager.StartBackpack() -- :D