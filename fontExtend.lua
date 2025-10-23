if not (love.graphics and love.font) then
    LOG("FONT lib is not loaded (need love.graphics & love.font)")
    return setmetatable({},{
        __index=function(t,k)
            t[k]=NULL
            return t[k]
        end,
    })
end

local set=love.graphics.setFont

---@type fun(font:love.Font, size:number, name?:string)
local onLoadFunc=NULL

---@type love.File[], Mat<love.Font>
local fontFiles,fontCache={},{_={}}

---@type string?, string
local defaultFont

---@type love.Font
local curFont=nil -- Current using font object

local FONT={_cache=fontCache}

---Set default font type
---@param name? string
function FONT.setDefaultFont(name)
    defaultFont=name
end

---Set a function (nil to disable) to be called just after a new font object is created
---
---Useful for setting font filters, lineHeight, etc.
---@param func? fun(font:love.Font, size:number, name?:string)
function FONT.setOnInit(func)
    if func==nil then
        onLoadFunc=NULL
    else
        assertf(type(func)=='function' or func==nil,"Need function or nil, got %s",type(func))
        onLoadFunc=func
    end
end

---Get love's default font object
---@param size number
---@return love.Font
local function _rawget(size)
    local f=fontCache._[size]
    if not f then
        assertf(type(size)=='number' and size>0 and size%1==0,"Need int >=1, got %s",size)
        f=love.graphics.newFont(size,'normal',love.graphics.getDPIScale()*SCR.k*2)
        fontCache._[size]=f
        onLoadFunc(f, size)
    end
    return f
end
FONT.rawget=_rawget

---Set love's default font
---@param size number
function FONT.rawset(size)
    set(fontCache._[size] or _rawget(size))
end

---Get font object with font size, use default font name if not given
---
---**Warning:** any numbers not appeared before will cause a new font object to be created, so don't call this with too many different font sizes
---@param size number
---@param name? string
---@return love.Font
local function _get(size,name)
    if not name then name=defaultFont end

    local f=fontCache[name]
    if not f then return _rawget(size) end
    f=f[size]

    if not f then
        assertf(type(size)=='number' and size>0 and size%1==0,"Need int >=1, got %s",size)
        f=love.graphics.newFont(fontFiles[name],size,'normal',love.graphics.getDPIScale()*SCR.k*2)
        fontCache[name][size]=f
        onLoadFunc(f, size, name)
    end
    return f
end
FONT.get=_get

---Set font with font size, use default font name if not given
---
---**Warning:** any numbers not appeared before will cause a new font object to be created, so don't call this with too many different font sizes
---@param size number
---@param name? string
function FONT.set(size,name)
    if not name then name=defaultFont end

    local f=_get(size,name)
    if f~=curFont then
        curFont=f
        set(curFont)
    end
end

---Load font(s) from file(s)
---@param name string | string[] | any
---@param path string
---@overload fun(map:table<string, string>)
function FONT.load(name,path)
    if type(name)=='table' then
        for k,v in next,name do
            FONT.load(k,v)
        end
    else
        assertf(love.filesystem.getInfo(path),"Font file %s(%s) not exist!",name,path)
        fontFiles[name]=love.filesystem.newFile(path)
        fontCache[name]={}
    end
end

return FONT
