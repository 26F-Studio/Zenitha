-- #  _____           _ _   _            #
-- # / _  / ___ _ __ (_) |_| |__   __ _  #
-- # \// / / _ \ '_ \| | __| '_ \ / _` | #
-- #  / //\  __/ | | | | |_| | | | (_| | #
-- # /____/\___|_| |_|_|\__|_| |_|\__,_| #
-- #                                     #
-- An awesome pure-lua framework using Love2D

-- #define (lol)
local ms,kb=love.mouse,love.keyboard
local KBisDown=kb.isDown

local gc=love.graphics
local gc_replaceTransform,gc_translate,gc_present=gc.replaceTransform,gc.translate,gc.present
local gc_setColor,gc_circle=gc.setColor,gc.circle
local gc_print,gc_printf=gc.print,gc.printf

local max,min=math.max,math.min
math.randomseed(os.time()*2600)
kb.setKeyRepeat(true)

--------------------------------------------------------------

-- Useful global values/variables
NONE=setmetatable({},{__newindex=function() error("Attempt to modify a constant table") end,__metatable=true})
NULL=function(...) end
PAPER=love.graphics.newCanvas(1,1)

SYSTEM=love.system.getOS() if SYSTEM=='OS X' then SYSTEM='macOS' end
MOBILE=SYSTEM=='Android' or SYSTEM=='iOS'
EDITING=""

-- Inside values
local mainLoopStarted=false
local autoGCcount=0
local devMode
local mx,my,mouseShow,cursorSpd=640,360,false,0
local lastX,lastY=0,0-- Last click pos
local jsState={}-- map, joystickID->axisStates: {axisName->axisVal}
local errData={}-- list, each error create {msg={errMsg strings},scene=sceneNameStr}
local bigCanvases=setmetatable({},{__index=function(self,k)
    self[k]=gc.newCanvas()
    return self[k]
end})

-- User-changeable values
local appName='Zenitha'
local versionText='V0.1'
local firstScene=false
local clickFX=function(x,y) SYSFX.new('tap',3,x,y) end
local discardCanvas=false
local updateFreq=100
local drawFreq=100
local sleepInterval=1/60
local function drawCursor(_,x,y)
    gc_setColor(1,1,1)
    gc.setLineWidth(2)
    gc_circle(ms.isDown(1) and 'fill' or 'line',x,y,6)
end
local globalKey={
    f8=function()
        devMode=1
        MSG.new('info',"DEBUG ON",.2)
    end
}
local devFnKey={NULL,NULL,NULL,NULL,NULL,NULL,NULL}
local onResize=NULL
local onFocus=NULL
local onQuit=NULL
local drawSysInfo=NULL

--------------------------------------------------------------

-- Extended lua basic libraries
MATH=       require'Zenitha.mathExtend'
STRING=     require'Zenitha.stringExtend'
TABLE=      require'Zenitha.tableExtend'

-- Pure lua modules (simple)
COLOR=      require'Zenitha.color'
DEBUG=      require'Zenitha.debug'
LOG=        require'Zenitha.log'
JSON=       require'Zenitha.json'
do-- Add pcall & MSG for JSON lib
    local encode,decode=JSON.encode,JSON.decode
    function JSON.encode(val)
        local a,b=pcall(encode,val)
        if a then
            return b
        elseif MSG then
            MSG.traceback()
        end
    end
    function JSON.decode(str)
        local a,b=pcall(decode,str)
        if a then
            return b
        elseif MSG then
            MSG.traceback()
        end
    end
end

-- Pure lua modules (complex)
LANG=       require'Zenitha.languages'
REQUIRE=    require'Zenitha.require'
PROFILE=    require'Zenitha.profile'
TASK=       require'Zenitha.task'
HASH=       require'Zenitha.sha2'
do-- Add pbkdf2 for HASH lib
    local bxor=require'bit'.bxor
    local char=string.char
    local function sxor(s1, s2)
        local b3=''
        for i=1,#s1 do
            b3=b3..char(bxor(s1:byte(i),s2:byte(i)))
        end
        return b3
    end
    function HASH.pbkdf2(hashFunc, pw, salt, n)
        local u=HASH.hex2bin(HASH.hmac(hashFunc, pw, salt..'\0\0\0\1'))
        local t=u

        for _=2,n do
            u=HASH.hex2bin(HASH.hmac(hashFunc, pw, u))
            t=sxor(t, u)
        end

        return HASH.bin2hex(t):upper()
    end
