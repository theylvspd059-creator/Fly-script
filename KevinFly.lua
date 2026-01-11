--[[
╦ ╦╦ ╦╔═╗╦╔═╗╔╗╔╔═╗╔╦╗
║║║╠═╣╠═╝║║╣ ║║║╠═╣ ║ 
╚╩╝╩ ╩╩  ╩╚═╝╝╚╝╩ ╩ ╩ 
███████╗██╗     ██╗   ██╗███████╗██╗  ██╗███████╗████████╗███████╗███╗   ███╗
██╔════╝██║     ██║   ██║██╔════╝╚██╗██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
█████╗  ██║     ██║   ██║█████╗   ╚███╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
██╔══╝  ██║     ██║   ██║██╔══╝   ██╔██╗ ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
██║     ███████╗╚██████╔╝███████╗██╔╝ ██╗███████║   ██║   ███████╗██║ ╚═╝ ██║
╚═╝     ╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝
===============================================================================
🛠️ By Kevin | Universal Roblox Fly System | v5.0
===============================================================================
A complete, modular fly system library for Roblox exploits
Features: Universal compatibility, mobile-friendly UI, smooth physics, undetectable
===============================================================================
--]]

local FlySystem = {}
FlySystem.__index = FlySystem
FlySystem.Version = "5.0"
FlySystem.Author = "Kevin"

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

-- Device Detection
local IS_PC = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled
local IS_MOBILE = UserInputService.TouchEnabled
local IS_CONSOLE = UserInputService.GamepadEnabled
local DEVICE_TYPE = IS_PC and "PC" or IS_MOBILE and "MOBILE" or IS_CONSOLE and "CONSOLE" or "UNKNOWN"

print("╔══════════════════════════════════════════╗")
print("║  FLY SYSTEM v5.0 by Kevin               ║")
print("║  Device: " .. string.format("%-31s", DEVICE_TYPE) .. "║")
print("║  Status: Initializing...                ║")
print("╚══════════════════════════════════════════╝")

-- Default Configuration
local DEFAULT_CONFIG = {
    -- UI Settings
    parent = nil, -- Auto-detected
    themeColor = Color3.fromRGB(255, 255, 255), -- White theme
    backgroundColor = Color3.fromRGB(20, 20, 25),
    transparency = 0.15,
    size = IS_MOBILE and 280 or 250,
    position = IS_MOBILE and UDim2.new(0.02, 0, 0.02, 0) or UDim2.new(0.02, 0, 0.02, 0),
    
    -- Fly Settings
    enabled = false,
    speed = 50,
    minSpeed = 1,
    maxSpeed = 200,
    acceleration = 5,
    deceleration = 5,
    hoverStabilization = false,
    smoothMovement = true,
    cameraRelative = true,
    
    -- Physics
    useModernConstraints = true,
    antiGravity = true,
    swimStyle = true,
    
    -- Keybinds (PC)
    keybinds = {
        toggle = Enum.KeyCode.F,
        forward = Enum.KeyCode.W,
        backward = Enum.KeyCode.S,
        left = Enum.KeyCode.A,
        right = Enum.KeyCode.D,
        up = Enum.KeyCode.Space,
        down = Enum.KeyCode.LeftControl,
        speedUp = Enum.KeyCode.E,
        speedDown = Enum.KeyCode.Q,
        toggleUI = Enum.KeyCode.H,
        hideUI = Enum.KeyCode.J
    },
    
    -- Gamepad (Console)
    gamepadBinds = {
        toggle = Enum.KeyCode.ButtonR3,
        up = Enum.KeyCode.ButtonA,
        down = Enum.KeyCode.ButtonB,
        speedUp = Enum.KeyCode.ButtonR1,
        speedDown = Enum.KeyCode.ButtonL1
    },
    
    -- Mobile
    mobileControls = true,
    joystickSize = 120,
    buttonSize = 60,
    
    -- Callbacks
    onToggle = nil,
    onSpeedChange = nil,
    onUIStateChange = nil
}

