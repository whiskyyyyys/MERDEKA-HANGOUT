local MarketplaceService = game:GetService("MarketplaceService")
local Player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

for i,v in pairs(script.Parent:WaitForChild("ProductSpin"):GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()

			local AnimationButtonImage1 = TweenService:Create(v,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.77,0.104)})
			local AnimationButtonImage2 = TweenService:Create(v,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.7,0.095)})
			
			local AnimationButtonHover1 = TweenService:Create(v,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.77,0.10)})
			local AnimationButtonHover2 = TweenService:Create(v,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.7,0.095)})

			AnimationButtonImage1:Play()
			AnimationButtonImage1.Completed:Connect(function()
				AnimationButtonImage2:Play()
			end)	AnimationButtonImage1:Play()

			local ID = v:WaitForChild("ID")
			MarketplaceService:PromptProductPurchase(Player,ID.Value)
		end)
		
		v.MouseEnter:Connect(function()
			local AnimationButtonHover1 = TweenService:Create(v,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.8,0.12)})
			AnimationButtonHover1:Play()
		end)
		
		v.MouseLeave:Connect(function()
			local AnimationButtonHover1 = TweenService:Create(v,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.7,0.095)})
			AnimationButtonHover1:Play()
		end)
		
	end
end


-- more uncopylocked! our discord https://discord.gg/uUv64J5sPZ