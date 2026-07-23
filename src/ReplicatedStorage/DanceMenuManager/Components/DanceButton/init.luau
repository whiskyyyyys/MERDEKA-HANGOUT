-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage");
local l_LocalizationService_0 = game:GetService("LocalizationService");
local l_CollectionService_0 = game:GetService("CollectionService");
local v2 = require(l_ReplicatedStorage_0.Modules.InstanceBase);
local v3 = require(script.Parent.HeartPopup);
local v4 = require(l_ReplicatedStorage_0.Modules.nevermore.Signal);
local v5 = require(l_ReplicatedStorage_0.Modules.GradientRotation);
local v6 = TweenInfo.new(0.5, Enum.EasingStyle.Quart);
local v7 = TweenInfo.new(0.25, Enum.EasingStyle.Quart);
local v8 = TweenInfo.new(0.25, Enum.EasingStyle.Quart);
local v9 = TweenInfo.new(0.25, Enum.EasingStyle.Quart);
local v10 = TweenInfo.new(0.25, Enum.EasingStyle.Linear);
local v11 = {};
v11.__index = v11;
setmetatable(v11, v2);
local function v11_1(v12_1, v13_1)
    local v14_1 = pcall(function()
        v12_1:AddTag(v13_1);
    end);
    if not v14_1 then
        l_CollectionService_0:AddTag(v12_1, v13_1);
    end;
end;
local function v11_2(v15_1, v16_1)
    local v17_1 = pcall(function()
        v15_1:RemoveTag(v16_1);
    end);
    if not v17_1 then
        l_CollectionService_0:RemoveTag(v15_1, v16_1);
    end;
end;
v11.new = function() --[[ Line: 30 ]] --[[ Name: new ]]
    -- upvalues: v2 (copy), v11 (copy), v4 (copy)
    local v12 = setmetatable(v2.new(), v11);
    v12:_createInstance(script.DanceButton);
    v12._lastClickTime = 0;
    v12._doubleClickThreshold = 0.2;
    v12._singleClick = v4.new();
    v12._doubleClick = v4.new();
    v12:_listenClicks();
    v12._maid:GiveTask(v12._singleClick);
    v12._maid:GiveTask(v12._doubleClick);
    v12._maid:GiveTask(function() --[[ Line: 46 ]]
        -- upvalues: v12 (copy)
        v12:_cancelCurrentThread();
    end);
    return v12;
end;
v11.DisplayPopup = function(v13) --[[ Line: 54 ]] --[[ Name: DisplayPopup ]]
    v13:_createPopup();
end;
v11.SetIsFavorte = function(v14, v15) --[[ Line: 58 ]] --[[ Name: SetIsFavorte ]]
    if v15 then
        v14.Instance.ImageButton.Image = "rbxassetid://118352918705149";
    else
        v14.Instance.ImageButton.Image = "rbxassetid://139845053855663";
    end;
    v14.Instance.ImageButton.ImageColor3 = v14:GetRule("TextColor") or Color3.fromRGB(255, 255, 255);
end;
v11.SetFavorite = function(v16) --[[ Line: 67 ]] --[[ Name: SetFavorite ]]
    v16:_animateHearthDisplay();
end;
v11.RemoveFavorite = function(v17) --[[ Line: 71 ]] --[[ Name: RemoveFavorite ]]
    v17:_animateHearthHide();
end;
v11.MoveToLeft = function(v18) --[[ Line: 75 ]] --[[ Name: MoveToLeft ]]
    -- upvalues: v6 (copy)
    v18.Inactive = true;
    v18.Instance.Size = UDim2.new(1, 0, 0, v18.Instance.AbsoluteSize.Y);
    v18.Instance.AutomaticSize = Enum.AutomaticSize.None;
    local v19, v20 = v18:_cTween({
        Position = UDim2.new(0, 0, 0, 0), 
        AnchorPoint = Vector2.new(1, 0)
    });
    v19.Completed:Wait();
    local _ = v18:_tween(v20, v6, {
        Size = UDim2.new(1, 0, 0, -4)
    }, true);
end;
v11.BindOnClick = function(v22, v23) --[[ Line: 91 ]] --[[ Name: BindOnClick ]]
    v22._singleClick:Connect(v23);
end;
v11.BindOnDoubleClick = function(v24, v25) --[[ Line: 96 ]] --[[ Name: BindOnDoubleClick ]]
    v24._doubleClick:Connect(v25);
