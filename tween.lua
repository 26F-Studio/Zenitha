---@alias Zenitha.Tween.Tag string

local preAnimSet={} ---@type Set<Zenitha.Tween> new Animation created during _update will be added here first, then moved to updAnimSet
local updAnimSet={} ---@type Set<Zenitha.Tween>
local tagAnimSet={} ---@type Set<Zenitha.Tween>
local unqAnimMap={} ---@type Map<Zenitha.Tween>

local min,floor=math.min,math.floor
local sin,cos=math.sin,math.cos
local clamp=MATH.clamp

---@enum (key) Zenitha.Tween.basicCurve
local curves={
    linear=function(t) return t end,
    inSin=function(t) return 1-cos(t*1.5707963267948966) end,
    outSin=function(t) return sin(t*1.5707963267948966) end,
    inQuad=function(t) return t^2 end,
    outQuad=function(t) return 1-(1-t)^2 end,
    inCubic=function(t) return t^3 end,
    outCubic=function(t) return 1-(1-t)^3 end,
    inQuart=function(t) return t^4 end,
    outQuart=function(t) return 1-(1-t)^4 end,
    inQuint=function(t) return t^5 end,
    outQuint=function(t) return 1-(1-t)^5 end,
    inExp=function(t) return 2^(10*(t-1)) end,
    outExp=function(t) return 1-2^(-10*t) end,
    inCirc=function(t) return 1-(1-t^2)^.5 end,
    outCirc=function(t) return (1-(t-1)^2)^.5 end,
    inBack=function(t) return t^2*(2.70158*t-1.70158) end,
    inElastic=function(t) return -2^(10*(t-1))*sin((10*t-10.75)*2.0943951023931953) end,
    outBack=nil,
    outElastic=nil,
}
curves.outBack=function(t) return 1-curves.inBack(1-t) end
curves.outElastic=function(t) return 1-curves.inElastic(1-t) end

---@enum (key) Zenitha.Tween.easeTemplate
local easeTemplates={
    Linear={'linear'},
    InSin={'inSin'},
    OutSin={'outSin'},
    InOutSin={'inSin','outSin'},
    OutInSin={'outSin','inSin'},
    InQuad={'inQuad'},
    OutQuad={'outQuad'},
    InOutQuad={'inQuad','outQuad'},
    OutInQuad={'outQuad','inQuad'},
    InCubic={'inCubic'},
    OutCubic={'outCubic'},
    InOutCubic={'inCubic','outCubic'},
    OutInCubic={'outCubic','inCubic'},
    InQuart={'inQuart'},
    OutQuart={'outQuart'},
    InOutQuart={'inQuart','outQuart'},
    OutInQuart={'outQuart','inQuart'},
    InQuint={'inQuint'},
    OutQuint={'outQuint'},
    InOutQuint={'inQuint','outQuint'},
    OutInQuint={'outQuint','inQuint'},
    InExp={'inExp'},
    OutExp={'outExp'},
    InOutExp={'inExp','outExp'},
    OutInExp={'outExp','inExp'},
    InCirc={'inCirc'},
    OutCirc={'outCirc'},
    InOutCirc={'inCirc','outCirc'},
    OutInCirc={'outCirc','inCirc'},
    InBack={'inBack'},
    OutBack={'outBack'},
    InOutBack={'inBack','outBack'},
    OutInBack={'outBack','inBack'},
    InElastic={'inElastic'},
    OutElastic={'outElastic'},
    InOutElastic={'inElastic','outElastic'},
    OutInElastic={'outElastic','inElastic'},
}

--------------------------------------------------------------
-- Tween Class

---@class Zenitha.Tween
---@field running boolean
---@field duration number default to 1
---@field time number used when no timeFunc
---@field loop false|'repeat'|'yoyo'
---@field loopCount number current loop number (start from 1)
---@field totalLoop number the total number of times to loop
---@field flipMode boolean true when loop is `'yoyo'`, making time flow back and forth
---@field ease Zenitha.Tween.basicCurve[]
---@field tags Set<Zenitha.Tween.Tag>
---@field unqTag Zenitha.Tween.Tag
---@field private doFunc fun(t:number, loopNo:number)
---@field private timeFunc? fun():number custom how time goes
---@field private onRepeat fun(loopNo:number)
---@field private onFinish function
---@field private onKill function
local Tween={}

Tween.__index=Tween

local duringUpdate=false -- During update, new [tween]:run() will be added to preAnimSet first to prevent undefined behavior of table iterating

