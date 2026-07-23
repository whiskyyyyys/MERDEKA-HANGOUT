return function(context, targetPlayer)
	local executor = context.Executor
	
	if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return "Karakter target tidak ditemukan!"
	end

	local targetRoot = targetPlayer.Character.HumanoidRootPart

	-- Bersihkan di sisi target
	local removed = false
	if targetRoot:FindFirstChild("MagnetAttachment") then
		targetRoot.MagnetAttachment:Destroy()
		removed = true
	end
	if targetRoot:FindFirstChild("MagnetConstraint") then
		targetRoot.MagnetConstraint:Destroy()
		removed = true
	end

	-- Bersihkan di sisi executor jika masih ada
	if executor.Character and executor.Character:FindFirstChild("HumanoidRootPart") then
		local execRoot = executor.Character.HumanoidRootPart
		local att = execRoot:FindFirstChild("MagnetTargetAttachment_" .. targetPlayer.Name)
		if att then
			att:Destroy()
		end
	end

	if removed then
		return "Magnet dilepaskan dari " .. targetPlayer.Name
	else
		return targetPlayer.Name .. " sedang tidak terkena efek magnet."
	end
end
