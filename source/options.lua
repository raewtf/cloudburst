-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText
local lower <const> = string.lower

class('options').extends(gfx.sprite) -- Create the scene's class
function options:init(...)
	options.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?
	pd.datastore.write(save)

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		pauseimage('options')
	end

	assets = {
		ashe = gfx.font.new('fonts/ashe'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		sasser = gfx.font.new('fonts/sasser'),
		roobert11 = gfx.font.new('fonts/roobert11'),
		move = smp.new('audio/sfx/move'),
		select = smp.new('audio/sfx/select'),
		back = smp.new('audio/sfx/back'),
		crank = smp.new('audio/sfx/crank'),
	}

	gfx.setFont(assets.smallcaps)

	vars = {
		selections = {'changearea', 'recentareas', 'temp', 'meas', 'refresh', 'lock', 'twofour', 'music', 'sfx', 'wallpaper', 'invert'},
		selection = 1,
		selection_timer = pd.timer.new(1, 1, 1),
		lastbump = false,
	}
	vars.optionsHandlers = {
		upButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
				if vars.selection > 1 then
					vars.selection -= 1
				else
					vars.selection = #vars.selections
				end
				vars.selection_timer:resetnew(50, vars.selection_timer.value, vars.selection)
				vars.lastbump = true
				if save.sfx then assets.move:play() end
			end)
		end,

		upButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		downButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
				if vars.selection < #vars.selections then
					vars.selection += 1
				else
					vars.selection = 1
				end
				vars.selection_timer:resetnew(50, vars.selection_timer.value, vars.selection)
				vars.lastbump = true
				if save.sfx then assets.move:play() end
			end)
		end,

		downButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		leftButtonDown = function()
			if vars.selections[vars.selection] == 'recentareas' then
				if save.recentareas == 51 then
					save.recentareas = 50
				elseif save.recentareas == 50 then
					save.recentareas = 25
				elseif save.recentareas == 25 then
					save.recentareas = 10
				elseif save.recentareas == 10 then
					save.recentareas = 5
				elseif save.recentareas == 5 then
					save.recentareas = 3
				elseif save.recentareas == 3 then
					save.recentareas = 0
				elseif save.recentareas == 0 then
					save.recentareas = 51
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'temp' then
				if save.temp == "celsius" then
					save.temp = "fahrenheit"
				else
					save.temp = "celsius"
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'meas' then
				if save.speed == "kph" then
					save.speed = "mph"
					save.meas = "inch"
				else
					save.speed = "kph"
					save.meas = "mm"
				end
				if save.sfx then assets.move:play() end
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
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'lock' then
				save.autolock -= 5
				if save.autolock < 10 then
					save.autolock = 50
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'twofour' then
				save.twofour -= 1
				if save.twofour < 1 then
					save.twofour = 3
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'music' then
				save.music = not save.music
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'sfx' then
				save.sfx = not save.sfx
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'wallpaper' then
				save.wallpaper -= 1
				if save.wallpaper < 1 then
					if pd.datastore.readImage('images/custom') ~= nil then
						save.wallpaper = 5
					else
						save.wallpaper = 4
					end
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'invert' then
				save.invert -= 1
				if save.invert < 1 then
					save.invert = 3
				end
				if save.invert == 1 then
					pd.display.setInverted(false)
				elseif save.invert == 2 then
					pd.display.setInverted(true)
				elseif save.invert == 3 then
					if time.hour >= 12 then
						pd.display.setInverted(true)
					end
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'retro' then
				save.retro = not save.retro
				if save.sfx then assets.move:play() end
			end
			gfx.sprite.redrawBackground()
		end,

		rightButtonDown = function()
			if vars.selections[vars.selection] == 'recentareas' then
				if save.recentareas == 0 then
					save.recentareas = 3
				elseif save.recentareas == 3 then
					save.recentareas = 5
				elseif save.recentareas == 5 then
					save.recentareas = 10
				elseif save.recentareas == 10 then
					save.recentareas = 25
				elseif save.recentareas == 25 then
					save.recentareas = 50
				elseif save.recentareas == 50 then
					save.recentareas = 51
				elseif save.recentareas == 51 then
					save.recentareas = 0
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'temp' then
				if save.temp == "celsius" then
					save.temp = "fahrenheit"
				else
					save.temp = "celsius"
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'meas' then
				if save.speed == "kph" then
					save.speed = "mph"
					save.meas = "inch"
				else
					save.speed = "kph"
					save.meas = "mm"
				end
				if save.sfx then assets.move:play() end
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
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'lock' then
				save.autolock += 5
				if save.autolock > 50 then
					save.autolock = 10
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'twofour' then
				save.twofour += 1
				if save.twofour > 3 then
					save.twofour = 1
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'music' then
				save.music = not save.music
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'sfx' then
				save.sfx = not save.sfx
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'wallpaper' then
				save.wallpaper += 1
				if pd.datastore.readImage('images/custom') ~= nil then
					if save.wallpaper > 5 then
						save.wallpaper = 1
					end
				else
					if save.wallpaper > 4 then
						save.wallpaper = 1
					end
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'invert' then
				save.invert += 1
				if save.invert > 3 then
					save.invert = 1
				end
				if save.invert == 1 then
					pd.display.setInverted(false)
				elseif save.invert == 2 then
					pd.display.setInverted(true)
				elseif save.invert == 3 then
					if time.hour >= 12 then
						pd.display.setInverted(true)
					end
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'retro' then
				save.retro = not save.retro
				if save.sfx then assets.move:play() end
			end
			gfx.sprite.redrawBackground()
		end,

		AButtonDown = function()
			if vars.selections[vars.selection] == 'changearea' then
				if save.recentareas == 0 or save.areas[1] == nil then
					scenemanager:transitionscene(initialization, 'changearea')
				else
					if save.recentareas ~= 51 then
						if #save.areas > save.recentareas then
							for i = save.recent, #save.areas do
								table.remove(save.areas, i)
							end
						end
					end
					scenemanager:transitionscene(initialization, 'changeareamult')
				end
				if save.sfx then assets.select:play() end
			elseif vars.selections[vars.selection] == 'recentareas' then
				if save.recentareas == 0 then
					save.recentareas = 3
				elseif save.recentareas == 3 then
					save.recentareas = 5
				elseif save.recentareas == 5 then
					save.recentareas = 10
				elseif save.recentareas == 10 then
					save.recentareas = 25
				elseif save.recentareas == 25 then
					save.recentareas = 50
				elseif save.recentareas == 50 then
					save.recentareas = 51
				elseif save.recentareas == 51 then
					save.recentareas = 0
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'temp' then
				if save.temp == "celsius" then
					save.temp = "fahrenheit"
				else
					save.temp = "celsius"
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'meas' then
				if save.speed == "kph" then
					save.speed = "mph"
					save.meas = "inch"
				else
					save.speed = "kph"
					save.meas = "mm"
				end
				if save.sfx then assets.move:play() end
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
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'lock' then
				save.autolock += 5
				if save.autolock > 50 then
					save.autolock = 10
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'twofour' then
				save.twofour += 1
				if save.twofour > 3 then
					save.twofour = 1
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'music' then
				save.music = not save.music
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'sfx' then
				save.sfx = not save.sfx
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'wallpaper' then
				save.wallpaper += 1
				if pd.datastore.readImage('images/custom') ~= nil then
					if save.wallpaper > 5 then
						save.wallpaper = 1
					end
				else
					if save.wallpaper > 4 then
						save.wallpaper = 1
					end
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'invert' then
				save.invert += 1
				if save.invert > 3 then
					save.invert = 1
				end
				if save.invert == 1 then
					pd.display.setInverted(false)
				elseif save.invert == 2 then
					pd.display.setInverted(true)
				elseif save.invert == 3 then
					if time.hour >= 12 then
						pd.display.setInverted(true)
					end
				end
				if save.sfx then assets.move:play() end
			elseif vars.selections[vars.selection] == 'retro' then
				save.retro = not save.retro
				if save.sfx then assets.move:play() end
			end
			gfx.sprite.redrawBackground()
		end,

		BButtonDown = function()
			if save.recentareas == 0 then
				save.areas = {}
			else
				if save.recentareas ~= 51 then
					if #save.areas > save.recentareas then
						for i = save.recent, #save.areas do
							table.remove(save.areas, i)
						end
					end
				end
			end
			if save.sfx then assets.back:play() end
			scenemanager:transitionscene(weather)
		end,
	}
	pd.inputHandlers.push(vars.optionsHandlers)

	vars.selection_timer.discardOnCompletion = false
	if save.found_retro then
		table.insert(vars.selections, 'retro')
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 120, 400, 30)
		gfx.setColor(gfx.kColorBlack)
		assets.roobert11:drawTextAligned(text('options_changearea'), 190, 154 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_recentareas'), 190, 184 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_temp'), 190, 214 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_meas'), 190, 244 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_refresh'), 190, 274 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_lock'), 190, 304 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_twofour'), 190, 334 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_music'), 190, 364 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_sfx'), 190, 394 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_wallpaper'), 190, 424 - (30 * vars.selection_timer.value), kTextAlignment.right)
		assets.roobert11:drawTextAligned(text('options_invert'), 190, 454 - (30 * vars.selection_timer.value), kTextAlignment.right)
		if save.found_retro then assets.roobert11:drawTextAligned(text('options_retro'), 190, 484 - (30 * vars.selection_timer.value), kTextAlignment.right) end
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRoundRect(210, 154 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 184 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 214 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 244 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 274 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 304 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 334 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 364 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 394 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 424 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.fillRoundRect(210, 454 - (30 * vars.selection_timer.value), 125, 20, 5)
		if save.found_retro then gfx.fillRoundRect(210, 484 - (30 * vars.selection_timer.value), 125, 20, 5) end
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRoundRect(210, 154 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 184 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 214 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 244 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 274 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 304 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 334 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 364 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 394 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 424 - (30 * vars.selection_timer.value), 125, 20, 5)
		gfx.drawRoundRect(210, 454 - (30 * vars.selection_timer.value), 125, 20, 5)
		if save.found_retro then gfx.drawRoundRect(210, 484 - (30 * vars.selection_timer.value), 125, 20, 5) end
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		gfx.drawTextInRect(lower(save.area), 272 - 60, 156 - (30 * vars.selection_timer.value), 120, 30, 0, '...', kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_recentareas' .. save.recentareas), 272, 186 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_' .. save.temp), 272, 216 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(save.speed == "kph" and text('options_metric') or text('options_imperial'), 272, 246 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_refresh' .. save.refresh), 272, 276 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_lock' .. save.autolock), 272, 306 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_twofour' .. save.twofour), 272, 336 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_' .. tostring(save.music)), 272, 366 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_' .. tostring(save.sfx)), 272, 396 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_wallpaper' .. save.wallpaper), 272, 426 - (30 * vars.selection_timer.value), kTextAlignment.center)
		assets.smallcaps:drawTextAligned(text('options_invert' .. save.invert), 272, 456 - (30 * vars.selection_timer.value), kTextAlignment.center)
		if save.found_retro then assets.smallcaps:drawTextAligned(text('options_' .. tostring(save.retro)), 272, 486 - (30 * vars.selection_timer.value), kTextAlignment.center) end
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 0, 400, 45)
		gfx.fillRect(0, 208, 400, 45)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawLine(0, 45, 400, 45)
		gfx.drawLine(0, 208, 400, 208)
		assets.ashe:drawTextAligned(text('options'), 200, 10, kTextAlignment.center)
		if vars.selections[vars.selection] == 'changearea' then
			assets.roobert11:drawTextAligned(text('select_crank'), 200, 215, kTextAlignment.center)
		else
			assets.roobert11:drawTextAligned(text('options_controls'), 200, 215, kTextAlignment.center)
		end
		gfx.setDitherPattern(0.50, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRoundRect(384, 51, 11, 151, 5)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(382, 50 + ((vars.selection_timer.value-1) * (#vars.selections)), 15, 155/(#vars.selections/3), 8)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRoundRect(382, 50 + ((vars.selection_timer.value-1) * (#vars.selections)), 15, 155/(#vars.selections/3), 8)
	end)

	self:add()
	pd.getCrankTicks(5)
end

function options:update()
	if vars.selection_timer.value ~= vars.selection then
		gfx.sprite.redrawBackground()
	elseif vars.lastbump then
		gfx.sprite.redrawBackground()
		vars.lastbump = false
	end
	local ticks = pd.getCrankTicks(5)
	if ticks ~= 0 and vars.selection > 0 then
		if save.sfx then assets.crank:play() end
		vars.selection += ticks
		if vars.selection < 1 then
			vars.selection = #vars.selections
		elseif vars.selection > #vars.selections then
			vars.selection = 1
		end
		vars.selection_timer:resetnew(50, vars.selection_timer.value, vars.selection)
		vars.lastbump = true
	end
end