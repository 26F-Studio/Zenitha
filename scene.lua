---@class Zenitha.Scene
---@field widgetList? Map<Zenitha.WidgetArg | Zenitha.Widget.base>
---@field scrollHeight? number
---
---@field load?        fun() | fun(fromScene:string | false, ...)  Called when scene loaded (false when loading first scene)
---@field enter?       fun() | fun(fromScene:string | false, ...) Called when scene swapping finished (false when entering first scene)
---@field leave?       fun() | fun(toScene:string, ...)   Called when scene swapping started
---@field unload?      fun() | fun(toScene:string, ...)  Called when scene unloaded
---@field mouseDown?   fun() | fun(x:number, y:number, k:number, presses:number): boolean? Able to interrupt cursor & widget control
---@field mouseMove?   fun() | fun(x:number, y:number, dx:number, dy:number)
---@field mouseUp?     fun() | fun(x:number, y:number, k:number, presses:number)
---@field mouseClick?  fun() | fun(x:number, y:number, k:number, dist:number, presses:number)
---@field wheelMove?   fun() | fun(dx:number, dy:number): boolean? Able to interrupt WIDGET._scroll
---@field touchDown?   fun() | fun(x:number, y:number, id:userdata, pressure?:number)
---@field touchUp?     fun() | fun(x:number, y:number, id:userdata, pressure?:number)
---@field touchMove?   fun() | fun(x:number, y:number, dx:number, dy:number, id:userdata, pressure?:number)
---@field touchClick?  fun() | fun(x:number, y:number, id:userdata, dist:number)
---@field keyDown?     fun() | fun(key:love.KeyConstant, isRep:boolean, scancode:love.Scancode): boolean? Able to interrupt cursor & widget control
---@field keyUp?       fun() | fun(key:love.KeyConstant, scancode:love.Scancode)
---@field textInput?   fun() | fun(texts:string): boolean? Able to interrupt widget control
---@field imeChange?   fun() | fun(texts:string): boolean? Able to interrupt widget control
---@field gamepadDown? fun() | fun(key:love.GamepadButton)
---@field gamepadUp?   fun() | fun(key:love.GamepadButton)
---@field fileDrop?    fun() | fun(file:love.DroppedFile)
---@field folderDrop?  fun() | fun(path:string)
---@field lowMemory?   fun()
---@field resize?      fun() | fun(width:number, height:number)
---@field focus?       fun() | fun(focus:boolean)
---@field update?      fun() | fun(dt:number)
---@field draw?        fun() Draw below widgets
---@field overDraw?    fun() Draw above widgets

---@class Zenitha.SceneSwap
---@field duration number Total duration
---@field switchTime? number Default to half of duration
---@field init? function
---@field draw fun(time:number) time from 0 to 1

---@type Map<Zenitha.Scene>
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

    'update','draw','overDraw',
}

local SCN={
    mainTouchID=nil, -- First touching ID(userdata)
    maxScroll=0,
    curScroll=0,

    swapping=false, -- If Swapping
    swapState={
        target=false,     -- Swapping target
        swapStyle=false,  -- Swapping style
        draw=false,       -- Swap draw func
        time=false,       -- Swap time (0~1)
        duration=false,   -- Swap time (total)
        transPoint=false, -- Transition time
    },
    stack={}, -- Scene stack
    prev=false,
    cur=false,
    stackChange=0, -- "How many scenes added to (removed from) stack in this swapping", only make sense when swapping (leave-unload-load-enter), will be reset to 0 after `enter` event
    args={}, -- Arguments from previous scene

    scenes=scenes,
}

local defaultSwap='fade'

local function fadeDraw(t)
    GC.setColor(.1,.1,.1,1-(t-.5)*(t-.5)*4)
    GC.rectangle('fill',0,0,SCR.w,SCR.h)
end

---@alias Zenitha.SceneSwapStyle Zenitha._swapStyles | string

