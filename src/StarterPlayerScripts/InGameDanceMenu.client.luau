-- InGame Dance bootstrap using ReplicatedStorage.DanceMenuManager
-- This replaces the previous custom fallback GUI toggle flow.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local connectionManager = require(modulesFolder:WaitForChild("ConnectionManager"))
local danceMenuManager = require(ReplicatedStorage:WaitForChild("DanceMenuManager"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local emoteRemotesFolder = remotesFolder and remotesFolder:FindFirstChild("EmoteRemotes")
local loadFavoritesRemote = emoteRemotesFolder and emoteRemotesFolder:FindFirstChild("LoadFavorites")
local saveFavoriteRemote = emoteRemotesFolder and emoteRemotesFolder:FindFirstChild("SaveFavorite")

local syncRemote = ReplicatedStorage:FindFirstChild("Sync")
local syncStatusRemote = ReplicatedStorage:FindFirstChild("SyncStatus")

-- NEW: SyncAnimTime for exact timeposition replication
local syncAnimTimeRemote = remotesFolder and remotesFolder:FindFirstChild("SyncAnimTime")
if not syncAnimTimeRemote then
	syncAnimTimeRemote = Instance.new("RemoteEvent")
	syncAnimTimeRemote.Name = "SyncAnimTime"
	syncAnimTimeRemote.Parent = remotesFolder or ReplicatedStorage
end

local emotesFolder = ReplicatedStorage:WaitForChild("Emotes")
local posesFolder = ReplicatedStorage:FindFirstChild("Poses")

local CONFIG = {
	AnimationPriority = Enum.AnimationPriority.Action4,
	DefaultLooped = true,
	StartFadeTime = 0.16,
	SwitchInFadeTime = 0.14,
	SwitchOutFadeTime = 0.14,
	SpamFadeTime = 0.01,
	StopFadeTime = 0.24,
	StopOnSameEmoteMinPlayTime = 0.22,
	PreloadAssets = true,
	PreloadTracksOnCharacter = true,
	PreloadBatchSize = 20,
}

local animationByName = {}
local categoryByName = {}
local favoritesByName = {}
local loadedTracks = {}

local currentTrack = nil
local currentTrackName = nil
local lastEmoteStartAt = 0
local suppressedAnimateScript = nil
local suppressedAnimateWasDisabled = nil
local manualMenuAnimating = false
local manualMenuOpen = false
local MANUAL_CLOSED_POSITION = UDim2.new(0, -10, 0.5, 0)
local preloadJobId = 0
local leaveSync

local function resolveDanceMenuNodes()
	local inGame = playerGui:FindFirstChild("InGame") or playerGui:WaitForChild("InGame", 10)
	if not inGame then
		return nil, nil, nil, nil, nil
	end

	local menus = inGame:FindFirstChild("Menus") or inGame:WaitForChild("Menus", 10)
	if not menus then
		return inGame, nil, nil, nil, nil
	end

	local menuFrame = menus:FindFirstChild("Dances") or menus:WaitForChild("Dances", 10)
	local listFrame = menuFrame and (menuFrame:FindFirstChild("Dances") or menuFrame:WaitForChild("Dances", 10))
	local titlesFrame = menuFrame and (menuFrame:FindFirstChild("Titles") or menuFrame:WaitForChild("Titles", 10))
	return inGame, menus, menuFrame, listFrame, titlesFrame
end

local function hasValidAnimationId(animation)
	if not animation or not animation:IsA("Animation") then
		return false
	end

	local animationId = animation.AnimationId
	if typeof(animationId) ~= "string" or animationId == "" then
		return false
	end

	return string.find(animationId, "%d") ~= nil
end

local function cleanupLegacyDanceOverlay()
	local oldOverlay = playerGui:FindFirstChild("DanceToggleOverlay")
	if oldOverlay then
		oldOverlay:Destroy()
	end
end

local function tryManagerToggle()
	if danceMenuManager and danceMenuManager.toggleMenu then
		local ok = danceMenuManager.toggleMenu()
		if ok then
			local _, _, _, listFrame, titlesFrame = resolveDanceMenuNodes()
			if listFrame and listFrame:IsA("GuiObject") then
				listFrame.Visible = true
			end
			if titlesFrame and titlesFrame:IsA("GuiObject") then
				titlesFrame.Visible = true
			end
			return true
		end
	end
	return false
end

local function fallbackManualToggle()
	local _, _, menuFrame = resolveDanceMenuNodes()
	if not menuFrame or not menuFrame:IsA("GuiObject") then
		return false
	end
	
	menuFrame.Visible = not menuFrame.Visible
	StarterGui:SetAttribute("DanceMenuOpen", menuFrame.Visible)
	return true
end

local function requestMenuToggle(sourceName)
	if tryManagerToggle() then
		return
	end
	local fallbackOk = fallbackManualToggle()
	if not fallbackOk then
		warn("[InGameDance] Toggle failed from:", sourceName)
	end
end

local function connectInGameTopButtonToDanceQuit()
	local inGame, menus, _, listFrame = resolveDanceMenuNodes()
	if not inGame then
		return
	end
	if not menus then
		return
	end
	if listFrame then
		print("[InGameDance] list target:", listFrame:GetFullName())
	end

	local seenButtons = {}
	local function connectCandidate(button, sourceName)
		if not button or not button:IsA("GuiButton") or seenButtons[button] then
			return
		end

		seenButtons[button] = true
		button.Activated:Connect(function()
			requestMenuToggle(sourceName or button:GetFullName())
		end)
		print("[InGameDance] connected toggle:", sourceName or button:GetFullName())
	end

	local function connectTopBarButton()
		local mainMenu = menus:FindFirstChild("Main")
		local top = mainMenu and mainMenu:FindFirstChild("Top")
		local topScrolling = top and top:FindFirstChild("ScrollingFrame")
		if not topScrolling then
			return
		end
		connectCandidate(topScrolling:FindFirstChild("button"), "InGame.Top.button")
	end

	local function connectLegacyEmoteButton()
		local legacyGui = playerGui:FindFirstChild("EmoteSystemGui")
		local legacyScript = legacyGui and legacyGui:FindFirstChild("EmoteSystemClient")
		if legacyScript and legacyScript:IsA("LocalScript") then
			legacyScript.Disabled = true
		end
		local legacyMainFrame = legacyGui and legacyGui:FindFirstChild("MainFrame")
		if legacyMainFrame and legacyMainFrame:IsA("GuiObject") then
			legacyMainFrame.Visible = false
		end
		local legacyButton = legacyGui and legacyGui:FindFirstChild("EmoteButton")
		connectCandidate(legacyButton, "EmoteSystemGui.EmoteButton")
	end

	local function watchContainer(containerName, sourceName)
		local container = inGame:FindFirstChild(containerName)
		if not container then
			return
		end

		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("GuiButton") then
				connectCandidate(descendant, sourceName)
				break
			end
		end

		container.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("GuiButton") then
				connectCandidate(descendant, sourceName)
			end
		end)
	end

	connectTopBarButton()
	connectLegacyEmoteButton()

	menus.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("GuiButton") and descendant.Name == "button" then
			local parent = descendant.Parent
			local grandParent = parent and parent.Parent
			if parent and parent.Name == "ScrollingFrame" and grandParent and grandParent.Name == "Top" then
				connectCandidate(descendant, "InGame.Top.button.dynamic")
			end
		end
	end)

	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "EmoteSystemGui" then
			task.defer(connectLegacyEmoteButton)
		end
	end)

	watchContainer("RblxButtons", "InGame.RblxButtons")
	watchContainer("RblxButtons2", "InGame.RblxButtons2")
