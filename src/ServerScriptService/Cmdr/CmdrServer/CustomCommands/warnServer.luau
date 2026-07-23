local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function(context, targets, message)
	local AdminRemotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
	if AdminRemotes then
		local WarnEvent = AdminRemotes:FindFirstChild("WarnEvent")
		if WarnEvent then
			for _, p in ipairs(targets) do
				WarnEvent:FireClient(p, message, context.Executor.UserId, context.Executor.Name)
			end
		end
	end
	return "Warn berhasil dikirim!"
end
