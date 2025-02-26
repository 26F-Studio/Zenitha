--[[
## ANSI Escape module
***Create ANSI Escape Code Easier***

Lua has a feature: calling function with only one string or table argument doesn't need parentheses:  
`print("hello")` **==** `print"hello"`  
`table.concat({"tech","mino"})` **==** `table.concant{"tech","mino"}`  
I'll use this feature below to make final result cleaner.

## Usage:

### Formats - `AE.xxx`
    AE.xxx(str) -- Apply format to string, with reset
    AE.xxx.. -- Apply format

### Colors - `AE._x`
    AE._x(str) -- Apply color to string, with reset
    AE._x.. -- Apply color

### Control - `AE.XXX`
    ..AE.XXX.. -- Execute with default param
    AE.XXX[param] -- Execute with single param
    AE.XXX(...) -- Execute with custom params

### Main - `AE`
    ..AE -- Reset
    AE(str) -- Apply multiple formats (splitted by ";")
    AE[num] -- Set RGB5 color

### Example
```
print(AE.i"italic") -- Auto set & reset format
print(AE.f..AE._R.."flashing, red ") -- Manually set format
print("not reset yet, "..AE'r;b;_G'.."reset, bold, green")
print(AE[005]..AE.u.."underline blue "..AE.."manual reset")
print(AE'd;_Y'.."reset, delete, yellow") -- Parse format
```
]]
---@diagnostic disable-next-line
local _hoverMouseHereToRead

local AE={}

local type=type
local floor=math.floor
local find,match=string.find,string.match
local sub,gsub=string.sub,string.gsub

local colorNum={
    _R='91',_G='92',_Y='93',_B='94',_M='95',_C='96',
    _r='31',_g='32',_y='33',_b='34',_m='35',_c='36',
}
---@param params? string leave blank to reset
---@return string
local function _parse(params)
    if not params then return '' end
    if find(params,'_') then
        while true do
            local c=match(params,'_%d%d%d')
            if not c then break end
            params=gsub(params,c,'38;5;'..(16+c:sub(2,2)*36+c:sub(3,3)*6+c:sub(4,4)),1)
        end
        while true do
            local c=match(params,'_[rgbcymRGBCYM]')
            if not c then break end
            params=gsub(params,c,colorNum[c])
        end
    end
    if find(params,'[ruf]') then params=gsub(gsub(gsub(params,'r','0'),'u','4'),'f','5') end
    if find(params,'[bid]') then params=gsub(gsub(gsub(params,'b','1'),'i','3'),'d','9') end
    return '\27['..params..'m'
end

setmetatable(AE,{
    -- Shortcut call
    __call=function(_,params) return _parse(params) end,
    -- Shortcut string
    __concat=function(a,b) return AE==b and a..'\27[0m' or '\27[0m'..b end,
    -- Shortcut RGB5 color
    __index=function(_,k)
        if type(k)=='number' then
            return '\27[38;5;'..(16+floor(k/100)*36+floor(k/10)%10*6+k%10)..'m'
        end
    end,
})
---@cast AE +fun(params:string): string
---@cast AE +string

-- metatable for cursor control
AE._meta={
    __concat=function(a,b) return type(a)=='table' and a.ae and a.data..b or a..b.data end,
    __index=function(self,num) return '\27['..num..self.raw end,
    __call=function(self,n1,n2)
        return '\27['..n1..(n2 and ","..n2 or "")..self.raw
    end,
    __metatable=true,
}
---@return {data:string, raw:string, ae:true} | string | Map<string> | fun(str:string, str2:string?): string
local function wrap(rawStr) return setmetatable({data='\27['..rawStr,raw=rawStr,ae=true},AE._meta) end

AE.U=wrap'A' -- Move cursor <N=1> up
AE.D=wrap'B' -- Move cursor <N=1> down
AE.R=wrap'C' -- Move cursor <N=1> right
AE.L=wrap'D' -- Move cursor <N=1> left
AE.NL=wrap'E' -- Move cursor to next <N=1> line
AE.PL=wrap'F' -- Move cursor to previous <N=1> line
AE.POS=wrap'H' -- Move cursor to position <N1=1>, <N2=1>
AE.ED=wrap'J' -- Clear screen (<N=0>: 0 = from cursor to end, 1 = from cursor to start, 2 = all, 3 = all and buffer)
AE.EL=wrap'K' -- Clear line (<N=0>: 0 = to line end, 1 = to line start, 2 = all)
AE.SAVE=wrap's' -- Save cursor position (may not implemented, private sequences)
AE.LOAD=wrap'u' -- Load cursor position (may not implemented, private sequences)

-- metatable for rendering
AE._metaM={
    __concat=function(a,b) return type(a)=='table' and a.ae and a.data..b or a..b.data end,
    __call=function(self,str)
        if sub(str,-4)=='\27[0m' then
            return self.data..str
        else
            return self.data..str..'\27[0m'
        end
    end,
    __metatable=true,
}
---@return {data:string, raw:string, ae:true} | string | fun(str:string): string
local function mWrap(rawStr) return setmetatable({data='\27['..rawStr..'m',raw=rawStr,ae=true},AE._metaM) end

AE.r=mWrap'0' -- reset, not necessary tho
AE.b=mWrap'1' -- bold, may be implemented as "colored", not really "bold"
AE.i=mWrap'3' -- italic
AE.u=mWrap'4' -- underline
AE.f=mWrap'5' -- flashing, may not be implemented
AE.v=mWrap'7' -- reverse foreground and background color
AE.s=mWrap'9' -- strikethrough
AE.bi=mWrap'1;3' -- bold and italic
AE.bu=mWrap'1;4' -- bold and underline
AE.iu=mWrap'3;4' -- italic and underline

-- All colors start with _

AE._R=mWrap'91' -- Light Red
AE._G=mWrap'92' -- Light Green
AE._Y=mWrap'93' -- Light Yellow
AE._B=mWrap'94' -- Light Blue
AE._M=mWrap'95' -- Light Magenta
AE._C=mWrap'96' -- Light Cyan
AE._r=mWrap'31' -- Red
AE._g=mWrap'32' -- Green
AE._y=mWrap'33' -- Yellow
AE._b=mWrap'34' -- Blue
AE._m=mWrap'35' -- Magenta
AE._c=mWrap'36' -- Cyan
AE._D=mWrap'30' -- Dark (0% brightness)
AE._d=mWrap'90' -- dark (33% brightness)
AE._l=mWrap'37' -- light (66% brightness)
AE._L=mWrap'97' -- Light (100% brightness)

AE.parse=_parse

return AE