---@enum (key) Zenitha._swapStyles
local swapStyles={---@type Map<Zenitha.SceneSwap>
    none={
        duration=0,switchTime=0,
        draw=function() end,
    },
    flash={
        duration=.16,switchTime=.08,
        draw=function() GC.clear(1,1,1) end,
    },
    fade=    {duration=0.5,switchTime=.25,draw=fadeDraw},
    fastFade={duration=0.2,switchTime=0.1,draw=fadeDraw},
    slowFade={duration=3.0,switchTime=1.5,draw=fadeDraw},
    swipeL={
        duration=.5,switchTime=.25,
        draw=function(t)
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            GC.rectangle('fill',(t*t*(2*t-3)*2+1)*SCR.w,0,SCR.w,SCR.h)
        end,
    },
    swipeR={
        duration=.5,switchTime=.25,
        draw=function(t)
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            GC.rectangle('fill',(t*t*(3-2*t)*2-1)*SCR.w,0,SCR.w,SCR.h)
        end,
    },
    swipeU={
        duration=.5,switchTime=.25,
        draw=function(t)
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            GC.rectangle('fill',0,(t*t*(2*t-3)*2+1)*SCR.h,SCR.w,SCR.h)
        end,
    },
    swipeD={
        duration=.5,switchTime=.25,
        draw=function(t)
            GC.setColor(.1,.1,.1,1-math.abs(t-.5))
            GC.rectangle('fill',0,(t*t*(3-2*t)*2-1)*SCR.h,SCR.w,SCR.h)
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
    WIDGET._setupWidgetListMeta(scene.widgetList)

    -- Check each field in scene object
    for k in next,scene do
        if k=='widgetList' then
            assertf(type(scene.widgetList)=='table',"SCN.add: scene[%s].widgetList need table",name)
            for kw,w in next,scene.widgetList do
                assertf(type(w)=='table',"SCN.add: scene[%s].widgetList need list<widgetArgTable | widgetObj>",name)
                if not w._widget then
                    ---@cast w Zenitha.WidgetArg
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
    if swapStyle.switchTime==nil then swapStyle.switchTime=swapStyle.duration/2 end
    assertf(type(swapStyle.switchTime)=='number' and swapStyle.switchTime>=0,"SCN.addSwap(name,swp): swp.switchTime need >=0")
    assertf(swapStyle.init==nil or type(swapStyle.init)=='function',"SCN.addSwap(name,swp): swp.init need function")
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
    local S=SCN.swapState
    dt=math.min(dt/S.duration,1)
    if S.time<=S.transPoint and S.time+dt>S.transPoint then
        -- Actually change scene at this moment
        SCN.prev=SCN.cur

        local scn=scenes[SCN.prev]
        if scn and scn.unload then scn.unload(S.target,unpack(SCN.args)) end
        -- print('unload',SCN.stackChange,S.target)

        SCN._load(S.target)
        ZENITHA.globalEvent.sceneSwap('swap')
    end
    S.time=S.time+dt
    if S.time>1 then
        SCN.swapping=false
        local scn=scenes[SCN.cur]
        if scn.enter then scn.enter(SCN.prev,unpack(SCN.args)) end
        -- print('enter',SCN.stackChange,SCN.prev)
        ZENITHA.globalEvent.sceneSwap('finish')
        SCN.stackChange=0
    end
end

---Load a scene, replace all events and fresh scrolling, widgets
---@param name string
function SCN._load(name)
    SCN.stack[#SCN.stack]=name
    SCN.cur=name

    ZENITHA.keyboard.setTextInput(false)
    SCN.mainTouchID=nil

    local scn=scenes[name]
    SCN.maxScroll=scn.scrollHeight or 0
    SCN.curScroll=0
    WIDGET._setWidgetList(scn.widgetList)
    for i=1,#eventNames do
        SCN[eventNames[i]]=scn[eventNames[i]]
    end

    if scn.load then scn.load(SCN.prev,unpack(SCN.args)) end
    -- print('load',SCN.stackChange,SCN.prev)
end

---Push a scene to stack
---@param tar? string
function SCN._push(tar)
    SCN.stackChange=SCN.stackChange+1
    table.insert(SCN.stack,tar or '_')
end

---Pop a scene from stack
function SCN._pop()
    SCN.stackChange=SCN.stackChange-1
    table.remove(SCN.stack)
end

---Swap to a sceene without add current scene to stack (cannot go back)
---@param tar string
---@param swapStyle? Zenitha.SceneSwapStyle
---@param ... any Arguments passed to new scene
function SCN.swapTo(tar,swapStyle,...)
    if scenes[tar] then
        if not SCN.swapping then
            -- Leave scene
            if SCN.leave then SCN.leave(tar,unpack(SCN.args)) end
            -- print('leave',SCN.stackChange,tar)

            SCN.swapping=true
            SCN.args={...}
            local S=SCN.swapState
            S.target,S.style=tar,swapStyle
            S.time=0

            if not swapStyle then swapStyle=defaultSwap end
            if not swapStyles[swapStyle] then
                MSG.log('warn',"No swap style named '"..swapStyle.."'")
                swapStyle=defaultSwap
            end

            local styleData=swapStyles[swapStyle]
            S.duration=styleData.duration
            S.transPoint=S.duration==0 and 0 or styleData.switchTime/S.duration
            S.draw=styleData.draw
            if styleData.init then styleData.init() end

            ZENITHA.globalEvent.sceneSwap('start',swapStyle)
        end
    else
        MSG('warn',"No Scene: "..tar)
    end
end

---Go to a scene
---@param tar string
---@param swapStyle? Zenitha.SceneSwapStyle
---@param ... any Arguments passed to new scene
function SCN.go(tar,swapStyle,...)
    if scenes[tar] then
        if not SCN.swapping then
            SCN._push()
            SCN.swapTo(tar,swapStyle,...)
        end
    else
        MSG('warn',"No Scene: "..tar)
    end
end

---Back to previous scene
---@param swapStyle? Zenitha.SceneSwapStyle
---@param ... any Arguments passed to previous scene
function SCN.back(swapStyle,...)
    if SCN.swapping then return end

    local m=#SCN.stack
    if m>1 then
        SCN._pop()
        -- Poll&Back to previous Scene
        SCN.swapTo(SCN.stack[#SCN.stack],swapStyle,...)
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
