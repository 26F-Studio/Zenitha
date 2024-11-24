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

AE._meta={
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
local function wrap(rawStr) return setmetatable({'\27['..rawStr..'m',ae=true},AE._meta) end

AE.r=wrap'0' -- reset, not necessary tho
AE.b=wrap'1' -- bold, may be implemented as "colored", not really "bold"
AE.i=wrap'3' -- italic
AE.u=wrap'4' -- underline
AE.f=wrap'5' -- flashing, may not be implemented
AE.v=wrap'7' -- reverse foreground and background color
AE.s=wrap'9' -- strikethrough
AE.bi=wrap'1;3' -- bold and italic
AE.bu=wrap'1;4' -- bold and underline
AE.iu=wrap'3;4' -- italic and underline

-- All colors start with _

AE._R=wrap'91' -- Light Red
AE._G=wrap'92' -- Light Green
AE._Y=wrap'93' -- Light Yellow
AE._B=wrap'94' -- Light Blue
AE._M=wrap'95' -- Light Magenta
AE._C=wrap'96' -- Light Cyan
AE._r=wrap'31' -- Red
AE._g=wrap'32' -- Green
AE._y=wrap'33' -- Yellow
AE._b=wrap'34' -- Blue
AE._m=wrap'35' -- Magenta
AE._c=wrap'36' -- Cyan
AE._D=wrap'30' -- Dark (1/4 brightness)
AE._d=wrap'90' -- dark (2/4 brightness)
AE._l=wrap'37' -- light (3/4 brightness)
AE._L=wrap'97' -- Light (4/4 brightness)

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
