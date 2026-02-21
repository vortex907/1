-- BrainotServer.lua  (complete rewrite)
-- Place in ServerScriptService

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local DataStore = DataStoreService:GetDataStore("BrainotData_v4")

-- ============================================================
-- CONSTANTS
-- ============================================================

local MAX_BASE_SLOTS  = 20   -- max brainots in base at once
local STEAL_PRODUCT_ID = 1234567890  -- REPLACE with your real Robux product ID

local BRAINOT_MONEY = {
	["Trippi Troppi"]              = 5,  ["Ballerina Cappuccina"]       = 6,
	["Cappucino Assasino"]         = 7,  ["Chimpanzini Bananini"]       = 5,
	["Trippi Troppi Troppa"]       = 8,  ["Odin Din Din Dun"]           = 6,
	["Br Br Patapim"]              = 5,  ["Boneca Ambalabu"]            = 7,
	["Tralalero Tralala"]          = 6,  ["Bombombini Gusini"]          = 8,
	["Trulimero Trulicina"]        = 9,  ["Svinina Bombardino"]         = 10,
	["Frigo Camelo"]               = 9,  ["Matteo"]                     = 7,
	["La Vacca Saturno Saturnita"] = 6,  ["Ta Ta Ta Ta Sahur"]          = 7,
	["Burbaloni Loliloli"]         = 8,  ["Pot Hotspot"]                = 6,
	["Bananita Dolphinita"]        = 9,  ["Giraffa Celestre"]           = 10,
	["Pipi Kiwi"]                  = 5,  ["Orangutini Ananassini"]      = 8,
	["Ballerino Lololo"]           = 7,  ["Job Job Job Sahur"]          = 9,
	["Strawberry Elephant"]        = 10, ["67 Letter"]                  = 12,
	["Esok Sekolah"]               = 8,  ["Karkerkar Kurkur"]           = 9,
	["Crab Chef"]                  = 11, ["Gangster Footera"]           = 12,
}

-- Sell price = base money * multiplier (cheap, about 5-10x the per-5s income)
local SELL_MULTIPLIER = { Normal = 8, Diamond = 20, Golden = 40 }
local TIER_MULTIPLIER = { Normal = 1, Diamond = 3,  Golden = 8  }
local CAPTURE_SPEED   = { Normal = 3, Diamond = 6,  Golden = 10 }

local TIER_COLORS_3D = {
	Normal  = Color3.fromRGB(200, 200, 200),
	Diamond = Color3.fromRGB(100, 220, 255),
	Golden  = Color3.fromRGB(255, 210, 50),
}

local ANIM_IDS = {
	["Giraffa Celestre"]           = { idle="rbxassetid://138080995344320", walk="rbxassetid://138958477587752" },
	["Orangutini Ananassini"]      = { idle="rbxassetid://83909970132395",  walk="rbxassetid://103111631820478" },
	["Ballerino Lololo"]           = { idle="rbxassetid://88823389910194",  walk="rbxassetid://86584835104754"  },
	["Job Job Job Sahur"]          = { idle="rbxassetid://101085892659863", walk="rbxassetid://111731625834133" },
	["Strawberry Elephant"]        = { idle="rbxassetid://138045506635619", walk="rbxassetid://77284429502743"  },
	["67 Letter"]                  = { idle="rbxassetid://114161754788842", walk="rbxassetid://123113690232576" },
	["Esok Sekolah"]               = { idle="rbxassetid://127685523578911", walk="rbxassetid://86850563981162"  },
	["Crab Chef"]                  = { idle="rbxassetid://139149962251661", walk="rbxassetid://77949944628002"  },
	["Gangster Footera"]           = { idle="rbxassetid://116439464277611", walk="rbxassetid://124624542225382" },
	["Karkerkar Kurkur"]           = { walk="rbxassetid://101598174725339", idle="rbxassetid://100022719315324" },
	["Bananita Dolphinita"]        = { walk="rbxassetid://118312907634608", idle="rbxassetid://120898443916200" },
	["Pot Hotspot"]                = { walk="rbxassetid://91204998521329",  idle="rbxassetid://127799277745634" },
	["Burbaloni Loliloli"]         = { walk="rbxassetid://97992150291572",  idle="rbxassetid://79921001162475"  },
	["Ta Ta Ta Ta Sahur"]          = { walk="rbxassetid://110738126954590", idle="rbxassetid://110884315283001" },
	["Matteo"]                     = { walk="rbxassetid://100637828525937", idle="rbxassetid://72411987040930"  },
	["Frigo Camelo"]               = { walk="rbxassetid://125296087957886", idle="rbxassetid://138870368397340" },
	["Svinina Bombardino"]         = { walk="rbxassetid://135809553238260", idle="rbxassetid://92398813016839"  },
	["Trulimero Trulicina"]        = { walk="rbxassetid://131155860551490", idle="rbxassetid://132233822953124" },
	["Bombombini Gusini"]          = { walk="rbxassetid://97312850853398",  idle="rbxassetid://108949283694471" },
	["Tralalero Tralala"]          = { walk="rbxassetid://96060363459602",  idle="rbxassetid://115956762431697" },
	["Boneca Ambalabu"]            = { walk="rbxassetid://83595480254596",  idle="rbxassetid://119760522552951" },
	["Br Br Patapim"]              = { walk="rbxassetid://97707231278453",  idle="rbxassetid://103324962508855" },
	["Odin Din Din Dun"]           = { walk="rbxassetid://78634603050662",  idle="rbxassetid://137186542387200" },
	["Trippi Troppi Troppa"]       = { walk="rbxassetid://113404239084107", idle="rbxassetid://104825748317462" },
	["Chimpanzini Bananini"]       = { walk="rbxassetid://97796483180896",  idle="rbxassetid://106808205315275" },
	["Trippi Troppi"]              = { walk="rbxassetid://125161036512325", idle="rbxassetid://127319771988896" },
	["Ballerina Cappuccina"]       = { walk="rbxassetid://85903123119730",  idle="rbxassetid://89172225688955"  },
	["Cappucino Assasino"]         = { walk="rbxassetid://72956943616581",  idle="rbxassetid://125735262153251" },
	["La Vacca Saturno Saturnita"] = { walk="rbxassetid://70619132098483"  },
	["Pipi Kiwi"]                  = { walk="rbxassetid://83588557044612"  },
}

