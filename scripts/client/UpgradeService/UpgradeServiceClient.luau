--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type UpgradeId = GameTypes.UpgradeId
type UpgradePurchaseResult = GameTypes.UpgradePurchaseResult
type PurchaseMode = "ONE" | "MAX"

local remoteInstance = ReplicatedStorage.Remotes:WaitForChild("BuyUpgrade")

local buyUpgradeRemote = remoteInstance

local UpgradeServiceClient = {}

local function buyUpgrade(upgradeId: UpgradeId, mode: PurchaseMode): UpgradePurchaseResult?
	local success, result = pcall(function()
		return buyUpgradeRemote:InvokeServer(upgradeId, mode)
	end)

	if not success then
		warn("Upgrade purchase failed:", result)
		return nil
	end

	return result :: UpgradePurchaseResult
end

function UpgradeServiceClient.BuyOne(upgradeId: UpgradeId): UpgradePurchaseResult?
	return buyUpgrade(upgradeId, "ONE")
end

function UpgradeServiceClient.BuyMax(upgradeId: UpgradeId): UpgradePurchaseResult?
	return buyUpgrade(upgradeId, "MAX")
end

return UpgradeServiceClient