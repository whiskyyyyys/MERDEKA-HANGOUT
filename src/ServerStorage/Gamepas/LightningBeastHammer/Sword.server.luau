local Debounce = true
local Swing
local Owner

local Damage = 0

local Equipped = false
local Humanoid

script.Parent.Equipped:connect(function()
	if script.Parent.Handle:FindFirstChild("Equip") then
		script.Parent.Handle.Equip:Play()
	end
	if Swing == nil or Humanoid ~= script.Parent.Parent:FindFirstChild("Humanoid") then
		Humanoid = script.Parent.Parent:FindFirstChild("Humanoid")
		if Humanoid then
			Swing = Humanoid:LoadAnimation(script.Parent.Swing)	
			Owner = game.Players:GetPlayerFromCharacter(Humanoid.Parent)	
		end
	end
	if Humanoid and not Equipped then
		Equipped = true
		Humanoid.WalkSpeed = Humanoid.WalkSpeed + 16
		Humanoid.JumpPower = Humanoid.JumpPower + 50
	end		
end)

script.Parent.Unequipped:connect(function()
	if Equipped and Humanoid then
		Equipped = false
		Humanoid.WalkSpeed = Humanoid.WalkSpeed - 16
		Humanoid.JumpPower = Humanoid.JumpPower - 50
	end	
end)

local Pbounce = true

script.Parent.Activated:connect(function()
	if Swing and Pbounce then
		Pbounce = false
		script.Parent.Handle.Slash:Play()
		Swing:Play()
		wait(0.5)
		Pbounce = true
	end
end)

--wxndev