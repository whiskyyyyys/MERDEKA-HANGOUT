return {
	Name = "kick",
	Aliases = {"usir"},
	Description = "Kick pemain dari server",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang akan di-kick"
		},
		{
			Type = "string",
			Name = "reason",
			Description = "Alasan kick",
			Default = "Kamu telah dikeluarkan dari server oleh Admin."
		}
	}
}
