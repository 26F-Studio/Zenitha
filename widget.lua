local gc=love.graphics
local gc_origin=gc.origin
local gc_translate,gc_replaceTransform=gc.translate,gc.replaceTransform
local gc_push,gc_pop=gc.push,gc.pop
local gc_setCanvas,gc_setBlendMode=gc.setCanvas,gc.setBlendMode
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_draw,gc_line=gc.draw,gc.line
local gc_rectangle=gc.rectangle
local gc_print,gc_printf=gc.print,gc.printf

local kb=love.keyboard
local timer=love.timer.getTime

local assert,next=assert,next
local int,ceil=math.floor,math.ceil
local max,min=math.max,math.min
local abs=math.abs
local sub,ins,rem=string.sub,table.insert,table.remove

local STENCIL=STENCIL
local xOy=SCR.xOy
local setFont,getFont=FONT.set,FONT.get
local mStr=GC.mStr
local approach=MATH.expApproach

local downArrowIcon=GC.DO{40,25,{'fPoly',0,0,20,25,40,0}}
local upArrowIcon=GC.DO{40,25,{'fPoly',0,25,20,0,40,25}}
local clearIcon=GC.DO{40,40,
    {'fRect',16,5,8,3},
    {'fRect',8,8,24,3},
    {'fRect',11,14,18,21},
}
local sureIcon=GC.DO{40,40,
    {'rawFT',35},
    {'mText',"?",20,0},
}
local smallerThen=GC.DO{20,20,
    {'setLW',5},
    {'line',18,2,1,10,18,18},
}
local largerThen=GC.DO{20,20,
    {'setLW',5},
    {'line',2,2,19,10,2,18},
}

local langMap=setmetatable({},{
    __index=function(self,k)
        self[k]='['..k..']'
        return self[k]
    end
})
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
local widgetCover do
    local L={1,360,{'fRect',0,30,1,300}}
    for i=0,30 do
        ins(L,{'setCL',1,1,1,i/30})
        ins(L,{'fRect',0,i,1,2})
        ins(L,{'fRect',0,360-i,1,2})
    end
    widgetCover=GC.DO(L)
end
local scr_w,scr_h

local function alignDraw(self,drawable,x,y,ang,image_k)
    local w=drawable:getWidth()
    local h=drawable:getHeight()
    local k=image_k or min(self.widthLimit/w,1)
    local ox=self.alignX=='left' and 0 or self.alignX=='right' and w or w*.5
    local oy=self.alignY=='up' and 0 or self.alignY=='down' and h or h*.5
    gc_draw(drawable,x,y,ang,k,1,ox,oy)
end

local WIDGET={}
local Widgets={}

-- Base widget (not used by user)
local baseWidget={
    type='null',
    name=false,
    x=0,y=0,

    color=COLOR.Z,
    posX='raw',posY='raw',
    fontSize=30,fontType=false,
    widthLimit=1e99,

    visibleFunc=false,-- function return a boolean

    _activeTime=0,
    _activeTimeMax=.1,
    _visible=nil,
}
function baseWidget:getInfo()
    local str=""
    for k in next,self.buildArgs do
        str=str..STRING.repD("$1=$2,",k..self[k])
    end
    return str
end
function baseWidget:reset()
    assert(not self.name or type(self.name)=='string','[widget].name can only be a string')

    assert(type(self.x)=='number','[widget].x must be a number')
    assert(type(self.y)=='number','[widget].y must be a number')
    assert(type(self.color)=='table','[widget].color must be a table')

    if self.posX=='raw' then
        self._x=self.x
    elseif self.posX=='left' then
        self._x=self.x-SCR.x/SCR.k
    elseif self.posX=='right' then
        self._x=SCR.w0-self.x+SCR.x/SCR.k
    else
        error("[widget].posX must be 'raw', 'left' or 'right'")
    end

    if self.posY=='raw' then
        self._y=self.y
    elseif self.posY=='up' then
        self._y=self.y-SCR.y/SCR.k
    elseif self.posY=='down' then
        self._y=SCR.h0-self.y+SCR.y/SCR.k
    else
        error("[widget].posY must be 'raw', 'up' or 'down'")
    end

    assert(type(self.fontSize)=='number','[widget].fontSize must be a number')
    assert(type(self.fontType)=='string' or self.fontType==false,'[widget].fontType must be a string')
    assert(type(self.widthLimit)=='number','[widget].widthLimit must be a number')
    assert(not self.visibleFunc or type(self.visibleFunc)=='function','[widget].visibleFunc can only be a function')

    self._text=nil
    if self.text then
        if type(self.text)=='function' then
            self._text=self.text()
            assert(type(self._text)=='string','function text must return a string')
        else
            assert(type(self.text)=='string',"[widget].text must be a string or function return a string")
            self._text=langMap[self.text]
        end
    elseif self.rawText then
        assert(type(self.rawText)=='string',"[widget].rawText must be a string")
        self._text=self.rawText
    end
    self._text=gc.newText(getFont(self.fontSize,self.fontType),self._text)

    self._image=nil
    if self.image then
        if type(self.image)=='string' then
            self._image=IMG[self.image]or PAPER
        else
            self._image=self.image
        end
    end

    self._activeTime=0

    self._visible=true
    if self.visibleFunc then
        self._visible=self.visibleFunc()
    end
