local gc_translate,gc_scale,gc_replaceTransform=GC.translate,GC.scale,GC.replaceTransform
local gc_push,gc_pop=GC.push,GC.pop
local gc_setColor,gc_setLineWidth=GC.setColor,GC.setLineWidth
local gc_draw,gc_line=GC.draw,GC.line
local gc_rectangle,gc_circle=GC.rectangle,GC.circle
local gc_print,gc_printf=GC.print,GC.printf

local kb=love.keyboard
local timer=love.timer.getTime

local assert,next=assert,next
local floor,ceil=math.floor,math.ceil
local max,min=math.max,math.min
local abs=math.abs
local sub,ins,rem=string.sub,table.insert,table.remove

local SCN,SCR,xOy=SCN,SCR,SCR.xOy
local setFont,getFont=FONT.set,FONT.get
local mStr=GC.mStr
local GC_stc_reset,GC_stc_setComp,GC_stc_stop=GC.stc_reset,GC.stc_setComp,GC.stc_stop
local GC_stc_circ,GC_stc_rect=GC.stc_circ,GC.stc_rect

local indexMeta={
    __index=function(L,k)
        for i=1,#L do
            if L[i].name==k then
                return L[i]
            end
        end
    end
}
local onChange=NULL
local widgetCanvas

local function updateWheel(self,d)
    self._floatWheel=self._floatWheel+(d or 0)
    if abs(self._floatWheel)>=1 then
        local n=MATH.sign(self._floatWheel)*floor(abs(self._floatWheel))
        self._floatWheel=self._floatWheel-n
        return n
    end
end
local function alignDraw(self,drawable,x,y,ang,image_k)
    local w=drawable:getWidth()
    local h=drawable:getHeight()
    local k=image_k or min(self.widthLimit/w,1)
    local ox=self.alignX=='left' and 0 or self.alignX=='right' and w or w*.5
    local oy=self.alignY=='up' and 0 or self.alignY=='down' and h or h*.5
    gc_draw(drawable,x,y,ang,k,1,ox,oy)
end

local Widgets={}
local WIDGET={_prototype=Widgets}

--------------------------------------------------------------

-- base (not used by user)
Widgets.base={
    type='null',
    name=false,
    keepFocus=false,
    x=0,y=0,

    color='L',
    color_fill='lS',
    pos=false,
    lineWidth=4,
    fontSize=30,fontType=false,
    widthLimit=1e99,

    isAbove=NULL,
    visibleFunc=false,-- function return a boolean

    _hoverTime=0,
    _hoverTimeMax=.1,
    _pressed=false,
    _pressTime=0,
    _pressTimeMax=.05,
    _visible=nil,
}
function Widgets.base:getInfo()
    local str=''
    for _,v in next,self.buildArgs do
        str=str..v..'='..tostring(self[v])..'\n'
    end
    return str
end
function Widgets.base:reset()
    assert(not self.name or type(self.name)=='string','[widget].name can only be a string')

    assert(type(self.x)=='number','[widget].x must be number')
    assert(type(self.y)=='number','[widget].y must be number')
    if type(self.color)=='string' then self.color=COLOR[self.color] end
    assert(type(self.color)=='table','[widget].color must be table')
    if type(self.color_fill)=='string' then self.color_fill=COLOR[self.color_fill] end
    assert(type(self.color_fill)=='table','[switch].color_fill must be table')

    if self.pos then
        assert(
            type(self.pos)=='table' and
            (type(self.pos[1])=='number' or self.pos[1]==false) and
            (type(self.pos[2])=='number' or self.pos[2]==false),
            "[widget].pos[1] and [2] must be [number] or false}"
        )
        self._x=self.x+(self.pos[1] and self.pos[1]*(SCR.w0+2*SCR.x/SCR.k)-SCR.x/SCR.k or 0)
        self._y=self.y+(self.pos[2] and self.pos[2]*(SCR.h0+2*SCR.y/SCR.k)-SCR.y/SCR.k or 0)
    else
        self._x=self.x
        self._y=self.y
    end

    assert(type(self.fontSize)=='number','[widget].fontSize must be number')
    assert(type(self.fontType)=='string' or self.fontType==false,'[widget].fontType must be string')
    assert(type(self.widthLimit)=='number','[widget].widthLimit must be number')
    assert(not self.visibleFunc or type(self.visibleFunc)=='function','[widget].visibleFunc can only be a function')

    self._text=self.text or self.name and ('['..self.name..']')
    if self._text then
        if type(self._text)=='function' then
            self._text=self._text()
            assert(type(self._text)=='string','function text must return a string')
        else
            assert(type(self._text)=='string','[widget].text must be string or function return a string')
        end
        self._text=GC.newText(getFont(self.fontSize,self.fontType),self._text)
    else
        self._text=PAPER
    end

    self._image=nil
    if self.image then
        if type(self.image)=='string' then
            self._image=IMG[self.image] or PAPER
        else
            self._image=self.image
        end
    end

    self._hoverTime=0

    if self.visibleFunc then
        self._visible=self.visibleFunc()
    elseif self._visible==nil then
        self._visible=true
    end
end
function Widgets.base:setVisible(bool)
    self._visible=bool and true or false
end
function Widgets.base:update(dt)
    if self._pressed then
        self._pressTime=min(self._pressTime+dt,self._pressTimeMax)
    else
        self._pressTime=max(self._pressTime-dt,0)
    end
    if WIDGET.sel==self then
        self._hoverTime=min(self._hoverTime+dt,self._hoverTimeMax)
    else
        self._hoverTime=max(self._hoverTime-dt,0)
    end
end
function Widgets.base.press()   end
function Widgets.base.release() end
function Widgets.base.drag()    end
function Widgets.base.scroll()  end


-- text
Widgets.text=setmetatable({
    type='text',

    text=false,
    alignX='center',alignY='center',

    _text=nil,

    buildArgs={
        'name',
        'pos',
        'x','y',

        'color','text',
        'fontSize','fontType',

        'alignX','alignY',
        'widthLimit',

        'visibleFunc',
    }
},{__index=Widgets.base,__metatable=true})
function Widgets.text:reset()
    Widgets.base.reset(self)
end
function Widgets.text:draw()
    if self._text then
        gc_setColor(self.color)
        alignDraw(self,self._text,self._x,self._y)
    end
end


