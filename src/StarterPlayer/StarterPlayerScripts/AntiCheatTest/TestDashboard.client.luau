--!strict
--[=[
    TestDashboard.client.luau
    Author: JV (lab2 / lab2SecurityProjectsR)
    Aegis Security & Staff Moderation HUD.
    Features:
      1. Exploit Interceptor Suite (Speed, Teleport, Fly, NoClip, Combat, Remote Flood)
      2. Staff Moderation & Ban Management Panel with Ban Registry & Revocation
      3. Live Discord Webhook Log Dispatcher
      4. Draggable window, Minimizer, Cyber-Glassmorphic aesthetics
    Copyright (c) 2026 JV. All rights reserved.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("AntiCheatRemotes") :: Folder
local SecurityAlertRemote = remotesFolder:WaitForChild("SecurityAlertRemote") :: RemoteEvent
local SimulateAttackRemote = remotesFolder:WaitForChild("SimulateAttackRemote") :: RemoteEvent
local ResetStrikesRemote = remotesFolder:WaitForChild("ResetStrikesRemote") :: RemoteEvent
local AdminBanRemote = remotesFolder:WaitForChild("AdminBanRemote") :: RemoteEvent
local AdminRevokeRemote = remotesFolder:WaitForChild("AdminRevokeRemote") :: RemoteEvent
local BanListSyncRemote = remotesFolder:WaitForChild("BanListSyncRemote") :: RemoteEvent

--------------------------------------------------------------------------------
-- SCREEN GUI ROOT
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiCheatAegisGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- MAIN GLASSMORPHIC WINDOW
--------------------------------------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 430, 0, 640)
mainFrame.Position = UDim2.new(0, 24, 0.5, -320)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Name = "MainStroke"
mainStroke.Color = Color3.fromRGB(48, 64, 94)
mainStroke.Thickness = 1.4
mainStroke.Parent = mainFrame

local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(56, 189, 248)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(99, 102, 241)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(168, 85, 247)),
})
strokeGradient.Rotation = 45
strokeGradient.Parent = mainStroke

--------------------------------------------------------------------------------
-- DRAGGABLE HEADER
--------------------------------------------------------------------------------
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0, 50)
headerFrame.BackgroundColor3 = Color3.fromRGB(18, 23, 36)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = headerFrame

local headerMask = Instance.new("Frame")
headerMask.Size = UDim2.new(1, 0, 0, 14)
headerMask.Position = UDim2.new(0, 0, 1, -14)
headerMask.BackgroundColor3 = Color3.fromRGB(18, 23, 36)
headerMask.BorderSizePixel = 0
headerMask.Parent = headerFrame

local headerIcon = Instance.new("TextLabel")
headerIcon.Size = UDim2.new(0, 32, 0, 32)
headerIcon.Position = UDim2.new(0, 14, 0, 9)
headerIcon.BackgroundTransparency = 1
headerIcon.Font = Enum.Font.GothamBold
headerIcon.Text = "🛡️"
headerIcon.TextSize = 20
headerIcon.Parent = headerFrame

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0, 220, 0, 20)
headerTitle.Position = UDim2.new(0, 48, 0, 7)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "AEGIS SECURITY & STAFF"
headerTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
headerTitle.TextSize = 14
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = headerFrame

local headerSubtitle = Instance.new("TextLabel")
headerSubtitle.Size = UDim2.new(0, 240, 0, 16)
headerSubtitle.Position = UDim2.new(0, 48, 0, 27)
headerSubtitle.BackgroundTransparency = 1
headerSubtitle.Font = Enum.Font.GothamMedium
headerSubtitle.Text = "Anti-Cheat Suite & Moderation Panel"
headerSubtitle.TextColor3 = Color3.fromRGB(148, 163, 184)
headerSubtitle.TextSize = 10
headerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
headerSubtitle.Parent = headerFrame

-- Live Active Pill Badge
local statusBadge = Instance.new("Frame")
statusBadge.Size = UDim2.new(0, 78, 0, 22)
statusBadge.Position = UDim2.new(1, -122, 0, 14)
statusBadge.BackgroundColor3 = Color3.fromRGB(16, 37, 30)
statusBadge.BorderSizePixel = 0
statusBadge.Parent = headerFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusBadge

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(34, 197, 94)
statusStroke.Thickness = 1
statusStroke.Parent = statusBadge

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 8, 0.5, -3)
statusDot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
statusDot.BorderSizePixel = 0
statusDot.Parent = statusBadge

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -18, 1, 0)
statusText.Position = UDim2.new(0, 18, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.GothamBold
statusText.Text = "ONLINE"
statusText.TextColor3 = Color3.fromRGB(74, 222, 128)
statusText.TextSize = 9
statusText.Parent = statusBadge

-- Minimize Toggle Button
local isMinimized = false
local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 26, 0, 26)
collapseBtn.Position = UDim2.new(1, -36, 0, 12)
collapseBtn.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.Text = "—"
collapseBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
collapseBtn.TextSize = 13
collapseBtn.AutoButtonColor = false
collapseBtn.Parent = headerFrame

local collapseCorner = Instance.new("UICorner")
collapseCorner.CornerRadius = UDim.new(0, 6)
collapseCorner.Parent = collapseBtn

--------------------------------------------------------------------------------
-- DRAG SYSTEM
--------------------------------------------------------------------------------
local isDragging = false
local dragStartPos: Vector3? = nil
local frameStartPos: UDim2? = nil

headerFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        frameStartPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and dragStartPos and frameStartPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        mainFrame.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end
end)

--------------------------------------------------------------------------------
-- TAB SWITCHER (Exploit Interceptors vs Staff Moderation)
--------------------------------------------------------------------------------
local tabNav = Instance.new("Frame")
tabNav.Name = "TabNav"
tabNav.Size = UDim2.new(1, -24, 0, 32)
tabNav.Position = UDim2.new(0, 12, 0, 56)
tabNav.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
tabNav.BorderSizePixel = 0
tabNav.Parent = mainFrame

local tabNavCorner = Instance.new("UICorner")
tabNavCorner.CornerRadius = UDim.new(0, 8)
tabNavCorner.Parent = tabNav

local tabNavStroke = Instance.new("UIStroke")
tabNavStroke.Color = Color3.fromRGB(36, 45, 66)
tabNavStroke.Thickness = 1
tabNavStroke.Parent = tabNav

local tab1Btn = Instance.new("TextButton")
tab1Btn.Name = "Tab1Btn"
tab1Btn.Size = UDim2.new(0.5, -2, 1, -4)
tab1Btn.Position = UDim2.new(0, 2, 0, 2)
tab1Btn.BackgroundColor3 = Color3.fromRGB(32, 42, 64)
tab1Btn.Font = Enum.Font.GothamBold
tab1Btn.Text = "🛡️ Exploit Tests"
tab1Btn.TextColor3 = Color3.fromRGB(241, 245, 249)
tab1Btn.TextSize = 11
tab1Btn.AutoButtonColor = false
tab1Btn.Parent = tabNav

local tab1Corner = Instance.new("UICorner")
tab1Corner.CornerRadius = UDim.new(0, 6)
tab1Corner.Parent = tab1Btn

local tab2Btn = Instance.new("TextButton")
tab2Btn.Name = "Tab2Btn"
tab2Btn.Size = UDim2.new(0.5, -2, 1, -4)
tab2Btn.Position = UDim2.new(0.5, 0, 0, 2)
tab2Btn.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
tab2Btn.Font = Enum.Font.GothamBold
tab2Btn.Text = "🔨 Staff Ban Panel"
tab2Btn.TextColor3 = Color3.fromRGB(148, 163, 184)
tab2Btn.TextSize = 11
tab2Btn.AutoButtonColor = false
tab2Btn.Parent = tabNav

local tab2Corner = Instance.new("UICorner")
tab2Corner.CornerRadius = UDim.new(0, 6)
tab2Corner.Parent = tab2Btn

--------------------------------------------------------------------------------
-- VIEWS CONTAINER
--------------------------------------------------------------------------------
local viewsContainer = Instance.new("Frame")
viewsContainer.Name = "ViewsContainer"
viewsContainer.Size = UDim2.new(1, 0, 1, -94)
viewsContainer.Position = UDim2.new(0, 0, 0, 94)
viewsContainer.BackgroundTransparency = 1
viewsContainer.Parent = mainFrame

collapseBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetHeight = isMinimized and 50 or 640
    collapseBtn.Text = isMinimized and "＋" or "—"
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 430, 0, targetHeight)
    }):Play()
end)

-- TAB 1: EXPLOIT SUITE VIEW
local exploitView = Instance.new("Frame")
exploitView.Name = "ExploitView"
exploitView.Size = UDim2.new(1, 0, 1, 0)
exploitView.BackgroundTransparency = 1
exploitView.Visible = true
exploitView.Parent = viewsContainer

-- TAB 2: STAFF MODERATION VIEW
local moderationView = Instance.new("Frame")
moderationView.Name = "ModerationView"
moderationView.Size = UDim2.new(1, 0, 1, 0)
moderationView.BackgroundTransparency = 1
moderationView.Visible = false
moderationView.Parent = viewsContainer

local function SwitchTab(tabIndex: number)
    if tabIndex == 1 then
        exploitView.Visible = true
        moderationView.Visible = false
        TweenService:Create(tab1Btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(32, 42, 64), TextColor3 = Color3.fromRGB(241, 245, 249) }):Play()
        TweenService:Create(tab2Btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(16, 20, 30), TextColor3 = Color3.fromRGB(148, 163, 184) }):Play()
    else
        exploitView.Visible = false
        moderationView.Visible = true
        TweenService:Create(tab1Btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(16, 20, 30), TextColor3 = Color3.fromRGB(148, 163, 184) }):Play()
        TweenService:Create(tab2Btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(32, 42, 64), TextColor3 = Color3.fromRGB(241, 245, 249) }):Play()
    end
end

tab1Btn.MouseButton1Click:Connect(function() SwitchTab(1) end)
tab2Btn.MouseButton1Click:Connect(function() SwitchTab(2) end)

--------------------------------------------------------------------------------
-- [TAB 1] METRICS CARDS
--------------------------------------------------------------------------------
local metricsFrame = Instance.new("Frame")
metricsFrame.Size = UDim2.new(1, -24, 0, 60)
metricsFrame.Position = UDim2.new(0, 12, 0, 4)
metricsFrame.BackgroundTransparency = 1
metricsFrame.Parent = exploitView

local metricsLayout = Instance.new("UIListLayout")
metricsLayout.FillDirection = Enum.FillDirection.Horizontal
metricsLayout.Padding = UDim.new(0, 8)
metricsLayout.Parent = metricsFrame

