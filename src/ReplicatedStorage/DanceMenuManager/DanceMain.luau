-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local l_Players_0 = game:GetService("Players");
local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage");
local l_LocalPlayer_0 = l_Players_0.LocalPlayer;
local function v4() --[[ Line: 6 ]] --[[ Name: getDancesMenu ]]
    -- upvalues: l_LocalPlayer_0 (copy)
    local l_PlayerGui_0 = l_LocalPlayer_0:FindFirstChild("PlayerGui") or l_LocalPlayer_0:WaitForChild("PlayerGui", 10);
    if not l_PlayerGui_0 then
        return nil;
    else
        local l_InGame_0 = l_PlayerGui_0:FindFirstChild("InGame") or l_PlayerGui_0:WaitForChild("InGame", 10);
        local l_Menus_0 = l_InGame_0 and (l_InGame_0:FindFirstChild("Menus") or l_InGame_0:WaitForChild("Menus", 10));
        return l_Menus_0 and (l_Menus_0:FindFirstChild("Dances") or l_Menus_0:WaitForChild("Dances", 10));
    end;
end;
local l_Dances_0 = v4();
local l_Modules_0 = l_ReplicatedStorage_0:WaitForChild("Modules");
local v5 = require(script.Parent.DanceMenuController);
local v6 = require(script.Parent.DanceButtons);
local v7 = require(script.Parent.TopController);
local l_ConnectionManager_0 = require(l_Modules_0:WaitForChild("ConnectionManager"));
local function v8(v9)
    local v10 = {};
    v10.Instance = v9;
    v10._linkedButtons = {};
    v10._clearOnButtonClick = false;
    local v11 = v9 and v9:FindFirstChild("TextBox", true);
    local v12 = v9 and v9:FindFirstChild("ImageButton", true);
    v10.EnableClearOnButtonClick = function(v13, v14)
        v13._clearOnButtonClick = v14 == true;
    end;
    v10.ClearText = function(_)
        if v11 and v11:IsA("TextBox") then
            v11.Text = "";
        end;
    end;
    v10.BindOnTextChange = function(_, v15)
        if v11 and v11:IsA("TextBox") then
            v11:GetPropertyChangedSignal("Text"):Connect(function()
                v15(v11.Text);
            end);
        end;
    end;
    v10.SetParent = function(_, _)
    end;
    v10.UpdateLinkedButton = function(v16, v17)
        v16._linkedButtons = v17 or {};
        local v18 = {};
        for v19, v20 in pairs(v16._linkedButtons) do
            local v21 = v19;
            if type(v20.GetTranslated) == "function" then
                local v22 = v20:GetTranslated();
                if type(v22) == "string" and v22 ~= "" then
                    v21 = v22;
                end;
            end;
            table.insert(v18, {
                Name = v19, 
                Text = string.lower(tostring(v21)), 
                Button = v20
            });
        end;
        table.sort(v18, function(v23, v24)
            return v23.Text < v24.Text;
        end);
        for v25, v26 in ipairs(v18) do
            local v27 = v26.Button;
            if type(v27.SetLayoutOrder) == "function" then
                v27:SetLayoutOrder(v25);
            elseif v27.Instance and v27.Instance:IsA("GuiObject") then
                v27.Instance.LayoutOrder = v25;
            end;
        end;
    end;
    if v12 and v12:IsA("GuiButton") then
        v12.Activated:Connect(function()
            if v10._clearOnButtonClick and v11 and v11:IsA("TextBox") then
                v11.Text = "";
                v11:CaptureFocus();
            elseif v11 and v11:IsA("TextBox") then
                v11:CaptureFocus();
            end;
        end);
    end;
    return v10;
