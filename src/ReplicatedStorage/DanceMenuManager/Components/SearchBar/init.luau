-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage");
local v1 = require(l_ReplicatedStorage_0.Modules.InstanceBase);
local v2 = require(l_ReplicatedStorage_0.Modules.UIFeedback.PromptManager);
local v3 = require(l_ReplicatedStorage_0.Modules.nevermore.Signal);
local v4 = {};
v4.__index = v4;
setmetatable(v4, v1);
v4.new = function(v5, v6) --[[ Line: 13 ]] --[[ Name: new ]]
    -- upvalues: v1 (copy), v4 (copy), v3 (copy)
    local v7 = setmetatable(v1.new(), v4);
    v7:_createInstance(script["$SearchBar"]);
    v7._linkedButtons = {};
    v7._clearOnButtonClick = false;
    v7.OnFilterSelected = v3.new();
    v7.sortType = v6 or "Name (A-Z)";
    v7._customFilters = {
        {
            Color = Color3.fromRGB(192, 192, 192), 
            Name = "Name (A-Z)", 
            FilterFunction = function(v8) --[[ Line: 25 ]] --[[ Name: FilterFunction ]]
                v8:_filterNameAscendent();
            end
        }, 
        {
            Color = Color3.fromRGB(192, 192, 192), 
            Name = "Name (Z-A)", 
            FilterFunction = function(v9) --[[ Line: 30 ]] --[[ Name: FilterFunction ]]
                v9:_filterNameDescendent();
            end
        }
    };
    if not v5 then
        v7:AddCustomFilter("Date (New - Old)", Color3.fromRGB(192, 192, 192), function(v10) --[[ Line: 35 ]]
            v10:_createDateFilter(function(v11, v12) --[[ Line: 36 ]]
                if v11.date == nil or v12.date == nil then
                    return;
                else
                    return v11.date > v12.date;
                end;
            end);
        end);
        v7:AddCustomFilter("Date (Old - New)", Color3.fromRGB(192, 192, 192), function(v13) --[[ Line: 44 ]]
            v13:_createDateFilter(function(v14, v15) --[[ Line: 45 ]]
                if v14.date == nil or v15.date == nil then
                    return;
                else
                    return v14.date < v15.date;
                end;
            end);
        end);
    end;
    v7:_listenFilterClick();
    v7._maid:GiveTask(v7.OnFilterSelected);
    v7._maid:GiveTask(function() --[[ Line: 57 ]]
        -- upvalues: v7 (copy)
        table.clear(v7._linkedButtons);
        table.clear(v7._customFilters);
    end);
    return v7;
end;
v4.EnableClearOnButtonClick = function(v16, v17) --[[ Line: 65 ]] --[[ Name: EnableClearOnButtonClick ]]
    v16._clearOnButtonClick = v17 == true;
end;
v4.ClearText = function(v18) --[[ Line: 69 ]] --[[ Name: ClearText ]]
    local l_TextBox_0 = v18.Instance.TextBox;
    if l_TextBox_0.Text ~= "" then
        l_TextBox_0.Text = "";
    end;
end;
v4.DisableFilter = function(v20) --[[ Line: 65 ]] --[[ Name: DisableFilter ]]
    v20.Instance.ImageButton.Visible = false;
end;
v4.SetPlaceHolderText = function(v21, v22) --[[ Line: 69 ]] --[[ Name: SetPlaceHolderText ]]
    v21.Instance.TextBox.PlaceholderText = v22;
end;
v4.BindOnFocusLost = function(v23, v24) --[[ Line: 73 ]] --[[ Name: BindOnFocusLost ]]
    local v26 = v23.Instance.TextBox.FocusLost:Connect(function(v25) --[[ Line: 74 ]]
        -- upvalues: v24 (copy), v23 (copy)
        v24(v23.Instance.TextBox.Text, v25);
    end);
    v23._maid:GiveTask(v26);
end;
v4.BindOnTextChange = function(v27, v28) --[[ Line: 80 ]] --[[ Name: BindOnTextChange ]]
    local v29 = v27.Instance.TextBox:GetPropertyChangedSignal("Text"):Connect(function() --[[ Line: 81 ]]
        -- upvalues: v28 (copy), v27 (copy)
        v28(v27.Instance.TextBox.Text);
    end);
    v27._maid:GiveTask(v29);
end;
v4.BindOnFilterSelection = function(v30, v31) --[[ Line: 87 ]] --[[ Name: BindOnFilterSelection ]]
    v30.OnFilterSelected:Connect(v31);
end;
v4.UpdateLinkedButton = function(v32, v33) --[[ Line: 91 ]] --[[ Name: UpdateLinkedButton ]]
    v32._linkedButtons = v33;
    v32:_filterNameAscendent();
    v32.sortType = "Name (A-Z)";
