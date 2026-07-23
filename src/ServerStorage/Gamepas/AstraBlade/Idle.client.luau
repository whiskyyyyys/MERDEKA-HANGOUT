local tool = script.Parent
local anim = Instance.new("Animation")
local anim1 = Instance.new("Animation")
anim.Name = "IdleAnim"
anim.AnimationId = "rbxassetid://92780175647522" -- Idle Animaton ID
anim1.Name = "EquipAnim"
anim1.AnimationId = "rbxassetid://92780175647522"-- Equip Tool Animaton ID
local track
local track1
-- When Tool Equipped
tool.Equipped:Connect(function()
	track = script.Parent.Parent.Humanoid:LoadAnimation(anim)
	track1 = script.Parent.Parent.Humanoid:LoadAnimation(anim1)
	track.Priority = Enum.AnimationPriority.Movement
	track1.Priority = Enum.AnimationPriority.Movement
	track.Looped = true
	track:Play()
	track1:Play()
end)

-- When Tool UnEqiopped
tool.Unequipped:Connect(function()
	if track and track1 then
		track:Stop()
		track1:Stop()
	end
end)




































--ABDUZCAN!