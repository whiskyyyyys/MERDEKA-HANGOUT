-- SERVICES
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- PLAYER / GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- REMOTES / ASSETS
local syncRemote = ReplicatedStorage:WaitForChild("Sync")
local syncBroadcast = ReplicatedStorage:WaitForChild("SyncBroadcast")
local syncStatus = ReplicatedStorage:WaitForChild("SyncStatus")
local EmotesFolder = ReplicatedStorage:WaitForChild("Emotes")
-- GUI references (prioritaskan GUI baru: InGame > PlayerMenu)
local inGameGui = playerGui:WaitForChild("InGame", 10)
if inGameGui then inGameGui.ResetOnSpawn = false end

local avatarMenu = playerGui:FindFirstChild("AvatarMenu")
if avatarMenu then avatarMenu.ResetOnSpawn = false end

local mainFrame = nil
if inGameGui then
	mainFrame = inGameGui:WaitForChild("PlayerMenu", 10)
end

if not mainFrame and avatarMenu then
	mainFrame = avatarMenu:WaitForChild("MainFrame", 10)
end

if not mainFrame then
	warn("PlayerMenu (InGame) and legacy AvatarMenu.MainFrame not found in PlayerGui!")
	return
end

-- Posisi default dan hidden (slide)
local defaultPos = mainFrame.Position
local hiddenPos = defaultPos + UDim2.new(0, 0, 1, 0)

-- Sound (dibuat setelah mainFrame ada)
local openSound = Instance.new("Sound", mainFrame)
openSound.SoundId = "rbxassetid://9083627113" -- ganti sesuai preferensi
openSound.Volume = 0.25

local closeSound = Instance.new("Sound", mainFrame)
closeSound.SoundId = "rbxassetid://9083627113" -- ganti agar beda suara
closeSound.Volume = 0.25

-- Debug: Print semua children mainFrame
print("=== MainFrame Children ===")
for _, child in ipairs(mainFrame:GetChildren()) do
	print("-", child.Name, child.ClassName)
end

-- GUI elements (support GUI baru + fallback legacy)
local contentScroll = mainFrame:FindFirstChild("ScrollingFrame") or mainFrame:WaitForChild("ScrollingFrame", 5)
local avatarSection = contentScroll and (contentScroll:FindFirstChild("aAvatar") or contentScroll:WaitForChild("aAvatar", 5))
local buttonsSection = contentScroll and (contentScroll:FindFirstChild("bButtons") or contentScroll:WaitForChild("bButtons", 5))

-- CREATE CARRY OPTIONS SECTION (overlay langsung di mainFrame)
local carryOptionsSection = Instance.new("ScrollingFrame")
carryOptionsSection.Name = "CarryOptionsSection"
carryOptionsSection.Size = UDim2.new(1, 0, 1, 0)
carryOptionsSection.Position = UDim2.new(0, 0, 0, 0)
carryOptionsSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
carryOptionsSection.BackgroundTransparency = 0.15
carryOptionsSection.BorderSizePixel = 0
carryOptionsSection.Visible = false
carryOptionsSection.CanvasSize = UDim2.new(0, 0, 0, 0)
carryOptionsSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
carryOptionsSection.ScrollBarThickness = 4
carryOptionsSection.ZIndex = 100
carryOptionsSection.Parent = mainFrame

local carryPadding = Instance.new("UIPadding")
carryPadding.PaddingTop = UDim.new(0, 10)
carryPadding.PaddingBottom = UDim.new(0, 10)
carryPadding.PaddingLeft = UDim.new(0, 5)
carryPadding.PaddingRight = UDim.new(0, 5)
carryPadding.Parent = carryOptionsSection

local carryListLayout = Instance.new("UIListLayout")
carryListLayout.SortOrder = Enum.SortOrder.LayoutOrder
carryListLayout.Padding = UDim.new(0, 8)
carryListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
carryListLayout.Parent = carryOptionsSection

local function findFirstByNameList(root, names)
	if not root then
		return nil
	end

	for _, name in ipairs(names) do
		local direct = root:FindFirstChild(name)
		if direct then
			return direct
		end
		local deep = root:FindFirstChild(name, true)
		if deep then
			return deep
		end
	end

	return nil
end

local function findTextObjectByNameList(root, names)
	local candidate = findFirstByNameList(root, names)
	if not candidate then
		return nil
	end

	if candidate:IsA("TextLabel") or candidate:IsA("TextButton") or candidate:IsA("TextBox") then
		return candidate
	end

	return candidate:FindFirstChildWhichIsA("TextLabel", true)
		or candidate:FindFirstChildWhichIsA("TextButton", true)
		or candidate:FindFirstChildWhichIsA("TextBox", true)
end

local function findImageObjectByNameList(root, names)
	local candidate = findFirstByNameList(root, names)
	if not candidate then
		return nil
	end

	if candidate:IsA("ImageLabel") or candidate:IsA("ImageButton") then
		return candidate
	end

	return candidate:FindFirstChildWhichIsA("ImageLabel", true)
		or candidate:FindFirstChildWhichIsA("ImageButton", true)
end

local avatarInfoSection = avatarSection and findFirstByNameList(avatarSection, {"Info", "info"})
local avatarStatsSection =
	(avatarInfoSection and findFirstByNameList(avatarInfoSection, {"cStats", "stats", "Stats"}))
	or (avatarSection and findFirstByNameList(avatarSection, {"cStats", "stats", "Stats"}))
local avatarStatsScroll =
	(avatarStatsSection and findFirstByNameList(avatarStatsSection, {"ScrollingFrame", "scrollingframe"}))
	or avatarStatsSection

local playerAvatar =
	(avatarSection and findImageObjectByNameList(avatarSection, {"Avatar", "PlayerAvatar", "PlayerAvater"}))
	or findImageObjectByNameList(mainFrame, {"PlayerAvater", "PlayerAvatar"})

local displayNameLabel =
	(avatarSection and findTextObjectByNameList(avatarSection, {"DisplayName", "aDisplayName"}))
	or findTextObjectByNameList(mainFrame, {"DisplayName", "aDisplayName"})
local usernameLabel =
	(avatarSection and findTextObjectByNameList(avatarSection, {"Username", "bUsername"}))
	or findTextObjectByNameList(mainFrame, {"Username", "bUsername"})
local connectionsLabel =
	(avatarStatsScroll and findTextObjectByNameList(avatarStatsScroll, {"Connections", "Connection"}))
	or (avatarStatsSection and findTextObjectByNameList(avatarStatsSection, {"Connections", "Connection"}))
local followersLabel =
	(avatarStatsScroll and findTextObjectByNameList(avatarStatsScroll, {"Followers", "Follower"}))
	or (avatarStatsSection and findTextObjectByNameList(avatarStatsSection, {"Followers", "Follower"}))
local playerName = mainFrame:FindFirstChild("PlayerName") -- legacy

local currentlyWearingSection =
	(buttonsSection and findFirstByNameList(buttonsSection, {"aCurrentlyWearing", "CurrentlyWearing"}))
	or findFirstByNameList(mainFrame, {"aCurrentlyWearing", "CurrentlyWearing"})
local currentlyWearingTitle =
	(currentlyWearingSection and findTextObjectByNameList(currentlyWearingSection, {"TextLabel", "Title"}))
	or findTextObjectByNameList(mainFrame, {"TextLabel", "Title"})
local currentlyWearingBackButton =
	currentlyWearingSection and findFirstByNameList(currentlyWearingSection, {"Back", "Prev", "Previous"})
local currentlyWearingForwardButton =
	currentlyWearingSection and findFirstByNameList(currentlyWearingSection, {"Forward", "Next"})
local currentlyWearingScroll =
	currentlyWearingSection and findFirstByNameList(currentlyWearingSection, {"ScrollingFrame", "Scroll"})
local currentlyWearingTemplate =
	currentlyWearingScroll and findFirstByNameList(currentlyWearingScroll, {"Accessory", "Template", "Item"})
local currentlyWearingBuyAllButton =
	currentlyWearingScroll and findFirstByNameList(currentlyWearingScroll, {"buyAll", "BuyAll", "Buy All"})

local function normalizeMenuText(value)
	if type(value) ~= "string" then
		return ""
	end

	local text = string.lower(value)
	text = string.gsub(text, ">", "")
	text = string.gsub(text, "%s+", " ")
	text = string.gsub(text, "^%s*(.-)%s*$", "%1")
	return text
end

local function getButtonText(button)
	if not button then
		return ""
	end

	if button:IsA("TextButton") or button:IsA("TextLabel") or button:IsA("TextBox") then
		if button.Text and button.Text ~= "" then
			return button.Text
		end
	end

	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			if descendant.Text and descendant.Text ~= "" then
				return descendant.Text
			end
		end
	end

	return ""
end

local function getOrderedActionButtons(container)
	local result = {}
	if not container then
		return result
	end

	local children = container:GetChildren()
	local childOrder = {}
	for i, child in ipairs(children) do
		childOrder[child] = i
	end

	for _, child in ipairs(children) do
		if child:IsA("GuiButton") and child.Name == "button" then
			table.insert(result, child)
		end
	end

	table.sort(result, function(a, b)
		if a.LayoutOrder == b.LayoutOrder then
			return (childOrder[a] or 0) < (childOrder[b] or 0)
		end
		return a.LayoutOrder < b.LayoutOrder
	end)

	return result
end

local orderedActionButtons = getOrderedActionButtons(buttonsSection)
local usedActionButtons = {}

local function claimActionButton(button)
	if button and not usedActionButtons[button] then
		usedActionButtons[button] = true
		return button
	end
	return nil
end

local function claimActionButtonByKeywords(keywords)
	for _, button in ipairs(orderedActionButtons) do
		if not usedActionButtons[button] then
			local label = normalizeMenuText(getButtonText(button))
			for _, keyword in ipairs(keywords) do
				if string.find(label, keyword, 1, true) then
					usedActionButtons[button] = true
					return button
				end
			end
		end
	end
	return nil
end

local function claimActionButtonByIndex(index)
	return claimActionButton(orderedActionButtons[index])
end

local function findActionButtonByText(text)
	local normalizedTarget = normalizeMenuText(text)
	for _, button in ipairs(orderedActionButtons) do
		local current = normalizeMenuText(getButtonText(button))
		if current == normalizedTarget then
			return button
		end
	end
	return nil
end

local function findGuiByName(root, name)
	if not root or not name then
		return nil
	end

	return root:FindFirstChild(name) or root:FindFirstChild(name, true)
end

local function getMenuButtonTextObject(button)
	if not button then
		return nil
	end

	if button:IsA("TextButton") or button:IsA("TextLabel") or button:IsA("TextBox") then
		return button
	end

	local textObject =
		button:FindFirstChildWhichIsA("TextLabel", true)
		or button:FindFirstChildWhichIsA("TextButton", true)
		or button:FindFirstChildWhichIsA("TextBox", true)
	return textObject
end

