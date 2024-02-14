local mesIcon={
    info=GC.load{40,40,
        {'setCL',1,1,1},
        {'setLW',2},
        {'dCirc',20,20,19},
        {'fRect',17,7,6,6},
        {'fRect',17,16,6,17},
    },
    check=GC.load{40,40,
        {'setLW',6},
        {'setCL',1,1,1},
        {'line',5,20,15,30,35,10},
    },
    warn=GC.load{40,40,
        {'setCL',1,1,1},
        {'setLW',3},
        {'dPoly',20.5,1,0,38,40,38},
        {'setCL',1,1,1},
        {'fRect',18,11,5,16,2},
        {'fRect',18,30,5,5,2},
    },
    error=GC.load{40,40,
        {'setLW',6},
        {'setCL',1,1,1},
        {'line',8,8,32,32},
        {'line',8,32,31,8},
    },
}

local mesList={}
local startY=0

local MSG={}
local backColors={
    info= {COLOR.hex"3575F0"},
    check={COLOR.hex"4FB666"},
    warn= {COLOR.hex"D2A100"},
    error={COLOR.hex"CF4949"},
    other={COLOR.hex"787878"},
}

---Create a new message popup at up-left corner
---@param icon string|love.Canvas
---@param str string
---@param time? number
function MSG.new(icon,str,time)
    local color=backColors.other
    if type(icon)=='string' then
        color=TABLE.shift(backColors[icon] or color)
        icon=mesIcon[icon]
    end
    local text=GC.newText(FONT.get(30),str)
    local w=math.max(text:getWidth()+(icon and 45 or 5),200)+15
    local h=math.max(text:getHeight()+2,50)
    local k=h>400 and 1/math.min(h/400,2.6) or 1

    table.insert(mesList,1,{
        startTime=.26,
        endTime=.26,
        time=time or 3,

        color=color,
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
    TABLE.cut(mesList)
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

            GC.setColor(m.color[1]*1.26,m.color[2]*1.26,m.color[3]*1.26,a*.042)
            GC.setLineWidth(15)GC.rectangle('line',0,0,m.w,m.h,8)
            GC.setLineWidth(10)GC.rectangle('line',0,0,m.w,m.h,8)
            GC.setLineWidth(6) GC.rectangle('line',0,0,m.w,m.h,8)
            GC.setColor(m.color[1],m.color[2],m.color[3],a)
            GC.rectangle('fill',0,0,m.w,m.h,8)
            GC.setColor(1,1,1,a)
            local x=10
            if m.icon then
                GC.mDraw(m.icon,24,24,nil,.8)
                x=x+40
            end
            GC.draw(m.text,x,6)
            GC.pop()
        end
        GC.translate(0,-startY)
    end
end

return MSG
