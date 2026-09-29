--!strict
--[=[
    AntiCheatServer.server.luau
    Author: JV (lab2 / lab2SecurityProjectsR)
    Central security coordinator and lifecycle manager.
    Copyright (c) 2026 JV. All rights reserved.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Locate parent folder or script hierarchy
local AntiCheatFolder = script.Parent
local Config = require(AntiCheatFolder:WaitForChild("Config") :: ModuleScript)
local MovementValidator = require(AntiCheatFolder.Modules:WaitForChild("MovementValidator") :: ModuleScript)
local CombatValidator = require(AntiCheatFolder.Modules:WaitForChild("CombatValidator") :: ModuleScript)
local RemoteSanitizer = require(AntiCheatFolder.Modules:WaitForChild("RemoteSanitizer") :: ModuleScript)
local DiscordLogger = require(AntiCheatFolder.Modules:WaitForChild("DiscordLogger") :: ModuleScript)
local EnvironmentSetup = require(AntiCheatFolder.Modules:WaitForChild("EnvironmentSetup") :: ModuleScript)
local ModerationManager = require(AntiCheatFolder.Modules:WaitForChild("ModerationManager") :: ModuleScript)

-- Initialize all modules & map environment
EnvironmentSetup.Init()
MovementValidator.Init(Config)
CombatValidator.Init(Config)
RemoteSanitizer.Init(Config)
DiscordLogger.Init(Config)
ModerationManager.Init(Config, DiscordLogger)

-- Create / Locate Shared Communication Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("AntiCheatRemotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "AntiCheatRemotes"
    remotesFolder.Parent = ReplicatedStorage
end

local function GetOrCreateRemote(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name) :: RemoteEvent?
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote
end

local SecurityAlertRemote = GetOrCreateRemote("SecurityAlertRemote")
local SimulateAttackRemote = GetOrCreateRemote("SimulateAttackRemote")
local ResetStrikesRemote = GetOrCreateRemote("ResetStrikesRemote")
local AdminBanRemote = GetOrCreateRemote("AdminBanRemote")
local AdminRevokeRemote = GetOrCreateRemote("AdminRevokeRemote")
local BanListSyncRemote = GetOrCreateRemote("BanListSyncRemote")

local lastFloodAlertTimes: { [Player]: number } = {}

local function FormatKickMessage(reason: string): string
    local category = "Gameplay Integrity Desynchronization"
    local errorCode = "SEC-400"

    if string.find(reason, "Speedhack") then
        category = "Movement Physics Violation (Speed)"
        errorCode = "SEC-501-SPD"
    elseif string.find(reason, "Teleport") then
        category = "Position Discontinuity (Teleportation)"
        errorCode = "SEC-502-TLP"
    elseif string.find(reason, "Fly") then
        category = "Freefall Physics Manipulation (Anti-Fly)"
        errorCode = "SEC-503-FLY"
    elseif string.find(reason, "NoClip") then
        category = "Geometry Collision Bypass (NoClip)"
        errorCode = "SEC-504-NCL"
    elseif string.find(reason, "Combat") or string.find(reason, "Hitbox") then
        category = "Combat Integrity Validation Failure"
        errorCode = "SEC-701-CBT"
    elseif string.find(reason, "Remote") or string.find(reason, "Flooding") then
        category = "Network Rate-Limit Exhaustion (DoS Protocol)"
        errorCode = "SEC-901-NET"
    end

    local incidentId = string.format("INC-%04d", math.random(1000, 9999))

    return string.format(
        "[Aegis Security System]\n" ..
        "Session terminated: Repeated gameplay integrity violations.\n\n" ..
        "Violation: %s\n" ..
        "Error Code: %s\n" ..
        "Reference: %s\n\n" ..
        "Please restart your client and rejoin.",
        category,
        errorCode,
        incidentId
    )
end

local function HandleViolation(player: Player, violationReason: string, strikes: number, customAction: string?)
    local actionTaken = customAction or "ROLLBACK"

    if strikes >= Config.MaxStrikesBeforeKick then
        actionTaken = "KICK"
    end

    if Config.DebugMode then
        print(string.format("[AntiCheat - Strike %d/%d] Player: %s | Violation: %s | Action: %s",
            strikes, Config.MaxStrikesBeforeKick, player.Name, violationReason, actionTaken))
    end

    -- Notify client UI for demonstration
    SecurityAlertRemote:FireClient(player, {
        Reason = violationReason,
        Strikes = strikes,
        Action = actionTaken,
        Timestamp = os.clock()
    })

    -- Log to Discord if enabled
    DiscordLogger.LogViolation(player, violationReason, strikes, actionTaken)

    -- Enforce kick if limit reached
    if actionTaken == "KICK" then
        task.delay(0.2, function()
            player:Kick(FormatKickMessage(violationReason))
        end)
    end
end

-- Setup player listeners
Players.PlayerAdded:Connect(function(player)
    MovementValidator.RegisterPlayer(player)
    CombatValidator.RegisterPlayer(player)
    RemoteSanitizer.RegisterPlayer(player)
    BanListSyncRemote:FireClient(player, ModerationManager.GetBansList())
end)

Players.PlayerRemoving:Connect(function(player)
    MovementValidator.UnregisterPlayer(player)
    CombatValidator.UnregisterPlayer(player)
    RemoteSanitizer.UnregisterPlayer(player)
    lastFloodAlertTimes[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    MovementValidator.RegisterPlayer(player)
    CombatValidator.RegisterPlayer(player)
    RemoteSanitizer.RegisterPlayer(player)
    BanListSyncRemote:FireClient(player, ModerationManager.GetBansList())
end

-- Central Physics Heartbeat Loop
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for _, player in ipairs(Players:GetPlayers()) do
        MovementValidator.ValidatePlayer(player, now, HandleViolation)
    end
end)

-- Demonstration Remotes Handler (Allows interactive testing from client GUI)
SimulateAttackRemote.OnServerEvent:Connect(function(player, attackType: string, extraData: any)
    -- Check Remote Rate Limiter
    if not RemoteSanitizer.CheckRateLimit(player) then
        local now = os.clock()
        local lastAlert = lastFloodAlertTimes[player] or 0
        -- Debounce alert: report at most once per 0.4s to prevent console log flooding
        if (now - lastAlert) >= 0.4 then
            lastFloodAlertTimes[player] = now
            local state = MovementValidator.GetState(player)
            local currentStrikes = state and state.Strikes or 0
            local newStrikes = currentStrikes + 2
            if state then state.Strikes = newStrikes end
            HandleViolation(player, "Remote Event Flooding (Token bucket exhausted - dropped)", newStrikes, "RATE_LIMITED")
        end
        return
    end

    if attackType == "TEST_COMBAT_HITBOX" then
        -- Client claims they hit a dummy or part
        local dummyPart = Workspace:FindFirstChild("TestDummyPart", true) :: BasePart?
        if not dummyPart then
            -- Fallback create a test target part
            dummyPart = Instance.new("Part")
            dummyPart.Name = "TestDummyPart"
            dummyPart.Size = Vector3.new(4, 4, 4)
            dummyPart.Position = Vector3.new(0, 10, 100) -- Far away
            dummyPart.Anchored = true
            dummyPart.Parent = Workspace
        end

        local claimedPosition = extraData and extraData.Position or Vector3.new(0, 10, 100)
        local result = CombatValidator.ValidateHit(player, dummyPart, claimedPosition)

        if not result.IsValid then
            local state = MovementValidator.GetState(player)
            local currentStrikes = state and state.Strikes or 1
            local newStrikes = currentStrikes + result.StrikePenalty
            if state then state.Strikes = newStrikes end
            HandleViolation(player, "Combat: " .. result.Reason, newStrikes, "DAMAGE_BLOCKED")
        else
            SecurityAlertRemote:FireClient(player, {
                Reason = "Combat check passed (Clean Hit)",
                Strikes = 0,
                Action = "PERMIT",
                Timestamp = os.clock()
            })
        end
    end
end)

ResetStrikesRemote.OnServerEvent:Connect(function(player)
    local state = MovementValidator.GetState(player)
    if state then
        state.Strikes = 0
        state.AirborneDuration = 0
        SecurityAlertRemote:FireClient(player, {
            Reason = "Strikes manually reset by tester",
            Strikes = 0,
            Action = "CLEARED",
            Timestamp = os.clock()
        })
    end
end)

-- Admin Moderation Remotes
AdminBanRemote.OnServerEvent:Connect(function(player, targetName: string, duration: string, reason: string)
    if not ModerationManager.IsAdmin(player) then
        SecurityAlertRemote:FireClient(player, {
            Reason = "Permission Denied: Administrator role required.",
            Strikes = 0,
            Action = "DENIED",
            Timestamp = os.clock()
        })
        return
    end

    local success, msg, record = ModerationManager.ExecuteBan(player, targetName, duration, reason)
    if success and record then
        BanListSyncRemote:FireAllClients(ModerationManager.GetBansList())
        SecurityAlertRemote:FireClient(player, {
            Reason = string.format("Ban %s issued on %s (%s). Webhook dispatched.", record.BanId, record.TargetName, record.Duration),
            Strikes = 0,
            Action = "BAN_ISSUED",
            Timestamp = os.clock()
        })
    else
        SecurityAlertRemote:FireClient(player, {
            Reason = msg or "Failed to execute ban.",
            Strikes = 0,
            Action = "ERROR",
            Timestamp = os.clock()
        })
    end
end)

AdminRevokeRemote.OnServerEvent:Connect(function(player, banId: string)
    if not ModerationManager.IsAdmin(player) then return end

    local success, msg = ModerationManager.RevokeBan(player, banId)
    if success then
        BanListSyncRemote:FireAllClients(ModerationManager.GetBansList())
        SecurityAlertRemote:FireClient(player, {
            Reason = string.format("Ban %s revoked.", banId),
            Strikes = 0,
            Action = "BAN_REVOKED",
            Timestamp = os.clock()
        })
    end
end)

print("🛡️ [AntiCheat Suite] Authoritative Security & Moderation Engine successfully started.")
