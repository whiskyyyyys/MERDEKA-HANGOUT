local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)

local client = players.LocalPlayer

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local MainModule = require(storage.modules.MainModule) 
local Utilities = require(storage.modules.Utilities) 
local Configuration = require(storage.modules.Configuration)

local navigation = script.Parent
local directory = navigation.directory
local fixed_buttons = navigation.fixed_buttons
local user = navigation.user

function display_role()
	repeat task.wait() until client:HasTag("Exe6PersonLoaded")
	
	local authorized = events.auth.Auth:InvokeServer("IsAuthorized", client.UserId)
	if not authorized then return end
	
	user.frame.role.Text = authorized.Role.Alias
	user.frame.role.BackgroundColor3 = authorized.Role.Accent
	user.frame.role.TextColor3 = Utilities.AdjustColor(authorized.Role.Accent)
	
	user.frame.profile.Image = Utilities.GetPlayerThumbnail(client.UserId)
	user.frame.display.Text = client.DisplayName
	
	user.frame.MouseButton1Click:Connect(function()
		MainModule.Profile(true, players.LocalPlayer.UserId, user.frame)
	end)
	
	user.frame.MouseEnter:Connect(function()
		tween_service:Create(user.frame, info, {BackgroundColor3 = Color3.fromRGB(47, 47, 47)}):Play()
	end)
	
	user.frame.MouseButton1Down:Connect(function()
		tween_service:Create(user.frame, info, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
	end)
	
	user.frame.InputEnded:Connect(function()
		tween_service:Create(user.frame, info, {BackgroundColor3 = Color3.fromRGB(34, 34, 34)}):Play()
	end)
end

function run()
	for i, button in pairs(directory:GetDescendants()) do
		if button:IsA("ImageButton") and button:HasTag("Exe6ScreenButton") then

			button.MouseButton1Click:Connect(function()
				if button.util.screen_directory.Value ~= MainModule.CurrentScreen() then
					MainModule.GoToScreen(button.util.screen_directory.Value)
					
					if navigation.Parent.Parent:GetAttribute("PortraitMode") then
						MainModule.NavigationMenu(false)
					end
				end
			end)

		end
	end
end

navigation.fixed_buttons.system.MouseButton1Click:Connect(function()
	MainModule.GoToScreen(navigation.Parent.screen.system)
end)

function CalibratePermissions()
	local authorized = events.auth.Auth:InvokeServer("IsAuthorized", client.UserId)
	
	local ViewAuditLogs = events.auth.Auth:InvokeServer("GetRoleSetting", authorized.Role.Alias, 
		"ViewAuditLogs")
	
	if ViewAuditLogs then
		navigation.directory.primary.audits.Visible = true
	else
		navigation.directory.primary.audits.Visible = false
	end
	
end

display_role()
run()
CalibratePermissions()