-- ============================================================
-- REMOTES
-- ============================================================

local Remotes = Instance.new("Folder")
Remotes.Name = "BrainotRemotes"; Remotes.Parent = ReplicatedStorage

local function makeEvent(n)  local r=Instance.new("RemoteEvent");  r.Name=n; r.Parent=Remotes; return r end
local function makeFunc(n)   local r=Instance.new("RemoteFunction"); r.Name=n; r.Parent=Remotes; return r end

local RE_StartCapture    = makeEvent("StartCapture")
local RE_CaptureResult   = makeEvent("CaptureResult")
local RE_UpdateMoney     = makeEvent("UpdateMoney")
local RE_SyncInventory   = makeEvent("SyncInventory")
local RE_PlaceInBase     = makeEvent("PlaceInBase")
local RE_CaptureAttempt  = makeEvent("CaptureAttempt")
local RE_AssignBase      = makeEvent("AssignBase")
local RE_PlacementResult = makeEvent("PlacementResult")
local RE_SellBrainot     = makeEvent("SellBrainot")      -- client->server: sell from inventory
local RE_SellFromBase    = makeEvent("SellFromBase")      -- client->server: sell from base
local RE_StealRequest    = makeEvent("StealRequest")      -- client->server: want to steal
local RE_StealResult     = makeEvent("StealResult")       -- server->client: steal outcome
local RE_SyncBase        = makeEvent("SyncBase")          -- server->client: base brainot list
local RE_RequestOtherBase = makeEvent("RequestOtherBase")
local RE_SendOtherBase    = makeEvent("SendOtherBase")
local RE_BuyClickStrength = makeEvent("BuyClickStrength")
local RE_SyncClickStrength = makeEvent("SyncClickStrength")

-- ============================================================
-- STORE PRICING
-- ============================================================

local CLICK_STRENGTH_BASE_COST = 500  -- first upgrade costs 500
local CLICK_STRENGTH_COST_MULT = 1.5   -- each level costs 1.5x more (500, 750, 1125...)

-- ============================================================
-- DATA
-- ============================================================

local playerData  = {}   -- [player] = { money, inventory, basePlaced, clickStrength }
local assignedBases = {}
local availableBases = {}

-- pending steal requests waiting for Robux purchase to confirm
local pendingSteal = {}  -- [player] = { targetPlayer, brainotIndex }

local function defaultData()
	return { money = 0, inventory = {}, basePlaced = {}, clickStrength = 1 }
	-- basePlaced = list of { name, tier } same as inventory items
	-- clickStrength = power per click in capture minigame (store upgrade later)
