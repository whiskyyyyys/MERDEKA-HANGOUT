local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserService = game:GetService("UserService")
local HapticService = game:GetService("HapticService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local slow = TweenInfo.new(.8, Enum.EasingStyle.Exponential)

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events

local modules = script.Parent

local module = {}

-- Time

local monthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
local monthShort = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

local function GetRelatives(epoch)
	local now = os.time()
	local diff = now - epoch

	local minutes = math.floor(math.abs(diff) / 60)
	local hours = math.floor(minutes / 60)
	local days = math.floor(hours / 24)
	local weeks = math.floor(days / 7)
	local months = math.floor(days / 30)
	local years = math.floor(days / 365)

	if diff == 0 then return "Now" end
	if diff > 0 then -- Past
		if years >= 1 then return years == 1 and "A year ago" or years .. " years ago" end
		if months >= 1 then return months == 1 and "A month ago" or months .. " months ago" end
		if weeks >= 1 then return weeks == 1 and "A week ago" or weeks .. " weeks ago" end
		if days == 1 then return "Yesterday" end
		if days > 1 then return days .. " days ago" end
		if hours >= 1 then return hours == 1 and "An hour ago" or hours .. " hours ago" end
		if minutes >= 1 then return minutes == 1 and "A minute ago" or minutes .. " minutes ago" end
		return "A moment ago"
	else -- Future
		diff = -diff
		if years >= 1 then return years == 1 and "Next year" or "In " .. years .. " years" end
		if months >= 1 then return months == 1 and "Next month" or "In " .. months .. " months" end
		if weeks >= 1 then return weeks == 1 and "Next week" or "In " .. weeks .. " weeks" end
		if days == 1 then return "Tomorrow" end
		if days > 1 then return "In " .. days .. " days" end
		if hours >= 1 then return hours == 1 and "In an hour" or "In " .. hours .. " hours" end
		if minutes >= 1 then return minutes == 1 and "In a minute" or "In " .. minutes .. " minutes" end
		return "Soon"
	end
end

function module.FormatEpochData(epoch)
	local timeTable = os.date("*t", epoch)
	local hour = timeTable.hour % 12
	local period = timeTable.hour < 12 and "AM" or "PM"

	if hour == 0 then hour = 12 end

	return {
		Time = {
			Hour = hour,
			Minutes = string.format("%02d", timeTable.min),
			Seconds = string.format("%02d", timeTable.sec),
			Period = period
		},

		Calender = {
			Month = {
				Short = monthShort[timeTable.month],
				Long = monthNames[timeTable.month],
				Numerical = timeTable.month
			},
			Day = timeTable.day,
			Year = {
				Short = timeTable.year % 100,
				Long = timeTable.year
			}
		},

		Relative = GetRelatives(epoch),

		Epoch = epoch
	}
end

function IsLeapYear(year)
	return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

function GetMonthDays(year)
	return {
		31, -- Jan
		IsLeapYear(year) and 29 or 28, -- Feb
		31, -- Mar
		30, -- Apr
		31, -- May
		30, -- Jun
		31, -- Jul
		31, -- Aug
		30, -- Sep
		31, -- Oct
		30, -- Nov
		31  -- Dec
	}
end

function GetYearDays(year)
	return IsLeapYear(year) and 366 or 365
end

function module.GetEpochStats(epoch, unit, within)
	local data = os.date("*t", epoch)
	local year, month, day = data.year, data.month, data.day
	local hour, min, sec = data.hour, data.min, data.sec
	local monthDays = GetMonthDays(year)
	local daysInMonth = monthDays[month]
	local daysInYear = GetYearDays(year)

	unit = unit:lower()
	within = within:lower()

	if within == "minute" then
		if unit == "seconds" then return sec end

	elseif within == "hour" then
		if unit == "minutes" then return min end
		if unit == "seconds" then return min * 60 + sec end

	elseif within == "day" then
		if unit == "hours" then return hour end
		if unit == "minutes" then return hour * 60 + min end
		if unit == "seconds" then return hour * 3600 + min * 60 + sec end

	elseif within == "week" then
		if unit == "days" then return data.wday - 1 end

	elseif within == "month" then
		if unit == "days" then return day end
		if unit == "hours" then return ((day - 1) * 24) + hour end
		if unit == "minutes" then return ((day - 1) * 24 * 60) + (hour * 60) + min end
		if unit == "seconds" then return ((day - 1) * 86400) + (hour * 3600) + (min * 60) + sec end

	elseif within == "year" then
		local dayOfYear = 0
		for m = 1, month - 1 do
			dayOfYear += monthDays[m]
		end
		dayOfYear += day

		if unit == "days" then return dayOfYear end
		if unit == "months" then return month end
		if unit == "hours" then return (dayOfYear - 1) * 24 + hour end
		if unit == "minutes" then return ((dayOfYear - 1) * 24 * 60) + (hour * 60) + min end
		if unit == "seconds" then return ((dayOfYear - 1) * 86400) + (hour * 3600) + (min * 60) + sec end
	end

	return nil
end

function module.FormatISO(ISO)
	local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%.*(%d*)Z"
	local year, month, day, hour, min, sec, frac = ISO:match(pattern)

	if not (year and month and day and hour and min and sec) then
		error("Invalid ISO 8601 format")
	end

	local utcTime = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec)
	})

	local localTime = os.date("*t", utcTime)
	local formattedTime = os.date("%B %d, %Y %I:%M:%S %p", utcTime)

	return formattedTime
