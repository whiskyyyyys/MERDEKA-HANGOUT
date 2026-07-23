local ThemeManager = {}

local primaryColor = Color3.fromRGB(255, 255, 255)
local rules = {
	BackgroundColor = Color3.fromRGB(41, 41, 41),
}

function ThemeManager.getPrimaryColor()
	return primaryColor
end

function ThemeManager.setPrimaryColor(color)
	if typeof(color) == "Color3" then
		primaryColor = color
	end
end

function ThemeManager.getRule(ruleName)
	return rules[ruleName]
end

function ThemeManager.setRule(ruleName, value)
	rules[ruleName] = value
end

return ThemeManager
