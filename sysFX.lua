if not love.graphics then
    LOG("SYSFS lib is not loaded (need love.graphics)")
    return setmetatable({},{
        __index=function(t,k)
            t[k]=NULL
            return t[k]
        end,
    })
end

---@alias Zenitha.SYSFXType
---| 'line' Fading Line
---| 'rect' Fading Rectangle
---| 'ripple' Fading Expanding Circle
---| 'rectRipple' Fading Expanding Rectangle
---| 'tap' Shirnking Transparent Circle
---| 'glow' Fading Gradient Circle
---| 'beam' Animated Line
---| 'particle' Simple Particle System

local gc_setColor,gc_setLineWidth=GC.setColor,GC.setLineWidth
local gc_draw,gc_line=GC.draw,GC.line
local gc_rectangle,gc_circle=GC.rectangle,GC.circle

local max,min=math.max,math.min
local ins,rem=table.insert,table.remove
local cos=math.cos

local FXlist={}
local SYSFX={}

-------------------------------------------------------------
-- FX Classes

local FX={}

---@class Zenitha.SysFX.baseFX
---@field t number [0,1] Animation progress
---@field rate number Animation time scale
---@field r number
---@field g number
---@field b number
---@field a number
local baseFX={
    t=0,
    rate=1,
    r=1,g=1,b=1,a=1,
}
function baseFX.update(self,dt)
    self.t=self.t+dt*self.rate
    return self.t>1
end
function baseFX.draw()
    -- Do nothing
end

---@class Zenitha.SysFX.line: Zenitha.SysFX.baseFX
---@field x1 number
---@field y1 number
---@field x2 number
---@field y2 number
---@field wid number
FX.line={}
function FX.line:draw()
    gc_setColor(self.r,self.g,self.b,self.a*(1-self.t))
    gc_setLineWidth(self.wid)
    gc_line(self.x1,self.y1,self.x2,self.y2)
end
function SYSFX.line(duration,x1,y1,x2,y2,wid,r,g,b,a)
    ins(FXlist,setmetatable({
        rate=1/duration,
        x1=x1,y1=y1,
        x2=x2,y2=y2,
        wid=wid or 2,
        r=r,g=g,b=b,a=a,
    },{__index=FX.line,__metatable=true}))
end

---@class Zenitha.SysFX.rect: Zenitha.SysFX.baseFX
---@field x number
---@field y number
---@field w number
---@field h number
FX.rect={}
function FX.rect:draw()
    gc_setColor(self.r,self.g,self.b,self.a*(1-self.t))
    gc_rectangle('fill',self.x,self.y,self.w,self.h,2)
end
function SYSFX.rect(duration,x,y,w,h,r,g,b,a)
    ins(FXlist,setmetatable({
        rate=1/duration,
        x=x,y=y,w=w,h=h or w,
        r=r,g=g,b=b,a=a,
    },{__index=FX.rect,__metatable=true}))
end

---@class Zenitha.SysFX.ripple: Zenitha.SysFX.baseFX
---@field x number
---@field y number
---@field radius number
FX.ripple={}
function FX.ripple:draw()
    gc_setLineWidth(2)
    gc_setColor(self.r,self.g,self.b,self.a*(1-self.t))
    gc_circle('line',self.x,self.y,self.t*(2-self.t)*self.radius)
end
function SYSFX.ripple(duration,x,y,radius,r,g,b,a)
    ins(FXlist,setmetatable({
        rate=1/duration,
        x=x,y=y,radius=radius,
        r=r,g=g,b=b,a=a,
    },{__index=FX.ripple,__metatable=true}))
end

---@class Zenitha.SysFX.rectRipple: Zenitha.SysFX.baseFX
---@field x number
---@field y number
---@field w number
---@field h number
FX.rectRipple={}
function FX.rectRipple:draw()
    gc_setLineWidth(6)
    gc_setColor(self.r,self.g,self.b,self.a*(1-self.t))
    local r=(10*self.t)^1.2
    gc_rectangle('line',self.x-r,self.y-r,self.w+2*r,self.h+2*r)
end
function SYSFX.rectRipple(duration,x,y,w,h,r,g,b,a)
    ins(FXlist,setmetatable({
        rate=1/duration,
        x=x,y=y,w=w,h=h,
        r=r,g=g,b=b,a=a,
    },{__index=FX.rectRipple,__metatable=true}))
end

