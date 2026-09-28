---
name: roblox-anticheat
description: >-
  Expert-level knowledge base and development workflow for creating server-authoritative,
  zero-lag, high-performance anti-cheat systems in Roblox using Luau. Covers physics validation,
  combat integrity, remote sanitization, telemetry, and exploit defense across all Roblox game genres.
---

# Roblox Anti-Cheat Engineering Specification & Expert Skill

This guide defines the engineering standards, architecture, algorithms, and defense mechanisms required to build enterprise-grade, server-authoritative anti-cheat solutions for Roblox experiences.

---

## 1. Core Threat Model & Engine Realities

### 1.1 The Golden Rule: Server Authority
1. **Client is fully compromised:** Any code running on `StarterPlayerScripts`, `CharacterScripts`, or local instances can be paused, manipulated, hooked, or completely removed by modern memory injectors and Luau executors (e.g. via `hookmetamethod`, `getrawmetatable`, `hookfunction`, `setupvaluetable`).
2. **Never trust client state:**
   - Never let the client dictate its health, money, inventory, weapon damage, cooldowns, or position authority.
   - Client scripts should only act as visual renderers and input transmitters.
3. **Network Ownership Nuance:**
   - Roblox replicates character physics from client to server because the character's root part has `NetworkOwnership` set to the client (to eliminate local input latency).
   - The server must mathematically validate the replicated `CFrame` and `AssemblyLinearVelocity` stream against physical constraints.

### 1.2 Performance & Memory Constraints
- **Frame Budget:** Anti-cheat server loops must run within **< 1.5ms per frame** across 50–100 players.
- **Garbage Collection (GC):** Avoid allocating temporary tables, closures, or vectors inside hot loops (`RunService.Heartbeat`, `Stepped`). Pre-allocate state tables and reuse buffers.
- **Math Optimizations:**
  - Avoid `(v1 - v2).Magnitude` in rapid distance thresholds; use squared distance comparisons (`dx*dx + dy*dy + dz*dz <= maxDist*maxDist`) to bypass costly square root calculations.
  - Cache `RaycastParams` instances; do not call `RaycastParams.new()` inside per-frame character loops.

---

## 2. Mathematical Detection Algorithms

### 2.1 Movement & Physics Validation

#### Speed & Teleport Check
- **Formula:**
  $$\text{MaxDist} = (\text{WalkSpeed} \times \Delta t) + \text{PingMargin} + \text{JumpDisplacement}$$
  $$\text{ObservedDist} = \sqrt{(x_2 - x_1)^2 + (z_2 - z_1)^2}$$
- **Horizontal vs Vertical Separation:** Never calculate combined 3D distance for speed checks because falling or launching creates huge vertical velocities. Always split calculations into Horizontal ($X/Z$) and Vertical ($Y$).
- **Lag Compensation (Ping Tolerance):**
  - Compute dynamic buffer: $\text{Buffer} = \min(\text{Player:GetNetworkPing()} \times 1.2 \times \text{WalkSpeed}, \text{MaxAllowedBuffer})$.
- **Handling False Positives:**
  - Ignore/adjust checks when `Humanoid:GetState()` is in `PlatformStanding`, `Ragdoll`, or seated in a `VehicleSeat`.
  - Use a "Rubberband / Rollback" buffer: store the last 5 confirmed valid positions and reset the character's `HumanoidRootPart.CFrame` to the last valid position instead of immediate kicks.

#### Anti-Fly & Hover Check
- **Detection vector:** Exploiters modify linear velocity or lock their $Y$ coordinate in mid-air.
- **Validation logic:**
  1. Check if the player is in `Enum.HumanoidStateType.Freefall`.
  2. If the player is airborne for more than $T_{\text{max\_jump}}$ (typically 1.2 to 1.8 seconds depending on `JumpHeight` / `JumpPower`), cast a downward raycast (`workspace:Raycast`) to measure distance to the nearest solid ground.
  3. If no ground is detected within jumping distance and the vertical delta $\Delta Y \approx 0$ (hovering) or $\Delta Y > 0$ without upward impulse forces, increment the fly violation counter.

#### Anti-NoClip Check
- **Detection vector:** Disabling character part collisions (`CanCollide = false`) locally.
- **Validation logic:**
  - Cast a ray from `LastValidPosition` to `CurrentPosition`.
  - Configure `RaycastParams` to whitelist or include only `workspace.Map` / geometry and ignore characters, accessories, and debris.
  - If raycast detects an intersection with an obstruction that has `CanCollide == true`, reject movement and rollback.

