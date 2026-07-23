return {
	Name = "unban",
	Aliases = {"pardon"},
	Description = "Menghapus status ban dari pemain (menggunakan UserId)",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "userId",
			Description = "UserId dari pemain yang akan di-unban (harus ID, bukan nama)"
		}
	}
}
