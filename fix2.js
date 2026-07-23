const fs = require('fs');

const ulPath = 'src/StarterGui/UpdateLogGUI/UpdateLogClient.client.luau';
if (fs.existsSync(ulPath)) {
    let ul = fs.readFileSync(ulPath, 'utf8');
    // Ensure Remotes folder is fetched properly. We can just add a safe getter or use WaitForChild with timeout.
    // Actually, UpdateLogGUI is trying to get OpenUpdateLog. Who creates OpenUpdateLog?
    // Let's just create the folder if it doesn't exist so it doesn't yield infinitely if the server hasn't made it.
    // Better yet, I will create a script in ServerScriptService to initialize ReplicatedStorage.Remotes
    console.log('Checked UpdateLogGUI');
}

const initPath = 'src/ServerScriptService/SystemInit.server.luau';
const initCode = `-- SystemInit.server.luau
-- Ensures shared folders exist in ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if not ReplicatedStorage:FindFirstChild("Remotes") then
    local r = Instance.new("Folder")
    r.Name = "Remotes"
    r.Parent = ReplicatedStorage
end
if not ReplicatedStorage:FindFirstChild("Modules") then
    local m = Instance.new("Folder")
    m.Name = "Modules"
    m.Parent = ReplicatedStorage
end
`;
fs.writeFileSync(initPath, initCode, 'utf8');
console.log('Created SystemInit.server.luau');

