--  _____           _ _   _            --
-- / _  / ___ _ __ (_) |_| |__   __ _  --
-- \// / / _ \ '_ \| | __| '_ \ / _` | --
--  / //\  __/ | | | | |_| | | | (_| | --
-- /____/\___|_| |_|_|\__|_| |_|\__,_| --
--                                     --

-- An awesome, deluxe Pure-Lua game/app framework using Love2D

---@class Zenitha.Main
local ZENITHA={path=(...)..'/'}

-- Export to global
_G.ZENITHA=ZENITHA

--------------------------------------------------------------

-- typedef (you need Lua language server extension to make all these "---@xxx" things work) (Recommend extension: "Lua" by sumneko)

---@class char:string Single-byte string
---@class Set<V>: { [V]:any }
---@class Map<V>: { [any]:V }
---@class Mat<V>: { [integer]:{ [integer]:V } }

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

-- Useful global constants & functions

---Just `{}`, an empty table used as placeholder
---@type table
NONE=setmetatable({},{__newindex=function() error("NONE: Attempt to modify constant table") end,__metatable=true})

---Just `function() end`, an empty function used as placeholder
function NULL(...) end

---Just `function() return true end`
function TRUE() return true end

---Just `function() return false end`
function FALSE() return false end

---@type 'macOS' | 'Windows' | 'Linux' | 'Android' | 'iOS' | 'unknown'
SYSTEM=love.system and love.system.getOS():gsub('OS X','macOS') or 'unknown'
---@type boolean (NOT RELIABLE) true if the system is Android or iOS
MOBILE=SYSTEM=='Android' or SYSTEM=='iOS'
if SYSTEM=='Web' then
    ---@type boolean? only exist when SYSTEM=='Web'
    WEB_COMPAT_MODE=false
    if love.thread then
        WEB_COMPAT_MODE=not love.thread.newThread('\n'):start()
    else
        print('Cannot check web compatible mode')
    end
    print('WEB_COMPAT_MODE = '..tostring(WEB_COMPAT_MODE))
end
---@type string Editting text, used by inputBox widget
EDITING=""

ZENITHA.mouse=love.mouse or {
    isDown=FALSE,
    setVisible=NULL,
    getPosition=function() return 0,0 end,
    getRelativeMode=FALSE,
    isGrabbed=FALSE,
    isVisible=FALSE,
}
ZENITHA.keyboard=love.keyboard or {
    isDown=FALSE,
    setKeyRepeat=NULL,
    setTextInput=NULL,
    hasTextInput=FALSE,
}
ZENITHA.graphics=love.graphics or setmetatable({
    getWidth=function() return 0 end,
    getHeight=function() return 0 end,
    getDimensions=function() return 0,0 end,
    getDPIScale=function() return 1 end,
},{__index=function() return NULL end})
ZENITHA.timer=love.timer or setmetatable({
    step=NULL,
    sleep=NULL,
    getFPS=function() return MATH.inf end,
    getTime=os.clock(),
},{__index=function() return NULL end})

-- Bit module fallback
if not bit then
    local suc
    suc,bit=pcall(require,'bit')
    if not suc then bit=require'Zenitha.bit'.bit end
end

---@type love.Canvas Empty canvas used as placeholder
PAPER=ZENITHA.graphics.newCanvas(1,1)

-- #define
local MSisDown,KBisDown=ZENITHA.mouse.isDown,ZENITHA.keyboard.isDown

local gc=ZENITHA.graphics
local gc_replaceTransform,gc_translate,gc_present=gc.replaceTransform,gc.translate,gc.present

local max,min=math.max,math.min
local floor,abs=math.floor,math.abs
math.randomseed(os.time()*2600)
ZENITHA.keyboard.setKeyRepeat(true)

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

