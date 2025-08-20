classes = {}

-- Importing things
import 'CoreLibs/math'
import 'CoreLibs/timer'
import 'CoreLibs/crank'
import 'CoreLibs/object'
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/keyboard'
import 'CoreLibs/animation'
import 'scenemanager'
import 'initialization'
import 'weather'
import 'options'
import 'credits'
scenemanager = scenemanager()

-- Setting up basic SDK params
local pd <const> = playdate
local gfx <const> = pd.graphics
local net <const> = pd.network
local smp <const> = pd.sound.sampleplayer
local fle <const> = pd.sound.fileplayer
local text <const> = gfx.getLocalizedText
local abs <const> = math.abs
local floor <const> = math.floor
local random <const> = math.random
local format <const> = string.format
local byte <const> = string.byte
local char <const> = string.char

pd.display.setRefreshRate(30)
gfx.setBackgroundColor(gfx.kColorWhite)
gfx.setLineWidth(2)

catalog = false
if pd.metadata.bundleID == "wtf.rae.cloudburst" then
	catalog = true
end

first_check = true
key = nil

assert(key ~= nil, 'Hi, please input a weatherapi.com API key to continue! If you\'re seeing this error, you know what you\'re doing. If you don\'t, please get in touch!')

-- Save check
function savecheck()
	save = pd.datastore.read()
	if save == nil then save = {} end
	save.area = save.area or ""
	save.areas = save.areas or {}
	save.temp = save.temp or "celsius"
	save.speed = save.speed or "kph"
	save.meas = save.meas or "mm"
	save.refresh = save.refresh or "1hr"
	save.autolock = save.autolock or 20
	save.wallpaper = save.wallpaper or 1
	save.invert = save.invert or 1
	save.twofour = save.twofour or 1
	save.recentareas = save.recentareas or 10
	if save.found_retro == nil then save.found_retro = false end
	if save.retro == nil then save.retro = false end
	if save.sfx == nil then save.sfx = true end
	if save.music == nil then save.music = true end
	if save.setup == nil then save.setup = true end
end

-- ... now we run that!
savecheck()

time = pd.getTime()
lasthour = time.hour
if save.wallpaper == 5 and pd.datastore.readImage('images/custom') == nil then
	save.wallpaper = 1
end
local pause = gfx.image.new('images/pause')
local pause_full = gfx.image.new('images/pause_full')
local roobert10 = gfx.font.new('fonts/roobert10')
local pause_copy = gfx.image.new(400, 240)

function pauseimage(scene, tip)
	pause_copy = gfx.image.new(400, 240)
	gfx.pushContext(pause_copy)
	if tip then
		pause:draw(0, 0)
		roobert10:drawText(text('tip' .. random(1, 20)), 9, 152)
	else
		pause_full:draw(0, 0)
	end
		roobert10:drawText('Cloudburst', 26, 5)
		roobert10:drawTextAligned('v' .. pd.metadata.version, 195, 5, kTextAlignment.right)
		roobert10:drawText(text(scene .. '_help'), 5, 35)
	gfx.popContext()
	pd.setMenuImage(pause_copy)
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

-- When the game closes...
function pd.gameWillTerminate()
	pd.datastore.write(save)
	local img = gfx.getDisplayImage()
	local byebye = gfx.imagetable.new('images/fade/fade')
	local byebyeanim = gfx.animator.new(750, 1, #byebye)
	local sfx = smp.new('audio/sfx/foldclose')
	if save.sfx then sfx:play() end
	gfx.setDrawOffset(0, 0)
	while not byebyeanim:ended() do
		img:draw(0, 0)
		byebye:drawImage(floor(byebyeanim:currentValue()), 0, 0)
		pd.display.flush()
	end
end

function pd.deviceWillSleep()
	pd.datastore.write(save)
end

-- Setting up music
music = nil

-- Fades the music out, and trashes it when finished. Should be called alongside a scene change, only if the music is expected to change. Delay can set the delay (in seconds) of the fade
function fademusic(delay)
	delay = delay or 1000
	if music ~= nil then
		music:setVolume(0, 0, delay/1000, function()
			music:stop()
			music = nil
		end)
	end
end

function stopmusic()
	if music ~= nil then
		music:stop()
		music = nil
	end
end

-- New music track. This should be called in a scene's init, only if there's no track leading into it. File is a path to an audio file in the PDX. Loop, if true, will loop the audio file. Range will set the loop's starting range.
function newmusic(file, loop, delay)
	if save.music and music == nil then -- If a music file isn't actively playing...then go ahead and set a new one.
		music = fle.new(file)
		music:setVolume(0)
		if loop then -- If set to loop, then ... loop it!
			music:setLoopRange(range or 0)
			music:play(0)
		else
			music:play()
			music:setFinishCallback(function()
				music = nil
			end)
		end
		music:setVolume(1, 1, delay/1000)
	end
end

-- ref: https://gist.github.com/ignisdesign/4323051
-- ref: http://stackoverflow.com/questions/20282054/how-to-urldecode-a-request-uri-string-in-lua
-- to encode table as parameters, see https://github.com/stuartpb/tvtropes-lua/blob/master/urlencode.lua
char_to_hex = function(c)
  return format("%%%02X", byte(c))
end
function urlencode(url)
  if url == nil then
	return
  end
  url = url:gsub("\n", "\r\n")
  str = url:gsub("([^%w _%%%-%.~])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end
hex_to_char = function(x)
  return char(tonumber(x, 16))
end
urldecode = function(url)
  if url == nil then
	return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end

function pd.timer:resetnew(duration, startValue, endValue, easingFunction)
	self.duration = duration
	if startValue ~= nil then
		self._startValue = startValue
		self.originalValues.startValue = startValue
		self._endValue = endValue or 0
		self.originalValues.endValue = endValue or 0
		self._easingFunction = easingFunction or pd.easingFunctions.linear
		self.originalValues.easingFunction = easingFunction or pd.easingFunctions.linear
		self._currentTime = 0
		self.value = self._startValue
	end
	self._lastTime = nil
	self.active = true
	self.hasReversed = false
	self.reverses = false
	self.repeats = false
	self.remainingDelay = self.delay
	self._calledOnRepeat = nil
	self.discardOnCompletion = false
	self.paused = false
	self.timerEndedCallback = self.timerEndedCallback
end

scenemanager:transitionsceneout(initialization)

function pd.update()
	if not vars.http_opened and vars.iwarnedyouabouthttpbroitoldyoudog then
		http = net.http.new("api.weatherapi.com", 443, true, "using your location info to retrieve weather data from weatherapi.com.")
		assert(http, 'Hi, please allow access to the network connection gates to use this app! Head to Settings > Permissions > Cloudburst, and set the Network permissions to "allow".')
		vars.http_opened = true
	end
	-- Catch-all stuff ...
	gfx.sprite.update()
	pd.timer.updateTimers()
	time = pd.getTime()
	if save.invert == 3 then
		if lasthour < 12 and time.hour >= 12 then
			pd.display.setInverted(true)
			lasthour = time.hour
		elseif lasthour == 23 and time.hour == 0 then
			pd.display.setInverted(false)
			lasthour = time.hour
		end
	end
end