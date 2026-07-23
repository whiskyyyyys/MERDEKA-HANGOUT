local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local storage = RepStorage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local server = script.Parent.Parent

local Auth = require(server.Auth)
local IdSaving = require(server.Systems.IdSaving)
local VariableEncoding = require(server.Systems.VariableEncoding)
local SafeTeleport = require(server.Systems.SafeTeleport)
local ChatLogging = require(server.Systems.ChatLogging)

local Utilities = require(storage.modules.Utilities)
local Configuration = Auth.GetConfigurations()
local Alerts = require(storage.modules.Alerts)

local Server = script.Parent.Parent

local module = {}

local function customConcat(list, sep)
	if (#list == 0) then
		return ""
	end
	local buildStr = ""
	for _, element in ipairs(list) do
		buildStr = buildStr..sep..tostring(element)
	end
	return string.sub(buildStr, #sep + 1)
end

local function GetAvatar(UserId:number) : (boolean,string)
	local Url = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds="..UserId.."&size=180x180&format=Png&isCircular=false"
	local Response = HttpService:RequestAsync({
		Url = Url,
		Method = "GET",
		Headers = {},
		Body = nil
	})
	if Response.Success then
		local Data = HttpService:JSONDecode(Response.Body)
		return true, Data["data"][1]["imageUrl"]
	else
		return false, Response.Body
	end
end

function module:AuditOnWebhook(header, description, color, mod: Player, involved, osTime)
	if not RunService:IsServer() then warn("Webhook Audits only works on server.") return; end
	if not mod then return end

	if Configuration.Auditing.WebhookLink == "" then return end
	
	local Success, Data = GetAvatar(mod.UserId)
	local thumbnail
	
	local EpochData = Utilities.FormatEpochData(osTime)
	local involvedNames = {}
	
	for _, i in pairs(involved) do
		table.insert(involvedNames, Players:GetNameFromUserIdAsync(i))
	end
	
	if Success then
		thumbnail = Data
	else
		thumbnail = 0
	end
	
	local Message = {
		["username"] = "Exe 6",
		["avatar_url"] = "https://i.ibb.co/ksdSWV6K/Exe-6-Square.png",
		
		["content"] = "-# " .. game.Name,
		["embeds"] = {{
			
			["title"] = header or "No title provided.",
			["description"] = description or "No description provided.",
			
			["type"] = "rich",
			["color"] = tonumber(color or 0xffffff),
			
			["image"] = {
				["url"] = "https://i.ibb.co/j9XKvx8Z/exe6webhookauditfooter.png",
			},
			
			["thumbnail"] = {
				["url"] = thumbnail,
			},
			
			["fields"] = {
				{
					["name"] = "Players",
					["value"] = "`"..("@"..customConcat(involvedNames, ", @")).."`",
					["inline"] = true
				},
				
				{
					["name"] = "Date",
					["value"] = EpochData.Calender.Month.Long.." "..EpochData.Calender.Day..", "..EpochData.Calender.Year.Long.." "..EpochData.Time.Hour..":"..EpochData.Time.Minutes.." "..EpochData.Time.Period,
					["inline"] = false
				},
			}
			
		}}
	}
	
	local HookData = HttpService:JSONEncode(Message)
	
	HttpService:PostAsync(Configuration.Auditing.WebhookLink, HookData)
end

return module