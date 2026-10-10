-- NIGHTDLC MOBILE VERSION (Optimized for phones)
-- GUI: Centered, compact, touch-friendly
-- All sizes and positions scaled for mobile screens

do
    -- Mobile GUI Constants
    local SCREEN_W = 400  -- Mobile viewport
    local SCREEN_H = 600
    local BUTTON_W = 120
    local BUTTON_H = 35
    local TEXT_SIZE = 12
    local TITLE_SIZE = 14
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TextService = game:GetService("TextService")
    
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Mobile Settings
    getgenv().nightdlc_settings = getgenv().nightdlc_settings or {
        enabled = true,
        esp_enabled = false,
        esp_color = Color3.fromRGB(0, 255, 0),
        autoshoot = false,
        autoshoot_key = Enum.KeyCode.E,
        worldviz_enabled = false,
        theme = "dark"
    }
    
    -- Create main ScreenGui (mobile-optimized)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NightDLCMobileGui"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Main container (centered)
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.fromScale(1, 1)
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = screenGui
    
    -- Card (mobile: smaller, centered)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.fromOffset(280, 220)  -- Compact, phone-friendly menu
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    card.BorderSizePixel = 0
    card.Parent = mainContainer
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "NightDLC"
    title.TextSize = TITLE_SIZE
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(10, 10)
    title.Size = UDim2.fromOffset(250, 25)
    title.Font = Enum.Font.GothamBold
    title.Parent = card
    
    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status"
    statusText.Text = "Mobile | Ready"
    statusText.TextSize = TEXT_SIZE - 2
    statusText.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusText.BackgroundTransparency = 1
    statusText.Position = UDim2.fromOffset(10, 35)
    statusText.Size = UDim2.fromOffset(250, 15)
    statusText.Font = Enum.Font.Gotham
    statusText.Parent = card
    
    -- Button grid (mobile: smaller buttons, vertical layout)
    local btnESP = Instance.new("TextButton")
    btnESP.Name = "ESPToggle"
    btnESP.Text = "ESP: OFF"
    btnESP.TextSize = TEXT_SIZE
    btnESP.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnESP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btnESP.BorderSizePixel = 0
    btnESP.Position = UDim2.fromOffset(10, 58)
    btnESP.Size = UDim2.fromOffset(260, 32)
    btnESP.Font = Enum.Font.Gotham
    btnESP.Parent = card
    
    local cornerESP = Instance.new("UICorner")
    cornerESP.CornerRadius = UDim.new(0, 4)
    cornerESP.Parent = btnESP
    
    -- Autoshoot button
    local btnAutoshoot = Instance.new("TextButton")
    btnAutoshoot.Name = "AutoshootToggle"
    btnAutoshoot.Text = "Autoshoot: OFF"
    btnAutoshoot.TextSize = TEXT_SIZE
    btnAutoshoot.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAutoshoot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btnAutoshoot.BorderSizePixel = 0
    btnAutoshoot.Position = UDim2.fromOffset(10, 96)
    btnAutoshoot.Size = UDim2.fromOffset(260, 32)
    btnAutoshoot.Font = Enum.Font.Gotham
    btnAutoshoot.Parent = card
    
    local cornerAutoshoot = Instance.new("UICorner")
    cornerAutoshoot.CornerRadius = UDim.new(0, 4)
    cornerAutoshoot.Parent = btnAutoshoot
    
    -- WorldViz button
    local btnWorldViz = Instance.new("TextButton")
    btnWorldViz.Name = "WorldVizToggle"
    btnWorldViz.Text = "Viz: OFF"
    btnWorldViz.TextSize = TEXT_SIZE
    btnWorldViz.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnWorldViz.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btnWorldViz.BorderSizePixel = 0
    btnWorldViz.Position = UDim2.fromOffset(10, 134)
    btnWorldViz.Size = UDim2.fromOffset(260, 32)
    btnWorldViz.Font = Enum.Font.Gotham
    btnWorldViz.Parent = card
    
    local cornerWorldViz = Instance.new("UICorner")
    cornerWorldViz.CornerRadius = UDim.new(0, 4)
    cornerWorldViz.Parent = btnWorldViz
    
    -- Minimize/Close button
    local btnClose = Instance.new("TextButton")
    btnClose.Name = "CloseButton"
    btnClose.Text = "X"
    btnClose.TextSize = TEXT_SIZE
    btnClose.TextColor3 = Color3.fromRGB(255, 100, 100)
    btnClose.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btnClose.BorderSizePixel = 0
    btnClose.Position = UDim2.fromOffset(250, 10)
    btnClose.Size = UDim2.fromOffset(20, 20)
    btnClose.Font = Enum.Font.Gotham
    btnClose.Parent = card
    
    -- Button click handlers
    local function updateButtonText()
        btnESP.Text = getgenv().nightdlc_settings.esp_enabled and "ESP: ON" or "ESP: OFF"
        btnAutoshoot.Text = getgenv().nightdlc_settings.autoshoot and "Autoshoot: ON" or "Autoshoot: OFF"
        btnWorldViz.Text = getgenv().nightdlc_settings.worldviz_enabled and "Viz: ON" or "Viz: OFF"
    end
    
    btnESP.MouseButton1Click:Connect(function()
        getgenv().nightdlc_settings.esp_enabled = not getgenv().nightdlc_settings.esp_enabled
        updateButtonText()
    end)
    
    btnAutoshoot.MouseButton1Click:Connect(function()
        getgenv().nightdlc_settings.autoshoot = not getgenv().nightdlc_settings.autoshoot
        updateButtonText()
    end)
    
    btnWorldViz.MouseButton1Click:Connect(function()
        getgenv().nightdlc_settings.worldviz_enabled = not getgenv().nightdlc_settings.worldviz_enabled
        updateButtonText()
    end)
    
    -- Floating, draggable menu toggle (mouse + touch)
    local floatingButton = Instance.new("TextButton")
    floatingButton.Name = "FloatingMenuToggle"
    floatingButton.Text = "N"
    floatingButton.TextSize = 18
    floatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatingButton.Font = Enum.Font.GothamBold
    floatingButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    floatingButton.BorderSizePixel = 0
    floatingButton.Size = UDim2.fromOffset(48, 48)
    floatingButton.Position = UDim2.new(0, 18, 0.65, 0)
    floatingButton.AutoButtonColor = true
    floatingButton.Active = true
    floatingButton.ZIndex = 10
    floatingButton.Parent = screenGui

    local floatingCorner = Instance.new("UICorner")
    floatingCorner.CornerRadius = UDim.new(1, 0)
    floatingCorner.Parent = floatingButton

    local floatingStroke = Instance.new("UIStroke")
    floatingStroke.Color = Color3.fromRGB(100, 100, 100)
    floatingStroke.Thickness = 1
    floatingStroke.Parent = floatingButton

    local dragging = false
    local dragStart = nil
    local startPosition = nil
    local moved = false

    floatingButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPosition = floatingButton.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                moved = true
            end
            if moved then
                floatingButton.Position = UDim2.new(
                    startPosition.X.Scale, startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
        end
    end)

    floatingButton.Activated:Connect(function()
        if not moved then
            card.Visible = not card.Visible
        end
    end)

    btnClose.Activated:Connect(function()
        card.Visible = false
    end)

    updateButtonText()
    
    -- ============================================
    -- WORLD VIZ SYSTEM (Simplified for Mobile)
    -- ============================================
    
    getgenv().nightdlc_worldviz = {
        enabled = false,
        esp_enabled = false,
        esp_color = Color3.fromRGB(0, 255, 0),
        
        toggle = function(self)
            self.enabled = not self.enabled
            statusText.Text = self.enabled and "Viz: Active" or "Viz: Inactive"
        end,
        
        toggle_esp = function(self)
            self.esp_enabled = not self.esp_enabled
        end,
        
        set_esp_color = function(self, r, g, b)
            self.esp_color = Color3.fromRGB(r, g, b)
        end
    }
    
    -- ESP drawing function
    local function draw_esp()
        if not getgenv().nightdlc_settings.esp_enabled then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local cam = workspace.CurrentCamera
                    local pos = humanoidRootPart.Position
                    local dist = (pos - cam.CFrame.Position).Magnitude
                    
                    local label = Instance.new("TextLabel")
                    label.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
                    label.TextSize = TEXT_SIZE - 2
                    label.TextColor3 = getgenv().nightdlc_settings.esp_color
                    label.BackgroundTransparency = 1
                    label.Parent = screenGui
                    
                    local screenPos = cam:WorldToScreenPoint(pos)
                    label.Position = UDim2.fromOffset(screenPos.X - 50, screenPos.Y - 30)
                    label.Size = UDim2.fromOffset(100, 20)
                    
                    game:GetService("Debris"):AddItem(label, 0.016)
                end
            end
        end
    end
    
    -- ============================================
    -- AUTOSHOOT SYSTEM
    -- ============================================
    
    local function autoshoot_loop()
        if not getgenv().nightdlc_settings.autoshoot then return end
        
        local cam = workspace.CurrentCamera
        local closest_dist = math.huge
        local closest_player = nil
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - cam.CFrame.Position).Magnitude
                    if dist < closest_dist then
                        closest_dist = dist
                        closest_player = player
                    end
                end
            end
        end
        
        if closest_player and closest_dist < 100 then
            local event = LocalPlayer.Character:FindFirstChild("Attack")
            if event then
                event:FireServer(closest_player.Character.HumanoidRootPart)
            end
        end
    end
    
    -- Main loop
    RunService.RenderStepped:Connect(function()
        draw_esp()
        autoshoot_loop()
    end)
    
    -- Keyboard shortcuts for mobile (optional)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.V then
            getgenv().nightdlc_settings.esp_enabled = not getgenv().nightdlc_settings.esp_enabled
            updateButtonText()
        elseif input.KeyCode == Enum.KeyCode.B then
            getgenv().nightdlc_settings.autoshoot = not getgenv().nightdlc_settings.autoshoot
            updateButtonText()
        end
    end)
    
    print("NightDLC Mobile loaded successfully!")

end
