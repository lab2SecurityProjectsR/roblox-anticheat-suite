--!strict
--[=[
    MovementValidator.luau
    Author: JV (lab2 / lab2SecurityProjectsR)
    Authoritative server-side physics and trajectory validator.
    Prevents Speedhack, Teleport, Fly/Hover, and NoClip with zero client trust.
    Copyright (c) 2026 JV. All rights reserved.
]=]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MovementValidator = {}
MovementValidator.__index = MovementValidator

type PlayerMovementState = {
    Player: Player,
    LastValidCFrame: CFrame,
    LastValidTime: number,
    AirborneDuration: number,
    LastRollbackTime: number,
    Strikes: number,
    LastStrikeTime: number,
    IsSeated: boolean,
    SpawnImmunityUntil: number,
}

local activeStates: { [Player]: PlayerMovementState } = {}

-- Reusable RaycastParams to prevent GC allocations in per-frame loops
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

function MovementValidator.Init(config)
    MovementValidator.Config = config
end

function MovementValidator.RegisterPlayer(player: Player)
    local state: PlayerMovementState = {
        Player = player,
        LastValidCFrame = CFrame.new(0, 5, 0),
        LastValidTime = os.clock(),
        AirborneDuration = 0,
        LastRollbackTime = 0,
        Strikes = 0,
        LastStrikeTime = os.clock(),
        IsSeated = false,
        SpawnImmunityUntil = os.clock() + 2.5,
    }

    activeStates[player] = state

    local function SetupCharacter(character: Model)
        state.AirborneDuration = 0
        state.SpawnImmunityUntil = os.clock() + 2.5 -- 2.5s grace period for spawn & physics stabilization
        state.LastValidTime = os.clock()

        task.spawn(function()
            local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
            local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

            if root and humanoid then
                state.LastValidCFrame = root.CFrame
                state.LastValidTime = os.clock()
                state.AirborneDuration = 0

                humanoid.Seated:Connect(function(isSeated)
                    state.IsSeated = isSeated
                end)
            end
        end)
    end

    player.CharacterAdded:Connect(SetupCharacter)
    if player.Character then
        SetupCharacter(player.Character)
    end
end

function MovementValidator.UnregisterPlayer(player: Player)
    activeStates[player] = nil
end

function MovementValidator.GetState(player: Player): PlayerMovementState?
    return activeStates[player]
end

local function RollbackPlayer(state: PlayerMovementState, root: BasePart, reason: string)
    local now = os.clock()
    if now - state.LastRollbackTime < 0.2 then
        return
    end

    state.LastRollbackTime = now
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = state.LastValidCFrame
end