local function CreateMetricCard(parent: Instance, title: string, initialValue: string, valueColor: Color3)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.315, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(18, 23, 34)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(36, 45, 66)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local cardTitle = Instance.new("TextLabel")
    cardTitle.Size = UDim2.new(1, -12, 0, 14)
    cardTitle.Position = UDim2.new(0, 8, 0, 5)
    cardTitle.BackgroundTransparency = 1
    cardTitle.Font = Enum.Font.GothamMedium
    cardTitle.Text = title
    cardTitle.TextColor3 = Color3.fromRGB(100, 116, 139)
    cardTitle.TextSize = 9
    cardTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardTitle.Parent = card

    local cardVal = Instance.new("TextLabel")
    cardVal.Name = "ValueLabel"
    cardVal.Size = UDim2.new(1, -12, 0, 20)
    cardVal.Position = UDim2.new(0, 8, 0, 20)
    cardVal.BackgroundTransparency = 1
    cardVal.Font = Enum.Font.GothamBold
    cardVal.Text = initialValue
    cardVal.TextColor3 = valueColor
    cardVal.TextSize = 13
    cardVal.TextXAlignment = Enum.TextXAlignment.Left
    cardVal.Parent = card

    return card, cardVal
end

local pingCard, pingLabel = CreateMetricCard(metricsFrame, "LATENCY", "2 ms", Color3.fromRGB(56, 189, 248))
local strikesCard, strikesLabel = CreateMetricCard(metricsFrame, "STRIKES", "0 / 8", Color3.fromRGB(74, 222, 128))
local statusCard, defenseLabel = CreateMetricCard(metricsFrame, "DEFENSE", "SECURE", Color3.fromRGB(34, 197, 94))

-- Animated Strike Bar
local strikeBarBg = Instance.new("Frame")
strikeBarBg.Size = UDim2.new(1, -16, 0, 4)
strikeBarBg.Position = UDim2.new(0, 8, 0, 46)
strikeBarBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
strikeBarBg.BorderSizePixel = 0
strikeBarBg.Parent = strikesCard

local strikeBarBgCorner = Instance.new("UICorner")
strikeBarBgCorner.CornerRadius = UDim.new(1, 0)
strikeBarBgCorner.Parent = strikeBarBg

local strikeBarFill = Instance.new("Frame")
strikeBarFill.Size = UDim2.new(0, 0, 1, 0)
strikeBarFill.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
strikeBarFill.BorderSizePixel = 0
strikeBarFill.Parent = strikeBarBg

local strikeBarFillCorner = Instance.new("UICorner")
strikeBarFillCorner.CornerRadius = UDim.new(1, 0)
strikeBarFillCorner.Parent = strikeBarFill

--------------------------------------------------------------------------------
-- [TAB 1] SIMULATION BUTTONS
--------------------------------------------------------------------------------
local section1Label = Instance.new("TextLabel")
section1Label.Size = UDim2.new(1, -24, 0, 16)
section1Label.Position = UDim2.new(0, 14, 0, 72)
section1Label.BackgroundTransparency = 1
section1Label.Font = Enum.Font.GothamBold
section1Label.Text = "⚡ MOVEMENT & VELOCITY CHECKS"
section1Label.TextColor3 = Color3.fromRGB(148, 163, 184)
section1Label.TextSize = 10
section1Label.TextXAlignment = Enum.TextXAlignment.Left
section1Label.Parent = exploitView

local moveGrid = Instance.new("Frame")
moveGrid.Size = UDim2.new(1, -24, 0, 78)
moveGrid.Position = UDim2.new(0, 12, 0, 90)
moveGrid.BackgroundTransparency = 1
moveGrid.Parent = exploitView

local moveGridLayout = Instance.new("UIGridLayout")
moveGridLayout.CellSize = UDim2.new(0.488, 0, 0, 35)
moveGridLayout.CellPadding = UDim2.new(0, 9, 0, 8)
moveGridLayout.Parent = moveGrid

local section2Label = Instance.new("TextLabel")
section2Label.Size = UDim2.new(1, -24, 0, 16)
section2Label.Position = UDim2.new(0, 14, 0, 176)
section2Label.BackgroundTransparency = 1
section2Label.Font = Enum.Font.GothamBold
section2Label.Text = "🎯 COMBAT & NETWORK INTEGRITY"
section2Label.TextColor3 = Color3.fromRGB(148, 163, 184)
section2Label.TextSize = 10
section2Label.TextXAlignment = Enum.TextXAlignment.Left
section2Label.Parent = exploitView

local combatGrid = Instance.new("Frame")
combatGrid.Size = UDim2.new(1, -24, 0, 38)
combatGrid.Position = UDim2.new(0, 12, 0, 194)
combatGrid.BackgroundTransparency = 1
combatGrid.Parent = exploitView

local combatGridLayout = Instance.new("UIGridLayout")
combatGridLayout.CellSize = UDim2.new(0.488, 0, 0, 35)
combatGridLayout.CellPadding = UDim2.new(0, 9, 0, 8)
combatGridLayout.Parent = combatGrid