end
function baseWidget:playSound()
    if self.sound then
        SFX.play(self.sound)
    end
end
function baseWidget:setVisible(bool)
    if bool then
        self._visible=true
    else
        self._visible=false
    end
end
function baseWidget:update(dt)
    if WIDGET.sel==self then
        self._activeTime=min(self._activeTime+dt,self._activeTimeMax)
    else
        self._activeTime=max(self._activeTime-dt,0)
    end
end


-- Text
Widgets.text={
    type='text',

    text=false,
    rawText=false,
    alignX='center',alignY='center',

    _text=nil,

    buildArgs={
        'name',
        'x','y',
        'color',
        'text','rawText',
        'fontSize','fontType',

        'alignX','alignY',
        'posX','posY',
        'widthLimit',

        'visibleFunc',
    }
} CLASS.inherit(Widgets.text,baseWidget)
function Widgets.text:reset()
    baseWidget.reset(self)
end
function Widgets.text:draw()
    if self._text then
        gc_setColor(self.color)
        alignDraw(self,self._text,self._x,self._y,self.widthLimit)
    end
end


-- Image
Widgets.image={
    type='image',
    ang=0,k=1,

    image=false,
    alignX='center',alignY='center',

    _image=nil,

    buildArgs={
        'name',
        'x','y',
        'ang','k',
        'image',
        'alignX','alignY',
        'posX','posY',

        'visibleFunc',
    },
} CLASS.inherit(Widgets.image,baseWidget)
function Widgets.image:draw()
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._text,self._x,self._y,self.ang,self.k)
    end
end


-- Button
Widgets.button={
    type='button',
    w=10,h=10,

    text=false,
    image=false,
    rawText=false,
    alignX='center',alignY='center',
    sound=false,

    code=NULL,

    _text=nil,
    _image=nil,

    buildArgs={
        'name',
        'x','y',
        'w','h',
        'alignX','alignY',
        'posX','posY',
        'text','image','rawText',
        'fontSize','fontType',
        'sound',

        'code',
        'visibleFunc',
    },
} CLASS.inherit(Widgets.button,baseWidget)
function Widgets.button:reset()
    baseWidget.reset(self)
    self.widthLimit=self.w
end
function Widgets.button:isAbove(x,y)
    return
        abs(x-self._x)<self.w*.5 and
        abs(y-self._y)<self.h*.5
end
function Widgets.button:press(_,_,k)
    self.code(k)
    self:playSound()
end
function Widgets.button:draw()
    local x,y=self._x,self._y
    local w,h=self.w,self.h
    x,y=x-w*.5,y-h*.5

    local c=self.color

    -- Background
    gc_setColor(c[1],c[2],c[3],(c[4] or 1)*(.1+.2*self._activeTime/self._activeTimeMax))
    gc_rectangle('fill',x,y,w,h,4)

    -- Frame
    gc_setLineWidth(2)
    gc_setColor(.2+c[1]*.8,.2+c[2]*.8,.2+c[3]*.8,(c[4] or 1)*.7)
    gc_rectangle('line',x,y,w,h,3)

    -- Drawable
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image,x+w*.5,y+h*.5)
    end
    if self._text then
        gc_setColor(self.color)
        alignDraw(self,self._text,x+w*.5,y+h*.5)
    end
end


-- checkBox
Widgets.checkBox={
    type='checkBox',
    w=10,

    text=false,
    image=false,
    rawText=false,
    labelPos='left',
    widthLimit=1e99,
    sound=false,

    disp=false,-- function return a boolean
    code=NULL,

    _text=nil,
    _image=nil,

    buildArgs={
        'name',
        'x','y','w',

        'labelPos',
        'posX','posY',
        'text','rawText',
        'fontSize','fontType',
        'widthLimit',
        'sound',

        'disp','code',
        'visibleFunc',
    },
} CLASS.inherit(Widgets.checkBox,baseWidget)
function Widgets.checkBox:reset()
    baseWidget.reset(self)
    if self.labelPos=='left' then
        self.alignX,self.alignY='right','center'
    elseif self.labelPos=='right' then
        self.alignX,self.alignY='left','center'
    elseif self.labelPos=='up' then
        self.alignX,self.alignY='center','down'
    elseif self.labelPos=='down' then
        self.alignX,self.alignY='center','up'
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
    self:playSound()
