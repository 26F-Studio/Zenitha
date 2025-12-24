---@class Zenitha.WidgetArg: Zenitha._WidgetArg
---@field type 'text' | 'image' | 'button' | 'hint' | 'checkBox' | 'switch' | 'slider' | 'slider_fill' | 'slider_progress' | 'selector' | 'inputBox' | 'textBox' | 'listBox' | string

---@class Zenitha._WidgetArg
---@field name string [All]
---@field pos table [All]
---
---@field x number [All]
---@field y number [All]
---@field w? number [EXCEPT text & switch]
---@field h? number [EXCEPT text & checkBox & slider & selector]
---@field widthLimit? number [EXCEPT image & button & *Box]
---
---@field color? Zenitha.ColorStr | Zenitha.Color [EXCEPT image & *Box] fallback of other color options
---@field text? string | function [EXCEPT image & listBox]
---@field textScale? number [EXCEPT image & listBox]
---@field fontSize? number [EXCEPT image & listBox]
---@field fontType? string [EXCEPT image & listBox]
---@field image? string | love.Drawable [image & button] Can use slash-path to read from IMG lib
---@field quad? love.Quad [image & button] Optional
---@field alignX? 'left' | 'right' | 'center' [text & image & button]
---@field alignY? 'top' | 'bottom' | 'center' [text & image & button]
---@field marginX? number [button & hint]
---@field marginY? number [button & hint]
---@field labelPos? 'top' |'right' |'bottom' |'left' |'topRight' |'topLeft' |'rightBottom' |'rightTop' |'bottomRight' |'bottomLeft' |'leftBottom' |'leftTop' [EXCEPT text & image & button & text/listBox]
---@field labelDist? number [EXCEPT text & image & button & text/listBox]
---@field disp? function [checkBox & switch & sliders & selector] Must return the value that widget should show
---@field code? function [checkBox & switch & sliders & selector & listBox] Called 'When triggered'
---@field onPress? function [button & hint] Called 'When pressed down'
---@field onClick? function [button] Called 'When pressed and release'
---@field visibleFunc function [All] Used to change widget's visibility when scene changed
---@field visibleTick function [All] Used to update widget's visibility every frame
---
---@field lineWidth? number [EXCEPT text & image & selector]
---@field cornerR? number [EXCEPT text & image & slider_fill & slider_progress & switch & selector] Round corner ratio
---
---@field textColor? Zenitha.ColorStr | Zenitha.Color [EXCEPT image & slider_progress & listBox]
---@field fillColor? Zenitha.ColorStr | Zenitha.Color [EXCEPT text & image & hint & selector]
---@field frameColor? Zenitha.ColorStr | Zenitha.Color [EXCEPT text & image]
---@field imageColor? Zenitha.ColorStr | Zenitha.Color [image & button]
---@field activeColor? Zenitha.ColorStr | Zenitha.Color [*Box]
---
---@field sound_press? string|false [button & checkBox & switch & selector & inputBox]
---@field sound_release? string|false [button]
---@field sound_hover? string|false [EXCEPT text & image]
---
---@field floatText? string | function [hint]
---@field floatFontSize? number [hint]
---@field floatFontType? string [hint]
---@field floatImage? string | love.Drawable [hint]
---@field floatBox? false | number[] [hint]
---@field floatCornerR? number
---@field floatLineWidth? number
---@field floatFillColor? Zenitha.ColorStr | Zenitha.Color
---@field floatFrameColor? Zenitha.ColorStr | Zenitha.Color
---@field floatTextColor? Zenitha.ColorStr | Zenitha.Color
---
---@field r? number [image]
---@field k? number [image]
---
---@field sound_on? string | false | false [checkBox & switch]
---@field sound_off? string | false | false [checkBox & switch]
---
---@field numFontSize? number [sliders]
---@field numFontType? string [sliders]
---@field axis? {minVal:number, maxVal:number, step?:number} [slider & slider_fill]
---@field unit? false | number [sliders] Unit shown on the axis (default to axis[3])
---@field valueShow? false | 'int' | 'float' | 'percent' | function [sliders] Value showing mode or function [called with widgetObj)
---@field lineDist? number [slider_fill] Outline dist from the bat
---@field soundInterval? number [sliders] Minimum interval between two sounds
---@field soundPitchRange? number [sliders] Pitch range applied to sound_drag, 12 for ±1 octave
---@field sound_drag? string | false [sliders] Drag sound
---
---@field selFontSize? number [selector]
---@field selFontType? string [selector]
---@field list? table [selector]
---@field show? function [selector]
---
---@field secret? boolean [inputBox]
---@field regex? string [inputBox]
---@field maxInputLength? number [inputBox]
---@field sound_input? string | false [inputBox]
---@field sound_bksp? string | false [inputBox]
---@field sound_clear? string | false [input/textBox]
---@field sound_fail? string | false [inputBox]
---
---@field scrollBarPos? 'left' | 'right' [textBox & listBox]
---@field scrollBarWidth? number [textBox & listBox]
---@field scrollBarDist? number [textBox & listBox]
---@field scrollBarColor? Zenitha.ColorStr | Zenitha.Color [textBox & listBox]
---@field lineHeight? number [textBox & listBox]
---
---@field yOffset? number [textBox]
---@field editable? boolean [textBox]
---
---@field drawFunc? fun(item:any, id:integer, selected:boolean) [listBox]
---@field releaseDist? number [listBox]
---@field stencilMode? 'total' | 'single' | false [listBox]
---@field sound_click? string | false [listBox]
---@field sound_select? string | false [listBox]

local type,assert,next,rawget=type,assert,next,rawget
local floor,ceil=math.floor,math.ceil
local max,min=math.max,math.min
local abs,clamp=math.abs,MATH.clamp
local sub,ins,rem=string.sub,table.insert,table.remove

local gc_translate,gc_scale=GC.translate,GC.scale
local gc_push,gc_pop=GC.push,GC.pop
local gc_setColor,gc_setLineWidth=GC.setColor,GC.setLineWidth
local gc_draw,gc_line=GC.draw,GC.line
local gc_rectangle,gc_circle=GC.rectangle,GC.circle
local gc_print,gc_printf=GC.print,GC.printf
local gc_stc_reset,gc_stc_stop=GC.stc_reset,GC.stc_stop
local gc_stc_circ,gc_stc_rect=GC.stc_circ,GC.stc_rect
local gc_mStr=GC.mStr
local gc_mRect=GC.mRect
local gc_mDraw=GC.mDraw

local kb=ZENITHA.keyboard
local timer=ZENITHA.timer.getTime

local COLOR,SCN,SCR,xOy=COLOR,SCN,SCR,SCR.xOy
local setFont,getFont=FONT.set,FONT.get
local utf8=require'utf8'

local legalLabelPos={
    norm={
        left=true,
        right=true,
        top=true,
        bottom=true,
    },
    noTop={
        left=true,
        right=true,
        bottom=true,
    },
    complex={
        center=true,
        top=true,
        right=true,
        bottom=true,
        left=true,
        topRight=true,
        topLeft=true,
        rightBottom=true,
        rightTop=true,
        bottomRight=true,
        bottomLeft=true,
        leftBottom=true,
        leftTop=true,
    },
}
local indexMeta={
    __index=function(L,k)
        for i=1,#L do
            if L[i].name==k then
                return L[i]
            end
        end
    end,
}

local function updateWheel(self,d)
    self._floatWheel=self._floatWheel+(d or 0)
    if abs(self._floatWheel)>=1 then
        local n=MATH.sign(self._floatWheel)*floor(abs(self._floatWheel))
        self._floatWheel=self._floatWheel-n
        return n
    end
end
local function alignDraw(self,drawable,x,y,r,kx,ky)
    local w=drawable:getWidth()
    local h=drawable:getHeight()
    if not kx then kx=min(self.widthLimit/w,1) end
    if not ky then ky=kx or 1 end
    local ox=self.alignX=='center' and w*.5 or self.alignX=='left' and 0 or w
    local oy=self.alignY=='center' and h*.5 or self.alignY=='top' and 0 or h
    gc_draw(drawable,x,y,r,kx,ky,ox,oy)
end
local function alignDrawQ(self,texture,quad,x,y,r,kx,ky)
    local _,_,w,h=quad:getViewport()
    if not kx then kx=min(self.widthLimit/w,1) end
    if not ky then ky=kx or 1 end
    local ox=self.alignX=='center' and w*.5 or self.alignX=='left' and 0 or w
    local oy=self.alignY=='center' and h*.5 or self.alignY=='top' and 0 or h
    gc_draw(texture,quad,x,y,r,kx,ky,ox,oy)
end
local function parseImgPath(path)
    local str=STRING.split(path,'/')
    local _img=IMG
    repeat
        _img=_img[rem(str,1)]
    until not (str[1] and _img)
    return _img or PAPER
end

local leftAngle=GC.load{w=20,
    {'setLW',5},
    {'line', 18,2,1,10,18,18},
}
local rightAngle=GC.load{w=20,
    {'setLW',5},
    {'line', 2,2,19,10,2,18},
}

local Widgets={}

--------------------------------------------------------------

