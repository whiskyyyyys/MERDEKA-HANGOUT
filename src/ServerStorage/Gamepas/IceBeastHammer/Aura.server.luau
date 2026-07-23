local tool = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local auraTemplate = ReplicatedStorage:WaitForChild("Auras"):WaitForChild("AuraTemplate3")

local auraClone

tool.Equipped:Connect(function()
	local character = tool.Parent
	local hrp = character:WaitForChild("HumanoidRootPart")

	if auraClone then
		auraClone:Destroy()
		auraClone = nil
	end

	auraClone = auraTemplate:Clone()
	auraClone.Name = "AuraClone"
	auraClone.Parent = hrp

	local attachmentsFolder = auraClone:FindFirstChild("Attachments")
	if attachmentsFolder then
		for _, att in ipairs(attachmentsFolder:GetChildren()) do
			if att:IsA("Attachment") then
				att.Parent = hrp
			end
		end
	end

	for _, pe in ipairs(auraClone:GetDescendants()) do
		if pe:IsA("ParticleEmitter") then
			if not pe.Parent:IsA("Attachment") then
				pe.Parent = hrp
			end
			pe.Enabled = true
		end
	end
end)

tool.Unequipped:Connect(function()
	if auraClone then
		auraClone:Destroy()
		auraClone = nil
	end
end)

--[[
                ██████╗ ███████╗██╗     ███████╗██╗  ██╗ ██████╗ ██████╗ ██╗   ██╗
                ██╔══██╗██╔════╝██║     ██╔════╝╚██╗██╔╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
                ██║  ██║█████╗  ██║     █████╗   ╚███╔╝ ██║   ██║██████╔╝ ╚████╔╝ 
                ██║  ██║██╔══╝  ██║     ██╔══╝   ██╔██╗ ██║   ██║██╔══██╗  ╚██╔╝  
                ██████╔╝███████╗███████╗███████╗██╔╝ ██╗╚██████╔╝██║  ██║   ██║   
                ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝
--]]