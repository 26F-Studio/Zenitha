---@diagnostic disable: inject-field

local gc=love.graphics
local getColor,setColor,prints,printf,draw,drawL=gc.getColor,gc.setColor,gc.print,gc.printf,gc.draw,gc.drawLayer
local newText=gc.newText
local line,arc,polygon=gc.line,gc.arc,gc.polygon
local rectangle,circle=gc.rectangle,gc.circle
local applyTransform=gc.applyTransform
local sin,cos=math.sin,math.cos
local pcall=pcall
local lerp=MATH.lerp
local NULL=NULL

local GC=TABLE.copyAll(gc,0)

--------------------------------------------------------------
-- Aligning Draw

---Printf a string with 'center'
---@param obj string|number
---@param x number
---@param y number
function GC.mStr(obj,x,y) printf(obj,x-1260,y,2520,'center') end

---Draw an object with x=obj:getWidth()/2
---@param obj love.Texture|love.Drawable
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawX(obj,x,y,a,k) draw(obj,x,y,a,k,nil,obj:getWidth()*.5,0) end

---Draw an object with y=obj:getWidth()/2
---@param obj love.Texture|love.Drawable
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawY(obj,x,y,a,k) draw(obj,x,y,a,k,nil,0,obj:getHeight()*.5) end

---Draw an object with both middle X & Y
---@param obj love.Texture|love.Drawable
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDraw(obj,x,y,a,k) draw(obj,x,y,a,k,nil,obj:getWidth()*.5,obj:getHeight()*.5) end

---Draw an object with both middle X & Y
---@param obj love.Texture|love.Drawable
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawQX(obj,quad,x,y,a,k)
    local _,_,w,h=quad:getViewport()
    draw(obj,quad,x,y,a,k,nil,w*.5,h*.5)
end

---Draw an object with both middle X & Y
---@param obj love.Texture|love.Drawable
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawQY(obj,quad,x,y,a,k)
    local _,_,w,h=quad:getViewport()
    draw(obj,quad,x,y,a,k,nil,w*.5,h*.5)
end

---Draw an object with both middle X & Y
---@param obj love.Texture|love.Drawable
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawQ(obj,quad,x,y,a,k)
    local _,_,w,h=quad:getViewport()
    draw(obj,quad,x,y,a,k,nil,w*.5,h*.5)
end

---Draw an layered obj with x=obj:getWidth()/2
---@param obj love.Texture
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawLX(obj,l,x,y,a,k) drawL(obj,l,x,y,a,k,nil,obj:getWidth()*.5,0) end

---Draw an layered obj with y=obj:getWidth()/2
---@param obj love.Texture
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawLY(obj,l,x,y,a,k) drawL(obj,l,x,y,a,k,nil,0,obj:getHeight()*.5) end

---Draw an layered obj with both middle X & Y
---@param obj love.Texture
---@param x? number
---@param y? number
---@param a? number
---@param k? number
function GC.mDrawL(obj,l,x,y,a,k) drawL(obj,l,x,y,a,k,nil,obj:getWidth()*.5,obj:getHeight()*.5) end

--------------------------------------------------------------
-- Utility

---Set current pen's alpha
---@param a number
function GC.setAlpha(a)
    local r,g,b=getColor()
    setColor(r,g,b,a)
end

---Multiply current pen's alpha
---@param k number
function GC.mulAlpha(k)
    local r,g,b,a=getColor()
    setColor(r,g,b,a*k)
end

---GC.print with protect call
function GC.safePrint(...)
    return pcall(prints,...)
end

---GC.printf with protect call
function GC.safePrintf(...)
    return pcall(printf,...)
end

