---@class Zenitha.Color: table READ ONLY
---@field [1] number Red
---@field [2] number Green
---@field [3] number Blue
---@field [4]? number Alpha

local rnd,sin,abs=math.random,math.sin,math.abs
local max,min=math.max,math.min

---Convert hex string to color
---@param str string
---@return number, number, number, number?
local function hex(str)
    assert(type(str)=='string',"COLOR.hex(str): Need string")
    str=str:match('#?(%x%x?%x?%x?%x?%x?%x?%x?)') or '000000'
    local r=(tonumber(str:sub(1,2),16) or 0)/255
    local g=(tonumber(str:sub(3,4),16) or 0)/255
    local b=(tonumber(str:sub(5,6),16) or 0)/255
    local a=(tonumber(str:sub(7,8),16) or 255)/255
    return r,g,b,a
end

local c={
    Reds=     {{hex'3D0401'},{hex'83140F'},{hex'FF3126'},{hex'FF7B74'},{hex'FFC0BC'}},
    Flames=   {{hex'3B1100'},{hex'802806'},{hex'FA5311'},{hex'F98D64'},{hex'FAC5B0'}},
    Oranges=  {{hex'341D00'},{hex'7B4501'},{hex'F58B00'},{hex'F4B561'},{hex'F5DAB8'}},
    Yellows=  {{hex'2E2500'},{hex'755D00'},{hex'F5C400'},{hex'F5D763'},{hex'F5EABD'}},
    Apples=   {{hex'202A02'},{hex'536D06'},{hex'AFE50B'},{hex'C5E460'},{hex'D9E5B2'}},
    Kellys=   {{hex'0C2800'},{hex'236608'},{hex'4ED415'},{hex'8ADE67'},{hex'C2E5B4'}},
    Greens=   {{hex'002A06'},{hex'096017'},{hex'1DC436'},{hex'69D37A'},{hex'B0E2B8'}},
    Jungles=  {{hex'002E2C'},{hex'00635E'},{hex'00C1B7'},{hex'5BD2CA'},{hex'B0E1DE'}},
    Cyans=    {{hex'032733'},{hex'135468'},{hex'30A3C6'},{hex'72C1D7'},{hex'B1DBE8'}},
    Ices=     {{hex'0C2437'},{hex'194A73'},{hex'318FDB'},{hex'6FAEE0'},{hex'A9CAE4'}},
    Seas=     {{hex'001F40'},{hex'014084'},{hex'007BFF'},{hex'519CEF'},{hex'B0CCEB'}},
    Blues=    {{hex'0D144F'},{hex'212B8F'},{hex'4053FB'},{hex'7C87F7'},{hex'B2B8F4'}},
    Purples=  {{hex'1D1744'},{hex'332876'},{hex'5947CC'},{hex'897CE1'},{hex'B7ADF7'}},
    Violets=  {{hex'2A1435'},{hex'54296C'},{hex'9F4BC9'},{hex'B075CB'},{hex'C8A7D8'}},
    Magentas= {{hex'37082B'},{hex'731A5D'},{hex'DE3AB5'},{hex'DF74C3'},{hex'DEA9D1'}},
    Wines=    {{hex'460813'},{hex'871126'},{hex'F52249'},{hex'F56D87'},{hex'F5B4C0'}},
    Darks=    {{hex'000000'},{hex'060606'},{hex'101010'},{hex'3C3C3C'},{hex'7A7A7A'}},
    Lights=   {{hex'B8B8B8'},{hex'DBDBDB'},{hex'FDFDFD'},{hex'FEFEFE'},{hex'FFFFFF'}},
    Translucents={{hex'060606CC'},{hex'3C3C3CCC'},{hex'7A7A7ACC'},{hex'DBDBDBCC'},{hex'FEFEFECC'}},
}
local COLOR=setmetatable({
    hex=hex,

    DarkRed=    c.Reds[1],     darkRed=    c.Reds[2],     Red=    c.Reds[3],     lightRed=    c.Reds[4],     LightRed=    c.Reds[5],
    DarkFlame=  c.Flames[1],   darkFlame=  c.Flames[2],   Flame=  c.Flames[3],   lightFlame=  c.Flames[4],   LightFlame=  c.Flames[5],
    DarkOrange= c.Oranges[1],  darkOrange= c.Oranges[2],  Orange= c.Oranges[3],  lightOrange= c.Oranges[4],  LightOrange= c.Oranges[5],
    DarkYellow= c.Yellows[1],  darkYellow= c.Yellows[2],  Yellow= c.Yellows[3],  lightYellow= c.Yellows[4],  LightYellow= c.Yellows[5],
    DarkApple=  c.Apples[1],   darkApple=  c.Apples[2],   Apple=  c.Apples[3],   lightApple=  c.Apples[4],   LightApple=  c.Apples[5],
    DarkKelly=  c.Kellys[1],   darkKelly=  c.Kellys[2],   Kelly=  c.Kellys[3],   lightKelly=  c.Kellys[4],   LightKelly=  c.Kellys[5],
    DarkGreen=  c.Greens[1],   darkGreen=  c.Greens[2],   Green=  c.Greens[3],   lightGreen=  c.Greens[4],   LightGreen=  c.Greens[5],
    DarkJungle= c.Jungles[1],  darkJungle= c.Jungles[2],  Jungle= c.Jungles[3],  lightJungle= c.Jungles[4],  LightJungle= c.Jungles[5],
    DarkCyan=   c.Cyans[1],    darkCyan=   c.Cyans[2],    Cyan=   c.Cyans[3],    lightCyan=   c.Cyans[4],    LightCyan=   c.Cyans[5],
    DarkIce=    c.Ices[1],     darkIce=    c.Ices[2],     Ice=    c.Ices[3],     lightIce=    c.Ices[4],     LightIce=    c.Ices[5],
    DarkSea=    c.Seas[1],     darkSea=    c.Seas[2],     Sea=    c.Seas[3],     lightSea=    c.Seas[4],     LightSea=    c.Seas[5],
    DarkBlue=   c.Blues[1],    darkBlue=   c.Blues[2],    Blue=   c.Blues[3],    lightBlue=   c.Blues[4],    LightBlue=   c.Blues[5],
    DarkPurple= c.Purples[1],  darkPurple= c.Purples[2],  Purple= c.Purples[3],  lightPurple= c.Purples[4],  LightPurple= c.Purples[5],
    DarkViolet= c.Violets[1],  darkViolet= c.Violets[2],  Violet= c.Violets[3],  lightViolet= c.Violets[4],  LightViolet= c.Violets[5],
    DarkMagenta=c.Magentas[1], darkMagenta=c.Magentas[2], Magenta=c.Magentas[3], lightMagenta=c.Magentas[4], LightMagenta=c.Magentas[5],
    DarkWine=   c.Wines[1],    darkWine=   c.Wines[2],    Wine=   c.Wines[3],    lightWine=   c.Wines[4],    LightWine=   c.Wines[5],
    DarkDark=   c.Darks[1],    darkDark=   c.Darks[2],    Dark=   c.Darks[3],    lightDark=   c.Darks[4],    LightDark=   c.Darks[5],
    DarkLight=  c.Lights[1],   darkLight=  c.Lights[2],   Light=  c.Lights[3],   lightLight=  c.Lights[4],   LightLight=  c.Lights[5],
    Black=      c.Darks[1],    --[[Dark=   c.Darks[3],]]
    DarkGray=   c.Darks[4],    darkGray=   c.Darks[5],    lightGray=c.Lights[1], LightGray=   c.Lights[2],
    DarkGrey=   c.Darks[4],    darkGrey=   c.Darks[5],    lightGrey=c.Lights[1], LightGrey=   c.Lights[2],
    --[[Light=  c.Lights[3],]] White=      c.Lights[5],
    DarkTranslucent=c.Translucents[1],
    darkTranslucent=c.Translucents[2],
    Translucent= c.Translucents[3],
    lightTranslucent=c.Translucents[4],
    LightTranslucent= c.Translucents[5],

    DR=c.Reds[1], -- DarkRed
    dR=c.Reds[2], -- darkRed
    R=c.Reds[3], -- Red
    lR=c.Reds[4], -- lightRed
    LR=c.Reds[5], -- LightRed
    DF=c.Flames[1], -- DarkFlame
    dF=c.Flames[2], -- darkFlame
    F=c.Flames[3], -- Flame
    lF=c.Flames[4], -- lightFlame
    LF=c.Flames[5], -- LightFlame
    DO=c.Oranges[1], -- DarkOrange
    dO=c.Oranges[2], -- darkOrange
    O=c.Oranges[3], -- Orange
    lO=c.Oranges[4], -- lightOrange
    LO=c.Oranges[5], -- LightOrange
    DY=c.Yellows[1], -- DarkYellow
    dY=c.Yellows[2], -- darkYellow
    Y=c.Yellows[3], -- Yellow
    lY=c.Yellows[4], -- lightYellow
    LY=c.Yellows[5], -- LightYellow
    DA=c.Apples[1], -- DarkApple
    dA=c.Apples[2], -- darkApple
    A=c.Apples[3], -- Apple
    lA=c.Apples[4], -- lightApple
    LA=c.Apples[5], -- LightApple
    DK=c.Kellys[1], -- DarkKelly
    dK=c.Kellys[2], -- darkKelly
    K=c.Kellys[3], -- Kelly
    lK=c.Kellys[4], -- lightKelly
    LK=c.Kellys[5], -- LightKelly
    DG=c.Greens[1], -- DarkGreen
    dG=c.Greens[2], -- darkGreen
    G=c.Greens[3], -- Green
    lG=c.Greens[4], -- lightGreen
    LG=c.Greens[5], -- LightGreen
    DJ=c.Jungles[1], -- DarkJungle
    dJ=c.Jungles[2], -- darkJungle
    J=c.Jungles[3], -- Jungle
    lJ=c.Jungles[4], -- lightJungle
    LJ=c.Jungles[5], -- LightJungle
    DC=c.Cyans[1], -- DarkCyan
    dC=c.Cyans[2], -- darkCyan
    C=c.Cyans[3], -- Cyan
    lC=c.Cyans[4], -- lightCyan
    LC=c.Cyans[5], -- LightCyan
    DI=c.Ices[1], -- DarkIce
    dI=c.Ices[2], -- darkIce
    I=c.Ices[3], -- Ice
    lI=c.Ices[4], -- lightIce
    LI=c.Ices[5], -- LightIce
    DS=c.Seas[1], -- DarkSea
    dS=c.Seas[2], -- darkSea
    S=c.Seas[3], -- Sea
    lS=c.Seas[4], -- lightSea
    LS=c.Seas[5], -- LightSea
    DB=c.Blues[1], -- DarkBlue
    dB=c.Blues[2], -- darkBlue
    B=c.Blues[3], -- Blue
    lB=c.Blues[4], -- lightBlue
    LB=c.Blues[5], -- LightBlue
    DP=c.Purples[1], -- DarkPurple
    dP=c.Purples[2], -- darkPurple
    P=c.Purples[3], -- Purple
    lP=c.Purples[4], -- lightPurple
    LP=c.Purples[5], -- LightPurple
    DV=c.Violets[1], -- DarkViolet
    dV=c.Violets[2], -- darkViolet
    V=c.Violets[3], -- Violet
    lV=c.Violets[4], -- lightViolet
    LV=c.Violets[5], -- LightViolet
    DM=c.Magentas[1], -- DarkMagenta
    dM=c.Magentas[2], -- darkMagenta
    M=c.Magentas[3], -- Magenta
    lM=c.Magentas[4], -- lightMagenta
    LM=c.Magentas[5], -- LightMagenta
    DW=c.Wines[1], -- DarkWine
    dW=c.Wines[2], -- darkWine
    W=c.Wines[3], -- Wine
    lW=c.Wines[4], -- lightWine
    LW=c.Wines[5], -- LightWine
    DD=c.Darks[1], -- DarkDark
    dD=c.Darks[2], -- darkDark
    D=c.Darks[3], -- Dark
    lD=c.Darks[4], -- lightDark
    LD=c.Darks[5], -- LightDark
    DL=c.Lights[1], -- DarkLight
    dL=c.Lights[2], -- darkLight
    L=c.Lights[3], -- Light
    lL=c.Lights[4], -- lightLight
    LL=c.Lights[5], -- LightLight
    DT=c.Translucents[1], -- DarkTranslucent
    dT=c.Translucents[2], -- darkTranslucent
    T=c.Translucents[3], -- Translucent
    lT=c.Translucents[4], -- lightTranslucent
    LT=c.Translucents[5], -- LightTranslucent

    Reds=c.Reds,         Flames=c.Flames,   Oranges=c.Oranges,
    Yellows=c.Yellows,   Apples=c.Apples,   Kellys=c.Kellys,
    Greens=c.Greens,     Jungles=c.Jungles,
    Cyans=c.Cyans,       Ices=c.Ices,       Seas=c.Seas,
    Blues=c.Blues,       Purples=c.Purples, Violets=c.Violets,
    Magentas=c.Magentas, Wines=c.Wines,
    Darks=c.Darks,       Lights=c.Lights,   Translucents=c.Translucents,
},{__index=function(_,k)
    assert(type(k)=='string', "COLOR[name]: Need string")
    errorf("COLOR[name]:  No color '%s'",k)
end,__metatable=true})

