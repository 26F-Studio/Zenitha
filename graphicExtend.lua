---@diagnostic disable: inject-field

if not love.graphics then
    LOG("GC lib is not loaded (need love.graphics)")
    return setmetatable({},{
        __index=function(t,k)
            t[k]=NULL
            return t[k]
        end
    })
end

local gc=love.graphics
local getColor,setColor,setShader=gc.getColor,gc.setColor,gc.setShader
local prints,printf,draw,drawL=gc.print,gc.printf,gc.draw,gc.drawLayer
local newText=gc.newText
local line,arc,polygon=gc.line,gc.arc,gc.polygon
local rectangle,circle,ellipse=gc.rectangle,gc.circle,gc.ellipse
local applyTransform=gc.applyTransform
local sin,cos=math.sin,math.cos
local type,pcall=type,pcall
local lerp=MATH.lerp
local NULL=NULL

---@class Zenitha.Graphics: love.graphics
local GC=TABLE.copyAll(gc,0)

--------------------------------------------------------------
-- Mesh

---Create a new 9-patch mesh cropped from a texture with specified viewport
---@param meshW number
---@param meshH number
---@param me number Mesh Edge width
---@param ve number Source Edge width
---@param texture love.Texture
---@param x number viewport x
---@param y number viewport y
---@param w number viewport w
---@param h number viewport h
function GC.new9mesh(meshW,meshH,me,ve,texture,x,y,w,h)
    local tw,th=texture:getDimensions()
    local meshMap={}
    for _y=0,3 do
        for _x=0,3 do
            table.insert(meshMap, {
                _x==0 and 0 or _x==1 and me or _x==2 and meshW-me or _x==3 and meshW,
                _y==0 and 0 or _y==1 and me or _y==2 and meshH-me or _y==3 and meshH,
                (_x==0 and x or _x==1 and x+ve or _x==2 and x+w-ve or _x==3 and x+w)/tw,
                (_y==0 and y or _y==1 and y+ve or _y==2 and y+h-ve or _y==3 and y+h)/th,
            })
        end
    end
    local mesh=GC.newMesh(meshMap, 'strip', 'static')
    mesh:setTexture(texture)
    mesh:setVertexMap({
        1,5,2,6,3,7,4,8,
        12,7,11,6,10,5,9,
        13,10,14,11,15,12,16,
    })
    return mesh
end

--------------------------------------------------------------
-- Aligning Draw

---Printf a string with 'center' option
---@param obj string | number | table
---@param x number
---@param y number
---@param w? number warping width, default to SCR.w0
function GC.mStr(obj,x,y,w) printf(obj,x-(w or SCR.w0)/2,y,(w or SCR.w0),'center') end

---Draw an object with both middle X & Y
---@param obj love.Texture | love.Drawable
---@param x? number
---@param y? number
---@param r? number
---@param kx? number
---@param ky? number
function GC.mDraw(obj,x,y,r,kx,ky)
    local w,h=obj:getDimensions()
    draw(obj,x,y,r,kx,ky,w*.5,h*.5)
end

---Draw an object with both middle X & Y, clipped with a quad
---@param obj love.Texture | love.Drawable
---@param quad love.Quad
---@param x? number
---@param y? number
---@param r? number
---@param kx? number
---@param ky? number
function GC.mDrawQ(obj,quad,x,y,r,kx,ky)
    local _,_,w,h=quad:getViewport()
    draw(obj,quad,x,y,r,kx,ky,w*.5,h*.5)
end

---Draw an layered obj with both middle X & Y
---@param obj love.Texture
---@param layer number
---@param x? number
---@param y? number
---@param r? number
---@param kx? number
---@param ky? number
function GC.mDrawL(obj,layer,x,y,r,kx,ky)
    local w,h=obj:getDimensions()
    drawL(obj,layer,x,y,r,kx,ky,w*.5,h*.5)
end

---Draw an layered obj with both middle X & Y, clipped with a quad
---@param obj love.Texture
---@param layer number
---@param quad love.Quad
---@param x? number
---@param y? number
---@param r? number
---@param kx? number
---@param ky? number
function GC.mDrawLQ(obj,layer,quad,x,y,r,kx,ky)
    local _,_,w,h=quad:getViewport()
    drawL(obj,layer,quad,x,y,r,kx,ky,w*.5,h*.5)
end

---Draw an object in a rectangle area
---@param obj love.Texture | love.Drawable
---@param x number
---@param y number
---@param w number
---@param h number
function GC.rDraw(obj,x,y,w,h)
    local ow,oh=obj:getDimensions()
    draw(obj,x,y,0,w/ow,h/oh)
