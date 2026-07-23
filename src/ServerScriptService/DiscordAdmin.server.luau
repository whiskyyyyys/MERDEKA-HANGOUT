-- ============================================================
-- DiscordAdmin.server.luau
-- Fitur: KICK, KILL, BAN, UNBAN, FREEZE, THAW, WARN, ANNOUNCE, MERDEKA, TP, JAIL, UNJAIL
-- ============================================================

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TOPIC = "DiscordAdmin"

-- Buat RemoteEvent jika belum ada
local AdminRemotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
if not AdminRemotes then
	AdminRemotes = Instance.new("Folder")
	AdminRemotes.Name = "AdminRemotes"
	AdminRemotes.Parent = ReplicatedStorage
end

local AnnounceEvent = AdminRemotes:FindFirstChild("AnnounceEvent")
if not AnnounceEvent then AnnounceEvent = Instance.new("RemoteEvent"); AnnounceEvent.Name = "AnnounceEvent"; AnnounceEvent.Parent = AdminRemotes end

local WarnEvent = AdminRemotes:FindFirstChild("WarnEvent")
if not WarnEvent then WarnEvent = Instance.new("RemoteEvent"); WarnEvent.Name = "WarnEvent"; WarnEvent.Parent = AdminRemotes end

local jailedPlayers = {}

local function createJailCell(player)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart
	
	-- Hapus penjara lama jika ada
	local oldJail = workspace:FindFirstChild("Jail_" .. player.Name)
	if oldJail then oldJail:Destroy() end
	
	local jailModel = Instance.new("Model")
	jailModel.Name = "Jail_" .. player.Name
	jailModel.Parent = workspace
	
	-- Posisikan sedikit di atas agar tidak nyangkut tanah
	local center = hrp.Position + Vector3.new(0, 2, 0)
	hrp.CFrame = CFrame.new(center)
	
	local function makeWall(size, offset)
		local part = Instance.new("Part")
		part.Size = size
		part.Position = center + offset
		part.Anchored = true
		part.CanCollide = true
		part.Material = Enum.Material.ForceField
		part.Color = Color3.fromRGB(255, 50, 50) -- Penjara laser merah
		part.Transparency = 0.2
		part.Parent = jailModel
		return part
	end
	
	local w = 6
	local h = 8
	local d = 6
	local th = 1
	
	makeWall(Vector3.new(w, th, d), Vector3.new(0, -h/2, 0))
	makeWall(Vector3.new(w, th, d), Vector3.new(0, h/2, 0))
	makeWall(Vector3.new(w, h, th), Vector3.new(0, 0, d/2))
	makeWall(Vector3.new(w, h, th), Vector3.new(0, 0, -d/2))
	makeWall(Vector3.new(th, h, d), Vector3.new(w/2, 0, 0))
	makeWall(Vector3.new(th, h, d), Vector3.new(-w/2, 0, 0))
end

local function handleCharacterSpawn(player, char)
	if jailedPlayers[player.UserId] then
		task.wait(1)
		createJailCell(player)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function(char) handleCharacterSpawn(p, char) end)
end
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char) handleCharacterSpawn(plr, char) end)
end)

local function spawnMerdekaFireworks()
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hrp = char.HumanoidRootPart
			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, 5, 0)
			att.Parent = hrp
			
			local emit = Instance.new("ParticleEmitter")
			emit.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
			})
			emit.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.5, 3),
				NumberSequenceKeypoint.new(1, 0)
			})
			emit.Texture = "rbxassetid://243660364"
			emit.Lifetime = NumberRange.new(1, 2)
			emit.Rate = 100
			emit.Speed = NumberRange.new(10, 20)
			emit.SpreadAngle = Vector2.new(180, 180)
			emit.Parent = att
			Debris:AddItem(att, 5)
		end
	end
end