end;
local v10 = {};
local v11 = {};
local v12 = nil;
local v13 = nil;
local v14 = {};
v14.__index = v14;
local v15 = nil;
v14.new = function() --[[ Line: 29 ]] --[[ Name: new ]]
    -- upvalues: v14 (copy), l_Dances_0 (ref), v4 (copy), v5 (copy), v6 (copy), v7 (copy)
    local v16 = setmetatable({}, v14);
    v15 = v16;
    l_Dances_0 = l_Dances_0 or v4();
    if not l_Dances_0 then
        task.spawn(function() --[[ Line: 35 ]]
            -- upvalues: l_Dances_0 (ref), v4 (ref), v16 (copy), v5 (ref), v6 (ref), v7 (ref)
            for _ = 1, 60 do
                l_Dances_0 = l_Dances_0 or v4();
                if l_Dances_0 then
                    v16.MenuController = v5.new(l_Dances_0);
                    v16.DanceButtons = v6.new(l_Dances_0);
                    v16.TopController = v7.new(l_Dances_0);
                    v16.SearchBar = v16:_createSearchBar();
                    v16:_init();
                    return;
                end;
                task.wait(1);
            end;
            warn("[DanceMenuManager] Dances menu not found after waiting.");
        end);
        return v16;
    end;
    v16.MenuController = v5.new(l_Dances_0);
    v16.DanceButtons = v6.new(l_Dances_0);
    v16.TopController = v7.new(l_Dances_0);
    v16.SearchBar = v16:_createSearchBar();
    v16:_init();
    return v16;
end;
v14._init = function(v16) --[[ Line: 43 ]] --[[ Name: _init ]]
    -- upvalues: v11 (ref), v10 (ref)
    v16.CurrentText = "";
    v16.SelectedTab = "Dances";
    v16:_setupSearchAutoClear();
    v16:_setSetDancesFunction();
    v16:_initTopSelector();
    v16:_initSearchBar();
    v16:_initFavoriteHandler();
    v16:_listenSync();
    v16.DanceButtons:UpdateFavorites(v11);
    v16:_setSetFavoritesFunction();
    if type(v10) == "table" then
        v16.DanceButtons:RenderButtons(v10);
        if v16.SearchBar then
            v16.SearchBar:UpdateLinkedButton(v16.DanceButtons._mappedButtons);
        end;
    end;
    v16:_searchDances();
end;
v14._initTopSelector = function(v17) --[[ Line: 57 ]] --[[ Name: _initTopSelector ]]
    v17.TopController:BindOnTapSelection(function(v18) --[[ Line: 58 ]]
        -- upvalues: v17 (copy)
        v17.SelectedTab = v18;
        v17:_searchDances();
        v17.DanceButtons.SelectedTab = v18;
    end);
end;
v14._initSearchBar = function(v19) --[[ Line: 65 ]] --[[ Name: _initSearchBar ]]
    if not v19.SearchBar then
        return;
    end;
    v19.SearchBar:BindOnTextChange(function(v20) --[[ Line: 66 ]]
        -- upvalues: v19 (copy)
        v19.CurrentText = v20;
        v19:_searchDances();
    end);
end;
v14._initFavoriteHandler = function(v21) --[[ Line: 74 ]] --[[ Name: _initFavoriteHandler ]]
    -- upvalues: v11 (ref)
    v21.DanceButtons:BindOnFavorite(function(v22, v23, _) --[[ Line: 75 ]]
        -- upvalues: v11 (ref), v21 (copy)
        if not v23 then
            local v25 = table.find(v11, v22);
            if v25 then
                table.remove(v11, v25);
            end;
            if v21.SelectedTab == "Favorites" then
                v21.DanceButtons:DestroyButton(v22);
            end;
            local l_Button_0 = v21.DanceButtons:GetButton(v22);
            if l_Button_0 then
                l_Button_0:RemoveFavorite();
                return;
            end;
        else
            table.insert(v11, v22);
            local l_Button_1 = v21.DanceButtons:GetButton(v22);
            if l_Button_1 then
                l_Button_1:SetFavorite();
            end;
        end;
    end);
end;
v14._searchDances = function(v28) --[[ Line: 104 ]] --[[ Name: _searchDances ]]
    -- upvalues: v11 (ref)
    local l_CurrentText_0 = v28.CurrentText;
    local v30 = nil;
    local v31 = string.lower(tostring(v28.SelectedTab or ""));
    if string.find(v31, "fav", 1, true) then
        v30 = type(v11) == "table" and v11 or {};
    elseif string.find(v31, "pose", 1, true) then
        v30 = v28.DanceButtons:GetNamesByCategory("pose");
    elseif string.find(v31, "dance", 1, true) then
        v30 = v28.DanceButtons:GetNamesByCategory("dance");
    end;
    if l_CurrentText_0 and #l_CurrentText_0 == 0 then
        l_CurrentText_0 = nil;
    end;
    v28.DanceButtons:SearchByQuery(l_CurrentText_0, v30);