---Convert HSV to RGB
---@param h number Color type
---@param s number Color amount
---@param v number Value
---@param a? number Alpha
---@return number, number, number, number?
function COLOR.HSV(h,s,v,a)
    if s<=0 then return v,v,v,a end
    h=h*6
    local p=v*s
    local x=abs((h-1)%2-1)*p
    if     h<1 then return v,x+v-p,v-p,a
    elseif h<2 then return x+v-p,v,v-p,a
    elseif h<3 then return v-p,v,x+v-p,a
    elseif h<4 then return v-p,x+v-p,v,a
    elseif h<5 then return x+v-p,v-p,v,a
    else            return v,v-p,x+v-p,a
    end
end
---@param r number [0,1]
---@param g number [0,1]
---@param b number [0,1]
---@param a? number alpha
---@return number, number, number, number? #All [0,1]
function COLOR.toHSV(r,g,b,a)
    local M=max(r,g,b)
    local m=min(r,g,b)
    if M==m then return 0,0,M,a end

    local d=M-m

    return
        (
            M==r and ((g-b)/d+(g<b and 6 or 0)) or
            M==g and ((b-r)/d+2) or
            ((r-g)/d+4)
        )/6,
        M==0 and 0 or d/M,
        M,
        a
end

local function hue2rgb(p,q,t)
    t=t%1
    if t<1/6 then return p+(q-p)*6*t end
    if t<1/2 then return q end
    if t<2/3 then return p+(q-p)*(2/3-t)*6 end
    return p
