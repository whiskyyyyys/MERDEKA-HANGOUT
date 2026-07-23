-- CarryChoices.lua (Bridal / Carry Pose Module)
local carryWeldModule = require(script.Parent.Parent.CarryRemotes.CarryWeld)


-- Posisi relatif antar pemain (atur sesuai animasi)
local calculatedCFrame = CFrame.new(-0.3, -0.3, -1) * CFrame.fromEulerAnglesXYZ(math.rad(90), math.rad(-40), math.rad(80))

-- Animasi pembawa dan yang dibawa
local animIdFirstPlayer = script:FindFirstChild("FirstAnim") and script.FirstAnim.Value or ""
local animIdSecondPlayer = script:FindFirstChild("SecondAnim") and script.SecondAnim.Value or ""

return function(args)
	if not args or not args.Players then
		warn("[CarryChoices] Invalid args table")
		return nil
	end

	local firstPlayer = args.Players.First
	local secondPlayer = args.Players.Second

	if not (firstPlayer and secondPlayer) then
		warn("[CarryChoices] Missing player references")
		return nil
	end

	-- Jalankan carry module dan dapatkan fungsi cleanup
	local ok, cleanup = pcall(function()
		return carryWeldModule(firstPlayer, secondPlayer, nil, calculatedCFrame, animIdFirstPlayer, animIdSecondPlayer)
	end)

	if not ok then
		warn("[CarryChoices] Carry module error:", cleanup)
		return nil
	end

	-- Harus return fungsi cleanup ke server biar bisa dilepas pas drop/decline
	return cleanup
end
