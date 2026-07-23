-- CarryChoices.lua (Nyeret / Drag Carry Pose Module)
local carryWeldModule = require(script.Parent.Parent.CarryRemotes.CarryWeld)

-- Posisi relatif antar pemain (nyeret = korban di belakang bawah)
local calculatedCFrame =
	CFrame.new(-2.35, -2, 4.5)
	* CFrame.fromEulerAnglesXYZ(math.rad(-25), math.rad(180), 0)

-- Ambil animasi (StringValue di dalam module)
local firstPlayerAnimId = script:FindFirstChild("FirstAnim") and script.FirstAnim.Value or ""
local secondPlayerAnimId = script:FindFirstChild("SecondAnim") and script.SecondAnim.Value or ""

return function(args)
	if not args or not args.Players then
		warn("[CarryChoices-Nyeret] Invalid args table")
		return nil
	end

	local firstPlayer = args.Players.First
	local secondPlayer = args.Players.Second

	if not (firstPlayer and secondPlayer) then
		warn("[CarryChoices-Nyeret] Missing player references")
		return nil
	end

	-- Jalankan carry module dan dapatkan fungsi cleanup
	local ok, cleanup = pcall(function()
		return carryWeldModule(
			firstPlayer,
			secondPlayer,
			nil,
			calculatedCFrame,
			firstPlayerAnimId,
			secondPlayerAnimId
		)
	end)

	if not ok then
		warn("[CarryChoices-Nyeret] Carry module error:", cleanup)
		return nil
	end

	-- Harus return fungsi cleanup ke server supaya bisa drop/decline dengan bersih
	return cleanup
end
