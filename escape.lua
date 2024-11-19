local floor=math.floor
local find,match=string.find,string.match
local sub,gsub=string.sub,string.gsub

local AE={
    r='\27[0m',
    b='\27[0;1m',-- bold may be implemented as "colored", not really bold
    i='\27[0;3m',
    u='\27[0;4m',
    bi='\27[0;1;3m',
    bu='\27[0;1;4m',
    iu='\27[0;3;4m',
    biu='\27[0;1;3;4m',
    f='\27[0;5m',
    d='\27[0;9m',
    _R='\27[91m',_G='\27[92m',_Y='\27[93m',_B='\27[94m',_M='\27[95m',_C='\27[96m',
    _r='\27[31m',_g='\27[32m',_y='\27[33m',_b='\27[34m',_m='\27[35m',_c='\27[36m',
}

local colorNum={
    _R='91',_G='92',_Y='93',_B='94',_M='95',_C='96',
    _r='31',_g='32',_y='33',_b='34',_m='35',_c='36',
}

---ANSI escape code shortcut
---@param params? string leave blank to reset
---@return string
function AE.parse(params)
    if not params then return AE.r end
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
    __call=function(_,params) return AE.parse(params) end,
    __concat=function(a,b) return AE==b and a..'\27[0m' or '\27[0m'..b end,
    __index=function(_,k)
        if type(k)=='number' then
            return '\27[38;5;'..(16+floor(k/100)*36+floor(k/10)%10*6+k%10)..'m'
        end
    end,
})

---@cast AE +fun(params:string):string
---@cast AE +string

return AE
