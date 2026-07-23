local ControllerNavigationManager = {}

local currentCloseCallback = nil
local currentRoot = nil
local currentSelectedButton = 1

function ControllerNavigationManager.initCrossNavigation(root, onClose)
	currentRoot = root
	currentCloseCallback = onClose
end

function ControllerNavigationManager.stopCrossNavigation()
	currentRoot = nil
	currentCloseCallback = nil
end

function ControllerNavigationManager.setButtonSelected(index)
	currentSelectedButton = index or currentSelectedButton
end

function ControllerNavigationManager.getState()
	return {
		root = currentRoot,
		onClose = currentCloseCallback,
		selectedButton = currentSelectedButton,
	}
end

return ControllerNavigationManager
