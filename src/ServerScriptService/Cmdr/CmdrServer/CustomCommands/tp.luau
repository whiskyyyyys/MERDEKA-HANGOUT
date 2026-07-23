return {
	Name = "tp",
	Aliases = {"teleport", "goto"},
	Description = "Teleportasi dirimu ke pemain lain",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "Pemain tujuan teleportasi"
		}
	}
}
