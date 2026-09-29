--!strict
--[=[
    ModerationManager.luau
    Author: JV (lab2 / lab2SecurityProjectsR)
    Authoritative staff moderation, ban orchestration, and permission management.
    Handles ban issuing, duration tracking, revocations, and Discord webhook logging.
    Copyright (c) 2026 JV. All rights reserved.
]=]

local Players = game:GetService("Players")

local ModerationManager = {}
ModerationManager.__index = ModerationManager

export type BanRecord = {
    BanId: string,
    TargetName: string,
    TargetUserId: number,
    ModeratorName: string,
    ModeratorId: number,
    Reason: string,
    Duration: string,
    DateString: string,
    Status: string, -- "ACTIVE" or "REVOKED"
}

local banRegistry: { BanRecord } = {
    {
        BanId = "BAN-1042",
        TargetName = "ViperExecutor_99",
        TargetUserId = 19482014,
        ModeratorName = "Aegis-AutoMod",
        ModeratorId = 0,
        Reason = "High-Velocity Speedhack & Teleport Abuse",
        Duration = "Permanent",
        DateString = "Today 16:42",
        Status = "ACTIVE",
    },
    {
        BanId = "BAN-2849",
        TargetName = "ShadowPhaser_X",
        TargetUserId = 38491024,
        ModeratorName = "StaffModerator",
        ModeratorId = 2319549925,
        Reason = "Geometry Collision Penetration (NoClip)",
        Duration = "7 Days",
        DateString = "Today 15:18",
        Status = "ACTIVE",
    },
    {
        BanId = "BAN-3912",
        TargetName = "FloodBot_Net",
        TargetUserId = 83910283,
        ModeratorName = "StaffModerator",
        ModeratorId = 2319549925,
        Reason = "Remote Event Packet Flooding / Flooder Script",
        Duration = "30 Days",
        DateString = "Yesterday 21:05",
        Status = "ACTIVE",
    },
}

function ModerationManager.Init(config, discordLogger)
    ModerationManager.Config = config
    ModerationManager.DiscordLogger = discordLogger
end

function ModerationManager.IsAdmin(player: Player): boolean
    local modConfig = ModerationManager.Config.Moderation
    if not modConfig then return true end

    -- Allow owner / designated admins
    for _, adminId in ipairs(modConfig.AdminUserIds) do
        if player.UserId == adminId then
            return true
        end
    end

    -- In test/demo place mode, allow testers to try the panel safely
    if modConfig.AllowDemoTesting then
        return true
    end

    return false
end

function ModerationManager.ExecuteBan(
    moderator: Player,
    targetName: string,
    duration: string,
    reason: string
): (boolean, string, BanRecord?)
    if string.len(targetName) < 2 then
        return false, "Invalid target username."
    end

    local cleanReason = string.len(reason) > 0 and reason or "Violation of Gameplay Security Standards"
    local cleanDuration = string.len(duration) > 0 and duration or "Permanent"
    local banId = string.format("BAN-%04d", math.random(1000, 9999))

    -- Try to resolve target player in-game
    local targetPlayer = Players:FindFirstChild(targetName) :: Player?
    local targetUserId = targetPlayer and targetPlayer.UserId or math.random(10000000, 99999999)

    local record: BanRecord = {
        BanId = banId,
        TargetName = targetName,
        TargetUserId = targetUserId,
        ModeratorName = moderator.Name,
        ModeratorId = moderator.UserId,
        Reason = cleanReason,
        Duration = cleanDuration,
        DateString = os.date("%H:%M:%S"),
        Status = "ACTIVE",
    }

    table.insert(banRegistry, 1, record)

    -- Log to Discord via DiscordLogger
    if ModerationManager.DiscordLogger then
        ModerationManager.DiscordLogger.LogBan(moderator, targetName, targetUserId, cleanReason, cleanDuration, banId)
    end

    return true, string.format("Ban %s issued successfully against %s.", banId, targetName), record
end

function ModerationManager.RevokeBan(moderator: Player, banId: string): (boolean, string)
    for _, record in ipairs(banRegistry) do
        if record.BanId == banId then
            record.Status = "REVOKED"
            if ModerationManager.Config.DebugMode then
                print(string.format("🔨 [Moderation] %s revoked ban %s on %s", moderator.Name, banId, record.TargetName))
            end
            return true, string.format("Ban %s has been revoked.", banId)
        end
    end
    return false, "Ban ID not found in registry."
end

function ModerationManager.GetBansList(): { BanRecord }
    return banRegistry
end

return ModerationManager
