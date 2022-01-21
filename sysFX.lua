local gc=love.graphics
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_draw,gc_line=gc.draw,gc.line
local gc_rectangle,gc_circle=gc.rectangle,gc.circle

local rnd=math.random
local max,min=math.max,math.min
local ins,rem=table.insert,table.remove

local fx={}

local function _normUpdate(S,dt)
    S.t=S.t+dt*S.rate
    return S.t>1
end

local FXupdate={}
FXupdate.attack=_normUpdate
FXupdate.tap=_normUpdate
FXupdate.ripple=_normUpdate
FXupdate.rectRipple=_normUpdate
FXupdate.rectangle=_normUpdate
function FXupdate.particle(S,dt)
    if S.vx then
        S.x=S.x+S.vx*S.rate
        S.y=S.y+S.vy*S.rate
        if S.ax then
            S.vx=S.vx+S.ax*S.rate
            S.vy=S.vy+S.ay*S.rate
        end
    end
    return _normUpdate(S,dt)
end
FXupdate.line=_normUpdate

local FXdraw={}
function FXdraw.attack(S)
    gc_setColor(S.r*2,S.g*2,S.b*2,S.a*min(4-S.t*4,1))

    gc_setLineWidth(S.wid)
    local t1,t2=max(5*S.t-4,0),min(S.t*4,1)
    gc_line(
        S.x1*(1-t1)+S.x2*t1,
        S.y1*(1-t1)+S.y2*t1,
        S.x1*(1-t2)+S.x2*t2,
        S.y1*(1-t2)+S.y2*t2
    )

    gc_setLineWidth(S.wid*.6)
    t1,t2=max(4*S.t-3,0),min(S.t*5,1)
    gc_line(
        S.x1*(1-t1)+S.x2*t1,
        S.y1*(1-t1)+S.y2*t1,
        S.x1*(1-t2)+S.x2*t2,
        S.y1*(1-t2)+S.y2*t2
    )
end
function FXdraw.tap(S)
    local t=S.t
    gc_setColor(1,1,1,(1-t)*.4)
    gc_circle('fill',S.x,S.y,30*(1-t)^.5)
end
function FXdraw.ripple(S)
    local t=S.t
    gc_setLineWidth(2)
    gc_setColor(1,1,1,1-t)
    gc_circle('line',S.x,S.y,t*(2-t)*S.r)
end
function FXdraw.rectRipple(S)
    gc_setLineWidth(6)
    gc_setColor(1,1,1,1-S.t)
    local r=(10*S.t)^1.2
    gc_rectangle('line',S.x-r,S.y-r,S.w+2*r,S.h+2*r)
end
function FXdraw.rectangle(S)
    gc_setColor(S.r,S.g,S.b,1-S.t)
    gc_rectangle('fill',S.x,S.y,S.w,S.h,2)
end
function FXdraw.particle(S)
    gc_setColor(1,1,1,1-S.t)
    gc_draw(S.image,S.x,S.y,nil,S.size,nil,S.cx,S.cy)
end
function FXdraw.line(S)
    gc_setColor(1,1,1,S.a*(1-S.t))
    gc_line(S.x1,S.y1,S.x2,S.y2)
end

local SYSFX={}
function SYSFX.update(dt)
    for i=#fx,1,-1 do
        if fx[i]:update(dt) then
            rem(fx,i)
        end
    end
end
function SYSFX.draw()
    for i=1,#fx do
        fx[i]:draw()
    end
end

function SYSFX.attack(rate,x1,y1,x2,y2,wid,r,g,b,a)
    ins(fx,{
        update=FXupdate.attack,
        draw=FXdraw.attack,
        t=0,
        rate=rate,
        x1=x1,y1=y1,-- Start pos
        x2=x2,y2=y2,-- End pos
        wid=wid,-- Line width
        r=r,g=g,b=b,a=a,
    })
end
function SYSFX.tap(rate,x,y)
    local T=
    {
        update=FXupdate.tap,
        draw=FXdraw.tap,
        t=0,
        rate=rate,
        x=x,y=y,
    }
    ins(fx,T)
end
function SYSFX.ripple(rate,x,y,r)
    ins(fx,{
        update=FXupdate.ripple,
        draw=FXdraw.ripple,
        t=0,
        rate=rate,
        x=x,y=y,r=r,
    })
end
function SYSFX.rectripple(rate,x,y,w,h)
    ins(fx,{
        update=FXupdate.rectRipple,
        draw=FXdraw.rectRipple,
        t=0,
        rate=rate,
        x=x,y=y,w=w,h=h,
    })
end
function SYSFX.rectangle(rate,x,y,w,h,r,g,b)
    ins(fx,{
        update=FXupdate.rectangle,
        draw=FXdraw.rectangle,
        t=0,
        rate=rate,
        x=x,y=y,w=w,h=h,
        r=r or 1,g=g or 1,b=b or 1,
    })
end
function SYSFX.particle(rate,obj,size,x,y,vx,vy,ax,ay)
    ins(fx,{
        update=FXupdate.particle,
        draw=FXdraw.particle,
        t=0,
        rate=rate*(.9+rnd()*.2),
        image=obj,size=size,
        cx=obj:getWidth()*.5,cy=obj:getHeight()*.5,
        x=x,y=y,
        vx=vx,vy=vy,
        ax=ax,ay=ay,
    })
end
function SYSFX.line(rate,x1,y1,x2,y2,r,g,b,a)
    ins(fx,{
        update=FXupdate.line,
        draw=FXdraw.line,
        t=0,
        rate=rate,
        x1=x1 or 0,y1=y1 or 0,
        x2=x2 or x1 or 1280,y2=y2 or y1 or 720,
        r=r or 1,g=g or 1,b=b or 1,a=a or 1,
    })
end
return SYSFX
