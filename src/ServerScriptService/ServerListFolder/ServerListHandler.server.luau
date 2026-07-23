local module = require(game:GetService("ServerScriptService").ServerListFolder:FindFirstChild("ServerList"))
local rs = game:GetService("ReplicatedStorage")
local rem = rs.Teleport
local DataBind = rs.CurrentData
local TS = game:GetService("TeleportService")

local chat = game:GetService("Chat")


rem.OnServerEvent:Connect(function(plr,arg1,Type)
	if arg1 and Type then
		if Type == "ToPlayer"then
			-- arg1 will be target player name
			if type(arg1) == "string" then
				module.TeleportToPlayer(plr,arg1)
			end
		elseif Type == "ToServer" then
			-- arg1 will be jobid
			TS:TeleportToPlaceInstance(game.PlaceId,arg1,plr)
		end
	end
end)

DataBind.OnServerInvoke = function()
	repeat task.wait(0.1) until module["RegionName"]
	print(module["RegionName"])
	return {ServerStartTime = module.ServerStartTime, RegionName = module["RegionName"]}
end
module.Init()


