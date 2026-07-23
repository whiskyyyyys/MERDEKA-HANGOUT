local Tool = script.Parent
local Humanoid
local Animator
local Equipped = false
local ComboIndex = 1
local Animations = {}
local Pbounce = true

Tool.Equipped:Connect(function()
	local Character = Tool.Parent
	Humanoid = Character:FindFirstChild("Humanoid")

	if Humanoid then
		Animator = Humanoid:FindFirstChildOfClass("Animator")
		if not Animator then
			Animator = Instance.new("Animator")
			Animator.Parent = Humanoid
		end

		-- Load 5 animations
		Animations = {}
		for i = 1, 5 do
			local anim = Tool:FindFirstChild("Slash"..i)
			if anim and anim:IsA("Animation") then
				Animations[i] = Animator:LoadAnimation(anim)
			end
		end

		if not Equipped then
			Equipped = true
			Humanoid.WalkSpeed += 10
			Humanoid.JumpPower += 10
		end
	end
end)

Tool.Unequipped:Connect(function()
	if Equipped and Humanoid then
		Equipped = false
		Humanoid.WalkSpeed -= 10
		Humanoid.JumpPower -= 10
	end
end)

Tool.Activated:Connect(function()
	if Animations[ComboIndex] and Pbounce then
		Pbounce = false

		-- Play same slash sound each time
		if Tool:FindFirstChild("Handle") and Tool.Handle:FindFirstChild("Slash") then
			Tool.Handle.Slash:Play()
		end

		-- Play animation
		Animations[ComboIndex]:Play()

		-- Advance combo
		ComboIndex += 1
		if ComboIndex > #Animations then
			ComboIndex = 1
		end

		task.wait(0.5)
		Pbounce = true
	end
end)

-- [[Delexory A.K.A | Wxndev]]