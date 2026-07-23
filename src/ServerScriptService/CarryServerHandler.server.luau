if _G.__CARRY_SERVER_LOADED then
	warn("[CARRY] Duplicate CarryServerHandler prevented:", script:GetFullName())
	return
end
_G.__CARRY_SERVER_LOADED = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryReplic = ReplicatedStorage:WaitForChild("CarryReplic")
local CarryRemotes = CarryReplic:WaitForChild("CarryRemotes")
local CarryRemote = CarryRemotes:WaitForChild("CarryRemote")
local CarryChoicesFolder = CarryReplic:WaitForChild("CarryChoices")

local maxDistanceValue = CarryRemotes:FindFirstChild("MAX_DISTANCE")
local MAX_DISTANCE = tonumber(maxDistanceValue and maxDistanceValue.Value) or 10

local ActiveCarries = {}
local PendingByTarget = {}
local PendingByRequester = {}

local function fireClientSafe(plr, action, data)
	if plr and plr.Parent == Players then
		CarryRemote:FireClient(plr, action, data)
	end
end

local function setCanAsk(plr, value)
	if not plr or plr.Parent ~= Players then
		return
	end

	local flag = plr:FindFirstChild("CanAskCarry")
	if flag then
		flag.Value = value
	end
end

local function setCarryable(plr, value)
	if not plr or not plr.Character then
		return
	end

	local flag = plr.Character:FindFirstChild("Carryble")
	if flag then
		flag.Value = value
	end
end

local function getCanAsk(plr)
	local flag = plr and plr:FindFirstChild("CanAskCarry")
	return flag and flag.Value == true
end

local function getCarryable(plr)
	local flag = plr and plr.Character and plr.Character:FindFirstChild("Carryble")
	return flag and flag.Value == true
end

local function getRoot(char)
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function isTooFar(firstChar, secondChar, maxDist)
	local root1 = getRoot(firstChar)
	local root2 = getRoot(secondChar)

	if not (root1 and root2) then
		return true
	end

	return (root1.Position - root2.Position).Magnitude > maxDist
end

local function isPlayerValid(plr)
	return plr and plr.Parent == Players
end

local function resolveCarryModule(choice)
	if typeof(choice) == "Instance" and choice:IsA("ModuleScript") then
		if choice:IsDescendantOf(CarryChoicesFolder) then
			return choice
		end
		return nil
	end

	if type(choice) ~= "string" or choice == "" then
		return nil
	end

	local fixedChoice = choice

	if fixedChoice == "Seret" and not CarryChoicesFolder:FindFirstChild("Seret") then
		if CarryChoicesFolder:FindFirstChild("Nyeret") then
			fixedChoice = "Nyeret"
		end
	end

	local found = CarryChoicesFolder:FindFirstChild(fixedChoice)
	if found and found:IsA("ModuleScript") then
		return found
	end

	return nil
end

local function clearPendingForTarget(target)
	local pending = PendingByTarget[target]
	if not pending then
		return
	end

	PendingByTarget[target] = nil
	if pending.requester then
		PendingByRequester[pending.requester] = nil
	end

	setCanAsk(target, true)
	if pending.requester then
		setCanAsk(pending.requester, true)
	end

	fireClientSafe(target, "HideCarryRequest", {})
end

local function clearPendingForRequester(requester)
	local target = PendingByRequester[requester]
	if target then
		clearPendingForTarget(target)
	end
end

local function endCarryFor(plr)
	local session = ActiveCarries[plr]
	if not session then
		return
	end

	ActiveCarries[plr] = nil
	local other = session.other
	if other then
		ActiveCarries[other] = nil
	end

	if typeof(session.cleanup) == "function" then
		pcall(session.cleanup)
	end

	for _, side in ipairs({ plr, other }) do
		if side and side.Parent == Players then
			setCanAsk(side, true)
			setCarryable(side, true)
			fireClientSafe(side, "CarryEnded", {})
		end
	end
end

local function startCarrySession(requester, target, carryChoice)
	if not (isPlayerValid(requester) and isPlayerValid(target)) then
		return false
	end

	if requester == target then
		return false
	end

	if ActiveCarries[requester] or ActiveCarries[target] then
		return false
	end

	if isTooFar(requester.Character, target.Character, MAX_DISTANCE) then
		return false
	end

	local carryModule = resolveCarryModule(carryChoice)
	if not carryModule then
		return false
	end

	setCanAsk(requester, false)
	setCanAsk(target, false)
	setCarryable(requester, false)
	setCarryable(target, false)

	local cleanupResult
	local ok, result = pcall(function()
		local optionModuleArgs = {
			Players = {
				First = requester,
				Second = target,
			}
		}
		return require(carryModule)(optionModuleArgs)
	end)

	if ok then
		cleanupResult = result
	else
		setCanAsk(requester, true)
		setCanAsk(target, true)
		setCarryable(requester, true)
		setCarryable(target, true)
		warn("[CARRY] Module carry error:", result)
		return false
	end

	ActiveCarries[requester] = {
		other = target,
		cleanup = cleanupResult,
	}

	ActiveCarries[target] = {
		other = requester,
		cleanup = cleanupResult,
	}

	-- Player A
	fireClientSafe(requester, "CarryStarted", {
		role = "carrier",
		otherUserId = target.UserId,
		otherName = target.DisplayName,
	})

	-- Player B
	fireClientSafe(target, "CarryStarted", {
		role = "carried",
		otherUserId = requester.UserId,
		otherName = requester.DisplayName,
	})

	return true
