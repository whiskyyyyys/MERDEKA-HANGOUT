-- KeyboardGui.client.lua  ->  LocalScript -> StarterGui/KeyboardGui
-- Script TERPISAH untuk mengelola KeyboardGUI (ScreenGui) yang dibuat manual.
-- Mengirim input ke GameGui via Attributes pada ScreenGui "GameGui".
--
-- Cara kerja:
--   Saat tombol huruf ditekan  -> set Attribute "_KB_Letter" = huruf
--   Saat tombol hapus ditekan  -> set Attribute "_KB_Backspace" = tick()
--   Saat tombol kirim ditekan  -> set Attribute "_KB_Submit" = tick()
--   GameGui.client.lua mendengarkan perubahan attribute tsb.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- =================================================================
-- CARI ScreenGui
-- =================================================================
local function waitForScreenGui(parent, name, timeout)
	local elapsed = 0
	while true do
		for _, child in ipairs(parent:GetDescendants()) do
			if child:IsA("ScreenGui") and child.Name == name then
				return child
			end
		end
		task.wait(0.1)
		elapsed = elapsed + 0.1
		if timeout and elapsed >= timeout then return nil end
	end
end

-- KeyboardGUI = ScreenGui yang kamu buat manual
-- Support beberapa nama agar aman saat UI di-rename di Studio.
local kbGui = waitForScreenGui(playerGui, "KeyboardGUI", 2)
	or waitForScreenGui(playerGui, "MobileKeyboard", 2)
	or waitForScreenGui(playerGui, "KeyboardGui", 2)

if not kbGui then
	-- Fallback: ambil ScreenGui pertama yang mengandung keyboard frame.
	for _, child in ipairs(playerGui:GetDescendants()) do
		if child:IsA("ScreenGui") then
			if child:FindFirstChild("MobileKeyboard")
				or child:FindFirstChild("MobileKeyborad")
				or child:FindFirstChild("KeyboardFrame") then
				kbGui = child
				break
			end
		end
	end
end

if not kbGui then
	warn("[KeyboardGui] ScreenGui keyboard tidak ditemukan (cek nama: KeyboardGUI/MobileKeyboard).")
	return
end

local function disableAutoLocalize(inst)
	if not inst then return end
	pcall(function()
		inst.AutoLocalize = false
	end)
end

disableAutoLocalize(kbGui)
for _, d in ipairs(kbGui:GetDescendants()) do
	disableAutoLocalize(d)
end
kbGui.DescendantAdded:Connect(disableAutoLocalize)

-- Pastikan keyboard ScreenGui full screen & no inset
kbGui.IgnoreGuiInset = true

local kbHolder = kbGui:FindFirstChild("MobileKeyboard")
	or kbGui:FindFirstChild("MobileKeyborad")
	or kbGui:FindFirstChild("KeyboardFrame")
	or kbGui
if not kbHolder then
	warn("[KeyboardGui] Container keyboard tidak ditemukan di ScreenGui keyboard!")
	return
end

-- Force full width supaya keyboard memenuhi layar kiri-kanan
if isMobile then
	kbHolder.Size = UDim2.new(1, 0, kbHolder.Size.Y.Scale, kbHolder.Size.Y.Offset)
	kbHolder.Position = UDim2.new(0, 0, kbHolder.Position.Y.Scale, kbHolder.Position.Y.Offset)
	kbHolder.AnchorPoint = Vector2.new(0, kbHolder.AnchorPoint.Y)
end

-- GameGui ScreenGui = target untuk komunikasi via Attributes
local gameGui = waitForScreenGui(playerGui, "GameGui", 10)
if not gameGui then
	warn("[KeyboardGui] ScreenGui 'GameGui' tidak ditemukan! Keyboard tidak bisa tersambung.")
	return
end

-- Tandai script keyboard utama aktif agar GameGui tidak perlu fallback binding.
gameGui:SetAttribute("_KB_Ready", true)

local typeSound = kbHolder:FindFirstChild("TypeSFX")
if not typeSound then
	-- Fallback mencoba cari di layar KeyboardGUI secara keseluruhan
	typeSound = kbGui:FindFirstChild("TypeSFX", true)
end

-- =================================================================
-- VISIBILITY: otomatis ikut giliran (diatur oleh GameGui via Attribute)
-- GameGui akan set Attribute "_KB_Show" = true/false
-- =================================================================
kbHolder.Visible = false

gameGui:GetAttributeChangedSignal("_KB_Show"):Connect(function()
	local show = gameGui:GetAttribute("_KB_Show")
	kbHolder.Visible = (show == true)
end)

