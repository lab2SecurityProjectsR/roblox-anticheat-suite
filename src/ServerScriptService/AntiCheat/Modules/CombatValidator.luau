--!strict
--[=[
    CombatValidator.luau
    Authoritative server-side hit, line-of-sight, angle cone, and hitbox expander validator.
]=]

local Workspace = game:GetService("Workspace")

local CombatValidator = {}
CombatValidator.__index = CombatValidator

local lastShotTimestamps: { [Player]: number } = {}
local combatRaycastParams = RaycastParams.new()
combatRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
combatRaycastParams.IgnoreWater = true

function CombatValidator.Init(config)
    CombatValidator.Config = config
end

function CombatValidator.RegisterPlayer(player: Player)
    lastShotTimestamps[player] = 0
end

function CombatValidator.UnregisterPlayer(player: Player)
    lastShotTimestamps[player] = nil
end

type HitCheckResult = {
    IsValid: boolean,
    Reason: string,
    StrikePenalty: number,
}

function CombatValidator.ValidateHit(
    attacker: Player,
    targetPart: BasePart,
    claimedHitPosition: Vector3
): HitCheckResult
    local now = os.clock()
    local config = CombatValidator.Config.Combat

    local attackerChar = attacker.Character
    if not attackerChar then
        return { IsValid = false, Reason = "Attacker character missing", StrikePenalty = 0 }
    end

    local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
    local attackerHead = attackerChar:FindFirstChild("Head") :: BasePart?
    if not attackerRoot or not attackerHead then
        return { IsValid = false, Reason = "Attacker body parts missing", StrikePenalty = 0 }
    end

    ----------------------------------------------------------------------
    -- 1. ATTACK RATE LIMIT / FAST FIRE CHECK
    ----------------------------------------------------------------------
    local lastShot = lastShotTimestamps[attacker] or 0
    local fireDelta = now - lastShot
    if fireDelta < (config.MinFireInterval - 0.02) then
        return {
            IsValid = false,
            Reason = string.format("Rapid Fire / Rate-Limit Bypass (%.3fs interval)", fireDelta),
            StrikePenalty = 2,
        }
    end
    lastShotTimestamps[attacker] = now

    ----------------------------------------------------------------------
    -- 2. MAXIMUM DISTANCE CHECK
    ----------------------------------------------------------------------
    local distance = (claimedHitPosition - attackerHead.Position).Magnitude
    if distance > config.MaxWeaponRange then
        return {
            IsValid = false,
            Reason = string.format("Out of range hit (Distance: %.1f studs, Max: %.1f)", distance, config.MaxWeaponRange),
            StrikePenalty = 2,
        }
    end

    ----------------------------------------------------------------------
    -- 3. HITBOX EXPANDER / BOUNDING BOX SANITY CHECK
    ----------------------------------------------------------------------
    -- Validate that claimedHitPosition is close to the canonical server-side part
    local targetCenter = targetPart.Position
    local targetSize = targetPart.Size
    local maxAllowedOffset = (targetSize.Magnitude / 2) + config.MaxHitboxPadding

    local offsetFromTarget = (claimedHitPosition - targetCenter).Magnitude
    if offsetFromTarget > maxAllowedOffset then
        return {
            IsValid = false,
            Reason = string.format("Hitbox Expander detected (Offset: %.1f studs, Allowed: %.1f)", offsetFromTarget, maxAllowedOffset),
            StrikePenalty = 3,
        }
    end

    ----------------------------------------------------------------------
    -- 4. LINE OF SIGHT (LoS) CHECK (WALLBANG PREVENTION)
    ----------------------------------------------------------------------
    if config.RequireLineOfSight then
        local targetChar = targetPart.Parent
        combatRaycastParams.FilterDescendantsInstances = { attackerChar, targetChar }

        local origin = attackerHead.Position
        local direction = (claimedHitPosition - origin)
        local losResult = Workspace:Raycast(origin, direction, combatRaycastParams)

        if losResult and losResult.Instance and losResult.Instance.CanCollide then
            return {
                IsValid = false,
                Reason = string.format("Wallbang / Obstruction bypass (Blocked by '%s')", losResult.Instance.Name),
                StrikePenalty = 2,
            }
        end
    end

    ----------------------------------------------------------------------
    -- 5. SILENT AIM / ANGLE CONE CHECK
    ----------------------------------------------------------------------
    local lookVector = attackerRoot.CFrame.LookVector
    local shotDirection = (claimedHitPosition - attackerRoot.Position).Unit
    local dotProduct = math.clamp(lookVector:Dot(shotDirection), -1, 1)
    local angleDegrees = math.deg(math.acos(dotProduct))

    if angleDegrees > config.MaxAngleConeDegrees then
        return {
            IsValid = false,
            Reason = string.format("Silent Aim / Impossible Shot Angle (Angle: %.1f°, Max: %.1f°)", angleDegrees, config.MaxAngleConeDegrees),
            StrikePenalty = 3,
        }
    end

    return { IsValid = true, Reason = "Clean Hit", StrikePenalty = 0 }
end

return CombatValidator