-- Constructor
function FlySystem.new(config)
    config = config or {}
    local self = setmetatable({}, FlySystem)
    
    -- Merge config with defaults
    self.config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self.config[key] = config[key] or value
    end
    
    -- State management
    self.enabled = self.config.enabled
    self.speed = self.config.speed
    self.direction = Vector3.new(0, 0, 0)
    self.gamepadInput = Vector2.new(0, 0)
    self.velocity = Vector3.new(0, 0, 0)
    self.targetVelocity = Vector3.new(0, 0, 0)
    
    -- References
    self.connections = {}
    self.uiElements = {}
    self.callbacks = {
        toggle = {self.config.onToggle},
        speedChange = {self.config.onSpeedChange},
        uiState = {self.config.onUIStateChange}
    }
    
    -- Player references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
    
    -- Physics objects
    self.constraints = {}
    
    -- UI State
    self.uiHidden = false
    self.uiMinimized = false
    
    -- Initialize
    self:_getPlayerReferences()
    self:_setupUI()
    self:_setupInput()
    self:_setupPhysics()
    
    print("✅ Fly System by Kevin initialized successfully!")
    return self
end

-- Internal: Get player references with error handling
function FlySystem:_getPlayerReferences()
    self.character = self.player.Character
    if not self.character then
        self.character = self.player.CharacterAdded:Wait()
    end
    
    self.humanoid = self.character:WaitForChild("Humanoid")
    self.rootPart = self.character:WaitForChild("HumanoidRootPart")
    
    -- Character change handlers
    table.insert(self.connections, self.player.CharacterAdded:Connect(function(char)
        self.character = char
        task.wait(0.1)
        self.humanoid = char:WaitForChild("Humanoid")
        self.rootPart = char:WaitForChild("HumanoidRootPart")
        
        if self.enabled then
            task.wait(0.3)
            self:Toggle()
            task.wait(0.1)
            self:Toggle()
        end
    end))
end

