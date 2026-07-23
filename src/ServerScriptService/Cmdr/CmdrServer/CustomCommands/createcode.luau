return {
	Name = "createcode",
	Aliases = {"addcode", "newcode"},
	Description = "Buat kode redeem baru (Khusus Owner/Co-Owner)",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "code",
			Description = "Nama kode (contoh: MERDEKA17)"
		},
		{
			Type = "string",
			Name = "rewardType",
			Description = "Jenis reward: Cash, MHCoin, Spins"
		},
		{
			Type = "integer",
			Name = "amount",
			Description = "Jumlah reward",
			Default = 100
		},
		{
			Type = "integer",
			Name = "limit",
			Description = "Batas maksimal pemain yang bisa menukarkan kode (opsional, kosong = tak terbatas)",
			Optional = true
		},
		{
			Type = "integer",
			Name = "expiryDays",
			Description = "Durasi kadaluarsa dalam hitungan hari (opsional, kosong = selamanya)",
			Optional = true
		}
	}
}
