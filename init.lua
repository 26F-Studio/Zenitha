--  #   _____           _ _   _             #
--  #  / _  / ___ _ __ (_) |_| |__   __ _   #
--  #  \// / / _ \ '_ \| | __| '_ \ / _` |  #
--  #   / //\  __/ | | | | |_| | | | (_| |  #
--  #  /____/\___|_| |_|_|\__|_| |_|\__,_|  #
--  #                                       #

--  > An awesome, deluxe Pure-Lua game/app framework using Love2D, with modules listed below:
--
--  `SCN` (Scene), allow you custom all callback functions for each scene and easily travel between them.
--   ```
--      SCN.add("menu",scene)
--      SCN.go("menu")
--      SCN.go("setting","fastFade")
--      SCN.back()
--   ```
--  `BGM`/`SFX`/`VOC` (Effect/Music/Voice), allow you play audio events simpler.
--   ```
--      BGM.play("bgm1") -- with smooth fade-in/out
--      SFX.play("click")
--      SFX.play("click",0.8,-1,24) -- 80% Vol, left-sided, +2 Oct effect
--      -- Module will automatically create/unload idle resources.
--   ```
--  `BG` (Background), a customizable layer under the scene.
--   ```
--      BG.add("space",bg)
--      BG.setDefault("space")
--      BG.set("galaxy")
--   ```
--  `WIDGET`, interactive widgets layer above the scene, has the highest priority.
--
--  `MSG` (Message), an on-screen print, can be used to show notifications or warnings.
--   ```
--      MSG.new('info',"Techmino is fun!")
--   ```
--  `GC`, extended lib of love.graphics.
--   ```
--      GC.mDraw(); GC.regPolygon();
--      GC.newCamera(); GC.newBezier(); 
--      GC.stc_setComp('equal',1); GC.stc_rect(0,0,800,600); ...; GC.stc_stop()
--      GC.DO{{'setCL',COLOR.R},{'fRect',0,0,800,600},...}
--   ```
--  `FONT`, set font style & size easily as `GC.setColor`.
--   ```
--      FONT.load{
--          consolas="consola.ttf",
--          pixel="codePixel-Regular.ttf"
--      }
--      FONT.set(20,'consolas')
--      FONT.setDefaultFont('pixel') -- My monospaced coding font: github.com/MrZ626/codePixel
--      FONT.set(26)
--      FONT.setFallback('pixel','consolas')
--   ```
--  `IMG` (Image), allow images to be lazy-loaded after first used.
--   ```
--      IMG.init{
--          bg={"back/1.png","back/2.png","back/3.png"},
--          ...
--      }
--      GC.draw(IMG.bg[1])
--   ```
--  `FILE`, save/load a lua table with one function call like `FILE.save(config,'conf.json')`.
--   ```
--      FILE.save(config,'conf.json') -- Default to json
--      config=FILE.load('conf.json')
--      FILE.save(data,'data.lua','-luaon') -- Support "Luaon" format similar to Json
--      data=FILE.load('data.lua')
--      texts=FILE.load('log.txt','-string')
--   ```
--  `LANG` (Language), an i18n module allow you manage all strings which displayed to players/users.
--   ```
--      LANG.add{en='lang/en.lua',zh='lang/zh.lua'}
--      LANG.setDefault('en')
--      Text=LANG.set('zh')
--      print(Text.hello=="你好")
--   ```
--  `MATH`/`STRING`/`TABLE`, extended libs of standard Lua libs.
--   ```
--      chebyshevDist=MATH.mDist2(0,x1,y1,x2,y2)
--      list=STRING.split("Welcome;to;Zenitha",";") -- {"Welcome","to","Zenitha"}
--      t2=TABLE.copyAll(t1)
--   ```
--  `TASK`, a pseudo-async module allow you run a function asynchronously (as coroutine which must yield itself periodically, be continued once per main loop cycle).
--   ```
--      TASK.lock("signal",2.56)
--      TASK.new(function()
--          repeat yield() until not TASK.getLock("signal")
--          print("Echo from Moon")
--      end)
--
--      function scene.keyDown(k)
--          if k~='escape' then return end
--          if TASK.lock('sureQuit',1) then MSG.new('info',Text.pressAgainToQuit) return end
--          love.event.quit()
--      end
--   ```
--  `TCP`, allow you exchange data much easier then using LuaSocket. (Yet designed for data exchanging with TCP module itself, and using pure json only)
--   ```
--      TASK.new(function() -- Simulate Server
--          TCP.S_start(10026)
--          TASK.yieldT(0.26) -- Wait a bit, or getting a nil from TCP:S_receive()
--          print(TCP.S_receive()) -- "Hello server!"
--      end)
--      TASK.new(function() -- Simulate Client
--          TCP.C_connect("127.0.0.1", 10026)
--          TCP.C_send("Hello server!")
--      end)
--   ```
--  `WS`, a simple http websocket with LuaSocket.
--   ```
--      local ws=WS.new({
--          host="localhost",
--          port="80",
--          path="/ws",
--          subPath="/res",
--          subPath="/res",
--      })
--      ws:connect()
--      TASK.new(function() -- Simulate Client
--          repeat coroutine.yield() until ws.state~='connecting'
--          ws:send("Hello server!")
--          repeat
--              local mes,op=ws:receive()
--              if mes then
--                  print(mes,op) -- "Hello Cliend!", 1 (text type)
--              end
--          until ws.state~='running'
--          print("WS disconnected")
--      end)
--   ```
--  `HTTP`, a simple http client with LuaSocket.
--   ```
--      HTTP.setThreadCount(1)
--      HTTP.setHost("127.0.0.1")
---     HTTP.request{
---         pool='login',
---         path='/api/v1/userlogin',
---         body={username='MrZ_26'},
---     }
---     local res
---     repeat res=HTTP.pollMsg('login') until res
---     print(res.code,res.body) -- "200", "<html>Welcome, MrZ_26</html>"
--   ```
--  `TWEEN`, a simple tweening module allow you making smooth animation with several lines of codes
--   ```
--      TWEEN.new(function(v) Pos=200+100*v end) -- update Pos with v which goes from 0 to 1
--      :setEase('InOutSin') -- with a sine curve
--      :setDuration(2.6) -- in 2.6 seconds
--      :setOnFinish(function() print("FIN") end) -- and print "FIN" when finished
--      :run() -- confirm start
--   ```
--  `PROFILE`, a simple debug tool allow you start/stop profiling anytime, the result will be placed into the clipboard.
--
--  `COLOR`, a set of common color tables which can be used with `COLOR.R` (red), `COLOR.dG` (dark green).
--
--  And some useful utility functions like `ZENITHA.setMaxFPS` `ZENITHA.setDebugInfo` `ZENITHA.setVersionText`.
--
--  Experimental modules:
--  `WAIT`, `DEBUG`, `LOG`, `SYSFX`, `TEXT`, `VIB`, `WHEELMOV`, `REQUIRE`, `HTTP`, `MIDI`
--
--  Exterior modules:
--  `JSON`, json.lua by rxi;
--  `HASH`, sha2.lua by Egor Skriptunoff;
--
--  All ZENITHA module VARs are named in all UPPERCASE.
---@class Zenitha.Main
ZENITHA={}

