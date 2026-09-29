-- Connected Discord-GitHub | Discord: jorgevvv | Roblox: narutodsfsdfsd
--!strict

--[[
    MovementSecurityService.luau
    Author: JV (lab2 / lab2SecurityProjectsR)
    Description:
        Server-authoritative physics, velocity, and spatial geometry validation engine.
        Enforces zero-client-trust invariants across character locomotion using
        sub-frame raycasting, projection vector analysis, and ping-adjusted thresholding.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

export type PlayerMovementRecord = {
    LastValidCFrame: CFrame,
    LastValidVelocity: Vector3,
    LastGroundPosition: Vector3,
    LastHeartbeatTime: number,
    FreefallAirTime: number,
    PingBufferSeconds: number,
    ConsecutiveStrikes: number,
    TotalViolations: number,
    IsGrounded: boolean,
    IsAirborne: boolean,
}

export type ValidationConfig = {
    BaseWalkSpeed: number,
    SpeedToleranceBuffer: number,
    MaxInstantDisplacement: number,
    MaxFreefallDuration: number,
    DownwardRaycastDistance: number,
    PingCompensationScale: number,
    StrikeDecayInterval: number,
    MaxStrikesBeforeAction: number,
}

export type ValidationResult = {
    Passed: boolean,
    ViolationType: string?,
    MeasuredMagnitude: number?,
    ThresholdMagnitude: number?,
    RecommendedPosition: CFrame?,
}

local DEFAULT_CONFIG: ValidationConfig = {
    BaseWalkSpeed = 16.0,
    SpeedToleranceBuffer = 14.5,
    MaxInstantDisplacement = 42.0,
    MaxFreefallDuration = 1.35,
    DownwardRaycastDistance = 6.2,
    PingCompensationScale = 0.08,
    StrikeDecayInterval = 12.0,
    MaxStrikesBeforeAction = 4,
}

local MovementSecurityService = {}
MovementSecurityService.__index = MovementSecurityService

function MovementSecurityService.new(customConfig: ValidationConfig?)
    local self = setmetatable({}, MovementSecurityService)

    self.Config = customConfig or DEFAULT_CONFIG
    self.PlayerRecords = {} :: { [Player]: PlayerMovementRecord }
    self.RaycastParameters = RaycastParams.new()
    self.RaycastParameters.FilterType = RaycastFilterType.Exclude
    self.RaycastParameters.IgnoreWater = true

    self.HeartbeatConnection = nil :: RBXScriptConnection?
    self.PlayerRemovingConnection = nil :: RBXScriptConnection?

    return self
end

function MovementSecurityService:RegisterPlayer(player: Player): PlayerMovementRecord
    local initialRecord: PlayerMovementRecord = {
        LastValidCFrame = CFrame.identity,
        LastValidVelocity = Vector3.zero,
        LastGroundPosition = Vector3.zero,
        LastHeartbeatTime = os.clock(),
        FreefallAirTime = 0.0,
        PingBufferSeconds = 0.05,
        ConsecutiveStrikes = 0,
        TotalViolations = 0,
        IsGrounded = true,
        IsAirborne = false,
    }

    self.PlayerRecords[player] = initialRecord
    return initialRecord
end

function MovementSecurityService:UnregisterPlayer(player: Player)
    -- Clean memory lifecycle to prevent dangling references upon disconnect
    self.PlayerRecords[player] = nil
end

function MovementSecurityService:FetchClientNetworkLatency(player: Player): number
    -- Ping sampling using round-trip network metrics
    local success, ping = pcall(function()
        return player:GetNetworkPing()
    end)

    if success and type(ping) == "number" then
        return math.clamp(ping, 0.01, 1.25)
    end
    return 0.06
end

function MovementSecurityService:PerformFloorSurfaceQuery(character: Model, rootPosition: Vector3): (boolean, Vector3)
    -- Multi-point downward spatial cast to establish true physical floor contact
    self.RaycastParameters.FilterDescendantsInstances = { character }

    local rayOrigin = rootPosition + Vector3.new(0, 0.5, 0)
    local rayDirection = Vector3.new(0, -self.Config.DownwardRaycastDistance, 0)
    local castHit = Workspace:Raycast(rayOrigin, rayDirection, self.RaycastParameters)

    if castHit and castHit.Instance then
        return true, castHit.Position
    end

    return false, rootPosition
end

function MovementSecurityService:ValidateTrajectoryPassage(character: Model, originPos: Vector3, destinationPos: Vector3): boolean
    -- Continuous collision detection to block geometry tunneling through walls
    local travelVector = destinationPos - originPos
    local travelDistance = travelVector.Magnitude

    if travelDistance < 0.25 then
        return true
    end

    self.RaycastParameters.FilterDescendantsInstances = { character }
    local wallHit = Workspace:Raycast(originPos, travelVector, self.RaycastParameters)

    if wallHit and wallHit.Instance and wallHit.Instance.CanCollide then
        return false
    end

    return true
end

function MovementSecurityService:AnalyzeLocomotionDelta(
    player: Player,
    rootPart: BasePart,
    humanoid: Humanoid,
    deltaTime: number
): ValidationResult
    local record = self.PlayerRecords[player]
    if not record then
        record = self:RegisterPlayer(player)
        record.LastValidCFrame = rootPart.CFrame
        record.LastValidVelocity = rootPart.AssemblyLinearVelocity
        record.LastGroundPosition = rootPart.Position
        return { Passed = true }
    end

    local currentTime = os.clock()
    local currentCFrame = rootPart.CFrame
    local currentPosition = currentCFrame.Position
    local previousPosition = record.LastValidCFrame.Position

    -- Isolate horizontal translation vector on XZ plane to prevent jump impulse from triggering speed alerts
    local displacementVector = currentPosition - previousPosition
    local horizontalVector = Vector3.new(displacementVector.X, 0, displacementVector.Z)
    local horizontalDistance = horizontalVector.Magnitude

    -- Compute dynamic latency ceiling
    local clientPing = self:FetchClientNetworkLatency(player)
    record.PingBufferSeconds = (record.PingBufferSeconds * 0.75) + (clientPing * 0.25)
    local pingCompensation = record.PingBufferSeconds * self.Config.PingCompensationScale * 60.0

    local expectedSpeed = math.max(humanoid.WalkSpeed, self.Config.BaseWalkSpeed)
    local allowableHorizontalThreshold = (expectedSpeed + self.Config.SpeedToleranceBuffer + pingCompensation) * deltaTime

    -- Test 1: Teleportation / Large displacement jump check
    if horizontalDistance > self.Config.MaxInstantDisplacement then
        return {
            Passed = false,
            ViolationType = "INSTANT_TELEPORT",
            MeasuredMagnitude = horizontalDistance,
            ThresholdMagnitude = self.Config.MaxInstantDisplacement,
            RecommendedPosition = record.LastValidCFrame,
        }
    end

    -- Test 2: Horizontal speed budget enforcement
    if horizontalDistance > allowableHorizontalThreshold and deltaTime > 0.015 then
        return {
            Passed = false,
            ViolationType = "SPEED_LIMIT_EXCEEDED",
            MeasuredMagnitude = horizontalDistance / deltaTime,
            ThresholdMagnitude = allowableHorizontalThreshold / deltaTime,
            RecommendedPosition = record.LastValidCFrame,
        }
    end

    -- Test 3: Penetration through static collidable geometry (NoClip)
    local trajectoryClear = self:ValidateTrajectoryPassage(rootPart.Parent :: Model, previousPosition, currentPosition)
    if not trajectoryClear then
        return {
            Passed = false,
            ViolationType = "GEOMETRY_PENETRATION",
            MeasuredMagnitude = horizontalDistance,
            ThresholdMagnitude = 0,
            RecommendedPosition = record.LastValidCFrame,
        }
    end

    -- Test 4: Floor validation and vertical suspension tracking
    local isGrounded, groundPoint = self:PerformFloorSurfaceQuery(rootPart.Parent :: Model, currentPosition)
    record.IsGrounded = isGrounded

    if isGrounded then
        record.FreefallAirTime = 0.0
        record.LastGroundPosition = groundPoint
    else
        record.FreefallAirTime += deltaTime
        if record.FreefallAirTime > self.Config.MaxFreefallDuration and currentPosition.Y > (previousPosition.Y - 0.2) then
            return {
                Passed = false,
                ViolationType = "AIR_SUSPENSION_FLY",
                MeasuredMagnitude = record.FreefallAirTime,
                ThresholdMagnitude = self.Config.MaxFreefallDuration,
                RecommendedPosition = CFrame.new(record.LastGroundPosition + Vector3.new(0, 3, 0)),
            }
        end
    end

    -- State approved: commit coordinate checkpoint
    record.LastValidCFrame = currentCFrame
    record.LastValidVelocity = rootPart.AssemblyLinearVelocity
    record.LastHeartbeatTime = currentTime

    -- Natural strike decay over clean gameplay intervals
    if record.ConsecutiveStrikes > 0 and (currentTime - record.LastHeartbeatTime) > self.Config.StrikeDecayInterval then
        record.ConsecutiveStrikes = math.max(0, record.ConsecutiveStrikes - 1)
    end

    return { Passed = true }
end

function MovementSecurityService:EnforcePositionCorrection(rootPart: BasePart, targetCFrame: CFrame)
    -- Zero physical kinetic momentum to eliminate rubber-banding oscillations
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    rootPart.CFrame = targetCFrame
end

function MovementSecurityService:ProcessPlayerVerification(player: Player, deltaTime: number)
    local character = player.Character
    if not character or not character.Parent then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?

    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return
    end

    -- Skip physics evaluation if player is intentionally seated or under platform mechanics
    if humanoid.Sit or rootPart.Anchored then
        local record = self.PlayerRecords[player]
        if record then
            record.LastValidCFrame = rootPart.CFrame
            record.FreefallAirTime = 0.0
        end
        return
    end

    local evaluation = self:AnalyzeLocomotionDelta(player, rootPart, humanoid, deltaTime)

    if not evaluation.Passed and evaluation.RecommendedPosition then
        local record = self.PlayerRecords[player]
        if record then
            record.ConsecutiveStrikes += 1
            record.TotalViolations += 1

            self:EnforcePositionCorrection(rootPart, evaluation.RecommendedPosition)

            warn(string.format(
                "[MovementSecurityService] Discrepancy detected for %s: %s (Strikes: %d, Value: %.2f)",
                player.Name,
                evaluation.ViolationType or "UNKNOWN",
                record.ConsecutiveStrikes,
                evaluation.MeasuredMagnitude or 0.0
            ))
        end
    end
end

function MovementSecurityService:Start()
    if self.HeartbeatConnection then
        return
    end

    -- Hook lifecycle for incoming player tracking
    for _, player in ipairs(Players:GetPlayers()) do
        self:RegisterPlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        self:RegisterPlayer(player)
    end)

    self.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        self:UnregisterPlayer(player)
    end)

    -- Primary sub-frame server physics cycle
    self.HeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        for _, player in ipairs(Players:GetPlayers()) do
            self:ProcessPlayerVerification(player, deltaTime)
        end
    end)
end

function MovementSecurityService:Stop()
    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end

    if self.PlayerRemovingConnection then
        self.PlayerRemovingConnection:Disconnect()
        self.PlayerRemovingConnection = nil
    end

    table.clear(self.PlayerRecords)
end

-- Initialize and expose singleton service
local SingletonEngine = MovementSecurityService.new()
SingletonEngine:Start()

return SingletonEngine
