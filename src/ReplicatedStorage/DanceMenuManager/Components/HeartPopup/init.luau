-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage");
local l_LocalPlayer_0 = game:GetService("Players").LocalPlayer;
local l_l_LocalPlayer_0_Mouse_0 = l_LocalPlayer_0:GetMouse();
local l_Dances_0 = l_LocalPlayer_0.PlayerGui:WaitForChild("InGame"):WaitForChild("Menus"):WaitForChild("Dances");
local v4 = require(l_ReplicatedStorage_0.Modules.InstanceBase);
local l_Promise_0 = require(l_ReplicatedStorage_0:WaitForChild("Modules"):WaitForChild("nevermore"):WaitForChild("Promise"));
local v6 = TweenInfo.new(0.25, Enum.EasingStyle.Quart);
local v7 = {};
v7.__index = v7;
setmetatable(v7, v4);
v7.new = function() --[[ Line: 26 ]] --[[ Name: new ]]
    -- upvalues: v4 (copy), v7 (copy)
    local v8 = setmetatable(v4.new(), v7);
    v8:_createInstance(script.heartPopup);
    return v8;
end;
v7.Create = function(v9, v10) --[[ Line: 33 ]] --[[ Name: Create ]]
    v9:_setParent(v10);
    v9:_animate();
end;
v7.Tween = function(v11, v12, v13) --[[ Line: 38 ]] --[[ Name: Tween ]]
    -- upvalues: l_Promise_0 (copy), v6 (copy)
    return (v11._maid:GiveTask(l_Promise_0.spawn(function(v14) --[[ Line: 39 ]]
        -- upvalues: v11 (copy), v13 (copy), v6 (ref), v12 (copy)
        local v15 = v11:_tween(v13 or v11.Instance, v6, v12).Completed:Once(function() --[[ Line: 41 ]]
            -- upvalues: v14 (copy)
            v14();
        end);
        v11._maid:GiveTask(v15);
    end)));
end;
v7._animate = function(v16) --[[ Line: 51 ]] --[[ Name: _animate ]]
    -- upvalues: l_Promise_0 (copy)
    return v16:Tween({
        Size = UDim2.new(0.25, 0, 0, 34), 
        Rotation = math.random(-20, 20)
    }):Then(function() --[[ Line: 56 ]]
        -- upvalues: l_Promise_0 (ref)
        return l_Promise_0.delay(0.3, function(v17) --[[ Line: 57 ]]
            v17();
        end);
    end):Then(function() --[[ Line: 61 ]]
        -- upvalues: v16 (copy)
        v16:Tween({
            Size = UDim2.new(0.375, 0, 0, 34), 
            Position = v16.Instance.Position - UDim2.new(0, 0, 0, v16.Instance.AbsoluteSize.Y)
        });
        return v16:Tween({
            TextTransparency = 1
        }, v16.Instance.TextLabel);
    end):Finally(function() --[[ Line: 70 ]]
        -- upvalues: v16 (copy)
        v16:Destroy();
    end);
end;
v7._setParent = function(v18, _) --[[ Line: 75 ]] --[[ Name: _setParent ]]
    -- upvalues: l_Dances_0 (copy)
    local v20 = v18:_absoluteToRelative(l_Dances_0);
    v18.Instance.Position = UDim2.new(0, v20.X, 0, v20.Y, 0);
    v18.Instance.Size = UDim2.new(0, 0, 0, 0);
    v18:SetParent(l_Dances_0:WaitForChild("popups"));
end;
v7._absoluteToRelative = function(_, v22) --[[ Line: 82 ]] --[[ Name: _absoluteToRelative ]]
    -- upvalues: l_l_LocalPlayer_0_Mouse_0 (copy)
    local v23 = Vector2.new(l_l_LocalPlayer_0_Mouse_0.X, l_l_LocalPlayer_0_Mouse_0.Y);
    local l_AbsolutePosition_0 = v22.AbsolutePosition;
    local l_AbsoluteSize_0 = v22.AbsoluteSize;
    local v26 = v23.X - l_AbsolutePosition_0.X;
    local v27 = v23.Y - l_AbsolutePosition_0.Y;
    v26 = math.max(0, (math.min(v26, l_AbsoluteSize_0.X)));
    v27 = math.max(0, (math.min(v27, l_AbsoluteSize_0.Y)));
    return Vector2.new(v26, v27);
end;
return v7;