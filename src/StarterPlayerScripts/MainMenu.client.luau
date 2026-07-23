-- ============================================================
-- MainMenu.client.luau
-- Topbar utama game — pakai TopbarPlus by ForeverHD
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Icon = require(ReplicatedStorage:WaitForChild("TopbarPlus"):WaitForChild("Icon"))

-- ─────────────────────────────────────────
-- KONFIGURASI ICON MENU
-- Ganti imageId sesuai game kamu
-- ─────────────────────────────────────────
local MENU_ITEMS = {
	{ imageId = "rbxassetid://108389261384111", action = "Settings"  }, -- gear
	{ imageId = "rbxassetid://116819039824541", action = "Shop"      }, -- shopping cart
	{ imageId = "rbxassetid://71915733910221", action = "Dance"     }, -- figure
	{ imageId = "rbxassetid://135488198321663", action = "Server"    }, -- globe
	{ imageId = "rbxassetid://89996216566721", action = "Redeem"    }, -- GANTI ID ICON REDEEM (KADO)
}

local GUI_MAP = {
	Settings = "Settings",
	Server   = "ServerListGui",
}

-- ─────────────────────────────────────────
-- FUNGSI BANTUAN FIX ID DECAL
-- ─────────────────────────────────────────
-- Jika Anda memasukkan ID dari link (Decal), fungsi ini otomatis mengubahnya 
-- menjadi Image agar bisa tampil.
local function fixId(idString)
	local id = string.match(idString, "%d+")
	if id then
		return "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150"
	end
	return idString
end

-- ─────────────────────────────────────────
-- TOPBARPLUS
-- ─────────────────────────────────────────

-- Buat sub-icons untuk fitur
local subIcons = {}

for _, item in ipairs(MENU_ITEMS) do
	local subIcon = Icon.new()
		:setImage(fixId(item.imageId))
		-- Perbesar gambar di dalamnya saja
		:modifyTheme({"IconImageScale", "Value", 0.9, "Deselected"})
		:modifyTheme({"IconImageScale", "Value", 0.9, "Selected"})
		-- Paksa gambar agar Fit (TIDAK GEPENG)
		:modifyTheme({"IconImage", "ScaleType", Enum.ScaleType.Fit, "Deselected"})
		:modifyTheme({"IconImage", "ScaleType", Enum.ScaleType.Fit, "Selected"})

	local guiName = GUI_MAP[item.action]
	local gui = nil
	local mainFrame = nil
	local toggleEvent = nil
	local syncEvent = nil

	-- Setup sinkronisasi dengan GUI
	task.spawn(function()
		if guiName then
			gui = playerGui:WaitForChild(guiName, 5)
			if gui then
				if guiName == "ServerListGui" then
					mainFrame = gui:WaitForChild("main", 3)
					if mainFrame then
						mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
							if mainFrame.Visible then
								gui.Enabled = true
								subIcon:select()
							else
								subIcon:deselect()
							end
						end)
					end
				else
					gui:GetPropertyChangedSignal("Enabled"):Connect(function()
						if gui.Enabled then
							subIcon:select()
						else
							subIcon:deselect()
						end
					end)
				end
			end
		elseif item.action == "Shop" then
			local shopGui = playerGui:WaitForChild("Shop", 5)
			if shopGui then
				toggleEvent = shopGui:WaitForChild("ToggleEvent", 5)
				syncEvent = shopGui:WaitForChild("SyncEvent", 5)
				
				if syncEvent then
					syncEvent.Event:Connect(function(isOpen)
						if isOpen then
							subIcon:select()
						else
							subIcon:deselect()
						end
					end)
				end
			end
		end
	end)

	subIcon:bindEvent("selected", function()
		if guiName == "ServerListGui" then
			local currentGui = playerGui:FindFirstChild(guiName)
			if currentGui then
				local mFrame = currentGui:FindFirstChild("main")
				if mFrame then mFrame.Visible = true end
				currentGui.Enabled = true
			end
		elseif guiName then
			local currentGui = playerGui:FindFirstChild(guiName)
			if currentGui then
				local toggle = currentGui:FindFirstChild("ToggleEvent")
				if toggle then
					toggle:Fire(true)
				else
					currentGui.Enabled = true
				end
			end
		elseif item.action == "Shop" then
			local shopGui = playerGui:FindFirstChild("Shop")
			if shopGui then
				local toggle = shopGui:FindFirstChild("ToggleEvent")
				if toggle then toggle:Fire(true) end
			end
		elseif item.action == "Redeem" then
			local toggle = ReplicatedStorage:FindFirstChild("ToggleRedeemGUI")
			if toggle then toggle:Fire(true) end
		elseif item.action == "Dance" then
			local danceMain = require(game:GetService("ReplicatedStorage"):WaitForChild("DanceMenuManager"):WaitForChild("DanceMain"))
			if danceMain and danceMain.toggleMenu then
				danceMain.toggleMenu()
				local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
				local menus = pg and pg:FindFirstChild("InGame") and pg.InGame:FindFirstChild("Menus")
				local dances = menus and menus:FindFirstChild("Dances")
				if dances then
					if dances:FindFirstChild("Dances") then dances.Dances.Visible = true end
					if dances:FindFirstChild("Titles") then dances.Titles.Visible = true end
				end
			end
		end
	end)

	subIcon:bindEvent("deselected", function()
		subIcon:setLabel("") 

		if guiName == "ServerListGui" then
			local currentGui = playerGui:FindFirstChild(guiName)
			if currentGui then
				local mFrame = currentGui:FindFirstChild("main")
				if mFrame then mFrame.Visible = false end
			end
		elseif guiName then
			local currentGui = playerGui:FindFirstChild(guiName)
			if currentGui then
				local toggle = currentGui:FindFirstChild("ToggleEvent")
				if toggle then
					toggle:Fire(false)
				else
					currentGui.Enabled = false
				end
			end
		elseif item.action == "Shop" then
			local shopGui = playerGui:FindFirstChild("Shop")
			if shopGui then
				local toggle = shopGui:FindFirstChild("ToggleEvent")
				if toggle then toggle:Fire(false) end
			end
		elseif item.action == "Redeem" then
			local toggle = ReplicatedStorage:FindFirstChild("ToggleRedeemGUI")
			if toggle then toggle:Fire(false) end
		elseif item.action == "Dance" then
			local danceMain = require(game:GetService("ReplicatedStorage"):WaitForChild("DanceMenuManager"):WaitForChild("DanceMain"))
			if danceMain and danceMain.toggleMenu then
				danceMain.toggleMenu()
			end
		end
	end)

	table.insert(subIcons, subIcon)
end

local mainIcon = Icon.new()
	:setLeft() -- Taruh di kiri, menyatu dengan icon bawaan Roblox
	:setImage(fixId("rbxassetid://136580800453923"), "Deselected") -- Logo kotak 4 (Deselected)
	:setImage(fixId("rbxassetid://3926305708"), "Selected")   -- Logo "X" (Selected) saat menu kebuka
	-- Perbesar gambar di dalamnya saja
	:modifyTheme({"IconImageScale", "Value", 0.9, "Deselected"})
	:modifyTheme({"IconImageScale", "Value", 0.9, "Selected"})
	:setMenu(subIcons) -- Otomatis buat animasi menu yang menyatu, persis kayak di gambar

print("[MainMenu] TopbarPlus Menu siap!")