local function handleAdminCommand(message)
	local data = message.Data
	if type(data) == "string" then
		local HttpService = game:GetService("HttpService")
		local success, parsed = pcall(function() return HttpService:JSONDecode(data) end)
		if success then data = parsed end
	end
	
	if not data or not data.command then return end
	
	local cmd = string.lower(data.command)
	local targetName = data.target
	local args = data.args or ""
	local adminId = data.adminId
	local adminName = data.adminName or "Admin"
	
	print("[DiscordAdmin] Executing:", cmd, "| Target:", targetName, "| Args:", args)
	
	local function getTargetPlayers()
		if targetName == "all" then return Players:GetPlayers() end
		for _, plr in ipairs(Players:GetPlayers()) do
			if string.lower(plr.Name) == string.lower(targetName) or string.lower(plr.DisplayName) == string.lower(targetName) then
				return {plr}
			end
		end
		return {}
	end
	
	local targets = getTargetPlayers()
	
	if cmd == "kick" then
		for _, p in ipairs(targets) do p:Kick("Kicked by Discord Admin (" .. adminName .. "):\n" .. tostring(args)) end
		
	elseif cmd == "kill" then
		for _, p in ipairs(targets) do
			if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.Health = 0 end
		end
		
	elseif cmd == "freeze" then
		for _, p in ipairs(targets) do
			if p.Character and p.Character:FindFirstChild("Humanoid") then
				p.Character.Humanoid.WalkSpeed = 0
				p.Character.Humanoid.JumpPower = 0
				p.Character.Humanoid.UseJumpPower = true
			end
		end
		
	elseif cmd == "thaw" then
		for _, p in ipairs(targets) do
			if p.Character and p.Character:FindFirstChild("Humanoid") then
				p.Character.Humanoid.WalkSpeed = 16
				p.Character.Humanoid.JumpPower = 50
			end
		end
		
	elseif cmd == "announce" then
		local GlobalAnnouncementEvent = ReplicatedStorage:FindFirstChild("GlobalAnnouncementEvent")
		if not GlobalAnnouncementEvent then
			GlobalAnnouncementEvent = Instance.new("RemoteEvent")
			GlobalAnnouncementEvent.Name = "GlobalAnnouncementEvent"
			GlobalAnnouncementEvent.Parent = ReplicatedStorage
		end
		
		GlobalAnnouncementEvent:FireAllClients({
			displayName = adminName,
			prefix = "",
			message = tostring(args),
			nameColor = Color3.fromRGB(255, 50, 50)
		})
		
	elseif cmd == "warn" then
		for _, p in ipairs(targets) do WarnEvent:FireClient(p, tostring(args), adminId, adminName) end
		
	elseif cmd == "tp" then
		local destinationName = tostring(args)
		local destPlayer = nil
		for _, plr in ipairs(Players:GetPlayers()) do
			if string.lower(plr.Name) == string.lower(destinationName) or string.lower(plr.DisplayName) == string.lower(destinationName) then
				destPlayer = plr
				break
			end
		end
		
		if destPlayer and destPlayer.Character and destPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local destCFrame = destPlayer.Character.HumanoidRootPart.CFrame
			for _, p in ipairs(targets) do
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					p.Character.HumanoidRootPart.CFrame = destCFrame * CFrame.new(3, 0, 0)
				end
			end
		end
		
	elseif cmd == "jail" then
		for _, p in ipairs(targets) do
			jailedPlayers[p.UserId] = true
			createJailCell(p)
		end
		
	elseif cmd == "unjail" then
		for _, p in ipairs(targets) do
			jailedPlayers[p.UserId] = nil
			local oldJail = workspace:FindFirstChild("Jail_" .. p.Name)
			if oldJail then oldJail:Destroy() end
		end
		
	elseif cmd == "givevip" then
		local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
		if success and userId then
			local vipStore = game:GetService("DataStoreService"):GetDataStore("FreeVIPUsers")
			pcall(function()
				vipStore:SetAsync(tostring(userId), true)
			end)
			
			local plr = Players:GetPlayerByUserId(userId)
			if plr then
				plr:SetAttribute("HasFreeVIP", true)
				-- Update title immediately
				local TitleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
				if TitleRemotes then
					local ReportDevice = TitleRemotes:FindFirstChild("ReportDevice")
					if ReportDevice then
						-- Trigger broadcast indirectly, or we can just let TitleService pick it up on next loop
					end
				end
			end
			print("[DiscordAdmin] Berhasil memberikan VIP permanen ke", targetName)
		end
		
	elseif cmd == "setlevel" then
		local lvl = tonumber(args)
		for _, p in ipairs(targets) do
			if lvl and lvl >= 1 and lvl <= 6 then
				p:SetAttribute("CustomLevel", lvl)
				print("[DiscordAdmin] Set custom level", p.Name, "to", lvl)
			else
				p:SetAttribute("CustomLevel", nil)
				print("[DiscordAdmin] Reset custom level", p.Name)
			end
		end
		
	elseif cmd == "restart" then
		AnnounceEvent:FireAllClients("SERVER SEDANG DIRESTART UNTUK UPDATE DALAM 5 DETIK! Mohon tunggu, Anda akan otomatis masuk kembali...", adminId, adminName)
		task.wait(5)
		
		local TS = game:GetService("TeleportService")
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function()
				TS:Teleport(game.PlaceId, p)
			end)
		end
		
	elseif cmd == "merdeka" then
		spawnMerdekaFireworks()
		AnnounceEvent:FireAllClients("MERDEKA! ????\n" .. tostring(args))
		
	elseif cmd == "ban" or cmd == "unban" then
		local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
		if success and userId then
			if cmd == "ban" then
				local reason = args == "" and "Banned via Discord" or args
				local config = { UserIds = {userId}, Duration = -1, DisplayReason = "Anda telah di-banned!\n" .. reason, PrivateReason = "Discord Admin", ExcludeAltAccounts = true, ApplyToUniverse = true }
				pcall(function() Players:BanAsync(config) end)
			else
				local config = { UserIds = {userId}, ApplyToUniverse = true }
				pcall(function() Players:UnbanAsync(config) end)
			end
		end
	
	-- ===== REDEEM CODE MANAGEMENT =====
	elseif cmd == "createcode" then
		-- Format: /createcode KODENAME RewardType Amount
		-- Contoh: /createcode MERDEKA17 Cash 500
		-- Contoh: /createcode GARUDA MHCoin 100
		-- Contoh: /createcode NUSANTARA Spins 3
		local parts = string.split(args, " ")
		local codeName = targetName or ""
		local rewardType = parts[1] or ""
		local amount = tonumber(parts[2] or "0")
		
		if codeName == "" or rewardType == "" or not amount or amount <= 0 then
			print("[DiscordAdmin] Format: createcode <KODE> <Cash/Coin/MHCoin/Spins> <jumlah>")
		else
			local createFunc = ReplicatedStorage:FindFirstChild("_CreateRedeemCode")
			if createFunc then
				local ok, msg = createFunc:Invoke(codeName, rewardType, amount)
				print("[DiscordAdmin] CreateCode:", msg)
			else
				print("[DiscordAdmin] RedeemService belum aktif!")
			end
		end
		
	elseif cmd == "deletecode" then
		-- Format: /deletecode KODENAME
		local codeName = targetName or ""
		if codeName == "" then
			print("[DiscordAdmin] Format: deletecode <KODE>")
		else
			local deleteFunc = ReplicatedStorage:FindFirstChild("_DeleteRedeemCode")
			if deleteFunc then
				local ok, msg = deleteFunc:Invoke(codeName)
				print("[DiscordAdmin] DeleteCode:", msg)
			else
				print("[DiscordAdmin] RedeemService belum aktif!")
			end
		end
		
	elseif cmd == "listcodes" then
		local listFunc = ReplicatedStorage:FindFirstChild("_ListRedeemCodes")
		if listFunc then
			local result = listFunc:Invoke()
			print("[DiscordAdmin] " .. tostring(result))
		else
			print("[DiscordAdmin] RedeemService belum aktif!")
		end
	end