local function CreateModernButton(parent: Instance, title: string, subtitle: string, accentColor: Color3, onClick: () -> ())
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(19, 25, 38)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = parent

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(38, 48, 70)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    local accentStrip = Instance.new("Frame")
    accentStrip.Size = UDim2.new(0, 3, 1, 0)
    accentStrip.BackgroundColor3 = accentColor
    accentStrip.BorderSizePixel = 0
    accentStrip.Parent = btn

    local stripCorner = Instance.new("UICorner")
    stripCorner.CornerRadius = UDim.new(0, 4)
    stripCorner.Parent = accentStrip

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -16, 0, 16)
    titleLbl.Position = UDim2.new(0, 12, 0, 3)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(241, 245, 249)
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = btn

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -16, 0, 14)
    subLbl.Position = UDim2.new(0, 12, 0, 18)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.Text = subtitle
    subLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
    subLbl.TextSize = 9
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(28, 38, 58) }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.18), { Color = accentColor }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.22), { BackgroundColor3 = Color3.fromRGB(19, 25, 38) }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.22), { Color = Color3.fromRGB(38, 48, 70) }):Play()
    end)

    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- Reset Reputation Button
local resetBtn = Instance.new("TextButton")
resetBtn.Name = "ResetButton"
resetBtn.Size = UDim2.new(1, -24, 0, 32)
resetBtn.Position = UDim2.new(0, 12, 0, 240)
resetBtn.BackgroundColor3 = Color3.fromRGB(16, 40, 28)
resetBtn.BorderSizePixel = 0
resetBtn.AutoButtonColor = false
resetBtn.Text = ""
resetBtn.Parent = exploitView

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetBtn

local resetStroke = Instance.new("UIStroke")
resetStroke.Color = Color3.fromRGB(34, 197, 94)
resetStroke.Thickness = 1
resetStroke.Parent = resetBtn

local resetLabel = Instance.new("TextLabel")
resetLabel.Size = UDim2.new(1, 0, 1, 0)
resetLabel.BackgroundTransparency = 1
resetLabel.Font = Enum.Font.GothamBold
resetLabel.Text = "🔄 Reset Reputation & Clear Strikes"
resetLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
resetLabel.TextSize = 11
resetLabel.Parent = resetBtn

--------------------------------------------------------------------------------
-- [TAB 1] REAL-TIME TELEMETRY LOG
--------------------------------------------------------------------------------
local consoleFrame = Instance.new("Frame")
consoleFrame.Name = "ConsoleFrame"
consoleFrame.Size = UDim2.new(1, -24, 0, 260)
consoleFrame.Position = UDim2.new(0, 12, 0, 280)
consoleFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 19)
consoleFrame.BorderSizePixel = 0
consoleFrame.ClipsDescendants = true
consoleFrame.Parent = exploitView

local consoleCorner = Instance.new("UICorner")
consoleCorner.CornerRadius = UDim.new(0, 10)
consoleCorner.Parent = consoleFrame

local consoleStroke = Instance.new("UIStroke")
consoleStroke.Color = Color3.fromRGB(30, 41, 59)
consoleStroke.Thickness = 1
consoleStroke.Parent = consoleFrame

local consoleHeader = Instance.new("Frame")
consoleHeader.Size = UDim2.new(1, 0, 0, 26)
consoleHeader.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
consoleHeader.BorderSizePixel = 0
consoleHeader.Parent = consoleFrame

local consoleTitle = Instance.new("TextLabel")
consoleTitle.Size = UDim2.new(1, -70, 1, 0)
consoleTitle.Position = UDim2.new(0, 10, 0, 0)
consoleTitle.BackgroundTransparency = 1
consoleTitle.Font = Enum.Font.RobotoMono
consoleTitle.Text = ">_ LIVE TELEMETRY LOG"
consoleTitle.TextColor3 = Color3.fromRGB(100, 116, 139)
consoleTitle.TextSize = 10
consoleTitle.TextXAlignment = Enum.TextXAlignment.Left
consoleTitle.Parent = consoleHeader

local clearLogsBtn = Instance.new("TextButton")
clearLogsBtn.Size = UDim2.new(0, 48, 0, 18)
clearLogsBtn.Position = UDim2.new(1, -54, 0, 4)
clearLogsBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 46)
clearLogsBtn.Font = Enum.Font.GothamMedium
clearLogsBtn.Text = "CLEAR"
clearLogsBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
clearLogsBtn.TextSize = 9
clearLogsBtn.AutoButtonColor = true
clearLogsBtn.Parent = consoleHeader

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 4)
clearCorner.Parent = clearLogsBtn

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -12, 1, -34)
logScroll.Position = UDim2.new(0, 8, 0, 30)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 3
logScroll.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = consoleFrame

local logListLayout = Instance.new("UIListLayout")
logListLayout.Padding = UDim.new(0, 4)
logListLayout.SortOrder = Enum.SortOrder.LayoutOrder
logListLayout.Parent = logScroll

local logCount = 0