end

function module.GetISO8601()
	local utcTime = os.time()
	local formattedTime = os.date("!%Y-%m-%dT%H:%M:%SZ", utcTime)

	return formattedTime
end

function module.FormatSecondsToHM(seconds, IncludeSeconds)
	local minThreshold = IncludeSeconds and 0 or 60
	if not seconds or typeof(seconds) ~= "number" or seconds < minThreshold then
		return nil
	end

	local s = math.floor(seconds % 60)
	local m = math.floor(seconds / 60) % 60
	local h = math.floor(seconds / 3600)

	if IncludeSeconds then
		if h > 0 then
			return string.format("%dh %dm %ds", h, m, s)
		elseif m > 0 then
			return string.format("%dm %ds", m, s)
		else
			return string.format("%ds", s)
		end
	else
		if h > 0 then
			return string.format("%dh %dm", h, m)
		else
			return string.format("%dm", m)
		end
	end
end

function module.FormatSecondsToYM(days)
	if not days or typeof(days) ~= "number" or days < 30 then
		return nil
	end

	local months = math.floor(days / 30)
	local years = math.floor(months / 12)
	months = months % 12

	if years > 0 then
		if months > 0 then
			return string.format("%dy %dmos", years, months)
		else
			return string.format("%dy", years)
		end
	else
		return string.format("%dmos", months)
	end
end

function module.FormatTime(seconds)
	assert(typeof(seconds) == "number" and seconds >= 0, "seconds must be a non-negative number.")

	local days = math.floor(seconds / 86400)
	seconds = seconds % 86400
	local hours = math.floor(seconds / 3600)
	seconds = seconds % 3600
	local minutes = math.floor(seconds / 60)
	seconds = seconds % 60

	local function PadWithZero(value)
		return string.format("%02d", value)
	end

	return {
		Days = days,
		Hours = hours,
		Minutes = minutes,
		Seconds = PadWithZero(seconds)
	}
end

function module.FormatTimeStringToSeconds(timeString)
	local total = 0

	local patterns = {
		{ unit = "[wW]", multiplier = 7 * 24 * 60 * 60 },
		{ unit = "[dD]", multiplier = 24 * 60 * 60 },
		{ unit = "[hH]", multiplier = 60 * 60 },
		{ unit = "[mM]", multiplier = 60 },
	}

	for _, pattern in ipairs(patterns) do
		local value = timeString:match("(%d+)%s*" .. pattern.unit)
		if value then
			total = total + tonumber(value) * pattern.multiplier
		end
	end

	return math.clamp(total, 60, 999999999)
