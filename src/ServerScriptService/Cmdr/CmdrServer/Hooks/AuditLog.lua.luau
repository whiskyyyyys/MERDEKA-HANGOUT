if game:GetService("RunService"):IsClient() then return function() end end

local HttpService = game:GetService("HttpService")

local WEBHOOK_URL = "https://webhook.lewisakura.moe/api/webhooks/1523673829031940277/HaE2EaCfV5teAR1s3pv-9yPqMWai15UbyRbSjPKbV9URwJwQdnNTqgrWZLjM_4Xqa7fi"

return function(registry)
	print("[Cmdr] AuditLog hook didaftarkan ke registry!")
	registry:RegisterHook("AfterRun", function(context)
		print("[Cmdr] AfterRun hook terpanggil untuk command:", context.Name)
		
		if WEBHOOK_URL == "" or WEBHOOK_URL == "MASUKKAN_LINK_WEBHOOK_DISCORD_DISINI" then 
			warn("[Cmdr] Webhook URL kosong!")
			return 
		end
		
		local adminName = context.Executor.Name
		local adminId = context.Executor.UserId
		local rawCommand = context.RawText
		
		local data = {
			embeds = {{
				title = "🛡️ Admin Command Log",
				description = string.format("**Admin:** %s (%d)\n**Command:** `%s`", adminName, adminId, rawCommand),
				color = 16753920,
				timestamp = DateTime.now():ToIsoDate()
			}}
		}
		
		task.spawn(function()
			print("[Cmdr] Mengirim data ke webhook...")
			local success, err = pcall(function()
				HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
			end)
			if not success then
				warn("[AuditLog] Gagal mengirim webhook! Error: " .. tostring(err))
			else
				print("[Cmdr] Webhook berhasil terkirim!")
			end
		end)
	end)
end