--------------------------------------------------------------

-- typedef (you need Lua language server extension to make all these "---@xxx" things work) (Recommend extension: "Lua" by sumneko)

---@class Set<T>: { [T]:any }
---@class Map<T>: { [any]:T }
---@class Mat<T>: { [integer]:{ [integer]:T } }

---@class Zenitha.Click
---@field x number
---@field y number

---@class Zenitha.Exception
---@field msg table
---@field scene string
---@field shot? love.ImageData

---@class Zenitha.JoystickState
---@field _id number
---@field _jsObj love.Joystick
---@field leftx number
---@field lefty number
---@field rightx number
---@field righty number
---@field triggerleft number
---@field triggerright number

--------------------------------------------------------------

-- #define
local MSisDown,KBisDown=love.mouse.isDown,love.keyboard.isDown

local gc=love.graphics or setmetatable({},{__index=function() return NULL end})
local gc_replaceTransform,gc_translate,gc_present=gc.replaceTransform,gc.translate,gc.present
local gc_setColor,gc_circle=gc.setColor,gc.circle
local gc_print,gc_printf=gc.print,gc.printf

local max,min=math.max,math.min
local floor,abs=math.floor,math.abs
math.randomseed(os.time()*2600)
love.keyboard.setKeyRepeat(true)

--------------------------------------------------------------

-- Useful global values/variables
---@type table Empty table used as placeholder
NONE=setmetatable({},{__newindex=function() error("NONE: Attempt to modify constant table") end,__metatable=true})
---@type function Empty function used as placeholder
NULL=function(...) end
---@type love.Canvas Empty canvas used as placeholder
PAPER=love.graphics.newCanvas(1,1)

---@type 'macOS'|'Windows'|'Linux'|'Android'|'iOS'
SYSTEM=love.system.getOS():gsub('OS X','macOS')
---@type boolean (NOT RELIABLE) true if the system is Android or iOS
MOBILE=SYSTEM=='Android' or SYSTEM=='iOS'
---@type string Editting text, used by inputBox widget
EDITING=""

---print with formatted string
---@param str string
---@diagnostic disable-next-line
function printf(str,...) print(str:format(...)) end

---error with formatted string
---@param str string
---@diagnostic disable-next-line
function errorf(str,...) error(str:format(...)) end

---assert with formatted string
---@generic T
---@param v T
---@param str string
---@return T
---@diagnostic disable-next-line
function assertf(v,str,...) return v or error(str:format(...)) end

---Use `local require=requirePath(...)` to require modules in simpler way
---@overload fun(loader:function):unknown
---@param path string
function simpRequire(path)
    return type(path)=='function' and
        function(module) return path(module) end or
        function(module) return require(path..module) end
end

-- Inside values
local mainLoopStarted=false
local devMode=false ---@type false|1|2|3|4
local mx,my,mouseShow,cursorSpd=640,360,false,0
local lastClicks={} ---@type Zenitha.Click[]
local jsState={} ---@type Zenitha.JoystickState[]
local errData={} ---@type Zenitha.Exception[]
local bigCanvases=setmetatable({},{
    __index=function(self,k)
        self[k]=gc.newCanvas(nil,nil,{msaa=select(3,love.window.getMode()).msaa})
        return self[k]
    end,
})

