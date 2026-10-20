# Zenitha

An awesome, deluxe Pure-Lua game/app framework using Love2D.

## How to start

Add this repo as submodule in the root folder:

```sh
git submodule add https://github.com/26F-Studio/Zenitha.git
git submodule update --init
# Update in the future:
git submodule update
```

Then load with only one line in main.lua:

```lua
require("zenitha")
```

Run the project and you should see the demo scene. Explore other features yourself and have fun!

## Modules

### SCN (Scene)

allow you custom all callback functions for each scene and easily travel between them.

```lua
SCN.add("menu",require'scene/example.lua')
SCN.go("menu")
SCN.go("setting","fastFade")
SCN.back()

---@scene/example.lua
local scn={}

function scn.load(previous, ...) ... end
function scn.unload(target, ...) ... end
function scn.keyDown(k)
    if k=='escape' then SCN.back() end -- Default behavior if `.keyDown` not defined
end
function scn.keyUp(k) ... end
function scn.mouseDown(x,y,k) ... end
function scn.mouseUp(x,y,k) ... end
function scn.mouseMove(x,y,dx,dy) ... end
scn.touchDown=scn.mouseDown -- These 3 lines make touch events behave like mouse events for temporary convenience
scn.touchUp=scn.mouseUp
scn.touchMove=scn.mouseMove
function scn.update(dt) ... end
function scn.draw() ... end

scn.widgetList={
    {type='button',pos={1,1},x=-160,y=-60,w=300,h=100,text='QUIT',onClick=WIDGET.c_backScn()},
    ...
}

return scn
```

### BGM / SFX / VOC (Music/Effect/Voice)

allow you play audio events simpler.

```lua
BGM.load("bgm1","music/1.ogg")
BGM.play("bgm1") -- with smooth fade-in/out
SFX.load("click","sfx/click.ogg")
SFX.play("click")
SFX.play("click",0.8,-1,24) -- 80% Vol, left-sided, +2 Oct effect
-- Module will automatically create/unload idle resources.
```

### BG (Background)

a customizable layer under the scene.

```lua
BG.add("space",{...})
BG.setDefault("space")
BG.set("galaxy")
```

### WIDGET

interactive widgets layer above the scene, has the highest priority.

### MSG (Message)

an on-screen print, can be used to show notifications or warnings.

```lua
MSG('info',"Techmino is fun!")
```

### GC

extended lib of love.graphics.

```lua
GC.mDraw(obj,x,y,r,kx,ky)
GC.strokePrint(strokeMode,d,strokeColor,textColor,str,x,y)
GC.regPolygon(mode,x,y,rad,segments,rot)

local cam=GC.newCamera()
cam:move(dx,dy)
cam:scale(k)
cam:apply()

local bez=GC.newBezier({{x1,y1},{x2,y2},...})
bez:render(resolution)
GC.line(bez.curve)

GC.stc_setComp('equal',1)
GC.stc_rect(0,0,800,600)
...
GC.stc_stop()

GC.DO{
    {'setCL',COLOR.R},
    {'fRect',0,0,800,600},
    ...
}
```

### FONT

set font style & size easily as `GC.setColor`.

```lua
FONT.load{
    consolas="consola.ttf",
    pixel="codePixel-Regular.ttf"
    -- My monospaced coding font: github.com/MrZ626/codePixel
}
FONT.setFallback('pixel','consolas')
FONT.setDefaultFont('pixel')

FONT.set(26)
GC.print(...)

FONT.set(20,'consolas')
GC.print(...)
```

### IMG (Image)

allow images to be lazy-loaded after first used.

```lua
IMG.init{
    bg={"back/1.png","back/2.png","back/3.png"},
    ...
}
GC.draw(IMG.bg[1])
```

### FILE

save/load a lua table with one function call like `FILE.save(config,'conf.json')`.

```lua
FILE.save(config,'conf.json') -- Default to json
config=FILE.load('conf.json')
FILE.save(data,'data.lua','-luaon') -- Support "Luaon" format similar to Json
data=FILE.load('data.lua')
texts=FILE.load('log.txt','-string')
```

### LANG (Language)

an i18n module allow you manage all strings which displayed to players/users.

```lua
LANG.add{en='lang/en.lua',zh='lang/zh.lua'}
LANG.setDefault('en')
Text=LANG.set('zh')
print(Text.hello=="你好")
```

### MATH / STRING / TABLE

extended libs of standard Lua libs.

```lua
chebyshevDist=MATH.mDist2(0,x1,y1,x2,y2)
list=STRING.split("Welcome;to;Zenitha",";") -- {"Welcome","to","Zenitha"}
t2=TABLE.copyAll(t1)
```