---Draw an offset stroke based on the specified object (extended love.gc.draw)
---@param strokeMode 'side'|'corner'|'full' other values will be treated as 'full'
---@param d number
---@param obj love.Texture|love.Drawable
---@param x number
---@param y number
---@param r? number rotation
---@param sx? number scale
---@param sy? number scale
---@param ox? number offset
---@param oy? number offset
---@param kx? number shear
---@param ky? number shear
function GC.strokeDraw(strokeMode,d,obj,x,y,r,sx,sy,ox,oy,kx,ky)
    if strokeMode~='corner' then
        draw(obj,x-d,y,r,sx,sy,ox,oy,kx,ky)
        draw(obj,x+d,y,r,sx,sy,ox,oy,kx,ky)
        draw(obj,x,y-d,r,sx,sy,ox,oy,kx,ky)
        draw(obj,x,y+d,r,sx,sy,ox,oy,kx,ky)
    end
    if strokeMode~='side' then
        d=d/1.4142135623730951
        draw(obj,x-d,y-d,r,sx,sy,ox,oy,kx,ky)
        draw(obj,x-d,y+d,r,sx,sy,ox,oy,kx,ky)
        draw(obj,x+d,y-d,r,sx,sy,ox,oy,kx,ky)
        draw(obj,x+d,y+d,r,sx,sy,ox,oy,kx,ky)
    end
end

---Print text with stroke (extended love.gc.printf)
---@param strokeMode? 'side'|'corner'|'full' other values will be treated as 'full'
---@param d number
---@param strokeColor Zenitha.Color Stroke color
---@param textColor? Zenitha.Color Center color (leave nil to disable text)
---@param str string
---@param x number
---@param y number
---@param align? love.AlignMode
---@param r? number rotation
---@param sx? number scale
---@param sy? number scale
---@param ox? number offset
---@param oy? number offset
---@param kx? number shear
---@param ky? number shear
function GC.strokePrint(strokeMode,d,strokeColor,textColor,str,x,y,align,r,sx,sy,ox,oy,kx,ky)
    local w=1280
    if align=='center' then
        x=x-w*.5
    elseif align=='right' then
        x=x-w
    end
    setColor(strokeColor or COLOR.L)
    if strokeMode~='corner' then
        printf(str,x-d,y,w,align,r,sx,sy,ox,oy,kx,ky)
        printf(str,x+d,y,w,align,r,sx,sy,ox,oy,kx,ky)
        printf(str,x,y-d,w,align,r,sx,sy,ox,oy,kx,ky)
        printf(str,x,y+d,w,align,r,sx,sy,ox,oy,kx,ky)
    end
    if strokeMode~='side' then
        d=d/1.4142135623730951
        printf(str,x-d,y-d,w,align,r,sx,sy,ox,oy,kx,ky)
        printf(str,x-d,y+d,w,align,r,sx,sy,ox,oy,kx,ky)
        printf(str,x+d,y-d,w,align,r,sx,sy,ox,oy,kx,ky)
        printf(str,x+d,y+d,w,align,r,sx,sy,ox,oy,kx,ky)
    end
    if textColor then
        setColor(textColor)
        printf(str,x,y,w,align,r,sx,sy,ox,oy,kx,ky)
    end
end

---Draw a rectangle but center aligned
---@param mode love.DrawMode
---@param x number
---@param y number
---@param w number
---@param h number
---@param rx? number
---@param ry? number
function GC.mRect(mode,x,y,w,h,rx,ry)
    rectangle(mode,x-w*.5,y-h*.5,w,h,rx,ry)
end

---Draw a regular polygon
---@param mode love.DrawMode
---@param x? number
---@param y? number
---@param rad number Radius
---@param segments number
---@param ang? number
function GC.regPolygon(mode,x,y,rad,segments,ang)
    if not x then x=0 end
    if not y then y=0 end
    if not ang then ang=0 end

    local l={}
    local angStep=6.283185307179586/segments
    for i=1,segments do
        l[2*i-1]=x+rad*cos(ang)
        l[2*i]=y+rad*sin(ang)
        ang=ang+angStep
    end
    polygon(mode,l)
end

