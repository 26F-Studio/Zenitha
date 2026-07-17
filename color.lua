--[[
## COLOR module

Features:

- `CLR.HEX`, `CLR.toHEX`
- `CLR.HSV`, `CLR.toHSV`
- `CLR.HSL`, `CLR.toHSL`
- `CLR.OKLCH`, `CLR.toOKLCH`
- `CLR.OKLAB`, `CLR.toOKLAB`
]]
---@diagnostic disable-next-line
local _hoverMouseHereToRead

--[[
Quick Palette:
- HEX: `CLR'FF8000'` for orange (see `CLR.HEX`) (need cache)
- RGB9: `CLR[960]` for orange (see `CLR.installNumLiteral`)
- HEX: `CLR.llYrS` for a light orange (see `CLR.ZCS`)
]]
local CLR={}
local max,min=math.max,math.min
local sin,cos=math.sin,math.cos
local atan2=math.atan2
local type,tonumber=type,tonumber
local find,match=string.find,string.match
local sub,format=string.sub,string.format

do -- Numeric Literal
    ---Installs numeric color literals into CLR (e.g., `CLR.installNumLiteral('RGB9')` enables `CLR[960]` for orange).
    ---
    ---Multiple calls overwrite previous installations.
    ---To use multiple libs simultaneously, set 2nd param to true and store the returned table yourself.
    ---
    ---For backward compatibility, you need this: `RGB9=CLR.installNumLiteral('RGB9',true)`
    ---@param mode 'RGB9' | 'RGBA9' | 'RGB5' | string could be `RGB\d` or `RGBA\d`
    ---@param export boolean? If true, return a new table instead of installing literals inside CLR
    function CLR.installNumLiteral(mode,export)
        -- Wipe old literals when already installed
        if not export then for k in next,CLR do if type(k)=='number' then CLR[k]=nil end end end

        -- Parse mode
        local m,n=string.match(mode,'(RGBA?)(%d)')
        if not m then error("CLR.installNumLiteral(mode): Invalid mode") end
        n=tonumber(n)
        if n==0 then error("CLR.installNumLiteral(mode): Invalid peak value") end

        -- Generate colors and install into CLR or return a new table
        local lib=export and {} or CLR
        if m=='RGB' then
            for r=0,n do for g=0,n do for b=0,n do lib[100*r+10*g+b]={r/n,g/n,b/n} end end end
        else
            for r=0,n do for g=0,n do for b=0,n do for a=0,n do lib[1000*r+100*g+10*b+a]={r/n,g/n,b/n,a/n} end end end end
        end

        if export then return lib end
    end
end

do -- HEX
    ---Convert hex string to color
    ---
    ---You can use `CLR"FF8000"` as shortcut, `CLR` has `__call=CLR.HEX` meta method
    ---
    ---**Warning:** low performance, do not use this directly in drawing loop
    ---@param str string
    ---@return number, number, number, number?
    ---@nodiscard
    function CLR.HEX(str)
        if type(str)~='string' then error("CLR.HEX(str): Need string") end
        str=match(str,'^(%x+)')
        if not str then
            error("CLR.HEX(str): Invalid string (no hex substring found)")
        elseif #str==6 then
            return
                (tonumber(sub(str,1,2),16) or 0)/255,
                (tonumber(sub(str,3,4),16) or 0)/255,
                (tonumber(sub(str,5,6),16) or 0)/255,
                1
        elseif #str==8 then
            return
                (tonumber(sub(str,1,2),16) or 0)/255,
                (tonumber(sub(str,3,4),16) or 0)/255,
                (tonumber(sub(str,5,6),16) or 0)/255,
                (tonumber(sub(str,7,8),16) or 255)/255
        elseif #str==3 then
            local r=(tonumber(sub(str,1,1),16) or 0)/15
            local g=(tonumber(sub(str,2,2),16) or 0)/15
            local b=(tonumber(sub(str,3,3),16) or 0)/15
            return r,g,b,1
        elseif #str==4 then
            local r=(tonumber(sub(str,1,1),16) or 0)/15
            local g=(tonumber(sub(str,2,2),16) or 0)/15
            local b=(tonumber(sub(str,3,3),16) or 0)/15
            local a=(tonumber(sub(str,4,4),16) or 15)/15
            return r,g,b,a
        else
            error("CLR.HEX(str): Invalid length (must be 6, 8, 3, 4)")
        end
    end

    ---Convert color to hex string
    ---@param r number [0,1]
    ---@param g number [0,1]
    ---@param b number [0,1]
    ---@param a? number alpha
    ---@return string hex the 6 or 8 digits string
    ---@nodiscard
    function CLR.toHEX(r,g,b,a)
        r,g,b=r*255,g*255,b*255
        if a then
            return format("%02X%02X%02X%02X",r,g,b,a*255)
        else
            return format("%02X%02X%02X",r,g,b)
        end
    end