function MovementValidator.ValidatePlayer(player: Player, now: number, onViolation: (Player, string, number) -> ())
    local state = activeStates[player]
    if not state then return end

    local character = player.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
    if not root or not humanoid or humanoid.Health <= 0 then return end

    -- Grace period after spawn/respawn to avoid false positives during load
    if now < state.SpawnImmunityUntil then
        state.LastValidCFrame = root.CFrame
        state.LastValidTime = now
        state.AirborneDuration = 0
        return
    end

    -- Ignore if falling to void death below map boundaries
    if root.Position.Y < (Workspace.FallenPartsDestroyHeight + 100) then
        return
    end

    -- Skip check if the player is currently in a vehicle seat or dead
    if state.IsSeated then
        state.LastValidCFrame = root.CFrame
        state.LastValidTime = now
        return
    end

    local dt = now - state.LastValidTime
    if dt < 0.05 then
        return -- Too frequent, wait for meaningful time delta
    end

    local currentPos = root.Position
    local lastPos = state.LastValidCFrame.Position
    local totalDist3D = (currentPos - lastPos).Magnitude
    local config = MovementValidator.Config.Movement

    -- Compute network ping buffer (adaptive latency compensation)
    local ping = player:GetNetworkPing() * 1000 -- in ms
    local pingBuffer = (ping / 100) * config.PingCompensationFactor * config.BaseWalkSpeed

    ----------------------------------------------------------------------
    -- 1. HORIZONTAL SPEED & TELEPORT VALIDATION
    ----------------------------------------------------------------------
    local dx = currentPos.X - lastPos.X
    local dz = currentPos.Z - lastPos.Z
    local dy = currentPos.Y - lastPos.Y
    local horizontalDistSq = (dx * dx) + (dz * dz)
    local horizontalDist = math.sqrt(horizontalDistSq)

    local maxSpeed = (config.BaseWalkSpeed + config.SpeedTolerance) + pingBuffer
    local maxAllowedDist = maxSpeed * dt
    local maxAllowedDistSq = maxAllowedDist * maxAllowedDist

    -- Check for extreme single-frame horizontal teleport OR unnatural upward teleport
    if horizontalDist > config.MaxTeleportDistance or (dy > 30 and root.AssemblyLinearVelocity.Y < 5) then
        state.Strikes += 2
        state.LastStrikeTime = now
        RollbackPlayer(state, root, "Teleport Detected")
        onViolation(player, string.format("Teleportation (jumped %.1f studs in %.2fs)", horizontalDist, dt), state.Strikes)
        return
    end

    -- Check horizontal speed hack
    if horizontalDistSq > maxAllowedDistSq then
        state.Strikes += 1
        state.LastStrikeTime = now
        local observedSpeed = horizontalDist / dt
        RollbackPlayer(state, root, "Speedhack Detected")
        onViolation(player, string.format("Speedhack (observed: %.1f studs/s, limit: %.1f)", observedSpeed, maxSpeed), state.Strikes)
        return
    end

    ----------------------------------------------------------------------
    -- 2. ANTI-FLY & HOVER VALIDATION
    ----------------------------------------------------------------------
    local humanoidState = humanoid:GetState()
    if humanoidState == Enum.HumanoidStateType.Freefall then
        state.AirborneDuration += dt

        if state.AirborneDuration > config.MaxJumpAirTime then
            -- Raycast downward to see if they are near legitimate terrain or platforms
            raycastParams.FilterDescendantsInstances = { character }
            local downRay = Workspace:Raycast(currentPos, Vector3.new(0, -config.MinGroundRaycastDistance, 0), raycastParams)

            if not downRay then
                -- Player is floating mid-air far from ground
                local verticalVelocity = root.AssemblyLinearVelocity.Y
                -- Only flag if hovering (nearly 0 vertical velocity) or flying upward
                -- Downward freefall at normal gravity is legitimate falling, not flying
                if (verticalVelocity > -10.0 and math.abs(verticalVelocity) < 6.0) or (verticalVelocity > 15.0) then
                    state.Strikes += 1
                    state.LastStrikeTime = now
                    RollbackPlayer(state, root, "Fly/Hover Detected")
                    onViolation(player, string.format("Fly / Infinite Hover (Airborne: %.2fs)", state.AirborneDuration), state.Strikes)
                    return
                end
            end
        end
    else
        state.AirborneDuration = 0
    end

    ----------------------------------------------------------------------
    -- 3. ANTI-NOCLIP (GEOMETRIC COLLISION TRAJECTORY)
    ----------------------------------------------------------------------
    if config.NoClipEnabled and totalDist3D > 0.1 then
        raycastParams.FilterDescendantsInstances = { character }
        local hitObstacle = Workspace:Raycast(lastPos, currentPos - lastPos, raycastParams)

        if hitObstacle and hitObstacle.Instance and hitObstacle.Instance.CanCollide then
            -- Verify it is a steep obstacle/wall rather than a walkable floor slope
            if math.abs(hitObstacle.Normal.Y) < 0.7 then
                state.Strikes += 1
                state.LastStrikeTime = now
                RollbackPlayer(state, root, "NoClip Detected")
                onViolation(player, string.format("NoClip (Passed through '%s')", hitObstacle.Instance.Name), state.Strikes)
                return
            end
        end
    end

    ----------------------------------------------------------------------
    -- REPUTATION RECOVERY (STRIKE DECAY)
    ----------------------------------------------------------------------
    if state.Strikes > 0 and (now - state.LastStrikeTime) > MovementValidator.Config.StrikeDecayInterval then
        state.Strikes = math.max(0, state.Strikes - 1)
        state.LastStrikeTime = now
    end

    -- State is valid: update canonical reference
    state.LastValidCFrame = root.CFrame
    state.LastValidTime = now
end

return MovementValidator
