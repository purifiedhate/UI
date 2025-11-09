-- MatchaUI Library (Fixed)
local MatchaUI = {}
MatchaUI.__index = MatchaUI

-- Utility functions
local function createVector2(x, y)
    if Vector2 then
        return Vector2.new(x, y)
    else
        local success, result = pcall(function()
            return Vector2.new(x, y)
        end)
        if success then
            return result
        else
            error("Vector2 not available in this environment")
        end
    end
end

local function isMouseOver(position, size, mousePos)
    return mousePos.X >= position.X and mousePos.X <= position.X + size.X and
           mousePos.Y >= position.Y and mousePos.Y <= position.Y + size.Y
end

-- Window Class
function MatchaUI:CreateWindow(title, size, position)
    local self = setmetatable({}, MatchaUI)
    
    self.Title = title or "MatchaUI Window"
    self.Size = size or createVector2(550, 450)
    self.Position = position or createVector2(100, 100)
    self.Visible = true
    self.Tabs = {}
    self.CurrentTab = 1
    self.Dragging = false
    self.DragOffset = createVector2(0, 0)
    self.Objects = {}
    
    -- Create main window elements
    self:createWindowElements()
    
    return self
end

function MatchaUI:createWindowElements()
    -- Main background
    local bg = Drawing.new("Square")
    bg.Size = self.Size
    bg.Position = self.Position
    bg.Color = Color3.fromRGB(30, 30, 35)
    bg.Filled = true
    bg.Transparency = 0.8
    table.insert(self.Objects, bg)
    self.Background = bg
    
    -- Title bar
    local titleBar = Drawing.new("Square")
    titleBar.Size = createVector2(self.Size.X, 35)
    titleBar.Position = self.Position
    titleBar.Color = Color3.fromRGB(25, 25, 30)
    titleBar.Filled = true
    titleBar.Transparency = 0.7
    table.insert(self.Objects, titleBar)
    self.TitleBar = titleBar
    
    -- Title text
    local titleText = Drawing.new("Text")
    titleText.Text = self.Title
    titleText.Size = 18
    titleText.Position = createVector2(self.Position.X + 15, self.Position.Y + 8)
    titleText.Color = Color3.fromRGB(255, 255, 255)
    titleText.Outline = true
    table.insert(self.Objects, titleText)
    self.TitleText = titleText
    
    -- Close button
    local closeButton = Drawing.new("Text")
    closeButton.Text = "×"
    closeButton.Size = 20
    closeButton.Position = createVector2(self.Position.X + self.Size.X - 25, self.Position.Y + 5)
    closeButton.Color = Color3.fromRGB(255, 255, 255)
    closeButton.Outline = true
    table.insert(self.Objects, closeButton)
    self.CloseButton = closeButton
    
    self.CloseButtonArea = {
        Position = createVector2(self.Position.X + self.Size.X - 25, self.Position.Y + 5),
        Size = createVector2(20, 20)
    }
    
    self.TitleBarArea = {
        Position = self.Position,
        Size = createVector2(self.Size.X, 35)
    }
end

