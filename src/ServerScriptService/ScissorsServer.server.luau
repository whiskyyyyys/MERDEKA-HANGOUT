-- ScissorsServer (Script di ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local remote = ReplicatedStorage:WaitForChild("ScissorsRemote")

local MAX_RANGE = 12 -- jarak maksimal (studs) agar tidak abuse
local COOLDOWN = 2 -- detik antara penggunaan untuk tiap player

local lastUse = {} -- lastUse[player] = timestamp

local function removeHairFromCharacter(character)
	if not character then return end

	-- Hapus semua Accessory (topi / rambut)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			-- secara aman hentikan apa pun yang perlu, lalu destroy
			child:Destroy()
		elseif child:IsA("MeshPart") or child:IsA("Part") then
			-- kalau nama mengandung 'hair' hapus juga (beberapa model rambut dibuat MeshPart)
			local nameLower = child.Name:lower()
			if string.find(nameLower, "hair") or string.find(nameLower, "ponytail") or string.find(nameLower, "bang") then
				child:Destroy()
			end
		end
	end

	-- juga cek descendant yang mungkin menempel di head
	local head = character:FindFirstChild("Head")
	if head then
		for _, d in ipairs(head:GetChildren()) do
			local n = d.Name:lower()
			if d:IsA("MeshPart") and (string.find(n, "hair") or string.find(n, "bang")) then
				d:Destroy()
			end
		end
	end
end

remote.OnServerEvent:Connect(function(playerThatFired, targetPlayer)
	-- safety checks
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return
	end
	-- jangan self
	if playerThatFired == targetPlayer then
		return
	end

	-- cooldown
	local now = tick()
	local last = lastUse[playerThatFired]
	if last and (now - last) < COOLDOWN then
		return
	end
	lastUse[playerThatFired] = now

	-- pastikan karakter ada dan humanoid ada
	local charA = playerThatFired.Character
	local charB = targetPlayer.Character
	if not (charA and charB) then return end

	local headA = charA:FindFirstChild("Head")
	local headB = charB:FindFirstChild("Head")
	if not (headA and headB) then return end

	-- periksa jarak
	local distance = (headA.Position - headB.Position).Magnitude
	if distance > MAX_RANGE then
		return
	end

	-- validasi tambahan (mis. apakah sedang di team yang sama?) - opsional
	-- lakukan aksi: hapus rambut/aksesoris target
	removeHairFromCharacter(charB)

	-- opsional: efek suara / partikel bisa ditambahkan di sini (dengan RemoteEvent lagi ke client target)
end)