end

---Draw an object in a rectangle area, clipped with a quad
---@param obj love.Texture | love.Drawable
---@param quad love.Quad
---@param x number
---@param y number
---@param w number
---@param h number
function GC.rDrawQ(obj,quad,x,y,w,h)
    local _,_,ow,oh=quad:getViewport()
    draw(obj,quad,x,y,0,w/ow,h/oh)
end

---Draw an layered object in a rectangle area
---@param obj love.Texture
---@param layer number
---@param x number
---@param y number
---@param w number
---@param h number
function GC.rDrawL(obj,layer,x,y,w,h)
    local ow,oh=obj:getDimensions()
    drawL(obj,layer,x,y,0,w/ow,h/oh)
end

---Draw an layered object in a rectangle area, clipped with a quad
---@param obj love.Texture
---@param layer number
---@param quad love.Quad
---@param x number
---@param y number
---@param w number
---@param h number
function GC.rDrawLQ(obj,layer,quad,x,y,w,h)
    local _,_,ow,oh=quad:getViewport()
    drawL(obj,layer,quad,x,y,0,w/ow,h/oh)
end

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
---@param strokeMode 'side' | 'corner' | 'full' other values will be treated as 'full'
---@param d number
---@param obj love.Texture | love.Drawable
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
---@param strokeMode? 'side' | 'corner' | 'full' other values will be treated as 'full'
---@param d number
---@param strokeColor? Zenitha.Color Stroke color (default to white)
---@param textColor? Zenitha.Color Center color (leave nil to disable text)
---@param str string
---@param x number
---@param y number
---@param w number? warping width, default to SCR.w0
---@param align? love.AlignMode
---@param r? number rotation
---@param sx? number scale
---@param sy? number scale
---@param ox? number offset
---@param oy? number offset
---@param kx? number shear
---@param ky? number shear
function GC.strokePrint(strokeMode,d,strokeColor,textColor,str,x,y,w,align,r,sx,sy,ox,oy,kx,ky)
    if not w then w=SCR.w0 end
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
---@param rot? number
function GC.regPolygon(mode,x,y,rad,segments,rot)
    if not x then x=0 end
    if not y then y=0 end
    if not rot then rot=0 end

    local l={}
    local rotStep=6.283185307179586/segments
    for i=1,segments do
        l[2*i-1]=x+rad*cos(rot)
        l[2*i]=y+rad*sin(rot)
        rot=rot+rotStep
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
    local rot=phase or 0
    local rotStep=6.283185307179586/segments
    for i=1,segments do
        X[i]=x+rad*cos(rot)
        Y[i]=y+rad*sin(rot)
        rot=rot+rotStep
    end
    X[segments+1]=x+rad*cos(rot)
    Y[segments+1]=y+rad*sin(rot)
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
            rot=rot+rotStep
            local R2=rad-rCorner/cos(halfAng)
            local arcCX,arcCY=x+R2*cos(rot),y+R2*sin(rot)
            arc('line','open',arcCX,arcCY,rCorner,rot-halfAng,rot+halfAng)
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
            rot=rot+rotStep
            local R2=rad-rCorner/cos(halfAng)
            local arcCX,arcCY=x+R2*cos(rot),y+R2*sin(rot)
            arc('fill','open',arcCX,arcCY,rCorner,rot-halfAng,rot+halfAng)
        end
        polygon('fill',L)
    else
        error("GC.regRoundPolygon(mode,...): Draw mode should be 'line' or 'fill'")
    end
end

local fillShader=gc.newShader[[
    uniform float fill;
    vec4 effect(vec4 color, sampler2D tex, vec2 texCoord, vec2 scrCoord) {
        float dist = length(texCoord.xy - 0.5);
        color.a *= smoothstep(0.5, fill, dist);
        return color;
    }
]] fillShader:send('fill',.5)
---(Shader Implementation) Draw a filled circle with blurring edge
---@param solid? number `0`=light, `[1/R,0.5)`=natural (R = blur width in pixel), `[0.5, inf)`=inverted circle (more blurred on larger), `nil`=last value
---@param x number
---@param y number
---@param r number
function GC.blurCircle(solid,x,y,r)
    if solid then
        fillShader:send('fill',solid)
    end
    -- local sd=getShader()
    -- setShader(fillShader)
    -- draw(PAPER,x,y,nil,r*2,nil,.5,.5)
    -- setShader(sd)
    setShader(fillShader)
    draw(PAPER,x,y,nil,r*2,nil,.5,.5)
    setShader()
