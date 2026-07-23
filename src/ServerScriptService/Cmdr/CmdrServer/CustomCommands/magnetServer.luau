return function(context, targetPlayer)
	local executor = context.Executor
	if executor == targetPlayer then
		return "Kamu tidak bisa menarik dirimu sendiri!"
	end
	
	if not executor.Character or not executor.Character:FindFirstChild("HumanoidRootPart") then
		return "Karaktermu tidak ditemukan!"
	end

	if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return "Karakter target tidak ditemukan!"
	end

	local targetRoot = targetPlayer.Character.HumanoidRootPart
	local execRoot = executor.Character.HumanoidRootPart

	-- Bersihkan efek magnet sebelumnya jika ada
	if targetRoot:FindFirstChild("MagnetAttachment") then
		targetRoot.MagnetAttachment:Destroy()
	end
	if targetRoot:FindFirstChild("MagnetConstraint") then
		targetRoot.MagnetConstraint:Destroy()
	end
	if execRoot:FindFirstChild("MagnetTargetAttachment_" .. targetPlayer.Name) then
		execRoot["MagnetTargetAttachment_" .. targetPlayer.Name]:Destroy()
	end

	-- Buat attachment di target
	local att0 = Instance.new("Attachment")
	att0.Name = "MagnetAttachment"
	att0.Parent = targetRoot

	-- Buat attachment di executor
	local att1 = Instance.new("Attachment")
	att1.Name = "MagnetTargetAttachment_" .. targetPlayer.Name
	att1.Position = Vector3.new(0, 0, -4) -- Di depan executor sejauh 4 stud
	att1.Parent = execRoot

	-- Buat constraint AlignPosition yang sangat kuat
	local alignPos = Instance.new("AlignPosition")
	alignPos.Name = "MagnetConstraint"
	alignPos.Attachment0 = att0
	alignPos.Attachment1 = att1
	alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
	alignPos.RigidityEnabled = false
	alignPos.MaxForce = 99999999 -- Sangat kuat
	alignPos.MaxVelocity = 100
	alignPos.Responsiveness = 100
	alignPos.Parent = targetRoot

	return "Magnet AKTIF: " .. targetPlayer.Name .. " ditarik kepadamu! Ketik unmagnet " .. targetPlayer.Name .. " untuk melepas."
end