end

local function getAnimator()
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

local function isR6Character(character, humanoid)
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
		return true
	end

	return character
		and character:FindFirstChild("Torso") ~= nil
		and character:FindFirstChild("UpperTorso") == nil
end

local function setDefaultAnimateSuppressed(character, shouldSuppress)
	local animateScript = character and character:FindFirstChild("Animate")

	if not shouldSuppress then
		if suppressedAnimateScript and suppressedAnimateScript.Parent then
			suppressedAnimateScript.Disabled = suppressedAnimateWasDisabled == true
		end
		suppressedAnimateScript = nil
		suppressedAnimateWasDisabled = nil
		return
	end

	if not animateScript or not animateScript:IsA("BaseScript") then
		return
	end

	if suppressedAnimateScript ~= animateScript then
		suppressedAnimateScript = animateScript
		suppressedAnimateWasDisabled = animateScript.Disabled
	end
	animateScript.Disabled = true
end

local function stopCompetingTracks(animator, keepTrack, fadeTime)
	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track ~= keepTrack then
			pcall(function()
				track:Stop(fadeTime or 0)
			end)
		end
	end
end

local function applyAutoSyncToTrack(track)
	if not track then return end
	
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local myAnimId = track.Animation and track.Animation.AnimationId
	
	local synced = false
	local targetSyncPlayer = nil
	
	if hrp and myAnimId then
		local Players = game:GetService("Players")
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= Players.LocalPlayer and otherPlayer.Character then
				local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
				local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
				local otherAnimator = otherHum and otherHum:FindFirstChild("Animator")
				
				if otherHrp and otherAnimator and (otherHrp.Position - hrp.Position).Magnitude <= 15 then
					for _, otherTrack in ipairs(otherAnimator:GetPlayingAnimationTracks()) do
						if otherTrack.Animation and otherTrack.Animation.AnimationId == myAnimId then
							track.TimePosition = otherTrack.TimePosition
							synced = true
							targetSyncPlayer = otherPlayer
							break
						end
					end
				end
			end
			if synced then break end
		end
	end
	
	if not synced then
		track.TimePosition = 0
	else
		if syncAnimTimeRemote and myAnimId and targetSyncPlayer then
			pcall(function()
				syncAnimTimeRemote:FireServer(myAnimId, targetSyncPlayer)
			end)
		end
	end
