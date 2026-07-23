-- ============================================================
-- GameConfig.lua
-- ModuleScript → ReplicatedStorage/Modules/GameConfig
-- Semua konfigurasi utama game Sambung Kata Jawa
-- ============================================================

local GameConfig = {}

-- ── Pengaturan Zona ─────────────────────────────────────────
-- Zona TIDAK lagi didefinisikan di sini.
-- Buat Part secara manual di Roblox Studio:
--   1. Buat Folder bernama "Zones" di dalam Workspace
--   2. Letakkan Part (bisa invisible) di dalam folder tersebut
--   3. Beri nama Part sesuai keinginan, misal "Zone1", "Zone2", dst.
--   4. Setel Attribute "MaxPlayers" (NumberValue) pada tiap Part
--      nilainya: 2 | 4 | 8  (default 2 jika tidak disetel)
-- ZoneManager akan otomatis mendeteksi semua Part di folder Zones.
GameConfig.ZoneFolder        = "Zones"   -- Nama folder di Workspace
GameConfig.DefaultMaxPlayers = 2         -- Fallback jika Part tidak punya Attribute MaxPlayers

-- ── Pengaturan Permainan ────────────────────────────────────
GameConfig.TurnTime          = 20   -- Detik max per giliran
GameConfig.MaxHP             = 2    -- Nyawa awal tiap pemain
GameConfig.MaxWrongPerTurn   = 5    -- Salah 5x → tanda berubah jadi X → nyawa berkurang
GameConfig.MinChainLength    = 1    -- Minimal huruf dari akhir kata (1, 2, atau 3 bebas)
GameConfig.PreGameCountdown  = 5    -- Detik hitungan mundur saat zone penuh
GameConfig.PartialCountdown  = 15   -- Detik hitungan mundur saat belum penuh (min 2 player)
GameConfig.MinPlayersToStart = 2    -- Minimal pemain untuk mulai countdown
GameConfig.MinPlayersByZoneSize = {
	[2] = 2,
	[4] = 3,
	[8] = 5,
}

-- ── Warna UI ────────────────────────────────────────────────
GameConfig.Colors = {
	Alive   = Color3.fromRGB(0,   200,  80),   -- Hijau
	Dead    = Color3.fromRGB(220,  50,  50),   -- Merah
	Timer   = Color3.fromRGB(255, 200,   0),   -- Kuning
	Panel   = Color3.fromRGB(30,   30,  30),   -- Panel gelapAC
	Text    = Color3.fromRGB(255, 255, 255),   -- Putih
}

-- ── Nama RemoteEvent / RemoteFunction ───────────────────────
-- Harus sama persis dengan yang dibuat di ServerScriptService/GameManager
GameConfig.Remotes = {
	-- Server → Client
	UpdateZoneInfo      = "UpdateZoneInfo",      -- kirim daftar zone ke client
	GameStarted         = "GameStarted",         -- memberi tahu game dimulai
	NewTurn             = "NewTurn",             -- giliran siapa + kata saat ini
	WordAccepted        = "WordAccepted",        -- kata diterima
	WordRejected        = "WordRejected",        -- kata ditolak (alasan)
	OpponentWrong       = "OpponentWrong",       -- server → all: lawan jawab salah
	PlayerEliminated    = "PlayerEliminated",    -- pemain gugur
	GameEnded           = "GameEnded",           -- pemenang diumumkan
	WinNotif            = "WinNotif",             -- server → client: detail reward menang/kalah
	UpdateHP            = "UpdateHP",            -- update UI nyawa
	TimerTick           = "TimerTick",           -- countdown tiap detik
	ZoneCountdown       = "ZoneCountdown",       -- hitungan mundur sebelum game mulai

	-- Coin system
	CoinReward          = "CoinReward",          -- server → client: reward coin setelah game
	CoinUpdate          = "CoinUpdate",          -- server → client: update total coin

	-- Stats system
	StatsUpdate         = "StatsUpdate",          -- server → client: update wins/losses

	-- Client → Server
	RequestJoinZone     = "RequestJoinZone",
	RequestLeaveZone    = "RequestLeaveZone",
	SubmitWord          = "SubmitWord",
	LiveTyping          = "LiveTyping",          -- relay ketikan ke semua pemain

	-- Admin
	AdminCommand        = "AdminCommand",        -- client → server: developer command
	AdminResponse       = "AdminResponse",       -- server → client: command response
	AdminAnnounce       = "AdminAnnounce",       -- server → all clients: announcement banner

	-- Leaderboard
	LeaderboardUpdate   = "LeaderboardUpdate",   -- server → all clients: top global data
	LossLeaderboardUpdate = "LossLeaderboardUpdate", -- server → all clients: top global losses

	-- Admin Abuse
	AdminAbuse          = "AdminAbuse",          -- server → all clients: abuse start/stop/countdown
}

-- ── Pengaturan Coin ─────────────────────────────────────────
GameConfig.Coin = {
	BaseWinMin       = 80,   -- coin minimum kalau menang
	BaseWinMax       = 150,  -- coin maksimum kalau menang
	PerWordBonus     = 15,   -- bonus per kata benar yang dijawab
	SpeedBonusFast   = 50,   -- bonus kalau menang < 60 detik
	SpeedBonusMedium = 25,   -- bonus kalau menang < 120 detik
	LoseReward       = 8,    -- coin per kata benar walau kalah
}

return GameConfig
