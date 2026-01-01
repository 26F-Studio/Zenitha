if not love.graphics then
    LOG("SCR lib is not loaded (need love.graphics)")
    if not love.window then LOG("SCR lib needs love.window to enable feature 'SCR.safeX/Y/W/H'") end
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
        end,
    })
end


---@class Zenitha.ScreenInfo
local SCR={
    w0=800, -- Designing Rect width
    h0=600, -- Designing Rect height
    w=0, -- Window width (for normal graphical actions)
    h=0, -- Window height
    diam=0, -- Diameter, equal to sqrt(w^2+h^2)
    W=0, -- Window width (for shader only, could be different from SCR.w on mobile devices)
    H=0, -- Window height
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
SCR.w0,SCR.h0=love.graphics.getDimensions()

---Set `Designing Rect` size
---
---`Designing Rect` is the largest rectangular area centered on the screen
---with the same proportions you specify.
---
---In Zenitha, *ALMOST ALL* operations related to screen size use `Designing Rect` rather than
---Love2D's original coordinate system. Then you can consider *ALMOST ALL* operations as being
---performed within this specified area, without concerning the real window size, which is variable.
---
---If necessary, you must manually set the transform back to origin with `gc.origin()` in *ALMOST ALL*
---callback events before drawing, and `SCR.xOy:inverseTransformPoint(x,y)` for mouse position.
---If you want to make self-adaption UI, you can use `gc.replaceTransform(SCR.xOy_ul)` to
---draw elements sticking to the upper-left corner, etc. (you won't consider scaling, only translation).
---
---*ALMOST ALL*: all cursor positions & drawing operations, except: drawing function of BG module,
---scene swapping cutscene of SCN module, waiting screen of WAIT module.
---@param w number
---@param h number
function SCR.setSize(w,h)
    SCR.w0,SCR.h0=w,h
end

---Re-calculate all parameters when window resized, normally called automatically
---@param w number
---@param h number
function SCR._resize(w,h)
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
    if love.window and love.window.getSafeArea then
        SCR.safeX,SCR.safeY,SCR.safeW,SCR.safeH=love.window.getSafeArea()
    else
        SCR.safeX,SCR.safeY,SCR.safeW,SCR.safeH=0,0,w,h
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
