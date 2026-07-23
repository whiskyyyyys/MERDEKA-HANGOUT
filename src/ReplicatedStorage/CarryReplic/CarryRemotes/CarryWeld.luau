local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEBUG = false
local DEBUG_TO_CLIENT = false

local DISABLED_STATES_WHILE_CARRIED = {
	Enum.HumanoidStateType.Running,
	Enum.HumanoidStateType.RunningNoPhysics,
	Enum.HumanoidStateType.Climbing,
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.Freefall,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.Seated,
	Enum.HumanoidStateType.GettingUp,
	Enum.HumanoidStateType.Swimming,
}

local function getCarryRemote()
	local carryReplic = ReplicatedStorage:FindFirstChild("CarryReplic")
	if not carryReplic then
		return nil
	end

	local carryRemotes = carryReplic:FindFirstChild("CarryRemotes")
	if not carryRemotes then
		return nil
	end

	local remote = carryRemotes:FindFirstChild("CarryRemote")
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	return nil
end

local CarryRemote = getCarryRemote()

local function logBoth(plrs, msg)
	if not DEBUG then
		return
	end

	warn("[CARRY-DEBUG] " .. msg)

	if DEBUG_TO_CLIENT and CarryRemote and plrs then
		for _, p in ipairs(plrs) do
			if p and p.Parent == Players then
				pcall(function()
					CarryRemote:FireClient(p, "DebugLog", {
						text = msg
					})
				end)
			end
		end
	end
end

local function createNoCollision(char1, char2)
	local p0 = char1:FindFirstChild("HumanoidRootPart") or char1.PrimaryPart
	local p1 = char2:FindFirstChild("HumanoidRootPart") or char2.PrimaryPart
	if not (p0 and p1) then
		return nil
	end

	local noCollision = Instance.new("NoCollisionConstraint")
	noCollision.Name = "CarryNoCollision"
	noCollision.Part0 = p0
	noCollision.Part1 = p1
	noCollision.Parent = char1

	return noCollision
end

local function safeDropPlacement(char, hum, root, targetXZ, yaw, extraIgnore)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local ignoreList = { char }
	if extraIgnore then
		for _, obj in ipairs(extraIgnore) do
			table.insert(ignoreList, obj)
		end
	end
	rayParams.FilterDescendantsInstances = ignoreList

	local basePos = root.Position
	if targetXZ then
		basePos = Vector3.new(targetXZ.X, basePos.Y, targetXZ.Z)
	end

	local origin = basePos + Vector3.new(0, 4, 0)
	local dir = Vector3.new(0, -150, 0)

	local result = workspace:Raycast(origin, dir, rayParams)

	local lift = math.max(3, (hum.HipHeight or 2) + 2.5)
	local targetPos

	if result then
		targetPos = Vector3.new(basePos.X, result.Position.Y + lift, basePos.Z)
	else
		targetPos = basePos + Vector3.new(0, 6, 0)
	end

	local finalYaw = yaw
	if finalYaw == nil then
		local _, ry, _ = root.CFrame:ToEulerAnglesYXZ()
		finalYaw = ry
	end

	root.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, finalYaw, 0)
end

local function getOrCreateAnimator(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

-- biarkan seperti gaya script asli supaya anim tetap jalan
local function loadAndPlay(humanoid, animId, looped)
	if not animId or animId == "" then
		return nil, nil
	end

	local animator = getOrCreateAnimator(humanoid)

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animId)

	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)

	if not ok or not track then
		pcall(function()
			anim:Destroy()
		end)
		return nil, nil
	end

	track.Priority = Enum.AnimationPriority.Action
	track.Looped = looped == true

	pcall(function()
		track:Play(0.15, 1, 1)
	end)

	task.delay(0.1, function()
		if track and track.Parent and not track.IsPlaying then
			pcall(function()
				track:Play(0.1, 1, 1)
			end)
		end
	end)

	return track, anim
end

local function setCharacterNetworkOwner(character, ownerPlayer)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") and not obj.Anchored then
			pcall(function()
				obj:SetNetworkOwner(ownerPlayer)
			end)
		end
	end
end

local function setCharacterNetworkOwnershipAuto(character)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") and not obj.Anchored then
			pcall(function()
				obj:SetNetworkOwnershipAuto()
			end)
		end
	end
end

local function disableHumanoidStates(humanoid)
	local savedStates = {}

	for _, state in ipairs(DISABLED_STATES_WHILE_CARRIED) do
		local ok, enabled = pcall(function()
			return humanoid:GetStateEnabled(state)
		end)

		if ok then
			savedStates[state] = enabled
			pcall(function()
				humanoid:SetStateEnabled(state, false)
			end)
		end
	end

	return savedStates
end

local function restoreHumanoidStates(humanoid, savedStates)
	for state, enabled in pairs(savedStates) do
		pcall(function()
			humanoid:SetStateEnabled(state, enabled)
		end)
	end
end

