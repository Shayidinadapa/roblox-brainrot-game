-- WorldBuilder: builds the whole 3D island of Brainrot Bay at runtime.
-- A sandy island, a conveyor belt along the north edge where brainrots
-- walk in, four player plots with six pads each, a central fountain,
-- palm trees, lamps, and a spawn area with a big title board.
-- Everything is plain Parts so the world is visible the moment the
-- place opens in Studio, with no assets to download.

local WorldBuilder = {}

local function makePart(name, shape, size, color, parent, position, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Position = position
	part.Parent = parent
	return part
end

local PLOT_COLORS = {
	Color3.fromRGB(255, 170, 170),
	Color3.fromRGB(170, 210, 255),
	Color3.fromRGB(180, 255, 170),
	Color3.fromRGB(255, 230, 150),
}

local function buildPlot(world, index, center)
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. tostring(index)
	plot.Parent = world

	local color = PLOT_COLORS[index]
	makePart("Platform", Enum.PartType.Block, Vector3.new(36, 1, 26), color,
		plot, center + Vector3.new(0, 0.5, 0), Enum.Material.Grass)

	-- Six pads in two rows of three.
	local pads = {}
	for row = 0, 1 do
		for col = -1, 1 do
			local padPos = center + Vector3.new(col * 11, 1.2, (row - 0.5) * 12)
			local pad = makePart("Pad", Enum.PartType.Cylinder, Vector3.new(1, 4.5, 4.5),
				Color3.fromRGB(255, 255, 255), plot, padPos, Enum.Material.Neon)
			pad.Orientation = Vector3.new(0, 0, 90)
			table.insert(pads, padPos + Vector3.new(0, 0.5, 0))
		end
	end

	-- Fence posts around the platform edge.
	for _, x in ipairs({ -17, 17 }) do
		for z = -12, 12, 6 do
			makePart("FencePost", Enum.PartType.Block, Vector3.new(0.6, 2.5, 0.6),
				Color3.fromRGB(140, 100, 60), plot, center + Vector3.new(x, 1.5, z))
		end
	end

	-- Sign pole and board; the owner name is written on it at runtime.
	local pole = makePart("SignPole", Enum.PartType.Cylinder, Vector3.new(0.8, 6, 0.8),
		Color3.fromRGB(120, 85, 50), plot, center + Vector3.new(0, 4, -13.5))
	pole.Orientation = Vector3.new(0, 0, 90)
	local board = makePart("SignBoard", Enum.PartType.Block, Vector3.new(14, 4, 0.6),
		Color3.fromRGB(90, 60, 30), plot, center + Vector3.new(0, 7.5, -13.5))
	local signGui = Instance.new("BillboardGui")
	signGui.Name = "PlotSign"
	signGui.Adornee = board
	signGui.Size = UDim2.new(14, 0, 4, 0)
	signGui.StudsOffset = Vector3.new(0, 0, 0)
	signGui.AlwaysOnTop = true
	signGui.Parent = plot
	local signText = Instance.new("TextLabel")
	signText.Name = "SignText"
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "PLOT " .. tostring(index) .. " — FREE"
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.TextStrokeTransparency = 0.1
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui

	return { index = index, center = center, pads = pads, signText = signText, model = plot }
end

local function buildPalm(world, position)
	local palm = Instance.new("Model")
	palm.Name = "PalmTree"
	palm.Parent = world
	local trunk = makePart("Trunk", Enum.PartType.Cylinder, Vector3.new(7, 1.2, 1.2),
		Color3.fromRGB(150, 105, 60), palm, position + Vector3.new(0, 3.5, 0))
	trunk.Orientation = Vector3.new(0, 0, 90)
	for i = 0, 4 do
		local angle = (i / 5) * math.pi * 2
		local leaf = makePart("Leaf", Enum.PartType.Block, Vector3.new(0.4, 0.4, 5),
			Color3.fromRGB(50, 180, 80), palm,
			position + Vector3.new(math.cos(angle) * 2.2, 7.2, math.sin(angle) * 2.2))
		leaf.CFrame = CFrame.new(leaf.Position)
			* CFrame.Angles(0, -angle, 0)
			* CFrame.Angles(0.5, 0, 0)
	end
	makePart("Coconuts", Enum.PartType.Ball, Vector3.new(1.2, 1.2, 1.2),
		Color3.fromRGB(110, 75, 40), palm, position + Vector3.new(0.8, 6.6, 0.5))
end

local function buildLamp(world, position)
	local lamp = Instance.new("Model")
	lamp.Name = "Lamp"
	lamp.Parent = world
	local lampPole = makePart("Pole", Enum.PartType.Cylinder, Vector3.new(6, 0.5, 0.5),
		Color3.fromRGB(50, 50, 60), lamp, position + Vector3.new(0, 3, 0))
	lampPole.Orientation = Vector3.new(0, 0, 90)
	local head = makePart("LampHead", Enum.PartType.Ball, Vector3.new(1.6, 1.6, 1.6),
		Color3.fromRGB(255, 240, 160), lamp, position + Vector3.new(0, 6.4, 0), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Range = 18
	light.Color = Color3.fromRGB(255, 240, 180)
	light.Parent = head
end

-- Build the world. Returns the layout the other systems need:
-- plots (with pad positions), conveyor waypoints, and the spawn point.
function WorldBuilder.buildWorld()
	local world = Instance.new("Model")
	world.Name = "BrainrotBayWorld"
	world.Parent = workspace

	-- Sandy island on top of the baseplate.
	makePart("Island", Enum.PartType.Block, Vector3.new(200, 2, 200),
		Color3.fromRGB(214, 196, 140), world, Vector3.new(0, -1, 0), Enum.Material.Sand)

	-- Conveyor belt along the north edge (z = -60), west to east.
	makePart("Conveyor", Enum.PartType.Block, Vector3.new(150, 1, 10),
		Color3.fromRGB(60, 60, 70), world, Vector3.new(0, 0.5, -60), Enum.Material.Metal)
	for x = -70, 70, 10 do
		makePart("ConveyorStripe", Enum.PartType.Block, Vector3.new(4, 0.2, 8),
			Color3.fromRGB(255, 210, 60), world, Vector3.new(x, 1.1, -60), Enum.Material.Neon)
	end
	-- Conveyor side rails.
	makePart("RailNorth", Enum.PartType.Block, Vector3.new(150, 1.5, 0.6),
		Color3.fromRGB(200, 200, 210), world, Vector3.new(0, 1.2, -65.2))
	makePart("RailSouth", Enum.PartType.Block, Vector3.new(150, 1.5, 0.6),
		Color3.fromRGB(200, 200, 210), world, Vector3.new(0, 1.2, -54.8))

	-- Four player plots.
	local plots = {}
	local centers = {
		Vector3.new(-55, 0, 20),
		Vector3.new(55, 0, 20),
		Vector3.new(-55, 0, 62),
		Vector3.new(55, 0, 62),
	}
	for i, center in ipairs(centers) do
		plots[i] = buildPlot(world, i, center)
	end

	-- Central fountain between the conveyor and the plots.
	local fountain = Instance.new("Model")
	fountain.Name = "Fountain"
	fountain.Parent = world
	local basin = makePart("Basin", Enum.PartType.Cylinder, Vector3.new(2, 20, 20),
		Color3.fromRGB(180, 180, 190), fountain, Vector3.new(0, 1, -12))
	basin.Orientation = Vector3.new(0, 0, 90)
	local water = makePart("Water", Enum.PartType.Cylinder, Vector3.new(1, 17, 17),
		Color3.fromRGB(60, 160, 255), fountain, Vector3.new(0, 1.6, -12), Enum.Material.Neon)
	water.Orientation = Vector3.new(0, 0, 90)
	local pillar = makePart("Pillar", Enum.PartType.Cylinder, Vector3.new(5, 2, 2),
		Color3.fromRGB(220, 220, 230), fountain, Vector3.new(0, 4, -12))
	pillar.Orientation = Vector3.new(0, 0, 90)
	makePart("TopBall", Enum.PartType.Ball, Vector3.new(3, 3, 3),
		Color3.fromRGB(60, 160, 255), fountain, Vector3.new(0, 7.5, -12), Enum.Material.Neon)

	-- Palm trees around the island edge.
	for _, pos in ipairs({
		Vector3.new(-90, 0, -80), Vector3.new(90, 0, -80),
		Vector3.new(-90, 0, 80), Vector3.new(90, 0, 80),
		Vector3.new(-90, 0, 0), Vector3.new(90, 0, 0),
		Vector3.new(0, 0, -88), Vector3.new(-30, 0, 88),
	}) do
		buildPalm(world, pos)
	end

	-- Lamps along the main walkway.
	for _, pos in ipairs({
		Vector3.new(-25, 0, -40), Vector3.new(25, 0, -40),
		Vector3.new(-25, 0, 40), Vector3.new(25, 0, 40),
	}) do
		buildLamp(world, pos)
	end

	-- Spawn location at the south edge, facing the island.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.5, 85)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Enabled = true
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Parent = world

	-- Big title board behind the spawn, readable in screenshots.
	local board = makePart("TitleBoard", Enum.PartType.Block, Vector3.new(26, 9, 1),
		Color3.fromRGB(40, 60, 120), world, Vector3.new(0, 12, 76))
	local titleGui = Instance.new("BillboardGui")
	titleGui.Name = "TitleGui"
	titleGui.Adornee = board
	titleGui.Size = UDim2.new(26, 0, 9, 0)
	titleGui.AlwaysOnTop = true
	titleGui.Parent = world
	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, 0, 0.6, 0)
	titleText.Position = UDim2.new(0, 0, 0.05, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "BRAINROT BAY"
	titleText.TextColor3 = Color3.fromRGB(255, 220, 80)
	titleText.TextStrokeTransparency = 0.1
	titleText.TextScaled = true
	titleText.Font = Enum.Font.FredokaOne
	titleText.Parent = titleGui
	local subText = Instance.new("TextLabel")
	subText.Name = "SubtitleText"
	subText.Size = UDim2.new(1, 0, 0.3, 0)
	subText.Position = UDim2.new(0, 0, 0.65, 0)
	subText.BackgroundTransparency = 1
	subText.Text = "Catch them. Base them. Get rich."
	subText.TextColor3 = Color3.fromRGB(255, 255, 255)
	subText.TextStrokeTransparency = 0.2
	subText.TextScaled = true
	subText.Font = Enum.Font.GothamBold
	subText.Parent = titleGui

	return {
		plots = plots,
		conveyorStart = Vector3.new(-72, 1, -60),
		conveyorEnd = Vector3.new(72, 1, -60),
		spawnPoint = Vector3.new(0, 3, 85),
	}
end

return WorldBuilder
