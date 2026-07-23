--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player: Player = Players.LocalPlayer :: Player
local toolParent: Instance = script.Parent
if not toolParent:IsA("Tool") then
	return
end
local tool: Tool = toolParent

local camInst: Instance? = Workspace.CurrentCamera
if not (camInst and camInst:IsA("Camera")) then
	return
end
local camera: Camera = camInst

local INITIAL_SPEED: number = 1
local ACCELERATION_TIME: number = 1
local DECELERATION_TIME: number = 1
local GLIDE_DISTANCE: number = 5
local HOVERBOARD_GRAVITY: number = 40
local HOVERBOARD_JUMP_POWER: number = 30
local MIN_MOVEMENT_SPEED: number = 1.01

local CAMERA_SPEED_BASE: number = 1
local CAMERA_SPEED_MAX: number = 60
local CAMERA_MIN_FOV: number = 70
local CAMERA_MAX_FOV: number = 100
local CAMERA_TWEEN_SPEED: number = 10

local originalWalkSpeed: number? = nil
local originalGravity: number = Workspace.Gravity
local originalJumpPower: number? = nil

local currentSpeed: number = INITIAL_SPEED
local targetSpeed: number = INITIAL_SPEED
local hoverboardEnabled: boolean = false
local glideTimer: number = 0

local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil
local lastMoveDirection: Vector3 = Vector3.zero

local function getTargetSpeed(): number
	local attr = player:GetAttribute("HoverboardSpeed")
	if typeof(attr) == "number" then
		return attr
	end
	return INITIAL_SPEED
end

local function setupCharacter(): ()
	local char: Model = player.Character or player.CharacterAdded:Wait()
	local humInst: Instance = char:WaitForChild("Humanoid")
	if humInst:IsA("Humanoid") then
		humanoid = humInst
		if originalWalkSpeed == nil then
			originalWalkSpeed = humInst.WalkSpeed
		end
		if originalJumpPower == nil then
			originalJumpPower = humInst.JumpPower
		end
	end
	local rootInst: Instance = char:WaitForChild("HumanoidRootPart")
	if rootInst:IsA("BasePart") then
		rootPart = rootInst
	end
end

local function enableHoverboard(): ()
	if not humanoid then return end
	local hum: Humanoid = humanoid
	currentSpeed = INITIAL_SPEED
	hum.WalkSpeed = INITIAL_SPEED
	hum.UseJumpPower = true
	hum.JumpPower = HOVERBOARD_JUMP_POWER
	Workspace.Gravity = HOVERBOARD_GRAVITY
end

local function disableHoverboard(): ()
	if not humanoid then return end
	local hum: Humanoid = humanoid
	if originalWalkSpeed then
		hum.WalkSpeed = originalWalkSpeed
	end
	if originalJumpPower then
		hum.UseJumpPower = true
		hum.JumpPower = originalJumpPower
	end
	Workspace.Gravity = originalGravity
end

player:GetAttributeChangedSignal("HoverboardEnabled"):Connect(function()
	local attr = player:GetAttribute("HoverboardEnabled")
	hoverboardEnabled = attr == true
	if hoverboardEnabled then
		enableHoverboard()
	else
		disableHoverboard()
	end
end)

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter()
end

RunService.RenderStepped:Connect(function(dt: number)
	if not hoverboardEnabled or not humanoid or not rootPart then return end
	assert(humanoid and rootPart, "Hoverboard requires humanoid and rootPart")
	local hum: Humanoid = humanoid
	local root: BasePart = rootPart
	targetSpeed = getTargetSpeed()
	local moveDir: Vector3 = hum.MoveDirection
	local isWalking: boolean = moveDir.Magnitude > 0
	if isWalking then
		glideTimer = 0
		local newDir: Vector3 = moveDir.Magnitude > 0 and moveDir.Unit or lastMoveDirection
		local lastDir: Vector3 = lastMoveDirection.Magnitude > 0 and lastMoveDirection.Unit or newDir
		local directionDot: number = lastDir:Dot(newDir)
		local turnAngle: number = math.acos(math.clamp(directionDot, -1, 1))
		local turnFactor: number = math.clamp(turnAngle / math.rad(90), 0, 1)
		if directionDot < -0.6 then
			currentSpeed = 0
		end
		local turnSlowdownMultiplier: number = 1 - (turnFactor * 0.4)
		local adjustedTarget: number = targetSpeed * turnSlowdownMultiplier
		local acceleration: number = (adjustedTarget - currentSpeed) / ACCELERATION_TIME
		currentSpeed += acceleration * dt
		lastMoveDirection = newDir
	else
		glideTimer += dt
		local fastStopTime: number = 0.2
		local deceleration: number = (INITIAL_SPEED - currentSpeed) / fastStopTime
		currentSpeed += deceleration * dt
	end
	currentSpeed = math.clamp(currentSpeed, INITIAL_SPEED, targetSpeed)
	hum.WalkSpeed = currentSpeed
	if not isWalking and lastMoveDirection.Magnitude > 0 then
		if glideTimer < 1 then
			local offset: Vector3 = lastMoveDirection.Unit * GLIDE_DISTANCE
			hum:MoveTo(root.Position + offset)
		else
			hum:Move(Vector3.zero, false)
			hum.PlatformStand = true
			task.defer(function()
				if humanoid then
					local h: Humanoid = humanoid
					h.PlatformStand = false
				end
			end)
		end
	end
	if camera then
		if hoverboardEnabled then
			local speedRatio: number = math.clamp((currentSpeed - CAMERA_SPEED_BASE) / (CAMERA_SPEED_MAX - CAMERA_SPEED_BASE), 0, 1)
			local targetFOV: number = CAMERA_MIN_FOV + (CAMERA_MAX_FOV - CAMERA_MIN_FOV) * speedRatio
			camera.FieldOfView += (targetFOV - camera.FieldOfView) * math.clamp(CAMERA_TWEEN_SPEED * dt, 0, 1)
		else
			camera.FieldOfView += (CAMERA_MIN_FOV - camera.FieldOfView) * math.clamp(CAMERA_TWEEN_SPEED * dt, 0, 1)
		end
	end
end)