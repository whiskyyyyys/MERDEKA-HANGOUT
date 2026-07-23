local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events

local module = {}

function module.FetchSettings()
	local SettingsData = events.Modules.Settings.FetchSettings:InvokeServer()
	if not SettingsData then return end
	
	return SettingsData
end

function module.FetchDefaultSettings()
	return {
		Playback = {
			Crossfade = {
				Enabled = true,
				Duration = 3
			},

			Equalizer = {
				Enabled = false,
				HighGain = 0,
				MidGain = 0,
				LowGain = 0
			},
		},

		Extras = {
			Glow = true,
			PlaybackHaptics = false,
		},

		Socials = {
			ListeningVisibility = true,
			Sharing = true,
		},
	}
end

return module