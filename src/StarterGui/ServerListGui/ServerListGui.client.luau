local main = script.Parent.main

local ListFrame = main:WaitForChild("ListFrame")
local uiListLayout = ListFrame:WaitForChild("UIListLayout")
local Sample = uiListLayout:WaitForChild("Sample")
local CurrentServer = uiListLayout:WaitForChild("CurrentServer")
local ChangeOrderBtn = main:WaitForChild("ChangeOrderBtn")
local OrderText = ChangeOrderBtn:FindFirstChild("OrderLabel")
local JoinVCButton = main:WaitForChild("VCServer") -- Adjust according to your GUI structure
local rs = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local rem = rs.DataTransfer
local TPRem = rs.Teleport
local CurrentData = rs:WaitForChild("CurrentData", math.huge)
local Connections = {} -- I need to avoid memory leak or else...
local Threads = {}
local Max_plrs = game.Players.MaxPlayers
local LocalSList = {}
local LocalPlayerList = {}
local OrderMode = "Ascension"
local teleportService = game:GetService("TeleportService")
local voiceChatService = game:GetService("VoiceChatService")

local originalServerPlaceId = 8848607186
local vcOnlyServerPlaceId = 17445806826

-- Text update time for when the user is not allowed
local messageDisplayTime = 3

-- Function to switch text temporarily
local function changeButtonText(button, newText, revertText)
	button.Text = newText
	task.delay(messageDisplayTime, function()
		button.Text = revertText
	end)
end

local function updateJoinButton()
	if game.PlaceId == vcOnlyServerPlaceId then
		JoinVCButton.label.Text = "Join Non-VC Servers"
	else
		JoinVCButton.label.Text = "Join 🎙️VC Only Server"
	end
end

local function isUserEligibleForVoiceChat()
	return voiceChatService:IsVoiceEnabledForUserIdAsync(game.Players.LocalPlayer.UserId)
end

local function joinVCOnlyServer()
	if game.PlaceId == vcOnlyServerPlaceId then
		-- Go to the original server
		teleportService:Teleport(originalServerPlaceId, game.Players.LocalPlayer)
	else
		-- Check if the player has voice chat eligibility
		if isUserEligibleForVoiceChat() then
			teleportService:Teleport(vcOnlyServerPlaceId, game.Players.LocalPlayer)
		else
			changeButtonText(JoinVCButton.label, "It seems like you don't have a VC access", "Join 🎙️ VC Only Server")
		end
	end
end

JoinVCButton.MouseButton1Click:Connect(joinVCOnlyServer)

for i, plr in ipairs(plrs:GetPlayers()) do
	table.insert(LocalPlayerList, plr.UserId)
end

plrs.PlayerAdded:Connect(function(plr)
	table.insert(LocalPlayerList, plr.UserId)
end)

plrs.PlayerRemoving:Connect(function(plr)
	for i, v in ipairs(LocalPlayerList) do
		if v == plr.UserId then
			table.remove(LocalPlayerList, i)
			break
		end
	end
end)

local function ArrayToString(original)
	local copy = "{"
	local ind = 1
	local max = 0
	for k, v in pairs(original) do
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
		ind += 1
	end
	copy = copy.."}"
	return copy
end

function Format(Int)
	return string.format("%02i", Int)
end

function convertToHMS(Seconds)
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds = Seconds - Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes = Minutes - Hours * 60
	return Format(Hours)..":"..Format(Minutes)..":"..Format(Seconds)
end

local function Update()
	for i, v in ipairs(Connections) do
		v:Disconnect()
	end
	for i, v in ipairs(ListFrame:GetChildren()) do
		if v.ClassName == "Frame" then
			v:Destroy()
		end
	end

	do
		local ServerFrame = CurrentServer:Clone()
		ServerFrame.Parent = ListFrame

		local Data = CurrentData
		if typeof(Data) ~= "table" then
			Data = {["RegionName"] = "Getting data...", ["ServerStartTime"] = os.time()}
		end
		ServerFrame.Region.Text = "Region: "..tostring(Data["RegionName"])
		ServerFrame.Time.Text = "Up Time: "..convertToHMS(os.time() - Data["ServerStartTime"])
		ServerFrame.Players.Text = "Players: "..#LocalPlayerList.."/"..tostring(Max_plrs)
	end

	local count = 0
	for i, v in ipairs(LocalSList) do
		local data = v
		local ServerStartTime = data["ServerStartTime"]
		local RegionName = data["RegionName"]
		if ServerStartTime and RegionName then
			local ServerFrame = Sample:Clone()
			ServerFrame.Parent = ListFrame
			ServerFrame.Region.Text = "Region: " .. tostring(RegionName)
			ServerFrame.Time.Text = "Up Time: "..convertToHMS(os.time() - ServerStartTime)
			ServerFrame.Players.Text = "Players: "..#v["plrs"].."/"..tostring(Max_plrs)

			local Connection = ServerFrame.JoinBtn.MouseButton1Down:Connect(function()
				TPRem:FireServer(v["job_id"], "ToServer")
			end)
			table.insert(Connections, Connection)
			count += 1
		end
	end
end

ChangeOrderBtn.MouseButton1Down:Connect(function()
	if OrderMode == "Ascension" then
		OrderMode = "Descension"
		OrderText.Text = "Sort Order: Highest to lowest"
		table.sort(LocalSList, function(Value1, Value2)
			return #Value1["plrs"] > #Value2["plrs"]
		end)
	else
		OrderMode = "Ascension"
		OrderText.Text = "Sort Order: Lowest to highest"
		table.sort(LocalSList, function(Value1, Value2)
			return #Value1["plrs"] < #Value2["plrs"]
		end)
	end
	Update()
end)

rem.OnClientEvent:Connect(function(ServerList)
	LocalSList = {}
	for job_id, t in pairs(ServerList) do
		local temp = table.clone(t["data"])
		temp["plrs"] = t["plrs"]
		temp["job_id"] = job_id
		table.insert(LocalSList, temp)
	end

	if OrderMode == "Ascension" then
		table.sort(LocalSList, function(Value1, Value2)
			return #Value1["plrs"] < #Value2["plrs"]
		end)
	elseif OrderMode == "Descension" then
		table.sort(LocalSList, function(Value1, Value2)
			return #Value1["plrs"] > #Value2["plrs"]
		end)
	end

	Update()
end)

coroutine.wrap(function()
	while (task.wait(1)) do
		Update()
	end
end)()

task.wait(3)
CurrentData = CurrentData:InvokeServer()
updateJoinButton()
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
