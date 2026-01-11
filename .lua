-- Exploit Script for Roblox: Fly Feature with Custom Menu
-- Made by Kevin

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flySpeed = 50  -- Default fly speed
local isFlying = false
local flyVelocity = Instance.new("BodyVelocity")
flyVelocity.Name = "FlyVelocity"
flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
flyVelocity.Velocity = Vector3.new(0, 0, 0)

-- Create the GUI Menu
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.Name = "FlyMenuGui"

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 150)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.Text = "Fly Menu - Made by Kevin"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Parent = mainFrame

local flyToggleButton = Instance.new("TextButton")
flyToggleButton.Size = UDim2.new(0, 180, 0, 30)
flyToggleButton.Position = UDim2.new(0.5, -90, 0, 40)
flyToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
flyToggleButton.Text = "Toggle Fly (Off)"
flyToggleButton.Parent = mainFrame
flyToggleButton.MouseButton1Click:Connect(function()
    isFlying = not isFlying
    if isFlying then
        flyToggleButton.Text = "Toggle Fly (On)"
        flyVelocity.Parent = rootPart
    else
        flyToggleButton.Text = "Toggle Fly (Off)"
        flyVelocity.Parent = nil
    end
end)

local speedSlider = Instance.new("TextBox")
speedSlider.Size = UDim2.new(0, 180, 0, 30)
speedSlider.Position = UDim2.new(0.5, -90, 0, 80)
speedSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
speedSlider.Text = "Enter Speed (e.g., 50)"
speedSlider.Parent = mainFrame
speedSlider.FocusLost:Connect(function()
    local input = tonumber(speedSlider.Text)
    if input then
        flySpeed = input
    end
end)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 50, 0, 20)
minimizeButton.Position = UDim2.new(0, 150, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
minimizeButton.Text = "-"
minimizeButton.Parent = mainFrame
minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Size = UDim2.new(0, 200, 0, 0)  -- Minimize
end)

local restoreButton = Instance.new("TextButton")
restoreButton.Size = UDim2.new(0, 50, 0, 20)
restoreButton.Position = UDim2.new(0, 150, 0, 5)
restoreButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
restoreButton.Text = "+"
restoreButton.Parent = screenGui  -- Add to screenGui for easy access
restoreButton.Visible = false
restoreButton.MouseButton1Click:Connect(function()
    mainFrame.Size = UDim2.new(0, 200, 0, 150)  -- Restore
    restoreButton.Visible = false
end)

minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Size = UDim2.new(0, 200, 0, 0)
    restoreButton.Visible = true
end)

-- Flying Logic
game:GetService("RunService").RenderStepped:Connect(function()
    if isFlying and rootPart then
        local moveDirection = Vector3.new(
            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) and -flySpeed or 0) +
            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) and flySpeed or 0),
            0,
            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) and -flySpeed or 0) +
            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) and flySpeed or 0)
        )
        
        moveDirection = (character.PrimaryPart.CFrame * CFrame.new(moveDirection.X, 0, moveDirection.Z)).LookVector * flySpeed
        
        flyVelocity.Velocity = Vector3.new(moveDirection.X, 
            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) and flySpeed or 
            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) and -flySpeed or 0)), 
            moveDirection.Z)
        
        flyVelocity.Parent = rootPart
    end
end)

print("Fly script loaded and ready - Made by Kevin")