---Use `local require=simpRequire(...)` to require modules in simpler way
---
---### Example
---```
---local require=simpRequire('path.to.scripts.')
---mod1=require('mod1') -- Same to require('path.to.scripts.mod1')
---mod2=require('mod2')
---mod3=require('mod3')
---```
---@param path string | fun(path:any):unknown
---@diagnostic disable-next-line
function simpRequire(path)
    return type(path)=='function' and
        function(module) return path(module) end or
        function(module) return require(path..module) end
end

--------------------------------------------------------------

-- Inside values
local mainLoopStarted=false
local devMode=false ---@type false | 1 | 2 | 3 | 4
local devClick={0,0} ---@type number[]
local mx,my -- cursor X/Y, using local variables for better performance
local cursor={
    vis='auto', ---@type 'auto' | 'always' | 'never'
    active=false,
    speed=260, -- Moving speed
}
local lastClicks={} ---@type Zenitha.Click[]
local jsState={} ---@type Zenitha.JoystickState[]
local errData={} ---@type Zenitha.Exception[]
---@type Map<love.Canvas>
ZENITHA.bigCanvas=setmetatable({},{
    __index=function(self,k)
        ---@diagnostic disable-next-line
        self[k]=gc.newCanvas(GC.getWidth(),GC.getHeight(),love.window and {msaa=select(3,love.window.getMode()).msaa} or nil)
        return self[k]
    end,
})

-- User-changeable values
local appName='Zenitha'
local appVer ---@type string?
local firstScene='_zenitha'
local discardCanvas=false
local updateFreq=100
local drawFreq=100
local mainLoopInterval=1/60
local sleepDurationError=0
local clickDist2=62
local maxErrorCount=3

local frameTimeList={}
local lastDrawTime=0
---@type (fun():string)[]
local debugInfo={
    function () return "DEV@"..ZENITHA.getDevMode() end,
    function () local fps=ZENITHA.timer.getFPS() return "FPS = "..fps.." ("..updateFreq.."% "..drawFreq.."%)" end,
    function () return "Cache = "..gcinfo() end,
    function () return "Audios = "..love.audio.getActiveSourceCount() end,
    function () return "Cursor "..floor(mx)..", "..floor(my) end,
}

