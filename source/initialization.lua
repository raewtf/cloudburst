-- Setting up consts
local pd <const> = playdate
local net <const> = pd.network
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('initialization').extends(gfx.sprite) -- Create the scene's class
function initialization:init(...)
	initialization.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true) -- Should this scene redraw the sprites constantly?

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
	end

	pd.keyboard.textChangedCallback = function()
		vars.text = pd.keyboard.text
	end

	area_response_json = {}
	weather_response_json = {}

	pd.keyboard.keyboardWillHideCallback = function(bool)
		save.area_result = 0
		if bool and vars.prompt == "welcome1" then
			self:closeui()
			save.area = vars.text
			pd.timer.performAfterDelay(300, function()
				self:openui("setup1")
			end)
		elseif bool and (vars.prompt == "changearea" or vars.prompt == "noarea" or vars.prompt == "whereareyouarea") then
			self:closeui()
			save.area = vars.text
			pd.timer.performAfterDelay(300, function()
				vars.http_opened = false
				vars.get_area = true
			end)
		end
	end

	assets = {
		roobert11 = gfx.font.new('fonts/roobert11'),
		roobert24 = gfx.font.new('fonts/roobert24'),
		ashe = gfx.font.new('fonts/ashe'),
		sasser = gfx.font.new('fonts/sasser'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		earth = gfx.imagetable.new('images/earth'),
		bg = gfx.imagetable.new('images/bg'),
		stars_s = gfx.image.new('images/stars_s'),
		stars_l = gfx.image.new('images/stars_l'),
		ui = gfx.image.new('images/ui_buttons'),
	}

	vars = {
		prompttoopen = args[1],
		earth_timer = pd.timer.new(30000, 1, 300),
		http_opened = true,
		http = nil,
		get_area = false,
		area_response = nil,
		area_response_formatted = nil,
		get_weather = false,
		weather_response = nil,
		weather_response_formatted = nil,
		stars_l = pd.timer.new(45000, -400, 0),
		stars_s = pd.timer.new(30000, -400, 0),
		satellite_timer = pd.timer.new(15000, -1, 1),
		ui_timer = pd.timer.new(1, 240, 240),
		crank_change = 0,
		ui_open = false,
		ticker_open = false,
		ui_closing = false,
		ticker_closing = false,
		ticker_timer_x = pd.timer.new(1, 0, 0),
		ticker_timer_y = pd.timer.new(1, -28, -28),
		ticker_string = "",
		text = "",
		prompt = "",
		setup1_selection = 1,
		setup2_selection = 1,
		results = 0,
		result = 1,
		result_timer = pd.timer.new(1, 1, 1),
		iwarnedyouabouthttpbroitoldyoudog = true,
	}
	vars.welcome1Handlers = {
		AButtonDown = function()
			pd.keyboard.show()
		end
	}
	vars.setup1Handlers = {
		leftButtonDown = function()
			if vars.setup1_selection == 1 then
			else
				vars.setup1_selection = 1
			end
		end,

		rightButtonDown = function()
			if vars.setup1_selection == 2 then
			else
				vars.setup1_selection = 2
			end
		end,

		AButtonDown = function()
			self:closeui()
			if vars.setup1_selection == 1 then
				save.temp = "celsius"
			elseif vars.setup1_selection == 2 then
				save.temp = "fahrenheit"
			end
			pd.timer.performAfterDelay(300, function()
				self:openui("setup2")
			end)
		end,

		BButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				self:openui("welcome1")
			end)
		end
	}
	vars.setup2Handlers = {
		leftButtonDown = function()
			if vars.setup2_selection == 1 then
			else
				vars.setup2_selection = 1
			end
		end,

		rightButtonDown = function()
			if vars.setup2_selection == 2 then
			else
				vars.setup2_selection = 2
			end
		end,

		AButtonDown = function()
			self:closeui()
			if vars.setup2_selection == 1 then
				save.speed = "kph"
				save.meas = "mm"
			elseif vars.setup2_selection == 2 then
				save.speed = "mph"
				save.meas = "inch"
			end
			pd.timer.performAfterDelay(300, function()
				self:openui("welcome2")
			end)
		end,

		BButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				self:openui("setup1")
			end)
		end
	}
	vars.welcome2Handlers = {
		AButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				vars.http_opened = false
				vars.get_area = true
			end)
		end,

		BButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				self:openui("setup2")
			end)
		end
	}
	vars.noareaHandlers = {
		AButtonDown = function()
			pd.keyboard.show()
		end
	}
	vars.changeareaHandlers = {
		AButtonDown = function()
			pd.keyboard.show()
		end
	}
	vars.whereareyouareaHandlers = {
		AButtonDown = function()
			pd.keyboard.show()
		end
	}
	vars.whereareyouHandlers = {
		upButtonDown = function()
			if vars.result == 1 then
			else
				vars.result -= 1
				vars.result_timer:resetnew(100, vars.result_timer.value, vars.result)
			end
		end,

		downButtonDown = function()
			if vars.result == vars.results then
			else
				vars.result += 1
				vars.result_timer:resetnew(100, vars.result_timer.value, vars.result)
			end
		end,

		AButtonDown = function()
			self:closeui()
			save.area_result = vars.result
			pd.timer.performAfterDelay(300, function()
				vars.http_opened = false
				vars.get_weather = true
			end)
		end,

		BButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				self:openui("whereareyouarea")
			end)
		end
	}
	vars.nointernetHandlers = {
		AButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(3000, function()
				if net.getStatus() == net.kStatusNotAvailable then
					self:openui("nointernet")
				else
					if vars.prompttoopen ~= nil then
						self:openui(vars.prompttoopen)
					else
						if save.setup then
							self:openui("welcome1")
						else
							vars.http_opened = false
							vars.get_area = true
						end
					end
				end
			end)
		end
	}

	vars.earth_timer.repeats = true
	vars.stars_l.repeats = true
	vars.stars_s.repeats = true
	vars.satellite_timer.reverses = true
	vars.satellite_timer.repeats = true
	vars.ui_timer.discardOnCompletion = false
	vars.ticker_timer_x.discardOnCompletion = false
	vars.ticker_timer_y.discardOnCompletion = false
	vars.result_timer.discardOnCompletion = false

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.bg[math.floor(math.random(1, 3))]:draw(0, 0)
		assets.stars_s:draw(((vars.stars_s.value + vars.crank_change) % 400) - 400, 0)
		assets.stars_l:draw(((vars.stars_l.value + (vars.crank_change / 1.2)) % 400) - 400, 0)
		assets.earth[math.floor((vars.earth_timer.value + (vars.crank_change / 1.8)) % 299) + 1]:draw(100, 140)
		if vars.ticker_open then
			gfx.fillRect(0, vars.ticker_timer_y.value, 400, 27)
			gfx.setColor(gfx.kColorWhite)
			gfx.drawLine(0, vars.ticker_timer_y.value + 27, 400, vars.ticker_timer_y.value + 27)
			gfx.setColor(gfx.kColorBlack)
		end
		if vars.ui_open then
			assets.draw_ui:draw(0 + math.floor(((pd.keyboard.left() - 400) / 2) / 2) * 2, math.floor(vars.ui_timer.value / 2) * 2)
		end
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			if vars.ticker_open then
				assets.smallcaps:drawText(vars.ticker_string, vars.ticker_timer_x.value, vars.ticker_timer_y.value + 5)
			end
			if vars.ui_open then
				if vars.prompt == "welcome1" or vars.prompt == "changearea" or vars.prompt == "noarea" or vars.prompt == "whereareyouarea" then
					assets.roobert11:drawTextAligned(vars.text, 200 + (pd.keyboard.left() - 400) / 2, 155 + vars.ui_timer.value, kTextAlignment.center)
				elseif vars.prompt == "setup1" then
					gfx.setColor(gfx.kColorWhite)
					gfx.drawRoundRect((vars.setup1_selection == 1 and 35 or 225), 115 + vars.ui_timer.value, 140, 50, 8)
					gfx.setColor(gfx.kColorBlack)
				elseif vars.prompt == "setup2" then
					gfx.setColor(gfx.kColorWhite)
					gfx.drawRoundRect((vars.setup2_selection == 1 and 35 or 225), 115 + vars.ui_timer.value, 140, 50, 8)
					gfx.setColor(gfx.kColorBlack)
				elseif vars.prompt == "whereareyou" then
					gfx.setClipRect(35, 90 + vars.ui_timer.value, 330, 90)
					for i = 1, vars.results do
						if area_response_json.results[i].name ~= nil then
							assets.roobert11:drawText(area_response_json.results[i].name, 50, 125 + (25 * i) + vars.ui_timer.value - (25 * vars.result_timer.value))
						end
						if area_response_json.results[i].admin1 ~= nil then
							assets.smallcaps:drawTextAligned(string.lower(area_response_json.results[i].admin1), 350, 125 + (25 * i) + vars.ui_timer.value - (25 * vars.result_timer.value), kTextAlignment.right)
						end
					end
					gfx.setColor(gfx.kColorXOR)
					gfx.fillRect(40, 123 + vars.ui_timer.value, 320, 24)
					gfx.setColor(gfx.kColorBlack)
					gfx.clearClipRect()
				end
			end
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	pd.timer.performAfterDelay(1000, function()
		if net.getStatus() == net.kStatusNotAvailable then
			self:openui("nointernet")
		else
			if vars.prompttoopen ~= nil then
				self:openui(vars.prompttoopen)
			else
				if save.setup then
					self:openui("welcome1")
				else
					vars.http_opened = false
					vars.get_area = true
				end
			end
		end
	end)

	self:add()