end

local function forceR6DanceTrack(track, fadeTime)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not isR6Character(character, humanoid) then
		return
	end

	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator or not track then
		return
	end

	setDefaultAnimateSuppressed(character, true)
	stopCompetingTracks(animator, track, fadeTime or CONFIG.SpamFadeTime)

	pcall(function()
		track.Priority = CONFIG.AnimationPriority
		track.Looped = CONFIG.DefaultLooped
		if not track.IsPlaying then
			track:Play(fadeTime or CONFIG.SpamFadeTime, 1, 1)
		end
		applyAutoSyncToTrack(track)
		track:AdjustSpeed(1)
	end)

	task.defer(function()
		if currentTrack == track and track.IsPlaying then
			stopCompetingTracks(animator, track, 0)
		end
	end)
end

local function preloadAnimationAssets()
	if not CONFIG.PreloadAssets then
		return
	end

	local assets = {}
	for _, animation in pairs(animationByName) do
		table.insert(assets, animation)
	end
	if #assets == 0 then
		return
	end

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
	end)
end

local function preloadTracksForCharacterAsync()
	if not CONFIG.PreloadTracksOnCharacter then
		return
	end

	preloadJobId += 1
	local jobId = preloadJobId

	task.spawn(function()
		for _ = 1, 120 do
			if jobId ~= preloadJobId then
				return
			end

			local animator = getAnimator()
			if animator then
				local loadedCount = 0
				for name, animation in pairs(animationByName) do
					if jobId ~= preloadJobId then
						return
					end

					if not loadedTracks[name] then
						local ok, track = pcall(function()
							return animator:LoadAnimation(animation)
						end)
						if ok and track then
							track.Priority = CONFIG.AnimationPriority
							track.Looped = CONFIG.DefaultLooped
							loadedTracks[name] = track
							loadedCount += 1
							if loadedCount % CONFIG.PreloadBatchSize == 0 then
								task.wait()
							end
						end
					end
				end
				return
			end

			task.wait(0.1)
		end
	end)
end

local function stopCurrentTrack(fadeTime)
	if currentTrack and currentTrack.IsPlaying then
		pcall(function()
			currentTrack:Stop(fadeTime or CONFIG.StopFadeTime)
		end)
	end

	currentTrack = nil
	currentTrackName = nil
	lastEmoteStartAt = 0
	setDefaultAnimateSuppressed(player.Character, false)
	player:SetAttribute("DanceName", "")
end

local function getOrLoadTrack(name)
	local track = loadedTracks[name]
	if track then
		return track
	end

	local animator = getAnimator()
	local animation = animationByName[name]
	if not animator or not animation then
		return nil
	end

	local ok, loadedTrack = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not loadedTrack then
		return nil
	end

	loadedTrack.Priority = CONFIG.AnimationPriority
	loadedTrack.Looped = CONFIG.DefaultLooped
	loadedTracks[name] = loadedTrack
	return loadedTrack
end

