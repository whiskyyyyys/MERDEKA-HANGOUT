return function(context, targets)
	for _, p in ipairs(targets) do
		if p.Character and p.Character:FindFirstChild("Humanoid") then
			p.Character.Humanoid.WalkSpeed = 16
			p.Character.Humanoid.JumpPower = 50
		end
	end
	return "Pemain berhasil dicairkan!"
end
