---@class Zenitha.Scene
---@field widgetList? Zenitha.WidgetArg[]|Zenitha.Widget.base[]
---@field scrollHeight? number|nil
---
---@field load? fun(fromScene:string, ...)  Called when scene loaded
---@field enter? fun(fromScene:string, ...) Called when scene swapping finished
---@field leave? fun(toScene:string, ...)   Called when scene swapping started
---@field unload? fun(toScene:string, ...)  Called when scene unloaded
---@field mouseDown? fun(x:number, y:number, k:number, presses:number):boolean? Able to interrupt cursor & widget control
---@field mouseMove? fun(x:number, y:number, dx:number, dy:number)
---@field mouseUp? fun(x:number, y:number, k:number, presses:number)
---@field mouseClick? fun(x:number, y:number, k:number, dist:number, presses:number)
---@field wheelMove? fun(dx:number, dy:number):boolean? Able to interrupt WIDGET._scroll
---@field touchDown? fun(x:number, y:number, id:userdata, pressure?:number)
---@field touchUp? fun(x:number, y:number, id:userdata, pressure?:number)
---@field touchMove? fun(x:number, y:number, dx:number, dy:number, id:userdata, pressure?:number)
---@field touchClick? fun(x:number, y:number, id:userdata, dist:number)
---@field keyDown? fun(key:love.KeyConstant, isRep:boolean, scancode:love.Scancode):boolean? Able to interrupt cursor & widget control
---@field keyUp? fun(key:love.KeyConstant, scancode:love.Scancode)
---@field textInput? fun(texts:string):boolean? Able to interrupt widget control
---@field imeChange? fun(texts:string):boolean? Able to interrupt widget control
---@field gamepadDown? fun(key:love.GamepadButton)
---@field gamepadUp? fun(key:love.GamepadButton)
---@field fileDrop? fun(file:love.DroppedFile)
---@field folderDrop? fun(path:string)
---@field lowMemory? fun()
---@field resize? fun(width:number, height:number)
---@field focus? fun(focus:boolean)
---@field update? fun(dt:number)
---@field draw? fun()

---@class Zenitha.SceneSwap
---@field duration number
---@field timeChange number
---@field draw function Called with timeRemain(duration~0)

---@type table<string, Zenitha.Scene>
local scenes={}

local eventNames={
    'load','enter','leave','unload',

    'mouseDown','mouseMove','mouseUp','mouseClick','wheelMove',
    'touchDown','touchMove','touchUp','touchClick',
    'keyDown','keyUp',
    'textInput','imeChange',
    'gamepadDown','gamepadUp',

    'fileDrop','folderDrop',
    'lowMemory',
    'resize','focus',

    'update','draw',
}