local function AppendLogEntry(action: string, message: string, color: Color3)
    logCount += 1

    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -4, 0, 20)
    entry.BackgroundTransparency = 1
    entry.LayoutOrder = logCount
    entry.Parent = logScroll

    local timestamp = os.date("%X")

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 52, 1, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Font = Enum.Font.RobotoMono
    timeLabel.Text = string.format("[%s]", timestamp)
    timeLabel.TextColor3 = Color3.fromRGB(71, 85, 105)
    timeLabel.TextSize = 9
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = entry

    local tagLabel = Instance.new("TextLabel")
    tagLabel.Size = UDim2.new(0, 80, 1, 0)
    tagLabel.Position = UDim2.new(0, 54, 0, 0)
    tagLabel.BackgroundTransparency = 1
    tagLabel.Font = Enum.Font.RobotoMono
    tagLabel.Text = string.format("[%s]", action)
    tagLabel.TextColor3 = color
    tagLabel.TextSize = 9
    tagLabel.TextXAlignment = Enum.TextXAlignment.Left
    tagLabel.Parent = entry

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -140, 1, 0)
    msgLabel.Position = UDim2.new(0, 138, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Font = Enum.Font.RobotoMono
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
    msgLabel.TextSize = 9
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = entry

    task.defer(function()
        logScroll.CanvasPosition = Vector2.new(0, 9999)
    end)
end

clearLogsBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(logScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    AppendLogEntry("SYSTEM", "Log buffer cleared.", Color3.fromRGB(56, 189, 248))
end)

AppendLogEntry("INITIALIZED", "Aegis Security Engine operational.", Color3.fromRGB(74, 222, 128))
AppendLogEntry("INFO", "Click simulation buttons to test interceptors.", Color3.fromRGB(148, 163, 184))

--------------------------------------------------------------------------------
-- [TAB 2] STAFF MODERATION SUITE IMPLEMENTATION
--------------------------------------------------------------------------------

-- Staff Metrics Row
local modMetricsFrame = Instance.new("Frame")
modMetricsFrame.Size = UDim2.new(1, -24, 0, 54)
modMetricsFrame.Position = UDim2.new(0, 12, 0, 4)
modMetricsFrame.BackgroundTransparency = 1
modMetricsFrame.Parent = moderationView

local modMetricsLayout = Instance.new("UIListLayout")
modMetricsLayout.FillDirection = Enum.FillDirection.Horizontal
modMetricsLayout.Padding = UDim.new(0, 8)
modMetricsLayout.Parent = modMetricsFrame

local roleCard, roleLabel = CreateMetricCard(modMetricsFrame, "YOUR ROLE", "ADMINISTRATOR", Color3.fromRGB(74, 222, 128))
local bansCard, bansCountLabel = CreateMetricCard(modMetricsFrame, "BANS LOGGED", "3 Active", Color3.fromRGB(248, 113, 113))
local hookCard, hookLabel = CreateMetricCard(modMetricsFrame, "WEBHOOK", "DISCORD SYNC", Color3.fromRGB(192, 132, 252))

-- Issue Ban Card Form
local banForm = Instance.new("Frame")
banForm.Name = "BanForm"
banForm.Size = UDim2.new(1, -24, 0, 186)
banForm.Position = UDim2.new(0, 12, 0, 66)
banForm.BackgroundColor3 = Color3.fromRGB(16, 21, 32)
banForm.BorderSizePixel = 0
banForm.Parent = moderationView

local formCorner = Instance.new("UICorner")
formCorner.CornerRadius = UDim.new(0, 10)
formCorner.Parent = banForm

local formStroke = Instance.new("UIStroke")
formStroke.Color = Color3.fromRGB(38, 48, 72)
formStroke.Thickness = 1
formStroke.Parent = banForm

local formTitle = Instance.new("TextLabel")
formTitle.Size = UDim2.new(1, -20, 0, 18)
formTitle.Position = UDim2.new(0, 10, 0, 8)
formTitle.BackgroundTransparency = 1
formTitle.Font = Enum.Font.GothamBold
formTitle.Text = "🔨 ISSUE DISCIPLINARY SANCTION"
formTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
formTitle.TextSize = 11
formTitle.TextXAlignment = Enum.TextXAlignment.Left
formTitle.Parent = banForm

-- Target Username Input
local targetInput = Instance.new("TextBox")
targetInput.Name = "TargetInput"
targetInput.Size = UDim2.new(1, -20, 0, 30)
targetInput.Position = UDim2.new(0, 10, 0, 30)
targetInput.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
targetInput.BorderSizePixel = 0
targetInput.Font = Enum.Font.GothamMedium
targetInput.PlaceholderText = "Target Username (e.g. ExploiterPlayer123)..."
targetInput.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
targetInput.Text = ""
targetInput.TextColor3 = Color3.fromRGB(241, 245, 249)
targetInput.TextSize = 11
targetInput.TextXAlignment = Enum.TextXAlignment.Left
targetInput.Parent = banForm

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 6)
targetCorner.Parent = targetInput

local targetPadding = Instance.new("UIPadding")
targetPadding.PaddingLeft = UDim.new(0, 8)
targetPadding.Parent = targetInput

-- Reason Input
local reasonInput = Instance.new("TextBox")
reasonInput.Name = "ReasonInput"
reasonInput.Size = UDim2.new(1, -20, 0, 30)
reasonInput.Position = UDim2.new(0, 10, 0, 66)
reasonInput.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
reasonInput.BorderSizePixel = 0
reasonInput.Font = Enum.Font.GothamMedium
reasonInput.PlaceholderText = "Infraction Reason (e.g. Speedhack / Malicious Remotes)..."
reasonInput.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
reasonInput.Text = ""
reasonInput.TextColor3 = Color3.fromRGB(241, 245, 249)
reasonInput.TextSize = 11
reasonInput.TextXAlignment = Enum.TextXAlignment.Left
reasonInput.Parent = banForm

local reasonCorner = Instance.new("UICorner")
reasonCorner.CornerRadius = UDim.new(0, 6)
reasonCorner.Parent = reasonInput

local reasonPadding = Instance.new("UIPadding")
reasonPadding.PaddingLeft = UDim.new(0, 8)
reasonPadding.Parent = reasonInput

-- Duration Selector Pills
local selectedDuration = "Permanent"
local durationRow = Instance.new("Frame")
durationRow.Size = UDim2.new(1, -20, 0, 24)
durationRow.Position = UDim2.new(0, 10, 0, 104)
durationRow.BackgroundTransparency = 1
durationRow.Parent = banForm

