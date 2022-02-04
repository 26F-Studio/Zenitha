local set=love.graphics.setFont
local fontFiles,fontCache={},{}
local defaultFont,defaultFallBack
local fallbackMap={}
local curFont=false-- Current using font object

local FONT={}

function FONT.setDefaultFont(name)
    defaultFont=name
end
function FONT.setDefaultFallback(name)
    defaultFallBack=name
end
function FONT.setFallback(font,fallback)
    fallbackMap[font]=fallback
end

function FONT.rawget(size)
    if not fontCache[size] then
        assert(type(size)=='number' and size>0 and size%1==0,"Font size should be a positive integer, not "..tostring(size))
        fontCache[size]=love.graphics.setNewFont(size,'light',love.graphics.getDPIScale()*SCR.k*2)
    end
    return fontCache[size]
end
function FONT.rawset(size)
    set(fontCache[size] or FONT.rawget(size))
end
function FONT.load(fonts)
    for name,path in next,fonts do
        assert(love.filesystem.getInfo(path),STRING.repD("Font file $1($2) not exist!",name,path))
        fontFiles[name]=love.filesystem.newFile(path)
        fontCache[name]={}
    end
end
function FONT.get(size,name)
    if not name then name=defaultFont end

    local f=fontCache[name]
    if not f then return FONT.rawget(size) end
    f=f[size]

    if not f then
        assert(type(size)=='number' and size>0 and size%1==0,"Font size should be a positive integer, not "..tostring(size))
        f=love.graphics.setNewFont(fontFiles[name],size,'light',love.graphics.getDPIScale()*SCR.k*2)
        local fallbackName=fallbackMap[name] or defaultFallBack and name~=defaultFallBack and defaultFallBack
        if fallbackName then
            f:setFallbacks(FONT.get(size,fallbackName))
        end
        fontCache[name][size]=f
    end
    return f
end
function FONT.set(size,name)
    if not name then name=defaultFont end

    local f=fontCache[name]
    if not f then return FONT.rawset(size) end
    f=f[size]

    if f~=curFont then
        curFont=f or FONT.get(size,name)
        set(curFont)
    end
end

return FONT
