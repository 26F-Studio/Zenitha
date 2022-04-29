local gc=love.graphics
local setColor,prints,printf,draw=gc.setColor,gc.print,gc.printf,gc.draw
local line,arc,polygon=gc.line,gc.arc,gc.polygon
local sin,cos=math.sin,math.cos
local pcall=pcall
local NULL=NULL

local GC={}
function GC.mStr(obj,x,y) printf(obj,x-626,y,1252,'center') end-- Printf a string with 'center'
function GC.simpX(obj,x,y) draw(obj,x-obj:getWidth()*.5,y) end-- Simply draw an obj with x=obj:getWidth()/2
function GC.simpY(obj,x,y) draw(obj,x,y-obj:getHeight()*.5) end-- Simply draw an obj with y=obj:getWidth()/2
function GC.X(obj,x,y,a,k) draw(obj,x,y,a,k,nil,obj:getWidth()*.5,0) end-- Draw an obj with x=obj:getWidth()/2
function GC.Y(obj,x,y,a,k) draw(obj,x,y,a,k,nil,0,obj:getHeight()*.5) end-- Draw an obj with y=obj:getWidth()/2
function GC.draw(obj,x,y,a,k) draw(obj,x,y,a,k,nil,obj:getWidth()*.5,obj:getHeight()*.5) end-- Draw an obj with both middle X & Y

--------------------------------------------------------------

function GC.safePrint(...)
    return pcall(prints,...)
end
function GC.safePrintf(...)
    return pcall(printf,...)
end
function GC.outDraw(obj,x,y,a,k,d,shadeCount)
    local w,h=obj:getWidth()*.5,obj:getHeight()*.5
    if shadeCount==4 then
        draw(obj,x-d,y-d,a,k,nil,w,h)
        draw(obj,x-d,y+d,a,k,nil,w,h)
        draw(obj,x+d,y-d,a,k,nil,w,h)
        draw(obj,x+d,y+d,a,k,nil,w,h)
    elseif shadeCount==8 then
        draw(obj,x-d,y-d,a,k,nil,w,h)
        draw(obj,x-d,y+d,a,k,nil,w,h)
        draw(obj,x+d,y-d,a,k,nil,w,h)
        draw(obj,x+d,y+d,a,k,nil,w,h)
        draw(obj,x-d,y,a,k,nil,w,h)
        draw(obj,x+d,y,a,k,nil,w,h)
        draw(obj,x,y-d,a,k,nil,w,h)
        draw(obj,x,y+d,a,k,nil,w,h)
    end
end
function GC.shadedPrint(str,x,y,mode,d,shadeCount,c1,c2)
    local w=1280
    if mode=='center' then
        x=x-w*.5
    elseif mode=='right' then
        x=x-w
    end
    if not d then d=1 end
    setColor(c1 or COLOR.D)
    if shadeCount==4 then
        printf(str,x-d,y-d,w,mode)
        printf(str,x-d,y+d,w,mode)
        printf(str,x+d,y-d,w,mode)
        printf(str,x+d,y+d,w,mode)
    elseif shadeCount==8 then
        printf(str,x-d,y-d,w,mode)
        printf(str,x-d,y+d,w,mode)
        printf(str,x+d,y-d,w,mode)
        printf(str,x+d,y+d,w,mode)
        printf(str,x-d,y,w,mode)
        printf(str,x+d,y,w,mode)
        printf(str,x,y-d,w,mode)
        printf(str,x,y+d,w,mode)
    else
        error('shadeCount(6th arg) must be 4 or 8')
    end
    setColor(c2 or COLOR.L)
    printf(str,x,y,w,mode)
end
function GC.regPolygon(mode,x,y,R,segments,phase)
    local l={}
    local ang=phase or 0
    local angStep=6.283185307179586/segments
    for i=1,segments do
        l[2*i-1]=x+R*cos(ang)
        l[2*i]=y+R*sin(ang)
        ang=ang+angStep
    end
    polygon(mode,l)
end
function GC.regRoundPolygon(mode,x,y,R,segments,r,phase)
    local X,Y={},{}
    local ang=phase or 0
    local angStep=6.283185307179586/segments
    for i=1,segments do
        X[i]=x+R*cos(ang)
        Y[i]=y+R*sin(ang)
        ang=ang+angStep
    end
    X[segments+1]=x+R*cos(ang)
    Y[segments+1]=y+R*sin(ang)
    local halfAng=6.283185307179586/segments/2
    local erasedLen=r*math.tan(halfAng)
    if mode=='line' then
        erasedLen=erasedLen+1-- Fix 1px cover
        for i=1,segments do
            -- Line
            local x1,y1,x2,y2=X[i],Y[i],X[i+1],Y[i+1]
            local dir=math.atan2(y2-y1,x2-x1)
            line(x1+erasedLen*cos(dir),y1+erasedLen*sin(dir),x2-erasedLen*cos(dir),y2-erasedLen*sin(dir))

            -- Arc
            ang=ang+angStep
            local R2=R-r/cos(halfAng)
            local arcCX,arcCY=x+R2*cos(ang),y+R2*sin(ang)
            arc('line','open',arcCX,arcCY,r,ang-halfAng,ang+halfAng)
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
            local R2=R-r/cos(halfAng)
            local arcCX,arcCY=x+R2*cos(ang),y+R2*sin(ang)
            arc('fill','open',arcCX,arcCY,r,ang-halfAng,ang+halfAng)
        end
        polygon('fill',L)
    else
        error("Draw mode should be 'line' or 'fill'")
    end
