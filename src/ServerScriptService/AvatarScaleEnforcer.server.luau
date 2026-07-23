local Players = game:GetService("Players")

local function enforceStandardScale(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	-- Fungsi untuk memaksa skala agar sama dengan avatar blocky standar
	local function setScale(scaleName, targetValue)
		local scaleObj = humanoid:FindFirstChild(scaleName)
		if scaleObj and scaleObj:IsA("NumberValue") then
			scaleObj.Value = targetValue
		end
	end

	-- Karena Roblox butuh waktu untuk merakit karakter R15, kita tunggu sebentar
	task.spawn(function()
		task.wait(1.5) -- Tunggu sampai avatar ter-load sempurna
		if not character.Parent then return end
		
		-- Hitung tinggi asli avatar dalam stud
		local height = character:GetExtentsSize().Y
		
		local bodyTypeScale = humanoid:FindFirstChild("BodyTypeScale")
		local isRthro = bodyTypeScale and bodyTypeScale.Value > 0.5
		
		-- Targetkan HANYA avatar Zepeto/Raksasa sungguhan (tinggi > 7.3 atau pakai proporsi Rthro)
		-- Avatar kotak (blocky) biasa meskipun sedikit tinggi tidak akan disentuh.
		if height > 7.3 or isRthro then
			print("[AvatarScale] Pemain", character.Name, "adalah Zepeto/Raksasa (" .. math.floor(height) .. " studs), mengecilkan ke standar...")
			for i = 1, 3 do
				if not character.Parent then break end
				
				-- Memaksa ukuran standar 1.0 (Blocky normal)
				setScale("BodyHeightScale", 1)
				setScale("BodyWidthScale", 1)
				setScale("BodyDepthScale", 1)
				setScale("HeadScale", 1)
				
				-- Memaksa proporsi standar
				setScale("BodyProportionScale", 0)
				setScale("BodyTypeScale", 0)
				
				task.wait(0.5)
			end
		else
			-- Biarkan avatar normal milik user tetap utuh!
			print("[AvatarScale] Pemain", character.Name, "tingginya wajar / bukan Zepeto, diabaikan.")
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(enforceStandardScale)
	
	if player.Character then
		enforceStandardScale(player.Character)
	end
end)

-- Untuk pemain yang sudah ada di server sebelum script ini jalan
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(enforceStandardScale)
	if player.Character then
		enforceStandardScale(player.Character)
	end
end
