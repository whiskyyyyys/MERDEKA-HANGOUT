-- SystemInit.server.luau
-- Ensures shared folders exist in ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function getOrCreateFolder(name)
	local f = ReplicatedStorage:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = ReplicatedStorage
	end
	return f
end

local remotesFolder = getOrCreateFolder("Remotes")
getOrCreateFolder("Modules")

-- Buat remote kosong agar script lama tidak infinite yield
if not remotesFolder:FindFirstChild("OpenUpdateLog") then
	local r = Instance.new("RemoteEvent")
	r.Name = "OpenUpdateLog"
	r.Parent = remotesFolder
end

if not ReplicatedStorage:FindFirstChild("PromoTeleportEvent") then
	local r = Instance.new("RemoteEvent")
	r.Name = "PromoTeleportEvent"
	r.Parent = ReplicatedStorage
end

print("[SystemInit] Berhasil membuat folder Remotes & OpenUpdateLog!")
