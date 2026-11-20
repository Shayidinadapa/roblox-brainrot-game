-- StealSystem: stealing brainrots from other players' bases, the lock
-- that protects a fresh purchase, and the slap glove players use to
-- defend their base. Stealing is the threat that forces the dash home:
-- a brainrot you just bought is locked for a while, then fair game.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotModel = require(script.Parent:WaitForChild("BrainrotModel"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local StealSystem = {}

StealSystem.SLAP_COOLDOWN = 1.5
StealSystem.SLAP_RANGE = 10
StealSystem.SLAP_POWER = 55

local slapCooldowns = {}

function StealSystem.sendNotice(game, player, text)
	local remote = game.remotes.Notice
	if remote and player.Parent then
		remote:FireClient(player, text)
	end
end

-- Put a steal prompt on an owned brainrot. It starts locked (a fresh
-- purchase cannot be stolen yet) and unlocks itself when the lock ends.
function StealSystem.attachStealPrompt(game, ownerState, entry)
	local model = entry.model
	if not model or not model.Parent then
		return
	end
	local old = model:FindFirstChild("StealPrompt")
	if old then
		old:Destroy()
	end
	local def = BrainrotData.getById(entry.defId)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ObjectText = def and def.name or "Brainrot"
	prompt.ActionText = "Steal"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = model

	task.delay(Economy.LOCK_SECONDS, function()
		if entry.valid and model.Parent then
			prompt.Enabled = true
		end
	end)

	prompt.Triggered:Connect(function(thief)
		StealSystem.trySteal(game, thief, entry.uid)
	end)
end

-- Move a brainrot from its owner to the thief's base.
function StealSystem.trySteal(game, thief, uid)
	local thiefState = game.players[thief]
	if not thiefState then
		return
	end
	local ownerState = nil
	local entry = nil
	for _, state in pairs(game.players) do
		for _, owned in ipairs(state.owned) do
			if owned.uid == uid then
				ownerState = state
				entry = owned
				break
			end
		end
		if entry then
			break
		end
	end
	if not entry or not ownerState then
		return
	end
	if ownerState.player == thief then
		StealSystem.sendNotice(game, thief, "That one is already yours!")
		return
	end
	if os.time() < entry.lockedUntil then
		local left = entry.lockedUntil - os.time()
		StealSystem.sendNotice(game, thief, "Locked! Try again in " .. tostring(left) .. "s.")
		return
	end
	local padPos, _ = Economy.getFreePadPos(game, thiefState)
	if not padPos then
		StealSystem.sendNotice(game, thief, "Your base is full! Rebirth to clear space.")
		return
	end
	local def = BrainrotData.getById(entry.defId)
	Economy.disownBrainrot(game, ownerState, uid)
	local newEntry = Economy.ownBrainrot(game, thiefState, def, entry.model)
	if not newEntry then
		return
	end
	StealSystem.attachStealPrompt(game, thiefState, newEntry)
	StealSystem.sendNotice(game, thief, "You stole " .. def.name .. "!")
	StealSystem.sendNotice(game, ownerState.player, thief.Name .. " stole your " .. def.name .. "!")
end

-- Build the slap glove tool: a Tool with a handle. Activation is
-- handled by the client firing SlapRequest (see init).
function StealSystem.buildSlapTool()
	local tool = Instance.new("Tool")
	tool.Name = "Slap Glove"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(1, 1.5, 2.5)
	handle.Color = Color3.fromRGB(255, 120, 160)
	handle.Material = Enum.Material.Neon
	handle.Parent = tool
	return tool
end

-- A slap flings every nearby player away from the slapper.
function StealSystem.handleSlap(game, player)
	local now = os.clock()
	if slapCooldowns[player] and now - slapCooldowns[player] < StealSystem.SLAP_COOLDOWN then
		return
	end
	slapCooldowns[player] = now
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, other in ipairs(game.Players:GetPlayers()) do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local delta = otherRoot.Position - root.Position
				delta = Vector3.new(delta.X, 0, delta.Z)
				if delta.Magnitude < StealSystem.SLAP_RANGE and delta.Magnitude > 0.1 then
					local direction = delta.Unit
					otherRoot.AssemblyLinearVelocity = direction * StealSystem.SLAP_POWER
						+ Vector3.new(0, 35, 0)
				end
			end
		end
	end
end

return StealSystem
