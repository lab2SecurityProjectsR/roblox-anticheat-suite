--!strict
--[=[
    EnvironmentSetup.luau
    Author: JV (lab2 / lab2SecurityProjectsR)
    Automatically provisions a polished demonstration arena in Workspace.
    Ensures a solid Baseplate, SpawnLocation, NoClip test wall, and Combat dummy exist
    so testers never spawn in the void or suffer accidental falls.
    Copyright (c) 2026 JV. All rights reserved.
]=]

local Workspace = game:GetService("Workspace")

local EnvironmentSetup = {}

function EnvironmentSetup.Init()
    local existingArena = Workspace:FindFirstChild("AntiCheatDemoArena")
    if existingArena then
        return existingArena
    end

    local arena = Instance.new("Folder")
    arena.Name = "AntiCheatDemoArena"
    arena.Parent = Workspace

    -- 1. Solid Ground / Baseplate
    local floor = Instance.new("Part")
    floor.Name = "BaseFloor"
    floor.Size = Vector3.new(500, 4, 500)
    floor.Position = Vector3.new(0, -2, 0)
    floor.Anchored = true
    floor.CanCollide = true
    floor.Material = Enum.Material.SmoothPlastic
    floor.Color = Color3.fromRGB(28, 33, 44)
    floor.TopSurface = Enum.SurfaceType.Smooth
    floor.BottomSurface = Enum.SurfaceType.Smooth
    floor.Parent = arena

    -- Subtle grid visual texture
    local gridTexture = Instance.new("Texture")
    gridTexture.Name = "GridTexture"
    gridTexture.Texture = "rbxassetid://6372755229"
    gridTexture.Face = Enum.NormalId.Top
    gridTexture.StudsPerTileU = 8
    gridTexture.StudsPerTileV = 8
    gridTexture.Transparency = 0.85
    gridTexture.Parent = floor

    -- 2. Spawn Pad
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "DemoSpawn"
    spawn.Size = Vector3.new(16, 1, 16)
    spawn.Position = Vector3.new(0, 0.5, 0)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = Color3.fromRGB(45, 55, 75)
    spawn.Material = Enum.Material.SmoothPlastic
    spawn.TopSurface = Enum.SurfaceType.Smooth
    spawn.Parent = arena

    -- 3. NoClip Obstacle Wall
    local wall = Instance.new("Part")
    wall.Name = "NoClipTestWall"
    wall.Size = Vector3.new(24, 14, 3)
    wall.Position = Vector3.new(0, 7, 24)
    wall.Anchored = true
    wall.CanCollide = true
    wall.Material = Enum.Material.Neon
    wall.Color = Color3.fromRGB(230, 57, 70)
    wall.Parent = arena

    local wallGui = Instance.new("BillboardGui")
    wallGui.Name = "WallLabel"
    wallGui.Size = UDim2.new(0, 240, 0, 60)
    wallGui.StudsOffset = Vector3.new(0, 9, 0)
    wallGui.AlwaysOnTop = true
    wallGui.MaxDistance = 80
    wallGui.Parent = wall

    local wallText = Instance.new("TextLabel")
    wallText.Size = UDim2.new(1, 0, 1, 0)
    wallText.BackgroundTransparency = 1
    wallText.Font = Enum.Font.GothamBold
    wallText.Text = "🧱 NOCLIP TEST WALL\nPress 'Simulate NoClip' to test"
    wallText.TextColor3 = Color3.fromRGB(255, 230, 230)
    wallText.TextSize = 14
    wallText.Parent = wallGui

    -- 4. Combat Dummy Target (Used by CombatValidator)
    local dummy = Instance.new("Part")
    dummy.Name = "TestDummyPart"
    dummy.Size = Vector3.new(4, 7, 4)
    dummy.Position = Vector3.new(0, 3.5, 55)
    dummy.Anchored = true
    dummy.CanCollide = true
    dummy.Material = Enum.Material.Neon
    dummy.Color = Color3.fromRGB(244, 162, 97)
    dummy.Parent = arena

    local dummyGui = Instance.new("BillboardGui")
    dummyGui.Name = "DummyLabel"
    dummyGui.Size = UDim2.new(0, 260, 0, 60)
    dummyGui.StudsOffset = Vector3.new(0, 5.5, 0)
    dummyGui.AlwaysOnTop = true
    dummyGui.MaxDistance = 90
    dummyGui.Parent = dummy

    local dummyText = Instance.new("TextLabel")
    dummyText.Size = UDim2.new(1, 0, 1, 0)
    dummyText.BackgroundTransparency = 1
    dummyText.Font = Enum.Font.GothamBold
    dummyText.Text = "🎯 COMBAT TARGET DUMMY\nValidates Reach & Line of Sight"
    dummyText.TextColor3 = Color3.fromRGB(255, 245, 220)
    dummyText.TextSize = 14
    dummyText.Parent = dummyGui

    -- 5. Perimeter Safety Barriers (Keep tester inside the arena)
    local barrierHeight = 12
    local barrierDist = 240
    local barrierConfigs = {
        { Size = Vector3.new(500, barrierHeight, 2), Pos = Vector3.new(0, barrierHeight / 2, barrierDist) },
        { Size = Vector3.new(500, barrierHeight, 2), Pos = Vector3.new(0, barrierHeight / 2, -barrierDist) },
        { Size = Vector3.new(2, barrierHeight, 500), Pos = Vector3.new(barrierDist, barrierHeight / 2, 0) },
        { Size = Vector3.new(2, barrierHeight, 500), Pos = Vector3.new(-barrierDist, barrierHeight / 2, 0) },
    }

    for i, cfg in ipairs(barrierConfigs) do
        local b = Instance.new("Part")
        b.Name = "PerimeterBarrier_" .. i
        b.Size = cfg.Size
        b.Position = cfg.Pos
        b.Anchored = true
        b.CanCollide = true
        b.Transparency = 0.95
        b.Parent = arena
    end

    return arena
end

return EnvironmentSetup