local function playAnimationByName(name)
	if player:GetAttribute("onSync") == true then
		leaveSync()
		stopCurrentTrack(CONFIG.SwitchOutFadeTime)
	end

	local track = getOrLoadTrack(name)
	if not track then
		return false
	end

	local now = os.clock()
	local isSameTrack = currentTrack == track and track.IsPlaying

	if isSameTrack and (now - lastEmoteStartAt) >= CONFIG.StopOnSameEmoteMinPlayTime then
		stopCurrentTrack(CONFIG.StopFadeTime)
		return true
	end

	local forceFadeTime = CONFIG.StartFadeTime
	if currentTrack and currentTrack ~= track and currentTrack.IsPlaying then
		forceFadeTime = CONFIG.SwitchInFadeTime
		pcall(function()
			track:Play(CONFIG.SwitchInFadeTime, 1, 1)
			applyAutoSyncToTrack(track)
			track:AdjustSpeed(1)
		end)
		pcall(function()
			currentTrack:Stop(CONFIG.SwitchOutFadeTime)
		end)
	elseif track.IsPlaying then
		forceFadeTime = CONFIG.SpamFadeTime
		pcall(function()
			applyAutoSyncToTrack(track)
			track:AdjustSpeed(1)
		end)
	else
		forceFadeTime = CONFIG.StartFadeTime
		pcall(function()
			track:Play(CONFIG.StartFadeTime, 1, 1)
			applyAutoSyncToTrack(track)
			track:AdjustSpeed(1)
		end)
	end

	if isSameTrack then
		pcall(function()
			track:Play(CONFIG.SpamFadeTime, 1, 1)
		end)
	end

	currentTrack = track
	currentTrackName = name
	lastEmoteStartAt = now
	forceR6DanceTrack(track, forceFadeTime)
	player:SetAttribute("DanceName", name)
	return true
end

