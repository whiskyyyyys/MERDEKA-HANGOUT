const fs = require('fs');
const zgPath = 'src/StarterGui/Minigames/SambungKata/ZoneGui/LocalScript.client.luau';
if (fs.existsSync(zgPath)) {
    let zg = fs.readFileSync(zgPath, 'utf8');
    zg = zg.replace('if not card then\r\n\tcard = screenGui:WaitForChild("Frame", 3) or screenGui:WaitForChild("ZoneCard", 3) or screenGui:FindFirstChildWhichIsA("Frame")\r\nend', 'if not card then\n\twarn("[ZoneGui] Frame LeaveGui/ZoneCard tidak ditemukan! Script dihentikan sementara.")\n\treturn\nend');
    // For MacOS/Linux line endings
    zg = zg.replace('if not card then\n\tcard = screenGui:WaitForChild("Frame", 3) or screenGui:WaitForChild("ZoneCard", 3) or screenGui:FindFirstChildWhichIsA("Frame")\nend', 'if not card then\n\twarn("[ZoneGui] Frame LeaveGui/ZoneCard tidak ditemukan! Script dihentikan sementara.")\n\treturn\nend');
    fs.writeFileSync(zgPath, zg, 'utf8');
    console.log('ZoneGui patched to prevent crash');
}
