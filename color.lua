--[[ Color Shortcuts
    R: Red
    F: Flame
    O: Orange
    Y: Yellow
    A: Apple
    K: Kelly
    G: Green
    J: Jungle
    C: Cyan
    I: Ice
    S: Sea
    B: Blue
    P: Purple
    V: Violet
    M: Magenta
    W: Wine
    D: Dark
    L: Light
    T: Translucent
    X: Xnothing
]]

---@class Zenitha.Color: table READ ONLY
---@field [1] number Red
---@field [2] number Green
---@field [3] number Blue
---@field [4]? number Alpha

local rnd,sin,abs=math.random,math.sin,math.abs
local max,min=math.max,math.min

---Convert hex string to color  
---**Warning:** low performance
---@param str string
---@return number, number, number, number?
---@nodiscard
local function HEX(str)
    assert(type(str)=='string',"COLOR.HEX(str): Need string")
    str=str:match('#?(%x%x?%x?%x?%x?%x?%x?%x?)') or '000000'
    local r=(tonumber(str:sub(1,2),16) or 0)/255
    local g=(tonumber(str:sub(3,4),16) or 0)/255
    local b=(tonumber(str:sub(5,6),16) or 0)/255
    local a=(tonumber(str:sub(7,8),16) or 255)/255
    return r,g,b,a
end

local c={
    Reds=     {{HEX'3D0401'},{HEX'83140F'},{HEX'FF3126'},{HEX'FF7B74'},{HEX'FFC0BC'}},
    Flames=   {{HEX'3B1100'},{HEX'802806'},{HEX'FA5311'},{HEX'F98D64'},{HEX'FAC5B0'}},
    Oranges=  {{HEX'341D00'},{HEX'7B4501'},{HEX'F58B00'},{HEX'F4B561'},{HEX'F5DAB8'}},
    Yellows=  {{HEX'2E2500'},{HEX'755D00'},{HEX'F5C400'},{HEX'F5D763'},{HEX'F5EABD'}},
    Apples=   {{HEX'202A02'},{HEX'536D06'},{HEX'AFE50B'},{HEX'C5E460'},{HEX'D9E5B2'}},
    Kellys=   {{HEX'0C2800'},{HEX'236608'},{HEX'4ED415'},{HEX'8ADE67'},{HEX'C2E5B4'}},
    Greens=   {{HEX'002A06'},{HEX'096017'},{HEX'1DC436'},{HEX'69D37A'},{HEX'B0E2B8'}},
    Jungles=  {{HEX'002E2C'},{HEX'00635E'},{HEX'00C1B7'},{HEX'5BD2CA'},{HEX'B0E1DE'}},
    Cyans=    {{HEX'032733'},{HEX'135468'},{HEX'30A3C6'},{HEX'72C1D7'},{HEX'B1DBE8'}},
    Ices=     {{HEX'0C2437'},{HEX'194A73'},{HEX'318FDB'},{HEX'6FAEE0'},{HEX'A9CAE4'}},
    Seas=     {{HEX'001F40'},{HEX'014084'},{HEX'007BFF'},{HEX'519CEF'},{HEX'B0CCEB'}},
    Blues=    {{HEX'0D144F'},{HEX'212B8F'},{HEX'4053FB'},{HEX'7C87F7'},{HEX'B2B8F4'}},
    Purples=  {{HEX'1D1744'},{HEX'332876'},{HEX'5947CC'},{HEX'897CE1'},{HEX'B7ADF7'}},
    Violets=  {{HEX'2A1435'},{HEX'54296C'},{HEX'9F4BC9'},{HEX'B075CB'},{HEX'C8A7D8'}},
    Magentas= {{HEX'37082B'},{HEX'731A5D'},{HEX'DE3AB5'},{HEX'DF74C3'},{HEX'DEA9D1'}},
    Wines=    {{HEX'460813'},{HEX'871126'},{HEX'F52249'},{HEX'F56D87'},{HEX'F5B4C0'}},
    Darks=    {{HEX'000000'},{HEX'060606'},{HEX'101010'},{HEX'3C3C3C'},{HEX'7A7A7A'}},
    Lights=   {{HEX'B8B8B8'},{HEX'DBDBDB'},{HEX'FDFDFD'},{HEX'FEFEFE'},{HEX'FFFFFF'}},
    Translucents={{HEX'060606CC'},{HEX'3C3C3CCC'},{HEX'7A7A7ACC'},{HEX'DBDBDBCC'},{HEX'FEFEFECC'}},
    Xnothing=    {{HEX'00000000'},{HEX'10101000'},{HEX'90909000'},{HEX'FDFDFD00'},{HEX'FFFFFF00'}},
}
---@enum (key) Zenitha.ColorStr
local COLOR={
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

    DarkTranslucent=c.Translucents[1],darkTranslucent=c.Translucents[2],Translucent=c.Translucents[3],lightTranslucent=c.Translucents[4],LightTranslucent=c.Translucents[5],

    -- Separating these (down below) into single lines helps making language server hinting the full color names

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
    DX=c.Xnothing[1], -- DarkXnothing
    dX=c.Xnothing[2], -- darkXnothing
    X=c.Xnothing[3], -- Xnothing
    lX=c.Xnothing[4], -- lightXnothing
    LX=c.Xnothing[5], -- LightXnothing
}
setmetatable(COLOR,{__index=function(_,k)
    assert(type(k)=='string', "COLOR[name]: Need string")
    errorf("COLOR[name]:  No color '%s'",k)
end,__metatable=true})

