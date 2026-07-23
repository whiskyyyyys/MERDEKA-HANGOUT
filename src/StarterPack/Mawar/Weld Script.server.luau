--Simply put it inside any model with bricks inside


local prev 
local parts = script.Parent:GetChildren() 

for i = 1,#parts do 
	if (parts[i].className == "Part") or (parts[i].className == "WedgePart") or (parts[i].className == "Seat") or (parts[i].className == "VehicleSeat") or (parts[i].className == "CornerWedgePart") or (parts[i].className == "WedgePart") or (parts[i].className == "UnionOperation") then 
		if (prev ~= nil)then 
			local weld = Instance.new("Weld") 
			weld.Part0 = prev 
			weld.Part1 = parts[i] 
			weld.C0 = prev.CFrame:inverse() 
			weld.C1 = parts[i].CFrame:inverse() 
			weld.Parent = prev 
		end 
		prev = parts[i] 
	end 
end

--Credits to NyroKoSu and OrientalAura