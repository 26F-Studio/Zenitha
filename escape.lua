-- Create ANSI escape code easier
--[[
Note:
    There's a Lua feature: calling function with only one string or table argument doesn't need parentheses
    Therefore, these are equivalent:
        print("hello")  &  print"hello"
        table.concat({"tech","mino"})  &  table.concant{"tech","mino"}
    To make the result code shorter, I'll use this in the example below.

Usage:
    AE.i"str" -- apply format to a string and reset
    AE.i.."str"..AE -- apply format then reset
    AE[520].."str" -- apply custom RGB5 color
    AE'b;i;u;f;d;_R'.."str" -- parse format

Example:
    print(AE.i"italic (call include reset)")
    print(AE.f..AE._R.."flashing, red ")
    print("not reset yet, "..AE'r;b;_G'.."reset, bold, green")
    print(AE[005]..AE.u.."underline blue "..AE.."manual reset")
    print(AE'd;_Y'.."reset, delete, yellow")
]]

local floor=math.floor
local find,match=string.find,string.match
local sub,gsub=string.sub,string.gsub

local AE={}

setmetatable(AE,{
    -- Shortcut call
    __call=function(_,params) return AE.parse(params) end,
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
    __concat=function(a,b) return a.ae and a[1]..b or a..b[1] end,
    __index=function(self,num) return '\27['..num..self[2] end,
    __call=function(self,n1,n2)
        if n2 then
            return '\27['..n1..","..n2..self[2]
        else
            return '\27['..n1..self[2]
        end
    end,
    __metatable=true,
}
local function wrap(rawStr) return setmetatable({'\27['..rawStr..'m',rawStr,ae=true},AE._meta) end

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
    __concat=function(a,b) return a.ae and a[1]..b or a..b[1] end,
    __call=function(self,str)
        if sub(str,-4)=='\27[0m' then
            return self[1]..str
        else
            return self[1]..str..'\27[0m'
        end
    end,
    __metatable=true,
}
local function mWrap(rawStr) return setmetatable({'\27['..rawStr..'m',ae=true},AE._metaM) end

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
AE._D=mWrap'30' -- Dark (1/4 brightness)
AE._d=mWrap'90' -- dark (2/4 brightness)
AE._l=mWrap'37' -- light (3/4 brightness)
AE._L=mWrap'97' -- Light (4/4 brightness)

local colorNum={
    _R='91',_G='92',_Y='93',_B='94',_M='95',_C='96',
    _r='31',_g='32',_y='33',_b='34',_m='35',_c='36',
}

---@param params? string leave blank to reset
---@return string
function AE.parse(params)
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

return AE
