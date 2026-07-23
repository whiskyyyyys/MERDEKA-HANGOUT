local TextChatService = game:GetService("TextChatService")

return function(context, targetPlayer, message)
	if not targetPlayer then
		return "Target tidak ditemukan."
	end

	-- Jika Cmdr mengirimkan tipe 'strings', itu berupa table (array kata-kata). Kita gabungkan jadi satu string.
	if type(message) == "table" then
		message = table.concat(message, " ")
	end

	-- Roblox's new TextChatService allows sending messages on behalf of players
	-- if the script is running on the server.
	-- We need to find the TextSource associated with the target player.
	
	local textChannel = TextChatService:FindFirstChild("TextChannels")
	if textChannel then
		textChannel = textChannel:FindFirstChild("RBXGeneral")
	end

	if not textChannel then
		-- Fallback to old Chat service if TextChatService is not fully used
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		if chatEvent and chatEvent:FindFirstChild("SayMessageRequest") then
			-- The old system doesn't easily let the server force a client to speak
			-- without a RemoteEvent specifically set up for it on the client side.
			-- We will try to use the newer TextChatService method first.
			return "Game ini menggunakan sistem chat lama (Legacy Chat). Fake chat dari server membutuhkan sistem TextChatService (baru) atau RemoteEvent khusus di client."
		end
		
		-- Try sending system message as a fallback if TextChatService is active but RBXGeneral is missing
		return "Gagal mengirim chat. Channel RBXGeneral tidak ditemukan."
	end

	-- Find the target's TextSource
	local success, err = pcall(function()
		local textSource = TextChatService:GetTextSourceAsync(targetPlayer.UserId)
		if textSource then
			textChannel:SendAsync(message, textSource)
		end
	end)

	if not success then
		-- Alternative method for new TextChatService (sometimes GetTextSourceAsync is tricky)
		-- If the above fails, we'll try a fallback approach: Fire a remote event to the target client
		-- to make them say it. Since we don't have a specific remote for this, we might need one.
		
		-- For now, let's inject a LocalScript into the target player to force them to chat
		local fakeChatScript = Instance.new("LocalScript")
		fakeChatScript.Name = "CmdrFakeChat"
		fakeChatScript.Source = [[
			local TextChatService = game:GetService("TextChatService")
			local Players = game:GetService("Players")
			local msg = "]] .. message:gsub('"', '\\"') .. [["
			
			local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
			if channel then
				channel:SendAsync(msg)
			else
				local chat = game:GetService("Players").LocalPlayer.PlayerScripts:FindFirstChild("ChatScript")
				if chat then
					game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(msg, "All")
				end
			end
			script:Destroy()
		]]
		fakeChatScript.Parent = targetPlayer:FindFirstChild("PlayerGui")
	end

	return "Berhasil memaksa " .. targetPlayer.Name .. " untuk bilang: " .. message
end
