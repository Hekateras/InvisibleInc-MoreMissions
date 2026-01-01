local util = include("modules/util")
local abilitydefs = include("sim/abilitydefs")
local disguise = abilitydefs.lookupAbility("disguise")

local oldcanuseAbility = disguise.canUseAbility
function disguise:canUseAbility(sim, unit, ...)
	if
		unit
		and unit:getUnitData().id == "MM_mole_disguise"
		and unit:getTraits().cooldown
		and unit:getTraits().cooldown > 0
	then
		local user = unit:getUnitOwner()
		if user and not user:getTraits().disguiseOn then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN, unit:getTraits().cooldown)
		end
	end
	return oldcanuseAbility(self, sim, unit, ...)
end

