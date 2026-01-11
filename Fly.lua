-- Universal Fly Script for Roblox
-- GitHub: https://github.com/theylvspd059-creator/Fly-script
-- Version: 2.0
-- Controls: F to toggle, WASD to move, Space/CTRL for up/down, E/Q for speed

-- ============================================
-- MAIN FLY SCRIPT (Copy all of this into your executor)
-- ============================================

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Fly Settings
local FlyEnabled = false
local FlySpeed = 50
local MaxSpeed = 200
local MinSpeed = 1
local Direction = Vector3.new(0, 0, 0)
local Smoothness = 0.5

-- Keybinds (Change these if you want)
local Keys = {
    Toggle = Enum.KeyCode.F,
    Forward = Enum.KeyCode.W,
    Backward = Enum.KeyCode.S,
    Left = Enum.KeyCode.A,
    Right = Enum.KeyCode.D,
    Up = Enum.KeyCode.Space,
    Down = Enum.KeyCode.LeftControl,
    IncreaseSpeed = Enum.KeyCode.E,
    DecreaseSpeed = Enum.KeyCode.Q
}

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyGUI"
ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 120)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 30)
StatusLabel.Position = UDim2.new(0, 5, 0, 5)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Fly: OFF"
StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 16
StatusLabel.Parent = MainFrame

-- Speed Label
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -10, 0, 25)
SpeedLabel.Position = UDim2.new(0, 5, 0, 35)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed: " .. FlySpeed
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 14
SpeedLabel.Parent = MainFrame

-- Controls Label
local ControlsLabel = Instance.new("TextLabel")
ControlsLabel.Size = UDim2.new(1, -10, 0, 60)
ControlsLabel.Position = UDim2.new(0, 5, 0, 60)
ControlsLabel.BackgroundTransparency = 1
ControlsLabel.Text = "F: Toggle\nWASD: Move\nSpace/CTRL: Up/Down\nE/Q: Speed"
ControlsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ControlsLabel.Font = Enum.Font.Gotham
ControlsLabel.TextSize = 12
ControlsLabel.TextXAlignment = Enum.TextXAlignment.Left
ControlsLabel.TextYAlignment = Enum.TextYAlignment.Top
ControlsLabel.Parent = MainFrame

-- Update GUI
local function UpdateGUI()
    StatusLabel.Text = "Fly: " .. (FlyEnabled and "ON" or "OFF")
    StatusLabel.TextColor3 = FlyEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    SpeedLabel.Text = "Speed: " .. FlySpeed
end

-- Toggle Fly
local function ToggleFly()
    FlyEnabled = not FlyEnabled
    
    if FlyEnabled then
        -- Save original states
        if not Humanoid:GetAttribute("OriginalWalkSpeed") then
            Humanoid:SetAttribute("OriginalWalkSpeed", Humanoid.WalkSpeed)
            Humanoid:SetAttribute("OriginalJumpPower", Humanoid.JumpPower)
        end
        
        -- Enable flying
        Humanoid.PlatformStand = true
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
        
        -- Notification
        game.StarterGui:SetCore("SendNotification", {
            Title = "Fly Enabled",
            Text = "Press F to toggle\nWASD to move\nSpace/CTRL for up/down\nE/Q to adjust speed",
            Duration = 5,
            Icon = "rbxassetid://4483345998"
        })
        
        print("✅ Fly: ON | Speed: " .. FlySpeed)
    else
        -- Disable flying
        Humanoid.PlatformStand = false
        
        -- Restore original states
        local originalWalkSpeed = Humanoid:GetAttribute("OriginalWalkSpeed") or 16
        local originalJumpPower = Humanoid:GetAttribute("OriginalJumpPower") or 50
        Humanoid.WalkSpeed = originalWalkSpeed
        Humanoid.JumpPower = originalJumpPower
        
        -- Reset velocity
        if HumanoidRootPart then
            HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        print("❌ Fly: OFF")
    end
    
    UpdateGUI()
end

-- Adjust Speed
local function AdjustSpeed(amount)
    FlySpeed = math.clamp(FlySpeed + amount, MinSpeed, MaxSpeed)
    UpdateGUI()
    print("Speed set to: " .. FlySpeed)
end

