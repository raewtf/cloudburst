-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('options').extends(gfx.sprite) -- Create the scene's class
function options:init(...)
	options.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
	end

	assets = {
		ashe = gfx.font.new('fonts/ashe'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		sasser = gfx.font.new('fonts/sasser'),
		roobert11 = gfx.font.new('fonts/roobert11'),
		roobert24 = gfx.font.new('fonts/roobert24')
	}

	vars = {
		selections = {'changearea', 'temp', 'meas', 'refresh', 'lock'},
		selection = 1,
	}
	vars.optionsHandlers = {
		upButtonDown = function()
			if vars.selection ~= 0 then
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
					if vars.selection > 1 then
						vars.selection -= 1
					else
						vars.selection = #vars.selections
					end
					gfx.sprite.redrawBackground()
				end)
			end
		end,

		upButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		downButtonDown = function()
			if vars.selection ~= 0 then
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
					if vars.selection < #vars.selections then
						vars.selection += 1
					else
						vars.selection = 1
					end
					gfx.sprite.redrawBackground()
				end)
			end
		end,

		downButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		leftButtonDown = function()
			gfx.sprite.redrawBackground()
			if vars.selections[vars.selection] == 'temp' then
				if save.temp == "celsius" then
					save.temp = "fahrenheit"
				else
					save.temp = "celsius"
				end
			elseif vars.selections[vars.selection] == 'meas' then
				if save.speed == "kph" then
					save.speed = "mph"
					save.meas = "inch"
				else
					save.speed = "kph"
					save.meas = "mm"
				end
			elseif vars.selections[vars.selection] == 'refresh' then
				if save.refresh == '15m' then
					save.refresh = 'manual'
				elseif save.refresh == '30m' then
					save.refresh = '15m'
				elseif save.refresh == '1hr' then
					save.refresh = '30m'
				elseif save.refresh == '2hr' then
					save.refresh = '1hr'
				elseif save.refresh == '4hr' then
					save.refresh = '2hr'
				elseif save.refresh == '8hr' then
					save.refresh = '4hr'
				elseif save.refresh == 'manual' then
					save.refresh = '8hr'
				end
			elseif vars.selections[vars.selection] == 'lock' then
				save.autolock -= 5
				if save.autolock < 10 then
					save.autolock = 50
				end
			end
		end,

		rightButtonDown = function()
			gfx.sprite.redrawBackground()
			if vars.selections[vars.selection] == 'temp' then
				if save.temp == "celsius" then
					save.temp = "fahrenheit"
				else
					save.temp = "celsius"
				end
			elseif vars.selections[vars.selection] == 'meas' then
				if save.speed == "kph" then
					save.speed = "mph"
					save.meas = "inch"
				else
					save.speed = "kph"
					save.meas = "mm"
				end
			elseif vars.selections[vars.selection] == 'refresh' then
				if save.refresh == '15m' then
					save.refresh = '30m'
				elseif save.refresh == '30m' then
					save.refresh = '1hr'
				elseif save.refresh == '1hr' then
					save.refresh = '2hr'
				elseif save.refresh == '2hr' then
					save.refresh = '4hr'
				elseif save.refresh == '4hr' then
					save.refresh = '8hr'
				elseif save.refresh == '8hr' then
					save.refresh = 'manual'
				elseif save.refresh == 'manual' then
					save.refresh = '15m'
				end
			elseif vars.selections[vars.selection] == 'lock' then
				save.autolock += 5
				if save.autolock > 50 then
					save.autolock = 10
				end
			end
		end,

		AButtonDown = function()
			if vars.selections[vars.selection] == 'changearea' then
				scenemanager:transitionscene(initialization, 'changearea')
			end
		end,

		BButtonDown = function()
			scenemanager:transitionscene(weather)
		end,
	}
	pd.inputHandlers.push(vars.optionsHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.ashe:drawTextAligned(text('options'), 200, 10, kTextAlignment.center)
		gfx.drawLine(0, 45, 400, 45)
		gfx.drawLine(0, 208, 400, 208)
		gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 45, 400, 165)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 20 + (30 * vars.selection), 400, 30)
		gfx.setColor(gfx.kColorBlack)
		assets.roobert11:drawTextAligned(text('options_changearea'), 200, 55, kTextAlignment.center)
		assets.roobert11:drawTextAligned(text('options_temp'), 190, 85, kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_meas'), 190, 115, kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_refresh'), 190, 145, kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_lock'), 190, 175, kTextAlignment.right)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRoundRect(210, 85, 125, 20, 5)
		gfx.fillRoundRect(210, 115, 125, 20, 5)
		gfx.fillRoundRect(210, 145, 125, 20, 5)
		gfx.fillRoundRect(210, 175, 125, 20, 5)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRoundRect(210, 85, 125, 20, 5)
		gfx.drawRoundRect(210, 115, 125, 20, 5)
		gfx.drawRoundRect(210, 145, 125, 20, 5)
		gfx.drawRoundRect(210, 175, 125, 20, 5)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.smallcaps:drawTextAligned(text('options_' .. save.temp), 272, 87, kTextAlignment.center)
		assets.smallcaps:drawTextAligned(save.speed == "kph" and text('options_metric') or text('options_imperial'), 272, 117, kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_refresh' .. save.refresh), 272, 147, kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_lock' .. save.autolock), 272, 177, kTextAlignment.center)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		if vars.selections[vars.selection] == 'changearea' then
			assets.roobert11:drawTextAligned(text('options_controls2'), 200, 215, kTextAlignment.center)
		else
			assets.roobert11:drawTextAligned(text('options_controls'), 200, 215, kTextAlignment.center)
		end
	end)

	self:add()
	pd.getCrankTicks(5)
end

function options:update()
	local ticks = pd.getCrankTicks(5)
	if ticks ~= 0 and vars.selection > 0 then
		vars.selection += ticks
		if vars.selection < 1 then
			vars.selection = #vars.selections
		elseif vars.selection > #vars.selections then
			vars.selection = 1
		end
		gfx.sprite.redrawBackground()
	end
end