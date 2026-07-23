chicken = script.Parent
size = chicken.Scale
while true do
	for i = 1,1.1,.01 do
		chicken.Scale = Vector3.new(size.X*-i,size.Y*i,size.Z*-i)
		wait(.1)
	end
		for i = 1.1,1,-.01 do
		chicken.Scale = Vector3.new(size.X*-i,size.Y*i,size.Z*-i) 
		wait(.1)
	end
end