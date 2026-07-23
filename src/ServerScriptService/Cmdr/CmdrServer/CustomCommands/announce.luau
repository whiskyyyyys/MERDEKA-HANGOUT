return {
	Name = "announce",
	Aliases = {"pengumuman"},
	Description = "Membuat pengumuman global",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "message",
			Description = "Pesan pengumuman"
		}
	}
}
