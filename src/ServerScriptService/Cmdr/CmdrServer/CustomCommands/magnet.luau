return {
	Name = "magnet",
	Aliases = {"pull"},
	Description = "Menarik player ke arahmu dengan kuat (bisa dimatikan dengan unmagnet).",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "Player yang ingin ditarik"
		}
	}
}
