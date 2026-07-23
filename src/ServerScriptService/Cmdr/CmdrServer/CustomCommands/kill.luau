return {
	Name = "kill",
	Aliases = {"mati", "slay"},
	Description = "Membunuh pemain",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "targets",
			Description = "Pemain yang akan dibunuh"
		}
	}
}
