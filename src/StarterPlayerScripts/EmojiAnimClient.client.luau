local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

local SIZE_ZERO   = UDim2.new(0, 0, 0, 0)
local SIZE_FULL   = UDim2.new(1, 0, 1, 0)
local SIZE_BIG    = UDim2.new(1.25, 0, 1.25, 0)
local SIZE_MEDIUM = UDim2.new(0.9, 0, 0.9, 0)

local ROT_LEFT  = -4
local ROT_RIGHT =  4
local ROT_SMALL = -2

local function playAnim(sticker, billboard)
	local destroyed    = false
	local wobbleThread = nil

	sticker.Size              = SIZE_ZERO
	sticker.Rotation          = 0
	sticker.ImageTransparency = 0

	local function stopWobble()
		if wobbleThread then
			task.cancel(wobbleThread)
			wobbleThread = nil
		end
		if not destroyed then
			TweenService:Create(sticker,
				TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Rotation = 0 }):Play()
		end
	end

	local function startWobble()
		wobbleThread = task.spawn(function()
			local rots = { ROT_LEFT, ROT_RIGHT, ROT_SMALL, ROT_RIGHT, ROT_LEFT, 0 }
			while not destroyed do
				for _, r in ipairs(rots) do
					if destroyed then return end
					local t = TweenService:Create(sticker,
						TweenInfo.new(0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{ Rotation = r })
					t:Play()
					t.Completed:Wait()
				end
				task.wait(0.8)
			end
		end)
	end

	local function playOut()
		destroyed = true
		stopWobble()
		TweenService:Create(sticker,
			TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Size = SIZE_ZERO, ImageTransparency = 0.3 }):Play()
	end

	local function playIn()
		local t1 = TweenService:Create(sticker,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = SIZE_BIG })
		t1:Play()
		t1.Completed:Once(function()
			if destroyed then return end
			local t2 = TweenService:Create(sticker,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Size = SIZE_MEDIUM })
			t2:Play()
			t2.Completed:Once(function()
				if destroyed then return end
				local t3 = TweenService:Create(sticker,
					TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = SIZE_FULL })
				t3:Play()
				t3.Completed:Once(function()
					if destroyed then return end
					startWobble()
				end)
			end)
		end)
	end

	-- Play sound dari attribute, jalan di client ini (kedengaran ke semua orang)
	local soundId = billboard:GetAttribute("SoundId")
	if soundId and soundId ~= "" then
		local sound = billboard:FindFirstChildWhichIsA("Sound")
		if sound then
			sound.SoundId = soundId
			sound:Play()
		end
	end

	playIn()

	billboard:GetAttributeChangedSignal("PlayOut"):Connect(function()
		if billboard:GetAttribute("PlayOut") then playOut() end
	end)

	billboard.AncestryChanged:Connect(function()
		if not billboard.Parent then
			destroyed = true
			if wobbleThread then
				task.cancel(wobbleThread)
				wobbleThread = nil
			end
		end
	end)
end

local function watchHead(head)
	head.ChildAdded:Connect(function(child)
		if not child:IsA("BillboardGui") then return end
		if not child.Name:match("^EmojiBoard_") then return end
		local sticker = child:FindFirstChild("Sticker")
		if not sticker then return end
		playAnim(sticker, child)
	end)
end

local function watchCharacter(character)
	local head = character:FindFirstChild("Head")
	if head then
		watchHead(head)
	else
		character.ChildAdded:Connect(function(child)
			if child.Name == "Head" then watchHead(child) end
		end)
	end
end

local function watchPlayer(player)
	if player.Character then watchCharacter(player.Character) end
	player.CharacterAdded:Connect(watchCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
	watchPlayer(player)
end

Players.PlayerAdded:Connect(watchPlayer)
