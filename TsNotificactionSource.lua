local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Player = game:GetService("Players").LocalPlayer

local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "AkaliNotif"
NotifGui.Parent = RunService:IsStudio() and Player.PlayerGui or game:GetService("CoreGui")

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Position = UDim2.new(0, 20, 0.5, -20)
Container.Size = UDim2.new(0, 300, 0.5, 0)
Container.BackgroundTransparency = 1
Container.Parent = NotifGui

-- Função para criar blur background
local function CreateBlurBackground(parent)
    if game:GetService("RunService"):IsStudio() then
        -- Fallback para Studio (onde BlurEffect não funciona)
        local BlurFrame = Instance.new("Frame")
        BlurFrame.Size = UDim2.new(1, 40, 1, 40)
        BlurFrame.Position = UDim2.new(-0.07, 0, -0.07, 0)
        BlurFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        BlurFrame.BackgroundTransparency = 0.15
        BlurFrame.ZIndex = -1
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 12)
        Corner.Parent = BlurFrame
        
        return BlurFrame
    else
        -- Blur real para o jogo
        local BlurEffect = Instance.new("BlurEffect")
        BlurEffect.Size = 8
        BlurEffect.Name = "NotificationBlur"
        
        return BlurEffect
    end
end

local function Image(ID, Button)
    local NewImage = Instance.new(string.format("Image%s", Button and "Button" or "Label"))
    NewImage.Image = ID
    NewImage.BackgroundTransparency = 1
    return NewImage
end

local function Round2px()
    local NewImage = Image("http://www.roblox.com/asset/?id=5761488251")
    NewImage.ScaleType = Enum.ScaleType.Slice
    NewImage.SliceCenter = Rect.new(2, 2, 298, 298)
    NewImage.ImageColor3 = Color3.fromRGB(25, 25, 25)
    NewImage.ImageTransparency = 0.05
    return NewImage
end

local function Shadow2px()
    local NewImage = Image("http://www.roblox.com/asset/?id=5761498316")
    NewImage.ScaleType = Enum.ScaleType.Slice
    NewImage.SliceCenter = Rect.new(17, 17, 283, 283)
    NewImage.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30)
    NewImage.Position = -UDim2.fromOffset(15, 15)
    NewImage.ImageColor3 = Color3.fromRGB(15, 15, 15)
    NewImage.ImageTransparency = 0.1
    return NewImage
end

local Padding = 12
local DescriptionPadding = 12
local InstructionObjects = {}
local TweenTime = 0.8
local TweenStyle = Enum.EasingStyle.Quint
local TweenDirection = Enum.EasingDirection.Out

local LastTick = tick()

local function CalculateBounds(TableOfObjects)
    local TableOfObjects = typeof(TableOfObjects) == "table" and TableOfObjects or {}
    local Y = 0
    for _, Object in next, TableOfObjects do
        if Object:IsA("GuiObject") then
            Y += Object.AbsoluteSize.Y
        end
    end
    return Y
end

local CachedObjects = {}

local function Update()
    local DeltaTime = tick() - LastTick
    local PreviousObjects = {}
    
    for i, ObjectData in ipairs(InstructionObjects) do
        local MainFrame, Delta, Done = ObjectData[1], ObjectData[2], ObjectData[3]
        
        if not Done then
            if Delta < TweenTime then
                ObjectData[2] = math.clamp(Delta + DeltaTime, 0, TweenTime)
                Delta = ObjectData[2]
            else
                ObjectData[3] = true
            end
        end
        
        local NewValue = TweenService:GetValue(Delta / TweenTime, TweenStyle, TweenDirection)
        local CurrentPos = MainFrame.Position
        
        -- Calcular posição Y baseada nas notificações anteriores
        local TotalHeight = 0
        for j = 1, i - 1 do
            local previousFrame = InstructionObjects[j][1]
            if previousFrame and previousFrame.Parent then
                TotalHeight += previousFrame.AbsoluteSize.Y + Padding
            end
        end
        
        local TargetPos = UDim2.new(0, 0, 0, TotalHeight)
        MainFrame.Position = CurrentPos:Lerp(TargetPos, NewValue)
        table.insert(PreviousObjects, MainFrame)
    end
    
    CachedObjects = PreviousObjects
    LastTick = tick()
end

RunService:BindToRenderStep("UpdateList", 0, Update)

local TitleSettings = {
    Font = Enum.Font.GothamSemibold,
    Size = 15
}

local DescriptionSettings = {
    Font = Enum.Font.Gotham,
    Size = 13,
    LineHeight = 1.1
}

local MaxWidth = 280 -- Largura máxima fixa

local function Label(Text, Font, Size, Button)
    local Label = Instance.new(string.format("Text%s", Button and "Button" or "Label"))
    Label.Text = Text
    Label.Font = Font
    Label.TextSize = Size
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.RichText = true
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    return Label
end

local function TitleLabel(Text)
    local label = Label(Text, TitleSettings.Font, TitleSettings.Size)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    return label
end

local function DescriptionLabel(Text)
    local label = Label(Text, DescriptionSettings.Font, DescriptionSettings.Size)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.LineHeight = DescriptionSettings.LineHeight
    return label