end
function Widgets.checkBox:draw()
    local x,y=self._x,self._y
    local w=self.w
    local ATV=self._activeTime/self._activeTimeMax

    local c=self.color

    if self.disp then
        -- Background
        gc_setColor(c[1],c[2],c[3],(c[4] or 1)*(.3*ATV))
        gc_rectangle('fill',x-w*.5,y-w*.5,w,w,4)

        -- Frame
        gc_setLineWidth(2)
        gc_setColor(.2+c[1]*.8,.2+c[2]*.8,.2+c[3]*.8,(c[4] or 1)*.7)
        gc_rectangle('line',x-w*.5,y-w*.5,w,w,3)
        if self.disp() then
            gc_rectangle('fill',x-w*.3,y-w*.3,w*.6,w*.6,3)
        end
    end

    -- Drawable
    local x2,y2
    if self.labelPos=='left' then
        x2,y2=x-w*.5-10,y
    elseif self.labelPos=='right' then
        x2,y2=x+w*.5+10,y
    elseif self.labelPos=='up' then
        x2,y2=x+w*.5,y-w*.5-10
    elseif self.labelPos=='down' then
        x2,y2=x+w*.5,y+w*.5+10
    end
    if self._image then
        gc_setColor(1,1,1)
        alignDraw(self,self._image,x2-ATV*6,y2)
    end
    if self._text then
        gc_setColor(self.color)
        alignDraw(self,self._text,x2-ATV*6,y2)
    end
end


-- Slider
Widgets.slider={
    type='slider',
    w=10,
    axis={0,1},
    smooth=nil,

    text=false,
    image=false,
    rawText=false,
    labelPos='left',
    widthLimit=1e99,
    sound=false,
    show=false,

    disp=false,-- function return the displaying _value
    code=NULL,

    _text=nil,
    _image=nil,
    _showFunc=nil,
    _pos=nil,
    _rangeL=nil,
    _rangeR=nil,
    _unit=nil,
    _smooth=nil,
    _textShowTime=nil,

    buildArgs={
        'name',
        'x','y','w',
        'axis','smooth',

        'labelPos',
        'posX','posY',
        'text','rawText',
        'fontSize','fontType',
        'widthLimit',

        'show',
        'disp','code',
        'visibleFunc',
    },
} CLASS.inherit(Widgets.slider,baseWidget)
local sliderShowFunc={
    int=function(S)
        return S.disp()
    end,
    float=function(S)
        return int(S.disp()*100+.5)*.01
    end,
    percent=function(S)
        return int(S.disp()*100+.5).."%"
    end,
}
function Widgets.slider:reset()
    baseWidget.reset(self)

    assert(type(self.disp)=='function','[slider].disp must be a function')

    self._rangeL=self.axis[1]
    self._rangeR=self.axis[2]
    self._unit=self.axis[3]
    if self.smooth~=nil then
        self._smooth=self.smooth
    else
        self._smooth=not self.axis[3]
    end
    self._pos=self._rangeL
    self._textShowTime=3

    if self.show then
        if type(self.show)=='function' then
            self._showFunc=self.show
        elseif type(self.show)=='string' then
            self._showFunc=assert(sliderShowFunc[self.show],"[slider].show must be a function, or 'int', 'float', or 'percent'")
        end
    elseif self.show==false then-- Use default if nil
        self._showFunc=NULL
    else
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
    end
end
function Widgets.slider:isAbove(x,y)
    return
        x>self._x-10 and
        x<self._x+self.w+10 and
        abs(y-self._y)<25
end
function Widgets.slider:update(dt)
    baseWidget.update(self,dt)
    if self._visible then
        self._pos=approach(self._pos,self.disp(),dt*26)
    end
    if WIDGET.sel==self then
        self._textShowTime=2
    end
    self._textShowTime=max(self._textShowTime-dt,0)
