if not love.graphics then
    LOG("MSG lib is not loaded (need love.graphics)")
    return setmetatable({},{
        __index=function(t,k)
            t[k]=NULL
            return t[k]
        end,
    })
end

---@class Zenitha.MessageData
---@field [1]? Zenitha.MessageType | love.Canvas
---@field [2]? string | table
---@field cat? Zenitha.MessageType | love.Canvas
---@field str? string | table
---@field time? number
---@field last? true message will appear at the bottom, not top
---@field alpha? number [0,1]

---@alias Zenitha.MessageType Zenitha._MessageType | string
---@enum (key) Zenitha._MessageType
local msgStyle={
    info={
        backColor={COLOR.HEX"3575F0"},
        textColor={COLOR.HEX"FFFFFF"},
        canvas=GC.load{w=40,
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
        canvas=GC.load{w=40,
            {'setLW',6},
            {'setCL',1,1,1},
            {'line',5,20,15,30,35,10},
        },
    },
    warn={
        backColor={COLOR.HEX"D2A100"},
        textColor={COLOR.HEX"FFFFFF"},
        canvas=GC.load{w=40,
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
        canvas=GC.load{w=40,
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

---@type Zenitha.MessageObject[]
local mesList={}
local startY=0

---Directly call `MSG` to create a popup at up-left corner, default to last 3s
---@class Zenitha.Message
local MSG=setmetatable({},{
    __call=function(_,cat,str,time)
        if type(cat)=='table' then
            MSG._new(cat)
        else
            MSG._new{cat=cat,str=str,time=time}
        end
    end,
    __metatable=true,
})
---@cast MSG +fun(type:Zenitha.MessageType | love.Canvas, str:string | table, time?:number)
---@cast MSG +fun(msg:Zenitha.MessageData)

---Add a new icon (and color) for message popup
---@param name string
---@param backColor Zenitha.Color
---@param canvas? love.Canvas | love.Texture
function MSG.addCategory(name,backColor,textColor,canvas)
    assert(type(name)=='string',"MSG.addType: name need string")
    assert(type(backColor)=='table' and #backColor>=3,"MSG.addType: color need {r,g,b}")
    assert(type(textColor)=='table' and #textColor>=3,"MSG.addType: color need {r,g,b}")
    msgStyle[name]={backColor=backColor,textColor=textColor,canvas=canvas}
end

---@param data Zenitha.MessageData
function MSG._new(data)
    local backColor,textColor
    if not data.cat then data.cat=data[1] end
    if not data.str then data.str=data[2] end
    if type(data.cat)=='string' then
        backColor=msgStyle[data.cat].backColor or msgStyle.other.backColor
        textColor=msgStyle[data.cat].textColor or msgStyle.other.textColor
        data.cat=msgStyle[data.cat].canvas
    else
        backColor=msgStyle.other.backColor
        textColor=msgStyle.other.textColor
    end
    local text=GC.newText(FONT.get(30),data.str)
    local w,h=text:getDimensions()
    w=math.max(w+(data.cat and 45 or 5),200)+15
    h=math.max(h+12,50)
    local k=1/math.min(math.max(w/(SCR.w0-6), h/400, 1), 2.6)

    ---@class Zenitha.MessageObject
    local obj={
        startTime=.26,
        endTime=.26,
        time=data.time or 3,

        backColor=backColor,
        textColor=textColor,
        alpha=data.alpha or .9,
        text=text,icon=data.cat,
        iconK=data.cat and 32/math.max(data.cat:getDimensions()),
        w=w,h=h,k=k,
        y=-h,
    }
    table.insert(mesList,data.last and #mesList+1 or 1,obj)
end
local _new=MSG._new

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
    _new({cat='error',str=msg:sub(
        msg:find("\n",2)+1,
        msg:find("\n%[C%], in 'xpcall'")
    ),time=5})
end

---Clear all messages
function MSG.clear()
    TABLE.clear(mesList)
end

---Log an info message both in console and with popup, with non ASCII filter
---@param category 'info' | 'warn' | 'error'
---@param info string
---@param time? number
function MSG.log(category,info,time)
    LOG(category,info)
    _new{category,STRING.filterASCII(info),time=time or (category=='warn' and 6 or category=='error' and 10 or 4.2)}
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
            table.remove(mesList,i).text:release()
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

local gc=love.graphics
local gc_push,gc_pop=gc.push,gc.pop
local gc_translate,gc_scale=gc.translate,gc.scale
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_draw,gc_rectangle=gc.draw,gc.rectangle
local gc_mDraw=GC.mDraw

---Draw all messages (called by Zenitha)
function MSG._draw()
    if mesList[1] then
        gc_translate(0,startY)
        gc_setLineWidth(2)
        for i=1,#mesList do
            local m=mesList[i]
            local a=(1/0.26)*(m.endTime-m.startTime)*m.alpha
            gc_push('transform')
            gc_translate(3+SCR.safeX,m.y)
            gc_scale(m.k)

            local c=m.backColor
            gc_setColor(c[1]*1.26,c[2]*1.26,c[3]*1.26,a*.042)
            gc_setLineWidth(15) gc_rectangle('line',0,0,m.w,m.h,8)
            gc_setLineWidth(10) gc_rectangle('line',0,0,m.w,m.h,8)
            gc_setLineWidth(6)  gc_rectangle('line',0,0,m.w,m.h,8)
            gc_setColor(c[1],c[2],c[3],a)
            gc_rectangle('fill',0,0,m.w,m.h,8)
            gc_setColor(1,1,1,a)
            local x=10
            if m.icon then
                gc_mDraw(m.icon,24,24,nil,m.iconK)
                x=x+40
            end

            local tc=m.textColor
            gc_setColor(tc[1],tc[2],tc[3],a)
            gc_draw(m.text,x,6)
            gc_pop()
        end
        gc_translate(0,-startY)
    end
end

return MSG