local function setMenuButtonText(button, text)
	if not button or not text then
		return
	end

	local textObject = getMenuButtonTextObject(button)
	if textObject then
		textObject.Text = text
	end
end

local function setMenuButtonTextColor(button, color)
	if not button or not color then
		return
	end

	local textObject = getMenuButtonTextObject(button)
	if textObject then
		textObject.TextColor3 = color
	end
end

local function setMenuButtonTextTransparency(button, transparency)
	if not button or transparency == nil then
		return
	end

	local textObject = getMenuButtonTextObject(button)
	if textObject then
		textObject.TextTransparency = transparency
	end
end

local PRIVATE_CHAT_TEXT = "Private chat"
local HIDE_AVATAR_TEXT = "Hide avatar"
local SHOW_AVATAR_TEXT = "Show avatar"

setMenuButtonText(orderedActionButtons[1], "Carry Player")
setMenuButtonText(orderedActionButtons[2], "Gift Shop Item")
setMenuButtonText(orderedActionButtons[3], "Add friend")
setMenuButtonText(orderedActionButtons[4], PRIVATE_CHAT_TEXT)
setMenuButtonText(orderedActionButtons[5], HIDE_AVATAR_TEXT)

local syncButton =
	mainFrame:FindFirstChild("SyncButton")
	or findActionButtonByText("Carry Player")
	or claimActionButtonByKeywords({"carry player", "carry"})
	or claimActionButtonByIndex(1)

local giftButton =
	mainFrame:FindFirstChild("GiftButton")
	or findActionButtonByText("Gift Shop Item")
	or claimActionButtonByKeywords({"gift shop item", "gift gamepass", "gift"})
	or claimActionButtonByIndex(2)

local addFriendButton =
	mainFrame:FindFirstChild("AddButton")
	or mainFrame:FindFirstChild("AddFriendButton")
	or findActionButtonByText("Add friend")
	or claimActionButtonByKeywords({"add connection", "connection", "add friend"})
	or claimActionButtonByIndex(3)

local chatButton =
	mainFrame:FindFirstChild("ChatButton")
	or findActionButtonByText(PRIVATE_CHAT_TEXT)
	or claimActionButtonByKeywords({"private chat", "chat", "whisper"})
	or claimActionButtonByIndex(4)

local hideAvatarButton =
	mainFrame:FindFirstChild("HideAvatarButton")
	or mainFrame:FindFirstChild("HideAvatar")
	or findActionButtonByText(HIDE_AVATAR_TEXT)
	or claimActionButtonByKeywords({"hide avatar", "show avatar", "hide"})
	or claimActionButtonByIndex(5)

local quitButton = findGuiByName(mainFrame, "Quit")
if not quitButton then
	quitButton = mainFrame:WaitForChild("Quit", 5)
end
local hideButton = findGuiByName(mainFrame, "Hide")
if quitButton and quitButton:IsA("GuiButton") then
	for _, child in ipairs(quitButton:GetDescendants()) do
		if child:IsA("GuiObject") and not child:IsA("GuiButton") then
			child.Active = false
		end
	end
end

local closeButton = nil
for _, candidate in ipairs({
	mainFrame:FindFirstChild("CloseButton"), -- legacy
	quitButton, -- GUI baru
	hideButton, -- fallback
	}) do
	if candidate then
		if candidate:IsA("GuiButton") then
			closeButton = candidate
			break
		end

		local nested = candidate:FindFirstChildWhichIsA("GuiButton", true)
		if nested then
			closeButton = nested
			break
		end
	end
end

if not closeButton and orderedActionButtons[5] ~= hideAvatarButton then
	closeButton = orderedActionButtons[5]
end

local function isActionButton(button)
	if not button then
		return false
	end

	for _, actionButton in ipairs(orderedActionButtons) do
		if actionButton == button then
			return true
		end
	end

	return false
end

local syncUsesActionButton = isActionButton(syncButton)
local syncButtonTextObject = getMenuButtonTextObject(syncButton)
local syncDefaultVisual = {
	backgroundColor3 = syncButton and syncButton.BackgroundColor3 or Color3.fromRGB(31, 34, 40),
	backgroundTransparency = syncButton and syncButton.BackgroundTransparency or 0.2,
	textColor3 = syncButtonTextObject and syncButtonTextObject.TextColor3 or Color3.fromRGB(245, 245, 245),
	textTransparency = syncButtonTextObject and syncButtonTextObject.TextTransparency or 0,
}

local function updateSyncButtonVisual(isActive)
	if not syncButton or not syncButton:IsA("GuiButton") then
		return
	end

	syncButton.Visible = true
	syncButton.Active = true
end

-- Debug print
print("GUI loaded successfully.")
print("MainFrame:", mainFrame)
print("PlayerAvatar:", playerAvatar)
print("PlayerName:", playerName)
print("DisplayNameLabel:", displayNameLabel)
print("UsernameLabel:", usernameLabel)
print("ConnectionsLabel:", connectionsLabel)
print("FollowersLabel:", followersLabel)
print("CurrentlyWearingSection:", currentlyWearingSection)
print("CurrentlyWearingScroll:", currentlyWearingScroll)
print("CurrentlyWearingTemplate:", currentlyWearingTemplate)
print("CurrentlyWearingBuyAllButton:", currentlyWearingBuyAllButton)
print("SyncButton:", syncButton)
print("ChatButton:", chatButton)
print("HideAvatarButton:", hideAvatarButton)
print("AddFriendButton:", addFriendButton)
print("CloseButton:", closeButton)
print("ButtonsSection:", buttonsSection)
for i, button in ipairs(orderedActionButtons) do
	print(string.format("ActionButton[%d]: %s | \"%s\"", i, button.Name, getButtonText(button)))
end

-- STATE
local syncedLeader = nil
local isSyncing = false
local myTracks = {}
local mySyncTargets = {}
local lastSentState = {}
local myFollowers = {}
local lastBroadcastAt = 0
local lastNonEmptyStateAt = 0
local syncPacketSeq = 0
local lastAcceptedSyncSeq = nil

updateSyncButtonVisual(false)

local SYNC_CONFIG = {
	-- Keep updates frequent, but stable enough to avoid jitter on packet variance.
	BroadcastMinInterval = 1 / 50,
	StateTimeThreshold = 0.016,
	SpeedThreshold = 0.01,
	TrackStartFade = 0.05,
	TrackSwitchFade = 0.08,
	TrackStopFade = 0.14,
	TrackHardStopFade = 0.30,
	EmptyStateGrace = 0.05,
	MissingTrackGrace = 0.06,
	PredictionBackTime = 0.012,
	MaxCorrectionPerSecond = 6.0,
	MinTransportDelay = 0,
	MaxTransportDelay = 0.35,

	-- Follower smoothing (leader preview on local client)
	LocalFollowerSnapThreshold = 0.45,
	LocalFollowerMicroIgnore = 0.004,
	LocalFollowerLerpFactor = 0.28,

	-- Follower smoothing (my character following leader)
	FollowerSnapThreshold = 0.45,
	FollowerMicroIgnore = 0.004,
	FollowerLerpFactor = 0.3,
}

local function sanitizeSpeed(speed)
	if typeof(speed) ~= "number" or speed ~= speed then
		return 1
	end

	return math.clamp(speed, 0, 3)
end

local function sanitizePriority(priority)
	if typeof(priority) == "EnumItem" then
		return priority
	end

	return Enum.AnimationPriority.Action4
end

local function clampTransportDelay(seconds)
	return math.clamp(tonumber(seconds) or 0, SYNC_CONFIG.MinTransportDelay, SYNC_CONFIG.MaxTransportDelay)
end

local function packSyncPayload(tracks, forceStop)
	syncPacketSeq += 1
	return {
		tracks = tracks,
		sentAt = workspace:GetServerTimeNow(),
		seq = syncPacketSeq,
		forceStop = forceStop == true,
	}
end

local function unpackSyncPayload(payload)
	if typeof(payload) ~= "table" then
		return nil, nil, nil, false
	end

	local tracks = payload
	local sentAt = nil
	local seq = nil
	local forceStop = false

	if typeof(payload.tracks) == "table" then
		tracks = payload.tracks
		sentAt = payload.sentAt
		seq = payload.seq
		forceStop = payload.forceStop == true
	else
		sentAt = payload.sentAt or payload.serverTime or payload.timestamp
		seq = payload.seq
		forceStop = payload.forceStop == true
	end

	if typeof(tracks) ~= "table" then
		return nil, sentAt, seq, forceStop
	end

	return tracks, sentAt, seq, forceStop
end

local animationAssetCache = {}
local function getAnimationAsset(animationId)
	if typeof(animationId) ~= "string" or animationId == "" then
		return nil
	end

	local animation = animationAssetCache[animationId]
	if animation then
		return animation
	end

	animation = Instance.new("Animation")
	animation.AnimationId = animationId
	animationAssetCache[animationId] = animation
	return animation
end

local function loadTrackFromAnimationId(animator, animationId)
	local animation = getAnimationAsset(animationId)
	if not animator or not animation then
		return nil
	end

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		return nil
	end

	return track
end

local syncSuppressedAnimateScript = nil
local syncSuppressedAnimateWasDisabled = nil

local function getAnimatorFromCharacter(character)
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator, humanoid
end

local function isR6Character(character, humanoid)
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
		return true
	end

	return character
		and character:FindFirstChild("Torso") ~= nil
		and character:FindFirstChild("UpperTorso") == nil
end

local function setLocalDefaultAnimateSuppressed(shouldSuppress)
	local character = player.Character
	local animateScript = character and character:FindFirstChild("Animate")

	if not shouldSuppress then
		if syncSuppressedAnimateScript and syncSuppressedAnimateScript.Parent then
			syncSuppressedAnimateScript.Disabled = syncSuppressedAnimateWasDisabled == true
		end
		syncSuppressedAnimateScript = nil
		syncSuppressedAnimateWasDisabled = nil
		return
	end

	if not animateScript or not animateScript:IsA("BaseScript") then
		return
	end

	if syncSuppressedAnimateScript ~= animateScript then
		syncSuppressedAnimateScript = animateScript
		syncSuppressedAnimateWasDisabled = animateScript.Disabled
	end
	animateScript.Disabled = true
end

local function stopCompetingAnimationTracks(animator, keepTrack, fadeTime)
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

local function forceR6SyncTrack(character, animator, humanoid, track, fadeTime)
	if not isR6Character(character, humanoid) then
		return
	end
	if not animator or not track then
		return
	end

	if character == player.Character then
		setLocalDefaultAnimateSuppressed(true)
	end

	pcall(function()
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		if not track.IsPlaying then
			track:Play(fadeTime or SYNC_CONFIG.TrackStartFade)
		end
	end)

	stopCompetingAnimationTracks(animator, track, fadeTime or SYNC_CONFIG.TrackSwitchFade)
end

