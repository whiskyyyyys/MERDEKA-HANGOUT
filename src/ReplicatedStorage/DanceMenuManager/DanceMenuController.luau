-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local l_TweenService_0 = game:GetService("TweenService");
local _ = game:GetService("Players");
local l_UserInputService_0 = game:GetService("UserInputService");
local l_StarterGui_0 = game:GetService("StarterGui");
local _ = game:GetService("TextChatService");
local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage");
local l_LocalPlayer_0 = game.Players.LocalPlayer;
local v7 = TweenInfo.new(0.5, Enum.EasingStyle.Exponential);
local v7_1 = UDim2.new(0, -10, 0.5, 0);
local v7_2 = 0.85;
local v7_3 = 64;
local v8 = require(script.Parent.SeatedEmotes);
local v9 = require(l_ReplicatedStorage_0.Menus.ControllerNavigationManager);
local function v10_3(v11, v12)
    if not v11 then
        return;
    else
        local v13 = v12 and 0 or 1;
        local v14 = v11:FindFirstChild("bar", true);
        local v15 = v14 and v14:FindFirstChildOfClass("UIStroke");
        local v16 = TweenInfo.new(v12 and 0.14 or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
        if v11:IsA("GuiObject") then
            v11.BackgroundTransparency = 1;
            if v11:IsA("TextButton") or v11:IsA("TextLabel") or v11:IsA("TextBox") then
                v11.TextTransparency = 1;
            end;
        end;
        if v14 and v14:IsA("GuiObject") then
            l_TweenService_0:Create(v14, v16, {
                BackgroundTransparency = v13
            }):Play();
        end;
        if v15 then
            l_TweenService_0:Create(v15, v16, {
                Transparency = v13
            }):Play();
        end;
        return;
    end;
end;
local v10 = {};
v10.__index = v10;
v10.new = function(v14) --[[ Line: 23 ]] --[[ Name: new ]]
    -- upvalues: v10 (copy), l_LocalPlayer_0 (copy)
    local v15 = setmetatable({}, v10);
    v15.Menu = v14;
    v15.Opened = true;
    v15._activeTweens = {};
    v15._defaultOpenPosition = UDim2.new(0, 4, 0.5, 0);
    v15._openPosition = v15._defaultOpenPosition;
    v15._dragging = false;
    v15._dragStart = nil;
    v15._menuStartAbsPosition = nil;
    v15._dragMoved = false;
    v15._dragHandle = nil;
    v15._dragHandleFadeToken = 0;
    v15:_connectCloseMethod();
    v15:_connectDrag();
    v15:_listenSeated();
    l_LocalPlayer_0.CharacterAdded:Connect(function() --[[ Line: 33 ]]
        -- upvalues: v15 (copy)
        v15:_listenSeated();
    end);
    v15:_listenKeyboard();
    return v15;
end;
v10._showDragHandle = function(v12) --[[ Line: 45 ]] --[[ Name: _showDragHandle ]]
    local v13 = v12._dragHandle or v12:_ensureDragHandle();
    if not v13 then
        return;
    else
        v12._dragHandleFadeToken = v12._dragHandleFadeToken + 1;
        v10_3(v13, true);
        return;
    end;
end;
v10._fadeDragHandleAfterDelay = function(v14) --[[ Line: 53 ]] --[[ Name: _fadeDragHandleAfterDelay ]]
    local v15 = v14._dragHandle or v14:_ensureDragHandle();
    if not v15 then
        return;
    else
        local v16 = v14._dragHandleFadeToken + 1;
        v14._dragHandleFadeToken = v16;
        task.delay(v7_2, function() --[[ Line: 59 ]]
            -- upvalues: v14 (copy), v16 (copy), v15 (copy)
            if v14._dragHandleFadeToken ~= v16 then
                return;
            elseif not v15.Parent then
                return;
            else
                v10_3(v15, false);
                return;
            end;
        end);
        return;
    end;
end;
v10._setToggleSelected = function(v13) --[[ Line: 46 ]] --[[ Name: _setToggleSelected ]]
    -- upvalues: v7 (copy)
    if v13.Menu and v13.Menu:FindFirstChild("Quit") then
        v13:_tween(v13.Menu.Quit, v7, {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        });
        if v13.Menu.Quit:FindFirstChild("ImageLabel") then
            v13:_tween(v13.Menu.Quit.ImageLabel, v7, {
                ImageColor3 = Color3.fromRGB(0, 0, 0)
            });
        end
    end
end;
v10._setToggleDeselected = function(v14) --[[ Line: 55 ]] --[[ Name: _setToggleDeselected ]]
    -- upvalues: v7 (copy)
    if v14.Menu and v14.Menu:FindFirstChild("Quit") then
        v14:_tween(v14.Menu.Quit, v7, {
            BackgroundColor3 = Color3.fromRGB(18, 18, 20)
        });
        if v14.Menu.Quit:FindFirstChild("ImageLabel") then
            v14:_tween(v14.Menu.Quit.ImageLabel, v7, {
                ImageColor3 = Color3.fromRGB(255, 255, 255)
            });
        end
    end
end;
v10._closeMenu = function(v15) --[[ Line: 66 ]] --[[ Name: _closeMenu ]]
    -- upvalues: l_StarterGui_0 (copy), v7 (copy), v9 (copy)
    v15._openPosition = v15._defaultOpenPosition;
    v15:_resetDragState();
    l_StarterGui_0:SetAttribute("DanceMenuOpen", false);
    v15:_setToggleDeselected();
    if v15.Menu then
        v15.Menu.Visible = false;
    end
    v9.stopCrossNavigation();
end;
v10._openMenu = function(v16) --[[ Line: 76 ]] --[[ Name: _openMenu ]]
    -- upvalues: l_StarterGui_0 (copy), v7 (copy), v9 (copy)
    local v17 = v16._openPosition or v16._defaultOpenPosition;
    v16:_resetDragState();
    l_StarterGui_0:SetAttribute("DanceMenuOpen", true);
    v16:_setToggleSelected();
    if v16.Menu then
        v16.Menu.Visible = true;
    end
    if v16.controllerNavigation then
        v16.controllerNavigation:Destroy();
        v16.controllerNavigation = nil;
    end;
    v16:_showDragHandle();
    v16:_fadeDragHandleAfterDelay();
    v9.initCrossNavigation(v16.Menu.Dances, function() --[[ Line: 87 ]]
        -- upvalues: v16 (copy)
        v16:_stopTweens();
        v16:_closeMenu();
        v16.Opened = true;
    end);
end;
v10._connectCloseMethod = function(v17) --[[ Line: 94 ]] --[[ Name: _connectCloseMethod ]]
    local v18 = v17.Menu:FindFirstChild("Quit");
    if v18 then
        if v18:IsA("GuiButton") then
            v18.Activated:Connect(function()
                -- upvalues: v17 (copy)
                v17:_onToggle();
            end);
        else
            v18.MouseButton1Click:Connect(function() --[[ Line: 96 ]]
                -- upvalues: v17 (copy)
                v17:_onToggle();
            end);
        end;
    end;
end;
v10._ensureDragHandle = function(v18) --[[ Line: 101 ]] --[[ Name: _ensureDragHandle ]]
    local v19 = v18.Menu:FindFirstChild("GrabBar");
    if v19 and v19:IsA("GuiButton") then
        v19.BackgroundTransparency = 1;
        if v19:IsA("TextButton") then
            v19.TextTransparency = 1;
            v19.AutoButtonColor = false;
        end;
        v18._dragHandle = v19;
        return v19;
    end;
    warn("[DanceMenu] GrabBar not found. Drag disabled.");
    return nil;
end;
v10._resetDragState = function(v18) --[[ Line: 101 ]] --[[ Name: _resetDragState ]]
    v18._dragging = false;
    v18._dragStart = nil;
    v18._menuStartAbsPosition = nil;
    v18._dragMoved = false;
end;
v10._connectDrag = function(v18) --[[ Line: 101 ]] --[[ Name: _connectDrag ]]
    -- upvalues: l_UserInputService_0 (copy), l_StarterGui_0 (copy)
    local v19 = v18:_ensureDragHandle();
    if not v19 then
        return;
    end;
    if v19:IsA("GuiObject") then
        v19.MouseEnter:Connect(function()
            -- upvalues: v18 (copy), l_StarterGui_0 (ref)
            if v18._seatedEmotes then
                return;
            elseif not l_StarterGui_0:GetAttribute("DanceMenuOpen") then
                return;
            else
                v18:_showDragHandle();
                v18:_fadeDragHandleAfterDelay();
                return;
            end;
        end);
    end;
    v19.InputBegan:Connect(function(v20) --[[ Line: 104 ]]
        -- upvalues: v18 (copy), l_StarterGui_0 (ref)
        if v18._seatedEmotes then
            return;
        elseif not l_StarterGui_0:GetAttribute("DanceMenuOpen") then
            return;
        elseif v20.UserInputType == Enum.UserInputType.MouseButton1 or v20.UserInputType == Enum.UserInputType.Touch then
            v18._dragging = true;
            v18._dragStart = v20.Position;
            v18._menuStartAbsPosition = v18.Menu.AbsolutePosition;
            v18._dragMoved = false;
            v18:_showDragHandle();
        end;
    end);
    l_UserInputService_0.InputChanged:Connect(function(v21) --[[ Line: 119 ]]
        -- upvalues: l_StarterGui_0 (ref), v18 (copy)
        if v21.UserInputType ~= Enum.UserInputType.MouseMovement and v21.UserInputType ~= Enum.UserInputType.Touch then
            return;
        elseif not l_StarterGui_0:GetAttribute("DanceMenuOpen") then
            v18:_resetDragState();
            return;
        elseif not v18._dragging then
            if v21.UserInputType == Enum.UserInputType.MouseMovement then
                local v22 = v18.Menu.AbsolutePosition;
                local v23 = v18.Menu.AbsoluteSize;
                local v24 = v21.Position;
                local v25 = v24.X >= v22.X and v24.X <= v22.X + v23.X;
                local v26 = v24.Y >= v22.Y and v24.Y <= v22.Y + math.min(v7_3, v23.Y);
                if v25 and v26 then
                    v18:_showDragHandle();
                    v18:_fadeDragHandleAfterDelay();
                end;
            end;
            return;
        else
            local v27 = v18.Menu.Parent;
            if not v27 then
                return;
            end;
            local v28 = v18.Menu.AbsoluteSize;
            local v29 = v27.AbsoluteSize;
            local v30 = v21.Position - v18._dragStart;
            local v31 = Vector2.new(v18._menuStartAbsPosition.X + v30.X, v18._menuStartAbsPosition.Y + v30.Y);
            local v32 = math.max(4, v29.X - v28.X - 4);
            local v33 = math.max(4, v29.Y - v28.Y - 4);
            local v34 = math.clamp(v31.X, 4, v32);
            local v35 = math.clamp(v31.Y, 4, v33);
            local v36 = v35 + v28.Y * 0.5 - v29.Y * 0.5;
            v18.Menu.Position = UDim2.new(0, v34, 0.5, v36);
            v18._openPosition = v18.Menu.Position;
            if not v18._dragMoved and v30.Magnitude > 8 then
                v18._dragMoved = true;
            end;
        end;
    end);
    l_UserInputService_0.InputEnded:Connect(function(v32) --[[ Line: 150 ]]
        -- upvalues: v18 (copy)
        if v32.UserInputType == Enum.UserInputType.MouseButton1 or v32.UserInputType == Enum.UserInputType.Touch then
            v18:_resetDragState();
            v18:_fadeDragHandleAfterDelay();
        end;
    end);
end;
v10._onToggle = function(v33) --[[ Line: 101 ]] --[[ Name: _onToggle ]]
    -- upvalues: l_StarterGui_0 (copy)
    if v33._seatedEmotes then
        return;
    elseif l_StarterGui_0:GetAttribute("IsNavegating") then
        return;
    else
        v33.Opened = not v33.Opened;
        v33:_stopTweens();
        if v33.Opened then
            v33:_closeMenu();
            return;
        else
            v33:_openMenu();
            return;
        end;
    end;
end;
v10._stopTweens = function(v19) --[[ Line: 119 ]] --[[ Name: _stopTweens ]]
    for _, v21 in next, v19._activeTweens do
        v21:Cancel();
        v21:Destroy();
        v21 = nil;
    end;
    table.clear(v19._activeTweens);
    v19._activeTweens = {};
end;
v10._tween = function(v22, v23, v24, v25) --[[ Line: 130 ]] --[[ Name: _tween ]]
    -- upvalues: l_TweenService_0 (copy)
    local v26 = l_TweenService_0:Create(v23, v24, v25);
    v26:Play();
    table.insert(v22._activeTweens, v26);
    return v26;
end;
v10._listenKeyboard = function(v27) --[[ Line: 138 ]] --[[ Name: _listenKeyboard ]]
    -- upvalues: l_UserInputService_0 (copy)
    l_UserInputService_0.InputBegan:Connect(function(v28, v29) --[[ Line: 139 ]]
        -- upvalues: v27 (copy)
        if v29 then
            return;
        else
            if v28.KeyCode == Enum.KeyCode.Q or v28.KeyCode == Enum.KeyCode.DPadDown then
                v27:_onToggle();
            end;
            return;
        end;
    end);
end;
v10._listenSeated = function(v30) --[[ Line: 151 ]] --[[ Name: _listenSeated ]]
    -- upvalues: l_LocalPlayer_0 (copy)
    local l_Character_0 = l_LocalPlayer_0.Character;
    local v32 = l_Character_0 and l_Character_0:WaitForChild("Humanoid");
    if v30._event then
        v30._event:Disconnect();
        v30._event = nil;
    end;
    v30._event = v32.Seated:Connect(function(v33, _) --[[ Line: 159 ]]
        -- upvalues: v30 (copy)
        v30:_deleteSeatedEmotes();
        if v33 then
            v30:_stopTweens();
            v30:_closeMenu();
            v30.Opened = true;
            v30:_startSeatedEmotes();
        end;
    end);
end;
v10._startSeatedEmotes = function(v35) --[[ Line: 172 ]] --[[ Name: _startSeatedEmotes ]]
    -- upvalues: v8 (copy)
    v35._seatedEmotes = v8.new(v35.Menu);
end;
v10._deleteSeatedEmotes = function(v36) --[[ Line: 176 ]] --[[ Name: _deleteSeatedEmotes ]]
    if v36._seatedEmotes then
        v36._seatedEmotes:Destroy();
        v36._seatedEmotes = nil;
    end;
end;
return v10;
