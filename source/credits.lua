-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('credits').extends(gfx.sprite) -- Create the scene's class
function credits:init(...)
	credits.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
	end

	assets = {
		ashe = gfx.font.new('fonts/ashe'),
		sasser = gfx.font.new('fonts/sasser'),
		roobert11 = gfx.font.new('fonts/roobert11'),
		roobert24 = gfx.font.new('fonts/roobert24')
	}

	vars = {

	}
	vars.creditsHandlers = {
		BButtonDown = function()
			scenemanager:transitionscene(weather)
		end,
	}
	pd.inputHandlers.push(vars.creditsHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.ashe:drawTextAligned(text('credits'), 200, 10, kTextAlignment.center)
		gfx.drawLine(0, 45, 400, 45)
		gfx.drawLine(0, 208, 400, 208)
		gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 45, 400, 165)
		gfx.setColor(gfx.kColorBlack)
		assets.roobert11:drawTextAligned(text('credits_full'), 200, 60, kTextAlignment.center)
		assets.roobert11:drawTextAligned(text('back'), 200, 215, kTextAlignment.center)
	end)

	self:add()
end