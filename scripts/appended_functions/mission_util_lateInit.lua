local function runAppend( modApi )
	local mission_util = include("sim/missions/mission_util")
	local makeAgentConnection_old = mission_util.makeAgentConnection
	
	mission_util.makeAgentConnection = function( script, sim, ... )
		-- log:write("[MM] makeAgentConnection append")
		makeAgentConnection_old(script, sim, ...)
		sim:triggerEvent( "agentConnectionDone" ) --used by various MM mission scripts
	end
	
	local showAugmentInstallDialog_old = mission_util.showAugmentInstallDialog
	mission_util.showAugmentInstallDialog = function( sim, item, unit )
		if not item:getTraits().augment then
			return
		end
		return showAugmentInstallDialog_old(sim, item, unit)
	end	
end

return { runAppend = runAppend }