end

function initialization:update()
	vars.crank_change += pd.getCrankChange()
	if vars.get_area then
		if net.getStatus() == net.kStatusNotAvailable then
			self:openui("nointernet")
		else
			if first_check and not save.setup then
				self:openticker(text("contacting_wb"))
				first_check = false
			else
				self:openticker(text("contacting"))
			end
			if save.setup then
				save.setup = false
			end
			http:get("/v1/search?name=" .. save.area .. "&count=10&language=en&format=json")
			http:setRequestCompleteCallback(function()
				http:setConnectTimeout(10)
				local bytes = http:getBytesAvailable()
				vars.area_response = http:read(bytes)
				if string.find(vars.area_response, "Bad Gateway") or vars.area_response == "" then
					self:closeticker()
					self:openui("noarea")
					http:close()
					return
				else
					local response_start = 0
					local response_end = 0
					for i = 1, string.len(vars.area_response) do
						if string.byte(vars.area_response, i) == string.byte("{") then
							response_start = i
							break
						end
					end
					for i = string.len(vars.area_response), 1, -1 do
						if string.byte(vars.area_response, i) == string.byte("}") then
							response_end = i
							break
						end
					end
					vars.area_response_formatted = string.sub(vars.area_response, response_start, response_end)
					area_response_json = json.decode(vars.area_response_formatted)
					http:close()
				end
				if area_response_json.results == nil then
					self:closeticker()
					self:openui("noarea")
				else
					vars.results = #area_response_json.results
					if vars.results > 1 and save.area_result == 0 then
						self:closeticker()
						vars.result = 1
						self:openui("whereareyou")
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
			self:openui("nointernet")
		else
			if not vars.ticker_open then
				self:openticker(text("contacting"))
			end
			local speed = ""
			local meas = ""
			local temp = ""
			http:get("https://api.open-meteo.com/v1/forecast?latitude=".. area_response_json.results[save.area_result].latitude .."&longitude=" .. area_response_json.results[save.area_result].longitude .. "&current=relative_humidity_2m,temperature_2m,weather_code,apparent_temperature,precipitation,is_day&hourly=temperature_2m,weather_code,relative_humidity_2m,precipitation&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weather_code&timezone="  .. area_response_json.results[save.area_result].timezone .. "&forecast_days=2&timeformat=unixtime")
			http:setRequestCompleteCallback(function()
				http:setConnectTimeout(10)
				local bytes = http:getBytesAvailable()
				vars.weather_response = http:read(bytes)
				local response_start = 0
				local response_end = 0
				for i = 1, string.len(vars.weather_response) do
					if string.byte(vars.weather_response, i) == string.byte("{") then
						response_start = i
						break
					end
				end
				for i = string.len(vars.weather_response), 1, -1 do
					if string.byte(vars.weather_response, i) == string.byte("}") then
						response_end = i
						break
					end
				end
				vars.weather_response_formatted = string.sub(vars.weather_response, response_start, response_end)
				weather_response_json = json.decode(vars.weather_response_formatted)
				http:close()
				self:closeticker()
				scenemanager:transitionscene(weather)
			end)
		end
		vars.get_weather = false
	end
end

function initialization:openticker(string)
	vars.ticker_string = string
	vars.ticker_timer_x:resetnew(10000, 400, -assets.smallcaps:getTextWidth(string))
	if not vars.ticker_open then
		vars.ticker_timer_y:resetnew(250, vars.ticker_timer_y.value, 0, pd.easingFunctions.outSine)
	end
	vars.ticker_timer_x.repeats = true
	vars.ticker_open = true
end

function initialization:closeticker()
	if not vars.ticker_closing then
		vars.ticker_timer_y:resetnew(250, vars.ticker_timer_y.value, -28, pd.easingFunctions.inSine)
	end
	vars.ticker_closing = true
	pd.timer.performAfterDelay(250, function()
		vars.ticker_open = false
		vars.ticker_closing = false
	end)
end

function initialization:openui(prompt)
	vars.prompt = prompt
	assets.draw_ui = assets.ui:copy()
	gfx.pushContext(assets.draw_ui)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.ashe:drawTextAligned(text(prompt), 200, 20, kTextAlignment.center)
		assets.roobert11:drawTextAligned(text(prompt .. '_text'), 200, 55, kTextAlignment.center)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		if prompt == "welcome1" or prompt == "changearea" or prompt == "noarea" or prompt == "whereareyouarea" then
			gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
			gfx.fillRoundRect(40, 150, 320, 30, 5)
			gfx.setColor(gfx.kColorWhite)
			gfx.drawRoundRect(40, 150, 320, 30, 5)
			gfx.setColor(gfx.kColorBlack)
			vars.text = ""
			assets.roobert11:drawTextAligned(text('keyboard'), 200, 200, kTextAlignment.center)
		elseif prompt == "setup1" then
			gfx.setColor(gfx.kColorWhite)
			gfx.fillRoundRect(40, 120, 130, 40, 5)
			gfx.fillRoundRect(230, 120, 130, 40, 5)
			gfx.setColor(gfx.kColorBlack)
			assets.roobert11:drawTextAligned(text('select'), 200, 200, kTextAlignment.center)
			assets.roobert11:drawTextAligned(text('celsius'), 105, 130, kTextAlignment.center)
			assets.roobert11:drawTextAligned(text('fahrenheit'), 295, 130, kTextAlignment.center)
		elseif prompt == "setup2" then
			gfx.setColor(gfx.kColorWhite)
			gfx.fillRoundRect(40, 120, 130, 40, 5)
			gfx.fillRoundRect(230, 120, 130, 40, 5)
			gfx.setColor(gfx.kColorBlack)
			assets.roobert11:drawTextAligned(text('select'), 200, 200, kTextAlignment.center)
			assets.roobert11:drawTextAligned(text('metric'), 105, 130, kTextAlignment.center)
			assets.roobert11:drawTextAligned(text('imperial'), 295, 130, kTextAlignment.center)
		elseif prompt == "welcome2" then
			assets.roobert11:drawTextAligned(text('ok'), 200, 200, kTextAlignment.center)
		elseif prompt == "whereareyou" then
			gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
			gfx.fillRoundRect(35, 90, 330, 90, 5)
			gfx.setColor(gfx.kColorWhite)
			gfx.drawRoundRect(35, 90, 330, 90, 5)
			gfx.setColor(gfx.kColorBlack)
			assets.roobert11:drawTextAligned(text('selectwhere'), 200, 200, kTextAlignment.center)
		elseif prompt == "nointernet" then
			assets.roobert11:drawTextAligned(text('tryagain'), 200, 200, kTextAlignment.center)
		end
	gfx.popContext()
	pd.inputHandlers.push(vars[prompt .. 'Handlers'])
	if not vars.ui_open then
		vars.ui_timer = pd.timer.new(250, vars.ui_timer.value, 0, pd.easingFunctions.outSine)
	end
	vars.ui_open = true
end

function initialization:closeui()
	pd.inputHandlers.pop()
	if not vars.ui_closing then
		vars.ui_timer = pd.timer.new(250, vars.ui_timer.value, 240, pd.easingFunctions.inSine)
	end
	vars.ui_closing = true
	pd.timer.performAfterDelay(250, function()
		vars.ui_open = false
		vars.ui_closing = false
	end)
end