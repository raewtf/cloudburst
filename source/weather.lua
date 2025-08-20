-- Setting up consts
local pd <const> = playdate
local net <const> = pd.network
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText
local sec, ms = pd.getSecondsSinceEpoch()
local floor <const> = math.floor
local ceil <const> = math.ceil
local random <const> = math.random
local format <const> = string.format
local lower <const> = string.lower
local find <const> = string.find
local len <const> = string.len
local byte <const> = string.byte
local sub <const> = string.sub
local gmatch <const> = string.gmatch

class('weather').extends(gfx.sprite) -- Create the scene's class
function weather:init(...)
	weather.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?
	pd.datastore.write(save)
	pd.setAutoLockDisabled(true)

	local lastminute = time.minute

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			if not vars.refreshing then
				menu:addMenuItem(text('refresh'), function()
					weather:refresh()
				end)
			end
			menu:addMenuItem(text('options'), function()
				vars.lo_power = false
				pd.display.setRefreshRate(30)
				scenemanager:transitionscene(options)
			end)
			menu:addMenuItem(text('credits'), function()
				vars.lo_power = false
				pd.display.setRefreshRate(30)
				scenemanager:transitionscene(credits)
			end)
		end
		pauseimage('weather', true)
	end

	function pd.gameWillResume()
		gfx.sprite.redrawBackground()
	end

	assets = {
		roobert11 = gfx.font.new('fonts/roobert11'),
		roobert24 = gfx.font.new('fonts/roobert24'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		fore = gfx.imagetable.new('images/fore'),
		battery = gfx.imagetable.new('images/battery'),
		thefold = gfx.image.new(400, 900),
		foldopen = smp.new('audio/sfx/foldopen'),
		foldclose = smp.new('audio/sfx/foldclose'),
		foldclosesoft = smp.new('audio/sfx/foldclosesoft'),
		foldtwang = smp.new('audio/sfx/foldtwang'),
		wind = gfx.image.new('images/wind'),
		compass = gfx.image.new('images/compass'),
		crank = smp.new('audio/sfx/crank'),
		crank_pull = smp.new('audio/sfx/crank_pull'),
		moon = gfx.imagetable.new('images/moon'),
	}

	gfx.setFont(assets.smallcaps)

	vars = {
		lastchecked = pd.getTime(),
		polygon = pd.geometry.polygon.new(0, 30, 340, 30, 360, 1, 400, 1, 400, 1000, 0, 1000, 0, 30),
		polygon2 = pd.geometry.polygon.new(0, 3, 358, 3, 340, 30, 0, 30, 0, 3),
		hourly_start = 1,
		get_data = false,
		http_opened = false,
		iwarnedyouabouthttpbroitoldyoudog = false,
		data_response = nil,
		data_response_formatted = nil,
		lo_power = false,
		chargebool = pd.getPowerStatus().charging,
		moon = random(1, 10),
		autolockdisabled = true,
		refreshing = false,
	}

	if response_json ~= nil then
		vars.localtime = pd.timeFromEpoch(response_json.location.localtime_epoch - 946684800, ms)
		vars.hourly_start = vars.localtime.hour
		vars.sunrise = response_json.forecast.forecastday[1].astro.sunrise
		vars.sunset = response_json.forecast.forecastday[1].astro.sunset
		vars.sunrise2 = response_json.forecast.forecastday[2].astro.sunrise
		vars.sunset2 = response_json.forecast.forecastday[2].astro.sunset
		self:calcsuntimes()
		vars.locallastminute = vars.localtime.minute

		weather:setuprefreshtimer()
	end

	if save.wallpaper == 1 then
		assets.default1 = gfx.image.new('images/default1')
		assets.default2 = gfx.image.new('images/default2')
		vars.default1_timer = pd.timer.new(15000, 0, -400, pd.easingFunctions.inOutSine)
		vars.default2_timer = pd.timer.new(18000, 0, -400, pd.easingFunctions.inOutSine)
		vars.default1_timer.reverses = true
		vars.default1_timer.repeats = true
		vars.default2_timer.reverses = true
		vars.default2_timer.repeats = true
	elseif save.wallpaper == 2 then
		local earthtime = args[1] or 30000
		local earthvalue = args[2] or 1
		local starsltime = args[3] or 45000
		local starslvalue = args[4] or -400
		local starsstime = args[5] or 30000
		local starssvalue = args[6] or -400
		if earthtime ~= 30000 then
			vars.ui_timer = pd.timer.new(250, -100, 0, pd.easingFunctions.outSine)
		else
			vars.ui_timer = pd.timer.new(1, 0, 0)
		end
		vars.crank_change = args[7] or 0
		assets.earth = gfx.imagetable.new('images/earth')
		assets.bg = gfx.imagetable.new('images/bg')
		assets.stars_s = gfx.image.new('images/stars_s')
		assets.stars_l = gfx.image.new('images/stars_l')
		vars.earth_timer = pd.timer.new(earthtime, earthvalue, 300)
		vars.stars_l = pd.timer.new(starsltime, starslvalue, 0)
		vars.stars_s = pd.timer.new(starsstime, starssvalue, 0)
		vars.earth_timer.timerEndedCallback = function()
			vars.earth_timer:resetnew(30000, 1, 300)
			vars.earth_timer.repeats = true
		end
		vars.stars_l.timerEndedCallback = function()
			vars.stars_l:resetnew(45000, -400, 0)
			vars.stars_l.repeats = true
		end
		vars.stars_s.timerEndedCallback = function()
			vars.stars_s:resetnew(30000, -400, 0)
			vars.stars_s.repeats = true
		end
	elseif save.wallpaper == 3 then
		assets.miko = gfx.font.new('fonts/miko')
	elseif save.wallpaper == 4 then
		assets.miko = gfx.font.new('fonts/miko')
	elseif save.wallpaper == 5 then
		assets.customimage = pd.datastore.readImage('images/custom')
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		if save.wallpaper == 1 then
			if response_json ~= nil then
				assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 18, 175)
				assets.roobert11:drawText(response_json.current.condition.text, 18, 205) -- todo: convert this to my own thing l8r
			end
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 205, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(355, 205)
			assets.default1:draw((vars.default1_timer.value // 2) * 2, 0)
			assets.default2:draw(vars.default2_timer.value, 0)
		elseif save.wallpaper == 2 then
			assets.bg[floor(random(1, 3))]:draw(0, 0)
			assets.stars_s:draw(((vars.stars_s.value + vars.crank_change) % 400) - 400, 0)
			assets.stars_l:draw(((vars.stars_l.value + (vars.crank_change / 1.2)) % 400) - 400, 0)
			assets.earth[floor((vars.earth_timer.value + (vars.crank_change / 1.8)) % 299) + 1]:draw(100, 140)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 18 + vars.ui_timer.value, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(355, 18 + vars.ui_timer.value)
			if response_json ~= nil then
				assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 18, 18 + vars.ui_timer.value or 0)
				assets.roobert11:drawText(response_json.current.condition.text, 18, 48 + vars.ui_timer.value)
			end
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		elseif save.wallpaper == 3 then
			if response_json ~= nil then
				assets.miko:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 215, 65, kTextAlignment.center)
				assets.roobert11:drawText(response_json.current.condition.text, 18, 205)
			end
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 205, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(355, 205)
		elseif save.wallpaper == 4 then
			if response_json ~= nil then
				assets.roobert11:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°, ' .. response_json.current.condition.text, 18, 205)
			end
			assets.miko:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute)), 200, 65, kTextAlignment.center)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(355, 205)
		elseif save.wallpaper == 5 then
			assets.customimage:draw(0, 0)
			if response_json ~= nil then
				assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 16, 175)
				assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 20, 175)
				assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 18, 173)
				assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 18, 177)
				assets.roobert11:drawText(response_json.current.condition.text, 16, 205)
				assets.roobert11:drawText(response_json.current.condition.text, 20, 205)
				assets.roobert11:drawText(response_json.current.condition.text, 18, 203)
				assets.roobert11:drawText(response_json.current.condition.text, 18, 207)
			end
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 343, 205, kTextAlignment.right)
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 347, 205, kTextAlignment.right)
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 203, kTextAlignment.right)
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 207, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(353, 205)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(357, 205)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(355, 203)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(355, 207)

			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			if response_json ~= nil then
				assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', 18, 175)
				assets.roobert11:drawText(response_json.current.condition.text, 18, 205)
			end
			assets.roobert11:drawTextAligned((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 205, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:draw(355, 205)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		end
	end)

	class('fold', _, classes).extends(gfx.sprite)
	function classes.fold:init()
		self:setImage(assets.thefold)
		self:setCenter(0, 0)
		self:moveTo(0, 242)
		self.open = false
		self.crank = 0
		self.lasty = 242
		self.timer = pd.timer.new(1500, 0, 0)
		self.timer.discardOnCompletion = false
		self.popped = false
		self:add()
	end
	function classes.fold:update()
		if self.open then
			if pd.buttonJustPressed('down') and self.y >= 0 then
				self.crank = 0
				self.open = false
				if save.sfx then assets.foldclose:play() end
			end
			if pd.buttonIsPressed('up') then
				self:moveBy(0, -10)
				if save.sfx and pd.getCurrentTimeMilliseconds() % 20 == 0 then
					if sprites.fold.y <= -390 then
						assets.crank_pull:play()
					else
						assets.crank:play()
					end
				end
			elseif pd.buttonIsPressed('down') then
				self:moveBy(0, 10)
				if save.sfx and pd.getCurrentTimeMilliseconds() % 20 == 0 then
					assets.crank:play()
				end
			end
			self:moveBy(0, -pd.getCrankChange())
			if self.y >= 0 then
				self.crank += pd.getCrankChange()
				self:moveTo(self.x, self.y += (0 - self.y) * 0.3)
				if self.y < 0.1 and self.y > -0.1 then
					self:moveTo(self.x, 0)
				end
			else
				self.crank = 0
			end
			if self.y <= -390 then
				self:moveTo(self.x, self.y += (-390 - self.y) * 0.3)
				if self.y < -390.1 and self.y > -389.9 then
					self:moveTo(self.x, -390)
				end
			end
			if pd.getCrankChange() > 0 then
				self.timer:resetnew(1500, 1, 0)
			end
			self.timer.timerEndedCallback = function()
				self.crank = 0
			end
			if self.crank < -100 then
				self.crank = 0
				self.open = false
				if save.sfx then assets.foldclose:play() end
			end
		else
			if pd.buttonJustPressed('up') then
				if self.popped then
					self.open = true
					if save.sfx then assets.foldopen:play() end
					self.crank = 0
					self.popped = false
				else
					self.popped = true
					if save.sfx then assets.foldtwang:play() end
					self.timer:resetnew(1500, 1, 0)
					self.crank = 30
					self:moveTo(self.x, self.y += (211 - self.y) * 0.5)
					self.timer.timerEndedCallback = function()
						if self.popped then
							self.crank = 0
							self.popped = false
							if save.sfx then assets.foldclosesoft:play() end
						end
					end
				end
			end
			if pd.buttonJustPressed('down') then
				if self.popped then
					self.crank = 0
					self.popped = false
					if save.sfx then assets.foldclosesoft:play() end
				end
			end
			self.crank += pd.getCrankChange()
			if self.crank < 0 then self.crank = 0 end
			if self.crank >= 30 then
				if not self.popped then
					self.popped = true
					if save.sfx then assets.foldtwang:play() end
				end
				self:moveBy(0, -pd.getCrankChange())
				if self.crank >= 100 then
					self.open = true
					if save.sfx then assets.foldopen:play() end
					self.crank = 0
					self.popped = false
				end
				if pd.getCrankChange() > 0 then
					self.timer:resetnew(1500, 1, 0)
				end
				self:moveTo(self.x, self.y += (211 - self.y) * 0.5)
				self.timer.timerEndedCallback = function()
					if self.popped then
						self.crank = 0
						self.popped = false
						if save.sfx then assets.foldclosesoft:play() end
					end
				end
			else
				if self.popped then
					self.crank = 0
					self.popped = false
					if save.sfx then assets.foldclosesoft:play() end
				end
				self:moveTo(self.x, self.y += (250 - self.y) * 0.3)
				if self.y < 250.1 and self.y > 249.9 then
					self:moveTo(self.x, 250)
				end
			end
		end
		self:moveTo(self.x, (self.y // 2) * 2)
		if sprites.fold.lasty ~= sprites.fold.y then
			pd.display.setRefreshRate(30)
		elseif vars.lo_power then
			pd.display.setRefreshRate(5)
		end
		self.lasty = self.y
	end

	if response_json ~= nil then
		sprites.fold = classes.fold()
		self:buildthefold()
	end

	self:add()
	pd.timer.performAfterDelay(300, function()
		if not pd.getPowerStatus().charging and not scenemanager.transitioning then
			pd.display.setRefreshRate(5)
			vars.lo_power = true
		end
	end)
end

function weather:update()
	if (save.wallpaper == 1 or save.wallpaper == 2) and (sprites.fold == nil or sprites.fold.y > 10) then
		gfx.sprite.redrawBackground()
	end
	if pd.getPowerStatus().charging ~= vars.chargebool then
		vars.chargebool = pd.getPowerStatus().charging
		if pd.getPowerStatus().charging then
			vars.lo_power = false
			pd.display.setRefreshRate(30)
		elseif not vars.lo_power and not scenemanager.transitioning then
			vars.lo_power = true
		end
	end
	if vars.chargebool then
		if sprites.fold ~= nil then
			if sprites.fold.y <= -390 then
				if pd.getCrankTicks(6) ~= 0 and save.sfx then
					assets.crank_pull:play()
				end
			else
				if pd.getCrankTicks(10) ~= 0 and save.sfx then
					assets.crank:play()
				end
			end
		end
		if save.wallpaper == 2 then
			vars.crank_change += pd.getCrankChange()
		end
	end
	sec, ms = pd.getSecondsSinceEpoch()
	if vars.localtime ~= nil then
		vars.locallastminute = vars.localtime.minute
	end
	if lastminute ~= time.minute then
		gfx.sprite.redrawBackground()
		if pd.getBatteryPercentage() < save.autolock and vars.autolockdisabled then
			pd.setAutoLockDisabled(false)
			vars.autolockdisabled = false
		elseif pd.getBatteryPercentage() > save.autolock and not vars.autolockdisabled then
			pd.setAutoLockDisabled(true)
			vars.autolockdisabled = true
		end
		pd.display.flush()
		lastminute = time.minute
	end
	if vars.get_data then
		if net.getStatus() == net.kStatusNotAvailable then
			scenemanager:transitionscene(initialization, "nointernet")
		else
			http:get("/v1/forecast.json?key=" .. key .. "&q=" .. urlencode(save.area) .. "&days=2&aqi=yes")
			http:setRequestCompleteCallback(function()
				http:setConnectTimeout(10)
				local bytes = http:getBytesAvailable()
				vars.data_response = http:read(bytes)
				if find(vars.data_response, "No matching location found.") or vars.data_response == "" then
					self:transitionscene(initialization, "noarea")
					http:close()
					return
				else
					-- chunk data here
					vars.data_response_formatted = ""
					local index = 1
					for line in gmatch(vars.data_response, "[^\r?\n]+") do
						 if index % 2 == 1 then
							  vars.data_response_formatted = vars.data_response_formatted .. line
						end
						index += 1
					end
					local response_end = 0
					for i = len(vars.data_response_formatted), 1, -1 do
						if byte(vars.data_response_formatted, i) == byte("}") then
							response_end = i
							break
						end
					end
					vars.data_response_formatted = sub(vars.data_response_formatted, 0, response_end)
					response_json = json.decode(vars.data_response_formatted)
					http:close()
					pd.scoreboards.addScore('hottestc', math.max(floor(response_json.current.temp_c), 0), function()
						pd.scoreboards.addScore('hottestf', math.max(floor((response_json.current.temp_c * 9/5) + 32), 0), function()
							pd.scoreboards.addScore('humidity', floor(response_json.current.humidity))
						end)
					end)
					vars.localtime = pd.timeFromEpoch(response_json.location.localtime_epoch - 946684800, ms)
					vars.hourly_start = vars.localtime.hour
					vars.sunrise = response_json.forecast.forecastday[1].astro.sunrise
					vars.sunset = response_json.forecast.forecastday[1].astro.sunset
					vars.sunrise2 = response_json.forecast.forecastday[2].astro.sunrise
					vars.sunset2 = response_json.forecast.forecastday[2].astro.sunset
					self:calcsuntimes()
					vars.locallastminute = vars.localtime.minute
					vars.lastchecked = pd.getTime()
					if sprites.fold == nil then
						sprites.fold = classes.fold()
					end
					self:buildthefold()
					gfx.sprite.redrawBackground()
					pd.display.flush()
				end
				vars.refreshing = false
			end)
		end
		vars.get_data = false
	end
end

function weather:calcsuntimes()
	if ((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) then
		if find(vars.sunrise, "PM") then vars.sunrise = vars.sunrise:gsub("[0-9]+", format("%02d",(tonumber(sub(vars.sunrise,1,2)) + 12) % 24), 1) end
		if find(vars.sunset, "PM") then vars.sunset = vars.sunset:gsub("[0-9]+", format("%02d",(tonumber(sub(vars.sunset,1,2)) + 12) % 24), 1) end
		if find(vars.sunrise2, "PM") then vars.sunrise2 = vars.sunrise2:gsub("[0-9]+", format("%02d",(tonumber(sub(vars.sunrise2,1,2)) + 12) % 24), 1) end
		if find(vars.sunset2, "PM") then vars.sunset2 = vars.sunset2:gsub("[0-9]+", format("%02d",(tonumber(sub(vars.sunset2,1,2)) + 12) % 24), 1) end

		vars.sunrise = vars.sunrise:gsub(" AM", "")
		vars.sunset = vars.sunset:gsub(" AM", "")
		vars.sunrise2 = vars.sunrise2:gsub(" AM", "")
		vars.sunset2 = vars.sunset2:gsub(" AM", "")

		vars.sunrise = vars.sunrise:gsub(" PM", "")
		vars.sunset = vars.sunset:gsub(" PM", "")
		vars.sunrise2 = vars.sunrise2:gsub(" PM", "")
		vars.sunset2 = vars.sunset2:gsub(" PM", "")
	else
		vars.sunrise = vars.sunrise:gsub("[0-9]+", tonumber(sub(vars.sunrise,1,2)), 1)
		vars.sunset = vars.sunset:gsub("[0-9]+", tonumber(sub(vars.sunset,1,2)), 1)
		vars.sunrise2 = vars.sunrise2:gsub("[0-9]+", tonumber(sub(vars.sunrise2,1,2)), 1)
		vars.sunset2 = vars.sunset2:gsub("[0-9]+", tonumber(sub(vars.sunset2,1,2)), 1)

		vars.sunrise = vars.sunrise:gsub(" AM", "a")
		vars.sunset = vars.sunset:gsub(" AM", "a")
		vars.sunrise2 = vars.sunrise2:gsub(" AM", "a")
		vars.sunset2 = vars.sunset2:gsub(" AM", "a")

		vars.sunrise = vars.sunrise:gsub(" PM", "p")
		vars.sunset = vars.sunset:gsub(" PM", "p")
		vars.sunrise2 = vars.sunrise2:gsub(" PM", "p")
		vars.sunset2 = vars.sunset2:gsub(" PM", "p")
	end
end

function weather:drawhourlyforecast(y)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect(20, y, 360, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(20, y, 360, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawTextAligned(text('1h'), 50, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('2h'), 110, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('3h'), 170, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('4h'), 230, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('5h'), 290, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('6h'), 350, y + 5, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[vars.hourly_start < 23 and 1 or 2].hour[(vars.hourly_start+1)%24 + 1].temp_c * 9/5) + 32 or response_json.forecast.forecastday[vars.hourly_start < 23 and 1 or 2].hour[(vars.hourly_start+1)%24 + 1].temp_c) .. '°', 50, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[vars.hourly_start < 22 and 1 or 2].hour[(vars.hourly_start+2)%24 + 1].temp_c * 9/5) + 32 or response_json.forecast.forecastday[vars.hourly_start < 22 and 1 or 2].hour[(vars.hourly_start+2)%24 + 1].temp_c) .. '°', 110, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[vars.hourly_start < 21 and 1 or 2].hour[(vars.hourly_start+3)%24 + 1].temp_c * 9/5) + 32 or response_json.forecast.forecastday[vars.hourly_start < 21 and 1 or 2].hour[(vars.hourly_start+3)%24 + 1].temp_c) .. '°', 170, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[vars.hourly_start < 20 and 1 or 2].hour[(vars.hourly_start+4)%24 + 1].temp_c * 9/5) + 32 or response_json.forecast.forecastday[vars.hourly_start < 20 and 1 or 2].hour[(vars.hourly_start+4)%24 + 1].temp_c) .. '°', 230, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[vars.hourly_start < 19 and 1 or 2].hour[(vars.hourly_start+5)%24 + 1].temp_c * 9/5) + 32 or response_json.forecast.forecastday[vars.hourly_start < 19 and 1 or 2].hour[(vars.hourly_start+5)%24 + 1].temp_c) .. '°', 290, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[vars.hourly_start < 18 and 1 or 2].hour[(vars.hourly_start+6)%24 + 1].temp_c * 9/5) + 32 or response_json.forecast.forecastday[vars.hourly_start < 18 and 1 or 2].hour[(vars.hourly_start+6)%24 + 1].temp_c) .. '°', 350, y + 45, kTextAlignment.center)
	weather:drawfore(response_json.forecast.forecastday[vars.hourly_start < 23 and 1 or 2].hour[(vars.hourly_start+1)%24 + 1].condition.code, 33, y + 23)
	weather:drawfore(response_json.forecast.forecastday[vars.hourly_start < 22 and 1 or 2].hour[(vars.hourly_start+2)%24 + 1].condition.code, 93, y + 23)
	weather:drawfore(response_json.forecast.forecastday[vars.hourly_start < 21 and 1 or 2].hour[(vars.hourly_start+3)%24 + 1].condition.code, 153, y + 23)
	weather:drawfore(response_json.forecast.forecastday[vars.hourly_start < 20 and 1 or 2].hour[(vars.hourly_start+4)%24 + 1].condition.code, 213, y + 23)
	weather:drawfore(response_json.forecast.forecastday[vars.hourly_start < 19 and 1 or 2].hour[(vars.hourly_start+5)%24 + 1].condition.code, 273, y + 23)
	weather:drawfore(response_json.forecast.forecastday[vars.hourly_start < 18 and 1 or 2].hour[(vars.hourly_start+6)%24 + 1].condition.code, 333, y + 23)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawmoon(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('moonphase'), (left and 20 or 210) + 5, y + 5)
	assets.smallcaps:drawText(text(weather:returnmoonphase(response_json.forecast.forecastday[1].astro.moon_phase, false)), (left and 20 or 210) + 5, y + 31)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
	weather:drawmoonphase(weather:returnmoonphase(response_json.forecast.forecastday[1].astro.moon_phase, true), (left and 131 or 321), y + 9)