local SCN={
    mainTouchID=nil, -- First touching ID(userdata)
    maxScroll=0,
    curScroll=0,

    swapping=false, -- If Swapping
    state={
        goingNew=false,   -- If going to new scene (for separating .go and .swapTo when swapping)
        target=false,     -- Swapping target
        swapStyle=false,  -- Swapping style
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

---@alias Zenitha.SceneSwapStyle Zenitha._SceneSwapStyle|string
---@enum (key) Zenitha._SceneSwapStyle
local swapStyles={
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

---Add a scene
---@param name string
---@param scene Zenitha.Scene
function SCN.add(name,scene)
    assertf(type(name)=='string',"SCN.add(name,scene): name need string, got %s",type(name))
    assertf(type(scene)=='table',"SCN.add(name,scene): scene need table, got %s",type(scene))
    assertf(not scenes[name],"SCN.add(name,scene): scene '%s' already exists",name)

    if scene.widgetList==nil then scene.widgetList={} end

    -- Check each field in scene object
    for k in next,scene do
        if k=='widgetList' then
            assertf(type(scene.widgetList)=='table',"SCN.add: scene[%s].widgetList need table",name)
            for kw,w in next,scene.widgetList do
                assertf(type(w)=='table',"SCN.add: scene[%s].widgetList need list<widgetArgTable|widgetObj>",name)
                if not w._widget then
                    scene.widgetList[kw]=WIDGET.new(w)
                end
            end
        elseif k=='scrollHeight' then
            assertf(type(scene.scrollHeight)=='number' and scene.scrollHeight>0,"SCN.add: scene[%s].scrollHeight need >0",name)
        elseif not TABLE.find(eventNames,k) then
            errorf("SCN.add(name,scene): Invalid key '%s' in scene[%s]",k,name)
        end
    end
    for i=1,#eventNames do assertf(scene[eventNames[i]]==nil or type(scene[eventNames[i]])=='function',"SCN.add: scene[%s].%s need function",name,eventNames[i]) end

    scenes[name]=scene
end

---Add a scene swapping animation
---@param name string
---@param swapStyle Zenitha.SceneSwap
function SCN.addSwapStyle(name,swapStyle)
    assertf(type(name)=='string',"SCN.addSwap(name,swp): name need string")
    assertf(not swapStyles[name],"SCN.addSwap(name,swp): Swap '%s' already exist",name)
    assertf(type(swapStyle)=='table',"SCN.addSwap(name,swp): swp need table")
    assertf(type(swapStyle.duration)=='number' and swapStyle.duration>=0,"SCN.addSwap(name,swp): swp.duration need >=0")
    assertf(type(swapStyle.timeChange)=='number' and swapStyle.timeChange>=0,"SCN.addSwap(name,swp): swp.timeChange need >=0")
    assertf(type(swapStyle.draw)=='function',"SCN.addSwap(name,swp): swp.draw need function")
    swapStyles[name]=swapStyle
end

---Set max scroll area of current scene, default to 0
---@param height? number
function SCN.setScroll(height)
    SCN.maxScroll=height or 0
    SCN.curScroll=MATH.clamp(SCN.curScroll,0,SCN.maxScroll)
end

---Update scene swapping animation (called by Zenitha)
---@param dt number
function SCN._swapUpdate(dt)
    local S=SCN.state
    S.timeRem=S.timeRem-dt
    if S.timeRem<S.timeChange and S.timeRem+dt>=S.timeChange then
        -- Actually change scene at this moment
        SCN.prev=SCN.cur
        if S.goingNew then
            SCN._push()
            S.goingNew=false
        end

        local scn=scenes[SCN.prev]
        if scn and scn.unload then scn.unload(SCN.prev,unpack(SCN.args)) end

        SCN._load(S.target)
    end
    if S.timeRem<0 then
        SCN.swapping=false
        local scn=scenes[SCN.cur]
        if scn.enter then scn.enter(SCN.cur,unpack(SCN.args)) end
    end
end

---Load a scene, replace all events and fresh scrolling, widgets
---@param name string
function SCN._load(name)
    SCN.stack[#SCN.stack]=name
    SCN.cur=name

    love.keyboard.setTextInput(false)
    SCN.mainTouchID=nil

    local scn=scenes[name]
    SCN.maxScroll=scn.scrollHeight or 0
    SCN.curScroll=0
    WIDGET._setWidgetList(scn.widgetList)
    for i=1,#eventNames do
        SCN[eventNames[i]]=scn[eventNames[i]]
    end

    if scn.load then scn.load(SCN.prev,unpack(SCN.args)) end
end

---Push a scene to stack
---@param tar? string
function SCN._push(tar)
    table.insert(SCN.stack,tar or '_')
end

---Pop a scene from stack
function SCN._pop()
    table.remove(SCN.stack)
end

---Swap to a sceene without add current scene to stack (cannot go back)
---@param tar string
---@param swapStyle? Zenitha.SceneSwapStyle
---@param ... any Arguments passed to new scene
function SCN.swapTo(tar,swapStyle,...)
    if scenes[tar] then
        if not SCN.swapping then
            swapStyle=swapStyle or defaultSwap
            if not swapStyles[swapStyle] then
                MSG.new('error',"No swap style named '"..swapStyle.."'")
                swapStyle=defaultSwap
            end
            SCN.swapping=true
            SCN.args={...}
            local S=SCN.state
            S.target,S.style=tar,swapStyle
            S.timeRem=swapStyles[swapStyle].duration
            S.timeChange=swapStyles[swapStyle].timeChange
            S.draw=swapStyles[swapStyle].draw
        end
    else
        MSG.new('warn',"No Scene: "..tar)
    end
end

---Go to a scene
---@param tar string
---@param swapStyle? Zenitha.SceneSwapStyle
---@param ... any Arguments passed to new scene
function SCN.go(tar,swapStyle,...)
    if scenes[tar] then
        if not SCN.swapping then
            SCN.state.goingNew=true
            SCN.swapTo(tar,swapStyle,...)
        end
    else
        MSG.new('warn',"No Scene: "..tar)
    end
end

---Back to previous scene
---@param swapStyle? Zenitha.SceneSwapStyle
---@param ... any Arguments passed to previous scene
function SCN.back(swapStyle,...)
    if SCN.swapping then return end

    local m=#SCN.stack
    if m>1 then
        -- Leave scene
        if SCN.leave then SCN.leave(SCN.stack[#SCN.stack-1],unpack(SCN.args)) end

        -- Poll&Back to previous Scene
        SCN.swapTo(SCN.stack[#SCN.stack-1],swapStyle,...)
        SCN._pop()
    else
        ZENITHA._quit(swapStyle)
    end
end

---Back to a specific scene
---@param tar string
---@param swapStyle? Zenitha.SceneSwapStyle
---@param ... any Arguments passed to target scene
function SCN.backTo(tar,swapStyle,...)
    if SCN.swapping then return end

    -- Poll&Back to previous Scene
    while SCN.stack[#SCN.stack-1]~=tar and #SCN.stack>1 do
        SCN._pop()
    end
    SCN.swapTo(SCN.stack[#SCN.stack],swapStyle,...)
end

---Print current scene stack to console
function SCN.printStack()
    for i=1,#SCN.stack do print(SCN.stack[i]) end
end

function SCN.setDefaultSwap(anim)
    assertf(type(anim)=='string',"SCN.setDefaultSwap(anim): Need string, got %s",anim)
    assertf(swapStyles[anim],"SCN.setDefaultSwap(anim): No swap style '%s'",anim)
    defaultSwap=anim
end

return SCN
