--- @class Zenitha.Scene
--- @field widgetList? Zenitha.widgetArg[]|Zenitha.widget.base[]
--- @field scrollHeight? number|nil
---
--- @field enter? function
--- @field leave? function
--- @field mouseDown? function
--- @field mouseMove? function
--- @field mouseUp? function
--- @field mouseClick? function
--- @field wheelMoved? function
--- @field touchDown? function
--- @field touchUp? function
--- @field touchMove? function
--- @field touchClick? function
--- @field keyDown? function
--- @field keyUp? function
--- @field gamepadDown? function
--- @field gamepadUp? function
--- @field fileDropped? function
--- @field directoryDropped? function
--- @field resize? function
--- @field update? function
--- @field draw? function

--- @class Zenitha.SceneSwap
--- @field duration number
--- @field timeChange number
--- @field draw function

--- @type Zenitha.Scene[]
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
    mainTouchID=nil, -- First touching ID(userdata)
    maxScroll=0,
    curScroll=0,

    swapping=false, -- If Swapping
    state={
        tar=false,        -- Swapping target
        style=false,      -- Swapping style
        draw=false,       -- Swap draw func
        timeRem=false,    -- Swap time remain
        timeChange=false, -- Loading point
    },
    stack={}, -- Scene stack
    prev=false,
    cur=false,
    args={}, -- Arguments from previous scene

    scenes=scenes,
}

local defaultSwap='fade'
-- Scene swapping animations
local swap={
    none={
        duration=0,timeChange=0,
        draw=function() end,
    },
    flash={
        duration=.16,timeChange=.08,
        draw=function() GC.clear(1,1,1) end,
    },
    fade={
        duration=.5,timeChange=.25,
        draw=function(t)
            GC.setColor(.1,.1,.1,t>.25 and 2-t*4 or t*4)
            GC.rectangle('fill',0,0,SCR.w,SCR.h)
        end,
    },
    fastFade={
        duration=.2,timeChange=.1,
        draw=function(t)
            GC.setColor(.1,.1,.1,t>.1 and 2-t*10 or t*10)
            GC.rectangle('fill',0,0,SCR.w,SCR.h)
        end,
    },
    slowFade={
        duration=3,timeChange=1.5,
        draw=function(t)
            GC.setColor(.1,.1,.1,t>1.5 and (3-t)/1.5 or t/1.5)
            GC.rectangle('fill',0,0,SCR.w,SCR.h)
        end,
    },
    swipeL={
        duration=.5,timeChange=.25,
        draw=function(t)
        t=t*2
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(3-2*t)*2-1
            GC.rectangle('fill',t*SCR.w,0,SCR.w,SCR.h)
        end,
    },
    swipeR={
        duration=.5,timeChange=.25,
        draw=function(t)
            t=t*2
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(2*t-3)*2+1
            GC.rectangle('fill',t*SCR.w,0,SCR.w,SCR.h)
        end,
    },
    swipeD={
        duration=.5,timeChange=.25,
        draw=function(t)
            t=t*2
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            t=t*t*(2*t-3)*2+1
            GC.rectangle('fill',0,t*SCR.h,SCR.w,SCR.h)
        end,
    },
}

--- Add a scene
--- @param name string
--- @param scene Zenitha.Scene
function SCN.add(name,scene)
    assert(type(scene)=='table',"scene must be table")
    assert(not scenes[name],"scene '"..tostring(name).."' already exists")

    if scene.widgetList==nil then scene.widgetList={} end

    -- Check each field in scene object
    for k,v in next,scene do
        if k=='widgetList' then
            assert(type(scene.widgetList)=='table',"[scene].widgetList must be table")
            for kw,w in next,scene.widgetList do
                assert(type(w)=='table',"[scene].widgetList[...] must be widget args table or widget object")
                if not w._widget then
                    scene.widgetList[kw]=WIDGET.new(w)
                end
            end
        elseif k=='scrollHeight' then
            assert(type(scene.scrollHeight)=='number' and scene.scrollHeight>0,"[scene].scrollHeight must be positive number")
        elseif TABLE.find(eventNames,k) then
            assert(type(v)=='function',"Scene '"..name.."'."..k.." must be function")
        else
            error("Invalid key '"..k.."' in scene '"..name.."'")
        end
    end
    for i=1,#eventNames do assert(not scene[eventNames[i]] or type(scene[eventNames[i]])=='function',"[scene]."..eventNames[i].." must be function") end

    scenes[name]=scene
end

