-- Choimin Hub Ultimate V10: Auto-Exec Installer & Dual DB Structure
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- 1. 지정된 외부 스크립트(auto.lua) 자동 실행 등록 (Auto-Exec)
----------------------------------------------------------------
local TARGET_AUTO_URL = "https://raw.githubusercontent.com/UNTITLED-HUB/UNTITLED-HUB/main/auto.lua"
local AUTO_EXEC_SCRIPT = string.format([[
pcall(function()
    loadstring(game:HttpGet("%s"))()
end)
]], TARGET_AUTO_URL)

-- (1) Executor autoexec 폴더에 파일 저장 (게임 접속 시 자동 실행)
pcall(function()
    if writefile then
        writefile("autoexec/UntitledHub_AutoExec.lua", AUTO_EXEC_SCRIPT)
    end
end)

-- (2) 게임 내 텔레포트/서버 이동 시 자동 실행 등록
local queue_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (Fluxus and Fluxus.queue_on_teleport)
if queue_teleport then
    pcall(function()
        queue_teleport(AUTO_EXEC_SCRIPT)
    end)
end

-- (3) 등록 완료 시스템 알림
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "CHOIMIN HUB",
        Text = "auto.lua 자동 실행 등록 완료!",
        Duration = 3
    })
end)

----------------------------------------------------------------
-- 2. 끝말잇기 핵심 로직 (자동 실행 X / 직접 실행 시에만 동작)
----------------------------------------------------------------
local SETTINGS = { AutoFarm = false, AutoWord = false, TypingSpeed = 0.3 }
local wordDB = nil
local usedWords = {}
local currentRoundWords = 0
local lastTargetTime = os.clock()

local CAT_NAMES = {
    normal = "📜 기본 (NORMAL)",
    always = "★ 추천 (ALWAYS)",
    attack = "⚔ 공격 (ATTACK)"
}

local DUUM_MAP = {
    ["녀"]="여", ["녁"]="역", ["년"]="연", ["념"]="염", ["닙"]="입", ["닢"]="잎",
    ["뉴"]="유", ["뇨"]="요", ["니"]="이",
    ["라"]="나", ["락"]="낙", ["란"]="난", ["람"]="남", ["랍"]="납", ["랑"]="낭",
    ["래"]="내", ["랭"]="냉", ["렝"]="냉", ["로"]="노", ["록"]="녹", ["론"]="논",
    ["롱"]="농", ["뢰"]="뇌", ["루"]="누", ["르"]="느", ["름"]="음", ["릉"]="능",
    ["려"]="여", ["력"]="역", ["련"]="연", ["렬"]="열", ["렴"]="염", ["렵"]="엽",
    ["령"]="영", ["례"]="예", ["료"]="요", ["룡"]="용", ["류"]="유", ["륙"]="육",
    ["륜"]="윤", ["률"]="율", ["륭"]="융", ["리"]="이", ["린"]="인", ["림"]="임",
    ["립"]="입", ["릿"]="잇", ["링"]="잉"
}

local THEME = {
    Background = Color3.fromRGB(20, 20, 26),
    Header = Color3.fromRGB(26, 27, 36),
    Card = Color3.fromRGB(28, 30, 40),
    Accent = Color3.fromRGB(99, 102, 241),
    ToggleOn = Color3.fromRGB(34, 197, 94),
    ToggleOff = Color3.fromRGB(60, 64, 80),
    Text = Color3.fromRGB(240, 242, 245),
    TextMuted = Color3.fromRGB(140, 145, 160),
    Border = Color3.fromRGB(42, 45, 60)
}

local function tween(object, info, properties)
    TweenService:Create(object, info, properties):Play()
end

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChoiminHubUI_V10"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Frame (250 x 230)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 230)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -115)
MainFrame.BackgroundColor3 = THEME.Background
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = THEME.Border
MainStroke.Thickness = 1

-- Header
local HeaderFrame = Instance.new("Frame", MainFrame)
HeaderFrame.Size = UDim2.new(1, 0, 0, 30)
HeaderFrame.BackgroundColor3 = THEME.Header
HeaderFrame.BorderSizePixel = 0

local HeaderPadding = Instance.new("UIPadding", HeaderFrame)
HeaderPadding.PaddingLeft = UDim.new(0, 10)
HeaderPadding.PaddingRight = UDim.new(0, 10)

