return function(context, targets)
	for _, p in ipairs(targets) do
		if p.Character and p.Character:FindFirstChild("Humanoid") then
			p.Character.Humanoid.WalkSpeed = 0
			p.Character.Humanoid.JumpPower = 0
			p.Character.Humanoid.UseJumpPower = true
		end
	end
	return "Pemain berhasil dibekukan!"
end
