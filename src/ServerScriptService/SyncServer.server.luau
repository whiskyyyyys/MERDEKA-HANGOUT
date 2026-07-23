local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- RemoteEvents
local syncRemote = ReplicatedStorage:FindFirstChild("Sync") or Instance.new("RemoteEvent", ReplicatedStorage)
syncRemote.Name = "Sync"

local syncStatus = ReplicatedStorage:FindFirstChild("SyncStatus") or Instance.new("RemoteEvent", ReplicatedStorage)
syncStatus.Name = "SyncStatus"

local syncBroadcast = ReplicatedStorage:FindFirstChild("SyncBroadcast") or Instance.new("RemoteEvent", ReplicatedStorage)
syncBroadcast.Name = "SyncBroadcast"

local EmotesFolder = ReplicatedStorage:WaitForChild("Emotes")

-- [leader] = { followers = { follower1, follower2, ... } }
local syncGroups = {}
local pendingBroadcastByLeader = {}
local nextRelayAtByLeader = {}
local RELAY_INTERVAL = 1 / 50

local function packSyncPayload(tracks, sentAt, seq, forceStop)
	return {
		tracks = tracks,
		sentAt = sentAt or workspace:GetServerTimeNow(),
		seq = seq,
		forceStop = forceStop == true,
	}
end

local function unpackSyncPayload(payload)
	if typeof(payload) ~= "table" then
		return nil, nil, nil, false
	end

	if typeof(payload.tracks) == "table" then
		return payload.tracks, payload.sentAt, payload.seq, payload.forceStop == true
	end

	return payload, payload.sentAt, payload.seq, payload.forceStop == true
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

local function isEmoteAnimation(anim)
	if not anim or not hasValidAnimationId(anim) then
		return false
	end

	for _, emote in ipairs(EmotesFolder:GetChildren()) do
		if hasValidAnimationId(emote) and anim.AnimationId == emote.AnimationId then
			return true
		end
	end

	return false
end

local function isFollowingLeader(leader, follower)
	local group = syncGroups[leader]
	if not group then
		return false
	end

	for _, candidate in ipairs(group.followers) do
		if candidate == follower then
			return true
		end
	end

	return false
end

local function removeFollowerFromGroup(leader, follower, notifyLeader)
	local group = syncGroups[leader]
	if not group then
		return false
	end

	local removed = false
	for i = #group.followers, 1, -1 do
		if group.followers[i] == follower then
			table.remove(group.followers, i)
			removed = true
		end
	end

	if removed and follower and follower:IsDescendantOf(game) then
		pcall(function()
			follower:SetAttribute("SyncLeaderUserId", nil)
		end)
	end

	if removed and notifyLeader and leader and leader:IsDescendantOf(game) then
		syncStatus:FireClient(leader, "follower_removed", follower)
	end

	if #group.followers == 0 then
		syncGroups[leader] = nil
		pendingBroadcastByLeader[leader] = nil
		nextRelayAtByLeader[leader] = nil
	end

	return removed
end

local function removeFollowerFromAllGroups(follower, skipLeader)
	local removedAny = false
	for leader in pairs(syncGroups) do
		if leader ~= skipLeader then
			local removed = removeFollowerFromGroup(leader, follower, true)
			if removed then
				removedAny = true
			end
		end
	end
	return removedAny
end

local function relayLeaderState(leader, payload, now)
	if typeof(payload) ~= "table" then
		return
	end

	local group = syncGroups[leader]
	if not group or #group.followers == 0 then
		syncGroups[leader] = nil
		pendingBroadcastByLeader[leader] = nil
		nextRelayAtByLeader[leader] = nil
		return
	end

	for i = #group.followers, 1, -1 do
		local follower = group.followers[i]
		if follower and follower:IsDescendantOf(game) and follower ~= leader then
			syncBroadcast:FireClient(follower, leader, payload)
		else
			table.remove(group.followers, i)
		end
	end

	if #group.followers == 0 then
		syncGroups[leader] = nil
		pendingBroadcastByLeader[leader] = nil
		nextRelayAtByLeader[leader] = nil
		return
	end

	nextRelayAtByLeader[leader] = now + RELAY_INTERVAL