-- User-changeable values
local appName='Zenitha'
local versionText='V0.1'
local firstScene='_zenitha'
local discardCanvas=false
local showFPS=true
local updateFreq=100
local drawFreq=100
local sleepInterval=1/60
local clickDist2=62
local maxErrorCount=3
local globalEvent={
    mouseDown=NULL, -- Able to interrupt scene event
    mouseMove=NULL, -- Able to interrupt scene event and widget interaction
    mouseUp=NULL, -- Able to interrupt scene event
    mouseClick=NULL, -- Able to interrupt scene event
    wheelMove=NULL, -- Able to interrupt scene event and widget interaction

    touchDown=NULL, -- Able to interrupt scene event
    touchUp=NULL, -- Able to interrupt scene event
    touchMove=NULL, -- Able to interrupt scene event
    touchClick=NULL, -- Able to interrupt scene event

    -- Able to interrupt scene event and widget interaction
    --
    -- Default to a debugging tool, switch on/off with F8, then use it with F1~F12
    keyDown=function(key,isRep)
        if isRep then return end
        if devMode then
            if     key=='f1'  then -- Show system info
                local info=("System:%s[%s]\nLuaVer:%s\nJitVer:%s\nJitVerNum:%s"):format(SYSTEM,jit.arch,_VERSION,jit.version,jit.version_num)
                print(info); MSG.new('info',info); return true
            elseif key=='f2'  then -- Quick profiling
                local info=PROFILE.switch() and "Profile start!" or "Profile report copied!"
                print(info); MSG.new('info',info); return true
            elseif key=='f3'  then -- Show screen info
                local info=table.concat(SCR.info(),"\n")
                print(info); MSG.new('info',info); return true
            elseif key=='f4'  then -- Show everything in _G
                for k,v in next,_G do print(k,v) end
                MSG.new('info',"_G listed in console")
            elseif key=='f5'  then -- Show selected widget info
                local info=WIDGET.sel and WIDGET.sel:getInfo() or "No widget selected"
                print(info); MSG.new('info',info); return true
            elseif key=='f6'  then -- Show scene stack
                local info="Scene stack:"..table.concat(SCN.stack,"->")
                print(info); MSG.new('info',info); return true
            elseif key=='f7'  then -- Open console
                if love['_openConsole'] then love['_openConsole']() end
                MSG.new('info',"Console opened")
            elseif key=='f8'  then devMode=false MSG.new('info',"DEBUG OFF",.2);      return true
            elseif key=='f9'  then devMode=1     MSG.new('info',"DEBUG 1 (Basic)");   return true
            elseif key=='f10' then devMode=2     MSG.new('info',"DEBUG 2 (Widget)");  return true
            elseif key=='f11' then devMode=3     MSG.new('info',"DEBUG 3 (Slow)");    return true
            elseif key=='f12' then devMode=4     MSG.new('info',"DEBUG 4 (Sloooow)"); return true
            elseif devMode==2 then -- Adjust Widget
                local W=WIDGET.sel ---@type table
                if not W then return end
                local editted
                if     key=='left'  then W.x=W.x-10; editted=true
                elseif key=='right' then W.x=W.x+10; editted=true
                elseif key=='up'    then W.y=W.y-10; editted=true
                elseif key=='down'  then W.y=W.y+10; editted=true
                elseif key==',' then W.w=W.w-10; editted=true
                elseif key=='.' then W.w=W.w+10; editted=true
                elseif key=='/' then W.h=W.h-10; editted=true
                elseif key=="'" then W.h=W.h+10; editted=true
                elseif key=='[' then W.fontSize=W.fontSize-5; editted=true
                elseif key==']' then W.fontSize=W.fontSize+5; editted=true
                end
                if editted then
                    W:reset()
                    return true
                end
            end
        elseif key=='f8' then
            devMode=1
            MSG.new('info',"DEBUG 1 (Basic)",.2)
            return true
        end
    end,
    keyUp=NULL, -- Able to interrupt scene event
    textInput=NULL, -- Able to interrupt scene event and widget interaction
    imeChange=NULL, -- Able to interrupt scene event and var `EDIT` updating

    gamepadAdd=NULL, -- Able to interrupt gamepad managing
    gamepadRemove=NULL, -- Able to interrupt gamepad managing
    gamepadAxis=NULL, -- Able to interrupt gamepad managing
    gamepadDown=NULL, -- Able to interrupt scene event and widget interaction
    gamepadUp=NULL, -- Able to interrupt scene event

    fileDrop=NULL, -- Able to interrupt scene event
    folderDrop=NULL, -- Able to interrupt scene event
    lowMemory=NULL, -- Able to interrupt scene event
    resize=NULL, -- Able to interrupt scene event
    focus=NULL, -- Able to interrupt scene event

    -- System info function (like time and battery power) drawing function (default transform is SCR.xOy_ul)
    drawSysInfo=NULL,

    -- Cursor drawing function (pass time,x,y as arguments) (Color and line width is uncertain)
    drawCursor=function(_,x,y)
        gc_setColor(1,1,1)
        gc.setLineWidth(2)
        gc_circle(MSisDown(1) and 'fill' or 'line',x,y,6)
    end,

    -- Called when "Click Event" triggered
    clickFX=function(x,y,_) SYSFX.tap(.26,x,y) end,

    -- Called when request quiting with ZENITHA._quit()
    requestQuit=NULL,

    -- Called when exactly before quiting
    quit=NULL,

    -- When exist, called when love.errorhandler is called. Normally you should handle error with scene named 'error'.
    error=false,
}

--------------------------------------------------------------

local require=simpRequire((...)..'.')

-- Extended lua basic libraries
MATH=       require'mathExtend'
STRING=     require'stringExtend'
TABLE=      require'tableExtend'

-- Pure lua modules (simple)
COLOR=      require'color'
RGB9={}     --[[Get color literal with `RGB9[960]`(Red)   ]] for r=0,9 do for g=0,9 do for b=0,9 do RGB9[100*r+10*g+b]={r/9,g/9,b/9} end end end
RGBA9={}    --[[Get color literal with `RGBA9[9609]`(Red) ]] for r=0,9 do for g=0,9 do for b=0,9 do for a=0,9 do RGBA9[1000*r+100*g+10*b+a]={r/9,g/9,b/9,a/9} end end end end
RGB5={}     --[[Get color literal with `RGB5[520]`(Red)   ]] for r=0,5 do for g=0,5 do for b=0,5 do RGB5[100*r+10*g+b]={r/5,g/5,b/5} end end end
RGBA5={}    --[[Get color literal with `RGBA5[5205]`(Red) ]] for r=0,5 do for g=0,5 do for b=0,5 do for a=0,5 do RGBA5[1000*r+100*g+10*b+a]={r/5,g/5,b/5,a/5} end end end end
RGB2={}     --[[Get color literal with `RGB2[210]`(Red)   ]] for r=0,2 do for g=0,2 do for b=0,2 do RGB2[100*r+10*g+b]={r/2,g/2,b/2} end end end
DEBUG=      require'debug'
LOG=        require'log'
JSON=       require'json'

-- Pure lua modules (complex, with update/draw)
LANG=       require'languages'
REQUIRE=    require'require'
PROFILE=    require'profile'
TASK=       require'task'
HASH=       require'sha2'

-- Love-based modules (simple)
VIB=        require'vibrate'
WHEELMOV=   require'wheelToArrow'
FONT=       require'font'
IMG=        require'image'
FILE=       require'file'
SCR=        require'screen'
GC=         require'gcExtend'
TCP=        require'tcp'
MIDI=       require'midi'

-- Love-based modules (complex, with update/draw)
HTTP=       require'http'
WS=         require'websocket'
SCN=        require'scene'
TEXT=       require'text'
SYSFX=      require'sysFX'
TWEEN=      require'tween'
WAIT=       require'wait'
MSG=        require'message'
BG=         require'background'
WIDGET=     require'widget'
SFX=        require'sfx'
BGM=        require'bgm'
VOC=        require'voice'

--------------------------------------------------------------

local TASK,HTTP,SCN,SCR,TEXT,SYSFX,TWEEN,WAIT,MSG,BG,WIDGET,VOC=TASK,HTTP,SCN,SCR,TEXT,SYSFX,TWEEN,WAIT,MSG,BG,WIDGET,VOC
local xOy=SCR.xOy
local ITP=xOy.inverseTransformPoint
local setFont=FONT.set

-- Set default font
FONT.load({
    _norm=(...)..'/norm.ttf',
    _mono=(...)..'/mono.ttf',
})
FONT.setDefaultFont('_norm')
FONT.setDefaultFallback('_norm')