local function releaseLocalR6SyncSuppressionIfIdle()
	if next(myTracks) == nil then
		setLocalDefaultAnimateSuppressed(false)
	end
end

-- HIGHLIGHT
local currentHighlight = nil
local selectedPlayer = nil
local hiddenAvatarUserIds = {}
local hiddenCharacterAddedConnections = {}
local profileStatsRequestVersion = 0
local friendCountCache = {}
local FRIEND_CACHE_TTL = 60

local function setProfileText(textObject, value)
	if not textObject or value == nil then
		return
	end

	if textObject:IsA("TextLabel") or textObject:IsA("TextButton") or textObject:IsA("TextBox") then
		textObject.Text = tostring(value)
		return
	end

	local nestedText =
		textObject:FindFirstChildWhichIsA("TextLabel", true)
		or textObject:FindFirstChildWhichIsA("TextButton", true)
		or textObject:FindFirstChildWhichIsA("TextBox", true)
	if nestedText then
		nestedText.Text = tostring(value)
	end
end

local function getSyncFollowersInServer(targetPlayer)
	if not targetPlayer then
		return 0
	end

	local total = 0
	local targetUserId = targetPlayer.UserId
	for _, candidate in ipairs(Players:GetPlayers()) do
		if candidate ~= targetPlayer and candidate:GetAttribute("SyncLeaderUserId") == targetUserId then
			total += 1
		end
	end
	return total
end

local function updateFollowersLabel(targetPlayer)
	if not followersLabel then
		return
	end

	if not targetPlayer then
		setProfileText(followersLabel, "Followers: 0")
		return
	end

	setProfileText(followersLabel, string.format("Followers: %d", getSyncFollowersInServer(targetPlayer)))
end

local function getFriendCountFromPages(userId)
	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(userId)
	end)
	if not ok or not pages then
		return nil
	end

	local total = 0
	local pageSafety = 0
	while true do
		pageSafety += 1
		local okPage, currentPage = pcall(function()
			return pages:GetCurrentPage()
		end)
		if not okPage or typeof(currentPage) ~= "table" then
			break
		end
		total += #currentPage

		if pages.IsFinished or pageSafety >= 200 then
			break
		end

		local okAdvance = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not okAdvance then
			break
		end
	end

	friendCountCache[userId] = {
		count = total,
		at = os.clock(),
	}
	return total
end

local function updateConnectionsLabelAsync(targetPlayer)
	if not connectionsLabel then
		return
	end

	if not targetPlayer then
		setProfileText(connectionsLabel, "Connections: 0")
		return
	end

	local userId = targetPlayer.UserId
	local cached = friendCountCache[userId]
	local now = os.clock()
	if cached and (now - cached.at) <= FRIEND_CACHE_TTL then
		setProfileText(connectionsLabel, string.format("Connections: %d", cached.count))
		return
	end

	setProfileText(connectionsLabel, "Connections: ...")
	profileStatsRequestVersion += 1
	local requestVersion = profileStatsRequestVersion
	task.spawn(function()
		local count = getFriendCountFromPages(userId)
		if profileStatsRequestVersion ~= requestVersion then
			return
		end
		if not selectedPlayer or selectedPlayer.UserId ~= userId then
			return
		end

		if typeof(count) == "number" then
			setProfileText(connectionsLabel, string.format("Connections: %d", count))
		else
			setProfileText(connectionsLabel, "Connections: --")
		end
	end)
end

local function refreshSelectedProfileStats()
	updateFollowersLabel(selectedPlayer)
	updateConnectionsLabelAsync(selectedPlayer)
end

updateFollowersLabel(nil)
updateConnectionsLabelAsync(nil)

local CURRENTLY_WEARING_PRODUCT_CACHE_TTL = 120
local currentlyWearingRequestVersion = 0
local currentlyWearingItems = {}
local currentlyWearingEntryButtons = {}
local currentlyWearingProductInfoCache = {}
local currentlyWearingSnapOffsets = {}
local currentlyWearingSnapIndex = 1
local currentlyWearingDragInput = nil
local currentlyWearingDragStartX = 0
local currentlyWearingDragStartCanvasX = 0
local currentlyWearingDidDrag = false
local currentlyWearingIgnoreClickUntil = 0
local currentlyWearingDragConnectionsBound = false
local currentlyWearingLayoutContentConnection = nil

local buyAllQueue = {}
local buyAllQueueVersion = 0
local buyAllIsRunning = false
local buyAllCurrentAssetId = nil
local buyAllTotalCount = 0
local buyAllProcessedCount = 0
local buyAllPromptToken = 0
local buyAllDefaultText = (currentlyWearingBuyAllButton and getButtonText(currentlyWearingBuyAllButton)) or "Buy all"
if buyAllDefaultText == "" then
	buyAllDefaultText = "Buy all"
end

local function setCurrentlyWearingTitleText(text)
	if currentlyWearingTitle and text then
		setProfileText(currentlyWearingTitle, text)
	end
end

local function setCurrentlyWearingBuyAllText(text)
	if currentlyWearingBuyAllButton and text then
		setProfileText(currentlyWearingBuyAllButton, text)
	end
end

local function parsePositiveAssetId(value)
	local numberValue = tonumber(value)
	if not numberValue then
		return nil
	end

	numberValue = math.floor(numberValue)
	if numberValue <= 0 then
		return nil
	end

	return numberValue
end

local function appendUniqueWornItem(collection, byIdMap, assetId, assetTypeName, displayName)
	if not assetId or byIdMap[assetId] then
		return
	end

	byIdMap[assetId] = true
	table.insert(collection, {
		assetId = assetId,
		displayName = displayName,
		assetTypeName = assetTypeName,
		priceInRobux = nil,
		isForSale = nil,
		isLimited = nil,
	})
end

local function parseCommaSeparatedAssetIds(value)
	local ids = {}
	if typeof(value) ~= "string" or value == "" then
		return ids
	end

	for match in string.gmatch(value, "%d+") do
		local assetId = parsePositiveAssetId(match)
		if assetId then
			table.insert(ids, assetId)
		end
	end

	return ids
end

local function collectCurrentlyWearingItemsFromDescription(description)
	local items = {}
	local byIdMap = {}

	if not description then
		return items
	end

	local okAccessories, accessoryEntries = pcall(function()
		return description:GetAccessories(true)
	end)
	if okAccessories and typeof(accessoryEntries) == "table" then
		for _, accessoryData in ipairs(accessoryEntries) do
			if typeof(accessoryData) ~= "table" then
				continue
			end
			local assetId = parsePositiveAssetId(accessoryData.AssetId or accessoryData.assetId)
			if assetId then
				appendUniqueWornItem(items, byIdMap, assetId, tostring(accessoryData.AccessoryType), nil)
			end
		end
	end

	for _, fieldInfo in ipairs({
		{"HatAccessory", true},
		{"HairAccessory", true},
		{"FaceAccessory", true},
		{"NeckAccessory", true},
		{"ShouldersAccessory", true},
		{"FrontAccessory", true},
		{"BackAccessory", true},
		{"WaistAccessory", true},
		{"ShirtAccessory", true},
		{"PantsAccessory", true},
		{"JacketAccessory", true},
		{"SweaterAccessory", true},
		{"ShortsAccessory", true},
		{"LeftShoeAccessory", true},
		{"RightShoeAccessory", true},
		{"DressSkirtAccessory", true},
		{"Shirt", false},
		{"Pants", false},
		{"GraphicTShirt", false},
		{"Face", false},
		{"Head", false},
		{"Torso", false},
		{"LeftArm", false},
		{"RightArm", false},
		{"LeftLeg", false},
		{"RightLeg", false},
		}) do
		local fieldName = fieldInfo[1]
		local isCommaSeparated = fieldInfo[2]
		local okValue, value = pcall(function()
			return description[fieldName]
		end)
		if not okValue then
			continue
		end

		if isCommaSeparated then
			for _, assetId in ipairs(parseCommaSeparatedAssetIds(value)) do
				appendUniqueWornItem(items, byIdMap, assetId, fieldName, nil)
			end
		else
			local assetId = parsePositiveAssetId(value)
			if assetId then
				appendUniqueWornItem(items, byIdMap, assetId, fieldName, nil)
			end
		end
	end

	return items
end

local function collectCurrentlyWearingItemsFromCharacter(targetPlayer)
	if not targetPlayer then
		return {}
	end

	local character = targetPlayer.Character
	if not character then
		return {}
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return {}
	end

	local okDescription, appliedDescription = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if okDescription and appliedDescription then
		local descriptionItems = collectCurrentlyWearingItemsFromDescription(appliedDescription)
		if #descriptionItems > 0 then
			return descriptionItems
		end
	end

	local fallbackItems = {}
	local byIdMap = {}

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			local sourceAssetId = nil
			local okSourceAssetId, sourceValue = pcall(function()
				return child.SourceAssetId
			end)
			if okSourceAssetId then
				sourceAssetId = parsePositiveAssetId(sourceValue)
			end

			appendUniqueWornItem(
				fallbackItems,
				byIdMap,
				sourceAssetId,
				tostring(child.AccessoryType),
				child.Name
			)
		elseif child:IsA("Shirt") then
			local assetId = nil
			for match in string.gmatch(child.ShirtTemplate or "", "%d+") do
				assetId = parsePositiveAssetId(match)
				if assetId then
					break
				end
			end
			appendUniqueWornItem(fallbackItems, byIdMap, assetId, "Shirt", child.Name)
		elseif child:IsA("Pants") then
			local assetId = nil
			for match in string.gmatch(child.PantsTemplate or "", "%d+") do
				assetId = parsePositiveAssetId(match)
				if assetId then
					break
				end
			end
			appendUniqueWornItem(fallbackItems, byIdMap, assetId, "Pants", child.Name)
		elseif child:IsA("ShirtGraphic") then
			local assetId = nil
			for match in string.gmatch(child.Graphic or "", "%d+") do
				assetId = parsePositiveAssetId(match)
				if assetId then
					break
				end
			end
			appendUniqueWornItem(fallbackItems, byIdMap, assetId, "GraphicTShirt", child.Name)
		end
	end

	if #fallbackItems > 0 then
		return fallbackItems
	end

	if not okDescription or not appliedDescription then
		return {}
	end

	return collectCurrentlyWearingItemsFromDescription(appliedDescription)
end

local function collectCurrentlyWearingItemsFromAppearance(userId)
	local items = {}
	local byIdMap = {}

	local ok, appearanceInfo = pcall(function()
		return Players:GetCharacterAppearanceInfoAsync(userId)
	end)
	if not ok or typeof(appearanceInfo) ~= "table" then
		return items
	end

	local assets = appearanceInfo.assets or appearanceInfo.Assets or appearanceInfo.items or appearanceInfo.Items
	if typeof(assets) ~= "table" then
		return items
	end

	for _, asset in ipairs(assets) do
		if typeof(asset) ~= "table" then
			continue
		end

		local assetId = parsePositiveAssetId(asset.id or asset.assetId or asset.AssetId)
		if not assetId then
			continue
		end

		local assetTypeName = nil
		if typeof(asset.assetType) == "table" then
			assetTypeName = asset.assetType.name or asset.assetType.Name
		else
			assetTypeName = asset.assetTypeName or asset.AssetTypeName
		end

		appendUniqueWornItem(items, byIdMap, assetId, assetTypeName, asset.name or asset.Name)
	end

	return items