-- Internal: Setup modern circular UI
function FlySystem:_setupUI()
    -- Auto-detect parent
    if not self.config.parent then
        self.config.parent = game:GetService("CoreGui") or self.player:WaitForChild("PlayerGui")
    end
    
    -- Main ScreenGui
    self.ui = Instance.new("ScreenGui")
    self.ui.Name = "KevinFlySystem"
    self.ui.Parent = self.config.parent
    self.ui.ResetOnSpawn = false
    self.ui.IgnoreGuiInset = IS_MOBILE
    
    -- Main Container (White Circular Interface)
    self.uiElements.main = Instance.new("Frame")
    local main = self.uiElements.main
    main.Size = UDim2.new(0, self.config.size, 0, self.config.size)
    main.Position = self.config.position
    main.BackgroundColor3 = self.config.themeColor
    main.BackgroundTransparency = self.config.transparency
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = self.ui
    
    -- Perfect Circle
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = main
    
    -- Glossy Effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 245, 245)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    gradient.Rotation = 45
    gradient.Parent = main
    
    -- Shadow/Glow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Parent = main
    self.uiElements.shadow = shadow
    
    -- Content Container
    self.uiElements.content = Instance.new("Frame")
    local content = self.uiElements.content
    content.Size = UDim2.new(0.9, 0, 0.9, 0)
    content.Position = UDim2.new(0.05, 0, 0.05, 0)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    -- Title (Kevin's Logo)
    self.uiElements.title = Instance.new("TextLabel")
    local title = self.uiElements.title
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "🛠️ Kevin's Fly"
    title.TextColor3 = Color3.fromRGB(30, 30, 35)
    title.Font = Enum.Font.GothamBold
    title.TextSize = IS_MOBILE and 18 or 16
    title.Parent = content
    
    -- Status Indicator
    self.uiElements.status = Instance.new("Frame")
    local status = self.uiElements.status
    status.Size = UDim2.new(1, 0, 0, 40)
    status.Position = UDim2.new(0, 0, 0, 35)
    status.BackgroundColor3 = Color3.fromRGB(220, 60, 60) -- Red when off
    status.BackgroundTransparency = 0.2
    status.Parent = content
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = status
    
    self.uiElements.statusText = Instance.new("TextLabel")
    local statusText = self.uiElements.statusText
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "FLY: OFF"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = IS_MOBILE and 16 or 14
    statusText.Parent = status
    
    -- Speed Control
    self.uiElements.speedContainer = Instance.new("Frame")
    local speedContainer = self.uiElements.speedContainer
    speedContainer.Size = UDim2.new(1, 0, 0, 60)
    speedContainer.Position = UDim2.new(0, 0, 0, 85)
    speedContainer.BackgroundTransparency = 1
    speedContainer.Parent = content
    
    -- Speed Label
    self.uiElements.speedLabel = Instance.new("TextLabel")
    local speedLabel = self.uiElements.speedLabel
    speedLabel.Size = UDim2.new(0.5, 0, 0, 20)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "SPEED: " .. self.speed
    speedLabel.TextColor3 = Color3.fromRGB(30, 30, 35)
    speedLabel.Font = Enum.Font.GothamMedium
    speedLabel.TextSize = 14
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = speedContainer
    
    -- Speed Slider
    self.uiElements.speedSlider = Instance.new("Frame")
    local speedSlider = self.uiElements.speedSlider
    speedSlider.Size = UDim2.new(1, 0, 0, 6)
    speedSlider.Position = UDim2.new(0, 0, 0, 25)
    speedSlider.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    speedSlider.BorderSizePixel = 0
    speedSlider.Parent = speedContainer
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = speedSlider
    
    -- Speed Fill
    self.uiElements.speedFill = Instance.new("Frame")
    local speedFill = self.uiElements.speedFill
    speedFill.Size = UDim2.new((self.speed - self.config.minSpeed) / (self.config.maxSpeed - self.config.minSpeed), 0, 1, 0)
    speedFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    speedFill.BorderSizePixel = 0
    speedFill.Parent = speedSlider
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = speedFill
    
    -- Speed Control Buttons
    self.uiElements.speedDown = self:_createButton("-", UDim2.new(0, 0, 0, 35), UDim2.new(0, 30, 0, 30), Color3.fromRGB(220, 60, 60))
    self.uiElements.speedDown.Parent = speedContainer
    
    self.uiElements.speedUp = self:_createButton("+", UDim2.new(1, -30, 0, 35), UDim2.new(0, 30, 0, 30), Color3.fromRGB(0, 200, 100))
    self.uiElements.speedUp.Parent = speedContainer
    
    -- Toggle Button
    self.uiElements.toggleBtn = self:_createButton("TOGGLE FLY", UDim2.new(0.5, -50, 0, 150), UDim2.new(0, 100, 0, 35), Color3.fromRGB(0, 120, 255))
    self.uiElements.toggleBtn.Parent = content
    
    -- Close Button (Top Right)
    self.uiElements.closeBtn = self:_createButton("×", UDim2.new(1, -35, 0, 5), UDim2.new(0, 30, 0, 30), Color3.fromRGB(220, 60, 60))
    self.uiElements.closeBtn.Parent = main
    
    -- Minimized Button (Red "N" circle)
    self.uiElements.minimizedBtn = Instance.new("TextButton")
    local minBtn = self.uiElements.minimizedBtn
    minBtn.Size = UDim2.new(0, 50, 0, 50)
    minBtn.Position = self.config.position
    minBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    minBtn.Text = "N"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 20
    minBtn.Visible = false
    minBtn.Parent = self.ui
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = minBtn
    
    -- Mobile Joystick
    if IS_MOBILE and self.config.mobileControls then
        self:_setupMobileControls()
    end
    
    -- Setup UI interactions
    self:_setupUIInteractions()
end

-- Internal: Create a styled button
function FlySystem:_createButton(text, position, size, color)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    -- Hover effects (PC only)
    if IS_PC then
        btn.MouseEnter:Connect(function()
            self:_tween(btn, {BackgroundTransparency = 0.1})
        end)
        btn.MouseLeave:Connect(function()
            self:_tween(btn, {BackgroundTransparency = 0})
        end)
    end
    
    return btn
end

-- Internal: Setup mobile touch controls
function FlySystem:_setupMobileControls()
    -- Mobile Controls Container
    self.uiElements.mobileControls = Instance.new("Frame")
    local mobile = self.uiElements.mobileControls
    mobile.Size = UDim2.new(1, 0, 1, 0)
    mobile.BackgroundTransparency = 1
    mobile.Parent = self.ui
    
    -- Joystick Base
    self.uiElements.joystickBase = Instance.new("Frame")
    local joystickBase = self.uiElements.joystickBase
    joystickBase.Size = UDim2.new(0, self.config.joystickSize, 0, self.config.joystickSize)
    joystickBase.Position = UDim2.new(0, 30, 1, -self.config.joystickSize - 30)
    joystickBase.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    joystickBase.BackgroundTransparency = 0.7
    joystickBase.BorderSizePixel = 0
    joystickBase.Parent = mobile
    
    local baseCorner = Instance.new("UICorner")
    baseCorner.CornerRadius = UDim.new(1, 0)
    baseCorner.Parent = joystickBase
    
    -- Joystick Handle
    self.uiElements.joystickHandle = Instance.new("Frame")
    local joystickHandle = self.uiElements.joystickHandle
    joystickHandle.Size = UDim2.new(0, 50, 0, 50)
    joystickHandle.Position = UDim2.new(0.5, -25, 0.5, -25)
    joystickHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    joystickHandle.BackgroundTransparency = 0.3
    joystickHandle.BorderSizePixel = 0
    joystickHandle.Parent = joystickBase
    
    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(1, 0)
    handleCorner.Parent = joystickHandle
    
    -- Vertical Buttons
    self.uiElements.upBtn = self:_createButton("▲", UDim2.new(1, -80, 1, -140), UDim2.new(0, 60, 0, 60), Color3.fromRGB(0, 120, 255))
    self.uiElements.upBtn.Parent = mobile
    
    self.uiElements.downBtn = self:_createButton("▼", UDim2.new(1, -80, 1, -70), UDim2.new(0, 60, 0, 60), Color3.fromRGB(0, 120, 255))
    self.uiElements.downBtn.Parent = mobile
end

-- Internal: Setup UI interactions
function FlySystem:_setupUIInteractions()
    -- Draggable Main UI
    if IS_PC then
        self.uiElements.main.Active = true
        self.uiElements.main.Draggable = true
    else
        -- Mobile drag with touch
        local dragStart, startPos
        self.uiElements.main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                dragStart = input.Position
                startPos = self.uiElements.main.Position
            end
        end)
        
        self.uiElements.main.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and dragStart then
                local delta = input.Position - dragStart
                self.uiElements.main.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        self.uiElements.main.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                dragStart = nil
            end
        end)
    end
    
    -- Button Actions
    self.uiElements.toggleBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    self.uiElements.closeBtn.MouseButton1Click:Connect(function()
        self:ToggleUI()
    end)
    
    self.uiElements.minimizedBtn.MouseButton1Click:Connect(function()
        self:ToggleUI()
    end)
    
    self.uiElements.speedDown.MouseButton1Click:Connect(function()
        self:SetSpeed(self.speed - self.config.deceleration)
    end)
    
    self.uiElements.speedUp.MouseButton1Click:Connect(function()
        self:SetSpeed(self.speed + self.config.acceleration)
    end)
    
    -- Speed Slider
    local sliding = false
    self.uiElements.speedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
        end
    end)
    
    self.uiElements.speedSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local slider = self.uiElements.speedSlider
            local relativeX = math.clamp(
                (input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X,
                0, 1
            )
            local newSpeed = math.floor(
                self.config.minSpeed + relativeX * (self.config.maxSpeed - self.config.minSpeed)
            )
            self:SetSpeed(newSpeed)
        end
    end)
    
    -- Mobile controls
    if IS_MOBILE then
        self:_setupMobileInput()
    end
