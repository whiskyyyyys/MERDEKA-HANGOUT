local part = script.Parent
local TweenService = game:GetService("TweenService")

local colors = {
	Color3.fromRGB(255, 255, 255), -- putih
	Color3.fromRGB(255, 0, 255)  -- pink muda
}

local tweenInfo = TweenInfo.new(
	3, -- durasi transisi (detik)
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1, -- loop
	true -- bolak-balik
)

local tween = TweenService:Create(part, tweenInfo, {
	Color = colors[2]
})

part.Color = colors[1]
tween:Play()
