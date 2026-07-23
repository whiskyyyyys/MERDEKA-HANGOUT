-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage");
local l_Players_0 = game:GetService("Players");
local _ = game:GetService("UserInputService");
local l_Modules_0 = l_ReplicatedStorage_0:WaitForChild("Modules");
local v4 = require(script.Parent.Components.DanceButton);
local l_ConnectionManager_0 = require(l_Modules_0:WaitForChild("ConnectionManager"));
local l_NotificationManager_0 = require(l_Modules_0:WaitForChild("UIFeedback"):WaitForChild("NotificationManager"));
local v7 = require(l_Modules_0.nevermore.Signal);
local v8 = {};
v8.__index = v8;
v8.new = function(v9) --[[ Line: 19 ]] --[[ Name: new ]]
    -- upvalues: v8 (copy), v7 (copy)
    local v10 = setmetatable({}, v8);
    v10.Menu = v9;
    v10._mappedButtons = {};
    v10._buttonCategories = {};
    v10._onFavoriteAnimation = v7.new();
    local l_Dances_0 = v9:WaitForChild("Dances");
    local l_Dance_0 = l_Dances_0:FindFirstChild("Dance") or l_Dances_0:FindFirstChild("Dance1");
    v10._templateButton = l_Dance_0;
    if l_Dance_0 and l_Dance_0:IsA("GuiButton") then
        l_Dance_0.Visible = false;
    end;
    v10:_connectDanceChange();
    return v10;
end;
v8.SearchByQuery = function(v11, v12, v13) --[[ Line: 32 ]] --[[ Name: SearchByQuery ]]
    local v14 = type(v13) == "table" and v13 or nil;
    if not v12 and not v14 then
        return v11:_displayAllDances();
    else
        for v15, v16 in next, v11._mappedButtons do
            local v17 = v11:_checkVisibilityByText(v12, v15);
            local v18 = v14 and v11:_checkVisibilityByWhitelist(v15, v14) or (not v14);
            v16:SetVisible(v17 and v18);
            v16:MakeNormal();
        end;
        return;
    end;
end;
v8.RenderButtons = function(v17, v18) --[[ Line: 48 ]] --[[ Name: RenderButtons ]]
    v17:_createButtons(v18);
end;
v8.UpdateFavorites = function(v19, v20) --[[ Line: 52 ]] --[[ Name: UpdateFavorites ]]
    for v21, v22 in next, v19._mappedButtons do
        if table.find(v20, v21) then
            v22:SetIsFavorte(true);
        else
            v22:SetIsFavorte(false);
        end;
    end;
end;
v8.BindOnFavorite = function(v23, v24) --[[ Line: 63 ]] --[[ Name: BindOnFavorite ]]
    v23._onFavoriteAnimation:Connect(v24);
end;
v8.GetButton = function(v25, v26) --[[ Line: 67 ]] --[[ Name: GetButton ]]
    return v25._mappedButtons[v26];
end;
v8.GetNamesByCategory = function(v25, v26)
    local v27 = {};
    local v28 = string.lower(tostring(v26 or ""));
    for v29, v30 in pairs(v25._buttonCategories) do
        if v30 == v28 then
            table.insert(v27, v29);
        end;
    end;
    return v27;
end;
v8.DestroyButton = function(v30, v31) --[[ Line: 71 ]] --[[ Name: DestroyButton ]]
    local l_v30_Button_0 = v30:GetButton(v31);
    if l_v30_Button_0 then
        l_v30_Button_0:MoveToLeft();
    end;
end;
v8._checkVisibilityByText = function(_, v31, v32) --[[ Line: 79 ]] --[[ Name: _checkVisibilityByText ]]
    if not v31 then
        return true;
    else
        local v33 = string.lower(v32);
        local v34 = string.lower(v31);
        if not string.find(v33, v34, 1, true) then
            return false;
        else
            return true;
        end;
    end;
end;
v8._checkVisibilityByWhitelist = function(_, v36, v37) --[[ Line: 94 ]] --[[ Name: _checkVisibilityByWhitelist ]]
    if type(v37) ~= "table" then
        return true;
    end;
    if table.find(v37, v36) then
        return true;
    else
        return false;
    end;
end;
v8._displayAllDances = function(v38) --[[ Line: 103 ]] --[[ Name: _displayAllDances ]]
    for _, v40 in pairs(v38._mappedButtons) do
        v40:SetVisible(true);
        v40:MakeNormal();
    end;
end;
v8._createButtons = function(v41, v42) --[[ Line: 110 ]] --[[ Name: _createButtons ]]
    for _, v44 in next, v42 do
        v41:_createDanceButton(v44);
    end;
