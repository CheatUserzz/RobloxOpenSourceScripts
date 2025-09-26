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
local function CreateBlurBackground()
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
    NewImage.ImageColor3 = Color3.fromRGB(25, 25, 25) -- Mais escuro para melhor contraste
    NewImage.ImageTransparency = 0.05 -- Leve transparência
    return NewImage
end

local function Shadow2px()
    local NewImage = Image("http://www.roblox.com/asset/?id=5761498316")
    NewImage.ScaleType = Enum.ScaleType.Slice
    NewImage.SliceCenter = Rect.new(17, 17, 283, 283)
    NewImage.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30)
    NewImage.Position = -UDim2.fromOffset(15, 15)
    NewImage.ImageColor3 = Color3.fromRGB(15, 15, 15) -- Shadow mais escura
    NewImage.ImageTransparency = 0.1
    return NewImage
end

local Padding = 12 -- Aumentado para melhor espaçamento
local DescriptionPadding = 12
local InstructionObjects = {}
local TweenTime = 0.8 -- Mais rápido
local TweenStyle = Enum.EasingStyle.Quint -- Mais suave
local TweenDirection = Enum.EasingDirection.Out

local LastTick = tick()

local function CalculateBounds(TableOfObjects)
    local TableOfObjects = typeof(TableOfObjects) == "table" and TableOfObjects or {}
    local X, Y = 0, 0
    for _, Object in next, TableOfObjects do
        X += Object.AbsoluteSize.X
        Y += Object.AbsoluteSize.Y
    end
    return {X = X, Y = Y, x = X, y = Y}
end

local CachedObjects = {}

