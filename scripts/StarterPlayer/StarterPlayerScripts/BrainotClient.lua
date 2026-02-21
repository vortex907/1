-- BrainotClient.lua  (complete rewrite)
-- Place in StarterPlayerScripts

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("BrainotRemotes")

local RE_StartCapture    = Remotes:WaitForChild("StartCapture")
local RE_CaptureResult   = Remotes:WaitForChild("CaptureResult")
local RE_UpdateMoney     = Remotes:WaitForChild("UpdateMoney")
local RE_SyncInventory   = Remotes:WaitForChild("SyncInventory")
local RE_PlaceInBase     = Remotes:WaitForChild("PlaceInBase")
local RE_CaptureAttempt  = Remotes:WaitForChild("CaptureAttempt")
local RE_AssignBase      = Remotes:WaitForChild("AssignBase")
local RE_PlacementResult = Remotes:WaitForChild("PlacementResult")
local RE_SellBrainot     = Remotes:WaitForChild("SellBrainot")
local RE_SellFromBase    = Remotes:WaitForChild("SellFromBase")
local RE_StealRequest    = Remotes:WaitForChild("StealRequest")
local RE_StealResult     = Remotes:WaitForChild("StealResult")
local RE_SyncBase          = Remotes:WaitForChild("SyncBase")
local RE_RequestOtherBase  = Remotes:WaitForChild("RequestOtherBase")
local RE_SendOtherBase     = Remotes:WaitForChild("SendOtherBase")
local RE_SyncClickStrength = Remotes:WaitForChild("SyncClickStrength")

local MAX_BASE_SLOTS = 20
local BRAINOT_MONEY = {
	["Trippi Troppi"]=5,["Ballerina Cappuccina"]=6,["Cappucino Assasino"]=7,
	["Chimpanzini Bananini"]=5,["Trippi Troppi Troppa"]=8,["Odin Din Din Dun"]=6,
	["Br Br Patapim"]=5,["Boneca Ambalabu"]=7,["Tralalero Tralala"]=6,
	["Bombombini Gusini"]=8,["Trulimero Trulicina"]=9,["Svinina Bombardino"]=10,
	["Frigo Camelo"]=9,["Matteo"]=7,["La Vacca Saturno Saturnita"]=6,
	["Ta Ta Ta Ta Sahur"]=7,["Burbaloni Loliloli"]=8,["Pot Hotspot"]=6,
	["Bananita Dolphinita"]=9,["Giraffa Celestre"]=10,["Pipi Kiwi"]=5,
	["Orangutini Ananassini"]=8,["Ballerino Lololo"]=7,["Job Job Job Sahur"]=9,
	["Strawberry Elephant"]=10,["67 Letter"]=12,["Esok Sekolah"]=8,
	["Karkerkar Kurkur"]=9,["Crab Chef"]=11,["Gangster Footera"]=12,
}
local SELL_MULT  = { Normal=8,  Diamond=20, Golden=40  }
local TIER_MULT  = { Normal=1,  Diamond=3,  Golden=8   }
local TIER_COLOR = {
	Normal  = Color3.fromRGB(200,200,200),
	Diamond = Color3.fromRGB(100,220,255),
	Golden  = Color3.fromRGB(255,210,50),
}

local myBaseName       = nil
local activeCapture    = nil
local currentInventory = {}
local currentBase      = {}
local totalIncome      = 0
local placingCooldown  = false
local myClickStrength  = 1

-- ============================================================
-- ROOT GUI
-- ============================================================

local sg = Instance.new("ScreenGui")
sg.Name="BrainotUI"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=player.PlayerGui

local function corner(parent, r) local c=Instance.new("UICorner",parent); c.CornerRadius=UDim.new(0,r or 10); return c end
local function stroke(parent, color, thick) local s=Instance.new("UIStroke",parent); s.Color=color; s.Thickness=thick or 2; return s end
local function label(parent, text, size, font, color, xalign)
	local l=Instance.new("TextLabel"); l.Size=size; l.BackgroundTransparency=1
	l.Text=text; l.TextColor3=color or Color3.new(1,1,1); l.TextScaled=true
	l.Font=font or Enum.Font.Gotham; l.Parent=parent
	if xalign then l.TextXAlignment=xalign end
	return l
end

-- ============================================================
-- TOAST NOTIFICATIONS
-- ============================================================

local function toast(text, color)
	color = color or Color3.fromRGB(80,220,120)
	local f=Instance.new("Frame"); f.Size=UDim2.new(0,340,0,52)
	f.Position=UDim2.new(0.5,-170,1,10); f.BackgroundColor3=Color3.fromRGB(10,10,25)
	f.BorderSizePixel=0; f.Parent=sg; corner(f,10); stroke(f,color,2)
	local l2=label(f,text,UDim2.new(1,-16,1,0),Enum.Font.GothamBold,color)
	l2.Position=UDim2.new(0,10,0,0); l2.TextXAlignment=Enum.TextXAlignment.Left
	TweenService:Create(f,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Position=UDim2.new(0.5,-170,1,-62)}):Play()
	task.delay(2.8,function()
		TweenService:Create(f,TweenInfo.new(0.2),{Position=UDim2.new(0.5,-170,1,20)}):Play()
		task.delay(0.25,function() f:Destroy() end)
	end)
end

-- ============================================================
-- TOP STATS BAR (clean, minimal)
-- ============================================================

local statsBar=Instance.new("Frame")
statsBar.Size=UDim2.new(0,320,0,52)
statsBar.Position=UDim2.new(0.5,-160,0,14)
statsBar.BackgroundColor3=Color3.fromRGB(18,18,28)
statsBar.BorderSizePixel=0
statsBar.Parent=sg
corner(statsBar,8)
local statsStroke=Instance.new("UIStroke",statsBar)
statsStroke.Color=Color3.fromRGB(60,60,80)
statsStroke.Thickness=1

