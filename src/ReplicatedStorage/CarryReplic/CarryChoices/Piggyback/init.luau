local carryWeldModule = require(script.Parent.Parent.CarryRemotes.CarryWeld)

-- Piggyback: sedikit di atas dan di belakang pembawa
local calculatedCFrame =
	CFrame.new(0, 1.18, 1.04)

local animIdFirstPlayer = script:FindFirstChild("FirstAnim") and script.FirstAnim.Value or ""
local animIdSecondPlayer = script:FindFirstChild("SecondAnim") and script.SecondAnim.Value or ""

return function(args)
	if not args or not args.Players then
		warn("[CarryChoices-Piggyback] Invalid args table")
		return nil
	end

	local firstPlayer = args.Players.First
	local secondPlayer = args.Players.Second

	if not (firstPlayer and secondPlayer) then
		warn("[CarryChoices-Piggyback] Missing player references")
		return nil
	end

	-- Jalankan carry module dan dapatkan fungsi cleanup
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
		warn("[CarryChoices-Piggyback] Carry module error:", cleanup)
		return nil
	end

	-- Harus return fungsi cleanup ke server biar bisa dilepas pas drop/decline
	return cleanup
end