function MatchaUI:AddTab(name)
    local tab = {
        Name = name,
        Elements = {},
        Buttons = {},
        Toggles = {},
        Visible = false,
        Window = self
    }
    
    -- Set metatable for tab to add methods
    setmetatable(tab, {
        __index = function(t, key)
            if key == "Section" then
                return function(_, sectionName)
                    local section = {
                        Type = "Section",
                        Text = sectionName,
                        Position = createVector2(0, 0),
                        Size = createVector2(0, 35)
                    }
                    table.insert(t.Elements, section)
                    return section
                end
            elseif key == "Button" then
                return function(_, buttonText, callback)
                    local button = {
                        Type = "Button",
                        Text = buttonText,
                        Callback = callback,
                        Position = createVector2(0, 0),
                        Size = createVector2(0, 35),
                        Hovered = false
                    }
                    table.insert(t.Elements, button)
                    table.insert(t.Buttons, button)
                    return button
                end
            elseif key == "Toggle" then
                return function(_, toggleText, default, callback)
                    local toggle = {
                        Type = "Toggle",
                        Text = toggleText,
                        Value = default or false,
                        Callback = callback,
                        Position = createVector2(0, 0),
                        Size = createVector2(0, 30),
                        Hovered = false
                    }
                    table.insert(t.Elements, toggle)
                    table.insert(t.Toggles, toggle)
                    return toggle
                end
            end
            return rawget(t, key)
        end
    })
    
    local buttonX = self.Position.X + 20 + (#self.Tabs * 90)
    local buttonPos = createVector2(buttonX, self.Position.Y + 40)
    
    -- Tab button text
    local buttonText = Drawing.new("Text")
    buttonText.Text = name
    buttonText.Size = 13
    buttonText.Position = createVector2(buttonX + 35, buttonPos.Y + 8)
    buttonText.Color = Color3.fromRGB(200, 200, 200)
    buttonText.Outline = true
    buttonText.Visible = self.Visible
    table.insert(self.Objects, buttonText)
    
    -- Tab underline
    local underline = Drawing.new("Square")
    underline.Size = createVector2(0, 2)
    underline.Position = createVector2(buttonX + 35, buttonPos.Y + 28)
    underline.Color = Color3.fromRGB(0, 150, 255)
    underline.Filled = true
    underline.Visible = self.Visible
    table.insert(self.Objects, underline)
    
    tab.Button = {
        Text = buttonText,
        Underline = underline,
        Position = buttonPos,
        Size = createVector2(85, 30)
    }
    
    table.insert(self.Tabs, tab)
    return tab
end

function MatchaUI:SwitchTab(tabIndex)
    for i, tab in ipairs(self.Tabs) do
        tab.Visible = (i == tabIndex)
        if tab.Button and tab.Button.Text then
            tab.Button.Text.Color = (i == tabIndex) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            if tab.Button.Underline then
                tab.Button.Underline.Size = (i == tabIndex) and createVector2(50, 2) or createVector2(0, 2)
            end
        end
    end
    self.CurrentTab = tabIndex
    self:Render()
end

function MatchaUI:Render()
    for _, tab in ipairs(self.Tabs) do
        local currentY = self.Position.Y + 85  -- Start below tabs
        
        for _, element in ipairs(tab.Elements) do
            local elementX = self.Position.X + 25
            local elementPos = createVector2(elementX, currentY)
            element.Position = elementPos
            
            if element.Type == "Section" then
                if not element.Drawing then
                    element.Drawing = Drawing.new("Text")
                    element.Drawing.Size = 15
                    element.Drawing.Color = Color3.fromRGB(255, 255, 255)
                    element.Drawing.Outline = true
                    table.insert(self.Objects, element.Drawing)
                end
                
                element.Drawing.Text = element.Text
                element.Drawing.Position = elementPos
                element.Drawing.Visible = self.Visible and tab.Visible
                
            elseif element.Type == "Button" then
                if not element.Drawing then
                    element.Drawing = Drawing.new("Square")
                    element.Drawing.Filled = true
                    element.Drawing.Color = Color3.fromRGB(255, 255, 255)
                    element.Drawing.Transparency = element.Hovered and 0.15 or 0.1
                    table.insert(self.Objects, element.Drawing)
                    
                    element.TextDrawing = Drawing.new("Text")
                    element.TextDrawing.Size = 14
                    element.TextDrawing.Color = Color3.fromRGB(255, 255, 255)
                    element.TextDrawing.Outline = true
                    table.insert(self.Objects, element.TextDrawing)
                end
                
                element.Drawing.Size = createVector2(self.Size.X - 50, 35)
                element.Drawing.Position = elementPos
                element.Drawing.Visible = self.Visible and tab.Visible
                element.Drawing.Transparency = element.Hovered and 0.15 or 0.1
                
                element.TextDrawing.Text = element.Text
                element.TextDrawing.Position = createVector2(elementPos.X + 10, elementPos.Y + 8)
                element.TextDrawing.Visible = self.Visible and tab.Visible
                
                element.Size = createVector2(self.Size.X - 50, 35)
                
            elseif element.Type == "Toggle" then
                if not element.Drawing then
                    -- Toggle background
                    element.Background = Drawing.new("Square")
                    element.Background.Size = createVector2(45, 25)
                    element.Background.Filled = true
                    element.Background.Color = element.Value and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(80, 80, 85)
                    table.insert(self.Objects, element.Background)
                    
                    -- Toggle dot
                    element.Dot = Drawing.new("Circle")
                    element.Dot.Radius = 8
                    element.Dot.Filled = true
                    element.Dot.Color = element.Value and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 255, 255)
                    element.Dot.NumSides = 12
                    table.insert(self.Objects, element.Dot)
                    
                    -- Toggle label
                    element.Label = Drawing.new("Text")
                    element.Label.Size = 14
                    element.Label.Color = Color3.fromRGB(255, 255, 255)
                    element.Label.Outline = true
                    table.insert(self.Objects, element.Label)
                end
                
                local dotPos = element.Value and createVector2(29, 12) or createVector2(8, 12)
                
                element.Background.Position = elementPos
                element.Background.Visible = self.Visible and tab.Visible
                element.Background.Color = element.Value and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(80, 80, 85)
                
                element.Dot.Position = createVector2(elementPos.X + dotPos.X, elementPos.Y + dotPos.Y)
                element.Dot.Visible = self.Visible and tab.Visible
                element.Dot.Color = element.Value and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 255, 255)
                
                element.Label.Text = element.Text
                element.Label.Position = createVector2(elementPos.X + 50, elementPos.Y + 4)
                element.Label.Visible = self.Visible and tab.Visible
                
                element.Size = createVector2(self.Size.X - 50, 25)
            end
            
            currentY = currentY + (element.Type == "Section" and 40 or 35)
        end
    end
