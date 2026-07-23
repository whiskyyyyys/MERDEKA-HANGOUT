local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local PLAYER_GROUP = "PlayersNoCollide"

pcall(function()
	PhysicsService:CreateCollisionGroup(PLAYER_GROUP)
end)

PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, false)

local function setCharacterCollision(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, PLAYER_GROUP)
		end
	end
end

local function setupAutoCollision(character)
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(descendant, PLAYER_GROUP)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		setCharacterCollision(character)
		setupAutoCollision(character)
	end)
end)