---@class Zenitha.Widget.base not used by user
---@field _widget true
---@field type string
---@field name string | false
---
---@field color Zenitha.ColorStr | Zenitha.Color
---@field textColor Zenitha.ColorStr | Zenitha.Color
---@field fillColor Zenitha.ColorStr | Zenitha.Color
---@field frameColor Zenitha.ColorStr | Zenitha.Color
---@field imageColor Zenitha.ColorStr | Zenitha.Color
---@field activeColor Zenitha.ColorStr | Zenitha.Color
---@field scrollBarColor Zenitha.ColorStr | Zenitha.Color
---
---@field lineWidth number
---@field cornerR number
---
---@field sound_press string | false
---@field sound_hover string | false
---
---@field _text love.Drawable | false
---@field _image love.Image | love.Drawable | false
---@field _hoverTime number
---@field _hoverTimeMax number
---@field _pressed boolean
---@field _pressTime number
---@field _pressTimeMax number
---@field _visible boolean | nil
---
---@field reset function
---@field press function
---@field release function
---@field scroll function
---@field drag function
---@field update function
---@field draw function
---@field isAbove function
---@field arrowKey function
---@field keypress function
---@field code function
Widgets.base={
    _widget=true,
    type='null',
    name=false,

    text=false,
    image=false,
    quad=false,

    keepFocus=false,
    x=0,y=0,

    color='L',
    textColor='L',
    fillColor='L',
    frameColor='L',
    imageColor='LL',
    activeColor='LY',
    scrollBarColor='L',
    pos=false,
    lineWidth=4,cornerR=3,
    textScale=1,fontSize=30,fontType=false,
    widthLimit=1e99,
    labelPos='left',
    labelDist=20,
    alignX='center',alignY='center',
    marginX=5,marginY=0,
    sound_press=false,sound_hover=false,

    isAbove=NULL,
    draw=NULL,
    visibleFunc=false, -- function return a boolean
    visibleTick=false, -- function return a boolean

    _text=false,
    _image=false,
    _hoverTime=0,
    _hoverTimeMax=.1,
    _pressed=false,
    _pressTime=0,
    _pressTimeMax=.05,
    _visible=nil,

    buildArgs={},
}
function Widgets.base:getInfo()
    local str=''
    for _,v in next,self.buildArgs do
        if type(self[v])=='number' or type(self[v])=='string' or type(self[v])=='boolean' then
            str=str..v..'='..tostring(self[v])..'\n'
        end
    end
    return str
end
function Widgets.base:resetPos()
    if self.pos then
        self._x=self.x+(self.pos[1] and self.pos[1]*(SCR.w0+2*SCR.x/SCR.k)-SCR.x/SCR.k or 0)
        self._y=self.y+(self.pos[2] and self.pos[2]*(SCR.h0+2*SCR.y/SCR.k)-SCR.y/SCR.k or 0)
    else
        self._x=self.x
        self._y=self.y
    end
end
local colorKeys={'color','textColor','fillColor','frameColor','imageColor','activeColor','scrollBarColor'}
function Widgets.base:reset(init)
    assert(not self.name or type(self.name)=='string',"[widget].name need string")

    assert(type(self.x)=='number',"[widget].x need number")
    assert(type(self.y)=='number',"[widget].y need number")
    for _,key in next,colorKeys do
        if type(self[key])=='string' then self[key]=COLOR[self[key]] end
        assert(type(self[key])=='table',"[widget]."..key.." need table")
        if not self[key][4] then self[key][4]=1 end
    end

    assert(type(self.lineWidth)=='number',"[widget].lineWidth need number")
    assert(type(self.cornerR)=='number',"[widget].cornerR need number")

    assert(self.alignX=='left' or self.alignX=='right' or self.alignX=='center',"[widget].alignX need 'left', 'right' or 'center'")
    assert(self.alignY=='top' or self.alignY=='bottom' or self.alignY=='center',"[widget].alignY need 'top', 'bottom' or 'center'")
    assert(type(self.marginX)=='number' and type(self.marginY)=='number',"[widget].marginX/Y need number")
    assert(type(self.labelDist)=='number',"[widget].labelDist need number")

    if self.pos then
        assert(
            type(self.pos)=='table' and
            (type(self.pos[1])=='number' or self.pos[1]==false) and
            (type(self.pos[2])=='number' or self.pos[2]==false),
            "[widget].pos[1] and [2] need number|false}"
        )
    end

    assert(type(self.fontSize)=='number',"[widget].fontSize need number")
    assert(type(self.fontType)=='string' or self.fontType==false,"[widget].fontType need string")
    assert(type(self.widthLimit)=='number',"[widget].widthLimit need number")
    assert(not self.visibleFunc or type(self.visibleFunc)=='function',"[widget].visibleFunc need function")
    assert(not self.visibleTick or type(self.visibleTick)=='function',"[widget].visibleTick need function")

    assert(not self.sound_press or type(self.sound_press)=='string',"[widget].sound_press need string")
    assert(not self.sound_hover or type(self.sound_hover)=='string',"[widget].sound_hover need string")

    self:resetPos()

    if type(self._text)=='userdata' and type(self._text.type)=='function' and self._text:type()=='Text' then self._text:release() end
    local content=self.text or self.name and ("["..self.name.."]")
    if content then
        if type(content)=='function' then
            content=content()
        end
        assert(type(content)=='string' or type(content)=='table',"[widget].text need colorstring|fun():colorstring")
        self._text=GC.newText(getFont(self.fontSize,self.fontType),content)
    else
        self._text=PAPER
    end

    if self.image then
        self._image=
            type(self.image)=='string' and
            parseImgPath(self.image) or
            self.image
    end
    if self.quad then
        assert(type(self.quad)=='userdata' and self.quad:type()=='Quad',"[widget].quad need love.Quad")
    end

    self._pressed=false
    self._hoverTime=0

    if self._visible==nil then
        self._visible=true
    end
    if not init then
        if self.visibleFunc then
            self._visible=self.visibleFunc()
        elseif self.visibleTick then
            self._visible=self.visibleTick()
        end
    end
end
function Widgets.base:setVisible(bool)
    if bool==nil then
        if self.visibleFunc then
            self._visible=self.visibleFunc()
        elseif self.visibleTick then
            self._visible=self.visibleTick()
        end
    else
        self._visible=bool and true or false
    end
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