end
---Convert HSL to RGB
---@param h number Color type
---@param s number Color amount
---@param l number Lightness
---@param a? number Alpha
---@return number, number, number, number?
function COLOR.HSL(h,s,l,a)
    if s<=0 then return l,l,l,a end

    local q=l<.5 and l*(1+s) or l*(1-s)+s
    local p=2*l-q
    return
        hue2rgb(p,q,h+1/3),
        hue2rgb(p,q,h),
        hue2rgb(p,q,h-1/3),
        a
end
---@param r number [0,1]
---@param g number [0,1]
---@param b number [0,1]
---@param a? number alpha
---@return number, number, number, number? #All [0,1]
function COLOR.toHSL(r,g,b,a)
    local M=max(r,g,b)
    local m=min(r,g,b)
    if M==m then return 0,0,M,a end

    local l=(M+m)/2
    local d=M-m
    return
        (
            M==r and ((g-b)/d+(g<b and 6 or 0)) or
            M==g and ((b-r)/d+2) or
            ((r-g)/d+4)
        )/6,
        l>.5 and d/(2-M-m) or d/(M+m),
        l,
        a
end

---Get Rainbow color with phase
---@param phase number cycle in 2pi
---@param a? number alpha
---@return number, number, number, number?
function COLOR.rainbow(phase,a)
    return
        sin(phase)*.4+.6,
        sin(phase+2.0944)*.4+.6,
        sin(phase-2.0944)*.4+.6,
        a
