local DataStoreService = game:GetService("DataStoreService")
return function(context, targets)
	local vipStore = DataStoreService:GetDataStore("FreeVIPUsers")
	for _, p in ipairs(targets) do
		pcall(function() vipStore:SetAsync(tostring(p.UserId), true) end)
		p:SetAttribute("HasFreeVIP", true)
	end
	return "VIP Permanen berhasil diberikan!"
end