local HeaderTitle = Instance.new("TextLabel", HeaderFrame)
HeaderTitle.Size = UDim2.new(1, -75, 1, 0)
HeaderTitle.Text = "CHOIMIN HUB"
HeaderTitle.TextColor3 = THEME.Text
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 11
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

local StatusBadge = Instance.new("TextLabel", HeaderFrame)
StatusBadge.Size = UDim2.new(0, 65, 0, 16)
StatusBadge.Position = UDim2.new(1, -65, 0.5, -8)
StatusBadge.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
StatusBadge.Text = "LOADING..."
StatusBadge.TextColor3 = Color3.new(0, 0, 0)
StatusBadge.Font = Enum.Font.GothamBold
StatusBadge.TextSize = 8
Instance.new("UICorner", StatusBadge).CornerRadius = UDim.new(0, 4)

-- Tabs
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -16, 0, 22)
TabContainer.Position = UDim2.new(0, 8, 0, 36)
TabContainer.BackgroundColor3 = THEME.Card
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 5)

local TabS = Instance.new("TextButton", TabContainer)
TabS.Size = UDim2.new(0.5, -2, 1, -2)
TabS.Position = UDim2.new(0, 1, 0, 1)
TabS.Text = "SETTINGS"
TabS.TextColor3 = THEME.Text
TabS.Font = Enum.Font.GothamBold
TabS.TextSize = 9
TabS.BackgroundColor3 = THEME.Background
TabS.AutoButtonColor = false
Instance.new("UICorner", TabS).CornerRadius = UDim.new(0, 4)

local TabD = Instance.new("TextButton", TabContainer)
TabD.Size = UDim2.new(0.5, -2, 1, -2)
TabD.Position = UDim2.new(0.5, 1, 0, 1)
TabD.Text = "DICTIONARY"
TabD.TextColor3 = THEME.TextMuted
TabD.Font = Enum.Font.GothamBold
TabD.TextSize = 9
TabD.BackgroundTransparency = 1
TabD.AutoButtonColor = false
Instance.new("UICorner", TabD).CornerRadius = UDim.new(0, 4)

-- Content Area
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -16, 1, -66)
Content.Position = UDim2.new(0, 8, 0, 62)
Content.BackgroundTransparency = 1

local SFrame = Instance.new("ScrollingFrame", Content)
SFrame.Size = UDim2.new(1, 0, 1, 0)
SFrame.BackgroundTransparency = 1
SFrame.BorderSizePixel = 0
SFrame.ScrollBarThickness = 3
SFrame.ScrollBarImageColor3 = THEME.Accent
SFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
SFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local DFrame = Instance.new("ScrollingFrame", Content)
DFrame.Size = UDim2.new(1, 0, 1, 0)
DFrame.BackgroundTransparency = 1
DFrame.BorderSizePixel = 0
DFrame.ScrollBarThickness = 3
DFrame.ScrollBarImageColor3 = THEME.Accent
DFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
DFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
DFrame.Visible = false

local SLayout = Instance.new("UIListLayout", SFrame)
SLayout.Padding = UDim.new(0, 6)

local DLayout = Instance.new("UIListLayout", DFrame)
DLayout.Padding = UDim.new(0, 5)

-- Component Creator
local function createToggle(name, parent)
    local key = name:gsub(" ", "")
    local Card = Instance.new("Frame", parent)
    Card.Size = UDim2.new(1, -4, 0, 28)
    Card.BackgroundColor3 = THEME.Card
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)
    
    local CardStroke = Instance.new("UIStroke", Card)
    CardStroke.Color = THEME.Border

    local Label = Instance.new("TextLabel", Card)
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.Text = name
    Label.TextColor3 = THEME.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1

    local SwitchBg = Instance.new("Frame", Card)
    SwitchBg.Size = UDim2.new(0, 28, 0, 14)
    SwitchBg.Position = UDim2.new(1, -34, 0.5, -7)
    SwitchBg.BackgroundColor3 = SETTINGS[key] and THEME.ToggleOn or THEME.ToggleOff
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)

    local SwitchKnob = Instance.new("Frame", SwitchBg)
    SwitchKnob.Size = UDim2.new(0, 10, 0, 10)
    SwitchKnob.Position = SETTINGS[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    SwitchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", SwitchKnob).CornerRadius = UDim.new(1, 0)

    local ClickBtn = Instance.new("TextButton", Card)
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""

    ClickBtn.MouseButton1Click:Connect(function()
        SETTINGS[key] = not SETTINGS[key]
        local isON = SETTINGS[key]
        tween(SwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = isON and THEME.ToggleOn or THEME.ToggleOff})
        tween(SwitchKnob, TweenInfo.new(0.15), {Position = isON and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)})
    end)
