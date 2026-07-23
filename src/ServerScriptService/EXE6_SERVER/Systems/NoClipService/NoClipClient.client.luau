local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remote = ReplicatedStorage:WaitForChild("NoClipRemote#!$")

local conn
local isMobile = UserInputService.TouchEnabled

local keys = {
    W = false,
    A = false,
    S = false,
    D = false,
    Space = false
}

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if keys[input.KeyCode.Name] ~= nil then
        keys[input.KeyCode.Name] = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if keys[input.KeyCode.Name] ~= nil then
        keys[input.KeyCode.Name] = false
    end
end)

local PlayerScripts = player:WaitForChild("PlayerScripts")
local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
local ControlModule = PlayerModule:GetControls()

local function getDir()
    local dir = Vector3.zero

    if isMobile then
        dir = ControlModule:GetMoveVector() or Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = Vector3.new(dir.X, 1, dir.Z)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir = Vector3.new(dir.X, -1, dir.Z)
        end
    else
        if keys.W then dir += Vector3.new(0,0,-1) end
        if keys.S then dir += Vector3.new(0,0,1) end
        if keys.A then dir += Vector3.new(-1,0,0) end
        if keys.D then dir += Vector3.new(1,0,0) end
        if keys.Space then dir += Vector3.new(0,1,0) end
    end

    if dir.Magnitude == 0 then return Vector3.zero end
    dir = dir.Unit

    local camCFrame = CFrame.new(Vector3.zero, camera.CFrame.LookVector)
    return camCFrame:VectorToWorldSpace(dir).Unit
end

local function isShiftLock()
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function enable()
    conn = RunService.RenderStepped:Connect(function()
        local rot = camera.CFrame - camera.CFrame.Position
        remote:FireServer(getDir(), rot, isShiftLock())
    end)
end

local function disable()
    if conn then
        conn:Disconnect()
        conn = nil
    end
end

remote.OnClientEvent:Connect(function(state)
    if state then
        enable()
    else
        disable()
    end
end)
