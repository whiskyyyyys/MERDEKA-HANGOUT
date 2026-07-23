local Debounce = true
local Swing
local Swing2
local Owner
local Damage = 0
local Equipped = false
local Humanoid

script.Parent.Equipped:connect(function()
	if script.Parent.Handle:FindFirstChild("Equip") then
		script.Parent.Handle.Equip:Play()
	end
	if (Swing == nil or Humanoid ~= script.Parent.Parent:FindFirstChild("Humanoid")) then 
		Humanoid = script.Parent.Parent:FindFirstChild("Humanoid")
		if Humanoid then
			Swing = Humanoid:LoadAnimation(script.Parent.Swing)
			Owner = game.Players:GetPlayerFromCharacter(Humanoid.Parent)
		end
	end
	if Humanoid and not Equipped then
		Equipped = true
		Humanoid.WalkSpeed = Humanoid.WalkSpeed + 10
		Humanoid.JumpPower = Humanoid.JumpPower + 10
	end		
end)

script.Parent.Unequipped:connect(function()
	if Equipped and Humanoid then
		Equipped = false
		Humanoid.WalkSpeed = Humanoid.WalkSpeed - 10
		Humanoid.JumpPower = Humanoid.JumpPower - 10
	end
end)

local Pbounce = true

script.Parent.Activated:connect(function()
	if (Swing) and Pbounce then
		Pbounce = false
		local choice = math.random(2)
		if choice == 1 then
			script.Parent.Handle.Slash:Play()
			Swing:Play()
		end
		wait(0.5)
		Pbounce = true
	end
end)
