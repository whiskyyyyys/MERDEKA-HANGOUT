local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")

local SELECT_TWEEN = TweenInfo.new(0.5, Enum.EasingStyle.Exponential)

local ThemeManager = require(ReplicatedStorage.Modules.ThemeManager)
local Signal = require(ReplicatedStorage.Modules.nevermore.Signal)
local ControllerNavigationManager = require(ReplicatedStorage.Menus.ControllerNavigationManager)

local function addTagSafe(instance, tagName)
	local ok = pcall(function()
		instance:AddTag(tagName)
	end)
	if not ok then
		CollectionService:AddTag(instance, tagName)
	end
end

local function removeTagSafe(instance, tagName)
	local ok = pcall(function()
		instance:RemoveTag(tagName)
	end)
	if not ok then
		CollectionService:RemoveTag(instance, tagName)
	end
end

local TopController = {}
TopController.__index = TopController

function TopController.new(menu)
	local self = setmetatable({}, TopController)
	self.Menu = menu
	self._activeTweens = {}
	self.OnTapSelection = Signal.new()

	self._titlesContainer = self:_resolveTitlesContainer()
	self._dancesButton = self:_resolveButton({ "Dances", "Dance" }, true)
	self._favoritesButton = self:_resolveButton({ "Favorites", "Favorite", "Fav" }, false)
	self._posesButton = self:_resolveButton({ "Poses", "Pose" }, false)

	self:_initDancesClick()
	self:_initFavoritesClick()
	self:_initPosesClick()
	self:_listenInputBegan()
	return self
end

function TopController:BindOnTapSelection(callback)
	self.OnTapSelection:Connect(callback)
end

function TopController:_resolveTitlesContainer()
	local titles = self.Menu:FindFirstChild("Titles")
	if titles then
		return titles
	end

	for _ = 1, 20 do
		titles = self.Menu:FindFirstChild("Titles")
		if titles then
			return titles
		end
		task.wait(0.15)
	end

	warn("[DanceMenuManager.TopController] Titles container not found")
	return nil
end

function TopController:_resolveButton(preferredNames, required)
	local titles = self._titlesContainer
	if not titles then
		return nil
	end

	for _, name in ipairs(preferredNames) do
		local candidate = titles:FindFirstChild(name)
		if candidate and candidate:IsA("GuiButton") then
			return candidate
		end
	end

	for _, child in ipairs(titles:GetChildren()) do
		if child:IsA("GuiButton") then
			return child
		end
	end

	if required then
		warn("[DanceMenuManager.TopController] Required tab button missing:", table.concat(preferredNames, "/"))
	end
	return nil
end

function TopController:_setButtonSelected(button)
	if not button then
		return
	end

	self:_tween(button, SELECT_TWEEN, {
		BackgroundColor3 = ThemeManager.getPrimaryColor() or Color3.fromRGB(255, 255, 255),
		TextColor3 = ThemeManager.getRule("TextColor") or Color3.fromRGB(0, 0, 0),
	})
	addTagSafe(button, "PrimaryColor")
	addTagSafe(button, "TextColor")
end

function TopController:_setButtonDeselected(button)
	if not button then
		return
	end

	self:_tween(button, SELECT_TWEEN, {
		BackgroundColor3 = ThemeManager.getRule("BackgroundColor") or Color3.fromRGB(41, 41, 41),
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})
	removeTagSafe(button, "PrimaryColor")
	removeTagSafe(button, "TextColor")
end

function TopController:_setButton(button)
	self:_stopTweens()

	local dancesButton = self._dancesButton
	local favoritesButton = self._favoritesButton
	local posesButton = self._posesButton

	if button and favoritesButton and button == favoritesButton then
		self.OnTapSelection:Fire("Favorites")
		self:_setButtonSelected(favoritesButton)
		self:_setButtonDeselected(dancesButton)
		self:_setButtonDeselected(posesButton)
		ControllerNavigationManager.setButtonSelected(1)
		return
	end

	if button and posesButton and button == posesButton then
		self.OnTapSelection:Fire("Poses")
		self:_setButtonSelected(posesButton)
		self:_setButtonDeselected(dancesButton)
		self:_setButtonDeselected(favoritesButton)
		ControllerNavigationManager.setButtonSelected(1)
		return
	end

	self.OnTapSelection:Fire("Dances")
	self:_setButtonSelected(dancesButton)
	self:_setButtonDeselected(favoritesButton)
	self:_setButtonDeselected(posesButton)
	ControllerNavigationManager.setButtonSelected(1)
end

function TopController:_initFavoritesClick()
	local favoritesButton = self._favoritesButton
	if not favoritesButton then
		return
	end

	favoritesButton.MouseButton1Click:Connect(function()
		self:_setButton(favoritesButton)
	end)
end

function TopController:_initPosesClick()
	local posesButton = self._posesButton
	if not posesButton then
		return
	end

	posesButton.MouseButton1Click:Connect(function()
		self:_setButton(posesButton)
	end)
end

function TopController:_initDancesClick()
	local dancesButton = self._dancesButton
	if not dancesButton then
		return
	end

	dancesButton.MouseButton1Click:Connect(function()
		self:_setButton(dancesButton)
	end)
end

function TopController:_listenInputBegan()
	UserInputService.InputBegan:Connect(function(input)
		if StarterGui:GetAttribute("MainMenuOpen") then
			return
		end

		if input.KeyCode == Enum.KeyCode.ButtonR1 then
			if self._favoritesButton then
				self:_setButton(self._favoritesButton)
			elseif self._posesButton then
				self:_setButton(self._posesButton)
			end
			return
		end

		if input.KeyCode == Enum.KeyCode.ButtonL1 and self._dancesButton then
			self:_setButton(self._dancesButton)
		end
	end)
end

function TopController:_stopTweens()
	for _, tween in next, self._activeTweens do
		tween:Cancel()
		tween:Destroy()
	end
	table.clear(self._activeTweens)
	self._activeTweens = {}
end

function TopController:_tween(target, tweenInfo, properties)
	local tween = TweenService:Create(target, tweenInfo, properties)
	tween:Play()
	table.insert(self._activeTweens, tween)
	return tween
end

return TopController
