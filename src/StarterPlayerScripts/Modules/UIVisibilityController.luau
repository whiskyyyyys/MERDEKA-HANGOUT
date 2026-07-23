local UIVisibilityController = {}
UIVisibilityController.__index = UIVisibilityController

-- nama ScreenGui yang JANGAN ikut disembunyikan (fishing UI sendiri)
local EXCLUDED_GUI_NAMES = {
	["Fishing"] = true,
}

function UIVisibilityController.new(playerGui)
	local self = setmetatable({}, UIVisibilityController)
	self.playerGui = playerGui
	self.previousStates = {}
	return self
end

function UIVisibilityController:HideOthers()
	self.previousStates = {}
	for _, gui in self.playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and not EXCLUDED_GUI_NAMES[gui.Name] then
			self.previousStates[gui] = gui.Enabled
			gui.Enabled = false
		end
	end
	-- sembunyikan juga default Roblox topbar/backpack/chat kalau perlu:
	-- game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end

function UIVisibilityController:RestoreOthers()
	for gui, wasEnabled in self.previousStates do
		if gui and gui.Parent then
			gui.Enabled = wasEnabled
		end
	end
	self.previousStates = {}
	-- game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end

return UIVisibilityController