import 'Tanuk_CodeSequence'

-- Setting up consts
local pd <const> = playdate
local net <const> = pd.network
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText
local floor <const> = math.floor
local random <const> = math.random
local lower <const> = string.lower
local find <const> = string.find
local len <const> = string.len
local byte <const> = string.byte
local sub <const> = string.sub

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

	response_json = {}

	pd.keyboard.keyboardWillHideCallback = function(bool)
		if bool and vars.prompt == "welcome1" then
			self:closeui()
			save.area = vars.text
			pd.timer.performAfterDelay(300, function()
				self:openui("setup1")
			end)
		elseif bool and (vars.prompt == "changearea" or vars.prompt == "noarea") then
			self:closeui()
			save.area = vars.text
			pd.timer.performAfterDelay(300, function()
				vars.http_opened = false
				vars.get_data = true
			end)
		end
	end

	assets = {
		roobert11 = gfx.font.new('fonts/roobert11'),
		ashe = gfx.font.new('fonts/ashe'),
		sasser = gfx.font.new('fonts/sasser'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		earth = gfx.imagetable.new('images/earth'),
		bg = gfx.imagetable.new('images/bg'),
		stars_s = gfx.image.new('images/stars_s'),
		stars_l = gfx.image.new('images/stars_l'),
		ui = gfx.image.new('images/ui_buttons'),
		sfx_ui = smp.new('audio/sfx/ui'),
		error = smp.new('audio/sfx/error'),
		move = smp.new('audio/sfx/move'),
		select = smp.new('audio/sfx/select'),
		connect = smp.new('audio/sfx/connect'),
		back = smp.new('audio/sfx/back'),
		crank = smp.new('audio/sfx/crank'),
	}

	gfx.setFont(assets.roobert11)

	vars = {
		prompttoopen = args[1],
		earth_timer = pd.timer.new(30000, 1, 300),
		stars_l = pd.timer.new(45000, -400, 0),
		stars_s = pd.timer.new(30000, -400, 0),
		crank_change = 0,
		http_opened = true,
		http = nil,
		get_data = false,
		data_response = nil,
		data_response_formatted = nil,
		ui_timer = pd.timer.new(1, 240, 240),
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
		iwarnedyouabouthttpbroitoldyoudog = true,
	}
	vars.welcome1Handlers = {
		AButtonDown = function()
			pd.keyboard.show()
			if save.sfx then assets.select:play() end
		end
	}
	vars.setup1Handlers = {
		leftButtonDown = function()
			if vars.setup1_selection == 1 then
			else
				if save.sfx then assets.move:play() end
				vars.setup1_selection = 1
			end
		end,

		rightButtonDown = function()
			if vars.setup1_selection == 2 then
			else
				if save.sfx then assets.move:play() end
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
			if save.sfx then assets.select:play() end
		end,

		BButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				self:openui("welcome1")
			end)
			if save.sfx then assets.back:play() end
		end
	}
	vars.setup2Handlers = {
		leftButtonDown = function()
			if vars.setup2_selection == 1 then
			else
				if save.sfx then assets.move:play() end
				vars.setup2_selection = 1
			end
		end,

		rightButtonDown = function()
			if vars.setup2_selection == 2 then
			else
				if save.sfx then assets.move:play() end
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
			if save.sfx then assets.select:play() end
			pd.timer.performAfterDelay(300, function()
				self:openui("welcome2")
			end)
		end,

		BButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				self:openui("setup1")
			end)
			if save.sfx then assets.back:play() end
		end
	}
	vars.welcome2Handlers = {
		AButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				vars.http_opened = false
				vars.get_data = true
			end)
			if save.sfx then assets.select:play() end
		end,

		BButtonDown = function()
			self:closeui()
			pd.timer.performAfterDelay(300, function()
				self:openui("setup2")
			end)
			if save.sfx then assets.back:play() end
		end
	}
	vars.noareaHandlers = {
		AButtonDown = function()
			pd.keyboard.show()
			if save.sfx then assets.select:play() end
		end
	}
	vars.changeareaHandlers = {
		AButtonDown = function()
			pd.keyboard.show()
			if save.sfx then assets.select:play() end
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
							vars.get_data = true
						end
					end
				end
				if save.sfx then assets.select:play() end
			end)
		end
	}

	vars.earth_timer.repeats = true
	vars.stars_l.repeats = true
	vars.stars_s.repeats = true
	vars.ui_timer.discardOnCompletion = false
	vars.ticker_timer_x.discardOnCompletion = false
	vars.ticker_timer_y.discardOnCompletion = false

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.bg[floor(random(1, 3))]:draw(0, 0)
		assets.stars_s:draw(((vars.stars_s.value + vars.crank_change) % 400) - 400, 0)
		assets.stars_l:draw(((vars.stars_l.value + (vars.crank_change / 1.2)) % 400) - 400, 0)
		assets.earth[floor((vars.earth_timer.value + (vars.crank_change / 1.8)) % 299) + 1]:draw(100, 140)
		if vars.ticker_open then
			gfx.fillRect(0, vars.ticker_timer_y.value, 400, 27)
			gfx.setColor(gfx.kColorWhite)
			gfx.drawLine(0, vars.ticker_timer_y.value + 27, 400, vars.ticker_timer_y.value + 27)
			gfx.setColor(gfx.kColorBlack)
		end
		if vars.ui_open then
			assets.draw_ui:draw(0 + (((pd.keyboard.left() - 400) / 2) // 2) * 2, floor(vars.ui_timer.value / 2) * 2)
		end
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			if vars.ticker_open then
				assets.smallcaps:drawText(vars.ticker_string, vars.ticker_timer_x.value, vars.ticker_timer_y.value + 5)
			end
			if vars.ui_open then
				if vars.prompt == "welcome1" or vars.prompt == "changearea" or vars.prompt == "noarea" then
					assets.roobert11:drawTextAligned(vars.text, 200 + (pd.keyboard.left() - 400) / 2, 155 + vars.ui_timer.value, kTextAlignment.center)
				elseif vars.prompt == "setup1" then
					gfx.setColor(gfx.kColorWhite)
					gfx.drawRoundRect((vars.setup1_selection == 1 and 35 or 225), 115 + vars.ui_timer.value, 140, 50, 8)
					gfx.setColor(gfx.kColorBlack)
				elseif vars.prompt == "setup2" then
					gfx.setColor(gfx.kColorWhite)
					gfx.drawRoundRect((vars.setup2_selection == 1 and 35 or 225), 115 + vars.ui_timer.value, 140, 50, 8)
					gfx.setColor(gfx.kColorBlack)
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
					vars.get_data = true
				end
			end
		end
	end)

	self:add()
	pd.getCrankTicks(5)
	if save.retro then
		newmusic('audio/music/chippy', true, 5000)
	else
		newmusic('audio/music/initialization', true, 5000)
	end

	if not save.found_retro then
		local sprCode = Tanuk_CodeSequence({pd.kButtonRight, pd.kButtonUp, pd.kButtonB, pd.kButtonDown, pd.kButtonUp, pd.kButtonB, pd.kButtonDown, pd.kButtonUp, pd.kButtonB}, function()
			if save.sfx then
				assets.select:play()
			end
			save.found_retro = true
			save.retro = true
			stopmusic()
			newmusic('audio/music/chippy', true, 0)
		end)
	end
end

function initialization:update()
	vars.crank_change += pd.getCrankChange()
	if vars.get_data then
		if net.getStatus() == net.kStatusNotAvailable then
			self:openui("nointernet")
		else
			if first_check and not save.setup then
				self:openticker(text("contacting_wb"))
				if save.sfx then assets.connect:play() end
				first_check = false
			else
				self:openticker(text("contacting"))
				if save.sfx then assets.connect:play() end
			end
			if save.setup then
				save.setup = false
				first_check = false
			end
			http:get("/v1/forecast.json?key=" .. key .. "&q=" .. urlencode(save.area) .. "&days=2&aqi=yes")
			http:setRequestCompleteCallback(function()
				http:setConnectTimeout(10)
				local bytes = http:getBytesAvailable()
				vars.data_response = http:read(bytes)
				if find(vars.data_response, "No matching location found.") or vars.data_response == "" then
					self:closeticker()
					self:openui("noarea")
					http:close()
					return
				else
					-- chunk data here
					vars.data_response_formatted = ""
					local index = 1
					for line in string.gmatch(vars.data_response, "[^\r?\n]+") do
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
					printTable(response_json)
					http:close()
					self:closeticker()
					fademusic(5000)
					if save.wallpaper == 2 then
						pd.timer.performAfterDelay(250, function()
							scenemanager:switchscene(weather, vars.earth_timer.timeLeft, vars.earth_timer.value, vars.stars_l.timeLeft, vars.stars_l.value, vars.stars_s.timeLeft, vars.stars_s.value, vars.crank_change)
						end)
					else
						scenemanager:transitionscene(weather)
					end
				end
			end)
		end
		vars.get_data = false
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
		if prompt == "welcome1" or prompt == "changearea" or prompt == "noarea" then
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
		elseif prompt == "nointernet" then
			assets.roobert11:drawTextAligned(text('tryagain'), 200, 200, kTextAlignment.center)
		end
	gfx.popContext()
	if prompt == "nointernet" or prompt == "noarea" then
		if save.sfx then assets.error:play() end
	else
		if save.sfx then assets.sfx_ui:play() end
	end
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