---Set doFunc (generally unnecessary, already set when creating)
---@param doFunc fun(t:number)
---@return Zenitha.Tween
function Tween:setDo(doFunc)
    assert(type(doFunc)=='function',"[tween]:setDo(doFunc): Need function")
    self.doFunc=doFunc
    return self
end

---Set onRepeat callback function `onRepeat(finishedLoopCount)`
---@param func function
---@return Zenitha.Tween
function Tween:setOnRepeat(func)
    assert(type(func)=='function',"[tween]:setOnRepeat(onRepeat): Need function")
    -- assert(not self.running,"[tween]:setOnRepeat(func): Can't set OnRepeat when running")
    self.onRepeat=func
    return self
end

---Set onFinish callback function
---@param func function
---@return Zenitha.Tween
function Tween:setOnFinish(func)
    assert(type(func)=='function',"[tween]:setOnFinish(onFinish): Need function")
    -- assert(not self.running,"[tween]:setOnFinish(func): Can't set OnFinish when running")
    self.onFinish=func
    return self
end

---Set onFinish callback function
---@param func function
---@return Zenitha.Tween
function Tween:setOnKill(func)
    assert(type(func)=='function',"[tween]:setOnKill(onKill): Need function")
    -- assert(not self.running,"[tween]:setOnKill(func): Can't set OnKill when running")
    self.onKill=func
    return self
end

---Set easing mode
---@param ease? Zenitha.Tween.easeTemplate|Zenitha.Tween.basicCurve[] default to 'InOutSin'
---@return Zenitha.Tween
function Tween:setEase(ease)
    -- assert(not self.running,"[tween]:setEase(ease): Can't set ease when running")
    if type(ease)=='string' then
        assertf(easeTemplates[ease],"[tween]:setEase(ease): Invalid ease name '%s'",ease)
        self.ease=easeTemplates[ease]
    elseif type(ease)=='table' then
        for i=1,#ease do
            assertf(curves[ease[i]],"[tween]:setEase(ease): Invalid ease curve name '%s'",ease[i])
        end
        self.ease=ease
    else
        error("[tween]:setEase(ease): Need string|table")
    end
    return self
end

---Set duration
---@param duration? number
---@return Zenitha.Tween
function Tween:setDuration(duration)
    assert(type(duration)=='number' and duration>=0,"[tween]:setDuration(duration): Need >=0")
    -- assert(not self.running,"[tween]:setDuration(duration): Can't set duration when running")
    self.duration=duration
    return self
end

---Set Looping
---@param loopMode false|'repeat'|'yoyo'
---@param totalLoop? number default to Infinity
---@return Zenitha.Tween
function Tween:setLoop(loopMode,totalLoop)
    assert(not self.timeFunc,"[tween]:setLoop(loopMode): Looping and timeFunc can't exist together")
    assert(not loopMode or loopMode=='repeat' or loopMode=='yoyo',"[tween]:setLoop(loopMode): Need false|'repeat'|'yoyo'")
    assert(not totalLoop or type(totalLoop)=='number' and totalLoop>=0,"[tween]:setLoop(loopMode,totalLoop): totalLoop need >=0")
    -- assert(not self.running,"[tween]:setLoop(loopMode): Can't set loop when running")
    self.loop=loopMode
    self.loopCount=1
    self.totalLoop=totalLoop or 1e99
    self.flipMode=false
    return self
end

---Set tag for batch actions
---@param tag Zenitha.Tween.Tag
---@return Zenitha.Tween
function Tween:setTag(tag)
    assert(type(tag)=='string',"[tween]:setTag(tag): Need string")
    tagAnimSet[self]=true
    self.tags[tag]=true
    return self
end

---Set uniqueID (when start running, other active animations with same uniqueID will be killed)
---@param uniqueTag Zenitha.Tween.Tag
---@return Zenitha.Tween
function Tween:setUnique(uniqueTag)
    assert(type(uniqueTag)=='string',"[tween]:setUnique(uniqueTag): Need string")
    self.unqTag=uniqueTag
    return self
end

---Copy an animation ojbect (idk what this is for)
---@return Zenitha.Tween
function Tween:copy()
    local anim=TWEEN.new()
    TABLE.update(anim,self,2)
    return anim
end

