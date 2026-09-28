--!strict
--[=[
    AntiCheat Configuration File
    Centralized thresholds, tolerances, and action policies.
]=]

local Config = {
    -- General System Settings
    DebugMode = true,                     -- Prints security telemetry to Studio Output
    MaxStrikesBeforeKick = 8,             -- Accumulation of violations before kicking
    StrikeDecayInterval = 12,             -- Seconds without violation to reduce 1 strike
    RollbackCooldown = 0.35,              -- Minimum seconds between rubberband actions

    -- Discord Webhook Telemetry
    Discord = {
        Enabled = true,                  -- Set to true if you have a valid Webhook URL
        WebhookUrl = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE",
        MinimumStrikesToLog = 3,          -- Avoid webhook spam for minor 1-strike lag hiccups
        NotifyOnKick = true,
    },

    -- Movement & Physics Constraints
    Movement = {
        BaseWalkSpeed = 20,               -- Accommodates standard walk and sprint mechanics
        SpeedTolerance = 22.0,            -- Buffer for jump momentum, slopes, and latency spikes (Total ~42 studs/s limit)
        MaxTeleportDistance = 45,         -- Maximum allowable stud jump in a single sub-second frame
        MaxJumpAirTime = 1.35,            -- Max seconds allowed in Freefall without touching floor
        MinGroundRaycastDistance = 6.0,   -- Distance downward to look for solid geometry
        NoClipEnabled = true,             -- Check trajectory intersection with CanCollide parts
        PingCompensationFactor = 0.08,    -- Extra stud buffer per 100ms of network ping
    },

    -- Combat & Hitbox Integrity
    Combat = {
        MaxWeaponRange = 85,              -- Maximum legitimate firing distance in studs
        MaxHitboxPadding = 3.5,           -- Permissible margin around target's actual Part size
        MaxAngleConeDegrees = 65,         -- Maximum angle between LookVector and Target Vector
        MinFireInterval = 0.12,           -- Minimum seconds allowed between consecutive shots (Rate limit)
        RequireLineOfSight = true,        -- Cast server raycast to verify target isn't behind a wall
    },

    -- Remote Event Security
    Remotes = {
        MaxCallsPerSecond = 35,           -- Flooding threshold per client
        EnforceTypeSanitization = true,
    },

    -- Staff & Moderation System
    Moderation = {
        AdminUserIds = { 2319549925 },       -- User's Roblox ID has full admin authority
        AllowDemoTesting = true,             -- Enables interactive ban showcase in test place
        DiscordModWebhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE",
    }
}

return table.freeze(Config)