end
function Widgets.slider:draw()
    local x,y=self._x,self._y
    local ATV=self._activeTime/self._activeTimeMax
    local x2=x+self.w

    gc_setColor(1,1,1,.5+ATV*.36)

    -- Units
    if not self._smooth then
        gc_setLineWidth(2)
        for p=self._rangeL,self._rangeR,self._unit do
            local X=x+(x2-x)*(p-self._rangeL)/(self._rangeR-self._rangeL)
            gc_line(X,y+7,X,y-7)
        end
    end

    -- Axis
    gc_setLineWidth(4)
    gc_line(x,y,x2,y)

    -- Block
    local cx=x+(x2-x)*(self._pos-self._rangeL)/(self._rangeR-self._rangeL)
    local bx,by=cx-10-ATV*2,y-16-ATV*5
    local bw,bh=20+ATV*4,32+ATV*10
    gc_setColor(.8,.8,.8)
    gc_rectangle('fill',bx,by,bw,bh,3)

    -- Glow
    if ATV>0 then
        gc_setLineWidth(2)
        gc_setColor(.97,.97,.97,ATV)
        gc_rectangle('line',bx+1,by+1,bw-2,bh-2,3)
    end

    -- Float text
    if self._textShowTime>0 and self.disp then
        setFont(25)
        gc_setColor(.97,.97,.97,min(self._textShowTime/2,1))
        mStr(self:disp(),cx,by-30)
    end

    -- Drawable
    if self._text then
        gc_setColor(.97,.97,.97)
        if self.labelPos=='left' then
            alignDraw(self,self._text,x-5-ATV*6,y)
        elseif self.labelPos=='right' then
            alignDraw(self,self._text,x+self.w+5+ATV*6,y)
        elseif self.labelPos=='down' then
            alignDraw(self,self._text,x+self.w*.5,y+20)
        end
    end
end
function Widgets.slider:press(x)
    self:drag(x)
end
function Widgets.slider:drag(x)
    if not x then return end
    x=x-self._x
    local newPos=MATH.interval(x/self.w,0,1)
    local newVal
    if not self._unit then
        newVal=(1-newPos)*self._rangeL+newPos*self._rangeR
    else
        newVal=newPos*(self._rangeR-self._rangeL)
        newVal=self._rangeL+int(newVal/self._unit+.5)*self._unit
    end
    if newVal~=self.disp() then
        self.code(newVal)
    end
    if self.change and timer()-self.lastTime>.5 then
        self.lastTime=timer()
        self.change()
    end
end
function Widgets.slider:release(x)
    self:drag(x)
    self.lastTime=0
end
function Widgets.slider:scroll(n)
    local p=self.disp()
    local u=self._unit or .01
    local P=MATH.interval(p+u*n,self._rangeL,self._rangeR)
    if p==P or not P then return end
    self.code(P)
    if self.change and timer()-self.lastTime>.18 then
        self.lastTime=timer()
        self.change()
    end
end
function Widgets.slider:arrowKey(k)
    self:scroll((k=='left' or k=='up') and -1 or 1)
end


Widgets.selector={
    type='selector',

    h=70,-- Attention, fixed height

    _select=false,-- Selected item ID
    _selText=false,-- Selected item name
    alignX='center',alignY='down',-- Force text alignment

    buildArgs={
        'name',
        'x','y','w',

        'posX','posY',
        'text','rawText',
        'sound',

        'list',
        'disp','code',
        'visibleFunc',
    },
} CLASS.inherit(Widgets.selector,baseWidget)
function Widgets.selector:reset()
    baseWidget.reset(self)

    assert(type(self.disp)=='function','[selector].disp must be a function')

    self.widthLimit=self.w

    local V,L=self.disp(),self.list
    for i=1,#L do
        if L[i]==V then
            self._select=i
            self._selText=self.list[i]
            return
        end
    end
    self._select=false
    self._selText=false
    MES.new('error',"Selector "..self.name.." dead, disp= "..tostring(V))
end
function Widgets.selector:isAbove(x,y)
    return
        abs(x-self._x)<self.w*.5 and
        abs(y-self._y)<60*.5
