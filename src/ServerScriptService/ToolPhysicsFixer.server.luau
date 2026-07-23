-- ============================================================
-- ToolPhysicsFixer.server.luau
-- Memperbaiki bug di mana pemain terlempar saat memegang tool
-- ============================================================

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local function fixTool(tool)
	if not tool:IsA("Tool") then return end
	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = false
			if desc.Name ~= "Handle" then
				desc.CanCollide = false
				desc.Massless = true
			else
				desc.CanCollide = false
				desc.Massless = true
			end
		end
	end
end

local function fixFolder(folder)
	for _, item in ipairs(folder:GetDescendants()) do
		if item:IsA("Tool") then
			fixTool(item)
		end
	end
end

print("[ToolPhysicsFixer] Memperbaiki physics untuk semua Tool...")
fixFolder(ServerStorage)
fixFolder(ReplicatedStorage)
fixFolder(StarterPack)
print("[ToolPhysicsFixer] Selesai memperbaiki tool physics.")