--------------------------------------------------------------

local function _updateMousePos(x,y,dx,dy)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Interrupt by global event
    if globalEvent.mouseMove(mx,my,dx,dy)==true then return end

    if SCN.mouseMove then SCN.mouseMove(x,y,dx,dy) end
    if MSisDown(1) then
        WIDGET._drag(x,y,dx,dy)
    else
        WIDGET._cursorMove(x,y,'move')
    end
end
local function _triggerMouseDown(x,y,k,presses)
    -- Debug info
    if devMode==1 then
        if not lastClicks[k] then lastClicks[k]={x=0,y=0} end
        print(("(%d,%d)<-%d,%d ~~(%d,%d)<-%d,%d"):format(
            x,y,
            x-lastClicks[k].x,y-lastClicks[k].y,
            floor(x/10)*10,floor(y/10)*10,
            floor((x-lastClicks[k].x)/10)*10,floor((y-lastClicks[k].y)/10)*10
        ))
    end

    -- Interrupt by scene swapping
    if SCN.swapping then return end

    WIDGET._cursorMove(x,y,'press')
    if WIDGET.sel then
        WIDGET._press(x,y,k)
    else
        -- Skip scene event by global event
        if globalEvent.mouseDown(mx,my,k,presses)~=true then
            if SCN.mouseDown then SCN.mouseDown(x,y,k,presses) end
        end
        lastClicks[k]={x=x,y=y}
    end
    globalEvent.clickFX(x,y,k)
end
local function mouse_update(dt)
    if not KBisDown('lctrl','rctrl') and KBisDown('up','down','left','right') then
        local dx,dy=0,0
        if KBisDown('up')    then dy=dy-cursorSpd end
        if KBisDown('down')  then dy=dy+cursorSpd end
        if KBisDown('left')  then dx=dx-cursorSpd end
        if KBisDown('right') then dx=dx+cursorSpd end
        if dx==0 and dy==0 then return end

        mx=max(min(mx+dx,SCR.w0),0)
        my=max(min(my+dy,SCR.h0),0)
        if my==0 or my==SCR.h0 and dy~=0 then
            WIDGET.sel=false
            WIDGET._drag(0,0,0,-dy)
        end
        _updateMousePos(mx,my,dx,dy)
        cursorSpd=min(cursorSpd+dt*26,12.6)
    else
        cursorSpd=6
    end
end
local function gp_update(js,dt)
    local sx,sy=js._jsObj:getGamepadAxis('leftx'),js._jsObj:getGamepadAxis('lefty')
    if abs(sx)>.1 or abs(sy)>.1 then
        local dx,dy=0,0
        if abs(sy)>.1 then dy=dy+2*sy*cursorSpd end
        if abs(sx)>.1 then dx=dx+2*sx*cursorSpd end
        if dx==0 and dy==0 then return end

        mx=max(min(mx+dx,SCR.w0),0)
        my=max(min(my+dy,SCR.h0),0)
        if my==0 or my==SCR.h0 then
            WIDGET.sel=false
            WIDGET._drag(0,0,0,-dy)
        end
        _updateMousePos(mx,my,dx,dy)
        cursorSpd=min(cursorSpd+dt*26,12.6)
    else
        cursorSpd=6
    end
end
---@type love.mousepressed
---@param x number
---@param y number
---@param k? number
---@param touch? boolean
---@param presses? number
function love.mousepressed(x,y,k,touch,presses)
    if touch or WAIT.state then return end
    mouseShow=true
    mx,my=ITP(xOy,x,y)

    _triggerMouseDown(mx,my,k,presses)
end
---@type love.mousemoved
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param touch? boolean
function love.mousemoved(x,y,dx,dy,touch)
    if touch then return end
    mouseShow=true

    x,y=ITP(xOy,x,y)
    mx,my=x,y
    dx,dy=dx/SCR.k,dy/SCR.k

    for k,last in next,lastClicks do
        if type(k)=='number' and (x-last.x)^2+(y-last.y)^2>clickDist2 then
            lastClicks[k]=nil
        end
    end

    _updateMousePos(mx,my,dx,dy)
end
---@type love.mousereleased
---@param x number
---@param y number
---@param k? number
---@param touch? boolean
---@param presses? number
function love.mousereleased(x,y,k,touch,presses)
    if touch or WAIT.state or SCN.swapping then return end
    mx,my=ITP(xOy,x,y)

    local widgetSel=not not WIDGET.sel
    if widgetSel then
        WIDGET._release(mx,my,k)
    end

    -- Skip scene event by global event
    if globalEvent.mouseUp(mx,my,k,presses)~=true then
        if SCN.mouseUp then SCN.mouseUp(mx,my,k,presses) end
    end

    if not widgetSel and lastClicks[k] then
        local dist=((x-lastClicks[k].x)^2+(y-lastClicks[k].y)^2)^.5
        -- Skip scene event by global event
        if globalEvent.mouseClick(mx,my,k,dist,presses)~=true then
            if SCN.mouseClick then
                SCN.mouseClick(mx,my,k,dist,presses)
            end
        end
    end

    WIDGET._cursorMove(mx,my,'release')
end
---@type love.wheelmoved
---@param dx number ±1 for each wheel movement
---@param dy number ±1 for each wheel movement
function love.wheelmoved(dx,dy)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Interrupt by global event
    if globalEvent.wheelMove(dx,dy)==true then return end

    -- Interrupt by scene event
    if SCN.wheelMove and SCN.wheelMove(dx,dy)==true then return end

    WIDGET._scroll(dx,dy)
end

---@type love.touchpressed
---@param id lightuserdata
---@param x number
---@param y number
---@param _? number dx and dy, ignored because always 0
---@param pressure? number
function love.touchpressed(id,x,y,_,_,pressure)
    -- Hide cursor when key pressed
    mouseShow=false

    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Update mainTouchID
    if not SCN.mainTouchID then
        SCN.mainTouchID=id
        WIDGET.unFocus(true)
        love.touchmoved(id,x,y,0,0,pressure)
    end

    -- Transform to designing coord
    x,y=ITP(xOy,x,y)

    lastClicks[id]={x=x,y=y}
    if WIDGET.sel and WIDGET.sel.type=='inputBox' and not WIDGET.sel:isAbove(x,y) then
        WIDGET.unFocus(true)
        love.keyboard.setTextInput(false)
    end
    WIDGET._cursorMove(x,y,'press')
    WIDGET._press(x,y,1)

    -- Skip scene event by global event
    if globalEvent.touchDown(x,y,id,pressure)~=true then
        if not WIDGET.sel and SCN.touchDown then SCN.touchDown(x,y,id,pressure) end
    end