end

function module.FormatSecondsToRealDate(seconds)
	local now = os.time()
	local targetTime = now + seconds
	local targetDate = os.date("*t", targetTime)
	local daysDifference = os.difftime(targetTime, now) // (24 * 60 * 60)
	local formattedTime = os.date("%I:%M%p", targetTime):gsub("^0", "")

	if daysDifference == 0 then
		return string.format("Today, %s", formattedTime)
	elseif daysDifference == 1 then
		return string.format("Tomorrow, %s", formattedTime)
	else
		return string.format("%d/%d/%d, %s", targetDate.month, targetDate.day, targetDate.year % 100, formattedTime)
	end
end

function module.FormatSecondsToYWDHM(seconds)
	local timeUnits = {
		{name = "y", seconds = 31536000},
		{name = "w", seconds = 604800},
		{name = "d", seconds = 86400},
		{name = "h", seconds = 3600},
		{name = "m", seconds = 60},
	}

	local result = {}

	for _, unit in ipairs(timeUnits) do
		if #result < 3 and seconds >= unit.seconds then
			local value = math.floor(seconds / unit.seconds)
			seconds = seconds % unit.seconds
			table.insert(result, value .. unit.name)
		end
	end

	return #result > 0 and table.concat(result, " ") or nil
end

function module.FormateSecondsToWord(seconds)
	assert(typeof(seconds) == "number" and seconds >= 0, "Seconds must be a non-negative number.")

	local units = {
		{name = "year", seconds = 31536000},
		{name = "month", seconds = 2592000},
		{name = "week", seconds = 604800},
		{name = "day", seconds = 86400},
		{name = "hour", seconds = 3600},
		{name = "minute", seconds = 60},
		{name = "second", seconds = 1},
	}

	for _, unit in ipairs(units) do
		local value = math.floor(seconds / unit.seconds)

		if value >= 1 then
			return string.format("%d %s%s", value, unit.name, value > 1 and "s" or "")
		end
	end

	return "0 seconds"
end

