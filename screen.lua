--- @class Zenitha.ScreenInfo
--- @field w0 number @Default Screen Size
--- @field h0 number @Default Screen Size
--- @field w number @Fullscreen w/h for graphic functions
--- @field h number @Fullscreen w/h for graphic functions
--- @field diam number @Diameter sqrt(w^2+h^2)
--- @field W number @Fullscreen w/h for shader
--- @field H number @Fullscreen w/h for shader
--- @field safeX number @Safe area position
--- @field safeY number @Safe area position
--- @field safeW number @Safe area size
--- @field safeH number @Safe area size
--- @field dpi number @DPI from gc.getDPIScale()
---
--- @field x number @Expected box's Up-left position
--- @field y number @Expected box's Up-left position
--- @field k number @Expected box's Scaling size
--- @field cx number @Expected box's Center position (Center X/Y)
--- @field cy number @Expected box's Center position (Center X/Y)
--- @field ex number @Expected box's Down-right position (End X/Y)
--- @field ey number @Expected box's Down-right position (End X/Y)
---
--- @field origin love.Transform @Screen transformation objects (love-origin)
--- @field xOy love.Transform    @Screen transformation objects (default)
--- @field xOy_m love.Transform  @Screen transformation objects (middle)
--- @field xOy_ul love.Transform @Screen transformation objects (up-left)
--- @field xOy_u love.Transform  @Screen transformation objects (up)
--- @field xOy_ur love.Transform @Screen transformation objects (up-right)
--- @field xOy_l love.Transform  @Screen transformation objects (left)
--- @field xOy_r love.Transform  @Screen transformation objects (right)
--- @field xOy_dl love.Transform @Screen transformation objects (down-left)
--- @field xOy_d love.Transform  @Screen transformation objects (down)
--- @field xOy_dr love.Transform @Screen transformation objects (down-right)


--- @type Zenitha.ScreenInfo
local SCR={
    w0=800,h0=600,
    w=0,h=0,diam=0,
    W=0,H=0,
    safeX=0,safeY=0,
    safeW=0,safeH=0,
    dpi=1,
    x=0,y=0,k=1,
    cx=0,cy=0,
    ex=0,ey=0,

    -- Screen transformation objects
    origin=love.math.newTransform(),
    xOy=   love.math.newTransform(),
    xOy_m= love.math.newTransform(),
    xOy_ul=love.math.newTransform(),
    xOy_u= love.math.newTransform(),
    xOy_ur=love.math.newTransform(),
    xOy_l= love.math.newTransform(),
    xOy_r= love.math.newTransform(),
    xOy_dl=love.math.newTransform(),
    xOy_d= love.math.newTransform(),
    xOy_dr=love.math.newTransform(),
}
if love.graphics then SCR.w0,SCR.h0=love.graphics.getDimensions() end

--- Set expected screen size
--- @param w number
--- @param h number
function SCR.setSize(w,h)
    SCR.w0,SCR.h0=w,h
end

--- Re-calculate arguments when window resized to w,h
--- @param w number
--- @param h number
function SCR.resize(w,h)
    SCR.w,SCR.h,SCR.dpi=w,h,love.graphics.getDPIScale()
    SCR.W,SCR.H=SCR.w*SCR.dpi,SCR.h*SCR.dpi
    SCR.r=h/w
    SCR.diam=(w^2+h^2)^.5

    SCR.x,SCR.y=0,0
    if SCR.r>=SCR.h0/SCR.w0 then
        SCR.k=w/SCR.w0
        SCR.y=(h-SCR.h0*SCR.k)/2
    else
        SCR.k=h/SCR.h0
        SCR.x=(w-SCR.w0*SCR.k)/2
    end
    SCR.cx,SCR.cy=SCR.w/2,SCR.h/2
    SCR.ex,SCR.ey=SCR.w-SCR.x,SCR.h-SCR.y
    if love.window.getSafeArea then
        SCR.safeX,SCR.safeY,SCR.safeW,SCR.safeH=love.window.getSafeArea()
    end

    SCR.origin:setTransformation(0,0)
    SCR.xOy:   setTransformation(SCR.x,SCR.y,0,SCR.k)
    SCR.xOy_m: setTransformation(w/2,h/2,0,SCR.k)
    SCR.xOy_ul:setTransformation(0,0,0,SCR.k)
    SCR.xOy_u: setTransformation(w/2,0,0,SCR.k)
    SCR.xOy_ur:setTransformation(w,0,0,SCR.k)
    SCR.xOy_l: setTransformation(0,h/2,0,SCR.k)
    SCR.xOy_r: setTransformation(w,h/2,0,SCR.k)
    SCR.xOy_dl:setTransformation(0,h,0,SCR.k)
    SCR.xOy_d: setTransformation(w/2,h,0,SCR.k)
    SCR.xOy_dr:setTransformation(w,h,0,SCR.k)
end

--- Get screen info
--- @return string[]
function SCR.info()
    return {
        ("w0,h0 : %d, %d"):format(SCR.w0,SCR.h0),
        ("x,y : %d, %d"):format(SCR.x,SCR.y),
        ("cx,cy : %d, %d"):format(SCR.cx,SCR.cy),
        ("ex,ey : %d, %d"):format(SCR.ex,SCR.ey),
        ("w,h : %d, %d"):format(SCR.w,SCR.h),
        ("W,H : %d, %d"):format(SCR.W,SCR.H),
        ("safeX,safeY : %d, %d"):format(SCR.safeX,SCR.safeY),
        ("safeW,safeH : %d, %d"):format(SCR.safeW,SCR.safeH),
        ("k,dpi,diam : %.2f, %d, %.2f"):format(SCR.k,SCR.dpi,SCR.diam),
    }
end

return SCR
