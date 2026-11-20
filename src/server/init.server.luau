-- init.server: Brainrot Bay starts here.
-- Builds the island, opens the remotes the client talks to, hands each
-- joining player a plot and a slap glove, then starts the conveyor and
-- the money tick. Everything else lives in the modules beside this file.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotSpawner = require(script:WaitForChild("BrainrotSpawner"))
local Economy = require(script:WaitForChild("Economy"))
local StealSystem = require(script:WaitForChild("StealSystem"))
local RebirthSystem = require(script:WaitForChild("RebirthSystem"))

local layout = WorldBuilder.buildWorld()

-- Remotes the client uses: HudUpdate + Notice go server-to-client,
-- RebirthRequest + SlapRequest go client-to-server.
local remotes = {}
for _, name in ipairs({ "HudUpdate", "Notice", "RebirthRequest", "SlapRequest" }) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	remotes[name] = remote
end

local game = {
	Players = Players,
	layout = layout,
	players = {},
	plots = {},
	walking = {},
	nextUid = 1,
	remotes = remotes,
}

-- Plot ownership: plot index -> player (or nil when free).
for i = 1, #layout.plots do
	game.plots[i] = { owner = nil }
end

local slapToolTemplate = StealSystem.buildSlapTool()

local function giveSlapTool(player)
	if player:FindFirstChild("Backpack") then
		local tool = slapToolTemplate:Clone()
		tool.Parent = player.Backpack
	end
end

local function setupPlayer(player)
	-- First free plot, first come first served.
	local plotIndex = nil
	for i, plot in ipairs(game.plots) do
		if not plot.owner then
			plotIndex = i
			plot.owner = player
			break
		end
	end
	if not plotIndex then
		plotIndex = 1
	end

	local state = Economy.createPlayerState(player, plotIndex)
	game.players[player] = state

	-- Leaderboard stats, mirrored from the state every tick.
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats
	local count = Instance.new("IntValue")
	count.Name = "Brainrots"
	count.Value = 0
	count.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	-- Starting cash so the first Common is reachable fast.
	Economy.addCash(state, 100)

	-- Write the owner's name on the plot sign.
	local plot = layout.plots[plotIndex]
	if plot and plot.signText then
		plot.signText.Text = "PLOT " .. tostring(plotIndex) .. " — " .. player.Name
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		giveSlapTool(player)
	end)
	giveSlapTool(player)
end

local function removePlayer(player)
	local state = game.players[player]
	if state then
		for _, owned in ipairs(state.owned) do
			owned.valid = false
			if owned.model and owned.model.Parent then
				owned.model:Destroy()
			end
		end
		game.players[player] = nil
	end
	for i, plot in ipairs(game.plots) do
		if plot.owner == player then
			plot.owner = nil
			local layoutPlot = layout.plots[i]
			if layoutPlot and layoutPlot.signText then
				layoutPlot.signText.Text = "PLOT " .. tostring(i) .. " — FREE"
			end
		end
	end
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

remotes.RebirthRequest.OnServerEvent:Connect(function(player)
	RebirthSystem.doRebirth(game, player)
end)

remotes.SlapRequest.OnServerEvent:Connect(function(player)
	StealSystem.handleSlap(game, player)
end)

Economy.startIncomeLoop(game)
BrainrotSpawner.start(game)