-- Handle Input
local function HandleInput(input, state)
    if input.KeyCode == Keys.Toggle then
        ToggleFly()
        return
    end
    
    if input.KeyCode == Keys.IncreaseSpeed then
        AdjustSpeed(10)
        return
    elseif input.KeyCode == Keys.DecreaseSpeed then
        AdjustSpeed(-10)
        return
    end
    
    if FlyEnabled then
        local change = state and 1 or -1
        
        if input.KeyCode == Keys.Forward then
            Direction = Direction + Vector3.new(0, 0, -change)
        elseif input.KeyCode == Keys.Backward then
            Direction = Direction + Vector3.new(0, 0, change)
        elseif input.KeyCode == Keys.Left then
            Direction = Direction + Vector3.new(-change, 0, 0)
        elseif input.KeyCode == Keys.Right then
            Direction = Direction + Vector3.new(change, 0, 0)
        elseif input.KeyCode == Keys.Up then
            Direction = Direction + Vector3.new(0, change, 0)
        elseif input.KeyCode == Keys.Down then
            Direction = Direction + Vector3.new(0, -change, 0)
        end
    end
end

-- Input Connections
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        HandleInput(input, true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        HandleInput(input, false)
    end
end)

-- Main Fly Loop
local FlyConnection
FlyConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if not FlyEnabled or not HumanoidRootPart or not Humanoid then return end
    
    local Camera = Workspace.CurrentCamera
    if not Camera then return end
    
    -- Calculate movement direction
    local moveDirection = Vector3.new(0, 0, 0)
    
    if Direction.Magnitude > 0 then
        local flatDirection = Vector3.new(Direction.X, 0, Direction.Z)
        if flatDirection.Magnitude > 0 then
            flatDirection = flatDirection.Unit
            
            -- Convert to camera space
            local cameraCF = Camera.CFrame
            local rightVector = cameraCF.RightVector
            local forwardVector = Vector3.new(cameraCF.LookVector.X, 0, cameraCF.LookVector.Z).Unit
            
            moveDirection = moveDirection + (forwardVector * flatDirection.Z)
            moveDirection = moveDirection + (rightVector * flatDirection.X)
        end
        
        -- Add vertical movement
        moveDirection = moveDirection + Vector3.new(0, Direction.Y, 0)
    end
    
    -- Apply speed and smooth movement
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * FlySpeed
    else
        -- Hover mode - counteract gravity
        moveDirection = Vector3.new(0, Workspace.Gravity * deltaTime * 0.1, 0)
    end
    
    -- Apply velocity
    HumanoidRootPart.Velocity = Vector3.new(
        moveDirection.X,
        moveDirection.Y,
        moveDirection.Z
    )
    
    -- Keep character upright
    if moveDirection.Magnitude > 0 then
        local lookDirection = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
        if lookDirection.Magnitude > 0 then
            HumanoidRootPart.CFrame = CFrame.lookAt(
                HumanoidRootPart.Position,
                HumanoidRootPart.Position + lookDirection.Unit
            )
        end
    end
end)

-- Handle Character Changes
LocalPlayer.CharacterAdded:Connect(function(newChar)
    repeat 
        RunService.Heartbeat:Wait() 
    until newChar:FindFirstChild("Humanoid") and newChar:FindFirstChild("HumanoidRootPart")
    
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    if FlyEnabled then
        -- Re-enable fly after respawn
        wait(0.5)
        if FlyEnabled then
            ToggleFly()
            wait(0.1)
            ToggleFly()
        end
    end
end)

-- Cleanup function
local function Cleanup()
    FlyEnabled = false
    if FlyConnection then
        FlyConnection:Disconnect()
    end
    if ScreenGui then
        ScreenGui:Destroy()
    end
    if Humanoid then
        Humanoid.PlatformStand = false
    end
    print("Fly script cleaned up")
end

-- Make cleanup available globally
getgenv().CleanupFly = Cleanup

-- Initial GUI update
UpdateGUI()

print("=================================")
print("🚀 Universal Fly Script Loaded!")
print("✅ Press F to toggle fly")
print("✅ WASD + Space/CTRL to move")
print("✅ E/Q to adjust speed")
print("✅ Current Speed: " .. FlySpeed)
print("=================================")

-- Chat commands for extra control
LocalPlayer.Chatted:Connect(function(message)
    local msg = message:lower()
    
    if msg:sub(1, 9) == "flyspeed " then
        local speed = tonumber(msg:sub(10))
        if speed then
            FlySpeed = math.clamp(speed, MinSpeed, MaxSpeed)
            UpdateGUI()
            print("Speed set to: " .. FlySpeed)
        end
    elseif msg == "flygui" then
        MainFrame.Visible = not MainFrame.Visible
        print("GUI " .. (MainFrame.Visible and "shown" or "hidden"))
    elseif msg == "flyhelp" then
        print([[
Fly Commands:
flyspeed [number] - Set speed (1-200)
flygui - Toggle GUI
flyhelp - Show this help
        ]])
    end
end)
