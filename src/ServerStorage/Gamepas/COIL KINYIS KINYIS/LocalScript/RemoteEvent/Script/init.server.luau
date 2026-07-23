


function EmitAll(char)
	for i,v in pairs(char:GetDescendants())  do
		if v:IsA("ParticleEmitter") then
			task.	spawn(function()

				task.wait(v:GetAttribute("EmitDelay"))
				v:Emit(v:GetAttribute("EmitCount"))
			end)




		end
	end
end

local Debris = game:GetService("Debris")

script.Parent.OnServerEvent:Connect(function(plr)

	local char = plr.Character
	local hrp = char.HumanoidRootPart
	local Hum = char.Humanoid
	local Smash = script["Love pangs(Start)"]:Clone()

	Hum.Animator:LoadAnimation(script.Start):Play()
	task.wait(0.4)
	Debris:AddItem(Smash,3)

	Smash.Parent = game.Workspace
	Smash.CFrame = hrp.CFrame 

	task.wait(0.05)

	EmitAll(Smash)



	local hitbox = Instance.new("Part")
	hitbox.Anchored = true
	hitbox.CanCollide =false
	hitbox.Transparency = 0.9
	hitbox.CanQuery = false

	hitbox.CanTouch = true
	hitbox.Parent = game.Workspace.Effects
	hitbox.Size = Vector3.new(9.93, 6.71, 11.48)
	hitbox.CFrame = hrp.CFrame 
	Debris:AddItem(hitbox,1)
	local cd = false
	hitbox.Touched:Connect(function(hit)
		if hit.Parent.Name ~= char.Name then
			if hit.Parent:FindFirstChild("Humanoid") then
				local Victim = hit.Parent
				if cd == false then

					cd = true
					local Ehrp = Victim.HumanoidRootPart
					local EHum = Victim.Humanoid

					Ehrp.CFrame = CFrame.lookAt(Ehrp.Position,hrp.Position)

					hrp.CFrame = Ehrp.CFrame * CFrame.new(0,0,4)

					local pang = script["Love pangs(End)"]:Clone()

					pang.Parent = game.Workspace.Effects
					pang.CFrame = Ehrp.CFrame
					hrp.Anchored = true
					Ehrp.Anchored = true
					for i,v in pairs(pang:GetDescendants()) do
						if v:IsA("ParticleEmitter") then
							v.Enabled = true
						end
					end
					Debris:AddItem(pang,3.5)
					local endanim = Hum.Animator:LoadAnimation(script.End)
					endanim:Play()
					for i = 1,10 do
						task.wait(0.1)
						script.Parent:FireClient(plr)
						EHum:TakeDamage(2)
						local high = script.Highlight:Clone()
						high.Parent = Victim
						Debris:AddItem(high,0.05)

					end

					hrp.Anchored = false
					Ehrp.Anchored = false
					endanim:Stop()
					for i,v in pairs(pang:GetDescendants()) do
						if v:IsA("ParticleEmitter") then
							v.Enabled = false
						end
					end
				end
			end
		end

	end)

end)