end

local function saveData(player)
	local d = playerData[player]
	if not d then return end
	pcall(function()
		DataStore:SetAsync("u_"..player.UserId, {
			money      = d.money,
			inventory  = d.inventory,
			basePlaced = d.basePlaced,
			clickStrength = d.clickStrength,
		})
	end)
end

local function loadData(player)
	local ok, saved = pcall(function() return DataStore:GetAsync("u_"..player.UserId) end)
	local d = defaultData()
	if ok and saved then
		d.money      = saved.money      or 0
		d.inventory  = saved.inventory  or {}
		d.basePlaced = saved.basePlaced or {}
		d.clickStrength = math.max(1, saved.clickStrength or 1)
	end
	playerData[player] = d
	return d
end

-- ============================================================
-- LEADERBOARD
-- ============================================================

local function setupLeaderboard(player)
	local ls = Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player
	local m  = Instance.new("IntValue"); m.Name="Money"; m.Value=0; m.Parent=ls
	return m
end

local function updateMoney(player, amount)
	local d = playerData[player]; if not d then return end
	d.money = math.max(0, amount)
	local ls = player:FindFirstChild("leaderstats")
	if ls then local m=ls:FindFirstChild("Money"); if m then m.Value=d.money end end
	RE_UpdateMoney:FireClient(player, d.money)
end

local function syncClickStrength(player)
	local d = playerData[player]; if not d then return end
	RE_SyncClickStrength:FireClient(player, d.clickStrength)
end

-- ============================================================
-- STORE - BUY CLICK STRENGTH
-- ============================================================

RE_BuyClickStrength.OnServerEvent:Connect(function(player)
	local d = playerData[player]; if not d then return end
	local current = math.max(1, d.clickStrength or 1)
	local cost = math.floor(CLICK_STRENGTH_BASE_COST * (CLICK_STRENGTH_COST_MULT ^ (current - 1)))
	if d.money < cost then return end
	d.money = d.money - cost
	d.clickStrength = current + 1
	updateMoney(player, d.money)
	syncClickStrength(player)
	saveData(player)
	print(player.Name .. " bought Click Strength " .. d.clickStrength .. " for $" .. cost)
end)

-- ============================================================
-- BASE SYSTEM
-- ============================================================

local function scanBases()
	for _,o in ipairs(workspace:GetChildren()) do
		if o:IsA("Model") and o.Name:match("^Base%d+$") then
			table.insert(availableBases, o.Name)
		end
	end
	table.sort(availableBases, function(a,b)
		return tonumber(a:match("%d+")) < tonumber(b:match("%d+"))
	end)
	print("Bases found: "..table.concat(availableBases,", "))
end
scanBases()

task.spawn(function()
	task.wait(1)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("SpawnLocation") and obj.Name ~= "PlayerSpawn" then
			obj.Enabled = false
			obj.Neutral = false
		end
	end
	print("BrainotServer: Default SpawnLocations disabled")
end)

local function getBase(player)
	return workspace:FindFirstChild(assignedBases[player] or "")
end

local function getZonePart(base)
	return base and base:FindFirstChild("Part")
end

local function getBaseSpawnCFrame(base)
	local zonePart = base:FindFirstChild("Part")
	if zonePart then
		local cf   = zonePart.CFrame
		local sz   = zonePart.Size
		local groundY = zonePart.Position.Y + sz.Y / 2 + 3
		local frontWorld = cf * CFrame.new(0, 0, sz.Z / 2 + 4)
		return CFrame.new(Vector3.new(frontWorld.Position.X, groundY, frontWorld.Position.Z))
			* CFrame.Angles(0, math.atan2(-cf.LookVector.X, -cf.LookVector.Z) + math.pi, 0)
	end
	local cf, sz = base:GetBoundingBox()
	return CFrame.new(cf.Position + cf.LookVector * (sz.Z / 2 + 5) + Vector3.new(0, 3, 0))
		* CFrame.Angles(0, math.atan2(-cf.LookVector.X, -cf.LookVector.Z) + math.pi, 0)
end

