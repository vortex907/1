-- BrainotStore.lua
-- Place in StarterPlayerScripts
-- Add a Part named "Store" in workspace - when player gets close, store GUI opens

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("BrainotRemotes")

local RE_BuyClickStrength  = Remotes:WaitForChild("BuyClickStrength")
local RE_SyncClickStrength = Remotes:WaitForChild("SyncClickStrength")
local RE_UpdateMoney       = Remotes:WaitForChild("UpdateMoney")

-- Config
local STORE_PART_NAME = "Store"
local PROXIMITY_RANGE = 14
local CHECK_INTERVAL  = 0.2

-- Pricing (must match server)
local CLICK_STRENGTH_BASE_COST = 500
local CLICK_STRENGTH_COST_MULT = 1.5

local myClickStrength = 1
local myMoney = 0
local nearStore = false
local storeGuiVisible = false

-- ============================================================
-- FIND STORE PART
-- ============================================================

local function findStorePart()
	local store = workspace:FindFirstChild(STORE_PART_NAME)
	if store then
		if store:IsA("BasePart") then return store end
		if store:IsA("Model") then
			return store.PrimaryPart or store:FindFirstChildWhichIsA("BasePart")
		end
	end
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name == STORE_PART_NAME then
			return desc
		end
	end
	return nil
end

-- ============================================================
-- GUI STYLING (brainrot style - bold, chunky, no emojis)
-- ============================================================

local sg = Instance.new("ScreenGui")
sg.Name = "BrainotStoreUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = player.PlayerGui

local function corner(parent, r)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, r or 12)
	return c
end

local function stroke(parent, color, thick)
	local s = Instance.new("UIStroke", parent)
	s.Color = color
	s.Thickness = thick or 3
	return s
end

-- ============================================================
-- STORE PANEL
-- ============================================================

local storePanel = Instance.new("Frame")
storePanel.Name = "StorePanel"
storePanel.Size = UDim2.new(0, 420, 0, 340)
storePanel.Position = UDim2.new(0.5, -210, 0.5, -170)
storePanel.BackgroundColor3 = Color3.fromRGB(12, 10, 28)
storePanel.BorderSizePixel = 0
storePanel.Visible = false
storePanel.Parent = sg
corner(storePanel, 16)
stroke(storePanel, Color3.fromRGB(255, 180, 50), 4)

-- Dark inner border
local innerGlow = Instance.new("UIStroke", storePanel)
innerGlow.Color = Color3.fromRGB(80, 60, 20)
innerGlow.Thickness = 1
innerGlow.Transparency = 0.5

-- Header
local storeHdr = Instance.new("Frame")
storeHdr.Size = UDim2.new(1, 0, 0, 56)
storeHdr.BackgroundColor3 = Color3.fromRGB(25, 18, 45)
storeHdr.BorderSizePixel = 0
storeHdr.Parent = storePanel
corner(storeHdr, 16)

local headerStripe = Instance.new("Frame")
headerStripe.Size = UDim2.new(1, 0, 0, 8)
headerStripe.Position = UDim2.new(0, 0, 0, 0)
headerStripe.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
headerStripe.BorderSizePixel = 0
headerStripe.Parent = storeHdr
corner(headerStripe, 16)

local storeTitle = Instance.new("TextLabel")
storeTitle.Size = UDim2.new(1, -20, 1, -12)
storeTitle.Position = UDim2.new(0, 14, 0, 8)
storeTitle.BackgroundTransparency = 1
storeTitle.Text = "UPGRADES"
storeTitle.TextColor3 = Color3.fromRGB(255, 210, 80)
storeTitle.TextScaled = true
storeTitle.Font = Enum.Font.GothamBlack
storeTitle.TextXAlignment = Enum.TextXAlignment.Left
storeTitle.Parent = storeHdr

local savedBadge = Instance.new("TextLabel")
savedBadge.Size = UDim2.new(0, 90, 0, 24)
savedBadge.Position = UDim2.new(1, -100, 0, 16)
savedBadge.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
savedBadge.BorderSizePixel = 0
savedBadge.Text = "SAVED"
savedBadge.TextColor3 = Color3.fromRGB(100, 255, 140)
savedBadge.TextScaled = true
savedBadge.Font = Enum.Font.GothamBold
savedBadge.Parent = storeHdr
corner(savedBadge, 6)
stroke(savedBadge, Color3.fromRGB(60, 180, 80), 1)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -48, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.Parent = storeHdr
corner(closeBtn, 8)

-- Click Strength upgrade card
local upgradeCard = Instance.new("Frame")
upgradeCard.Size = UDim2.new(1, -24, 0, 110)
upgradeCard.Position = UDim2.new(0, 12, 0, 68)
upgradeCard.BackgroundColor3 = Color3.fromRGB(18, 15, 38)
upgradeCard.BorderSizePixel = 0
upgradeCard.Parent = storePanel
corner(upgradeCard, 12)
stroke(upgradeCard, Color3.fromRGB(120, 100, 200), 2)