-- Inisialisasi
local initShow = gameGui:GetAttribute("_KB_Show")
kbHolder.Visible = (initShow == true)

-- =================================================================
-- SAMBUNGKAN SEMUA TOMBOL
-- =================================================================
local function isDeleteButton(btn)
	local name = btn.Name:lower()
	if name == "backspace" or name == "delete" or name == "del" or name == "hapus" or name == "back" then
		return true
	end
	local text = (btn:IsA("TextButton") and btn.Text or ""):gsub("%s+", "")
	if text == "" then return false end
	local lower = text:lower()
	if lower == "del" or lower == "hapus" or lower == "backspace" or lower == "back" or lower == "delete" then
		return true
	end
	if text:find("\226\140\171") or text:find("\226\134\144") or text:find("\226\156\150") or text:find("\194\171") then
		return true
	end
	return false
end

local function isSubmitButton(btn)
	local name = btn.Name:lower()
	if name == "enter" or name == "submit" or name == "send" or name == "kirim" or name == "ok" then
		return true
	end
	local text = (btn:IsA("TextButton") and btn.Text or ""):gsub("%s+", "")
	if text == "" then return false end
	local lower = text:lower()
	if lower == "kirim" or lower == "enter" or lower == "send" or lower == "submit" or lower == "ok" then
		return true
	end
	if text:find("\226\134\181") or text:find("\226\156\147") or text:find("\226\156\148") then
		return true
	end
	return false
end

local function getButtonCharacter(btn)
	-- Pertama cari dari Text property
	if btn:IsA("TextButton") then
		local text = btn.Text or ""
		local trimmed = text:gsub("%s+", ""):gsub("<[^>]+>", "") -- buang whitespace & tag html
		if #trimmed == 1 and trimmed:match("[A-Za-z]") then
			return trimmed:lower()
		end
	end

	-- Kedua cari dari TextLabel di dalamnya
	local txtLabel = btn:FindFirstChildWhichIsA("TextLabel")
	if txtLabel then
		local t2 = txtLabel.Text or ""
		local trimmed2 = t2:gsub("%s+", ""):gsub("<[^>]+>", "")
		if #trimmed2 == 1 and trimmed2:match("[A-Za-z]") then
			return trimmed2:lower()
		end
	end

	-- Terakhir dari Nama tombol bila tepat 1 karakter (A-Z)
	if #btn.Name == 1 and btn.Name:match("[A-Za-z]") then
		return btn.Name:lower()
	end

	return nil
end

local connectedButtons = {}

local function connectButtons(parent)
	for _, btn in ipairs(parent:GetDescendants()) do
		if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and not connectedButtons[btn] then
			connectedButtons[btn] = true

			local charStr = getButtonCharacter(btn)

			if charStr then
				---------------------------------------------------
				-- TOMBOL HURUF (A-Z)
				---------------------------------------------------
				btn.MouseButton1Click:Connect(function()
					if typeSound then typeSound:Play() end
					gameGui:SetAttribute("_KB_Letter", charStr)
					-- Reset supaya bisa tekan huruf yang sama berulang
					task.defer(function()
						gameGui:SetAttribute("_KB_Letter", "")
					end)
				end)

			elseif isDeleteButton(btn) then
				---------------------------------------------------
				-- TOMBOL HAPUS (Backspace)
				---------------------------------------------------
				btn.MouseButton1Click:Connect(function()
					if typeSound then typeSound:Play() end
					gameGui:SetAttribute("_KB_Backspace", tick())
				end)

			elseif isSubmitButton(btn) then
				---------------------------------------------------
				-- TOMBOL KIRIM (Enter/Submit)
				---------------------------------------------------
				btn.MouseButton1Click:Connect(function()
					if typeSound then typeSound:Play() end
					gameGui:SetAttribute("_KB_Submit", tick())
				end)
			end
		end
	end
end

connectButtons(kbHolder)

-- Kalau ada tombol baru yang ditambahkan nanti (dynamic)
kbHolder.DescendantAdded:Connect(function(desc)
	if desc:IsA("TextButton") or desc:IsA("ImageButton") then
		task.spawn(function()
			for _ = 1, 5 do  -- tunggu sampai 5 frame agar GUI text/name termuat
				task.wait()
				if getButtonCharacter(desc) or isDeleteButton(desc) or isSubmitButton(desc) then
					break
				end
			end
			connectButtons(kbHolder)
		end)
	end
end)

