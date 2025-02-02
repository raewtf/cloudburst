-- Importing things
import 'CoreLibs/math'
import 'CoreLibs/timer'
import 'CoreLibs/object'
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/keyboard'
import 'CoreLibs/animation'
import 'scenemanager'
import 'initialization'
import 'weather'
scenemanager = scenemanager()

-- Setting up basic SDK params
local pd <const> = playdate
local gfx <const> = pd.graphics
local net <const> = pd.network
local smp <const> = pd.sound.sampleplayer
local fle <const> = pd.sound.fileplayer
local text <const> = gfx.getLocalizedText

pd.display.setRefreshRate(30)
gfx.setBackgroundColor(gfx.kColorWhite)
gfx.setLineWidth(2)

-- Save check
function savecheck()
	save = pd.datastore.read()
	if save == nil then save = {} end
	save.area = save.area or ""
	save.area_result = save.area_result or 0
	save.temp = save.temp or "celsius"
	save.speed = save.speed or "kph"
	save.meas = save.meas or "mm"
	if save.setup == nil then save.setup = true end
end

-- ... now we run that!
savecheck()

-- When the game closes...
function pd.gameWillTerminate()
	pd.datastore.write(save)
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
function newmusic(file, loop, range)
	if save.music and music == nil then -- If a music file isn't actively playing...then go ahead and set a new one.
		music = fle.new(file)
		if loop then -- If set to loop, then ... loop it!
			music:setLoopRange(range or 0)
			music:play(0)
		else
			music:play()
			music:setFinishCallback(function()
				music = nil
			end)
		end
	end
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

scenemanager:switchscene(initialization)

function pd.update()
	if not vars.http_opened then
		if vars.get_area then
			http = net.http.new("geocoding-api.open-meteo.com", 443, true, "using your local area to access location info.")
		else
			http = net.http.new("api.open-meteo.com", 443, true, "using your location info to retrieve local weather.")
			vars.get_weather = true
		end
		assert(http, 'Hi! Sorry about the crash, but it was the best way to reach you. Please allow access to the network connection gates to use this app! If you\'ve accidentally selected \'Never\', clear out the app\'s data from your Data Disk to continue - it\'s in the "wtf.rae.cloudburst" folder.')
		vars.http_opened = true
	end
	-- Catch-all stuff ...
	gfx.sprite.update()
	pd.timer.updateTimers()
	pd.drawFPS(10, 10)
end