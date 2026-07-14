--!strict

local RS = game:GetService("ReplicatedStorage")
local UgradeTileView = require(RS:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("UpgradeTileView"))
local UpgradeTileTemplate = RS:WaitForChild("Assets"):WaitForChild("UpgradeTileTemplate")

local container = workspace:WaitForChild("Map"):WaitForChild("ResearchStation")
	:WaitForChild("UpgradeScreen"):WaitForChild("SurfaceGui"):WaitForChild("MainFrame"):WaitForChild("ScrollingFrame")

local GameTypes = require(RS:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("GameTypes"))
local UpgradeDefinitions = require(RS:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("UpgradeDefinitions"))
type UpgradeDefinition = UpgradeDefinitions.UpgradeDefinition
type UpgradeId = GameTypes.UpgradeId
local definitions = UpgradeDefinitions.Definitions

local UpgradeBoardServiceClient = {}

function UpgradeBoardServiceClient.init()
	for _, upgrade in pairs(definitions) do
		local tile = UpgradeTileTemplate:Clone()
		tile.Name = upgrade.Id
		tile.Parent = container
		UgradeTileView.Setup(tile, upgrade)
	end
end

return UpgradeBoardServiceClient
