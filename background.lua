if not love.graphics then
    LOG("BG lib is not loaded (need love.graphics)")
    return setmetatable({},{
        __index=function(t,k)
            t[k]=NULL
            return t[k]
        end
    })
end

---@class Zenitha.Background
---@field init function
---@field resize function
---@field update function
---@field draw function
---@field event function
---@field discard function

local gc_clear=love.graphics.clear

---@type Zenitha.Background[]
local BGs={} -- Stored backgrounds

local BG={
    default='none',
    locked=false,
    cur='none',
}

local fields={'init','resize','update','draw','event','discard'}

---Lock the background, forbid changing with `BG.set()` until call `BG.unlock()`
function BG.lock() BG.locked=true end

---Unlock the background, allow changing with `BG.set()`
function BG.unlock() BG.locked=false end

---Add a background
---@param name string
---@param bg {init:function, resize:function, update:function, draw:function, event:function, discard:function}
function BG.add(name,bg)
    assertf(type(name)=='string',"BG.add(name,bg): name need string")
    assertf(not BGs[name],"BG.add(name,bg): name '%s' already exists",name)
    assertf(type(bg)=='table',"BG.add(name,bg): bg need table")
    for i=1,#fields do
        if bg[fields[i]]==nil then bg[fields[i]]=NULL end
        assertf(type(bg[fields[i]])=='function',"BG.add(name,bg): BG.%s need function",fields[i])
    end
    BGs[name]=bg
end

---Send data to a background (trigger its 'event' function)
---@param name? string
---@param ... any Arguments passed to background's 'event' function
function BG.send(name,...)
    if BGs[name] then
        BGs[name].event(...)
    else
        MSG.log('warn',"No background named '"..name.."' to send data to")
    end
end

---Set the default background, used when `BG.set()` is called without argument
---@param name string
function BG.setDefault(name)
    BG.default=name
end

---Set a addeed background (when not locked), use default background if name not given
---@param name? string
function BG.set(name)
    name=name or BG.default
    if BG.locked then return end
    if not BGs[name] then
        MSG.log('warn',"No background named '"..name.."' to set")
        return
    end
    if name~=BG.cur then
        BGs[BG.cur].discard()
        BG.cur=name
        BGs[BG.cur].init()
    end
    return true
end

---Get the current background name
---@return string | false
function BG.get() return BG.cur end

---Trigger when resize
---@param w number
---@param h number
function BG._resize(w,h) BGs[BG.cur].resize(w,h) end

---Update current BG (called by Zenitha)
---@param dt number
function BG._update(dt) BGs[BG.cur].update(dt) end

---Draw current BG (called by Zenitha)
function BG._draw() BGs[BG.cur].draw() end

do -- Built-in: None
    BG.add('none',{
        draw=function()
            gc_clear(.08,.08,.084)
        end,
    })
end
do -- Built-in: Color
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
do -- Built-in: Image
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
            GC.mDraw(image,mx,my,nil,k)
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
