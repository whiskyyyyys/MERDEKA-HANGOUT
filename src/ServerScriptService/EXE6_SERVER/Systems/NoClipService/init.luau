local NoClipService = {}
NoClipService.__index = NoClipService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsServer() then
    warn("NoClipService is not allowed on the Client.")
    return {
        NoClip = function()
            warn("Unable to run the NoClipService 'NoClip' function from the client.")
        end,
        SetState = function()
            warn("Unable to run the NoClipService 'SetState' function from the client.")
        end,
    }
end

if ReplicatedStorage:FindFirstChild("NoClipServiceLink") then
    local Link = ReplicatedStorage:WaitForChild("NoClipServiceLink")
    return require(Link.Value)
else
    local Link = Instance.new("ObjectValue")
    Link.Name = "NoClipServiceLink"
    Link.Parent = ReplicatedStorage
    Link.Value = script
end

local Remote = Instance.new("RemoteEvent")
Remote.Name = "NoClipRemote#!$"
Remote.Parent = ReplicatedStorage

NoClipService.States = {}
NoClipService.Data = {}

local SPEED = 180
local ACCELERATION = 8
local ROTATION_SMOOTH = 4

local function replicateClient(player: Player)
    local PlayerGui = player:WaitForChild("PlayerGui")
    if PlayerGui:FindFirstChild("ReplicatedScripts") then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ReplicatedScripts"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = PlayerGui

    local client = script:WaitForChild("NoClipClient"):Clone()
    client.Parent = gui
    client.Enabled = true
end

for _, p in ipairs(Players:GetPlayers()) do
    replicateClient(p)
end

Players.PlayerAdded:Connect(replicateClient)

function NoClipService:SetState(player: Player, state: boolean)
    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    if state then
        humanoid.PlatformStand = true
        root.Anchored = true
        self.Data[player] = {
            pos = root.Position,
            velocity = Vector3.zero,
            rot = root.CFrame - root.Position,
            targetRot = root.CFrame - root.Position,
            dir = Vector3.zero,
            shiftLock = false
        }
    else
        root.Anchored = false
        humanoid.PlatformStand = false
        root.Velocity = Vector3.zero
        self.Data[player] = nil
    end
end

function NoClipService:NoClip(player: Player, state)
	if not state then
		state = not self.States[player.UserId]
	end
	
    self.States[player.UserId] = state or nil
	self:SetState(player, state)
	
	Remote:FireClient(player, state)
	
	return state
end

function NoClipService:GetState(player: Player)
	return self.States[player.UserId]
end

Remote.OnServerEvent:Connect(function(player, dir, camRot, shiftLock)
    if not NoClipService.States[player.UserId] then return end
    local data = NoClipService.Data[player]
	if not data then return end
	
    data.dir = dir
    data.targetRot = camRot
    data.shiftLock = shiftLock
end)

RunService.Heartbeat:Connect(function(dt)
    for player, data in pairs(NoClipService.Data) do
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local targetVel = data.dir * SPEED
        data.velocity = data.velocity:Lerp(targetVel, math.clamp(ACCELERATION * dt, 0, 1))
        data.pos += data.velocity * dt

        if data.shiftLock then
            root.CFrame = CFrame.new(data.pos) * data.targetRot
            data.rot = data.targetRot
        else
            local alpha = math.clamp(ROTATION_SMOOTH * dt, 0, 1)
            data.rot = data.rot:Lerp(data.targetRot, alpha)
            root.CFrame = CFrame.new(data.pos) * data.rot
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    NoClipService.States[player.UserId] = nil
    NoClipService.Data[player] = nil
end)

return setmetatable({}, NoClipService)