local function assignBase(player)
	if assignedBases[player] or #availableBases == 0 then return end
	local name = table.remove(availableBases, 1)
	assignedBases[player] = name
	local base = workspace:FindFirstChild(name)
	if not base then return end
	base:SetAttribute("Owner", player.Name)
	base:SetAttribute("OwnerUserId", player.UserId)

	local existing = base:FindFirstChild("PlayerSpawn")
	if existing then existing:Destroy() end

	local spawnCF  = getBaseSpawnCFrame(base)
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name        = "PlayerSpawn"
	spawnLoc.Size        = Vector3.new(4, 1, 4)
	spawnLoc.CFrame      = spawnCF * CFrame.new(0, -0.5, 0)
	spawnLoc.Anchored    = true
	spawnLoc.CanCollide  = true
	spawnLoc.Neutral     = false
	spawnLoc.TeamColor   = BrickColor.new("White")
	spawnLoc.Transparency = 1
	spawnLoc.Material    = Enum.Material.SmoothPlastic
	spawnLoc.CastShadow  = false
	spawnLoc.Parent      = base

	player.RespawnLocation = spawnLoc

	local anchor = base:FindFirstChildOfClass("BasePart")
	if anchor then
		local existing2 = base:FindFirstChild("OwnerTag")
		if existing2 then existing2:Destroy() end
		local _, sz = base:GetBoundingBox()
		local bill = Instance.new("BillboardGui")
		bill.Name="OwnerTag"; bill.Size=UDim2.new(0,260,0,70)
		bill.StudsOffset=Vector3.new(0, sz.Y/2+8, 0)
		bill.AlwaysOnTop=false; bill.MaxDistance=120
		bill.Adornee=anchor; bill.Parent=base
		local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0)
		bg.BackgroundColor3=Color3.fromRGB(8,8,22); bg.BackgroundTransparency=0.2
		bg.BorderSizePixel=0; bg.Parent=bill
		Instance.new("UICorner",bg).CornerRadius=UDim.new(0,10)
		local st=Instance.new("UIStroke",bg); st.Color=Color3.fromRGB(255,210,50); st.Thickness=2
		local t1=Instance.new("TextLabel"); t1.Size=UDim2.new(1,-8,0.44,0); t1.Position=UDim2.new(0,4,0,2)
		t1.BackgroundTransparency=1; t1.Text=name; t1.TextColor3=Color3.fromRGB(255,210,50)
		t1.TextScaled=true; t1.Font=Enum.Font.GothamBold; t1.Parent=bg
		local t2=Instance.new("TextLabel"); t2.Size=UDim2.new(1,-8,0.48,0); t2.Position=UDim2.new(0,4,0.46,0)
		t2.BackgroundTransparency=1; t2.Text=player.Name; t2.TextColor3=Color3.fromRGB(255,255,255)
		t2.TextScaled=true; t2.Font=Enum.Font.Gotham; t2.Parent=bg
	end

	local cf, sz = base:GetBoundingBox()
	RE_AssignBase:FireClient(player, name, cf.Position, sz)
	print("Assigned "..name.." to "..player.Name)
end

local function releaseBase(player)
	local name = assignedBases[player]; if not name then return end
	local base = workspace:FindFirstChild(name)
	if base then
		base:SetAttribute("Owner", nil); base:SetAttribute("OwnerUserId", nil)
		local tag   = base:FindFirstChild("OwnerTag");   if tag   then tag:Destroy()   end
		local spawn = base:FindFirstChild("PlayerSpawn"); if spawn then spawn:Destroy() end
		for _,c in ipairs(base:GetChildren()) do
			if c:GetAttribute("MoneyPerSecond") then c:Destroy() end
		end
	end
	player.RespawnLocation = nil
	assignedBases[player] = nil
	table.insert(availableBases, name)
	table.sort(availableBases, function(a,b) return tonumber(a:match("%d+"))<tonumber(b:match("%d+")) end)
end

-- ============================================================
-- MODEL HELPERS
-- ============================================================

local function getModelBottomOffset(model)
	model:PivotTo(CFrame.new(0,500,0))
	local lowest = math.huge
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name~="PlacedTagAnchor" then
			local b = p.Position.Y - p.Size.Y*0.5
			if b < lowest then lowest = b end
		end
	end
	return model:GetPivot().Position.Y - lowest
end