end

-- Internal: Setup mobile input handling
function FlySystem:_setupMobileInput()
    local joystickActive = false
    local joystickStartPos
    
    -- Joystick
    self.uiElements.joystickBase.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = true
            joystickStartPos = input.Position
        end
    end)
    
    self.uiElements.joystickBase.InputChanged:Connect(function(input)
        if joystickActive and input.UserInputType == Enum.UserInputType.Touch then
            local base = self.uiElements.joystickBase
            local handle = self.uiElements.joystickHandle
            local maxDistance = (base.AbsoluteSize.X / 2) - 25
            
            local delta = input.Position - base.AbsolutePosition - base.AbsoluteSize / 2
            local distance = math.min(delta.Magnitude, maxDistance)
            local direction = distance > 0 and delta.Unit or Vector2.new(0, 0)
            
            -- Update handle position
            local newPos = direction * distance
            handle.Position = UDim2.new(
                0.5, newPos.X - 25,
                0.5, newPos.Y - 25
            )
            
            -- Update movement direction (invert Y for intuitive controls)
            self.direction = Vector3.new(
                direction.X,
                0,
                -direction.Y
            )
        end
    end)
    
    self.uiElements.joystickBase.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = false
            self.direction = Vector3.new(0, 0, 0)
            
            -- Reset joystick
            self:_tween(self.uiElements.joystickHandle, {
                Position = UDim2.new(0.5, -25, 0.5, -25)
            })
        end
    end)
    
    -- Mobile buttons
    local verticalActive = false
    
    self.uiElements.upBtn.InputBegan:Connect(function()
        verticalActive = true
        self.direction = Vector3.new(self.direction.X, 1, self.direction.Z)
    end)
    
    self.uiElements.downBtn.InputBegan:Connect(function()
        verticalActive = true
        self.direction = Vector3.new(self.direction.X, -1, self.direction.Z)
    end)
    
    self.uiElements.upBtn.InputEnded:Connect(function()
        if verticalActive then
            self.direction = Vector3.new(self.direction.X, 0, self.direction.Z)
        end
    end)
    
    self.uiElements.downBtn.InputEnded:Connect(function()
        if verticalActive then
            self.direction = Vector3.new(self.direction.X, 0, self.direction.Z)
        end
    end)
