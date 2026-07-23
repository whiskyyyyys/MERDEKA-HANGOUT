return function(context, targets, level)
	for _, p in ipairs(targets) do
		if level >= 1 and level <= 6 then
			p:SetAttribute("CustomLevel", level)
		else
			p:SetAttribute("CustomLevel", nil)
		end
	end
	return "Level berhasil diubah!"
end
