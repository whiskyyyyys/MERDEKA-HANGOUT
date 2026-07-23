local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local run_service = game:GetService("RunService")

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local modules = storage.modules

local Alerts = require(modules.Alerts)

function CheckValidity(recipient)
	if run_service:IsClient() then return end

	if recipient:HasTag("Exe6PlayerUnavailable") then
		Alerts.BannerNotify({
			Header = "Player is unavailable.",
			Description = recipient.DisplayName .. " is unavailable.",
			Involved = {recipient.UserId},
			Icon = "rbxassetid://11419666512",
			Host = recipient
		})

		return
	end
	
	return true
end

local module = {}

export type HumanoidProperty = {
	Health: any,
	Jump: any,
	Speed: any
}

export type TeleportMethod = "Bring" | "Follow"

function module.SetHumanoidProperties(recipient: Player, Property: HumanoidProperty)
	if not CheckValidity(recipient) then return end
	
	local character = recipient.Character or recipient.CharacterAdded:Wait()
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	if Property.Health then
		humanoid.Health = Property.Health
	elseif Property.Jump then
		humanoid.JumpPower = Property.Jump
	elseif Property.Speed then
		humanoid.WalkSpeed = Property.Speed
	end
	
	return true
end

function module.SetFreeze(recipient: Player, State: boolean)
	if not CheckValidity(recipient) then return end
	
	local character = recipient.Character or recipient.CharacterAdded:Wait()
	if not character then return end
	
	local root = character:WaitForChild("HumanoidRootPart")
	
	root.Anchored = State
	
	return true
end

function module.Teleport(moderator: Player, recipient: Player, TeleportMethod: TeleportMethod)
	if not CheckValidity(recipient) then return end

	local recipient_character = recipient.Character or recipient.CharacterAdded:Wait()
	if not recipient_character then return end
	
	local moderator_character = moderator.Character or moderator.CharacterAdded:Wait()
	if not moderator_character then return end
	
	if TeleportMethod == "Follow" then
		moderator_character:WaitForChild("HumanoidRootPart").CFrame = recipient_character:WaitForChild("HumanoidRootPart").CFrame
	elseif TeleportMethod == "Bring" then
		recipient_character:WaitForChild("HumanoidRootPart").CFrame = moderator_character:WaitForChild("HumanoidRootPart").CFrame
	end
	
	return true
end

function module.SetTransparency(recipient: Player, Transparency: number)
	if not CheckValidity(recipient) then return end

	local character = recipient.Character or recipient.CharacterAdded:Wait()
	if not character then return end
	
	for _, i in pairs(character:GetDescendants()) do
		if i:IsA("BasePart") and i.Name ~= "HumanoidRootPart" then
			i.Transparency = Transparency
		end
		if i:IsA("Decal") then
			i.Transparency = Transparency
		end
	end
	
	return true
end

function module.CopyAvatar(recipient: Player, subject: number)
	if not CheckValidity(recipient) then return end
	
	local character = recipient.Character or recipient.CharacterAdded:Wait()
	if not character then return end
	
	local success, HumanoidDescription = pcall(function()
		return players:GetHumanoidDescriptionFromUserId(subject)
	end)
	
	if success and HumanoidDescription then
		character:WaitForChild("Humanoid"):ApplyDescription(HumanoidDescription)
	end
	
	return success
end

local TrackTag = "Exe6Tracking"

function module.SetTrack(Object, State)
	if not Object or not Object:IsA("Instance") then return end

	if Object:IsA("BasePart") then
		if State then
			Object:AddTag(TrackTag)
		else
			Object:RemoveTag(TrackTag)
		end

	elseif Object:IsA("Model") then
		local humanoid = Object:FindFirstChild("Humanoid")
		local player = players:GetPlayerFromCharacter(Object)

		if humanoid and player then
			if State then
				Object:AddTag(TrackTag)

				player.CharacterAdded:Connect(function(char)
					char:AddTag(TrackTag)
				end)
			else
				Object:RemoveTag(TrackTag)
			end

		else
			if State then
				Object:AddTag(TrackTag)
			else
				Object:RemoveTag(TrackTag)
			end
		end
	end
end

return module