local NotificationManager = {}

function NotificationManager.error(message)
	warn("[NotificationManager]", message)
	return false
end

function NotificationManager.sendNotification(notificationType, payload)
	local bodyText = ""
	if type(payload) == "table" and type(payload.Body) == "table" then
		bodyText = tostring(payload.Body[1] or "")
	end

	if bodyText ~= "" then
		print(string.format("[NotificationManager] %s: %s", tostring(notificationType), bodyText))
	else
		print(string.format("[NotificationManager] %s", tostring(notificationType)))
	end
end

return NotificationManager
