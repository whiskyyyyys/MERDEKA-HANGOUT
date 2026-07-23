require('dotenv').config();
const { Client, GatewayIntentBits } = require('discord.js');
const axios = require('axios');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent
    ]
});

const PREFIX = '!';
const TOPIC = 'DiscordAdmin'; // Harus sama dengan di Roblox Script

client.on('clientReady', async () => {
    console.log(`Bot berhasil login sebagai ${client.user.tag}!`);
    
    // Fungsi untuk mengupdate status bot dengan jumlah player
    const updateStatus = async () => {
        try {
            const universeId = process.env.ROBLOX_UNIVERSE_ID;
            if (universeId) {
                const response = await axios.get(`https://games.roblox.com/v1/games?universeIds=${universeId}`);
                if (response.data && response.data.data && response.data.data.length > 0) {
                    const playing = response.data.data[0].playing || 0;
                    client.user.setActivity(`Merdeka Hangout | ${playing} Player`, { type: 3 }); // type 3 = Watching
                } else {
                    client.user.setActivity('Merdeka Hangout | 0 Player', { type: 3 });
                }
            } else {
                client.user.setActivity('Merdeka Hangout | 0 Player', { type: 3 });
            }
        } catch (error) {
            console.log("Gagal mengambil data player:", error.message);
            client.user.setActivity('Merdeka Hangout | 0 Player', { type: 3 });
        }
    };

    // Panggil sekali saat bot menyala
    updateStatus();

    // Jalankan setiap 30 detik
    setInterval(updateStatus, 30000);

    // DM ke pembuat bot (owner) otomatis tanpa perlu setting ID!
    try {
        const app = await client.application.fetch();
        const owner = app.owner.members ? app.owner.owner.user : app.owner;
        if (owner) {
            await owner.send(`✅ Bot **${client.user.tag}** berhasil dinyalakan dan siap menerima command admin Anda!`);
        }
    } catch (e) {
        console.log("Gagal mengirim DM ke owner. Mungkin DM diblokir.");
    }
    
    // Auto-send Update Log saat bot menyala
    const channelId = process.env.UPDATE_LOG_CHANNEL_ID;
    if (channelId && process.env.AUTO_SEND_LOG === 'true') {
        try {
            const channel = await client.channels.fetch(channelId);
            if (channel) {
                const updateMessage = `**Game Update v1.3.0 (#23)**\n> *Pembaruan besar-besaran telah rilis! Baca detail lengkap perubahannya di bawah ini:*\n\n` +
                                      `✦ **Additions**\n\`\`\`diff\n` +
                                      `+ [FITUR BARU] Auto-Resume AFK Reconnect: Memancing tidak pernah semudah ini! Jika kamu mengaktifkan Auto Fishing lalu terputus atau ter-kick karena AFK, saat kamu reconnect, karaktermu akan otomatis memegang pancingan dan lanjut memancing di posisi terakhirmu!\n\`\`\`\n\n` +
                                      `⇄ **Changes**\n\`\`\`md\n` +
                                      `# Perombakan Visual Ikan: Selamat tinggal kotak biru neon! Kini, ikan tangkapan yang melompat dari air murni berupa wujud gambar 2D aslinya, memberikan nuansa elegan layaknya game simulator premium.\n` +
                                      `# Penyesuaian Jeda Auto-Catch: Mode penarikan ikan otomatis yang sebelumnya terlihat kaku dan instan, kini diubah menjadi jauh lebih natural dengan jeda acak (2 hingga 4 detik).\n` +
                                      `# Pembaruan GUI Carry: Menu pemilihan Carry telah dirombak total! Menu kini muncul dengan mulus di sisi kanan layar, ukuran teks diperbesar, dan sepenuhnya responsif untuk SEMUA perangkat (Mobile, Tablet, PC).\n` +
                                      `# Peningkatan Sistem Spin: Sistem Spin Wheel (Roda Keberuntungan) telah dioptimalkan untuk memastikan proses putaran lebih mulus dan pembagian hadiah lebih stabil.\n\`\`\`\n\n` +
                                      `▲ **Fixes**\n\`\`\`md\n` +
                                      `# Memperbaiki bug kritis di mana tombol 'Auto Fishing' menghilang secara permanen setelah jendela notifikasi tangkapan ikan tertutup.\n` +
                                      `# Memperbaiki error merah (TweenService) pada animasi tangkapan jika ikan tidak memiliki gambar Icon.\n` +
                                      `# Memperbaiki bug duplikasi opsi pada menu Carry yang membuat tombol pilihan muncul berkali-kali.\n\`\`\``;
                await channel.send(updateMessage);
                console.log("Berhasil mengirim auto-update log ke channel public.");
            }
        } catch (e) {
            console.log("Gagal mengirim auto-update log public:", e.message);
        }
    }

    // Auto-send Staff Update Log
    const staffChannelId = process.env.STAFF_LOG_CHANNEL_ID;
    if (staffChannelId && process.env.AUTO_SEND_LOG === 'true') {
        try {
            const staffChannel = await client.channels.fetch(staffChannelId);
            if (staffChannel) {
                const staffUpdateMessage = `**Staff Command & System Update**\n> *New administrative commands and system limits have been implemented for moderation.*\n\n` +
                                           `✦ **New Commands & Features**\n\`\`\`diff\n` +
                                           `+ /kick [player] - Kick a player from the server.\n` +
                                           `+ /ban [player] [duration] - Temporarily ban a player with a set duration.\n` +
                                           `+ /unban [player] - Remove a ban from a player.\n` +
                                           `+ /kill [player] - Instantly eliminate a target player.\n` +
                                           `+ /tp [player] - Teleport directly to a specific player.\n\`\`\`\n\n` +
                                           `⇄ **Changes & Limits**\n\`\`\`md\n` +
                                           `# Redeem Code Limits: Codes can now be set with expiration dates and maximum usage limits.\n` +
                                           `# Code Validation: Added strict validation to prevent code abuse or double claiming.\n` +
                                           `# Shop Restrictions: Gifting system is now strictly verified via Server Scripts to prevent exploiters.\n\`\`\``;
                await staffChannel.send(staffUpdateMessage);
                console.log("Berhasil mengirim auto-update log ke channel staff.");
            }
        } catch (e) {
            console.log("Gagal mengirim auto-update log staff:", e.message);
        }
    }
});