local function addPlacedNameTag(model, displayName, tier, mps)
	local root = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
	if not root then return end
	local _, sz = model:GetBoundingBox()
	local tc = TIER_COLORS_3D[tier] or TIER_COLORS_3D.Normal

	local anch = Instance.new("Part")
	anch.Name="PlacedTagAnchor"; anch.Size=Vector3.new(0.1,0.1,0.1)
	anch.Transparency=1; anch.Anchored=false; anch.CanCollide=false
	anch.CanQuery=false; anch.CastShadow=false
	anch.CFrame = root.CFrame + Vector3.new(0, sz.Y/2+3.5, 0)
	anch.Parent = model
	local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=anch; w.Parent=anch

	local bill=Instance.new("BillboardGui"); bill.Adornee=anch
	bill.Size=UDim2.new(0,200,0,82); bill.MaxDistance=55; bill.AlwaysOnTop=false; bill.Parent=anch

	local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0)
	bg.BackgroundColor3=Color3.fromRGB(5,5,15); bg.BackgroundTransparency=0.22
	bg.BorderSizePixel=0; bg.Parent=bill
	Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
	local sk=Instance.new("UIStroke",bg); sk.Color=tc; sk.Thickness=2

	local stripe=Instance.new("Frame"); stripe.Size=UDim2.new(1,0,0,20)
	stripe.BackgroundColor3=tc; stripe.BorderSizePixel=0; stripe.Parent=bg
	Instance.new("UICorner",stripe).CornerRadius=UDim.new(0,8)
	local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
	tl.Text=tier:upper(); tl.TextColor3=Color3.fromRGB(10,10,10)
	tl.TextScaled=true; tl.Font=Enum.Font.GothamBold; tl.Parent=stripe

	local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,-6,0,22); nl.Position=UDim2.new(0,3,0,21)
	nl.BackgroundTransparency=1; nl.Text=displayName; nl.TextColor3=tc
	nl.TextScaled=true; nl.Font=Enum.Font.GothamBold; nl.Parent=bg

	local ml=Instance.new("TextLabel"); ml.Size=UDim2.new(1,-6,0,18); ml.Position=UDim2.new(0,3,0,44)
	ml.BackgroundTransparency=1; ml.Text="+$"..mps.."/5s"; ml.TextColor3=Color3.fromRGB(80,255,130)
	ml.TextScaled=true; ml.Font=Enum.Font.GothamBold; ml.Parent=bg

	local sellPrice = (BRAINOT_MONEY[displayName] or 5) * (SELL_MULTIPLIER[tier] or 8)
	local sl=Instance.new("TextLabel"); sl.Size=UDim2.new(1,-6,0,14); sl.Position=UDim2.new(0,3,0,63)
	sl.BackgroundTransparency=1; sl.Text="Sell: $"..sellPrice; sl.TextColor3=Color3.fromRGB(255,200,60)
	sl.TextScaled=true; sl.Font=Enum.Font.Gotham; sl.Parent=bg
end

local function playBaseAnim(model, displayName)
	task.wait(0.5)
	local ad = ANIM_IDS[displayName]; if not ad then return end
	local ctrl = nil
	for _,d in ipairs(model:GetDescendants()) do if d:IsA("AnimationController") then ctrl=d; break end end
	if not ctrl then return end
	local anim_inst = ctrl:FindFirstChildOfClass("Animator")
	if not anim_inst then anim_inst=Instance.new("Animator"); anim_inst.Parent=ctrl; task.wait() end
	local id = ad.walk or ad.idle; if not id then return end
	local a=Instance.new("Animation"); a.AnimationId=id
	local ok,tr=pcall(function() return anim_inst:LoadAnimation(a) end)
	if ok and tr then tr.Looped=true; tr:Play() end
end

local function startBaseWander(model, zonePart)
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name~="PlacedTagAnchor" then p.Anchored=true; p.CanCollide=false end
	end
	local zCF=zonePart.CFrame; local zSz=zonePart.Size
	local halfX=zSz.X/2-2; local halfZ=zSz.Z/2-2
	local groundY=zonePart.Position.Y+zSz.Y/2
	local lift=getModelBottomOffset(model)
	model:PivotTo(CFrame.new(zCF.Position.X, groundY+lift, zCF.Position.Z))

	task.spawn(function()
		while model.Parent~=nil do
			local lx=math.random()*2*halfX-halfX
			local lz=math.random()*2*halfZ-halfZ
			local wt=zCF*CFrame.new(lx,0,lz)
			local tx,tz=wt.Position.X,wt.Position.Z
			local sx=model:GetPivot().Position.X
			local sz=model:GetPivot().Position.Z
			local dist=math.sqrt((tx-sx)^2+(tz-sz)^2)
			if dist<0.5 then task.wait(2); continue end
			local fCF=CFrame.lookAt(Vector3.new(sx,0,sz),Vector3.new(tx,0,tz))*CFrame.Angles(0,math.pi,0)
			local rot=fCF-fCF.Position
			local wTime=dist/3; local el=0; local last=tick()
			while el<wTime and model.Parent~=nil do
				local now=tick(); local dt=now-last; last=now; el+=dt
				local al=math.clamp(el/wTime,0,1)
				local cx=sx+(tx-sx)*al; local cz=sz+(tz-sz)*al
				model:PivotTo(CFrame.new(cx,groundY+lift,cz)*rot)
				task.wait()
			end
			task.wait(math.random(2,5))
		end
	end)