local function getFavoriteListForMenu()
	local result = {}
	for name, isFavorite in pairs(favoritesByName) do
		if isFavorite and animationByName[name] then
			table.insert(result, name)
		end
	end
	table.sort(result, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	return result
end

local function syncFavoritesToMenu()
	danceMenuManager.setFavoriteDances(getFavoriteListForMenu())
end

local function applyFavoritesPayload(payload)
	table.clear(favoritesByName)

	if typeof(payload) ~= "table" then
		syncFavoritesToMenu()
		return
	end

	local function readList(list)
		if typeof(list) ~= "table" then
			return
		end
		for _, animationName in ipairs(list) do
			if typeof(animationName) == "string" and animationByName[animationName] then
				favoritesByName[animationName] = true
			end
		end
	end

	readList(payload.dances or payload.Dances or payload.dance)
	readList(payload.poses or payload.Poses or payload.pose)
	syncFavoritesToMenu()
end

local function favoriteAnimationByName(name)
	if typeof(name) ~= "string" or not animationByName[name] then
		return false
	end

	local nextState = not (favoritesByName[name] == true)
	favoritesByName[name] = nextState
	syncFavoritesToMenu()

	if saveFavoriteRemote and saveFavoriteRemote:IsA("RemoteEvent") then
		local category = categoryByName[name] or "dance"
		task.spawn(function()
			saveFavoriteRemote:FireServer(name, category)
		end)
	end

	return nextState
end

leaveSync = function()
	if syncRemote and syncRemote:IsA("RemoteEvent") then
		pcall(function()
			syncRemote:FireServer(nil, "unsync")
		end)
	end
	player:SetAttribute("onSync", false)
end

local function buildDanceEntries()
	table.clear(animationByName)
	table.clear(categoryByName)

	local entries = {}
	local nextCreatedAt = 1

	local function addFromFolder(folder, category)
		if not folder then
			return
		end

		for _, animation in ipairs(folder:GetChildren()) do
			if animation:IsA("Animation") and hasValidAnimationId(animation) and not animationByName[animation.Name] then
				animationByName[animation.Name] = animation
				local normalizedCategory = string.lower(tostring(category or "dance"))
				if normalizedCategory ~= "pose" then
					normalizedCategory = "dance"
				end
				categoryByName[animation.Name] = normalizedCategory
				table.insert(entries, {
					Name = animation.Name,
					createdAt = animation:GetAttribute("createdAt") or nextCreatedAt,
					Category = normalizedCategory,
				})
				nextCreatedAt += 1
			end
		end
	end

	addFromFolder(emotesFolder, "dance")
	addFromFolder(posesFolder, "pose")

	table.sort(entries, function(a, b)
		return string.lower(a.Name) < string.lower(b.Name)
	end)

	return entries
end

local function loadFavoritesFromServer()
	if not loadFavoritesRemote or not loadFavoritesRemote:IsA("RemoteFunction") then
		return
	end

	task.spawn(function()
		local ok, result = pcall(function()
			return loadFavoritesRemote:InvokeServer()
		end)
		if ok then
			applyFavoritesPayload(result)
		end
	end)
end

local animationHandlerProvider = {}

function animationHandlerProvider:playAnimation(animationName)
	return playAnimationByName(animationName)
end

function animationHandlerProvider:favoriteAnimation(animationName)
	return favoriteAnimationByName(animationName)
end

function animationHandlerProvider:leaveSync()
	leaveSync()
	return true
end

function animationHandlerProvider:changeSeatAnimation(_)
	return true
end

connectionManager.addProvider("animationHandler", animationHandlerProvider)

cleanupLegacyDanceOverlay()
connectInGameTopButtonToDanceQuit()

local danceEntries = buildDanceEntries()
danceMenuManager.setDances(danceEntries)
syncFavoritesToMenu()
loadFavoritesFromServer()
preloadAnimationAssets()

if saveFavoriteRemote and saveFavoriteRemote:IsA("RemoteEvent") then
	saveFavoriteRemote.OnClientEvent:Connect(function(updatedFavorites)
		applyFavoritesPayload(updatedFavorites)
	end)
end

if syncStatusRemote and syncStatusRemote:IsA("RemoteEvent") then
	syncStatusRemote.OnClientEvent:Connect(function(action)
		if action == "start" then
			player:SetAttribute("onSync", true)
			stopCurrentTrack(CONFIG.SwitchOutFadeTime)
		elseif action == "stop" then
			player:SetAttribute("onSync", false)
		end
	end)
end

if syncAnimTimeRemote and syncAnimTimeRemote:IsA("RemoteEvent") then
	syncAnimTimeRemote.OnClientEvent:Connect(function(sourcePlayer, animId, targetSyncPlayer)
		if not sourcePlayer or not targetSyncPlayer then return end
		
		-- Gunakan loop pendek untuk menunggu animasi sourcePlayer termuat di klien ini
		task.spawn(function()
			local retries = 0
			while retries < 20 do
				local sourceChar = sourcePlayer.Character
				local targetChar = targetSyncPlayer.Character
				if not sourceChar or not targetChar then
					task.wait(0.1)
					retries += 1
					continue
				end
				
				local sourceAnim = sourceChar:FindFirstChild("Humanoid") and sourceChar.Humanoid:FindFirstChild("Animator")
				local targetAnim = targetChar:FindFirstChild("Humanoid") and targetChar.Humanoid:FindFirstChild("Animator")
				
				if sourceAnim and targetAnim then
					local sTrack, tTrack
					for _, track in ipairs(sourceAnim:GetPlayingAnimationTracks()) do
						if track.Animation and track.Animation.AnimationId == animId then
							sTrack = track
							break
						end
					end
					
					for _, track in ipairs(targetAnim:GetPlayingAnimationTracks()) do
						if track.Animation and track.Animation.AnimationId == animId then
							tTrack = track
							break
						end
					end
					
					if sTrack and tTrack then
						-- BOOM, PERFECT VISUAL SYNC
						sTrack.TimePosition = tTrack.TimePosition
						break
					end
				end
				
				task.wait(0.1)
				retries += 1
			end
		end)
	end)
end

local function resetCharacterState()
	for name, track in pairs(loadedTracks) do
		if track and track.IsPlaying then
			pcall(function()
				track:Stop(0)
			end)
		end
		loadedTracks[name] = nil
	end
	stopCurrentTrack(0)
end

if player:GetAttribute("DanceName") == nil then
	player:SetAttribute("DanceName", "")
end
if player:GetAttribute("onSync") == nil then
	player:SetAttribute("onSync", false)
end

if player.Character then
	resetCharacterState()
	preloadTracksForCharacterAsync()
end

player.CharacterAdded:Connect(function()
	resetCharacterState()
	preloadTracksForCharacterAsync()
end)
