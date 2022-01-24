-- #define (lol)
local ms,kb=love.mouse,love.keyboard
local KBisDown=kb.isDown

local gc=love.graphics
local gc_replaceTransform,gc_present=gc.replaceTransform,gc.present
local gc_push,gc_pop,gc_clear,gc_discard=gc.push,gc.pop,gc.clear,gc.discard
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_draw,gc_line,gc_rectangle,gc_circle=gc.draw,gc.line,gc.rectangle,gc.circle
local gc_print,gc_printf=gc.print,gc.printf

local max,min=math.max,math.min
math.randomseed(os.time()*2600)

--------------------------------------------------------------

-- Useful global values/variables
NONE={}setmetatable(NONE,{__newindex=function() error('Attempt to modify a constant table') end})
NULL=function(...) end
PAPER=love.graphics.newCanvas(1,1)

SYSTEM=love.system.getOS() if SYSTEM=='OS X' then SYSTEM='macOS' end
MOBILE=SYSTEM=='Android' or SYSTEM=='iOS'
SAVEDIR=love.filesystem.getSaveDirectory()
EDITING=""

-- Inside values
local mainLoopStarted=false
local autoGCcount=0
local devMode
local mx,my,mouseShow,cursorSpd=640,360,false,0
local lastX,lastY=0,0-- Last click pos
local jsState={}-- map, joystickID->axisStates: {axisName->axisVal}
local errData={}-- list, each error create {mes={errMes strings},scene=sceneNameStr}

-- User-changeable values
local appName='Zenitha'
local versionText='V0.1'
local showPowerInfo=true
local showClickFX=true
local discardCanvas=false
local updateFreq=100
local drawFreq=100
local sleepInterval=1/60
local function drawCursor(_,x,y)
    gc_setColor(1,1,1)
    gc_setLineWidth(2)
    gc_circle(ms.isDown(1) and 'fill' or 'line',x,y,6)
end
local globalKey={
    f8=function()
        devMode=1
        MES.new('info',"DEBUG ON",.2)
    end
}
local devFnKey={NULL,NULL,NULL,NULL,NULL,NULL,NULL}
local onResize=NULL
local onFocus=NULL
local onQuit=NULL

--------------------------------------------------------------

-- Extended lua basic libraries
MATH=       require'zenitha.mathExtend'
STRING=     require'zenitha.stringExtend'
TABLE=      require'zenitha.tableExtend'
CLASS=      require'zenitha.class'

-- Pure lua modules (simple)
COLOR=      require'zenitha.color'
TEST=       require'zenitha.test'
LOG=        require'zenitha.log'
JSON=       require'zenitha.json'

-- Pure lua modules (complex)
LOG=        require'zenitha.log'
REQUIRE=    require'zenitha.require'
TASK=       require'zenitha.task'
WS=         require'zenitha.websocket'
LANG=       require'zenitha.languages'
PROFILE=    require'zenitha.profile'

do-- Add pcall & MES for JSON lib
    local encode,decode=JSON.encode,JSON.decode
    JSON.encode=function(val)
        local a,b=pcall(encode,val)
        if a then
            return b
        elseif MES then
            MES.traceback()
        end
    end
    JSON.decode=function(str)
        local a,b=pcall(decode,str)
        if a then
            return b
        elseif MES then
            MES.traceback()
        end
    end
end

-- Love-based modules (data)
FILE=       require'zenitha.file'
WHEELMOV=   require'zenitha.wheelToArrow'
SCR=        require'zenitha.screen'
SCN=        require'zenitha.scene'

-- Love-based modules (media)
GC=         require'zenitha.gcExtend'
STENCIL=    require'zenitha.stencil'
FONT=       require'zenitha.font'
TEXT=       require'zenitha.text'
SYSFX=      require'zenitha.sysFX'
MES=        require'zenitha.message'
BG=         require'zenitha.background'
WIDGET=     require'zenitha.widget'
VIB=        require'zenitha.vibrate'
SFX=        require'zenitha.sfx'
IMG=        require'zenitha.image'
BGM=        require'zenitha.bgm'
VOC=        require'zenitha.voice'

