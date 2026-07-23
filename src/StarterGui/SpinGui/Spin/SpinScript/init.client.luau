local Spin = script.Parent:WaitForChild("Spin")
local SpinButton = script.Parent:WaitForChild("SpinButton")
local RewardName = script.Parent:WaitForChild("RewardName")

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Debounce = false
local SpinWheelEvent = ReplicatedStorage:WaitForChild("SpinWheelEvent")

local Player = Players.LocalPlayer
local PlayerStats = Player:WaitForChild("PlayerStats")
local SpinStats = PlayerStats:WaitForChild("Spin")
local SpinTime = PlayerStats:WaitForChild("SpinTime")

local function saniyeDakikaSaniyeCevirString(saniye)
	local dakika = math.floor(saniye / 60)
	local kalanSaniye = saniye % 60
	return string.format("%02d:%02d", dakika, kalanSaniye)
end

local function SpinError()
	spawn(function()
		local SpinErr = script:FindFirstChild("SpinError") and script.SpinError:Clone()
		if not SpinErr then return end
		SpinErr.Size = UDim2.fromScale(0,0)
		SpinErr.Parent = script.Parent:WaitForChild("NotEnough")
		local Animation = TweenService:Create(SpinErr,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.8,0.15)})
		local CloseAnimation = TweenService:Create(SpinErr,TweenInfo.new(0.1),{Size = UDim2.fromScale(0,0)})
		Animation:Play()
		Animation.Completed:Connect(function()
			wait(0.35)
			CloseAnimation:Play()
			CloseAnimation.Completed:Connect(function()
				SpinErr:Destroy()
			end)
		end)
	end)
end

local function updateTimer()
	script.Parent.SpinTimer.Text = "Spin : "..SpinStats.Value.." ("..saniyeDakikaSaniyeCevirString(SpinTime.Value)..")"
end

SpinTime.Changed:Connect(updateTimer)
SpinStats.Changed:Connect(updateTimer)
updateTimer()

local function ShowReward(amountText)
	local Animation = TweenService:Create(RewardName,TweenInfo.new(0.3),{Size = UDim2.fromScale(0.258,0.069)})
	local Animation2 = TweenService:Create(RewardName,TweenInfo.new(0.2),{Size = UDim2.fromScale(0,0)})
	RewardName.Text = amountText
	RewardName.TextColor3 = Color3.fromRGB(255, 215, 0)
	RewardName.Visible = true
	Animation:Play()
	Animation.Completed:Connect(function()
		spawn(function()
			wait(1.5)
			Animation2:Play()
			Animation2.Completed:Connect(function()
				RewardName.Visible = false
			end)
		end)
	end)
end

local AnimationButtonImage1 = TweenService:Create(SpinButton,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.21,0.21)})
local AnimationButtonImage2 = TweenService:Create(SpinButton,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.17,0.17)})

SpinButton.MouseButton1Click:Connect(function()
	if Debounce then return end

	AnimationButtonImage1:Play()
	AnimationButtonImage1.Completed:Connect(function()
		AnimationButtonImage2:Play()
	end)

	if SpinStats.Value >= 1 then
		Debounce = true
		SpinWheelEvent:FireServer()
	else
		SpinError()
	end
end)

SpinWheelEvent.OnClientEvent:Connect(function(success, rewardId, targetAngle)
	if not success then
		Debounce = false
		return
	end
	
	local fullSpins = 360 * 5
	local finalRotation = fullSpins + targetAngle
	
	local Animation1 = TweenService:Create(Spin, TweenInfo.new(5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = finalRotation})
	Animation1:Play()
	
	Animation1.Completed:Connect(function()
		-- Reset putaran tanpa fullSpins
		Spin.Rotation = targetAngle
		
		-- Tampilkan nama hadiah berdasarkan ID dari server (sesuai daftar di server)
		local prizeStr = "Reward!"
		if rewardId == 1 then prizeStr = "You won +2 MH Coin!"
		elseif rewardId == 2 then prizeStr = "You won +Rp 25.000!"
		elseif rewardId == 3 then prizeStr = "You won +Rp 10.000!"
		elseif rewardId == 4 then prizeStr = "You won +1 MH Coin!"
		elseif rewardId == 5 then prizeStr = "You won +Rp 150.000!"
		elseif rewardId == 6 then prizeStr = "You won +Rp 250.000!"
		end
		
		ShowReward(prizeStr)
		wait(1)
		Debounce = false
	end)
end)