function module.FormatSecondsToMSS(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60

	return string.format("%d:%02d", minutes, secs)
end

function module.ISOToEpoch(isoString)
	local success, result = pcall(function()
		return DateTime.fromIsoDate(isoString)
	end)

	if success and result then
		return result.UnixTimestamp
	else
		return
	end
end

-- Interface / Numbers

function module.SwitchToggle(Switch, State)
	if State then
		TweenService:Create(Switch, info, {ImageColor3 = Color3.fromRGB(0, 185, 62)}):Play()
		TweenService:Create(Switch.Knob, info, {Position = UDim2.fromScale(1, .5),
			ImageColor3 = Color3.fromRGB(0, 85, 28)}):Play()
	else
		TweenService:Create(Switch, info, {ImageColor3 = Color3.fromRGB(34, 34, 34)}):Play()
		TweenService:Create(Switch.Knob, info, {Position = UDim2.fromScale(0, .5),
			ImageColor3 = Color3.fromRGB(12, 12, 12)}):Play()
	end
end

function module.GetInitials(Text)
	if not Text or Text == "" then return "" end

	local initials = ""

	initials ..= string.sub(Text, 1, 1)

	for i = 2, #Text do
		local char = string.sub(Text, i, i)
		local prevChar = string.sub(Text, i - 1, i - 1)
		local isNumber = string.match(char, "%d")
		local isAfterSpace = (prevChar == " ") and string.match(char, "%S")
		local isCamelCase = string.match(char, "%u") and string.match(prevChar, "%l")

		if isNumber or isAfterSpace or isCamelCase then
			initials ..= char
		end

		if #initials >= 4 then break end
	end

	return string.sub(initials, 1, 4)
end

function module.GetRelativePixels(DesiredVector2, ParentVector2)
	return DesiredVector2 - ParentVector2
end

function module.Map(Value, ValueMin, ValueMax, PostMin, PostMax)
	return PostMin + (Value - ValueMin) * (PostMax - PostMin) / (ValueMax - ValueMin)
end

function module.RandomOffRange(MinValue, OffMin, OffMax, MaxValue)
	if math.random() < .5 then
		return math.random() * (OffMin - MinValue) + MinValue
	else
		return math.random() * (MaxValue - OffMax) + OffMax
	end
end

function module.GetCoverForSong(SongId)
	return module.AssetToTexture(SongId)
end

function module.AssetToTexture(assetid)
	return "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=" .. assetid
end

function module.FilterString(Text, Id, WidelyVisible)
	if RunService:IsServer() then
		local result
		local success, err = pcall(function()
			result = TextService:FilterStringAsync(Text, Id)
		end)

		if success then
			if WidelyVisible then
				return result:GetNonChatStringForBroadcastAsync()
			else
				return result:GetNonChatStringForUserAsync()
			end
			
		else
			local hash = {}

			for i = 1, string.len(Text) do
				table.insert(hash, "#")
			end

			return table.concat(hash, "")
		end
		
	elseif RunService:IsClient() then
		return events.UI.FilterString:InvokeServer(Text, Id, WidelyVisible)
	end
end

function module.SendTextboxForFiltering(textbox, id, WidelyVisible)
	task.spawn(function()
		textbox.Interactable = false
		textbox.Text = module.FilterString(textbox.Text, id, WidelyVisible)
		textbox.Interactable = true
	end)
end

function module.CapitalizeWords(text)
	return (text:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

function module.ResetScrollPosition(ui:GuiObject)
	for i, scroll in pairs(ui:GetDescendants()) do
		if scroll:IsA("ScrollingFrame") then
			scroll.CanvasPosition = Vector2.new(0, 0)
		end
	end
end

function module.GetPlayerThumbnail(id)
	return Players:GetUserThumbnailAsync(id or 1, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end

function module.AdjustColor(color)
	local r, g, b = color.R * 255, color.G * 255, color.B * 255
	local brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255
	local adjustmentFactor = brightness < .5 and .3 or -.3

	r = math.clamp(r + adjustmentFactor * 255, 0, 255)
	g = math.clamp(g + adjustmentFactor * 255, 0, 255)
	b = math.clamp(b + adjustmentFactor * 255, 0, 255)

	return Color3.fromRGB(r, g, b)
end

function module.TrimString(input, max)
	if #input > max then
		return input:sub(1, max)
	else
		return input
	end
end

function module.ShuffleString(input)
	local chars = {}

	for char in input:gmatch(".") do
		table.insert(chars, char)
	end

	for i = #chars, 2, -1 do
		local j = math.random(1, i)
		chars[i], chars[j] = chars[j], chars[i]
	end

	local shuffled = table.concat(chars)

	return shuffled
end

function module.AddBadgeToIdentifier(identifier, isVerified, Membership)
	local isPremium = Membership == Enum.MembershipType.Premium

	if isVerified and isPremium then
		return identifier .. utf8.char(0xE000) .. " " .. utf8.char(0xE001)
	elseif isVerified and not isPremium then
		return identifier .. utf8.char(0xE000)
	elseif not isVerified and isPremium then
		return identifier .. utf8.char(0xE001)
	elseif not isVerified and not isPremium then
		return identifier 
	end
end

-- Tables

function module.DivideTableElements(Size, Array)
	local Result = {}
	local Current = {}

	for i, Value in ipairs(Array) do
		table.insert(Current, Value)

		if #Current == Size then
			table.insert(Result, Current)
			Current = {}
		end
	end

	if #Current > 0 then
		table.insert(Result, Current)
	end

	return Result
end

function module.ArrangeByFrequency(list)
	local frequency = {}
	local firstIndex = {}

	for i, value in ipairs(list) do
		frequency[value] = (frequency[value] or 0) + 1

		if firstIndex[value] == nil then
			firstIndex[value] = i
		end
	end

	local unique = {}
	
	for value in pairs(frequency) do
		table.insert(unique, value)
	end

	table.sort(unique, function(a, b)
		if frequency[a] ~= frequency[b] then
			return frequency[a] > frequency[b]
		end
		
		return firstIndex[a] < firstIndex[b]
	end)

	return unique
end

function module.GetTagsBySongId(Audios, SongId, Title)
	for i, Chunk in pairs(Audios) do
		for i, Song in pairs(Chunk) do
			if Song.Id == SongId then
				return Song.Tags
			end
		end
	end
	
	local AudioSearchParams = Instance.new("AudioSearchParams")
	AudioSearchParams.Title = Title
	
	
end

function module.CombineTables(t1, t2)
	local result = {}

	for i, v in ipairs(t1) do
		result[i] = v
	end

	for i, v in ipairs(t2) do
		result[i] = v
	end

	return result
end

function module.GetElementsNumber(t)
	local copy = {}

	for i, v in pairs(t) do
		table.insert(copy, v)
	end

	return #copy
end

function module.SerializeNumberTable(t)
	return table.concat(t, ",")
end

function module.DeserializeNumberTable(serialized)
	local result = {}

	for number in serialized:gmatch("[^,]+") do
		table.insert(result, tonumber(number))
	end

	return result
end

function module.ExtractTableContents(t, start, last)
	local result = {}

	for i = start, last do
		table.insert(result, t[i])
	end

	return result
end

function module.RemoveRange(tbl, StartIndex, EndIndex)
	local t = {}

	for i, e in pairs(tbl) do
		table.insert(t, e)
	end

	for i = EndIndex, StartIndex, -1 do
		table.remove(t, i)
	end

	return t
end

-- Scripts

function module.SetStatusForScriptDescendants(item, status)
	for i, s in pairs(item:GetDescendants()) do
		if s:IsA("LocalScript") and not s:HasTag("Exe6ExcludeScript") then
			s.Enabled = status
		end
	end
end

-- Misc

function module.HowSimilar(String1, String2)
	String1 = String1:lower()
	String2 = String2:lower()

	if String1 == String2 then return 100 end
	if #String1 == 0 or #String2 == 0 then return 0 end

	local len1, len2 = #String1, #String2
	local matrix = {}

	for i = 0, len1 do
		matrix[i] = {[0] = i}
	end
	for j = 0, len2 do
		matrix[0][j] = j
	end

	for i = 1, len1 do
		for j = 1, len2 do
			local cost = (string.sub(String1, i, i) == string.sub(String2, j, j)) and 0 or 1
			matrix[i][j] = math.min(
				matrix[i-1][j] + 1,
				matrix[i][j-1] + 1,
				matrix[i-1][j-1] + cost
			)
		end
	end

	local distance = matrix[len1][len2]
	local maxLength = math.max(len1, len2)
	local percentage = (1 - (distance / maxLength)) * 100

	return math.floor(percentage + .5)
end

function module.GetViewportRatio()
	local viewport = workspace.CurrentCamera.ViewportSize

	return viewport.X + viewport.Y
end

function module.GetNameByUserIdAsync(id, AddAt)
	local success, result = pcall(function()
		return Players:GetNameFromUserIdAsync(id)
	end)

	if success then
		if AddAt then
			return "@" .. result
		else
			return result
		end
	end

	return ""
end

function module.GetDisplayNameById(id)
	local success, result = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync({id})[1]
	end)

	if success then
		if result then
			return result.DisplayName
		else
			return ""
		end
	end

	return ""
end

function module.GetUserInfoByUserId(id)
	local success, result = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync({id})
	end)

	if success then
		return result[1]
	end

	return nil
end

function module.GetUserIdByNameAsync(name)
	local success, result = pcall(function()
		return Players:GetUserIdFromNameAsync(name)
	end)

	if success then
		return result
	end

	return nil
end

function module.TweenModel(model:Model, value, tweeninfo)
	if typeof(value) == "CFrame" then
		local CFrameValue = Instance.new("CFrameValue")
		CFrameValue.Value = model:GetPivot()

		CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
			model:PivotTo(CFrameValue.Value)
		end)

		local tween = TweenService:Create(CFrameValue, tweeninfo, {Value = value})

		tween:Play()

		tween.Completed:Connect(function()
			CFrameValue:Destroy()
		end)
	else

		local ScaleValue = Instance.new("NumberValue")
		ScaleValue.Value = model:GetScale()

		ScaleValue:GetPropertyChangedSignal("Value"):Connect(function()
			model:ScaleTo(ScaleValue.Value)
		end)

		local tween = TweenService:Create(ScaleValue, tweeninfo, {Value = value})

		tween:Play()

		tween.Completed:Connect(function()
			ScaleValue:Destroy()
		end)
	end
