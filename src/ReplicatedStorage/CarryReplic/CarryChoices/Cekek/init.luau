-- location: ReplicatedStorage/CarryChoices/Cekek

local carryWeldModule = require(script.Parent.Parent.CarryRemotes.CarryWeld)

-- Posisi relatif antar pemain (cekek = di depan, sedikit ke bawah & condong ke kanan)
local calculatedCFrame =
	CFrame.new(0, 1.15, -1.7)
	* CFrame.fromEulerAnglesXYZ(math.rad(-25), math.rad(180), 0)

-- Animasi pembawa & yang dibawa (pastikan 2 StringValue ini ada di dalam module)
local animIdFirstPlayer = script:FindFirstChild("FirstAnim") and script.FirstAnim.Value or ""
local animIdSecondPlayer = script:FindFirstChild("SecondAnim") and script.SecondAnim.Value or ""

return function(args)
	if not args or not args.Players then
		warn("[CarryChoices-Cekek] Invalid args table")
		return nil
	end

	local firstPlayer = args.Players.First
	local secondPlayer = args.Players.Second
	if not (firstPlayer and secondPlayer) then
		warn("[CarryChoices-Cekek] Missing player references")
		return nil
	end

	-- Jalankan carry & dapatkan fungsi cleanup dari module utama
	local ok, cleanup = pcall(function()
		return carryWeldModule(
			firstPlayer,
			secondPlayer,
			nil,
			calculatedCFrame,
			animIdFirstPlayer,
			animIdSecondPlayer
		)
	end)

	if not ok then
		warn("[CarryChoices-Cekek] Carry module error:", cleanup)
		return nil
	end

	-- Wajib return cleanup supaya server bisa drop/decline dengan benar
	return cleanup
end