end

-- Internal: Setup input handling
function FlySystem:_setupInput()
    -- Keyboard Input
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            
            if key == self.config.keybinds.toggle then
                self:Toggle()
            elseif key == self.config.keybinds.toggleUI then
                self:ToggleUI()
            elseif key == self.config.keybinds.hideUI then
                self:HideUI()
            elseif key == self.config.keybinds.speedUp then
                self:SetSpeed(self.speed + self.config.acceleration)
            elseif key == self.config.keybinds.speedDown then
                self:SetSpeed(self.speed - self.config.deceleration)
            elseif self.enabled then
                -- Movement keys
                if key == self.config.keybinds.forward then
                    self.direction = self.direction + Vector3.new(0, 0, -1)
                elseif key == self.config.keybinds.backward then
                    self.direction = self.direction + Vector3.new(0, 0, 1)
                elseif key == self.config.keybinds.left then
                    self.direction = self.direction + Vector3.new(-1, 0, 0)
                elseif key == self.config.keybinds.right then
                    self.direction = self.direction + Vector3.new(1, 0, 0)
                elseif key == self.config.keybinds.up then
                    self.direction = self.direction + Vector3.new(0, 1, 0)
                elseif key == self.config.keybinds.down then
                    self.direction = self.direction + Vector3.new(0, -1, 0)
                end
            end
        elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
            -- Gamepad support
            if input.KeyCode == self.config.gamepadBinds.toggle then
                self:Toggle()
            end
        end
    end))
    
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and self.enabled then
            local key = input.KeyCode
            
            if key == self.config.keybinds.forward then
                self.direction = self.direction + Vector3.new(0, 0, 1)
            elseif key == self.config.keybinds.backward then
                self.direction = self.direction + Vector3.new(0, 0, -1)
            elseif key == self.config.keybinds.left then
                self.direction = self.direction + Vector3.new(1, 0, 0)
            elseif key == self.config.keybinds.right then
                self.direction = self.direction + Vector3.new(-1, 0, 0)
            elseif key == self.config.keybinds.up then
                self.direction = self.direction + Vector3.new(0, -1, 0)
            elseif key == self.config.keybinds.down then
                self.direction = self.direction + Vector3.new(0, 1, 0)
            end
        end
    end))
    
    -- Gamepad thumbsticks
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Gamepad1 then
            if input.KeyCode == Enum.KeyCode.Thumbstick1 then
                self.gamepadInput = Vector2.new(input.Position.X, -input.Position.Y)
                
                -- Apply deadzone
                if self.gamepadInput.Magnitude < 0.2 then
                    self.gamepadInput = Vector2.new(0, 0)
                end
                
                if self.enabled then
                    self.direction = Vector3.new(
                        self.gamepadInput.X,
                        0,
                        self.gamepadInput.Y
                    )
                end
            end
        end
    end))