end

createToggle("Auto Farm", SFrame)
createToggle("Auto Word", SFrame)

-- Speed Box
local SpeedCard = Instance.new("Frame", SFrame)
SpeedCard.Size = UDim2.new(1, -4, 0, 28)
SpeedCard.BackgroundColor3 = THEME.Card
Instance.new("UICorner", SpeedCard).CornerRadius = UDim.new(0, 5)
local SpeedStroke = Instance.new("UIStroke", SpeedCard)
SpeedStroke.Color = THEME.Border

local SpeedLabel = Instance.new("TextLabel", SpeedCard)
SpeedLabel.Size = UDim2.new(0.5, 0, 1, 0)
SpeedLabel.Position = UDim2.new(0, 8, 0, 0)
SpeedLabel.Text = "Typing Speed"
SpeedLabel.TextColor3 = THEME.Text
SpeedLabel.Font = Enum.Font.GothamMedium
SpeedLabel.TextSize = 10
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.BackgroundTransparency = 1

local Speed = Instance.new("TextBox", SpeedCard)
Speed.Size = UDim2.new(0, 50, 0, 18)
Speed.Position = UDim2.new(1, -58, 0.5, -9)
Speed.PlaceholderText = "0.3"
Speed.Text = "0.3"
Speed.BackgroundColor3 = THEME.Header
Speed.TextColor3 = THEME.Accent
Speed.Font = Enum.Font.GothamBold
Speed.TextSize = 10
Instance.new("UICorner", Speed).CornerRadius = UDim.new(0, 4)
local InputStroke = Instance.new("UIStroke", Speed)
InputStroke.Color = THEME.Border

Speed:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(Speed.Text)
    if val then SETTINGS.TypingSpeed = math.max(0, val) end
end)

-- Search Box
local SearchBoxCard = Instance.new("Frame", DFrame)
SearchBoxCard.Size = UDim2.new(1, -4, 0, 24)
SearchBoxCard.BackgroundColor3 = THEME.Card
Instance.new("UICorner", SearchBoxCard).CornerRadius = UDim.new(0, 5)
local SearchStroke = Instance.new("UIStroke", SearchBoxCard)
SearchStroke.Color = THEME.Border

local Search = Instance.new("TextBox", SearchBoxCard)
Search.Size = UDim2.new(1, -16, 1, 0)
Search.Position = UDim2.new(0, 8, 0, 0)
Search.PlaceholderText = "시작 단어 검색 (예: 이)"
Search.Text = ""
Search.BackgroundTransparency = 1
Search.TextColor3 = THEME.Text
Search.PlaceholderColor3 = THEME.TextMuted
Search.Font = Enum.Font.Gotham
Search.TextSize = 10
Search.TextXAlignment = Enum.TextXAlignment.Left

-- Category Filter Buttons
local selectedFilter = "all"
local FilterFrame = Instance.new("Frame", DFrame)
FilterFrame.Size = UDim2.new(1, -4, 0, 20)
FilterFrame.BackgroundTransparency = 1

local FilterLayout = Instance.new("UIListLayout", FilterFrame)
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 4)

local filterBtns = {}
local renderDictionary

local function createFilterBtn(text, filterKey)
    local btn = Instance.new("TextButton", FilterFrame)
    btn.Size = UDim2.new(0.32, -2, 1, 0)
    btn.BackgroundColor3 = (selectedFilter == filterKey) and THEME.Accent or THEME.Card
    btn.Text = text
    btn.TextColor3 = THEME.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = THEME.Border

    filterBtns[filterKey] = btn

    btn.MouseButton1Click:Connect(function()
        selectedFilter = filterKey
        for k, b in pairs(filterBtns) do
            b.BackgroundColor3 = (k == filterKey) and THEME.Accent or THEME.Card
        end
        if renderDictionary then renderDictionary() end
    end)
end

createFilterBtn("전체", "all")
createFilterBtn("📜 기본", "normal")
createFilterBtn("⚔ 공격", "attack")

