local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)

local storage = ReplicatedStorage:WaitForChild("EXE6_STORAGE")
local Utilities = require(storage.modules.Utilities)

local ActiveLeaf = {}
local FocusedLeaf
local Panel

local LeafData = {}

local module = {}

export type LeafProperties = {
	LockedZIndex: any,
	DragDisabled: any,
	NormalizeSize: any,
	DisableOtherLeafWhenFocused: any,
	DisablePanelWhenFocused: any,
	DisableForcedClose: any,
	
	MinSize: any,
	MaxSize: any
}

function module:Apply(Leaf, Properties: LeafProperties) 
	local screenSize = workspace.CurrentCamera.ViewportSize
	
	local x
	local y
	
	if screenSize.X > Properties.MinSize.X then
		x = math.clamp(Properties.MaxSize.X, Properties.MinSize.X, screenSize.X)
	else
		x = Properties.MinSize.X + 50
	end
	
	if screenSize.Y > Properties.MinSize.Y then
		y = math.clamp(Properties.MaxSize.Y, Properties.MinSize.Y, screenSize.Y)
	else
		y = Properties.MinSize.Y + 50
	end
	
	Properties.MaxSize = Vector2.new(x, y)

	LeafData[Leaf] = {
		MinSize = Properties.MinSize,
		MaxSize = Properties.MaxSize,
		BaseSize = Vector2.new(Leaf.Size.X.Offset, Leaf.Size.Y.Offset),
		
		LockedZIndex = Properties.LockedZIndex,
		DragDisabled = Properties.DragDisabled,
		NormalizeSize = Properties.NormalizeSize,
		DisableOtherLeafWhenFocused = Properties.DisableOtherLeafWhenFocused,
		DisablePanelWhenFocused = Properties.DisablePanelWhenFocused,
		DisableForcedClose = Properties.DisableForcedClose
	}
	
	local Data = LeafData[Leaf]

	local Frame = Leaf.frame
	local Controls = Frame:WaitForChild("LeafletControls")

	local Top = Controls:FindFirstChild("Top")
	local Bottom = Controls:FindFirstChild("Bottom")
	local ResizeHandle = Bottom and Bottom:FindFirstChild("Resize")
	
	if Data.NormalizeSize then
		local NormalizedSize = module:NormalizeLeafSize(Vector2.new(Leaf.Size.X.Offset, Leaf.Size.Y.Offset),
			Data.MinSize, Data.MaxSize)

		Leaf.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
	end

	local resizing = false
	local startPos, startSize

	local dragging = false
	local dragOffset

	-- Resize
	if Data.MinSize ~= Data.MaxSize then
		if ResizeHandle then
			ResizeHandle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					(input.UserInputType == Enum.UserInputType.Touch) then

					resizing = true
					startPos = UserInputService:GetMouseLocation()
					startSize = Leaf.Size
					
					Utilities.Haptic(1, .01)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					input.UserInputType == Enum.UserInputType.Touch then

					resizing = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if resizing and not dragging then
					local currentPos = UserInputService:GetMouseLocation()
					local delta = currentPos - startPos

					local newWidth = math.clamp(startSize.X.Offset + delta.X * 2, Data.MinSize.X, Data.MaxSize.X)
					local newHeight = math.clamp(startSize.Y.Offset + delta.Y * 2, Data.MinSize.Y, Data.MaxSize.Y)

					TweenService:Create(Leaf, info, {
						Size = UDim2.new(0, newWidth, 0, newHeight)
					}):Play()
				end
			end)
		end
	else
		ResizeHandle.Visible = false
	end
	
	-- Dragging
	if not Data.DragDisabled then
		if Top then
			Top.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					(input.UserInputType == Enum.UserInputType.Touch) then

					dragging = true
					Controls.Protection.Visible = true

					local mousePos = UserInputService:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
					dragOffset = mousePos - Top.AbsolutePosition
					
					Utilities.Haptic(1, .01)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or
					input.UserInputType == Enum.UserInputType.Touch then

					dragging = false
					Controls.Protection.Visible = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and not resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or
					input.UserInputType == Enum.UserInputType.Touch) then

					local screenSize = workspace.CurrentCamera.ViewportSize
					local frameSize = Frame.AbsoluteSize

					local mousePos = UserInputService:GetMouseLocation()
					local newTopLeft = mousePos - dragOffset

					local clampedTopLeft = Vector2.new(
						math.clamp(newTopLeft.X, 0, (screenSize.X - frameSize.X) + 100),
						math.clamp(newTopLeft.Y, 0, (screenSize.Y - frameSize.Y) + 100)
					)
					local finalCenter = clampedTopLeft + frameSize / 2

					TweenService:Create(Leaf, info, {
						Position = UDim2.new(0, finalCenter.X, 0, finalCenter.Y)
					}):Play()
				end
			end)
		end
	end

	-- Focus
	Controls.Space.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			(input.UserInputType == Enum.UserInputType.Touch) then

			module:CaptureFocus(Leaf)
		end
	end)
