local WAIT={
    state=false,
    timer=false,
    totalTimer=false,

    enterTime=.2,
    leaveTime=.2,
    timeout=6,
    coverColor={.1,.1,.1},
    coverAlpha=.6,

    defaultInit=NULL,
    defaultUpdate=NULL,
    defaultDraw=NULL,
    defaultQuit=NULL,

    arg=false,
}

local arcAlpha={1,.6,.4,.3}
local defaultDraw=function(a,t)
    GC.setLineWidth(SCR.h/26)
    t=t*2.6
    for i=1,4 do
        GC.setColor(1,1,1,a*arcAlpha[i])
        GC.arc('line','open',SCR.w/2,SCR.h/2,SCR.h/5,t+MATH.tau*(i/4),t+MATH.tau*((i+1)/4))
    end
end

--- @class Zenitha.waitObj
--- @field init?            function
--- @field update?          function
--- @field quit?            function
--- @field draw?            function
--- @field timeout?         number
--- @field escapable?       boolean
--- @field coverAlpha?      number
--- @field noDefaultInit?   boolean
--- @field noDefaultUpdate? boolean
--- @field noDefaultDraw?   boolean
--- @field noDefaultQuit?   boolean

--- Start a new Wait Modal
--- @param data Zenitha.waitObj
function WAIT.new(data)
    if WAIT.state then return end

    assert(type(data)=='table',"arg must be table")
    assert(data.init==nil            or type(data.init)            =='function',"Field 'enter' must be function")
    assert(data.update==nil          or type(data.update)          =='function',"Field 'update' must be function")
    assert(data.quit==nil            or type(data.quit)            =='function',"Field 'leave' must be function")
    assert(data.draw==nil            or type(data.draw)            =='function',"Field 'draw' must be function")
    assert(data.timeout==nil         or type(data.timeout)         =='number',  "Field 'timeout' must be number")
    assert(data.escapable==nil       or type(data.escapable)       =='boolean', "Field 'escapable' must be boolean")
    assert(data.coverAlpha==nil      or type(data.coverAlpha)      =='number',  "Field 'coverAlpha' must be number")
    assert(data.noDefaultInit==nil   or type(data.noDefaultInit)   =='boolean', "Field 'noDefaultInit' must be boolean")
    assert(data.noDefaultUpdate==nil or type(data.noDefaultUpdate) =='boolean', "Field 'noDefaultUpdate' must be boolean")
    assert(data.noDefaultDraw==nil   or type(data.noDefaultDraw)   =='boolean', "Field 'noDefaultDraw' must be boolean")
    assert(data.noDefaultQuit==nil   or type(data.noDefaultQuit)   =='boolean', "Field 'noDefaultQuit' must be boolean")
    if not data.noDefaultInit then WAIT.defaultInit() end
    if data.init then data.init() end

    WAIT.arg=data
    WAIT.state='enter'
    WAIT.timer=0
    WAIT.totalTimer=0
end

--- Interrupt the current
function WAIT.interrupt()
    if WAIT.state and WAIT.state~='leave' then
        WAIT.state='leave'
        WAIT.timer=WAIT.leaveTime*WAIT.timer/WAIT.enterTime
    end
end

--- Update Wait Modal (called by Zenitha)
--- @param dt number
function WAIT._update(dt)
    if WAIT.state then
        WAIT.totalTimer=WAIT.totalTimer+dt
        if not WAIT.arg.noDefaultUpdate then WAIT.defaultUpdate(dt,WAIT.totalTimer) end
        if WAIT.arg.update then WAIT.arg.update(dt,WAIT.totalTimer) end

        if WAIT.state~='leave' and WAIT.totalTimer>=(WAIT.arg.timeout or WAIT.timeout) then
            WAIT.interrupt()
        end

        if WAIT.state=='enter' then
            WAIT.timer=math.min(WAIT.timer+dt,WAIT.enterTime)
            if WAIT.timer>=WAIT.enterTime then WAIT.state='wait' end
        elseif WAIT.state=='leave' then
            WAIT.timer=WAIT.timer-dt
            if WAIT.timer<=0 then
                WAIT.state=false
                if not WAIT.arg.noDefaultQuit then WAIT.defaultQuit() end
                if WAIT.arg.quit then WAIT.arg.quit() end
            end
        end
    end
end

--- Draw Wait Modal (called by Zenitha)
function WAIT._draw()
    if WAIT.state then
        local alpha=(
            WAIT.state=='enter' and WAIT.timer/WAIT.enterTime or
            WAIT.state=='wait' and 1 or
            WAIT.state=='leave' and WAIT.timer/WAIT.leaveTime
        )
        if (WAIT.arg.coverAlpha or WAIT.coverAlpha)>0 then
            GC.setColor(
                WAIT.coverColor[1],
                WAIT.coverColor[2],
                WAIT.coverColor[3],
                alpha*(WAIT.arg.coverAlpha or WAIT.coverAlpha)
            )
            GC.rectangle('fill',0,0,SCR.w,SCR.h)
        end

        if not WAIT.arg.noDefaultDraw then defaultDraw(alpha,WAIT.totalTimer) end
        if WAIT.arg.draw then WAIT.arg.draw(alpha,WAIT.totalTimer) end
    end
end

--- Set the time of entering animation
--- @param t number
function WAIT.setEnterTime(t)
    assert(type(t)=='number' and t>0,"Arg must be number larger then 0")
    WAIT.enterTime=t
end

--- Set the time of leaving animation
--- @param t number
function WAIT.setLeaveTime(t)
    assert(type(t)=='number' and t>0,"Arg must be number larger then 0")
    WAIT.leaveTime=t
end

--- Set the time of timeout
--- @param t number
function WAIT.setTimeout(t)
    assert(type(t)=='number' and t>0,"Arg must be number larger then 0")
    WAIT.timeout=t
end

--- Set the color of background cover
--- @param r number
--- @param g number
--- @param b number
function WAIT.setCoverColor(r,g,b)
    if type(r)=='table' then
        r,g,b=r[1],r[2],r[3]
    end
    if
        type(r)=='number' and r>=0 and r<=1 and
        type(g)=='number' and g>=0 and g<=1 and
        type(b)=='number' and b>=0 and b<=1
    then
        WAIT.coverColor[1],WAIT.coverColor[2],WAIT.coverColor[3]=r,g,b
    else
        error("Arg must be r,g,b or {r,g,b} and all between 0~1")
    end
end

--- Set the alpha of background cover
--- @param alpha number
function WAIT.setCoverAlpha(alpha)
    assert(type(alpha)=='number' and alpha>=0 and alpha<=1,"Alpha must be number between 0~1")
    WAIT.coverAlpha=alpha
end

--- Set the default init function
--- @param func function
function WAIT.setDefaultInit(func)
    assert(type(func)=='function',"func must be function")
    WAIT.defaultInit=func
end

--- Set the default update function
--- @param func function
function WAIT.setDefaultUpdate(func)
    assert(type(func)=='function',"func must be function")
    WAIT.defaultUpdate=func
end

--- Set the default draw function
--- @param func function
function WAIT.setDefaultDraw(func)
    assert(type(func)=='function',"func must be function")
    defaultDraw=func
end

--- Set the default quit function
--- @param func function
function WAIT.setDefaultQuit(func)
    assert(type(func)=='function',"func must be function")
    WAIT.defaultQuit=func
end

-- Allow simply calling WAIT(arg) to create a new Wait Modal
setmetatable(WAIT,{
    __call=function(self,data)
        self.new(data)
    end,
    __metatable=true,
})

return WAIT