local cardStripe = Instance.new("Frame")
cardStripe.Size = UDim2.new(1, 0, 0, 6)
cardStripe.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
cardStripe.BorderSizePixel = 0
cardStripe.Parent = upgradeCard
corner(cardStripe, 12)

local powerTitle = Instance.new("TextLabel")
powerTitle.Size = UDim2.new(1, -20, 0, 28)
powerTitle.Position = UDim2.new(0, 12, 0, 12)
powerTitle.BackgroundTransparency = 1
powerTitle.Text = "CLICK STRENGTH"
powerTitle.TextColor3 = Color3.fromRGB(200, 170, 255)
powerTitle.TextScaled = true
powerTitle.Font = Enum.Font.GothamBold
powerTitle.TextXAlignment = Enum.TextXAlignment.Left
powerTitle.Parent = upgradeCard

local powerVal = Instance.new("TextLabel")
powerVal.Size = UDim2.new(0, 120, 0, 26)
powerVal.Position = UDim2.new(0, 12, 0, 42)
powerVal.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
powerVal.BorderSizePixel = 0
powerVal.Text = "Power: 1"
powerVal.TextColor3 = Color3.fromRGB(255, 220, 100)
powerVal.TextScaled = true
powerVal.Font = Enum.Font.GothamBold
powerVal.Parent = upgradeCard
corner(powerVal, 6)
stroke(powerVal, Color3.fromRGB(255, 180, 50), 1)

local buyBtn = Instance.new("TextButton")
buyBtn.Size = UDim2.new(0, 160, 0, 44)
buyBtn.Position = UDim2.new(1, -172, 0.5, -22)
buyBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
buyBtn.BorderSizePixel = 0
buyBtn.Text = "BUY $500"
buyBtn.TextColor3 = Color3.new(1, 1, 1)
buyBtn.TextScaled = true
buyBtn.Font = Enum.Font.GothamBlack
buyBtn.Parent = upgradeCard
corner(buyBtn, 10)
stroke(buyBtn, Color3.fromRGB(80, 255, 120), 2)

local hintLbl = Instance.new("TextLabel")
hintLbl.Size = UDim2.new(1, -24, 0, 36)
hintLbl.Position = UDim2.new(0, 12, 0, 190)
hintLbl.BackgroundTransparency = 1
hintLbl.Text = "Each click in capture counts for more. Get closer to the Store brick to open."
hintLbl.TextColor3 = Color3.fromRGB(120, 110, 150)
hintLbl.TextScaled = true
hintLbl.Font = Enum.Font.Gotham
hintLbl.TextWrapped = true
hintLbl.TextXAlignment = Enum.TextXAlignment.Left
hintLbl.TextYAlignment = Enum.TextYAlignment.Top
hintLbl.Parent = storePanel

-- ============================================================
-- PROXIMITY DETECTION
-- ============================================================

local function updateCostDisplay()
	local cost = math.floor(CLICK_STRENGTH_BASE_COST * (CLICK_STRENGTH_COST_MULT ^ (myClickStrength - 1)))
	buyBtn.Text = "BUY $" .. cost
	if myMoney < cost then
		buyBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 50)
		buyBtn.TextColor3 = Color3.fromRGB(180, 140, 140)
	else
		buyBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
	end
end

local function openStore()
	if storeGuiVisible then return end
	storeGuiVisible = true
	storePanel.Visible = true
	storePanel.Position = UDim2.new(0.5, -210, 0.5, -120)
	TweenService:Create(storePanel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -210, 0.5, -170)}):Play()
end

local function closeStore()
	if not storeGuiVisible then return end
	storeGuiVisible = false
	TweenService:Create(storePanel, TweenInfo.new(0.15), {Position = UDim2.new(0.5, -210, 0.5, -120)}):Play()
	task.delay(0.18, function()
		storePanel.Visible = false
	end)
end

task.spawn(function()
	while true do
		task.wait(CHECK_INTERVAL)
		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local storePart = findStorePart()
		if not storePart then continue end

		local dist = (root.Position - storePart.Position).Magnitude
		local wasNear = nearStore
		nearStore = dist <= PROXIMITY_RANGE

		if nearStore and not wasNear then
			openStore()
		elseif not nearStore and wasNear then
			closeStore()
		end
	end
end)

-- ============================================================
-- EVENTS
-- ============================================================

closeBtn.MouseButton1Click:Connect(closeStore)

buyBtn.MouseButton1Click:Connect(function()
	local cost = math.floor(CLICK_STRENGTH_BASE_COST * (CLICK_STRENGTH_COST_MULT ^ (myClickStrength - 1)))
	if myMoney < cost then return end
	RE_BuyClickStrength:FireServer()
end)

RE_SyncClickStrength.OnClientEvent:Connect(function(level)
	myClickStrength = math.max(1, level or 1)
	powerVal.Text = "Power: " .. myClickStrength
	updateCostDisplay()
end)

RE_UpdateMoney.OnClientEvent:Connect(function(amount)
	myMoney = amount
	updateCostDisplay()
end)

print("BrainotStore: Add a Part named 'Store' in workspace. Get close to open the store.")
