local grip = game.ReplicatedStorage.DuelWeld:WaitForChild("LeftGrip")
local grip2 = game.ReplicatedStorage.DuelWeld:WaitForChild("RightGrip")
local tool = script.Parent

tool.Changed:Connect(function()
	local char = script.Parent.Parent
	local weldClone = grip:Clone()
	weldClone.C0 = grip2.C0
	weldClone.C1 = tool.Grip
	if char:FindFirstChild("LeftHand")~= nil or char:FindFirstChild("Left Arm") ~= nil then
		weldClone.Parent = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
		weldClone.Part0 = weldClone.Parent
		weldClone.Part1 = script.Parent.Handle2
	end
	tool.Unequipped:Connect(function()
		weldClone:Destroy()
	end)
end)