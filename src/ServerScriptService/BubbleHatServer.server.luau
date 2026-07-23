-- BubbleHatServer
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local function distance(p1, p2)
	if not (p1 and p2 and p1.Character and p2.Character) then return math.huge end
	local hrp1 = p1.Character:FindFirstChild("HumanoidRootPart")
	local hrp2 = p2.Character:FindFirstChild("HumanoidRootPart")
	if not (hrp1 and hrp2) then return math.huge end
	return (hrp1.Position - hrp2.Position).Magnitude
end

local function createFullBodyBubble(targetChar, playerWhoClicked)
	local root = targetChar:FindFirstChild("HumanoidRootPart")
	local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	-- Buat bubble
	local bubble = Instance.new("Part")
	bubble.Shape = Enum.PartType.Ball
	bubble.Material = Enum.Material.Glass
	bubble.Color = Color3.fromRGB(180, 255, 255)
	bubble.Transparency = 0.4
	bubble.Size = Vector3.new(8, 8, 8)
	bubble.Anchored = false
	bubble.CanCollide = false
	bubble.Massless = true
	bubble.Parent = workspace
	bubble.CFrame = root.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = bubble
	weld.Parent = bubble

	-- Biar melayang langsung
	humanoid.PlatformStand = true
	root.Velocity = Vector3.zero -- stop gerakan sebelumnya

	-- Gaya melayang & menjauh
	local bp = Instance.new("BodyPosition")
	bp.MaxForce = Vector3.new(20000, 20000, 20000)
	bp.P = 3000
	bp.D = 200
	bp.Position = root.Position + Vector3.new(0, 6, 0)
	bp.Parent = root

	-- Gaya rotasi lembut
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(10000, 10000, 10000)
	bg.P = 300
	bg.CFrame = root.CFrame
	bg.Parent = root

	-- Suara bubble (hanya terdengar oleh target)
	local underwater = Instance.new("Sound")
	underwater.SoundId = "rbxassetid://9112752575"
	underwater.Looped = true
	underwater.Volume = 1
	underwater.RollOffMaxDistance = 50
	underwater.Parent = root
	underwater:Play()

	-- Animasi napas bubble
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(bubble, tweenInfo, {Size = Vector3.new(8.4, 8.4, 8.4)})
	tween:Play()

	-- Arah menjauh pelan dari player yang klik
	local clickerHRP = playerWhoClicked.Character and playerWhoClicked.Character:FindFirstChild("HumanoidRootPart")
	local awayDir = Vector3.new(0, 0, 0)
	if clickerHRP then
		awayDir = (root.Position - clickerHRP.Position).Unit
	end

	-- Gerak menjauh halus
	task.spawn(function()
		local start = tick()
		while tick() - start < 8 do
			bp.Position = bp.Position + awayDir * 0.5 -- perlahan menjauh
			bg.CFrame = bg.CFrame * CFrame.Angles(math.rad(8), math.rad(10), math.rad(6)) -- berputar lembut
			task.wait(0.1)
		end
	end)

	-- Bubble pecah setelah 8 detik
	task.delay(8, function()
		humanoid.PlatformStand = false
		tween:Cancel()

		if underwater then underwater:Stop() underwater:Destroy() end
		if bp then bp:Destroy() end
		if bg then bg:Destroy() end
		if bubble then bubble:Destroy() end

		-- Suara pecah (didengar oleh player di sekitar)
		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character and distance(plr, targetPlayer) <= 40 then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local pop = Instance.new("Sound")
					pop.SoundId = "rbxassetid://85730811347567"
					pop.Volume = 1
					pop.RollOffMaxDistance = 50
					pop.Parent = hrp
					pop:Play()
					Debris:AddItem(pop, 3)
				end
			end
		end
	end)

	Debris:AddItem(bubble, 10)
end

game.DescendantAdded:Connect(function(child)
	if child:IsA("RemoteEvent") and child.Name == "BubbleRemote" then
		child.OnServerEvent:Connect(function(player, targetChar)
			createFullBodyBubble(targetChar, player)
		end)
	end
end)
