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

class('weather').extends(gfx.sprite) -- Create the scene's class
function weather:init(...)
	weather.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addMenuItem(text('refresh'), function()
				weather:refresh()
			end)
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
		crank = smp.new('audio/sfx/crank'),
	}

	vars = {
		localtime = pd.GMTTimeFromEpoch(sec + weather_response_json.utc_offset_seconds, ms),
		sunrise = pd.GMTTimeFromEpoch(weather_response_json.daily.sunrise[1] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		sunset = pd.GMTTimeFromEpoch(weather_response_json.daily.sunset[1] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		sunrise2 = pd.GMTTimeFromEpoch(weather_response_json.daily.sunrise[2] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		sunset2 = pd.GMTTimeFromEpoch(weather_response_json.daily.sunset[2] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		polygon = pd.geometry.polygon.new(0, 30, 340, 30, 360, 1, 400, 1, 400, 1000, 0, 1000, 0, 30),
		polygon2 = pd.geometry.polygon.new(0, 3, 358, 3, 340, 30, 0, 30, 0, 3),
		hourly_start = 1,
		get_area = false,
		get_weather = false,
		http_opened = false,
		iwarnedyouabouthttpbroitoldyoudog = false,
		area_response = nil,
		area_response_formatted = nil,
		weather_response = nil,
		weather_response_formatted = nil,
		lo_power = false,
		chargebool = pd.getPowerStatus().charging,
	}

	for i = 1, #weather_response_json.hourly.time do
		local time = pd.GMTTimeFromEpoch(weather_response_json.hourly.time[i] - 946684800 + weather_response_json.utc_offset_seconds, ms)
		if vars.localtime.hour == time.hour then
			vars.hourly_start = i
			break
		end
	end

	vars.locallastminute = vars.localtime.minute

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
		assets.earth = gfx.imagetable.new('images/earth')
		assets.bg = gfx.imagetable.new('images/bg')
		assets.stars_s = gfx.image.new('images/stars_s')
		assets.stars_l = gfx.image.new('images/stars_l')
		vars.earth_timer = pd.timer.new(30000, 1, 300)
		vars.stars_l = pd.timer.new(45000, -400, 0)
		vars.stars_s = pd.timer.new(30000, -400, 0)
		vars.crank_change = 0
		vars.earth_timer.repeats = true
		vars.stars_l.repeats = true
		vars.stars_s.repeats = true
	elseif save.wallpaper == 3 then
		assets.miko = gfx.font.new('fonts/miko')
	elseif save.wallpaper == 4 then
		assets.miko = gfx.font.new('fonts/miko')
	elseif save.wallpaper == 5 then
		assets.customimage = pd.datastore.readImage('images/custom')
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		if save.wallpaper == 1 then
			assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (weather_response_json.current.temperature_2m * 9/5) + 32 or weather_response_json.current.temperature_2m) .. '°', 18, 175)
			assets.roobert11:drawText(text('wc_' .. weather_response_json.current.weather_code), 18, 205)
			assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 205, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:drawScaled(355, 205, 2)
			assets.default1:draw((vars.default1_timer.value // 2) * 2, 0)
			assets.default2:draw(vars.default2_timer.value, 0)
		elseif save.wallpaper == 2 then
			assets.bg[floor(random(1, 3))]:draw(0, 0)
			assets.stars_s:draw(((vars.stars_s.value + vars.crank_change) % 400) - 400, 0)
			assets.stars_l:draw(((vars.stars_l.value + (vars.crank_change / 1.2)) % 400) - 400, 0)
			assets.earth[floor((vars.earth_timer.value + (vars.crank_change / 1.8)) % 299) + 1]:draw(100, 140)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (weather_response_json.current.temperature_2m * 9/5) + 32 or weather_response_json.current.temperature_2m) .. '°', 18, 18)
			assets.roobert11:drawText(text('wc_' .. weather_response_json.current.weather_code), 18, 48)
			assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 18, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:drawScaled(355, 18, 2)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		elseif save.wallpaper == 3 then
			assets.miko:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.current.temperature_2m * 9/5) + 32 or weather_response_json.current.temperature_2m) .. '°', 215, 65, kTextAlignment.center)
			assets.roobert11:drawText(text('wc_' .. weather_response_json.current.weather_code), 18, 205)
			assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 205, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:drawScaled(355, 205, 2)
		elseif save.wallpaper == 4 then
			assets.miko:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute)), 200, 65, kTextAlignment.center)
			assets.roobert11:drawText(floor(save.temp == 'fahrenheit' and (weather_response_json.current.temperature_2m * 9/5) + 32 or weather_response_json.current.temperature_2m) .. '°, ' .. text('wc_' .. weather_response_json.current.weather_code), 18, 205)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:drawScaled(355, 205, 2)
		elseif save.wallpaper == 5 then
			assets.customimage:draw(0, 0)
			gfx.setImageDrawMode(gfx.kDrawModeNXOR)
			assets.roobert24:drawText(floor(save.temp == 'fahrenheit' and (weather_response_json.current.temperature_2m * 9/5) + 32 or weather_response_json.current.temperature_2m) .. '°', 18, 175)
			assets.roobert11:drawText(text('wc_' .. weather_response_json.current.weather_code), 18, 205)
			assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",time.hour) .. ':' .. format("%02d",time.minute)) or (((time.hour % 12) == 0 and '12' or time.hour % 12) .. ':' .. format("%02d",time.minute) .. (time.hour >= 12 and 'p' or 'a')), 345, 205, kTextAlignment.right)
			assets.battery[ceil(pd.getBatteryPercentage() / 17)]:drawScaled(355, 205, 2)
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
			if self.y <= -210 then
				self:moveTo(self.x, self.y += (-210 - self.y) * 0.3)
				if self.y < -210.1 and self.y > -209.9 then
					self:moveTo(self.x, -210)
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
			self.crank += pd.getCrankChange()
			if self.crank < 0 then self.crank = 0 end
			if self.crank >= 30 then
				if not self.popped then
					self.popped = true
					assets.foldtwang:play()
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
						assets.foldclosesoft:play()
					end
				end
			else
				if self.popped then
					self.crank = 0
					self.popped = false
					assets.foldclosesoft:play()
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

	sprites.fold = classes.fold()
	self:add()
	self:buildthefold()
	pd.timer.performAfterDelay(300, function()
		if not pd.getPowerStatus().charging and not scenemanager.transitioning then
			pd.display.setRefreshRate(5)
			vars.lo_power = true
		end
	end)
