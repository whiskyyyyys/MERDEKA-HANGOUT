local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MawarSystem = ReplicatedStorage:WaitForChild("MawarSystem")
local RequestGive = MawarSystem:WaitForChild("RequestGive")
local ReceivePrompt = MawarSystem:WaitForChild("ReceivePrompt")
local RespondGive = MawarSystem:WaitForChild("RespondGive")

local pendingRequests = {} 
local requestCooldowns = {}

local MAX_GIVE_DISTANCE = 15 -- Studs

local function hasTool(player, toolName)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	if character and character:FindFirstChild(toolName) then return character[toolName] end
	if backpack and backpack:FindFirstChild(toolName) then return backpack[toolName] end
	return nil
end

local function createReceivedEffect(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local attachment = Instance.new("Attachment", rootPart)

	local particles = Instance.new("ParticleEmitter", attachment)
	particles.Texture = "rbxassetid://5860841663" 

	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 120)), -- Hot Pink
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 182, 193))  -- Light Rose
	})

	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), 
		NumberSequenceKeypoint.new(0.2, 1.8), 
		NumberSequenceKeypoint.new(0.8, 1.2), 
		NumberSequenceKeypoint.new(1, 0)
	})

	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.1),
		NumberSequenceKeypoint.new(1, 1)
	})

	particles.LightEmission = 0.6
	particles.ZOffset = 1
	particles.EmissionDirection = Enum.NormalId.Top
	particles.SpreadAngle = Vector2.new(45, 45) 
	particles.Speed = NumberRange.new(4, 7)
	particles.Lifetime = NumberRange.new(1.5, 2.5)
	particles.Rotation = NumberRange.new(-45, 45)
	particles.RotSpeed = NumberRange.new(-30, 30)
	particles.Drag = 2 

	particles.Enabled = false 
	particles:Emit(40) 

	task.delay(3, function()
		if attachment then attachment:Destroy() end
	end)
end

RequestGive.OnServerEvent:Connect(function(sender, targetPlayer, toolName)
	if not targetPlayer or targetPlayer == sender then return end

	-- 🛡️ SECURITY: Anti-Spam Cooldown (3 seconds)
	local now = os.time()
	if requestCooldowns[sender.UserId] and (now - requestCooldowns[sender.UserId]) < 3 then return end
	requestCooldowns[sender.UserId] = now

	-- 🛡️ SECURITY: Check if sender actually has the item
	if not hasTool(sender, toolName) then return end

	-- 🛡️ SECURITY: Distance Check
	local sChar = sender.Character
	local tChar = targetPlayer.Character
	if not sChar or not tChar then return end

	local sRoot = sChar:FindFirstChild("HumanoidRootPart")
	local tRoot = tChar:FindFirstChild("HumanoidRootPart")
	if not sRoot or not tRoot then return end

	if (sRoot.Position - tRoot.Position).Magnitude > MAX_GIVE_DISTANCE then return end

	pendingRequests[targetPlayer.UserId] = {Sender = sender, ToolName = toolName, Time = now}
	ReceivePrompt:FireClient(targetPlayer, sender, toolName)
end)

RespondGive.OnServerEvent:Connect(function(targetPlayer, accepted)
	local requestData = pendingRequests[targetPlayer.UserId]
	pendingRequests[targetPlayer.UserId] = nil 

	if accepted and requestData then
		local sender = requestData.Sender
		local toolName = requestData.ToolName

		-- Fetch the tool dynamically to ensure they didn't drop it while waiting
		local mawar = hasTool(sender, toolName)

		if mawar and targetPlayer:FindFirstChild("Backpack") then

			-- If the receiver already has one, destroy the sender's to prevent duplicates,
			-- otherwise transfer it properly.
			if not hasTool(targetPlayer, toolName) then
				mawar.Parent = targetPlayer.Backpack
			else
				mawar:Destroy()
			end

			if targetPlayer.Character then
				createReceivedEffect(targetPlayer.Character)
			end
		end
	end
end)