script.Parent.Activated:Connect(function()
	local mouse = game.Players.LocalPlayer:GetMouse()
	script.RemoteEvent:FireServer(mouse.Target,mouse.Hit)
end)