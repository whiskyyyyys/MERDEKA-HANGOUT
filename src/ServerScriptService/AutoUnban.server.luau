-- Script ini dibuat untuk secara otomatis mencabut ban "wh9six" begitu game dinyalakan
local Players = game:GetService("Players")

task.spawn(function()
	print("[AutoUnban] Sedang mencoba membuka gembok ban untuk wh9six...")
	
	local ok, userId = pcall(function()
		return Players:GetUserIdFromNameAsync("wh9six")
	end)
	
	if ok and userId then
		local unbanOk, unbanErr = pcall(function()
			Players:UnbanAsync({
				UserIds = {userId},
				ApplyToUniverse = true
			})
		end)
		
		if unbanOk then
			print("✅ [AutoUnban] SUKSES! Akun wh9six (ID: " .. userId .. ") sudah tidak di-ban lagi. Anda sudah bisa masuk!")
		else
			warn("❌ [AutoUnban] GAGAL mencabut ban:", unbanErr)
		end
	else
		warn("❌ [AutoUnban] Gagal mencari ID untuk username wh9six!")
	end
	
	-- Hapus script ini agar tidak nyampah
	script:Destroy()
end)