end

function weather:update()
	if save.wallpaper == 1 or save.wallpaper == 2 and sprites.fold.y > 10 then
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
		if pd.getCrankTicks(8) ~= 0 and save.sfx then
			assets.crank:play()
		end
		if save.wallpaper == 2 then
			vars.crank_change += pd.getCrankChange()
		end
	end
	sec, ms = pd.getSecondsSinceEpoch()
	vars.localtime = pd.GMTTimeFromEpoch(sec + weather_response_json.utc_offset_seconds, ms)
	if vars.locallastminute ~= vars.localtime.minute then
		self:buildthefold()
		pd.display.flush()
	end
	vars.locallastminute = vars.localtime.minute
	if lastminute ~= time.minute then
		if pd.getBatteryPercentage() < save.autolock then
			pd.setAutoLockDisabled(false)
		else
			pd.setAutoLockDisabled(true)
		end
		pd.display.flush()
	end
	if vars.get_area then
		if net.getStatus() == net.kStatusNotAvailable then
			scenemanager:transitionscene(initialization, "nointernet")
		else
			http:get("/v1/search?name=" .. urlencode(save.area) .. "&count=10&language=en&format=json")
			http:setRequestCompleteCallback(function()
				http:setConnectTimeout(10)
				local bytes = http:getBytesAvailable()
				vars.area_response = http:read(bytes)
				if find(vars.area_response, "Bad Gateway") or vars.area_response == "" then
					self:closeticker()
					self:openui("noarea")
					http:close()
					return
				else
					local response_start = 0
					local response_end = 0
					for i = 1, len(vars.area_response) do
						if byte(vars.area_response, i) == byte("{") then
							response_start = i
							break
						end
					end
					for i = len(vars.area_response), 1, -1 do
						if byte(vars.area_response, i) == byte("}") then
							response_end = i
							break
						end
					end
					vars.area_response_formatted = sub(vars.area_response, response_start, response_end)
					area_response_json = json.decode(vars.area_response_formatted)
					http:close()
				end
				if area_response_json.results == nil then
					self:transitionscene(initialization, "noarea")
				else
					vars.results = #area_response_json.results
					if vars.results > 1 and save.area_result == 0 then
						self:closeticker()
						vars.result = 1
						self:transitionscene(initialization, "whereareyou")
					else
						save.area_result = 1
						vars.http_opened = false
						vars.get_weather = true
					end
				end
			end)
		end
		vars.get_area = false
	end
	if vars.get_weather then
		if net.getStatus() == net.kStatusNotAvailable then
			self:transitionscene(initialization, "nointernet")
		else
			http:get("https://api.open-meteo.com/v1/forecast?latitude=".. area_response_json.results[save.area_result].latitude .."&longitude=" .. area_response_json.results[save.area_result].longitude .. "&current=relative_humidity_2m,temperature_2m,weather_code,apparent_temperature,precipitation,is_day&hourly=temperature_2m,weather_code,relative_humidity_2m,precipitation&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weather_code&timezone="  .. area_response_json.results[save.area_result].timezone .. "&forecast_days=2&timeformat=unixtime")
			http:setRequestCompleteCallback(function()
				http:setConnectTimeout(10)
				local bytes = http:getBytesAvailable()
				vars.weather_response = http:read(bytes)
				local response_start = 0
				local response_end = 0
				for i = 1, len(vars.weather_response) do
					if byte(vars.weather_response, i) == byte("{") then
						response_start = i
						break
					end
				end
				for i = len(vars.weather_response), 1, -1 do
					if byte(vars.weather_response, i) == byte("}") then
						response_end = i
						break
					end
				end
				vars.weather_response_formatted = sub(vars.weather_response, response_start, response_end)
				weather_response_json = json.decode(vars.weather_response_formatted)
				http:close()
				if sprites.fold ~= nil then
					self:buildthefold()
				end
				pd.display.flush()
			end)
		end
		vars.get_weather = false
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
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+1] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+0]) .. '°', 50, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+2] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+1]) .. '°', 110, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+3] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+2]) .. '°', 170, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+4] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+3]) .. '°', 230, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+5] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+4]) .. '°', 290, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+6] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+5]) .. '°', 350, y + 45, kTextAlignment.center)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+1], 33, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+2], 93, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+3], 153, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+4], 213, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+5], 273, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+6], 333, y + 23)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawlocaltime(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('localtime'), (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",vars.localtime.hour) .. ':' .. format("%02d",vars.localtime.minute)) or (((vars.localtime.hour % 12) == 0 and '12' or vars.localtime.hour % 12) .. ':' .. format("%02d",vars.localtime.minute) .. (vars.localtime.hour >= 12 and 'p' or 'a')), (left and 183 or 373), y + 35, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawnow(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('now'), (left and 20 or 210) + 5, y + 5)
	weather:drawfore(weather_response_json.current.weather_code, (left and 55 or 245), y + 32)
	assets.roobert24:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.current.temperature_2m * 9/5) + 32 or weather_response_json.current.temperature_2m) .. '°', (left and 183 or 373), y + 35, kTextAlignment.right)
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
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",vars.sunrise.hour) .. ':' .. format("%02d",vars.sunrise.minute)) or (((vars.sunrise.hour % 12) == 0 and '12' or vars.sunrise.hour % 12) .. ':' .. format("%02d",vars.sunrise.minute) .. (vars.sunrise.hour >= 12 and 'p' or 'a')), (left and 20 or 210) + 46, y + 30, kTextAlignment.center)
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",vars.sunset.hour) .. ':' .. format("%02d",vars.sunset.minute)) or (((vars.sunset.hour % 12) == 0 and '12' or vars.sunset.hour % 12) .. ':' .. format("%02d",vars.sunset.minute) .. (vars.sunset.hour >= 12 and 'p' or 'a')), (left and 20 or 210) + 126, y + 30, kTextAlignment.center)
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
	assets.roobert24:drawTextAligned(floor(save.temp == 'fahrenheit' and (weather_response_json.current.apparent_temperature * 9/5) + 32 or weather_response_json.current.apparent_temperature) .. '°', (left and 183 or 373), y + 18, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('hi') .. floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_max[1] * 9/5) + 32 or weather_response_json.daily.temperature_2m_max[1]) .. '° ' .. text('lo') .. floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_min[1] * 9/5) + 32 or weather_response_json.daily.temperature_2m_min[1]) .. '°', (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawhumidity(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('humidity'), (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned(weather_response_json.current.relative_humidity_2m .. '%', (left and 183 or 373), y + 18, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('nexthour') .. weather_response_json.hourly.relative_humidity_2m[vars.hourly_start + 1] .. '%', (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawprecipitation(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('precipitation'), (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned((save.meas == 'mm' and (weather_response_json.current.precipitation / 25.4) or weather_response_json.current.precipitation) .. (save.meas == 'mm' and 'mm' or '"'), (left and 183 or 373), y + 18, kTextAlignment.right)
	assets.smallcaps:drawTextAligned(text('nexthour') .. weather_response_json.hourly.precipitation[vars.hourly_start + 1] .. (save.meas == 'mm' and 'mm' or '"'), (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawtomorrow(y)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect(20, y, 360, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(20, y, 360, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText(text('tomorrow'), 25, y + 5)
	weather:drawfore(weather_response_json.daily.weather_code[2], 40, y + 28)
	assets.roobert11:drawText(text('hi2') .. floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_max[2] * 9/5) + 32 or weather_response_json.daily.temperature_2m_max[2]) .. '° ' .. text('lo2') .. floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_min[2] * 9/5) + 32 or weather_response_json.daily.temperature_2m_min[2]) .. '°', 90, y + 28)
	assets.fore[1]:draw(240, y + 7)
	assets.fore[2]:draw(320, y + 7)
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",vars.sunrise2.hour) .. ':' .. format("%02d",vars.sunrise2.minute)) or (((vars.sunrise2.hour % 12) == 0 and '12' or vars.sunrise2.hour % 12) .. ':' .. format("%02d",vars.sunrise2.minute) .. (vars.sunrise2.hour >= 12 and 'p' or 'a')), 256, y + 30, kTextAlignment.center)
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and format("%02d",vars.sunset2.hour) .. ':' .. format("%02d",vars.sunset2.minute)) or (((vars.sunset2.hour % 12) == 0 and '12' or vars.sunset2.hour % 12) .. ':' .. format("%02d",vars.sunset2.minute) .. (vars.sunset2.hour >= 12 and 'p' or 'a')), 336, y + 30, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('sunrise'), 256, y + 48, kTextAlignment.center)
	assets.smallcaps:drawTextAligned(text('sunset'), 336, y + 48, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawfore(code, x, y)
	if code == 0 then
		if (vars.localtime.hour > vars.sunrise.hour and vars.localtime.hour < vars.sunset.hour) then
			assets.fore[1]:draw(x, y)
		else
			assets.fore[2]:draw(x, y)
		end
	elseif code == 1 or code == 2 then
		if (vars.localtime.hour > vars.sunrise.hour and vars.localtime.hour < vars.sunset.hour) then
			assets.fore[4]:draw(x, y)
		else
			assets.fore[5]:draw(x, y)
		end
	elseif code == 3 then
		assets.fore[3]:draw(x, y)
	elseif code == 45 or code == 48 then
		assets.fore[9]:draw(x, y)
	elseif code == 51 or code == 53 or code == 55 or code == 56 or code == 57 or code == 61 or code == 63 or code == 65 or code == 66 or code == 67 or code == 80 or code == 81 or code == 82 then
		assets.fore[6]:draw(x, y)
	elseif code == 71 or code == 73 or code == 75 or code == 77 or code == 85 or code == 86 then
		assets.fore[8]:draw(x, y)
	elseif code == 95 then
		assets.fore[10]:draw(x, y)
	elseif code == 96 or code == 99 then
		assets.fore[7]:draw(x, y)
	end
end

function weather:refresh()
	vars.iwarnedyouabouthttpbroitoldyoudog = true
	vars.http_opened = false
	vars.get_area = true
	if save.refresh ~= "manual" then
		vars.refresh_timer:reset()
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
		weather:drawlocaltime(50, true)
		weather:drawnow(50, false)
		weather:drawhourlyforecast(130)
		weather:drawfeelslike(210, true)
		weather:drawsuntimes(210, false)
		weather:drawhumidity(290, true)
		weather:drawprecipitation(290, false)
		weather:drawtomorrow(370)
		assets.smallcaps:drawText(text('weatherin') .. lower(area_response_json.results[save.area_result].name), 10, 8)
		assets.roobert11:drawText(text('crank'), 370, 7)
	gfx.popContext()
	sprites.fold:setImage(assets.thefold)
end