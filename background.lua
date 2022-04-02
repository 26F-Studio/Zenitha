local gc_clear=love.graphics.clear
local BGs={
    none={draw=function() gc_clear(.08,.08,.084) end}
}
local BG={
    default='none',
    locked=false,
    cur='none',
    init=false,
    resize=false,
    update=NULL,
    draw=BGs.none.draw,
    event=false,
    discard=NULL,
}

function BG.lock() BG.locked=true end
function BG.unlock() BG.locked=false end
function BG.add(name,bg)
    BGs[name]=bg
end
function BG.send(...)
    if BG.event then
        BG.event(...)
    end
end
function BG.setDefault(bg)
    BG.default=bg
end
function BG.set(name)
    name=name or BG.default
    if not BGs[name] or BG.locked then return end
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

do
    local gc=love.graphics
    local r,g,b=.26,.26,.26
    BG.add('color',{
        draw=function()
            gc.clear(r,g,b)
        end,
        event=function(_r,_g,_b)
            r,g,b=_r,_g,_b
        end,
    })
end
do
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

return BG
