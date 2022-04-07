local gc_clear=love.graphics.clear
local BGs={}-- Stored backgrounds
local BG={
    default='none',
    locked=false,
    cur=false,
    init=NULL,
    resize=NULL,
    update=NULL,
    draw=NULL,
    event=NULL,
    discard=NULL,
}

function BG.lock() BG.locked=true end
function BG.unlock() BG.locked=false end
function BG.add(name,bg)
    BGs[name]=bg
end
function BG.send(name,...)
    if BGs[name] then
        BGs[name].event(...)
    else
        MES.new('warning',"No background named '"..name.."' to send data to")
    end
end
function BG.setDefault(bg)
    BG.default=bg
end
function BG.set(name)
    name=name or BG.default
    if BG.locked then return end
    if not BGs[name] then
        MES.new('warning',"No background named '"..name.."' to set")
        return
    end
    if name~=BG.cur then
        BG.discard()
        BG.cur=name
        local bg=BGs[name]

        BG.init=   bg.init or NULL
        BG.resize= bg.resize or NULL
        BG.update= bg.update or NULL
        BG.draw=   bg.draw or NULL
        BG.event=  bg.event or NULL
        BG.discard=bg.discard or NULL
        BG.init()
    end
    return true
end

do-- Built-in: None
    BG.add('none',{
        draw=function()
            gc_clear(.08,.08,.084)
        end,
    })
end
do-- Built-in: Color
    local r,g,b=.26,.26,.26
    BG.add('color',{
        draw=function()
            gc_clear(r,g,b)
        end,
        event=function(_r,_g,_b)
            r,g,b=_r,_g,_b
        end,
    })
end
do-- Built-in: Image
    local gc_setColor=love.graphics.setColor
    local back={}
    local image=false
    local alpha=.26
    local mx,my,k
    function back.init()
        back.resize()
    end
    function back.resize()
        mx,my=SCR.w*.5,SCR.h*.5
        if image then
            k=math.max(SCR.w/image:getWidth(),SCR.h/image:getHeight())
        end
    end
    function back.draw()
        gc_clear(.1,.1,.1)
        if image then
            gc_setColor(1,1,1,alpha)
            GC.draw(image,mx,my,nil,k)
        end
    end
    function back.event(a,img)
        if a then alpha=a end
        if img then image=img end
        back.resize()
    end

    BG.add('image',back)
end

BG.set('none')

return BG
