--!strict
--[=[
    DiscordLogger.luau
    Asynchronous telemetry reporter to Discord Webhooks with rate-limit queue.
]=]

local HttpService = game:GetService("HttpService")

local DiscordLogger = {}
DiscordLogger.__index = DiscordLogger

local messageQueue: { any } = {}
local isProcessingQueue = false
local lastPostTime = 0

function DiscordLogger.Init(config)
    DiscordLogger.Config = config
end

function DiscordLogger.LogViolation(player: Player, violationType: string, strikes: number, actionTaken: string)
    local config = DiscordLogger.Config.Discord
    if not config.Enabled or config.WebhookUrl == "" or string.find(config.WebhookUrl, "YOUR_WEBHOOK_HERE") then
        return
    end

    if strikes < config.MinimumStrikesToLog and actionTaken ~= "KICK" then
        return
    end

    local color = 0xFFA500 -- Orange
    if actionTaken == "KICK" then
        color = 0xFF0000 -- Red
    elseif actionTaken == "ROLLBACK" then
        color = 0x3498DB -- Blue
    end

    local ping = math.floor(player:GetNetworkPing() * 1000)
    local payload = {
        embeds = {
            {
                title = "🚨 Security Alert: Violation Detected",
                color = color,
                fields = {
                    { name = "Player", value = string.format("%s (`%d`)", player.Name, player.UserId), inline = true },
                    { name = "Ping", value = string.format("%d ms", ping), inline = true },
                    { name = "Strikes", value = string.format("%d / %d", strikes, DiscordLogger.Config.MaxStrikesBeforeKick), inline = true },
                    { name = "Violation Details", value = violationType, inline = false },
                    { name = "Action Taken", value = string.format("**%s**", actionTaken), inline = true },
                    { name = "Server JobId", value = string.sub(game.JobId ~= "" and game.JobId or "Studio-Session", 1, 14), inline = true },
                },
                footer = { text = "Roblox Anti-Cheat Suite • Server-Authoritative Security" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }

    table.insert(messageQueue, { Url = config.WebhookUrl, Payload = payload })
    DiscordLogger.ProcessQueue()
end

function DiscordLogger.LogBan(moderator: Player, targetName: string, targetUserId: number, reason: string, duration: string, banId: string)
    local config = DiscordLogger.Config.Discord
    local modWebhook = (DiscordLogger.Config.Moderation and DiscordLogger.Config.Moderation.DiscordModWebhook) or config.WebhookUrl

    if DiscordLogger.Config.DebugMode then
        print(string.format("🔨 [Staff Moderation Log] %s banned %s (%d) | Duration: %s | Reason: %s | Ref: %s",
            moderator.Name, targetName, targetUserId, duration, reason, banId))
    end

    if not config.Enabled or modWebhook == "" or string.find(modWebhook, "YOUR_") then
        return
    end

    local payload = {
        embeds = {
            {
                title = "🔨 Moderation Enforcement: Player Banned",
                color = 0xDC2626, -- Deep Crimson Red
                description = string.format("A moderation sanction was executed against **%s** by an authorized staff member.", targetName),
                fields = {
                    { name = "👤 Target Account", value = string.format("**%s**\nUserId: `%d`", targetName, targetUserId), inline = true },
                    { name = "🛡️ Issued By", value = string.format("**%s**\nUserId: `%d`", moderator.Name, moderator.UserId), inline = true },
                    { name = "⏳ Duration", value = string.format("`%s`", duration), inline = true },
                    { name = "📋 Infraction Reason", value = string.format("```%s```", reason), inline = false },
                    { name = "🏷️ Incident ID", value = string.format("`%s`", banId), inline = true },
                    { name = "🌐 Server Job", value = string.format("`%s`", string.sub(game.JobId ~= "" and game.JobId or "Studio-Session", 1, 14)), inline = true },
                },
                footer = { text = "Aegis Moderation Engine • Server Authority" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }

    table.insert(messageQueue, { Url = modWebhook, Payload = payload })
    DiscordLogger.ProcessQueue()
end

function DiscordLogger.ProcessQueue()
    if isProcessingQueue or #messageQueue == 0 then return end
    isProcessingQueue = true

    task.spawn(function()
        while #messageQueue > 0 do
            local now = os.clock()
            if now - lastPostTime < 1.1 then
                task.wait(1.1 - (now - lastPostTime))
            end

            local item = table.remove(messageQueue, 1)
            lastPostTime = os.clock()

            local targetUrl = (type(item) == "table" and item.Url) or DiscordLogger.Config.Discord.WebhookUrl
            local payloadData = (type(item) == "table" and item.Payload) or item

            local success, err = pcall(function()
                HttpService:PostAsync(
                    targetUrl,
                    HttpService:JSONEncode(payloadData),
                    Enum.HttpContentType.ApplicationJson
                )
            end)

            if not success and DiscordLogger.Config.DebugMode then
                warn("[AntiCheat Webhook Error]:", err)
            end
        end
        isProcessingQueue = false
    end)
end

return DiscordLogger
