--!nonstrict
-- Cappuccino - click to toggle caffeine. Awake, the steam sways while it is on; asleep, z's drift up while off.
--
-- The widget tracks its own on/off state: it starts off (as Noctalia's caffeine
-- does) and sets caffeine explicitly on each click. Each bar gets its own widget
-- instance, so the state lives in noctalia.state to keep every monitor's mug in step.
--
-- Frames in frames/: asleep-0..11.png (off, one z cycle), awake-0..7.png (on, one steam cycle).

local AWAKE_FRAMES, ASLEEP_FRAMES = 8, 12
local WIDTH, HEIGHT = 22, 26 -- logical px; frames are 240x284
local STATE_KEY = "caffeinated"

local caffeinated = noctalia.state.get(STATE_KEY) == true
local frame = 0

local function refresh()
  if caffeinated then
    barWidget.setImage("frames/awake-" .. frame .. ".png", false, WIDTH, HEIGHT)
    barWidget.setTooltip("Caffeine on")
  else
    barWidget.setImage("frames/asleep-" .. frame .. ".png", false, WIDTH, HEIGHT)
    barWidget.setTooltip("Caffeine off")
  end
end

local function show(enabled)
  caffeinated = enabled
  frame = 0
  refresh()
end

local function setCaffeinated(enabled)
  noctalia.runAsync({ "noctalia", "msg", if enabled then "caffeine-enable" else "caffeine-disable" })
  noctalia.state.set(STATE_KEY, enabled)
  show(enabled)
end

noctalia.state.watch(STATE_KEY, function(value)
  if (value == true) ~= caffeinated then
    show(value == true)
  end
end)

function update()
  frame = (frame + 1) % (if caffeinated then AWAKE_FRAMES else ASLEEP_FRAMES)
  refresh()
end

function onClick()
  setCaffeinated(not caffeinated)
end

-- noctalia msg plugin amerii/cappuccino:cappuccino all enable|disable
-- (no toggle: an `all` target reaches every bar's instance, so it would flip once per bar)
function onIpc(event)
  if event == "enable" or event == "disable" then
    setCaffeinated(event == "enable")
  end
end

noctalia.setUpdateInterval(120)
refresh()
