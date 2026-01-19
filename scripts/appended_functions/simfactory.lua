local simfactory = include("sim/simfactory")

local oldcreateUnit = simfactory.createUnit
function simfactory.createUnit(unitData, ...)
	local unit = oldcreateUnit(unitData, ...)
	if unit and unit.getTraits then
		local traits = unit:getTraits()
		if traits.MM_mod_cooldownMax and traits.cooldownMax then
			traits.cooldownMax = traits.cooldownMax + traits.MM_mod_cooldownMax
		end
		if traits.MM_mod_chargesMax and traits.chargesMax then
			traits.chargesMax = traits.chargesMax + traits.MM_mod_chargesMax
			traits.charges = traits.charges + traits.MM_mod_chargesMax
		end
		if traits.MM_mod_maxAmmo and traits.maxAmmo then
			traits.maxAmmo = traits.maxAmmo + traits.MM_mod_maxAmmo
			if traits.ammo_clip then
				traits.ammo_clip = traits.ammo_clip + traits.MM_mod_maxAmmo
			end
		end
		if traits.MM_mod_pwrCost and traits.pwrCost then
			traits.pwrCost = traits.pwrCost + traits.MM_mod_pwrCost
		end
		if traits.MM_mod_requirements then
			unit:getUnitData().requirements = nil
		end
		if traits.MM_mod_armorPiercing then
			traits.armorPiercing = (traits.armorPiercing or 0) + traits.MM_mod_armorPiercing
		end
		if traits.MM_mod_damage then
			if traits.damage and traits.stun then
				traits.stun = traits.stun + traits.MM_mod_damage
			end
			if traits.damage then
				traits.damage = traits.damage + traits.MM_mod_damage
			end
			if traits.baseDamage then
				traits.baseDamage = traits.baseDamage + traits.MM_mod_damage
			end
		end
	end
	return unit
end