local durationLayout = Instance.new("UIListLayout")
durationLayout.FillDirection = Enum.FillDirection.Horizontal
durationLayout.Padding = UDim.new(0, 8)
durationLayout.Parent = durationRow

local durationButtons: { TextButton } = {}

local function CreateDurationPill(text: string)
    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0.31, 0, 1, 0)
    pill.BackgroundColor3 = (text == selectedDuration and Color3.fromRGB(38, 54, 84)) or Color3.fromRGB(12, 16, 24)
    pill.Font = Enum.Font.GothamBold
    pill.Text = text
    pill.TextColor3 = (text == selectedDuration and Color3.fromRGB(56, 189, 248)) or Color3.fromRGB(148, 163, 184)
    pill.TextSize = 10
    pill.AutoButtonColor = false
    pill.Parent = durationRow

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 6)
    pCorner.Parent = pill

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = (text == selectedDuration and Color3.fromRGB(56, 189, 248)) or Color3.fromRGB(36, 45, 66)
    pStroke.Thickness = 1
    pStroke.Parent = pill

    pill.MouseButton1Click:Connect(function()
        selectedDuration = text
        for _, btn in ipairs(durationButtons) do
            local isSel = (btn.Text == selectedDuration)
            btn.BackgroundColor3 = isSel and Color3.fromRGB(38, 54, 84) or Color3.fromRGB(12, 16, 24)
            btn.TextColor3 = isSel and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(148, 163, 184)
            local st = btn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = isSel and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(36, 45, 66) end
        end
    end)

    table.insert(durationButtons, pill)
end

CreateDurationPill("24 Hours")
CreateDurationPill("7 Days")
CreateDurationPill("Permanent")

-- Execute Ban Button
local executeBanBtn = Instance.new("TextButton")
executeBanBtn.Name = "ExecuteBanBtn"
executeBanBtn.Size = UDim2.new(1, -20, 0, 36)
executeBanBtn.Position = UDim2.new(0, 10, 0, 138)
executeBanBtn.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
executeBanBtn.BorderSizePixel = 0
executeBanBtn.AutoButtonColor = false
executeBanBtn.Font = Enum.Font.GothamBold
executeBanBtn.Text = "🔨 EXECUTE BAN & DISPATCH DISCORD WEBHOOK"
executeBanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
executeBanBtn.TextSize = 11
executeBanBtn.Parent = banForm

local execCorner = Instance.new("UICorner")
execCorner.CornerRadius = UDim.new(0, 8)
execCorner.Parent = executeBanBtn

executeBanBtn.MouseEnter:Connect(function()
    TweenService:Create(executeBanBtn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(220, 38, 38) }):Play()
end)

executeBanBtn.MouseLeave:Connect(function()
    TweenService:Create(executeBanBtn, TweenInfo.new(0.22), { BackgroundColor3 = Color3.fromRGB(185, 28, 28) }):Play()
end)

executeBanBtn.MouseButton1Click:Connect(function()
    local target = targetInput.Text
    local reason = reasonInput.Text
    if string.len(target) < 2 then
        AppendLogEntry("ADMIN", "Target username cannot be blank.", Color3.fromRGB(239, 68, 68))
        return
    end

    AppendLogEntry("ADMIN", string.format("Sending ban request: %s (%s)...", target, selectedDuration), Color3.fromRGB(250, 204, 21))
    AdminBanRemote:FireServer(target, selectedDuration, reason)

    targetInput.Text = ""
    reasonInput.Text = ""
end)

-- Active Bans Table Registry
local registryFrame = Instance.new("Frame")
registryFrame.Name = "RegistryFrame"
registryFrame.Size = UDim2.new(1, -24, 0, 276)
registryFrame.Position = UDim2.new(0, 12, 0, 260)
registryFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 19)
registryFrame.BorderSizePixel = 0
registryFrame.ClipsDescendants = true
registryFrame.Parent = moderationView

local regCorner = Instance.new("UICorner")
regCorner.CornerRadius = UDim.new(0, 10)
regCorner.Parent = registryFrame

local regStroke = Instance.new("UIStroke")
regStroke.Color = Color3.fromRGB(30, 41, 59)
regStroke.Thickness = 1
regStroke.Parent = registryFrame

local regHeader = Instance.new("Frame")
regHeader.Size = UDim2.new(1, 0, 0, 26)
regHeader.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
regHeader.BorderSizePixel = 0
regHeader.Parent = registryFrame

local regTitle = Instance.new("TextLabel")
regTitle.Size = UDim2.new(1, -20, 1, 0)
regTitle.Position = UDim2.new(0, 10, 0, 0)
regTitle.BackgroundTransparency = 1
regTitle.Font = Enum.Font.RobotoMono
regTitle.Text = "📋 ACTIVE ENFORCEMENT REGISTRY"
regTitle.TextColor3 = Color3.fromRGB(100, 116, 139)
regTitle.TextSize = 10
regTitle.TextXAlignment = Enum.TextXAlignment.Left
regTitle.Parent = regHeader

local banScroll = Instance.new("ScrollingFrame")
banScroll.Size = UDim2.new(1, -12, 1, -34)
banScroll.Position = UDim2.new(0, 8, 0, 30)
banScroll.BackgroundTransparency = 1
banScroll.BorderSizePixel = 0
banScroll.ScrollBarThickness = 3
banScroll.ScrollBarImageColor3 = Color3.fromRGB(239, 68, 68)
banScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
banScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
banScroll.Parent = registryFrame