### ASYNC

Asynchronous luaCode / systemCmd execution module using Love2D threads.

```lua
ASYNC.runLua('resultKey1',[[
    return "Hello"
]])

ASYNC.get('resultKey1') -- "Hello", or nil if not finished yet

ASYNC.runCmd('resultKey2',[[
    echo "World"
]])

ASYNC.get('resultKey2') -- "World", or nil if not finished yet
```

### TASK

a pseudo-async module allow you run a function asynchronously (as coroutine which must yield itself periodically, be continued once per main loop cycle).

```lua
TASK.lock("signal",2.56)
TASK.new(function()
    repeat yield() until not TASK.getLock("signal")
    print("Echo from Moon")
end)

function scene.keyDown(k)
    if k~='escape' then return end
    if TASK.lock('sureQuit',1) then MSG('info',Text.pressAgainToQuit) return end
    love.event.quit()
end
```

### TCP

allow you exchange data much easier then using LuaSocket. (Yet designed for data exchanging with TCP module itself, and using pure json only)

```lua
-- Simulate Server
TASK.new(function()
    TCP.S_start(10026)
    TASK.yieldT(0.26) -- Wait a bit, giving client time to send data
    print(TCP.S_receive()) -- "Hello server!"
end)

-- Simulate Client
TASK.new(function()
    TCP.C_connect("127.0.0.1", 10026)
    TCP.C_send("Hello server!")
end)
```

### Maintained HTTPS/WSS transport

Online clients now require `Zenitha.transport` explicitly instead of using the retired `HTTP` and `WS` globals. The independently correlated native transport uses maintained reqwest/rustls and tungstenite; Web/WASM uses browser fetch/WebSocket through the existing JS bridge. Unrelated local TCP and offline utilities are unchanged.

```lua
local Transport=require 'Zenitha.transport'
local client,err=Transport.new()
if not client then
    print(err.code) -- Missing packaged dependency does not prevent offline play.
    return
end
local requestId,requestError=client:request{
    url=configuredCadenceOrigin..'/health/live',
    method='GET',
    timeout=12, -- seconds
}
-- The business owner, not individual scenes, drains events each frame.
local event=client:poll()
if event and event.kind=='http' and event.id==requestId then
    print(event.status) -- event.body contains the complete response bytes.
end
-- client:destroy() on application exit.
```

HTTP bodies are bounded to 2 MiB and complete socket messages to 256 KiB. `connect`, `send`, `close`, `cancel`, `callbackBegin`, `openAuthorization` and protected session-storage operations have one consistent product adapter interface. Browser socket headers are rejected; obtain the single-use Cadence connection ticket through HTTPS first. Native refresh credentials belong in the OS store, and Web bearer credentials are never written to localStorage or IndexedDB.

Linux native HTTPS/WSS, TLS-negative, fragmentation, cancellation and loopback callback probes have passed. Packaged LÖVE, browser and actual-device acceptance are separate and are not inferred from compilation or workflow definitions.

### TWEEN

a simple tweening module allow you making smooth animation with several lines of codes

```lua
TWEEN.new(function(v) Pos=200+100*v end) -- update Pos with v which goes from 0 to 1
:setEase('InOutSin') -- with a sine curve
:setDuration(2.6) -- in 2.6 seconds
:setOnFinish(function() print("FIN") end) -- and print "FIN" when finished
:run() -- confirm and start
```

### PROFILE

a simple debug tool allow you start/stop profiling anytime, the result will be placed into the clipboard.

### COLOR

a set of common color tables which can be used with `COLOR.R` (red), `COLOR.dG` (dark green).

### LOG

a simple log tool allow you print fancy text to console and keep permanent log.

```lua
LOG('info',"26 audio assets loaded")
LOG('warn',"This app is currently in beta!")
```

### AE (ANSI Escape)

a simple shortcut tool allow you create ANSI escape code super easily

```lua
print(AE.b"Bold"..AE.i.."Underline Italic")
print(AE'r;d;_M'.."reset, delete, magenta "..AE.."and reset format manually")
```

### Other

And some useful utility functions like `ZENITHA.setMainLoopSpeed` `ZENITHA.setDebugInfo` `ZENITHA.setVersionText`.

Experimental modules:
`WAIT`, `DEBUG`, `SYSFX`, `TEXT`, `VIB`, `WHEELMOV`, `LOADLIB`, `MIDI`, `COMPILE`

Exterior modules:
`JSON`, json.lua by rxi;
`HASH`, sha2.lua by Egor Skriptunoff;

All ZENITHA module VARs are named in all UPPERCASE.