-- Money
local moneyFrame=Instance.new("Frame")
moneyFrame.Size=UDim2.new(0,155,0,38)
moneyFrame.Position=UDim2.new(0,8,0,7)
moneyFrame.BackgroundColor3=Color3.fromRGB(28,28,42)
moneyFrame.BorderSizePixel=0
moneyFrame.Parent=statsBar
corner(moneyFrame,6)
local moneyIcon=label(moneyFrame,"$",UDim2.new(0,28,1,0),Enum.Font.GothamBold,Color3.fromRGB(200,180,80))
local moneyAmt=label(moneyFrame,"0",UDim2.new(1,-36,1,0),Enum.Font.GothamBold,Color3.fromRGB(255,255,255),Enum.TextXAlignment.Left)
moneyAmt.Position=UDim2.new(0,30,0,0)
local incomeLabel=label(moneyFrame,"+0/5s",UDim2.new(1,-8,0.4,0),Enum.Font.Gotham,Color3.fromRGB(100,180,120),Enum.TextXAlignment.Right)
incomeLabel.Position=UDim2.new(0,4,0.55,0)

-- Power (saved)
local powerFrame=Instance.new("Frame")
powerFrame.Size=UDim2.new(0,140,0,38)
powerFrame.Position=UDim2.new(0,170,0,7)
powerFrame.BackgroundColor3=Color3.fromRGB(28,32,48)
powerFrame.BorderSizePixel=0
powerFrame.Parent=statsBar
corner(powerFrame,6)
local powerTitleLbl=label(powerFrame,"CLICK",UDim2.new(0,50,0.4,0),Enum.Font.Gotham,Color3.fromRGB(140,150,180),Enum.TextXAlignment.Left)
powerTitleLbl.Position=UDim2.new(0,8,0,2)
local powerValLbl=label(powerFrame,"1",UDim2.new(1,-50,1,0),Enum.Font.GothamBold,Color3.fromRGB(220,210,150),Enum.TextXAlignment.Right)
powerValLbl.Position=UDim2.new(0,0,0,0)
local savedLbl=label(powerFrame,"saved",UDim2.new(0,36,0,14),Enum.Font.Gotham,Color3.fromRGB(80,160,100))
savedLbl.Position=UDim2.new(0,8,0.5,0)

-- ============================================================
-- BASE HUD (top left)
-- ============================================================

local baseHud=Instance.new("Frame"); baseHud.Size=UDim2.new(0,210,0,46)
baseHud.Position=UDim2.new(0,12,0,12); baseHud.BackgroundColor3=Color3.fromRGB(8,8,20)
baseHud.BorderSizePixel=0; baseHud.Parent=sg; corner(baseHud,10); stroke(baseHud,Color3.fromRGB(255,210,50))

local baseHudLbl=label(baseHud,"Waiting for base...",UDim2.new(1,-10,1,0),Enum.Font.GothamBold,Color3.fromRGB(255,210,50),Enum.TextXAlignment.Left)
baseHudLbl.Position=UDim2.new(0,8,0,0)

-- ============================================================
-- SIDE BUTTONS
-- ============================================================

local function sideBtn(text, yPos, col)
	local b=Instance.new("TextButton"); b.Size=UDim2.new(0,130,0,44)
	b.Position=UDim2.new(0,12,0,yPos); b.BackgroundColor3=col or Color3.fromRGB(25,25,50)
	b.BorderSizePixel=0; b.Text=text; b.TextColor3=Color3.new(1,1,1)
	b.TextScaled=true; b.Font=Enum.Font.GothamBold; b.Parent=sg; corner(b,10); return b
end

local invBtn  = sideBtn("Inventory", 90,  Color3.fromRGB(25,25,50))
local baseBtn = sideBtn("My Base",   142, Color3.fromRGB(20,40,25))
stroke(invBtn, Color3.fromRGB(100,100,220)); stroke(baseBtn, Color3.fromRGB(60,180,80))

-- ============================================================
-- SHARED PANEL BUILDER
-- ============================================================

local function makePanel(title, strokeCol)
	local panel=Instance.new("Frame"); panel.Size=UDim2.new(0,370,0.78,0)
	panel.Position=UDim2.new(0,12,0.11,0); panel.BackgroundColor3=Color3.fromRGB(8,8,22)
	panel.BorderSizePixel=0; panel.Visible=false; panel.Parent=sg; corner(panel,14); stroke(panel,strokeCol,2)

	local hdr=Instance.new("Frame"); hdr.Size=UDim2.new(1,0,0,50); hdr.BackgroundColor3=Color3.fromRGB(16,16,42)
	hdr.BorderSizePixel=0; hdr.Parent=panel; corner(hdr,14)

	local titleLbl=label(hdr,title,UDim2.new(1,-50,1,0),Enum.Font.GothamBold,Color3.fromRGB(255,255,255),Enum.TextXAlignment.Left)
	titleLbl.Position=UDim2.new(0,14,0,0)

	local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,34,0,34)
	closeBtn.Position=UDim2.new(1,-40,0,8); closeBtn.BackgroundColor3=Color3.fromRGB(180,40,40)
	closeBtn.BorderSizePixel=0; closeBtn.Text="X"; closeBtn.TextColor3=Color3.new(1,1,1)
	closeBtn.TextScaled=true; closeBtn.Font=Enum.Font.GothamBold; closeBtn.Parent=panel; corner(closeBtn,8)
	closeBtn.MouseButton1Click:Connect(function() panel.Visible=false end)

	local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-14,1,-58)
	scroll.Position=UDim2.new(0,7,0,52); scroll.BackgroundTransparency=1
	scroll.BorderSizePixel=0; scroll.ScrollBarThickness=4; scroll.CanvasSize=UDim2.new(0,0,0,0)
	scroll.ScrollBarImageColor3=strokeCol; scroll.Parent=panel
	local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,6)
	layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=scroll

	return panel, hdr, titleLbl, scroll, layout