local banListLayout = Instance.new("UIListLayout")
banListLayout.Padding = UDim.new(0, 6)
banListLayout.SortOrder = Enum.SortOrder.LayoutOrder
banListLayout.Parent = banScroll

local function RenderBanList(bans: { any })
    for _, child in ipairs(banScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local activeCount = 0
    for idx, ban in ipairs(bans) do
        if ban.Status == "ACTIVE" then activeCount += 1 end

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 48)
        card.BackgroundColor3 = (ban.Status == "ACTIVE" and Color3.fromRGB(16, 20, 30)) or Color3.fromRGB(12, 14, 20)
        card.BorderSizePixel = 0
        card.LayoutOrder = idx
        card.Parent = banScroll

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 6)
        cCorner.Parent = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color = (ban.Status == "ACTIVE" and Color3.fromRGB(45, 55, 80)) or Color3.fromRGB(24, 28, 38)
        cStroke.Thickness = 1
        cStroke.Parent = card

        -- User & Ban ID
        local userLbl = Instance.new("TextLabel")
        userLbl.Size = UDim2.new(0.65, 0, 0, 16)
        userLbl.Position = UDim2.new(0, 8, 0, 6)
        userLbl.BackgroundTransparency = 1
        userLbl.Font = Enum.Font.GothamBold
        userLbl.Text = string.format("👤 %s  [%s]", ban.TargetName, ban.BanId)
        userLbl.TextColor3 = (ban.Status == "ACTIVE" and Color3.fromRGB(241, 245, 249)) or Color3.fromRGB(100, 116, 139)
        userLbl.TextSize = 11
        userLbl.TextXAlignment = Enum.TextXAlignment.Left
        userLbl.Parent = card

        -- Reason
        local reasonLbl = Instance.new("TextLabel")
        reasonLbl.Size = UDim2.new(0.65, 0, 0, 16)
        reasonLbl.Position = UDim2.new(0, 8, 0, 24)
        reasonLbl.BackgroundTransparency = 1
        reasonLbl.Font = Enum.Font.GothamMedium
        reasonLbl.Text = string.format("Reason: %s • %s", ban.Reason, ban.Duration)
        reasonLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
        reasonLbl.TextSize = 9
        reasonLbl.TextXAlignment = Enum.TextXAlignment.Left
        reasonLbl.TextTruncate = Enum.TextTruncate.AtEnd
        reasonLbl.Parent = card

        -- Revoke / Status Button
        if ban.Status == "ACTIVE" then
            local revokeBtn = Instance.new("TextButton")
            revokeBtn.Size = UDim2.new(0, 68, 0, 24)
            revokeBtn.Position = UDim2.new(1, -76, 0.5, -12)
            revokeBtn.BackgroundColor3 = Color3.fromRGB(40, 22, 28)
            revokeBtn.Font = Enum.Font.GothamBold
            revokeBtn.Text = "REVOKE"
            revokeBtn.TextColor3 = Color3.fromRGB(248, 113, 113)
            revokeBtn.TextSize = 9
            revokeBtn.AutoButtonColor = true
            revokeBtn.Parent = card

            local revCorner = Instance.new("UICorner")
            revCorner.CornerRadius = UDim.new(0, 6)
            revCorner.Parent = revokeBtn

            local revStroke = Instance.new("UIStroke")
            revStroke.Color = Color3.fromRGB(239, 68, 68)
            revStroke.Thickness = 1
            revStroke.Parent = revokeBtn

            revokeBtn.MouseButton1Click:Connect(function()
                AdminRevokeRemote:FireServer(ban.BanId)
                AppendLogEntry("ADMIN", string.format("Revoking ban %s...", ban.BanId), Color3.fromRGB(250, 204, 21))
            end)
        else
            local revokedLbl = Instance.new("TextLabel")
            revokedLbl.Size = UDim2.new(0, 68, 0, 24)
            revokedLbl.Position = UDim2.new(1, -76, 0.5, -12)
            revokedLbl.BackgroundTransparency = 1
            revokedLbl.Font = Enum.Font.GothamBold
            revokedLbl.Text = "REVOKED"
            revokedLbl.TextColor3 = Color3.fromRGB(100, 116, 139)
            revokedLbl.TextSize = 9
            revokedLbl.Parent = card
        end
    end

    bansCountLabel.Text = string.format("%d Active", activeCount)
end

BanListSyncRemote.OnClientEvent:Connect(function(bansList)
    RenderBanList(bansList)
end)

--------------------------------------------------------------------------------
-- [TAB 1] SIMULATION TESTS CALLBACKS
--------------------------------------------------------------------------------

-- 1. Speedhack Simulation
CreateModernButton(moveGrid, "⚡ Speedhack", "WalkSpeed = 90", Color3.fromRGB(56, 189, 248), function()
    local char = localPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
    if hum then
        hum.WalkSpeed = 90
        AppendLogEntry("CLIENT", "WalkSpeed injected to 90. Move now to see server rollback!", Color3.fromRGB(56, 189, 248))
        task.delay(4, function()
            if hum then hum.WalkSpeed = 16 end
        end)
    end
end)

-- 2. Teleport Simulation
CreateModernButton(moveGrid, "🌀 Teleport", "+65 Studs Forward", Color3.fromRGB(129, 140, 248), function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if root then
        AppendLogEntry("CLIENT", "Forcing instant CFrame jump (+65 studs)...", Color3.fromRGB(129, 140, 248))
        root.CFrame = root.CFrame * CFrame.new(0, 0, -65)
    end
end)

