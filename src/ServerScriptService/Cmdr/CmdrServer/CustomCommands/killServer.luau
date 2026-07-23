return function(context, targets)
	local count = 0
	
	for _, p in ipairs(targets) do
		if p.Character and p.Character:FindFirstChild("Humanoid") then
			p.Character.Humanoid.Health = 0
			count = count + 1
		end
	end
	
	return "Berhasil membunuh " .. count .. " pemain."
end
