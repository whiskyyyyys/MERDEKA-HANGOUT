local player = game.Players.LocalPlayer

repeat wait(1) until player.Character

local character = player.Character
local humanoid = character:WaitForChild("Humanoid")

local animation = Instance.new("Animation")
animation.Name = "Idle"
animation.Parent = script.Parent

animation.AnimationId = "http://www.roblox.com/asset/?id=" .. "124492418146753"
local animtrack = humanoid:LoadAnimation(animation)

script.Parent.Equipped:connect(function()
	animtrack:Play()
end)

script.Parent.Unequipped:connect(function()
	animtrack:Stop()
end)

