-- BrainrotData: the cast of Brainrot Bay.
-- Every character is an original invention for this game: absurd, named,
-- and ranked on a ladder of rarities. Each entry carries its price, its
-- money-per-second, its colours, and which accessory its model wears.
-- This module is shared: the server spawns from it and the client reads
-- it to label the HUD, so it lives in ReplicatedStorage.

local BrainrotData = {}

BrainrotData.RARITIES = {
	Common = { weight = 45, color = Color3.fromRGB(200, 200, 200), order = 1 },
	Rare = { weight = 28, color = Color3.fromRGB(80, 170, 255), order = 2 },
	Epic = { weight = 15, color = Color3.fromRGB(180, 90, 255), order = 3 },
	Legendary = { weight = 8, color = Color3.fromRGB(255, 190, 40), order = 4 },
	Mythic = { weight = 3, color = Color3.fromRGB(255, 70, 120), order = 5 },
	["Brainrot God"] = { weight = 1, color = Color3.fromRGB(60, 255, 180), order = 6 },
}

-- id, name, rarity, cost, income per second, body colour, head colour, accessory
BrainrotData.BRAINROTS = {
	{ id = "turbo_toast", name = "Turbo Toast", rarity = "Common", cost = 50, income = 1,
		bodyColor = Color3.fromRGB(222, 184, 110), headColor = Color3.fromRGB(245, 222, 170), accessory = "bowtie" },
	{ id = "sir_quackington", name = "Sir Quackington III", rarity = "Common", cost = 150, income = 3,
		bodyColor = Color3.fromRGB(255, 230, 120), headColor = Color3.fromRGB(255, 250, 200), accessory = "hat" },
	{ id = "pickle_pete", name = "Pickle Pete", rarity = "Common", cost = 300, income = 5,
		bodyColor = Color3.fromRGB(110, 200, 90), headColor = Color3.fromRGB(150, 230, 110), accessory = "mustache" },
	{ id = "dj_noodle", name = "DJ Noodle", rarity = "Rare", cost = 800, income = 10,
		bodyColor = Color3.fromRGB(250, 210, 90), headColor = Color3.fromRGB(255, 240, 170), accessory = "headphones" },
	{ id = "captain_picklebeard", name = "Captain Picklebeard", rarity = "Rare", cost = 1200, income = 15,
		bodyColor = Color3.fromRGB(90, 160, 90), headColor = Color3.fromRGB(240, 210, 160), accessory = "hat" },
	{ id = "professor_wobbles", name = "Professor Wobbles", rarity = "Rare", cost = 2000, income = 25,
		bodyColor = Color3.fromRGB(150, 120, 220), headColor = Color3.fromRGB(220, 200, 250), accessory = "glasses" },
	{ id = "baron_von_bounce", name = "Baron von Bounce", rarity = "Epic", cost = 5000, income = 50,
		bodyColor = Color3.fromRGB(120, 90, 220), headColor = Color3.fromRGB(200, 170, 255), accessory = "cape" },
	{ id = "madame_zucchini", name = "Madame Zucchini", rarity = "Epic", cost = 8000, income = 80,
		bodyColor = Color3.fromRGB(60, 180, 90), headColor = Color3.fromRGB(120, 230, 130), accessory = "crown" },
	{ id = "king_fluffernutter", name = "King Fluffernutter", rarity = "Legendary", cost = 15000, income = 150,
		bodyColor = Color3.fromRGB(255, 215, 90), headColor = Color3.fromRGB(255, 240, 180), accessory = "crown" },
	{ id = "doctor_soggy_socks", name = "Doctor Soggy Socks", rarity = "Legendary", cost = 25000, income = 250,
		bodyColor = Color3.fromRGB(90, 140, 220), headColor = Color3.fromRGB(180, 210, 255), accessory = "glasses" },
	{ id = "grand_noodler", name = "The Grand Noodler", rarity = "Mythic", cost = 50000, income = 500,
		bodyColor = Color3.fromRGB(255, 120, 150), headColor = Color3.fromRGB(255, 200, 210), accessory = "halo" },
	{ id = "elder_glorp", name = "Elder Glorp, Devourer of Mondays", rarity = "Brainrot God", cost = 120000, income = 1200,
		bodyColor = Color3.fromRGB(60, 220, 160), headColor = Color3.fromRGB(140, 255, 210), accessory = "wings" },
}

local byId = {}
for _, def in ipairs(BrainrotData.BRAINROTS) do
	byId[def.id] = def
end

function BrainrotData.getById(id)
	return byId[id]
end

function BrainrotData.getRarityColor(rarity)
	local entry = BrainrotData.RARITIES[rarity]
	if entry then
		return entry.color
	end
	return Color3.fromRGB(255, 255, 255)
end

-- Pick one brainrot, weighted so common faces show up often and a
-- Brainrot God is a rare event worth running for.
function BrainrotData.pickWeightedRandom()
	local totalWeight = 0
	for _, rarity in pairs(BrainrotData.RARITIES) do
		totalWeight += rarity.weight
	end
	local roll = math.random() * totalWeight
	local pickedRarity = "Common"
	for name, rarity in pairs(BrainrotData.RARITIES) do
		roll -= rarity.weight
		if roll <= 0 then
			pickedRarity = name
			break
		end
	end
	local pool = {}
	for _, def in ipairs(BrainrotData.BRAINROTS) do
		if def.rarity == pickedRarity then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

-- The cheapest brainrot the player does not own yet, for the HUD hint.
function BrainrotData.getNextTier(ownedIds)
	local owned = {}
	for _, id in ipairs(ownedIds) do
		owned[id] = true
	end
	local sorted = {}
	for _, def in ipairs(BrainrotData.BRAINROTS) do
		table.insert(sorted, def)
	end
	table.sort(sorted, function(a, b)
		return a.cost < b.cost
	end)
	for _, def in ipairs(sorted) do
		if not owned[def.id] then
			return def
		end
	end
	return nil
end

return BrainrotData
