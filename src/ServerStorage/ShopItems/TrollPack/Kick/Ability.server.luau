--[[ delete this line since its useless to you who must have insented
game:GetService("ReplicatedStorage").Events:FindFirstChild("Animator")
]]

--Usefull stuff line
local debris = game:GetService("Debris")
local event = script.Parent:FindFirstChild("Activate")
local tool = script.Parent
local ToolName = tool.Name

local Animation = tool:FindFirstChild("AnimationOfKick") --Animation local
local OnHitAnimation = tool:FindFirstChild("AnimationOfDamage") --Animation for damaged models

local sound1 = tool:FindFirstChild("Punch Swing ") --on attack
local sound2 = tool:FindFirstChild("kick") --on hit

local Anchored = true --when the hitbox should be stuck in place [Needed True]
local Visible = false --When hitbox should be visible
local Size = 5 --how big should the hitbox be
local HitboxLifeTime = 0.2 --how long the hitbox should last
local Damage = 0 --Damage on hit

local KnockBack = true --when Knockback should be enable
local KnockbackPower = 300 --how much the knockback Power should be
local KnockbackTime = 0.2 --how long the knockback should last

local cooldownTime = 1 --Coodown time
local cooldown = false

--Warning: if you do not know how to script then do not mess with the Function you Might break it
event.OnServerEvent:Connect(function(plr)
	if not cooldown then
		cooldown = true
		local char = plr.Character
		local phum = char:FindFirstChild("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		phum:LoadAnimation(Animation):Play()
		sound1:Play()
		task.wait(0.2)
		local NewHitbox = Instance.new("Part")
		NewHitbox.Name = "Hitbox"
		NewHitbox.Size = Vector3.new(Size, Size, Size)
		if not Visible then NewHitbox.Transparency = 1 end
		if Anchored then NewHitbox.Anchored = true end
		NewHitbox.Material = Enum.Material.ForceField
		NewHitbox.Color = Color3.fromRGB(255, 0, 0)
		NewHitbox.CanCollide = false
		local RootPosition = hrp.CFrame
		NewHitbox.CFrame = RootPosition * CFrame.new(0, 0, -3.5)
		NewHitbox.Parent = workspace
		debris:AddItem(NewHitbox, HitboxLifeTime)
	local hitbox = workspace:GetPartBoundsInBox(NewHitbox.CFrame, Vector3.new(Size, Size, Size))
		local hit = {}
		for i, part in pairs(hitbox) do
			if part.Parent:FindFirstChild("Humanoid") and not table.find(hit, part.Parent) and part.Parent.Name ~= plr.Name then
				table.insert(hit, part.Parent)
				local hum = part.Parent:FindFirstChild("Humanoid")
				hum:TakeDamage(Damage)
				hum:LoadAnimation(OnHitAnimation):Play()
				sound2:Play()
				if KnockBack then
				local knockback = Instance.new("BodyVelocity")
				knockback.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				knockback.Velocity = hrp.CFrame.LookVector * KnockbackPower
				knockback.Parent = part
				game.Debris:AddItem(knockback, KnockbackTime)
				end
			end
		end
		for count = 1, cooldownTime do
			task.wait(1)
			tool.Name = cooldownTime - count
		end
		tool.Name = ToolName
		cooldown = false
	end
end)