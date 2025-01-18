# Zenitha

```text
---------------------------------------
|  _____           _ _   _            |
| / _  / ___ _ __ (_) |_| |__   __ _  |
| \// / / _ \ '_ \| | __| '_ \ / _' | |
|  / //\  __/ | | | | |_| | | | (_| | |
| /____/\___|_| |_|_|\__|_| |_|\__,_| |
|                                     |
---------------------------------------
```

**An awesome, deluxe Pure-Lua game/app framework using Love2D,**  
**with modules listed below:**

## SCN (Scene)

allow you custom all callback functions for each scene and easily travel between them.

```lua
SCN.add("menu",scene)
SCN.go("menu")
SCN.go("setting","fastFade")
SCN.back()
```

## BGM / SFX / VOC (Music/Effect/Voice)

allow you play audio events simpler.

```lua
BGM.play("bgm1") -- with smooth fade-in/out
SFX.play("click")
SFX.play("click",0.8,-1,24) -- 80% Vol, left-sided, +2 Oct effect
-- Module will automatically create/unload idle resources.
```

## BG (Background)

a customizable layer under the scene.

```lua
BG.add("space",{...})
BG.setDefault("space")
BG.set("galaxy")
```

## WIDGET

interactive widgets layer above the scene, has the highest priority.

## MSG (Message)

an on-screen print, can be used to show notifications or warnings.

```lua
MSG('info',"Techmino is fun!")
```

## GC

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

## FONT

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

## IMG (Image)

allow images to be lazy-loaded after first used.

```lua
IMG.init{
    bg={"back/1.png","back/2.png","back/3.png"},
    ...
}
GC.draw(IMG.bg[1])
```

## FILE

save/load a lua table with one function call like `FILE.save(config,'conf.json')`.

```lua
FILE.save(config,'conf.json') -- Default to json
config=FILE.load('conf.json')
FILE.save(data,'data.lua','-luaon') -- Support "Luaon" format similar to Json
data=FILE.load('data.lua')
texts=FILE.load('log.txt','-string')
```

## LANG (Language)

an i18n module allow you manage all strings which displayed to players/users.

```lua
LANG.add{en='lang/en.lua',zh='lang/zh.lua'}
LANG.setDefault('en')
Text=LANG.set('zh')
print(Text.hello=="你好")
```

## MATH / STRING / TABLE

extended libs of standard Lua libs.

```lua
chebyshevDist=MATH.mDist2(0,x1,y1,x2,y2)
list=STRING.split("Welcome;to;Zenitha",";") -- {"Welcome","to","Zenitha"}
t2=TABLE.copyAll(t1)
```

## TASK

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

## TCP

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

## WS (WebSocket)

a simple http websocket with LuaSocket.

```lua
local ws=WS.new({
    host="localhost",
    port="80",
    path="/ws",
    subPath="/res",
    subPath="/res",
})
ws:connect()

-- Client loop
TASK.new(function()
    repeat coroutine.yield() until ws.state~='connecting'
    ws:send("Hello server!")
    repeat
        local mes,op=ws:receive()
        if mes then
            print(mes,op) -- "Hello Cliend!", 1 (text type)
        end
    until ws.state~='running'
    print("WS disconnected")
end)
```

## HTTP

a simple http client with LuaSocket.

```lua
HTTP.setThreadCount(1)
HTTP.setHost("127.0.0.1")
HTTP.request{
    pool='login',
    path='/api/v1/userlogin',
    body={username='MrZ_26'},
}
local res
repeat res=HTTP.pollMsg('login') until res
print(res.code,res.body) -- "200", "<html>Welcome, MrZ_26</html>"
```

## TWEEN

a simple tweening module allow you making smooth animation with several lines of codes

```lua
TWEEN.new(function(v) Pos=200+100*v end) -- update Pos with v which goes from 0 to 1
:setEase('InOutSin') -- with a sine curve
:setDuration(2.6) -- in 2.6 seconds
:setOnFinish(function() print("FIN") end) -- and print "FIN" when finished
:run() -- confirm and start
```

## PROFILE

a simple debug tool allow you start/stop profiling anytime, the result will be placed into the clipboard.

## COLOR

a set of common color tables which can be used with `COLOR.R` (red), `COLOR.dG` (dark green).

## LOG

a simple log tool allow you print fancy text to console and keep permanent log.

```lua
LOG('info',"26 audio assets loaded")
LOG('warn',"This app is currently in beta!")
```

## AE (ANSI Escape)

a simple shortcut tool allow you create ANSI escape code super easily

```lua
print(AE.b"Bold"..AE.i.."Underline Italic")
print(AE'r;d;_M'.."reset, delete, magenta "..AE.."and reset format manually")
```

And some useful utility functions like `ZENITHA.setMainLoopSpeed` `ZENITHA.setDebugInfo` `ZENITHA.setVersionText`.

Experimental modules:
`WAIT`, `DEBUG`, `SYSFX`, `TEXT`, `VIB`, `WHEELMOV`, `LOADLIB`, `MIDI`

Exterior modules:
`JSON`, json.lua by rxi;
`HASH`, sha2.lua by Egor Skriptunoff;

All ZENITHA module VARs are named in all UPPERCASE.
