local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )
local talkinghead_ingame = include( "client/fe/talkinghead_ingame" )

local ShowLine = talkinghead_ingame.ShowLine
talkinghead_ingame.ShowLine = function(self, idx, ...)
	-- bug fix for all scripts: wait for the previous script to fade out so
	-- the new one doesn't disappear immediately
	while self.widget:hasTransition() do
		coroutine.yield()
	end

	-- leave other scripts unchanged
	if not self.script[idx].MM_script then
		return ShowLine(self, idx, ...)
	end

	self.line_idx = idx

	if self._scriptThread then
		self._scriptThread:stop()
		self._scriptThread = nil
	end

	self:StopLine(self)

	local line = self.script[idx]
	self.line = line

	local was_viz = self.widget:isVisible()
	if (self:shouldShowSubtitles() or not line.voice) and (not self.ismainframefn or not self.ismainframefn()) then
		self.widget:setVisible(true)
	else
		self.widget:setVisible(false)
	end

	local playing_voice = false
	if line.voice then
		MOAIFmodDesigner.playSound(line.voice, "talkinghead_voice")
		playing_voice = MOAIFmodDesigner.isPlaying("talkinghead_voice")
	else
		MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/Operator/textbox")
	end

	if
		self.widget:isVisible()
		and (not was_viz or line.anim ~= self.talking_head_anim or self.line_idx == 1)
		and not self.widget:hasTransition()
	then
		self.widget:createTransition("activate_left")
	end
	self.talking_head_anim = line.anim

	self.widget.binder.profileAnim:bindBuild(line.build or line.anim)
	self.widget.binder.profileAnim:bindAnim(line.anim)
	if line.name then
		self.widget.binder.headerTxt:setText(line.name .. ":")
	else
		self.widget.binder.headerTxt:setText("")
	end

	-- new code starts here
	local lbl = self.widget.binder.bodyTxt
	lbl:spoolText(line.text, line.spoolSpeed or 30) -- added optional spoolspeed
	self._typeThread = MOAICoroutine.new()
	-- changed so it automatically turns the page after finishing the spool if the
	-- text is too long to display in a single text box
	self._typeThread:run(function()
		local page = 1
		while true do
			local frames = 0
			if not playing_voice then
				MOAIFmodDesigner.playSound("SpySociety/HUD/menu/text_print_2_LP", "MM_talkinghead_type")
			end
			lbl._cont:getProp():spool()
			while lbl:isSpooling() do
				frames = frames + 1
				coroutine.yield()
			end
			MOAIFmodDesigner.stopSound("MM_talkinghead_type")
			-- optional delay before turning the page
			if line.pageDelay and line.pageDelay[page] then
				local delay = line.pageDelay[page] * cdefs.SECONDS - frames
				if delay > 0 then
					rig_util.wait(delay)
				end
			else
				rig_util.wait(2.5 * cdefs.SECONDS)
			end
			if lbl:hasNextPage() then
				lbl:nextPage()
				page = page + 1
			else
				break
			end
		end
		self._typeThread = nil
	end)

	if self.line_idx < #self.script then
		self._scriptThread = MOAICoroutine.new()
		self._scriptThread:run(function()
			if playing_voice then
				while MOAIFmodDesigner.isPlaying("talkinghead_voice") do
					coroutine.yield()
				end
				rig_util.wait(0.2 * cdefs.SECONDS)
			else
				-- wait for typethread to terminate instead of a fixed amount of time
				-- (setting line.timing no longer does anything)
				while self._typeThread ~= nil do
					coroutine.yield()
				end
			end

			self:ShowLine(self.line_idx + 1)
		end)
	elseif self.line_idx >= #self.script then
		self._scriptThread = MOAICoroutine.new()
		self._scriptThread:run(function()
			if playing_voice then
				while MOAIFmodDesigner.isPlaying("talkinghead_voice") do
					coroutine.yield()
				end
				rig_util.wait(0.2 * cdefs.SECONDS)
			else
				-- wait for typethread to terminate instead of a fixed amount of time
				-- (setting line.timing no longer does anything)
				while self._typeThread ~= nil do
					coroutine.yield()
				end
			end

			if self.onfinished then
				self.onfinished()
			end
			self:Halt()
			self.isdone = true
		end)
	end
end

local StopLine = talkinghead_ingame.StopLine
talkinghead_ingame.StopLine = function(self, ...)
	MOAIFmodDesigner.stopSound("MM_talkinghead_type")
	StopLine(self, ...)
end

--[[ -- prevent Operator messages during mainframe mode, if we want this

--by Cyberboy2000

local oldShowLine = talkinghead_ingame.ShowLine

function talkinghead_ingame:ShowLine(idx)
    -- The placeholder is here because it's a lazy way to make the delay apply to the last line in a script (the Halt function is called from multiple places so we don't want to alter it)
    if not self.script[#self.script].placeHolder then
        table.insert( self.script, { placeHolder = true } )
    end
    
    if self.ismainframefn() then
        -- You can add additional delay or wait conditions here
        while self.ismainframefn() do
            coroutine.yield()
        end

        rig_util.wait( (self.script[idx].timing or 5) * cdefs.SECONDS)
    end
    
    if self.script[idx].placeHolder then
        -- This runs after the final line has been played
        table.remove(self.script)
        
        self:Halt()
        return
    end
    
    oldShowLine(self, idx)

end ]]--