-- 3. Fly / Hover Simulation
CreateModernButton(moveGrid, "🦅 Fly / Hover", "Anti-Gravity Suspend", Color3.fromRGB(45, 212, 191), function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
    if root and hum then
        AppendLogEntry("CLIENT", "Freezing Y axis in mid-air for 3s...", Color3.fromRGB(45, 212, 191))
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 2, 0)
        bodyVelocity.MaxForce = Vector3.new(0, 100000, 0)
        bodyVelocity.Parent = root
        task.delay(3, function()
            bodyVelocity:Destroy()
        end)
    end
end)

-- 4. NoClip Simulation
local noclipConn: RBXScriptConnection? = nil
CreateModernButton(moveGrid, "🧱 NoClip Wall", "Phase Collisions", Color3.fromRGB(251, 146, 60), function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not char or not root then return end

    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end

    AppendLogEntry("CLIENT", "NoClip active for 6s! Walk into the red barrier.", Color3.fromRGB(251, 146, 60))

    local expireTime = os.clock() + 6
    noclipConn = RunService.Stepped:Connect(function()
        if os.clock() > expireTime or not char.Parent then
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
            end
            AppendLogEntry("CLIENT", "NoClip simulation expired.", Color3.fromRGB(148, 163, 184))
            return
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    root.AssemblyLinearVelocity = root.CFrame.LookVector * 26
end)

-- 5. Hitbox Expander Simulation
CreateModernButton(combatGrid, "🎯 Hitbox Expander", "Reach & Wallbang", Color3.fromRGB(244, 114, 182), function()
    AppendLogEntry("CLIENT", "Firing combat hit claiming 55-stud offset...", Color3.fromRGB(244, 114, 182))
    SimulateAttackRemote:FireServer("TEST_COMBAT_HITBOX", {
        Position = Vector3.new(0, 0, 0)
    })
end)

-- 6. Remote Event Flooding
CreateModernButton(combatGrid, "🌊 Remote Flooding", "DoS Burst (x60)", Color3.fromRGB(192, 132, 252), function()
    AppendLogEntry("CLIENT", "Bursting 60 remote calls in 1 frame...", Color3.fromRGB(192, 132, 252))
    for _ = 1, 60 do
        SimulateAttackRemote:FireServer("PING_PACKET", {})
    end
end)

-- 7. Reset Strikes
resetBtn.MouseButton1Click:Connect(function()
    ResetStrikesRemote:FireServer()
    local char = localPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
    if hum then hum.WalkSpeed = 16 end
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    AppendLogEntry("CLIENT", "Requested reputation strike wipe from server.", Color3.fromRGB(74, 222, 128))
end)

--------------------------------------------------------------------------------
-- TELEMETRY LISTENER & DYNAMIC HUD UPDATES
--------------------------------------------------------------------------------
SecurityAlertRemote.OnClientEvent:Connect(function(data)
    local strikeRatio = math.clamp(data.Strikes / 8, 0, 1)

    strikesLabel.Text = string.format("%d / 8", data.Strikes)
    local strikeColor = Color3.fromRGB(74, 222, 128)
    if data.Strikes >= 6 then
        strikeColor = Color3.fromRGB(239, 68, 68)
        defenseLabel.Text = "CRITICAL"
        defenseLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
    elseif data.Strikes >= 3 then
        strikeColor = Color3.fromRGB(250, 204, 21)
        defenseLabel.Text = "ALERT"
        defenseLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
    else
        defenseLabel.Text = "SECURE"
        defenseLabel.TextColor3 = Color3.fromRGB(34, 197, 94)
    end
    strikesLabel.TextColor3 = strikeColor

    TweenService:Create(strikeBarFill, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(strikeRatio, 0, 1, 0),
        BackgroundColor3 = strikeColor
    }):Play()

    local tagColor = Color3.fromRGB(56, 189, 248)
    if data.Action == "ROLLBACK" then
        tagColor = Color3.fromRGB(250, 204, 21)
    elseif data.Action == "KICK" then
        tagColor = Color3.fromRGB(239, 68, 68)
    elseif data.Action == "DAMAGE_BLOCKED" then
        tagColor = Color3.fromRGB(244, 114, 182)
    elseif data.Action == "RATE_LIMITED" then
        tagColor = Color3.fromRGB(192, 132, 252)
    elseif data.Action == "BAN_ISSUED" then
        tagColor = Color3.fromRGB(239, 68, 68)
    elseif data.Action == "BAN_REVOKED" then
        tagColor = Color3.fromRGB(74, 222, 128)
    elseif data.Action == "CLEARED" then
        tagColor = Color3.fromRGB(74, 222, 128)
    end

    AppendLogEntry(data.Action, data.Reason, tagColor)

    TweenService:Create(mainStroke, TweenInfo.new(0.15), { Color = tagColor }):Play()
    task.delay(0.4, function()
        TweenService:Create(mainStroke, TweenInfo.new(0.5), { Color = Color3.fromRGB(48, 64, 94) }):Play()
    end)
end)

-- Continuous Ping Telemetry Loop
task.spawn(function()
    while true do
        local pingMs = math.floor(localPlayer:GetNetworkPing() * 1000)
        pingLabel.Text = string.format("%d ms", pingMs)
        if pingMs > 150 then
            pingLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
        elseif pingMs > 80 then
            pingLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
        else
            pingLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
        end
        task.wait(1)
    end
end)
