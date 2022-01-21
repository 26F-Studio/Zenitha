local set=love.graphics.setFont
local fontFiles,fontCache={},{}
local defaultFont,defaultFallBack
local fallbackMap={}
local curFont=false-- Current using font object

local FONT={}

function FONT.setDefaultFont(name) defaultFont=name end
function FONT.setDefaultFallback(name) defaultFallBack=name end
function FONT.setFallback(font,fallback) fallbackMap[font]=fallback end

function FONT.rawget(s)
    if not fontCache[s] then
        fontCache[s]=love.graphics.setNewFont(s,'light',love.graphics.getDPIScale()*SCR.k*2)
    end
    return fontCache[s]
end
function FONT.rawset(s)
    set(fontCache[s] or FONT.rawget(s))
end
function FONT.load(fonts)
    for name,path in next,fonts do
        assert(love.filesystem.getInfo(path),STRING.repD("Font file $1($2) not exist!",name,path))
        fontFiles[name]=love.filesystem.newFile(path)
        fontCache[name]={}
    end
    FONT.reset()
end
function FONT.get(size,name)
    if not name then name=defaultFont end

    local f=fontCache[name]
    if not f then return FONT.rawget(size) end
    f=f[size]

    if not f then
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
function FONT.reset()
    for name,cache in next,fontCache do
        if type(cache)=='table' then
            for size in next,cache do
                cache[size]=FONT.get(size,name)
            end
        else
            fontCache[name]=FONT.rawget(name)
        end
    end
end

return FONT