end

local function collectCurrentlyWearingItemsFromHumanoidDescription(userId)
	local ok, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(userId)
	end)
	if not ok or not description then
		return {}
	end

	return collectCurrentlyWearingItemsFromDescription(description)
end

local function getProductInfoCached(assetId)
	local now = os.clock()
	local cached = currentlyWearingProductInfoCache[assetId]
	if cached and (now - cached.at) <= CURRENTLY_WEARING_PRODUCT_CACHE_TTL then
		return cached.info
	end

	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
	end)
	if not ok or typeof(info) ~= "table" then
		return nil
	end

	currentlyWearingProductInfoCache[assetId] = {
		info = info,
		at = now,
	}
	return info
end

local function updateCurrentlyWearingItemFromProductInfo(itemData)
	if not itemData then
		return
	end

	local info = getProductInfoCached(itemData.assetId)
	if not info then
		return
	end

	if typeof(info.Name) == "string" and info.Name ~= "" then
		itemData.displayName = info.Name
	end
	itemData.priceInRobux = tonumber(info.PriceInRobux)
	itemData.isForSale = info.IsForSale == true
	itemData.isLimited = (info.IsLimited == true) or (info.IsLimitedUnique == true)
end

local function getCurrentlyWearingDisplayName(itemData)
	if not itemData then
		return "Unknown item"
	end
	if typeof(itemData.displayName) == "string" and itemData.displayName ~= "" then
		return itemData.displayName
	end
	if typeof(itemData.assetTypeName) == "string" and itemData.assetTypeName ~= "" then
		return string.format("%s #%d", itemData.assetTypeName, itemData.assetId)
	end
	return string.format("Item #%d", itemData.assetId)
end

local function getCurrentlyWearingStatusText(itemData)
	if not itemData then
		return ""
	end
	if typeof(itemData.priceInRobux) == "number" then
		return string.format("%d R$", itemData.priceInRobux)
	end
	if itemData.isLimited == true then
		return "Limited"
	end
	if itemData.isForSale == false then
		return "Offsale"
	end
	return ""
end

local function clearCurrentlyWearingEntries()
	for _, entryButton in ipairs(currentlyWearingEntryButtons) do
		if entryButton and entryButton.Parent then
			entryButton:Destroy()
		end
	end
	table.clear(currentlyWearingEntryButtons)
	table.clear(currentlyWearingSnapOffsets)
	currentlyWearingSnapIndex = 1

	if currentlyWearingScroll then
		for _, child in ipairs(currentlyWearingScroll:GetChildren()) do
			if child == currentlyWearingTemplate or child == currentlyWearingBuyAllButton then
				continue
			end
			if child:GetAttribute("GeneratedByAvatarMenuClient") == true then
				child:Destroy()
			end
		end
	end
end

local function setupCurrentlyWearingScroll()
	if not currentlyWearingScroll or not currentlyWearingScroll:IsA("ScrollingFrame") then
		return
	end

	currentlyWearingScroll.ScrollingEnabled = true
	currentlyWearingScroll.ScrollingDirection = Enum.ScrollingDirection.X
	currentlyWearingScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	currentlyWearingScroll.CanvasSize = UDim2.fromOffset(0, 0)
	currentlyWearingScroll.ClipsDescendants = true

	local layout = currentlyWearingScroll:FindFirstChildWhichIsA("UIListLayout")
	if layout then
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.SortOrder = Enum.SortOrder.LayoutOrder

		if currentlyWearingLayoutContentConnection then
			currentlyWearingLayoutContentConnection:Disconnect()
			currentlyWearingLayoutContentConnection = nil
		end
		currentlyWearingLayoutContentConnection = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			task.defer(function()
				if currentlyWearingScroll and currentlyWearingScroll.Parent then
					local currentX = currentlyWearingScroll.CanvasPosition.X
					local canvasWidth = math.max(0, math.ceil(layout.AbsoluteContentSize.X))
					currentlyWearingScroll.CanvasSize = UDim2.new(0, canvasWidth, 0, 0)
					local windowWidth = currentlyWearingScroll.AbsoluteSize.X
					local okWindowSize, absoluteWindowSize = pcall(function()
						return currentlyWearingScroll.AbsoluteWindowSize
					end)
					if okWindowSize and typeof(absoluteWindowSize) == "Vector2" and absoluteWindowSize.X > 0 then
						windowWidth = absoluteWindowSize.X
					end
					local maxX = math.max(0, canvasWidth - windowWidth)
					currentlyWearingScroll.CanvasPosition = Vector2.new(math.clamp(currentX, 0, maxX), 0)
				end
			end)
		end)
	end
end

local function getCurrentlyWearingScrollMetrics()
	if not currentlyWearingScroll or not currentlyWearingScroll:IsA("ScrollingFrame") then
		return 0, 0, 0
	end

	local windowWidth = currentlyWearingScroll.AbsoluteSize.X
	local okWindowSize, absoluteWindowSize = pcall(function()
		return currentlyWearingScroll.AbsoluteWindowSize
	end)
	if okWindowSize and typeof(absoluteWindowSize) == "Vector2" and absoluteWindowSize.X > 0 then
		windowWidth = absoluteWindowSize.X
	end

	local canvasWidth = currentlyWearingScroll.AbsoluteCanvasSize.X
	if canvasWidth <= 0 then
		canvasWidth = currentlyWearingScroll.CanvasSize.X.Offset
	end

	local currentX = currentlyWearingScroll.CanvasPosition.X
	local maxX = math.max(0, canvasWidth - windowWidth)
	return currentX, maxX, windowWidth
end

local function findClosestCurrentlyWearingSnapIndex(targetX)
	if #currentlyWearingSnapOffsets == 0 then
		return 1
	end

	local bestIndex = 1
	local bestDistance = math.huge
	for i, offset in ipairs(currentlyWearingSnapOffsets) do
		local distance = math.abs(offset - targetX)
		if distance < bestDistance then
			bestDistance = distance
			bestIndex = i
		end
	end

	return bestIndex
end

