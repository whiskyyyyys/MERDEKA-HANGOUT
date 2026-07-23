return function(context, target)
	local executor = context.Executor
	
	if not executor.Character or not executor.Character:FindFirstChild("HumanoidRootPart") then
		return "Gagal: Karaktermu belum spawn."
	end
	
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		return "Gagal: Pemain tujuan tidak ditemukan atau belum spawn."
	end
	
	local destCFrame = target.Character.HumanoidRootPart.CFrame
	
	-- Teleport executor ke belakang / samping sedikit dari target
	executor.Character.HumanoidRootPart.CFrame = destCFrame * CFrame.new(3, 0, 0)
	
	return "Berhasil teleportasi ke " .. target.Name
end
