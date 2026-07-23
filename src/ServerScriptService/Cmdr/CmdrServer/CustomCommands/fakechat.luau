return {
	Name = "fakechat",
	Aliases = {"sudo", "forcechat", "fc"},
	Description = "Memaksa player target untuk mengirim pesan di chat (Jail/Troll).",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "Player yang akan dikorbankan"
		},
		{
			Type = "strings",
			Name = "message",
			Description = "Pesan yang akan dia katakan"
		}
	}
}
