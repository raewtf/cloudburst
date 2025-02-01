-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('weather').extends(gfx.sprite) -- Create the scene's class
function weather:init(...)
	weather.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	assets = {
		sasser = gfx.font.new('fonts/sasser'),
		roobert24 = gfx.font.new('fonts/roobert24')
	}

	vars = {

	}

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.sasser:drawText('Weather in ' .. zip_response_json.results[1].admin1 .. ', ' .. zip_response_json.results[1].country_code, 10, 10)
		assets.roobert24:drawText(weather_response_json.current.temperature_2m .. weather_response_json.current_units.temperature_2m, 10, 30)
	end)

	self:add()
end