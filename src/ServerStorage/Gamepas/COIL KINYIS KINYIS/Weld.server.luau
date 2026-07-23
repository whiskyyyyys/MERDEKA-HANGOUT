local tool = script.Parent

-- Pastikan ada Handle
local handle = tool:WaitForChild("Handle")



-- =====================================
-- 2. Auto-Weld semua part model ke Handle
-- =====================================

for _, part in ipairs(tool:GetChildren()) do
	if part:IsA("BasePart") and part ~= handle then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = handle
		part.Anchored = false
		part.Massless = true
	end
end
