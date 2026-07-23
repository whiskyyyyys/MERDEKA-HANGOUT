local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local Maid = require(script.Parent.nevermore.Maid)
local ThemeManager = require(script.Parent.ThemeManager)

local InstanceBase = {}
InstanceBase.__index = InstanceBase

local function addTag(instance, tagName)
	local ok = pcall(function()
		instance:AddTag(tagName)
	end)
	if not ok then
		CollectionService:AddTag(instance, tagName)
	end
end

local function removeTag(instance, tagName)
	local ok = pcall(function()
		instance:RemoveTag(tagName)
	end)
	if not ok then
		CollectionService:RemoveTag(instance, tagName)
	end
end

function InstanceBase.new()
	local self = setmetatable({}, InstanceBase)
	self._maid = Maid.new()
	self.Instance = nil
	return self
end

function InstanceBase:_createInstance(template)
	if not template then
		return
	end

	local clone = template:Clone()
	clone.Parent = nil
	self.Instance = clone

	self._maid:GiveTask(function()
		if clone then
			clone:Destroy()
		end
	end)
end

function InstanceBase:SetParent(parent)
	if self.Instance then
		self.Instance.Parent = parent
	end
end

function InstanceBase:SetVisible(isVisible)
	if self.Instance and self.Instance:IsA("GuiObject") then
		self.Instance.Visible = isVisible == true
	end
end

function InstanceBase:SetLayoutOrder(order)
	if self.Instance and self.Instance:IsA("GuiObject") then
		self.Instance.LayoutOrder = order
	end
end

function InstanceBase:SetInstanceName(name)
	if self.Instance then
		self.Instance.Name = name
	end
end

function InstanceBase:GetRule(ruleName)
	return ThemeManager.getRule(ruleName)
end

function InstanceBase:GetPrimary()
	return ThemeManager.getPrimaryColor()
end

function InstanceBase:SetTags(tags)
	if not self.Instance or type(tags) ~= "table" then
		return
	end

	for _, tagName in ipairs(tags) do
		if type(tagName) == "string" then
			addTag(self.Instance, tagName)
		end
	end
end

function InstanceBase:RemoveTags(tags)
	if not self.Instance or type(tags) ~= "table" then
		return
	end

	for _, tagName in ipairs(tags) do
		if type(tagName) == "string" then
			removeTag(self.Instance, tagName)
		end
	end
end

function InstanceBase:_tween(instance, tweenInfo, properties)
	local target = instance or self.Instance
	if not target then
		return nil
	end

	local tween = TweenService:Create(target, tweenInfo, properties)
	tween:Play()
	self._maid:GiveTask(tween)
	return tween
end

function InstanceBase:Destroy()
	self._maid:DoCleaning()
	self.Instance = nil
end

return InstanceBase
