local SkinConfig = {}

SkinConfig.DEFAULT_SKIN = "RodDefault"

-- name = nama Tool di ServerStorage.SkinRod
-- workspaceName = nama Part etalase di Workspace.ProximityPromptBuySkinsRod
-- viewportModelName = nama child Model di dalam Tool tsb (buat ditampilkan di ViewportFrame)
-- Catatan: RodDefault modelnya bernama "Default_Model" (BUKAN "RodDefault_Model")
SkinConfig.SKINS = {
	{name = "RodDefault", workspaceName = "RodDefault", viewportModelName = "Default_Model", price = 0},
	{name = "Eirie_Bat", workspaceName = "EirieBat", viewportModelName = "Eirie_Bat_Model", price = 500},
	{name = "Galactic", workspaceName = "Galactic", viewportModelName = "Galactic_Model", price = 1500},
	{name = "Purple_Saber", workspaceName = "PurpleSaber", viewportModelName = "Purple_Saber_Model", price = 2500},
	{name = "Royal_Spider", workspaceName = "RoyalSpider", viewportModelName = "Royal_Spider_Model", price = 5000},
}

function SkinConfig.GetSkinData(name)
	for _, skin in SkinConfig.SKINS do
		if skin.name == name then
			return skin
		end
	end
	return nil
end

function SkinConfig.GetSkinByWorkspaceName(workspaceName)
	for _, skin in SkinConfig.SKINS do
		if skin.workspaceName == workspaceName then
			return skin
		end
	end
	return nil
end

return SkinConfig