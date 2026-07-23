local tool = script.Parent

local function setGripActive(char, active)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		
		-- Jika active == true → mainkan animasi grip
		-- Jika active == false → hentikan animasi grip
		if active then
			local gripAnim = Instance.new("Animation")
			gripAnim.AnimationId = "rbxassetid://<ID_ANIMASI_GRIP>"
			local gripTrack = animator:LoadAnimation(gripAnim)
			gripTrack.Name = "GripTrack"
			gripTrack:Play()
		else
			-- Hentikan semua animasi grip yang masih aktif
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if track.Name == "GripTrack" then
					track:Stop()
					track:Destroy()
				end
			end
		end
	end
end

tool.Equipped:Connect(function()
	local char = tool.Parent
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local handleRight = tool:FindFirstChild("HandleRight")
	if handleRight then
		local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		if rightHand then
			local weldR = Instance.new("Motor6D")
			weldR.Name = "RightGripCustom"
			weldR.Part0 = rightHand
			weldR.Part1 = handleRight
			weldR.C0 = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(30), 0, 0)
			weldR.Parent = rightHand
		end
	end

	local handleLeft = tool:FindFirstChild("HandleLeft")
	if handleLeft then
		local leftHand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
		if leftHand then
			local weldL = Instance.new("Motor6D")
			weldL.Name = "LeftGrip"
			weldL.Part0 = leftHand
			weldL.Part1 = handleLeft
			weldL.C0 = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(30), 0, 0)
			weldL.Parent = leftHand
		end
	end

	-- Aktifkan animasi grip
	setGripActive(char, true)
end)

tool.Unequipped:Connect(function()
	local char = tool.Parent
	if char then
		-- Matikan animasi grip
		setGripActive(char, false)

		-- Hapus weld grip dari tangan
		for _, limb in ipairs({"RightHand","Right Arm","LeftHand","Left Arm"}) do
			local part = char:FindFirstChild(limb)
			if part then
				for _,v in ipairs(part:GetChildren()) do
					if v:IsA("Motor6D") and (v.Name == "RightGripCustom" or v.Name == "LeftGrip") then
						v:Destroy()
					end
				end
			end
		end
	end
end)
