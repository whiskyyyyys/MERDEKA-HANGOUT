-- Script: MemeBillboardServer (versi di punggung)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remote = ReplicatedStorage:FindFirstChild("MemeBillboardRemote")
if not Remote then
	Remote = Instance.new("RemoteEvent")
	Remote.Name = "MemeBillboardRemote"
	Remote.Parent = ReplicatedStorage
end

Remote.OnServerEvent:Connect(function(player, targetPlayer, text)
	if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local root = targetPlayer.Character.HumanoidRootPart

	-- Hapus yang lama kalau masih ada
	if root:FindFirstChild("BackBillboard") then
		root.BackBillboard:Destroy()
	end

	-- Buat Billboard baru
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BackBillboard"
	billboard.Size = UDim2.new(0, 140, 0, 50)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	billboard.Parent = root

	-- Posisi di belakang punggung
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 2.5)
	billboard.Adornee = root

	-- Biar ngadep belakang player (kita pakai rotasi kamera)
	billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0)
	billboard.LightInfluence = 0
	billboard.ClipsDescendants = false

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(255, 230, 190)
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextScaled = true
	textLabel.Text = text or "Got trolled!"
	textLabel.TextStrokeTransparency = 0.4
	textLabel.TextStrokeColor3 = Color3.fromRGB(40, 20, 10)
	textLabel.Parent = billboard

	-- Efek muncul smooth
	billboard.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(billboard, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 140, 0, 50)
	}):Play()

	-- Sedikit goyang naik-turun biar lucu
	local RunService = game:GetService("RunService")
	local startTime = tick()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not billboard or not billboard.Parent then
			if conn then conn:Disconnect() end
			return
		end
		local t = tick() - startTime
		local bob = math.sin(t * 2) * 0.25
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.5 + bob, 2.5)
	end)

	-- Hapus setelah 1 menit
	task.delay(60, function()
		if billboard and billboard.Parent then
			if conn then conn:Disconnect() end
			local fade = TweenService:Create(billboard, TweenInfo.new(0.5), {Size = UDim2.new(0, 0, 0, 0)})
			fade:Play()
			fade.Completed:Connect(function()
				billboard:Destroy()
			end)
		end
	end)
end)
