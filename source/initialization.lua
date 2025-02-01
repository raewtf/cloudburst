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

	assets = {
		roobert11 = gfx.font.new('fonts/roobert11'),
		roobert24 = gfx.font.new('fonts/roobert24'),
		sasser = gfx.font.new('fonts/sasser'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		earth = gfx.imagetable.new('images/earth'),
		bg = gfx.image.new('images/bg'),
	}

	vars = {
		earth_timer = pd.timer.new(30000, 1, 300),
		http_opened = false,
		http = nil,
		get_zip = true,
		zip_response = nil,
		zip_response_formatted = nil,
		get_weather = false,
		weather_response = nil,
		weather_response_formatted = nil,
	}

	vars.earth_timer.repeats = true

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.bg:draw(0, 0)
		assets.earth[math.floor(vars.earth_timer.value)]:draw(100, 140)
	end)

	self:add()
end

function initialization:update()
	if vars.get_zip then
		http:get("/v1/search?name=" .. save.zip .. "&count=1&language=en&format=json")
		http:setRequestCompleteCallback(function()
			http:setConnectTimeout(10)
			local bytes = http:getBytesAvailable()
			print(bytes)
			vars.zip_response = http:read(bytes)
			print(vars.zip_response)
			local response_start = 0
			local response_end = 0
			for i = 1, string.len(vars.zip_response) do
				if string.byte(vars.zip_response, i) == string.byte("{") then
					response_start = i
					break
				end
			end
			for i = string.len(vars.zip_response), 1, -1 do
				if string.byte(vars.zip_response, i) == string.byte("}") then
					response_end = i
					break
				end
			end
			vars.zip_response_formatted = string.sub(vars.zip_response, response_start, response_end)
			zip_response_json = json.decode(vars.zip_response_formatted)
			printTable(zip_response_json)
			http:close()
			vars.http_opened = false
			-- vars.get_weather = true
		end)
		vars.get_zip = false
	end
	if vars.get_weather then
		http:get("/v1/forecast?latitude=" .. zip_response_json.results[1].latitude .. "&longitude=" .. zip_response_json.results[1].longitude .. "&current=temperature_2m&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&timezone=" .. zip_response_json.results[1].timezone .. "&forecast_days=1")
		http:setRequestCompleteCallback(function()
			http:setConnectTimeout(10)
			local bytes = http:getBytesAvailable()
			print(bytes)
			vars.weather_response = http:read(bytes)
			print(vars.weather_response)
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
			printTable(weather_response_json)
			http:close()
			scenemanager:switchscene(weather)
		end)
		vars.get_weather = false
	end
end