--------------------------------------------------------------

local WIDGET,SCR,SCN=WIDGET,SCR,SCN
local setFont=FONT.set
local xOy=SCR.xOy
local ITP=xOy.inverseTransformPoint

-- Power info updating function
local infoCanvas=gc.newCanvas(108,27)
local function updatePowerInfo()
    local state,pow=love.system.getPowerInfo()
    gc.setCanvas(infoCanvas)
    gc_push('transform')
    gc.origin()
    gc_clear(0,0,0,.25)
    if state~='unknown' then
        gc_setLineWidth(4)
        if state=='nobattery' then
            gc_setColor(1,1,1)
            gc_setLineWidth(2)
            gc_line(74,5,100,22)
        elseif pow then
            if state=='charging' then gc_setColor(0,1,0)
            elseif pow>50 then        gc_setColor(1,1,1)
            elseif pow>26 then        gc_setColor(1,1,0)
            elseif pow==26 then       gc_setColor(.5,0,1)
            else                      gc_setColor(1,0,0)
            end
            gc.rectangle('fill',76,6,pow*.22,14)
            if pow<100 then
                setFont(15,'_basic')
                gc.setColor(COLOR.D)
                gc_print(pow,77,1)
                gc_print(pow,77,3)
                gc_print(pow,79,1)
                gc_print(pow,79,3)
                gc_setColor(COLOR.Z)
                gc_print(pow,78,2)
            end
        end
        gc_rectangle('fill',74,3,26,2)
        gc_rectangle('fill',74,21,26,2)
        gc_rectangle('fill',99,4,2,18)
        gc_rectangle('fill',102,3,2,14)
    end
    setFont(25,'_basic')
    gc_print(os.date("%H:%M"),3,-5)
    gc_pop()
    gc.setCanvas()
end

-- Set default font
FONT.load({_basic='Zenitha/basic.otf'})
FONT.setDefaultFont('_basic')
FONT.setDefaultFallback('_basic')

do-- Define demo scene
    local testVal_1=false
    local testVal_2=18
    local testVal_3='opt2'
    local function _sceneDraw()
        setFont(150,'_basic')
        GC.mStr("Zenitha",400,60)
        setFont(60,'_basic')
        GC.mStr("Demo Scene",400,220)
        setFont(20,'_basic')
        GC.mStr("Powered by LÖVE",400,300)
    end
    SCN.add('_zenitha',{
        draw=function()
            gc.setColor(.97,.97,.97,.626)
            _sceneDraw()

            STENCIL.start('equal',1)
            STENCIL.circle(400+100*math.cos(love.timer.getTime()*1.26),260+100*math.sin(love.timer.getTime()*1.26),126)
            gc.setColor(COLOR.rainbow_light(love.timer.getTime()))
            _sceneDraw()
            STENCIL.stop()
        end,
        widgetList={
            WIDGET.new{type='checkBox',rawText='1:checkBox',x=210,y=390,w=40,disp=function()return testVal_1 end,code=function()testVal_1=not testVal_1 end},
            WIDGET.new{type='slider',  rawText='2:slider',  x=370,y=390,w=180,axis={10,26,4},disp=function()return testVal_2 end,code=function(v)testVal_2=v end},
            WIDGET.new{type='selector',rawText='3:selector',x=670,y=390,w=200,list={'opt1','opt2','opt3'},disp=function()return testVal_3 end,code=function(v)testVal_3=v end},
            WIDGET.new{type='inputBox',rawText='4:inputBox',x=100,y=450,w=300,h=100,labelPos='down'},
            WIDGET.new{type='button',  rawText='Quit',x=600,y=500,w=200,h=100,code=function() love.event.quit() end},
        }
    })
end

--------------------------------------------------------------