end

-- Love-based modules (simple)
VIB=        require'Zenitha.vibrate'
WHEELMOV=   require'Zenitha.wheelToArrow'
FONT=       require'Zenitha.font'
IMG=        require'Zenitha.image'
FILE=       require'Zenitha.file'
SCR=        require'Zenitha.screen'
GC=         require'Zenitha.gcExtend'

-- Love-based modules (complex)
HTTP=       require'Zenitha.http'
SCN=        require'Zenitha.scene'
TEXT=       require'Zenitha.text'
SYSFX=      require'Zenitha.sysFX'
WAIT=       require'Zenitha.wait'
MSG=        require'Zenitha.message'
BG=         require'Zenitha.background'
WIDGET=     require'Zenitha.widget'
SFX=        require'Zenitha.sfx'
BGM=        require'Zenitha.bgm'
VOC=        require'Zenitha.voice'

--------------------------------------------------------------

local WIDGET,SCR,SCN,BG,WAIT=WIDGET,SCR,SCN,BG,WAIT
local xOy=SCR.xOy
local ITP=xOy.inverseTransformPoint
local setFont=FONT.set

-- Set default font
FONT.load({
    _norm='Zenitha/norm.ttf',
    _mono='Zenitha/mono.ttf',
})
FONT.setDefaultFont('_norm')
FONT.setDefaultFallback('_norm')

--------------------------------------------------------------

local function _updateMousePos(x,y,dx,dy)
    if SCN.swapping or WAIT.state then return end
    dx,dy=dx/SCR.k,dy/SCR.k
    if SCN.mouseMove then SCN.mouseMove(x,y,dx,dy) end
    if ms.isDown(1) then
        WIDGET._drag(x,y,dx,dy)
    else
        WIDGET._cursorMove(x,y)
    end
end
local function _triggerMouseDown(x,y,k)
    if devMode==1 then
        print(("(%d,%d)<-%d,%d ~~(%d,%d)<-%d,%d"):format(
            x,y,
            x-lastX,y-lastY,
            math.floor(x/10)*10,math.floor(y/10)*10,
            math.floor((x-lastX)/10)*10,math.floor((y-lastY)/10)*10
        ))
    end
    if SCN.swapping then return end
    if WIDGET.sel then
        WIDGET._press(x,y,k)
    else
        if SCN.mouseDown then SCN.mouseDown(x,y,k) end
        lastX,lastY=x,y
    end
    clickFX(x,y)
end
local function mouse_update(dt)
    if not KBisDown('lctrl','rctrl') and KBisDown('up','down','left','right') then
        local dx,dy=0,0
        if KBisDown('up') then    dy=dy-cursorSpd end
        if KBisDown('down') then  dy=dy+cursorSpd end
        if KBisDown('left') then  dx=dx-cursorSpd end
        if KBisDown('right') then dx=dx+cursorSpd end
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
local function gp_update(js,dt)
    local sx,sy=js._jsObj:getGamepadAxis('leftx'),js._jsObj:getGamepadAxis('lefty')
    if math.abs(sx)>.1 or math.abs(sy)>.1 then
        local dx,dy=0,0
        if sy<-.1 then dy=dy+2*sy*cursorSpd end
        if sy>.1 then  dy=dy+2*sy*cursorSpd end
        if sx<-.1 then dx=dx+2*sx*cursorSpd end
        if sx>.1 then  dx=dx+2*sx*cursorSpd end
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
function love.mousepressed(x,y,k,touch)
    if touch or WAIT.state then return end
    mouseShow=true
    mx,my=ITP(xOy,x,y)
    _triggerMouseDown(mx,my,k)
end
function love.mousemoved(x,y,dx,dy,touch)
    if touch then return end
    mouseShow=true
    mx,my=ITP(xOy,x,y)
    _updateMousePos(mx,my,dx,dy)
end
function love.mousereleased(x,y,k,touch)
    if touch or WAIT.state or SCN.swapping then return end
    mx,my=ITP(xOy,x,y)
    if WIDGET.sel then
        WIDGET._release(mx,my,k)
    else
        if SCN.mouseUp then SCN.mouseUp(mx,my,k) end
        if lastX and SCN.mouseClick and (mx-lastX)^2+(my-lastY)^2<62 then
            SCN.mouseClick(mx,my,k)
        end
    end