-- image
Widgets.image=setmetatable({
    type='image',
    ang=0,k=1,

    image=false,
    alignX='center',alignY='center',

    _image=nil,

    buildArgs={
        'name',
        'pos',
        'x','y',

        'ang','k',
        'image',
        'alignX','alignY',

        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.image:draw()
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._text,self._x,self._y,self.ang,self.k)
    end
end


-- button
Widgets.button=setmetatable({
    type='button',
    w=40,h=false,

    text=false,
    image=false,
    alignX='center',alignY='center',
    cornerR=10,
    sound=false,

    code=NULL,

    _text=nil,
    _image=nil,
    _pressed=false,

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',
        'lineWidth','cornerR',
        'alignX','alignY',
        'text','image',
        'color',
        'fontSize','fontType',
        'sound',

        'code',
        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.button:reset()
    Widgets.base.reset(self)
    if not self.h then self.h=self.w end
    assert(self.w and type(self.w)=='number','[inputBox].w must be number')
    assert(self.h and type(self.h)=='number','[inputBox].h must be number')
    self.widthLimit=self.w
end
function Widgets.button:isAbove(x,y)
    return
        abs(x-self._x)<self.w*.5 and
        abs(y-self._y)<self.h*.5
end
function Widgets.button:press()
    self._pressed=true
end
function Widgets.button:release(x,y,k)
    self._pressed=false
    if self:isAbove(x,y) then
        if self.sound then
            SFX.play(self.sound)
        end
        self.code(k)
    end
end
function Widgets.button:drag(x,y)
    if not self:isAbove(x,y) and self==WIDGET.sel then
        WIDGET.unFocus()
        self._pressed=false
    end
end
function Widgets.button:draw()
    gc_push('transform')
    gc_translate(self._x,self._y)

    if self._pressTime>0 then
        gc_scale(1-self._pressTime/self._pressTimeMax*.0626)
    end
    local w,h=self.w,self.h

    local c=self.color

    -- Background
    gc_setColor(c[1],c[2],c[3],.1+.2*self._hoverTime/self._hoverTimeMax)
    gc_rectangle('fill',-w*.5,-h*.5,w,h,self.cornerR)

    -- Frame
    gc_setLineWidth(self.lineWidth)
    gc_setColor(.2+c[1]*.8,.2+c[2]*.8,.2+c[3]*.8,.95)
    gc_rectangle('line',-w*.5,-h*.5,w,h,self.cornerR)

    -- Drawable
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image)
    end
    if self._text then
        gc_setColor(c)
        alignDraw(self,self._text)
    end
    gc_pop()
end

-- button_fill
Widgets.button_fill=setmetatable({
    type='button_fill',
    color_text=TABLE.shift(COLOR.L),
    buildArgs=TABLE.combine(Widgets.button.buildArgs,{'color_text'}),
},{__index=Widgets.button,__metatable=true})
function Widgets.button_fill:draw()
    gc_push('transform')
    gc_translate(self._x,self._y)

    if self._pressTime>0 then
        gc_scale(1-self._pressTime/self._pressTimeMax*.0626)
    end

    local w,h=self.w,self.h
    local HOV=self._hoverTime/self._hoverTimeMax

    local c=self.color
    local r,g,b=c[1],c[2],c[3]

    -- Rectangle
    gc_setColor(.15+r*.7*(1-HOV*.26),.15+g*.7*(1-HOV*.26),.15+b*.7*(1-HOV*.26),.9)
    gc_rectangle('fill',-w*.5,-h*.5,w,h,self.cornerR)

    -- Drawable
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image)
    end
    if self._text then
        gc_setColor(self.color_text)
        alignDraw(self,self._text)
    end
    gc_pop()
end

-- button_invis
Widgets.button_invis=setmetatable({
    type='button_invis',
},{__index=Widgets.button,__metatable=true})
function Widgets.button_invis:release(x,y,k)
    self._pressed=false
    if self:isAbove(x,y) then
        self.code(k)
    end
end
function Widgets.button_invis:draw()
    gc_push('transform')
    gc_translate(self._x,self._y)

    local w,h=self.w,self.h
    local HOV=self._hoverTime/self._hoverTimeMax

    local c=self.color

    -- Rectangle
    gc_setColor(c[1],c[2],c[3],HOV*.16)
    gc_rectangle('fill',-w*.5,-h*.5,w,h,self.cornerR)

    -- Drawable
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image)
    end
    if self._text then
        gc_setColor(c)
        alignDraw(self,self._text)
    end
    gc_pop()
end


-- checkBox
Widgets.checkBox=setmetatable({
    type='checkBox',
    w=30,

    text=false,
    image=false,
    alignX='center',alignY='center',
    labelPos='right',
    labelDistance=20,
    cornerR=3,
    sound_on=false,sound_off=false,

    disp=false,-- function return a boolean
    code=NULL,

    _text=nil,
    _image=nil,

    buildArgs={
        'name',
        'pos',
        'x','y','w',
        'lineWidth','cornerR',

        'labelPos',
        'labelDistance',
        'color','text',
        'fontSize','fontType',
        'widthLimit',
        'sound_on','sound_off',

        'disp','code',
        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.checkBox:reset()
    Widgets.base.reset(self)
    if self.labelPos=='left' then
        self.alignX='right'
    elseif self.labelPos=='right' then
        self.alignX='left'
    elseif self.labelPos=='up' then
        self.alignY='down'
    elseif self.labelPos=='down' then
        self.alignY='up'
    else
        error("[checkBox].labelPos must be 'left', 'right', 'up', or 'down'")
    end
end
function Widgets.checkBox:isAbove(x,y)
    return
        self.disp and
        abs(x-self._x)<self.w*.5 and
        abs(y-self._y)<self.w*.5
end
function Widgets.checkBox:press(_,_,k)
    self.code(k)
    if self.disp() then
        if self.sound_on then
            SFX.play(self.sound_on)
        end
    else
        if self.sound_off then
            SFX.play(self.sound_off)
        end
    end
end
function Widgets.checkBox:draw()
    gc_push('transform')
    gc_translate(self._x,self._y)
    local w=self.w
    local HOV=self._hoverTime/self._hoverTimeMax

    local c=self.color

    if self.disp then
        -- Background
        gc_setColor(c[1],c[2],c[3],.3*HOV)
        gc_rectangle('fill',-w*.5,-w*.5,w,w,self.cornerR)

        -- Frame
        gc_setLineWidth(self.lineWidth)
        gc_setColor(.2+c[1]*.8,.2+c[2]*.8,.2+c[3]*.8)
        gc_rectangle('line',-w*.5,-w*.5,w,w,self.cornerR)
        if self.disp() then
            gc_scale(.5*w)
            gc_setLineWidth(self.lineWidth*2/w)
            gc_line(-.7,.05,-.2,.5,.7,-.55)
            gc_scale(2/w)
        end
    end

    -- Drawable
    local x2,y2=0,0
    if self.labelPos=='left' then
        x2=-w*.5-self.labelDistance
    elseif self.labelPos=='right' then
        x2=w*.5+self.labelDistance
    elseif self.labelPos=='up' then
        y2=-w*.5-self.labelDistance
    elseif self.labelPos=='down' then
        y2=w*.5+self.labelDistance
    end
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image,x2,y2)
    end
    if self._text then
        gc_setColor(c)
        alignDraw(self,self._text,x2,y2)
    end
    gc_pop()
end


-- switch
Widgets.switch=setmetatable({
    type='checkBox',
    h=30,

    text=false,
    image=false,
    alignX='center',alignY='center',
    labelPos='right',
    labelDistance=20,
    sound_on=false,sound_off=false,

    disp=false,-- function return a boolean
    code=NULL,

    _text=nil,
    _image=nil,

    _slideTime=nil,

    buildArgs={
        'name',
        'pos',
        'x','y','h',

        'labelPos',
        'labelDistance',
        'color','color_fill',
        'text','fontSize','fontType',
        'lineWidth','widthLimit',
        'sound_on','sound_off',

        'disp','code',
        'visibleFunc',
    },
},{__index=Widgets.checkBox,__metatable=true})
function Widgets.switch:reset()
    Widgets.base.reset(self)

    self._slideTime=0
    if self.labelPos=='left' then
        self.alignX='right'
    elseif self.labelPos=='right' then
        self.alignX='left'
    elseif self.labelPos=='up' then
        self.alignY='down'
    elseif self.labelPos=='down' then
        self.alignY='up'
    else
        error("[switch].labelPos must be 'left', 'right', 'up', or 'down'")
    end
end
function Widgets.switch:isAbove(x,y)
    return
        self.disp and
        abs(x-self._x)<self.h and
        abs(y-self._y)<self.h*.5
end
function Widgets.switch:update(dt)
    Widgets.base.update(self,dt)
    if self.disp() then
        self._slideTime=min(self._slideTime+dt,self._hoverTimeMax/2)
    else
        self._slideTime=max(self._slideTime-dt,-self._hoverTimeMax/2)
    end
end
function Widgets.switch:draw()
    gc_push('transform')
    gc_translate(self._x,self._y)
    local h=self.h
    local HOV=self._hoverTime/self._hoverTimeMax

    local c=self.color

    if self.disp then
        -- Background
        gc_setColor(self.color_fill[1],self.color_fill[2],self.color_fill[3],self._slideTime/self._hoverTimeMax+.5)
        gc_rectangle('fill',-h,-h*.5,h*2,h,h*.5)

        -- Frame
        gc_setLineWidth(self.lineWidth)
        gc_setColor(.2+c[1]*.8,.2+c[2]*.8,.2+c[3]*.8,.8+.2*HOV)
        gc_rectangle('line',-h,-h*.5,h*2,h,h*.5)

        -- Axis
        gc_setColor(1,1,1,.8+.2*HOV)
        gc_circle('fill',h*(self._slideTime/self._hoverTimeMax),0,h*(.35+HOV*.05))
    end

    -- Drawable
    local x2,y2=0,0
    if self.labelPos=='left' then
        x2=-h-self.labelDistance
    elseif self.labelPos=='right' then
        x2=h+self.labelDistance
    elseif self.labelPos=='up' then
        y2=-h*.5-self.labelDistance
    elseif self.labelPos=='down' then
        y2=h*.5+self.labelDistance
    end
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image,x2,y2)
    end
    if self._text then
        gc_setColor(c)
        alignDraw(self,self._text,x2,y2)
    end
    gc_pop()
end


-- slider
Widgets.slider=setmetatable({
    type='slider',
    w=100,
    axis={0,1},
    smooth=nil,

    text=false,
    image=false,
    labelPos='left',
    labelDistance=20,
    cornerR=3,
    valueShow=nil,

    disp=false,-- function return the displaying _value
    code=NULL,

    _floatWheel=0,
    _text=nil,
    _image=nil,
    _showFunc=nil,
    _pos=nil,
    _rangeL=nil,
    _rangeR=nil,
    _rangeWidth=nil,
    _unit=nil,
    _smooth=nil,
    _textShowTime=nil,

    buildArgs={
        'name',
        'pos',
        'x','y','w',
        'lineWidth','cornerR',

        'axis','smooth',
        'labelPos',
        'labelDistance',
        'color','text',
        'fontSize','fontType',
        'widthLimit',

        'valueShow',
        'disp','code',
        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
local sliderShowFunc={
    null=function()
        return ''
    end,
    int=function(S)
        return S.disp()
    end,
    float=function(S)
        return floor(S.disp()*100+.5)*.01
    end,
    percent=function(S)
        return floor(S.disp()*100+.5)..'%'
    end,
}
function Widgets.slider:reset()
    Widgets.base.reset(self)

    assert(type(self.disp)=='function','[slider].disp must be function')

    assert(
        type(self.axis)=='table' and (#self.axis==2 or #self.axis==3) and
        type(self.axis[1])=='number' and
        type(self.axis[2])=='number' and
        (not self.axis[3] or type(self.axis[3])=='number'),
        "[slider].axis must be {low,high} or {low,high,unit}"
    )
    self._rangeL=self.axis[1]
    self._rangeR=self.axis[2]
    self._rangeWidth=self._rangeR-self._rangeL
    self._unit=self.axis[3]
    if self.smooth~=nil then
        self._smooth=self.smooth
    else
        self._smooth=not self.axis[3]
    end
    self._pos=self._rangeL
    self._textShowTime=3

    if self.valueShow then
        if type(self.valueShow)=='function' then
            self._showFunc=self.valueShow
        elseif type(self.valueShow)=='string' then
            self._showFunc=assert(sliderShowFunc[self.valueShow],"[slider].valueShow must be function, or 'int', 'float', or 'percent'")
        end
    elseif self.valueShow==false then-- Show nothing if false
        self._showFunc=sliderShowFunc.null
    else-- Use default if nil
        if self._unit and self._unit%1==0 then
            self._showFunc=sliderShowFunc.int
        else
            self._showFunc=sliderShowFunc.percent
        end
    end

    if self.labelPos=='left' then
        self.alignX='right'
    elseif self.labelPos=='right' then
        self.alignX='left'
    elseif self.labelPos=='down' then
        self.alignY='up'
        self.labelDistance=max(self.labelDistance,20)
    else
        error("[slider].labelPos must be 'left', 'right', or 'down'")
    end
end
function Widgets.slider:isAbove(x,y)
    return
        x>self._x-10 and
        x<self._x+self.w+10 and
        abs(y-self._y)<25
end
function Widgets.slider:update(dt)
    Widgets.base.update(self,dt)
    if self._visible then
        self._pos=MATH.expApproach(self._pos,self.disp(),dt*26)
    end
    if WIDGET.sel==self then
        self._textShowTime=2
    end
    self._textShowTime=max(self._textShowTime-dt,0)
end
function Widgets.slider:draw()
    local x,y=self._x,self._y
    local HOV=self._hoverTime/self._hoverTimeMax
    local x2=x+self.w
    local rangeL,rangeR=self._rangeL,self._rangeR

    gc_setColor(1,1,1,.5+HOV*.36)

    -- Units
    if not self._smooth then
        gc_setLineWidth(self.lineWidth)
        for p=rangeL,rangeR,self._unit do
            local X=x+(x2-x)*(p-rangeL)/self._rangeWidth
            gc_line(X,y+7,X,y-7)
        end
    end

    -- Axis
    gc_setLineWidth(self.lineWidth*2)
    gc_line(x,y,x2,y)

    -- Block
    local pos=MATH.clamp(self._pos,rangeL,rangeR)
    local cx=x+(x2-x)*(pos-rangeL)/self._rangeWidth
    local bx,by=cx-10-HOV*2,y-16-HOV*5
    local bw,bh=20+HOV*4,32+HOV*10
    gc_setColor(pos==self._pos and COLOR.DL or COLOR.lR)
    gc_rectangle('fill',bx,by,bw,bh,self.cornerR)

    -- Glow
    if HOV>0 then
        gc_setLineWidth(self.lineWidth*.5)
        gc_setColor(1,1,1,HOV*.8)
        gc_rectangle('line',bx+1,by+1,bw-2,bh-2,self.cornerR)
    end

    -- Float text
    if self._textShowTime>0 then
        setFont(25)
        gc_setColor(1,1,1,min(self._textShowTime/2,1))
        mStr(self:_showFunc(),cx,by-30)
    end

    -- Drawable
    if self._text then
        gc_setColor(COLOR.L)
        if self.labelPos=='left' then
            alignDraw(self,self._text,x-self.labelDistance,y)
        elseif self.labelPos=='right' then
            alignDraw(self,self._text,x+self.w+self.labelDistance,y)
        elseif self.labelPos=='down' then
            alignDraw(self,self._text,x+self.w*.5,y+self.labelDistance)
        end
    end
end
function Widgets.slider:press(x)
    self:drag(x)
end
function Widgets.slider:drag(x)
    if not x then return end
    x=x-self._x
    local newPos=MATH.clamp(x/self.w,0,1)
    local newVal
    if not self._unit then
        newVal=(1-newPos)*self._rangeL+newPos*self._rangeR
    else
        newVal=newPos*self._rangeWidth
        newVal=self._rangeL+floor(newVal/self._unit+.5)*self._unit
    end
    if newVal~=self.disp() then
        self.code(newVal)
    end
end
function Widgets.slider:scroll(dx,dy)
    local n=updateWheel(self,(dx+dy)*self._rangeWidth/(self._unit or .01)/20)
    if n then
        local p=self.disp()
        local u=self._unit or .01
        local P=MATH.clamp(p+u*n,self._rangeL,self._rangeR)
        if p==P or not P then return end
        self.code(P)
    end
end
function Widgets.slider:arrowKey(k)
    self:scroll((k=='left' or k=='up') and -1 or 1,0)
end


-- slider_fill
Widgets.slider_fill=setmetatable({
    type='slider_fill',
    w=100,h=40,
    axis={0,1},

    text=false,
    image=false,
    labelPos='left',
    labelDistance=20,
    lineDist=3,

    disp=false,-- function return the displaying _value
    code=NULL,

    _text=nil,
    _image=nil,
    _pos=nil,
    _rangeL=nil,
    _rangeR=nil,
    _rangeWidth=nil,-- just _rangeR-_rangeL, for convenience

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',

        'axis',
        'labelPos',
        'labelDistance',
        'lineWidth','lineDist',
        'text','fontSize','fontType',
        'widthLimit',

        'disp','code',
        'visibleFunc',
    },
},{__index=Widgets.slider,__metatable=true})
function Widgets.slider_fill:reset()
    Widgets.base.reset(self)

    assert(self.w and type(self.w)=='number','[inputBox].w must be number')
    assert(self.h and type(self.h)=='number','[inputBox].h must be number')
    assert(type(self.disp)=='function','[slider].disp must be function')

    assert(
        type(self.axis)=='table' and #self.axis==2 and
        type(self.axis[1])=='number' and
        type(self.axis[2])=='number',
        "[slider].axis must be {number,number}"
    )
    self._rangeL=self.axis[1]
    self._rangeR=self.axis[2]
    self._rangeWidth=self._rangeR-self._rangeL
    self._pos=self._rangeL
    self._textShowTime=3

    if self.labelPos=='left' then
        self.alignX='right'
    elseif self.labelPos=='right' then
        self.alignX='left'
    elseif self.labelPos=='down' then
        self.alignY='up'
        self.labelDistance=max(self.labelDistance,20)
    else
        error("[slider_fill].labelPos must be 'left','right' or 'down'")
    end
end
function Widgets.slider_fill:isAbove(x,y)
    return
        x>self._x and
        x<self._x+self.w and
        abs(y-self._y)<self.h*.5
end
function Widgets.slider_fill:draw()
    local x,y=self._x,self._y
    local w,h=self.w,self.h
    local r=h*.5
    local HOV=self._hoverTime/self._hoverTimeMax
    local rate=(self._pos-self._rangeL)/self._rangeWidth
    local num=floor((self.disp()-self._rangeL)/self._rangeWidth*100+.5)..'%'

    -- Capsule
    gc_setColor(1,1,1,.6+HOV*.26)
    gc_setLineWidth(self.lineWidth+HOV)
    gc_rectangle('line',x-self.lineDist,y-r-self.lineDist,w+2*self.lineDist,h+2*self.lineDist,r+self.lineDist)
    if HOV>0 then
        gc_setColor(1,1,1,HOV*.12)
        gc_rectangle('fill',x-self.lineDist,y-r-self.lineDist,w+2*self.lineDist,h+2*self.lineDist,r+self.lineDist)
    end

    -- Stenciled capsule and text
    GC_stc_reset()
    GC_stc_rect(x+r,y-r,w-h,h)
    GC_stc_circ(x+r,y,r)
    GC_stc_circ(x+w-r,y,r)

    setFont(30)
    gc_setColor(1,1,1,.75+HOV*.26)
    mStr(num,x+w*.5,y-18)
    gc_rectangle('fill',x,y-r,w*rate,h)

    GC_stc_reset()
    GC_stc_rect(x,y-r,w*rate,h)
    gc_setColor(0,0,0,.9)
    mStr(num,x+w*.5,y-18)
    GC_stc_stop()

    -- Drawable
    if self._text then
        gc_setColor(COLOR.L)
        local x2,y2
        if self.labelPos=='left' then
            x2,y2=x-self.labelDistance,y
        elseif self.labelPos=='right' then
            x2,y2=x+w+self.labelDistance,y
        elseif self.labelPos=='down' then
            x2,y2=x+w*.5,y-self.labelDistance
        end
        alignDraw(self,self._text,x2,y2)
    end
end


-- slider_progress
Widgets.slider_progress=setmetatable({
    type='slider_progress',
    w=100,h=10,

    text=false,
    image=false,
    labelPos='left',
    labelDistance=20,
    lineDist=3,

    disp=false,-- function return the displaying _value
    code=NULL,

    _text=nil,
    _image=nil,
    _pos=nil,
    _rangeL=nil,
    _rangeR=nil,
    _rangeWidth=nil,-- just _rangeR-_rangeL, for convenience

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',

        'labelPos',
        'labelDistance',
        'lineWidth',
        'text','fontSize','fontType',
        'widthLimit',

        'disp','code',
        'visibleFunc',
    },
},{__index=Widgets.slider,__metatable=true})
function Widgets.slider_progress:reset()
    Widgets.base.reset(self)

    assert(self.w and type(self.w)=='number','[inputBox].w must be number')
    assert(self.h and type(self.h)=='number','[inputBox].h must be number')
    assert(type(self.disp)=='function','[slider].disp must be function')

    assert(
        type(self.axis)=='table' and #self.axis==2 and
        type(self.axis[1])=='number' and
        type(self.axis[2])=='number',
        "[slider].axis must be {number,number}"
    )
    self._rangeL=self.axis[1]
    self._rangeR=self.axis[2]
    self._rangeWidth=self._rangeR-self._rangeL
    self._pos=self._rangeL
    self._textShowTime=3

    if self.labelPos=='left' then
        self.alignX='right'
    elseif self.labelPos=='right' then
        self.alignX='left'
    elseif self.labelPos=='down' then
        self.alignY='up'
        self.labelDistance=max(self.labelDistance,20)
    else
        error("[slider_progress].labelPos must be 'left','right' or 'down'")
    end
end
function Widgets.slider_progress:isAbove(x,y)
    return
        x>self._x and
        x<self._x+self.w and
        abs(y-self._y)<self.h*2
end
function Widgets.slider_progress:draw()
    local x,y=self._x,self._y
    local w,h=self.w,self.h
    local HOV=self._hoverTime/self._hoverTimeMax

    h=h*(1+HOV)

    gc_setColor(.5,.5,.5,.4+.1*HOV)
    gc_rectangle('fill',x,y-h*.5,w,h,h*.5)
    gc_setColor(COLOR.L)
    if w*self._pos>=1 then
        gc_rectangle('fill',x,y-h*.5,w*self._pos,h,h*.5)
    end

    -- Drawable
    if self._text then
        local x2,y2
        if self.labelPos=='left' then
            x2,y2=x-self.labelDistance,y
        elseif self.labelPos=='right' then
            x2,y2=x+w+self.labelDistance,y
        elseif self.labelPos=='down' then
            x2,y2=x+w*.5,y-self.labelDistance
        end
        alignDraw(self,self._text,x2,y2)
    end
end


-- selector
local leftAngle=GC.load{20,20,
    {'setLW',5},
    {'line',18,2,1,10,18,18},
}
local rightAngle=GC.load{20,20,
    {'setLW',5},
    {'line',2,2,19,10,2,18},
}
Widgets.selector=setmetatable({
    type='selector',

    w=100,
    labelPos='left',
    labelDistance=20,
    sound=false,

    disp=false,-- function return a boolean
    show=function(v) return v end,
    code=NULL,

    _floatWheel=0,
    _text=nil,
    _image=nil,
    _select=false,-- Selected item ID
    _selText=false,-- Selected item name
    selFontSize=30,selFontType=false,
    alignX='center',alignY='center',-- Force text alignment

    buildArgs={
        'name',
        'pos',
        'x','y','w',

        'color','text',
        'fontSize','fontType',
        'selFontSize','selFontType',
        'widthLimit',

        'labelPos',
        'labelDistance',
        'sound',

        'list','disp','show',
        'code',
        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.selector:reset()
    Widgets.base.reset(self)

    assert(self.w and type(self.w)=='number','[selector].w must be number')
    assert(type(self.list)=='table','[selector].list must be table')
    assert(type(self.disp)=='function','[selector].disp must be function')
    assert(type(self.show)=='function','[selector].show must be function')

    if self.labelPos=='left' then
        self.alignX='right'
    elseif self.labelPos=='right' then
        self.alignX='left'
    elseif self.labelPos=='down' then
        self.alignY='up'
    elseif self.labelPos=='up' then
        self.alignY='down'
    else
        error("[selector].labelPos must be 'left','right','down' or 'up'")
    end

    local V=self.disp()
    self._selText=GC.newText(getFont(self.selFontSize,self.selFontType),self.show(V))
    self._select=false
    for i=1,#self.list do
        if self.list[i]==V then
            self._select=i
            break
        end
    end
end
function Widgets.selector:isAbove(x,y)
    return
        abs(x-self._x)<self.w*.5 and
        abs(y-self._y)<60*.5
end
function Widgets.selector:draw()
    local x,y=self._x,self._y
    local w=self.w
    local HOV=self._hoverTime/self._hoverTimeMax

    -- Arrow
    if self._select then
        gc_setColor(1,1,1,.6+HOV*.26)
        local t=(timer()%.5)^.5
        if self._select>1 then
            gc_draw(leftAngle,x-w*.5,y-10)
            if HOV>0 then
                gc_setColor(1,1,1,HOV*1.5*(.5-t))
                gc_draw(leftAngle,x-w*.5-t*40,y-10)
                gc_setColor(1,1,1,.6+HOV*.26)
            end
        end
        if self._select<#self.list then
            gc_draw(rightAngle,x+w*.5-20,y-10)
            if HOV>0 then
                gc_setColor(1,1,1,HOV*1.5*(.5-t))
                gc_draw(rightAngle,x+w*.5-20+t*40,y-10)
            end
        end
    end

    -- Drawable
    gc_setColor(COLOR.L)
    local x2,y2
    if self.labelPos=='left' then
        x2,y2=x-w*.5-self.labelDistance,y
    elseif self.labelPos=='right' then
        x2,y2=x+w*.5+self.labelDistance,y
    elseif self.labelPos=='up' then
        x2,y2=x,y-self.labelDistance
    elseif self.labelPos=='down' then
        x2,y2=x,y+self.labelDistance
    end
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image,x2,y2)
    end
    if self._text then
        gc_setColor(self.color)
        alignDraw(self,self._text,x2,y2)
    end
    if self._selText then
        GC.mDraw(self._selText,x,y)
    end
end
function Widgets.selector:press(x)
    if x then
        local s=self._select
        if x<self._x then
            if s>1 then
                s=s-1
            end
        else
            if s<#self.list then
                s=s+1
            end
        end
        if self._select~=s then
            self.code(self.list[s])
            self._select=s
            self._selText:set(self.show(self.list[s]))
            if self.sound then
                SFX.play(self.sound)
            end
        end
    end
end
function Widgets.selector:scroll(dx,dy)
    local n=updateWheel(self,dx+dy)
    if n then
        local s=self._select
        if n==1 then
            if s==1 then return end
            s=s-1
        elseif n==-1 then
            if s==#self.list then return end
            s=s+1
        end
        self.code(self.list[s])
        self._select=s
        self._selText:set(self.show(self.list[s]))
        if self.sound then
            SFX.play(self.sound)
        end
    end
end
function Widgets.selector:arrowKey(k)
    self:scroll((k=='left' or k=='up') and -1 or 1,0)
end


-- inputBox
Widgets.inputBox=setmetatable({
    type='inputBox',
    keepFocus=true,

    w=100,
    h=40,

    secret=false,
    regex=false,
    labelPos='left',
    labelDistance=20,
    cornerR=3,

    maxInputLength=1e99,
    sound_input=false,sound_bksp=false,sound_del=false,sound_clear=false,

    _value='',-- Text contained

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',

        'text','fontSize','fontType',
        'secret',
        'regex',
        'labelPos',
        'labelDistance',
        'lineWidth','cornerR',
        'maxInputLength',
        'sound_input','sound_bksp','sound_del','sound_clear',

        'list',
        'disp','code',
        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.inputBox:reset()
    Widgets.base.reset(self)
    assert(self.w and type(self.w)=='number','[inputBox].w must be number')
    assert(self.h and type(self.h)=='number','[inputBox].h must be number')
    assert(not self.inputSound or type(self.inputSound)=='string','[inputBox].inputSound can only be a string')
    assert(not self.delSound or type(self.delSound)=='string','[inputBox].delSound can only be a string')
    assert(not self.clearSound or type(self.clearSound)=='string','[inputBox].clearSound can only be a string')
    if self.labelPos=='left' then
        self.alignX,self.alignY='right','center'
    elseif self.labelPos=='right' then
        self.alignX,self.alignY='left','center'
    elseif self.labelPos=='up' then
        self.alignX,self.alignY='center','down'
    elseif self.labelPos=='down' then
        self.alignX,self.alignY='center','up'
    else
        error("[inputBox].labelPos must be 'left', 'right', 'up', or 'down'")
    end
end
function Widgets.inputBox:hasText()
    return #self._value>0
end
function Widgets.inputBox:getText()
    return self._value
end
function Widgets.inputBox:setText(str)
    if type(str)=='string' then
        self._value=str
    end
end
function Widgets.inputBox:addText(str)
    if type(str)=='string' then
        self._value=self._value..str
    else
        MES.new('error',"inputBox "..self.name.." dead, addText("..type(str)..")")
    end
end
function Widgets.inputBox:clear()
    self._value=''
    if self.sound_clear then
        SFX.play(self.sound_clear)
    end
end
function Widgets.inputBox:isAbove(x,y)
    return
        x>self._x and
        y>self._y and
        x<self._x+self.w and
        y<self._y+self.h
end
function Widgets.inputBox:draw()
    local x,y,w,h=self._x,self._y,self.w,self.h
    local HOV=self._hoverTime/self._hoverTimeMax

    -- Background
    gc_setColor(0,0,0,.3)
    gc_rectangle('fill',x,y,w,h,self.cornerR)

    -- Highlight
    gc_setColor(1,1,1,HOV*.2*(math.sin(timer()*6.26)*.25+.75))
    gc_rectangle('fill',x,y,w,h,self.cornerR)

    -- Frame
    gc_setColor(COLOR.L)
    gc_setLineWidth(self.lineWidth)
    gc_rectangle('line',x,y,w,h,self.cornerR)

    -- Drawable
    if self._text then
        gc_setColor(COLOR.L)
        local x2,y2
        if self.labelPos=='left' then
            x2,y2=x-8,y+self.h*.5
        elseif self.labelPos=='right' then
            x2,y2=x+self.w+8,y+self.h*.5
        elseif self.labelPos=='up' then
            x2,y2=x+self.w*.5,y
        elseif self.labelPos=='down' then
            x2,y2=x+self.w*.5,y+self.h
        end
        alignDraw(self,self._text,x2,y2)
    end

    local f=self.fontSize
    if self.secret then
        y=y+h*.5-f*.2
        for i=1,#self._value do
            gc_rectangle('fill',x+f*.6*i,y,f*.4,f*.4)
        end
    else
        setFont(f,self.fontType)
        gc_printf(self._value,x+10,y,self.w-20)
        if WIDGET.sel==self then
            gc_print(EDITING,x+10,y+12-f*1.4)
        end
    end
end
function Widgets.inputBox:press()
    if MOBILE then
        local _,y1=xOy:transformPoint(0,self.y+self.h)
        kb.setTextInput(true,0,y1,1,1)
    end
end
function Widgets.inputBox:keypress(k)
    local t=self._value
    if #t>0 and EDITING=='' then
        if k=='backspace' then
            local p=#t
            while t:byte(p)>=128 and t:byte(p)<192 do
                p=p-1
            end
            t=sub(t,1,p-1)
            if self.sound_bksp then
                SFX.play(self.sound_bksp)
            end
        elseif k=='delete' then
            t=''
            if self.sound_del then
                SFX.play(self.sound_del)
            end
        end
        self._value=t
    end
end


-- textBox
Widgets.textBox=setmetatable({
    type='textBox',
    keepFocus=true,

    w=100,
    h=40,

    scrollBarPos='left',
    lineHeight=30,
    yOffset=-2,
    cornerR=3,
    activeColor=TABLE.shift(COLOR.LY),
    idleColor=TABLE.shift(COLOR.L),
    fixContent=true,
    sound_clear=false,

    _floatWheel=0,
    _texts=false,
    _scrollPos=0,-- Scroll-down-distance
    _scrollPos1=0,
    _sure=0,-- Sure-timer for clear history

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',

        'fontSize','fontType',
        'scrollBarPos',
        'lineHeight',
        'yOffset',
        'lineWidth','cornerR',
        'activeColor','idleColor',
        'fixContent',
        'sound_clear',

        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.textBox:reset()
    Widgets.base.reset(self)
    assert(self.w and type(self.w)=='number','[textBox].w must be number')
    assert(self.h and type(self.h)=='number','[textBox].h must be number')
    for _,v in next,{'activeColor','idleColor'} do
        if type(self[v])=='string' then self[v]=COLOR[self[v]] end
        assert(type(self[v])=='table','[textBox].'..v..' must be table')
    end

    assert(self.scrollBarPos=='left' or self.scrollBarPos=='right',"[textBox].scrollBarPos must be 'left' or 'right'")
    assert(type(self.yOffset)=='number',"[textBox].yOffset must be number")

    if not self._texts then self._texts={} end
    self._capacity=ceil(self.h/self.lineHeight)
    self._scrollPos1=-2*self.h
end
function Widgets.textBox:replaceTexts(newList)
    self._texts=newList
    self._scrollPos=0
end
function Widgets.textBox:setTexts(newList)
    TABLE.clear(self._texts)
    TABLE.connect(self._texts,newList)
    self._scrollPos=0
end
function Widgets.textBox:push(t)
    ins(self._texts,t)
    if self._scrollPos==(#self._texts-1-self._capacity)*self.lineHeight then-- minus 1 for the new message
        self._scrollPos=min(self._scrollPos+self.lineHeight,(#self._texts-self._capacity)*self.lineHeight)
    end
end
function Widgets.textBox:clear()
    self._texts={}
    self._scrollPos=0
    if self.sound_clear then
        SFX.play(self.sound_clear)
    end
end
function Widgets.textBox:isAbove(x,y)
    return
        x>self._x and
        y>self._y and
        x<self._x+self.w and
        y<self._y+self.h
end
function Widgets.textBox:press(x,y)
    if not (x and y) then return end
    self:drag(0,0,0,0)
    if not self.fixContent and x>self._x+self.w-40 and y<self._y+40 then
        if self._sure>0 then
            self:clear()
            self._sure=0
        else
            self._sure=1
        end
    end
end
function Widgets.textBox:drag(_,_,_,dy)
    self._scrollPos=max(0,min(self._scrollPos-dy,(#self._texts-self._capacity)*self.lineHeight))
end
function Widgets.textBox:scroll(dx,dy)
    self._scrollPos=max(0,min(self._scrollPos-(dx+dy)*self.lineHeight,(#self._texts-self._capacity)*self.lineHeight))
end
function Widgets.textBox:arrowKey(k)
    self:scroll(0,k =='up' and -1 or k=='down' and 1 or 0)
end
function Widgets.textBox:update(dt)
    if self._sure>0 then
        self._sure=max(self._sure-dt,0)
    end
    if self._visible then
        self._scrollPos1=MATH.expApproach(self._scrollPos1,self._scrollPos,dt*26)
    end
end
function Widgets.textBox:draw()
    local x,y,w,h=self._x,self._y,self.w,self.h
    local texts=self._texts
    local lineH=self.lineHeight
    local scroll=self._scrollPos1

    -- Background
    gc_setColor(0,0,0,.3)
    gc_rectangle('fill',x,y,w,h,self.cornerR)

    -- Frame
    gc_setColor(WIDGET.sel==self and self.activeColor or self.idleColor)
    local lw=self.lineWidth
    gc_setLineWidth(lw)
    gc_rectangle('line',x-lw*.5,y-lw*.5,w+lw,h+lw,self.cornerR)

    -- Texts
    gc_push('transform')
        gc_translate(x,y)

        -- Slider
        gc_setColor(COLOR.L)
        if #texts>self._capacity then
            local len=h*h/(#texts*lineH)
            if self.scrollBarPos=='left' then
                gc_rectangle('fill',-15,(h-len)*scroll/((#texts-self._capacity)*lineH),10,len,self.cornerR)
            elseif self.scrollBarPos=='right' then
                gc_rectangle('fill',w+5,(h-len)*scroll/((#texts-self._capacity)*lineH),10,len,self.cornerR)
            end
        end

        -- Clear button
        if not self.fixContent then
            gc_rectangle('line',w-40,0,40,40,self.cornerR)
            if self._sure==0 then
                gc_rectangle('fill',w-40+16,5,8,3)
                gc_rectangle('fill',w-40+8,8,24,3)
                gc_rectangle('fill',w-40+11,14,18,21)
            else
                setFont(40,'_basic')
                mStr('?',w-40+21,-8)
            end
        end

        -- Texts
        setFont(self.fontSize,self.fontType)
        GC_stc_rect(0,0,w,h)
        GC_stc_setComp()
        gc_translate(0,-(scroll%lineH))
        local pos=floor(scroll/lineH)
        for i=1,self._capacity+1 do
            i=pos+i
            if texts[i] then
                gc_printf(texts[i],10,self.yOffset,w-16)
            end
            gc_translate(0,lineH)
        end
        GC_stc_stop()
    gc_pop()
end


-- listBox
Widgets.listBox=setmetatable({
    type='listBox',
    w=100,
    h=40,

    scrollBarPos='left',
    lineHeight=30,
    cornerR=3,
    activeColor=TABLE.shift(COLOR.LI),
    idleColor=TABLE.shift(COLOR.L),
    drawFunc=false,-- function that draw options. Input: option,id,ifSelected
    releaseDist=10,

    _floatWheel=0,
    _list=false,
    _capacity=0,
    _scrollPos=0,
    _scrollPos1=0,
    _selected=0,
    _pressX=false,
    _pressY=false,

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',

        'scrollBarPos',
        'lineHeight',
        'lineWidth','cornerR',
        'activeColor','idleColor',
        'drawFunc',
        'releaseDist',

        'code',
        'visibleFunc',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.listBox:reset()
    Widgets.base.reset(self)
    assert(self.w and type(self.w)=='number','[listBox].w must be number')
    assert(self.h and type(self.h)=='number','[listBox].h must be number')
    for _,v in next,{'activeColor','idleColor'} do
        if type(self[v])=='string' then self[v]=COLOR[self[v]] end
        assert(type(self[v])=='table','[listBox].'..v..' must be table')
    end
    assert(self.scrollBarPos=='left' or self.scrollBarPos=='right',"[listBox].scrollBarPos must be 'left' or 'right'")

    assert(type(self.drawFunc)=='function',"[listBox].drawFunc must be function")
    if not self._list then self._list={} end
    self._capacity=ceil(self.h/self.lineHeight)
    self._scrollPos1=-2*self.h
end
function Widgets.listBox:clear()
    self._list={}
    self._scrollPos=0
end
function Widgets.listBox:setList(t)
    self._list=t
    self._selected=1
    self._scrollPos=0
end
function Widgets.listBox:getList()
    return self._list
end
function Widgets.listBox:getLen()
    return #self._list
end
function Widgets.listBox:getSelect()
    return self._selected
end
function Widgets.listBox:getItem()
    return self._list[self._selected]
end
function Widgets.listBox:isAbove(x,y)
    return
        x>self._x and
        y>self._y and
        x<self._x+self.w and
        y<self._y+self.h
end
function Widgets.listBox:push(t)
    ins(self._list,t)
end
function Widgets.listBox:pop()
    if #self._list>0 then
        rem(self._list)
        Widgets.listBox:drag(0,0,0,0)
    end
end
function Widgets.listBox:remove()
    if self._selected then
        rem(self._list,self._selected)
        if not self._list[self._selected] then
            self:arrowKey('up')
        end
        self:_moveScroll(0,false)
    end
end
function Widgets.listBox:press(x,y)
    self._pressX=x
    self._pressY=y
end
function Widgets.listBox:release(x,y)
    if not (x and y) then return end
    if self._pressX then
        self._pressX=false
        self._pressY=false
        x,y=x-self._x,y-self._y
        if not (x and y and x>0 and y>0 and x<=self.w and y<=self.h) then return end
        y=floor((y+self._scrollPos1)/self.lineHeight)+1
        if self._list[y] then
            if self._selected~=y then
                self._selected=y
                self:_moveScroll(0,true)
                SFX.play('selector',.8,0,12)
            else
                if self.code then
                    self:code(self:getSelect(),self:getItem())
                end
            end
        end
    end
end
function Widgets.listBox:_moveScroll(dy,selInSight)
    self._scrollPos=MATH.clamp(
        not selInSight and self._scrollPos+dy or
        MATH.clamp(self._scrollPos+dy,
            (self._selected+1)*self.lineHeight-self.h,
            (self._selected-2)*self.lineHeight
        ),
        0,#self._list*self.lineHeight-self.h
    )
end
function Widgets.listBox:drag(x,y,_,dy)
    if self._pressX and MATH.distance(x,y,self._pressX,self._pressY)>self.releaseDist then
        self._pressX,self._pressY=false,false
    end
    self:_moveScroll(-dy,false)
end
function Widgets.listBox:scroll(dx,dy)
    self:_moveScroll((-dx-dy)*self.lineHeight,false)
end
function Widgets.listBox:arrowKey(dir)
    if dir=='up' then
        self._selected=max(self._selected-1,1)
    elseif dir=='down' then
        self._selected=min(self._selected+1,#self._list)
    elseif dir~='autofresh' then
        return
    end
    self:_moveScroll(0,true)
end
function Widgets.listBox:select(i)
    self._selected=i
    self:arrowKey('autofresh')
end
function Widgets.listBox:update(dt)
    if self._visible then
        self._scrollPos1=MATH.expApproach(self._scrollPos1,self._scrollPos,dt*26)
    end
end
function Widgets.listBox:draw()
    local x,y,w,h=self._x,self._y,self.w,self.h
    local list=self._list
    local lineH=self.lineHeight
    local H=#list*lineH
    local scroll=self._scrollPos1

    gc_push('transform')
        gc_translate(x,y)

        -- Background
        gc_setColor(0,0,0,.4)
        gc_rectangle('fill',0,0,w,h,self.cornerR)

        -- Frame
        gc_setColor(WIDGET.sel==self and self.activeColor or self.idleColor)
        local lw=self.lineWidth
        gc_setLineWidth(lw)
        gc_rectangle('line',-lw*.5,-lw*.5,w+lw,h+lw,self.cornerR)

        -- Slider
        if h<H then
            local len=h*h/H
            gc_setColor(COLOR.L)
            gc_rectangle('fill',-15,max((h-len)*scroll/(H-h),0),12,len,self.cornerR)
        end

        -- List
        GC_stc_rect(0,0,w,h)
        GC_stc_setComp()
        local pos=floor(scroll/lineH)
        gc_translate(0,-(scroll%lineH))
        for i=1,self._capacity+1 do
            i=pos+i
            if list[i]~=nil then
                self.drawFunc(list[i],i,i==self._selected)
            end
            gc_translate(0,lineH)
        end
        GC_stc_stop()
    gc_pop()
end

--------------------------------------------------------------


-- Widget module
WIDGET.active={}-- Table contains all active widgets
WIDGET.sel=false-- Selected widget
local function _resetAllWidgets()
    for i=1,#WIDGET.active do
        WIDGET.active[i]:reset()
    end
end
function WIDGET.setWidgetList(list)
    WIDGET.unFocus(true)
    WIDGET.active=list or NONE

    if list then
        WIDGET.cursorMove(SCR.xOy:inverseTransformPoint(love.mouse.getPosition()))

        -- Set metatable for new widget lists
        if getmetatable(list)~=indexMeta then
            setmetatable(list,indexMeta)
        end

        _resetAllWidgets()
    end
    onChange()
end
function WIDGET.getSelected()
    return WIDGET.sel
end
function WIDGET.isFocus(W)
    if W then
        return W and WIDGET.sel==W
    else
        return WIDGET.sel~=false
    end
end
function WIDGET.focus(W)
    if WIDGET.sel==W then return end
    if WIDGET.sel and WIDGET.sel.type=='inputBox' then
        kb.setTextInput(false)
        EDITING=''
    end
    if W and W._visible then
        WIDGET.sel=W
        if W.type=='inputBox' and not kb.hasTextInput() then
            local _,y1=xOy:transformPoint(0,W.y+W.h)
            kb.setTextInput(true,0,y1,1,1)
        end
    end
end
function WIDGET.unFocus(force)
    local W=WIDGET.sel
    if W and (force or not W.keepFocus) then
        if W.type=='inputBox' then
            kb.setTextInput(false)
            EDITING=''
        end
        WIDGET.sel=false
    end
end

function WIDGET.cursorMove(x,y)
    for _,W in next,WIDGET.active do
        if W._visible and W:isAbove(x,y+SCN.curScroll) then
            WIDGET.focus(W)
            return
        end
    end
    if WIDGET.sel and not WIDGET.sel.keepFocus then
        WIDGET.unFocus()
    end
end
function WIDGET.press(x,y,k)
    local W=WIDGET.sel
    if W then
        if not W:isAbove(x,y+SCN.curScroll) then
            WIDGET.unFocus(true)
        else
            W:press(x,y and y+SCN.curScroll,k)
            if not W._visible then WIDGET.unFocus() end
        end
    end
end
function WIDGET.release(x,y)
    if WIDGET.sel then
        WIDGET.sel:release(x,y+SCN.curScroll)
    end
end
function WIDGET.drag(x,y,dx,dy)
    local W=WIDGET.sel
    if W then
        W:drag(x,y+SCN.curScroll,dx,dy)
    else
        SCN.curScroll=MATH.clamp(SCN.curScroll-dy,0,SCN.maxScroll)
    end
end
function WIDGET.scroll(dx,dy)
    local W=WIDGET.sel
    if W then
        W:scroll(dx,dy)
    else
        SCN.curScroll=MATH.clamp(SCN.curScroll-dy*SCR.h0/6.26,0,SCN.maxScroll)
    end
end
function WIDGET.textinput(texts)
    local W=WIDGET.sel
    if W and W.type=='inputBox' then
        if (not W.regex or texts:match(W.regex)) and (not W.limit or #(WIDGET.sel._value..texts)<=W.limit) then
            WIDGET.sel._value=WIDGET.sel._value..texts
            SFX.play(Widgets.inputBox.sound_input)
        else
            SFX.play('drop_cancel')
        end
    end
end

function WIDGET.update(dt)
    for _,W in next,WIDGET.active do
        if W.visibleFunc then
            local v=W.visibleFunc()
            if W._visible~=v then
                W._visible=v
                if v then
                    if W:isAbove(SCR.xOy:inverseTransformPoint(love.mouse.getPosition())) then
                        WIDGET.focus(W)
                    end
                else
                    if W==WIDGET.sel then
                        WIDGET.unFocus(true)
                    end
                end
            end
        end
        if W.update then W:update(dt) end
    end
end
function WIDGET.resize(w,h)
    if widgetCanvas then widgetCanvas:release() end
    widgetCanvas=GC.newCanvas(w,h)
    _resetAllWidgets()
end
function WIDGET.draw()
    gc_translate(0,-SCN.curScroll)
    for _,W in next,WIDGET.active do
        if W._visible then W:draw() end
    end
    gc_setColor(1,1,1)
    gc_draw(widgetCanvas)
    gc_replaceTransform(SCR.xOy)
end

function WIDGET.setDefaultButtonSound(sound)
    assert(type(sound)=='string',"WIDGET.setDefaultButtonSound(sound): sound must be string")
    Widgets.button.sound=sound
end
function WIDGET.setDefaultCheckBoxSound(sound_on,sound_off)
    assert(type(sound_on)=='string' and type(sound_off)=='string',"WIDGET.setDefaultCheckBoxSound(sound_on,sound_off): sounds must be string")
    Widgets.checkBox.sound_on=sound_on
    Widgets.checkBox.sound_off=sound_off
end
function WIDGET.setDefaultSelectorSound(sound)
    assert(type(sound)=='string',"WIDGET.setDefaultSelectorSound(sound): sound must be string")
    Widgets.selector.sound=sound
end
function WIDGET.setDefaultTypeSound(sound_input,sound_bksp,sound_del)
    assert(type(sound_input)=='string' and type(sound_del)=='string',"WIDGET.setDefaultTypeSound(sound_input,sound_del): sounds must be string")
    Widgets.inputBox.sound_input=sound_input
    Widgets.inputBox.sound_bksp=sound_bksp
    Widgets.inputBox.sound_del=sound_del
end
function WIDGET.setDefaultClearSound(sound_clear)
    assert(type(sound_clear)=='string',"WIDGET.setDefaultClearSound(sound_clear): sound_clear must be string")
    Widgets.inputBox.sound_clear=sound_clear
    Widgets.textBox.sound_clear=sound_clear
end
function WIDGET.new(args)
    local t=args.type
    args.type=nil

    local W=Widgets[t]
    assert(W,'Widget type '..tostring(t)..' does not exist')
    local w=setmetatable({},{__index=W,__metatable=true})

    for k,v in next,args do
        if TABLE.find(W.buildArgs,k) then
            w[k]=v
        else
            error('Illegal argument '..k..' for widget '..t)
        end
    end
    w:reset()

    return w
end

--------------------------------------------------------------
-- User funcs
function WIDGET.setOnChange(func)
    assert(type(func)=='function',"WIDGET.setOnChange(func): func must be function")
    onChange=func
end

-- Widget function shortcuts
function WIDGET.c_backScn()SCN.back() end
do-- function WIDGET.c_goScn(name,style)
    local cache={}
    function WIDGET.c_goScn(name,style)
        local hash=style and name..style or name
        if not cache[hash] then
            cache[hash]=function() SCN.go(name,style) end
        end
        return cache[hash]
    end
end
do-- function WIDGET.c_swapScn(name,style)
    local cache={}
    function WIDGET.c_swapScn(name,style)
        local hash=style and name..style or name
        if not cache[hash] then
            cache[hash]=function() SCN.swapTo(name,style) end
        end
        return cache[hash]
    end
end
do-- function WIDGET.c_pressKey(k)
    local cache={}
    function WIDGET.c_pressKey(k)
        if not cache[k] then
            cache[k]=function() love.keypressed(k) end
        end
        return cache[k]
    end
end
--------------------------------------------------------------

function WIDGET.newClass(name,parent)
    assert(type(name)=='string',"WIDGET.newClass(name,parent): name must be string")
    assert(not Widgets[name],"Widget class "..name.." already exists")
    if not parent then parent='base' end
    assert(type(parent)=='string',"WIDGET.newClass(name,parent): name must be string")
    assert(Widgets[parent],"Parent widget class "..parent.." does not exist")
    Widgets[name]=setmetatable({
        type=name,
    },{__index=Widgets[parent],__metatable=true})
    return Widgets[name]
end

return WIDGET