---Start the animation animate with time (again), or custom timeFunc
---
---Warning: you still have full access to animation after [tween]:run(), but don't touch it unless you know what you're doing
---@param timeFunc? fun():number Custom the timeFunc (return a number in duration)
function Tween:run(timeFunc)
    if self.running then return end
    assert(timeFunc==nil or type(timeFunc)=='function',"[tween]:run(timeFunc): Need function if exists")
    assert(not (self.loop and timeFunc),"[tween]:run(timeFunc): Looping and timeFunc can't exist together")
    if self.unqTag then
        if unqAnimMap[self.unqTag] then
            local a=unqAnimMap[self.unqTag]
            a:kill()
        end
        unqAnimMap[self.unqTag]=self
    end
    if timeFunc then
        self.timeFunc=timeFunc
    else
        self.time=0
    end
    self:update(0);
    (duringUpdate and preAnimSet or updAnimSet)[self]=true
end

---Finish instantly (cannot apply to animation with timeFunc)
---@param simBound? boolean simulate all bound case for animation with loop
---@return Zenitha.Tween
function Tween:skip(simBound)
    assert(not self.timeFunc,"[tween]:skip(): Can't skip an animation with timeFunc")
    if not self.loop then
        self.time=self.duration
        self:update(0)
    else
        if simBound then
        else
            if self.loop=='repeat' then
                self.time=self.duration
                self.loopCount=self.totalLoop
                self:update(0)
            elseif self.loop=='yoyo' then
                self.time=self.duration
                self.flipMode=self.loopCount%2==1==self.flipMode
                self.loopCount=self.totalLoop
                self:update(0)
            end
        end
    end
    return self
end

---Release animation from auto updating list and tag list
function Tween:kill()
    preAnimSet[self]=nil
    updAnimSet[self]=nil
    tagAnimSet[self]=nil
    if self.unqTag then unqAnimMap[self.unqTag]=nil end
    self.onKill()
end

---@param t number
---@param ease function[]
---@return number
local function curveValue(t,ease)
    local step=#ease
    local n=min(floor(t*step),step-1)
    local base=n/step
    local curve=curves[ease[n+1]]
    return base+curve((t-base)*step)/step
end

---Update the animation
function Tween:update(dt)
    self.running=true
    if self.timeFunc then
        local t=self.timeFunc()
        if t then
            self.doFunc(curveValue(clamp(self.flipMode and 1-t or t,0,1),self.ease),self.loopCount)
        else
            self.onFinish()
            self:kill()
        end
    else
        self.time=self.time+dt
        local t=min(self.time/self.duration,1)
        self.doFunc(curveValue(self.flipMode and 1-t or t,self.ease),self.loopCount)
        if t>=1 then
            if self.loop and self.loopCount<self.totalLoop then
                self.time=0
                self.onRepeat(self.loopCount)
                self.loopCount=self.loopCount+1
                if self.loop=='yoyo' then
                    self.flipMode=not self.flipMode
                end
            else
                self.onFinish()
                self:kill()
            end
        end
    end
end

--------------------------------------------------------------
-- Module

local TWEEN={}

---Create a new tween animation
---@param doFunc? fun(t:number, loopNo:number)
---@return Zenitha.Tween
function TWEEN.new(doFunc)
    assert(doFunc==nil or type(doFunc)=='function',"TWEEN.new(doFunc): Need function")
    local anim=setmetatable({
        running=false,
        duration=1,
        doFunc=doFunc or NULL,
        ease=easeTemplates.InOutQuad,
        tags={},
        unqTag=nil,
        onRepeat=NULL,
        onFinish=NULL,
        onKill=NULL,
    },Tween)
    return anim
end

---Update all autoAnims (called by Zenitha)
---@param dt number
function TWEEN._update(dt)
    duringUpdate=true
    for anim in next,updAnimSet do
        anim:update(dt)
    end
    for anim in next,preAnimSet do
        preAnimSet[anim]=nil
        updAnimSet[anim]=true
    end
    duringUpdate=false
end

---@param tag Zenitha.Tween.Tag
---@param method 'setEase'|'setTime'|'pause'|'continue'|'skip'|'kill'|'update'
local function tagAction(tag,method,...)
    assert(type(tag)=='string',"TWEEN.tag_"..method..": tag need string")
    for anim in next,tagAnimSet do
        if anim.tags[tag] then
            Tween[method](anim,...)
        end
    end
end

---Finish tagged animations instantly
---@param tag Zenitha.Tween.Tag
function TWEEN.tag_skip(tag)
    tagAction(tag,'skip')
end

---Kill tagged animations
---@param tag Zenitha.Tween.Tag
function TWEEN.tag_kill(tag)
    tagAction(tag,'kill')
end

---Update tagged animations
---@param tag Zenitha.Tween.Tag
---@param dt number
function TWEEN.tag_update(tag,dt)
    tagAction(tag,'update',dt)
end

return TWEEN