---Draw a regular polygon with rounded corner
---@param mode love.DrawMode
---@param x? number
---@param y? number
---@param rad number Radius
---@param segments number
---@param rCorner number Radius of rounded corner
---@param phase? number
function GC.regRoundPolygon(mode,x,y,rad,segments,rCorner,phase)
    if not x then x=0 end
    if not y then y=0 end

    local X,Y={},{}
    local ang=phase or 0
    local angStep=6.283185307179586/segments
    for i=1,segments do
        X[i]=x+rad*cos(ang)
        Y[i]=y+rad*sin(ang)
        ang=ang+angStep
    end
    X[segments+1]=x+rad*cos(ang)
    Y[segments+1]=y+rad*sin(ang)
    local halfAng=6.283185307179586/segments/2
    local erasedLen=rCorner*math.tan(halfAng)
    if mode=='line' then
        erasedLen=erasedLen+1 -- Fix 1px cover
        for i=1,segments do
            -- Line
            local x1,y1,x2,y2=X[i],Y[i],X[i+1],Y[i+1]
            local dir=math.atan2(y2-y1,x2-x1)
            line(x1+erasedLen*cos(dir),y1+erasedLen*sin(dir),x2-erasedLen*cos(dir),y2-erasedLen*sin(dir))

            -- Arc
            ang=ang+angStep
            local R2=rad-rCorner/cos(halfAng)
            local arcCX,arcCY=x+R2*cos(ang),y+R2*sin(ang)
            arc('line','open',arcCX,arcCY,rCorner,ang-halfAng,ang+halfAng)
        end
    elseif mode=='fill' then
        local L={}
        for i=1,segments do
            -- Line
            local x1,y1,x2,y2=X[i],Y[i],X[i+1],Y[i+1]
            local dir=math.atan2(y2-y1,x2-x1)
            L[4*i-3]=x1+erasedLen*cos(dir)
            L[4*i-2]=y1+erasedLen*sin(dir)
            L[4*i-1]=x2-erasedLen*cos(dir)
            L[4*i]=y2-erasedLen*sin(dir)

            -- Arc
            ang=ang+angStep
            local R2=rad-rCorner/cos(halfAng)
            local arcCX,arcCY=x+R2*cos(ang),y+R2*sin(ang)
            arc('fill','open',arcCX,arcCY,rCorner,ang-halfAng,ang+halfAng)
        end
        polygon('fill',L)
    else
        error("GC.regRoundPolygon(mode,...): Draw mode should be 'line' or 'fill'")
    end
end

do -- function GC.getScreenShot(table,key) -- Save screenshot as image object to a table
    local _t,_k
    local function _captureFunc(imageData) -- Actually triggered by engine a bit later after calling GC.getScreenShot, because love2d's capture function doesn't effect instantly
        _t[_k]=gc.newImage(imageData)
    end
    ---@param t table
    ---@param k any
    function GC.getScreenShot(t,k)
        _t,_k=t,k
        gc.captureScreenshot(_captureFunc)
    end
end

--------------------------------------------------------------
-- Beziers

---@class Zenitha.Curve.Bezier
---@field points Zenitha.Curve.Point[]
---@field curve number[]
---@field ctrlPos number[]
local Bezier={}
Bezier.__index=Bezier