local function rebuildCurrentlyWearingSnapOffsets()
	table.clear(currentlyWearingSnapOffsets)
	if not currentlyWearingScroll or not currentlyWearingScroll:IsA("ScrollingFrame") then
		return
	end

	local currentX, maxX = getCurrentlyWearingScrollMetrics()
	local visibleChildren = {}
	for _, child in ipairs(currentlyWearingScroll:GetChildren()) do
		if not child:IsA("GuiObject") then
			continue
		end
		if child == currentlyWearingTemplate then
			continue
		end
		if not child.Visible then
			continue
		end
		if child:IsA("UIListLayout") or child:IsA("UIPadding") then
			continue
		end
		table.insert(visibleChildren, child)
	end

	table.sort(visibleChildren, function(a, b)
		if a.LayoutOrder == b.LayoutOrder then
			return a.AbsolutePosition.X < b.AbsolutePosition.X
		end
		return a.LayoutOrder < b.LayoutOrder
	end)

	for _, child in ipairs(visibleChildren) do
		local offset = child.AbsolutePosition.X - currentlyWearingScroll.AbsolutePosition.X + currentX
		offset = math.clamp(math.floor(offset + 0.5), 0, maxX)

		local last = currentlyWearingSnapOffsets[#currentlyWearingSnapOffsets]
		if not last or math.abs(last - offset) > 1 then
			table.insert(currentlyWearingSnapOffsets, offset)
		end
	end

	if #currentlyWearingSnapOffsets == 0 then
		table.insert(currentlyWearingSnapOffsets, 0)
	end
	if maxX > (currentlyWearingSnapOffsets[#currentlyWearingSnapOffsets] or 0) + 1 then
		table.insert(currentlyWearingSnapOffsets, maxX)
	end
end

local function snapCurrentlyWearingToIndex(index)
	if not currentlyWearingScroll or not currentlyWearingScroll:IsA("ScrollingFrame") then
		return
	end

	if #currentlyWearingSnapOffsets == 0 then
		currentlyWearingSnapIndex = 1
		currentlyWearingScroll.CanvasPosition = Vector2.new(0, 0)
		return
	end

	currentlyWearingSnapIndex = math.clamp(index, 1, #currentlyWearingSnapOffsets)
	local targetX = currentlyWearingSnapOffsets[currentlyWearingSnapIndex] or 0
	currentlyWearingScroll.CanvasPosition = Vector2.new(targetX, 0)
end

local function updateCurrentlyWearingNavigationState()
	if #currentlyWearingItems <= 0 then
		currentlyWearingSnapIndex = 1
		if currentlyWearingBackButton and currentlyWearingBackButton:IsA("GuiButton") then
			currentlyWearingBackButton.Active = false
			currentlyWearingBackButton.AutoButtonColor = false
		end
		if currentlyWearingForwardButton and currentlyWearingForwardButton:IsA("GuiButton") then
			currentlyWearingForwardButton.Active = false
			currentlyWearingForwardButton.AutoButtonColor = false
		end
		for _, navButton in ipairs({currentlyWearingBackButton, currentlyWearingForwardButton}) do
			if navButton and navButton:IsA("GuiObject") then
				navButton.Visible = true
			end
		end
		return
	end

	if currentlyWearingScroll and currentlyWearingScroll:IsA("ScrollingFrame") and #currentlyWearingSnapOffsets > 0 then
		currentlyWearingSnapIndex = findClosestCurrentlyWearingSnapIndex(currentlyWearingScroll.CanvasPosition.X)
	end

	local canGoBack = currentlyWearingSnapIndex > 1
	local canGoForward = currentlyWearingSnapIndex < #currentlyWearingSnapOffsets

	for _, navButton in ipairs({currentlyWearingBackButton, currentlyWearingForwardButton}) do
		if navButton and navButton:IsA("GuiObject") then
			navButton.Visible = true
		end
	end

	if currentlyWearingBackButton and currentlyWearingBackButton:IsA("GuiButton") then
		currentlyWearingBackButton.Active = canGoBack
		currentlyWearingBackButton.AutoButtonColor = canGoBack
	end
	if currentlyWearingForwardButton and currentlyWearingForwardButton:IsA("GuiButton") then
		currentlyWearingForwardButton.Active = canGoForward
		currentlyWearingForwardButton.AutoButtonColor = canGoForward
	end
end

local function snapCurrentlyWearingToNearest()
	if not currentlyWearingScroll or not currentlyWearingScroll:IsA("ScrollingFrame") then
		return
	end

	local currentX = currentlyWearingScroll.CanvasPosition.X
	local nearestIndex = findClosestCurrentlyWearingSnapIndex(currentX)
	snapCurrentlyWearingToIndex(nearestIndex)
	updateCurrentlyWearingNavigationState()
end

local function moveCurrentlyWearingByStep(step)
	if #currentlyWearingSnapOffsets <= 1 then
		return
	end

	local currentIndex = currentlyWearingSnapIndex
	if currentIndex < 1 or currentIndex > #currentlyWearingSnapOffsets then
		local currentX = currentlyWearingScroll and currentlyWearingScroll.CanvasPosition.X or 0
		currentIndex = findClosestCurrentlyWearingSnapIndex(currentX)
	end

	local nextIndex = math.clamp(currentIndex + step, 1, #currentlyWearingSnapOffsets)
	snapCurrentlyWearingToIndex(nextIndex)
	updateCurrentlyWearingNavigationState()
end

local function bindCurrentlyWearingDragInput()
	if currentlyWearingDragConnectionsBound then
		return
	end
	if not currentlyWearingScroll or not currentlyWearingScroll:IsA("GuiObject") then
		return
	end

	currentlyWearingDragConnectionsBound = true

	local function isInputOverCurrentlyWearingScroll(position)
		if not currentlyWearingScroll or not currentlyWearingScroll:IsA("GuiObject") then
			return false
		end
		local topLeft = currentlyWearingScroll.AbsolutePosition
		local size = currentlyWearingScroll.AbsoluteSize
		return position.X >= topLeft.X
			and position.X <= (topLeft.X + size.X)
			and position.Y >= topLeft.Y
			and position.Y <= (topLeft.Y + size.Y)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if #currentlyWearingSnapOffsets <= 1 then
			return
		end
		if not isInputOverCurrentlyWearingScroll(input.Position) then
			return
		end

		currentlyWearingDragInput = input
		currentlyWearingDragStartX = input.Position.X
		currentlyWearingDragStartCanvasX = currentlyWearingScroll.CanvasPosition.X
		currentlyWearingDidDrag = false
	end)

	UserInputService.InputChanged:Connect(function(input)
		if currentlyWearingDragInput ~= input then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if not currentlyWearingScroll or not currentlyWearingScroll:IsA("ScrollingFrame") then
			return
		end

		local deltaX = input.Position.X - currentlyWearingDragStartX
		if math.abs(deltaX) > 5 then
			currentlyWearingDidDrag = true
		end

		local _, maxX = getCurrentlyWearingScrollMetrics()
		local targetX = math.clamp(currentlyWearingDragStartCanvasX - deltaX, 0, maxX)
		currentlyWearingScroll.CanvasPosition = Vector2.new(targetX, 0)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if currentlyWearingDragInput ~= input then
			return
		end

		currentlyWearingDragInput = nil
		if currentlyWearingDidDrag then
			currentlyWearingIgnoreClickUntil = os.clock() + 0.2
			snapCurrentlyWearingToNearest()
		else
			updateCurrentlyWearingNavigationState()
		end
	end)
end

local function promptPurchaseForCurrentlyWearingItem(itemData)
	if not itemData then
		return
	end
	if os.clock() < currentlyWearingIgnoreClickUntil then
		return
	end

	pcall(function()
		MarketplaceService:PromptPurchase(player, itemData.assetId)
	end)
end

local function renderCurrentlyWearingPage(resetScrollToStart)
	local previousCanvasX = 0
	if currentlyWearingScroll and currentlyWearingScroll:IsA("ScrollingFrame") then
		previousCanvasX = currentlyWearingScroll.CanvasPosition.X
	end

	clearCurrentlyWearingEntries()
	setupCurrentlyWearingScroll()
	bindCurrentlyWearingDragInput()

	local totalItems = #currentlyWearingItems

	setCurrentlyWearingTitleText(string.format("Currently Wearing (%d)", totalItems))

	if not currentlyWearingScroll or not currentlyWearingTemplate then
		return
	end

	currentlyWearingTemplate.Visible = false

	for i, itemData in ipairs(currentlyWearingItems) do
		if not itemData then
			continue
		end

		local entryButton = currentlyWearingTemplate:Clone()
		entryButton.Name = string.format("Accessory_%d", i)
		entryButton.Visible = true
		entryButton.LayoutOrder = i
		entryButton:SetAttribute("GeneratedByAvatarMenuClient", true)
		entryButton.Parent = currentlyWearingScroll

		local titleLabel = findTextObjectByNameList(entryButton, {"COMMAND", "Name", "Title"})
		local statusLabel = findTextObjectByNameList(entryButton, {"LIMITED", "Price", "Status"})
		local iconImage = findImageObjectByNameList(entryButton, {"ImageLabel", "Icon", "Image"})
		local displayName = getCurrentlyWearingDisplayName(itemData)
		local statusText = getCurrentlyWearingStatusText(itemData)

		if titleLabel and titleLabel ~= entryButton then
			setProfileText(titleLabel, displayName)
		else
			setProfileText(entryButton, displayName)
		end
		if statusLabel and statusLabel ~= titleLabel then
			setProfileText(statusLabel, statusText)
			if statusLabel:IsA("GuiObject") then
				statusLabel.Visible = statusText ~= ""
			end
		end
		if iconImage then
			iconImage.Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", itemData.assetId)
		end

		if entryButton:IsA("GuiButton") then
			entryButton.MouseButton1Click:Connect(function()
				promptPurchaseForCurrentlyWearingItem(itemData)
			end)
		end

		table.insert(currentlyWearingEntryButtons, entryButton)
	end

	if currentlyWearingBuyAllButton then
		currentlyWearingBuyAllButton.LayoutOrder = totalItems + 1
		if currentlyWearingBuyAllButton:IsA("GuiButton") then
			local canInteract = totalItems > 0
			currentlyWearingBuyAllButton.Active = canInteract
			currentlyWearingBuyAllButton.AutoButtonColor = canInteract
		end
	end

	if currentlyWearingScroll:IsA("ScrollingFrame") then
		task.defer(function()
			if currentlyWearingScroll.Parent and currentlyWearingScroll:IsA("ScrollingFrame") then
				local layout = currentlyWearingScroll:FindFirstChildWhichIsA("UIListLayout")
				local contentWidth = layout and layout.AbsoluteContentSize.X or 0
				contentWidth = math.max(0, math.ceil(contentWidth))
				currentlyWearingScroll.CanvasSize = UDim2.new(0, contentWidth, 0, 0)

				local _, maxX = getCurrentlyWearingScrollMetrics()
				local targetX = resetScrollToStart and 0 or math.clamp(previousCanvasX, 0, maxX)
				currentlyWearingScroll.CanvasPosition = Vector2.new(targetX, 0)

				rebuildCurrentlyWearingSnapOffsets()
				local nearestIndex = findClosestCurrentlyWearingSnapIndex(currentlyWearingScroll.CanvasPosition.X)
				snapCurrentlyWearingToIndex(nearestIndex)
				updateCurrentlyWearingNavigationState()
			end
		end)
	end
end

local function applyCurrentlyWearingItems(items)
	currentlyWearingItems = items
	renderCurrentlyWearingPage(true)
end

local function cancelBuyAllQueue()
	buyAllQueueVersion += 1
	buyAllIsRunning = false
	buyAllCurrentAssetId = nil
	buyAllTotalCount = 0
	buyAllProcessedCount = 0
	buyAllPromptToken += 1
	table.clear(buyAllQueue)
	setCurrentlyWearingBuyAllText(buyAllDefaultText)
end

local function continueBuyAllQueue(queueVersion)
	if not buyAllIsRunning or queueVersion ~= buyAllQueueVersion then
		return
	end

	local itemData = table.remove(buyAllQueue, 1)
	if not itemData then
		cancelBuyAllQueue()
		return
	end

	buyAllCurrentAssetId = itemData.assetId
	local progressNow = buyAllProcessedCount + 1
	setCurrentlyWearingBuyAllText(string.format("Buying %d/%d", progressNow, buyAllTotalCount))

	local ok = pcall(function()
		MarketplaceService:PromptPurchase(player, itemData.assetId)
	end)
	if not ok then
		buyAllProcessedCount += 1
		buyAllCurrentAssetId = nil
		task.defer(function()
			continueBuyAllQueue(queueVersion)
		end)
		return
	end

	buyAllPromptToken += 1
	local promptToken = buyAllPromptToken
	task.delay(6, function()
		if not buyAllIsRunning or queueVersion ~= buyAllQueueVersion then
			return
		end
		if buyAllCurrentAssetId ~= itemData.assetId then
			return
		end
		if promptToken ~= buyAllPromptToken then
			return
		end

		buyAllProcessedCount += 1
		buyAllCurrentAssetId = nil
		continueBuyAllQueue(queueVersion)
	end)
end

local function startBuyAllQueue()
	cancelBuyAllQueue()

	local queue = {}
	for _, itemData in ipairs(currentlyWearingItems) do
		if itemData and itemData.assetId and itemData.assetId > 0 then
			table.insert(queue, itemData)
		end
	end

	if #queue == 0 then
		return
	end

	buyAllQueue = queue
	buyAllIsRunning = true
	buyAllCurrentAssetId = nil
	buyAllTotalCount = #queue
	buyAllProcessedCount = 0
	buyAllQueueVersion += 1
	local queueVersion = buyAllQueueVersion
	continueBuyAllQueue(queueVersion)
end

local function refreshCurrentlyWearingAsync(targetPlayer)
	currentlyWearingRequestVersion += 1
	local requestVersion = currentlyWearingRequestVersion
	cancelBuyAllQueue()
	clearCurrentlyWearingEntries()
	currentlyWearingItems = {}
	updateCurrentlyWearingNavigationState()

	if not targetPlayer then
		setCurrentlyWearingTitleText("Currently Wearing (0)")
		return
	end

	setCurrentlyWearingTitleText("Currently Wearing (...)")

	task.spawn(function()
		local items = collectCurrentlyWearingItemsFromCharacter(targetPlayer)
		if #items == 0 then
			items = collectCurrentlyWearingItemsFromHumanoidDescription(targetPlayer.UserId)
		end
		if #items == 0 then
			items = collectCurrentlyWearingItemsFromAppearance(targetPlayer.UserId)
		end

		-- Character appearance may not be fully applied yet in Studio/playtest; retry briefly once.
		if #items == 0 then
			task.wait(0.35)
			items = collectCurrentlyWearingItemsFromCharacter(targetPlayer)
		end

		if requestVersion ~= currentlyWearingRequestVersion then
			return
		end
		if not selectedPlayer or selectedPlayer ~= targetPlayer then
			return
		end

		if #items == 0 then
			warn("CurrentlyWearing: no wearable asset IDs found for", targetPlayer.Name)
		end

		applyCurrentlyWearingItems(items)

		task.spawn(function()
			local changed = false
			for _, itemData in ipairs(currentlyWearingItems) do
				if requestVersion ~= currentlyWearingRequestVersion then
					return
				end
				if not selectedPlayer or selectedPlayer ~= targetPlayer then
					return
				end

				local previousName = itemData.displayName
				local previousStatus = getCurrentlyWearingStatusText(itemData)
				updateCurrentlyWearingItemFromProductInfo(itemData)
				local nextName = itemData.displayName
				local nextStatus = getCurrentlyWearingStatusText(itemData)
				if previousName ~= nextName or previousStatus ~= nextStatus then
					changed = true
				end
			end

			if changed and requestVersion == currentlyWearingRequestVersion and selectedPlayer == targetPlayer then
				renderCurrentlyWearingPage()
			end
		end)
	end)
end

MarketplaceService.PromptPurchaseFinished:Connect(function(promptPlayer, assetId, _isPurchased)
	if promptPlayer ~= player then
		return
	end
	if not buyAllIsRunning then
		return
	end

	local expectedAssetId = buyAllCurrentAssetId
	if expectedAssetId and assetId ~= expectedAssetId then
		return
	end

	buyAllPromptToken += 1
	buyAllProcessedCount += 1
	buyAllCurrentAssetId = nil
	local queueVersion = buyAllQueueVersion
	task.defer(function()
		continueBuyAllQueue(queueVersion)
	end)
end)

if currentlyWearingTemplate and currentlyWearingTemplate:IsA("GuiObject") then
	currentlyWearingTemplate.Visible = false
end
setupCurrentlyWearingScroll()
if currentlyWearingScroll and currentlyWearingScroll:IsA("ScrollingFrame") then
	currentlyWearingScroll:GetPropertyChangedSignal("CanvasSize"):Connect(function()
		rebuildCurrentlyWearingSnapOffsets()
		updateCurrentlyWearingNavigationState()
	end)
	currentlyWearingScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		rebuildCurrentlyWearingSnapOffsets()
		updateCurrentlyWearingNavigationState()
	end)
	currentlyWearingScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		updateCurrentlyWearingNavigationState()
	end)
end
setCurrentlyWearingTitleText("Currently Wearing (0)")
setCurrentlyWearingBuyAllText(buyAllDefaultText)
updateCurrentlyWearingNavigationState()

local function setLocalHiddenOnInstance(instance, hidden)
	pcall(function()
		instance.LocalTransparencyModifier = hidden and 1 or 0
	end)
end

local function setCharacterHidden(character, hidden)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		setLocalHiddenOnInstance(descendant, hidden)
	end
end

local function clearHiddenConnection(userId)
	local connection = hiddenCharacterAddedConnections[userId]
	if connection then
		connection:Disconnect()
		hiddenCharacterAddedConnections[userId] = nil
	end
end

local function ensureHiddenConnection(targetPlayer)
	if not targetPlayer then
		return
	end

	local userId = targetPlayer.UserId
	if hiddenCharacterAddedConnections[userId] then
		return
	end

	hiddenCharacterAddedConnections[userId] = targetPlayer.CharacterAdded:Connect(function(character)
		if not hiddenAvatarUserIds[userId] then
			return
		end

		task.defer(function()
			setCharacterHidden(character, true)
		end)
		task.delay(0.5, function()
			if hiddenAvatarUserIds[userId] then
				setCharacterHidden(character, true)
			end
		end)
	end)
end

local function isAvatarHidden(targetPlayer)
	return targetPlayer and hiddenAvatarUserIds[targetPlayer.UserId] == true
end

local function updateHideAvatarButtonText(targetPlayer)
	if not hideAvatarButton or not hideAvatarButton:IsA("GuiButton") then
		return
	end

	setMenuButtonText(hideAvatarButton, isAvatarHidden(targetPlayer) and SHOW_AVATAR_TEXT or HIDE_AVATAR_TEXT)
end

local function applyHiddenStateToPlayer(targetPlayer)
	if not targetPlayer then
		return
	end

	if targetPlayer.Character then
		setCharacterHidden(targetPlayer.Character, isAvatarHidden(targetPlayer))
	end
end

local function setAvatarHidden(targetPlayer, shouldHide)
	if not targetPlayer then
		return
	end

	local userId = targetPlayer.UserId
	hiddenAvatarUserIds[userId] = shouldHide and true or nil

	if shouldHide then
		ensureHiddenConnection(targetPlayer)
	else
		clearHiddenConnection(userId)
	end

	applyHiddenStateToPlayer(targetPlayer)
end

mainFrame.Visible = false
-- Pastikan posisi awal berada di default (jika perlu start hidden offscreen, uncomment berikut)
-- mainFrame.Position = hiddenPos

local function createHighlight(character)
	if currentHighlight then
		currentHighlight:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "SelectionHighlight"
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	currentHighlight = highlight
end

local function removeHighlight()
	if currentHighlight then
		currentHighlight:Destroy()
		currentHighlight = nil
	end
end

local function stopTrackMap(trackMap, targetMap, fadeTime)
	for animId, track in pairs(trackMap) do
		if track and track.IsPlaying then
			pcall(function() track:Stop(fadeTime) end)
		end
		trackMap[animId] = nil
		if targetMap then
			targetMap[animId] = nil
		end
	end

	if trackMap == myTracks then
		releaseLocalR6SyncSuppressionIfIdle()
	end
end

-- STOP SYNC function (letakkan sebelum tombol memanggilnya)
local function stopSync()
	if syncedLeader then
		-- Minta server untuk unsync
		pcall(function()
			syncRemote:FireServer(syncedLeader, "unsync")
		end)

		syncedLeader = nil
		isSyncing = false
		lastAcceptedSyncSeq = nil

		-- Stop semua track lokal
		stopTrackMap(myTracks, mySyncTargets, SYNC_CONFIG.TrackStopFade)
		updateSyncButtonVisual(false)
	end
end

-- OPEN MENU (slide in)
local function openAvatarMenu(targetPlayer)
	if not targetPlayer or targetPlayer == player then return end

	selectedPlayer = targetPlayer
	updateSyncButtonVisual(isSyncing and syncedLeader == targetPlayer)
	updateHideAvatarButtonText(targetPlayer)

	-- Set teks nama (GUI baru)
	setProfileText(displayNameLabel, targetPlayer.DisplayName)
	setProfileText(usernameLabel, "@" .. targetPlayer.Name)
	refreshSelectedProfileStats()
	refreshCurrentlyWearingAsync(targetPlayer)

	-- Set PlayerName (legacy)
	if playerName then
		playerName.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
	end

	-- Set PlayerAvatar (thumbnail)
	if playerAvatar then
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
		end)
		if ok and content then
			playerAvatar.Image = content
		end
	end

	-- Create highlight
	if targetPlayer.Character then
		createHighlight(targetPlayer.Character)
	end

	-- Show menu with slide in animation
	mainFrame.Visible = true
	mainFrame.Position = hiddenPos

	if openSound then
		pcall(function() openSound:Play() end)
	end

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = defaultPos
	})
	tween:Play()

	print("Menu opened:", targetPlayer.Name)