local function _updateMousePos(x,y,dx,dy)
    if SCN.swapping then return end
    dx,dy=dx/SCR.k,dy/SCR.k
    if SCN.mouseMove then SCN.mouseMove(x,y,dx,dy) end
    if ms.isDown(1) then
        WIDGET.drag(x,y,dx,dy)
    else
        WIDGET.cursorMove(x,y)
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
    if SCN.mouseDown then SCN.mouseDown(x,y,k) end
    WIDGET.press(x,y,k)
    lastX,lastY=x,y
    if showClickFX then SYSFX.tap(3,x,y) end
end
local function mouse_update(dt)
    if not KBisDown('lctrl','rctrl') and KBisDown('up','down','left','right') then
        local dx,dy=0,0
        if KBisDown('up') then    dy=dy-cursorSpd end
        if KBisDown('down') then  dy=dy+cursorSpd end
        if KBisDown('left') then  dx=dx-cursorSpd end
        if KBisDown('right') then dx=dx+cursorSpd end
        mx=max(min(mx+dx,1280),0)
        my=max(min(my+dy,720),0)
        if my==0 or my==720 then
            WIDGET.sel=false
            WIDGET.drag(0,0,0,-dy)
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
        mx=max(min(mx+dx,1280),0)
        my=max(min(my+dy,720),0)
        if my==0 or my==720 then
            WIDGET.sel=false
            WIDGET.drag(0,0,0,-dy)
        end
        _updateMousePos(mx,my,dx,dy)
        cursorSpd=min(cursorSpd+dt*26,12.6)
    else
        cursorSpd=6
    end
end
function love.mousepressed(x,y,k,touch)
    if touch then return end
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
    if touch or SCN.swapping then return end
    mx,my=ITP(xOy,x,y)
    if SCN.mouseUp then SCN.mouseUp(mx,my,k) end
    if WIDGET.sel then
        WIDGET.release(mx,my)
    else
        if lastX and SCN.mouseClick and (mx-lastX)^2+(my-lastY)^2<62 then
            SCN.mouseClick(mx,my,k)
        end
    end
end
function love.wheelmoved(x,y)
    if SCN.swapping then return end
    if SCN.wheelMoved then
        SCN.wheelMoved(x,y)
    else
        WIDGET.unFocus()
        WIDGET.drag(0,0,0,100*y)
    end
end

function love.touchpressed(id,x,y)
    mouseShow=false
    if SCN.swapping then return end
    if not SCN.mainTouchID then
        SCN.mainTouchID=id
        WIDGET.unFocus(true)
        love.touchmoved(id,x,y,0,0)
    end
    x,y=ITP(xOy,x,y)
    lastX,lastY=x,y
    WIDGET.cursorMove(x,y)
    if SCN.touchDown then SCN.touchDown(x,y,id) end
    if kb.hasTextInput() then kb.setTextInput(false) end
end
function love.touchmoved(id,x,y,dx,dy)
    if SCN.swapping then return end
    x,y=ITP(xOy,x,y)
    if SCN.touchMove then SCN.touchMove(x,y,dx/SCR.k,dy/SCR.k,id) end
    WIDGET.drag(x,y,dx/SCR.k,dy/SCR.k)
end
function love.touchreleased(id,x,y)
    if SCN.swapping then return end
    x,y=ITP(xOy,x,y)
    if id==SCN.mainTouchID then
        WIDGET.press(x,y,1)
        WIDGET.release(x,y)
        WIDGET.cursorMove(x,y)
        WIDGET.unFocus()
        SCN.mainTouchID=false
    end
    if SCN.touchUp then SCN.touchUp(x,y,id) end
    if (x-lastX)^2+(y-lastY)^2<62 then
        if SCN.touchClick then SCN.touchClick(x,y) end
        if showClickFX then SYSFX.tap(3,x,y) end
    end
end

