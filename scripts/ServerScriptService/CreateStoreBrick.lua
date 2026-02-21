-- CreateStoreBrick.lua
-- Place in ServerScriptService
-- Creates a "Store" part in workspace if one doesn't exist.
-- Place it where you want the store - players get close to open the GUI.

local workspace = game:GetService("Workspace")

local function createStoreBrick()
	if workspace:FindFirstChild("Store") then return end

	local part = Instance.new("Part")
	part.Name = "Store"
	part.Size = Vector3.new(8, 6, 4)
	part.Position = Vector3.new(0, 3, 0)
	part.Anchored = true
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 180, 50)
	part.Parent = workspace

	-- Decorative label
	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.new(0, 120, 0, 40)
	bill.StudsOffset = Vector3.new(0, 5, 0)
	bill.Adornee = part
	bill.Parent = part

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
	bg.BorderSizePixel = 0
	bg.Parent = bill
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "STORE"
	lbl.TextColor3 = Color3.fromRGB(255, 210, 80)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBlack
	lbl.Parent = bg

	print("CreateStoreBrick: Created Store part at 0,3,0. Move it where you want!")
end

createStoreBrick()
