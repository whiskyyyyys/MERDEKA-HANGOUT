chicken = script.Parent
col = false
local cooldown = false
function loop()
while true do
	local movement = math.random(0,10)
	local randorient = math.random(-179,179)
	print("moving")
	--print(randorient)
	while chicken.Orientation.Y < randorient and chicken.Orientation.Y < (randorient+1) do
	chicken.Orientation = chicken.Orientation + Vector3.new(0,.5,0)
	wait(1/100000)
	end
	--print("rotated")
	for i = 0,1,.01 do
		if col == false then
		local newCFrame = chicken.CFrame - chicken.CFrame.LookVector*(movement/10)*i
		chicken.CFrame = newCFrame
		wait(1/math.random(10,100))
		else
		break
		end
	end
	wait(1)
wait(math.random(1,3))
end
end
loop()
chicken.Touched:Connect(function(part)
print("touched")
if cooldown == false then
if part.CanCollide == "true" then
col = true
cooldown = true
loop()
wait(3)
cooldown = false
end
end
end)