chicken = script.Parent
col = false
ts = game:GetService("TweenService")
function jump()
--print("jumping")
local goal = {}
goal.Position = chicken.Position + Vector3.new(0,1,0)
local tweenInfo = TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,true,0)
local tween = ts:Create(chicken,tweenInfo,goal)
tween:Play()
end
while true do
local jumpchance = math.random(1,10)
if jumpchance < 5 then
	jump()
end
wait(math.random(1,3))
end