local function Update()
    local DeltaTime = tick() - LastTick
    local PreviousObjects = {}
    for CurObj, Object in next, InstructionObjects do
        local Label, Delta, Done = Object[1], Object[2], Object[3]
        if (not Done) then
            if (Delta < TweenTime) then
                Object[2] = math.clamp(Delta + DeltaTime, 0, 1)
                Delta = Object[2]
            else
                Object[3] = true
            end
        end
        local NewValue = TweenService:GetValue(Delta, TweenStyle, TweenDirection)
        local CurrentPos = Label.Position
        local PreviousBounds = CalculateBounds(PreviousObjects)
        local TargetPos = UDim2.new(0, 0, 0, PreviousBounds.Y + (Padding * #PreviousObjects))
        Label.Position = CurrentPos:Lerp(TargetPos, NewValue)
        table.insert(PreviousObjects, Label)
    end
    CachedObjects = PreviousObjects
    LastTick = tick()
end

RunService:BindToRenderStep("UpdateList", 0, Update)

local TitleSettings = {
    Font = Enum.Font.GothamSemibold,
    Size = 15 -- Ligeiramente maior
}

local DescriptionSettings = {
    Font = Enum.Font.Gotham,
    Size = 13,
    LineHeight = 1.1 -- Melhor espaçamento entre linhas
}

local MaxWidth = (Container.AbsoluteSize.X - Padding - DescriptionPadding)

local function Label(Text, Font, Size, Button)
    local Label = Instance.new(string.format("Text%s", Button and "Button" or "Label"))
    Label.Text = Text
    Label.Font = Font
    Label.TextSize = Size
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.RichText = true
    Label.TextColor3 = Color3.fromRGB(240, 240, 240) -- Texto ligeiramente mais suave
    return Label
end

local function TitleLabel(Text)
    local label = Label(Text, TitleSettings.Font, TitleSettings.Size)
    label.TextColor3 = Color3.fromRGB(255, 255, 255) -- Titulo mais brilhante
    return label
end

local function DescriptionLabel(Text)
    local label = Label(Text, DescriptionSettings.Font, DescriptionSettings.Size)
    label.TextColor3 = Color3.fromRGB(220, 220, 220) -- Descrição mais suave
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
    TweenService:Create(Object, TweenInfo.new(0.3, TweenStyle, TweenDirection), { -- Animação mais longa
        [Prop] = 1
    }):Play()
end

local function SearchTableFor(Table, For)
    for _, v in next, Table do
        if (v == For) then
            return true
        end
    end
    return false
end

local function FindIndexByDependency(Table, Dependency)
    for Index, Object in next, Table do
        if (typeof(Object) == "table") then
            local Found = SearchTableFor(Object, Dependency)
            if (Found) then
                return Index
            end
        else
            if (Object == Dependency) then
                return Index
            end
        end
    end
end

local function ResetObjects()
    for _, Object in next, InstructionObjects do
        Object[2] = 0
        Object[3] = false
    end
end

local function FadeOutAfter(Object, Seconds)
    wait(Seconds)
    FadeProperty(Object)
    for _, SubObj in next, Object:GetDescendants() do
        FadeProperty(SubObj)
    end
    wait(0.3) -- Aumentado para combinar com a animação
    table.remove(InstructionObjects, FindIndexByDependency(InstructionObjects, Object))
    ResetObjects()
    Object:Destroy() -- Garantir que é removido
end

return {
    Notify = function(Properties)
        local Properties = typeof(Properties) == "table" and Properties or {}
        local Title = Properties.Title
        local Description = Properties.Description
        local Duration = Properties.Duration or 5
        if (Title) or (Description) then
            local Y = Title and 28 or 0 -- Ajustado para novo tamanho
            if (Description) then
                local TextSize = TextService:GetTextSize(Description, DescriptionSettings.Size, DescriptionSettings.Font, Vector2.new(MaxWidth, 0))
                Y += math.ceil(TextSize.Y / DescriptionSettings.Size) * (DescriptionSettings.Size * DescriptionSettings.LineHeight)
                Y += 10 -- Mais espaçamento
            end
            
            local MainFrame = Instance.new("Frame")
            MainFrame.BackgroundTransparency = 1
            MainFrame.Size = UDim2.new(1, 0, 0, Y)
            MainFrame.Position = UDim2.new(-1, 20, 0, CalculateBounds(CachedObjects).Y + (Padding * #CachedObjects))
            MainFrame.Parent = Container
            
            -- Adicionar blur background
            local BlurBackground = CreateBlurBackground()
            if BlurBackground:IsA("BlurEffect") then
                BlurBackground.Parent = game:GetService("Lighting")
                -- Remover blur quando a notificação for destruída
                MainFrame.Destroying:Connect(function()
                    BlurBackground:Destroy()
                end)
            else
                BlurBackground.Parent = MainFrame
                BlurBackground.ZIndex = -1
            end
            
            local NewLabel = Round2px()
            NewLabel.Size = UDim2.new(1, 0, 1, 0)
            NewLabel.Position = UDim2.new(0, 0, 0, 0)
            NewLabel.Parent = MainFrame
            
            -- Adicionar borda sutil
            local Border = Image("http://www.roblox.com/asset/?id=5554236805")
            Border.ScaleType = Enum.ScaleType.Slice
            Border.SliceCenter = Rect.new(3, 3, 297, 297)
            Border.Size = UDim2.new(1, 2, 1, 2)
            Border.Position = UDim2.new(0, -1, 0, -1)
            Border.ImageColor3 = Color3.fromRGB(60, 60, 60)
            Border.ImageTransparency = 0.7
            Border.Parent = NewLabel
            
            if (Title) then
                local NewTitle = TitleLabel(Title)
                NewTitle.Size = UDim2.new(1, -12, 0, 28) -- Ajustado para novo padding
                NewTitle.Position = UDim2.fromOffset(12, 4) -- Mais espaçamento
                NewTitle.Parent = NewLabel
            end
            
            if (Description) then
                local NewDescription = DescriptionLabel(Description)
                NewDescription.TextWrapped = true
                NewDescription.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(-DescriptionPadding, Title and -32 or -8)
                NewDescription.Position = UDim2.fromOffset(12, Title and 28 or 8)
                NewDescription.TextYAlignment = Enum.TextYAlignment[Title and "Top" or "Center"]
                NewDescription.Parent = NewLabel
            end
            
            Shadow2px().Parent = NewLabel
            
            table.insert(InstructionObjects, {MainFrame, 0, false})
            coroutine.wrap(FadeOutAfter)(MainFrame, Duration)
        end
    end,
}