end

-- Internal: Setup physics
function FlySystem:_setupPhysics()
    table.insert(self.connections, RunService.Heartbeat:Connect(function(dt)
        if not self.enabled or not self.rootPart then return end
        
        -- Get camera for direction
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        -- Calculate movement
        local moveDirection = self.direction
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            
            if self.config.cameraRelative then
                -- Camera-relative movement
                local cameraCF = camera.CFrame
                local right = cameraCF.RightVector
                local forward = Vector3.new(cameraCF.LookVector.X, 0, cameraCF.LookVector.Z).Unit
                
                local worldDirection = Vector3.new(0, 0, 0)
                worldDirection = worldDirection + (forward * moveDirection.Z)
                worldDirection = worldDirection + (right * moveDirection.X)
                worldDirection = worldDirection + Vector3.new(0, moveDirection.Y, 0)
                
                moveDirection = worldDirection.Unit
            end
            
            -- Calculate target velocity
            self.targetVelocity = moveDirection * self.speed
            
            -- Hover stabilization
            if self.config.hoverStabilization and math.abs(moveDirection.Y) < 0.1 then
                self.targetVelocity = Vector3.new(
                    self.targetVelocity.X,
                    0,
                    self.targetVelocity.Z
                )
            end
        else
            -- No input - apply hover or gravity
            if self.config.hoverStabilization then
                self.targetVelocity = Vector3.new(0, 0, 0)
            else
                self.targetVelocity = Vector3.new(0, -Workspace.Gravity * dt * 0.5, 0)
            end
        end
        
        -- Smooth velocity interpolation
        if self.config.smoothMovement then
            local alpha = math.min(dt * 10, 1)
            self.velocity = self.velocity:Lerp(self.targetVelocity, alpha)
        else
            self.velocity = self.targetVelocity
        end
        
        -- Apply velocity using modern constraints or direct method
        if self.config.useModernConstraints then
            if not self.constraints.velocity then
                self.constraints.velocity = Instance.new("LinearVelocity")
                self.constraints.velocity.Attachment0 = Instance.new("Attachment")
                self.constraints.velocity.Attachment0.Parent = self.rootPart
                self.constraints.velocity.MaxForce = math.huge
                self.constraints.velocity.Parent = self.rootPart
            end
            self.constraints.velocity.VectorVelocity = self.velocity
            
            -- Orientation constraint
            if not self.constraints.orientation then
                self.constraints.orientation = Instance.new("AlignOrientation")
                self.constraints.orientation.Attachment0 = self.constraints.velocity.Attachment0
                self.constraints.orientation.MaxTorque = 10000
                self.constraints.orientation.Responsiveness = 200
                self.constraints.orientation.Parent = self.rootPart
            end
            
            -- Look at movement direction
            if self.velocity.Magnitude > 0 then
                local lookDir = Vector3.new(self.velocity.X, 0, self.velocity.Z)
                if lookDir.Magnitude > 0 then
                    self.constraints.orientation.CFrame = CFrame.lookAt(
                        self.rootPart.Position,
                        self.rootPart.Position + lookDir.Unit
                    )
                end
            end
        else
            -- Direct velocity method (more compatible)
            self.rootPart.Velocity = self.velocity
            
            -- Apply anti-gravity
            if self.config.antiGravity then
                self.rootPart.AssemblyLinearVelocity = Vector3.new(
                    self.velocity.X,
                    self.velocity.Y + (Workspace.Gravity * dt),
                    self.velocity.Z
                )
            end
        end
        
        -- Swim-fly style: Keep character in neutral pose
        if self.config.swimStyle and self.humanoid then
            self.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end))