end
---@type love.touchmoved
---@param id lightuserdata
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param pressure? number
function love.touchmoved(id,x,y,dx,dy,pressure)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Transform to designing coord
    x,y=ITP(xOy,x,y)
    dx,dy=dx/SCR.k,dy/SCR.k

    if lastClicks[id] and (x-lastClicks[id].x)^2+(y-lastClicks[id].y)^2>clickDist2 then
        lastClicks[id]=nil
    end
    WIDGET._drag(x,y,dx,dy)

    -- Skip scene event by global event
    if globalEvent.touchMove(x,y,id,pressure)~=true then
        if not WIDGET.sel and SCN.touchMove then SCN.touchMove(x,y,dx,dy,id,pressure) end
    end
end
---@type love.touchreleased
---@param id lightuserdata
---@param x number
---@param y number
---@param _? number dx and dy, ignored because always 0
---@param pressure? number
function love.touchreleased(id,x,y,_,_,pressure)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Transform to designing coord
    x,y=ITP(xOy,x,y)
    if id==SCN.mainTouchID then
        WIDGET._release(x,y,id)
        WIDGET._cursorMove(x,y,'release')
        WIDGET.unFocus()
        SCN.mainTouchID=false
    end

    -- Skip scene event by global event
    if globalEvent.touchUp(x,y,id,pressure)~=true then
        if SCN.touchUp then SCN.touchUp(x,y,id,pressure) end
    end

    if lastClicks[id] then
        local dist=((x-lastClicks[id].x)^2+(y-lastClicks[id].y)^2)^.5
        -- Skip scene event by global event
        if globalEvent.touchClick(x,y,id,dist)~=true then
            if SCN.touchClick then SCN.touchClick(x,y,id,dist) end
        end
        globalEvent.clickFX(x,y,1)
    end
end

-- Touch control test
-- function love.mousepressed(x,y,k) if k==1 then love.touchpressed(1,x,y) end end
-- function love.mousereleased(x,y,k) if k==1 then love.touchreleased(1,x,y) end end
-- function love.mousemoved(x,y,dx,dy) if isMsDown(1) then love.touchmoved(1,x,y,dx,dy) end end

---@type love.keypressed
---@param key love.KeyConstant
---@param scancode? love.Scancode
---@param isRep? boolean
function love.keypressed(key,scancode,isRep)
    -- Hide cursor when key pressed
    if not isRep then mouseShow=false end

    -- Interrupt by scene swapping
    if SCN.swapping then return end

    -- Interrupt by WAIT module
    if WAIT.state then
        if key=='escape' and WAIT.arg.escapable then WAIT.interrupt() end
        return
    end

    -- Interrupt when typing text
    if EDITING~="" then return end

    -- Interrupt by global event
    if globalEvent.keyDown(key,isRep,scancode)==true then return end

    -- Interrupt by scene event
    if SCN.keyDown and SCN.keyDown(key,isRep,scancode)==true then return end

    -- Widget interaction
    local W=WIDGET.sel
    if key=='escape' and not isRep then
        SCN.back()
    elseif key=='up' or key=='down' or key=='left' or key=='right' then
        if KBisDown('lctrl','rctrl') then
            if W and W.arrowKey then W:arrowKey(key) end
        else
            mouseShow=true
        end
    elseif W and W.keypress then
        W:keypress(key)
    elseif key=='space' or key=='return' then
        mouseShow=true
        if not isRep then
            globalEvent.clickFX(mx,my,1)
            _triggerMouseDown(mx,my,1)
            WIDGET._release(mx,my,1)
        end
    end
end
---@type love.keyreleased
---@param key love.KeyConstant
---@param scancode? love.Scancode
function love.keyreleased(key,scancode)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Skip scene event by global event
    if globalEvent.keyUp(key,scancode)~=true then
        if SCN.keyUp then SCN.keyUp(key,scancode) end
    end
end

---@type love.textinput
---@param texts string
function love.textinput(texts)
    -- Interrupt by global event
    if globalEvent.textInput(texts)==true then return end

    -- Interrupt by scene event
    if SCN.textInput and SCN.textInput(texts)==true then return end

    WIDGET._textinput(texts)
end

---@type love.textedited
---@param texts string
function love.textedited(texts)
    -- Interrupt by global event
    if globalEvent.imeChange(texts)==true then return end

    -- Interrupt by scene event
    if SCN.imeChange and SCN.imeChange(texts)==true then return end

    EDITING=texts
end

-- analog sticks: -1, 0, 1 for neg, neutral, pos
-- triggers: 0 for released, 1 for pressed
local jsAxisEventName={
    leftx={'leftstick_left','leftstick_right'},
    lefty={'leftstick_up','leftstick_down'},
    rightx={'rightstick_left','rightstick_right'},
    righty={'rightstick_up','rightstick_down'},
    triggerleft={'triggerleft'},
    triggerright={'triggerright'},
}
local gamePadKeys={'a','b','x','y','back','guide','start','leftstick','rightstick','leftshoulder','rightshoulder','dpup','dpdown','dpleft','dpright'}
local dPadToKey={
    dpup='up',
    dpdown='down',
    dpleft='left',
    dpright='right',
    start='return',
    back='escape',
}
---@type love.joystickadded
---@param JS love.Joystick
function love.joystickadded(JS)
    -- Interrupt by global event
    if globalEvent.gamepadAdd(JS)==true then return end

    table.insert(jsState,{
        _id=JS:getID(),
        _jsObj=JS,
        leftx=0,
        lefty=0,
        rightx=0,
        righty=0,
        triggerleft=0,
        triggerright=0,
    })
    MSG.new('info',"Joystick added")
end
---@type love.joystickremoved
---@param JS love.Joystick
function love.joystickremoved(JS)
    -- Interrupt by global event
    if globalEvent.gamepadRemove(JS)==true then return end

    for i=1,#jsState do
        if jsState[i]._jsObj==JS then
            for j=1,#gamePadKeys do
                if JS:isGamepadDown(gamePadKeys[j]) then
                    love.gamepadreleased(JS,gamePadKeys[j])
                end
            end
            love.gamepadaxis(JS,'leftx',0)
            love.gamepadaxis(JS,'lefty',0)
            love.gamepadaxis(JS,'rightx',0)
            love.gamepadaxis(JS,'righty',0)
            love.gamepadaxis(JS,'triggerleft',-1)
            love.gamepadaxis(JS,'triggerright',-1)
            MSG.new('info',"Joystick removed")
            table.remove(jsState,i)
            break
        end
    end