end

local function canRequestCarry(requester, target)
	if not (isPlayerValid(requester) and isPlayerValid(target)) then
		return false
	end

	if requester == target then
		return false
	end

	if not requester.Character or not target.Character then
		return false
	end

	if ActiveCarries[requester] or ActiveCarries[target] then
		return false
	end

	if PendingByRequester[requester] or PendingByTarget[target] then
		return false
	end

	if not getCanAsk(requester) or not getCanAsk(target) then
		return false
	end

	if not getCarryable(requester) or not getCarryable(target) then
		return false
	end

	if isTooFar(requester.Character, target.Character, MAX_DISTANCE) then
		return false
	end

	return true
end

local function createPendingRequest(requester, target, carryChoice)
	if not canRequestCarry(requester, target) then
		return
	end

	local carryModule = resolveCarryModule(carryChoice)
	if not carryModule then
		return
	end

	PendingByTarget[target] = {
		requester = requester,
		module = carryModule,
	}

	PendingByRequester[requester] = target

	setCanAsk(requester, false)
	setCanAsk(target, false)

	fireClientSafe(target, "ShowCarryRequest", {
		requesterUserId = requester.UserId,
		requesterName = requester.DisplayName,
		carryType = carryModule.Name,
	})
end

local function handleCarryResponse(target, accepted, requesterUserId)
	local pending = PendingByTarget[target]
	if not pending then
		return
	end

	local requester = pending.requester
	if not isPlayerValid(requester) then
		clearPendingForTarget(target)
		return
	end

	if requesterUserId and requester.UserId ~= requesterUserId then
		return
	end

	PendingByTarget[target] = nil
	PendingByRequester[requester] = nil

	if not accepted then
		setCanAsk(target, true)
		setCanAsk(requester, true)
		fireClientSafe(target, "HideCarryRequest", {})
		return
	end

	local success = startCarrySession(requester, target, pending.module)
	if not success then
		setCanAsk(target, true)
		setCanAsk(requester, true)
		setCarryable(target, true)
		setCarryable(requester, true)
		fireClientSafe(target, "HideCarryRequest", {})
	end
end

local function ensurePlayerFlags(plr)
	local canAskCarry = plr:FindFirstChild("CanAskCarry")
	if not canAskCarry then
		canAskCarry = Instance.new("BoolValue")
		canAskCarry.Name = "CanAskCarry"
		canAskCarry.Value = true
		canAskCarry.Parent = plr
	else
		canAskCarry.Value = true
	end
end

local function onCharacterAdded(plr, character)
	local carryble = character:FindFirstChild("Carryble")
	if not carryble then
		carryble = Instance.new("BoolValue")
		carryble.Name = "Carryble"
		carryble.Value = true
		carryble.Parent = character
	else
		carryble.Value = true
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			clearPendingForRequester(plr)
			clearPendingForTarget(plr)
			endCarryFor(plr)
			setCarryable(plr, true)
			setCanAsk(plr, true)
		end)
	end
end

local function onPlayerAdded(plr)
	ensurePlayerFlags(plr)

	plr.CharacterAdded:Connect(function(character)
		onCharacterAdded(plr, character)
	end)

	if plr.Character then
		task.spawn(onCharacterAdded, plr, plr.Character)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, plr)
end
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(plr)
	clearPendingForRequester(plr)
	clearPendingForTarget(plr)
	endCarryFor(plr)
end)

CarryRemote.OnServerEvent:Connect(function(plr, action, a, b)
	local ok, err = pcall(function()
		if action == "RequestCarry" then
			local targetPlr = a
			local carryType = b
			createPendingRequest(plr, targetPlr, carryType)

		elseif action == "CarryResponse" then
			local accepted = a == true
			local requesterUserId = b
			handleCarryResponse(plr, accepted, requesterUserId)

		elseif action == "DropCarry" then
			clearPendingForRequester(plr)
			clearPendingForTarget(plr)
			endCarryFor(plr)
		end
	end)

	if not ok then
		warn("CarryRemote server error:", err)
	end
end)