end

function MatchaUI:HandleInput(mousePos, mouse1Pressed)
    if mouse1Pressed then
        if not self.Dragging then
            -- Check for close button
            if isMouseOver(self.CloseButtonArea.Position, self.CloseButtonArea.Size, mousePos) then
                self:Destroy()
                return true
            end
            
            -- Check for title bar dragging
            if isMouseOver(self.TitleBarArea.Position, self.TitleBarArea.Size, mousePos) then
                self.Dragging = true
                self.DragOffset = createVector2(mousePos.X - self.Position.X, mousePos.Y - self.Position.Y)
            end
            
            -- Check tab buttons
            for i, tab in ipairs(self.Tabs) do
                if tab.Button and isMouseOver(tab.Button.Position, tab.Button.Size, mousePos) then
                    self:SwitchTab(i)
                    break
                end
            end
            
            -- Check elements in current tab
            local currentTab = self.Tabs[self.CurrentTab]
            if currentTab and currentTab.Visible then
                for _, element in ipairs(currentTab.Elements) do
                    if element.Position and element.Size and isMouseOver(element.Position, element.Size, mousePos) then
                        if element.Type == "Button" and element.Callback then
                            element.Callback()
                        elseif element.Type == "Toggle" and element.Callback then
                            element.Value = not element.Value
                            element.Callback(element.Value)
                            self:Render() -- Re-render to update toggle state
                        end
                    end
                end
            end
        end
    else
        self.Dragging = false
    end
    
    -- Handle dragging
    if self.Dragging then
        self.Position = createVector2(mousePos.X - self.DragOffset.X, mousePos.Y - self.DragOffset.Y)
        self:UpdatePositions()
    end
    
    -- Update hover states
    local currentTab = self.Tabs[self.CurrentTab]
    if currentTab and currentTab.Visible then
        for _, element in ipairs(currentTab.Elements) do
            if element.Type == "Button" and element.Position and element.Size then
                local wasHovered = element.Hovered
                element.Hovered = isMouseOver(element.Position, element.Size, mousePos)
                if wasHovered ~= element.Hovered then
                    self:Render() -- Re-render to update hover state
                end
            end
        end
    end
    
    return false
end

function MatchaUI:UpdatePositions()
    -- Update main window elements
    self.Background.Position = self.Position
    self.TitleBar.Position = self.Position
    self.TitleText.Position = createVector2(self.Position.X + 15, self.Position.Y + 8)
    self.CloseButton.Position = createVector2(self.Position.X + self.Size.X - 25, self.Position.Y + 5)
    
    self.CloseButtonArea.Position = createVector2(self.Position.X + self.Size.X - 25, self.Position.Y + 5)
    self.TitleBarArea.Position = self.Position
    
    -- Update tab buttons
    for i, tab in ipairs(self.Tabs) do
        local buttonX = self.Position.X + 20 + ((i - 1) * 90)
        local buttonPos = createVector2(buttonX, self.Position.Y + 40)
        
        if tab.Button then
            tab.Button.Position = buttonPos
            if tab.Button.Text then
                tab.Button.Text.Position = createVector2(buttonX + 35, buttonPos.Y + 8)
            end
            if tab.Button.Underline then
                tab.Button.Underline.Position = createVector2(buttonX + 35, buttonPos.Y + 28)
            end
        end
    end
    
    self:Render()
end

function MatchaUI:SetVisible(visible)
    self.Visible = visible
    for _, obj in ipairs(self.Objects) do
        if obj then
            obj.Visible = visible
        end
    end
    self:Render()
end

function MatchaUI:Destroy()
    for _, obj in ipairs(self.Objects) do
        if obj then
            obj:Remove()
        end
    end
    self.Objects = {}
end

-- Create a global function to create windows
function MatchaUI.CreateWindow(title, size, position)
    return MatchaUI:CreateWindow(title, size, position)
end

return MatchaUI