---@class Zenitha.SysFX.tap: Zenitha.SysFX.baseFX
---@field x number
---@field y number
FX.tap={
    a=.4,
}
function FX.tap:draw()
    gc_setColor(self.r,self.g,self.b,self.a*(1-self.t))
    gc_circle('fill',self.x,self.y,30*(1-self.t)^.5)
end
function SYSFX.tap(duration,x,y,radius,r,g,b,a)
    ins(FXlist,setmetatable({
        rate=1/duration,
        x=x,y=y,radius=radius,
        r=r,g=g,b=b,a=a,
    },{__index=FX.tap,__metatable=true}))
end

---@class Zenitha.SysFX.glow: Zenitha.SysFX.baseFX
---@field x number
---@field y number
---@field radius number
FX.glow={}
function FX.glow:draw()
    gc_setLineWidth(2)
    for i=1,self.radius,2 do
        gc_setColor(1,1,1,(1-self.t)*cos((i-1)/self.radius*1.5708))
        gc_circle('line',self.x,self.y,i)
    end
end
function SYSFX.glow(duration,x,y,radius,r,g,b,a)
    ins(FXlist,setmetatable({
        rate=1/duration,
        x=x,y=y,radius=radius or 10,
        r=r,g=g,b=b,a=a,
    },{__index=FX.glow,__metatable=true}))
end

---@class Zenitha.SysFX.beam: Zenitha.SysFX.line
FX.beam={}
function FX.beam:draw()
    gc_setColor(self.r*2,self.g*2,self.b*2,self.a*min(4-self.t*4,1))

    gc_setLineWidth(self.wid)
    local t1,t2=max(5*self.t-4,0),min(self.t*4,1)
    gc_line(
        self.x1*(1-t1)+self.x2*t1,
        self.y1*(1-t1)+self.y2*t1,
        self.x1*(1-t2)+self.x2*t2,
        self.y1*(1-t2)+self.y2*t2
    )

    gc_setLineWidth(self.wid*.6)
    t1,t2=max(4*self.t-3,0),min(self.t*5,1)
    gc_line(
        self.x1*(1-t1)+self.x2*t1,
        self.y1*(1-t1)+self.y2*t1,
        self.x1*(1-t2)+self.x2*t2,
        self.y1*(1-t2)+self.y2*t2
    )
end
function SYSFX.beam(duration,x1,y1,x2,y2,wid,r,g,b,a)
    ins(FXlist,setmetatable({
        rate=1/duration,
        x1=x1,y1=y1,
        x2=x2,y2=y2,
        wid=wid or 6,
        r=r,g=g,b=b,a=a,
    },{__index=FX.beam,__metatable=true}))
end

---@class Zenitha.SysFX.particle: Zenitha.SysFX.baseFX
---@field image love.Drawable
---@field size number
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field ax number
---@field ay number
---@field private cx number
---@field private cy number
FX.particle={}
function FX.particle:update(dt)
    if self.vx then
        self.x=self.x+self.vx*self.rate
        self.y=self.y+self.vy*self.rate
        if self.ax then
            self.vx=self.vx+self.ax*self.rate
            self.vy=self.vy+self.ay*self.rate
        end
    end
    return baseFX.update(self,dt)
end
function FX.particle:draw()
    gc_setColor(1,1,1,1-self.t)
    gc_draw(self.image,self.x,self.y,nil,self.size,nil,self.cx,self.cy)
end
function SYSFX.particle(duration,image,size,x,y,vx,vy,ax,ay)
    ins(FXlist,setmetatable({
        rate=1/duration,
        image=image,
        size=size,
        cx=image:getWidth()*.5,cy=image:getHeight()*.5,
        x=x,y=y,
        vx=vx,vy=vy,
        ax=ax,ay=ay,
    },{__index=FX.particle,__metatable=true}))
end

-------------------------------------------------------------

for _,fx in next,FX do
    setmetatable(fx,{__index=baseFX,__metatable=true})
end

-------------------------------------------------------------

---Update all FXs (called by Zenitha)
---@param dt number
function SYSFX._update(dt)
    local i=1
    while i<=#FXlist do
        if FXlist[i]:update(dt) then
            rem(FXlist,i)
        else
            i=i+1
        end
    end
end

---Draw all FXs (called by Zenitha)
function SYSFX._draw()
    for i=1,#FXlist do
        FXlist[i]:draw()
    end
end

return SYSFX
