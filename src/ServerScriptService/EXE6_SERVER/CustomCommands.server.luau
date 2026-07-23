local tween_service = game:GetService("TweenService")
local replicated_storage = game:GetService("ReplicatedStorage")

local smooth = TweenInfo.new(10, Enum.EasingStyle.Exponential)

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")

local Auth = require(script.Parent.Auth)

local Configuration = require(storage.modules.Configuration)
local Alerts = require(storage.modules.Alerts)

--// CUSTOM COMMANDS

storage.utilities.custom_commands.Tools.OnServerEvent:Connect(function(moderator, data)
	if not Auth.IsAuthorized(moderator.UserId) then return end

	local involved = {}

	for i, recipient in pairs(data.Recipient) do
		for i, tools in pairs(data.Tools) do
			local copy = tools:Clone()

			copy.Parent = recipient.Backpack
		end

		table.insert(involved, recipient.UserId)
	end

	Alerts.BannerNotify({
		Header = "Tools successfully distributed.",
		Description = "Tools are successfullly distributed to the recipient(s).",
		Icon = "rbxassetid://11432855214",
		Involved = involved,
		Host = moderator
	})
end)

storage.utilities.custom_commands.ClearTools.OnServerEvent:Connect(function(moderator, data)
	if not Auth.IsAuthorized(moderator.UserId) then return end

	local involved = {}

	for i, recipient in pairs(data.Recipient) do
		recipient.Backpack:ClearAllChildren()		

		table.insert(involved, recipient.UserId)
	end

	Alerts.BannerNotify({
		Header = "Successfully Cleared Tools.",
		Description = "Cleared all of the backpack of the recipient(s).",
		Icon = "rbxassetid://11326877264",
		Involved = involved,
		Host = moderator
	})
end)

--

storage.utilities.custom_commands.ChangeTime.OnServerEvent:Connect(function(moderator, data)
	if not Auth.IsAuthorized(moderator.UserId) then return end

	if data.Animate then
		tween_service:Create(game.Lighting, smooth, {ClockTime = data["Time"]}):Play()
	else
		game.Lighting.ClockTime = data["Time"]
	end
end)

--

storage.utilities.custom_commands.ClearAccessories.OnServerEvent:Connect(function(moderator, data)
	if not Auth.IsAuthorized(moderator.UserId) then return end

	for i, plr in pairs(data.Recipient) do
		local char = plr.Character or plr.CharacterLoaded:Wait()

		for i, accessories in pairs(char:GetChildren()) do
			if accessories:IsA("Accessory") then
				if data["IncludeHair"] then
					accessories:Destroy()
				else
					if accessories.AccessoryType ~= Enum.AccessoryType.Hair then
						accessories:Destroy()
					end
				end
			end
		end
	end
end)

--

storage.utilities.custom_commands.Fling.OnServerEvent:Connect(function(moderator, data)
	if not Auth.IsAuthorized(moderator.UserId) then return end

	for i, plr in pairs(data.Victim) do
		local char = plr.Character or plr.CharacterLoaded:Wait()
		local characterHumanoid = char:FindFirstChild("Humanoid")
		local characterRootPart = char:FindFirstChild("HumanoidRootPart")

		if characterHumanoid and characterRootPart then
			local flingDirection = characterRootPart.CFrame.LookVector
			local velocity = Instance.new("BodyVelocity")

			velocity.Velocity = flingDirection * data.Force
			velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			velocity.Parent = characterRootPart

			task.wait(0.1)

			velocity:Destroy()
		end
	end
end)