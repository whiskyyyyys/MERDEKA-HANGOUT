--// Hoverboard Script

local COOLDOWN_TIME: number = 3
local HOVERBOARD_SPEED: number = 40
local HOVERBOARD_ELEVATION: number = 5

type SpeedData = { WalkSpeed: number }
type ElevationData = { HipHeight: number }

local DEFAULT_HOVERBOARD_SPEED: SpeedData? = nil
local DEFAULT_HOVERBOARD_ELEVATION: ElevationData? = nil

local IS_HOVERBOARD_EQUIPPED: boolean = false
local CANCEL_HOVERBOARD_ACTIVATION: boolean = false
local HOVERBOARD_DEBOUNCE: boolean = false
local isHoverSoundPlaying: boolean = false

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// Attach hoverboard model when character spawns
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local hoverboardTemplate: Instance? = ServerStorage:FindFirstChild("HoverboardModel")
		if not (hoverboardTemplate and hoverboardTemplate:IsA("Model")) then return end

		local hoverboard: Model = hoverboardTemplate:Clone()
		hoverboard.Name = "HoverboardModel"
		hoverboard.Parent = character

		local leftFootInst = character:FindFirstChild("LeftFoot")
		local handleInst = hoverboard:FindFirstChild("Handle")

		if leftFootInst and leftFootInst:IsA("BasePart") and handleInst and handleInst:IsA("BasePart") then
			local leftFoot: BasePart = leftFootInst
			local handle: BasePart = handleInst

			--// Apply position + rotation (0, 180, 90)
			handle.CFrame =
				leftFoot.CFrame
				* CFrame.new(1, 0, 0)
				* CFrame.Angles(0, math.rad(180), math.rad(90))

			local weld: WeldConstraint = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = leftFoot
			weld.Parent = handle
		end
	end)
end)

--// Tool setup
local tool: Instance = script.Parent
if not tool:IsA("Tool") then return end