end

-- REQUEST SYNC
syncRemote.OnServerEvent:Connect(function(player, targetPlayer, action)
	if action == "sync" then
		if not targetPlayer or targetPlayer == player or not targetPlayer:IsA("Player") then
			return
		end

		-- A follower can only have one leader at a time.
		removeFollowerFromAllGroups(player, targetPlayer)

		if not syncGroups[targetPlayer] then
			syncGroups[targetPlayer] = {followers = {}}
		end

		if not isFollowingLeader(targetPlayer, player) then
			table.insert(syncGroups[targetPlayer].followers, player)
			pcall(function()
				player:SetAttribute("SyncLeaderUserId", targetPlayer.UserId)
			end)
			syncStatus:FireClient(targetPlayer, "follower_added", player)
		end

		-- Send initial state from leader to follower.
		local leaderChar = targetPlayer.Character
		if leaderChar then
			local hum = leaderChar:FindFirstChild("Humanoid")
			local animator = hum and hum:FindFirstChild("Animator")
			if animator then
				local tracks = animator:GetPlayingAnimationTracks()
				local initialState = {}

				for _, track in ipairs(tracks) do
					if track.IsPlaying and isEmoteAnimation(track.Animation) then
						table.insert(initialState, {
							AnimId = track.Animation.AnimationId,
							TimePos = track.TimePosition,
							Speed = track.Speed,
							Priority = track.Priority
						})
					end
				end

				syncBroadcast:FireClient(player, targetPlayer, packSyncPayload(initialState, workspace:GetServerTimeNow(), 0, false))
			end
		end

		syncStatus:FireClient(player, "start", targetPlayer)

	elseif action == "unsync" then
		removeFollowerFromAllGroups(player)
		pcall(function()
			player:SetAttribute("SyncLeaderUserId", nil)
		end)
		-- Always send stop for client-side safety cleanup.
		syncStatus:FireClient(player, "stop")
	end
end)

-- LEADER BROADCAST STATE
syncBroadcast.OnServerEvent:Connect(function(leader, payload)
	local group = syncGroups[leader]
	if not group or #group.followers == 0 then
		return
	end
	local animationState, sentAt, seq, forceStop = unpackSyncPayload(payload)
	if typeof(animationState) ~= "table" then
		return
	end

	-- Keep only the most recent state; older intermediate states are dropped.
	pendingBroadcastByLeader[leader] = packSyncPayload(animationState, sentAt, seq, forceStop)

	local now = os.clock()
	if now >= (nextRelayAtByLeader[leader] or 0) then
		local queued = pendingBroadcastByLeader[leader]
		pendingBroadcastByLeader[leader] = nil
		relayLeaderState(leader, queued, now)
	end
end)

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for leader, payload in pairs(pendingBroadcastByLeader) do
		if now < (nextRelayAtByLeader[leader] or 0) then
			continue
		end

		pendingBroadcastByLeader[leader] = nil
		relayLeaderState(leader, payload, now)
	end
end)

-- CLEANUP
Players.PlayerRemoving:Connect(function(player)
	-- Player leaves as leader.
	local group = syncGroups[player]
	if group then
		for _, follower in ipairs(group.followers) do
			if follower and follower:IsDescendantOf(game) then
				pcall(function()
					follower:SetAttribute("SyncLeaderUserId", nil)
				end)
				syncStatus:FireClient(follower, "stop")
			end
		end
		syncGroups[player] = nil
	end
	pendingBroadcastByLeader[player] = nil
	nextRelayAtByLeader[player] = nil

	-- Player leaves as follower.
	removeFollowerFromAllGroups(player)
	pcall(function()
		player:SetAttribute("SyncLeaderUserId", nil)
	end)
end)
