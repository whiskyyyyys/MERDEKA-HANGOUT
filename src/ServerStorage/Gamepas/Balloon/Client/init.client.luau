local Tool = script.Parent
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer   = Players.LocalPlayer
local OriginalGravity = workspace.Gravity

local Globo  = Tool:WaitForChild("Globo")
local Handle = Tool:WaitForChild("Handle")

-- ==================== SIGN TEXT & COLOR ====================
local text = Globo:WaitForChild("SurfaceGui"):WaitForChild("BallonSign")

local function updateSign()
	local signText = LocalPlayer:GetAttribute("SignText")
	local colorHex = LocalPlayer:GetAttribute("ToolColor")
	text.Text = (signText ~= nil and signText ~= "") and signText or "AFK"
	if colorHex then
		local ok, color = pcall(Color3.fromHex, colorHex)
		if ok then text.TextColor3 = color end
	end
end

updateSign()
LocalPlayer:GetAttributeChangedSignal("SignText"):Connect(updateSign)
LocalPlayer:GetAttributeChangedSignal("ToolColor"):Connect(updateSign)

-- ==================== ANIMASI HOLD BALON ====================
local HOLD_ANIM_ID = "rbxassetid://93276543034803"

local holdAnim     = Instance.new("Animation")
holdAnim.AnimationId = HOLD_ANIM_ID
local holdTrack    = nil

local function playHoldAnim(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
		or humanoid:WaitForChild("Animator", 3)
	if not animator then return end
	if holdTrack then
		holdTrack:Stop()
		holdTrack:Destroy()
		holdTrack = nil
	end
	holdTrack = animator:LoadAnimation(holdAnim)
	holdTrack.Priority = Enum.AnimationPriority.Action4
	holdTrack.Looped   = true
	holdTrack:Play()
end

local function stopHoldAnim()
	if holdTrack then
		holdTrack:Stop()
		holdTrack:Destroy()
		holdTrack = nil
	end
end

-- ==================== KONSTANTA FISIKA ====================
local PHYSICS = {
	RHO_AIR          = 1.225,
	RHO_HELIUM       = 0.164,
	DRAG_COEFF        = 0.47,
	ADDED_MASS_COEFF  = 0.5,
	ENVELOPE_MASS     = 0.004,
}

local CONFIG = {
	Radius             = 1.4,
	WindBaseSpeed      = 0.8,
	WindGustAmp        = 1.5,
	WindFreqScale      = 0.15,
	WindVerticalAmp    = 0.3,
	LinearDamping      = 0.08,
	CharSpeedThreshold = 1,
	SettleTime         = 6,
	SettleDamping      = 2,
	MinWindScale       = 0.03,
	ResetSpeed         = 3,
	VelKillAlpha       = 0.95,
	VelKillRate        = 4,
}

local R              = CONFIG.Radius
local VOLUME         = (4/3) * math.pi * R^3
local BALLOON_MASS   = PHYSICS.RHO_HELIUM * VOLUME + PHYSICS.ENVELOPE_MASS
local DRAG_FACTOR    = 0.5 * PHYSICS.DRAG_COEFF * PHYSICS.RHO_AIR * (math.pi * R^2)
local EFFECTIVE_MASS = BALLOON_MASS + PHYSICS.ADDED_MASS_COEFF * PHYSICS.RHO_AIR * VOLUME

-- ==================== SIMULASI ANGIN ====================
local function getWind(pos, t)
	local x, y, z = pos.X, pos.Y, pos.Z
	local f = CONFIG.WindFreqScale
	return Vector3.new(
		math.sin(t*0.3  + z*f*0.5)       * CONFIG.WindBaseSpeed
			+ math.sin(t*1.1 + y*f*0.8 + 2.7) * CONFIG.WindGustAmp * 0.5
			+ math.sin(t*3.7 + z*f*2   + 5.1) * CONFIG.WindGustAmp * 0.15,
		math.sin(t*1.6  + x*f*1.2 + 0.8) * CONFIG.WindVerticalAmp,
		math.cos(t*0.25 + x*f*0.4)        * CONFIG.WindBaseSpeed * 0.7
			+ math.cos(t*0.9 + x*f*0.6 + 1.3) * CONFIG.WindGustAmp * 0.4
			+ math.cos(t*4.1 + y*f*1.8 + 3.9) * CONFIG.WindGustAmp * 0.12
	)
end

-- ==================== KELAS SIMULATOR BALON ====================
local BalloonSimulator = {}
BalloonSimulator.__index = BalloonSimulator

function BalloonSimulator.new(character, balloon)
	local self = setmetatable({}, BalloonSimulator)
	self._active     = true
	self._clock      = 0
	self._stillTimer = 0
	self._character  = character
	self._balloon    = balloon

	balloon.Massless = true
	balloon.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.05, 0.7, 0.05, 0.8)

	local attachment       = Instance.new("Attachment")
	attachment.Name        = "ForceAttachment"
	attachment.Parent      = balloon

	local vectorForce                = Instance.new("VectorForce")
	vectorForce.Name                 = "SimulatedHeliumForce"
	vectorForce.ApplyAtCenterOfMass  = true
	vectorForce.RelativeTo           = Enum.ActuatorRelativeTo.World
	vectorForce.Force                = Vector3.zero
	vectorForce.Attachment0          = attachment
	vectorForce.Parent               = balloon

	self._vectorForce = vectorForce
	self._attachment  = attachment

	self._heartbeat = RunService.Heartbeat:Connect(function(dt)
		if not self._active or not balloon or not balloon.Parent then
			self:Destroy()
			return
		end

		self._clock += dt

		local rootPart = self._character and self._character:FindFirstChild("HumanoidRootPart")
		local charVel  = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
		local hSpeed   = Vector3.new(charVel.X, 0, charVel.Z).Magnitude

		if hSpeed < CONFIG.CharSpeedThreshold then
			self._stillTimer = math.min(self._stillTimer + dt, CONFIG.SettleTime)
		else
			self._stillTimer = math.max(self._stillTimer - dt * CONFIG.ResetSpeed, 0)
		end

		local t      = math.clamp(self._stillTimer / CONFIG.SettleTime, 0, 1)
		local settle = t * t * (3 - 2 * t)

		local gravity    = workspace.Gravity
		local balloonVel = balloon.AssemblyLinearVelocity
		local mass       = balloon:GetMass()

		local wind   = getWind(balloon.Position, self._clock) * (1 - settle * (1 - CONFIG.MinWindScale))
		local relVel = balloonVel - wind
		local speed  = relVel.Magnitude

		if settle > CONFIG.VelKillAlpha then
			local kill = math.min(1,
				(dt * CONFIG.VelKillRate)
					* ((settle - CONFIG.VelKillAlpha) / (1 - CONFIG.VelKillAlpha))
			)
			balloon.AssemblyLinearVelocity  = balloon.AssemblyLinearVelocity:Lerp(Vector3.zero, kill)
			balloon.AssemblyAngularVelocity = balloon.AssemblyAngularVelocity:Lerp(Vector3.zero, kill)
		end

		local massRatio = (EFFECTIVE_MASS > 0 and mass > 0) and (mass / EFFECTIVE_MASS) or 0

		local gravForce = Vector3.new(0, mass * gravity, 0)
		local buoyancy  = Vector3.new(0, PHYSICS.RHO_AIR * VOLUME * gravity, 0)
		local heliumWgt = Vector3.new(0, -BALLOON_MASS * gravity, 0)
		local drag      = (speed > 0.001) and (-relVel.Unit * DRAG_FACTOR * speed * speed) or Vector3.zero
		local damping   = -balloonVel * (CONFIG.LinearDamping + (CONFIG.SettleDamping - CONFIG.LinearDamping) * settle)

		self._vectorForce.Force = gravForce + (buoyancy + heliumWgt + drag + damping) * massRatio
	end)

	return self
