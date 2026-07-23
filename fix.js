const fs = require('fs');

function fixFile(path, replacements) {
    if (!fs.existsSync(path)) return;
    let content = fs.readFileSync(path, 'utf8');
    let changed = false;
    for (let i=0; i<replacements.length; i++) {
        let r = replacements[i];
        if (content.includes(r.from)) {
            content = content.split(r.from).join(r.to);
            changed = true;
        }
    }
    if (changed) {
        fs.writeFileSync(path, content, 'utf8');
        console.log('Fixed ' + path);
    }
}

fixFile('src/ServerScriptService/Minigames/SambungKata/ZoneManager.server.luau', [
    { from: 'ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Minigames"):WaitForChild("SambungKata")', to: 'ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")' }
]);

fixFile('src/ServerScriptService/Minigames/SambungKata/CoinService.server.luau', [
    { from: 'ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Minigames"):WaitForChild("SambungKata")', to: 'ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")' }
]);

fixFile('src/ServerScriptService/Minigames/SambungKata/GameManager.server.luau', [
    { from: 'ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Minigames"):WaitForChild("SambungKata")', to: 'ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")' }
]);

const mkPath = 'src/StarterGui/Minigames/SambungKata/MobileKeyboard/LocalScript.client.luau';
if (fs.existsSync(mkPath)) {
    let mk = fs.readFileSync(mkPath, 'utf8');
    // Replace the specific malformed line
    mk = mk.replace(/local kbGui = waitForScreenGui\(playerGui, "MobileKeyboard", 2\)\r?\n\t*or waitForScreenGui\(playerGui, "MobileKeyboard", 2\)\r?\n\t*or waitForScreenGui\(playerGui, "KeyboardGUI", 2\)/, 'local kbGui = waitForScreenGui(playerGui, "KeyboardGUI", 2)\n\tor waitForScreenGui(playerGui, "MobileKeyboard", 2)');
    fs.writeFileSync(mkPath, mk, 'utf8');
    console.log('Fixed MobileKeyboard 1');
}

// Fix ZoneGui LocalScript LeaveGui/ZoneCard frame not found
const zgPath = 'src/StarterGui/Minigames/SambungKata/ZoneGui/LocalScript.client.luau';
if (fs.existsSync(zgPath)) {
    let zg = fs.readFileSync(zgPath, 'utf8');
    // The script waits for LeaveGui or ZoneGui, then finds Frame or ZoneCard.
    // It errored: Frame utama LeaveGui/ZoneCard tidak ditemukan!
    // Let's modify it to be more robust.
    zg = zg.replace('local card = screenGui:FindFirstChild("Frame") or screenGui:FindFirstChild("ZoneCard")', 
                    'local card = screenGui:WaitForChild("Frame", 3) or screenGui:WaitForChild("ZoneCard", 3) or screenGui:FindFirstChildWhichIsA("Frame")');
    zg = zg.replace('card = screenGui:WaitForChild("Frame", 5) or screenGui:WaitForChild("ZoneCard", 10)', 
                    'card = screenGui:WaitForChild("Frame", 3) or screenGui:WaitForChild("ZoneCard", 3) or screenGui:FindFirstChildWhichIsA("Frame")');
    fs.writeFileSync(zgPath, zg, 'utf8');
    console.log('Fixed ZoneGui');
}