tool.Equipped:Connect(function()
	local characterInst: Instance? = tool.Parent
	if not (characterInst and characterInst:IsA("Model")) then return end
	local character: Model = characterInst

	local player: Player? = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	local animationsFolderInst = tool:FindFirstChild("Animations")
	if not (animationsFolderInst and animationsFolderInst:IsA("Folder")) then return end
	local animationsFolder: Folder = animationsFolderInst

	local equipAnimInst = animationsFolder:FindFirstChild("Equip")
	local idleAnimInst = animationsFolder:FindFirstChild("Idle")
	if not (equipAnimInst and equipAnimInst:IsA("Animation") and idleAnimInst and idleAnimInst:IsA("Animation")) then return end

	local equipAnim: Animation = equipAnimInst
	local idleAnim: Animation = idleAnimInst
	local equipTrack: AnimationTrack = animator:LoadAnimation(equipAnim)
	local idleTrack: AnimationTrack = animator:LoadAnimation(idleAnim)

	if not DEFAULT_HOVERBOARD_SPEED then
		DEFAULT_HOVERBOARD_SPEED = { WalkSpeed = humanoid.WalkSpeed }
	end
	if not DEFAULT_HOVERBOARD_ELEVATION then
		DEFAULT_HOVERBOARD_ELEVATION = { HipHeight = humanoid.HipHeight }
	end

	local hoverboardModelInst = character:FindFirstChild("HoverboardModel")
	if not (hoverboardModelInst and hoverboardModelInst:IsA("Model")) then return end
	local hoverboardModel: Model = hoverboardModelInst

	--// Functions
	local function toggleInvisibility(enable: boolean): ()
		for _, child in hoverboardModel:GetChildren() do
			if child:IsA("MeshPart") then
				child.Transparency = enable and 0 or 1
			end
		end
		for _, child in tool:GetChildren() do
			if child:IsA("MeshPart") then
				child.Transparency = enable and 1 or 0
			end
		end
	end

	local function updateHoverboardElevation(enable: boolean): ()
		if enable then
			local tween: Tween = TweenService:Create(
				humanoid,
				TweenInfo.new(1, Enum.EasingStyle.Quad),
				{ HipHeight = HOVERBOARD_ELEVATION }
			)
			tween:Play()
		elseif DEFAULT_HOVERBOARD_ELEVATION then
			humanoid.HipHeight = DEFAULT_HOVERBOARD_ELEVATION.HipHeight
		end
	end

	local function setHoverSoundVolume(volume: number): ()
		local handleInst = hoverboardModel:FindFirstChild("Handle")
		if handleInst and handleInst:IsA("BasePart") then
			local soundInst = handleInst:FindFirstChild("Hover")
			if soundInst and soundInst:IsA("Sound") then
				soundInst.Volume = volume
			end
		end
	end

	local function hoverSound(enable: boolean): ()
		local handleInst = hoverboardModel:FindFirstChild("Handle")
		if not (handleInst and handleInst:IsA("BasePart")) then return end

		local brakeSoundInst = handleInst:FindFirstChild("Brake")
		local hoverLoopInst = handleInst:FindFirstChild("Hover")

		if enable and not isHoverSoundPlaying then
			if hoverLoopInst and hoverLoopInst:IsA("Sound") then
				hoverLoopInst.Volume = 0.2
			end
			isHoverSoundPlaying = true
		elseif not enable and isHoverSoundPlaying then
			if brakeSoundInst and brakeSoundInst:IsA("Sound") then
				brakeSoundInst:Play()
			end
			if hoverLoopInst and hoverLoopInst:IsA("Sound") then
				hoverLoopInst.Volume = 0
			end
			isHoverSoundPlaying = false
		end
	end

	local function checkPlayerMovement(): ()
		if humanoid.MoveDirection.Magnitude > 0 and IS_HOVERBOARD_EQUIPPED and humanoid.WalkSpeed == HOVERBOARD_SPEED then
			hoverSound(true)
		else
			hoverSound(false)
		end
	end

	--// Jumping sound
	humanoid.Jumping:Connect(function(active: boolean)
		if active and IS_HOVERBOARD_EQUIPPED then
			local handleInst = hoverboardModel:FindFirstChild("Handle")
			if handleInst and handleInst:IsA("BasePart") then
				local jumpSoundInst = handleInst:FindFirstChild("Jump")
				if jumpSoundInst and jumpSoundInst:IsA("Sound") then
					jumpSoundInst:Play()
				end
			end
		end
	end)

	--// Movement check
	RunService.Heartbeat:Connect(function()
		checkPlayerMovement()
		if not IS_HOVERBOARD_EQUIPPED then
			if DEFAULT_HOVERBOARD_SPEED then humanoid.WalkSpeed = DEFAULT_HOVERBOARD_SPEED.WalkSpeed end
			if DEFAULT_HOVERBOARD_ELEVATION then humanoid.HipHeight = DEFAULT_HOVERBOARD_ELEVATION.HipHeight end
			idleTrack:Stop()
			isHoverSoundPlaying = false
			setHoverSoundVolume(0)
		end
	end)

	--// Activation (toggle hoverboard on/off)
	tool.Activated:Connect(function()
		if HOVERBOARD_DEBOUNCE then return end
		HOVERBOARD_DEBOUNCE = true
		CANCEL_HOVERBOARD_ACTIVATION = false

		if not IS_HOVERBOARD_EQUIPPED then
			-- Equip
			IS_HOVERBOARD_EQUIPPED = true
			player:SetAttribute("HoverboardSpeed", HOVERBOARD_SPEED)
			player:SetAttribute("HoverboardEnabled", true)

			if equipTrack.IsPlaying then equipTrack:Stop() end
			equipTrack.Looped = false
			equipTrack:Play()
			task.wait(math.min(equipTrack.Length, 0.6))

			if CANCEL_HOVERBOARD_ACTIVATION then
				IS_HOVERBOARD_EQUIPPED = false
				HOVERBOARD_DEBOUNCE = false
				return
			end

			humanoid.WalkSpeed = HOVERBOARD_SPEED
			idleTrack:Play()
			toggleInvisibility(true)
			updateHoverboardElevation(true)

			local hoverboardInst = hoverboardModel:FindFirstChild("Hoverboard")
			if hoverboardInst and hoverboardInst:IsA("MeshPart") then
				local backInst = hoverboardInst:FindFirstChild("BackParticles")
				local frontInst = hoverboardInst:FindFirstChild("FrontParticles")
				if backInst and backInst:IsA("Attachment") and frontInst and frontInst:IsA("Attachment") then
					local backPE = backInst:FindFirstChildOfClass("ParticleEmitter")
					local frontPE = frontInst:FindFirstChildOfClass("ParticleEmitter")
					if backPE then backPE.Enabled = true end
					if frontPE then frontPE.Enabled = true end
				end
			end

			local engineInst = hoverboardModel:FindFirstChild("Handle")
			if engineInst and engineInst:IsA("BasePart") then
				local engineSoundInst = engineInst:FindFirstChild("Engine")
				if engineSoundInst and engineSoundInst:IsA("Sound") then
					engineSoundInst.Volume = 0.05
				end
			end

		else
			-- Unequip
			idleTrack:Stop()
			IS_HOVERBOARD_EQUIPPED = false
			player:SetAttribute("HoverboardSpeed", nil)
			player:SetAttribute("HoverboardEnabled", false)
			toggleInvisibility(false)
			updateHoverboardElevation(false)

			local hoverboardInst = hoverboardModel:FindFirstChild("Hoverboard")
			if hoverboardInst and hoverboardInst:IsA("MeshPart") then
				local backInst = hoverboardInst:FindFirstChild("BackParticles")
				local frontInst = hoverboardInst:FindFirstChild("FrontParticles")
				if backInst and backInst:IsA("Attachment") and frontInst and frontInst:IsA("Attachment") then
					local backPE = backInst:FindFirstChildOfClass("ParticleEmitter")
					local frontPE = frontInst:FindFirstChildOfClass("ParticleEmitter")
					if backPE then backPE.Enabled = false end
					if frontPE then frontPE.Enabled = false end
				end
			end

			local engineInst = hoverboardModel:FindFirstChild("Handle")
			if engineInst and engineInst:IsA("BasePart") then
				local engineSoundInst = engineInst:FindFirstChild("Engine")
				if engineSoundInst and engineSoundInst:IsA("Sound") then
					engineSoundInst.Volume = 0
				end
			end
		end

		task.wait(COOLDOWN_TIME)
		HOVERBOARD_DEBOUNCE = false
	end)

	--// Unequip resets everything
	tool.Unequipped:Connect(function()
		CANCEL_HOVERBOARD_ACTIVATION = true
		if DEFAULT_HOVERBOARD_SPEED then humanoid.WalkSpeed = DEFAULT_HOVERBOARD_SPEED.WalkSpeed end
		if DEFAULT_HOVERBOARD_ELEVATION then humanoid.HipHeight = DEFAULT_HOVERBOARD_ELEVATION.HipHeight end
		player:SetAttribute("HoverboardSpeed", nil)
		player:SetAttribute("HoverboardEnabled", false)
		IS_HOVERBOARD_EQUIPPED = false
		idleTrack:Stop()
		if equipTrack and equipTrack.IsPlaying then equipTrack:Stop() end
		isHoverSoundPlaying = false
		toggleInvisibility(false)
		setHoverSoundVolume(0)

		local hoverboardInst = hoverboardModel:FindFirstChild("Hoverboard")
		if hoverboardInst and hoverboardInst:IsA("MeshPart") then
			local backInst = hoverboardInst:FindFirstChild("BackParticles")
			local frontInst = hoverboardInst:FindFirstChild("FrontParticles")
			if backInst and backInst:IsA("Attachment") and frontInst and frontInst:IsA("Attachment") then
				local backPE = backInst:FindFirstChildOfClass("ParticleEmitter")
				local frontPE = frontInst:FindFirstChildOfClass("ParticleEmitter")
				if backPE then backPE.Enabled = false end
				if frontPE then frontPE.Enabled = false end
			end
		end

		local engineInst = hoverboardModel:FindFirstChild("Handle")
		if engineInst and engineInst:IsA("BasePart") then
			local engineSoundInst = engineInst:FindFirstChild("Engine")
			if engineSoundInst and engineSoundInst:IsA("Sound") then
				engineSoundInst.Volume = 0
			end
		end
	end)
end)