---Render the curve to a points list with specific mode
---@param seg number Segments between each data point
---@param dist? number [Second-Processing], Distance between each data point, nil to skip this step
function Bezier:render(seg,dist)
    assert(type(seg)=='number' and seg>0 and seg%1==0,"Bezier:render(seg,dist): seg need positive int")
    local list=self.points
    print(TABLE.dump(list))
    assert(list and #list>1,"Bezier:render: points need at least 2")

    local p=1 -- r goes first, Find first data point
    while list[p] and list[p][3] do p=p+1 end
    assert(list[p],"[Bezier]:render: Data point not found")

    local curve={}
    local secList={list[p]}
    while true do
        -- Find next data point
        local _p=p
        for i=p+1,#list do
            if list[i][3] then
                secList[#secList+1]=list[i]
            else
                p=i
                break
            end
        end
        if p==_p then break end -- No more data point
        secList[#secList+1]=list[p]

        -- Generate curve t in [0,1) for each section
        for t=1,seg do
            -- Normalize t
            t=(t-1)/seg

            -- Create list for each dimension
            local xList,yList={},{}
            for i=1,#secList do
                xList[i]=secList[i][1]
                yList[i]=secList[i][2]
            end

            -- Calculate curve with lerping
            while #xList>1 do
                for i=1,#xList-1 do
                    xList[i]=lerp(xList[i],xList[i+1],t)
                    yList[i]=lerp(yList[i],yList[i+1],t)
                end
                xList[#xList],yList[#yList]=nil,nil
            end
            curve[#curve+1]=xList[1]
            curve[#curve+1]=yList[1]
        end

        -- Clear section list cache
        TABLE.clear(secList)
        secList[1]=list[p]
    end

    curve[#curve+1]=list[p][1]
    curve[#curve+1]=list[p][2]

    if dist~=nil then
        assert(type(dist)=='number' and dist>0,"Bezier:render(seg,dist): dist need positive number")
        -- TODO
    end
    self.curve=curve
    return curve
end

---@class Zenitha.Curve.Point
---@field [1] number
---@field [2] number
---@field [3] boolean
---@field x? number
---@field y? number
---@field ctrl? boolean

---@param points Zenitha.Curve.Point[]
---@return Zenitha.Curve.Bezier
function GC.newBezier(points)
    assert(type(points)=='table',"GC.newBezier(points): Need points[]")
    local _pList={}
    for i=1,#points do
        local p=points[i]
        local P={
            p[1] or p.x,
            p[2] or p.y,
            not not (p[3] or p.ctrl),
        }
        assert(P[1] and P[2],"GC.newBezier(points): points[n] need [1]&[2]/x&y")
        _pList[i]=P
    end
    return setmetatable({
        points=_pList,
        curve={},
    },Bezier)
end

--------------------------------------------------------------
-- Easier Stencil

local gc_stencil,gc_setStencilTest=gc.stencil,gc.setStencilTest

local stc_action,stc_value='replace',1

---Reset stencil states, set default stencil states:
---
---draw: 'replace', 1
---
---test: 'equal', 1
function GC.stc_reset()
    stc_action,stc_value='replace',1
    gc_setStencilTest('equal',1)
    gc_stencil(NULL)
end

---Set stencil test mode (just love.graphics.setStencilTest with default)
---@param compMode? love.CompareMode
---@param compVal? number
function GC.stc_setComp(compMode,compVal)
    gc_setStencilTest(compMode or 'equal',compVal or 1)
end

---Set stencil draw mode (just love.graphics.stencil)
---@param drawMode love.StencilAction
---@param drawVal number
function GC.stc_setPen(drawMode,drawVal)
    stc_action,stc_value=drawMode,drawVal
end

---Cancel stencil comparing (just love.graphics.setStencilTest)
function GC.stc_stop()
    gc_setStencilTest()
end

local rect_x,rect_y,rect_w,rect_h,rect_rx,rect_ry,rect_seg
local function stencil_rectangle()
    rectangle('fill',rect_x,rect_y,rect_w,rect_h,rect_rx,rect_ry,rect_seg)
end
---Draw a rectangle as stencil
---@param x number
---@param y number
---@param w number
---@param h number
---@param rx? number
---@param ry? number
---@param seg? number
function GC.stc_rect(x,y,w,h,rx,ry,seg)
    rect_x,rect_y,rect_w,rect_h,rect_rx,rect_ry,rect_seg=x,y,w,h,rx,ry,seg
    gc_stencil(stencil_rectangle,stc_action,stc_value,true)
end

local circ_x,circ_y,circ_r,circ_seg
local function stencil_circle()
    circle('fill',circ_x,circ_y,circ_r,circ_seg)
end
---Draw a circle as stencil
---@param x number
---@param y number
---@param r number
---@param seg? number
function GC.stc_circ(x,y,r,seg)
    circ_x,circ_y,circ_r,circ_seg=x,y,r,seg
    gc_stencil(stencil_circle,stc_action,stc_value,true)
end

--------------------------------------------------------------
-- Camera

---@class Zenitha.Camera
---@field x0 number
---@field y0 number
---@field k0 number
---@field a0 number
---@field x number
---@field y number
---@field k number
---@field a number
---@field moveSpeed number
---@field rotateSpeed number
---@field swing number
---@field maxDist number
---@field minK number
---@field maxK number
---@field transform love.Transform
local Camera={}

---Move camera
---@param dx number
---@param dy number
function Camera:move(dx,dy)
    self.x0=self.x0+dx
    self.y0=self.y0+dy
    if self.maxDist then
        local dist=MATH.distance(0,0,self.x0,self.y0)/self.k0
        if dist>self.maxDist then
            local angle=math.atan2(self.y0,self.x0)
            self.x0=self.maxDist*math.cos(angle)*self.k0
            self.y0=self.maxDist*math.sin(angle)*self.k0
        end
    end
end

---Rotate camera
---@param da number
function Camera:rotate(da)
    self.a0=self.a0+da
end

---Scale camera
---@param dk number
function Camera:scale(dk)
    local k0=self.k0
    self.k0=MATH.clamp(self.k0*dk,self.minK or 0,self.maxK or 1e99)
    dk=self.k0/k0
    self.x0,self.y0=self.x0*dk,self.y0*dk
end

---Update camera
---@param dt number
function Camera:update(dt)
    self.x=MATH.expApproach(self.x,self.x0,dt*self.moveSpeed)
    self.y=MATH.expApproach(self.y,self.y0,dt*self.moveSpeed)
    self.k=MATH.expApproach(self.k,self.k0,dt*self.moveSpeed)
    self.a=MATH.expApproach(self.a,self.a0+(self.swing and self.swing*math.sin(love.timer.getTime()/1.26) or 0),dt*self.rotateSpeed)
    self.transform:setTransformation(self.x,self.y,self.a,self.k)
end

---Apply camera's transform
function Camera:apply()
    applyTransform(self.transform)
end

---Create a new camera
---@return Zenitha.Camera
function GC.newCamera()
    local c={
        x0=0,y0=0,k0=1,a0=0,
        x=0,y=0,k=1,a=0,
        moveSpeed=26,
        rotateSpeed=6.26,
        swing=false,

        maxDist=false,
        minK=false,maxK=false,
        transform=love.math.newTransform(),
    }
    return setmetatable(c,{__index=Camera})
end

--------------------------------------------------------------
-- TODO: text warping

local function measureWidth(font,str)
    return newText(font,str):getWidth()
end
function GC.warpText(font,str,width)
    local list={}

    -- TODO:
    -- use 'measureWidth(font,string)' to measure the width of string
    -- return a table of strings, each of which is no longer than given width

    return list
end

--------------------------------------------------------------

do -- function GC.load(L), GC.execute(t)
    ---@alias Zenitha.drawingCommand {[1]:Zenitha.drawingCommandType, [number]:any}

    ---@enum (key) Zenitha.drawingCommandType
    local cmds={
        push=     'push',
        pop=      'pop',

        repT=     'replaceTransform',
        appT=     'applyTransform',
        invT=     'inverseTransformPoint',

        origin=   'origin',
        move=     'translate',
        scale=    'scale',
        rotate=   'rotate',
        shear=    'shear',
        clear=    'clear',

        setCL=    'setColor',
        setCM=    'setColorMask',
        setLW=    'setLineWidth',
        setLS=    'setLineStyle',
        setLJ=    'setLineJoin',
        setBM=    'setBlendMode',
        setSD=    'setShader',

        print=    'print',
        rawFT=    function(...) FONT.rawset(...) end,
        setFT=    function(...) FONT.set(...) end,
        mStr=     'mStr',
        mDrawX=   'mDrawX',
        mDrawY=   'mDrawY',
        mDraw=    'mDraw',
        stDraw=   'strokeDraw',
        stPrint=  'strokePrint',

        draw=     'draw',
        line=     'line',
        fRect=function(...) gc.rectangle('fill',...) end,
        dRect=function(...) gc.rectangle('line',...) end,
        fCirc=function(...) gc.circle('fill',...) end,
        dCirc=function(...) gc.circle('line',...) end,
        fElps=function(...) gc.ellipse('fill',...) end,
        dElps=function(...) gc.ellipse('line',...) end,
        fPoly=function(...) polygon('fill',...) end,
        dPoly=function(...) polygon('line',...) end,

        dPie=function(...) arc('line',...) end,
        dArc=function(...) arc('line','open',...) end,
        dBow=function(...) arc('line','closed',...) end,
        fPie=function(...) arc('fill',...) end,
        fArc=function(...) arc('fill','open',...) end,
        fBow=function(...) arc('fill','closed',...) end,

        fRPol=function(...) GC.regPolygon('fill',...) end,
        dRPol=function(...) GC.regPolygon('line',...) end,
        fRRPol=function(...) GC.regRoundPolygon('fill',...) end,
        dRRPol=function(...) GC.regRoundPolygon('line',...) end,
    }
    for k,v in next,cmds do
        if type(v)=='string' then
            cmds[k]=GC[v]
        end
    end

    local function GC_execute(t)
        if type(t[1])=='string' then
            cmds[t[1]](unpack(t,2))
        elseif type(t[1])=='table' then
            for i=1,#t do
                GC_execute(t[i])
            end
        elseif type(t[1])=='function' then
            t[1](unpack(t,2))
        else
            error("GC_execute(...): Wrong type of [1]")
        end
    end
    ---Run a set of graphics commands in table-format
    ---
    ---See commands list by going to declaration of this function, then scroll up.
    ---@param t Zenitha.drawingCommand[]
    ---## Example
    ---```lua
    ---GC.execute{
    ---    {'setCL',1,0,0},
    ---    {'dRect','fill',0,0,100,100},
    ---    {'setCL',1,1,0},
    ---    {'dCirc','fill',50,50,40},
    ---}
    ---```
    function GC.execute(t) GC_execute(t) end

    local sizeLimit=gc.getSystemLimits().texturesize
    ---Similar to GC.execute, but draw on a canvas.
    ---@param list {w:number, h:number, [number]:Zenitha.drawingCommand}
    ---## Example
    ---```lua
    ---GC.load{w=100,h=100 -- size of canvas
    ---    {'setCL',1,0,0},
    ---    {'dRect','fill',0,0,100,100},
    ---    {'setCL',1,1,0},
    ---    {'dCirc','fill',50,50,40},
    ---} --> canvas
    ---```
    function GC.load(list)
        local w,h=tonumber(list.w),tonumber(list.h)
        assert(w and h and w>0 and h>0 and w%1==0 and h%1==0,"GC.load(L): L[1] and L[2] need int >=1")
        gc.push()
            local canvas
            while true do
                local success
                success,canvas=pcall(gc.newCanvas,math.min(w,sizeLimit),math.min(h,sizeLimit))
                if success then
                    break
                else
                    sizeLimit=math.floor(sizeLimit*.8)
                    assert(sizeLimit>=1,"GC.load(L): Failed to create canvas")
                end
            end
            gc.setCanvas(canvas)
            gc.clear(1,1,1,0)
            gc.origin()
            gc.setColor(1,1,1)
            gc.setLineWidth(1)
            for i=1,#list do
                local code=list[i]
                local cmd=code[1]
                if type(cmd)=='string' then
                    cmd=assert(cmds[cmd],"GC.load(L): No gc command: "..cmd)(unpack(code,2))
                elseif type(cmd)=='function' then
                    cmd(unpack(code,2))
                else
                    error("GC.load: cmd need string|function")
                end
            end
            gc.setShader()
            gc.setColorMask()
            gc.setBlendMode('alpha')
            gc.setCanvas()
        gc.pop()
        return canvas
    end
end

return GC