end

do -- HSV & HSL
    ---Convert HSV to RGB
    ---@param h number Hue (0 red, 1/3 green, 2/3 blue)
    ---@param s number Saturation (0 grey, 1 rainbow)
    ---@param v number Value (0 black, 1 white/rainbow)
    ---@param a? number Alpha
    ---@return number, number, number, number?
    ---@nodiscard
    function CLR.HSV(h,s,v,a)
        if s<=0 then return v,v,v,a end
        h=h*6
        local p=v*s
        local x=(h-1)%2-1
        x=(x<0 and -x or x)*p
        if h<1 then
            return v,x+v-p,v-p,a
        elseif h<2 then
            return x+v-p,v,v-p,a
        elseif h<3 then
            return v-p,v,x+v-p,a
        elseif h<4 then
            return v-p,x+v-p,v,a
        elseif h<5 then
            return x+v-p,v-p,v,a
        else
            return v,v-p,x+v-p,a
        end
    end

    local function hue2rgb(lo,hi,hue)
        hue=hue%1*6
        return
            hue<1 and lo+(hi-lo)*hue or
            hue<3 and hi or
            hue<4 and lo+(hi-lo)*(4-hue) or
            lo
    end

    ---Convert HSL to RGB
    ---@param h number Hue (0 red, 1/3 green, 2/3 blue)
    ---@param s number Saturation (0 grey, 1 rainbow)
    ---@param l number Lightness (0 black, 0.5 grey/rainbow, 1 white)
    ---@param a? number Alpha
    ---@return number, number, number, number?
    ---@nodiscard
    function CLR.HSL(h,s,l,a)
        if s<=0 then return l,l,l,a end
        local hi=l<.5 and l*(1+s) or l*(1-s)+s
        local lo=2*l-hi
        return
            hue2rgb(lo,hi,h+1/3),
            hue2rgb(lo,hi,h),
            hue2rgb(lo,hi,h-1/3),
            a
    end

    ---Convert RGB to HSV
    ---@param r number [0,1]
    ---@param g number [0,1]
    ---@param b number [0,1]
    ---@param a? number alpha
    ---@return number, number, number, number? #All [0,1]
    ---@nodiscard
    function CLR.toHSV(r,g,b,a)
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

    ---Convert RGB to HSL
    ---@param r number [0,1]
    ---@param g number [0,1]
    ---@param b number [0,1]
    ---@param a? number alpha
    ---@return number, number, number, number? #All [0,1]
    ---@nodiscard
    function CLR.toHSL(r,g,b,a)
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
end

