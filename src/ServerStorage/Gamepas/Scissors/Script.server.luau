local remote = script.Parent:WaitForChild("Remote")
local sound = script.Parent:WaitForChild("Handle"):WaitForChild("Sound")
local plrs = game:GetService("Players")

local function getAccessory(hit: Instance?)
	if hit == nil then
		return nil
	elseif hit:IsA("Accoutrement") then
		return hit
	else
		return getAccessory(hit.Parent)
	end
end

remote.OnServerEvent:Connect(function(plr, target)
	if plr ~= plrs:GetPlayerFromCharacter(script.Parent.Parent) then
		-- possibly exploiting but it could just be lag
		warn(plr.Name .. " may be exploiting. Attempted to fire a remote that wasn't theirs (but they could have unequipped the item)")
		return
	end
	
	local handle = script.Parent:FindFirstChild("Handle")
	
	if not handle then return end
	
	local mag = (handle.Position - target.Position).Magnitude
	
	--warn(plr, target, mag)
	
	if mag > 8 then return end
	
	local accessory = getAccessory(target)
	
	if not accessory then
		return
	end
	
	sound:Play()
	accessory:Destroy()
end)