end;
v11.SetText = function(v26, v27) --[[ Line: 101 ]] --[[ Name: SetText ]]
    v26.Instance.Text = v27;
end;
v11.SetSelected = function(v28, v29) --[[ Line: 105 ]] --[[ Name: SetSelected ]]
    -- upvalues: v6 (copy), v9 (copy), v10 (copy)
    local v30 = v29 and (v28:GetPrimary() or Color3.fromRGB(192, 192, 192)) or v28:GetRule("BackgroundColor") or Color3.fromRGB(41, 41, 41);
    local v31 = v29 and (v28:GetRule("TextColor") or Color3.fromRGB(0, 0, 0)) or Color3.fromRGB(255, 255, 255);
    local v32 = v29 and 40 or 8;
    local _ = v29 and 1 or 0;
    local v34 = v29 and 0.25 or 0.35;
    v28.Instance.ImageButton.UIScale.Scale = 1;
    v28:_tween(v28.Instance, v6, {
        BackgroundColor3 = v30, 
        TextColor3 = v31
    });
    v28:_tween(v28.Instance.UIPadding, v6, {
        PaddingRight = UDim.new(0, v32)
    });
    v28:_tween(v28.Instance.ImageButton, v29 and v9 or v10, {
        ImageColor3 = v31
    });
    v28:_tween(v28.Instance.ImageButton, v29 and v10 or v9, {
        ImageTransparency = v34
    }, true);
    v28:_setTags(v29);
    if v29 then
        v28:_startGradient();
        return;
    else
        v28:_stopGradient();
        return;
    end;
end;
v11.MakeNormal = function(v35) --[[ Line: 145 ]] --[[ Name: MakeNormal ]]
    v35.Inactive = nil;
    local l_Parent_0 = v35.Instance.Parent;
    if l_Parent_0.Name == v35.Instance.Name then
        v35.Instance.Size = UDim2.new(1, -12, 0, 32);
        v35.Instance.AutomaticSize = Enum.AutomaticSize.Y;
        v35.Instance.Parent = l_Parent_0.Parent;
        l_Parent_0:Destroy();
    end;
end;
v11.GetTranslated = function(v37) --[[ Line: 156 ]] --[[ Name: GetTranslated ]]
    -- upvalues: l_LocalizationService_0 (copy)
    local l_l_LocalizationService_0_TranslatorForPlayer_0 = l_LocalizationService_0:GetTranslatorForPlayer(game.Players.LocalPlayer);
    if l_l_LocalizationService_0_TranslatorForPlayer_0 then
        return l_l_LocalizationService_0_TranslatorForPlayer_0:Translate(v37.Instance, v37.Instance.Text);
    else
        return v37.Instance.Text;
    end;
end;
v11._stopGradient = function(v39) --[[ Line: 166 ]] --[[ Name: _stopGradient ]]
    if v39._currentGradient then
        v39._currentGradient:Destroy();
        v39._currentGradient = nil;
    end;
end;
v11._startGradient = function(v40) --[[ Line: 173 ]] --[[ Name: _startGradient ]]
    -- upvalues: v5 (copy)
    v40._currentGradient = v5.new(v40.Instance);
end;
v11._listenClicks = function(v41) --[[ Line: 178 ]] --[[ Name: _listenClicks ]]
    local l_Instance_0 = v41.Instance;
    local v43 = l_Instance_0.Activated:Connect(function() --[[ Line: 180 ]]
        -- upvalues: v41 (copy)
        v41._singleClick:Fire();
    end);
    local v44 = l_Instance_0.ImageButton.Activated:Connect(function() --[[ Line: 183 ]]
        -- upvalues: v41 (copy)
        v41._doubleClick:Fire();
    end);
    local v45 = l_Instance_0:GetAttributeChangedSignal("Clicked"):Connect(function() --[[ Line: 186 ]]
        -- upvalues: v41 (copy)
        v41._singleClick:Fire();
    end);
    local v46 = l_Instance_0:GetAttributeChangedSignal("InputKeycode"):Connect(function() --[[ Line: 189 ]]
        -- upvalues: l_Instance_0 (copy), v41 (copy)
        if l_Instance_0:GetAttribute("InputKeycode") == Enum.KeyCode.ButtonX then
            print("X click");
            v41._doubleClick:Fire();
        end;
    end);
    v41._maid:GiveTask(v46);
    v41._maid:GiveTask(v45);
    v41._maid:GiveTask(v44);
    v41._maid:GiveTask(v43);
