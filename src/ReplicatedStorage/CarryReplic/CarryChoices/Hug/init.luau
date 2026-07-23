-- CarryChoices.lua (Hug / Pelukan Pose Module)
local carryWeldModule = require(script.Parent.Parent.CarryRemotes.CarryWeld)

-- Posisi relatif antar pemain (model pelukan)
-- Dekat, sejajar sedikit ke depan
local calculatedCFrame =
	CFrame.new(0, 0.6, -1.2) * CFrame.fromEulerAnglesXYZ(math.rad(-25), math.rad(180), 0)

-- Ambil animasi dari StringValue dalam module
local firstPlayerAnimId = script:FindFirstChild("FirstAnim") and script.FirstAnim.Value or ""
local secondPlayerAnimId = script:FindFirstChild("SecondAnim") and script.SecondAnim.Value or ""

return function(args)
	if not args or not args.Players then
		warn("[CarryChoices-Hug] Invalid args table.")
		return nil
	end

	local firstPlayer = args.Players.First
	local secondPlayer = args.Players.Second

	if not (firstPlayer and secondPlayer) then
		warn("[CarryChoices-Hug] Missing player references.")
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
		warn("[CarryChoices-Hug] Carry module error:", cleanup)
		return nil
	end

	-- Return fungsi cleanup agar server bisa drop/decline
	return cleanup
end
