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
    cur=false,
    args={},-- Arguments from previous scene

    scenes=scenes,
}
-- Scene swapping animations
local swap={
    none={
        duration=0,changeTime=0,
        draw=function() end,
    },
    flash={
        duration=.16,changeTime=.08,
        draw=function() GC.clear(1,1,1) end,
    },
    fade={
        duration=.5,changeTime=.25,
        draw=function(t)
            GC.setColor(.1,.1,.1,t>.25 and 2-t*4 or t*4)
            GC.rectangle('fill',0,0,SCR.w,SCR.h)
        end,
    },
    fastFade={
        duration=.2,changeTime=.1,
        draw=function(t)
            GC.setColor(.1,.1,.1,t>.1 and 2-t*10 or t*10)
            GC.rectangle('fill',0,0,SCR.w,SCR.h)
        end,
    },
    slowFade={
        duration=3,changeTime=1.5,
        draw=function(t)
            GC.setColor(.1,.1,.1,t>1.5 and (3-t)/1.5 or t/1.5)
            GC.rectangle('fill',0,0,SCR.w,SCR.h)
        end,
    },
    swipeL={
        duration=.5,changeTime=.25,
        draw=function(t)
        t=t*2
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(3-2*t)*2-1
            GC.rectangle('fill',t*SCR.w,0,SCR.w,SCR.h)
        end,
    },
    swipeR={
        duration=.5,changeTime=.25,
        draw=function(t)
            t=t*2
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(2*t-3)*2+1
            GC.rectangle('fill',t*SCR.w,0,SCR.w,SCR.h)
        end,
    },
    swipeD={
        duration=.5,changeTime=.25,
        draw=function(t)
            t=t*2
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(2*t-3)*2+1
            GC.rectangle('fill',0,t*SCR.h,SCR.w,SCR.h)
        end,
    },
}

function SCN.add(name,scene)
    assert(not scenes[name],STRING.repD("SCN.add(name,scene): scene '$1' already exists",name))
    assert(type(scene)=='table',"SCN.add(name,scene): Scene object must be table")

    -- Check each field in scene object
    for k,v in next,scene do
        if k=='widgetList' then
            assert(type(scene.widgetList)=='table',"[scene].widgetList must be table")
        elseif k=='scrollHeight' then
            assert(type(scene.scrollHeight)=='number' and scene.scrollHeight>0,"[scene].scrollHeight must be positive number")
        elseif TABLE.find(eventNames,k) then
            assert(type(v)=='function',"Scene '"..name.."'."..k.." must be function")
        else
            error("Invalid key '"..k.."' in scene '"..name.."'")
        end
    end
    for i=1,#eventNames do assert(not scene[eventNames[i]] or type(scene[eventNames[i]])=='function',"[scene]."..eventNames[i].." must be function") end

    if not scene.widgetList then scene.widgetList={} end
    setmetatable(scene.widgetList,WIDGET.indexMeta)
    scenes[name]=scene
end
function SCN.addSwap(name,swp)
    assert(type(name)=='string',"Arg name must be string")
    assert(not swap[name],"Swap '"..name.."' already exist")
    assert(type(swp)=='table',"Arg swp must be table")
    assert(type(swp.duration)=='number' and swp.duration>=0,"swp.duration must be nonnegative number")
    assert(type(swp.changeTime)=='number' and swp.changeTime>=0,"swp.changeTime must be nonnegative number")
    assert(type(swp.draw)=='function',"swp.draw must be function")
    swap[name]=swp
end
function SCN.setScroll(height)
    SCN.maxScroll=height or 0
    SCN.curScroll=MATH.clamp(SCN.curScroll,0,SCN.maxScroll)
end

function SCN.swapUpdate(dt)
    local S=SCN.state
    S.time=S.time-dt
    if S.time<S.changeTime and S.time+dt>=S.changeTime then
        -- Actually load scene at this moment
        SCN.stack[#SCN.stack]=S.tar
        SCN.cur=S.tar
        SCN.load(S.tar)
        SCN.mainTouchID=nil
    end
    if S.time<0 then
        SCN.swapping=false
    end
end

function SCN.load(s)
    love.keyboard.setTextInput(false)

    local S=scenes[s]
    SCN.maxScroll=S.scrollHeight or 0
    SCN.curScroll=0
    WIDGET.setWidgetList(S.widgetList)
    for i=1,#eventNames do
        SCN[eventNames[i]]=S[eventNames[i]]
    end

    if S.enter then S.enter() end
end
function SCN.push(tar)
    table.insert(SCN.stack,tar or SCN.stack[#SCN.stack-1])
end
function SCN.pop()
    table.remove(SCN.stack)
end

function SCN.swapTo(tar,style,...)-- Parallel scene swapping, cannot back
    if scenes[tar] then
        if not SCN.swapping then
            SCN.prev=SCN.stack[#SCN.stack]

            style=style or 'fade'
            if not swap[style] then
                MSG.new('error',"No swap style named '"..style.."'")
                style='fade'
            end
            SCN.swapping=true
            SCN.args={...}
            local S=SCN.state
            S.tar,S.style=tar,style
            S.time=swap[style].duration
            S.changeTime=swap[style].changeTime
            S.draw=swap[style].draw
        end
    else
        MSG.new('warn',"No Scene: "..tar)
    end
end
function SCN.go(tar,style,...)-- Normal scene swapping, can back
    if scenes[tar] then
        if not SCN.swapping then
            SCN.push(SCN.stack[#SCN.stack] or '_')
            SCN.swapTo(tar,style,...)
        end
    else
        MSG.new('warn',"No Scene: "..tar)
    end
end
function SCN.back(style,...)
    if SCN.swapping then return end

    local m=#SCN.stack
    if m>1 then
        -- Leave scene
        if SCN.leave then SCN.leave() end

        -- Poll&Back to previous Scene
        SCN.pop()
        SCN.swapTo(SCN.stack[#SCN.stack],style,...)
    else
        Zenitha._quit(style)
    end
end
function SCN.backTo(tar,style,...)
    if SCN.swapping then return end

    -- Leave scene
    if SCN.sceneBack then
        SCN.sceneBack()
    end

    -- Poll&Back to previous Scene
    while SCN.stack[#SCN.stack-1]~=tar and #SCN.stack>1 do
        SCN.pop()
    end
    SCN.swapTo(SCN.stack[#SCN.stack],style,...)
end
function SCN.printStack()
    for i=1,#SCN.stack do print(SCN.stack[i]) end
end

return SCN
