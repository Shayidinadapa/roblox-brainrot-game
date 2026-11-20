-- BrainrotModel: builds a brainrot character out of plain Parts.
-- Every character is a round body, a round head, a face, one accessory,
-- and a floating label showing its name, rarity, and money-per-second.
-- No meshes, decals, or uploaded assets: everything is built from parts
-- so the place file stays self-contained.

local BrainrotModel = {}

local function makePart(name, shape, size, color, parent, cframe)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function buildAccessory(kind, head, headTopY, headColor)
	local acc = Instance.new("Model")
	acc.Name = "Accessory"
	if kind == "hat" then
		local brim = makePart("HatBrim", Enum.PartType.Cylinder, Vector3.new(0.6, 2.6, 2.6),
			Color3.fromRGB(60, 45, 90), acc, head.CFrame * CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2))
		brim.Name = "HatBrim"
		makePart("HatTop", Enum.PartType.Cylinder, Vector3.new(1.2, 1.5, 1.5),
			Color3.fromRGB(60, 45, 90), acc, head.CFrame * CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.pi / 2))
	elseif kind == "crown" then
		makePart("Crown", Enum.PartType.Cylinder, Vector3.new(0.7, 1.8, 1.8),
			Color3.fromRGB(255, 210, 60), acc, head.CFrame * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2))
		for i = -1, 1 do
			makePart("CrownSpike", Enum.PartType.Wedge, Vector3.new(0.5, 0.6, 0.5),
				Color3.fromRGB(255, 210, 60), acc,
				head.CFrame * CFrame.new(i * 0.6, 1.8, 0))
		end
	elseif kind == "glasses" then
		makePart("LensLeft", Enum.PartType.Block, Vector3.new(0.7, 0.7, 0.15),
			Color3.fromRGB(20, 20, 25), acc, head.CFrame * CFrame.new(-0.45, 0.15, -1.05))
		makePart("LensRight", Enum.PartType.Block, Vector3.new(0.7, 0.7, 0.15),
			Color3.fromRGB(20, 20, 25), acc, head.CFrame * CFrame.new(0.45, 0.15, -1.05))
		makePart("Bridge", Enum.PartType.Block, Vector3.new(0.3, 0.12, 0.12),
			Color3.fromRGB(20, 20, 25), acc, head.CFrame * CFrame.new(0, 0.15, -1.05))
	elseif kind == "mustache" then
		makePart("Mustache", Enum.PartType.Block, Vector3.new(1.3, 0.25, 0.2),
			Color3.fromRGB(40, 25, 15), acc, head.CFrame * CFrame.new(0, -0.45, -1.0))
	elseif kind == "headphones" then
		makePart("CupLeft", Enum.PartType.Cylinder, Vector3.new(0.5, 1.0, 1.0),
			Color3.fromRGB(30, 30, 40), acc, head.CFrame * CFrame.new(-1.1, 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2))
		makePart("CupRight", Enum.PartType.Cylinder, Vector3.new(0.5, 1.0, 1.0),
			Color3.fromRGB(30, 30, 40), acc, head.CFrame * CFrame.new(1.1, 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2))
		makePart("Band", Enum.PartType.Block, Vector3.new(2.3, 0.25, 0.5),
			Color3.fromRGB(220, 60, 90), acc, head.CFrame * CFrame.new(0, 1.05, 0))
	elseif kind == "cape" then
		local cape = makePart("Cape", Enum.PartType.Block, Vector3.new(2.6, 3.2, 0.15),
			Color3.fromRGB(200, 30, 60), acc, head.CFrame * CFrame.new(0, -1.2, 1.35))
		cape.Material = Enum.Material.Neon
	elseif kind == "bowtie" then
		makePart("BowLeft", Enum.PartType.Wedge, Vector3.new(0.5, 0.6, 0.3),
			Color3.fromRGB(200, 30, 60), acc, head.CFrame * CFrame.new(-0.4, -1.1, -0.9) * CFrame.Angles(0, math.pi, 0))
		makePart("BowRight", Enum.PartType.Wedge, Vector3.new(0.5, 0.6, 0.3),
			Color3.fromRGB(200, 30, 60), acc, head.CFrame * CFrame.new(0.4, -1.1, -0.9))
	elseif kind == "halo" then
		makePart("Halo", Enum.PartType.Cylinder, Vector3.new(0.25, 2.4, 2.4),
			Color3.fromRGB(255, 230, 120), acc, head.CFrame * CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.pi / 2))
	elseif kind == "wings" then
		local left = makePart("WingLeft", Enum.PartType.Block, Vector3.new(0.15, 1.6, 2.2),
			Color3.fromRGB(255, 255, 255), acc, head.CFrame * CFrame.new(-1.2, -0.6, 1.2) * CFrame.Angles(0, 0, 0.5))
		left.Material = Enum.Material.Neon
		local right = makePart("WingRight", Enum.PartType.Block, Vector3.new(0.15, 1.6, 2.2),
			Color3.fromRGB(255, 255, 255), acc, head.CFrame * CFrame.new(1.2, -0.6, 1.2) * CFrame.Angles(0, 0, -0.5))
		right.Material = Enum.Material.Neon
	end
	return acc