end

do -- function GC.getScreenShot(table,key) -- Save screenshot as image object to a table
    local _t,_k
    local function _captureFunc(imageData) -- Actually triggered by engine a bit later after calling GC.getScreenShot, because Love2D's capture function doesn't effect instantly
        _t[_k]=gc.newImage(imageData)
    end
    ---@param t table
    ---@param k any
    function GC.getScreenShot(t,k)
        _t,_k=t,k
        gc.captureScreenshot(_captureFunc)
    end
end

---@param canvas love.Canvas
---@param fileName string
---@param format? love.ImageFormat
---@param ... number params for canvas:newImageData, should be `slice(0),mipmapLv(1),x,y,w,h`
function GC.saveCanvas(canvas,fileName,format,...)
    canvas:newImageData(...):encode(format or 'png',fileName)
end

--------------------------------------------------------------
-- Beziers

---@class Zenitha.Curve.Bezier
---@field points Zenitha.Curve.Point[]
---@field curve number[]
local Bezier={}
Bezier.__index=Bezier

---Render the curve to a points list with specific mode
---@param seg number Segments between each data point
---@param dist? number [Second-Processing], Distance between each data point, nil to skip this step
function Bezier:render(seg,dist)
    assert(type(seg)=='number' and seg>0 and seg%1==0,"Bezier:render(seg,dist): seg need positive int")
    local list=self.points
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
        -- TODO: resample by distance
    end
    self.curve=curve
    return curve
end

---@class Zenitha.Curve.Point
---@field [1] number
---@field [2] number
---@field [3]? boolean
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
-- User Coordinate System

local ucsMode,ucsD1,ucsD2

---Move/Scale/Rotate the coordinate system and remember the movement (ONLY ONE TIME)
---
---Only useful when there's only one step, or you should use classical way (`push('transform')`+`pop()`) instead
---@param mode 'm' | 's' | 'r'
---@param d1 number
---@param d2? number not needed for mode 'r'
function GC.ucs_move(mode,d1,d2)
    if mode=='m' then
        gc.translate(d1,d2)
    elseif mode=='s' then
        gc.scale(d1,d2)
    elseif mode=='r' then
        gc.rotate(d1)
    else
        error("GC.ucs_move(mode,...): mode need 'm' | 's' | 'r'")
    end
    ucsMode,ucsD1,ucsD2=mode,d1,d2
end

---Revert ONE STEP of the coordinate system movement, which remembered by GC.ucs_move
function GC.ucs_back()
    if ucsMode=='m' then
        gc.translate(-ucsD1,-ucsD2)
    elseif ucsMode=='s' then
        gc.scale(1/ucsD1,1/ucsD2)
    elseif ucsMode=='r' then
        gc.rotate(-ucsD1)
    end
end

--------------------------------------------------------------
-- Easier Stencil

local gc_stencil,gc_setStencilTest=gc.stencil,gc.setStencilTest

local stc_action,stc_value='replace',1

---Reset stencil states, set default stencil states:
---- draw: 'replace', 1
---- test: 'equal', 1
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

local elps_x,elps_y,elps_rx,elps_ry,elps_seg
local function stencil_ellipse()
    ellipse('fill',elps_x,elps_y,elps_rx,elps_ry,elps_seg)
end
---Draw a circle as stencil
---@param x number
---@param y number
---@param rx number
---@param ry number
---@param seg? number
function GC.stc_elps(x,y,rx,ry,seg)
    elps_x,elps_y,elps_rx,elps_ry,elps_seg=x,y,rx,ry,seg
    gc_stencil(stencil_ellipse,stc_action,stc_value,true)
end

local arc_type,arc_x,arc_y,arc_r,arc_a1,arc_a2,arc_seg
local function stencil_arc()
    arc('fill',arc_type,arc_x,arc_y,arc_r,arc_a1,arc_a2,arc_seg)
end
---Draw a circle as stencil
---@param arcType love.ArcType
---@param x number
---@param y number
---@param a1 number
---@param a2 number
---@param r number
---@param seg? number
function GC.stc_arc(arcType,x,y,a1,a2,r,seg)
    arc_type,arc_x,arc_y,arc_r,arc_a1,arc_a2,arc_seg=arcType,x,y,r,a1,a2,seg
    gc_stencil(stencil_arc,stc_action,stc_value,true)
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
            local rot=math.atan2(self.y0,self.x0)
            self.x0=self.maxDist*math.cos(rot)*self.k0
            self.y0=self.maxDist*math.sin(rot)*self.k0
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
    self.a=MATH.expApproach(self.a,self.a0+(self.swing and self.swing*math.sin(ZENITHA.timer.getTime()/1.26) or 0),dt*self.rotateSpeed)
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
-- TODO: text wraping