end;
v14._createSearchBar = function(_) --[[ Line: 118 ]] --[[ Name: _createSearchBar ]]
    -- upvalues: l_Dances_0 (copy), v8 (copy)
    local v32 = l_Dances_0:WaitForChild("Dances");
    local v33 = v32:FindFirstChild("$SearchBar") or v32:FindFirstChild("SearchBar");
    if not v33 then
        warn("[DanceMenuManager] Existing $SearchBar not found in Dances frame.");
        return nil;
    end;
    local v34 = v8(v33);
    v34:EnableClearOnButtonClick(false);
    return v34;
end;
v14._setupSearchAutoClear = function(v33) --[[ Line: 124 ]] --[[ Name: _setupSearchAutoClear ]]
    if not v33.SearchBar or not v33.SearchBar.Instance then
        return;
    end;
    local v34 = v33.SearchBar.Instance:FindFirstChild("TextBox");
    if not v34 or not v34:IsA("TextBox") then
        return;
    end;
    v34.Focused:Connect(function() --[[ Line: 129 ]]
        -- upvalues: v33 (copy), v34 (copy)
        if v33.CurrentText ~= "" then
            v34.Text = "";
        end;
    end);
end;
v14._setSetDancesFunction = function(v35) --[[ Line: 124 ]] --[[ Name: _setSetDancesFunction ]]
    -- upvalues: v12 (ref), v10 (ref)
    v12 = function() --[[ Line: 125 ]]
        -- upvalues: v35 (copy), v10 (ref)
        v35.DanceButtons:RenderButtons(v10);
        if v35.SearchBar then
            v35.SearchBar:UpdateLinkedButton(v35.DanceButtons._mappedButtons);
        end;
        v35:_searchDances();
    end;
end;
v14._setSetFavoritesFunction = function(v36) --[[ Line: 130 ]] --[[ Name: _setSetFavoritesFunction ]]
    -- upvalues: v13 (ref), v11 (ref)
    v13 = function() --[[ Line: 131 ]]
        -- upvalues: v36 (copy), v11 (ref)
        v36.DanceButtons:UpdateFavorites(v11);
        if v36.SearchBar then
            v36.SearchBar:UpdateLinkedButton(v36.DanceButtons._mappedButtons);
        end;
    end;
end;
v14._listenSync = function(_) --[[ Line: 138 ]] --[[ Name: _listenSync ]]
    -- upvalues: l_Dances_0 (copy), l_LocalPlayer_0 (copy), l_ConnectionManager_0 (copy)
    local l_Stop_0 = l_Dances_0:WaitForChild("Stop");
    l_LocalPlayer_0:GetAttributeChangedSignal("onSync"):Connect(function() --[[ Line: 140 ]]
        -- upvalues: l_LocalPlayer_0 (ref), l_Stop_0 (copy)
        l_Stop_0.Visible = l_LocalPlayer_0:GetAttribute("onSync");
    end);
    l_Stop_0.Activated:Connect(function() --[[ Line: 144 ]]
        -- upvalues: l_ConnectionManager_0 (ref)
        l_ConnectionManager_0.callProvider("animationHandler", "leaveSync");
    end);
end;
v14._setDanceFavorite = function(_, v38, v39) --[[ Line: 149 ]] --[[ Name: _setDanceFavorite ]]
    v38.IsFavorite = v39;
end;
v14.setFavoriteDances = function(v40) --[[ Line: 155 ]] --[[ Name: setFavoriteDances ]]
    -- upvalues: v11 (ref), v13 (ref)
    v11 = type(v40) == "table" and v40 or {};
    if v13 then
        v13();
    end;
end;
v14.setDances = function(v41) --[[ Line: 163 ]] --[[ Name: setDances ]]
    -- upvalues: v10 (ref), v12 (ref)
    v10 = v41;
    if v12 then
        v12();
    end;
end;
v14.toggleMenu = function()
    local v42 = v15;
    if not v42 then
        return false;
    end;
    local v43 = v42.MenuController;
    if v43 and v43._onToggle then
        v43:_onToggle();
        return true;
    else
        return false;
    end;
end;
return v14.new();