end

-- Simple show/hide for carry overlay
local function hideCarryOverlay()
	carryOptionsSection.Visible = false
end

local function showCarryOverlay()
	carryOptionsSection.Visible = true
end

-- CLOSE MENU (slide out)
local function closeAvatarMenu()
	local function finishClose()
		mainFrame.Visible = false
		mainFrame.Position = defaultPos
	end

	if closeSound then
		pcall(function() closeSound:Play() end)
	end

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Position = hiddenPos
	})

	tween:Play()

	local completed = false
	local completedConn
	completedConn = tween.Completed:Connect(function()
		completed = true
		if completedConn then
			completedConn:Disconnect()
			completedConn = nil
		end
		finishClose()
	end)

	task.delay(0.45, function()
		if completed then
			return
		end
		if completedConn then
			completedConn:Disconnect()
			completedConn = nil
		end
		finishClose()
	end)

	selectedPlayer = nil
	profileStatsRequestVersion += 1
	currentlyWearingRequestVersion += 1
	cancelBuyAllQueue()
	clearCurrentlyWearingEntries()
	currentlyWearingItems = {}
	updateCurrentlyWearingNavigationState()
	setCurrentlyWearingTitleText("Currently Wearing (0)")
	updateFollowersLabel(nil)
	updateConnectionsLabelAsync(nil)
	updateHideAvatarButtonText(nil)
	removeHighlight()
	
	hideCarryOverlay()
end

local function connectCloseHandler(button)
	if not button then
		return false
	end

	local clickedThisFrame = false
	local function fireClose()
		if clickedThisFrame then
			return
		end
		clickedThisFrame = true
		closeAvatarMenu()
		task.defer(function()
			clickedThisFrame = false
		end)
	end

	local connected = false
	local seen = {}
	local function bindClick(target)
		if not target or seen[target] then
			return
		end
		seen[target] = true

		if target:IsA("GuiButton") then
			connected = true
			target.MouseButton1Click:Connect(fireClose)
			target.Activated:Connect(fireClose)
			target.TouchTap:Connect(fireClose)
			return
		end

		if target:IsA("GuiObject") then
			target.Active = true
			connected = true
			target.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					fireClose()
				end
			end)
		end
	end

	bindClick(button)
	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			bindClick(descendant)
		end
	end

	-- If child overlay eats the click, this fallback still closes menu.
	if button:IsA("GuiObject") then
		for _, descendant in ipairs(button:GetDescendants()) do
			if descendant:IsA("GuiObject") and not descendant:IsA("GuiButton") then
				bindClick(descendant)
			end
		end
	end

	return connected
end

-- BUTTONS: safety checks sebelum connect
-- Function to populate carry options dynamically
-- Function to populate carry options dynamically
local function populateCarryOptions(targetPlayer)
	print("[AvatarMenu] populateCarryOptions called for", targetPlayer.Name)
	-- Clear old buttons
	for _, child in ipairs(carryOptionsSection:GetChildren()) do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end

	local CarryChoicesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("CarryReplic")
	if CarryChoicesFolder then CarryChoicesFolder = CarryChoicesFolder:FindFirstChild("CarryChoices") end
	
	if not CarryChoicesFolder then 
		warn("[AvatarMenu] CarryChoicesFolder NOT FOUND!")
		return 
	end

	local childrenCount = #CarryChoicesFolder:GetChildren()
	print("[AvatarMenu] Found CarryChoicesFolder with", childrenCount, "choices")

	local backButton = Instance.new("TextButton")
	backButton.Size = UDim2.new(0.9, 0, 0, 40)
	backButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	backButton.Font = Enum.Font.GothamBold
	backButton.TextSize = 16
	backButton.Text = "← Back"
	backButton.LayoutOrder = 0
	backButton.ZIndex = 101
	local corner = Instance.new("UICorner", backButton)
	corner.CornerRadius = UDim.new(0, 8)
	backButton.Parent = carryOptionsSection

	backButton.MouseButton1Click:Connect(function()
		hideCarryOverlay()
	end)

	local order = 1
	for _, choice in ipairs(CarryChoicesFolder:GetChildren()) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.9, 0, 0, 40)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 16
		btn.Text = choice.Name
		btn.LayoutOrder = order
		btn.ZIndex = 101
		local btnCorner = Instance.new("UICorner", btn)
		btnCorner.CornerRadius = UDim.new(0, 8)
		btn.Parent = carryOptionsSection

		btn.MouseButton1Click:Connect(function()
			local CarryReplic = game:GetService("ReplicatedStorage"):WaitForChild("CarryReplic")
			local CarryRemotes = CarryReplic:WaitForChild("CarryRemotes")
			local CarryRemote = CarryRemotes:WaitForChild("CarryRemote")
			CarryRemote:FireServer("RequestCarry", targetPlayer, choice.Name)
			
			if type(closeAvatarMenu) == "function" then
				closeAvatarMenu()
			else
				warn("closeAvatarMenu is nil in Carry choice! Forcing close.")
				mainFrame.Visible = false
				mainFrame.Position = defaultPos
			end
		end)
		order = order + 1
	end
