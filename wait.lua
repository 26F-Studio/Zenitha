if not love.graphics then
    LOG('debug',"WAIT lib is not loaded (need love.graphics)")
    return {
        _update=NULL,
        _draw=NULL,
    }
end

---@class Zenitha.WaitEvent
---@field init?            function
---@field update?          function
---@field quit?            function
---@field draw?            function
---@field timeout?         number
---@field escapable?       boolean
---@field coverAlpha?      number
---@field noDefaultInit?   boolean
---@field noDefaultUpdate? boolean
---@field noDefaultDraw?   boolean
---@field noDefaultQuit?   boolean

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

---Start a new Wait Modal
---@param args Zenitha.WaitEvent
function WAIT.new(args)
    if WAIT.state then return end

    assert(type(args)=='table',"WAIT.new(args): Need waitArgTable")
    assert(args.init==nil            or type(args.init)            =='function',"WAIT.new: args.enter need function")
    assert(args.update==nil          or type(args.update)          =='function',"WAIT.new: args.update need function")
    assert(args.quit==nil            or type(args.quit)            =='function',"WAIT.new: args.leave need function")
    assert(args.draw==nil            or type(args.draw)            =='function',"WAIT.new: args.draw need function")
    assert(args.timeout==nil         or type(args.timeout)         =='number',  "WAIT.new: args.timeout need number")
    assert(args.escapable==nil       or type(args.escapable)       =='boolean', "WAIT.new: args.escapable need boolean")
    assert(args.coverAlpha==nil      or type(args.coverAlpha)      =='number',  "WAIT.new: args.coverAlpha need number")
    assert(args.noDefaultInit==nil   or type(args.noDefaultInit)   =='boolean', "WAIT.new: args.noDefaultInit need boolean")
    assert(args.noDefaultUpdate==nil or type(args.noDefaultUpdate) =='boolean', "WAIT.new: args.noDefaultUpdate need boolean")
    assert(args.noDefaultDraw==nil   or type(args.noDefaultDraw)   =='boolean', "WAIT.new: args.noDefaultDraw need boolean")
    assert(args.noDefaultQuit==nil   or type(args.noDefaultQuit)   =='boolean', "WAIT.new: args.noDefaultQuit need boolean")
    if not args.noDefaultInit then WAIT.defaultInit() end
    if args.init then args.init() end

    WAIT.arg=args
    WAIT.state='enter'
    WAIT.timer=0
    WAIT.totalTimer=0
end

---Interrupt the current
function WAIT.interrupt()
    if WAIT.state and WAIT.state~='leave' then
        WAIT.state='leave'
        WAIT.timer=WAIT.leaveTime*WAIT.timer/WAIT.enterTime
    end
end

---Update Wait Modal (called by Zenitha)
---@param dt number
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

---Draw Wait Modal (called by Zenitha)
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

---Set the time of entering animation
---@param t number
function WAIT.setEnterTime(t)
    assert(type(t)=='number' and t>0,"WAIT.setEnterTime(t): Need >0")
    WAIT.enterTime=t
end

---Set the time of leaving animation
---@param t number
function WAIT.setLeaveTime(t)
    assert(type(t)=='number' and t>0,"WAIT.setLeaveTime(t): Need >0")
    WAIT.leaveTime=t
end

---Set the time of timeout
---@param t number
function WAIT.setTimeout(t)
    assert(type(t)=='number' and t>0,"WAIT.setTimeout(t): Need >0")
    WAIT.timeout=t
end

---Set the color of background cover
---@param r number
---@param g number
---@param b number
---@overload fun(color:{r:number, g:number, b:number})
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
        error("WAIT.setCoverColor(r,g,b): Need r,g,b or {r,g,b} in [0,1]")
    end
end

---Set the alpha of background cover
---@param alpha number
function WAIT.setCoverAlpha(alpha)
    assert(type(alpha)=='number' and alpha>=0 and alpha<=1,"WAIT.setCoverAlpha(alpha): Need in [0,1]")
    WAIT.coverAlpha=alpha
end

---Set the default init function
---@param func function
function WAIT.setDefaultInit(func)
    assert(type(func)=='function',"WAIT.setDefaultInit(func): Need function")
    WAIT.defaultInit=func
end

---Set the default update function
---@param func function
function WAIT.setDefaultUpdate(func)
    assert(type(func)=='function',"WAIT.setDefaultUpdate(func): Need function")
    WAIT.defaultUpdate=func
end

---Set the default draw function
---@param func function
function WAIT.setDefaultDraw(func)
    assert(type(func)=='function',"WAIT.setDefaultDraw(func): Need function")
    defaultDraw=func
end

---Set the default quit function
---@param func function
function WAIT.setDefaultQuit(func)
    assert(type(func)=='function',"WAIT.setDefaultQuit(func): Need function")
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
