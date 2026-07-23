local plrs = game:GetService("Players")
local TS = game:GetService("TeleportService")
local MS = game:GetService("MessagingService")
local CS = game:GetService("Chat")
local LS = game:GetService("LocalizationService")

local rs = game:GetService("ReplicatedStorage")

local https = game:GetService("HttpService")

local module = {}

local ServerList = {} -- this table is for all servers
local PlayerList = {} -- this table is for all players

local ServerStartTime = os.time()
module.ServerStartTime = ServerStartTime
module.DataTransferRemote = rs.DataTransfer

local function UpdateAllClients(ServerList)
	module.DataTransferRemote:FireAllClients(ServerList)
end

local function cleanupDeadServers()
	for jobId, serverData in pairs(ServerList) do
		if #serverData["plrs"] == 0 then
			ServerList[jobId] = nil
			print("Removed dead server:", jobId)
		end
	end
	UpdateAllClients(ServerList) -- Update clients after cleanup
end

task.spawn(function()
	while task.wait(30) do -- Runs every 30 seconds
		cleanupDeadServers()
	end
end)

local function ArrayToString(original) -- рекурсиввная функция работает, если все остальные типы кроме table могут быть конвертированны в str через tostring()
	local copy = "{"
	local ind = 1
	local max = 0
	for k,v in pairs(original) do
		max += 1
	end

	for k, v in pairs(original) do
		local str = ""
		if type(v) == "table" then
			str = ArrayToString(v)
		else
			str = tostring(v)
		end
		if ind < max then
			copy = copy..k.." = "..str..", "
		else
			copy = copy..k.." = "..str
		end
		ind+=1
	end
	copy = copy.."}"
	return copy
end




local function Send(message,sender,topic)
	local messageData = {}
	messageData["sender"] = sender -- placeId
	messageData["message"] = message -- message

	local encoded = https:JSONEncode(messageData)
	MS:PublishAsync(topic, encoded)
end

local RegionName = nil

for i,plr in ipairs(plrs:GetPlayers()) do
	Send({UserId = plr.UserId,Type = "Added",ServerStartTime = ServerStartTime, RegionName = RegionName,},game.JobId,"SList")
	table.insert(PlayerList,plr.UserId)
	module.DataTransferRemote:FireClient(plr,ServerList)
end

local function getFlag(player)
	local code = LS:GetCountryRegionForPlayerAsync(player)
	local first = string.byte(string.upper(string.sub(code, 1, 1))) - 0x41 + 0x1F1E6
	local second = string.byte(string.upper(string.sub(code, 2, 2))) - 0x41 + 0x1F1E6
	return utf8.char(first) .. utf8.char(second)
end

plrs.PlayerAdded:Connect(function(plr)
	if RegionName == nil then
		RegionName = LS:GetCountryRegionForPlayerAsync(plr) .. " " .. getFlag(plr)
	end
	Send({UserId = plr.UserId, Type = "Added", ServerStartTime = ServerStartTime, RegionName = RegionName}, game.JobId, "SList")
	table.insert(PlayerList, plr.UserId)
	module.DataTransferRemote:FireClient(plr, ServerList)
end)

plrs.PlayerRemoving:Connect(function(plr)
	Send({UserId = plr.UserId,Type = "Removed"},game.JobId,"SList")
	for i,v in ipairs(PlayerList) do -- goes through players in local server list
		if v == plr.UserId then
			table.remove(PlayerList,i) -- removes player from local server list
			break
		end
	end
end)



function module.Init()
	repeat
		task.wait(0.1)
	until RegionName
	module.RegionName = RegionName
	
	local function callback(serviceData)
		local decodedData = https:JSONDecode(serviceData.Data)
		if decodedData then
			local sender = decodedData.sender
			local message = decodedData.message
			if sender ~= game.JobId  then -- checks if this message wasn't sent from this server

				print("Callback: ")
				print("Decoded Data: ",ArrayToString(decodedData))
				if ServerList[sender] == nil then
					ServerList[sender] = {["data"] = {},["plrs"] = {}}
				end

				if message.Type == "RequestInfo" then

					ServerList[sender]["data"]["RegionName"] = message.RegionName
					ServerList[sender]["data"]["ServerStartTime"] = message.ServerStartTime

					Send({List = PlayerList,Type = "SendInfo",RegionName = RegionName,ServerStartTime = ServerStartTime},game.JobId,sender)
				end

				if message.Type == "Added" then
					ServerList[sender]["data"]["RegionName"] = message.RegionName
					ServerList[sender]["data"]["ServerStartTime"] = message.ServerStartTime
					table.insert(ServerList[sender]["plrs"],message.UserId)
				end

				if message.Type == "ShuttingDown" then
					ServerList[sender] = nil
				end

				if message.Type == "Removed" then
					for i,v in ipairs(ServerList[sender]["plrs"]) do -- goes through players in local server list
						if v == message.UserId then
							table.remove(ServerList[sender]["plrs"],i) -- removes player from local server list
							break
						end
					end
				end
				print("Current Array: ",ArrayToString(ServerList))
				UpdateAllClients(ServerList)
				print("")
			end
		end
	end

	local function private_callback(serviceData)
		local decodedData = https:JSONDecode(serviceData.Data)
		if decodedData then

			local sender = decodedData.sender
			local message = decodedData.message
			if sender ~= game.JobId  then -- checks if this message wasn't sent from this server
				print("Callback! Data: ")
				print(ArrayToString(serviceData))
				if ServerList[sender] == nil then -- if in this server list there was no such server then it will add one
					ServerList[sender] = {["data"] = {},["plrs"] = {}}
				end

				if message.Type == "SendInfo" then
					ServerList[sender]["plrs"] = message.List
					ServerList[sender]["data"]["RegionName"] = message.RegionName
					ServerList[sender]["data"]["ServerStartTime"] = message.ServerStartTime
				end
				UpdateAllClients(ServerList)
			end
		end
	end
	if game.JobId ~= "" then
		MS:SubscribeAsync("SList", callback)
		MS:SubscribeAsync(game.JobId, private_callback)
		coroutine.wrap(function()
			task.wait(5)
			Send({Type = "RequestInfo",RegionName = RegionName,ServerStartTime = ServerStartTime},game.JobId,"SList")
		end)()
		coroutine.wrap(function()
			while task.wait(60) do
				ServerList = {}
				Send({Type = "RequestInfo",RegionName = RegionName,ServerStartTime = ServerStartTime},game.JobId,"SList")
			end
		end)()
	end
end



local function FindPlayer(Name)
	for job_id, plrList in pairs(ServerList) do
		for _,plr in ipairs(plrList) do
			if plr.Name == Name then
				return job_id
			end
		end
	end
end

function module.TeleportToPlayer(plr,plrName)
	local job_id = FindPlayer(plrName)
	if job_id then
		TS:TeleportToPlaceInstance(game.PlaceId,job_id,plr)
	else
		print("There is no such player")
	end
end

function module.PrintServerList()
	print(ArrayToString(ServerList))
end
game:BindToClose(function()
	Send({Type = "ShuttingDown"},game.JobId,"SList")
end)
return module
--[[

██╗  ██╗  ██████╗  ███████╗
╚██╗██╔╝ ██╔════╝  ██╔════╝
 ╚███╔╝  ██║       ███████╗
 ██╔██╗  ██║       ╚════██║
██╔╝ ██╗ ╚██████╗  ███████║
╚═╝  ╚═╝  ╚═════╝  ╚══════╝

███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗ ███████╗
██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗██╔════╝
███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║███████╗
╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║╚════██║
███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝███████║
╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ ╚══════╝

]]