end;
v8._createDanceButton = function(v45, v46) --[[ Line: 116 ]] --[[ Name: _createDanceButton ]]
    -- upvalues: v4 (copy), l_ConnectionManager_0 (copy)
    local l_Name_0 = v46.Name;
    local v47 = string.lower(tostring(v46.Category or v46.category or "dance"));
    if v47 ~= "pose" then
        v47 = "dance";
    end;
    local l_Dances_1 = v45.Menu:WaitForChild("Dances");
    local v48 = v4.new();
    v48:SetText(l_Name_0);
    v48:SetInstanceName(l_Name_0);
    v48:SetParent(l_Dances_1);
    v45:_applyTemplateSizing(v48.Instance);
    v48:BindOnClick(function() --[[ Line: 124 ]]
        -- upvalues: l_ConnectionManager_0 (ref), l_Name_0 (copy)
        l_ConnectionManager_0.callProvider("animationHandler", "playAnimation", l_Name_0);
    end);
    v48:BindOnDoubleClick(function() --[[ Line: 128 ]]
        -- upvalues: v45 (copy), v48 (copy), l_Name_0 (copy)
        v45:_saveToFavorites(v48, l_Name_0);
    end);
    v48.CreatedAt = v46.createdAt;
    v45._mappedButtons[l_Name_0] = v48;
    v45._buttonCategories[l_Name_0] = v47;
    return v48;
end;
v8._applyTemplateSizing = function(v49, v50)
    local v51 = v49._templateButton;
    if not v50 or not v50:IsA("TextButton") then
        return;
    end;
    if v51 and v51:IsA("TextButton") then
        v50.AutomaticSize = v51.AutomaticSize;
        v50.Size = v51.Size;
        v50.TextWrapped = v51.TextWrapped;
        v50.TextTruncate = v51.TextTruncate;
        local l_UIPadding_0 = v51:FindFirstChild("UIPadding");
        local l_UIPadding_1 = v50:FindFirstChild("UIPadding");
        if l_UIPadding_0 and l_UIPadding_0:IsA("UIPadding") and l_UIPadding_1 and l_UIPadding_1:IsA("UIPadding") then
            l_UIPadding_1.PaddingLeft = l_UIPadding_0.PaddingLeft;
            l_UIPadding_1.PaddingRight = l_UIPadding_0.PaddingRight;
            l_UIPadding_1.PaddingTop = l_UIPadding_0.PaddingTop;
            l_UIPadding_1.PaddingBottom = l_UIPadding_0.PaddingBottom;
        end;
        return;
    else
        v50.AutomaticSize = Enum.AutomaticSize.Y;
        v50.Size = UDim2.new(1, -12, 0, 32);
        v50.TextWrapped = false;
        v50.TextTruncate = Enum.TextTruncate.AtEnd;
        return;
    end;
end;
v8._connectDanceChange = function(v52) --[[ Line: 138 ]] --[[ Name: _connectDanceChange ]]
    -- upvalues: l_Players_0 (copy)
    l_Players_0.LocalPlayer:GetAttributeChangedSignal("DanceName"):Connect(function(_) --[[ Line: 139 ]]
        -- upvalues: v52 (copy), l_Players_0 (ref)
        local l_Stop_0 = v52.Menu:FindFirstChild("Stop");
        local l_Attribute_0 = l_Players_0.LocalPlayer:GetAttribute("DanceName");
        local v54 = v52._mappedButtons[l_Attribute_0];
        for _, v56 in next, v52._mappedButtons do
            v56:SetSelected(false);
        end;
        if v54 then
            v54:SetSelected(true);
        end;
        if l_Stop_0 then
            if l_Attribute_0 and l_Attribute_0 ~= "" then
                l_Stop_0.TouchText.Text = "Touch to stop coordinate";
                l_Stop_0.DanceText.Text = l_Attribute_0;
                return;
            else
                l_Stop_0.TouchText.Text = "Touch to stop coordinate";
                l_Stop_0.DanceText.Text = "";
            end;
        end;
    end);
end;
v8._saveToFavorites = function(v57, v58, v59) --[[ Line: 164 ]] --[[ Name: _saveToFavorites ]]
    -- upvalues: l_ConnectionManager_0 (copy), l_NotificationManager_0 (copy)
    l_ConnectionManager_0.callProvider("animationHandler", "favoriteAnimation", v59):Then(function(v60, v61) --[[ Line: 165 ]]
        -- upvalues: l_NotificationManager_0 (ref), v57 (copy), v59 (copy), v58 (copy)
        if not v60 then
            return l_NotificationManager_0.error(v61);
        else
            v57:_fireAddedRemotes(v61, v59, v58);
            local v62 = v61 and "addAnimation" or "removeAnimation";
            l_NotificationManager_0.sendNotification(v62, {
                Body = {
                    v59
                }
            });
            return;
        end;
    end);
end;
v8._fireAddedRemotes = function(v63, v64, v65, v66) --[[ Line: 176 ]] --[[ Name: _fireAddedRemotes ]]
    v63._onFavoriteAnimation:Fire(v65, v64, v66);
end;
return v8;
