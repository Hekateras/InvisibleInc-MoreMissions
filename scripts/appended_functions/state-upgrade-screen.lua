local upgradeScreen = include("states/state-upgrade-screen")
local abilitydefs = include("sim/abilitydefs")
local util = include("client_util")

local function findUpgradedProgramWidget(progList, programUpgrades, ability)
	if not ability then
		return
	end

	for abilityName, upgrade in pairs(programUpgrades) do
		if abilityName == ability.name then
			for _, item in ipairs(progList:getItems()) do
				-- not great since we identify by name and not id here...
				-- alternative would be to clear progList and build it from scratch ourselves
				-- edit: apparently we track program upgrades by name anyway so that checks out I guess
				if abilityName == item.user_data then
					return item.widget, upgrade
				end
			end
		end
	end
end

local function getUpgradeDesc(ability, upgrade, isRapier)
	local desc = ""
	local path = STRINGS.MOREMISSIONS.UI.TOOLTIPS.PROGRAM_UPGRADE
	if upgrade.parasite_strength then
		local num = upgrade.parasite_strength
		if num > 0 then
			num = "+" .. num
		end
		desc = util.sformat(path.PARASITE, num)
	elseif upgrade.break_firewalls then
		local num = upgrade.break_firewalls
		if num > 0 then
			num = "+" .. num
		end
		desc = util.sformat(path.FIREWALLS, num)
	elseif upgrade.cpu_cost then
		local num = upgrade.cpu_cost
		if num > 0 then
			num = "+" .. num
		end
		desc = util.sformat(path.PWRCOST, num)
	elseif upgrade.maxCooldown then
		local num = upgrade.maxCooldown
		if num > 0 then
			num = "+" .. num
		end
		desc = util.sformat(path.COOLDOWN, num)
	elseif upgrade.range then
		local num = upgrade.range
		if num > 0 then
			num = "+" .. num
		end
		desc = util.sformat(path.RANGE, num)
	end

	-- special tooltip for rapier
	if isRapier and upgrade.cpu_cost == -1 then
		desc = util.sformat(path.PWRCOST_Rapier, upgrade.cpu_cost)
	end
	return desc
end

local oldselectIncognita = upgradeScreen.selectIncognita
function upgradeScreen:selectIncognita(unitDef, ...)
	oldselectIncognita(self, unitDef, ...)
	local progList = self.screen:findWidget("progList")
	local programUpgrades = self._agency.MM_upgradedPrograms
	if not self._agency.abilities or not programUpgrades or not progList then
		return
	end

	for _, abilityID in ipairs(self._agency.abilities) do
		local isRapier = abilityID == "rapier"
		local ability = abilitydefs.lookupAbility(abilityID)
		local widget, upgrade = findUpgradedProgramWidget(progList, programUpgrades, ability)
		if widget then
			local desc = getUpgradeDesc(ability, upgrade, isRapier)
			widget.binder.nameTxt:setText(
				STRINGS.MOREMISSIONS.UI.TOOLTIPS.PROGRAM_UPGRADE.UPGRADED_PREFIX .. ability.name
			)
			widget.binder.MM_aiTermUpgradedTip:setVisible(true)
			widget.binder.MM_aiTermUpgradedTip:setText(
				STRINGS.MOREMISSIONS.UI.TOOLTIPS.PROGRAM_UPGRADE.UPGRADED_LONG_PREFIX .. desc
			)
			if ability.cpu_cost and upgrade.cpu_cost then
				if upgrade.cpu_cost < 0 then
					widget.binder.powerTxt:setColor(0, 1, 0, 1)
				end
				local newCpuCost = ability.cpu_cost + upgrade.cpu_cost
				if newCpuCost >= 1 then
					widget.binder.powerTxt:setText(newCpuCost)
				else
					widget.binder.powerTxt:setText("-")
				end
			end
		end
	end
end