COLOR.Reds=c.Reds
COLOR.Flames=c.Flames
COLOR.Oranges=c.Oranges
COLOR.Yellows=c.Yellows
COLOR.Apples=c.Apples
COLOR.Kellys=c.Kellys
COLOR.Greens=c.Greens
COLOR.Jungles=c.Jungles
COLOR.Cyans=c.Cyans
COLOR.Ices=c.Ices
COLOR.Seas=c.Seas
COLOR.Blues=c.Blues
COLOR.Purples=c.Purples
COLOR.Violets=c.Violets
COLOR.Magentas=c.Magentas
COLOR.Wines=c.Wines
COLOR.Darks=c.Darks
COLOR.Lights=c.Lights
COLOR.Translucents=c.Translucents
COLOR.Xnothing=c.Xnothing

for i=1,5 do
    COLOR[i]={
        Red=c.Reds[i],       Flame=c.Flames[i],   Orange=c.Oranges[i],
        Yellow=c.Yellows[i], Apple=c.Apples[i],   Kelly=c.Kellys[i],
        Green=c.Greens[i],   Jungle=c.Jungles[i], Cyan=c.Cyans[i],
        Ice=c.Ices[i],       Sea=c.Seas[i],       Blue=c.Blues[i],
        Purple=c.Purples[i], Violet=c.Violets[i], Magenta=c.Magentas[i],
        Wine=c.Wines[i],     Dark=c.Darks[i],     Light=c.Lights[i],
        Translucent=c.Translucents[i],Xnothing=c.Xnothing[i],
    }
end

COLOR.HEX=HEX

---Convert color to hex string
---@param r number [0,1]
---@param g number [0,1]
---@param b number [0,1]
---@param a? number alpha
---@return string hex the 6 or 8 digits string
---@nodiscard
function COLOR.toHEX(r,g,b,a)
    if a then
        r,g,b,a=r*255,g*255,b*255,a*255
        return string.format("%02X%02X%02X%02X",r,g,b,a)
    else
        r,g,b=r*255,g*255,b*255
        return string.format("%02X%02X%02X",r,g,b)
    end
end



---Convert HSV to RGB
---@param h number Color type
---@param s number Color amount
---@param v number Value
---@param a? number Alpha
---@return number, number, number, number?
---@nodiscard
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

---Convert RGB to HSV
---@param r number [0,1]
---@param g number [0,1]
---@param b number [0,1]
---@param a? number alpha
---@return number, number, number, number? #All [0,1]
---@nodiscard
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
---@nodiscard
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

---Convert RGB to HSL
---@param r number [0,1]
---@param g number [0,1]
---@param b number [0,1]
---@param a? number alpha
---@return number, number, number, number? #All [0,1]
---@nodiscard
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
---@nodiscard
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
---@nodiscard
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
---@nodiscard
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
---@nodiscard
function COLOR.rainbow_gray(phase,a)
    return
        sin(phase)*.16+.5,
        sin(phase+2.0944)*.16+.5,
        sin(phase-2.0944)*.16+.5,
        a
end



local sets={'Reds','Flames','Oranges','Yellows','Apples','Kellys','Greens','Jungles','Cyans','Ices','Seas','Blues','Purples','Violets','Magentas','Wines'}
---Get a random standard color
---@param brightness? number 1~5, blank for random brightness
---@return Zenitha.Color
---@nodiscard
function COLOR.random(brightness)
    return COLOR[sets[rnd(#sets)]][brightness or rnd(5)]
end
COLOR.colorSets=sets



---Get mix value (linear) of two colors with a ratio (not clamped) in vararg
---@param c1 Zenitha.Color
---@param c2 Zenitha.Color
---@param t number
---@param a? number alpha
---@return number, number, number, number
---@nodiscard
function COLOR.lerp(c1,c2,t,a)
    return
        c1[1]*(1-t)+c2[1]*t,
        c1[2]*(1-t)+c2[2]*t,
        c1[3]*(1-t)+c2[3]*t,
        a or (c1[4] or 1)*(1-t)+(c2[4] or 1)*t
end



return COLOR
