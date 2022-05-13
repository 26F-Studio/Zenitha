local gc=love.graphics
local setColor=gc.setColor

local floor,rnd=math.floor,math.random
local max,min=math.max,math.min
local ins,rem=table.insert,table.remove
local draw=gc.draw

local textFX={}
function textFX.appear(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        nil,nil,
        T._ox,T._oy
    )
end
function textFX.fly(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x+(T._t-.5)^3*300,T.y,
        nil,
        nil,nil,
        T._ox,T._oy
    )
end
function textFX.stretch(T)-- stretchK
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        max(1-T._t/T.inPoint,0)*(T.stretchK or 1)+1 or 1,1,
        T._ox,T._oy
    )
end
function textFX.drive(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        nil,nil,
        T._ox,T._oy,
        (max(1-T._t/T.inPoint,0)*(T.driveX or 2)) or 0,0
    )
end
function textFX.spin(T)-- spinA
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        (max(1-T._t/T.inPoint,0)^2-max(1-(1-T._t)/T.outPoint,0)^2)*(T.spinA or .4),
        nil,nil,
        T._ox,T._oy
    )
end
function textFX.flicker(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1)*rnd())
    draw(
        T.text,T.x,T.y,
        nil,
        nil,nil,
        T._ox,T._oy
    )
end
function textFX.zoomout(T)
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        T._t^.5*.1+1,nil,
        T._ox,T._oy
    )
end
function textFX.beat(T)-- exSize
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y,
        nil,
        1+(T.exSize or .5)*max(1-T._t/T.inPoint,0)^.6,nil,
        T._ox,T._oy
    )
end
function textFX.score(T)-- popH
    setColor(T.r,T.g,T.b,T.a*min(T._t/T.inPoint,1)*min((1-T._t)/T.outPoint,1))
    draw(
        T.text,T.x,T.y-0-T._t^.2*T.popH,
        nil,
        nil,nil,
        T._ox,T._oy
    )
end

local TEXT={_texts={}}
function TEXT:clear()
    self._texts={}
end

--[[ data:
    text="Example Text",
    x=0,y=0,
    r=1,g=1,b=1,a=1,
    fontSize=40,
    fontType=nil,
    duration=1,
    inPoint=0.2,
    outPoint=0.2,

    style='appear',
    _sytleArgs=...
]]
function TEXT:add(data)
    local T={
        _t=0,-- Timer
        text=gc.newText(FONT.get(floor((data.fontSize or 40)/5)*5,data.fontType),data.text or "Example Text"),
        x=data.x or 0,y=data.y or 0,
        r=data.r,g=data.g,b=data.b,a=data.a,
        duration=data.duration or 1,
        inPoint=data.inPoint or 0.2,
        outPoint=data.outPoint or 0.2,

        draw=assert(textFX[data.style or 'appear'],"No text type:"..tostring(data.style)),
        stretchK=   data.stretchK,
        spinA=      data.spinA,
        exSize=     data.exSize,
        popH=       data.popH,
    }
    T._ox,T._oy=T.text:getWidth()*.5,T.text:getHeight()*.5
    if type(data.color)=='string' then data.color=COLOR[data.color] end
    if data.color then T.r=data.color[1] T.g=data.color[2] T.b=data.color[3] T.a=data.color[4] end
    if not T.r then T.r=T.r or 1 end
    if not T.g then T.g=T.g or 1 end
    if not T.b then T.b=T.b or 1 end
    if not T.a then T.a=T.a or 1 end
    ins(self._texts,T)
end
function TEXT:update(dt)
    local list=self._texts
    for i=#list,1,-1 do
        local T=list[i]
        T._t=T._t+dt/T.duration
        if T._t>1 then
            rem(list,i)
        end
    end
end
function TEXT:draw()
    local list=self._texts
    for i=1,#list do list[i]:draw() end
end
function TEXT.new()-- Create new text container
    return setmetatable({_texts={}},{__index=TEXT})
end
return TEXT