end

if syncButton and syncButton:IsA("GuiButton") then
	syncButton.Visible = true
	syncButton.MouseButton1Click:Connect(function()
		print("[AvatarMenu] Carry button clicked!")
		if selectedPlayer then
			populateCarryOptions(selectedPlayer)
			showCarryOverlay()
			print("[AvatarMenu] carryOptionsSection shown. Visible:", carryOptionsSection.Visible, "Parent:", carryOptionsSection.Parent.Name, "Size:", carryOptionsSection.Size, "ZIndex:", carryOptionsSection.ZIndex)
		end
	end)
else
	warn("CarryButton not found; carry feature disabled.")
end

if giftButton and giftButton:IsA("GuiButton") then
	giftButton.Visible = true
	giftButton.MouseButton1Click:Connect(function()
		if selectedPlayer then
			local shopGui = playerGui:FindFirstChild("Shop")
			if shopGui then
				local toggle = shopGui:FindFirstChild("ToggleEvent")
				if toggle then
					toggle:Fire(true, selectedPlayer.UserId)
					if type(closeAvatarMenu) == "function" then
						closeAvatarMenu()
					else
						warn("closeAvatarMenu is nil in Gift callback! Forcing close.")
						mainFrame.Visible = false
						mainFrame.Position = defaultPos
					end
				end
			end
		end
	end)
else
	warn("GiftButton not found; gifting feature disabled.")
end

if chatButton and chatButton:IsA("GuiButton") then
	local function openPrivateChatToTarget(targetPlayer)
		-- Legacy fallback yang paling kompatibel untuk Private Chat di Avatar Context Menu
		local ok = pcall(function()
			StarterGui:SetCore("ChatBarText", "/w " .. targetPlayer.Name .. " ")
		end)
		return ok
	end

	chatButton.MouseButton1Click:Connect(function()
		if not selectedPlayer then return end

		local opened = openPrivateChatToTarget(selectedPlayer)
		if not opened then
			warn("Private chat channel unavailable for target:", selectedPlayer.Name)
		end

		closeAvatarMenu()
	end)
end

if hideAvatarButton and hideAvatarButton:IsA("GuiButton") then
	updateHideAvatarButtonText(nil)
	hideAvatarButton.MouseButton1Click:Connect(function()
		if not selectedPlayer then
			return
		end

		local shouldHide = not isAvatarHidden(selectedPlayer)
		setAvatarHidden(selectedPlayer, shouldHide)
		updateHideAvatarButtonText(selectedPlayer)
		closeAvatarMenu()
	end)
else
	warn("Hide avatar button not found.")
end


if addFriendButton and addFriendButton:IsA("GuiButton") then
	addFriendButton.MouseButton1Click:Connect(function()
		if selectedPlayer then
			pcall(function() player:RequestFriendship(selectedPlayer) end)
			closeAvatarMenu()
		end
	end)
else
	warn("Add friend button not found.")
end

if currentlyWearingBackButton and currentlyWearingBackButton:IsA("GuiButton") then
	currentlyWearingBackButton.MouseButton1Click:Connect(function()
		if #currentlyWearingItems <= 0 then
			return
		end

		moveCurrentlyWearingByStep(-1)
	end)
end

if currentlyWearingForwardButton and currentlyWearingForwardButton:IsA("GuiButton") then
	currentlyWearingForwardButton.MouseButton1Click:Connect(function()
		if #currentlyWearingItems <= 0 then
			return
		end

		moveCurrentlyWearingByStep(1)
	end)
end

if currentlyWearingBuyAllButton and currentlyWearingBuyAllButton:IsA("GuiButton") then
	currentlyWearingBuyAllButton.MouseButton1Click:Connect(function()
		if buyAllIsRunning then
			cancelBuyAllQueue()
			return
		end
		if not selectedPlayer then
			return
		end
		if #currentlyWearingItems <= 0 then
			return
		end

		startBuyAllQueue()
	end)
end

if closeButton or quitButton or hideButton then
	local connectedCloseTargets = {}
	local function connectUniqueCloseTarget(target)
		if not target or connectedCloseTargets[target] then
			return
		end
		for existingTarget, _ in pairs(connectedCloseTargets) do
			if target:IsDescendantOf(existingTarget) or existingTarget:IsDescendantOf(target) then
				return
			end
		end
		connectedCloseTargets[target] = true
		connectCloseHandler(target)
	end

	connectUniqueCloseTarget(quitButton)
	connectUniqueCloseTarget(hideButton)
	connectUniqueCloseTarget(closeButton)
else
	warn("CloseButton not found.")
end

local syncLeaderAttributeConnections = {}
local function bindSyncLeaderAttribute(playerObject)
	if not playerObject or syncLeaderAttributeConnections[playerObject] then
		return
	end

	syncLeaderAttributeConnections[playerObject] = playerObject:GetAttributeChangedSignal("SyncLeaderUserId"):Connect(function()
		if selectedPlayer then
			updateFollowersLabel(selectedPlayer)
		end
	end)
end

for _, otherPlayer in ipairs(Players:GetPlayers()) do
	bindSyncLeaderAttribute(otherPlayer)
end

Players.PlayerAdded:Connect(function(joinedPlayer)
	bindSyncLeaderAttribute(joinedPlayer)
	if selectedPlayer then
		updateFollowersLabel(selectedPlayer)
	end
end)

-- CLICK DETECTION dengan Mouse.Button1Down
mouse.Button1Down:Connect(function()
	-- jika menu sedang terbuka jangan buka lagi
	if mainFrame.Visible then return end

	local target = mouse.Target
	if not target then return end

	local model = target:FindFirstAncestorOfClass("Model")
	if not model then return end

	local targetPlayer = Players:GetPlayerFromCharacter(model)
	if not targetPlayer or targetPlayer == player then return end

	---------------------------------------------------------
	-- CAMERA DISTANCE CHECK
	---------------------------------------------------------
	local camera = workspace.CurrentCamera
	local camPos = camera.CFrame.Position

	local root2 = model:FindFirstChild("HumanoidRootPart")
	if not root2 then return end

	local distance = (camPos - root2.Position).Magnitude
	local maxCamDistance = 35

	if distance > maxCamDistance then
		print("Camera terlalu jauh:", distance)
		return
	end
	---------------------------------------------------------

	print("Player clicked:", targetPlayer.Name, "CameraDist:", distance)
	openAvatarMenu(targetPlayer)
end)


-- CLOSE MENU KETIKA ESC
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.Escape and mainFrame.Visible then
		closeAvatarMenu()
	end
end)

-- Helpers: cek apakah animation adalah emote (dari folder Emotes)
local emoteIdLookup = {}
local function rebuildEmoteIdLookup()
	table.clear(emoteIdLookup)
	for _, emote in ipairs(EmotesFolder:GetChildren()) do
		if emote and emote:IsA("Animation") and typeof(emote.AnimationId) == "string" and emote.AnimationId ~= "" then
			emoteIdLookup[emote.AnimationId] = true
		end
	end
end

rebuildEmoteIdLookup()
EmotesFolder.ChildAdded:Connect(rebuildEmoteIdLookup)
EmotesFolder.ChildRemoved:Connect(rebuildEmoteIdLookup)

local function isEmoteAnimation(anim)
	return anim and typeof(anim.AnimationId) == "string" and emoteIdLookup[anim.AnimationId] == true
end

