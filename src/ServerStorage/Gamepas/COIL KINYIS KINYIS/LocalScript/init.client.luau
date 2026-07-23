
local cd = false

local cdtime = 2
script.Parent.Activated:Connect(function()
	
	
	if cd == false then
		cd = true
		script.RemoteEvent:FireServer()
		
		task.wait(cdtime)
		cd = false
	end
end)
