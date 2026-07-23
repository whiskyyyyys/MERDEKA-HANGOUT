local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function(context, message)
	local ev = ReplicatedStorage:FindFirstChild("GlobalAnnouncementEvent")
	if ev then
		ev:FireAllClients({
			displayName = context.Executor.Name,
			prefix = "",
			message = message,
			nameColor = Color3.fromRGB(255, 50, 50)
		})
	end
	return "Pengumuman terkirim!"
end
