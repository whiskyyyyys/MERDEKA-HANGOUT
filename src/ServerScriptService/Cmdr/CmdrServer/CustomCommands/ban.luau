return {
	Name = "ban",
	Aliases = {"banned"},
	Description = "Ban pemain (bisa berdurasi dalam hitungan hari)",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang akan di-ban"
		},
		{
			Type = "integer",
			Name = "days",
			Description = "Durasi ban dalam hari (opsional, kosong = selamanya)",
			Optional = true
		},
		{
			Type = "string",
			Name = "reason",
			Description = "Alasan ban",
			Default = "Melanggar peraturan game."
		}
	}
}
