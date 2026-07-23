return {
	Name = "setlevel",
	Description = "Set level custom pemain",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang diubah"
		},
		{
			Type = "number",
			Name = "level",
			Description = "Level 1-6"
		}
	}
}