do -- OKLAB & OKLCH
    ---Convert OKLCH to RGB, the brand new perceptually uniform color space!
    ---
    ---Note: the output might be out of [0,1], but it's fine to use them as final result, Love2D will clamp them for you.
    ---@param l number Lightness (0 black, 1 white)
    ---@param c number Chroma (0 grey, 0.2~0.3 colorful)
    ---@param h number Hue (0 red, 1/3 green, 2/3 blue)
    ---@param alpha number? Alpha
    ---@return number, number, number, number?
    ---@nodiscard
    function CLR.OKLCH(l,c,h,alpha)
        local a=c*cos(h*6.283185307179586)
        local b=c*sin(h*6.283185307179586)
        local l3=(l+0.3963377774*a+0.2158037573*b)^3
        local m3=(l-0.1055613458*a-0.0638541728*b)^3
        local s3=(l-0.0894841775*a-1.2914855480*b)^3
        local _r=4.0767416621*l3-3.3077115913*m3+0.2309699292*s3
        local _g=-1.2684380046*l3+2.6097574011*m3-0.3413193965*s3
        local _b=-0.0041960863*l3-0.7034186147*m3+1.7076147010*s3
        return
            _r<=0.0031308 and 12.92*_r or 1.055*(_r^(1/2.4))-0.055,
            _g<=0.0031308 and 12.92*_g or 1.055*(_g^(1/2.4))-0.055,
            _b<=0.0031308 and 12.92*_b or 1.055*(_b^(1/2.4))-0.055,
            alpha
    end

    ---Convert OKLAB to RGB (you should use OKLCH, this is not for human consumption)
    ---@param l number
    ---@param a number
    ---@param b number
    ---@param alpha number?
    ---@nodiscard
    function CLR.OKLAB(l,a,b,alpha)
        local l3=(l+0.3963377774*a+0.2158037573*b)^3
        local m3=(l-0.1055613458*a-0.0638541728*b)^3
        local s3=(l-0.0894841775*a-1.2914855480*b)^3
        local _r=4.0767416621*l3-3.3077115913*m3+0.2309699292*s3
        local _g=-1.2684380046*l3+2.6097574011*m3-0.3413193965*s3
        local _b=-0.0041960863*l3-0.7034186147*m3+1.7076147010*s3
        return
            _r<=0.0031308 and 12.92*_r or 1.055*(_r^(1/2.4))-0.055,
            _g<=0.0031308 and 12.92*_g or 1.055*(_g^(1/2.4))-0.055,
            _b<=0.0031308 and 12.92*_b or 1.055*(_b^(1/2.4))-0.055,
            alpha
    end

    ---Convert RGB to OKLCH
    ---@param r number [0,1]
    ---@param g number [0,1]
    ---@param b number [0,1]
    ---@param alpha? number
    ---@return number, number, number, number?
    ---@nodiscard
    function CLR.toOKLCH(r,g,b,alpha)
        local lr=r<=0.04045 and r/12.92 or ((r+0.055)/1.055)^2.4
        local lg=g<=0.04045 and g/12.92 or ((g+0.055)/1.055)^2.4
        local lb=b<=0.04045 and b/12.92 or ((b+0.055)/1.055)^2.4
        local l3=0.4122214708*lr+0.5363325363*lg+0.0514459929*lb
        local m3=0.2119034982*lr+0.6806995451*lg+0.1073969566*lb
        local s3=0.0883024619*lr+0.2817188376*lg+0.6299787005*lb
        local l1=l3>=0 and l3^(1/3) or -((-l3)^(1/3))
        local m1=m3>=0 and m3^(1/3) or -((-m3)^(1/3))
        local s1=s3>=0 and s3^(1/3) or -((-s3)^(1/3))
        local _l=0.2104542553*l1+0.7936177850*m1-0.0040720468*s1
        local _a=1.9779984951*l1-2.4285922050*m1+0.4505937099*s1
        local _b=0.0259040371*l1+0.7827717662*m1-0.8086757660*s1
        local C=(_a*_a+_b*_b)^.5
        local H=C>0 and (atan2(_b,_a)/6.283185307179586)%1 or 0
        return _l,C,H,alpha
    end

    ---Convert RGB to OKLAB
    ---@param r number [0,1]
    ---@param g number [0,1]
    ---@param b number [0,1]
    ---@param alpha? number
    ---@return number, number, number, number?
    ---@nodiscard
    function CLR.toOKLAB(r,g,b,alpha)
        local lr=r<=0.04045 and r/12.92 or ((r+0.055)/1.055)^2.4
        local lg=g<=0.04045 and g/12.92 or ((g+0.055)/1.055)^2.4
        local lb=b<=0.04045 and b/12.92 or ((b+0.055)/1.055)^2.4
        local l3=0.4122214708*lr+0.5363325363*lg+0.0514459929*lb
        local m3=0.2119034982*lr+0.6806995451*lg+0.1073969566*lb
        local s3=0.0883024619*lr+0.2817188376*lg+0.6299787005*lb
        local l1=l3>=0 and l3^(1/3) or -((-l3)^(1/3))
        local m1=m3>=0 and m3^(1/3) or -((-m3)^(1/3))
        local s1=s3>=0 and s3^(1/3) or -((-s3)^(1/3))
        return
            0.2104542553*l1+0.7936177850*m1-0.0040720468*s1,
            1.9779984951*l1-2.4285922050*m1+0.4505937099*s1,
            0.0259040371*l1+0.7827717662*m1-0.8086757660*s1,
            alpha
    end
end