end
function Widgets.selector:draw()
    local x,y=self._x,self._y
    local w,h=self.w,self.h
    x,y=x-w*.5,y-h*.5
    local ATV=self._activeTime/self._activeTimeMax

    -- Background
    gc_setColor(0,0,0,.3)
    gc_rectangle('fill',x,y,w,h,4)

    -- Frame
    gc_setColor(1,1,1,.6+ATV*.4)
    gc_setLineWidth(2)
    gc_rectangle('line',x,y,w,h,3)

    -- Arrow
    if self._select then
        gc_setColor(1,1,1,.2+ATV*.4)
        local t=(timer()%.5)^.5
        if self._select>1 then
            gc_draw(smallerThen,x+6,y+40)
            if ATV>0 then
                gc_setColor(1,1,1,ATV*1.5*(.5-t))
                gc_draw(smallerThen,x+6-t*40,y+40)
                gc_setColor(1,1,1,.2+ATV*.4)
            end
        end
        if self._select<#self.list then
            gc_draw(largerThen,x+w-26,y+40)
            if ATV>0 then
                gc_setColor(1,1,1,ATV*1.5*(.5-t))
                gc_draw(largerThen,x+w-26+t*40,y+40)
            end
        end
    end

    -- Drawable
    if self._text then
        gc_setColor(self.color)
        alignDraw(self,self._text,x+w*.5,y+35)
    end
    if self._selText then
        setFont(30)
        gc_setColor(COLOR.Z)
        mStr(self._selText,x+w*.5,y+30)
    end
end
function Widgets.selector:press(x)
    if x then
        local s=self._select
        if x<self.x then
            if s>1 then
                s=s-1
                SYSFX.rectangle(3,self._x-self.w*.5,self._y-self.h*.5-WIDGET.scrollPos,self.w*.5,self.h)
            end
        else
            if s<#self.list then
                s=s+1
                SYSFX.rectangle(3,self.x,self.y-self.h*.5-WIDGET.scrollPos,self.w*.5,self.h)
            end
        end
        if self._select~=s then
            self.code(self.list[s])
            self._select=s
            self._selText=self.list[s]
            self:playSound()
        end
    end
end
function Widgets.selector:scroll(n)
    local s=self._select
    if n==-1 then
        if s==1 then return end
        s=s-1
        SYSFX.rectangle(3,self._x,self._y-WIDGET.scrollPos,self.w*.5,60)
    else
        if s==#self.list then return end
        s=s+1
        SYSFX.rectangle(3,self.x+self.w*.5,self.y-WIDGET.scrollPos,self.w*.5,60)
    end
    self.code(self.list[s])
    self._select=s
    self._selText=self.list[s]
    self:playSound()
end
function Widgets.selector:arrowKey(k)
    self:scroll((k=='left' or k=='up') and -1 or 1)
end


Widgets.inputBox={
    type='inputBox',
    keepFocus=true,

    h=40,

    secret=false,
    inputSound=false,
    delSound=false,
    clearSound=false,
    regex=false,
    maxInputLength=1e99,

    _value="",-- Text contained

    buildArgs={
        'name',
        'x','y','w','h',

        'fontSize','fontType',
        'posX','posY',
        'secret',
        'inputSound',
        'delSound',
        'clearSound',

        'list',
        'disp','code',
        'visibleFunc',
    },
} CLASS.inherit(Widgets.inputBox,baseWidget)
function Widgets.inputBox:reset()
    baseWidget.reset(self)
    assert(self.w and type(self.w)=='number','[inputBox].w must be a number')
    assert(self.h and type(self.h)=='number','[inputBox].h must be a number')
    assert(not self.inputSound or type(self.inputSound)=='string','[inputBox].inputSound can only be a string')
    assert(not self.delSound or type(self.delSound)=='string','[inputBox].delSound can only be a string')
    assert(not self.clearSound or type(self.clearSound)=='string','[inputBox].clearSound can only be a string')
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
    self._value=""
end
function Widgets.inputBox:isAbove(x,y)
    return
        x>self.x and
        y>self.y and
        x<self.x+self.w and
        y<self.y+self.h
end
function Widgets.inputBox:draw()
    local x,y,w,h=self._x,self._y,self.w,self.h
    local ATV=self._activeTime/self._activeTimeMax

    -- Background
    gc_setColor(0,0,0,.3)
    gc_rectangle('fill',x,y,w,h,4)

    -- Highlight
    gc_setColor(1,1,1,ATV*.1*(math.sin(timer()*6.26)*.3+.7))
    gc_rectangle('fill',x,y,w,h,4)

    -- Frame
    gc_setColor(1,1,1)
    gc_setLineWidth(3)
    gc_rectangle('line',x,y,w,h,3)

    -- Drawable
    local f=self.fontSize
    setFont(f,self.fontType)
    if self.obj then
        gc_draw(self.obj,x-12-self.obj:getWidth(),y+h*.5-self.obj:getHeight()*.5)
    end
    if self.secret then
        y=y+h*.5-f*.2
        for i=1,#self._value do
            gc_rectangle("fill",x+f*.6*i,y,f*.4,f*.4)
        end
    else
        gc_printf(self._value,x+10,y,self.w)
        setFont(f-10)
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
    if #t>0 and EDITING=="" then
        if k=='backspace' then
            local p=#t
            while t:byte(p)>=128 and t:byte(p)<192 do
                p=p-1
            end
            t=sub(t,1,p-1)
            SFX.play('lock')
        elseif k=='delete' then
            t=""
            SFX.play('hold')
        end
        self._value=t
    end
