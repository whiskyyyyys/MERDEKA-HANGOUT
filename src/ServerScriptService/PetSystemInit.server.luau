local ServerScriptService = game:GetService("ServerScriptService")
local PetShopService = require(ServerScriptService.Modules.PetShopService)
-- PetService akan dijalankan secara otomatis saat di-require karena memiliki event listeners
require(ServerScriptService.Modules.PetService)

PetShopService.Init()

print("[PetSystemInit] Sistem Pet berhasil dimuat!")
