return function(context, targets, reason)
	local count = 0
	
	for _, p in ipairs(targets) do
		p:Kick("Di-kick oleh Admin: " .. reason)
		count = count + 1
	end
	
	return "Berhasil melakukan kick terhadap " .. count .. " pemain."
end