end
function WIDGET.newInputBox(D)-- name,x,y,w[,h][,font=30][,fontType][,secret][,regex][,limit],hide
    local _={
        name=  D.name or "_",

        x=     D.x,
        y=     D.y,
        w=     D.w,
        h=     D.h,

        font=  D.fontSize or int(D.h/7-1)*5,
        fontType= D.fontType,
        secret=D.secret==true,
        regex= D.regex,
        limit= D.limit,
        hideF= D.hideF,
        hide=  D.hide,
    }
    return _
end


--[[
local textBox={
    type='textBox',
    scrollPos=0,-- Scroll-down-distance
    sure=0,-- Sure-timer for clear history
}
function textBox:reset()
    -- haha nothing here, techmino is so fun!
end
function textBox:setTexts(t)
    self.texts=t
    self.scrollPos=0
end
function textBox:clear()
    self.texts={}
    self.scrollPos=0
    SFX.play('fall')
end
function textBox:isAbove(x,y)
    return
        x>self.x and
        y>self.y and
        x<self.x+self.w and
        y<self.y+self.h
end
function textBox:update(dt)
    if self.sure>0 then
        self.sure=max(self.sure-dt,0)
    end
end
function textBox:push(t)
    ins(self.texts,t)
    if self.scrollPos==(#self.texts-1-self.capacity)*self.lineH then-- minus 1 for the new message
        self.scrollPos=min(self.scrollPos+self.lineH,(#self.texts-self.capacity)*self.lineH)
    end
end
function textBox:press(x,y)
    if not (x and y) then return end
    self:drag(0,0,0,0)
    if not self.fix and x>self.x+self.w-40 and y<self.y+40 then
        if self.sure>0 then
            self:clear()
            self.sure=0
        else
            self.sure=1
        end
    end
end
function textBox:drag(_,_,_,dy)
    self.scrollPos=max(0,min(self.scrollPos-dy,(#self.texts-self.capacity)*self.lineH))
end
function textBox:scroll(dir)
    if type(dir)=='string' then
        if dir=="up" then
            dir=-1
        elseif dir=="down" then
            dir=1
        else
            return
        end
    end
    self:drag(nil,nil,nil,-dir*self.lineH)
end
function textBox:arrowKey(k)
    if k=='up' then
        self:scroll(-1)
    elseif k=='down' then
        self:scroll(-1)
    end
end
function textBox:draw()
    local x,y,w,h=self._x,self._y,self.w,self.h
    local texts=self.texts
    local scrollPos=self.scrollPos
    local cap=self.capacity
    local lineH=self.lineH

    -- Background
    gc_setColor(0,0,0,.3)
    gc_rectangle('fill',x,y,w,h,4)

    -- Frame
    gc_setLineWidth(2)
    gc_setColor(WIDGET.sel==self and COLOR.lN or COLOR.Z)
    gc_rectangle('line',x,y,w,h,3)

    -- Texts
    setFont(self.fontSize,self.fontType)
    gc_push('transform')
        gc_translate(x,y)

        -- Slider
        gc_setColor(1,1,1)
        if #texts>cap then
            local len=h*h/(#texts*lineH)
            gc_rectangle('fill',-15,(h-len)*scrollPos/((#texts-cap)*lineH),12,len,3)
        end

        -- Clear button
        if not self.fix then
            gc_rectangle('line',w-40,0,40,40,3)
            gc_draw(self.sure==0 and clearIcon or sureIcon,w-40,0)
        end
        STENCIL.start('equal',1)
        STENCIL.rectangle(0,0,w,h)
        gc_translate(0,-(scrollPos%lineH))
        local pos=int(scrollPos/lineH)
        for i=pos+1,min(pos+cap+1,#texts) do
            gc_printf(texts[i],10,4,w-16)
            gc_translate(0,lineH)
        end
        STENCIL.stop()
    gc_pop()
end
function WIDGET.newTextBox(D)-- name,x,y,w,h[,font=30][,fontType][,lineH][,fix],hide
    local _={
        name= D.name or "_",

        x=    D.x,
        y=    D.y,
        w=    D.w,
        h=    D.h,

        font= D.fontSize or 30,
        fontType=D.fontType,
        fix=  D.fix,
        texts={},
        hideF=D.hideF,
        hide= D.hide,
    }
    _.lineH=D.lineH or _.fontSize*7/5
    _.capacity=ceil((D.h-10)/_.lineH)

    for k,v in next,textBox do _[k]=v end
    return _
end

local listBox={
    type='listBox',
    keepFocus=true,
    scrollPos=0,-- Scroll-down-distance
    selected=0,-- Hidden wheel move value
}
function listBox:reset()
    -- haha nothing here too, techmino is really fun!
end
function listBox:clear()
    self.list={}
    self.scrollPos=0
end
function listBox:setList(t)
    self.list=t
    self.selected=1
    self.scrollPos=0
end
function listBox:getList()
    return self.list
end
function listBox:getLen()
    return #self.list
end
function listBox:getSel()
    return self.list[self.selected]
end
function listBox:isAbove(x,y)
    return
        x>self.x and
        y>self.y and
        x<self.x+self.w and
        y<self.y+self.h
end
function listBox:push(t)
    ins(self.list,t)
end
function listBox:pop()
    if #self.list>0 then
        rem(self.list)
        listBox:drag(0,0,0,0)
    end
end
function listBox:remove()
    if self.selected then
        rem(self.list,self.selected)
        if not self.list[self.selected] then
            self:arrowKey('up')
        end
        self:drag(0,0,0,0)
    end
end
function listBox:press(x,y)
    if not (x and y) then return end
    x,y=x-self.x,y-self.y
    if not (x and y and x>0 and y>0 and x<=self.w and y<=self.h) then return end
    self:drag(0,0,0,0)
    y=int((y+self.scrollPos)/self.lineH)+1
    if self.list[y] then
        if self.selected~=y then
            self.selected=y
            SFX.play('selector',.8,0,12)
        end
    end
end
function listBox:drag(_,_,_,dy)
    self.scrollPos=max(0,min(self.scrollPos-dy,(#self.list-self.capacity)*self.lineH))
end
function listBox:scroll(n)
    self:drag(nil,nil,nil,-n*self.lineH)
end
function listBox:arrowKey(dir)
    if dir=="up" then
        self.selected=max(self.selected-1,1)
        if self.selected<int(self.scrollPos/self.lineH)+2 then
            self:drag(nil,nil,nil,self.lineH)
        end
    elseif dir=="down" then
        self.selected=min(self.selected+1,#self.list)
        if self.selected>int(self.scrollPos/self.lineH)+self.capacity-1 then
            self:drag(nil,nil,nil,-self.lineH)
        end
    end
end
function listBox:select(i)
    self.selected=i
    if self.selected<int(self.scrollPos/self.lineH)+2 then
        self:drag(nil,nil,nil,1e99)
    elseif self.selected>int(self.scrollPos/self.lineH)+self.capacity-1 then
        self:drag(nil,nil,nil,-1e99)
    end
end
function listBox:draw()
    local x,y,w,h=self._x,self._y,self.w,self.h
    local list=self.list
    local scrollPos=self.scrollPos
    local cap=self.capacity
    local lineH=self.lineH

    gc_push('transform')
        gc_translate(x,y)

        -- Background
        gc_setColor(0,0,0,.4)
        gc_rectangle('fill',0,0,w,h,4)

        -- Frame
        gc_setColor(WIDGET.sel==self and COLOR.lN or COLOR.Z)
        gc_setLineWidth(2)
        gc_rectangle('line',0,0,w,h,3)

        -- Slider
        if #list>cap then
            gc_setColor(1,1,1)
            local len=h*h/(#list*lineH)
            gc_rectangle('fill',-15,(h-len)*scrollPos/((#list-cap)*lineH),12,len,3)
        end

        -- List
        STENCIL.start('equal',1)
        STENCIL.rectangle(w,h)
        local pos=int(scrollPos/lineH)
        gc_translate(0,-(scrollPos%lineH))
        for i=pos+1,min(pos+cap+1,#list) do
            self.drawF(list[i],i,i==self.selected)
            gc_translate(0,lineH)
        end
        STENCIL.stop()
    gc_pop()
end
function WIDGET.newListBox(D)-- name,x,y,w,h,lineH,drawF[,hideF][,hide]
    local _={
        name=    D.name or "_",

        x=       D.x,
        y=       D.y,
        w=       D.w,
        h=       D.h,

        list=    {},
        lineH=   D.lineH,
        capacity=ceil(D.h/D.lineH),
        drawF=   D.drawF,
        hideF=   D.hideF,
        hide=    D.hide,
    }

    for k,v in next,listBox do _[k]=v end
    return _
end
]]

WIDGET.active={}-- Table contains all active widgets
WIDGET.scrollHeight=0-- Max drag height, not actual container height!
WIDGET.scrollPos=0-- Current scroll position
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
function WIDGET.setScrollHeight(height)
    WIDGET.scrollHeight=height and height or 0
    WIDGET.scrollPos=0
end
function WIDGET.setLang(newLangMap)
    langMap=newLangMap
    _resetAllWidgets()
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
        EDITING=""
    end
    WIDGET.sel=W
    if W and W.type=='inputBox' then
        local _,y1=xOy:transformPoint(0,W.y+W.h)
        kb.setTextInput(true,0,y1,1,1)
    end
end
function WIDGET.unFocus(force)
    local W=WIDGET.sel
    if W and (force or not W.keepFocus) then
        if W.type=='inputBox' then
            kb.setTextInput(false)
            EDITING=""
        end
        WIDGET.sel=false
    end
end

function WIDGET.cursorMove(x,y)
    for _,W in next,WIDGET.active do
        if W._visible and W:isAbove(x,y+WIDGET.scrollPos) then
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
        W:press(x,y and y+WIDGET.scrollPos,k)
        if W.hide then WIDGET.unFocus() end
    end
end
function WIDGET.drag(x,y,dx,dy)
    if WIDGET.sel then
        local W=WIDGET.sel
        if W.drag then
            W:drag(x,y+WIDGET.scrollPos,dx,dy)
        elseif not W:isAbove(x,y+WIDGET.scrollPos) then
            WIDGET.unFocus(true)
        end
    else
        WIDGET.scrollPos=max(min(WIDGET.scrollPos-dy,WIDGET.scrollHeight),0)
    end
end
function WIDGET.release(x,y)
    local W=WIDGET.sel
    if W and W.release then
        W:release(x,y+WIDGET.scrollPos)
    end
end
function WIDGET.textinput(texts)
    local W=WIDGET.sel
    if W and W.type=='inputBox' then
        if (not W.regex or texts:match(W.regex)) and (not W.limit or #(WIDGET.sel._value..texts)<=W.limit) then
            WIDGET.sel._value=WIDGET.sel._value..texts
            SFX.play('touch')
        else
            SFX.play('drop_cancel')
        end
    end
end

function WIDGET.update(dt)
    for _,W in next,WIDGET.active do
        if W.hideF then
            W.hide=W.hideF()
            if W.hide and W==WIDGET.sel then
                WIDGET.unFocus(true)
            end
        end
        if W.update then W:update(dt) end
    end
end
function WIDGET.resize(w,h)
    scr_w,scr_h=w,h
    if widgetCanvas then widgetCanvas:release() end
    widgetCanvas=gc.newCanvas(w,h)
    _resetAllWidgets()
end
function WIDGET.draw()
    gc_setCanvas({stencil=true},widgetCanvas)
        gc_translate(0,-WIDGET.scrollPos)
        for _,W in next,WIDGET.active do
            if W._visible then W:draw() end
        end
        gc_origin()
        gc_setColor(1,1,1)
        if WIDGET.scrollHeight>0 then
            if WIDGET.scrollPos>0 then
                gc_draw(upArrowIcon,scr_w*.5,10,0,SCR.k,nil,upArrowIcon:getWidth()*.5,0)
            end
            if WIDGET.scrollPos<WIDGET.scrollHeight then
                gc_draw(downArrowIcon,scr_w*.5,scr_h-10,0,SCR.k,nil,downArrowIcon:getWidth()*.5,downArrowIcon:getHeight())
            end
            gc_setBlendMode('multiply','premultiplied')
            gc_draw(widgetCover,nil,nil,nil,scr_w,scr_h/360)
        end
    gc_setCanvas({stencil=false})
    gc_setBlendMode('alpha','premultiplied')
    gc_draw(widgetCanvas)
    gc_setBlendMode('alpha')
    gc_replaceTransform(SCR.xOy)
end

function WIDGET.new(args)
    local t=args.type
    args.type=nil
    assert(t,'Widget type not specified')
    local W=Widgets[t]
    assert(W,'Widget type '..t..' does not exist')
    local w=CLASS.instance(W)
    for k,v in next,args do
        if TABLE.find(W.buildArgs,k) then
            w[k]=v
        else
            error('Illegal argument '..k..' for widget '..t)
        end
    end
    return w
end

function WIDGET.setOnChange(func) onChange=assert(type(func)=='function' and func,"WIDGET.setOnChange(func): func must be a function") end

return WIDGET