end

-- Internal: Tween helper
function FlySystem:_tween(object, properties, duration)
    duration = duration or 0.2
    local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad), properties)
    tween:Play()
    return tween
end

-- Public API Methods

-- Toggle fly on/off
function FlySystem:Toggle()
    self.enabled = not self.enabled
    
    if self.enabled then
        -- Enable fly
        self.humanoid.PlatformStand = true
        
        -- Save original state
        if not self.humanoid:GetAttribute("OriginalWalkSpeed") then
            self.humanoid:SetAttribute("OriginalWalkSpeed", self.humanoid.WalkSpeed)
            self.humanoid:SetAttribute("OriginalJumpPower", self.humanoid.JumpPower)
        end
        
        -- Disable normal movement
        self.humanoid.WalkSpeed = 0
        self.humanoid.JumpPower = 0
        
        -- Stop animations
        for _, track in pairs(self.humanoid:GetPlayingAnimationTracks()) do
            if track.Name ~= "idle" then
                track:Stop()
            end
        end
        
        -- Update UI
        self.uiElements.status.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        self.uiElements.statusText.Text = "FLY: ON"
        
        print("🛠️ Kevin's Fly: ENABLED")
    else
        -- Disable fly
        self.humanoid.PlatformStand = false
        
        -- Restore original state
        local walkSpeed = self.humanoid:GetAttribute("OriginalWalkSpeed") or 16
        local jumpPower = self.humanoid:GetAttribute("OriginalJumpPower") or 50
        self.humanoid.WalkSpeed = walkSpeed
        self.humanoid.JumpPower = jumpPower
        
        -- Cleanup physics
        for _, constraint in pairs(self.constraints) do
            if constraint then
                constraint:Destroy()
            end
        end
        self.constraints = {}
        
        -- Reset velocity
        self.direction = Vector3.new(0, 0, 0)
        self.velocity = Vector3.new(0, 0, 0)
        self.targetVelocity = Vector3.new(0, 0, 0)
        
        if self.rootPart then
            self.rootPart.Velocity = Vector3.new(0, 0, 0)
            self.rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        -- Update UI
        self.uiElements.status.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        self.uiElements.statusText.Text = "FLY: OFF"
        
        print("🛠️ Kevin's Fly: DISABLED")
    end
    
    -- Trigger callbacks
    self:_triggerCallback("toggle", self.enabled)
end

-- Set fly speed
function FlySystem:SetSpeed(speed)
    self.speed = math.clamp(speed, self.config.minSpeed, self.config.maxSpeed)
    
    -- Update UI
    self.uiElements.speedLabel.Text = "SPEED: " .. self.speed
    self.uiElements.speedFill.Size = UDim2.new(
        (self.speed - self.config.minSpeed) / (self.config.maxSpeed - self.config.minSpeed),
        0,
        1,
        0
    )
    
    -- Trigger callbacks
    self:_triggerCallback("speedChange", self.speed)
