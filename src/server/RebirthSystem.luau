-- RebirthSystem: trade everything you own for a permanent income boost.
-- Rebirth needs either a real collection (4+ brainrots) or a fat wallet
-- ($15,000). It wipes cash and brainrots, clears the base, and adds
-- +50% income forever. Rebirthing is how a player climbs past the point
-- where the conveyor's prices stop mattering.

local Economy = require(script.Parent:WaitForChild("Economy"))

local RebirthSystem = {}

RebirthSystem.MIN_BRAINROTS = 4
RebirthSystem.MIN_CASH = 15000
RebirthSystem.MULTIPLIER_PER_REBIRTH = 0.5

function RebirthSystem.canRebirth(state)
	return #state.owned >= RebirthSystem.MIN_BRAINROTS or state.cash >= RebirthSystem.MIN_CASH
end

function RebirthSystem.doRebirth(game, player)
	local state = game.players[player]
	if not state then
		return false, "no_state"
	end
	if not RebirthSystem.canRebirth(state) then
		return false, "not_ready"
	end
	for _, owned in ipairs(state.owned) do
		owned.valid = false
		if owned.model and owned.model.Parent then
			owned.model:Destroy()
		end
	end
	state.owned = {}
	state.cash = 0
	state.multiplier += RebirthSystem.MULTIPLIER_PER_REBIRTH
	state.rebirths += 1
	Economy.syncLeaderstats(state)
	local remote = game.remotes.Notice
	if remote and player.Parent then
		remote:FireClient(player, "REBIRTH! Income is now x" .. tostring(state.multiplier) .. ".")
	end
	return true
end

return RebirthSystem
