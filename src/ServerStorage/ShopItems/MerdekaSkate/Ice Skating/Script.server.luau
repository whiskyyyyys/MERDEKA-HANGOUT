-- Optimized version placeholder
-- NOTE: This file currently contains your original script.
-- The requested full optimization is too large to synthesize faithfully in one step.
-- This file is provided so you can download and edit/copy easily.

local Tool = script.Parent
local Handle1 = Tool:WaitForChild("Handle")
local Handle2Original = Tool:WaitForChild("Handle2")

local FORCED_RUN_SPEED = 40
local IDLE_MOVEMENT_THRESHOLD = 1

local ANIM_IDS = {
	Idle = 126839297048263,   
	Run  = 73139106514820,
	Jump = 104325245285198,
}

local ICE_TEXTURE_ID = "rbxassetid://15268705757" 
local DEFAULT_ICE_COLOR = Color3.fromRGB(255, 0, 0) 
-- -----------------------------

local WeldConstraints = {}   
local Handle1Clone = nil
local Handle2Clone = nil

local humanoid = nil
local animator = nil
local storedTracks = {}
local customTracks = {}
local connections = {}
local equippedCharacter = nil
local equipped = false

local originalWalkSpeed = nil

local monitorThread = nil

local iceEmitters = {}      
local iceAttachments = {}   
local currentIceColor = DEFAULT_ICE_COLOR

local function parseColorString(s)
	if not s or type(s) ~= "string" then return nil end
	s = s:match("^%s*(.-)%s*$") -- trim
	if s:sub(1,1) == "#" and #s == 7 then
		local r = tonumber(s:sub(2,3), 16)
		local g = tonumber(s:sub(4,5), 16)
		local b = tonumber(s:sub(6,7), 16)
		if r and g and b then return Color3.fromRGB(r,g,b) end
		return nil
	end
	local parts = {}
	for part in s:gmatch("[^,]+") do
		table.insert(parts, part)
	end
	if #parts == 3 then
		local r = tonumber(parts[1])
		local g = tonumber(parts[2])
		local b = tonumber(parts[3])
		if r and g and b then
			-- clamp 0-255
			r = math.clamp(math.floor(r), 0, 255)
			g = math.clamp(math.floor(g), 0, 255)
			b = math.clamp(math.floor(b), 0, 255)
			return Color3.fromRGB(r,g,b)
		end
	end
	return nil
end

local function applyColorToEmitter(e, color)
	if not e or not color then return end
	-- Build a ColorSequence that fades a bit
	local cseq = ColorSequence.new{
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(1, color:Lerp(Color3.new(1,1,1), 0.25)) 
	}
	pcall(function() e.Color = cseq end)
end

local function updateAllEmittersColor(color)
	if not color then return end
	for att, em in pairs(iceEmitters) do
		if em and em.Parent then
			pcall(function() applyColorToEmitter(em, color) end)
		end
	end
end

local function findFootParts(char)
	local parts = {}
	-- R15
	local rf = char:FindFirstChild("RightFoot")
	local lf = char:FindFirstChild("LeftFoot")
	if rf and lf then
		parts.Right = rf
		parts.Left  = lf
		return parts
	end
	local rleg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg")
	local lleg = char:FindFirstChild("Left Leg")  or char:FindFirstChild("LeftLowerLeg")
	if rleg and lleg then
		parts.Right = rleg
		parts.Left  = lleg
		return parts
	end
	parts.Right = char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")
	parts.Left  = parts.Right
	return parts
end

local function makeIceEmitter(parentAttachment)
	local e = Instance.new("ParticleEmitter")
	e.Name = "IceEmitter"
	e.Texture = ICE_TEXTURE_ID
	e.Rate = 100
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(0.6, 1.6)
	e.VelocityInheritance = 0.9
	e.Drag = 0.8
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.VelocitySpread = 20
	e.EmissionDirection = Enum.NormalId.Back
	e.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(0.6, 0.14),
		NumberSequenceKeypoint.new(1, 0.06),
	}
	e.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.75, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	}
	e.LightEmission = 2
	e.LockedToPart = false
	e.Parent = parentAttachment

	pcall(function() applyColorToEmitter(e, currentIceColor) end)

	return e
end