end

-- ============================================================
-- INVENTORY PANEL
-- ============================================================

local invPanel, invHdr, invTitleLbl, invScroll, invLayout = makePanel("Inventory", Color3.fromRGB(100,100,220))

local invCounter=label(invHdr,"0",UDim2.new(0,55,0.65,0),Enum.Font.GothamBold,Color3.fromRGB(180,180,255))
invCounter.Position=UDim2.new(1,-120,0.18,0); invCounter.BackgroundColor3=Color3.fromRGB(35,35,85)
invCounter.BackgroundTransparency=0; corner(invCounter,7)

local function sellPrice(name, tier)
	return (BRAINOT_MONEY[name] or 5) * (SELL_MULT[tier] or 8)
end
local function mpsVal(name, tier)
	return (BRAINOT_MONEY[name] or 5) * (TIER_MULT[tier] or 1)
end

local function buildRow(parent, layoutOrder, tierColor, nameText, tierText, leftBtnText, leftBtnColor, leftCb, rightBtnText, rightBtnColor, rightCb)
	local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,64); row.BackgroundColor3=Color3.fromRGB(14,14,34)
	row.BorderSizePixel=0; row.LayoutOrder=layoutOrder; row.Parent=parent; corner(row,8)
	local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,5,1,0); bar.BackgroundColor3=tierColor
	bar.BorderSizePixel=0; bar.Parent=row; corner(bar,4)
	local nl=label(row,nameText,UDim2.new(1,-230,0,26),Enum.Font.GothamBold,Color3.fromRGB(240,240,240),Enum.TextXAlignment.Left)
	nl.Position=UDim2.new(0,14,0,5)
	local tl=label(row,tierText,UDim2.new(1,-230,0,20),Enum.Font.GothamBold,tierColor,Enum.TextXAlignment.Left)
	tl.Position=UDim2.new(0,14,0,32)

	local function makeBtn(text, col, xOff, cb)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(0,100,0,36)
		b.Position=UDim2.new(1,xOff,0.5,-18); b.BackgroundColor3=col
		b.BorderSizePixel=0; b.Text=text; b.TextColor3=Color3.new(1,1,1)
		b.TextScaled=true; b.Font=Enum.Font.GothamBold; b.Parent=row; corner(b,8)
		b.MouseButton1Click:Connect(cb); return b
	end

	if leftBtnText  then makeBtn(leftBtnText,  leftBtnColor,  -215, leftCb)  end
	if rightBtnText then makeBtn(rightBtnText, rightBtnColor, -108, rightCb) end
	return row
end

