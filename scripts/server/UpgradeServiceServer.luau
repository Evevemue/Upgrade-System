--!strict

local RS = game:GetService("ReplicatedStorage")
local DataService = require(RS:WaitForChild("Packages"):WaitForChild("DataService")).server
local UpgradeDefinitions = require(RS:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("UpgradeDefinitions"))
local GameTypes = require(RS:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("GameTypes"))

type UpgradeDefinition = UpgradeDefinitions.UpgradeDefinition
type UpgradePurchaseResult = GameTypes.UpgradePurchaseResult
type UpgradePurchaseCode = GameTypes.UpgradePurchaseCode
type UpgradeId = GameTypes.UpgradeId

local buyUpgradeRemote = RS:WaitForChild("Remotes"):WaitForChild("BuyUpgrade")

local purchasingPlrs: {[Player]: boolean} = {}

local UpgradeServiceServer = {}

function UpgradeServiceServer.TryBuyUpgrade(plr: Player,rawUpgradeId: unknown,rawMode: unknown): UpgradePurchaseResult
	if purchasingPlrs[plr] then
		return {
			Success = false,
			Code = "BUSY",
			NewLevel = nil,
			NewGold = nil,
		}
	end

	purchasingPlrs[plr] = true

	local function finish(result: UpgradePurchaseResult): UpgradePurchaseResult
		purchasingPlrs[plr] = nil
		return result
	end

	if type(rawUpgradeId) ~= "string" then
		return finish({
			Success = false,
			Code = "INVALID_UPGRADE",
			NewLevel = nil,
			NewGold = nil,
		})
	end

	if rawMode ~= "ONE" and rawMode ~= "MAX" then
		return finish({
			Success = false,
			Code = "INVALID_MODE",
			NewLevel = nil,
			NewGold = nil,
		})
	end

	local upgrade = UpgradeDefinitions.Definitions[rawUpgradeId :: UpgradeId]

	if upgrade == nil then
		return finish({
			Success = false,
			Code = "INVALID_UPGRADE",
			NewLevel = nil,
			NewGold = nil,
		})
	end

	local upgradeId = upgrade.Id
	local mode = rawMode :: "ONE" | "MAX"

	local upgrades = DataService:get(plr, "upgrades")

	if type(upgrades) ~= "table" then
		upgrades = {}
	end

	local storedLevel = upgrades[upgradeId]

	local currentLevel = if type(storedLevel) == "number"
		then math.clamp(math.floor(storedLevel), 0, upgrade.MaxLevel)
		else 0

	if UpgradeDefinitions.IsMaxLevel(upgradeId, currentLevel) then
		return finish({
			Success = false,
			Code = "MAX_LEVEL",
			NewLevel = upgrade.MaxLevel,
			NewGold = nil,
		})
	end

	local storedGold = DataService:get(plr, "gold")
	local currentGold = if type(storedGold) == "number"
		then math.max(0, storedGold)
		else 0

	local newLevel = currentLevel
	local totalPrice = 0

	local maximumPurchases = if mode == "ONE"
		then 1
		else upgrade.MaxLevel - currentLevel

	for _ = 1, maximumPurchases do
		local nextPrice = UpgradeDefinitions.GetPrice(upgradeId, newLevel)

		if nextPrice == nil then
			break
		end

		if totalPrice + nextPrice > currentGold then
			break
		end

		totalPrice += nextPrice
		newLevel += 1
	end

	if newLevel == currentLevel then
		return finish({
			Success = false,
			Code = "NOT_ENOUGH_GOLD",
			NewLevel = currentLevel,
			NewGold = currentGold,
		})
	end

	local newGold = currentGold - totalPrice

	local updateSuccess, updateError = pcall(function()
		DataService:update(plr, "upgrades", function(currentUpgrades)
			if type(currentUpgrades) ~= "table" then
				currentUpgrades = {}
			end

			currentUpgrades[upgradeId] = newLevel

			return currentUpgrades
		end)

		DataService:update(plr, "gold", function()
			return newGold
		end)
	end)

	if not updateSuccess then
		warn(
			string.format(
				"Failed to purchase upgrade for %s: %s",
				plr.Name,
				tostring(updateError)
			)
		)

		return finish({
			Success = false,
			Code = "SERVER_ERROR",
			NewLevel = nil,
			NewGold = nil,
		})
	end

	return finish({
		Success = true,
		Code = "SUCCESS",
		NewLevel = newLevel,
		NewGold = newGold,
	})
end

function UpgradeServiceServer.init()
	buyUpgradeRemote.OnServerInvoke = function(plr: Player, upgradeId: unknown, mode: unknown): UpgradePurchaseResult
		return UpgradeServiceServer.TryBuyUpgrade(plr, upgradeId, mode)
	end
end

return UpgradeServiceServer