local function measureWidth(font,str)
    return newText(font,str):getWidth()
end
function GC.wrapText(font,str,width)
    local list={}

    -- TODO:
    -- use 'measureWidth(font,string)' to measure the width of string
    -- return a table of strings, each of which is no longer than given width

    return list
end

--------------------------------------------------------------
-- Canvas

local initCanvasSetup={stencil=false}
---Create a canvas with specified size, and draw on it with given function
---
---Starting from empty canvas with origin transform. Will restore previous graphics state after done
---@param w number
---@param h number
---@param drawFunc function
---@param stencil? true
---@return love.Canvas
function GC.initCanvas(w,h,drawFunc,stencil)
    initCanvasSetup[1]=gc.newCanvas(w,h)
    initCanvasSetup.stencil=not not stencil
    gc.push()
    gc.origin()
    gc.setCanvas(initCanvasSetup)
    drawFunc()
    gc.pop()
    return initCanvasSetup[1]
end

do -- function GC.load(L), GC.execute(t)
    ---@alias Zenitha.drawingCommand {_help?:Zenitha.Graphics.drawingCommandType, [1]:Zenitha.Graphics.drawingCommandType, [number]:any}

    ---@enum (key) Zenitha.Graphics.drawingCommandType
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
        mDraw=    'mDraw',
        mDrawQ=   'mDrawQ',
        mDrawL=   'mDrawL',
        mDrawLQ=  'mDrawLQ',
        stStr=    'strokePrint',
        stDraw=   'strokeDraw',

        draw=     'draw',
        drawL=    'drawLayer',
        line=     'line',
        fRect=function(...) rectangle('fill',...) end,
        dRect=function(...) rectangle('line',...) end,
        fCirc=function(...) circle('fill',...) end,
        dCirc=function(...) circle('line',...) end,
        fElps=function(...) ellipse('fill',...) end,
        dElps=function(...) ellipse('line',...) end,
        fPoly=function(...) polygon('fill',...) end,
        dPoly=function(...) polygon('line',...) end,

        fPie=function(...) arc('fill',...) end,
        dPie=function(...) arc('line',...) end,
        fArc=function(...) arc('fill','open',...) end,
        dArc=function(...) arc('line','open',...) end,
        fBow=function(...) arc('fill','closed',...) end,
        dBow=function(...) arc('line','closed',...) end,

        fMRect=function(...) GC.mRect('fill',...) end,
        dMRect=function(...) GC.mRect('line',...) end,
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
    ---See commands list by going to declaration of this function, then scroll up
    ---
    ---### Example
    ---```
    ---GC.execute{
    ---    {'setCL',1,0,0},
    ---    {'dRect','fill',0,0,100,100},
    ---    {'setCL',1,1,0},
    ---    {'dCirc','fill',50,50,40},
    ---}
    ---```
    ---@param t Zenitha.drawingCommand[]
    function GC.execute(t) GC_execute(t) end

    local sizeLimit=gc.getSystemLimits().texturesize
    ---Similar to GC.execute, but draw on a canvas
    ---
    ---### Example
    ---```
    ---GC.load{w=100,h=100 -- size of canvas, h is optional (default to w)
    ---    {'setCL',1,0,0},
    ---    {'dRect','fill',0,0,100,100},
    ---    {'setCL',1,1,0},
    ---    {'dCirc','fill',50,50,40},
    ---} --> canvas
    ---```
    ---@param list {w:number, h:number, [number]:Zenitha.drawingCommand}
    function GC.load(list)
        local w=tonumber(list.w)
        local h=tonumber(list.h) or w
        assert(w and h and w>0 and h>0 and w%1==0 and h%1==0,"GC.load(L): L.w (and L.h) must be positive integer")
        gc.push()
            local canvas
            while true do
                local suc
                suc,canvas=pcall(gc.newCanvas,math.min(w,sizeLimit),math.min(h,sizeLimit))
                if suc then
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
                    if not cmds[cmd] then error("GC.load(L): No gc command: "..cmd) end
                    cmd=cmds[cmd](unpack(code,2))
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
