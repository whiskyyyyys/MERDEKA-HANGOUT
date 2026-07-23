local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")
local text_service = game:GetService("TextService")
local user_service = game:GetService("UserService")
local haptic_service = game:GetService("HapticService")

local players = game:GetService("Players")
local serverscript_service = game:GetService("ServerScriptService")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local slow = TweenInfo.new(.8, Enum.EasingStyle.Exponential)

local modules = script.Parent
local events = modules.Parent.events
local Configuration = require(modules.Configuration)

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

function module.GetLayoutOrderFromEpochTime(epoch)
	local date = os.date("*t", epoch)

	return (date.hour * 3600) + (date.min * 60) + date.sec + 1
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

function module.FormatSecondsToHM(seconds)
	if not seconds or typeof(seconds) ~= "number" or seconds < 60 then
		return nil
	end

	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60)
	minutes = minutes % 60

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
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
		Days = PadWithZero(days),
		Hours = PadWithZero(hours),
		Minutes = PadWithZero(minutes),
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
		{ name = "y", seconds = 31536000 },
		{ name = "w", seconds = 604800 },
		{ name = "d", seconds = 86400 },
		{ name = "h", seconds = 3600 },
		{ name = "m", seconds = 60 },
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

-- Interface / Numbers

function module.MapNumberRange(mainRange: NumberRange, targetRange: NumberRange, value: number)
	local min1, max1 = mainRange.Min, mainRange.Max
	local min2, max2 = targetRange.Min, targetRange.Max

	value = math.clamp(value, min1, max1)

	local alpha = (value - min1) / (max1 - min1)
	local result = min2 + (max2 - min2) * alpha

	return result
end

function module.CircularProgress(Canvas, Duration, StartFilled)
	local Half = Duration / 2
	local RotaryInfo = TweenInfo.new(Half, Enum.EasingStyle.Linear)

	task.spawn(function()
		if StartFilled then
			Canvas.RightCircle.Rotation = 180
			Canvas.RightCircle.Visible = false

			Canvas.LeftCircle.Rotation = 180
			Canvas.LeftCircle.Visible = true

			Canvas.LeftLine.Visible = true
			Canvas.RightLine.Visible = true

			--

			tween_service:Create(Canvas.LeftCircle, RotaryInfo, {Rotation = 0}):Play()

			--
			task.wait(Half)
			--

			Canvas.RightCircle.Visible = true

			tween_service:Create(Canvas.RightCircle, RotaryInfo, {Rotation = 0}):Play()

			--
			task.wait(Half)
			--

			Canvas.LeftLine.Visible = false
			Canvas.RightLine.Visible = false
		else
			Canvas.RightCircle.Rotation = 0
			Canvas.RightCircle.Visible = true

			Canvas.LeftCircle.Rotation = 0
			Canvas.LeftCircle.Visible = true

			Canvas.RightCircle.Visible = true
			Canvas.LeftLine.Visible = true

			--

			tween_service:Create(Canvas.RightCircle, RotaryInfo, {Rotation = 180}):Play()

			--
			task.wait(Half)
			--

			tween_service:Create(Canvas.LeftCircle, RotaryInfo, {Rotation = 180}):Play()
		end
	end)
end

function module.GetHalfViewport()
	local viewport = workspace.CurrentCamera.ViewportSize

	local x = (viewport.X / 2)
	local y = (viewport.Y / 2)

	return Vector2.new(x, y)
end

function module.TransformToSource(Source, Subject)
	local PADDING = Vector2.new(150, 150)

	local sourceAbsPos = Source.AbsolutePosition
	local sourceAbsSize = Source.AbsoluteSize
	local sourceAnchorOffset = sourceAbsSize * Source.AnchorPoint
	local sourceCenter = sourceAbsPos + sourceAnchorOffset

	local finalSize = sourceAbsSize + PADDING

	local subjectAnchorOffset = finalSize * Subject.AnchorPoint

	local parentAbsPos = Subject.Parent.AbsolutePosition
	local topLeftRelative = sourceCenter - parentAbsPos

	return {
		Position = UDim2.fromOffset(topLeftRelative.X + (sourceAbsSize.X / 2), topLeftRelative.Y + (sourceAbsSize.Y / 2)),
		Size = UDim2.fromOffset(finalSize.X, finalSize.Y)
	}