end

-- ============================================================
-- SPAWN A PLACED BRAINOT MODEL IN BASE
-- ============================================================

local function spawnPlacedModel(base, item)
	local zonePart = getZonePart(base)
	if not zonePart then return nil end

	local SpawnModels = workspace:FindFirstChild("SpawnModels")
	if not SpawnModels then return nil end

	local template = nil
	for _,folder in ipairs(SpawnModels:GetChildren()) do
		local f = folder:FindFirstChild(item.name)
		if f then template=f; break end
	end
	if not template then return nil end

	local clone = template:Clone()
	clone.Name   = item.name.."_BasePlaced"
	clone.Parent = base

	local mps = (BRAINOT_MONEY[item.name] or 5) * (TIER_MULTIPLIER[item.tier] or 1)
	clone:SetAttribute("MoneyPerSecond", mps)
	clone:SetAttribute("DisplayName",    item.name)
	clone:SetAttribute("Tier",           item.tier)

	for _,p in ipairs(clone:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored=true; p.CanCollide=false end
	end

	local groundY   = zonePart.Position.Y + zonePart.Size.Y/2
	local lift      = getModelBottomOffset(clone)
	local finalY    = groundY + lift
	local zPos      = zonePart.Position

	clone:PivotTo(CFrame.new(zPos.X, finalY+25, zPos.Z))
	task.wait(0.05)
	for i=1,24 do
		local a=i/24; local e=1-(1-a)^3
		clone:PivotTo(CFrame.new(zPos.X, (finalY+25)+((finalY-(finalY+25))*e), zPos.Z))
		task.wait(0.4/24)
	end
	clone:PivotTo(CFrame.new(zPos.X, finalY, zPos.Z))

	addPlacedNameTag(clone, item.name, item.tier, mps)
	startBaseWander(clone, zonePart)
	task.spawn(playBaseAnim, clone, item.name)

	return clone, mps
end

local function syncBaseToClient(player)
	local d = playerData[player]; if not d then return end
	RE_SyncBase:FireClient(player, d.basePlaced)
end

-- ============================================================
-- PLACE IN BASE
-- ============================================================

RE_PlaceInBase.OnServerEvent:Connect(function(player, invIndex)
	local d = playerData[player]; if not d then return end
	local item = d.inventory[invIndex]; if not item then return end

	if #d.basePlaced >= MAX_BASE_SLOTS then
		RE_PlacementResult:FireClient(player, false, "Base full! Max "..MAX_BASE_SLOTS.." Brainots")
		return
	end

	local base = getBase(player)
	if not base then RE_PlacementResult:FireClient(player, false, "No base assigned"); return end

	table.remove(d.inventory, invIndex)
	table.insert(d.basePlaced, item)

	RE_SyncInventory:FireClient(player, d.inventory)
	syncBaseToClient(player)

	local clone, mps = spawnPlacedModel(base, item)
	if clone then
		RE_PlacementResult:FireClient(player, true, item.name, mps)
		print(player.Name.." placed "..item.name.." ("..item.tier..")")
	else
		RE_PlacementResult:FireClient(player, false, "Spawn failed for "..item.name)
	end

	saveData(player)
end)

-- ============================================================
-- SELL FROM INVENTORY / BASE
-- ============================================================

RE_SellBrainot.OnServerEvent:Connect(function(player, invIndex)
	local d = playerData[player]; if not d then return end
	local item = d.inventory[invIndex]; if not item then return end

	local base = (BRAINOT_MONEY[item.name] or 5) * (SELL_MULTIPLIER[item.tier] or 8)
	table.remove(d.inventory, invIndex)
	RE_SyncInventory:FireClient(player, d.inventory)
	updateMoney(player, d.money + base)
	saveData(player)

	print(player.Name.." sold "..item.name.." from inventory for $"..base)
end)

RE_SellFromBase.OnServerEvent:Connect(function(player, baseIndex)
	local d = playerData[player]; if not d then return end
	local item = d.basePlaced[baseIndex]; if not item then return end

	local price = (BRAINOT_MONEY[item.name] or 5) * (SELL_MULTIPLIER[item.tier] or 8)

	table.remove(d.basePlaced, baseIndex)
	syncBaseToClient(player)

	local base = getBase(player)
	if base then
		local count = 0
		for _,child in ipairs(base:GetChildren()) do
			if child:GetAttribute("MoneyPerSecond") then
				count += 1
				if count == baseIndex then
					child:Destroy()
					break
				end
			end
		end
	end

	updateMoney(player, d.money + price)
	saveData(player)

	RE_PlacementResult:FireClient(player, true, "Sold "..item.name.." for $"..price, 0)
	print(player.Name.." sold "..item.name.." from base for $"..price)
end)

-- ============================================================
-- STEAL WITH ROBUX
-- ============================================================

RE_StealRequest.OnServerEvent:Connect(function(player, targetPlayer, baseIndex)
	local td = playerData[targetPlayer]
	if not td then RE_StealResult:FireClient(player, false, "Player offline"); return end
	local item = td.basePlaced[baseIndex]
	if not item then RE_StealResult:FireClient(player, false, "Brainot not found"); return end

	pendingSteal[player.UserId] = { targetPlayer=targetPlayer, baseIndex=baseIndex, item=item }

	MarketplaceService:PromptProductPurchase(player, STEAL_PRODUCT_ID)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if receiptInfo.ProductId ~= STEAL_PRODUCT_ID then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local buyer = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not buyer then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local pending = pendingSteal[buyer.UserId]
	if not pending then return Enum.ProductPurchaseDecision.PurchaseGranted end
	pendingSteal[buyer.UserId] = nil

	local targetPlayer = pending.targetPlayer
	local td = playerData[targetPlayer]
	local bd = playerData[buyer]

	if not td or not bd then
		RE_StealResult:FireClient(buyer, false, "Target went offline")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local item = td.basePlaced[pending.baseIndex]
	if not item then
		RE_StealResult:FireClient(buyer, false, "Brainot already gone")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	table.remove(td.basePlaced, pending.baseIndex)
	syncBaseToClient(targetPlayer)
	local tBase = getBase(targetPlayer)
	if tBase then
		local count = 0
		for _,child in ipairs(tBase:GetChildren()) do
			if child:GetAttribute("MoneyPerSecond") then
				count += 1
				if count == pending.baseIndex then child:Destroy(); break end
			end
		end
	end
	saveData(targetPlayer)

	table.insert(bd.inventory, item)
	RE_SyncInventory:FireClient(buyer, bd.inventory)
	saveData(buyer)

	RE_StealResult:FireClient(buyer, true, item.name, item.tier)
	print(buyer.Name.." stole "..item.name.." from "..targetPlayer.Name)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ============================================================
-- CAPTURE SYSTEM
-- ============================================================

local beingCaptured  = {}
local playerBusy     = {}
local playerCooldown = {}

local FAIL_COOLDOWN = 8
local RE_CaptureLocked = makeEvent("CaptureLocked")

local function releaseCapture(model, player)
	if model then
		beingCaptured[model] = nil
		local tag = model:FindFirstChild("LockedLabel")
		if tag then tag:Destroy() end
	end
	if player then
		playerBusy[player] = nil
	end
end

RE_CaptureAttempt.OnServerEvent:Connect(function(player, brainotModel)
	if not brainotModel or not brainotModel.Parent then return end
	if beingCaptured[brainotModel] then return end

	if playerBusy[player] then return end
	if playerCooldown[player] then return end

	local char = player.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end

	local ok, cf = pcall(function() return brainotModel:GetBoundingBox() end)
	local center
	if ok and cf then
		center = cf.Position
	else
		for _,p in ipairs(brainotModel:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "NameTagAnchor" then center = p.Position; break end
		end
	end
	if not center then return end

	local dist = (root.Position - center).Magnitude
	if dist > 35 then return end

	beingCaptured[brainotModel] = player
	playerBusy[player]          = brainotModel

	local lockedLbl = Instance.new("StringValue")
	lockedLbl.Name  = "LockedLabel"
	lockedLbl.Value = player.Name
	lockedLbl.Parent = brainotModel

	local tier = brainotModel:GetAttribute("Tier") or "Normal"
	local name = brainotModel:GetAttribute("DisplayName") or brainotModel.Name
	local d = playerData[player]; if not d then return end
	local clickStrength = math.max(1, d.clickStrength or 1)

	RE_StartCapture:FireClient(player, {
		tier     = tier,
		name     = name,
		speed    = CAPTURE_SPEED[tier] or 3,
		modelRef = brainotModel,
		clickStrength = clickStrength,
	})

	local ancestryConn
	ancestryConn = brainotModel.AncestryChanged:Connect(function()
		if not brainotModel:IsDescendantOf(workspace) then
			ancestryConn:Disconnect()
			if beingCaptured[brainotModel] == player then
				releaseCapture(brainotModel, player)
				playerCooldown[player] = nil
				RE_CaptureLocked:FireClient(player, 0)
			end
		end
	end)
end)

RE_CaptureResult.OnServerEvent:Connect(function(player, brainotModel, won)
	if not brainotModel then return end
	if beingCaptured[brainotModel] ~= player then return end

	releaseCapture(brainotModel, player)

	if won then
		if not brainotModel.Parent then return end
		local d = playerData[player]; if not d then return end
		local tier = brainotModel:GetAttribute("Tier") or "Normal"
		local name = brainotModel:GetAttribute("DisplayName") or "Unknown"
		table.insert(d.inventory, { name=name, tier=tier })
		brainotModel:Destroy()
		RE_SyncInventory:FireClient(player, d.inventory)
		saveData(player)
		print(player.Name .. " caught " .. name)
	else
		playerCooldown[player] = true
		RE_CaptureLocked:FireClient(player, FAIL_COOLDOWN)
		task.delay(FAIL_COOLDOWN, function()
			playerCooldown[player] = nil
			if player.Parent then
				RE_CaptureLocked:FireClient(player, 0)
			end
		end)
		print(player.Name .. " failed to catch " .. (brainotModel:GetAttribute("DisplayName") or "?"))
	end
end)

-- ============================================================
-- VIEW OTHER PLAYER BASE
-- ============================================================

RE_RequestOtherBase.OnServerEvent:Connect(function(requester, targetPlayer)
	local td = playerData[targetPlayer]
	if not td then
		RE_SendOtherBase:FireClient(requester, nil, "Player offline")
		return
	end
	RE_SendOtherBase:FireClient(requester, targetPlayer, td.basePlaced)
end)

-- ============================================================
-- MONEY TICKER
-- ============================================================

task.spawn(function()
	while true do
		task.wait(5)
		for player, d in pairs(playerData) do
			if not player.Parent then continue end
			local base = getBase(player); if not base then continue end
			local earned = 0
			for _,obj in ipairs(base:GetChildren()) do
				local mps = obj:GetAttribute("MoneyPerSecond")
				if mps then earned += mps end
			end
			if earned > 0 then
				updateMoney(player, d.money + earned)
				saveData(player)
			end
		end
	end
end)

-- ============================================================
-- PLAYER JOIN / LEAVE
-- ============================================================

Players.PlayerAdded:Connect(function(player)
	local d = loadData(player)
	local ls = setupLeaderboard(player)
	ls.Value = d.money

	assignBase(player)

	player.CharacterAdded:Connect(function(char)
		task.spawn(function()
			local baseName = assignedBases[player]
			if not baseName then return end
			local base = workspace:FindFirstChild(baseName)
			if not base then return end

			local hrp = char:WaitForChild("HumanoidRootPart", 8)
			if not hrp then return end

			task.wait(0.15)

			local spawnCF = getBaseSpawnCFrame(base)
			hrp.CFrame    = spawnCF
		end)

		task.wait(1)
		RE_UpdateMoney:FireClient(player, d.money)
		RE_SyncInventory:FireClient(player, d.inventory)
		syncBaseToClient(player)
		syncClickStrength(player)

		local baseName = assignedBases[player]
		if baseName then
			local base = workspace:FindFirstChild(baseName)
			if base then
				local cf, sz = base:GetBoundingBox()
				RE_AssignBase:FireClient(player, baseName, cf.Position, sz)

				local alreadyRestored = base:GetAttribute("Restored_"..player.UserId)
				if not alreadyRestored and #d.basePlaced > 0 then
					base:SetAttribute("Restored_"..player.UserId, true)
					for _, item in ipairs(d.basePlaced) do
						task.spawn(function()
							spawnPlacedModel(base, item)
						end)
						task.wait(0.3)
					end
				end
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local model = playerBusy[player]
	if model then releaseCapture(model, player) end
	playerCooldown[player] = nil

	saveData(player)
	releaseBase(player)
	playerData[player] = nil
end)

game:BindToClose(function()
	for player, _ in pairs(playerData) do
		saveData(player)
	end
end)
