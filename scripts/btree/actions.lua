local array = include("modules/array")
local util = include("modules/util")
local simdefs = include("sim/simdefs")
local Actions = include("sim/btree/actions")

function Actions.mmArmVip( sim, unit )
	unit:getTraits().mmSearchedVipSafe = true
	unit:getTraits().vip = false

	-- Let mission script handle the weapon transfer
	sim:triggerEvent( "MM-VIP-ARMING", {unit=unit} )

	return simdefs.BSTATE_COMPLETE
end

function Actions.mmRequestNewPanicTarget( sim, unit )

	local rememberedInterest = unit:getBrain():getSenses():getRememberedInterest()
	if rememberedInterest then
		unit:getBrain():getSenses():addInterest( rememberedInterest.x, rememberedInterest.y, rememberedInterest.sense, rememberedInterest.reason, rememberedInterest.sourceUnit )
		return simdefs.BSTATE_COMPLETE
	end

	local x0,y0 = unit:getLocation()
	local cells = sim:getCells( "saferoom" )
	local doorCell = sim:getCells( "saferoom_door" ) and sim:getCells( "saferoom_door" )[1]
	local targetCell = nil

	if cells then
		cells = util.tdupe( cells )
		local function isInvalidHuntCell(c)
			return (
				-- open cells
				c.impass > 0
				-- not near the CEO's current position
				or (math.abs(c.x - x0) <= 2 and math.abs(c.y - y0) <= 2)
				-- not at the door (don't accidentally open the door to peek)
				or (doorCell and c.x == doorCell.x and c.y == doorCell.y)
			)
		end
		array.removeIf( cells, isInvalidHuntCell )

		targetCell = cells[sim:nextRand(1, #cells)]
	end

	if not targetCell then
		return simdefs.BSTATE_FAILED
	end

	unit:getBrain():getSenses():addInterest( targetCell.x, targetCell.y, simdefs.SENSE_RADIO, simdefs.REASON_HUNTING, unit )

	return simdefs.BSTATE_COMPLETE
end