local List = Instance.new("Frame", DFrame)
List.Size = UDim2.new(1, -4, 0, 0)
List.BackgroundTransparency = 1
List.AutomaticSize = Enum.AutomaticSize.Y

-- Fetch Dictionary DB
local function fetchDB()
    local success, result = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/UNTITLED-HUB/kr_words/main/kr_words.json") end)
    if success and result then 
        wordDB = HttpService:JSONDecode(result)
        StatusBadge.Text = "READY"
        StatusBadge.BackgroundColor3 = THEME.ToggleOn
        StatusBadge.TextColor3 = Color3.new(1, 1, 1)
    else
        StatusBadge.Text = "ERROR"
        StatusBadge.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
        StatusBadge.TextColor3 = Color3.new(1, 1, 1)
    end
end

-- Tab Logic
TabS.MouseButton1Click:Connect(function() 
    SFrame.Visible = true 
    DFrame.Visible = false 
    tween(TabS, TweenInfo.new(0.15), {BackgroundTransparency = 0, TextColor3 = THEME.Text})
    tween(TabD, TweenInfo.new(0.15), {BackgroundTransparency = 1, TextColor3 = THEME.TextMuted})
end)

TabD.MouseButton1Click:Connect(function() 
    SFrame.Visible = false 
    DFrame.Visible = true 
    tween(TabD, TweenInfo.new(0.15), {BackgroundTransparency = 0, TextColor3 = THEME.Text})
    tween(TabS, TweenInfo.new(0.15), {BackgroundTransparency = 1, TextColor3 = THEME.TextMuted})
end)

