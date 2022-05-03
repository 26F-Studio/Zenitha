local gc=love.graphics

local scenes={}

local eventNames={
    "enter",
    "leave",

    "mouseDown","mouseMove","mouseUp","mouseClick","wheelMoved",
    "touchDown","touchUp","touchMove","touchClick",
    "keyDown","keyUp",
    "gamepadDown","gamepadUp",
    "fileDropped","directoryDropped",
    "resize",
    "update","draw",
}

local SCN={
    mainTouchID=nil,     -- First touching ID(userdata)
    cur='NULL',          -- Current scene name
    maxScroll=0,
    curScroll=0,

    swapping=false,      -- If Swapping
    state={
        tar=false,       -- Swapping target
        style=false,     -- Swapping style
        changeTime=false,-- Loading point
        time=false,      -- Full swap time
        draw=false,      -- Swap draw  func
    },
    stack={},-- Scene stack
    prev=false,
    args={},-- Arguments from previous scene

    scenes=scenes,
}

function SCN.add(name,scene)
    assert(not scene.scrollHeight or type(scene.scrollHeight)=='number',"[scene].scrollHeight must be number")
    assert(not scene.widgetList or type(scene.widgetList)=='table',"[scene].widgetList must be table")
    assert(not scenes[name],STRING.repD("SCN.add(name,scene): scene '$1' already exists",name))
    for i=1,#eventNames do assert(not scene[eventNames[i]] or type(scene[eventNames[i]])=='function',"[scene]."..eventNames[i].." must be function") end
    if not scene.widgetList then scene.widgetList={} end
    setmetatable(scene.widgetList,WIDGET.indexMeta)
    scenes[name]=scene
end
function SCN.setScroll(height)
    SCN.maxScroll=height or 0
    SCN.curScroll=MATH.clamp(SCN.curScroll,0,SCN.maxScroll)
end

function SCN.swapUpdate(dt)
    local S=SCN.state
    S.time=S.time-dt
    if S.time<S.changeTime and S.time+dt>=S.changeTime then
        -- Scene swapped this frame
        SCN.prev=SCN.cur
        SCN.load(S.tar)
        SCN.mainTouchID=nil
    end
    if S.time<0 then
        SCN.swapping=false
    end
end

function SCN.load(s)
    love.keyboard.setTextInput(false)

    SCN.cur=s

    local S=scenes[s]
    SCN.maxScroll=S.scrollHeight or 0
    SCN.curScroll=0
    WIDGET.setWidgetList(S.widgetList)
    for i=1,#eventNames do
        SCN[eventNames[i]]=S[eventNames[i]]
    end

    if S.enter then S.enter() end
end
function SCN.push(tar,style)
    if not SCN.swapping then
        local m=#SCN.stack
        SCN.stack[m+1]=tar or SCN.cur
        SCN.stack[m+2]=style or 'fade'
    end
end
function SCN.pop()
    table.remove(SCN.stack)
    table.remove(SCN.stack)
end

local swap={
    none={
        duration=0,changeTime=0,
        draw=function() end
    },
    flash={
        duration=.16,changeTime=.08,
        draw=function() gc.clear(1,1,1) end
    },
    fade={
        duration=.5,changeTime=.25,
        draw=function(t)
            gc.setColor(.1,.1,.1,t>.25 and 2-t*4 or t*4)
            gc.rectangle('fill',0,0,SCR.w,SCR.h)
        end
    },
    fastFade={
        duration=.1,changeTime=.05,
        draw=function(t)
            gc.setColor(.1,.1,.1,t>.05 and 2-t*20 or t*20)
            gc.rectangle('fill',0,0,SCR.w,SCR.h)
        end
    },
    slowFade={
        duration=3,changeTime=1.5,
        draw=function(t)
            gc.setColor(.1,.1,.1,t>1.5 and (3-t)/1.5 or t/1.5)
            gc.rectangle('fill',0,0,SCR.w,SCR.h)
        end
    },
    swipeL={
        duration=.5,changeTime=.25,
        draw=function(t)
        t=t*2
            gc.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(3-2*t)*2-1
            gc.rectangle('fill',t*SCR.w,0,SCR.w,SCR.h)
        end
    },
    swipeR={
        duration=.5,changeTime=.25,
        draw=function(t)
            t=t*2
            gc.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(2*t-3)*2+1
            gc.rectangle('fill',t*SCR.w,0,SCR.w,SCR.h)
        end
    },
    swipeD={
        duration=.5,changeTime=.25,
        draw=function(t)
            t=t*2
            gc.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(2*t-3)*2+1
            gc.rectangle('fill',0,t*SCR.h,SCR.w,SCR.h)
        end
    },
}-- Scene swapping animations
function SCN.swapTo(tar,style,...)-- Parallel scene swapping, cannot back
    if scenes[tar] then
        if not SCN.swapping and tar~=SCN.cur then
            style=style or 'fade'
            SCN.swapping=true
            SCN.args={...}
            local S=SCN.state
            S.tar,S.style=tar,style
            S.time=swap[style].duration
            S.changeTime=swap[style].changeTime
            S.draw=swap[style].draw
        end
    else
        MES.new('warn',"No Scene: "..tar)
    end
end
function SCN.go(tar,style,...)-- Normal scene swapping, can back
    if scenes[tar] then
        SCN.push()
        SCN.swapTo(tar,style,...)
    else
        MES.new('warn',"No Scene: "..tar)
    end
end
function SCN.back(...)
    if SCN.swapping then return end

    local m=#SCN.stack
    if m>0 then
        -- Leave scene
        if SCN.leave then SCN.leave() end

        -- Poll&Back to previous Scene
        SCN.swapTo(SCN.stack[m-1],SCN.stack[m],...)
        table.remove(SCN.stack)
        table.remove(SCN.stack)
    else
        Zenitha._quit()
    end
end
return SCN