end
do-- function GC.getScreenShot()
    local capturedImage
    local function _captureScreenshotFunc(imageData) capturedImage=gc.newImage(imageData) end
    function GC.getScreenShot()
        gc.captureScreenshot(_captureScreenshotFunc)
        return capturedImage
    end
end

--------------------------------------------------------------

local gc_stencil,gc_setStencilTest=gc.stencil,gc.setStencilTest
local gc_rectangle,gc_circle=gc.rectangle,gc.circle

local stc_action,stc_value='replace',1

function GC.stc_reset()
    stc_action,stc_value='replace',1
    gc_setStencilTest('equal',1)
    gc_stencil(NULL)
end
function GC.stc_setComp(compMode,compVal)
    gc_setStencilTest(compMode or 'equal',compVal or 1)
end
function GC.stc_setPen(action,val)
    stc_action,stc_value=action,val
end
function GC.stc_stop()
    gc_setStencilTest()
end

local rect_x,rect_y,rect_w,rect_h
local function stencil_rectangle()
    gc_rectangle('fill',rect_x,rect_y,rect_w,rect_h)
end

function GC.stc_rect(x,y,w,h)
    rect_x,rect_y,rect_w,rect_h=x,y,w,h
    gc_stencil(stencil_rectangle,stc_action,stc_value,true)
end

local circle_x,circle_y,circle_r,circle_seg
local function stencil_circle()
    gc_circle('fill',circle_x,circle_y,circle_r,circle_seg)
end

function GC.stc_circ(x,y,r,seg)
    circle_x,circle_y,circle_r,circle_seg=x,y,r,seg
    gc_stencil(stencil_circle,stc_action,stc_value,true)
end

--------------------------------------------------------------

do-- function GC.load(L), GC.execute(t)
    local cmds={
        push=     gc.push,
        pop=      gc.pop,

        repT=     gc.replaceTransform,
        appT=     gc.applyTransform,
        invT=     gc.inverseTransformPoint,

        origin=   gc.origin,
        move=     gc.translate,
        scale=    gc.scale,
        rotate=   gc.rotate,
        shear=    gc.shear,
        clear=    gc.clear,

        setCL=    gc.setColor,
        setCM=    gc.setColorMask,
        setLW=    gc.setLineWidth,
        setLS=    gc.setLineStyle,
        setLJ=    gc.setLineJoin,
        setBM=    gc.setBlendMode,
        setSD=    gc.setShader,

        print=    gc.print,
        rawFT=    function(...) FONT.rawset(...) end,
        setFT=    function(...) FONT.set(...) end,
        mText=    GC.mStr,
        mDraw=    GC.draw,
        mDrawX=   GC.X,
        mDrawY=   GC.Y,
        mOutDraw= GC.outDraw,

        draw=     gc.draw,
        line=     line,
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
            error('Wrong type of [1]')
        end
    end
    GC.execute=GC_execute

    local sizeLimit=gc.getSystemLimits().texturesize
    function GC.load(L)
        assert(type(L[1])=='number' and type(L[2])=='number',"function GC.load(L): L[1] and L[2] must be positive number")
        gc.push()
            local canvas
            while true do
                local success
                success,canvas=pcall(gc.newCanvas,math.min(L[1],sizeLimit),math.min(L[2],sizeLimit))
                if success then
                    break
                else
                    sizeLimit=math.floor(sizeLimit*.8)
                    assert(sizeLimit>=1,"WTF why can't I create a canvas?")
                end
            end
            gc.setCanvas(canvas)
            gc.clear(1,1,1,0)
            gc.origin()
            gc.setColor(1,1,1)
            gc.setLineWidth(1)
            for i=3,#L do
                local cmd=L[i][1]
                if type(cmd)=='string' then
                    cmd=assert(cmds[cmd],"No gc command: "..cmd)(unpack(L[i],2))
                elseif type(cmd)=='function' then
                    cmd(unpack(L[i],2))
                else
                    error("cmd must be string or function")
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