end;
v4.AddCustomFilter = function(v30, v31, v32, v33) --[[ Line: 98 ]] --[[ Name: AddCustomFilter ]]
    for _, v35 in ipairs(v30._customFilters) do
        if v35.Name == v31 then
            warn("Filter '" .. v31 .. "' already exists. Overwriting...");
            v35.Color = v32 or Color3.fromRGB(192, 192, 192);
            v35.FilterFunction = v33;
            return;
        end;
    end;
    table.insert(v30._customFilters, {
        Color = v32 or Color3.fromRGB(192, 192, 192), 
        Name = v31, 
        FilterFunction = v33
    });
end;
v4.RemoveCustomFilter = function(v36, v37) --[[ Line: 115 ]] --[[ Name: RemoveCustomFilter ]]
    if v37 == "Name (A-Z)" or v37 == "Name (Z-A)" then
        warn("Cannot remove default filter: " .. v37);
        return false;
    else
        for v38, v39 in ipairs(v36._customFilters) do
            if v39.Name == v37 then
                table.remove(v36._customFilters, v38);
                return true;
            end;
        end;
        warn("Filter '" .. v37 .. "' not found");
        return false;
    end;
end;
v4.GetAvailableFilters = function(v40) --[[ Line: 132 ]] --[[ Name: GetAvailableFilters ]]
    local v41 = {};
    for _, v43 in ipairs(v40._customFilters) do
        table.insert(v41, v43.Name);
    end;
    return v41;
end;
v4._listenFilterClick = function(v44) --[[ Line: 140 ]] --[[ Name: _listenFilterClick ]]
    local v45 = v44.Instance.ImageButton.MouseButton1Click:Connect(function() --[[ Line: 141 ]]
        -- upvalues: v44 (copy)
        if v44._clearOnButtonClick then
            v44:ClearText();
            v44.Instance.TextBox:CaptureFocus();
            return;
        end;
        v44:_filter();
    end);
    local v46 = v44.Instance:GetAttributeChangedSignal("Clicked"):Connect(function() --[[ Line: 145 ]]
        -- upvalues: v44 (copy)
        v44.Instance.TextBox:CaptureFocus();
    end);
    local v47 = v44.Instance:GetAttributeChangedSignal("InputKeycode"):Connect(function() --[[ Line: 148 ]]
        -- upvalues: v44 (copy)
        if v44.Instance:GetAttribute("InputKeycode") == Enum.KeyCode.ButtonX then
            if v44._clearOnButtonClick then
                v44:ClearText();
                v44.Instance.TextBox:CaptureFocus();
                return;
            end;
            v44:_filter();
        end;
    end);
    v44._maid:GiveTask(v46);
    v44._maid:GiveTask(v47);
    v44._maid:GiveTask(v45);
end;
v4._filter = function(v48) --[[ Line: 160 ]] --[[ Name: _filter ]]
    -- upvalues: v2 (copy)
    local v49, v50, v51 = v2.displaySelectionPrompt(v48._customFilters, v48.sortType):Yield();
    local v52 = type(v51) == "string" and v51 or type(v50) == "string" and v50 or nil;
    if not v49 or not v52 then
        return;
    else
        for _, v53 in ipairs(v48._customFilters) do
            if v53.Name == v52 then
                v53.FilterFunction(v48);
                break;
            end;
        end;
        v48.sortType = v52;
        v48.OnFilterSelected:Fire(v52);
        return;
    end;
end;
v4._filterNameAscendent = function(v53) --[[ Line: 177 ]] --[[ Name: _filterNameAscendent ]]
    v53:_createFilter(function(v54, v55) --[[ Line: 178 ]]
        return v54.Text < v55.Text;
    end);
end;
v4._filterNameDescendent = function(v56) --[[ Line: 184 ]] --[[ Name: _filterNameDescendent ]]
    v56:_createFilter(function(v57, v58) --[[ Line: 185 ]]
        return v57.Text > v58.Text;
    end);
end;
v4._makeFilter = function(v59, v60) --[[ Line: 191 ]] --[[ Name: _makeFilter ]]
    table.sort(v59._linkedButtons, v60);
    for v61, v62 in ipairs(v59._linkedButtons) do
        v62:SetLayoutOrder(v61);
    end;
end;
v4._createFilter = function(v63, v64) --[[ Line: 199 ]] --[[ Name: _createFilter ]]
    local v65 = {};
    for v66, v67 in pairs(v63._linkedButtons) do
        table.insert(v65, {
            Text = v67:GetTranslated(), 
            Name = v66
        });
    end;
    table.sort(v65, v64);
    for v68, v69 in ipairs(v65) do
        v63._linkedButtons[v69.Name]:SetLayoutOrder(v68);
    end;
end;
v4._createDateFilter = function(v70, v71) --[[ Line: 214 ]] --[[ Name: _createDateFilter ]]
    local v72 = {};
    for v73, v74 in pairs(v70._linkedButtons) do
        table.insert(v72, {
            name = v73, 
            date = v74.CreatedAt
        });
    end;
    table.sort(v72, v71);
    for v75, v76 in ipairs(v72) do
        v70._linkedButtons[v76.name]:SetLayoutOrder(v75);
    end;
end;
return v4;
