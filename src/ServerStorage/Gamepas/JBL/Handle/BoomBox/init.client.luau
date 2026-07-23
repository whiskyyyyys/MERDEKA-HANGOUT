--By Mirtis152
game:GetService("RunService").RenderStepped:connect(function()
	if script.Parent:WaitForChild("Sound").PlaybackLoudness > 500 then
		script:WaitForChild("Function"):FireServer()
    end
end)

-