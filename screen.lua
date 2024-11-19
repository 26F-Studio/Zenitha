if not (love.math and love.graphics and love.window) then
    LOG("debug","SCR lib is not loaded (need love.math & love.graphics & love.window)")
    local fakeTransform={
        transformPoint=NULL,
        inverseTransformPoint=NULL,
    }
    return setmetatable({
        w0=0,h0=0,
        w=0,h=0,diam=0,
        W=0,H=0,
        safeX=0,safeY=0,
        safeW=0,safeH=0,
        dpi=1,
        x=0,y=0,k=1,
        cx=0,cy=0,ex=0,ey=0,
        origin=fakeTransform,
        xOy=   fakeTransform,
        xOy_m= fakeTransform,
        xOy_ul=fakeTransform,
        xOy_u= fakeTransform,
        xOy_ur=fakeTransform,
        xOy_l= fakeTransform,
        xOy_r= fakeTransform,
        xOy_dl=fakeTransform,
        xOy_d= fakeTransform,
        xOy_dr=fakeTransform,
    },{
        __index=function(_,k)
            error("attempt to use SCR."..k..", but SCR lib is not loaded (need love.graphics & love.window)")
        end
    })
end


---@class Zenitha.ScreenInfo
local SCR={
    w0=800, -- Designing Rect width
    h0=600, -- Designing Rect height
    w=0, -- Current Full width (for graphic action)
    h=0, -- Current Full height (for graphic action)
    diam=0, -- Diameter, equal to sqrt(w^2+h^2)
    W=0, -- Current Full width (for shader only)
    H=0, -- Current Full height (for shader only)
    safeX=0, -- Safe area X position
    safeY=0, -- Safe area Y position
    safeW=0, -- Safe area width
    safeH=0, -- Safe area height
    dpi=1, -- DPI got from gc.getDPIScale()
    x=0, -- Min X of Designing Rect in original coord
    y=0, -- Min Y of Designing Rect in original coord
    k=1, -- Scaling K of Designing Rect in original coord
    cx=0, -- Center X of Designing Rect in original coord
    cy=0, -- Center Y of Designing Rect in original coord
    ex=0, -- Max X of Designing Rect in original coord
    ey=0, -- Max Y of Designing Rect in original coord

    -- Screen transformation objects

    origin=love.math.newTransform(), -- Screen transformation objects (love-origin)
    xOy=   love.math.newTransform(), -- Screen transformation objects (default)
    xOy_m= love.math.newTransform(), -- Screen transformation objects (middle)
    xOy_ul=love.math.newTransform(), -- Screen transformation objects (up-left)
    xOy_u= love.math.newTransform(), -- Screen transformation objects (up)
    xOy_ur=love.math.newTransform(), -- Screen transformation objects (up-right)
    xOy_l= love.math.newTransform(), -- Screen transformation objects (left)
    xOy_r= love.math.newTransform(), -- Screen transformation objects (right)
    xOy_dl=love.math.newTransform(), -- Screen transformation objects (down-left)
    xOy_d= love.math.newTransform(), -- Screen transformation objects (down)
    xOy_dr=love.math.newTransform(), -- Screen transformation objects (down-right)
}

-- Set the default designing rect size
SCR.w0,SCR.h0=ZENITHA.graphics.getDimensions()

---Set `Designing Rect` size

---`Designing Rect` is the largest rectangular area centered on the screen
---with the same proportions you specify.
---
---Then, you can consider all drawing operations as being performed within this specified area,
---without concerning the real window size which can be adjusted to any value.
---
---If you want to make self-adaption ui, you can use `gc.replaceTranformation(SCR.xOy_ul)` things to
---makes some elements stick to the upper-left corner, etc.
---
---In Zenitha, all operations related to screen size use `Designing Rect`
---rather than the engine's original coordinate system.
---If necessary, you must manually transform the coordinate values back to the origin in all callback events,
---and `gc.replaceTransform(SCR.origin)` at the beginning of each draw function.
---@param w number
---@param h number
function SCR.setSize(w,h)
    SCR.w0,SCR.h0=w,h
end

---Re-calculate all parameters when window resized, normally called automatically
---@param w number
---@param h number
function SCR._resize(w,h)
    SCR.w,SCR.h,SCR.dpi=w,h,ZENITHA.graphics.getDPIScale()
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

---Get all parameters of SCR module with a list of string
---@return string[]
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
