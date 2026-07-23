local Tool = script.Parent
local Players = game:GetService("Players")
local Globo  = Tool:WaitForChild("Globo")
local Handle = Tool:WaitForChild("Handle")

local currentPlayer = nil
local STRING_LENGTH = 4.5
local rope = Globo:FindFirstChildWhichIsA("RopeConstraint")

-- ==================== WELD HELPER ====================
local function addWeld()
	local old = Globo:FindFirstChild("GloboWeld")
	if old then old:Destroy() end
	Globo.CFrame = Handle.CFrame + Vector3.new(0, STRING_LENGTH, 0)
	Globo.AssemblyLinearVelocity  = Vector3.zero
	Globo.AssemblyAngularVelocity = Vector3.zero
	local weld  = Instance.new("WeldConstraint")
	weld.Name   = "GloboWeld"
	weld.Part0  = Globo
	weld.Part1  = Handle
	weld.Parent = Globo
	Globo.Anchored = false
	if rope then rope.Enabled = false end
end

local function removeWeld()
	local weld = Globo:FindFirstChild("GloboWeld")
	if weld then weld:Destroy() end
	Globo.AssemblyLinearVelocity  = Vector3.zero
	Globo.AssemblyAngularVelocity = Vector3.zero
	if rope then rope.Enabled = true end
end

local function applyThemeColor(player)
	local colorHex = player:GetAttribute("ToolColor")
	if not colorHex then return end
	local ok, color = pcall(Color3.fromHex, colorHex)
	if ok then Globo.Color = color end
end

local function resetHumanoid(character)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = false
		humanoid.JumpPower    = 50
	end
end

addWeld()

task.defer(function()
	local parent = Tool.Parent
	local player
	if parent then
		player = Players:GetPlayerFromCharacter(parent)
		if not player and parent:IsA("Backpack") then
			player = parent.Parent
		end
	end
	if player then
		applyThemeColor(player)
		player:GetAttributeChangedSignal("ToolColor"):Connect(function()
			applyThemeColor(player)
		end)
	end
end)

-- ==================== EVENT TOOL ====================
Tool.Equipped:Connect(function()
	local character = Tool.Parent
	currentPlayer = Players:GetPlayerFromCharacter(character)
	if not currentPlayer then return end
	applyThemeColor(currentPlayer)
	removeWeld()

	-- ✅ HAPUS workspace.Gravity di sini — client yang handle
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower    = 12
	end
end)

Tool.Unequipped:Connect(function()
	addWeld()

	-- ✅ HAPUS workspace.Gravity di sini
	if currentPlayer and currentPlayer.Character then
		resetHumanoid(currentPlayer.Character)
	end
	currentPlayer = nil
end)

Tool:GetPropertyChangedSignal("Parent"):Connect(function()
	local parent = Tool.Parent
	if not parent then
		Globo.Anchored = false
		addWeld()
	end

	-- ✅ Kalau tool balik ke backpack saat respawn, reset humanoid
	local character = currentPlayer and currentPlayer.Character
	if character and not Players:GetPlayerFromCharacter(parent) then
		resetHumanoid(character)
		currentPlayer = nil
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if player == currentPlayer then
		Globo.Anchored = false
		addWeld()
		currentPlayer = nil
	end
end)