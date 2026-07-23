local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

return function(context)
	local players = Players:GetPlayers()
	if #players == 0 then
		return "Tidak ada player di server untuk direstart."
	end
	
	local placeId = game.PlaceId
	
	-- Tampilkan pesan ke seluruh server bahwa server sedang restart
	for _, player in ipairs(players) do
		task.spawn(function()
			local PlayerGui = player:FindFirstChild("PlayerGui")
			if PlayerGui then
				local gui = Instance.new("ScreenGui")
				gui.Name = "RestartMessage"
				gui.IgnoreGuiInset = true
				
				local frame = Instance.new("Frame")
				frame.Size = UDim2.fromScale(1, 1)
				frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				frame.Parent = gui
				
				local text = Instance.new("TextLabel")
				text.Size = UDim2.fromScale(0.8, 0.2)
				text.Position = UDim2.fromScale(0.1, 0.4)
				text.BackgroundTransparency = 1
				text.Text = "SERVER RESTART / UPDATE\nMohon tunggu, kamu sedang dipindahkan ke server baru..."
				text.TextColor3 = Color3.fromRGB(255, 255, 255)
				text.TextScaled = true
				text.Font = Enum.Font.GothamBold
				text.Parent = frame
				
				gui.Parent = PlayerGui
			end
		end)
	end
	
	-- Jeda agar player sempat baca dan UI ke-load
	task.wait(3)
	
	local success, err = pcall(function()
		-- Teleport semua player secara massal ke public server yang baru (tidak ke job id yang sama)
		local options = Instance.new("TeleportOptions")
		TeleportService:TeleportAsync(placeId, players, options)
	end)
	
	if success then
		return "Restarting Server... Memindahkan " .. #players .. " player."
	else
		return "Gagal melakukan restart: " .. tostring(err)
	end
end