local function buildInventoryUI(inv)
	currentInventory = inv
	for _,c in ipairs(invScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	invCounter.Text = #inv.."/"

	for i, item in ipairs(inv) do
		local tc   = TIER_COLOR[item.tier] or TIER_COLOR.Normal
		local sp   = sellPrice(item.name, item.tier)
		local mps  = mpsVal(item.name, item.tier)
		local sub  = item.tier:upper().."  |  +$"..mps.."/5s  |  Sell: $"..sp

		buildRow(invScroll, i, tc, item.name, sub,
			"Place Base", Color3.fromRGB(35,140,70), function()
				if placingCooldown then return end
				if not myBaseName then toast("No base assigned!",Color3.fromRGB(255,80,80)); return end
				if #currentBase >= MAX_BASE_SLOTS then toast("Base full! ("..MAX_BASE_SLOTS.." max)",Color3.fromRGB(255,80,80)); return end
				placingCooldown=true
				RE_PlaceInBase:FireServer(i)
				task.delay(1.5, function() placingCooldown=false end)
			end,
			"Sell $"..sp, Color3.fromRGB(180,120,20), function()
				RE_SellBrainot:FireServer(i)
			end
		)
	end
	invScroll.CanvasSize=UDim2.new(0,0,0,math.max(0,#inv*70-6))
end

-- ============================================================
-- BASE PANEL
-- ============================================================

local basePanel, baseHdrFrame, baseTitleLbl, baseScroll, baseScrollLayout = makePanel("My Base", Color3.fromRGB(60,180,80))

local baseCounter=label(baseHdrFrame,"0/20",UDim2.new(0,65,0.65,0),Enum.Font.GothamBold,Color3.fromRGB(130,255,150))
baseCounter.Position=UDim2.new(1,-130,0.18,0); baseCounter.BackgroundColor3=Color3.fromRGB(15,45,20)
baseCounter.BackgroundTransparency=0; corner(baseCounter,7)

local function buildBaseUI(placed)
	currentBase = placed
	baseCounter.Text = #placed.."/"..MAX_BASE_SLOTS
	baseCounter.TextColor3 = (#placed>=MAX_BASE_SLOTS) and Color3.fromRGB(255,80,80) or Color3.fromRGB(130,255,150)

	for _,c in ipairs(baseScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	if #placed == 0 then
		local empty=label(baseScroll,"No Brainots placed yet.\nOpen Inventory to place in Base",UDim2.new(1,0,0,80),Enum.Font.Gotham,Color3.fromRGB(120,120,160))
		empty.LayoutOrder=1; empty.Parent=baseScroll
		baseScroll.CanvasSize=UDim2.new(0,0,0,80); return
	end

	for i, item in ipairs(placed) do
		local tc   = TIER_COLOR[item.tier] or TIER_COLOR.Normal
		local sp   = sellPrice(item.name, item.tier)
		local mps  = mpsVal(item.name, item.tier)
		local sub  = item.tier:upper().."  |  +$"..mps.."/5s  |  Sell: $"..sp

		buildRow(baseScroll, i, tc, item.name, sub,
			nil, nil, nil,
			"Sell $"..sp, Color3.fromRGB(180,120,20), function()
				RE_SellFromBase:FireServer(i)
			end
		)
	end
	baseScroll.CanvasSize=UDim2.new(0,0,0,math.max(0,#placed*70-6))
end

-- ============================================================
-- OTHER PLAYERS' BASE VIEWER
-- ============================================================

local otherBasePanel = Instance.new("Frame")
otherBasePanel.Size=UDim2.new(0,370,0.78,0)
otherBasePanel.Position=UDim2.new(1,-382,0.11,0)
otherBasePanel.BackgroundColor3=Color3.fromRGB(20,8,8)
otherBasePanel.BorderSizePixel=0; otherBasePanel.Visible=false; otherBasePanel.Parent=sg
corner(otherBasePanel,14); stroke(otherBasePanel,Color3.fromRGB(220,60,60),2)

local obHdr=Instance.new("Frame"); obHdr.Size=UDim2.new(1,0,0,50)
obHdr.BackgroundColor3=Color3.fromRGB(40,14,14); obHdr.BorderSizePixel=0; obHdr.Parent=otherBasePanel; corner(obHdr,14)
local obTitle=label(obHdr,"Viewing Base",UDim2.new(1,-50,1,0),Enum.Font.GothamBold,Color3.fromRGB(255,120,120),Enum.TextXAlignment.Left)
obTitle.Position=UDim2.new(0,14,0,0)
local obClose=Instance.new("TextButton"); obClose.Size=UDim2.new(0,34,0,34)
obClose.Position=UDim2.new(1,-40,0,8); obClose.BackgroundColor3=Color3.fromRGB(180,40,40)
obClose.BorderSizePixel=0; obClose.Text="X"; obClose.TextColor3=Color3.new(1,1,1)
obClose.TextScaled=true; obClose.Font=Enum.Font.GothamBold; obClose.Parent=otherBasePanel; corner(obClose,8)
obClose.MouseButton1Click:Connect(function() otherBasePanel.Visible=false end)

local obScroll=Instance.new("ScrollingFrame"); obScroll.Size=UDim2.new(1,-14,1,-58)
obScroll.Position=UDim2.new(0,7,0,52); obScroll.BackgroundTransparency=1
obScroll.BorderSizePixel=0; obScroll.ScrollBarThickness=4; obScroll.CanvasSize=UDim2.new(0,0,0,0)
obScroll.ScrollBarImageColor3=Color3.fromRGB(220,60,60); obScroll.Parent=otherBasePanel
local obLayout=Instance.new("UIListLayout"); obLayout.Padding=UDim.new(0,6)
obLayout.SortOrder=Enum.SortOrder.LayoutOrder; obLayout.Parent=obScroll

local viewingPlayer = nil

local function viewOtherBase(targetPlayer, placed)
	viewingPlayer = targetPlayer
	obTitle.Text = targetPlayer.Name.."'s Base"
	for _,c in ipairs(obScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	if #placed == 0 then
		local e=label(obScroll,"This base is empty",UDim2.new(1,0,0,60),Enum.Font.Gotham,Color3.fromRGB(150,150,150))
		e.LayoutOrder=1; e.Parent=obScroll; obScroll.CanvasSize=UDim2.new(0,0,0,60)
		otherBasePanel.Visible=true; return
	end

	for i, item in ipairs(placed) do
		local tc  = TIER_COLOR[item.tier] or TIER_COLOR.Normal
		local mps = mpsVal(item.name, item.tier)
		local sub = item.tier:upper().."  |  +$"..mps.."/5s"

		buildRow(obScroll, i, tc, item.name, sub,
			nil, nil, nil,
			"Steal (R$)", Color3.fromRGB(180,30,30), function()
				local confirm = Instance.new("Frame")
				confirm.Size=UDim2.new(0,320,0,160); confirm.Position=UDim2.new(0.5,-160,0.5,-80)
				confirm.BackgroundColor3=Color3.fromRGB(15,8,8); confirm.BorderSizePixel=0; confirm.Parent=sg
				corner(confirm,12); stroke(confirm,Color3.fromRGB(255,60,60),2)
				local ql=Instance.new("TextLabel"); ql.Size=UDim2.new(1,-10,0,40); ql.Position=UDim2.new(0,5,0,10)
				ql.BackgroundTransparency=1; ql.Text="Steal "..item.name.."?"
				ql.TextColor3=Color3.fromRGB(255,80,80); ql.TextScaled=true; ql.Font=Enum.Font.GothamBold; ql.Parent=confirm
				local ql2=Instance.new("TextLabel"); ql2.Size=UDim2.new(1,-10,0,36); ql2.Position=UDim2.new(0,5,0,52)
				ql2.BackgroundTransparency=1; ql2.Text="This costs Robux. Confirm?"
				ql2.TextColor3=Color3.fromRGB(200,200,200); ql2.TextScaled=true; ql2.Font=Enum.Font.Gotham; ql2.Parent=confirm

				local yesBtn=Instance.new("TextButton"); yesBtn.Size=UDim2.new(0.44,0,0,42)
				yesBtn.Position=UDim2.new(0.04,0,1,-52); yesBtn.BackgroundColor3=Color3.fromRGB(200,40,40)
				yesBtn.BorderSizePixel=0; yesBtn.Text="Steal!"; yesBtn.TextColor3=Color3.new(1,1,1)
				yesBtn.TextScaled=true; yesBtn.Font=Enum.Font.GothamBold; yesBtn.Parent=confirm; corner(yesBtn,8)

				local noBtn=Instance.new("TextButton"); noBtn.Size=UDim2.new(0.44,0,0,42)
				noBtn.Position=UDim2.new(0.52,0,1,-52); noBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
				noBtn.BorderSizePixel=0; noBtn.Text="Cancel"; noBtn.TextColor3=Color3.new(1,1,1)
				noBtn.TextScaled=true; noBtn.Font=Enum.Font.GothamBold; noBtn.Parent=confirm; corner(noBtn,8)

				noBtn.MouseButton1Click:Connect(function() confirm:Destroy() end)
				yesBtn.MouseButton1Click:Connect(function()
					confirm:Destroy()
					RE_StealRequest:FireServer(targetPlayer, i)
				end)
			end
		)
	end
	obScroll.CanvasSize=UDim2.new(0,0,0,math.max(0,#placed*70-6))
	otherBasePanel.Visible=true
end

-- ============================================================
-- PROXIMITY DETECTOR
-- ============================================================

local nearbyBase      = nil
local nearbyBaseBill  = Instance.new("BillboardGui")
nearbyBaseBill.Size=UDim2.new(0,180,0,46); nearbyBaseBill.StudsOffset=Vector3.new(0,0,0)
nearbyBaseBill.AlwaysOnTop=true; nearbyBaseBill.MaxDistance=60; nearbyBaseBill.Enabled=false
nearbyBaseBill.Parent=sg

local nearByBaseBtn=Instance.new("TextButton"); nearByBaseBtn.Size=UDim2.new(1,0,1,0)
nearByBaseBtn.BackgroundColor3=Color3.fromRGB(180,30,30); nearByBaseBtn.BorderSizePixel=0
nearByBaseBtn.Text="View Base [F]"; nearByBaseBtn.TextColor3=Color3.new(1,1,1)
nearByBaseBtn.TextScaled=true; nearByBaseBtn.Font=Enum.Font.GothamBold
nearByBaseBtn.Parent=nearbyBaseBill; corner(nearByBaseBtn,8)

local basePromptAnchor=Instance.new("Part"); basePromptAnchor.Name="BasePromptAnchor"
basePromptAnchor.Size=Vector3.new(0.1,0.1,0.1); basePromptAnchor.Anchored=true
basePromptAnchor.CanCollide=false; basePromptAnchor.CanQuery=false; basePromptAnchor.CastShadow=false
basePromptAnchor.Transparency=1; basePromptAnchor.Position=Vector3.new(0,-9999,0)
basePromptAnchor.Parent=workspace
nearbyBaseBill.Adornee=basePromptAnchor; nearbyBaseBill.Parent=basePromptAnchor

task.spawn(function()
	while true do
		task.wait(0.3)
		local char=player.Character; if not char then continue end
		local root=char:FindFirstChild("HumanoidRootPart"); if not root then continue end

		local best, bestDist, bestOwner = nil, 30, nil
		for _,base in ipairs(workspace:GetChildren()) do
			if not base:IsA("Model") then continue end
			if not base.Name:match("^Base%d+$") then continue end
			local owner = base:GetAttribute("Owner")
			if not owner or owner == player.Name then continue end
			local ok, cf = pcall(function() return base:GetBoundingBox() end)
			if ok and cf then
				local d=(root.Position-cf.Position).Magnitude
				if d < bestDist then bestDist=d; best=base; bestOwner=owner end
			end
		end

		if best ~= nearbyBase then
			nearbyBase = best
			if best then
				local ok, cf = pcall(function() return best:GetBoundingBox() end)
				if ok and cf then
					basePromptAnchor.Position = cf.Position + Vector3.new(0,8,0)
					nearbyBaseBill.Enabled=true
					nearByBaseBtn.Text=bestOwner.."'s Base [F]"
				end
			else
				basePromptAnchor.Position=Vector3.new(0,-9999,0)
				nearbyBaseBill.Enabled=false
			end
		end
	end
end)

local function tryViewBase()
	if not nearbyBase then return end
	local ownerName = nearbyBase:GetAttribute("Owner")
	if not ownerName then return end
	local targetPlayer = Players:FindFirstChild(ownerName)
	if not targetPlayer then toast("Player offline",Color3.fromRGB(255,80,80)); return end
	RE_RequestOtherBase:FireServer(targetPlayer)
end

RE_SendOtherBase.OnClientEvent:Connect(function(targetPlayer, placed)
	if not targetPlayer or not placed then
		toast("Could not load base", Color3.fromRGB(255,80,80)); return
	end
	viewOtherBase(targetPlayer, placed)
end)

nearByBaseBtn.MouseButton1Click:Connect(tryViewBase)
UserInputService.InputBegan:Connect(function(input, _)
	if input.KeyCode == Enum.KeyCode.F then tryViewBase() end
end)

-- ============================================================
-- CAPTURE PROMPT
-- ============================================================

local currentTarget = nil

local captureAnchor=Instance.new("Part"); captureAnchor.Name="CapturePromptAnchor"
captureAnchor.Size=Vector3.new(0.1,0.1,0.1); captureAnchor.Anchored=true
captureAnchor.CanCollide=false; captureAnchor.CanQuery=false; captureAnchor.CastShadow=false
captureAnchor.Transparency=1; captureAnchor.Position=Vector3.new(0,-9999,0); captureAnchor.Parent=workspace

local capPromptBill=Instance.new("BillboardGui"); capPromptBill.Size=UDim2.new(0,200,0,80)
capPromptBill.StudsOffset=Vector3.new(0,0,0); capPromptBill.AlwaysOnTop=true
capPromptBill.MaxDistance=40; capPromptBill.Enabled=false
capPromptBill.Adornee=captureAnchor; capPromptBill.Parent=captureAnchor

local billTop=Instance.new("Frame",capPromptBill)
billTop.Size=UDim2.new(1,0,0,32); billTop.Position=UDim2.new(0,0,0,0)
billTop.BackgroundColor3=Color3.fromRGB(10,10,22); billTop.BorderSizePixel=0; corner(billTop,6)

local billName=Instance.new("TextLabel",billTop)
billName.Size=UDim2.new(1,-6,0.58,0); billName.Position=UDim2.new(0,4,0,1)
billName.BackgroundTransparency=1; billName.Text=""; billName.TextColor3=Color3.new(1,1,1)
billName.TextScaled=true; billName.Font=Enum.Font.GothamBold
billName.TextXAlignment=Enum.TextXAlignment.Left; billName.TextTruncate=Enum.TextTruncate.AtEnd

local billTier=Instance.new("TextLabel",billTop)
billTier.Size=UDim2.new(1,-6,0.38,0); billTier.Position=UDim2.new(0,4,0.6,0)
billTier.BackgroundTransparency=1; billTier.Text=""; billTier.TextScaled=true
billTier.Font=Enum.Font.GothamBold; billTier.TextXAlignment=Enum.TextXAlignment.Left

local capBtn=Instance.new("TextButton",capPromptBill)
capBtn.Size=UDim2.new(1,0,0,42); capBtn.Position=UDim2.new(0,0,0,36)
capBtn.BackgroundColor3=Color3.fromRGB(220,40,40); capBtn.BorderSizePixel=0
capBtn.Text="Capture [E]"; capBtn.TextColor3=Color3.new(1,1,1)
capBtn.TextScaled=true; capBtn.Font=Enum.Font.GothamBold; corner(capBtn,8)

local function getBrainotTop(model)
	local ok,cf,sz=pcall(function() return model:GetBoundingBox() end)
	if ok and cf then return cf.Position+Vector3.new(0,sz.Y/2+5,0) end
	local p=model:FindFirstChildOfClass("BasePart")
	return p and p.Position+Vector3.new(0,4,0) or Vector3.new(0,-9999,0)
end

local captureLocked   = false
local cooldownEndTime = 0

task.spawn(function()
	while true do
		task.wait(0.1)
		local char=player.Character; if not char then continue end
		local root=char:FindFirstChild("HumanoidRootPart"); if not root then continue end
		local best, bestD = nil, 18
		for _,obj in ipairs(workspace:GetChildren()) do
			if obj:GetAttribute("IsBrainot") then
				local ok,cf=pcall(function() return obj:GetBoundingBox() end)
				if ok and cf then
					local d=(root.Position-cf.Position).Magnitude
					if d<bestD then bestD=d; best=obj end
				end
			end
		end
		if best~=currentTarget then currentTarget=best end
		if currentTarget and currentTarget.Parent then
			captureAnchor.Position=getBrainotTop(currentTarget)
			capPromptBill.Enabled=true

			local bName = currentTarget:GetAttribute("DisplayName") or currentTarget.Name
			local bTier = currentTarget:GetAttribute("Tier") or "Normal"
			local tc    = TIER_COLOR[bTier] or TIER_COLOR.Normal
			billName.Text      = bName
			billTier.Text      = bTier:upper()
			billTier.TextColor3 = tc

			local lockedLabel = currentTarget:FindFirstChild("LockedLabel")
			if lockedLabel then
				capBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
				capBtn.Text = "In use: " .. lockedLabel.Value
			elseif captureLocked then
				local rem = math.max(0, cooldownEndTime - tick())
				capBtn.BackgroundColor3 = Color3.fromRGB(110,35,35)
				capBtn.Text = string.format("Cooldown: %.1fs", rem)
			else
				capBtn.BackgroundColor3 = Color3.fromRGB(220,40,40)
				capBtn.Text = "Capture [E]"
			end
		else
			captureAnchor.Position=Vector3.new(0,-9999,0)
			capPromptBill.Enabled=false; currentTarget=nil
		end
	end
end)

local function tryCapture()
	if not currentTarget or not currentTarget.Parent then return end
	if activeCapture then return end
	if captureLocked then toast("Wait for your cooldown!",Color3.fromRGB(255,80,80)); return end
	if currentTarget:FindFirstChild("LockedLabel") then
		toast("Someone else is catching that!",Color3.fromRGB(255,150,50)); return
	end
	RE_CaptureAttempt:FireServer(currentTarget)
end

capBtn.MouseButton1Click:Connect(tryCapture)
UserInputService.InputBegan:Connect(function(input, _)
	if input.KeyCode == Enum.KeyCode.E then tryCapture() end
end)

-- ============================================================
-- CAPTURE MINIGAME UI (with click strength)
-- ============================================================

local capFrame=Instance.new("Frame"); capFrame.Size=UDim2.new(0,440,0,310)
capFrame.Position=UDim2.new(0.5,-220,0.5,-155); capFrame.BackgroundColor3=Color3.fromRGB(8,8,20)
capFrame.BorderSizePixel=0; capFrame.Visible=false; capFrame.Parent=sg
corner(capFrame,16); local capStroke=stroke(capFrame,Color3.fromRGB(255,80,80),3)

local capHdr=Instance.new("Frame"); capHdr.Size=UDim2.new(1,0,0,48)
capHdr.BackgroundColor3=Color3.fromRGB(30,8,8); capHdr.BorderSizePixel=0; capHdr.Parent=capFrame; corner(capHdr,16)
label(capHdr,"CAPTURE BATTLE",UDim2.new(1,0,1,0),Enum.Font.GothamBold,Color3.fromRGB(255,80,80))

local capName=Instance.new("TextLabel"); capName.Size=UDim2.new(1,-20,0,30)
capName.Position=UDim2.new(0,10,0,52); capName.BackgroundTransparency=1
capName.TextScaled=true; capName.Font=Enum.Font.Gotham; capName.Parent=capFrame

local function makeBar(yPos, fillColor)
	local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,-20,0,26); bg.Position=UDim2.new(0,10,0,yPos)
	bg.BackgroundColor3=Color3.fromRGB(25,25,25); bg.BorderSizePixel=0; bg.Parent=capFrame; corner(bg,6)
	local fill=Instance.new("Frame"); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=fillColor
	fill.BorderSizePixel=0; fill.Parent=bg; corner(fill,6)
	return bg, fill
end
local _, youFill  = makeBar(88,  Color3.fromRGB(60,220,100))
local _, brtFill  = makeBar(120, Color3.fromRGB(255,60,60))

local youLbl=Instance.new("TextLabel"); youLbl.Size=UDim2.new(1,-20,0,26); youLbl.Position=UDim2.new(0,10,0,88)
youLbl.BackgroundTransparency=1; youLbl.Text="YOU"; youLbl.TextColor3=Color3.new(1,1,1); youLbl.TextScaled=true
youLbl.Font=Enum.Font.GothamBold; youLbl.Parent=capFrame
local brtLbl=Instance.new("TextLabel"); brtLbl.Size=UDim2.new(1,-20,0,26); brtLbl.Position=UDim2.new(0,10,0,120)
brtLbl.BackgroundTransparency=1; brtLbl.Text="BRAINOT"; brtLbl.TextColor3=Color3.new(1,1,1); brtLbl.TextScaled=true
brtLbl.Font=Enum.Font.GothamBold; brtLbl.Parent=capFrame

local clickConn = nil

local clickBtn=Instance.new("TextButton"); clickBtn.Size=UDim2.new(0,220,0,70)
clickBtn.Position=UDim2.new(0.5,-110,0,162); clickBtn.BackgroundColor3=Color3.fromRGB(40,120,220)
clickBtn.BorderSizePixel=0; clickBtn.Text="CLICK!"; clickBtn.TextColor3=Color3.new(1,1,1)
clickBtn.TextScaled=true; clickBtn.Font=Enum.Font.GothamBold; clickBtn.Parent=capFrame; corner(clickBtn,14)
stroke(clickBtn,Color3.fromRGB(100,180,255),2)

local timerLbl=Instance.new("TextLabel"); timerLbl.Size=UDim2.new(1,0,0,28); timerLbl.Position=UDim2.new(0,0,0,238)
timerLbl.BackgroundTransparency=1; timerLbl.TextScaled=true; timerLbl.Font=Enum.Font.Gotham
timerLbl.TextColor3=Color3.fromRGB(180,180,180); timerLbl.Parent=capFrame

local resultLbl=Instance.new("TextLabel"); resultLbl.Size=UDim2.new(1,-20,0,44); resultLbl.Position=UDim2.new(0,10,0,262)
resultLbl.BackgroundTransparency=1; resultLbl.TextScaled=true; resultLbl.Font=Enum.Font.GothamBold; resultLbl.Parent=capFrame

local WIN_CLICKS=20; local GAME_DUR=5

local function pulseBtn()
	TweenService:Create(clickBtn,TweenInfo.new(0.06),{Size=UDim2.new(0,234,0,76),BackgroundColor3=Color3.fromRGB(70,160,255)}):Play()
	task.delay(0.06,function()
		TweenService:Create(clickBtn,TweenInfo.new(0.1),{Size=UDim2.new(0,220,0,70),BackgroundColor3=Color3.fromRGB(40,120,220)}):Play()
	end)
end

local function resetCapUI()
	capFrame.Visible=false; capStroke.Color=Color3.fromRGB(255,80,80); resultLbl.Text=""
	timerLbl.Text=""; youFill.Size=UDim2.new(0,0,1,0); brtFill.Size=UDim2.new(0,0,1,0)
	clickBtn.Visible=false
	if clickConn then clickConn:Disconnect(); clickConn=nil end
end

local function endCapture(won)
	if not activeCapture then return end
	local data=activeCapture; activeCapture=nil
	if clickConn then clickConn:Disconnect(); clickConn=nil end
	clickBtn.Visible=false
	if won then
		resultLbl.Text="CAPTURED! "..data.name.." is yours!"
		resultLbl.TextColor3=Color3.fromRGB(60,220,100); capStroke.Color=Color3.fromRGB(60,220,100)
	else
		resultLbl.Text=data.name.." escaped!"
		resultLbl.TextColor3=Color3.fromRGB(255,80,80); capStroke.Color=Color3.fromRGB(255,80,80)
	end
	RE_CaptureResult:FireServer(data.modelRef, won)
	task.delay(2,function() resetCapUI() end)
end

RE_StartCapture.OnClientEvent:Connect(function(data)
	if not data then return end
	if activeCapture then resetCapUI() end
	activeCapture=data; capFrame.Visible=true; clickBtn.Visible=true; resultLbl.Text=""; timerLbl.Text=""
	capName.Text=data.name.."  ["..data.tier:upper().."]"
	capName.TextColor3=TIER_COLOR[data.tier] or Color3.new(1,1,1)
	capStroke.Color=TIER_COLOR[data.tier] or Color3.fromRGB(255,80,80)

	-- Each upgrade adds only 6% more per click (level 7 = 1.36, not 7)
	local rawLevel = math.max(1, data.clickStrength or 1)
	local addPerClick = 1 + (rawLevel - 1) * 0.06
	local pc=0; local finished=false; local t0=tick()
	local heartConn; heartConn=RunService.Heartbeat:Connect(function()
		if activeCapture~=data then heartConn:Disconnect(); return end
		local el=tick()-t0; local tl=math.max(0,GAME_DUR-el)
		timerLbl.Text=string.format("%.1fs left",tl)
		local brtC=el*data.speed
		TweenService:Create(youFill,TweenInfo.new(0.05),{Size=UDim2.new(math.clamp(pc/WIN_CLICKS,0,1),0,1,0)}):Play()
		TweenService:Create(brtFill,TweenInfo.new(0.05),{Size=UDim2.new(math.clamp(brtC/WIN_CLICKS,0,1),0,1,0)}):Play()
		if pc>=WIN_CLICKS and not finished then finished=true; heartConn:Disconnect(); endCapture(true)
		elseif (brtC>=WIN_CLICKS or tl<=0) and not finished then finished=true; heartConn:Disconnect(); endCapture(false) end
	end)
	if clickConn then clickConn:Disconnect() end
	clickConn=clickBtn.MouseButton1Click:Connect(function()
		if activeCapture~=data or finished then return end
		pc = pc + addPerClick
		pulseBtn()
	end)
end)

-- ============================================================
-- COOLDOWN SIGNAL FROM SERVER
-- ============================================================

local RE_CaptureLocked = Remotes:WaitForChild("CaptureLocked")
local cooldownTimerConn = nil

local cooldownBar=Instance.new("Frame"); cooldownBar.Size=UDim2.new(0,300,0,44)
cooldownBar.Position=UDim2.new(0.5,-150,0,84); cooldownBar.BackgroundColor3=Color3.fromRGB(30,5,5)
cooldownBar.BorderSizePixel=0; cooldownBar.Visible=false; cooldownBar.Parent=sg
corner(cooldownBar,8); stroke(cooldownBar,Color3.fromRGB(220,50,50),2)
local cooldownLbl=label(cooldownBar,"",UDim2.new(1,-16,1,0),Enum.Font.GothamBold,Color3.fromRGB(255,80,80),Enum.TextXAlignment.Left)
cooldownLbl.Position=UDim2.new(0,10,0,0)

RE_CaptureLocked.OnClientEvent:Connect(function(seconds)
	if cooldownTimerConn then cooldownTimerConn:Disconnect(); cooldownTimerConn=nil end
	if seconds and seconds > 0 then
		captureLocked=true; cooldownEndTime=tick()+seconds; cooldownBar.Visible=true
		local endTime=tick()+seconds
		cooldownTimerConn=RunService.Heartbeat:Connect(function()
			local rem=endTime-tick()
			if rem<=0 then
				cooldownTimerConn:Disconnect(); cooldownTimerConn=nil
				captureLocked=false; cooldownEndTime=0; cooldownBar.Visible=false; cooldownLbl.Text=""
			else
				cooldownLbl.Text=string.format("Cooldown: %.1fs", rem)
			end
		end)
	else
		captureLocked=false; cooldownEndTime=0; cooldownBar.Visible=false; cooldownLbl.Text=""
		if activeCapture then
			activeCapture=nil
			if clickConn then clickConn:Disconnect(); clickConn=nil end
			resultLbl.Text="Brainot escaped!"; resultLbl.TextColor3=Color3.fromRGB(255,80,80)
			task.delay(1.5,function() resetCapUI() end)
		end
	end
end)

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================

RE_AssignBase.OnClientEvent:Connect(function(baseName)
	myBaseName=baseName
	baseHudLbl.Text=baseName.." (Your Base)"
	toast("Base assigned: "..baseName, Color3.fromRGB(255,210,50))
end)

RE_UpdateMoney.OnClientEvent:Connect(function(amount)
	moneyAmt.Text=tostring(amount)
	if totalIncome>0 then incomeLabel.Text="+"..totalIncome.."/5s" end
	TweenService:Create(statsBar,TweenInfo.new(0.1),{Size=UDim2.new(0,335,0,58)}):Play()
	task.delay(0.12,function() TweenService:Create(statsBar,TweenInfo.new(0.1),{Size=UDim2.new(0,320,0,52)}):Play() end)
end)

RE_SyncClickStrength.OnClientEvent:Connect(function(level)
	myClickStrength=math.max(1,level or 1)
	powerValLbl.Text=tostring(myClickStrength)
end)

RE_SyncInventory.OnClientEvent:Connect(function(inv)
	buildInventoryUI(inv)
end)

RE_SyncBase.OnClientEvent:Connect(function(placed)
	buildBaseUI(placed)
	totalIncome=0
	for _,item in ipairs(placed) do totalIncome+=mpsVal(item.name,item.tier) end
	incomeLabel.Text=totalIncome>0 and ("+"..totalIncome.."/5s") or "place to earn"
end)

RE_PlacementResult.OnClientEvent:Connect(function(success, msg, mps)
	placingCooldown=false
	if success and mps and mps>0 then
		totalIncome+=mps; incomeLabel.Text="+"..totalIncome.."/5s from base"
		toast(msg.." placed!  +$"..mps.."/5s", Color3.fromRGB(80,220,120))
	elseif success then
		toast(msg, Color3.fromRGB(80,220,120))
	else
		toast("Error: "..tostring(msg), Color3.fromRGB(255,80,80))
	end
end)

RE_StealResult.OnClientEvent:Connect(function(success, name, tier)
	if success then
		toast("Stole "..name.."! ("..tostring(tier)..")", Color3.fromRGB(255,80,80))
	else
		toast("Steal failed: "..tostring(name), Color3.fromRGB(255,150,50))
	end
end)

-- ============================================================
-- BUTTON TOGGLES
-- ============================================================

local function slideIn(panel)
	panel.Visible=true
	panel.Position=UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset, panel.Position.Y.Scale, panel.Position.Y.Offset+20)
	TweenService:Create(panel,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Position=UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset, 0.11, 0)}):Play()
end

invBtn.MouseButton1Click:Connect(function()
	if invPanel.Visible then invPanel.Visible=false
	else basePanel.Visible=false; slideIn(invPanel) end
end)

baseBtn.MouseButton1Click:Connect(function()
	if basePanel.Visible then basePanel.Visible=false
	else invPanel.Visible=false; slideIn(basePanel) end
end)