local function noDevkeyPressed(key)
    if key=='f1' then      devFnKey[1]()
    elseif key=='f2' then  devFnKey[2]()
    elseif key=='f3' then  devFnKey[3]()
    elseif key=='f4' then  devFnKey[4]()
    elseif key=='f5' then  devFnKey[5]()
    elseif key=='f6' then  devFnKey[6]()
    elseif key=='f7' then  devFnKey[7]()
    elseif key=='f8' then  devMode=nil MES.new('info',"DEBUG OFF",.2)
    elseif key=='f9' then  devMode=1   MES.new('info',"DEBUG 1")
    elseif key=='f10' then devMode=2   MES.new('info',"DEBUG 2")
    elseif key=='f11' then devMode=3   MES.new('info',"DEBUG 3")
    elseif key=='f12' then devMode=4   MES.new('info',"DEBUG 4")
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
            elseif key=='[' then W.font=W.font-5
            elseif key==']' then W.font=W.font+5
            else return true
            end
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
    elseif not SCN.swapping then
        if EDITING=="" and (not SCN.keyDown or SCN.keyDown(key,isRep)) then
            local W=WIDGET.sel
            if key=='escape' and not isRep then
                SCN.back()
            elseif key=='up' or key=='down' or key=='left' or key=='right' then
                mouseShow=true
                if KBisDown('lctrl','rctrl') then
                    if W and W.arrowKey then W:arrowKey(key) end
                end
            elseif key=='space' or key=='return' then
                mouseShow=true
                if not isRep then
                    if showClickFX then SYSFX.tap(3,mx,my) end
                    _triggerMouseDown(mx,my,1)
                end
            else
                if W and W.keypress then
                    W:keypress(key)
                end
            end
        end
    end
end
function love.keyreleased(i)
    if SCN.swapping then return end
    if SCN.keyUp then SCN.keyUp(i) end
end

function love.textedited(texts)
    EDITING=texts
end
function love.textinput(texts)
    WIDGET.textinput(texts)
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
    MES.new('info',"Joystick added")
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
            MES.new('info',"Joystick removed")
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
    if not SCN.swapping then
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
                if showClickFX then SYSFX.tap(3,mx,my) end
                _triggerMouseDown(mx,my,1)
            else
                if W and W.keypress then
                    W:keypress(key)
                end
            end
        end
    end
end
function love.gamepadreleased(_,i)
    if SCN.swapping then return end
    if SCN.gamepadUp then SCN.gamepadUp(i) end
end

function love.filedropped(file)
    if SCN.fileDropped then SCN.fileDropped(file) end
end
function love.directorydropped(dir)
    if SCN.directoryDropped then SCN.directoryDropped(dir) end
end

function love.lowmemory()
    collectgarbage()
    if autoGCcount<3 then
        autoGCcount=autoGCcount+1
        MES.new('check',"[auto GC] low MEM 设备内存过低")
    end
end

function love.resize(w,h)
    if SCR.w==w and SCR.h==h then return end
    SCR.resize(w,h)
    if BG.resize then BG.resize(w,h) end
    if SCN.resize then SCN.resize(w,h) end
    WIDGET.resize(w,h)
    onResize(w,h)
end

function love.focus(f) onFocus(f) end

local function secondLoopThread()
    local mainLoop=love.run()
    repeat coroutine.yield() until mainLoop()