client.on('messageCreate', async (message) => {
    if (message.author.bot) return;
    if (!message.content.startsWith(PREFIX)) return;

    // Pisahkan command dan argumen
    const args = message.content.slice(PREFIX.length).trim().split(/ +/);
    const command = args.shift().toLowerCase();

    // Command List
    if (['kick', 'kill', 'announce', 'ban', 'unban', 'warn', 'freeze', 'thaw', 'merdeka', 'tp', 'jail', 'unjail', 'givevip', 'restart', 'help', 'setlevel', 'updatelog'].includes(command)) {
        
        // ==========================================
        // SISTEM KEAMANAN (HIERARKI DISCORD ID)
        // ==========================================
        const ownerIds = (process.env.OWNER_IDS || "").split(",").map(i => i.trim()).filter(i => i);
        const ceoIds = (process.env.CEO_IDS || "").split(",").map(i => i.trim()).filter(i => i);
        const adminIds = (process.env.ADMIN_IDS || "").split(",").map(i => i.trim()).filter(i => i);
        const modIds = (process.env.MODERATOR_IDS || "").split(",").map(i => i.trim()).filter(i => i);

        const isOwner = ownerIds.includes(message.author.id) || ceoIds.includes(message.author.id);
        const isAdmin = isOwner || adminIds.includes(message.author.id);
        const isMod = isAdmin || modIds.includes(message.author.id);

        if (command === 'help') {
            if (!isMod) return message.reply("⛔ Akses Ditolak! Anda tidak memiliki izin Admin/Moderator.");
            
            let helpText = "**🛠️ DAFTAR COMMAND ADMIN MERDEKA HANGOUT**\n\n";
            
            if (isMod) {
                helpText += "**🔹 Moderator Commands:**\n";
                helpText += "`!kick [Target]` - Usir pemain dari game.\n";
                helpText += "`!jail [Target]` - Kurung pemain di penjara.\n";
                helpText += "`!unjail [Target]` - Bebaskan pemain.\n";
                helpText += "`!freeze [Target]` - Bekukan pemain.\n";
                helpText += "`!thaw [Target]` - Cairkan pemain.\n";
                helpText += "`!warn [Target] [Pesan]` - Beri peringatan.\n";
                helpText += "`!tp [Target1] [Target2]` - Pindahkan pemain.\n\n";
            }
            
            if (isAdmin) {
                helpText += "**🔸 Admin Commands:**\n";
                helpText += "`!announce [Pesan]` - Pengumuman Global.\n";
                helpText += "`!merdeka` - Perayaan kembang api.\n";
                helpText += "`!ban [Target]` - Blokir permanen.\n";
                helpText += "`!unban [Target]` - Cabut blokir permanen.\n";
                helpText += "`!kill [Target]` - Bunuh karakter.\n\n";
            }
            
            if (isOwner) {
                helpText += "**👑 Owner/CEO Commands:**\n";
                helpText += "`!givevip [Target]` - Beri VIP Gratis Permanen.\n";
                helpText += "`!setlevel [Target] [1-6]` - Set Level (Icon Bintang) pemain secara paksa.\n";
                helpText += "`!restart` - Soft Shutdown semua server (Update Tanpa Kick).\n";
            }
            
            helpText += "\n*Ganti `[Target]` dengan nama Roblox asli atau `all` untuk semua pemain.*";
            return message.reply(helpText);
        }

        let allowed = false;
        if (command === 'givevip' || command === 'restart' || command === 'setlevel' || command === 'updatelog') {
            allowed = isOwner; // Hanya Owner & CEO
        } else if (['ban', 'unban', 'announce', 'merdeka', 'kill'].includes(command)) {
            allowed = isAdmin; // Admin ke atas
        } else if (['kick', 'jail', 'unjail', 'freeze', 'thaw', 'warn', 'tp'].includes(command)) {
            allowed = isMod; // Moderator ke atas
        }

        if (!allowed) {
            return message.reply(`⛔ Akses Ditolak! ID Discord Anda tidak memiliki izin yang cukup untuk menjalankan perintah \`!${command}\`.`);
        }

        let target = "";
        let commandArgs = "";
        
        if (command === 'updatelog') {
            const channelId = process.env.UPDATE_LOG_CHANNEL_ID;
            if (!channelId) {
                return message.reply("⛔ Konfigurasi `UPDATE_LOG_CHANNEL_ID` belum diset di Railway/Environment Variables!");
            }
            const channel = client.channels.cache.get(channelId);
            if (!channel) {
                return message.reply("⛔ Tidak dapat menemukan channel dengan ID tersebut. Pastikan bot ada di server yang sama dan memiliki izin 'View Channel' & 'Send Messages'.");
            }
            
            const updateMessage = `**Game Update v1.3.0 (#23)**\n> *Pembaruan besar-besaran telah rilis! Baca detail lengkap perubahannya di bawah ini:*\n\n` +
                                  `✦ **Additions**\n\`\`\`diff\n` +
                                  `+ [FITUR BARU] Auto-Resume AFK Reconnect: Memancing tidak pernah semudah ini! Jika kamu mengaktifkan Auto Fishing lalu terputus atau ter-kick karena AFK, saat kamu reconnect, karaktermu akan otomatis memegang pancingan dan lanjut memancing di posisi terakhirmu!\n\`\`\`\n\n` +
                                  `⇄ **Changes**\n\`\`\`md\n` +
                                  `# Perombakan Visual Ikan: Selamat tinggal kotak biru neon! Kini, ikan tangkapan yang melompat dari air murni berupa wujud gambar 2D aslinya, memberikan nuansa elegan layaknya game simulator premium.\n` +
                                  `# Penyesuaian Jeda Auto-Catch: Mode penarikan ikan otomatis yang sebelumnya terlihat kaku dan instan, kini diubah menjadi jauh lebih natural dengan jeda acak (2 hingga 4 detik).\n` +
                                  `# Pembaruan GUI Carry: Menu pemilihan Carry telah dirombak total! Menu kini muncul dengan mulus di sisi kanan layar, ukuran teks diperbesar, dan sepenuhnya responsif untuk SEMUA perangkat (Mobile, Tablet, PC).\n` +
                                  `# Peningkatan Sistem Spin: Sistem Spin Wheel (Roda Keberuntungan) telah dioptimalkan untuk memastikan proses putaran lebih mulus dan pembagian hadiah lebih stabil.\n\`\`\`\n\n` +
                                  `▲ **Fixes**\n\`\`\`md\n` +
                                  `# Memperbaiki bug kritis di mana tombol 'Auto Fishing' menghilang secara permanen setelah jendela notifikasi tangkapan ikan tertutup.\n` +
                                  `# Memperbaiki error merah (TweenService) pada animasi tangkapan jika ikan tidak memiliki gambar Icon.\n` +
                                  `# Memperbaiki bug duplikasi opsi pada menu Carry yang membuat tombol pilihan muncul berkali-kali.\n\`\`\``;
                                  
            try {
                await channel.send(updateMessage);
                return message.reply(`✅ Berhasil mengirim Update Log ke channel <#${channelId}>!`);
            } catch (err) {
                console.error("Gagal mengirim update log:", err);
                return message.reply("⛔ Gagal mengirim pesan ke channel tersebut. Cek permission bot.");
            }
        }

        if (command === 'announce' || command === 'merdeka' || command === 'restart') {
            commandArgs = args.join(" ");
            if (command === 'announce' && !commandArgs) return message.reply("Contoh: `!announce Server update`");
        } else if (command === 'tp') {
            target = args.shift();
            commandArgs = args.shift(); // Target kedua
            if (!target || !commandArgs) return message.reply("Contoh: `!tp Budi Andi` (Pindahkan Budi ke tempat Andi)");
        } else {
            target = args.shift();
            if (!target) return message.reply(`Contoh: \`!${command} Budi\` atau \`!${command} all\``);
            commandArgs = args.join(" ");
        }

        // ==========================================
        // Cek Mapping ID Discord -> Roblox
        // ==========================================
        let adminRobloxId = null;
        if (process.env.DISCORD_TO_ROBLOX) {
            const pairs = process.env.DISCORD_TO_ROBLOX.split(",");
            for (let pair of pairs) {
                const parts = pair.split(":");
                if (parts.length === 2 && parts[0].trim() === message.author.id) {
                    adminRobloxId = parts[1].trim();
                    break;
                }
            }
        }

        const payloadData = {
            command: command,
            target: target,
            args: commandArgs,
            adminId: adminRobloxId,
            adminName: message.member ? message.member.displayName : message.author.username
        };

        const url = `https://apis.roblox.com/messaging-service/v1/universes/${process.env.ROBLOX_UNIVERSE_ID}/topics/${TOPIC}`;
        
        try {
            await axios.post(url, {
                message: JSON.stringify(payloadData)
            }, {
                headers: {
                    'x-api-key': process.env.ROBLOX_API_KEY,
                    'Content-Type': 'application/json'
                }
            });

            message.reply(`? Berhasil mengirim command \`${command}\` ke server Roblox!`);
        } catch (error) {
            console.error("Error mengirim ke Roblox:", error.response ? error.response.data : error.message);
            message.reply("? Gagal mengirim command. Cek console bot untuk detail error (Pastikan API Key & Universe ID benar).");
        }
    }
});

client.login(process.env.DISCORD_TOKEN);
