-- BrainrotSpawner: the conveyor never stops. Every few seconds a new
-- brainrot appears at the west end, walks east along the belt, and
-- either gets bought by a player or walks off the end and despawns.
-- Rare faces are worth sprinting for; a Brainrot God is worth
-- dropping everything for.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotModel = require(script.Parent:WaitForChild("BrainrotModel"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local StealSystem = require(script.Parent:WaitForChild("StealSystem"))

local BrainrotSpawner = {}

BrainrotSpawner.SPAWN_INTERVAL = 4
BrainrotSpawner.MAX_WALKING = 12
BrainrotSpawner.WALK_DURATION = 42

function BrainrotSpawner.spawnBrainrot(game)
	local def = BrainrotData.pickWeightedRandom()
	local start = game.layout.conveyorStart
	local model = BrainrotModel.build(def, start, BrainrotData)
	model.Parent = workspace

	local uid = game.nextUid
	game.nextUid += 1
	local entry = { uid = uid, def = def, model = model }
	game.walking[uid] = entry

	-- The buy prompt rides on the model while it walks.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ObjectText = def.name .. "  (" .. def.rarity .. ")"
	prompt.ActionText = "Buy  $" .. tostring(def.cost)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model
	prompt.Triggered:Connect(function(player)
		if not game.walking[uid] then
			return
		end
		local owned, reason = Economy.tryBuy(game, player, uid)
		if owned then
			StealSystem.attachStealPrompt(game, game.players[player], owned)
			StealSystem.sendNotice(game, player, "You bought " .. def.name .. " for $" .. tostring(def.cost) .. "!")
		elseif reason == "poor" then
			StealSystem.sendNotice(game, player, "Not enough cash! " .. def.name .. " costs $" .. tostring(def.cost) .. ".")
		elseif reason == "base_full" then
			StealSystem.sendNotice(game, player, "Your base is full! Rebirth to clear space.")
		end
	end)

	-- Walk east along the belt; despawn at the end if nobody bought it.
	BrainrotModel.walkTo(model, game.layout.conveyorEnd, BrainrotSpawner.WALK_DURATION, function()
		if game.walking[uid] then
			game.walking[uid] = nil
			if model.Parent then
				model:Destroy()
			end
		end
	end)
end

function BrainrotSpawner.start(game)
	task.spawn(function()
		while true do
			task.wait(BrainrotSpawner.SPAWN_INTERVAL)
			local count = 0
			for _ in pairs(game.walking) do
				count += 1
			end
			if count < BrainrotSpawner.MAX_WALKING then
				BrainrotSpawner.spawnBrainrot(game)
			end
		end
	end)
end

return BrainrotSpawner
