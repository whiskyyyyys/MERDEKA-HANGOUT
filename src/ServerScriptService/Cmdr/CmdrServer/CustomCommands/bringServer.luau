return function(context, targets)
	local executor = context.Executor
	
	if not executor.Character or not executor.Character:FindFirstChild("HumanoidRootPart") then
		return "Gagal: Karaktermu belum spawn, tidak bisa membawa pemain."
	end
	
	local destCFrame = executor.Character.HumanoidRootPart.CFrame
	local count = 0
	
	for _, p in ipairs(targets) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			p.Character.HumanoidRootPart.CFrame = destCFrame * CFrame.new(0, 0, -3) -- Membawa mereka di depanmu
			count = count + 1
		end
	end
	
	return "Berhasil memanggil " .. count .. " pemain ke tempatmu."
end
