if not love.graphics then
    print("TEXT lib is not loaded (need love.graphics)")
    return {
        clear=NULL,
        add=NULL,
        update=NULL,
        draw=NULL,
        new=NULL,
    }
end

---@class Zenitha.TextAnimArg
---@field text? string
---@field x? number
---@field y? number
---@field k? number
---@field kx? number
---@field ky? number
---@field align? Zenitha.TextAlignMode|{[1]:number, [2]:number}
---@field r? number
---@field g? number
---@field b? number
---@field a? number
---@field color? number[]|Zenitha.ColorStr
---@field fontSize? number
---@field fontType? string|nil
---@field duration? number
---@field inPoint? number
---@field outPoint? number
---@field style? Zenitha.TextAnimStyle
---@field styleArg? any

local setColor=GC.setColor
local draw=GC.draw

local floor,rnd=math.floor,math.random
local max,min=math.max,math.min
local ins,rem=table.insert,table.remove

---@enum (key) Zenitha.TextAnimStyle
local textFX={
appear=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        T.kx,T.ky,
        T._ox,T._oy
    )
end,
fly=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x+(T._t-.5)^3*(T.arg or 300),T.y,
        nil,
        T.kx,T.ky,
        T._ox,T._oy
    )
end,
stretch=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        (max(1-T._t/T.inPoint,0)*(T.arg or 1)+1)*T.kx,T.ky,
        T._ox,T._oy
    )
end,
drive=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        T.kx,T.ky,
        T._ox,T._oy,
        (max(1-T._t/T.inPoint,0)*(T.driveX or 2)) or 0,0
    )
end,
spin=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        (max(1-T._t/T.inPoint,0)^2-max(1-(1-T._t)/T.outPoint,0)^2)*(T.arg or .4),
        T.kx,T.ky,
        T._ox,T._oy
    )
end,
flicker=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1)*rnd())
    draw(
        T.text,T.x,T.y,
        nil,
        T.kx,T.ky,
        T._ox,T._oy
    )
end,
zoomout=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    local k=T._t^.5*(T.arg or .1)+1
    draw(
        T.text,T.x,T.y,
        nil,
        k*T.kx,k*T.ky,
        T._ox,T._oy
    )
end,
beat=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    local k=1+(T.arg or .5)*max(1-T._t/T.inPoint,0)^.6
    draw(
        T.text,T.x,T.y,
        nil,
        k*T.kx,k*T.ky,
        T._ox,T._oy
    )
end,
score=function(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y-0-T._t^.2*(T.arg or 30),
        nil,
        T.kx,T.ky,
        T._ox,T._oy
    )
end,
}

---@class Zenitha.Text
local TEXT={_texts={}}

---Clear text container
function TEXT:clear()
    self._texts={}
end

---@enum (key) Zenitha.TextAlignMode
local alignModes={
    left={0,.5},
    right={1,.5},
    top={.5,0},
    bottom={.5,1},
    center={.5,.5},
    topleft={0,0},
    topright={1,0},
    bottomleft={0,1},
    bottomright={1,1},
}
---Add text to container
---@param data Zenitha.TextAnimArg
---## Example
---```lua
---default={
---    text="Example Text",
---    x=0,y=0,
---    align={.5,.5},
---    r=1,g=1,b=1,a=1,
---    fontSize=40,
---    fontType=nil,
---
---    style='appear', -- Check declaration to learn more
---    duration=1,
---    inPoint=0.2,
---    outPoint=0.2,
---    styleArg=...,
---}
---```
function TEXT:add(data)
    local T={
        text=GC.newText(FONT.get(floor((data.fontSize or 40)/5)*5,data.fontType),data.text or "Example Text"),
        x=data.x or 0,y=data.y or 0,
        kx=data.k or data.kx or 1,ky=data.k or data.ky or data.kx or 1,
        align=alignModes[data.align] or data.align or alignModes.center,
        r=data.r,g=data.g,b=data.b,a=data.a,
        duration=data.duration or 1,
        inPoint=data.inPoint or 0.2,
        outPoint=data.outPoint or 0.2,

        draw=assertf(textFX[data.style or 'appear'],"No text type: %s",data.style),
        arg=data.styleArg,
    }
    assert(type(T.align)=='table',"Text.add: field align need string or {u,v}")
    T._t=0 -- Timer
    T._ox,T._oy=T.text:getWidth()*T.align[1],T.text:getHeight()*T.align[2]
    if type(data.color)=='string' then data.color=COLOR[data.color] end
    if data.color then T.r,T.g,T.b,T.a=data.color[1],data.color[2],data.color[3],data.color[4] end
    T.r=T.r or 1
    T.g=T.g or 1
    T.b=T.b or 1
    T.a=T.a or 1
    ins(self._texts,T)
end

---Update text container
---@param dt number
function TEXT:update(dt)
    local list=self._texts
    for i=#list,1,-1 do
        local T=list[i]
        T._t=T._t+dt/T.duration
        if T._t>1 then
            rem(list,i)
        end
    end
end

---Draw text container
function TEXT:draw()
    local list=self._texts
    for i=1,#list do list[i]:draw() end
end

---Create new text container
---@return Zenitha.Text
function TEXT.new()
    return setmetatable({_texts={}},{__index=TEXT})
end
return TEXT