-- Broadcast state ke server (dipanggil tiap heartbeat)
local function broadcastMyState()
	if next(myFollowers) == nil then
		return
	end

	if not player.Character then return end
	local animator = getAnimatorFromCharacter(player.Character)
	if not animator then return end

	local tracks = animator:GetPlayingAnimationTracks()
	local currentState = {}
	local forceStopNow = false

	for _, track in ipairs(tracks) do
		if track.IsPlaying and track.Animation and isEmoteAnimation(track.Animation) then
			table.insert(currentState, {
				AnimId = track.Animation.AnimationId,
				TimePos = track.TimePosition,
				Speed = track.Speed,
				Priority = track.Priority
			})
		end
	end

	table.sort(currentState, function(a, b)
		return a.AnimId < b.AnimId
	end)

	local now = os.clock()
	if #currentState > 0 then
		lastNonEmptyStateAt = now
	elseif #lastSentState > 0 and (now - lastNonEmptyStateAt) < SYNC_CONFIG.EmptyStateGrace then
		-- If leader actually stopped dancing, push empty state immediately.
		local danceName = player:GetAttribute("DanceName")
		if danceName == "" then
			forceStopNow = true
		else
			-- Prevent 1-frame empty-state gaps during rapid spam switching.
			currentState = lastSentState
		end
	end

	local stateChanged = #currentState ~= #lastSentState
	if not stateChanged then
		for i, data in ipairs(currentState) do
			local last = lastSentState[i]
			if not last
				or last.AnimId ~= data.AnimId
				or math.abs(last.TimePos - data.TimePos) > SYNC_CONFIG.StateTimeThreshold
				or math.abs((last.Speed or 1) - (data.Speed or 1)) > SYNC_CONFIG.SpeedThreshold then
				stateChanged = true
				break
			end
		end
	end

	if stateChanged and (now - lastBroadcastAt >= SYNC_CONFIG.BroadcastMinInterval or #currentState ~= #lastSentState) then
		local payload = packSyncPayload(currentState, forceStopNow)
		pcall(function() syncBroadcast:FireServer(payload) end)
		lastSentState = currentState
		lastBroadcastAt = now
	end

	-- update followers locally
	pcall(function() updateFollowersLocally(currentState, forceStopNow) end)
end

-- Update followers local function (maintain follower animations)
function updateFollowersLocally(animationState, forceStopNow)
	local stateMap = {}
	local now = os.clock()
	for _, data in ipairs(animationState) do
		stateMap[data.AnimId] = data
	end
	local hasIncomingTracks = next(stateMap) ~= nil

	for follower, followerData in pairs(myFollowers) do
		if not follower.Character then continue end

		local animator, humanoid = getAnimatorFromCharacter(follower.Character)
		if not animator then continue end
		if not followerData.targets then
			followerData.targets = {}
		end

		if forceStopNow and not hasIncomingTracks then
			for animId, track in pairs(followerData.tracks) do
				pcall(function() track:Stop(SYNC_CONFIG.TrackHardStopFade) end)
				followerData.tracks[animId] = nil
				followerData.targets[animId] = nil
			end
			continue
		end

		-- stop tracks not in stateMap
		for animId, track in pairs(followerData.tracks) do
			if not stateMap[animId] then
				if hasIncomingTracks then
					pcall(function() track:Stop(SYNC_CONFIG.TrackSwitchFade) end)
					followerData.tracks[animId] = nil
					followerData.targets[animId] = nil
					continue
				end

				local target = followerData.targets[animId]
				if target then
					target.missingSince = target.missingSince or now
					if (now - target.missingSince) < SYNC_CONFIG.MissingTrackGrace then
						continue
					end
				end
				pcall(function() track:Stop(SYNC_CONFIG.TrackStopFade) end)
				followerData.tracks[animId] = nil
				followerData.targets[animId] = nil
			end
		end

		-- register/update target states from leader
		for animId, data in pairs(stateMap) do
			local track = followerData.tracks[animId]
			local speed = sanitizeSpeed(data.Speed)
			local priority = sanitizePriority(data.Priority)
			local timePos = tonumber(data.TimePos) or 0

			if not track then
				track = loadTrackFromAnimationId(animator, data.AnimId)
				if not track then
					continue
				end
				track.Priority = priority
				followerData.tracks[animId] = track
				pcall(function()
					track:Play(SYNC_CONFIG.TrackStartFade)
					track.TimePosition = timePos
				end)
			end

			forceR6SyncTrack(follower.Character, animator, humanoid, track, SYNC_CONFIG.TrackStartFade)

			if math.abs(track.Speed - speed) > SYNC_CONFIG.SpeedThreshold then
				pcall(function() track:AdjustSpeed(speed) end)
			end

			followerData.targets[animId] = {
				baseTimePos = timePos,
				receivedAt = now,
				speed = speed,
				missingSince = nil,
			}
		end
	end
end

local function applyPredictedTrackSync(track, target, now, dt, snapThreshold, microIgnore, lerpFactor)
	if not track or not target then
		return
	end

	local predictionElapsed = math.max(0, (now - target.receivedAt) - SYNC_CONFIG.PredictionBackTime)
	local expectedPos = target.baseTimePos + predictionElapsed * target.speed
	local delta = expectedPos - track.TimePosition
	local length = track.Length
	if track.Looped and typeof(length) == "number" and length > 0.001 then
		delta = (delta + length * 0.5) % length - length * 0.5
		expectedPos = track.TimePosition + delta
	end
	local absDelta = math.abs(delta)

	if absDelta > snapThreshold then
		track.TimePosition = expectedPos
	elseif absDelta > microIgnore then
		local correction = delta * lerpFactor
		local maxCorrection = SYNC_CONFIG.MaxCorrectionPerSecond * math.max(dt, 1 / 240)
		if math.abs(correction) > maxCorrection then
			correction = (correction > 0 and 1 or -1) * maxCorrection
		end
		track.TimePosition = track.TimePosition + correction
	end

	if math.abs(track.Speed - target.speed) > SYNC_CONFIG.SpeedThreshold then
		pcall(function() track:AdjustSpeed(target.speed) end)
	end
end

local function stepFollowerTracks(dt)
	local now = os.clock()
	for follower, followerData in pairs(myFollowers) do
		if not follower.Character or not followerData.targets then
			continue
		end

		for animId, track in pairs(followerData.tracks) do
			local target = followerData.targets[animId]
			applyPredictedTrackSync(
				track,
				target,
				now,
				dt,
				SYNC_CONFIG.LocalFollowerSnapThreshold,
				SYNC_CONFIG.LocalFollowerMicroIgnore,
				SYNC_CONFIG.LocalFollowerLerpFactor
			)
		end
	end
end

-- RECEIVING BROADCAST: leader -> follower (apply to me)
syncBroadcast.OnClientEvent:Connect(function(leader, syncPayload)
	if not isSyncing or leader ~= syncedLeader then return end
	if not player.Character then return end

	local animator, humanoid = getAnimatorFromCharacter(player.Character)
	if not animator then return end

	local animationState, payloadSentAt, payloadSeq, forceStopNow = unpackSyncPayload(syncPayload)
	if not animationState then
		return
	end
	if typeof(payloadSeq) == "number" then
		if lastAcceptedSyncSeq and payloadSeq <= lastAcceptedSyncSeq then
			return
		end
		lastAcceptedSyncSeq = payloadSeq
	end

	local serverNow = workspace:GetServerTimeNow()
	local transportDelay = 0
	if typeof(payloadSentAt) == "number" then
		transportDelay = clampTransportDelay(serverNow - payloadSentAt)
	end

	local stateMap = {}
	for _, data in ipairs(animationState) do
		if typeof(data) == "table" and typeof(data.AnimId) == "string" and data.AnimId ~= "" then
			local speed = sanitizeSpeed(data.Speed)
			local timePos = tonumber(data.TimePos) or 0
			stateMap[data.AnimId] = {
				AnimId = data.AnimId,
				TimePos = timePos + transportDelay * speed,
				Speed = speed,
				Priority = sanitizePriority(data.Priority),
			}
		end
	end
	local hasIncomingTracks = next(stateMap) ~= nil

	local now = os.clock()

	if forceStopNow and not hasIncomingTracks then
		stopTrackMap(myTracks, mySyncTargets, SYNC_CONFIG.TrackHardStopFade)
		return
	end

	-- stop local tracks not present anymore
	for animId, track in pairs(myTracks) do
		if not stateMap[animId] then
			if hasIncomingTracks then
				pcall(function() track:Stop(SYNC_CONFIG.TrackSwitchFade) end)
				myTracks[animId] = nil
				mySyncTargets[animId] = nil
				continue
			end

			local target = mySyncTargets[animId]
			if target then
				target.missingSince = target.missingSince or now
				if (now - target.missingSince) < SYNC_CONFIG.MissingTrackGrace then
					continue
				end
			end
			pcall(function() track:Stop(SYNC_CONFIG.TrackStopFade) end)
			myTracks[animId] = nil
			mySyncTargets[animId] = nil
		end
	end

	-- play/update tracks from leader
	for animId, data in pairs(stateMap) do
		local track = myTracks[animId]
		local speed = sanitizeSpeed(data.Speed)
		local priority = sanitizePriority(data.Priority)
		local timePos = tonumber(data.TimePos) or 0

		if not track then
			track = loadTrackFromAnimationId(animator, data.AnimId)
			if not track then
				continue
			end
			track.Priority = priority
			myTracks[animId] = track
			pcall(function()
				track:Play(SYNC_CONFIG.TrackStartFade)
				track.TimePosition = timePos
			end)
		end

		forceR6SyncTrack(player.Character, animator, humanoid, track, SYNC_CONFIG.TrackStartFade)

		if math.abs(track.Speed - speed) > SYNC_CONFIG.SpeedThreshold then
			pcall(function() track:AdjustSpeed(speed) end)
		end

		mySyncTargets[animId] = {
			baseTimePos = timePos,
			receivedAt = now,
			speed = speed,
			missingSince = nil,
		}
	end
end)

local function stepMyTracks(dt)
	if not isSyncing then
		return
	end

	local now = os.clock()
	for animId, track in pairs(myTracks) do
		local target = mySyncTargets[animId]

		if not target then
			pcall(function() track:Stop(SYNC_CONFIG.TrackStopFade) end)
			myTracks[animId] = nil
			mySyncTargets[animId] = nil
			continue
		end

		if target.missingSince then
			if (now - target.missingSince) >= SYNC_CONFIG.MissingTrackGrace then
				pcall(function() track:Stop(SYNC_CONFIG.TrackStopFade) end)
				myTracks[animId] = nil
				mySyncTargets[animId] = nil
			end
			continue
		end

		applyPredictedTrackSync(
			track,
			target,
			now,
			dt,
			SYNC_CONFIG.FollowerSnapThreshold,
			SYNC_CONFIG.FollowerMicroIgnore,
			SYNC_CONFIG.FollowerLerpFactor
		)
	end

	releaseLocalR6SyncSuppressionIfIdle()
end

-- SYNC STATUS (server informs start/stop/follower add/remove)
syncStatus.OnClientEvent:Connect(function(status, targetPlayer)
	if status == "start" then
		syncedLeader = targetPlayer
		isSyncing = true
		lastAcceptedSyncSeq = nil
		updateSyncButtonVisual(selectedPlayer ~= nil and syncedLeader == selectedPlayer)

	elseif status == "stop" then
		syncedLeader = nil
		isSyncing = false
		lastAcceptedSyncSeq = nil

		stopTrackMap(myTracks, mySyncTargets, SYNC_CONFIG.TrackStopFade)
		updateSyncButtonVisual(false)

	elseif status == "follower_added" then
		local follower = targetPlayer
		if follower and follower ~= player then
			myFollowers[follower] = {tracks = {}, targets = {}}
		end

	elseif status == "follower_removed" then
		local follower = targetPlayer
		if myFollowers[follower] then
			for _, track in pairs(myFollowers[follower].tracks) do
				pcall(function() track:Stop(SYNC_CONFIG.TrackStopFade) end)
			end
			myFollowers[follower] = nil
		end
	end

	if selectedPlayer then
		updateFollowersLabel(selectedPlayer)
	end
end)

-- HEARTBEAT: broadcast my animation state periodically
RunService.Heartbeat:Connect(function(dt)
	broadcastMyState()
	stepMyTracks(dt)
	stepFollowerTracks(dt)
end)

-- Bersihkan follower ketika respawn / character added
player.CharacterAdded:Connect(function()
	setLocalDefaultAnimateSuppressed(false)
	for follower, data in pairs(myFollowers) do
		for _, track in pairs(data.tracks) do
			pcall(function() track:Stop(SYNC_CONFIG.TrackStopFade) end)
		end
	end
	myFollowers = {}
	myTracks = {}
	mySyncTargets = {}
	lastSentState = {}
	lastBroadcastAt = 0
	lastNonEmptyStateAt = 0
	lastAcceptedSyncSeq = nil
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	local userId = leavingPlayer.UserId
	hiddenAvatarUserIds[userId] = nil
	clearHiddenConnection(userId)

	local attrConnection = syncLeaderAttributeConnections[leavingPlayer]
	if attrConnection then
		attrConnection:Disconnect()
		syncLeaderAttributeConnections[leavingPlayer] = nil
	end

	if selectedPlayer == leavingPlayer then
		closeAvatarMenu()
	elseif selectedPlayer then
		updateFollowersLabel(selectedPlayer)
	end
end)