-- Helper: Category-Aware Word Fetcher
local function getCategoryWords(catKey, query)
    local matchedWords = {}
    local catData = wordDB and wordDB[catKey]
    if not catData then return matchedWords end

    if catKey == "always" then
        for _, w in ipairs(catData) do
            if query == "" then
                table.insert(matchedWords, { word = w, isDuum = false })
            else
                if string.sub(w, 1, #query) == query then
                    table.insert(matchedWords, { word = w, isDuum = false })
                else
                    local firstChar = string.sub(w, 1, 3)
                    if DUUM_MAP[firstChar] == query then
                        table.insert(matchedWords, { word = w, isDuum = true })
                    end
                end
            end
        end
    else
        if query == "" then
            for letter, list in pairs(catData) do
                if type(list) == "table" then
                    for _, w in ipairs(list) do
                        table.insert(matchedWords, { word = w, isDuum = false })
                        if #matchedWords >= 50 then break end
                    end
                end
                if #matchedWords >= 50 then break end
            end
        else
            if catData[query] and type(catData[query]) == "table" then
                for _, w in ipairs(catData[query]) do
                    table.insert(matchedWords, { word = w, isDuum = false })
                end
            end
            for origLetter, duumLetter in pairs(DUUM_MAP) do
                if duumLetter == query and catData[origLetter] and type(catData[origLetter]) == "table" then
                    for _, w in ipairs(catData[origLetter]) do
                        table.insert(matchedWords, { word = w, isDuum = true })
                    end
                end
            end
        end
    end

    return matchedWords
end

-- Dictionary Renderer
renderDictionary = function()
    List:ClearAllChildren()
    local newLayout = Instance.new("UIListLayout", List)
    newLayout.Padding = UDim.new(0, 3)
    
    if not wordDB then return end
    local query = Search.Text:gsub("%s+", "")
    
    local filterCats = {}
    if selectedFilter == "all" then
        filterCats = {"normal", "always", "attack"}
    elseif selectedFilter == "normal" then
        filterCats = {"normal"}
    elseif selectedFilter == "attack" then
        filterCats = {"attack", "always"}
    end
    
    for _, catKey in ipairs(filterCats) do
        local matchedWords = getCategoryWords(catKey, query)
        
        if #matchedWords > 0 then
            table.sort(matchedWords, function(a, b)
                if a.isDuum ~= b.isDuum then return not a.isDuum end
                return a.word < b.word
            end)
            
            local h = Instance.new("TextLabel", List)
            local catDisplayName = CAT_NAMES[catKey] or catKey:upper()
            h.Text = string.format("%s (%d개)", catDisplayName, #matchedWords)
            h.Size = UDim2.new(1, 0, 0, 18)
            h.TextColor3 = THEME.Accent
            h.Font = Enum.Font.GothamBold
            h.TextSize = 9
            h.TextXAlignment = Enum.TextXAlignment.Left
            h.BackgroundTransparency = 1
            
            local displayLimit = (query == "") and 40 or #matchedWords
            for i = 1, math.min(#matchedWords, displayLimit) do
                local itemData = matchedWords[i]
                local Item = Instance.new("Frame", List)
                Item.Size = UDim2.new(1, 0, 0, 20)
                Item.BackgroundColor3 = THEME.Card
                Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 3)

                local l = Instance.new("TextLabel", Item)
                l.Text = itemData.isDuum and (itemData.word .. "  [두음]") or itemData.word
                l.Size = UDim2.new(1, -12, 1, 0)
                l.Position = UDim2.new(0, 6, 0, 0)
                l.TextColor3 = itemData.isDuum and THEME.TextMuted or THEME.Text
                l.Font = Enum.Font.Gotham
                l.TextSize = 9
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.BackgroundTransparency = 1
            end
        end
    end
end

Search:GetPropertyChangedSignal("Text"):Connect(renderDictionary)

-- Target Extraction
local function extractTargetLetter(text)
    if not text or text == "" then return nil end
    local letter = text:match("'(.-)'") or text:match("%[(.-)%]") or text:match('"(.-)"')
    if letter and letter ~= "" then return letter end
    
    for char in text:gmatch("[%z\1-\127\192-\247][%128-\191]*") do
        if #char >= 3 then return char end
    end
    return nil
end

-- Submit Word
local function submitWordToGame(tb, word)
    pcall(function()
        tb:CaptureFocus()
        task.wait(0.03)
        tb.Text = word
        task.wait(0.03)
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        
        task.wait(0.03)
        if tb:IsFocused() then tb:ReleaseFocus(true) end
    end)
end

-- Auto Word Loop Mechanism
local lastProcessedTarget = ""
local isTypingNow = false

local function processAutoWord()
    if not SETTINGS.AutoWord or not wordDB or isTypingNow then return end
    
    local gameGui = PlayerGui:FindFirstChild("GameGui") or PlayerGui:FindFirstChild("Gui")
    if not gameGui then return end
    
    local triesFrame = gameGui:FindFirstChild("TriesFrame", true)
    local tb = triesFrame and triesFrame:FindFirstChild("TextBox", true)
    if not tb or not tb:IsDescendantOf(game) then return end
    
    local rawText = tb.PlaceholderText
    local target = extractTargetLetter(rawText)
    
    if not target or target == "" then
        if os.clock() - lastTargetTime > 3 then
            currentRoundWords = 0
            usedWords = {}
            lastProcessedTarget = ""
        end
        return
    end
    
    lastTargetTime = os.clock()
    
    if target and target ~= "" and target ~= lastProcessedTarget then
        local cats
        if currentRoundWords == 0 then
            cats = {"normal", "always", "attack"}
        else
            cats = {"always", "attack", "normal"}
        end
        
        for _, cat in ipairs(cats) do
            local matchedWords = getCategoryWords(cat, target)
            
            for _, item in ipairs(matchedWords) do
                local w = item.word
                if not usedWords[w] then
                    isTypingNow = true
                    
                    if SETTINGS.TypingSpeed > 0 then
                        task.wait(SETTINGS.TypingSpeed)
                    end
                    
                    if SETTINGS.AutoWord and tb and tb.Parent then
                        local currentTarget = extractTargetLetter(tb.PlaceholderText)
                        if currentTarget == target then
                            submitWordToGame(tb, w)
                            usedWords[w] = true
                            lastProcessedTarget = target
                            currentRoundWords = currentRoundWords + 1
                        end
                    end
                    
                    isTypingNow = false
                    return
                end
            end
        end
    end
end

-- Auto Farm Loop
task.spawn(function()
    while task.wait(2) do
        if SETTINGS.AutoFarm then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if (obj:IsA("Seat") or obj:IsA("VehicleSeat")) and not obj.Occupant then
                        local dist = (obj.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < 50 then 
                            char.Humanoid:MoveTo(obj.Position)
                            if dist < 4 then obj:Sit(char.Humanoid) end 
                        end
                    end
                end
            end
        end
    end
end)

-- Polling Loop
task.spawn(function()
    fetchDB()
    renderDictionary()
    
    while task.wait(0.05) do
        if SETTINGS.AutoWord then
            pcall(processAutoWord)
        end
    end
end)
