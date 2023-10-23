local MATH={}
for k,v in next,math do MATH[k]=v end

MATH.tau=2*math.pi
MATH.phi=(1+math.sqrt(5))/2
MATH.inf=1/0
MATH.nan=0/0

local floor,ceil=math.floor,math.ceil
local sin,cos=math.sin,math.cos
local max,min=math.max,math.min
local rnd=math.random
local exp,log=math.exp,math.log
local abs=math.abs
local tau=MATH.tau

--- Check if a number is NaN
--- @param n number
--- @return boolean
function MATH.isnan(n)
    return n~=n
end

--- Get a number's sign
--- @param a number
--- @return -1|0|1
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
--- @param chance? number 0~1
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

--- Get a random real number in [a, b)
--- @param a number
--- @param b number
--- @return number
function MATH.rand(a,b)
    return a+rnd()*(b-a)
end

--- Get a random value from a table
--- @param map table
--- @return integer
function MATH.randFrom(map)
    local count=0
    for _ in next,map do
        count=count+1
    end
    local r=rnd()*count
    for _,v in next,map do
        r=r-1
        if r<=0 then return v end
    end
    error("WTF")
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

--- Get a random key with specified frequency table
--- @param fList table<any, number> positive numbers
--- @return integer
function MATH.randFreqAll(fList)
    local sum=TABLE.sumAll(fList)
    local r=rnd()*sum
    for k,v in next,fList do
        r=r-v
        if r<0 then return k end
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

--- Get mix value (linear) of two numbers with a ratio (not clamped)
--- @param v1 number
--- @param v2 number
--- @param ratio number 0~1 at most time
--- @return number
function MATH.lerp(v1,v2,ratio)
    return v1+(v2-v1)*ratio
end

--- Inverse function of MATH.lerp (not clamped)
--- @param v1 number
--- @param v2 number
--- @param value number
--- @return number
function MATH.iLerp(v1,v2,value)
    return (value-v1)/(v2-v1)
end

--- Similar to MATH.lerp (clamped)
--- @param v1 number
--- @param v2 number
--- @param ratio number 0~1 at most time
--- @return number
function MATH.cLerp(v1,v2,ratio)
    return
        ratio<=v1 and 0 or
        ratio>=v2 and 1 or
        v1+(v2-v1)*ratio
end

--- Inverse function of MATH.cLerp (clamped)
--- @param v1 number
--- @param v2 number
--- @param value number
--- @return number
function MATH.icLerp(v1,v2,value)
    return (value-v1)/(v2-v1)
end

local clamp,lerp=MATH.clamp,MATH.lerp

--- Get mix value (linear) of a list of numbers with a ratio (clampped in [0,1])
--- @param list number[]
--- @param ratio number
--- @return number
function MATH.listLerp(list,ratio)
    local index=(#list-1)*clamp(ratio,0,1)+1
    return lerp(list[floor(index)],list[ceil(index)],index%1)
end

--- Specify a line pass (x1,y1) and (x2,y2), get the y value when x=t
---
--- Same to the combination of MATH.iLerp and MATH.lerp
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @param ratio number
--- @return number
function MATH.interpolate(x1,y1,x2,y2,ratio)
    return y1+(ratio-x1)*(y2-y1)/(x2-x1)
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

--- Get Minkowski distance between two 2D points
--- @param p 0|number 0 for Chebyshev distance
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
function MATH.mDist2(p,x1,y1,x2,y2)
    return
        p==0 and max(abs(x1-x2),abs(y1-y2)) or
        p==1 and abs(x1-x2)+abs(y1-y2) or
        p==2 and ((x1-x2)^2+(y1-y2)^2)^.5 or
        (abs(x1-x2)^p+abs(y1-y2)^p)^(1/p)
end

--- Get Minkowski distance between two 3D points
--- @param p 0|number 0 for Chebyshev distance
--- @param x1 number
--- @param y1 number
--- @param z1 number
--- @param x2 number
--- @param y2 number
--- @param z2 number
function MATH.mDist3(p,x1,y1,z1,x2,y2,z2)
    return
        p==0 and max(abs(x1-x2),abs(y1-y2),abs(z1-z2)) or
        p==1 and abs(x1-x2)+abs(y1-y2)+abs(z1-z2) or
        p==2 and ((x1-x2)^2+(y1-y2)^2+(z1-z2)^2)^.5 or
        (abs(x1-x2)^p+abs(y1-y2)^p+abs(z1-z2)^p)^(1/p)
end

--- Get Minkowski distance between two vectors
--- @param p 0|number 0 for Chebyshev distance
--- @param v1 number[]
--- @param v2 number[]
function MATH.mDistV(p,v1,v2)
    assert(#v1==#v2,"Vector length not match")
    if p==0 then
        local maxD=0
        for i=1,#v1 do
            maxD=max(maxD,abs(v1[i]-v2[i]))
        end
        return maxD
    else
        local sum=0
        for i=1,#v1 do
            sum=sum+abs(v1[i]-v2[i])^p
        end
        return sum^(1/p)
    end
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