end

-- Toggle UI visibility
function FlySystem:ToggleUI()
    if self.uiMinimized then
        -- Show full UI
        self.uiElements.main.Visible = true
        self.uiElements.minimizedBtn.Visible = false
        if IS_MOBILE then
            self.uiElements.mobileControls.Visible = true
        end
        self.uiMinimized = false
    else
        -- Minimize to "N" button
        self.uiElements.main.Visible = false
        self.uiElements.minimizedBtn.Visible = true
        if IS_MOBILE then
            self.uiElements.mobileControls.Visible = false
        end
        self.uiMinimized = true
    end
    
    self:_triggerCallback("uiState", not self.uiMinimized)
end

-- Hide UI completely
function FlySystem:HideUI()
    self.uiHidden = not self.uiHidden
    self.ui.Enabled = not self.uiHidden
    self:_triggerCallback("uiState", not self.uiHidden)
end

-- Set theme color
function FlySystem:SetTheme(color)
    self.config.themeColor = color
    self.uiElements.main.BackgroundColor3 = color
end

-- Set transparency
function FlySystem:SetTransparency(transparency)
    self.config.transparency = transparency
    self.uiElements.main.BackgroundTransparency = transparency
end

-- Add custom button
function FlySystem:AddButton(name, callback)
    local btn = self:_createButton(name, UDim2.new(0.1, 0, 0.9, -30), UDim2.new(0.8, 0, 0, 30), Color3.fromRGB(100, 100, 255))
    btn.Parent = self.uiElements.content
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Register callback
function FlySystem:RegisterCallback(event, callback)
    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end
    table.insert(self.callbacks[event], callback)
end

-- Internal: Trigger callbacks
function FlySystem:_triggerCallback(event, ...)
    if self.callbacks[event] then
        for _, callback in ipairs(self.callbacks[event]) do
            if type(callback) == "function" then
                pcall(callback, ...)
            end
        end
    end
end

-- Destroy and cleanup
function FlySystem:Destroy()
    -- Disable fly if active
    if self.enabled then
        self:Toggle()
    end
    
    -- Disconnect all connections
    for _, connection in ipairs(self.connections) do
        if connection then
            pcall(function() connection:Disconnect() end)
        end
    end
    
    -- Destroy UI
    if self.ui then
        self.ui:Destroy()
    end
    
    -- Cleanup physics
    for _, constraint in pairs(self.constraints) do
        if constraint then
            constraint:Destroy()
        end
    end
    
    print("🛠️ Kevin's Fly System: DESTROYED")
    
    setmetatable(self, nil)
end

-- Quick initialization function
function FlySystem:QuickStart()
    print("╔══════════════════════════════════════════╗")
    print("║  🛠️ Kevin's Fly System Quick Start      ║")
    print("║  Press F to toggle fly                  ║")
    print("║  WASD + Space/CTRL to move              ║")
    print("║  E/Q to adjust speed                    ║")
    print("║  H to minimize UI, J to hide            ║")
    print("╚══════════════════════════════════════════╝")
    
    if IS_MOBILE then
        print("📱 Mobile: Use on-screen joystick and buttons")
    end
end

-- Return the module
return FlySystem

--[[
===============================================================================
EXAMPLE USAGE:
===============================================================================

-- Load the module
local FlySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/..."))()

-- Create instance
local fly = FlySystem.new({
    speed = 60,
    themeColor = Color3.fromRGB(0, 180, 255),
    hoverStabilization = true
})

-- Quick start (prints controls)
fly:QuickStart()

-- Custom button
fly:AddButton("BOOST", function()
    fly:SetSpeed(150)
end)

-- Register callback
fly:RegisterCallback("toggle", function(enabled)
    print("Fly is now:", enabled and "ON" or "OFF")
end)

===============================================================================
--]]
