local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(context, targets, days, reason)
	local banFunc = ReplicatedStorage:FindFirstChild("_BanPlayer")
	if not banFunc then
		return "Error: BanService belum dimuat di server."
	end
	
	local count = 0
	local executorName = context.Executor and context.Executor.Name or "Server Admin"
	
	for _, p in ipairs(targets) do
		local success, err = banFunc:Invoke(p.UserId, reason, days, executorName)
		if success then
			count = count + 1
		else
			warn("[Cmdr] Gagal ban pemain " .. p.Name .. ": " .. tostring(err))
		end
	end
	
	local durationStr = "selamanya"
	if days and days > 0 then
		durationStr = "selama " .. days .. " hari"
	end
	
	return "Berhasil mem-ban " .. count .. " pemain " .. durationStr .. "."
end
