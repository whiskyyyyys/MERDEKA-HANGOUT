local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(context, userId)
	local unbanFunc = ReplicatedStorage:FindFirstChild("_UnbanPlayer")
	if not unbanFunc then
		return "Error: BanService belum dimuat di server."
	end
	
	if not tonumber(userId) then
		return "Gagal: UserId harus berupa angka."
	end
	
	local success, err = unbanFunc:Invoke(userId)
	if success then
		return "Berhasil menghapus status ban untuk UserId " .. userId .. "."
	else
		return "Gagal menghapus ban: " .. tostring(err)
	end
end
