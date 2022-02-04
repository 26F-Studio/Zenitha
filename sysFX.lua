local gc=love.graphics
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_draw,gc_line=gc.draw,gc.line
local gc_rectangle,gc_circle=gc.rectangle,gc.circle

local rnd=math.random
local max,min=math.max,math.min
local ins,rem=table.insert,table.remove

local FXlist={}
local FX={}

-------------------------------------------------------------

local baseFX={
    update=function(self,dt)
        self.t=self.t+dt*self.rate
        return self.t>1
    end,
    draw=function()
        -- Do nothing
    end,
    rate=1,
}


FX.beam=setmetatable({
    type='beam',
    t=0,
},{__index=baseFX})
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
function FX.beam.new(rate,x1,y1,x2,y2,wid,r,g,b,a)
    return setmetatable({
        rate=rate,
        x1=x1,y1=y1,-- Start pos
        x2=x2,y2=y2,-- End pos
        wid=wid,-- Line width
        r=r,g=g,b=b,a=a,
    },{__index=FX.beam})
end


FX.tap=setmetatable({
    type='tap',
    t=0,
},{__index=baseFX})
function FX.tap:draw()
    local t=self.t
    gc_setColor(1,1,1,(1-t)*.4)
    gc_circle('fill',self.x,self.y,30*(1-t)^.5)
end
function FX.tap.new(rate,x,y)
    return setmetatable({
        rate=rate,
        x=x,y=y,
    },{__index=FX.tap})
end


FX.ripple=setmetatable({
    type='ripple',
    t=0,
},{__index=baseFX})
function FX.ripple:draw()
    local t=self.t
    gc_setLineWidth(2)
    gc_setColor(1,1,1,1-t)
    gc_circle('line',self.x,self.y,t*(2-t)*self.r)
end
function FX.ripple.new(rate,x,y,r)
    return setmetatable({
        rate=rate,
        x=x,y=y,r=r,
    },{__index=FX.ripple})
end


FX.rectRipple=setmetatable({
    type='rectRipple',
    t=0,
},{__index=baseFX})
function FX.rectRipple:draw()
    gc_setLineWidth(6)
    gc_setColor(1,1,1,1-self.t)
    local r=(10*self.t)^1.2
    gc_rectangle('line',self.x-r,self.y-r,self.w+2*r,self.h+2*r)
end
function FX.rectRipple.new(rate,x,y,w,h)
    return setmetatable({
        rate=rate,
        x=x,y=y,w=w,h=h,
    },{__index=FX.rectRipple})
end


FX.rect=setmetatable({
    type='rect',
    t=0,
},{__index=baseFX})
function FX.rect:draw()
    gc_setColor(self.r,self.g,self.b,1-self.t)
    gc_rectangle('fill',self.x,self.y,self.w,self.h,2)
end
function FX.rect.new(rate,x,y,w,h,r,g,b)
    return setmetatable({
        rate=rate,
        x=x,y=y,w=w,h=h,
        r=r or 1,g=g or 1,b=b or 1,
    },{__index=FX.rect})
end


FX.particle=setmetatable({
    type='particle',
    t=0,
},{__index=baseFX})
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
function FX.particle.new(rate,obj,size,x,y,vx,vy,ax,ay)
    return setmetatable({
        rate=rate*(.9+rnd()*.2),
        image=obj,size=size,
        cx=obj:getWidth()*.5,cy=obj:getHeight()*.5,
        x=x,y=y,
        vx=vx,vy=vy,
        ax=ax,ay=ay,
    },{__index=FX.particle})
end


FX.line=setmetatable({
    type='line',
    t=0,
},{__index=baseFX})
function FX.line:draw()
    gc_setColor(1,1,1,self.a*(1-self.t))
    gc_line(self.x1,self.y1,self.x2,self.y2)
end
function FX.line.new(rate,x1,y1,x2,y2,r,g,b,a)
    return setmetatable({
        rate=rate,
        x1=x1 or 0,y1=y1 or 0,
        x2=x2 or x1 or SCR.w0,y2=y2 or y1 or SCR.h0,
        r=r or 1,g=g or 1,b=b or 1,a=a or 1,
    },{__index=FX.line})
end

-------------------------------------------------------------


local SYSFX={}
function SYSFX.update(dt)
    for i=#FXlist,1,-1 do
        if FXlist[i]:update(dt) then
            rem(FXlist,i)
        end
    end
end
function SYSFX.draw()
    for i=1,#FXlist do
        FXlist[i]:draw()
    end
end
function SYSFX.new(type,...)
    assert(FX[type],"No FX type: "..type)
    ins(FXlist,FX[type].new(...))
end

return SYSFX