---@class Zenitha.Widget.text: Zenitha.Widget.base
Widgets.text=setmetatable({
    type='text',

    text=false,

    buildArgs={
        'name',
        'pos',
        'x','y',
        'alignX','alignY',

        'color','textColor',
        'text','textScale','fontSize','fontType',

        'widthLimit',

        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.text:reset(init)
    if self.color then
        self.textColor=self.color
    end
    Widgets.base.reset(self,init)
end
function Widgets.text:draw()
    if self._text then
        gc_setColor(self.textColor)
        alignDraw(self,self._text,self._x,self._y,nil,self.textScale)
    end
end


---@class Zenitha.Widget.image: Zenitha.Widget.base
---@field _kx number | false
---@field _ky number | false
Widgets.image=setmetatable({
    type='image',
    w=false,h=false,k=false,
    r=0,

    image=false,
    _kx=false,_ky=false,

    buildArgs={
        'name',
        'pos',
        'x','y',
        'k','w','h', -- k & w+h are not compatible
        'alignX','alignY',

        'r',
        'imageColor',
        'image','quad',

        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.image:reset(init)
    Widgets.base.reset(self,init)
    assert(not self.k or not (self.w or self.h),"[image].w/h and .k cannot appear at the same time")
    if not self._image then return end

    if self.k then
        self._kx,self._ky=self.k,self.k
    elseif self.w or self.h then
        if self.w then self._kx=self.w/self._image:getWidth() end
        if self.h then self._ky=self.h/self._image:getHeight() end
        if not self.w then self._kx=self._ky end
        if not self.h then self._ky=self._kx end
    else
        self._kx,self._ky=1,1
    end
end
function Widgets.image:draw()
    if self._image then
        gc_setColor(self.imageColor)
        if self.quad then
            alignDrawQ(self,self._image,self.quad,self._x,self._y,self.r,self._kx,self._ky)
        else
            alignDraw(self,self._image,self._x,self._y,self.r,self._kx,self._ky)
        end
    end
end


---@class Zenitha.Widget.button: Zenitha.Widget.base
---@field w number
---@field h number
---@field sound_release string | false
Widgets.button=setmetatable({
    type='button',
    w=40,h=false,

    text=false,
    image=false,
    cornerR=10,
    sound_release=false,

    onPress=NULL,
    onClick=NULL,

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',
        'alignX','alignY',
        'marginX','marginY',
        'lineWidth','cornerR',

        'color','fillColor','frameColor','imageColor','textColor',
        'text','textScale','fontSize','fontType','image','quad',
        'sound_release',
        'sound_press','sound_hover',

        'onPress','onClick',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.button:reset(init)
    self.fillColor=rawget(self,'fillColor') or rawget(self,'color') or self.fillColor
    self.frameColor=rawget(self,'frameColor') or rawget(self,'color') or self.frameColor
    self.textColor=rawget(self,'textColor') or rawget(self,'color') or self.textColor
    Widgets.base.reset(self,init)
    if not self.h then self.h=self.w end
    assert(self.w and type(self.w)=='number',"[button].w need number")
    assert(self.h and type(self.h)=='number',"[button].h need number")
    assert(not self.sound_release or type(self.sound_release)=='string',"[button].sound_release need string")
    self.widthLimit=self.w
end
function Widgets.button:isAbove(x,y)
    return
        abs(x-self._x)<self.w*.5 and
        abs(y-self._y)<self.h*.5
end
function Widgets.button:press(_,_,k)
    self._pressed=true
    self.onPress(k)
end
function Widgets.button:release(_,_,k)
    if self._pressed then
        self._pressed=false
        if self.sound_release then
            SFX.play(self.sound_release)
        end
        self.onClick(k)
    end
end
function Widgets.button:drag(x,y)
    if not self:isAbove(x,y) and WIDGET.sel==self then
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

    local fillC=self.fillColor
    local frameC=self.frameColor

    -- Background
    gc_setColor(fillC[1],fillC[2],fillC[3],fillC[4]*(.1+.2*self._hoverTime/self._hoverTimeMax))
    gc_mRect('fill',0,0,w,h,self.cornerR)

    -- Frame
    gc_setLineWidth(self.lineWidth)
    gc_setColor(.2+frameC[1]*.8,.2+frameC[2]*.8,.2+frameC[3]*.8,.95)
    gc_mRect('line',0,0,w,h,self.cornerR)

    -- Drawable
    local startX=self.alignX=='center' and 0 or self.alignX=='left' and -w*.5+self.marginX or w*.5-self.marginX
    local startY=self.alignY=='center' and 0 or self.alignY=='top' and -h*.5+self.marginY or h*.5-self.marginY
    if self._image then
        gc_setColor(self.imageColor)
        if self.quad then
            alignDrawQ(self,self._image,self.quad,startX,startY)
        else
            alignDraw(self,self._image,startX,startY)
        end
    end
    if self._text then
        gc_setColor(self.textColor)
        alignDraw(self,self._text,startX,startY,nil,self.textScale)
    end
    gc_pop()
end


---@class Zenitha.Widget.hint: Zenitha.Widget.base
---@field w number
---@field h number
---@field floatFontSize number
---@field floatFontType string
---@field floatBox number[]
---@field floatCornerR number
---@field floatLineWidth number
---@field floatFillColor Zenitha.ColorStr | Zenitha.Color
---@field floatFrameColor Zenitha.ColorStr | Zenitha.Color
---@field floatTextColor Zenitha.ColorStr | Zenitha.Color
---@field _floatText love.Drawable | false
---@field _floatImage love.Drawable | false
---@field _floatBox number[]
Widgets.hint=setmetatable({
    type='hint',
    w=40,h=false,

    text=false,
    image=false,
    cornerR=10,

    floatText=false,
    floatFontSize=30,
    floatFontType=false,
    floatImage=false,
    floatBox=false,
    labelPos='top',
    labelDist=10,
    marginX=15,
    marginY=10,
    floatCornerR=5,
    floatLineWidth=3,
    floatFillColor={.1,.1,.1,.8},
    floatFrameColor='DL',
    floatTextColor='dL',

    _floatText=false,
    _floatImage=false,
    _floatBox=false,

    onPress=NULL,

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',
        'lineWidth','cornerR',

        'color','frameColor','textColor',
        'text','textScale','fontSize','fontType','image','quad',
        'floatImage','floatText','floatFontSize','floatFontType',
        'floatBox','marginX','marginY',
        'labelPos','labelDist',
        'floatCornerR','floatLineWidth','floatFillColor','floatFrameColor','floatTextColor',

        'sound_hover',

        'onPress',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
local colorKeys_hint={'floatFillColor','floatFrameColor','floatTextColor'}
function Widgets.hint:reset(init)
    self.fillColor=rawget(self,'fillColor') or rawget(self,'color') or self.fillColor
    self.frameColor=rawget(self,'frameColor') or rawget(self,'color') or self.frameColor
    self.textColor=rawget(self,'textColor') or rawget(self,'color') or self.textColor
    Widgets.base.reset(self,init)
    if not self.h then self.h=self.w end
    assert(self.w and type(self.w)=='number',"[hint].w need number")
    assert(self.h and type(self.h)=='number',"[hint].h need number")
    assert(legalLabelPos.complex[self.labelPos],"[hint].labelPos need 'center', or (combination of, like 'rightTop') 'left', 'right', 'top', 'bottom'")

    for _,key in next,colorKeys_hint do
        if type(self[key])=='string' then self[key]=COLOR[self[key]] end
        assert(type(self[key])=='table',"[hint]."..key.." need table")
        if not self[key][4] then self[key][4]=1 end
    end

    if self.floatImage then
        self._floatImage=
            type(self.floatImage)=='string' and
            parseImgPath(self.floatImage) or
            self.floatImage
    end
    if self.floatText then
        if type(self.floatText)=='function' then
            self._floatText=self.floatText()
        else
            self._floatText=self.floatText
        end
        assert(type(self._floatText)=='string' or type(self._floatText)=='table',"[hint].floatText need colorstring|fun():colorstring")
        self._floatText=GC.newText(getFont(self.floatFontSize,self.floatFontType),self._floatText)
    end
    if not self.floatFontSize then self.floatFontSize=self.fontSize end
    if not self.floatFontType then self.floatFontType=self.fontType end
    assert(type(self.floatFontSize)=='number',"[hint].floatFontSize need number")
    assert(type(self.floatFontType)=='string' or self.floatFontType==false,"[hint].floatFontType need string")

    local box
    if self.floatBox then
        assert(type(box)=='table',"[widget].floatBox need {x,y,w,h}")
        box=TABLE.copy(self.floatBox)
        for i=1,4 do assert(type(box[i])=='number',"[widget].floatBox need {x,y,w,h}") end
    else
        local w,h=(self._floatImage or self._floatText or PAPER):getDimensions()
        w,h=w+self.marginX*2,h+self.marginY*2
        box={-w*.5,-h*.5,w,h}
    end
    if self.labelPos=='top' then
        box[2]=box[2]-(self.h+box[4])*.5-self.labelDist
    elseif self.labelPos=='right' then
        box[1]=box[1]+(self.w+box[3])*.5+self.labelDist
    elseif self.labelPos=='bottom' then
        box[2]=box[2]+(self.h+box[4])*.5+self.labelDist
    elseif self.labelPos=='left' then
        box[1]=box[1]-(self.w+box[3])*.5-self.labelDist
    elseif self.labelPos=='topRight' then
        box[2]=box[2]-(self.h+box[4])*.5-self.labelDist
        box[1]=-self.w*.5
    elseif self.labelPos=='topLeft' then
        box[2]=box[2]-(self.h+box[4])*.5-self.labelDist
        box[1]=-box[3]+self.w*.5
    elseif self.labelPos=='rightBottom' then
        box[1]=box[1]+(self.w+box[3])*.5+self.labelDist
        box[2]=-self.h*.5
    elseif self.labelPos=='rightTop' then
        box[1]=box[1]+(self.w+box[3])*.5+self.labelDist
        box[2]=-box[4]+self.h*.5
    elseif self.labelPos=='bottomRight' then
        box[2]=box[2]+(self.h+box[4])*.5+self.labelDist
        box[1]=-self.w*.5
    elseif self.labelPos=='bottomLeft' then
        box[2]=box[2]+(self.h+box[4])*.5+self.labelDist
        box[1]=-box[3]+self.w*.5
    elseif self.labelPos=='leftBottom' then
        box[1]=box[1]-(self.w+box[3])*.5-self.labelDist
        box[2]=-self.h*.5
    elseif self.labelPos=='leftTop' then
        box[1]=box[1]-(self.w+box[3])*.5-self.labelDist
        box[2]=-box[4]+self.h*.5
    end
    if self._x+box[1]<0 then
        box[1]=-self._x
    elseif self._x+box[1]+box[3]>SCR.w0 then
        box[1]=SCR.w0-self._x-box[3]
    end
    if self._y+box[2]<0 then
        box[2]=-self._y
    elseif self._y+box[2]+box[4]>SCR.h0 then
        box[2]=SCR.h0-self._y-box[4]
    end
    self._floatBox=box

    assert(type(self.floatCornerR)=='number',"[widget].floatCornerR need number")
    assert(type(self.floatLineWidth)=='number',"[widget].floatLineWidth need number")
end
function Widgets.hint:isAbove(x,y)
    return
        abs(x-self._x)<self.w*.5 and
        abs(y-self._y)<self.h*.5
end
function Widgets.hint:press(_,_,k)
    self.onPress(k)
end
function Widgets.hint:draw()
    gc_push('transform')
    gc_translate(self._x,self._y)

    local w,h=self.w,self.h
    local HOV=self._hoverTime/self._hoverTimeMax

    local frameC=self.frameColor

    -- Frame
    gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*(.1+.1*HOV))
    gc_setLineWidth(self.lineWidth)
    gc_mRect('line',0,0,w,h,self.cornerR)

    -- Drawable
    if self._image then
        gc_setColor(1,1,1)
        if self.quad then
            alignDrawQ(self,self._image,self.quad)
        else
            alignDraw(self,self._image)
        end
    end
    if self._text then
        gc_setColor(self.textColor)
        gc_mDraw(self._text,nil,nil,nil,self.textScale)
    end

    -- Hovering info
    if HOV>0 then
        local box=self._floatBox
        local fFillC=self.floatFillColor
        local fFrameC=self.floatFrameColor
        gc_translate(box[1],box[2])
        gc_setColor(fFillC[1],fFillC[2],fFillC[3],fFillC[4]*HOV)
        gc_rectangle('fill',0,0,box[3],box[4],self.floatCornerR)
        gc_setLineWidth(self.floatLineWidth)
        gc_setColor(fFrameC[1],fFrameC[2],fFrameC[3],fFrameC[4]*HOV)
        gc_rectangle('line',0,0,box[3],box[4],self.floatCornerR)
        gc_translate(box[3]*.5,box[4]*.5)
        if self._floatImage then
            gc_setColor(1,1,1,HOV)
            gc_mDraw(self._floatImage)
        end
        if self._floatText then
            local textC=self.floatTextColor
            gc_setColor(textC[1],textC[2],textC[3],textC[4]*HOV)
            gc_mDraw(self._floatText)
        end
    end
    gc_pop()
end


---@class Zenitha.Widget.checkBox: Zenitha.Widget.base
---@field w number
---@field sound_on string | false
---@field sound_off string | false
Widgets.checkBox=setmetatable({
    type='checkBox',
    w=30,

    text=false,
    image=false,
    sound_on=false,sound_off=false,

    disp=false, -- function return a boolean
    code=NULL,

    buildArgs={
        'name',
        'pos',
        'x','y','w',
        'lineWidth','cornerR',

        'labelPos',
        'labelDist',
        'color','fillColor','frameColor','textColor',
        'text','textScale','fontSize','fontType',
        'widthLimit',
        'sound_on','sound_off',
        'sound_press','sound_hover',

        'disp','code',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.checkBox:reset(init)
    self.fillColor=rawget(self,'fillColor') or rawget(self,'color') or self.fillColor
    self.frameColor=rawget(self,'frameColor') or rawget(self,'color') or self.frameColor
    self.textColor=rawget(self,'textColor') or rawget(self,'color') or self.textColor
    Widgets.base.reset(self,init)
    assert(legalLabelPos.norm[self.labelPos],"[checkBox].labelPos need 'left', 'right', 'top', or 'bottom'")

    assert(type(self.disp)=='function',"[checkBox].disp need function")
    assert(not self.sound_on or type(self.sound_on)=='string',"[checkBox].sound_on need string")
    assert(not self.sound_off or type(self.sound_off)=='string',"[checkBox].sound_off need string")

    self.alignX=self.labelPos=='left' and 'right' or self.labelPos=='right' and 'left' or 'center'
    self.alignY=self.labelPos=='top' and 'bottom' or self.labelPos=='bottom' and 'top' or 'center'
end
function Widgets.checkBox:isAbove(x,y)
    return
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

    local fillC=self.fillColor
    local frameC=self.frameColor

    -- Background
    gc_setColor(fillC[1],fillC[2],fillC[3],.3*HOV)
    gc_mRect('fill',0,0,w,w,self.cornerR)

    -- Frame
    gc_setLineWidth(self.lineWidth)
    gc_setColor(.2+frameC[1]*.8,.2+frameC[2]*.8,.2+frameC[3]*.8,frameC[4])
    gc_mRect('line',0,0,w,w,self.cornerR)
    if self.disp() then
        gc_scale(.5*w)
        gc_setLineWidth(self.lineWidth*2/w)
        gc_line(-.7,.05,-.2,.5,.7,-.55)
        gc_scale(2/w)
    end

    -- Drawable
    local x2,y2=0,0
    if self.labelPos=='left' then
        x2=-w*.5-self.labelDist
    elseif self.labelPos=='right' then
        x2=w*.5+self.labelDist
    elseif self.labelPos=='top' then
        y2=-w*.5-self.labelDist
    elseif self.labelPos=='bottom' then
        y2=w*.5+self.labelDist
    end
    if self._text then
        gc_setColor(self.textColor)
        alignDraw(self,self._text,x2,y2,nil,self.textScale)
    end
    gc_pop()
end


---@class Zenitha.Widget.switch: Zenitha.Widget.checkBox
---@field _slideTime number
Widgets.switch=setmetatable({
    type='switch',
    h=30,

    fillColor='I',
    text=false,
    image=false,

    disp=false, -- function return a boolean
    code=NULL,

    _slideTime=false,

    buildArgs={
        'name',
        'pos',
        'x','y','h',

        'labelPos',
        'labelDist',
        'color','fillColor','frameColor','textColor',
        'text','textScale','fontSize','fontType',
        'lineWidth','widthLimit',
        'sound_on','sound_off',
        'sound_press','sound_hover',

        'disp','code',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.checkBox,__metatable=true})
function Widgets.switch:reset(init)
    self.fillColor=rawget(self,'fillColor') or rawget(self,'color') or self.fillColor
    self.frameColor=rawget(self,'frameColor') or rawget(self,'color') or self.frameColor
    self.textColor=rawget(self,'textColor') or rawget(self,'color') or self.textColor
    Widgets.base.reset(self,init)
    assert(legalLabelPos.norm[self.labelPos],"[switch].labelPos need 'left', 'right', 'top', or 'bottom'")

    assert(type(self.disp)=='function',"[switch].disp need function")

    self._slideTime=0
    self.alignX=self.labelPos=='left' and 'right' or self.labelPos=='right' and 'left' or 'center'
    self.alignY=self.labelPos=='top' and 'bottom' or self.labelPos=='bottom' and 'top' or 'center'
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

    local fillC=self.fillColor
    local frameC=self.frameColor

    -- Background
    gc_setColor(fillC[1],fillC[2],fillC[3],fillC[4]*(self._slideTime/self._hoverTimeMax+.5))
    gc_mRect('fill',0,0,h*2,h,h*.5)

    -- Frame
    gc_setLineWidth(self.lineWidth)
    gc_setColor(.2+frameC[1]*.8,.2+frameC[2]*.8,.2+frameC[3]*.8,frameC[4]*(.8+.2*HOV))
    gc_mRect('line',0,0,h*2,h,h*.5)

    -- Axis
    gc_setColor(frameC[1],frameC[2],frameC[3],.8+.2*HOV)
    gc_circle('fill',h*(self._slideTime/self._hoverTimeMax),0,h*(.35+HOV*.05))

    -- Drawable
    local x2,y2=0,0
    if self.labelPos=='left' then
        x2=-h-self.labelDist
    elseif self.labelPos=='right' then
        x2=h+self.labelDist
    elseif self.labelPos=='top' then
        y2=-h*.5-self.labelDist
    elseif self.labelPos=='bottom' then
        y2=h*.5+self.labelDist
    end
    if self._text then
        gc_setColor(self.textColor)
        alignDraw(self,self._text,x2,y2,nil,self.textScale)
    end
    gc_pop()
end


---@class Zenitha.Widget.slider: Zenitha.Widget.base
---@field w number
---@field valueShow false | 'int' | 'float' | 'percent' | function
---@field numFontSize number
---@field numFontType false | string
---@field sound_drag string | false
---@field soundInterval number
---@field soundPitchRange number
---@field _showFunc function
---@field _pos number
---@field _pos0 number
---@field _rangeL number
---@field _rangeR number
---@field _rangeWidth number
---@field _unit number
---@field _textShowTime number
---@field _lastSoundTime number
Widgets.slider=setmetatable({
    type='slider',
    w=100,
    axis={0,1},
    unit=nil,

    frameColor='DL',
    text=false,
    image=false,
    numFontSize=25,numFontType=false,
    valueShow=nil,
    textAlwaysShow=false,
    sound_drag=false,
    soundInterval=.0626,
    soundPitchRange=0,

    disp=false, -- function return the displaying _value
    code=NULL,

    _floatWheel=0,
    _showFunc=false,
    _pos=false,
    _pos0=false,
    _rangeL=false,
    _rangeR=false,
    _rangeWidth=false, -- just _rangeR-_rangeL, for convenience
    _rangeUnit=false, -- actual unit of value step
    _unit=false, -- visual unit on slider
    _textShowTime=false,
    _approachSpeed=26,
    _lastSoundTime=0,

    buildArgs={
        'name',
        'pos',
        'x','y','w',
        'lineWidth','cornerR',

        'axis','unit',
        'labelPos',
        'labelDist',
        'color','fillColor','frameColor','textColor',
        'text','textScale','fontSize','fontType',
        'numFontSize','numFontType',
        'widthLimit',
        'textAlwaysShow',
        'sound_drag','sound_hover',
        'soundInterval',
        'soundPitchRange',

        'valueShow',
        'disp','code',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
local sliderShowFunc={
    null=function()
        return ''
    end,
    int=function(S)
        return S._pos0
    end,
    float=function(S)
        return floor(S._pos0*100+.5)*.01
    end,
    percent=function(S)
        return floor(S._pos0*100+.5)..'%'
    end,
}
function Widgets.slider:reset(init)
    self.fillColor=rawget(self,'fillColor') or rawget(self,'color') or self.fillColor
    self.frameColor=rawget(self,'frameColor') or rawget(self,'color') or self.frameColor
    self.textColor=rawget(self,'textColor') or rawget(self,'color') or self.textColor
    Widgets.base.reset(self,init)
    assert(legalLabelPos.noTop[self.labelPos],"[slider].labelPos need 'left', 'right', or 'bottom'")

    assert(self.w and type(self.w)=='number',"[slider].w need number")
    assert(type(self.numFontSize)=='number',"[slider].numFontSize need number")
    assert(type(self.numFontType)=='string' or self.numFontType==false,"[slider].numFontType need string")
    assert(type(self.disp)=='function',"[slider].disp need function")
    assert(
        type(self.axis)=='table' and (#self.axis==2 or #self.axis==3) and
        type(self.axis[1])=='number' and
        type(self.axis[2])=='number' and
        (not self.axis[3] or type(self.axis[3])=='number'),
        "[slider].axis need {low,high} or {low,high,unit}"
    )
    assert(not self.unit or type(self.unit)=='number' and self.unit>0,"[slider].unit need number")
    assert(not self.sound_drag or type(self.sound_drag)=='string',"[slider].sound_drag need string")
    assert(type(self.soundInterval)=='number',"[slider].soundInterval need number")
    assert(type(self.soundPitchRange)=='number',"[slider].soundPitchRange need number")

    self._rangeL=self.axis[1]
    self._rangeR=self.axis[2]
    self._rangeWidth=self._rangeR-self._rangeL
    self._rangeUnit=self.axis[3]
    if self.unit==nil then
        self._unit=self.axis[3]
    else
        self._unit=self.unit
    end
    self._pos=self._rangeL
    self._pos0=self._rangeL
    self._textShowTime=3

    if self.valueShow then
        if type(self.valueShow)=='function' then
            self._showFunc=self.valueShow
        elseif type(self.valueShow)=='string' then
            self._showFunc=sliderShowFunc[self.valueShow] or error("[slider].valueShow need function, or 'int', 'float', or 'percent'")
            end
    elseif self.valueShow==false then -- Show nothing if false
        self._showFunc=sliderShowFunc.null
    else -- Use default if nil
        if self._unit and self._unit%1==0 then
            self._showFunc=sliderShowFunc.int
        else
            self._showFunc=sliderShowFunc.percent
        end
    end

    assert(self.labelPos~='top',"[slider].labelPos cannot be 'top'")
    self.alignX=self.labelPos=='left' and 'right' or self.labelPos=='right' and 'left' or 'center'
    if self.labelPos=='bottom' then
        self.alignY='top'
        self.labelDist=max(self.labelDist,20)
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
        self._pos0=self.disp()
        self._pos=MATH.expApproach(self._pos,self._pos0,dt*self._approachSpeed)
    end
    if WIDGET.sel==self then
        self._textShowTime=2
    end
    if not self.textAlwaysShow then
        self._textShowTime=max(self._textShowTime-dt,0)
    end
end
function Widgets.slider:draw()
    local x,y=self._x,self._y
    local HOV=self._hoverTime/self._hoverTimeMax
    local x2=x+self.w
    local rangeL,rangeR=self._rangeL,self._rangeR

    local fillC=self.fillColor
    local frameC=self.frameColor

    -- Axis Units
    if self._unit then
        gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*.26)
        gc_setLineWidth(self.lineWidth)
        for p=rangeL,rangeR,self._unit do
            local X=x+self.w*(p-rangeL)/self._rangeWidth
            gc_line(X,y+7,X,y-7)
        end
    end

    -- Axis Line
    gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*(.5+HOV*.26))
    gc_setLineWidth(self.lineWidth*2)
    gc_line(x,y,x2,y)

    -- Block
    local pos=clamp(self._pos,rangeL,rangeR)
    local cx=x+self.w*(pos-rangeL)/self._rangeWidth
    local bx,by=cx-10-HOV*2,y-16-HOV*5
    local bw,bh=20+HOV*4,32+HOV*10
    gc_setColor((self._pos0<rangeL or self._pos0>rangeR) and COLOR.lR or fillC)
    gc_rectangle('fill',bx,by,bw,bh,self.cornerR)

    -- Glow
    if HOV>0 then
        gc_setLineWidth(self.lineWidth*.5)
        gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*HOV*.8)
        gc_rectangle('line',bx+1,by+1,bw-2,bh-2,self.cornerR)
    end

    -- Float text
    if self._textShowTime>0 then
        setFont(self.numFontSize,self.numFontType)
        gc_setColor(fillC[1],fillC[2],fillC[3],fillC[4]*min(self._textShowTime/2,1))
        gc_mStr(self:_showFunc(),cx,by-self.numFontSize-10)
    end

    -- Drawable
    if self._text then
        gc_setColor(self.textColor)
        if self.labelPos=='left' then
            alignDraw(self,self._text,x-self.labelDist,y,nil,self.textScale)
        elseif self.labelPos=='right' then
            alignDraw(self,self._text,x+self.w+self.labelDist,y,nil,self.textScale)
        elseif self.labelPos=='bottom' then
            alignDraw(self,self._text,x+self.w*.5,y+self.labelDist,nil,self.textScale)
        end
    end
end
function Widgets.slider:trigger(x,mode)
    if not x then return end
    local pos=clamp((x-self._x)/self.w,0,1)
    local newVal=
        self._rangeUnit and self._rangeL+floor(pos*self._rangeWidth/self._rangeUnit+.5)*self._rangeUnit
        or (1-pos)*self._rangeL+pos*self._rangeR
    if mode~='release' and self.sound_drag and timer()-self._lastSoundTime>self.soundInterval and newVal~=self.disp() then
        SFX.play(self.sound_drag,nil,nil,(pos*2-1)*self.soundPitchRange)
        self._lastSoundTime=timer()
    end
    if mode~='drag' or newVal~=self.disp() then
        self.code(newVal,mode)
    end
end
function Widgets.slider:press(x)
    self:trigger(x,'press')
end
function Widgets.slider:drag(x)
    self:trigger(x,'drag')
end
function Widgets.slider:release(x)
    self:trigger(x,'release')
end
function Widgets.slider:scroll(dx,dy)
    local n=updateWheel(self,(dx+dy)*self._rangeWidth/(self._rangeUnit or .01)/20)
    if n then
        local p=self._pos0
        local u=self._rangeUnit or .01
        local P=clamp(p+u*n,self._rangeL,self._rangeR)
        if P and p~=P then
            self.code(P)
        end
    end
end
function Widgets.slider:arrowKey(k)
    self:scroll((k=='left' or k=='up') and -1 or 1,0)
end


---@class Zenitha.Widget.slider_fill: Zenitha.Widget.slider
---@field w number
---@field h number
Widgets.slider_fill=setmetatable({
    type='slider_fill',
    w=100,h=40,
    axis={0,1},

    text=false,
    image=false,
    lineDist=3,
    sound_drag=false,
    soundInterval=.0626,
    soundPitchRange=0,

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',

        'axis',
        'labelPos',
        'labelDist',
        'lineWidth','lineDist',
        'color','fillColor','frameColor','textColor',
        'text','textScale','fontSize','fontType',
        'widthLimit',
        'sound_drag','sound_hover',
        'soundInterval',
        'soundPitchRange',

        'disp','code',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.slider,__metatable=true})
function Widgets.slider_fill:reset(init)
    self.fillColor=rawget(self,'fillColor') or rawget(self,'color') or self.fillColor
    Widgets.base.reset(self,init)
    assert(legalLabelPos.noTop[self.labelPos],"[slider_fill].labelPos need 'left', 'right', or 'bottom'")

    assert(self.w and type(self.w)=='number',"[slider_fill].w need number")
    assert(self.h and type(self.h)=='number',"[slider_fill].h need number")
    assert(type(self.disp)=='function',"[slider_fill].disp need function")
    assert(not self.sound_drag or type(self.sound_drag)=='string',"[slider_fill].sound_drag need string")
    assert(type(self.soundInterval)=='number',"[slider_fill].soundInterval need number")
    assert(type(self.soundPitchRange)=='number',"[slider_fill].soundPitchRange need number")

    assert(
        type(self.axis)=='table' and #self.axis==2 and
        type(self.axis[1])=='number' and
        type(self.axis[2])=='number',
        "[slider_fill].axis need {number,number}"
    )
    self._rangeL=self.axis[1]
    self._rangeR=self.axis[2]
    self._rangeWidth=self._rangeR-self._rangeL
    self._pos=self._rangeL
    self._textShowTime=3

    assert(self.labelPos~='top',"[slider_fill].cannot be 'top'")
    self.alignX=self.labelPos=='left' and 'right' or self.labelPos=='right' and 'left' or 'center'
    if self.labelPos=='bottom' then
        self.alignY='top'
        self.labelDist=max(self.labelDist,20)
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
    local num=floor((self._pos0-self._rangeL)/self._rangeWidth*100+.5)..'%'

    local fillC=self.fillColor
    local frameC=self.frameColor

    -- Capsule
    gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*(.6+HOV*.26))
    gc_setLineWidth(self.lineWidth+HOV)
    gc_mRect('line',x+w*.5,y-r+h*.5,w+2*self.lineDist,h+2*self.lineDist,r+self.lineDist)
    if HOV>0 then
        gc_setColor(fillC[1],fillC[2],fillC[3],fillC[4]*HOV*.12)
        gc_mRect('fill',x+w*.5,y-r+h*.5,w+2*self.lineDist,h+2*self.lineDist,r+self.lineDist)
    end

    -- Stenciled capsule
    gc_stc_reset()
    gc_stc_rect(x+r,y-r,w-h,h)
    gc_stc_circ(x+r,y,r)
    gc_stc_circ(x+w-r,y,r)

    -- Text 1
    setFont(self.numFontSize,self.numFontType)
    gc_setColor(1,1,1,.75+HOV*.26)
    gc_mStr(num,x+w*.5,y-self.numFontSize*.7)
    gc_rectangle('fill',x,y-r,w*rate,h)

    -- Text 2
    gc_stc_reset()
    gc_stc_rect(x,y-r,w*rate,h)
    gc_setColor(0,0,0,.9)
    gc_mStr(num,x+w*.5,y-self.numFontSize*.7)
    gc_stc_stop()

    -- Drawable
    if self._text then
        gc_setColor(self.textColor)
        local x2,y2
        if self.labelPos=='left' then
            x2,y2=x-self.labelDist,y
        elseif self.labelPos=='right' then
            x2,y2=x+w+self.labelDist,y
        elseif self.labelPos=='bottom' then
            x2,y2=x+w*.5,y-self.labelDist
        end
        alignDraw(self,self._text,x2,y2,nil,self.textScale)
    end
end


---@class Zenitha.Widget.slider_progress: Zenitha.Widget.slider
---@field w number
---@field h number
Widgets.slider_progress=setmetatable({
    type='slider_progress',
    w=100,h=10,
    frameColor='LD',
    fillColor='L',

    text=false,
    image=false,
    lineDist=3,
    sound_drag=false,
    soundInterval=.0626,
    soundPitchRange=0,

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',
        'color','frameColor','fillColor',

        'labelPos',
        'labelDist',
        'lineWidth',
        'text','textScale','fontSize','fontType',
        'widthLimit',
        'sound_drag','sound_hover',
        'soundInterval',
        'soundPitchRange',

        'disp','code',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.slider,__metatable=true})
function Widgets.slider_progress:reset(init)
    self.fillColor=rawget(self,'fillColor') or rawget(self,'color') or self.fillColor
    Widgets.base.reset(self,init)
    assert(legalLabelPos.noTop[self.labelPos],"[slider_progress].labelPos need 'left', 'right', or 'bottom'")

    assert(self.w and type(self.w)=='number',"[slider_progress].w need number")
    assert(self.h and type(self.h)=='number',"[slider_progress].h need number")
    assert(type(self.disp)=='function',"[slider_progress].disp need function")
    assert(not self.sound_drag or type(self.sound_drag)=='string',"[slider_progress].sound_drag need string")
    assert(type(self.soundInterval)=='number',"[slider_progress].soundInterval need number")
    assert(type(self.soundPitchRange)=='number',"[slider_progress].soundPitchRange need number")

    assert(
        type(self.axis)=='table' and #self.axis==2 and
        type(self.axis[1])=='number' and
        type(self.axis[2])=='number',
        "[slider_progress].axis need {number,number}"
    )
    self._rangeL=self.axis[1]
    self._rangeR=self.axis[2]
    self._rangeWidth=self._rangeR-self._rangeL
    self._pos=self._rangeL
    self._textShowTime=3

    assert(self.labelPos~='top',"[slider_progress].labelPos cannot be 'top'")
    self.alignX=self.labelPos=='left' and 'right' or self.labelPos=='right' and 'left' or 'center'
    if self.labelPos=='bottom' then
        self.alignY='top'
        self.labelDist=max(self.labelDist,20)
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

    local fillC=self.fillColor
    local frameC=self.frameColor

    h=h*(1+HOV)

    gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*(.4+.1*HOV))
    gc_rectangle('fill',x,y-h*.5,w,h,h*.5)
    gc_setColor(fillC)
    if w*self._pos>=1 then
        gc_rectangle('fill',x,y-h*.5,w*self._pos,h,h*.5)
    end

    -- Drawable
    if self._text then
        local x2,y2
        if self.labelPos=='left' then
            x2,y2=x-self.labelDist,y
        elseif self.labelPos=='right' then
            x2,y2=x+w+self.labelDist,y
        elseif self.labelPos=='bottom' then
            x2,y2=x+w*.5,y-self.labelDist
        end
        alignDraw(self,self._text,x2,y2,nil,self.textScale)
    end
end


---@class Zenitha.Widget.selector: Zenitha.Widget.base
---@field w number
---@field _select number | false
---@field _selText love.Text
Widgets.selector=setmetatable({
    type='selector',
    w=100,

    list=false, -- table of items
    disp=false, -- function return a boolean
    show=function(v) return v end,
    code=NULL,

    _floatWheel=0,
    _select=false, -- Selected item ID
    _selText=false, -- Selected item name
    selFontSize=30,selFontType=false,

    buildArgs={
        'name',
        'pos',
        'x','y','w',

        'color','frameColor','textColor',
        'text','textScale','fontSize','fontType',
        'selFontSize','selFontType',
        'widthLimit',

        'labelPos',
        'labelDist',
        'sound_press','sound_hover',

        'list','disp','show',
        'code',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.selector:reset(init)
    self.frameColor=rawget(self,'frameColor') or rawget(self,'color') or self.frameColor
    self.textColor=rawget(self,'textColor') or rawget(self,'color') or self.textColor
    Widgets.base.reset(self,init)
    assert(legalLabelPos.norm[self.labelPos],"[selector].labelPos need 'left', 'right', or 'bottom'")

    assert(self.w and type(self.w)=='number',"[selector].w need number")
    assert(type(self.list)=='table',"[selector].list need table")
    assert(type(self.disp)=='function',"[selector].disp need function")
    assert(type(self.show)=='function',"[selector].show need function")

    if self.labelPos=='left' then
        self.alignX='right'
    elseif self.labelPos=='right' then
        self.alignX='left'
    elseif self.labelPos=='bottom' then
        self.alignY='top'
    elseif self.labelPos=='top' then
        self.alignY='bottom'
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

    local frameC=self.frameColor

    -- Arrow
    if self._select then
        gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*(.6+HOV*.26))
        local t=(timer()%.5)^.5
        if self._select>1 then
            gc_draw(leftAngle,x-w*.5,y-10)
            if HOV>0 then
                gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*HOV*1.5*(.5-t))
                gc_draw(leftAngle,x-w*.5-t*40,y-10)
                gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*(.6+HOV*.26))
            end
        end
        if self._select<#self.list then
            gc_draw(rightAngle,x+w*.5-20,y-10)
            if HOV>0 then
                gc_setColor(frameC[1],frameC[2],frameC[3],frameC[4]*HOV*1.5*(.5-t))
                gc_draw(rightAngle,x+w*.5-20+t*40,y-10)
            end
        end
    end

    -- Drawable
    local x2,y2
    if self.labelPos=='left' then
        x2,y2=x-w*.5-self.labelDist,y
    elseif self.labelPos=='right' then
        x2,y2=x+w*.5+self.labelDist,y
    elseif self.labelPos=='top' then
        x2,y2=x,y-self.labelDist
    elseif self.labelPos=='bottom' then
        x2,y2=x,y+self.labelDist
    end
    if self._text then
        gc_setColor(self.textColor)
        alignDraw(self,self._text,x2,y2,nil,self.textScale)
    end
    if self._selText then
        gc_setColor(self.textColor)
        gc_mDraw(self._selText,x,y)
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
            if self.sound_press then
                SFX.play(self.sound_press)
            end
        end
    end
end
function Widgets.selector:scroll(dx,dy)
    local n=updateWheel(self,dx+dy)
    if n then
        local s=self._select
        if n==1 then
            if s==#self.list then return end
            s=s+1
        elseif n==-1 then
            if s==1 then return end
            s=s-1
        end
        self.code(self.list[s])
        self._select=s
        self._selText:set(self.show(self.list[s]))
        if self.sound_press then
            SFX.play(self.sound_press)
        end
    end
end
function Widgets.selector:arrowKey(k)
    self:scroll((k=='left' or k=='up') and -1 or 1,0)
end


---@class Zenitha.Widget.inputBox: Zenitha.Widget.base
---@field w number
---@field h number
---@field sound_input string | false
---@field sound_bksp string | false
---@field sound_clear string | false
---@field sound_fail string | false
Widgets.inputBox=setmetatable({
    type='inputBox',
    keepFocus=true,
    w=100,h=40,

    fillColor={0,0,0,.3},
    secret=false,
    regex=false,

    maxInputLength=1e99,
    sound_input=false,sound_bksp=false,sound_clear=false,sound_fail=false,

    _value='', -- Text contained

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',
        'lineWidth','cornerR',

        'fillColor','frameColor','textColor','activeColor',
        'text','textScale','fontSize','fontType',
        'secret',
        'regex',
        'labelPos',
        'labelDist',
        'maxInputLength',
        'sound_input','sound_bksp','sound_clear','sound_fail',
        'sound_press','sound_hover',

        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.inputBox:reset(init)
    Widgets.base.reset(self,init)
    assert(legalLabelPos.norm[self.labelPos],"[inputBox].labelPos need 'left', 'right', or 'bottom'")

    assert(self.w and type(self.w)=='number',"[inputBox].w need number")
    assert(self.h and type(self.h)=='number',"[inputBox].h need number")
    assert(not self.sound_input or type(self.sound_input)=='string',"[inputBox].sound_input need string")
    assert(not self.sound_bksp or type(self.sound_bksp)=='string',"[inputBox].sound_bksp need string")
    assert(not self.sound_clear or type(self.sound_clear)=='string',"[inputBox].sound_clear need string")
    assert(not self.sound_fail or type(self.sound_fail)=='string',"[inputBox].sound_fail need string")
    if self.labelPos=='left' then
        self.alignX,self.alignY='right','center'
    elseif self.labelPos=='right' then
        self.alignX,self.alignY='left','center'
    elseif self.labelPos=='top' then
        self.alignX,self.alignY='center','bottom'
    elseif self.labelPos=='bottom' then
        self.alignX,self.alignY='center','top'
    end
end
function Widgets.inputBox:_cutTooLong()
    local extra=utf8.offset(self._value,self.maxInputLength+1)
    if extra then
        self._value=sub(self._value,1,extra-1)
    end
end
function Widgets.inputBox:hasText()
    return #self._value>0
end
function Widgets.inputBox:getText()
    return self._value
end
function Widgets.inputBox:setText(str)
    if not str then str="" end
    assert(type(str)=='string',"Arg need string")
    self._value=str
    self:_cutTooLong()
end
function Widgets.inputBox:addText(str)
    if not str then str="" end
    assert(type(str)=='string',"Arg need string")
    self._value=self._value..str
    self:_cutTooLong()
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

    local actColor=self.activeColor

    -- Background
    gc_setColor(self.fillColor)
    gc_rectangle('fill',x,y,w,h,self.cornerR)

    -- Highlight
    gc_setColor(actColor[1],actColor[2],actColor[3],actColor[4]*HOV*.2*(math.sin(timer()*6.26)*.25+.75))
    gc_rectangle('fill',x,y,w,h,self.cornerR)

    -- Frame
    gc_setColor(self.frameColor)
    gc_setLineWidth(self.lineWidth)
    gc_rectangle('line',x,y,w,h,self.cornerR)

    -- Drawable
    if self._text then
        gc_setColor(self.textColor)
        local x2,y2
        if self.labelPos=='left' then
            x2,y2=x-8,y+self.h*.5
        elseif self.labelPos=='right' then
            x2,y2=x+self.w+8,y+self.h*.5
        elseif self.labelPos=='top' then
            x2,y2=x+self.w*.5,y
        elseif self.labelPos=='bottom' then
            x2,y2=x+self.w*.5,y+self.h
        end
        alignDraw(self,self._text,x2,y2,nil,self.textScale)
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
            if self.sound_clear then
                SFX.play(self.sound_clear)
            end
        end
        self._value=t
        self:_cutTooLong()
    end
end


---@class Zenitha.Widget.textBox: Zenitha.Widget.base
---@field w number
---@field h number
---@field scrollBarColor Zenitha.ColorStr | Zenitha.Color
---@field sound_clear string | false
---@field _texts table
Widgets.textBox=setmetatable({
    type='textBox',
    w=100,h=40,

    fillColor={0,0,0,.3},
    scrollBarPos='left',
    scrollBarWidth=8,
    scrollBarDist=3,
    lineHeight=30,
    yOffset=-2,
    editable=true,
    sound_clear=false,

    _floatWheel=0,
    _texts=false,
    _scrollPos=0, -- Scroll-down-distance
    _scrollPos1=0,
    _sure=0, -- Sure-timer for clear history

    buildArgs={
        'name',
        'pos',
        'x','y','w','h',
        'lineWidth','cornerR',

        'fillColor','frameColor','textColor','activeColor',
        'fontSize','fontType',
        'scrollBarPos','scrollBarWidth','scrollBarColor','scrollBarDist',
        'lineHeight',
        'yOffset',
        'editable',
        'sound_clear','sound_hover',

        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.textBox:reset(init)
    Widgets.base.reset(self,init)
    assert(self.w and type(self.w)=='number',"[textBox].w need number")
    assert(self.h and type(self.h)=='number',"[textBox].h need number")
    assert(not self.sound_clear or type(self.sound_clear)=='string',"[textBox].sound_clear need string")

    assert(self.scrollBarPos=='left' or self.scrollBarPos=='right',"[textBox].scrollBarPos need 'left' or 'right'")
    assert(type(self.yOffset)=='number',"[textBox].yOffset need number")

    if not self._texts then self._texts={} end
    self._capacity=ceil(self.h/self.lineHeight)
    self._scrollPos1=-2*self.h
end
function Widgets.textBox:setTextList(newList)
    self._texts=newList
    self._scrollPos=0
end
function Widgets.textBox:setTexts(t)
    assert(type(t)=='table',"Arg need table")
    TABLE.clear(self._texts)
    TABLE.append(self._texts,t)
    self._scrollPos=0
end
function Widgets.textBox:push(t)
    ins(self._texts,t)
    if self._scrollPos==(#self._texts-1)*self.lineHeight-self.h then -- minus 1 for the new message
        self._scrollPos=min(self._scrollPos+self.lineHeight,#self._texts*self.lineHeight-self.h)
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
    if self.editable and x>self._x+self.w-40 and y<self._y+40 then
        if self._sure>0 then
            self:clear()
            self._sure=0
        else
            self._sure=1
        end
    end
end
function Widgets.textBox:drag(_,_,_,dy)
    self._scrollPos=clamp(
        self._scrollPos-dy,
        0,max(#self._texts*self.lineHeight-self.h,0)
    )
end
function Widgets.textBox:scroll(dx,dy)
    self._scrollPos=clamp(
        self._scrollPos-(dx+dy)*self.lineHeight,
        0,max(#self._texts*self.lineHeight-self.h,0)
    )
end
function Widgets.textBox:arrowKey(k)
    self:scroll(0,k=='up' and -1 or k=='down' and 1 or 0)
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
    local list=self._texts
    local lineH=self.lineHeight
    local H=#list*lineH
    local scroll=self._scrollPos1

    local frameC=WIDGET.sel==self and self.activeColor or self.frameColor

    -- Background
    gc_setColor(self.fillColor)
    gc_rectangle('fill',x,y,w,h,self.cornerR)

    -- Frame
    gc_setColor(frameC)
    local lw=self.lineWidth
    gc_setLineWidth(lw)
    gc_rectangle('line',x-lw*.5,y-lw*.5,w+lw,h+lw,self.cornerR)

    -- Texts
    gc_push('transform')
        gc_translate(x,y)

        -- Slider
        if #list>self._capacity then
            gc_setColor(self.scrollBarColor)
            local len=h*h/H
            if self.scrollBarPos=='left' then
                gc_rectangle('fill',-self.scrollBarWidth-self.scrollBarDist,(h-len)*scroll/(H-h),self.scrollBarWidth,len,self.cornerR)
            elseif self.scrollBarPos=='right' then
                gc_rectangle('fill',w+self.scrollBarDist,(h-len)*scroll/(H-h),self.scrollBarWidth,len,self.cornerR)
            end
        end

        gc_setColor(frameC)

        -- Clear button
        if self.editable then
            gc_rectangle('line',w-40,0,40,40,self.cornerR)
            if self._sure==0 then
                gc_rectangle('fill',w-40+16,5,8,3)
                gc_rectangle('fill',w-40+8,8,24,3)
                gc_rectangle('fill',w-40+11,14,18,21)
            else
                setFont(40,'_norm')
                gc_mStr("?",w-40+21,-8)
            end
        end

        -- Texts
        gc_setColor(self.textColor)
        setFont(self.fontSize,self.fontType)
        gc_stc_reset()
        gc_stc_rect(0,0,w,h)
        gc_translate(0,-(scroll%lineH))
        local pos=floor(scroll/lineH)
        for i=1,self._capacity+1 do
            i=pos+i
            if list[i] then
                gc_printf(list[i],10,self.yOffset,w-16)
            end
            gc_translate(0,lineH)
        end
        gc_stc_stop()
    gc_pop()
end


---@class Zenitha.Widget.listBox: Zenitha.Widget.base
---@field w number
---@field h number
---@field sound_click string | false
---@field sound_select string | false
---@field _list table List of items
Widgets.listBox=setmetatable({
    type='listBox',
    w=100,h=40,

    fillColor={0,0,0,.3},
    scrollBarPos='left',
    scrollBarWidth=8,
    scrollBarDist=3,
    lineHeight=30,
    drawFunc=false, -- function that draw items. Input: item,id,isSelect
    releaseDist=10,
    stencilMode='total',
    sound_click=false,
    sound_select=false,

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
        'lineWidth','cornerR',

        'fillColor','frameColor','activeColor',
        'scrollBarPos','scrollBarWidth','scrollBarColor','scrollBarDist',
        'lineHeight',
        'drawFunc',
        'releaseDist',
        'stencilMode',
        'sound_click','sound_select','sound_hover',
        'code',
        'visibleFunc',
        'visibleTick',
    },
},{__index=Widgets.base,__metatable=true})
function Widgets.listBox:reset(init)
    Widgets.base.reset(self,init)
    assert(not self.sound_click or type(self.sound_click)=='string',"[listBox].sound_click need string")
    assert(not self.sound_select or type(self.sound_select)=='string',"[listBox].sound_select need string")
    assert(self.w and type(self.w)=='number',"[listBox].w need number")
    assert(self.h and type(self.h)=='number',"[listBox].h need number")
    assert(self.scrollBarPos=='left' or self.scrollBarPos=='right',"[listBox].scrollBarPos need 'left' or 'right'")

    assert(type(self.drawFunc)=='function',"[listBox].drawFunc need function")
    assert(type(self.releaseDist)=='number' and self.releaseDist>=0,"[listBox].drawFunc need >=0")
    assert(self.stencilMode=='total' or self.stencilMode=='single' or self.stencilMode==false,"[listBox].stencilMode need 'total' or 'single' or false")
    if not self._list then self._list={} end
    self._capacity=ceil(self.h/self.lineHeight)
    self._scrollPos1=-2*self.h
end
function Widgets.listBox:clear()
    self._list={}
    self._scrollPos=0
end
function Widgets.listBox:setList(t)
    assert(type(t)=='table',"Arg need table")
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
    if self._list[1] then
        rem(self._list)
        self:drag(0,0,0,0)
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
                SFX.play(self.sound_select)
            else
                if self.code then
                    self:code(self:getSelect(),self:getItem())
                    SFX.play(self.sound_click)
                end
            end
        end
    end
end
function Widgets.listBox:_moveScroll(dy,selInSight)
    self._scrollPos=clamp(
        not selInSight and self._scrollPos+dy or
        clamp(self._scrollPos+dy,
            (self._selected+1)*self.lineHeight-self.h,
            (self._selected-2)*self.lineHeight
        ),
        0,max(#self._list*self.lineHeight-self.h,0)
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
    self._selected=clamp(i,1,#self._list)
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
        gc_setColor(self.fillColor)
        gc_rectangle('fill',0,0,w,h,self.cornerR)

        -- Frame
        gc_setColor(WIDGET.sel==self and self.activeColor or self.frameColor)
        local lw=self.lineWidth
        gc_setLineWidth(lw)
        gc_mRect('line',w*.5,h*.5,w+lw,h+lw,self.cornerR)

        -- Slider
        if h<H then
            local len=h*h/H
            gc_setColor(self.scrollBarColor)
            if self.scrollBarPos=='left' then
                gc_rectangle('fill',-self.scrollBarWidth-self.scrollBarDist,(h-len)*scroll/(H-h),self.scrollBarWidth,len,self.cornerR)
            elseif self.scrollBarPos=='right' then
                gc_rectangle('fill',w+self.scrollBarDist,(h-len)*scroll/(H-h),self.scrollBarWidth,len,self.cornerR)
            end
        end

        -- List
        local pos=floor(scroll/lineH)
        local cap=self._capacity
        local sel=self._selected
        ---@type function
        local drawFunc=self.drawFunc
        if self.stencilMode=='single' then
            local modH=scroll%lineH
            gc_translate(0,-modH)
            for i=1,cap+1 do
                gc_stc_reset()
                if i==1 then
                    gc_stc_rect(0,modH,w,lineH-modH)
                elseif i==cap+1 then
                    gc_stc_rect(0,0,w,modH)
                else
                    gc_stc_rect(0,0,w,lineH)
                end
                i=pos+i
                if list[i]~=nil then
                    drawFunc(list[i],i,i==sel)
                end
                gc_translate(0,lineH)
            end
        else
            if self.stencilMode then
                gc_stc_reset()
                gc_stc_rect(0,0,w,h)
            end
            gc_translate(0,-(scroll%lineH))
            for i=1,cap+1 do
                i=pos+i
                if list[i]~=nil then
                    drawFunc(list[i],i,i==sel)
                end
                gc_translate(0,lineH)
            end
        end
        gc_stc_stop()
    gc_pop()
end

--------------------------------------------------------------

-- Widget module
local WIDGET={_prototype=Widgets}

---@type Zenitha.Widget.base[]
WIDGET.active={} -- Table contains all active widgets

---@type Zenitha.Widget.base | false
WIDGET.sel=false -- Selected widget

---Reset all widgets (called by Zenitha when scene changed and window resized or something)
function WIDGET._reset()
    for i=1,#WIDGET.active do
        WIDGET.active[i]:reset()
    end
end

function WIDGET._setupWidgetListMeta(list)
    if getmetatable(list)~=indexMeta then
        setmetatable(list,indexMeta)
    end
end

---Set WIDGET.active to widget list (called by Zenitha when scene changed)
---@param list Zenitha.Widget.base[]
function WIDGET._setWidgetList(list)
    WIDGET.unFocus(true)
    WIDGET.active=list or NONE

    if list then
        local x,y=xOy:inverseTransformPoint(ZENITHA.mouse.getPosition())
        WIDGET._cursorMove(x,y,'init')
        WIDGET._reset()
    end
end

---Get selected widget
---@return Zenitha.Widget.base | false
function WIDGET.getSelected()
    return WIDGET.sel
end

---Check if widget W is focused, or check if any widget is focused if false or nil were given
---@param W? Zenitha.Widget.base | false
---@return boolean
function WIDGET.isFocus(W)
    if W then
        return W and WIDGET.sel==W
    else
        return WIDGET.sel~=false
    end
end

---Focus widget W
---@param W Zenitha.Widget.base
---@param reason? 'init' | 'press' | 'move' | 'release'
function WIDGET.focus(W,reason)
    if WIDGET.sel==W then return end
    if WIDGET.sel and WIDGET.sel.type=='inputBox' then
        kb.setTextInput(false)
        EDITING=''
    end
    if W and W._visible then
        if W.type=='inputBox' then
            if reason~='move' and reason~='init' then
                WIDGET.sel=W
                if not kb.hasTextInput() then
                    local _,y1=xOy:transformPoint(0,W.y+W.h)
                    kb.setTextInput(true,0,y1,1,1)
                end
            end
        else
            WIDGET.sel=W
        end
    end
    if WIDGET.sel==W and W.sound_hover then
        SFX.play(W.sound_hover)
    end
end

---Unfocus widget
---
---soft unfocus like moving mouse, won't unfocus some widget with `keepFocus` tag, like inputBox.
---@param force? boolean
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

---Update widget states with cursor move event (called by Zenitha)
---@param x number
---@param y number
---@param reason 'init' | 'press' | 'move' | 'release'
function WIDGET._cursorMove(x,y,reason)
    for _,W in next,WIDGET.active do
        if W._visible and W:isAbove(x,y+SCN.curScroll) then
            WIDGET.focus(W,reason)
            return
        end
    end
    if WIDGET.sel and not WIDGET.sel.keepFocus then
        WIDGET.unFocus()
    end
end

---Update widget states with press event (called by Zenitha)
---@param x number
---@param y number
---@param k number | lightuserdata | any
function WIDGET._press(x,y,k)
    WIDGET._cursorMove(x,y,'press')
    local W=WIDGET.sel
    if W then
        if not W:isAbove(x,y+SCN.curScroll) then
            WIDGET.unFocus(true)
        else
            W:press(x,y and y+SCN.curScroll,k)
            if W.sound_press then
                SFX.play(W.sound_press)
            end
            if not W._visible then WIDGET.unFocus() end
        end
    end
end

---Update widget states with release event (called by Zenitha)
---@param x number
---@param y number
---@param k number | lightuserdata | any
function WIDGET._release(x,y,k)
    if WIDGET.sel then
        WIDGET.sel:release(x,y+SCN.curScroll,k)
    end
end

---Update widget states with drag event (called by Zenitha)
---@param x number
---@param y number
---@param dx number
---@param dy number
function WIDGET._drag(x,y,dx,dy)
    local W=WIDGET.sel
    if W then
        W:drag(x,y+SCN.curScroll,dx,dy)
    else
        SCN.curScroll=clamp(SCN.curScroll-dy,0,SCN.maxScroll)
    end
end

---Update widget states with scroll event (called by Zenitha)
---@param dx number
---@param dy number
function WIDGET._scroll(dx,dy)
    local W=WIDGET.sel
    if W then
        W:scroll(dx,dy)
    else
        SCN.curScroll=clamp(SCN.curScroll-dy*SCR.h0/6.26,0,SCN.maxScroll)
    end
end

---Update widget states with drag event (called by Zenitha)
---@param texts string
function WIDGET._textinput(texts)
    ---@type Zenitha.Widget.inputBox
    local W=WIDGET.sel
    if W and W.type=='inputBox' then
        if not W.regex or texts:match(W.regex) then
            W._value=W._value..texts
            W:_cutTooLong()
            SFX.play(W.sound_input)
        else
            SFX.play(W.sound_fail)
        end
    end
end

---Update all widgets (called by Zenitha)
---@param dt number
function WIDGET._update(dt)
    for _,W in next,WIDGET.active do
        if W.visibleTick then
            local v=W.visibleTick()
            if W._visible~=v then
                W._visible=v
                if v then
                    if W:isAbove(xOy:inverseTransformPoint(ZENITHA.mouse.getPosition())) then
                        WIDGET.focus(W,'move')
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

---Draw all widgets (called by Zenitha)
function WIDGET._draw()
    for _,W in next,WIDGET.active do
        if W._visible then W:draw() end
    end
end

---Draw widgets
---@param widgetList Zenitha.Widget.base[]
---@param scroll? number
function WIDGET.draw(widgetList,scroll)
    if scroll then gc_translate(0,-scroll) end
    for _,W in next,widgetList do
        if W._visible then W:draw() end
    end
end

---Create new widget
---@param args Zenitha.WidgetArg Arguments to create widget, check declare widget class for more info
---@return Zenitha.Widget.base
function WIDGET.new(args)
    local t=args.type
    args.type=nil

    local W=Widgets[t]
    assert(W,("Widget type '%s' does not exist"):format(t))
    local w=setmetatable({},{__index=W,__metatable=true})

    for k,v in next,args do
        if TABLE.find(W.buildArgs,k) then
            w[k]=v
        else
            errorf("WIDGET.new(args): Illegal argument %s for widget %s",k,t)
        end
    end
    w:reset(true)

    return w
end

---Adjust default widget option
---@param opt Map<Zenitha._WidgetArg> | any
function WIDGET.setDefaultOption(opt)
    for t,data in next,opt do
        assertf(Widgets[t],"Widget type '%s' does not exist",t)
        for k,v in next,data do
            assertf(Widgets[t][k]~=nil,"Widget type '%s' doesn't have option %s",t,k)
            Widgets[t][k]=v
        end
    end
end

--------------------------------------------------------------
-- User funcs

-- Widget function shortcuts
local c_cache={}

---Widget shortcut function of `SCN.back()`
---@param style? string
---@return function
function WIDGET.c_backScn(style)
    local hash='c_backScn/'..tostring(style)
    if not c_cache[hash] then
        c_cache[hash]=function() SCN.back(style) end
    end
    return c_cache[hash]
end

---Widget shortcut function of `SCN.go()`
---@param name string
---@param style? string
---@return function
function WIDGET.c_goScn(name,style)
    local hash='c_goScn/'..(style and name..','..style or name)
    if not c_cache[hash] then
        c_cache[hash]=function() SCN.go(name,style) end
    end
    return c_cache[hash]
end

---Widget shortcut function of `SCN.swapTo()`
---@param name string
---@param style? string
---@return function
function WIDGET.c_swapScn(name,style)
    local hash='c_swapScn/'..(style and name..','..style or name)
    if not c_cache[hash] then
        c_cache[hash]=function() SCN.swapTo(name,style) end
    end
    return c_cache[hash]
end

---Widget shortcut function of `SCN.swapTo()`
---@param key string
---@return function
function WIDGET.c_pressKey(key)
    local hash='c_pressKey/'..key
    if not c_cache[hash] then
        c_cache[hash]=function() love.keypressed(key) end
    end
    return c_cache[hash]
end

--------------------------------------------------------------

---Create & Get custom new widget class (not guaranteed to work)
---@param name string
---@param parent string
---@return Zenitha.Widget.base
function WIDGET.newClass(name,parent)
    if not parent then parent='base' end
    assertf(type(name)=='string',"Widget name need string")
    assertf(type(parent)=='string',"Widget name need string")
    assertf(not Widgets[name],"Widget class %s already exists",name)
    assertf(Widgets[parent],"Parent widget class %s does not exist",parent)
    Widgets[name]=setmetatable({type=name},{__index=Widgets[parent],__metatable=true})
    return Widgets[name]
end

WIDGET._alignDraw=alignDraw
WIDGET._alignDrawQ=alignDrawQ

return WIDGET
