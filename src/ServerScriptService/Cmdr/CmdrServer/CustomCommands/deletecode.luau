return {
	Name = "deletecode",
	Aliases = {"removecode", "delcode"},
	Description = "Hapus kode redeem (Khusus Owner/Co-Owner)",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "code",
			Description = "Nama kode yang mau dihapus"
		}
	}
}
