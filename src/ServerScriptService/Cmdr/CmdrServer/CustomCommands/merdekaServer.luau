local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function(context, message)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, 5, 0)
			att.Parent = char.HumanoidRootPart
			
			local emit = Instance.new("ParticleEmitter")
			emit.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
			})
			emit.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 3), NumberSequenceKeypoint.new(1, 0)})
			emit.Texture = "rbxassetid://243660364"
			emit.Lifetime = NumberRange.new(1, 2)
			emit.Rate = 100
			emit.Speed = NumberRange.new(10, 20)
			emit.SpreadAngle = Vector2.new(180, 180)
			emit.Parent = att
			Debris:AddItem(att, 5)
		end
	end
	
	local ev = ReplicatedStorage:FindFirstChild("GlobalAnnouncementEvent")
	if ev then
		ev:FireAllClients({
			displayName = "MERDEKA!",
			prefix = "",
			message = message,
			nameColor = Color3.fromRGB(255, 0, 0)
		})
	end
	return "Kembang api merdeka dinyalakan!"
end