end
function love.wheelmoved(dx,dy)
    if WAIT.state or SCN.swapping then return end
    if not SCN.wheelMoved or SCN.wheelMoved(dx,dy) then
        WIDGET._scroll(dx,dy)
    end
end

function love.touchpressed(id,x,y)
    mouseShow=false
    if WAIT.state or SCN.swapping then return end
    if not SCN.mainTouchID then
        SCN.mainTouchID=id
        WIDGET.unFocus(true)
        love.touchmoved(id,x,y,0,0)
    end
    x,y=ITP(xOy,x,y)
    lastX,lastY=x,y
    if WIDGET.sel and WIDGET.sel.type=='inputBox' and not WIDGET.sel:isAbove(x,y) then
        WIDGET.unFocus(true)
        kb.setTextInput(false)
    end
    WIDGET._cursorMove(x,y)
    WIDGET._press(x,y,1)
    if SCN.touchDown then SCN.touchDown(x,y,id) end
end
function love.touchmoved(id,x,y,dx,dy)
    if WAIT.state or SCN.swapping then return end
    x,y=ITP(xOy,x,y)
    if SCN.touchMove then SCN.touchMove(x,y,dx/SCR.k,dy/SCR.k,id) end
    WIDGET._drag(x,y,dx/SCR.k,dy/SCR.k)
end
function love.touchreleased(id,x,y)
    if WAIT.state or SCN.swapping then return end
    x,y=ITP(xOy,x,y)
    if id==SCN.mainTouchID then
        WIDGET._release(x,y,id)
        WIDGET._cursorMove(x,y)
        WIDGET.unFocus()
        SCN.mainTouchID=false
    end
    if SCN.touchUp then SCN.touchUp(x,y,id) end
    if (x-lastX)^2+(y-lastY)^2<62 then
        if SCN.touchClick then SCN.touchClick(x,y) end
        clickFX(x,y)
    end
end

-- Touch control test
-- function love.mousepressed(x,y,k) if k==1 then love.touchpressed(1,x,y) end end
-- function love.mousereleased(x,y,k) if k==1 then love.touchreleased(1,x,y) end end
-- function love.mousemoved(x,y,dx,dy) if ms.isDown(1) then love.touchmoved(1,x,y,dx,dy) end end

local function noDevkeyPressed(key)
    if key=='f1' then      devFnKey[1]()
    elseif key=='f2' then  devFnKey[2]()
    elseif key=='f3' then  devFnKey[3]()
    elseif key=='f4' then  devFnKey[4]()
    elseif key=='f5' then  devFnKey[5]()
    elseif key=='f6' then  devFnKey[6]()
    elseif key=='f7' then  devFnKey[7]()
    elseif key=='f8' then  devMode=nil MSG.new('info',"DEBUG OFF",.2)
    elseif key=='f9' then  devMode=1   MSG.new('info',"DEBUG 1")
    elseif key=='f10' then devMode=2   MSG.new('info',"DEBUG 2")
    elseif key=='f11' then devMode=3   MSG.new('info',"DEBUG 3")
    elseif key=='f12' then devMode=4   MSG.new('info',"DEBUG 4")
    elseif devMode==2 then
        local W=WIDGET.sel
        if W then
            if key=='left' then W.x=W.x-10
            elseif key=='right' then W.x=W.x+10
            elseif key=='up' then W.y=W.y-10
            elseif key=='down' then W.y=W.y+10
            elseif key==',' then W.w=W.w-10
            elseif key=='.' then W.w=W.w+10
            elseif key=='/' then W.h=W.h-10
            elseif key=='\'' then W.h=W.h+10
            elseif key=='[' then W.fontSize=W.fontSize-5
            elseif key==']' then W.fontSize=W.fontSize+5
            else return true
            end
            W:reset()
        else
            return true
        end
    else
        return true
    end
end
function love.keypressed(key,_,isRep)
    mouseShow=false
    if devMode and not noDevkeyPressed(key) then
        -- Do nothing
    elseif globalKey[key] then
        globalKey[key]()
    else
        if SCN.swapping then return end
        if WAIT.state then
            if key=='escape' and WAIT.arg.escapable then WAIT.interrupt() end
            return
        end
        if EDITING=="" and (not SCN.keyDown or SCN.keyDown(key,isRep)) then
            local W=WIDGET.sel
            if key=='escape' and not isRep then
                SCN.back()
            elseif key=='up' or key=='down' or key=='left' or key=='right' then
                mouseShow=true
                if KBisDown('lctrl','rctrl') then
                    if W and W.arrowKey then W:arrowKey(key) end
                end
            elseif W and W.keypress then
                W:keypress(key)
            elseif key=='space' or key=='return' then
                mouseShow=true
                if not isRep then
                    clickFX(mx,my)
                    _triggerMouseDown(mx,my,1)
                    WIDGET._release(mx,my,1)
                end
            end
        end
    end
