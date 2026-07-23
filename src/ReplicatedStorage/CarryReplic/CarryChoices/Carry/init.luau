-- CarryChoices.lua (Basic Carry / Front Lift Pose Module)
local carryWeldModule = require(script.Parent.Parent.CarryRemotes.CarryWeld)

-- Posisi relatif antar pemain (gendong depan netral)
local calculatedCFrame =
	CFrame.new(0, 2.5, 1.13)

-- Ambil animasi dari StringValue
local firstPlayerAnimId = script:FindFirstChild("FirstAnim") and script.FirstAnim.Value or ""
local secondPlayerAnimId = script:FindFirstChild("SecondAnim") and script.SecondAnim.Value or ""

return function(args)
	if not args or not args.Players then
		warn("[CarryChoices-Carry] Invalid args table")
		return nil
	end

	local firstPlayer = args.Players.First
	local secondPlayer = args.Players.Second

	if not (firstPlayer and secondPlayer) then
		warn("[CarryChoices-Carry] Missing player references")
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
		warn("[CarryChoices-Carry] Carry module error:", cleanup)
		return nil
	end

	-- Return cleanup supaya bisa dilepas drop/decline dengan bersih
	return cleanup
end