end

local PropertyTweenOut = {
    Text = "TextTransparency",
    Fram = "BackgroundTransparency",
    Imag = "ImageTransparency"
}

local function FadeProperty(Object)
    local Prop = PropertyTweenOut[string.sub(Object.ClassName, 1, 4)]
    TweenService:Create(Object, TweenInfo.new(0.3, TweenStyle, TweenDirection), {
        [Prop] = 1
    }):Play()
end

local function FindIndexByDependency(Table, Dependency)
    for Index, ObjectData in ipairs(Table) do
        if ObjectData[1] == Dependency then
            return Index
        end
    end
    return nil
end

local function ResetObjects()
    for _, ObjectData in ipairs(InstructionObjects) do
        ObjectData[2] = 0
        ObjectData[3] = false
    end
end

local function FadeOutAfter(MainFrame, Seconds)
    wait(Seconds)
    
    -- Fade out de todos os elementos
    FadeProperty(MainFrame)
    for _, child in ipairs(MainFrame:GetDescendants()) do
        if child:IsA("GuiObject") then
            FadeProperty(child)
        end
    end
    
    wait(0.3)
    
    -- Remover da tabela e destruir
    local index = FindIndexByDependency(InstructionObjects, MainFrame)
    if index then
        table.remove(InstructionObjects, index)
    end
    
    ResetObjects()
    
    -- Destruir após a animação
    delay(0.1, function()
        if MainFrame then
            MainFrame:Destroy()
        end
    end)
end

return {
    Notify = function(Properties)
        local Properties = typeof(Properties) == "table" and Properties or {}
        local Title = Properties.Title or ""
        local Description = Properties.Description or ""
        local Duration = Properties.Duration or 5
        
        if Title == "" and Description == "" then return end
        
        -- Calcular altura necessária
        local totalHeight = 0
        
        if Title ~= "" then
            totalHeight += 28 -- Altura do título
        end
        
        if Description ~= "" then
            local textSize = TextService:GetTextSize(
                Description, 
                DescriptionSettings.Size, 
                DescriptionSettings.Font, 
                Vector2.new(MaxWidth - DescriptionPadding * 2, 10000) -- Altura máxima grande
            )
            totalHeight += textSize.Y + 10
        end
        
        -- Altura mínima e padding
        totalHeight = math.max(totalHeight, 40) + 16 -- Padding vertical
        
        -- Criar frame principal
        local MainFrame = Instance.new("Frame")
        MainFrame.BackgroundTransparency = 1
        MainFrame.Size = UDim2.new(0, 300, 0, totalHeight)
        MainFrame.Position = UDim2.new(-1, 20, 0, 0) -- Começa fora da tela
        MainFrame.Parent = Container
        
        -- Blur background (apenas visual, não afeta tamanho)
        local BlurBackground = CreateBlurBackground(MainFrame)
        if not BlurBackground:IsA("BlurEffect") then
            BlurBackground.Parent = MainFrame
            BlurBackground.ZIndex = -1
        end
        
        -- Container principal da notificação
        local NotificationContainer = Round2px()
        NotificationContainer.Size = UDim2.new(1, 0, 1, 0)
        NotificationContainer.Position = UDim2.new(0, 0, 0, 0)
        NotificationContainer.Parent = MainFrame
        
        -- Sombra
        local shadow = Shadow2px()
        shadow.Parent = NotificationContainer
        
        -- Borda sutil
        local Border = Image("http://www.roblox.com/asset/?id=5554236805")
        Border.ScaleType = Enum.ScaleType.Slice
        Border.SliceCenter = Rect.new(3, 3, 297, 297)
        Border.Size = UDim2.new(1, 2, 1, 2)
        Border.Position = UDim2.new(0, -1, 0, -1)
        Border.ImageColor3 = Color3.fromRGB(60, 60, 60)
        Border.ImageTransparency = 0.7
        Border.ZIndex = 2
        Border.Parent = NotificationContainer
        
        -- Conteúdo da notificação
        local contentPosition = 8
        
        if Title ~= "" then
            local titleLabel = TitleLabel(Title)
            titleLabel.Size = UDim2.new(1, -16, 0, 24)
            titleLabel.Position = UDim2.new(0, 8, 0, contentPosition)
            titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
            titleLabel.Parent = NotificationContainer
            contentPosition += 24 + 4
        end
        
        if Description ~= "" then
            local descLabel = DescriptionLabel(Description)
            descLabel.TextWrapped = true
            descLabel.Size = UDim2.new(1, -16, 1, -contentPosition - 8)
            descLabel.Position = UDim2.new(0, 8, 0, contentPosition)
            descLabel.TextYAlignment = Title ~= "" and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
            descLabel.Parent = NotificationContainer
        end
        
        -- Adicionar à lista de notificações
        table.insert(InstructionObjects, {MainFrame, 0, false})
        
        -- Iniciar fade out após o tempo especificado
        coroutine.wrap(FadeOutAfter)(MainFrame, Duration)
        
        return MainFrame
    end,
}