end

function module.PlayersToUserIds(PlayerTable)
	local UserIds = {}

	for i, plr in pairs(PlayerTable) do
		table.insert(UserIds, plr.UserId)
	end

	return UserIds
end


--

local charset = "!@#$%^&*()-_=+[]{}|:;<>?,./`~ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local base = #charset

local charToIndex = {}
for i = 1, base do
	charToIndex[charset:sub(i, i)] = i - 1
end

function module.Decode(encoded: string)
	assert(#encoded % 2 == 0, "Invalid encoded string length")

	local decoded = {}

	for i = 1, #encoded, 2 do
		local high = charToIndex[encoded:sub(i, i)] or 0
		local low = charToIndex[encoded:sub(i + 1, i + 1)] or 0
		local byte = (high * base) + low
		table.insert(decoded, string.char(byte))
	end

	return table.concat(decoded)
end

function module.Encode(text: string)
	local encoded = {}

	for i = 1, #text do
		local byte = string.byte(text, i)
		local high = math.floor(byte / base)
		local low = byte % base
		table.insert(encoded, charset:sub(high + 1, high + 1))
		table.insert(encoded, charset:sub(low + 1, low + 1))
	end

	return table.concat(encoded)
end

local function HSLToColor3(h, s, l)
	s /= 100
	l /= 100

	local c = (1 - math.abs(2 * l - 1)) * s
	local x = c * (1 - math.abs((h / 60) % 2 - 1))
	local m = l - c / 2

	local r, g, b = 0, 0, 0

	if h < 60 then
		r, g, b = c, x, 0
	elseif h < 120 then
		r, g, b = x, c, 0
	elseif h < 180 then
		r, g, b = 0, c, x
	elseif h < 240 then
		r, g, b = 0, x, c
	elseif h < 300 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end

	return Color3.new(r + m, g + m, b + m)
end

function module.GenerateArtistGradient(ArtistName)
	local seed = 0
	
	for i = 1, #ArtistName do
		seed += string.byte(ArtistName, i) * i
	end

	local hue = seed % 360
	local saturation = 48 + (seed % 15)
	local lightBucket = seed % 3
	local lightness

	if lightBucket == 0 then
		lightness = 32 + (seed % 6)
	elseif lightBucket == 1 then
		lightness = 40 + (seed % 6)
	else
		lightness = 48 + (seed % 7)
	end
	
	local hueShift = ((seed % 2 == 0) and 1 or -1) * (6 + seed % 9)
	local lightShift = ((seed % 3 == 0) and -1 or 1) * (5 + seed % 6)

	local hue2 = (hue + hueShift) % 360
	local light2 = math.clamp(lightness + lightShift, 28, 58)

	local colorA = HSLToColor3(hue,  saturation, lightness)
	local colorB = HSLToColor3(hue2, saturation, light2)

	return colorA, colorB
end

-- Haptics

local lastTap

function module.Haptic(Value, Length)
	task.spawn(function()
		local thisTick = tick()
		lastTap = thisTick

		HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, Value)

		--
		task.wait(Length or .05)
		--

		if lastTap == thisTick then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
		end
	end)
end

return module