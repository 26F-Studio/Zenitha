local MATH={} for k,v in next,math do MATH[k]=v end

MATH.tau=2*math.pi
MATH.phi=(1+math.sqrt(5))/2
MATH.inf=1/0
MATH.nan=0/0

local floor,ceil=math.floor,math.ceil
local sin,cos=math.sin,math.cos
local rnd=math.random
local exp,log=math.exp,math.log
local tau=MATH.tau

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
--- @return number
function MATH.roundUnit(n,u)
    return floor(n/u+.5)*u
end

--- Get a random boolean with specified chance, 50% if not given
--- @param chance? number @0~1
--- @return boolean
function MATH.roll(chance)
    return rnd()<(chance or .5)
end

--- Select random one between a and b (50% - 50%)
--- @param a any
--- @param b any
--- @return any
function MATH.coin(a,b)
    if rnd()<.5 then
        return a
    else
        return b
    end
end

--- Get a random real number between a and b
--- @param a number
--- @param b number
--- @return number
function MATH.rand(a,b)
    return a+rnd()*(b-a)
end

--- Get a random integer with specified frequency list
--- @param fList number[] positive numbers
--- @return integer
function MATH.randFreq(fList)
    local sum=TABLE.sum(fList)
    local r=rnd()*sum
    for i=1,#fList do
        r=r-fList[i]
        if r<0 then return i end
    end
    error("Frequency list should be a simple positive number list")
end

--- Get a random numbers in gaussian distribution (Box-Muller algorithm + stream buffer)
--- @return number
local randNormBF
function MATH.randNorm()
    if randNormBF then
        local res=randNormBF
        randNormBF=nil
        return res
    else
        local r=rnd()*tau
        local d=(-2*log(1-rnd())*tau)^.5
        randNormBF=sin(r)*d
        return cos(r)*d
    end
end

--- Restrict a number in a range
--- @param v number
--- @param low number
--- @param high number
--- @return number
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
--- @return number
function MATH.mix(v1,v2,ratio)
    return v1+(v2-v1)*ratio
end

--- Get ratio value (linear) of two numbers with a mixed value
--- @param v1 number
--- @param v2 number
--- @param value number
--- @return number
function MATH.imix(v1,v2,value)
    return (value-v1)/(v2-v1)
end

local clamp,mix=MATH.clamp,MATH.mix
--- Get mix value (linear) of a list of numbers with a ratio (clampped in [0,1])
--- @param list number[]
--- @param ratio number
--- @return number
function MATH.listMix(list,ratio)
    local t2=(#list-1)*clamp(ratio,0,1)+1
    return mix(list[floor(t2)],list[ceil(t2)],t2%1)
end

--- Specify a line pass (x1,y1) and (x2,y2), get the y value when x=t
--- Works similar to MATH.mix()
--- @param t number
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @return number
function MATH.interpolate(t,x1,y1,x2,y2)
    return y1+(t-x1)*(y2-y1)/(x2-x1)
end

--- Get a closer value from a to b with "exponential speed" k
---
--- Can be called multiple times, you'll get same result for same sum of k
--- @param a number
--- @param b number
--- @param k number
--- @return number
function MATH.expApproach(a,b,k)
    return b+(a-b)*exp(-k)
end

--- Get distance between two points
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @return number
function MATH.distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^.5
end

--- Check if a point is in a polygon
---
--- By Pedro Gimeno, donated to the public domain
--- @param x number
--- @param y number
--- @param poly number[] {x1,y1,x2,y2,...}
--- @param evenOddRule boolean
--- @return boolean
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
    else -- non-zero winding rule
        return wn~=0
    end
end

--- Get the greatest common divisor of two positive integers
--- @param a number
--- @param b number
--- @return number
function MATH.gcd(a,b)
    repeat
        a=a%b
        a,b=b,a
    until b<1
    return a
end

return MATH
