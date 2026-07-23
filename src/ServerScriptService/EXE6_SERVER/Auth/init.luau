--// TERMS

export type RoleSettings = 
	"Accent" |

"Kickable" |
"Bannable" |
"Warnable" |

"AuditActivities" |
"AuditWebhooks" |

"ViewProfile" |
"ViewChatHistory" |
"ViewWarnHistory" |

"Kick" |
"Notify" |
"Warn" |
"ConfigureHumanoid" |
"ConfigureCharacter"|
"Fly" |

"Ban" |
"ServerBan" |
"Unban" |
"ServerUnban" |

"ServerAnnouncement" |
"GlobalAnnouncement" |

"ViewAuditLogs" |
"ServerPrivacy" |

"ServerTeleportation"

--// FUNCTIONS

local run_service = game:GetService("RunService")
local group_service = game:GetService("GroupService")
local players = game:GetService("Players")

local module = {}

function module.GetRoles()
	local folder = script.Roles
	local index = {}

	for i, Role in pairs(folder:GetChildren()) do
		if Role:IsA("Configuration") then
			local Items = {}

			for prop, value in pairs(Role:GetAttributes()) do
				Items[prop] = value
			end

			Items["Alias"] = Role.Name

			index[Role.Name] = Items
		end
	end

	return index
end

function module.GetPlayers()
	local folder = script.Players
	local index = {}

	for i, Player in pairs(folder:GetChildren()) do
		if Player:IsA("Configuration") then
			local Items = {}

			Items["Active"] = Player:GetAttribute("Active")
			Items["Role"] = module.GetRoles()[Player:GetAttribute("Role")]

			index[Player.Name:lower()] = Items
		end
	end

	return index
end

function module.GetGroup()
	local folder = script.Groups
	local index = {}

	for i, Group in pairs(folder:GetChildren()) do
		if Group:IsA("Folder") then
			local Ranks = {}

			for i, rank in pairs(Group:GetChildren()) do
				Ranks[tonumber(rank.Name)] = {
					Active = rank:GetAttribute("Active"),
					Role = module.GetRoles()[rank:GetAttribute("Role")]
				}
			end

			index[tonumber(Group.Name)] = {Active = Group:GetAttribute("Active"), Ranks = Ranks}
		end
	end

	return index
end

function module.GetRanks(group_id)
	return module.GetGroup()[group_id].Ranks
end

function module.GetRoleNameFromRoleTable(RoleTable)
	return RoleTable.Alias
end

function module.IsPlayerPermitted(identifier)
	local username

	if typeof(identifier) == "number" then
		username = players:GetNameFromUserIdAsync(identifier):lower()

	elseif typeof(identifier) == "string" then
		username = identifier:lower()
	end

	if username then
		local authorized = module.GetPlayers()[username]

		if authorized and authorized.Active then
			return authorized
		else
			return nil
		end
	end
end

function module.IsRankPermitted(identifier)
	if typeof(identifier) ~= "number" then return end

	local success, groups = pcall(function()
		return group_service:GetGroupsAsync(identifier)
	end)

	if groups then
		for _, main_group in pairs(groups) do
			local auth_group = module.GetGroup()[main_group.Id]

			if auth_group and auth_group.Active then
				local auth_rank = auth_group.Ranks[main_group.Rank]

				if auth_rank and auth_rank.Active then
					return auth_rank
				else
					continue
				end
			else
				continue
			end
		end
	end

	return false
end

-- Is this user permitted
function module.IsAuthorized(id)
	local player = module.IsPlayerPermitted(id)
	local rank = module.IsRankPermitted(id)

	if player then
		return player

	elseif rank then
		return rank

	else
		return false
	end
end

function module.GetRoleByUserId(id)
	local player_permitted = module.IsPlayerPermitted(id)
	local rank_permitted = module.IsRankPermitted(id)

	if player_permitted then
		return module.GetRoleNameFromRoleTable(player_permitted)
	elseif rank_permitted then
		return module.GetRoleNameFromRoleTable(rank_permitted)
	end

	return false
end

function module.GetRoleByRank(rank, group_id)
	if module.GetGroup()[group_id].RANKS[rank] then
		return module.GetRoleNameFromRoleTable(module.GetGroup()[group_id].RANKS[rank])
	end

	return false
end

function module.GetRankInGroup(id)
	local groups = group_service:GetGroupsAsync(id)

	for _, main_group in ipairs(groups) do
		if table.find(module.GetGroup(), main_group.Id) then
			return main_group.Rank
		end
	end

	return nil
end

function module.GetRoleSetting(role, setting: RoleSettings)
	return module.GetRoles()[role][setting]
end

function module.PermissionCount(role)
	local role = module.GetRoles()[role]

	if not role then
		return 0
	end

	local permissionCount = 0

	for _, permission in pairs(role) do
		if type(permission) == "boolean" and permission then
			permissionCount = permissionCount + 1
		end
	end

	return permissionCount
end

function module.GetConfigurations()
	local Configs = script.Configuration
	local Index = {}

	for i, Set in pairs(Configs:GetChildren()) do		
		if Set:IsA("Folder") then
			local collection = {}

			for i, item in pairs(Set:GetChildren()) do
				table.insert(collection, item.Value)
			end

			Index[Set.Name] = collection
		elseif Set:IsA("Configuration") then
			local collection = {}

			for i, item in pairs(Set:GetAttributes()) do
				if i == "AccessKey" then
					local success, result = pcall(function()
						return Enum.KeyCode[item]
					end)

					if success then
						collection[i] = result
					else
						collection[i] = Enum.KeyCode.F2
					end
				else
					collection[i] = item
				end
			end

			Index[Set.Name] = collection
		end
	end
	
	if run_service:IsClient() and not run_service:IsStudio() then
		Index.Auditing.WebhookLink = ""
	end

	return Index
end

return module