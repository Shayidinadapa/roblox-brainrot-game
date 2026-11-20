-- Hud.client: the Brainrot Bay interface.
-- Money, income rate, and multiplier sit top-right (clear of the Roblox
-- menu buttons in the top-left corner). Owned brainrots list down the
-- right side, the rebirth button sits bottom-right, and a toast line
-- under the title carries server notices: purchases, steals, locks.
-- The slap glove is wired here too: activating it asks the server to slap.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("BrainrotBayHud") then
	return
end

local hudUpdate = ReplicatedStorage:WaitForChild("HudUpdate")
local noticeRemote = ReplicatedStorage:WaitForChild("Notice")
local rebirthRemote = ReplicatedStorage:WaitForChild("RebirthRequest")
local slapRemote = ReplicatedStorage:WaitForChild("SlapRequest")

local function formatMoney(amount)
	local text = tostring(math.floor(amount))
	local result = ""
	while #text > 3 do
		result = "," .. string.sub(text, -3) .. result
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. result
end

local function makeLabel(parent, name, size, position, text, textColor, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextStrokeTransparency = 0.1
	label.TextScaled = true
	label.Font = font or Enum.Font.GothamBold
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Title, top-center.
makeLabel(gui, "Title", UDim2.new(0, 320, 0, 44), UDim2.new(0.5, -160, 0, 8),
	"BRAINROT BAY", Color3.fromRGB(255, 220, 80), Enum.Font.FredokaOne)

-- Toast line under the title.
local toast = makeLabel(gui, "Toast", UDim2.new(0, 520, 0, 30), UDim2.new(0.5, -260, 0, 56),
	"", Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
toast.TextTransparency = 1

-- Money panel, top-right.
local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "MoneyFrame"
moneyFrame.Size = UDim2.new(0, 260, 0, 110)
moneyFrame.Position = UDim2.new(1, -276, 0, 12)
moneyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
moneyFrame.BackgroundTransparency = 0.25
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = gui
local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 12)
moneyCorner.Parent = moneyFrame

local cashLabel = makeLabel(moneyFrame, "CashLabel", UDim2.new(1, -16, 0, 44), UDim2.new(0, 8, 0, 6),
	"$0", Color3.fromRGB(90, 255, 120), Enum.Font.FredokaOne)
local incomeLabel = makeLabel(moneyFrame, "IncomeLabel", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 52),
	"+$0/sec", Color3.fromRGB(255, 255, 255))
local multLabel = makeLabel(moneyFrame, "MultiplierLabel", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 80),
	"Income x1.0", Color3.fromRGB(255, 210, 60))

-- Owned list, right side under the money panel.
local ownedFrame = Instance.new("Frame")
ownedFrame.Name = "OwnedFrame"
ownedFrame.Size = UDim2.new(0, 260, 0, 220)
ownedFrame.Position = UDim2.new(1, -276, 0, 134)
ownedFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
ownedFrame.BackgroundTransparency = 0.25
ownedFrame.BorderSizePixel = 0
ownedFrame.Parent = gui
local ownedCorner = Instance.new("UICorner")
ownedCorner.CornerRadius = UDim.new(0, 12)
ownedCorner.Parent = ownedFrame
makeLabel(ownedFrame, "OwnedHeader", UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 6),
	"MY BRAINROTS (0)", Color3.fromRGB(255, 255, 255))
local ownedList = makeLabel(ownedFrame, "OwnedList", UDim2.new(1, -16, 0, 150), UDim2.new(0, 8, 0, 38),
	"No brainrots yet.\nGrab one off the conveyor!", Color3.fromRGB(200, 200, 210), Enum.Font.Gotham)
ownedList.TextYAlignment = Enum.TextYAlignment.Top
ownedList.TextXAlignment = Enum.TextXAlignment.Left
local nextLabel = makeLabel(ownedFrame, "NextLabel", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 190),
	"", Color3.fromRGB(255, 210, 60))
nextLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Rebirth button, bottom-right.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Size = UDim2.new(0, 240, 0, 52)
rebirthButton.Position = UDim2.new(1, -256, 1, -68)
rebirthButton.BackgroundColor3 = Color3.fromRGB(160, 40, 220)
rebirthButton.Text = "REBIRTH  (x1.5 income)"
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextScaled = true
rebirthButton.Font = Enum.Font.FredokaOne
rebirthButton.Parent = gui
local rebirthCorner = Instance.new("UICorner")
rebirthCorner.CornerRadius = UDim.new(0, 12)
rebirthCorner.Parent = rebirthButton

-- How to play, bottom-left.
local helpLabel = makeLabel(gui, "HelpLabel", UDim2.new(0, 430, 0, 66), UDim2.new(0, 16, 1, -82),
	"Buy brainrots off the conveyor • They earn $ on your base\nSteal from others (locked 30s after a buy) • Slap to defend\nRebirth at 4 brainrots or $15,000 for +50% income forever",
	Color3.fromRGB(255, 255, 255), Enum.Font.Gotham)
helpLabel.TextXAlignment = Enum.TextXAlignment.Left
helpLabel.TextYAlignment = Enum.TextYAlignment.Top

rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)

local toastUntil = 0
local function showToast(text)
	toast.Text = text
	toast.TextTransparency = 0
	toastUntil = os.clock() + 4
	task.delay(4, function()
		if os.clock() >= toastUntil then
			toast.TextTransparency = 1
		end
	end)
end

noticeRemote.OnClientEvent:Connect(showToast)

hudUpdate.OnClientEvent:Connect(function(data)
	cashLabel.Text = formatMoney(data.cash)
	incomeLabel.Text = "+" .. formatMoney(data.incomePerSec) .. "/sec"
	multLabel.Text = "Income x" .. tostring(data.multiplier) .. "  •  Rebirths: " .. tostring(data.rebirths)
	local header = ownedFrame:FindFirstChild("OwnedHeader")
	if header then
		header.Text = "MY BRAINROTS (" .. tostring(data.ownedCount) .. ")"
	end
	if data.ownedCount == 0 then
		ownedList.Text = "No brainrots yet.\nGrab one off the conveyor!"
	else
		local lines = {}
		for _, id in ipairs(data.ownedIds) do
			local def = BrainrotData.getById(id)
			if def then
				table.insert(lines, def.name .. "  •  " .. def.rarity .. "  •  $" .. tostring(def.income) .. "/s")
			end
		end
		ownedList.Text = table.concat(lines, "\n")
	end
	local next = BrainrotData.getNextTier(data.ownedIds)
	if next then
		nextLabel.Text = "Next: " .. next.name .. " — $" .. tostring(next.cost)
	else
		nextLabel.Text = "You own them all!"
	end
end)

-- Slap glove: activating the tool asks the server to slap.
local backpack = player:WaitForChild("Backpack")
local function wireTool(tool)
	if tool.Name == "Slap Glove" then
		tool.Activated:Connect(function()
			slapRemote:FireServer()
		end)
	end
end
for _, tool in ipairs(backpack:GetChildren()) do
	wireTool(tool)
end
backpack.ChildAdded:Connect(wireTool)
