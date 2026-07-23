local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AdminRemotes = ReplicatedStorage:WaitForChild("AdminRemotes", 10)
if not AdminRemotes then return end

local AnnounceEvent = AdminRemotes:WaitForChild("AnnounceEvent")
local WarnEvent = AdminRemotes:WaitForChild("WarnEvent")

-- ==========================================
-- FUNGSI: UI ANNOUNCE (Custom dari User)
-- ==========================================
local AnnouncementEvent = ReplicatedStorage:WaitForChild("GlobalAnnouncementEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnnouncementGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 1, 0)
container.BackgroundTransparency = 1
container.Parent = screenGui

local messageDuration = 6
local spacing = 0.09
local startingY = 0.1
local activeMessages = {}

local function createAnnouncement(displayName, prefix, message, nameColor)
	local messageIndex = #activeMessages + 1
	local yPos = startingY + (messageIndex - 1) * spacing

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0.6, 0, 0.07, 0)
	holder.Position = UDim2.new(0.5, 0, yPos, 0)
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = container

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 1
	bg.Parent = holder

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, 0),
		NumberSequenceKeypoint.new(0.9, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = bg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.Cartoon
	label.TextSize = 24
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTransparency = 1
	label.RichText = true
	label.Parent = holder

	local verifiedBadge = utf8.char(0xE000)
	
	if nameColor then
		local r = math.floor(nameColor.R * 255)
		local g = math.floor(nameColor.G * 255)
		local b = math.floor(nameColor.B * 255)
		label.Text = string.format('<font color="rgb(%d,%d,%d)">%s%s</font>%s: %s', r, g, b, displayName, verifiedBadge, prefix or "", message)
	else
		label.Text = string.format("%s%s%s: %s", displayName, verifiedBadge, prefix or "", message)
	end

	holder.Size = UDim2.new(0, label.TextBounds.X + 40, 0.07, 0)

	table.insert(activeMessages, holder)

	TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
	TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

	task.delay(messageDuration, function()
		local fadeBg = TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		local fadeText = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
		fadeBg:Play()
		fadeText:Play()
		fadeText.Completed:Wait()

		local indexToRemove = table.find(activeMessages, holder)
		if indexToRemove then
			table.remove(activeMessages, indexToRemove)
			holder:Destroy()
			for i = indexToRemove, #activeMessages do
				local targetY = startingY + (i - 1) * spacing
				TweenService:Create(activeMessages[i], TweenInfo.new(0.3), {
					Position = UDim2.new(0.5, 0, targetY, 0)
				}):Play()
			end
		end
	end)
end

local TextChatService = game:GetService("TextChatService")

AnnouncementEvent.OnClientEvent:Connect(function(data)
	if typeof(data) == "table" then
		if data.isChatOnly then
			local formattedText = "<font color='#FFB300'><b>📢 [SERVER]: " .. data.message .. "</b></font>"
			local rbxSystem = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXSystem")
			if rbxSystem then
				rbxSystem:DisplaySystemMessage(formattedText)
			else
				game.StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = "📢 [SERVER]: " .. data.message,
					Color = Color3.fromRGB(255, 179, 0),
					Font = Enum.Font.SourceSansBold,
					FontSize = Enum.FontSize.Size18
				})
			end
			return
		end
		
		if data.displayName and data.message then
			createAnnouncement(data.displayName, data.prefix, data.message, data.nameColor)
		end
	end
end)

-- ==========================================
-- FUNGSI: UI WARN (Modern Alert)
-- ==========================================
WarnEvent.OnClientEvent:Connect(function(text, adminId, adminName)
	local sg = Instance.new("ScreenGui")
	sg.Name = "ModernWarning"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = playerGui
	
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = sg
	
	local container = Instance.new("Frame")
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.Size = UDim2.new(0.85, 0, 0, 200)
	container.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
	container.BackgroundTransparency = 0.1
	container.Parent = overlay
	
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(500, 250)
	constraint.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(255, 40, 40)
	stroke.Parent = container
	
	-- Icon Warning besar di tengah atas (Atau Avatar)
	local icon = Instance.new("ImageLabel")
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, -40)
	icon.Size = UDim2.new(0, 80, 0, 80)
	icon.BackgroundTransparency = 1
	icon.Parent = container
	
	if adminId and tonumber(adminId) then
		local content = Players:GetUserThumbnailAsync(tonumber(adminId), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		icon.Image = content
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = icon
		local strokeImg = Instance.new("UIStroke")
		strokeImg.Thickness = 3
		strokeImg.Color = Color3.fromRGB(255, 60, 60)
		strokeImg.Parent = icon
	else
		icon.Image = "rbxassetid://6023426915" -- Warning triangle icon
		icon.ImageColor3 = Color3.fromRGB(255, 60, 60)
	end
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 45)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	if adminId and tonumber(adminId) then
		local robloxName = adminName
		pcall(function()
			robloxName = Players:GetNameFromUserIdAsync(tonumber(adminId))
		end)
		title.Text = "PERINGATAN DARI " .. string.upper(robloxName) .. "!"
	else
		title.Text = "PERINGATAN!"
	end
	title.TextColor3 = Color3.fromRGB(255, 60, 60)
	title.TextSize = 24
	title.Parent = container
	
	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -40, 1, -95)
	msg.Position = UDim2.new(0, 20, 0, 75)
	msg.BackgroundTransparency = 1
	msg.Font = Enum.Font.GothamMedium
	msg.Text = text
	msg.TextColor3 = Color3.fromRGB(220, 220, 220)
	msg.TextSize = 18
	msg.TextWrapped = true
	msg.TextYAlignment = Enum.TextYAlignment.Top
	msg.RichText = true
	msg.Parent = container
	
	-- Animasi Popup Alert
	container.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.85, 0, 0, 200)}):Play()
	
	-- Efek Berkedip Merah pada stroke
	task.spawn(function()
		for i = 1, 10 do
			if not stroke.Parent then break end
			TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(150, 0, 0)}):Play()
			task.wait(0.3)
			TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 40, 40)}):Play()
			task.wait(0.3)
		end
	end)
	
	task.wait(8)
	
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	local out = TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
	out:Play()
	out.Completed:Wait()
	
	sg:Destroy()
end)
