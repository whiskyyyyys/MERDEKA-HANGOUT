local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local ShowEmoji         = RS:WaitForChild("EmojiSystem"):WaitForChild("ShowEmoji")
local BillboardTemplate = RS:WaitForChild("Emoji")

local activeBillboards = {}

local function destroyWithAnim(billboard)
	if not billboard or not billboard.Parent then return end
	billboard:SetAttribute("PlayOut", true)
	task.delay(0.25, function()
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
	end)
end

local function clearBillboard(player)
	local data = activeBillboards[player]
	if data then
		if data.thread then task.cancel(data.thread) end
		if data.deferThread then task.cancel(data.deferThread) end
		destroyWithAnim(data.billboard)
		activeBillboards[player] = nil
	end
end

ShowEmoji.OnServerEvent:Connect(function(player, slotIndex, imageId, soundId, fallbackDuration)
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > 8 then return end
	if type(imageId) ~= "string" or imageId == "" then return end
	fallbackDuration = (type(fallbackDuration) == "number" and fallbackDuration > 0)
		and math.min(fallbackDuration, 30) or 4

	local character = player.Character
	if not character then return end
	local head = character:FindFirstChild("Head")
	local hrp  = character:FindFirstChild("HumanoidRootPart")
	if not head or not hrp then return end

	clearBillboard(player)

	local billboard = BillboardTemplate:Clone()
	billboard.Name    = "EmojiBoard_" .. player.UserId
	billboard.Adornee = head

	local sticker = billboard:FindFirstChild("Sticker")
	if sticker then sticker.Image = imageId end

	local bbSound = billboard:FindFirstChildWhichIsA("Sound")
	if bbSound then bbSound:Destroy() end

	billboard.Parent = head

	local duration = fallbackDuration

	if type(soundId) == "string" and soundId ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId    = soundId
		sound.RollOffMaxDistance = 60
		sound.RollOffMinDistance = 5
		sound.Volume = 10
		sound.Parent = hrp
		sound:Play()

		local deferThread = task.defer(function()
			if sound.TimeLength == 0 then
				local loaded = false
				local conn
				conn = sound.Loaded:Connect(function()
					loaded = true
					conn:Disconnect()
				end)
				local waited = 0
				while not loaded and waited < 3 do
					if not sound.Parent then
						if conn then conn:Disconnect() end
						return
					end
					task.wait(0.1)
					waited += 0.1
				end
				if not loaded and conn then conn:Disconnect() end
			end

			if not sound.Parent then return end

			local finalDuration = sound.TimeLength > 0 and sound.TimeLength or fallbackDuration
			local data = activeBillboards[player]
			if data and data.billboard == billboard then
				if data.thread then task.cancel(data.thread) end
				data.thread = task.delay(finalDuration, function()
					sound:Destroy()
					destroyWithAnim(billboard)
					activeBillboards[player] = nil
				end)
			end
		end)

		activeBillboards[player] = {
			billboard   = billboard,
			thread      = task.delay(duration, function()
				sound:Destroy()
				destroyWithAnim(billboard)
				activeBillboards[player] = nil
			end),
			deferThread = deferThread,
		}
	else
		activeBillboards[player] = {
			billboard   = billboard,
			thread      = task.delay(duration, function()
				destroyWithAnim(billboard)
				activeBillboards[player] = nil
			end),
			deferThread = nil,
		}
	end
end)

Players.PlayerRemoving:Connect(function(player)
	clearBillboard(player)
end)