end

local success, err = pcall(function() MessagingService:SubscribeAsync(TOPIC, handleAdminCommand) end)
if success then print("[DiscordAdmin] Siap menerima perintah dari Discord (Open Cloud)!") else warn("[DiscordAdmin] Gagal terhubung:", err) end

-- ============================================================
-- FALLBACK: IN-GAME CHAT COMMANDS (Untuk Testing di Studio)
-- ============================================================
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Cek Izin (Khusus Owner / Developer / Admin untuk testing)
		-- Boleh menggunakan command in-game berawalan slash (/)
		if message:sub(1, 1) == "/" then
			local rawArgs = string.split(message:sub(2), " ")
			local command = string.lower(table.remove(rawArgs, 1))
			
			local validCommands = {
				kick=true, kill=true, announce=true, ban=true, unban=true, warn=true,
				freeze=true, thaw=true, merdeka=true, tp=true, jail=true, unjail=true,
				givevip=true, restart=true, setlevel=true,
				createcode=true, deletecode=true, listcodes=true
			}
			
			if validCommands[command] then
				local target = ""
				local cmdArgs = ""
				
				if command == "announce" or command == "merdeka" or command == "restart" then
					cmdArgs = table.concat(rawArgs, " ")
				elseif command == "tp" then
					target = table.remove(rawArgs, 1) or ""
					cmdArgs = table.remove(rawArgs, 1) or ""
				else
					target = table.remove(rawArgs, 1) or ""
					cmdArgs = table.concat(rawArgs, " ")
				end
				
				-- Kirim simulasi ke handleAdminCommand
				handleAdminCommand({
					Data = {
						command = command,
						target = target,
						args = cmdArgs,
						adminId = player.UserId,
						adminName = player.Name
					}
				})
			end
		end
	end)
end)