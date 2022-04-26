local abs=math.abs
local function hex(str)
    assert(type(str)=='string',"COLOR.hex(str): str must be string")
    str=str:match('#?%x%x?%x?%x?%x?%x?%x?%x?#?') or '000000'
    assert(#str<=8,"COLOR.hex(str): length of str must <= 8 (except #)")
    local r=(tonumber(str:sub(1,2),16) or 0)/255
    local g=(tonumber(str:sub(3,4),16) or 0)/255
    local b=(tonumber(str:sub(5,6),16) or 0)/255
    local a=(tonumber(str:sub(7,8),16) or 255)/255
    return r,g,b,a
end
local function hsv(h,s,v,a)-- Color type, Color amount, Light
    if s<=0 then return v,v,v,a end
    h=h*6
    local c=v*s
    local x=abs((h-1)%2-1)*c
    if h<1     then return v,x+v-c,v-c,a
    elseif h<2 then return x+v-c,v,v-c,a
    elseif h<3 then return v-c,v,x+v-c,a
    elseif h<4 then return v-c,x+v-c,v,a
    elseif h<5 then return x+v-c,v-c,v,a
    else            return v,v-c,x+v-c,a
    end
end

local COLOR={
    hex=hex,hsv=hsv,

    Red=     {{hex'3D0401'},{hex'83140F'},{hex'FF3126'},{hex'FF7B74'},{hex'FFC0BC'}},
    Flame=   {{hex'3B1100'},{hex'802806'},{hex'FA5311'},{hex'F98D64'},{hex'FAC5B0'}},
    Orange=  {{hex'341D00'},{hex'7B4501'},{hex'F58B00'},{hex'F4B561'},{hex'F5DAB8'}},
    Yellow=  {{hex'2E2500'},{hex'755D00'},{hex'F5C400'},{hex'F5D763'},{hex'F5EABD'}},
    Apple=   {{hex'202A02'},{hex'536D06'},{hex'AFE50B'},{hex'C5E460'},{hex'D9E5B2'}},
    Kelly=   {{hex'0C2800'},{hex'236608'},{hex'4ED415'},{hex'8ADE67'},{hex'C2E5B4'}},
    Green=   {{hex'002A06'},{hex'096017'},{hex'1DC436'},{hex'69D37A'},{hex'B0E2B8'}},
    Jungle=  {{hex'002E2C'},{hex'00635E'},{hex'00C1B7'},{hex'5BD2CA'},{hex'B0E1DE'}},
    Cyan=    {{hex'032733'},{hex'135468'},{hex'30A3C6'},{hex'72C1D7'},{hex'B1DBE8'}},
    Ice=     {{hex'0C2437'},{hex'194A73'},{hex'318FDB'},{hex'6FAEE0'},{hex'A9CAE4'}},
    Sea=     {{hex'001F40'},{hex'014084'},{hex'007BFF'},{hex'519CEF'},{hex'B0CCEB'}},
    Blue=    {{hex'0D144F'},{hex'212B8F'},{hex'4053FB'},{hex'7C87F7'},{hex'B2B8F4'}},
    Purple=  {{hex'1D1744'},{hex'332876'},{hex'5947CC'},{hex'897CE1'},{hex'B7ADF7'}},
    Violet=  {{hex'2A1435'},{hex'54296C'},{hex'9F4BC9'},{hex'B075CB'},{hex'C8A7D8'}},
    Magenta= {{hex'37082B'},{hex'731A5D'},{hex'DE3AB5'},{hex'DF74C3'},{hex'DEA9D1'}},
    Wine=    {{hex'460813'},{hex'871126'},{hex'F52249'},{hex'F56D87'},{hex'F5B4C0'}},

    Dark=    {{hex'000000'},{hex'060606'},{hex'101010'},{hex'3C3C3C'},{hex'7A7A7A'}},
    Light=   {{hex'B8B8B8'},{hex'DBDBDB'},{hex'FDFDFD'},{hex'FEFEFE'},{hex'FFFFFF'}},
    Xback=   {{hex'060606CC'},{hex'3C3C3CCC'},{hex'7A7A7ACC'},{hex'DBDBDBCC'},{hex'FEFEFECC'}},
}
do
    -- Get all color names
    local colorNames={}
    for k,v in next,COLOR do
        if type(v)=='table' then
            table.insert(colorNames,k)
        end
    end

    -- Shorten color names (COLOR.R=COLOR.Red)
    for i=1,#colorNames do
        local name=colorNames[i]
        COLOR['D'..name:sub(1,1)]=COLOR[name][1]
        COLOR['d'..name:sub(1,1)]=COLOR[name][2]
        COLOR[     name:sub(1,1)]=COLOR[name][3]
        COLOR['l'..name:sub(1,1)]=COLOR[name][4]
        COLOR['L'..name:sub(1,1)]=COLOR[name][5]
    end

    -- Create [1]~[5] color lists (COLOR[1]={red={...}, ...}, ...)
    for i=1,5 do
        COLOR[i]={}
        for j=1,#colorNames do
            local name=colorNames[j]
            COLOR[i][name]=COLOR[name][i]
            COLOR[i][name:sub(1,1)]=COLOR[name][i]
        end
    end
end
setmetatable(COLOR,{__index=function(_,k)
    assert(type(k)=='string', "COLOR[name]: name must be string")
    error("No color: "..tostring(k))
end,__metatable=true})


do-- Random generators
    local rnd=math.random
    local colors={'R','F','O','Y','A','K','G','J','C','I','S','B','P','V','M','W'}
    function COLOR.random(t)
        if type(t)~='number' or not COLOR[t] then error("COLOR.random(t): t must be 1~5 (brightness)") end
        return COLOR[t][colors[rnd(#colors)]]
    end
end

do-- Rainbow generators
    local sin=math.sin
    function COLOR.rainbow(phase,a)
        return
            sin(phase)*.4+.6,
            sin(phase+2.0944)*.4+.6,
            sin(phase-2.0944)*.4+.6,
            a
    end
    function COLOR.rainbow_light(phase,a)
        return
            sin(phase)*.2+.7,
            sin(phase+2.0944)*.2+.7,
            sin(phase-2.0944)*.2+.7,
            a
    end
    function COLOR.rainbow_dark(phase,a)
        return
            sin(phase)*.2+.4,
            sin(phase+2.0944)*.2+.4,
            sin(phase-2.0944)*.2+.4,
            a
    end
    function COLOR.rainbow_gray(phase,a)
        return
            sin(phase)*.16+.5,
            sin(phase+2.0944)*.16+.5,
            sin(phase-2.0944)*.16+.5,
            a
    end
end

return COLOR
