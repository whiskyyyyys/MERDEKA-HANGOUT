local module = {}

local STYLE_MULTIPLIERS = {
	Linear = 2,
	Sine = 7,
	Exponential = 8,
	Back = 14
}

function module.ApproachInHeartbeat(Instance: Instance, Property: string, Target, DeltaTime, Info: TweenInfo)
	local Current = Instance[Property]
	local Style = Info.EasingStyle.Name
	local Time = math.max(Info.Time, .01)
	local BaseSnappiness = STYLE_MULTIPLIERS[Style] or STYLE_MULTIPLIERS.Sine
	local Snappiness = (1 / Time) * BaseSnappiness
	local Alpha = 1 - math.exp(-Snappiness * DeltaTime)

	local DataType = typeof(Current)

	if DataType == "number" then
		Instance[Property] = Current + (Target - Current) * Alpha

	elseif DataType == "UDim2" or DataType == "Vector2" or DataType == "Vector3" or DataType == "Color3" then
		Instance[Property] = Current:Lerp(Target, Alpha)

	elseif DataType == "UDim" then
		local NewScale = Current.Scale + (Target.Scale - Current.Scale) * Alpha
		local NewOffset = Current.Offset + (Target.Offset - Current.Offset) * Alpha
		
		Instance[Property] = UDim.new(NewScale, NewOffset)

	else
		Instance[Property] = Target
	end
end

return module