end

function module:ApplyMainFrame(MainFrame, Properties: LeafProperties)
	local screenSize = workspace.CurrentCamera.ViewportSize
	local FullscreenDefault = not (Utilities.GetViewportRatio() > 1300)

	Panel = MainFrame
	Properties.MaxSize = screenSize - Vector2.new(20, 20)

	local Content = MainFrame.content
	local Controls = Content:WaitForChild("LeafletControls")

	local Top = Controls:FindFirstChild("Top")
	local Bottom = Controls:FindFirstChild("Bottom")
	local ResizeHandle = Bottom and Bottom:FindFirstChild("Resize")

	local resizing = false
	local startPos, startSize

	local dragging = false
	local dragOffset

	if not FullscreenDefault then
		-- Resizing
		
		if ResizeHandle then
			ResizeHandle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					(input.UserInputType == Enum.UserInputType.Touch) then

					resizing = true
					startPos = UserInputService:GetMouseLocation()
					startSize = MainFrame.Size
					
					Utilities.Haptic(1, .01)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					input.UserInputType == Enum.UserInputType.Touch then

					resizing = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if resizing and not dragging then
					local currentPos = UserInputService:GetMouseLocation()
					local delta = currentPos - startPos

					local newWidth = math.clamp(startSize.X.Offset + delta.X * 2, Properties.MinSize.X, Properties.MaxSize.X)
					local newHeight = math.clamp(startSize.Y.Offset + delta.Y * 2, Properties.MinSize.Y, Properties.MaxSize.Y)

					TweenService:Create(MainFrame, info, {
						Size = UDim2.new(0, newWidth, 0, newHeight)
					}):Play()
				end
			end)
		end
		
		-- Dragging
		
		if Top then
			Top.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					(input.UserInputType == Enum.UserInputType.Touch) then
					
					if MainFrame:GetAttribute("Fullscreen") then return end

					dragging = true
					Controls.Protection.Visible = true

					local mousePos = UserInputService:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
					dragOffset = mousePos - Top.AbsolutePosition
					
					Utilities.Haptic(1, .01)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or
					input.UserInputType == Enum.UserInputType.Touch then

					dragging = false
					Controls.Protection.Visible = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and not resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or
					input.UserInputType == Enum.UserInputType.Touch) then

					local screenSize = workspace.CurrentCamera.ViewportSize
					local frameSize = MainFrame.AbsoluteSize

					local mousePos = UserInputService:GetMouseLocation()
					local newTopLeft = mousePos - dragOffset

					local clampedTopLeft = Vector2.new(
						math.clamp(newTopLeft.X, 0, (screenSize.X - frameSize.X) + 100),
						math.clamp(newTopLeft.Y, 0, (screenSize.Y - frameSize.Y) + 100)
					)
					local finalCenter = clampedTopLeft + frameSize / 2

					TweenService:Create(MainFrame, info, {
						Position = UDim2.new(0, finalCenter.X, 0, finalCenter.Y)
					}):Play()
				end
			end)
		end
	end
end

