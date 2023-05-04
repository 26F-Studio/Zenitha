local MATH={} for k,v in next,math do MATH[k]=v end

local floor,ceil=math.floor,math.ceil
local rnd=math.random
local exp=math.exp

MATH.tau=2*math.pi
MATH.phi=(1+math.sqrt(5))/2
MATH.inf=1/0
MATH.nan=0/0

--- Check if a number is NaN
--- @param n number
--- @return boolean
function MATH.isnan(n)
    return n~=n
end

--- Get a number's sign
--- @param a number
--- @return number @-1 or 0 or 1
function MATH.sign(a)
    return a>0 and 1 or a<0 and -1 or 0
end

--- Round a number with specified unit
--- @param n number
--- @param u number
function MATH.roundUnit(n,u)
    return floor(n/u+.5)*u
end

--- Get a random boolean with specified chance, 50% if not given
--- @param chance? number @0~1
function MATH.roll(chance)
    return rnd()<(chance or .5)
end

--- Select random one between a and b (50% - 50%)
--- @param a any
--- @param b any
function MATH.coin(a,b)
    if rnd()<.5 then
        return a
    else
        return b
    end
end


--- Restrict a number in a range
--- @param v number
--- @param low number
--- @param high number
function MATH.clamp(v,low,high)
    if v<=low then
        return low
    elseif v>=high then
        return high
    else
        return v
    end
end

--- Get mix value (linear) of two numbers with a ratio
--- @param v1 number
--- @param v2 number
--- @param ratio number @0~1 at most time
function MATH.mix(v1,v2,ratio)
    return v1+(v2-v1)*ratio
end

local clamp,mix=MATH.clamp,MATH.mix
--- Get mix value (linear) of a list of numbers with a ratio (clampped in [0,1])
--- @param list number[]
--- @param ratio number
function MATH.listMix(list,ratio)
    local t2=(#list-1)*clamp(ratio,0,1)+1
    return mix(list[floor(t2)],list[ceil(t2)],t2%1)
end

--- Specify a line pass (x1,y1) and (x2,y2), get the y value when x=t
--- Works similar to MATH.mix()
function MATH.interpolate(t,x1,y1,x2,y2)
    return y1+(t-x1)*(y2-y1)/(x2-x1)
end

--- Get a closer value from a to b with "exponential speed" k
---
--- Can be called multiple times, you'll get same result for same sum of k
--- @param a number
--- @param b number
--- @param k number
function MATH.expApproach(a,b,k)
    return b+(a-b)*exp(-k)
end

--- Get distance between two points
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
function MATH.distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^.5
end

--- Check if a point is in a polygon
---
--- By Pedro Gimeno,donated to the public domain
function MATH.pointInPolygon(x,y,poly,evenOddRule)
    local x1,y1,x2,y2
    local len=#poly
    x2,y2=poly[len-1],poly[len]
    local wn=0
    for idx=1,len,2 do
        x1,y1=x2,y2
        x2,y2=poly[idx],poly[idx+1]
        if y1>y then
            if y2<=y and (x1-x)*(y2-y)<(x2-x)*(y1-y) then
                wn=wn+1
            end
        else
            if y2>y and (x1-x)*(y2-y)>(x2-x)*(y1-y) then
                wn=wn-1
            end
        end
    end
    if evenOddRule then
        return wn%2~=0
    else-- non-zero winding rule
        return wn~=0
    end
end

return MATH