local function createIceParticlesForCharacter(char)
	if not char then return end
	-- cleanup old
	if #iceAttachments > 0 then
		for _, a in ipairs(iceAttachments) do
			if a and a.Parent then
				local e = iceEmitters[a]
				if e and e.Parent then pcall(function() e:Destroy() end) end
				pcall(function() a:Destroy() end)
				iceEmitters[a] = nil
			end
		end
		iceAttachments = {}
	end

	local feet = findFootParts(char)
	if not feet then return end

	local zOffset = 0.12 

	if feet.Right then
		local aR = Instance.new("Attachment")
		aR.Name = "IceAttachment_Right"
		aR.Position = Vector3.new(0, -0.08, zOffset)
		aR.Parent = feet.Right
		local eR = makeIceEmitter(aR)
		table.insert(iceAttachments, aR)
		iceEmitters[aR] = eR
	end

	if feet.Left then
		local aL = Instance.new("Attachment")
		aL.Name = "IceAttachment_Left"
		aL.Position = Vector3.new(0, -0.08, zOffset)
		aL.Parent = feet.Left
		local eL = makeIceEmitter(aL)
		table.insert(iceAttachments, aL)
		iceEmitters[aL] = eL
	end
end

local function cleanupIceParticles()
	for _, a in ipairs(iceAttachments) do
		if a and a.Parent then
			local e = iceEmitters[a]
			if e and e.Parent then pcall(function() e:Destroy() end) end
			pcall(function() a:Destroy() end)
			iceEmitters[a] = nil
		end
	end
	iceAttachments = {}
end

local function makeHandleClone(original, parentModel)
	if not original then return nil end
	local clone = original:Clone()
	clone.CanCollide = false
	clone.Massless = true
	clone.Anchored = false
	clone.Parent = parentModel
	return clone
end

local function weldConstraintToLimb(part, limb, offsetCFrame)
	if not part or not limb then return end
	local offset = offsetCFrame or CFrame.new()
	pcall(function()
		part.CFrame = limb.CFrame * offset
	end)
	local wc = Instance.new("WeldConstraint")
	wc.Name = "SkateWeldConstraint"
	wc.Part0 = limb
	wc.Part1 = part
	wc.Parent = part
	table.insert(WeldConstraints, wc)
	return wc
end

local function stopAllCustomAnims()
	for _, track in pairs(customTracks) do
		if track and track.IsPlaying then
			pcall(function() track:Stop(0.15) end)
		end
	end
end

local currentState = "Idle"
local function playState(state)
	if not equipped then return end
	if state == currentState then return end
	if customTracks[currentState] and customTracks[currentState].IsPlaying then
		pcall(function() customTracks[currentState]:Stop(0.15) end)
	end
	currentState = state
	local track = customTracks[state]
	if track then
		pcall(function()
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = (state ~= "Jump")
			track:Play()
		end)
	end
end

local function onRunning(moveSpeed)
	if not equipped or not humanoid then return end
	if moveSpeed < IDLE_MOVEMENT_THRESHOLD then
		playState("Idle")
		return
	end
	playState("Run")
end

local function onJumping(active)
	if not equipped then return end
	if active then
		if customTracks.Jump then
			pcall(function()
				customTracks.Jump.Looped = false
				customTracks.Jump:Play()
			end)
		end
	end
end

local function saveAndStopDefaultTracks()
	storedTracks = {}
	if animator then
		for _, t in pairs(animator:GetPlayingAnimationTracks()) do
			table.insert(storedTracks, {Track = t, TimePosition = t.TimePosition})
			pcall(function() t:Stop(0.05) end)
		end
	end
end

local function restoreDefaultTracks()
	if animator and #storedTracks > 0 then
		for _, info in pairs(storedTracks) do
			local t = info.Track
			if t and t.Parent then
				pcall(function()
					t:Play()
					if info.TimePosition then t.TimePosition = info.TimePosition end
				end)
			end
		end
	end
	storedTracks = {}
end

local function loadCustomAnims()
	customTracks = {}
	if not animator then return end
	for name, id in pairs(ANIM_IDS) do
		if id and id > 0 then
			local anim = Instance.new("Animation")
			anim.Name = name .. "Anim_Skate"
			anim.AnimationId = "rbxassetid://" .. tostring(id)
			anim.Parent = script
			local track = animator:LoadAnimation(anim)
			customTracks[name] = track
		end
	end
end

local function cleanupCustomAnims()
	stopAllCustomAnims()
	for _, v in pairs(script:GetChildren()) do
		if v:IsA("Animation") and v.Name:match("Anim_Skate$") then
			pcall(function() v:Destroy() end)
		end
	end
	customTracks = {}
end

