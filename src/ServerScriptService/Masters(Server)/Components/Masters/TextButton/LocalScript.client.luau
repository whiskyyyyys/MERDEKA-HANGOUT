script.Parent.FocusLost:Connect(function()
	script.Parent.Parent.scale.Scale = tostring(script.Parent.Text)
end)