--- Add a scene swapping animation
--- @param name string
--- @param swp Zenitha.SceneSwap
function SCN.addSwap(name,swp)
    assert(type(name)=='string',"Arg name must be string")
    assert(not swap[name],"Swap '"..name.."' already exist")
    assert(type(swp)=='table',"Arg swp must be table")
    assert(type(swp.duration)=='number' and swp.duration>=0,"swp.duration must be nonnegative number")
    assert(type(swp.timeChange)=='number' and swp.timeChange>=0,"swp.timeChange must be nonnegative number")
    assert(type(swp.draw)=='function',"swp.draw must be function")
    swap[name]=swp
end

--- Set max scroll area of current scene, default to 0
--- @param height? number
function SCN.setScroll(height)
    SCN.maxScroll=height or 0
    SCN.curScroll=MATH.clamp(SCN.curScroll,0,SCN.maxScroll)
end

--- Update scene swapping animation (called by Zenitha)
--- @param dt number
function SCN._swapUpdate(dt)
    local S=SCN.state
    S.timeRem=S.timeRem-dt
    if S.timeRem<S.timeChange and S.timeRem+dt>=S.timeChange then
        -- Actually load scene at this moment
        SCN.stack[#SCN.stack]=S.tar
        SCN.cur=S.tar
        SCN._load(S.tar)
        SCN.mainTouchID=nil
    end
    if S.timeRem<0 then
        SCN.swapping=false
    end
end

--- Load a scene, replace all events and fresh scrolling, widgets
--- @param name string
function SCN._load(name)
    love.keyboard.setTextInput(false)

    local S=scenes[name]
    SCN.maxScroll=S.scrollHeight or 0
    SCN.curScroll=0
    WIDGET._setWidgetList(S.widgetList)
    for i=1,#eventNames do
        SCN[eventNames[i]]=S[eventNames[i]]
    end

    if S.enter then S.enter() end
end

--- Push a scene to stack
--- @param tar? string
function SCN._push(tar)
    table.insert(SCN.stack,tar or SCN.stack[#SCN.stack-1])
end

--- Pop a scene from stack
function SCN._pop()
    table.remove(SCN.stack)
end

--- Swap to a sceene without add current scene to stack (cannot go back)
--- @param tar string
--- @param style? string
--- @param ... any Arguments passed to new scene
function SCN.swapTo(tar,style,...)
    if scenes[tar] then
        if not SCN.swapping then
            SCN.prev=SCN.stack[#SCN.stack]

            style=style or defaultSwap
            if not swap[style] then
                MSG.new('error',"No swap style named '"..style.."'")
                style=defaultSwap
            end
            SCN.swapping=true
            SCN.args={...}
            local S=SCN.state
            S.tar,S.style=tar,style
            S.timeRem=swap[style].duration
            S.timeChange=swap[style].timeChange
            S.draw=swap[style].draw
        end
    else
        MSG.new('warn',"No Scene: "..tar)
    end
end

--- Go to a scene
--- @param tar string
--- @param style? string
--- @param ... any Arguments passed to new scene
function SCN.go(tar,style,...)
    if scenes[tar] then
        if not SCN.swapping then
            SCN._push(SCN.stack[#SCN.stack] or '_')
            SCN.swapTo(tar,style,...)
        end
    else
        MSG.new('warn',"No Scene: "..tar)
    end
end

--- Back to previous scene
--- @param style? string
--- @param ... any Arguments passed to previous scene
function SCN.back(style,...)
    if SCN.swapping then return end

    local m=#SCN.stack
    if m>1 then
        -- Leave scene
        if SCN.leave then SCN.leave() end

        -- Poll&Back to previous Scene
        SCN.swapTo(SCN.stack[#SCN.stack-1],style,...)
        SCN._pop()
    else
        Zenitha._quit(style)
    end
end

--- Back to a specific scene
--- @param tar string
--- @param style? string
--- @param ... any Arguments passed to target scene
function SCN.backTo(tar,style,...)
    if SCN.swapping then return end

    -- Poll&Back to previous Scene
    while SCN.stack[#SCN.stack-1]~=tar and #SCN.stack>1 do
        SCN._pop()
    end
    SCN.swapTo(SCN.stack[#SCN.stack],style,...)
end

--- Print current scene stack to console
function SCN.printStack()
    for i=1,#SCN.stack do print(SCN.stack[i]) end
end

function SCN.setDefaultSwap(anim)
    assert(type(anim)=='string',"swap style must be string")
    assert(swap[anim],"No swap style named '"..anim.."'")
    defaultSwap=anim
end

return SCN