function module:CaptureFocus(Leaf)
	FocusedLeaf = Leaf
	
	local Data = module:GetLeafData(Leaf)

	if not Data.LockedZIndex then
		Leaf.ZIndex = 2
	end
	
	if Data.DisableOtherLeafWhenFocused then
		module:SetActiveLeafInteractable(false, Leaf)
	end
	
	if Data.DisablePanelWhenFocused then
		module:SetPanelInteractable(false)
	end

	-- Visual Feedback

	Leaf.frame.LeafletControls.Bottom.Interactable = true

	TweenService:Create(Leaf, info, {ImageTransparency = 0}):Play()
	TweenService:Create(Leaf.frame.LeafletControls.Bottom.Resize.icon, info, {ImageTransparency = 0}):Play()
	
	for i, AerialEffect in pairs(Leaf:GetDescendants()) do
		if AerialEffect:HasTag("Exe6AerialEffect") then
			AerialEffect.Enabled = true
		end
	end

	for i, v in pairs(ActiveLeaf) do
		if v ~= Leaf then
			module:RemoveFocus(v)
		end
	end
end

function module:RemoveFocus(Leaf)
	if FocusedLeaf == Leaf then
		FocusedLeaf = nil
	end
	
	local Data = module:GetLeafData(Leaf)

	if not Data.LockedZIndex then
		Leaf.ZIndex = 1
	end
	
	local FreeToEnableLeaf = true
	local FreeToEnablePanel = true
	
	for i, v in pairs(ActiveLeaf) do
		if v ~= Leaf then
			local v_data = module:GetLeafData(v)
			
			if v_data.DisableOtherLeafWhenFocused or v_data.DisablePanelWhenFocused then
				FreeToEnableLeaf = not v_data.DisableOtherLeafWhenFocused
				FreeToEnablePanel = not v_data.DisablePanelWhenFocused
				
				break
			end
		end
	end
	
	if FreeToEnableLeaf then
		module:SetActiveLeafInteractable(true, Leaf)
	end
	
	if FreeToEnablePanel then
		module:SetPanelInteractable(true)
	end
	
	-- Visual Feedback

	Leaf.frame.LeafletControls.Bottom.Interactable = false

	TweenService:Create(Leaf, info, {ImageTransparency = .8}):Play()
	TweenService:Create(Leaf.frame.LeafletControls.Bottom.Resize.icon, info, {ImageTransparency = 1}):Play()
	
	for i, AerialEffect in pairs(Leaf:GetDescendants()) do
		if AerialEffect:HasTag("Exe6AerialEffect") then
			AerialEffect.Enabled = false
		end
	end
end

function module:Activate(Leaf)
	local position = table.find(ActiveLeaf, Leaf)

	if position then
		return
	end

	table.insert(ActiveLeaf, Leaf)
end

function module:Deactivate(Leaf)
	local position = table.find(ActiveLeaf, Leaf)

	if not position then
		return
	end
	
	if FocusedLeaf == Leaf then
		module:RemoveFocus(Leaf)
	end

	table.remove(ActiveLeaf, position)
end

function module:NormalizeLeafSize(BaseSize, MinSize, MaxSize)
	local screenSize = workspace.CurrentCamera.ViewportSize
	local factorX = screenSize.X / 1920 
	local factorY = (screenSize.Y / 1080) * 1.3

	local normalizedWidth = math.clamp(BaseSize.X * factorX, MinSize.X, MaxSize.X)
	local normalizedHeight = math.clamp(BaseSize.Y * factorY, MinSize.Y, MaxSize.Y)

	return Vector2.new(normalizedWidth, normalizedHeight)
end

function module:GetLeafData(Leaf)
	return LeafData[Leaf]
end

function module:GetActiveLeaf()
	return ActiveLeaf
end

function module:SetActiveLeafInteractable(state, ExceptLeaf)
	for i, Leaf in pairs(ActiveLeaf) do
		if Leaf ~= ExceptLeaf then
			Leaf.Interactable = state
		end
	end
end

function module:SetPanelInteractable(state)
	if not Panel then return end
	
	Panel.Interactable = state
end

return module