return {
	Name = "warn",
	Description = "Beri peringatan ke pemain",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang diberi peringatan"
		},
		{
			Type = "string",
			Name = "message",
			Description = "Pesan peringatan"
		}
	}
}
