local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local announceEvent = remotes:WaitForChild("ShowAnnouncement")

announceEvent.OnClientEvent:Connect(function(message)
	-- Format pesan (Teks warna Emas/Orange)
	local formattedText = "<font color='#FFB300'><b>" .. message .. "</b></font>"

	-- 1. Coba kirim via sistem chat baru Roblox (TextChatService)
	local rbxSystem = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXSystem")
	
	if rbxSystem then
		rbxSystem:DisplaySystemMessage(formattedText)
	else
		-- 2. Fallback: Kalau masih pakai sistem chat lama (Legacy Chat)
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = message,
				Color = Color3.fromRGB(255, 179, 0), -- Warna Emas/Orange
				Font = Enum.Font.GothamBold,
				TextSize = 16
			})
		end)
	end
end)