end
---@type love.gamepadaxis
---@param JS love.Joystick
---@param axis love.GamepadAxis
---@param val number
function love.gamepadaxis(JS,axis,val)
    -- Interrupt by global event
    if globalEvent.gamepadAxis(JS,axis,val)==true then return end

    local js
    for i=1,#jsState do
        if jsState[i]._jsObj==JS then
            js=jsState[i]
            break
        end
    end
    assert(js,"WTF why js not found")
    if axis=='leftx' or axis=='lefty' or axis=='rightx' or axis=='righty' then
        local newVal= -- range: [0,1]
            val>.4 and 1 or
            val<-.4 and -1 or
            0
        if newVal~=js[axis] then
            if js[axis]==-1 then
                love.gamepadreleased(JS,jsAxisEventName[axis][1])
            elseif js[axis]~=0 then
                love.gamepadreleased(JS,jsAxisEventName[axis][2])
            end
            if newVal==-1 then
                love.gamepadpressed(JS,jsAxisEventName[axis][1])
            elseif newVal==1 then
                love.gamepadpressed(JS,jsAxisEventName[axis][2])
            end
            js[axis]=newVal
        end
    elseif axis=='triggerleft' or axis=='triggerright' then
        local newVal=val>.3 and 1 or 0 -- range: [0,1]
        if newVal~=js[axis] then
            if newVal==1 then
                love.gamepadpressed(JS,jsAxisEventName[axis][1])
            else
                love.gamepadreleased(JS,jsAxisEventName[axis][1])
            end
            js[axis]=newVal
        end
    end
end
---@type love.gamepadpressed
---@param JS love.Joystick
---@param key love.GamepadButton|string
function love.gamepadpressed(JS,key)
    -- Hide cursor when gamepad pressed
    mouseShow=false

    -- Interrupt by scene swapping
    if SCN.swapping then return end

    -- Interrupt by global event
    if globalEvent.gamepadDown(JS,key)==true then return end

    local interruptCursor
    if SCN.gamepadDown then
        interruptCursor=SCN.gamepadDown(key)
    elseif SCN.keyDown then
        interruptCursor=SCN.keyDown(dPadToKey[key] or key)
    end
    if not interruptCursor then
        local keyboardKey=dPadToKey[key] or key
        mouseShow=true
        local W=WIDGET.sel
        if keyboardKey=='back' then
            SCN.back()
        elseif keyboardKey=='up' or keyboardKey=='down' or keyboardKey=='left' or keyboardKey=='right' then
            mouseShow=true
            if W and W.arrowKey then W:arrowKey(keyboardKey) end
        elseif keyboardKey=='return' then
            mouseShow=true
            globalEvent.clickFX(mx,my,1)
            _triggerMouseDown(mx,my,1)
            WIDGET._release(mx,my,1)
        else
            if W and W.keypress then
                W:keypress(keyboardKey)
            end
        end
    end
end
---@type love.gamepadreleased
---@param JS love.Joystick
---@param key love.GamepadButton|string
function love.gamepadreleased(JS,key)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Skip scene event by global event
    if globalEvent.gamepadUp(JS,key)~=true then
        if SCN.gamepadUp then
            SCN.gamepadUp(key)
        elseif SCN.keyUp then
            SCN.keyUp(dPadToKey[key] or key)
        end
    end
end

---@type love.filedropped
---@param file love.DroppedFile
function love.filedropped(file)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Skip scene event by global event
    if globalEvent.fileDrop(file)~=true then
        if SCN.fileDrop then SCN.fileDrop(file) end
    end
end
---@type love.directorydropped
---@param path string
function love.directorydropped(path)
    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Skip scene event by global event
    if globalEvent.folderDrop(path)~=true then
        if SCN.folderDrop then SCN.folderDrop(path) end
    end
end

---@type love.lowmemory
function love.lowmemory()
    collectgarbage()

    -- Skip scene event by global event
    if globalEvent.lowMemory()~=true then
        if SCN.lowMemory then SCN.lowMemory() end
    end
end

---@type love.resize
---@param w number
---@param h number
function love.resize(w,h)
    if SCR.w==w and SCR.h==h then return end
    SCR._resize(w,h)
    for k in next,bigCanvases do
        bigCanvases[k]:release()
        bigCanvases[k]=gc.newCanvas()
    end
    BG._resize(w,h)

    -- Skip scene event by global event
    if globalEvent.resize(w,h)~=true then
        if SCN.resize then SCN.resize(w,h) end
    end

    WIDGET._reset()
end

---@type love.focus
---@param f boolean
function love.focus(f)
    -- Skip scene event by global event
    if globalEvent.focus(f)~=true then
        if SCN.focus then SCN.focus(f) end
    end
end

