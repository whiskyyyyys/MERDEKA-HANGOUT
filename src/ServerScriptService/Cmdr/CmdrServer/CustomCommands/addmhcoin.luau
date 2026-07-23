return {
	Name = "addmhcoin",
	Aliases = {"givemhcoin"},
	Description = "Menambahkan MHCoin ke pemain (Khusus Owner/Co-Owner)",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang akan diberi MHCoin"
		},
		{
			Type = "integer",
			Name = "amount",
			Description = "Jumlah MHCoin",
			Default = 100
		}
	}
}
