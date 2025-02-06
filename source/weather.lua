-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText
local sec, ms = pd.getSecondsSinceEpoch()

class('weather').extends(gfx.sprite) -- Create the scene's class
function weather:init(...)
	weather.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		menu:addMenuItem(text('refresh'), function()
			scenemanager:transitionscene(initialization)
			pd.display.setRefreshRate(30)
		end)
		menu:addMenuItem(text('options'), function()
			scenemanager:transitionscene(options)
			pd.display.setRefreshRate(30)
		end)
		menu:addMenuItem(text('credits'), function()
			scenemanager:transitionscene(credits)
			pd.display.setRefreshRate(30)
		end)
	end

	assets = {
		sasser = gfx.font.new('fonts/sasser'),
		roobert11 = gfx.font.new('fonts/roobert11'),
		roobert24 = gfx.font.new('fonts/roobert24'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		fore_sun = gfx.image.new('images/fore_sun'),
		fore_moon = gfx.image.new('images/fore_moon'),
		fore_cloud = gfx.image.new('images/fore_cloud'),
		fore_cloud_sun = gfx.image.new('images/fore_cloud_sun'),
		fore_cloud_moon = gfx.image.new('images/fore_cloud_moon'),
		fore_rain = gfx.image.new('images/fore_rain'),
		fore_hail = gfx.image.new('images/fore_hail'),
		fore_wind = gfx.image.new('images/fore_wind'),
		fore_lightning = gfx.image.new('images/fore_lightning'),
		fore_snow = gfx.image.new('images/fore_snow'),
	}


	vars = {
		localtime = pd.GMTTimeFromEpoch(sec + weather_response_json.utc_offset_seconds, ms),
		sunrise = pd.GMTTimeFromEpoch(weather_response_json.daily.sunrise[1] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		sunset = pd.GMTTimeFromEpoch(weather_response_json.daily.sunset[1] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		sunrise2 = pd.GMTTimeFromEpoch(weather_response_json.daily.sunrise[2] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		sunset2 = pd.GMTTimeFromEpoch(weather_response_json.daily.sunset[2] - 946684800 + weather_response_json.utc_offset_seconds, 0),
		polygon = pd.geometry.polygon.new(0, 30, 340, 30, 365, 0, 400, 0, 400, 480, 0, 480, 0, 30),
		hourly_start = 1,
	}

	for i = 1, #weather_response_json.hourly.time do
		local time = pd.GMTTimeFromEpoch(weather_response_json.hourly.time[i], ms)
		if vars.localtime.hour == time.hour then
			vars.hourly_start = i
			break
		end
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.sasser:drawText('Weather in ' .. area_response_json.results[save.area_result].name, 10, 10)
		assets.roobert24:drawText(math.floor(save.temp == 'fahrenheit' and (weather_response_json.current.temperature_2m * 9/5) + 32 or weather_response_json.current.temperature_2m) .. '°', 10, 30)
		assets.roobert11:drawText(text('wc_' .. weather_response_json.current.weather_code), 10, 80)
	end)

	class('fold', _, classes).extends(gfx.sprite)
	function classes.fold:init()
		self:setSize(400, 480)
		self:setCenter(0, 0)
		self:moveTo(0, 242)
		self.open = false
		self.crank = 0
		self.timer = pd.timer.new(1500, 0, 0)
		self.timer.discardOnCompletion = false
		self:add()
	end
	function classes.fold:update()
		-- self:moveBy(0, self.crank)
		if self.open then
			self:moveBy(0, -pd.getCrankChange())
			if self.y >= -30 then
				self.crank += pd.getCrankChange()
				self:moveTo(self.x, self.y += (-31 - self.y) * 0.3)
			else
				self.crank = 0
			end
			if self.y <= -140 then
				self:moveTo(self.x, self.y += (-140 - self.y) * 0.3)
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
			end
		else
			self.crank += pd.getCrankChange()
			if self.crank >= 30 then
				self:moveBy(0, -pd.getCrankChange())
				if self.crank >= 100 then
					self.open = true
					self.crank = 0
				end
				if pd.getCrankChange() > 0 then
					self.timer:resetnew(1500, 1, 0)
				end
				self:moveTo(self.x, self.y += (211 - self.y) * 0.5)
				self.timer.timerEndedCallback = function()
					self.crank = 0
				end
			else
				self:moveTo(self.x, self.y += (242 - self.y) * 0.3)
			end
		end
	end
	function classes.fold:draw()
		gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
		gfx.fillPolygon(vars.polygon)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawPolygon(vars.polygon)
		weather:drawhourlyforecast(50)
		weather:drawfeelslike(130, true)
		weather:drawsuntimes(130, false)
		weather:drawhumidity(210, true)
		weather:drawprecipitation(210, false)
		weather:drawtomorrow(290)
	end

	sprites.fold = classes.fold()
	self:add()
	pd.timer.performAfterDelay(300, function()
		pd.display.setRefreshRate(30)
	end)
end

function weather:update()
	sec, ms = pd.getSecondsSinceEpoch()
	vars.localtime = pd.GMTTimeFromEpoch(sec + weather_response_json.utc_offset_seconds, ms)
	if pd.getBatteryPercentage() < save.autolock then
		pd.setAutoLockDisabled(false)
	else
		pd.setAutoLockDisabled(true)
	end
end

function weather:drawhourlyforecast(y)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect(20, y, 360, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(20, y, 360, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.roobert11:drawText('Ⓓ', 370, 7)
	assets.smallcaps:drawTextAligned('now', 50, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('1h.', 110, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('2h.', 170, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('3h.', 230, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('4h.', 290, y + 5, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('5h.', 350, y + 5, kTextAlignment.center)
	assets.roobert11:drawTextAligned(math.floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+0] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+0]) .. '°', 50, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(math.floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+1] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+1]) .. '°', 110, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(math.floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+2] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+2]) .. '°', 170, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(math.floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+3] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+3]) .. '°', 230, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(math.floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+4] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+4]) .. '°', 290, y + 45, kTextAlignment.center)
	assets.roobert11:drawTextAligned(math.floor(save.temp == 'fahrenheit' and (weather_response_json.hourly.temperature_2m[vars.hourly_start+5] * 9/5) + 32 or weather_response_json.hourly.temperature_2m[vars.hourly_start+5]) .. '°', 350, y + 45, kTextAlignment.center)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+0], 33, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+1], 93, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+2], 153, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+3], 213, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+4], 273, y + 23)
	weather:drawfore(weather_response_json.hourly.weather_code[vars.hourly_start+5], 333, y + 23)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawlocaltime(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText('local time', (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned((pd.shouldDisplay24HourTime() and string.format("%02d",vars.localtime.hour) .. ':' .. string.format("%02d",vars.localtime.minute)) or (((vars.localtime.hour % 12) == 0 and '12') or vars.localtime.hour % 12 .. ':' .. string.format("%02d",vars.localtime.minute) .. (vars.localtime.hour > 12 and 'p' or 'a')), (left and 183 or 373), y + 35, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawsuntimes(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.fore_sun:draw((left and 20 or 210) + 30, y + 7)
	assets.fore_moon:draw((left and 20 or 210) + 110, y + 7)
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and string.format("%02d",vars.sunrise.hour) .. ':' .. string.format("%02d",vars.sunrise.minute)) or (((vars.sunrise.hour % 12) == 0 and '12' or vars.sunrise.hour % 12) .. ':' .. string.format("%02d",vars.sunrise.minute) .. (vars.sunrise.hour > 12 and 'p' or 'a')), (left and 20 or 210) + 46, y + 30, kTextAlignment.center)
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and string.format("%02d",vars.sunset.hour) .. ':' .. string.format("%02d",vars.sunset.minute)) or (((vars.sunset.hour % 12) == 0 and '12' or vars.sunset.hour % 12) .. ':' .. string.format("%02d",vars.sunset.minute) .. (vars.sunset.hour > 12 and 'p' or 'a')), (left and 20 or 210) + 126, y + 30, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('sunrise', (left and 20 or 210) + 46, y + 48, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('sunset', (left and 20 or 210) + 126, y + 48, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawfeelslike(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText('feels like', (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned(math.floor(save.temp == 'fahrenheit' and (weather_response_json.current.apparent_temperature * 9/5) + 32 or weather_response_json.current.apparent_temperature) .. '°', (left and 183 or 373), y + 18, kTextAlignment.right)
	assets.smallcaps:drawTextAligned('hi: ' .. math.floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_max[1] * 9/5) + 32 or weather_response_json.daily.temperature_2m_max[1]) .. '° ' .. 'lo: ' .. math.floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_min[1] * 9/5) + 32 or weather_response_json.daily.temperature_2m_min[1]) .. '°', (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawhumidity(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText('humidity', (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned(weather_response_json.current.relative_humidity_2m .. '%', (left and 183 or 373), y + 18, kTextAlignment.right)
	assets.smallcaps:drawTextAligned('next hour: ' .. weather_response_json.hourly.relative_humidity_2m[vars.hourly_start + 1] .. '%', (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawprecipitation(y, left)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect((left and 20 or 210), y, 170, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText('precipitation', (left and 20 or 210) + 5, y + 5)
	assets.roobert24:drawTextAligned(weather_response_json.current.precipitation .. (save.meas == 'mm' and 'mm' or '"'), (left and 183 or 373), y + 18, kTextAlignment.right)
	assets.smallcaps:drawTextAligned('next hour: ' .. weather_response_json.hourly.precipitation[vars.hourly_start + 1] .. (save.meas == 'mm' and 'mm' or '"'), (left and 183 or 373), y + 48, kTextAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawtomorrow(y)
	gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
	gfx.fillRoundRect(20, y, 360, 70, 5)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(20, y, 360, 70, 5)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	assets.smallcaps:drawText('tomorrow', 25, y + 5)
	weather:drawfore(weather_response_json.daily.weather_code[2], 40, y + 28)
	assets.roobert11:drawText('HI: ' .. math.floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_max[2] * 9/5) + 32 or weather_response_json.daily.temperature_2m_max[2]) .. '° ' .. 'LO: ' .. math.floor(save.temp == 'fahrenheit' and (weather_response_json.daily.temperature_2m_min[2] * 9/5) + 32 or weather_response_json.daily.temperature_2m_min[2]) .. '°', 90, y + 28)
	assets.fore_sun:draw(240, y + 7)
	assets.fore_moon:draw(320, y + 7)
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and string.format("%02d",vars.sunrise2.hour) .. ':' .. string.format("%02d",vars.sunrise2.minute)) or (((vars.sunrise2.hour % 12) == 0 and '12' or vars.sunrise2.hour % 12) .. ':' .. string.format("%02d",vars.sunrise2.minute) .. (vars.sunrise2.hour > 12 and 'p' or 'a')), 256, y + 30, kTextAlignment.center)
	assets.roobert11:drawTextAligned((pd.shouldDisplay24HourTime() and string.format("%02d",vars.sunset2.hour) .. ':' .. string.format("%02d",vars.sunset2.minute)) or (((vars.sunset2.hour % 12) == 0 and '12' or vars.sunset2.hour % 12) .. ':' .. string.format("%02d",vars.sunset2.minute) .. (vars.sunset2.hour > 12 and 'p' or 'a')), 336, y + 30, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('sunrise', 256, y + 48, kTextAlignment.center)
	assets.smallcaps:drawTextAligned('sunset', 336, y + 48, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function weather:drawfore(code, x, y)
	if code == 0 then
		if (vars.localtime.hour > vars.sunrise.hour and vars.localtime.hour < vars.sunset.hour) then
			assets.fore_sun:draw(x, y)
		else
			assets.fore_moon:draw(x, y)
		end
	elseif code == 1 or code == 2 then
		if (vars.localtime.hour > vars.sunrise.hour and vars.localtime.hour < vars.sunset.hour) then
			assets.fore_cloud_sun:draw(x, y)
		else
			assets.fore_cloud_moon:draw(x, y)
		end
	elseif code == 3 then
		assets.fore_cloud:draw(x, y)
	elseif code == 45 or code == 48 then
		assets.fore_wind:draw(x, y)
	elseif code == 51 or code == 53 or code == 55 or code == 56 or code == 57 or code == 61 or code == 63 or code == 65 or code == 66 or code == 67 or code == 80 or code == 81 or code == 82 then
		assets.fore_rain:draw(x, y)
	elseif code == 71 or code == 73 or code == 75 or code == 77 or code == 85 or code == 86 then
		assets.fore_snow:draw(x, y)
	elseif code == 95 then
		assets.fore_lightning:draw(x, y)
	elseif code == 96 or code == 99 then
		assets.fore_hail:draw(x, y)
	end
end