---@type love.errorhandler
---@param msg string
---@return function #The main loop function
function love.errorhandler(msg)
    -- Call global event if exist
    if globalEvent.error then return globalEvent.error(msg) end

    if type(msg)~='string' then
        msg="Unknown error"
    elseif msg:find("Invalid UTF-8") then
        msg="[Invalid UTF-8] If you are on Windows, try downloading win32 or win64\n(different from what you are using now)."
    end

    -- Generate error message
    local err={"Error:"..msg}
    local c=2
    for l in debug.traceback("",2):gmatch("(.-)\n") do
        if c>2 then
            if not l:find("boot") then
                err[c]=l:gsub("^\t*","")
                c=c+1
            end
        else
            err[2]="Traceback"
            c=3
        end
    end
    print("\n"..table.concat(err,"\n",1,c-2))

    -- Reset something
    if love.audio and love.sound then love.audio.stop() end
    BGM.stop()
    gc.reset()
    SCR._resize(gc.getWidth(),gc.getHeight())

    local sceneStack=SCN and table.concat(SCN.stack,"/") or "NULL"
    if mainLoopStarted and #errData<maxErrorCount and SCN.scenes['error'] then
        BG.set('none')
        table.insert(errData,{msg=err,scene=sceneStack})

        -- Write messages to log file
        love.filesystem.append('error.log',
            os.date("%Y/%m/%d %A %H:%M:%S\n")..
            #errData.." crash(es) "..SYSTEM.."-"..versionText.."  scene: "..sceneStack.."\n"..
            table.concat(err,"\n",1,c-2).."\n\n"
        )

        -- Get screencapture
        GC.getScreenShot(errData[#errData],'shot')
        gc.present()

        return love.run()
    else
        love.mouse.setVisible(true)

        local errorMsg
        errorMsg=mainLoopStarted and
            "Too many errors or fatal error occured.\nPlease restart the game." or
            "An error has occurred during loading.\nError info has been created, and you can send it to the author."
        return function()
            love.event.pump()
            for E,a,b in love.event.poll() do
                if E=='quit' or a=='escape' then
                    return true
                elseif E=='resize' then
                    SCR._resize(a,b)
                end
            end
            gc.clear(.3,.5,.9)
            gc.push('transform')
            gc.replaceTransform(SCR.origin)
            local k=min(SCR.h/720,1)
            gc.scale(k)
            setFont(100,'_norm') gc_print(":(",100,0,0,1.2)
            setFont(40,'_norm') gc.printf(errorMsg,100,160,SCR.w/k-200)
            setFont(20,'_norm') gc.printf(err[1],100,330,SCR.w/k-200)
            gc.print(SYSTEM.."-"..versionText.."\nScene stack:"..sceneStack,100,640)
            gc.print("TRACEBACK",100,430)
            for i=4,#err-2 do
                gc_print(err[i],100,380+20*i)
            end
            gc.pop()
            gc.present()
            love.timer.sleep(.26)
        end
    end
end

-- Remove default callbacks
love.threaderror=nil
love.draw=nil
love.update=nil

local devColor={
    COLOR.L,
    COLOR.lM,
    COLOR.lG,
    COLOR.lB,
}

local debugInfos={
    {"Cache",gcinfo},
}
---@type love.run
---@return function #The main loop function
function love.run()
    mainLoopStarted=true

    local SCN_swapUpdate=SCN._swapUpdate
    local STEP,SLEEP=love.timer.step,love.timer.sleep
    local FPS,MINI=love.timer.getFPS,love.window.isMinimized
    local PUMP,POLL=love.event.pump,love.event.poll
    local timer=love.timer.getTime

    local frameTimeList={}
    local lastLoopTime=timer()
    local lastUpdateTime=lastLoopTime
    local lastDrawTime=lastLoopTime
    local lastScreenCheckTime=lastLoopTime

    -- counters range from 0 to 99, trigger at 100
    -- start at 100 to guarantee trigger both of them at first frame
    local updateCounter=100
    local drawCounter=100

    love.resize(gc.getWidth(),gc.getHeight())
    if #errData>0 then
        SCN.stack={'error'}
        SCN._load('error')
    else
        SCN.go(firstScene,'none')
    end

    -- Main loop
    return function()
        local time=timer()
        STEP()

        -- local loopDT=time-lastLoopTime
        lastLoopTime=time

        -- EVENT
        PUMP()
        for N,A,B,C,D,E in POLL() do
            if love[N] then
                love[N](A,B,C,D,E)
            elseif N=='quit' then
                globalEvent.quit()
                return A or true
            end
        end

        -- UPDATE
        updateCounter=updateCounter+updateFreq
        if updateCounter>=100 then
            updateCounter=updateCounter-100

            local updateDT=time-lastUpdateTime
            lastUpdateTime=time

            if mouseShow then mouse_update(updateDT) end
            if next(jsState) then gp_update(jsState[1],updateDT) end
            VOC._update()
            BG._update(updateDT)
            TEXT:update(updateDT)
            MSG._update(updateDT)
            SYSFX._update(updateDT)
            WAIT._update(updateDT)
            HTTP._update()
            TASK._update(updateDT)
            TWEEN._update(updateDT)
            if SCN.update then SCN.update(updateDT) end
            if SCN.swapping then SCN_swapUpdate(updateDT) end
            WIDGET._update(updateDT)
        end

        -- DRAW
        if not MINI() then
            drawCounter=drawCounter+drawFreq
            if drawCounter>=100 then
                drawCounter=drawCounter-100

                local drawDT=time-lastDrawTime
                lastDrawTime=time

                gc_replaceTransform(SCR.origin)
                    BG._draw()
                gc_replaceTransform(xOy)
                    if SCN.draw then
                        gc_translate(0,-SCN.curScroll)
                        SCN.draw()
                    end
                gc_replaceTransform(xOy)
                    gc_translate(0,-SCN.curScroll)
                    WIDGET._draw()
                gc_replaceTransform(xOy)
                    SYSFX._draw()
                    TEXT.draw(TEXT)
                    if mouseShow then globalEvent.drawCursor(time,mx,my) end
                gc_replaceTransform(SCR.xOy_ul)
                    globalEvent.drawSysInfo()
                gc_replaceTransform(xOy)
                    if SCN.overDraw then
                        SCN.overDraw()
                    end
                gc_replaceTransform(SCR.origin)
                    if SCN.swapping then
                        SCN.state.draw(SCN.state.timeRem)
                    end
                gc_replaceTransform(SCR.xOy_ul)
                    MSG._draw()
                gc_replaceTransform(SCR.xOy_d)
                    -- Version string
                    gc_setColor(.9,.9,.9,.42)
                    setFont(15,'_norm')
                    gc_printf(versionText,-2600,-20,5200,'center')
                gc_replaceTransform(SCR.xOy_dl)
                    local safeX=SCR.safeX/SCR.k

                    -- FPS
                    if showFPS then
                        setFont(15,'_norm')
                        gc_setColor(COLOR.L)
                        gc_print(FPS(),safeX+5,-20)
                    end

                    -- Debug info.
                    if devMode then
                        -- Debug infos at left-down
                        gc_setColor(devColor[devMode])

                        -- Text infos
                        for i=1,#debugInfos do
                            gc_print(debugInfos[i][1],safeX+5,-20-20*i)
                            gc_print(debugInfos[i][2](),safeX+62.6,-20-20*i)
                        end

                        -- Update & draw frame time
                        table.insert(frameTimeList,1,drawDT)
                        table.remove(frameTimeList,126)
                        gc_setColor(1,1,1,.26)
                        for i=1,#frameTimeList do
                            gc.rectangle('fill',150+2*i,-20,2,-frameTimeList[i]*4000)
                        end

                        -- Cursor position info
                        gc_replaceTransform(SCR.origin)
                            local x,y=xOy:transformPoint(mx,my)
                            gc.setLineWidth(1)
                            gc.line(x,0,x,SCR.h)
                            gc.line(0,y,SCR.w,y)
                            GC.strokePrint('full',1,COLOR.D,COLOR.L,floor(mx+.5)..","..floor(my+.5),x,y,'left')
                    end
                gc_replaceTransform(SCR.origin)
                    WAIT._draw()
                gc_present()

                -- Speed up a bit on mobile device, maybe
                if discardCanvas then gc.discard() end
            end
        end

        -- Check screen size
        if time-lastScreenCheckTime>1.26 and (gc.getWidth()~=SCR.w or gc.getHeight()~=SCR.h) then
            love.resize(gc.getWidth(),gc.getHeight())
            lastScreenCheckTime=time
        end

        -- Slow devmode
        if devMode then
            if devMode==3 then
                SLEEP(.1)
            elseif devMode==4 then
                SLEEP(.5)
            end
        end

        local curFrameInterval=timer()-lastLoopTime
        if curFrameInterval<sleepInterval*.9626 then SLEEP(sleepInterval*.9626-curFrameInterval) end
        while timer()-lastLoopTime<sleepInterval do end
    end
end

--------------------------------------------------------------
-- Utility functions

---Go to quit scene then terminate the application
---@param swapStyle? Zenitha.SceneSwapStyle Choose a scene swapping style
function ZENITHA._quit(swapStyle)
    -- Skip quitting by global event
    if globalEvent.requestQuit()~=true then
        SCN.swapTo('_quit',swapStyle or 'slowFade')
    end
end

---Set the application name string
---@param name string
function ZENITHA.setAppName(name)
    assert(type(name)=='string',"ZENITHA.setAppName(name): Need string")
    appName=name
end

---Get the application name
---@return string
function ZENITHA.getAppName() return appName end

---Set the application version text
---@param text string
function ZENITHA.setVersionText(text)
    assert(type(text)=='string',"ZENITHA.setVersionText(text): Need string")
    versionText=text
end

---Get the application version text
---@return string
function ZENITHA.getVersionText() return versionText end

---Get the joysticks' state table
function ZENITHA.getJsState() return jsState end

---Get the error info
---@param i number|'#' Index of error info, `'#'` for the last one
---@return Zenitha.Exception
---@overload fun():Zenitha.Exception[]
function ZENITHA.getErr(i)
    if i=='#' then
        return errData[#errData]
    elseif i then
        return errData[i]
    else
        return errData
    end
end

---Set the debug info list
---@param list {[1]:string, [2]:function}[]
function ZENITHA.setDebugInfo(list)
    assert(type(list)=='table',"ZENITHA.setDebugInfo(list): Need table")
    for i=1,#list do
        assert(type(list[i][1])=='string',"ZENITHA.setDebugInfo(list): list[i][1] need string")
        assert(type(list[i][2])=='function',"ZENITHA.setDebugInfo(list): list[i][2] need function")
    end
    debugInfos=TABLE.copy(list)
    TABLE.reverse(debugInfos)
end

---Set the first scene to load, normally this must be used, or you wlil enter the demo scene
---@param name string|any
function ZENITHA.setFirstScene(name)
    assert(type(name)=='string',"ZENITHA.setFirstScene(name): Need string")
    firstScene=name
end

---Set whether to discard canvas buffer after drawing each frame
---@param b boolean
function ZENITHA.setCleanCanvas(b)
    assert(type(b)=='boolean',"ZENITHA.setCleanCanvas(b): Need boolean")
    discardCanvas=b
end

---Set the updating rate of the application
---
---Default value is 100(%), all updating will be called every main loop cycle
---
---If set to 50(%), all *.update(dt) will be called every 2 main loop cycle
---@param rate number in [0,100]
function ZENITHA.setUpdateFreq(rate)
    assert(type(rate)=='number' and rate>0 and rate<=100,"ZENITHA.setUpdateFreq(rate): Need in (0,100]")
    updateFreq=rate
end

---Set the drawing rate of the application, same as Zenitha.setUpdateFreq(rate)
---@param rate number in [0,100]
function ZENITHA.setDrawFreq(rate)
    assert(type(rate)=='number' and rate>0 and rate<=100,"ZENITHA.setDrawFreq(rate): Need in (0,100]")
    drawFreq=rate
end

---Set whether to show FPS at left-down corner
---@param b boolean
function ZENITHA.setShowFPS(b)
    assert(type(b)=='boolean',"ZENITHA.setShowFPS(b): Need boolean")
    showFPS=b
end

---Set the max update rate of main loop cycle
---@param fps number Default to 60
function ZENITHA.setMaxFPS(fps)
    assert(type(fps)=='number' and fps>0,"ZENITHA.setMaxFPS(fps): Need >0")
    sleepInterval=1/fps
end

---Set click distance threshold
---@param dist number Default to 7.87
function ZENITHA.setClickDist(dist)
    assert(type(dist)=='number' and dist>0,"ZENITHA.setClickDist(dist): Need >0")
    clickDist2=dist^2
end

---Set the max error count, before hitting this number, errors will cause scene swapping to 'error'
---@param n number Default to 3
function ZENITHA.setMaxErrorCount(n)
    assert(type(n)=='number' and n>0,"ZENITHA.setMaxErrorCount(n): Need >0")
    maxErrorCount=n
end

---Get a big canvas which is as big as the screen
---@param id string Canvas ID
---@return love.Canvas
function ZENITHA.getBigCanvas(id)
    return bigCanvases[id]
end

---Set cursor invisible
function ZENITHA.hideCursor() mouseShow=false end

---Global event callback function table, they will be called earlier than scene event (if exist)
---
---**Return `true` as "INTERRUPT" signal**, to prevent calling scene event and other process (see each function for details)
ZENITHA.globalEvent=setmetatable(globalEvent,{
    __newindex=function()
        error("ZENITHA.globalEvent: You shall not add field to this table")
    end,
    __metatable=true,
})

--------------------------------------------------------------

SCN.add('_quit',{load=love.event.quit})
SCN.add('_console',require'scene.console')
SCN.add('_zenitha',require'scene.demo')
SCN.add('_test',require'scene.test')

-- Every little bit helps in saving resources (maybe)
collectgarbage()