end;
v11._cancelCurrentThread = function(v47) --[[ Line: 203 ]] --[[ Name: _cancelCurrentThread ]]
    if v47.currentThread then
        task.cancel(v47.currentThread);
        v47.currentThread = nil;
    end;
end;
v11._cTween = function(v48, v49) --[[ Line: 210 ]] --[[ Name: _cTween ]]
    -- upvalues: v6 (copy)
    local l_Instance_1 = v48.Instance;
    local l_Parent_1 = l_Instance_1.Parent;
    local l_Frame_0 = Instance.new("Frame");
    l_Frame_0.Name = l_Instance_1.Name;
    l_Frame_0.Size = l_Instance_1.Size;
    l_Frame_0.BackgroundTransparency = 1;
    l_Frame_0.LayoutOrder = l_Instance_1.LayoutOrder;
    l_Instance_1.Parent = l_Frame_0;
    l_Instance_1.Size = UDim2.new(1, 0, 1, 0);
    l_Instance_1.Position = UDim2.new(0, 0, 0, 0);
    l_Instance_1.AnchorPoint = Vector2.new(0, 0);
    l_Frame_0.Parent = l_Parent_1;
    v48._maid:GiveTask(l_Frame_0);
    return v48:_tween(l_Instance_1, v6, v49), l_Frame_0;
end;
v11._createPopup = function(v53) --[[ Line: 231 ]] --[[ Name: _createPopup ]]
    -- upvalues: v3 (copy)
    v3.new():Create(v53.Instance);
end;
v11._setTags = function(v54, v55) --[[ Line: 236 ]] --[[ Name: _setTags ]]
    -- upvalues: v11_1 (copy), v11_2 (copy)
    local v56 = {
        "PrimaryColor", 
        "TextColor"
    };
    if v55 then
        v54:SetTags(v56);
        v11_1(v54.Instance.ImageButton, v56[2]);
        return;
    else
        v54:RemoveTags(v56);
        v11_2(v54.Instance.ImageButton, v56[2]);
        return;
    end;
end;
v11._animateHearthDisplay = function(v57) --[[ Line: 249 ]] --[[ Name: _animateHearthDisplay ]]
    -- upvalues: v8 (copy), v7 (copy)
    local v58 = v57.Instance.ImageButton:Clone();
    v58.UIScale.Scale = 0;
    v58.Image = "rbxassetid://118352918705149";
    v58.ImageTransparency = 1;
    v58.AnchorPoint = Vector2.new(0.5, 0.5);
    v58.Position = UDim2.new(0.5, 0, 0.5, 0);
    v58.Parent = v57.Instance.ImageButton;
    v57:_tween(v58, v8, {
        ImageTransparency = 0.25
    });
    v57:_tween(v58.UIScale, v7, {
        Scale = 0.9
    }).Completed:Connect(function() --[[ Line: 265 ]]
        -- upvalues: v57 (copy), v58 (copy)
        v57.Instance.ImageButton.Image = "rbxassetid://118352918705149";
        v58:Destroy();
    end);
    v57._maid:GiveTask(v58);
end;
v11._animateHearthHide = function(v59) --[[ Line: 273 ]] --[[ Name: _animateHearthHide ]]
    -- upvalues: v8 (copy)
    local v60 = v59.Instance.ImageButton:Clone();
    v60.UIScale.Scale = 0.9;
    v60.Image = "rbxassetid://118352918705149";
    v60.ImageTransparency = 0.25;
    v60.AnchorPoint = Vector2.new(0.5, 0.5);
    v60.Position = UDim2.new(0.5, 0, 0.5, 0);
    v60.Parent = v59.Instance.ImageButton;
    v59.Instance.ImageButton.Image = "rbxassetid://139845053855663";
    v59:_tween(v60, v8, {
        ImageTransparency = 1
    });
    v59:_tween(v60.UIScale, v8, {
        Scale = 0
    }).Completed:Connect(function() --[[ Line: 287 ]]
        -- upvalues: v60 (copy)
        v60:Destroy();
    end);
    v59._maid:GiveTask(v60);
end;
v11._updateLikeButtonColor = function(v61) --[[ Line: 294 ]] --[[ Name: _updateLikeButtonColor ]]
    v61.Instance.ImageButton.ImageColor3 = v61:GetRule("TextColor");
end;
return v11;
