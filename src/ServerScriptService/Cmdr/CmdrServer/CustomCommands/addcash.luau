return {
	Name = "addcash",
	Aliases = {"givecash"},
	Description = "Menambahkan Cash ke pemain (Khusus Owner/Co-Owner)",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang akan diberi Cash"
		},
		{
			Type = "integer",
			Name = "amount",
			Description = "Jumlah Cash",
			Default = 1000
		}
	}
}
