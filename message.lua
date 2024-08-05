---@alias Zenitha.MessageType Zenitha._MessageType|string
---@enum (key) Zenitha._MessageType
local msgStyle={
    info={
        backColor={COLOR.HEX"3575F0"},
        textColor={COLOR.HEX"FFFFFF"},
        canvas=GC.load{w=40,h=40,
            {'setCL',1,1,1},
            {'setLW',2},
            {'dCirc',20,20,19},
            {'fRect',17,7,6,6},
            {'fRect',17,16,6,17},
        },
    },
    check={
        backColor={COLOR.HEX"4FB666"},
        textColor={COLOR.HEX"FFFFFF"},
        canvas=GC.load{w=40,h=40,
            {'setLW',6},
            {'setCL',1,1,1},
            {'line',5,20,15,30,35,10},
        },
    },
    warn={
        backColor={COLOR.HEX"D2A100"},
        textColor={COLOR.HEX"FFFFFF"},
        canvas=GC.load{w=40,h=40,
            {'setCL',1,1,1},
            {'setLW',3},
            {'dPoly',20.5,1,0,38,40,38},
            {'setCL',1,1,1},
            {'fRect',18,11,5,16,2},
            {'fRect',18,30,5,5,2},
        },
    },
    error={
        backColor={COLOR.HEX"CF4949"},
        textColor={COLOR.HEX"FFFFFF"},
        canvas=GC.load{w=40,h=40,
            {'setLW',6},
            {'setCL',1,1,1},
            {'line',8,8,32,32},
            {'line',8,32,31,8},
        },
    },
    other={
        backColor={COLOR.HEX"787878"},
        textColor={COLOR.HEX"FFFFFF"},
    },
}

local mesList={}
local startY=0

local MSG={}

---Add a new icon (and color) for message popup
---@param name string
---@param backColor Zenitha.Color
---@param canvas? love.Canvas
function MSG.addCategory(name,backColor,textColor,canvas)
    assert(type(name)=='string',"MSG.addType: name need string")
    assert(type(backColor)=='table' and #backColor>=3,"MSG.addType: color need {r,g,b}")
    assert(type(textColor)=='table' and #textColor>=3,"MSG.addType: color need {r,g,b}")
    msgStyle[name]={backColor=backColor,textColor=textColor,canvas=canvas}
end

---Create a new message popup at up-left corner
---@param icon Zenitha.MessageType|love.Canvas
---@param str string
---@param time? number
function MSG.new(icon,str,time)
    local backColor=msgStyle.other.backColor
    local textColor=msgStyle.other.textColor
    if type(icon)=='string' then
        backColor=msgStyle[icon].backColor or backColor
        textColor=msgStyle[icon].textColor or textColor
        icon=msgStyle[icon].canvas
    end
    local text=GC.newText(FONT.get(30),str)
    local w=math.max(text:getWidth()+(icon and 45 or 5),200)+15
    local h=math.max(text:getHeight()+2,50)
    local k=h>400 and 1/math.min(h/400,2.6) or 1

    table.insert(mesList,1,{
        startTime=.26,
        endTime=.26,
        time=time or 3,

        backColor=backColor,
        textColor=textColor,
        text=text,icon=icon,
        w=w,h=h,k=k,
        y=-h,
    })
end

---Set the y position of message popup
---@param y number
function MSG.setSafeY(y)
    assert(type(y)=='number' and y>=0,"MSG.setSafeY(y): Need >=0")
    startY=y
end

---Show a traceback message
function MSG.traceback()
    local msg=
        debug.traceback('',1)
        :gsub(': in function',', in')
        :gsub(':',' ')
        :gsub('\t','')
    MSG.new('error',msg:sub(
        msg:find("\n",2)+1,
        msg:find("\n%[C%], in 'xpcall'")
    ),5)
end

---Clear all messages
function MSG.clear()
    TABLE.clear(mesList)
end

---Update all messages (called by Zenitha)
---@param dt number
function MSG._update(dt)
    for i=#mesList,1,-1 do
        local m=mesList[i]
        if m.startTime>0 then
            m.startTime=math.max(m.startTime-dt,0)
        elseif m.time>0 then
            m.time=math.max(m.time-dt,0)
        elseif m.endTime>0 then
            m.endTime=m.endTime-dt
        else
            table.remove(mesList,i)
        end
        if i>1 then
            local _m=mesList[i-1]
            local ty=_m.y+_m.h*_m.k
            m.y=MATH.expApproach(m.y,ty+3,dt*26)
        else
            m.y=MATH.expApproach(m.y,3,dt*26)
        end
    end
end

---Draw all messages (called by Zenitha)
function MSG._draw()
    if #mesList>0 then
        GC.translate(0,startY)
        GC.setLineWidth(2)
        for i=1,#mesList do
            local m=mesList[i]
            local a=3.846*(m.endTime-m.startTime)
            GC.push('transform')
            GC.translate(3+SCR.safeX,m.y)
            GC.scale(m.k)

            local c=m.backColor
            GC.setColor(c[1]*1.26,c[2]*1.26,c[3]*1.26,a*.042)
            GC.setLineWidth(15) GC.rectangle('line',0,0,m.w,m.h,8)
            GC.setLineWidth(10) GC.rectangle('line',0,0,m.w,m.h,8)
            GC.setLineWidth(6)  GC.rectangle('line',0,0,m.w,m.h,8)
            GC.setColor(c[1],c[2],c[3],a)
            GC.rectangle('fill',0,0,m.w,m.h,8)
            GC.setColor(1,1,1,a)
            local x=10
            if m.icon then
                GC.mDraw(m.icon,24,24,nil,.8)
                x=x+40
            end

            local tc=m.textColor
            GC.setColor(tc[1],tc[2],tc[3],a)
            GC.draw(m.text,x,6)
            GC.pop()
        end
        GC.translate(0,-startY)
    end
end

return MSG