end
function love.errorhandler(msg)
    if type(msg)~='string' then
        msg="Unknown error"
    elseif msg:find("Invalid UTF-8") then
        msg="[Invalid UTF-8] If you are on Windows, try downloading Techmino-win32 or Techmino-win64 (different from what you are using now)."
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
    print(table.concat(err,"\n",1,c-2))

    -- Reset something
    love.audio.stop()
    gc.reset()

    if mainLoopStarted and #errData<3 then
        BG.set('none')
        local scn=SCN and SCN.cur or "NULL"
        table.insert(errData,{mes=err,scene=scn})

        -- Write messages to log file
        love.filesystem.append('conf/error.log',
            os.date("%Y/%m/%d %A %H:%M:%S\n")..
            #errData.." crash(es) "..love.system.getOS().."-"..versionText.."  scene: "..scn.."\n"..
            table.concat(err,"\n",1,c-2).."\n\n"
        )

        -- Get screencapture
        gc.captureScreenshot(function(_) errData[#errData].shot=gc.newImage(_) end)
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
            gc_clear(.3,.5,.9)
            gc_push('transform')
            gc_replaceTransform(SCR.xOy)
            setFont(100,'_basic')gc_print(":(",100,0,0,1.2)
            setFont(40,'_basic')gc.printf(errorMsg,100,160,SCR.w0-100)
            setFont(20,'_basic')
            gc_print(love.system.getOS().."-"..versionText.."                          scene:"..(SCN and SCN.cur or "NULL"),100,660)
            gc.printf(err[1],100,360,1260-100)
            gc_print("TRACEBACK",100,450)
            for i=4,#err-2 do
                gc_print(err[i],100,400+20*i)
            end
            gc_pop()
            gc_present()
            love.timer.sleep(.26)
        end
    end
end

-- Remove default callbacks
love.threaderror=nil
love.draw=nil
love.update=nil

local devColor={
    COLOR.Z,
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

    local BG=BG
    local TEXT_update,TEXT_draw=TEXT.update,TEXT.draw
    local MES_update,MES_draw=MES.update,MES.draw
    local WS_update=WS.update
    local TASK_update=TASK.update
    local SYSFX_update,SYSFX_draw=SYSFX.update,SYSFX.draw
    local WIDGET_update,WIDGET_draw=WIDGET.update,WIDGET.draw
    local STEP,WAIT=love.timer.step,love.timer.sleep
    local FPS,MINI=love.timer.getFPS,love.window.isMinimized
    local PUMP,POLL=love.event.pump,love.event.poll

    local timer=love.timer.getTime

    local frameTimeList={}
    local lastLoopTime=timer()
    local lastUpdateTime=timer()
    local lastDrawTime=timer()
    local lastPowFreshingTime=timer()

    -- counters range from 0 to 99, trigger at 100
    local updateCounter=0
    local drawCounter=0

    updatePowerInfo()
    love.resize(gc.getWidth(),gc.getHeight())
    SCN.init('_zenitha')

    return function()
        local _
        local time=timer()
        STEP()

        local loopDT=time-lastLoopTime
        lastLoopTime=time

        -- EVENT
        PUMP()
        for N,a,b,c,d,e in POLL() do
            if love[N] then
                love[N](a,b,c,d,e)
            elseif N=='quit' then
                onQuit()
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
            VOC.update()
            BG.update(updateDT)
            TEXT_update(updateDT)
            MES_update(updateDT)
            WS_update(updateDT)
            TASK_update(updateDT)
            SYSFX_update(updateDT)
            if SCN.update then SCN.update(updateDT) end
            if SCN.swapping then SCN.swapUpdate(updateDT) end
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
                    gc_setColor(1,1,1)
                    BG.draw()
                gc_replaceTransform(SCR.xOy)
                    if SCN.draw then SCN.draw() end
                    WIDGET_draw()
                    SYSFX_draw()
                    TEXT_draw()

                    -- Draw cursor
                    if mouseShow then drawCursor(time,mx,my) end
                gc_replaceTransform(SCR.xOy_ul)
                    MES_draw()
                gc_replaceTransform(SCR.origin)
                    -- Draw power info.
                    if showPowerInfo then
                        gc_setColor(1,1,1)
                        gc_draw(infoCanvas,SCR.safeX,0,0,SCR.k)
                    end

                    -- Draw scene swapping animation
                    if SCN.swapping then
                        gc_setColor(1,1,1)
                        _=SCN.stat
                        _.draw(_.time)
                    end
                gc_replaceTransform(SCR.xOy_d)
                    -- Draw Version string
                    gc_setColor(.9,.9,.9,.42)
                    setFont(20,'_basic')
                    gc_printf(versionText,-2600,-30,5200,'center')
                gc_replaceTransform(SCR.xOy_dl)
                    local safeX=SCR.safeX/SCR.k

                    -- Draw FPS
                    setFont(15,'_basic')
                    gc_setColor(1,1,1)
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
                        table.insert(frameTimeList,1,drawDT)table.remove(frameTimeList,126)
                        gc_setColor(1,1,1,.3)
                        for i=1,#frameTimeList do
                            gc.rectangle('fill',150+2*i,-20,2,-frameTimeList[i]*4000)
                        end

                        -- Cursor pos disp
                        gc_replaceTransform(SCR.origin)
                            local x,y=SCR.xOy:transformPoint(mx,my)
                            gc_setLineWidth(1)
                            gc_line(x,0,x,SCR.h)
                            gc_line(0,y,SCR.w,y)
                            local t=math.floor(mx+.5)..","..math.floor(my+.5)
                            gc.setColor(COLOR.D)
                            gc_print(t,x+1,y)
                            gc_print(t,x+1,y-1)
                            gc_print(t,x+2,y-1)
                            gc_setColor(COLOR.Z)
                            gc_print(t,x+2,y)
                    end
                gc_present()

                -- SPEED UPUPUP!
                if discardCanvas then gc_discard() end
            end
        end

        -- Fresh power info.
        if time-lastPowFreshingTime>2.6 then
            if showPowerInfo then
                updatePowerInfo()
                lastPowFreshingTime=time
            end
            if gc.getWidth()~=SCR.w or gc.getHeight()~=SCR.h then
                love.resize(gc.getWidth(),gc.getHeight())
            end
        end

        -- Slow devmode
        if devMode then
            if devMode==3 then
                WAIT(.1)
            elseif devMode==4 then
                WAIT(.5)
            end
        end

        _=timer()-lastLoopTime
        if _<sleepInterval*.9626 then WAIT(sleepInterval*.9626-_) end
        while timer()-lastLoopTime<sleepInterval do end
    end
end

--------------------------------------------------------------

-- Zenitha framework & methods
Zenitha={}

function Zenitha.setAppName(name)
    assert(type(name)=='string','Z.appName must be a string')
    appName=name
end
function Zenitha.getAppName() return appName end

function Zenitha.setVersionText(text)
    assert(type(text)=='string','Z.versionText must be a string')
    versionText=text
end
function Zenitha.getVersionText() return versionText end

function Zenitha.getJsState() return jsState end
function Zenitha.getErr(i)
    if i=='#' then
        return errData[#errData]
    elseif i then
        return errData[i]
    else
        return errData
    end
end

function Zenitha.setPowerInfo(bool) showPowerInfo=bool end
function Zenitha.setCleanCanvas(bool) discardCanvas=bool end
function Zenitha.setUpdateFreq(n) updateFreq=n end
function Zenitha.setDrawFreq(n) drawFreq=n end
function Zenitha.setMaxFPS(fps) sleepInterval=1/fps end
function Zenitha.setClickFX(bool) showClickFX=bool end

-- [Warning] Color and line width is uncertain value, set it in the function.
function Zenitha.setCursor(func) drawCursor=func end

-- Change first-level global key events
function Zenitha.setGlobalKey(key,func)
    assert(type(key)=='string',"Z.setOnFnKeys(key,func): key must be a string")
    if not func then
        globalKey[key]=nil
    else
        assert(type(func)=='function',"Z.setOnFnKeys(key,func): func must be a function")
        globalKey[key]=func
    end
end

-- Change F1~F7 events of devmode (F8 mode)
function Zenitha.setOnFnKeys(list)
    assert(type(list)=='table',"Z.setOnFnKeys(list): list must be a table")
    for i=1,7 do devFnKey[i]=assert(type(list[i])=='function' and list[i]) end
end

function Zenitha.setDebugInfo(list)
    assert(type(list)=='table',"Z.setDebugInfo(list): list must be a table")
    for i=1,#list do
        assert(type(list[i][1])=='string',"Z.setDebugInfo(list): list[i][1] must be a string")
        assert(type(list[i][2])=='function',"Z.setDebugInfo(list): list[i][2] must be a function")
    end
    debugInfos=list
end

function Zenitha.setOnFocus(func)
    onFocus=assert(type(func)=='function' and func,"Z.setOnFocus(func): func must be a function")
end

function Zenitha.setOnResize(func)
    onResize=assert(type(func)=='function' and func,"Z.setOnResize(func): func must be a function")
end

function Zenitha.setOnQuit(func)
    onQuit=assert(type(func)=='function' and func,"Z.setOnQuit(func): func must be a function")
end
