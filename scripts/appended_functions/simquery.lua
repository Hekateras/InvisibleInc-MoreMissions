local binops = include( "modules/binary_ops" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

-- This isn't defined by vanilla, but may be provided/extended by other mods
local oldCanUseLockedExit = simquery._canUseLockedExit

-- If truthy, override the op-specific checks from canModifyExit to bypass the normal locked checks.
-- This method assumes responsibility for any op-specific conditions that need to still apply (e.g. closed) before returning true.
--
-- Generic failure modes (e.g. dragging a body) will cause canModifyExit to fail with corresponding error messages, regardless of this call.
--
-- Return a mod-specific value to ease identifying which mod's override to use in simengine:modifyExit.
function simquery._canUseLockedExit( unit, exitOp, exit )
	local res = false
	if oldCanUseLockedExit then
		res = oldCanUseLockedExit( unit, exit ) 
	end

	if (not res
		and (exitOp == simdefs.EXITOP_OPEN or exitOp == simdefs.EXITOP_UNLOCK)
		and exit.closed and exit.locked
		and unit and unit:isNPC() and unit:getTraits().npcPassiveKeybits
	) then
		if binops.b_and( exit.keybits, unit:getTraits().npcPassiveKeybits ) ~= 0 then
			res = 'mm_npckey'
		end
	end

	return res
end

if not oldCanUseLockedExit then
	-- Wrap canModifyExit to check _canUseLockedExit

	local oldCanModifyExit = simquery.canModifyExit

	function simquery.canModifyExit( unit, exitOp, cell, dir, ... )
		local exit = cell.exits[ dir ]
		assert( exit and exit.door )

		if unit and simquery._canUseLockedExit( unit, exitOp, exit ) then
			-- Only check non-op-specific conditions
			return oldCanModifyExit( unit, 'NOOP', cell, dir, ... )
		end

		return oldCanModifyExit( unit, exitOp, cell, dir, ... )
	end
end

-- Disallow refit drone from pathing through lethal lasers.
local oldCanPath = simquery.canPath
function simquery.canPath( cellquery, unit, startcell, endcell, ... )
	local result, reason = oldCanPath( cellquery, unit, startcell, endcell, ... )
	if not result then
		-- Already failed. No changes needed.
		return result, reason
	end
	if not (unit and unit:getTraits().MM_agencyDynamicNonImpass) then
		-- Not a special non-vanilla unit.
		return result, reason
	end
	-- agencyDynamicNonImpass: We function like dynamicImpass=false,
	-- except that enemy impassable emitters (lethal lasers) should still be impassable.
	for i,cellUnit in ipairs(endcell.units) do
		if cellUnit:getTraits().dynamicImpass then
			-- Owned emitters will turn themselves off, so they are not considered impassable.
			-- Things that aren't emitters are passable.
			if cellUnit:getTraits().emitterID and not cellUnit:canControl( unit ) then
				return false, simdefs.CANMOVE_DYNAMIC_IMPASS
			end
		end
	end
	-- If no impassable emitters, return the original result.
	return result, reason
end
