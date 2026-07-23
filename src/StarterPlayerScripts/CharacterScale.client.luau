local Players = game:GetService("Players")

local function enforceStandardScale(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
			if not humanoid then return end
			
				local function setScale(scaleName, targetValue)
							local scaleObj = humanoid:FindFirstChild(scaleName)
									if scaleObj and scaleObj:IsA("NumberValue") then
													scaleObj.Value = targetValue
															
									end
				end
end