end

function module.GetSpecularHighlightsAndShadows(color: Color3, HighlightIntensity, ShadowIntensity)
	local function AdjustBrightness(c: Color3, factor: number)
		return Color3.new(
			math.clamp(c.R * factor, 0, 1),
			math.clamp(c.G * factor, 0, 1),
			math.clamp(c.B * factor, 0, 1)
		)
	end

	local highlight = AdjustBrightness(color, HighlightIntensity or 1.3)
	local shadow = AdjustBrightness(color, ShadowIntensity or .3)

	return {
		Highlight = highlight,
		Shadows = shadow
	}
end

function module.AssetToTexture(assetid)
	return "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=" .. assetid
end

function module.FormatSecondsToMSS(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60

	return string.format("%d:%02d", minutes, secs)
end

function module.AnimateFillTextbox(textbox:TextBox)
	local transparency = textbox.TextTransparency

	textbox.TextTransparency = 1
	textbox.LineHeight = 2

	tween_service:Create(textbox, slow, {TextTransparency = transparency, LineHeight = 1}):Play()
end

function module.FilterString(text, id, visible_to_all)
	if run_service:IsServer() then
		local result
		local success, err = pcall(function()
			result = text_service:FilterStringAsync(text, id)
		end)

		if result then
			if visible_to_all then
				return result:GetNonChatStringForBroadcastAsync()
			else
				return result:GetNonChatStringForUserAsync()
			end
		else
			local hash = {}

			for i = 1, string.len(text) do
				table.insert(hash, "#")
			end

			return table.concat(hash, "")
		end
	elseif run_service:IsClient() then
		return events.ui.FilterString:InvokeServer(text, id, visible_to_all)
	end
end

function module.SendTextboxForFiltering(textbox, id, visible_to_all)
	task.spawn(function()
		textbox.Interactable = false
		textbox.Text = module.FilterString(textbox.Text, id, visible_to_all)
		textbox.Interactable = true
	end)
end

function module.SetBadgeOfNavigationButton(NavName, state)
	assert(run_service:IsClient(), "This function only works on the client.")

	local ui = players.LocalPlayer.PlayerGui:FindFirstChild("EXE6")
	local navigation = ui.main_frame.content.navigation

	local button = navigation.directory.primary:FindFirstChild(NavName)
	if not button then return end

	if state then

		tween_service:Create(button.util.badge_container, info, {GroupTransparency = 0}):Play()
		tween_service:Create(button.util.badge_container.badge, info, {Size = UDim2.fromOffset(14, 14)}):Play()

	else

		tween_service:Create(button.util.badge_container, info, {GroupTransparency = 1}):Play()
		tween_service:Create(button.util.badge_container.badge, info, {Size = UDim2.fromOffset(4, 4)}):Play()

	end
end

function module.PointToRelativePoint(ui, desired_abs)
	local relativePosition = desired_abs - ui.Parent.AbsolutePosition

	return Vector2.new(relativePosition.X, relativePosition.Y)
end

function module.RoundByRoundifier(roundifier, n)
	return math.floor(n / roundifier + .5) * roundifier
end

function module.ResetScrollPosition(ui:GuiObject)
	for i, scroll in pairs(ui:GetDescendants()) do
		if scroll:IsA("ScrollingFrame") then
			scroll.CanvasPosition = Vector2.new(0, 0)
		end
	end
end

function module.GetPlayerThumbnail(id)
	return players:GetUserThumbnailAsync(id or 1, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
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

function module.SwitchToggle(switch, state)
	if state then
		tween_service:Create(switch, info, {ImageColor3 = module.AdjustColor(Configuration.Interface.Theme)}):Play()
		tween_service:Create(switch.knob, info, {Position = UDim2.fromScale(1, .5),
			ImageColor3 = Configuration.Interface.Theme}):Play()
	else
		tween_service:Create(switch, info, {ImageColor3 = Color3.fromRGB(88, 88, 88)}):Play()
		tween_service:Create(switch.knob, info, {Position = UDim2.fromScale(0, .5),
			ImageColor3 = Color3.fromRGB(34, 34, 34)}):Play()
	end
end

function module.TrimString(input, max)
	if #input > max then
		return input:sub(1, max)
	else
		return input
	end
end

function module.GetScaleByScrollPositionInHomepage(canvas_position)
	return math.clamp(-1/80 * canvas_position + 2, 1, 5)
end

function module.GetImageColor3ByScrollPositionInHomepage(canvas_position)
	canvas_position = math.clamp(canvas_position, 0, 80)

	local startColor = Color3.fromRGB(42, 42, 42)
	local endColor = Color3.fromRGB(97, 97, 97)
	local factor = canvas_position / 80

	local r = startColor.R + (endColor.R - startColor.R) * factor
	local g = startColor.G + (endColor.G - startColor.G) * factor
	local b = startColor.B + (endColor.B - startColor.B) * factor

	return Color3.new(r, g, b)
end

function module.GetTransparencyByScrollPositionInHomepage(canvas_position)
	canvas_position = math.clamp(canvas_position, 0, 80)

	return 1 - (canvas_position / 80)
end

function module.GetSizeXByScrollPositionInHomepage(canvas_position)
	canvas_position = math.clamp(canvas_position, 0, 80)

	return (-3/4) * canvas_position + 60
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

function module.GetActiveModals()
	assert(run_service:IsClient(), "This function only works on the client.")

	local ui = players.LocalPlayer.PlayerGui:FindFirstChild("EXE6")
	local t = {}

	if ui then
		for i, m in pairs(ui.modal_frame:GetChildren()) do
			if m:IsA("ImageButton") and m.Visible and m.Interactable then
				table.insert(t, m)
			end
		end
	end
	return t
end

-- Tables

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

function module.IsSelectedRecordedUserIdConsistent(t)
	local Standard = nil

	for _, button in pairs(t) do
		if button:IsA("ImageButton") then
			if Standard == nil then
				Standard = button.ban_type.game.Visible
			end

			if button.ban_type.game.Visible == Standard then
				continue
			else 
				return false
			end
		else
			return false
		end
	end

	return true, Standard
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

function module.GetExtremeIndex(tbl, mode)	
	if #tbl == 0 then
		return nil
	end

	local extremeIndex = 1

	for i = 2, #tbl do
		if (mode == ">" and tbl[i] > tbl[extremeIndex]) or (mode == "<" and tbl[i] < tbl[extremeIndex]) then
			extremeIndex = i
		end
	end

	return extremeIndex
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

function module.GetViewportRatio()
	local viewport = workspace.CurrentCamera.ViewportSize

	return viewport.X + viewport.Y
end

function module.GetNameByUserIdAsync(id, AddAt)
	local success, result = pcall(function()
		return players:GetNameFromUserIdAsync(id)
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
		return user_service:GetUserInfosByUserIdsAsync({id})[1]
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
		return user_service:GetUserInfosByUserIdsAsync({id})
	end)

	if success then
		return result[1]
	end

	return nil
end

function module.GetUserIdByNameAsync(name)
	local success, result = pcall(function()
		return players:GetUserIdFromNameAsync(name)
	end)

	if success then
		return result
	end

	return nil
end

local GeneratedCodes = {}

function module.GenerateUniqueCode(length)
	assert(type(length) == "number" and length > 0, "Length must be a positive number.")

	local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

	local code
	repeat
		local AvailableCharacters = {}

		for char in characters:gmatch(".") do
			table.insert(AvailableCharacters, char)
		end

		for i = #AvailableCharacters, 2, -1 do
			local j = math.random(i)
			AvailableCharacters[i], AvailableCharacters[j] = AvailableCharacters[j], AvailableCharacters[i]
		end

		code = table.concat(AvailableCharacters, "", 1, length)
	until not GeneratedCodes[code]

	GeneratedCodes[code] = true

	return code
end

function module.TweenModel(model:Model, value, tweeninfo)
	if typeof(value) == "CFrame" then
		local CFrameValue = Instance.new("CFrameValue")
		CFrameValue.Value = model:GetPivot()

		CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
			model:PivotTo(CFrameValue.Value)
		end)

		local tween = tween_service:Create(CFrameValue, tweeninfo, {Value = value})

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

		local tween = tween_service:Create(ScaleValue, tweeninfo, {Value = value})

		tween:Play()

		tween.Completed:Connect(function()
			ScaleValue:Destroy()
		end)
	end
end

function module.GetPermsVisualsList()

	local VisualNames = {
		AuditActivities = "Audit Activities",
		AuditWebhooks = "Audit Webhooks",

		ViewBanHistory = "View Ban History",
		ViewChatHistory = "View Chat History",
		ViewWarnHistory = "View Warn History",

		Kick = "Kick",
		Notify = "Notify",
		Warn = "Warn",
		ConfigureHumanoid = "Configure Humanoid",
		ConfigureCharacter = "Configure Character",
		Fly = "Fly",

		Ban = "Ban",
		ServerBan = "Server Ban",
		Unban = "Unban",
		ServerUnban = "Server Unban",

		ServerAnnouncement = "Server Announcement",
		GlobalAnnouncement = "Global Announcement",

		ViewAuditLogs = "View Audit Logs",
		ServerPrivacy = "Server Privacy",

		ServerTeleportation = "Server Teleportation",
	}

	local Descriptions = {
		AuditActivities = "Logs all of the activities.";
		AuditWebhooks = "Connect all of the audited activities .",

		ViewBanHistory = "Able to view user's ban history.";
		ViewChatHistory = "Able to view user's chat history.";
		ViewWarnHistory = "Able to view user's warn history";

		Kick = "Remove players from the server.";
		Notify = "Send notifications to players";
		Warn = "Issue warnings to players.";
		ConfigureHumanoid = "Modify a player's humanoid properties on the profile. (Walk Speed, Jump, Health)";
		ConfigureCharacter = "Edit a player's character on the profile. (Freeze, Visibility, Teleportations)";
		Fly = "Ability to toggle flying capabilities.";

		Ban = "Ban players from the game.";
		ServerBan = "Ban players from a server.";
		Unban = "Revoke game bans.";
		ServerUnban = "Revoke server-specific bans.";

		ServerAnnouncement = "Broadcast announcements in the server.";
		GlobalAnnouncement = "Broadcast announcements across all active servers.";

		ViewAuditLogs = "Access the logged activities.";
		ServerPrivacy = "Modify the server's privacy settings.";

		ServerTeleportation = "Teleport between different servers in the game.";
	}

	return VisualNames, Descriptions
end

function module.GetUserIdsOfTeam(role_name)
	local data = {}

	if run_service:IsServer() then
		for i, plr in pairs(players:GetPlayers()) do
			local Auth = require(serverscript_service:WaitForChild("EXE6_SERVER").Auth)
			local authorized = Auth.IsAuthorized(plr.UserId)

			if plr:HasTag("Exe6PersonLoaded") and authorized then
				if role_name then
					if authorized.Role.Alias == role_name then
						table.insert(data, plr.UserId)
					end
				else
					table.insert(data, plr.UserId)
				end
			end 
		end
	else
		for i, plr in pairs(players:GetPlayers()) do
			local authorized = events.auth.Auth:InvokeServer("IsAuthorized", plr.UserId)

			if plr:HasTag("Exe6PersonLoaded") and authorized then
				if role_name then
					if authorized.Role.Alias == role_name then
						table.insert(data, plr.UserId)
					end
				else
					table.insert(data, plr.UserId)
				end
			end 
		end
	end

	return data
end

function module.GetUserIdsOfNonmembers()
	local data = {}

	if run_service:IsServer() then
		for i, member in pairs(players:GetPlayers()) do
			local Auth = require(serverscript_service:WaitForChild("EXE6_SERVER").Auth)
			local authorized = Auth.IsAuthorized(member.UserId)

			if member:HasTag("Exe6PersonLoaded") and not authorized then
				table.insert(data, member.UserId)
			end
		end
	elseif run_service:IsClient() then 
		for i, member in pairs(players:GetPlayers()) do
			local authorized = events.auth.Auth:InvokeServer("IsAuthorized", member.UserId)

			if member:HasTag("Exe6PersonLoaded") and not authorized then
				table.insert(data, member.UserId)
			end
		end
	end

	return data
end

function module.GetUserIdsOfEveryone()
	local data = {}

	for i, plr in pairs(players:GetPlayers()) do
		if plr:HasTag("Exe6PersonLoaded") then
			table.insert(data, plr.UserId)
		end 
	end

	return data
end

function module.GetUserIdsOfTeamInServer()
	local team = {}

	if run_service:IsServer() then
		for i, member in pairs(players:GetPlayers()) do
			local Auth = require(serverscript_service:WaitForChild("EXE6_SERVER").Auth)
			local authorized = Auth.IsAuthorized(member.UserId)

			if member:HasTag("Exe6PersonLoaded") and authorized then
				table.insert(team, member.UserId)
			end
		end
	elseif run_service:IsClient() then 
		for i, member in pairs(players:GetPlayers()) do
			local authorized = events.auth.Auth:InvokeServer("IsAuthorized", member.UserId)

			if member:HasTag("Exe6PersonLoaded") and authorized then
				table.insert(team, member.UserId)
			end
		end
	end

	return team
end

function module.AddWarnHighlight()
	local highlight = Instance.new("Highlight")

	highlight.Name = "PlayerUnavailability"
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.fromRGB(65, 65, 65)
	highlight.FillTransparency = .2
	highlight.OutlineTransparency = 1

	highlight:AddTag("Exe6")

	return highlight
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

--// HAPTICS

local lastTap

function module.Haptic(Value, Length)
	if not Configuration.Interface.HapticFeedback then return end

	task.spawn(function()
		local thisTick = tick()
		lastTap = thisTick

		haptic_service:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, Value)

		--
		task.wait(Length or .05)
		--

		if lastTap == thisTick then
			haptic_service:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
		end
	end)
end

function module.ParseMentions(input)
	local mentions = {}
	local hasValidMentions = false

	local formatted = input:gsub("@(%f[%w][%w_.]+)", function(user)
		local success, userId = pcall(function()
			return players:GetUserIdFromNameAsync(user)
		end)

		if success and userId then
			mentions[userId] = user
			hasValidMentions = true

			return `<font color="#{Configuration.Interface.Theme:ToHex()}"><b>@{user}</b></font>`
		else
			return "@" .. user
		end
	end)

	if not hasValidMentions then
		return nil
	end

	return mentions, formatted
end

function module.StopAllPlayback(ui, playback)
	if playback then
		for i, other in pairs(ui:GetDescendants()) do
			if other:IsA("Sound") and other:HasTag("Exe6PlaybackSoundItem") and other ~= playback then
				other:Stop()
			end
		end
	else
		for i, other in pairs(ui:GetDescendants()) do
			if other:IsA("Sound") and other:HasTag("Exe6PlaybackSoundItem") then
				other:Stop()
			end
		end
	end
end

function module.PlayersToUserIds(PlayerTable)
	local UserIds = {}

	for i, plr in pairs(PlayerTable) do
		table.insert(UserIds, plr.UserId)
	end

	return UserIds
end

return module