---

### 2.2 Combat & Hit Validation

#### Anti-Hitbox Expansion
- **Threat:** Exploiters scale the opponent's `HumanoidRootPart.Size` to $50\times50\times50$ studs locally, hitting targets across maps.
- **Server-Side Validation:**
  1. **Maximum Range Check:** Validate $(P_{\text{attacker}} - P_{\text{target}}).\text{Magnitude} \le \text{WeaponMaxRange} + \text{PingTolerance}$.
  2. **Line of Sight (LoS):** Raycast from attacker's head or barrel to target's torso. Ensure no static walls or obstacles block the shot.
  3. **Bounding Box Sanity:** Validate that the hit point lies within the server's canonical target bounding box (plus a 2.5 stud latency padding).

#### Anti-Silent Aim & Impossible Angles
- **Threat:** Exploiter faces north but bullets shoot 90° east toward an enemy.
- **Server-Side Check:**
  - Calculate angle between attacker's `LookVector` and direction vector to target:
    $$\cos(\theta) = \frac{\vec{V}_{\text{look}} \cdot (\vec{P}_{\text{target}} - \vec{P}_{\text{attacker}})}{\|\vec{P}_{\text{target}} - \vec{P}_{\text{attacker}}\|}$$
  - If $\theta > \text{MaxAllowedConeAngle}$, reject damage event.

#### Fire-Rate & Ammo Enforcement
- Maintain a server-side timestamp table: `LastShotTime[player] = os.clock()`.
- If `os.clock() - LastShotTime[player] < WeaponCooldown - 0.03` (grace margin), drop hit.
- Server tracks current magazine and reserves. Client requests a "Reload"; server waits for duration before resetting ammo.

---

### 2.3 RemoteEvent Sanitization & Rate-Limiting

#### Sanitization Rules
- **Type Checking:** Strict validation of every argument passed:
  ```luau
  if typeof(targetId) ~= "string" or typeof(amount) ~= "number" then
      return
  end
  ```
- **Value Bounds:**
  - Verify numeric arguments are not `NaN`, `math.huge`, negative (for deposits/buys), or outside permissible range.
- **Call Frequency (Token Bucket / Rate Limiter):**
  - Limit client remote calls (e.g., maximum 20 requests per second per player across non-physics remotes).
  - Automatically drop and flag players spamming remotes to crash the server or overwhelm memory.

---

## 3. Game Genre Adaptation Matrix

| Genre | Primary Threat Vectors | Priority Protections | Recommended Action |
| :--- | :--- | :--- | :--- |
| **Shooter / FPS** | Hitbox expansion, silent aim, wallbangs, rapid fire | Server raycasting, angle cone, shot timestamps | Reject hit + Log strike |
| **Simulator / Tycoon** | Remote spam, auto-collect teleport, instant rebirth | TouchTransmitter validation, rate-limiter, proximity checks | Rollback + Remote drop |
| **Obby / Platformer** | Fly, noclip, high jump, checkpoint skipping | Checkpoint sequence check, vertical raycast, speed validation | Soft rollback to checkpoint |
| **RPG / Fighting** | Cooldown bypassing, stamina/mana manipulation, infinite dodge | Server state machine, cooldown tracker, hit confirm | State reset + Damage cancel |

---

## 4. Strike System & Action Protocol

Never instantly ban on a single violation to prevent lag-induced player loss. Use a progressive penalty model:

1. **Strike 1–3 (Minor / Suspected Lag):**
   - Silent correction / Rubberband (reposition to last valid location).
   - Drop the invalid action (drop shot, deny purchase).
2. **Strike 4–6 (Repeated Infraccion):**
   - Telemetry logged to internal database / Discord staff channel.
   - Force character reload or temporary action lock (0.5s freeze).
3. **Strike 7+ (Definite Exploit):**
   - Kick with clean error message: `Player:Kick("Connection anomaly detected [SEC-104]. Please check your network stability.")`.
   - Optional permanent ban record saved to `DataStoreService`.

---

## 5. Development & Testing Workflow

When implementing an anti-cheat system for a client:
1. **Analyze Client Gameplay:** Identify core mechanics (dashes, vehicles, custom weapons, checkpoints).
2. **Configure Thresholds:** Set parameters with at least a 20–30% tolerance margin for bad connections (up to 300ms ping).
3. **Provide a Demonstration Test Place:** Deliver a controlled place with an exploit simulation menu so the client can verify detections in real time.
4. **Deliver Clean Architecture:** Ensure all checks are isolated into independent, toggleable Luau modules.
