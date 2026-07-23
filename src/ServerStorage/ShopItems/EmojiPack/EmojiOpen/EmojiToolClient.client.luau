local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local tool        = script.Parent
local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")
local emojiGui    = playerGui:WaitForChild("EmojiGui")
local holder      = emojiGui:WaitForChild("Holder")

local EmojiConfig = require(RS:WaitForChild("EmojiSystem"):WaitForChild("EmojiConfig"))
local ShowEmoji   = RS:WaitForChild("EmojiSystem"):WaitForChild("ShowEmoji")

local slotOrder = {
	"Emoji1","Emoji2","Emoji3","Emoji4",
	"Emoji5","Emoji6","Emoji7","Emoji8"
}

local sfxHover = Instance.new("Sound")
sfxHover.SoundId = EmojiConfig.hoverSound or ""
sfxHover.Volume  = 2
sfxHover.Parent  = SoundService

local sfxClick = Instance.new("Sound")
sfxClick.SoundId = EmojiConfig.clickSound or ""
sfxClick.Volume  = 2
sfxClick.Parent  = SoundService

for i, slotName in ipairs(slotOrder) do
	local cfg = EmojiConfig[i]
	if not cfg then break end
	local emojiLabel = holder:FindFirstChild(slotName)
	if not emojiLabel then continue end
	local btn     = emojiLabel:FindFirstChild("Btn")
	local sticker = btn and btn:FindFirstChild("Sticker")
	if sticker then sticker.Image = cfg.image end
end

local TWEEN_HOVER_IN  = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_HOVER_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_IMG_IN    = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_IMG_OUT   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local activeTweens = {}

local function cancelActive(slotName)
	local t = activeTweens[slotName]
	if t then
		for _, tw in ipairs(t) do
			tw:Cancel()
		end
	end
	activeTweens[slotName] = nil
end

for _, slotName in ipairs(slotOrder) do
	local emojiLabel = holder:FindFirstChild(slotName)
	if not emojiLabel then continue end
	local btn     = emojiLabel:FindFirstChild("Btn")
	local uiScale = emojiLabel:FindFirstChildOfClass("UIScale")
	if not btn then continue end

	btn.MouseEnter:Connect(function()
		cancelActive(slotName)
		local t1 = TweenService:Create(emojiLabel, TWEEN_IMG_IN,   { ImageTransparency = 0 })
		local t2 = uiScale and TweenService:Create(uiScale, TWEEN_HOVER_IN, { Scale = 1.05 })
		activeTweens[slotName] = t2 and { t1, t2 } or { t1 }
		t1:Play()
		if t2 then t2:Play() end
		if sfxHover.SoundId ~= "" then sfxHover:Play() end
	end)

	btn.MouseLeave:Connect(function()
		cancelActive(slotName)
		local t1 = TweenService:Create(emojiLabel, TWEEN_IMG_OUT,   { ImageTransparency = 1 })
		local t2 = uiScale and TweenService:Create(uiScale, TWEEN_HOVER_OUT, { Scale = 1 })
		activeTweens[slotName] = t2 and { t1, t2 } or { t1 }
		t1:Play()
		if t2 then t2:Play() end
	end)
end

local POS_HIDDEN = UDim2.new(0.5, 0, 1.3, 0)
local POS_SHOWN  = UDim2.new(0.5, 0, 0.5, 0)

local TWEEN_IN  = TweenInfo.new(0.45, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

local tweenIn  = TweenService:Create(holder, TWEEN_IN,  { Position = POS_SHOWN  })
local tweenOut = TweenService:Create(holder, TWEEN_OUT, { Position = POS_HIDDEN })

local function resetSlots()
	for _, slotName in ipairs(slotOrder) do
		cancelActive(slotName)
		local emojiLabel = holder:FindFirstChild(slotName)
		if not emojiLabel then continue end
		emojiLabel.ImageTransparency = 1
		local uiScale = emojiLabel:FindFirstChildOfClass("UIScale")
		if uiScale then uiScale.Scale = 1 end
	end
end

local function showHolder()
	holder.Position = POS_HIDDEN
	holder.Visible  = true
	tweenOut:Cancel()
	tweenIn:Play()
end

local function hideHolder()
	tweenIn:Cancel()
	tweenOut:Play()
	tweenOut.Completed:Once(function()
		holder.Visible = false
		resetSlots()
	end)
end

for i, slotName in ipairs(slotOrder) do
	local cfg = EmojiConfig[i]
	if not cfg then break end
	local emojiLabel = holder:FindFirstChild(slotName)
	if not emojiLabel then continue end
	local btn = emojiLabel:FindFirstChild("Btn")
	if not btn then continue end

	btn.MouseButton1Click:Connect(function()
		if sfxClick.SoundId ~= "" then sfxClick:Play() end
		local soundId = (cfg.sound and cfg.sound ~= "") and cfg.sound or ""
		ShowEmoji:FireServer(i, cfg.image, soundId, cfg.duration)
		hideHolder()
		localPlayer.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
	end)
end

tool.Equipped:Connect(showHolder)
tool.Unequipped:Connect(hideHolder)

tool.AncestryChanged:Connect(function()
	if not tool.Parent then
		sfxHover:Destroy()
		sfxClick:Destroy()
	end
end)

holder.Position = POS_HIDDEN
holder.Visible  = false