end

function weather:drawwind(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('wind'), (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawText((save.speed == 'mph' and format("%.1f", response_json.current.wind_kph / 1.609) or response_json.current.wind_kph), (left and 20 or 210) + 5, y + 20)
	assets.roobert11:drawText((save.speed == 'mph' and 'm/h' or 'k/h'), (left and 20 or 210) + 8 + assets.roobert24:getTextWidth((save.speed == 'mph' and format("%.1f", response_json.current.wind_kph / 1.609) or response_json.current.wind_kph)), y + 30)
	assets.smallcaps:drawText(text('gusts') .. (save.speed == 'mph' and format("%.1f", response_json.current.gust_kph / 1.609) or response_json.current.gust_kph) .. (save.speed == 'mph' and 'm/h' or 'k/h'), (left and 20 or 210) + 5, y + 48)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
	assets.compass:draw((left and 125 or 315), y + 5)
	assets.wind:drawRotated((left and 155 or 345), y + 35, response_json.current.wind_degree - 180)
end

function weather:drawairqualityindex(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('airquality'), (left and 20 or 210) + 5, y + 5)
	assets.roobert11:drawText(text('epa'), (left and 20 or 210) + 5, y + 31)
	assets.roobert24:drawText(response_json.current.air_quality['us-epa-index'], (left and 20 or 210) + 8 + assets.roobert11:getTextWidth(text('epa')), y + 21)
	assets.smallcaps:drawText(text('defra') .. response_json.current.air_quality['gb-defra-index'], (left and 20 or 210) + 5, y + 50)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawairquality(y)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect(20, y, 360, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(20, y, 360, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('co') .. response_json.current.air_quality.co .. text('ppb'), 29, y + 7)
	assets.smallcaps:drawText(text('no2') .. response_json.current.air_quality.no2 .. text('ppb'), 29, y + 28)
	assets.smallcaps:drawText(text('o3') .. response_json.current.air_quality.o3 .. text('ppb'), 29, y + 48)
	assets.smallcaps:drawTextAligned(text('pm10') .. response_json.current.air_quality.pm10 .. text('ugm3'), 371, y + 7, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('pm25') .. response_json.current.air_quality.pm2_5 .. text('ugm3'), 371, y + 28, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('so2') .. response_json.current.air_quality.so2 .. text('ppb'), 371, y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawnow(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('now'), (left and 20 or 210) + 5, y + 5)
	weather:drawfore(response_json.current.condition.code, (left and 55 or 245), y + 32)
	assets.roobert24:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.current.temp_c * 9/5) + 32 or response_json.current.temp_c) .. '°', (left and 183 or 373), y + 35, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawsuntimes(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.fore[1]:draw((left and 20 or 210) + 30, y + 7)
	assets.fore[2]:draw((left and 20 or 210) + 110, y + 7)
	assets.roobert11:drawTextAligned(vars.sunrise, (left and 20 or 210) + 46, y + 30, kTextAlignment.center)
	assets.roobert11:drawTextAligned(vars.sunset, (left and 20 or 210) + 126, y + 30, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('sunrise'), (left and 20 or 210) + 46, y + 48, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('sunset'), (left and 20 or 210) + 126, y + 48, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawfeelslike(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('feelslike'), (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned(floor(save.temp == 'fahrenheit' and (response_json.current.feelslike_c * 9/5) + 32 or response_json.current.feelslike_c) .. '°', (left and 183 or 373), y + 20, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('hi') .. floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[1].day.maxtemp_c * 9/5) + 32 or response_json.forecast.forecastday[1].day.maxtemp_c) .. '° ' .. text('lo') .. floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[1].day.mintemp_c * 9/5) + 32 or response_json.forecast.forecastday[1].day.mintemp_c) .. '°', (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawhumidity(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('humidity'), (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned(response_json.current.humidity .. '%', (left and 183 or 373), y + 20, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('nexthour') .. response_json.forecast.forecastday[vars.hourly_start < 23 and 1 or 2].hour[(vars.hourly_start+1)%24 + 1].humidity .. '%', (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawprecipitation(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('precipitation'), (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned((save.meas == 'inch' and format("%.1f", response_json.current.precip_mm / 25.4) or response_json.current.precip_mm) .. (save.meas == 'mm' and 'mm' or '"'), (left and 183 or 373), y + 20, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('nexthour') .. (save.meas == 'inch' and format("%.1f", response_json.forecast.forecastday[vars.hourly_start < 23 and 1 or 2].hour[(vars.hourly_start+1)%24 + 1].precip_mm / 25.4) or response_json.forecast.forecastday[vars.hourly_start < 23 and 1 or 2].hour[(vars.hourly_start+1)%24 + 1].precip_mm) .. (save.meas == 'mm' and 'mm' or '"'), (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawtomorrow(y)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect(20, y, 360, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(20, y, 360, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('tomorrow'), 25, y + 5)
	weather:drawfore(response_json.forecast.forecastday[2].day.condition.code, 40, y + 28)
	assets.roobert11:drawText(text('hi2') .. floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[2].day.maxtemp_c * 9/5) + 32 or response_json.forecast.forecastday[2].day.maxtemp_c) .. '° ' .. text('lo2') .. floor(save.temp == 'fahrenheit' and (response_json.forecast.forecastday[2].day.mintemp_c * 9/5) + 32 or response_json.forecast.forecastday[2].day.mintemp_c) .. '°', 90, y + 28)
	assets.fore[1]:draw(240, y + 7)
	assets.fore[2]:draw(320, y + 7)
	assets.roobert11:drawTextAligned(vars.sunrise2, 256, y + 30, kTextAlignment.center)
	assets.roobert11:drawTextAligned(vars.sunset2, 335, y + 30, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('sunrise'), 256, y + 48, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('sunset'), 336, y + 48, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawfore(code, x, y)
	if code == 1000 then -- Clear
		if response_json.current.is_day == 1 then
			assets.fore[1]:draw(x, y)
		else
			assets.fore[2]:draw(x, y)
		end
	elseif code == 1003 then -- Partly cloudy
		if response_json.current.is_day == 1 then
			assets.fore[4]:draw(x, y)
		else
			assets.fore[5]:draw(x, y)
		end
	elseif code == 1006 or code == 1009 or code == 1135 or code == 1147 then -- Cloudy
		assets.fore[3]:draw(x, y)
	elseif code == 1030 or code == 1063 or code == 1072 or code == 1150 or code == 1153 or code == 1168 or code == 1171 or code == 1180 or code == 1193 or code == 1186 or code == 1189 or code == 1192 or code == 1195 or code == 1198 or code == 1201 or code == 1240 or code == 1243 or code == 1246 then -- Rainy
		assets.fore[6]:draw(x, y)
	elseif code == 1066 or code == 1069 or code == 1114 or code == 1117 or code == 1204 or code == 1207 or code == 1210 or code == 1213 or code == 1216 or code == 1219 or code == 1222 or code == 1225 or code == 1249 or code == 1252 or code == 1255 or code == 1258 then -- Snowy
		assets.fore[8]:draw(x, y)
	elseif code == 1087 or code == 1263 or code == 1276 or code == 1279 or code == 1282 then -- Lightning
		assets.fore[10]:draw(x, y)
	elseif code == 1237 or code == 1261 or code == 1264 then -- Hail
		assets.fore[7]:draw(x, y)
	end
end

function weather:returnmoonphase(str, num)
	if num then
		if str == "Waxing Crescent" then
			return 1
		elseif str == "First Quarter" then
			return 2
		elseif str == "Waxing Gibbous" then
			return 3
		elseif str == "Full Moon" then
			return 4
		elseif str == "Waning Gibbous" then
			return 5
		elseif str == "Last Quarter" then
			return 6
		elseif str == "Waning Crescent" then
			return 7
		elseif str == "New Moon" then
			return 8
		end
	else
		if str == "Waxing Crescent" then
			return "waxingcrescent"
		elseif str == "First Quarter" then
			return "firstquarter"
		elseif str == "Waxing Gibbous" then
			return "waxinggibbous"
		elseif str == "Full Moon" then
			return "fullmoon"
		elseif str == "Waning Gibbous" then
			return "waninggibbous"
		elseif str == "Last Quarter" then
			return "lastquarter"
		elseif str == "Waning Crescent" then
			return "waningcrescent"
		elseif str == "New Moon" then
			return "newmoon"
		end
	end
end

function weather:drawmoonphase(num, x, y)
	if vars.moon > 9 then
		assets.moon[num + 8]:draw(x, y)
	else
		assets.moon[num]:draw(x, y)
	end
end

function weather:refresh()
	vars.refreshing = true
	vars.iwarnedyouabouthttpbroitoldyoudog = true
	vars.http_opened = false
	vars.get_data = true
	if save.refresh ~= "manual" then
		if vars.refresh_timer ~= nil then
			vars.refresh_timer:reset()
			vars.refresh_timer:start()
		else
			weather:setuprefreshtimer()
		end
	end
end

function weather:setuprefreshtimer()
	if save.refresh == "15m" then
		vars.refresh_timer_duration = 900 * 1000
	elseif save.refresh == "30m" then
		vars.refresh_timer_duration = 1800 * 1000
	elseif save.refresh == "1hr" then
		vars.refresh_timer_duration = 3600 * 1000
	elseif save.refresh == "2hr" then
		vars.refresh_timer_duration = 7200 * 1000
	elseif save.refresh == "4hr" then
		vars.refresh_timer_duration = 14400 * 1000
	elseif save.refresh == "8hr" then
		vars.refresh_timer_duration = 28800 * 1000
	end
	if save.refresh ~= "manual" then
		vars.refresh_timer = pd.timer.new(vars.refresh_timer_duration, function()
			weather:refresh()
		end)
		vars.refresh_timer.discardOnCompletion = false
	end
end

function weather:buildthefold()
	gfx.pushContext(assets.thefold)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 3, 400, 1000)
		gfx.setColor(gfx.kColorBlack)
		gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
		gfx.fillPolygon(vars.polygon)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawPolygon(vars.polygon)
		gfx.drawPolygon(vars.polygon2)
		if response_json ~= nil then
			weather:drawnow(50, true)
			weather:drawfeelslike(50, false)
			weather:drawhourlyforecast(130)
			weather:drawwind(210, true)
			weather:drawairqualityindex(210, false)
			weather:drawairquality(290, false)
			weather:drawhumidity(370, true)
			weather:drawprecipitation(370, false)
			weather:drawtomorrow(450)
			weather:drawmoon(530, true)
			weather:drawsuntimes(530, false)
			gfx.drawTextInRect(text('weatherin') .. lower(response_json.location.name) .. ', ' .. lower(response_json.location.region), 10, 8, 330, 30, 0, '...')
		else
		end
		assets.roobert11:drawText(text('crank'), 370, 7)
		gfx.drawLine(0, 610, 400, 610)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 610, 400, 1500)
		gfx.setColor(gfx.kColorBlack)
		assets.smallcaps:drawText(text('lastchecked'), 10, 615)
		assets.smallcaps:drawText((((save.twofour == 2) or (save.twofour == 1 and pd.shouldDisplay24HourTime())) and format("%02d",vars.lastchecked.hour) .. ':' .. format("%02d",vars.lastchecked.minute)) or (((vars.lastchecked.hour % 12) == 0 and '12' or vars.lastchecked.hour % 12) .. ':' .. format("%02d",vars.lastchecked.minute) .. (vars.lastchecked.hour >= 12 and 'p' or 'a')), 10 + assets.smallcaps:getTextWidth(text('lastchecked')), 615)
	gfx.popContext()
	sprites.fold:setImage(assets.thefold)
end