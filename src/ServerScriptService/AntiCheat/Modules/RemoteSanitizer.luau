--!strict
--[=[
    RemoteSanitizer.luau
    Protects RemoteEvents and RemoteFunctions from spam attacks, NaN injections,
    payload tampering, and server resource exhaustion.
]=]

local RemoteSanitizer = {}
RemoteSanitizer.__index = RemoteSanitizer

type CallBucket = {
    Tokens: number,
    LastRefill: number,
}

local clientBuckets: { [Player]: CallBucket } = {}

function RemoteSanitizer.Init(config)
    RemoteSanitizer.Config = config
end

function RemoteSanitizer.RegisterPlayer(player: Player)
    clientBuckets[player] = {
        Tokens = RemoteSanitizer.Config.Remotes.MaxCallsPerSecond,
        LastRefill = os.clock(),
    }
end

function RemoteSanitizer.UnregisterPlayer(player: Player)
    clientBuckets[player] = nil
end

function RemoteSanitizer.CheckRateLimit(player: Player): boolean
    local bucket = clientBuckets[player]
    if not bucket then return true end

    local now = os.clock()
    local maxTokens = RemoteSanitizer.Config.Remotes.MaxCallsPerSecond
    local timePassed = now - bucket.LastRefill

    -- Refill tokens linearly
    bucket.Tokens = math.min(maxTokens, bucket.Tokens + (timePassed * maxTokens))
    bucket.LastRefill = now

    if bucket.Tokens >= 1 then
        bucket.Tokens -= 1
        return true
    else
        return false -- Rate limit exceeded
    end
end

-- Helper: validate number is finite, not NaN, not infinite
function RemoteSanitizer.IsValidNumber(value: any, min: number?, max: number?): boolean
    if typeof(value) ~= "number" then return false end
    if value ~= value then return false end -- NaN check
    if value == math.huge or value == -math.huge then return false end
    if min and value < min then return false end
    if max and value > max then return false end
    return true
end

-- Helper: validate string length and sanitize
function RemoteSanitizer.IsValidString(value: any, maxLength: number?): boolean
    if typeof(value) ~= "string" then return false end
    local maxLen = maxLength or 256
    if string.len(value) > maxLen then return false end
    return true
end

return RemoteSanitizer
