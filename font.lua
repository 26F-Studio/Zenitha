local set=love.graphics.setFont

--- @type love.File[], love.Font[][]
local fontFiles,fontCache={},{}

--- @type string, string
local defaultFont,defaultFallBack

--- @type table<string, string>
local fallbackMap={}

--- @type love.Font
local curFont=nil-- Current using font object

local FONT={}

--- Set default font type
--- @param name string
function FONT.setDefaultFont(name)
    defaultFont=name
end

--- Set default fallback font type
--- @param name string
function FONT.setDefaultFallback(name)
    defaultFallBack=name
end

--- Set fallback font for an exist font
--- @param font string
--- @param fallback string
function FONT.setFallback(font,fallback)
    fallbackMap[font]=fallback
end


--- Get love's default font object
--- @param size number
--- @return love.Font
function FONT.rawget(size)
    if not fontCache[size] then
        assert(type(size)=='number' and size>0 and size%1==0,"Font size should be a positive integer, not "..tostring(size))
        fontCache[size]=love.graphics.setNewFont(size,'normal',love.graphics.getDPIScale()*SCR.k*2)
    end
    return fontCache[size]
end

--- Set love's default font
--- @param size number
function FONT.rawset(size)
    set(fontCache[size] or FONT.rawget(size))
end

--- Load font(s) from file(s)
--- @param name string|string[]|any
--- @param path string
--- @overload fun(map:table<string, string>)
function FONT.load(name,path)
    if type(name)=='table' then
        for k,v in next,name do
            FONT.load(k,v)
        end
    else
        assert(love.filesystem.getInfo(path),STRING.repD("Font file $1($2) not exist!",name,path))
        fontFiles[name]=love.filesystem.newFile(path)
        fontCache[name]={}
    end
end

--- Get font object with font size, use default font name if not given
---
--- Warning: any numbers not appeared before will cause a new font object to be created, so don't call this with too many different font sizes
--- @param size number
--- @param name? string
--- @return love.Font
function FONT.get(size,name)
    if not name then name=defaultFont end

    local f=fontCache[name]
    if not f then return FONT.rawget(size) end
    f=f[size]

    if not f then
        assert(type(size)=='number' and size>0 and size%1==0,"Font size should be a positive integer, not "..tostring(size))
        f=love.graphics.setNewFont(fontFiles[name],size,'normal',love.graphics.getDPIScale()*SCR.k*2)
        local fallbackName=fallbackMap[name] or defaultFallBack and name~=defaultFallBack and defaultFallBack
        if fallbackName then
            f:setFallbacks(FONT.get(size,fallbackName))
        end
        fontCache[name][size]=f
    end
    return f
end

--- Set font with font size, use default font name if not given
---
--- Warning: any numbers not appeared before will cause a new font object to be created, so don't call this with too many different font sizes
--- @param size number
--- @param name? string
function FONT.set(size,name)
    if not name then name=defaultFont end

    local f=FONT.get(size,name)

    if f~=curFont then
        curFont=f
        set(curFont)
    end
end

return FONT
