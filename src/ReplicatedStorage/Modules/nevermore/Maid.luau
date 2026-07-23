local Maid = {}
Maid.__index = Maid

local function cleanTask(taskItem)
	local itemType = typeof(taskItem)
	if itemType == "RBXScriptConnection" then
		if taskItem.Connected then
			taskItem:Disconnect()
		end
		return
	end

	if itemType == "Instance" then
		taskItem:Destroy()
		return
	end

	if itemType == "function" then
		taskItem()
		return
	end

	if itemType == "thread" then
		task.cancel(taskItem)
		return
	end

	if itemType == "table" then
		if type(taskItem.Destroy) == "function" then
			taskItem:Destroy()
			return
		end
		if type(taskItem.DoCleaning) == "function" then
			taskItem:DoCleaning()
			return
		end
		if type(taskItem.Disconnect) == "function" then
			taskItem:Disconnect()
			return
		end
		if type(taskItem.Cancel) == "function" then
			taskItem:Cancel()
			return
		end
		if type(taskItem.cancel) == "function" then
			taskItem:cancel()
			return
		end
	end
end

function Maid.new()
	local self = setmetatable({}, Maid)
	self._tasks = {}
	return self
end

function Maid:GiveTask(taskItem)
	table.insert(self._tasks, taskItem)
	return taskItem
end

function Maid:DoCleaning()
	for index = #self._tasks, 1, -1 do
		local taskItem = self._tasks[index]
		self._tasks[index] = nil
		local ok, err = pcall(cleanTask, taskItem)
		if not ok then
			warn("[Maid] Failed to clean task:", err)
		end
	end
end

function Maid:Destroy()
	self:DoCleaning()
end

return Maid
