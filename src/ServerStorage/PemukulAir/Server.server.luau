local tool = script.Parent
local handle = tool:FindFirstChild("Handle") or tool:WaitForChild("Part")
local cooldown = false 
local cooldownTime = 1

tool:WaitForChild("Event").OnServerEvent:Connect(function(plr, mode, target, velocity)
	if mode == "slash" then
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		local hrp = target:FindFirstChild("HumanoidRootPart")
		
		if humanoid and hrp then
			if not cooldown then
				cooldown = true 
				

				local flingvelocity = velocity * 1
				local multipliervelocity = tool:WaitForChild("Power").Value * 2	
				
				local bv = Instance.new("BodyVelocity")
				bv.Parent = hrp
				bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
				bv.Velocity = flingvelocity + Vector3.new(0, multipliervelocity, 0)


				local sound = handle.Sound
				if sound then
					sound:Play()
				end
			
				local targetPlayer = game.Players:GetPlayerFromCharacter(target)
				
				local touchedConnection
				
				touchedConnection = hrp.Touched:Connect(function(hit)
					if hit and (hit:IsA("BasePart") or hit.Name == "Baseplate") then
						humanoid.Sit = true
						
						touchedConnection:Disconnect()
						
					end
				end)
				
				
				
				wait(0.1) 
				bv:Destroy()
				
				wait(.5)
				tool.CLIENT.Enabled = false
				if plr.UserId == 7218183926 or plr.UserId == 3475914974 then
					wait(0)
				else
					wait(cooldownTime)
				end
				tool.CLIENT.Enabled = true
				cooldown = false
			end
		end
	end
end)