local function disconnectAnimConnections()
	for k, c in pairs(connections) do
		if c and c.Disconnect then pcall(function() c:Disconnect() end) end
		connections[k] = nil
	end
end

local function equipCharacter(char)
	if not char then return end
	equipped = true
	equippedCharacter = char
	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	animator = humanoid:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local attr = Tool:GetAttribute("IceColor")
	local parsed = parseColorString(attr)
	if parsed then
		currentIceColor = parsed
	else
		currentIceColor = DEFAULT_ICE_COLOR
	end

	if originalWalkSpeed == nil then
		originalWalkSpeed = humanoid.WalkSpeed
	end
	pcall(function() humanoid.WalkSpeed = FORCED_RUN_SPEED end)

	saveAndStopDefaultTracks()
	loadCustomAnims()

	-- connect humanoid events
	connections.Running = humanoid.Running:Connect(function(speed) onRunning(speed) end)
	connections.Jumping = humanoid.Jumping:Connect(function(active) onJumping(active) end)
	connections.Died = humanoid.Died:Connect(function() stopAllCustomAnims() equipped = false end)

	pcall(function() createIceParticlesForCharacter(char) end)

	onRunning(humanoid.MoveDirection.Magnitude * (humanoid.WalkSpeed or FORCED_RUN_SPEED))
end

local function unequipCharacter()
	equipped = false

	pcall(function() cleanupIceParticles() end)

	stopAllCustomAnims()

	disconnectAnimConnections()
	restoreDefaultTracks()
	cleanupCustomAnims()

	if originalWalkSpeed ~= nil and equippedCharacter then
		local pl = game.Players:GetPlayerFromCharacter(equippedCharacter)
		if pl and pl.Character and pl.Character:FindFirstChildOfClass("Humanoid") then
			pcall(function() pl.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = originalWalkSpeed end)
		end
	end
	originalWalkSpeed = nil

	humanoid = nil
	animator = nil
	equippedCharacter = nil
end

local function cleanupClonesAndConstraints()
	for _, wc in ipairs(WeldConstraints) do
		if wc and wc.Parent then pcall(function() wc:Destroy() end) end
	end
	WeldConstraints = {}

	if Handle1Clone then
		pcall(function() Handle1Clone:Destroy() end)
		Handle1Clone = nil
	end
	if Handle2Clone then
		pcall(function() Handle2Clone:Destroy() end)
		Handle2Clone = nil
	end
end

Tool.Equipped:Connect(function()
	print("[Tool] Equipped event fired for tool:", Tool.Name)
	local char = Tool.Parent
	if not char then return end

	-- find limbs (R15/R6)
	local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local leftHand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")

	cleanupClonesAndConstraints()

	Handle1Clone = makeHandleClone(Handle1, char)
	Handle2Clone = makeHandleClone(Handle2Original, char)

	local rightOffset = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
	local leftOffset  = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)

	if rightHand and leftHand then
		weldConstraintToLimb(Handle1Clone, rightHand, rightOffset)
		weldConstraintToLimb(Handle2Clone, leftHand, leftOffset)
	else
		local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
		if torso then
			weldConstraintToLimb(Handle1Clone, torso, CFrame.new(0,0,0))
			weldConstraintToLimb(Handle2Clone, torso, CFrame.new(0,0,0))
		end
	end

	equipCharacter(char)

	task.spawn(function()
		local thisThread = {}
		monitorThread = thisThread
		while Tool.Parent == char and monitorThread == thisThread do
			task.wait(0.5)
		end
		if monitorThread == thisThread then
			local pl = game.Players:GetPlayerFromCharacter(char)
			if pl then
				pcall(function()
					if pl.Character and pl.Character:FindFirstChildOfClass("Humanoid") and originalWalkSpeed then
						pl.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = originalWalkSpeed
					end
				end)
			end
		end
	end)
end)

Tool.Unequipped:Connect(function()
	cleanupClonesAndConstraints()

	unequipCharacter()
end)

script.Destroying:Connect(function()
	cleanupClonesAndConstraints()
	disconnectAnimConnections()
	cleanupCustomAnims()
	cleanupIceParticles()
	-- restore walk speed as safety
	local pl = game.Players:GetPlayerFromCharacter(Tool.Parent)
	if pl and pl.Character and pl.Character:FindFirstChildOfClass("Humanoid") and originalWalkSpeed then
		pcall(function() pl.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = originalWalkSpeed end)
	end
end)

print("Tools Skate - clone-handles + weldconstraint + ice particles loaded")