end
---Variant of COLOR.rainbow
---@param phase number cycle in 2pi
---@param a? number alpha
---@return number, number, number, number?
function COLOR.rainbow_light(phase,a)
    return
        sin(phase)*.2+.7,
        sin(phase+2.0944)*.2+.7,
        sin(phase-2.0944)*.2+.7,
        a
end
---Variant of COLOR.rainbow
---@param phase number cycle in 2pi
---@param a? number alpha
---@return number, number, number, number?
function COLOR.rainbow_dark(phase,a)
    return
        sin(phase)*.2+.4,
        sin(phase+2.0944)*.2+.4,
        sin(phase-2.0944)*.2+.4,
        a
end
---Variant of COLOR.rainbow
---@param phase number cycle in 2pi
---@param a? number alpha
---@return number, number, number, number?
function COLOR.rainbow_gray(phase,a)
    return
        sin(phase)*.16+.5,
        sin(phase+2.0944)*.16+.5,
        sin(phase-2.0944)*.16+.5,
        a
end

COLOR.colorSets={'Reds','Flames','Oranges','Yellows','Apples','Kellys','Greens','Jungles','Cyans','Ices','Seas','Blues','Purples','Violets','Magentas','Wines'}

function COLOR.random(brightness)
    return COLOR[COLOR.colorSets[rnd(#COLOR.colorSets)]][brightness or rnd(5)]
end

return COLOR
