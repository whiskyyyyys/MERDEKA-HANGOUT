return {
	Name = "givefish",
	Aliases = {"spawnfish"},
	Description = "Memberikan ikan tertentu ke pemain dengan berat (Kg) kustom (bisa ekstrem/raksasa).",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "Target",
			Description = "Pemain yang akan menerima ikan (bisa all, others, nama)"
		},
		{
			Type = "fish",
			Name = "FishName",
			Description = "Nama ikan persis (contoh: Nemi, Turtle, ReefShark)"
		},
		{
			Type = "number",
			Name = "WeightKg",
			Description = "Berat ikan dalam Kg (semakin berat, wujud ikan akan semakin raksasa)"
		}
	}
}
