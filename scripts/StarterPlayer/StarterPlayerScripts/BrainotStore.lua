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
-- STORE GUI (clean, matches main HUD)
-- ============================================================

local sg = Instance.new("ScreenGui")
sg.Name = "BrainotStoreUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = player.PlayerGui

local function corner(parent, r)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, r or 8)
	return c
end

local storePanel = Instance.new("Frame")
storePanel.Name = "StorePanel"
storePanel.Size = UDim2.new(0, 340, 0, 220)
storePanel.Position = UDim2.new(0.5, -170, 0.5, -110)
storePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
storePanel.BorderSizePixel = 0
storePanel.Visible = false
storePanel.Parent = sg
corner(storePanel, 10)
local panelStroke = Instance.new("UIStroke", storePanel)
panelStroke.Color = Color3.fromRGB(70, 70, 100)
panelStroke.Thickness = 1

-- Header
local storeHdr = Instance.new("Frame")
storeHdr.Size = UDim2.new(1, 0, 0, 44)
storeHdr.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
storeHdr.BorderSizePixel = 0
storeHdr.Parent = storePanel
corner(storeHdr, 10)

local storeTitle = Instance.new("TextLabel")
storeTitle.Size = UDim2.new(1, -55, 1, 0)
storeTitle.Position = UDim2.new(0, 12, 0, 0)
storeTitle.BackgroundTransparency = 1
storeTitle.Text = "STORE"
storeTitle.TextColor3 = Color3.fromRGB(200, 190, 160)
storeTitle.TextScaled = true
storeTitle.Font = Enum.Font.GothamBold
storeTitle.TextXAlignment = Enum.TextXAlignment.Left
storeTitle.Parent = storeHdr

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = storeHdr
corner(closeBtn, 6)

-- Upgrade card
local upgradeCard = Instance.new("Frame")
upgradeCard.Size = UDim2.new(1, -24, 0, 88)
upgradeCard.Position = UDim2.new(0, 12, 0, 56)
upgradeCard.BackgroundColor3 = Color3.fromRGB(28, 28, 48)
upgradeCard.BorderSizePixel = 0
upgradeCard.Parent = storePanel
corner(upgradeCard, 8)

local powerTitle = Instance.new("TextLabel")
powerTitle.Size = UDim2.new(0, 140, 0, 22)
powerTitle.Position = UDim2.new(0, 12, 0, 10)
powerTitle.BackgroundTransparency = 1
powerTitle.Text = "CLICK STRENGTH"
powerTitle.TextColor3 = Color3.fromRGB(160, 155, 180)
powerTitle.TextScaled = true
powerTitle.Font = Enum.Font.Gotham
powerTitle.TextXAlignment = Enum.TextXAlignment.Left
powerTitle.Parent = upgradeCard

local powerVal = Instance.new("TextLabel")
powerVal.Size = UDim2.new(0, 50, 0, 28)
powerVal.Position = UDim2.new(0, 12, 0, 36)
powerVal.BackgroundTransparency = 1
powerVal.Text = "1"
powerVal.TextColor3 = Color3.fromRGB(220, 210, 170)
powerVal.TextScaled = true
powerVal.Font = Enum.Font.GothamBold
powerVal.TextXAlignment = Enum.TextXAlignment.Left
powerVal.Parent = upgradeCard

local descLbl = Instance.new("TextLabel")
descLbl.Size = UDim2.new(0, 100, 0, 32)
descLbl.Position = UDim2.new(0, 65, 0, 34)
descLbl.BackgroundTransparency = 1
descLbl.Text = "slightly faster capture"
descLbl.TextColor3 = Color3.fromRGB(110, 110, 130)
descLbl.TextScaled = true
descLbl.Font = Enum.Font.Gotham
descLbl.TextXAlignment = Enum.TextXAlignment.Left
descLbl.Parent = upgradeCard

local buyBtn = Instance.new("TextButton")
buyBtn.Size = UDim2.new(0, 120, 0, 40)
buyBtn.Position = UDim2.new(1, -132, 0.5, -20)
buyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 70)
buyBtn.BorderSizePixel = 0
buyBtn.Text = "BUY $500"
buyBtn.TextColor3 = Color3.new(1, 1, 1)
buyBtn.TextScaled = true
buyBtn.Font = Enum.Font.GothamBold
buyBtn.Parent = upgradeCard
corner(buyBtn, 6)

local hintLbl = Instance.new("TextLabel")
hintLbl.Size = UDim2.new(1, -24, 0, 48)
hintLbl.Position = UDim2.new(0, 12, 0, 152)
hintLbl.BackgroundTransparency = 1
hintLbl.Text = "Walk up to the Store brick to open. Each upgrade makes captures slightly easier."
hintLbl.TextColor3 = Color3.fromRGB(90, 90, 110)
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
		buyBtn.BackgroundColor3 = Color3.fromRGB(60, 55, 55)
		buyBtn.TextColor3 = Color3.fromRGB(140, 130, 130)
	else
		buyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 70)
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
	end
end

local function openStore()
	if storeGuiVisible then return end
	storeGuiVisible = true
	storePanel.Visible = true
	storePanel.Position = UDim2.new(0.5, -170, 0.5, -80)
	TweenService:Create(storePanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -170, 0.5, -110)}):Play()
end

local function closeStore()
	if not storeGuiVisible then return end
	storeGuiVisible = false
	TweenService:Create(storePanel, TweenInfo.new(0.15), {Position = UDim2.new(0.5, -170, 0.5, -80)}):Play()
	task.delay(0.16, function()
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
	powerVal.Text = tostring(myClickStrength)
	updateCostDisplay()
end)

RE_UpdateMoney.OnClientEvent:Connect(function(amount)
	myMoney = amount
	updateCostDisplay()
end)

print("BrainotStore: Add a Part named 'Store' in workspace. Get close to open the store.")
