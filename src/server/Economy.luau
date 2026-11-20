-- Economy: money, buying, income, and ownership of brainrots.
-- Each player has a state table: cash, income multiplier, rebirth count,
-- owned brainrots, and the plot they live on. Cash is mirrored into
-- leaderstats so the default leaderboard and the client HUD can read it.
-- One Brainrot God is worth more than a whole base of Commons: that is
-- the ladder the player climbs.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotModel = require(script.Parent:WaitForChild("BrainrotModel"))

local Economy = {}

Economy.LOCK_SECONDS = 30
Economy.MAX_PADS_PER_PLOT = 6

function Economy.createPlayerState(player, plotIndex)
	return {
		player = player,
		cash = 0,
		multiplier = 1,
		rebirths = 0,
		totalEarned = 0,
		owned = {},
		plotIndex = plotIndex,
	}
end

function Economy.getIncomePerSec(state)
	local total = 0
	for _, owned in ipairs(state.owned) do
		local def = BrainrotData.getById(owned.defId)
		if def then
			total += def.income
		end
	end
	return total * state.multiplier
end

function Economy.syncLeaderstats(state)
	local player = state.player
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local cash = stats:FindFirstChild("Cash")
	if cash then
		cash.Value = math.floor(state.cash)
	end
	local count = stats:FindFirstChild("Brainrots")
	if count then
		count.Value = #state.owned
	end
	local rebirths = stats:FindFirstChild("Rebirths")
	if rebirths then
		rebirths.Value = state.rebirths
	end
end

function Economy.addCash(state, amount)
	state.cash += amount
	if amount > 0 then
		state.totalEarned += amount
	end
	Economy.syncLeaderstats(state)
end

-- First free pad position on the player's plot, or nil when full.
function Economy.getFreePadPos(game, state)
	local plot = game.layout.plots[state.plotIndex]
	if not plot then
		return nil
	end
	local used = {}
	for _, owned in ipairs(state.owned) do
		used[owned.padIndex] = true
	end
	for i, padPos in ipairs(plot.pads) do
		if not used[i] then
			return padPos, i
		end
	end
	return nil
end

-- Register a brainrot as owned: walk it to a pad and lock it against
-- stealing for a short while. Returns the owned entry, or nil + reason.
function Economy.ownBrainrot(game, state, def, model)
	local padPos, padIndex = Economy.getFreePadPos(game, state)
	if not padPos then
		return nil, "base_full"
	end
	local entry = {
		uid = game.nextUid,
		defId = def.id,
		model = model,
		padIndex = padIndex,
		lockedUntil = os.time() + Economy.LOCK_SECONDS,
		valid = true,
	}
	game.nextUid += 1
	table.insert(state.owned, entry)
	Economy.syncLeaderstats(state)
	BrainrotModel.walkTo(model, padPos, 2)
	return entry
end

function Economy.disownBrainrot(game, state, uid)
	for i, owned in ipairs(state.owned) do
		if owned.uid == uid then
			owned.valid = false
			table.remove(state.owned, i)
			Economy.syncLeaderstats(state)
			return owned
		end
	end
	return nil
end

-- Buy a brainrot that is currently walking the conveyor.
-- Returns the owned entry on success, or nil + a reason string.
function Economy.tryBuy(game, player, uid)
	local state = game.players[player]
	local walking = game.walking[uid]
	if not state or not walking then
		return nil, "gone"
	end
	local def = walking.def
	if state.cash < def.cost then
		return nil, "poor"
	end
	local padPos, _ = Economy.getFreePadPos(game, state)
	if not padPos then
		return nil, "base_full"
	end
	Economy.addCash(state, -def.cost)
	game.walking[uid] = nil
	local buyPrompt = walking.model:FindFirstChild("BuyPrompt")
	if buyPrompt then
		buyPrompt:Destroy()
	end
	local entry = Economy.ownBrainrot(game, state, def, walking.model)
	if not entry then
		Economy.addCash(state, def.cost)
		return nil, "base_full"
	end
	return entry
end

-- Every second, every owned brainrot pays its owner.
function Economy.startIncomeLoop(game)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, state in pairs(game.players) do
				local income = Economy.getIncomePerSec(state)
				if income > 0 then
					Economy.addCash(state, income)
				end
				local remote = game.remotes.HudUpdate
				if remote and player.Parent then
					local ownedIds = {}
					for _, owned in ipairs(state.owned) do
						table.insert(ownedIds, owned.defId)
					end
					remote:FireClient(player, {
						cash = math.floor(state.cash),
						incomePerSec = income,
						ownedCount = #state.owned,
						multiplier = state.multiplier,
						rebirths = state.rebirths,
						ownedIds = ownedIds,
					})
				end
			end
		end
	end)
end

return Economy
