return {
	Name = "addspins",
	Aliases = {"givedaticket", "addticket"},
	Description = "Menambahkan tiket spin ke pemain (Khusus Owner/Co-Owner)",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang akan diberi tiket"
		},
		{
			Type = "integer",
			Name = "amount",
			Description = "Jumlah tiket",
			Default = 1
		}
	}
}
