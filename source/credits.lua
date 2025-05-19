-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText
local min <const> = math.min
local max <const> = math.max

class('credits').extends(gfx.sprite) -- Create the scene's class
function credits:init(...)
	credits.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?
	pd.datastore.write(save)
	pd.setAutoLockDisabled(false)

	function pd.gameWillPause()
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		pauseimage('credits', true)
	end

	assets = {
		ashe = gfx.font.new('fonts/ashe'),
		smallcaps = gfx.font.new('fonts/smallcaps'),
		roobert11 = gfx.font.new('fonts/roobert11'),
		back = smp.new('audio/sfx/back'),
		crank = smp.new('audio/sfx/crank'),
	}

	vars = {
		scroll = 0,
		lastscroll = 0,
		scrollmin = 0,
		scrollmax = 215,
	}
	vars.creditsHandlers = {
		BButtonDown = function()
			if save.sfx then assets.back:play() end
			scenemanager:transitionscene(weather)
		end,
	}
	pd.inputHandlers.push(vars.creditsHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setColor(gfx.kColorBlack)
		assets.roobert11:drawTextAligned(text('credits_full'), 190, 60 - vars.scroll, kTextAlignment.center)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 0, 400, 45)
		gfx.fillRect(0, 208, 400, 45)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawLine(0, 45, 400, 45)
		gfx.drawLine(0, 208, 400, 208)
		assets.ashe:drawTextAligned(text('credits'), 200, 10, kTextAlignment.center)
		assets.roobert11:drawTextAligned(text('credits_controls'), 200, 215, kTextAlignment.center)
		gfx.setDitherPattern(0.50, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRoundRect(384, 51, 11, 151, 5)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillCircleAtPoint(389, 194 - ((vars.scrollmax - min(max(vars.scroll, vars.scrollmin), vars.scrollmax))/vars.scrollmax) * 135, 8)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawCircleAtPoint(389, 194 - ((vars.scrollmax - min(max(vars.scroll, vars.scrollmin), vars.scrollmax))/vars.scrollmax) * 135, 8)
	end)

	self:add()
end

function credits:update()
	vars.scroll += pd.getCrankChange()
	if pd.buttonIsPressed('down') then
		vars.scroll += 10
	elseif pd.buttonIsPressed('up') then
		vars.scroll -= 10
	end
	if vars.scroll < vars.scrollmin then
		vars.scroll += (vars.scrollmin - vars.scroll) * 0.3
	elseif vars.scroll > vars.scrollmax then
		vars.scroll += (vars.scrollmax - vars.scroll) * 0.3
	end
	if vars.lastscroll ~= vars.scroll then
		gfx.sprite.redrawBackground()
	end
	vars.lastscroll = vars.scroll
end