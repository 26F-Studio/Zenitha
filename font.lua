local set=love.graphics.setFont

---@type love.File[], Mat<love.Font>
local fontFiles,fontCache={},{}

---@type string, string
local defaultFont,defaultFallBack

---@type table<string, string>
local fallbackMap={}

---@type table<string, {[1]:string,[2]:string}>
local filterMap={}

---@type love.Font
local curFont=nil -- Current using font object

local FONT={}

---Set default font type
---@param name string
function FONT.setDefaultFont(name)
    defaultFont=name
end

---Set default fallback font type
---@param name string
function FONT.setDefaultFallback(name)
    defaultFallBack=name
end

---Set fallback font for an exist font
---@param font string
---@param fallback string
function FONT.setFallback(font,fallback)
    fallbackMap[font]=fallback
end

function FONT.setFilter(font,min,mag)
    filterMap[font]={min,mag}
end

---Get love's default font object
---@param size number
---@return love.Font
local function _rawget(size)
    if not fontCache[size] then
        assertf(type(size)=='number' and size>0 and size%1==0,"Need int >=1, got %s",size)
        fontCache[size]=love.graphics.setNewFont(size,'normal',love.graphics.getDPIScale()*SCR.k*2)
    end
    return fontCache[size]
end
FONT.rawget=_rawget

---Set love's default font
---@param size number
local function _rawset(size)
    set(fontCache[size] or _rawget(size))
end
FONT.rawset=_rawset

---Load font(s) from file(s)
---@param name string|string[]|any
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

---Get font object with font size, use default font name if not given
---
---Warning: any numbers not appeared before will cause a new font object to be created, so don't call this with too many different font sizes
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
        if filterMap[name] then
            f:setFilter(filterMap[name][1],filterMap[name][2])
        end
        local fallbackName=fallbackMap[name] or defaultFallBack and name~=defaultFallBack and defaultFallBack
        if fallbackName then
            f:setFallbacks(_get(size,fallbackName))
        end
        fontCache[name][size]=f
    end
    return f
end
FONT.get=_get

---Set font with font size, use default font name if not given
---
---Warning: any numbers not appeared before will cause a new font object to be created, so don't call this with too many different font sizes
---@param size number
---@param name? string
local function _set(size,name)
    if not name then name=defaultFont end

    local f=_get(size,name)
    if f~=curFont then
        curFont=f
        set(curFont)
    end
end
FONT.set=_set

return FONT