end
function love.keyreleased(i)
    if WAIT.state or SCN.swapping then return end
    if SCN.keyUp then SCN.keyUp(i) end
end

function love.textedited(texts)
    EDITING=texts
end
function love.textinput(texts)
    WIDGET._textinput(texts)
end

-- analog sticks: -1, 0, 1 for neg, neutral, pos
-- triggers: 0 for released, 1 for pressed
local jsAxisEventName={
    leftx={'leftstick_left','leftstick_right'},
    lefty={'leftstick_up','leftstick_down'},
    rightx={'rightstick_left','rightstick_right'},
    righty={'rightstick_up','rightstick_down'},
    triggerleft='triggerleft',
    triggerright='triggerright'
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
function love.joystickadded(JS)
    table.insert(jsState,{
        _id=JS:getID(),
        _jsObj=JS,
        leftx=0,lefty=0,
        rightx=0,righty=0,
        triggerleft=0,triggerright=0
    })
    MSG.new('info',"Joystick added")
end
function love.joystickremoved(JS)
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
function love.gamepadaxis(JS,axis,val)
    if jsState[1] and JS==jsState[1]._jsObj then
        local js=jsState[1]
        if axis=='leftx' or axis=='lefty' or axis=='rightx' or axis=='righty' then
            local newVal=-- range: [0,1]
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
            local newVal=val>.3 and 1 or 0-- range: [0,1]
            if newVal~=js[axis] then
                if newVal==1 then
                    love.gamepadpressed(JS,jsAxisEventName[axis])
                else
                    love.gamepadreleased(JS,jsAxisEventName[axis])
                end
                js[axis]=newVal
            end
        end
    end
end
function love.gamepadpressed(_,key)
    mouseShow=false
    if SCN.swapping then return end
    local cursorCtrl
    if SCN.gamepadDown then
        cursorCtrl=SCN.gamepadDown(key)
    elseif SCN.keyDown then
        cursorCtrl=SCN.keyDown(dPadToKey[key] or key)
    else
        cursorCtrl=true
    end
    if cursorCtrl then
        key=dPadToKey[key] or key
        mouseShow=true
        local W=WIDGET.sel
        if key=='back' then
            SCN.back()
        elseif key=='up' or key=='down' or key=='left' or key=='right' then
            mouseShow=true
            if W and W.arrowKey then W:arrowKey(key) end
        elseif key=='return' then
            mouseShow=true
            clickFX(mx,my)
            _triggerMouseDown(mx,my,1)
            WIDGET._release(mx,my,1)
        else
            if W and W.keypress then
                W:keypress(key)
            end
        end
    end
end
function love.gamepadreleased(_,key)
    if WAIT.state or SCN.swapping then return end
    if SCN.gamepadUp then
        SCN.gamepadUp(key)
    elseif SCN.keyUp then
        SCN.keyUp(dPadToKey[key] or key)
    end
end

function love.filedropped(file)
    if WAIT.state or SCN.swapping then return end
    if SCN.fileDropped then SCN.fileDropped(file) end
end
function love.directorydropped(dir)
    if WAIT.state or SCN.swapping then return end
    if SCN.directoryDropped then SCN.directoryDropped(dir) end
end

function love.lowmemory()
    collectgarbage()
    if autoGCcount<3 then
        autoGCcount=autoGCcount+1
        MSG.new('check',"[auto GC] low MEM 设备内存过低"..string.rep('.',4-autoGCcount))
    end
end

function love.resize(w,h)
    if SCR.w==w and SCR.h==h then return end
    SCR.resize(w,h)
    for k in next,bigCanvases do
        bigCanvases[k]:release()
        bigCanvases[k]=gc.newCanvas()
    end
    BG._resize(w,h)
    if SCN.resize then SCN.resize(w,h) end
    WIDGET._reset()
    onResize(w,h)
end

function love.focus(f)
    if onFocus then
        onFocus(f)
    end
end

local function secondLoopThread()
    local mainLoop=love.run()
    repeat coroutine.yield() until mainLoop()
end
function love.errorhandler(msg)
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
    love.audio.stop()
    BGM.stop()
    gc.reset()
    SCR.resize(gc.getWidth(),gc.getHeight())

    local sceneStack=SCN and table.concat(SCN.stack,"/") or "NULL"
    if mainLoopStarted and #errData<3 and SCN.scenes['error'] then
        BG.set('none')
        table.insert(errData,{msg=err,scene=sceneStack})

        -- Write messages to log file
        love.filesystem.append('error.log',
            os.date("%Y/%m/%d %A %H:%M:%S\n")..
            #errData.." crash(es) "..love.system.getOS().."-"..versionText.."  scene: "..sceneStack.."\n"..
            table.concat(err,"\n",1,c-2).."\n\n"
        )

        -- Get screencapture
        GC.getScreenShot(errData[#errData],'shot')
        gc.present()

        -- Create a new mainLoop thread to keep game alive
        local status,resume=coroutine.status,coroutine.resume
        local loopThread=coroutine.create(secondLoopThread)
        local res,threadErr
        repeat
            res,threadErr=resume(loopThread)
        until status(loopThread)=='dead'
        if not res then
            love.errorhandler(threadErr)
            return
        end
    else
        ms.setVisible(true)

        local errorMsg
        errorMsg=mainLoopStarted and
            "Too many errors or fatal error occured.\nPlease restart the game." or
            "An error has occurred during loading.\nError info has been created, and you can send it to the author."
        while true do
            love.event.pump()
            for E,a,b in love.event.poll() do
                if E=='quit' or a=='escape' then
                    return true
                elseif E=='resize' then
                    SCR.resize(a,b)
                end
            end
            GC.clear(.3,.5,.9)
            GC.push('transform')
            GC.replaceTransform(SCR.origin)
            local k=math.min(SCR.h/720,1)
            GC.scale(k)
            setFont(100,'_norm') gc_print(":(",100,0,0,1.2)
            setFont(40,'_norm') gc.printf(errorMsg,100,160,SCR.w/k-200)
            setFont(25,'_norm') gc.printf(err[1],100,380,SCR.w/k-200)
            setFont(20,'_norm')
            GC.print(love.system.getOS().."-"..versionText.."\nScene stack:"..sceneStack,100,640)
            GC.print("TRACEBACK",100,430)
            for i=4,#err-2 do
                gc_print(err[i],100,380+20*i)
            end
            GC.pop()
            GC.present()
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
function love.run()
    mainLoopStarted=true

    local love=love

    local SCN_swapUpdate=SCN._swapUpdate
    local BG_update,BG_draw=BG._update,BG._draw
    local TEXT,TEXT_update,TEXT_draw=TEXT,TEXT.update,TEXT.draw
    local MES_update,MES_draw=MSG._update,MSG._draw
    local SYSFX_update,SYSFX_draw=SYSFX._update,SYSFX._draw
    local WAIT_update,WAIT_draw=WAIT._update,WAIT._draw
    local HTTP_update=HTTP._update
    local TASK_update=TASK._update
    local WIDGET_update,WIDGET_draw=WIDGET._update,WIDGET._draw
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
    elseif SCN.scenes[firstScene] then
        SCN.go(firstScene,'none')
        SCN.scenes._zenitha=nil
    else
        if firstScene then
            MSG.new('error',"No scene named '"..firstScene.."'")
        end
        SCN.go('_zenitha')
    end

    -- Main loop
    return function()
        local time=timer()
        STEP()

        -- local loopDT=time-lastLoopTime
        lastLoopTime=time

        -- EVENT
        PUMP()
        for N,a,b,c,d,e in POLL() do
            if love[N] then
                love[N](a,b,c,d,e)
            elseif N=='quit' then
                return a or true
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
            BG_update(updateDT)
            TEXT_update(TEXT,updateDT)
            MES_update(updateDT)
            SYSFX_update(updateDT)
            WAIT_update(updateDT)
            HTTP_update()
            TASK_update(updateDT)
            if SCN.update then SCN.update(updateDT) end
            if SCN.swapping then SCN_swapUpdate(updateDT) end
            WIDGET_update(updateDT)
        end

        -- DRAW
        if not MINI() then
            drawCounter=drawCounter+drawFreq
            if drawCounter>=100 then
                drawCounter=drawCounter-100

                local drawDT=time-lastDrawTime
                lastDrawTime=time

                gc_replaceTransform(SCR.origin)
                    BG_draw()
                gc_replaceTransform(xOy)
                    if SCN.draw then
                        gc_translate(0,-SCN.curScroll)
                        SCN.draw()
                    end
                gc_replaceTransform(xOy)
                    gc_translate(0,-SCN.curScroll)
                    WIDGET_draw()
                gc_replaceTransform(xOy)
                    SYSFX_draw()
                    TEXT_draw(TEXT)
                    if mouseShow then drawCursor(time,mx,my) end
                gc_replaceTransform(SCR.xOy_ul)
                    drawSysInfo()
                gc_replaceTransform(SCR.origin)
                    if SCN.swapping then
                        SCN.state.draw(SCN.state.time)
                    end
                gc_replaceTransform(SCR.xOy_ul)
                    MES_draw()
                gc_replaceTransform(SCR.xOy_d)
                    -- Version string
                    gc_setColor(.9,.9,.9,.42)
                    setFont(20,'_norm')
                    gc_printf(versionText,-2600,-30,5200,'center')
                gc_replaceTransform(SCR.xOy_dl)
                    local safeX=SCR.safeX/SCR.k

                    -- FPS
                    setFont(15,'_norm')
                    gc_setColor(COLOR.L)
                    gc_print(FPS(),safeX+5,-20)

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
                        table.insert(frameTimeList,1,drawDT) table.remove(frameTimeList,126)
                        gc_setColor(1,1,1,.26)
                        for i=1,#frameTimeList do
                            gc.rectangle('fill',150+2*i,-20,2,-frameTimeList[i]*4000)
                        end

                        -- Cursor pos disp
                        gc_replaceTransform(SCR.origin)
                            local x,y=xOy:transformPoint(mx,my)
                            gc.setLineWidth(1)
                            gc.line(x,0,x,SCR.h)
                            gc.line(0,y,SCR.w,y)
                            local t=math.floor(mx+.5)..","..math.floor(my+.5)
                            gc.setColor(COLOR.D)
                            gc_print(t,x+1,y)
                            gc_print(t,x+1,y-1)
                            gc_print(t,x+2,y-1)
                            gc_setColor(COLOR.L)
                            gc_print(t,x+2,y)
                    end
                gc_replaceTransform(SCR.origin)
                    WAIT_draw()
                gc_present()

                -- SPEED UPUP! (probably not that obvious)
                if discardCanvas then GC.discard() end
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

-- Zenitha framework & methods
Zenitha={}

--- Go to quit scene then terminate the application
--- @param style? string @Choose a scene swapping style
function Zenitha._quit(style)
    onQuit()
    SCN.swapTo('_quit',style or 'slowFade')
end

--- Set the application name string
--- @param name string
function Zenitha.setAppName(name)
    assert(type(name)=='string','App name must be string')
    appName=name
end

--- Get the application name
--- @return string
function Zenitha.getAppName() return appName end

--- Set the application version text
--- @param text string
function Zenitha.setVersionText(text)
    assert(type(text)=='string','Version text must be string')
    versionText=text
end

--- Get the application version text
--- @return string
function Zenitha.getVersionText() return versionText end

--- Get the joysticks' state table
function Zenitha.getJsState() return jsState end

--- Get the error info
--- @param i number @Index of error info
--- @return table @Error info table
function Zenitha.getErr(i)
    if i=='#' then
        return errData[#errData]
    elseif i then
        return errData[i]
    else
        return errData
    end
end

--- Set the debug info list
--- @param list table<number,  table<string|function>>[]
function Zenitha.setDebugInfo(list)
    assert(type(list)=='table',"Zenitha.setDebugInfo(list): list must be table")
    for i=1,#list do
        assert(type(list[i][1])=='string',"Zenitha.setDebugInfo(list): list[i][1] must be string")
        assert(type(list[i][2])=='function',"Zenitha.setDebugInfo(list): list[i][2] must be function")
    end
    debugInfos=list
end

--- Set the first scene to load
--- @param name string|any
function Zenitha.setFirstScene(name)
    assert(type(name)=='string',"Zenitha.setFirstScene(name): name must be string")
    firstScene=name
end

--- Set whether to discard canvas buffer after drawing each frame
--- @param b boolean
function Zenitha.setCleanCanvas(b)
    assert(type(b)=='boolean',"Zenitha.setCleanCanvas(b): b must be boolean")
    discardCanvas=b
end

--- Set the updating rate of the application
---
--- Default value is 100(%), all *.update(dt) will be called every main loop
---
--- If set to 50(%), all *.update(dt) will be called every 2 main loop
--- @param rate number @Updating rate percentage, range from 0 to 100
function Zenitha.setUpdateFreq(rate)
    assert(type(rate)=='number' and rate>0 and rate<=100,"Zenitha.setUpdateFreq(rate): rate must in (0,100]")
    updateFreq=rate
end

--- Set the drawing rate of the application, same as Zenitha.setUpdateFreq(rate)
--- @param rate number @Drawing rate percentage, range from 0 to 100
function Zenitha.setDrawFreq(rate)
    assert(type(rate)=='number' and rate>0 and rate<=100,"Zenitha.setDrawFreq(rate): rate must in (0,100]")
    drawFreq=rate
end

--- Set the max update rate of main loop
---
--- Default value is 60
--- @param fps number
function Zenitha.setMaxFPS(fps)
    assert(type(fps)=='number' and fps>0,"Zenitha.setMaxFPS(fps): fps must be positive number")
    sleepInterval=1/fps
end

--- Set click effect
---
--- Boolean: switch on/off
---
--- Function: trigger custom function after every clicks (pass x,y as arguments)
--- @param fx false|true|function
function Zenitha.setClickFX(fx)
    assert(type(fx)=='boolean' or type(fx)=='function',"Zenitha.setClickFX(fx): fx must be boolean or function")
    if fx==false then fx=NULL end
    if fx==true then fx=function(x,y) SYSFX.new('tap',3,x,y) end end
    clickFX=fx
end

--- Set highest priority global key-pressing event listener
--- @param key string @Key name
--- @param func function|false @Function to be called when key is pressed, false to remove
function Zenitha.setOnGlobalKey(key,func)
    assert(type(key)=='string',"Zenitha.setOnFnKeys(key,func): key must be string")
    if func==false then
        globalKey[key]=nil
    else
        assert(type(func)=='function',"Zenitha.setOnFnKeys(key,func): func must be function|false")
        globalKey[key]=func
    end
end

--- Set Fn keys' event listener (for debugging)
--- @param list table<function> @Function list, [1~7]=function
function Zenitha.setOnFnKeys(list)
    assert(type(list)=='table',"Zenitha.setOnFnKeys(list): list must be table, [1~7]=function")
    for i=1,7 do
        assert(type(list[i])=='function',"Zenitha.setOnFnKeys(list): list must be table, [1~7]=function")
        devFnKey[i]=list[i]
    end
end

--- Set global onFocus event listener
--- @param func function @Function to be called when window focus changed
function Zenitha.setOnFocus(func)
    assert(type(func)=='function',"Zenitha.setOnFocus(func): func must be function")
    onFocus=func
end

--- Set global onResize event listener
--- @param func function @Function to be called when window resized
function Zenitha.setOnResize(func)
    assert(type(func)=='function',"Zenitha.setOnResize(func): func must be function")
    onResize=func
end

--- Set global onQuit event listener
--- @param func function @Function to be called when application is about to quit
function Zenitha.setOnQuit(func)
    assert(type(func)=='function',"Zenitha.setOnQuit(func): func must be function")
    onQuit=func
end

--- Set cursor drawing function (pass time,x,y as arguments)
---
--- Color and line width is uncertain, set it yourself in the function.
--- @param func function @Function to be called when drawing cursor
function Zenitha.setDrawCursor(func)
    assert(type(func)=='function',"Zenitha.setDrawCursor(func): func must be function")
    drawCursor=func
end

--- Set system info drawing function (default transform is SCR.xOy_ul)
--- @param func function @Function to be called when drawing system info
function Zenitha.setDrawSysInfo(func)
    assert(type(func)=='function',"Zenitha.setDrawSysInfo(func): func must be function")
    drawSysInfo=func
end

--- Get a big canvas which is as big as the screen
--- @param id string @Canvas ID
--- @return love.Canvas
function Zenitha.getBigCanvas(id)
    return bigCanvases[id]
end

--------------------------------------------------------------

SCN.add('_quit',{enter=function() onQuit() love.event.quit() end})
SCN.add('_console',require'Zenitha/scene/console')
SCN.add('_zenitha',require'Zenitha/scene/demo')
SCN.add('_test',require'Zenitha/scene/test')