local function getDropPositionFromCarrier(iRoot, fallbackRoot)
	if iRoot and iRoot.Parent then
		local backOffset = -3.5
		local sideOffset = 1.75

		local look = iRoot.CFrame.LookVector
		local right = iRoot.CFrame.RightVector

		local pos = iRoot.Position + (look * backOffset) + (right * sideOffset)
		local _, ry, _ = iRoot.CFrame:ToEulerAnglesYXZ()

		return pos, ry
	end

	if fallbackRoot and fallbackRoot.Parent then
		local _, ry, _ = fallbackRoot.CFrame:ToEulerAnglesYXZ()
		return fallbackRoot.Position + Vector3.new(0, 0, -3), ry
	end

	return nil, nil
end

local function startCarry(
	initiator,
	recipient,
	mainPart,
	offset,
	animCarry,
	animLift
)
	if not (initiator and recipient and initiator.Character and recipient.Character) then
		return
	end

	local initiatorChar = initiator.Character
	local recipientChar = recipient.Character

	local iRoot = initiatorChar:FindFirstChild("HumanoidRootPart")
	local rRoot = recipientChar:FindFirstChild("HumanoidRootPart")
	local iHum = initiatorChar:FindFirstChildOfClass("Humanoid")
	local rHum = recipientChar:FindFirstChildOfClass("Humanoid")

	if not (iRoot and rRoot and iHum and rHum) then
		return
	end

	local initiatorCarryStatus = initiatorChar:WaitForChild("Carryble", 5)
	local recipientCarryStatus = recipientChar:WaitForChild("Carryble", 5)
	if not (initiatorCarryStatus and recipientCarryStatus) then
		return
	end

	-- patch: cegah carry dobel pada kedua character
	if initiatorChar:FindFirstChild("CarrySessionActive") or recipientChar:FindFirstChild("CarrySessionActive") then
		logBoth({ initiator, recipient }, "StartCarry blocked: CarrySessionActive exists")
		return nil
	end

	local sessionMarkA = Instance.new("BoolValue")
	sessionMarkA.Name = "CarrySessionActive"
	sessionMarkA.Value = true
	sessionMarkA.Parent = initiatorChar

	local sessionMarkB = Instance.new("BoolValue")
	sessionMarkB.Name = "CarrySessionActive"
	sessionMarkB.Value = true
	sessionMarkB.Parent = recipientChar

	if not mainPart or not mainPart:IsA("BasePart") or not mainPart:IsDescendantOf(initiatorChar) then
		mainPart = iRoot
	end

	offset = offset or CFrame.new(0, 0, 1)

	local watchers = { initiator, recipient }
	local t0 = os.clock()

	logBoth(watchers, ("StartCarry | %s -> %s"):format(initiator.Name, recipient.Name))

	local saved = {
		WalkSpeed = rHum.WalkSpeed,
		JumpPower = rHum.JumpPower,
		JumpHeight = rHum.JumpHeight,
		UseJumpPower = rHum.UseJumpPower,
		AutoRotate = rHum.AutoRotate,
		PlatformStand = rHum.PlatformStand,
		Sit = rHum.Sit,
	}

	local savedStateEnables = disableHumanoidStates(rHum)

	local physicsData = {}
	for _, part in ipairs(recipientChar:GetDescendants()) do
		if part:IsA("BasePart") then
			physicsData[part] = {
				Massless = part.Massless,
				CanCollide = part.CanCollide,
				CanTouch = part.CanTouch,
				CustomProps = part.CustomPhysicalProperties,
			}
		end
	end

	local tracks = {}
	local animObjs = {}

	-- urutan anim dibiarkan seperti script asli
	if animLift then
		local t, a = loadAndPlay(rHum, animLift, true)
		tracks.lift = t
		animObjs.lift = a
	end

	if animCarry then
		local t, a = loadAndPlay(iHum, animCarry, true)
		tracks.carry = t
		animObjs.carry = a
	end

	rHum.Sit = false
	rHum.AutoRotate = false
	rHum.PlatformStand = true
	rHum.WalkSpeed = 0

	if rHum.UseJumpPower then
		rHum.JumpPower = 0
	else
		rHum.JumpHeight = 0
	end

	pcall(function()
		rHum:ChangeState(Enum.HumanoidStateType.Physics)
	end)

	for part, _ in pairs(physicsData) do
		if part and part.Parent then
			part.Massless = true
			part.CanCollide = false
			part.CanTouch = false
		end
	end

	setCharacterNetworkOwner(recipientChar, initiator)

	rRoot.AssemblyLinearVelocity = Vector3.zero
	rRoot.AssemblyAngularVelocity = Vector3.zero
	rRoot.CFrame = mainPart.CFrame * offset

	local carryWeld = Instance.new("WeldConstraint")
	carryWeld.Name = "CarryWeld"
	carryWeld.Part0 = mainPart
	carryWeld.Part1 = rRoot
	carryWeld.Parent = rRoot

	local noCol = createNoCollision(initiatorChar, recipientChar)

	-- penjaga anim seperti script asli
	local hb = RunService.Heartbeat:Connect(function()
		if tracks.lift and tracks.lift.Parent and not tracks.lift.IsPlaying then
			pcall(function()
				tracks.lift:Play(0.1, 1, 1)
			end)
		end

		if tracks.carry and tracks.carry.Parent and not tracks.carry.IsPlaying then
			pcall(function()
				tracks.carry:Play(0.1, 1, 1)
			end)
		end
	end)

	local released = false
	local events = {}

	local function releaseCarry(reason)
		if released then
			return
		end
		released = true

		logBoth(watchers, ("ReleaseCarry reason=%s"):format(tostring(reason or "manual")))

		if hb then
			hb:Disconnect()
		end

		for _, t in pairs(tracks) do
			pcall(function()
				t:Stop(0.1)
			end)
		end

		for _, a in pairs(animObjs) do
			pcall(function()
				a:Destroy()
			end)
		end

		if carryWeld then
			pcall(function()
				carryWeld:Destroy()
			end)
		end

		-- patch: kembalikan owner ke recipient dulu, lalu auto
		setCharacterNetworkOwner(recipientChar, recipient)

		if rRoot and rRoot.Parent then
			rRoot.AssemblyLinearVelocity = Vector3.zero
			rRoot.AssemblyAngularVelocity = Vector3.zero
		end

		for part, data in pairs(physicsData) do
			if part and part.Parent then
				part.Massless = data.Massless
				part.CanCollide = data.CanCollide
				part.CanTouch = data.CanTouch
				pcall(function()
					part.CustomPhysicalProperties = data.CustomProps
				end)
			end
		end

		if rRoot and rRoot.Parent and rHum and rHum.Parent then
			local dropPos, dropYaw = getDropPositionFromCarrier(iRoot, rRoot)
			safeDropPlacement(recipientChar, rHum, rRoot, dropPos, dropYaw, { initiatorChar })
		end

		if rRoot and rRoot.Parent then
			rRoot.AssemblyLinearVelocity = Vector3.zero
			rRoot.AssemblyAngularVelocity = Vector3.zero
		end

		if rHum and rHum.Parent then
			rHum.PlatformStand = saved.PlatformStand
			rHum.Sit = false
			rHum.AutoRotate = saved.AutoRotate

			rHum.WalkSpeed = (saved.WalkSpeed and saved.WalkSpeed > 0) and saved.WalkSpeed or 16
			if saved.UseJumpPower then
				rHum.JumpPower = (saved.JumpPower and saved.JumpPower > 0) and saved.JumpPower or 50
			else
				rHum.JumpHeight = (saved.JumpHeight and saved.JumpHeight > 0) and saved.JumpHeight or 7.2
			end

			restoreHumanoidStates(rHum, savedStateEnables)

			pcall(function()
				rHum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)

			task.delay(0.05, function()
				if rHum and rHum.Parent then
					pcall(function()
						rHum:ChangeState(Enum.HumanoidStateType.Running)
					end)
				end
			end)
		end

		task.delay(0.25, function()
			if recipientChar and recipientChar.Parent then
				setCharacterNetworkOwnershipAuto(recipientChar)
			end
		end)

		if noCol then
			task.delay(0.4, function()
				if noCol and noCol.Parent then
					pcall(function()
						noCol:Destroy()
					end)
				end
			end)
		end

		if initiatorCarryStatus then
			initiatorCarryStatus.Value = true
		end

		if recipientCarryStatus then
			recipientCarryStatus.Value = true
		end

		for _, e in ipairs(events) do
			pcall(function()
				e:Disconnect()
			end)
		end

		if sessionMarkA and sessionMarkA.Parent then
			sessionMarkA:Destroy()
		end

		if sessionMarkB and sessionMarkB.Parent then
			sessionMarkB:Destroy()
		end

		logBoth(watchers, ("Release done in %.3fs"):format(os.clock() - t0))
	end

	table.insert(events, iHum.Died:Connect(function()
		releaseCarry("initiator_died")
	end))

	table.insert(events, rHum.Died:Connect(function()
		releaseCarry("recipient_died")
	end))

	table.insert(events, initiator.CharacterRemoving:Connect(function()
		releaseCarry("initiator_removed")
	end))

	table.insert(events, recipient.CharacterRemoving:Connect(function()
		releaseCarry("recipient_removed")
	end))

	table.insert(events, initiatorCarryStatus:GetPropertyChangedSignal("Value"):Connect(function()
		if initiatorCarryStatus.Value then
			releaseCarry("initiator_flag")
		end
	end))

	table.insert(events, recipientCarryStatus:GetPropertyChangedSignal("Value"):Connect(function()
		if recipientCarryStatus.Value then
			releaseCarry("recipient_flag")
		end
	end))

	return function()
		releaseCarry("manual_cleanup")
	end
end

return function(a, b, mainPart, offset, animCarry, animLift)
	if typeof(a) == "table" and a.Players then
		return startCarry(a.Players.First, a.Players.Second, mainPart, offset, animCarry, animLift)
	else
		return startCarry(a, b, mainPart, offset, animCarry, animLift)
	end
end