do -- Zenitha Color System
    local errMsg={
        wrongLight="CLR.ZCS: Wrong lightness prefix: ",
        hueFtTooLong="CLR.ZCS: Hue postfix too long",
        wrongChroma="CLR.ZCS: Chroma postfix too long",
        wrongEnd="CLR.ZCS: junk chars at the end: ",
    }
    local hueFtPat={
        '^(r*)(.*)',
        '^(y*)(.*)',
        '^(g*)(.*)',
        '^(c*)(.*)',
        '^(b*)(.*)',
        '^(m*)(.*)',
        '^(r*)(.*)',
        '^(y*)(.*)',
    }
    local lightnessPrefix={d6=1,d5=2,d4=3,d3=4,d2=5,d1=6,d0=7,l0=7,l1=8,l2=9,l3=10,l4=11,l5=12,l6=13}
    local chromaPostfix={sss=1,ss=2,s=3,_=4,S=5,SS=6,SSS=7}

    local lightness={}; for i=1,13 do lightness[i]=i/14 end
    local chromaRatio={}; for i=1,7 do chromaRatio[i]=(i/7)^.62 end
    local hueOffset=20/360
    local chromaMax={}
    for h=0,29 do
        local H=(h/30+hueOffset)%1
        local row={}
        for li=1,13 do
            local L=lightness[li]
            local lo,hi=0,.5
            for _=1,20 do
                local mid=(lo+hi)*.5
                local r,g,b=CLR.OKLCH(L,mid,H)
                local m1,m2=min(r,g,b),max(r,g,b)
                if m1>=0 and m2<=1 then lo=mid else hi=mid end
            end
            row[li]=lo
        end
        chromaMax[h+1]=row
    end


    CLR.W={1,1,1}
    CLR.K={0,0,0}
    ---Construct color with Zenitha Color System (ZCS), a compact color representation.
    ---
    ---How to construct the ZCS string (similar idea to HSL):
    ---1. Lightness prefix: `d6/d5/../d1/[empty]/l1/l2/../l6` for 1 to 13
    ---2. Hue: `R/Y/G/C/B/M` for standard 6 hues.
    ---3. Hue finetuning: add (up to 4) `r/y/g/c/b/m` after hue to shift slightly towards there (must be adjacent, shift 1/5 each).
    ---4. Chroma postfix: `sss/ss/s/[empty]/S/SS/SSS` for saturation 1 to 7
    ---5. Alpha postfix: `0/1/2/../9` for alpha 0 to 1 (or left empty)
    ---
    ---Examples:
    ---- `"Yrr"` = Orange
    ---- `"d1GcSS"` = dark(-1) Green, vivid(+2)
    ---- `"l2Ms"` = light(+2) Green, muted(-1)
    ---- `"d2"` = dark(-2) (grey)
    ---- `"K"` = black (special case) (= `"d7"`)
    ---- `"W"` = white (special case) (= `"l7"`)
    ---- `""` = (grey) (special case) (= `"d0"|"l0"`)
    ---@param str string
    ---@return number, number, number, number?
    ---@nodiscard
    function CLR.ZCS(str)
        local l=7 ---@type number  [1, 13]
        local c=4 ---@type number  [1, 7]
        local h ---@type number [0,29]
        local a
        local sec

        -- Lightness
        sec=match(str,'^([dl][0-6]?)')
        if sec then
            str=sub(str,#sec+1)
            if lightnessPrefix[sec] then
                l=lightnessPrefix[sec]
            else
                error(errMsg.wrongLight..sec)
            end
        end

        -- Hue
        sec,str=match(str,'^([RYGCBM]?)(.*)')
        if sec and #sec>0 then
            local hid=find('RYGCBMRY',sec,2) -- 2~7
            local finetune=0

            -- Hue finetuning
            sec,str=match(str,hueFtPat[hid-1])
            if #sec>0 then
                if #sec>4 then error(errMsg.hueFtTooLong) end
                finetune=- #sec
            else
                sec,str=match(str,hueFtPat[hid+1])
                if #sec>0 then
                    if #sec>4 then error(errMsg.hueFtTooLong) end
                    finetune=#sec
                end
            end
            h=((hid-1)*5+finetune)%30

            -- Chroma
            sec,str=match(str,'^([sS]*)(.*)')
            if #sec>0 then
                if chromaPostfix[sec] then
                    c=chromaPostfix[sec]
                else
                    error(errMsg.wrongChroma..sec)
                end
            end
        end

        -- Alpha
        sec,str=match(str,'^([0-9]?)(.*)')
        if #sec>0 then a=sec/9 end

        -- End parsing
        if #str>0 then error(errMsg.wrongEnd..str) end

        -- Calculate
        if h then
            return CLR.OKLCH(
                lightness[l],
                chromaRatio[c]*chromaMax[h+1][l],
                (h/30+hueOffset)%1,
                a
            )
        else
            local _l=lightness[l]
            return _l,_l,_l,a
        end
    end
    function CLR.ZCS_test(l,c,h,a)
        return CLR.OKLCH(
            lightness[l],
            chromaRatio[c]*chromaMax[h+1][l],
            (h/30+hueOffset)%1,
            a
        )
    end
end

setmetatable(CLR,{
    __call=function(_,str) return CLR.HEX(str) end,
    __index=function(self,str)
        if type(str)=='number' then error("CLR[num]: invalid numeric literal") end
        if type(str)~='string' then error("CLR[str]: invalid ZCS string") end
        assert(type(str)=='string')
        local clr={CLR.ZCS(str)}
        self[str]=clr
        return clr
    end,
})
---@cast CLR +fun(hexStr:string):number,number,number,number?

return CLR
