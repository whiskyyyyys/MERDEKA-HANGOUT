local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemotesUtil = {}

local EVENT_NAMES = {
	"RequestCast",
	"CastResult",
	"SubmitCatchResult",
	"FishCaught",
	"SellFishResult",
	"SkinRodEquip",
	"SkinRodBuy",
	"SkinRodResult",
	"SkinRodDataRequest",
	"SkinRodDataResponse",
	"RequestCharacterRefresh",
	"ToggleFavoriteFish",
	"PetDataRequest",
	"PetDataResponse",
	"PetEquip",
	"PetPurchased"
}

function RemotesUtil.Get()
	local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not Remotes then
		if RunService:IsServer() then
			Remotes = Instance.new("Folder")
			Remotes.Name = "Remotes"
			Remotes.Parent = ReplicatedStorage
		else
			Remotes = ReplicatedStorage:WaitForChild("Remotes")
		end
	end

	local remotes = {}
	for _, name in EVENT_NAMES do
		local event = Remotes:FindFirstChild(name)
		if not event then
			if RunService:IsServer() then
				event = Instance.new("RemoteEvent")
				event.Name = name
				event.Parent = Remotes
			else
				event = Remotes:WaitForChild(name)
			end
		end
		remotes[name] = event
	end
	return remotes
end

return RemotesUtil