end

function BalloonSimulator:Destroy()
	if not self._active then return end
	self._active = false
	if self._heartbeat   then self._heartbeat:Disconnect()   end
	if self._vectorForce then self._vectorForce:Destroy()    end
	if self._attachment  then self._attachment:Destroy()     end
end

-- ==================== STATE & HELPER ====================
local simulator  = nil
local seatedConn = nil
local diedConn   = nil

local function resetHumanoid(character)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.UseJumpPower = false
	humanoid.JumpPower    = 50
end

local function cleanUp()
	if seatedConn then seatedConn:Disconnect(); seatedConn = nil end
	if diedConn   then diedConn:Disconnect();   diedConn   = nil end
	if simulator  then simulator:Destroy();      simulator  = nil end
	stopHoldAnim()
	-- ✅ Selalu reset gravity saat cleanup
	workspace.Gravity = OriginalGravity
end

local function onDied()
	cleanUp()
	-- ✅ Reset humanoid pas mati
	local character = LocalPlayer.Character
	resetHumanoid(character)
end

local function setupDiedConnection(character)
	if diedConn then diedConn:Disconnect(); diedConn = nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		diedConn = humanoid.Died:Connect(onDied)
	end
end

-- ==================== EVENT TOOL ====================
Tool.Equipped:Connect(function()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	cleanUp()
	updateSign()

	simulator = BalloonSimulator.new(character, Globo)
	playHoldAnim(character)

	-- ✅ Gravity hanya diubah di client
	workspace.Gravity = 10

	humanoid.UseJumpPower = true
	humanoid.JumpPower    = 12

	seatedConn = humanoid.Seated:Connect(function(isSeated)
		if not isSeated then
			task.delay(1, function()
				local h = character:FindFirstChildOfClass("Humanoid")
				if h then
					h.UseJumpPower = true
					h.JumpPower    = 12
				end
			end)
		end
	end)
end)

Tool.Unequipped:Connect(function()
	cleanUp()
	resetHumanoid(LocalPlayer.Character)
end)

Tool:GetPropertyChangedSignal("Parent"):Connect(function()
	local parent = Tool.Parent
	if not parent or parent ~= LocalPlayer.Character then
		cleanUp()
		resetHumanoid(LocalPlayer.Character)
	end
end)

-- ==================== EVENT KARAKTER ====================
local function onCharacterAdded(character)
	-- ✅ Selalu reset gravity saat respawn
	workspace.Gravity = OriginalGravity
	cleanUp()
	setupDiedConnection(character)
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)