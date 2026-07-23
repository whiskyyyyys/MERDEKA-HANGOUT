local tool = script.Parent
local humanoid
local climbTrack
local climbConnection
local isClimbing = false

-- Animasi climbing (ganti ID sesuai animasi kamu)
local climbAnim = Instance.new("Animation")
climbAnim.AnimationId = "rbxassetid://97330202665714" -- GANTI ID jika perlu

-- Stop climbing anim
local function stopClimb()
	if climbTrack and climbTrack.IsPlaying then
		climbTrack:Stop()
	end
end

local function handleStateChange(oldState, newState)
	-- Kalau mulai memanjat
	if newState == Enum.HumanoidStateType.Climbing then
		isClimbing = true
		if climbTrack then
			climbTrack:Play()
		end

		-- Kalau sudah turun / lepas climbing
	elseif newState ~= Enum.HumanoidStateType.Climbing then
		isClimbing = false
		stopClimb()
	end
end

tool.Equipped:Connect(function()
	humanoid = tool.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		climbTrack = humanoid:LoadAnimation(climbAnim)
		climbTrack.Priority = Enum.AnimationPriority.Action

		climbConnection = humanoid.StateChanged:Connect(handleStateChange)

		humanoid.Died:Connect(function()
			stopClimb()
			if climbConnection then climbConnection:Disconnect() end
		end)
	end
end)

tool.Unequipped:Connect(function()
	stopClimb()
	isClimbing = false
	if climbConnection then
		climbConnection:Disconnect()
		climbConnection = nil
	end
end)