end

local function buildLabel(model, head, def, BrainrotData)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = head
	gui.Size = UDim2.new(7, 0, 3.4, 0)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = def.rarity
	rarityLabel.TextColor3 = BrainrotData.getRarityColor(def.rarity)
	rarityLabel.TextStrokeTransparency = 0.2
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = gui

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, 0, 0.3, 0)
	incomeLabel.Position = UDim2.new(0, 0, 0.7, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$" .. tostring(def.income) .. "/sec"
	incomeLabel.TextColor3 = Color3.fromRGB(90, 255, 120)
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.Parent = gui
end

-- Build a full character model standing at `position`, facing -Z.
-- Returns the Model; its PrimaryPart is the body.
function BrainrotModel.build(def, position, BrainrotData)
	local model = Instance.new("Model")
	model.Name = def.name

	local base = CFrame.new(position)
	local body = makePart("Body", Enum.PartType.Ball, Vector3.new(3, 3, 3),
		def.bodyColor, model, base * CFrame.new(0, 1.6, 0))
	local head = makePart("Head", Enum.PartType.Ball, Vector3.new(2.1, 2.1, 2.1),
		def.headColor, model, base * CFrame.new(0, 3.9, 0))

	-- Face: two eyes and a smile, on the -Z side.
	makePart("EyeLeft", Enum.PartType.Ball, Vector3.new(0.4, 0.5, 0.2),
		Color3.fromRGB(255, 255, 255), model, base * CFrame.new(-0.45, 4.1, -1.0))
	makePart("PupilLeft", Enum.PartType.Ball, Vector3.new(0.2, 0.25, 0.1),
		Color3.fromRGB(20, 20, 20), model, base * CFrame.new(-0.45, 4.1, -1.12))
	makePart("EyeRight", Enum.PartType.Ball, Vector3.new(0.4, 0.5, 0.2),
		Color3.fromRGB(255, 255, 255), model, base * CFrame.new(0.45, 4.1, -1.0))
	makePart("PupilRight", Enum.PartType.Ball, Vector3.new(0.2, 0.25, 0.1),
		Color3.fromRGB(20, 20, 20), model, base * CFrame.new(0.45, 4.1, -1.12))
	makePart("Smile", Enum.PartType.Block, Vector3.new(0.9, 0.15, 0.15),
		Color3.fromRGB(60, 30, 20), model, base * CFrame.new(0, 3.45, -1.0))

	-- Feet: two small stubs so the character reads as standing.
	makePart("FootLeft", Enum.PartType.Block, Vector3.new(0.9, 0.4, 1.1),
		Color3.fromRGB(60, 40, 25), model, base * CFrame.new(-0.7, 0.2, 0))
	makePart("FootRight", Enum.PartType.Block, Vector3.new(0.9, 0.4, 1.1),
		Color3.fromRGB(60, 40, 25), model, base * CFrame.new(0.7, 0.2, 0))

	local accessory = buildAccessory(def.accessory, head, 5, def.headColor)
	accessory.Parent = model

	buildLabel(model, head, def, BrainrotData)

	model.PrimaryPart = body
	return model
end

-- Walk a model toward `target` over `duration` seconds, bobbing gently
-- and facing the direction of travel. Calls onArrive when it gets there.
-- Starting a new walk cancels any walk already running on that model:
-- a bought brainrot must head for its new base, not keep sliding
-- along the conveyor under the old walk's orders.
local walkTokens = {}

function BrainrotModel.walkTo(model, target, duration, onArrive)
	local token = (walkTokens[model] or 0) + 1
	walkTokens[model] = token
	task.spawn(function()
		local start = model:GetPivot()
		local flat = Vector3.new(target.X - start.Position.X, 0, target.Z - start.Position.Z)
		local steps = math.max(1, math.floor(duration * 30))
		for i = 1, steps do
			if not model.Parent or walkTokens[model] ~= token then
				if walkTokens[model] == token then
					walkTokens[model] = nil
				end
				return
			end
			local t = i / steps
			local pos = start.Position:Lerp(target, t)
			local bob = math.sin(t * math.pi * 6) * 0.25
			local at = pos + Vector3.new(0, bob, 0)
			local facing
			if flat.Magnitude > 0.01 then
				facing = CFrame.lookAt(at, at + flat)
			else
				facing = CFrame.new(at)
			end
			model:PivotTo(facing)
			task.wait(1 / 30)
		end
		if walkTokens[model] == token then
			walkTokens[model] = nil
		end
		if model.Parent and walkTokens[model] == nil and onArrive then
			onArrive()
		end
	end)
end

return BrainrotModel