---@class Zenitha.GlobalEvent
---@field mouseDown     fun(mx:number, my:number, k?:number, presses?:number): boolean? Able to interrupt scene event and widget interaction
---@field mouseMove     fun(mx:number, my:number, dx?:number, dy?:number): boolean? Able to interrupt scene event and widget interaction
---@field mouseUp       fun(mx:number, my:number, k?:number, presses?:number): boolean? Able to interrupt scene event
---@field mouseClick    fun(mx:number, my:number, k?:number, dist?:number, presses?:number): boolean? Able to interrupt scene event
---@field wheelMove     fun(dx:number, dy:number): boolean? Able to interrupt scene event and widget interaction
---@field touchDown     fun(x:number, y:number, id?:lightuserdata, pressure?:number): boolean? Able to interrupt scene event
---@field touchUp       fun(x:number, y:number, id?:lightuserdata, pressure?:number): boolean? Able to interrupt scene event
---@field touchMove     fun(x:number, y:number, id?:lightuserdata, pressure?:number): boolean? Able to interrupt scene event
---@field touchClick    fun(x:number, y:number, id?:lightuserdata, dist?:number): boolean? Able to interrupt scene event
---@field keyDown       fun(key:string, isRep?:boolean, scancode?:string): boolean? Able to interrupt scene event and widget interaction. Default to a debugging tool, switch on/off with F8, then use it with F1-F12
---@field keyUp         fun(key:string, scancode?:string): boolean? Able to interrupt scene event
---@field textInput     fun(texts:string): boolean? Able to interrupt scene event and widget interaction
---@field imeChange     fun(texts:string): boolean? Able to interrupt scene event and var `EDIT` updating
---@field gamepadAdd    fun(JS:love.Joystick): boolean? Able to interrupt gamepad managing
---@field gamepadRemove fun(JS:love.Joystick): boolean? Able to interrupt gamepad managing
---@field gamepadAxis   fun(JS:love.Joystick, axis:love.GamepadAxis, val?:number): boolean? Able to interrupt gamepad managing
---@field gamepadDown   fun(JS:love.Joystick, key:love.GamepadButton | string): boolean? Able to interrupt scene event and widget interaction
---@field gamepadUp     fun(JS:love.Joystick, key:love.GamepadButton | string): boolean? Able to interrupt scene event
---@field fileDrop      fun(file:love.DroppedFile): boolean? Able to interrupt scene event
---@field folderDrop    fun(path:string): boolean? Able to interrupt scene event
---@field lowMemory     fun(): boolean? Able to interrupt scene event
---@field resize        fun(w:number, h:number): boolean? Able to interrupt scene event
---@field focus         fun(f:boolean): boolean? Able to interrupt scene event
---
---@field drawExtra     fun() A global drawing function (above cursor, below scene swapping, default to SCR.xOy)
---@field drawCursor    fun(x:number, y:number, time:number) Cursor drawing function
---@field drawDebugInfo fun() A global drawing function (above everything, no default position, contains many info so it's not recommended to change it)
---@field clickFX       fun(x:number, y:number, k:number) Called when "Click Event" triggered
---
---@field sceneSwap     fun(state:'start' | 'swap' | 'finish', style?:string) Called when scene swapping start
---@field requestQuit   fun(): boolean? Called when request quiting with ZENITHA._quit()
---@field quit          fun() Called when exactly before quiting
---@field error         false | fun(msg:string): any When exist, called when love.errorhandler is called. Normally you should handle error with scene named 'error'.
local globalEvent={
    mouseDown=function(x,y,k)
        if devMode then
            print(("%d@(%d,%d) Diff<%d,%d>\tapprox(%d,%d)<%d,%d>"):format(
                k,x,y,
                x-devClick[1],y-devClick[2],
                floor(x/10)*10,floor(y/10)*10,
                floor((x-devClick[1])/10)*10,floor((y-devClick[2])/10)*10
            ))
            devClick[1],devClick[2]=x,y
        end
    end,
    mouseMove=NULL,
    mouseUp=NULL,
    mouseClick=NULL,
    wheelMove=NULL,

    touchDown=NULL,
    touchUp=NULL,
    touchMove=NULL,
    touchClick=NULL,

    keyDown=function(key,isRep)
        if isRep then return end
        if devMode then
            if     key=='f1'  then -- Show system info
                local info=("System:%s[%s]\nLuaVer:%s\nJitVer:%s\nJitVerNum:%s"):format(SYSTEM,jit.arch,_VERSION,jit.version,jit.version_num)
                MSG.log('info',info); return true
            elseif key=='f2'  then -- Quick profiling
                local info=PROFILE.switch() and "Profile start!" or "Profile report copied!"
                MSG.log('info',info); return true
            elseif key=='f3'  then -- Show screen info
                local info=table.concat(SCR.info(),"\n")
                MSG.log('info',info); return true
            elseif key=='f4'  then -- Show everything in _G
                for k,v in next,_G do print(k,v) end
                MSG('info',"_G listed in console")
            elseif key=='f5'  then -- Show selected widget info
                local info=WIDGET.sel and WIDGET.sel:getInfo() or "No widget selected"
                MSG.log('info',info); return true
            elseif key=='f6'  then -- Show scene stack
                local info="Scene stack:"..table.concat(SCN.stack,"->")
                MSG.log('info',info); return true
            elseif key=='f7'  then -- Open console
                if UTIL.openConsole() then
                    MSG('info',"Console opened")
                else
                    MSG('warn',"Failed to open Console")
                end
            elseif key=='f8'  then ZENITHA.setDevMode(false) return true
            elseif key=='f9'  then ZENITHA.setDevMode(1)     return true
            elseif key=='f10' then ZENITHA.setDevMode(2)     return true
            elseif key=='f11' then ZENITHA.setDevMode(3)     return true
            elseif key=='f12' then ZENITHA.setDevMode(4)     return true
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
            MSG('info',"DEBUG 1 (Basic)",.2)
            return true
        end
    end,
    keyUp=NULL,
    textInput=NULL,
    imeChange=NULL,

    gamepadAdd=NULL,
    gamepadRemove=NULL,
    gamepadAxis=NULL,
    gamepadDown=NULL,
    gamepadUp=NULL,

    fileDrop=NULL,
    folderDrop=NULL,
    lowMemory=NULL,
    resize=NULL,
    focus=NULL,

    drawExtra=NULL,
    drawCursor=function(x,y)
        gc.setColor(1,1,1)
        gc.setLineWidth(2)
        gc.circle(MSisDown(1) and 'fill' or 'line',x,y,6)
    end,
    drawDebugInfo=function()
        if appVer then
            gc_replaceTransform(SCR.xOy_d)
            gc.setColor(.9,.9,.9,.42)
            FONT.set(15,'_norm')
            gc.printf(appVer,-2600,-20,5200,'center')
        end

        if devMode then
            gc_replaceTransform(SCR.xOy_dl)
            local safeX=SCR.safeX/SCR.k

            -- Frame time graph
            local t=ZENITHA.timer.getTime()
            table.insert(frameTimeList,1,t-lastDrawTime)
            lastDrawTime=t
            table.remove(frameTimeList,260)
            gc.setColor(.62,.62,.62,.62)
            for i=1,#frameTimeList do
                gc.rectangle('fill',2*i,-2,2,-frameTimeList[i]*4000)
            end

            -- Texts
            FONT.set(15,'_norm')
            for i=1,#debugInfo do
                local str=debugInfo[i]()
                gc.setColor(COLOR.D); gc.print(str,safeX+6,-20*i+1)
                gc.setColor(COLOR.L); gc.print(str,safeX+5,-20*i)
            end

            -- Cursor
            gc_replaceTransform(SCR.origin)
            local x,y=SCR.xOy:transformPoint(mx,my)
            gc.setLineWidth(6)
            gc.setColor(0,0,0,.26)
            gc.line(x,0,x,SCR.h)
            gc.line(0,y,SCR.w,y)
            gc.setLineWidth(2)
            gc.setColor(1,1,1,.62)
            gc.line(x,0,x,SCR.h)
            gc.line(0,y,SCR.w,y)
            local xMode=mx/SCR.w0<.33 and 'left' or mx/SCR.w0>.67 and 'right' or 'center'
            GC.strokePrint('full',1,COLOR.D,COLOR.L,floor(mx+.5)..","..floor(my+.5),x,y-26,nil,xMode)
        end
    end,
    clickFX=function(x,y,_) SYSFX.tap(.26,x,y) end,

    sceneSwap=NULL,
    requestQuit=NULL,
    quit=NULL,
    error=false,
}

--------------------------------------------------------------

local require=simpRequire((...)..'.')

-- Pure lua modules (simple)
COLOR=      require'color'
AE=         require'escape'
LOG=        require'log'
RGB9={}     --[[Get color literal with `RGB9[960]`(Red)   ]] for r=0,9 do for g=0,9 do for b=0,9 do RGB9[100*r+10*g+b]={r/9,g/9,b/9} end end end
RGBA9={}    --[[Get color literal with `RGBA9[9609]`(Red) ]] for r=0,9 do for g=0,9 do for b=0,9 do for a=0,9 do RGBA9[1000*r+100*g+10*b+a]={r/9,g/9,b/9,a/9} end end end end
RGB5={}     --[[Get color literal with `RGB5[520]`(Red)   ]] for r=0,5 do for g=0,5 do for b=0,5 do RGB5[100*r+10*g+b]={r/5,g/5,b/5} end end end
RGBA5={}    --[[Get color literal with `RGBA5[5205]`(Red) ]] for r=0,5 do for g=0,5 do for b=0,5 do for a=0,5 do RGBA5[1000*r+100*g+10*b+a]={r/5,g/5,b/5,a/5} end end end end
RGB2={}     --[[Get color literal with `RGB2[210]`(Red)   ]] for r=0,2 do for g=0,2 do for b=0,2 do RGB2[100*r+10*g+b]={r/2,g/2,b/2} end end end
UTIL=       require'util'
JSON=       require'json'

-- Extended lua basic libraries
MATH=       require'mathExtend'
STRING=     require'stringExtend'
TABLE=      require'tableExtend'

-- Pure lua modules (complex, with update/draw)
LANG=       require'languages'
LOADLIB=    require'loadlib'
PROFILE=    require'profile'
TASK=       require'task'
HASH=       require'sha2'

-- Love-based modules (simple)
if SYSTEM=='Web' then JS=require'js' end
CLIPBOARD=  require'clipboard'
VIB=        require'vibrate'
WHEELMOV=   require'wheelToArrow'
FONT=       require'fontExtend'
IMG=        require'imageLoader'
FILE=       require'fileExtend'
SCR=        require'screen'
GC=         require'graphicExtend'
TCP=        require'tcp'
MIDI=       require'midi'

-- Love-based modules (complex, with update/draw)
ASYNC=      require'async'
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
local TP=xOy.transformPoint
local ITP=xOy.inverseTransformPoint

-- Set default font
FONT.load({
    _norm=(...)..'/norm.ttf',
    _mono=(...)..'/mono.ttf',
})
FONT.setDefaultFont('_norm')

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
    -- Interrupt by scene swapping
    if SCN.swapping then return end

    -- Skip all others by global event
    if globalEvent.mouseDown(x,y,k,presses)~=true then
        WIDGET._cursorMove(x,y,'press')
        if WIDGET.sel then
            WIDGET._press(x,y,k)
        else
            if SCN.mouseDown then SCN.mouseDown(x,y,k,presses) end
        end
    end
    globalEvent.clickFX(x,y,k)
end
---@param js Zenitha.JoystickState
local function _gpCursorUpdate(js,dt)
    local sx,sy=js._jsObj:getGamepadAxis('leftx'),js._jsObj:getGamepadAxis('lefty')
    if abs(sx)>.1 or abs(sy)>.1 then
        local dx,dy=0,0
        if abs(sy)>.1 then dy=dy+dt*sy*cursor.speed end
        if abs(sx)>.1 then dx=dx+dt*sx*cursor.speed end
        if dx==0 and dy==0 then return end

        mx=max(min(mx+dx,SCR.w0),0)
        my=max(min(my+dy,SCR.h0),0)
        if my==0 or my==SCR.h0 then
            WIDGET.sel=false
            WIDGET._drag(0,0,0,-dy)
        end
        _updateMousePos(mx,my,dx,dy)
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
    cursor.active=true
    mx,my=ITP(xOy,x,y)

    lastClicks[k]={x=x,y=y}
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
    cursor.active=true

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
            if SCN.mouseClick then SCN.mouseClick(mx,my,k,dist,presses) end
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
    cursor.active=false

    -- Interrupt by scene swapping & WAIT module
    if SCN.swapping or WAIT.state then return end

    -- Update mainTouchID
    if not SCN.mainTouchID then
        SCN.mainTouchID=id
        WIDGET.unFocus(true)
    end

    -- Transform to designing coord
    x,y=ITP(xOy,x,y)

    lastClicks[id]={x=x,y=y}
    if WIDGET.sel and WIDGET.sel.type=='inputBox' and not WIDGET.sel:isAbove(x,y) then
        WIDGET.unFocus(true)
        ZENITHA.keyboard.setTextInput(false)
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
    if not isRep then cursor.active=false end

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
    elseif W and W.keypress then
        W:keypress(key)
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
    MSG.log('info',"Joystick added")
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
            MSG.log('info',"Joystick removed")
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
---@param key love.GamepadButton | string
function love.gamepadpressed(JS,key)
    -- Hide cursor when gamepad pressed
    cursor.active=false

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
        cursor.active=true
        local W=WIDGET.sel
        if keyboardKey=='back' then
            SCN.back()
        elseif keyboardKey=='up' or keyboardKey=='down' or keyboardKey=='left' or keyboardKey=='right' then
            cursor.active=true
            if W and W.arrowKey then W:arrowKey(keyboardKey) end
        elseif keyboardKey=='return' then
            cursor.active=true
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
---@param key love.GamepadButton | string
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

local bigCanvases=ZENITHA.bigCanvas
---@type love.resize
---@param w number
---@param h number
function love.resize(w,h)
    if SCR.w==w and SCR.h==h then return end
    SCR._resize(w,h)
    for k in next,bigCanvases do
        bigCanvases[k]:release()
        ---@diagnostic disable-next-line
        bigCanvases[k]=gc.newCanvas(w,h,love.window and {msaa=select(3,love.window.getMode()).msaa} or nil)
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
        if love.filesystem then
            love.filesystem.append('error.log',
                os.date("%Y/%m/%d %A %H:%M:%S\n")..
                #errData.." crash(es) "..SYSTEM.."-"..(appVer or "noVer").."  scene: "..sceneStack.."\n"..
                table.concat(err,"\n",1,c-2).."\n\n"
            )
        end

        -- Get screencapture
        GC.getScreenShot(errData[#errData],'shot')
        gc.present()

        return love.run()
    else
        ZENITHA.mouse.setVisible(true)

        local errorMsg
        errorMsg=mainLoopStarted and
            "Too many errors or fatal error occured.\nPlease restart the game." or
            "An error has occurred during loading.\nError info has been created, and you can send it to the author."
        return function()
            if love.event then
                love.event.pump()
                for E,a,b in love.event.poll() do
                    if E=='quit' or a=='escape' then
                        return true
                    elseif E=='resize' then
                        SCR._resize(a,b)
                    end
                end
            end
            gc.clear(.3,.5,.9)
            gc.push('transform')
            gc.replaceTransform(SCR.origin)
            local k=min(SCR.h/720,1)
            gc.scale(k)
            FONT.set(100,'_norm') gc.print(":(",100,0,0,1.2)
            FONT.set(40,'_norm') gc.printf(errorMsg,100,160,SCR.w/k-200)
            FONT.set(20,'_norm') gc.printf(err[1],100,330,SCR.w/k-200)
            gc.print(SYSTEM.."-"..(appVer or "noVer").."\nScene stack:"..sceneStack,100,640)
            gc.print("TRACEBACK",100,430)
            for i=4,#err-2 do
                gc.print(err[i],100,380+20*i)
            end
            gc.pop()
            gc.present()
            ZENITHA.timer.sleep(.26)
        end
    end
end

-- Remove default callbacks
love.threaderror=nil
love.draw=nil
love.update=nil

---@type love.run
---@return function #The main loop function
function love.run()
    mainLoopStarted=true

    local SCN_swapUpdate=SCN._swapUpdate
    local STEP,SLEEP=ZENITHA.timer.step,ZENITHA.timer.sleep
    local MINI=love.window and love.window.isMinimized or FALSE
    local PUMP,POLL=love.event and love.event.pump or NULL,love.event.poll
    local timer=ZENITHA.timer.getTime

    local lastUpdateTime=timer()
    local lastScreenCheckTime=lastUpdateTime

    -- counters range from 0 to 99, trigger at 100
    -- start at 100 to guarantee trigger both of them at first frame
    local updateCounter=100
    local drawCounter=100

    love.resize(gc.getWidth(),gc.getHeight())
    if errData[1] then
        SCN.stack={'error'}
        SCN._load('error')
    else
        SCN.go(firstScene,'none')
    end

    -- Main loop
    return function()
        -- Loop start time
        local loopT=timer()
        STEP()

        -- EVENT
        if PUMP then
            PUMP()
            for N,A,B,C,D,E in POLL() do
                if love[N] then
                    love[N](A,B,C,D,E)
                elseif N=='quit' then
                    globalEvent.quit()
                    return A or true
                end
            end
        end

        -- UPDATE
        updateCounter=updateCounter+updateFreq
        if updateCounter>=100 then
            updateCounter=updateCounter-100

            local updateDT=loopT-lastUpdateTime
            lastUpdateTime=loopT

            if SYSTEM == 'Web' then
                JS.retrieveData(updateDT)
                CLIPBOARD._update(updateDT)
            end

            if next(jsState) then _gpCursorUpdate(jsState[1],updateDT) end
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
                    TEXT:draw()
                    if SCN.overDraw then SCN.overDraw() end
                gc_replaceTransform(xOy)
                    globalEvent.drawExtra()
                gc_replaceTransform(xOy)
                    if cursor.vis=='always' or cursor.vis=='auto' and cursor.active then globalEvent.drawCursor(mx,my,loopT) end
                gc_replaceTransform(SCR.origin)
                    if SCN.swapping then SCN.swapState.draw(SCN.swapState.time) end
                gc_replaceTransform(SCR.xOy_ul)
                    MSG._draw()
                gc_replaceTransform(SCR.origin)
                    WAIT._draw()
                    globalEvent.drawDebugInfo()
                gc_present()

                -- Speed up a bit on mobile device, maybe
                if discardCanvas then gc.discard() end
            end
        end

        -- Check screen size
        if loopT-lastScreenCheckTime>1 and (gc.getWidth()~=SCR.w or gc.getHeight()~=SCR.h) then
            love.resize(gc.getWidth(),gc.getHeight())
            lastScreenCheckTime=loopT
        end

        -- Slow devmode
        if devMode and devMode>=3 then
            SLEEP(devMode==3 and .1 or .5)
        end

        local timeRemain=loopT+mainLoopInterval-timer()
        if timeRemain>sleepDurationError then SLEEP(timeRemain-sleepDurationError) end
        while timer()-loopT<mainLoopInterval do end
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
---@param ver? string
function ZENITHA.setAppInfo(name,ver)
    assert(type(name)=='string',"ZENITHA.setAppInfo: need string")
    assert(ver==nil or type(ver)=='string',"ZENITHA.setAppInfo: version need string or nil")
    appName,appVer=name,ver
end

---Get the application name
---@return string, string?
function ZENITHA.getAppInfo() return appName,appVer end

---Get the joysticks' state table
function ZENITHA.getJsState() return jsState end

---Get the error info
---@param i number | '#' Index of error info, `'#'` for the last one
---@return Zenitha.Exception
---@overload fun(): Zenitha.Exception[]
function ZENITHA.getErr(i)
    if i=='#' then
        return errData[#errData]
    elseif i then
        return errData[i]
    else
        return errData
    end
end

---Set the first scene to load, normally this must be used, or you wlil enter the demo scene
---@param name string | any
function ZENITHA.setFirstScene(name)
    assert(type(name)=='string',"ZENITHA.setFirstScene(name): Need string")
    firstScene=name
end

---Set whether to discard canvas buffer after drawing each frame
---@param bool boolean
function ZENITHA.setCleanCanvas(bool)
    assert(type(bool)=='boolean',"ZENITHA.setCleanCanvas(b): Need boolean")
    discardCanvas=bool
end

---Set the max update rate of main loop cycle
---@param lps number Loop/sec, default to 60
function ZENITHA.setMainLoopSpeed(lps)
    assert(type(lps)=='number' and lps>0,"ZENITHA.setMainLoopSpeed(lps): Need >0")
    mainLoopInterval=1/lps
end

---Set the sleep duration error to balance accuracy & performance of main-loop-frequency
---
---Recommend value:
---| Mode \| | Value |
---| -: | :-: |
---| Accuracy \| | 🪟1.0, 🐧0.5 |
---| Default \| | 0 |
---| Economy \| | -0.5 |
---| Power-Saving \| | -1.0 |
---
---How this works: Because `love.timer.sleep(t)` is not accurate enough (always a bit more time), so we can sleep `[setting value] LESS`, then busy-wait to obtain the exact time interval.
---
---But `sleep()` actually only accept integer microsecond value, so when we need to sleep 1.5ms, doing `sleep(1.5ms)` is same as `sleep(1ms)`, so busy-wait will still work for ~0.5ms.
---That's why we accept negative number. Setting error to -1ms means we will do `sleep(2.5ms)` when we need 1.5, so busy-wait is guaranteed not to be triggered, saving more resource.
---@param ms number in [-1,1], default to 0 (ms)
function ZENITHA.setSleepDurationError(ms)
    assert(type(ms)=='number' and ms>=-1 and ms<=1,"ZENITHA.setSleepFault(ms): Need in [-1,1]")
    sleepDurationError=ms/1000
end

---Set the updating rate of the application
---
---Default value is 100(%), all updating will be called every main loop cycle
---If set to 50(%), all *.update(dt) will be called every 2 main loop cycle
---@param rate number in [0,100]
function ZENITHA.setUpdateRate(rate)
    assert(type(rate)=='number' and rate>0 and rate<=100,"ZENITHA.setUpdateRate(rate): Need in (0,100]")
    updateFreq=rate
end

---Set the drawing rate of the application, same as Zenitha.setUpdateRate(rate)
---@param rate number in [0,100]
function ZENITHA.setRenderRate(rate)
    assert(type(rate)=='number' and rate>0 and rate<=100,"ZENITHA.setRenderRate(rate): Need in (0,100]")
    drawFreq=rate
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

---Set cursor's visibility (default to 'auto')
---@param mode 'auto' | 'always' | 'never'
function ZENITHA.setCursorVisible(mode)
    if mode=='always' then
        cursor.active=true
    elseif mode=='never' then
        cursor.active=false
    elseif mode~='auto' then
        error("ZENITHA.setCursorVisible(mode): mode must be 'always', 'never' or 'auto'")
    end
    cursor.vis=mode
end

---Set cursor's position (will trigger mousemoved event)
---
---Note: you can get/set cursor's speed through ZENITHA._cursor.speed
---@param x number
---@param y number
---@param dx? number
---@param dy? number
function ZENITHA.setCursorPos(x,y,dx,dy)
    x,y=TP(xOy,x,y)
    x=MATH.clamp(x,0,SCR.w)
    y=MATH.clamp(y,0,SCR.h)
    love.mousemoved(x,y,dx or 0,dy or 0)
end

function ZENITHA.getDevMode()
    return devMode
end
function ZENITHA.setDevMode(m)
    if m==false then
        devMode=false
        MSG('info',"DEBUG OFF",1)
    else
        devClick[1],devClick[2]=0,0
        if m==1 then
            devMode=1
            MSG('info',"DEBUG 1 (Basic)",1)
        elseif m==2 then
            devMode=2
            MSG('info',"DEBUG 2 (Widget)",1)
        elseif m==3 then
            devMode=3
            MSG('info',"DEBUG 3 (Slow)",1)
        elseif m==4 then
            devMode=4
            MSG('info',"DEBUG 4 (Sloooow)",1)
        end
    end
end
---Global event callback function table, they will be called earlier than scene event (if exist)
---
---**Return `true` as "INTERRUPT" signal**, to prevent calling scene event and other process (see each function for details)
ZENITHA.globalEvent=setmetatable(globalEvent,{
    __newindex=function()
        error("ZENITHA.globalEvent: You shall not add new field")
    end,
    __metatable=true,
})

ZENITHA._debugInfo=debugInfo
ZENITHA._cursor=cursor

--------------------------------------------------------------

SCN.add('_quit',{load=love.event and love.event.quit or NULL})
SCN.add('_console',require'scene.console')
SCN.add('_zenitha',require'scene.demo')
SCN.add('_test',require'scene.test')

-- Every little bit helps in saving resources (maybe)
collectgarbage()

-- In case someone need it
return ZENITHA
