local BeatSpeed = 0.1
local BeatBack = 0.2
local function onBeat(player)
	game:GetService("TweenService"):Create(script.Parent.Parent.Parent.Bars.Left:WaitForChild("JDL2"):WaitForChild("Side") , TweenInfo.new(BeatSpeed), {Size = Vector3.new(0.344, 0.9, 1)}):Play()
	game:GetService("TweenService"):Create(script.Parent.Parent.Parent.Bars.Right:WaitForChild("JDL2"):WaitForChild("Side") , TweenInfo.new(BeatSpeed), {Size = Vector3.new(0.344, 0.9, 1)}):Play()
	wait(BeatSpeed)
	game:GetService("TweenService"):Create(script.Parent.Parent.Parent.Bars.Left:WaitForChild("JDL2"):WaitForChild("Side"), TweenInfo.new(BeatBack), {Size = Vector3.new(0.05, 0.9, 0.9)}):Play()
	game:GetService("TweenService"):Create(script.Parent.Parent.Parent.Bars.Right:WaitForChild("JDL2"):WaitForChild("Side"), TweenInfo.new(BeatBack), {Size = Vector3.new(0.05, 0.9, 0.9)}):Play()
	wait(BeatBack)
end
script.Parent.OnServerEvent:Connect(onBeat)