-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage");
local l_TweenService_0 = game:GetService("TweenService");
local l_UserInputService_0 = game:GetService("UserInputService");
local v3 = require(l_ReplicatedStorage_0.Modules.nevermore.Maid);
local v4 = require(l_ReplicatedStorage_0.Modules.ConnectionManager);
local _ = require(l_ReplicatedStorage_0.Modules.ThemeManager);
local v6 = TweenInfo.new(0.5, Enum.EasingStyle.Exponential);
local v7 = {};
v7.__index = v7;
v7.new = function(v8) --[[ Line: 25 ]] --[[ Name: new ]]
    -- upvalues: v7 (copy), v3 (copy), v4 (copy)
    local v9 = setmetatable({}, v7);
    v9.Menu = v8;
    v9._maid = v3.new();
    v9._activeTweens = {};
    if v8:FindFirstChild("Quit") and v8.Quit:FindFirstChild("ImageLabel") then
        v8.Quit.ImageLabel.Image = "rbxassetid://104015383388020";
        v9._maid:GiveTask(function() --[[ Line: 33 ]]
            -- upvalues: v8 (copy)
            v8.Quit.ImageLabel.Image = "rbxassetid://128292426424905";
        end);
        v9:_listenClick();
    end
    v4.callProvider("animationHandler", "changeSeatAnimation", true);
    v9:_listenKeyboard();
    return v9;
end;
v7.Destroy = function(v10) --[[ Line: 45 ]] --[[ Name: Destroy ]]
    v10._maid:DoCleaning();
end;
v7._listenClick = function(v11) --[[ Line: 49 ]] --[[ Name: _listenClick ]]
    -- upvalues: v4 (copy)
    local v12 = v11.Menu.Quit.MouseButton1Click:Connect(function() --[[ Line: 50 ]]
        -- upvalues: v11 (copy), v4 (ref)
        v11:_handleAnimation();
        v4.callProvider("animationHandler", "changeSeatAnimation");
    end);
    v11._maid:GiveTask(v12);
end;
v7._handleAnimation = function(v13) --[[ Line: 58 ]] --[[ Name: _handleAnimation ]]
    -- upvalues: v6 (copy)
    if not v13.Menu:FindFirstChild("Quit") then return end
    v13:_tween(v13.Menu.Quit, v6, {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    if v13.Menu.Quit:FindFirstChild("ImageLabel") then
        v13:_tween(v13.Menu.Quit.ImageLabel, v6, {
            ImageColor3 = Color3.fromRGB(0, 0, 0)
        }).Completed:Connect(function() --[[ Line: 64 ]]
            -- upvalues: v13 (copy), v6 (ref)
            task.wait(0.5);
            if not v13.Menu:FindFirstChild("Quit") then return end
            v13:_tween(v13.Menu.Quit, v6, {
                BackgroundColor3 = Color3.fromRGB(18, 18, 20)
            });
            if v13.Menu.Quit:FindFirstChild("ImageLabel") then
                v13:_tween(v13.Menu.Quit.ImageLabel, v6, {
                    ImageColor3 = Color3.fromRGB(255, 255, 255)
                });
            end
        end);
    end
end;
v7._listenKeyboard = function(v14) --[[ Line: 75 ]] --[[ Name: _listenKeyboard ]]
    -- upvalues: l_UserInputService_0 (copy), v4 (copy)
    local v17 = l_UserInputService_0.InputBegan:Connect(function(v15, v16) --[[ Line: 76 ]]
        -- upvalues: v14 (copy), v4 (ref)
        if v16 then
            return;
        else
            if v15.KeyCode == Enum.KeyCode.Q then
                v14:_handleAnimation();
                v4.callProvider("animationHandler", "changeSeatAnimation");
            end;
            return;
        end;
    end);
    v14._maid:GiveTask(v17);
end;
v7._tween = function(v18, v19, v20, v21) --[[ Line: 88 ]] --[[ Name: _tween ]]
    -- upvalues: l_TweenService_0 (copy)
    local v22 = l_TweenService_0:Create(v19, v20, v21);
    v22:Play();
    table.insert(v18._activeTweens, v22);
    v18._maid:GiveTask(function() --[[ Line: 92 ]]
        -- upvalues: v22 (copy)
        v22:Cancel();
        v22:Destroy();
    end);
    return v22;
end;
return v7;