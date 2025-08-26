local MATH={}

for k,v in next,math do MATH[k]=v end

MATH.e=math.exp(1)
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

---Check if a number is NaN
---@param n number
---@return boolean
---@nodiscard
function MATH.isnan(n)
    return n~=n
end

---Get a number's sign
---@param a number
---@return -1 | 0 | 1
---@nodiscard
function MATH.sign(a)
    return a>0 and 1 or a<0 and -1 or 0
end

---Get absolute value of a 1D-3D vector
---@param x number
---@param y number
---@param z number
---@return number, number, number
---@nodiscard
---@overload fun(x:number): number
---@overload fun(x:number, y:number): number, number
function MATH.vecAbs(x,y,z)
    if z then
        return (x*x+y*y+z*z)^.5
    elseif y then
        return (x*x+y*y)^.5
    else
        return x>0 and x or -x
    end
end

---Get normalized 1D-3D vector
---@param x number
---@param y number
---@param z number
---@return number, number, number
---@nodiscard
---@overload fun(x:number): number
---@overload fun(x:number, y:number): number, number
function MATH.vecDir(x,y,z)
    if z then
        local r=(x*x+y*y+z*z)^.5
        if r==0 then return 0,0,0 end
        return x/r,y/r,z/r
    elseif y then
        local r=(x*x+y*y)^.5
        if r==0 then return 0,0 end
        return x/r,y/r
    else
        return x>0 and 1 or x<0 and -1 or 0
    end
end

---Sum table in [1-#]
---@param data number[]
---@param s? integer start pos (default 1)
---@param e? integer end pos (default #t)
---@return number
---@nodiscard
function MATH.sum(data,s,e)
    local sum=0
    for i=s or 1,e or #data do sum=sum+data[i] end
    return sum
end

---Sum table
---@param t Map<number>
---@return number
---@nodiscard
function MATH.sumAll(t)
    local sum=0
    for _,v in next,t do sum=sum+v end
    return sum
end

---STATISTIC
---@param data number[]
---@param s? integer start pos (default 1)
---@param e? integer end pos (default #t)
---@return number
---@nodiscard
function MATH.average(data,s,e)
    if not s then s=1 end
    if not e then e=#data end
    return MATH.sum(data,s,e)/(e-s+1)
end

---STATISTIC
---@param data number[]
---@param pow number 0: geometric mean, 1: arithmetic mean, -1: harmonic mean, etc.
function MATH.pAverage(data,pow)
    if pow==0 then
        local product=1
        for i=1,#data do
            product=product*data[i]
        end
        return product^(1/#data)
    else
        local sum=0
        for i=1,#data do
            sum=sum+data[i]^pow
        end
        return (sum/#data)^(1/pow)
    end
end

---STATISTIC
---@param data number[]
---@param s? integer start pos (default 1)
---@param e? integer end pos (default #t)
---@return number
---@nodiscard
function MATH.median(data,s,e)
    if not s then s=1 end
    if not e then e=#data end
    local t=TABLE.sub(data,s,e)
    table.sort(t)
    local n=#t/2
    return n%1==0 and (t[n]+t[n+1])/2 or t[n+.5]
end

---STATISTIC
---@param data number[]
---@return number
---@nodiscard
function MATH.totalSquareSum(data)
    local avg=MATH.average(data,1,#data)
    local sum=0
    for i=1,#data do
        sum=sum+(data[i]-avg)^2
    end
    return sum
end

function MATH.variance(data)       return MATH.totalSquareSum(data)/#data     end --[[STATISTIC]]--[[@param data number[] ]]--[[@return number]]--[[@nodiscard]]
function MATH.sampleVariance(data) return MATH.totalSquareSum(data)/(#data-1) end --[[STATISTIC]]--[[@param data number[] ]]--[[@return number]]--[[@nodiscard]]
function MATH.stdDev(data)         return MATH.variance(data)^.5              end --[[STATISTIC]]--[[@param data number[] ]]--[[@return number]]--[[@nodiscard]]
function MATH.sampleStdDev(data)   return MATH.sampleVariance(data)^.5        end --[[STATISTIC]]--[[@param data number[] ]]--[[@return number]]--[[@nodiscard]]

---Round a number to nearest integer (round up for .5)
---Will lower performance a bit, you should just use floor(n+0.5)
---@param n number
function MATH.round(n)
    return floor(n+.5)
end

---Round a number with specified unit
---@param n number
---@param u number
---@return number
---@nodiscard
function MATH.roundUnit(n,u)
    return floor(n/u+.5)*u
end

---Round a number with its fractional part as possibility
---@param n number
---@return integer
---@nodiscard
function MATH.roundRnd(n)
    return rnd()<n%1 and ceil(n) or floor(n)
end

---Round a number with specified unit
---@param x number
---@param base number
---@return number
---@nodiscard
function MATH.roundLog(x,base)
    return floor(log(x,base)+.5)
end

---Get a random boolean with specified chance, 50% if not given
---@param chance? number [0,1]
---@return boolean
---@nodiscard
function MATH.roll(chance)
    return rnd()<(chance or .5)
end

---Select random one between a and b (50% - 50%)
---@generic A, B
---@param head A
---@param tail B
---@return A | B
---@nodiscard
function MATH.coin(head,tail)
    if rnd()<.5 then
        return head
    else
        return tail
    end
end

---Get a random real number in [a, b)
---@param a number
---@param b number
---@return number
---@nodiscard
function MATH.rand(a,b)
    return a+rnd()*(b-a)
end

---Get a random value from a table
---@param map table
---@return integer
---@nodiscard
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

---Get a random integer with specified frequency list
---@param fList number[] positive numbers
---@return integer
---@nodiscard
function MATH.randFreq(fList)
    local sum=MATH.sum(fList)
    local r=rnd()*sum
    for i=1,#fList do
        r=r-fList[i]
        if r<0 then return i end
    end
    error("MATH.randFreq(fList): Need simple positive number list")
end

---Get a random key with specified frequency table
---@generic K
---@param fList {[K]:number} positive numbers
---@return K
---@nodiscard
function MATH.randFreqAll(fList)
    local sum=MATH.sumAll(fList)
    local r=rnd()*sum
    for k,v in next,fList do
        r=r-v
        if r<0 then return k end
    end
    error("MATH.randFreqAll(fList): Need simple positive number list")
end

local randNormBF
---Get a random numbers in gaussian distribution (Box-Muller algorithm + stream buffer)  
---Mean = 0, Standard Deviation = 1
---@return number
---@nodiscard
function MATH.randNorm()
    if randNormBF then
        local res=randNormBF
        randNormBF=nil
        return res
    else
        local r=rnd()*tau
        local d=(-2*log(1-rnd()))^.5
        randNormBF=sin(r)*d
        return cos(r)*d
    end
end

---Find which interval the number is in
---### Example
---```
---MATH.selectFreq(50,{10,20,30,40}) -- 3, because 50 will drop into the 3rd interval [30,60)
---```
---@param v number
---@param fList number[] positive numbers
---@nodiscard
function MATH.selectFreq(v,fList)
    for i=1,#fList do
        v=v-fList[i]
        if v<0 then return i end
    end
    error("WTF")
end

---Same to MATH.selectFreq but with any table. Notice: keys are not in order
---@param v number
---@param fList Map<number> positive numbers
---@nodiscard
function MATH.selectFreqAll(v,fList)
    for k,f in next,fList do
        v=v-f
        if v<0 then return k end
    end
    error("WTF")
end

---Restrict a number in a range
---@param v number
---@param low number
---@param high number
---@return number
---@nodiscard
function MATH.clamp(v,low,high)
    return v<=low and low or v>=high and high or v
end

---Check if a number is in a range
---@param v number
---@param low number
---@param high number
---@return boolean
---@nodiscard
function MATH.between(v,low,high)
    return v>=low and v<=high
end

---Get mix value (linear) of two numbers with a ratio (not clamped)
---@param v1 number
---@param v2 number
---@param t number
---@return number
---@nodiscard
function MATH.lerp(v1,v2,t)
    return v1+(v2-v1)*t
end

---Inverse function of MATH.lerp (not clamped)
---@param v1 number
---@param v2 number MUSTN'T equal to v1
---@param value number
---@return number
---@nodiscard
function MATH.iLerp(v1,v2,value)
    return (value-v1)/(v2-v1)
end

---Similar to MATH.lerp (clamped)
---@param v1 number
---@param v2 number
---@param t number
---@return number
---@nodiscard
function MATH.cLerp(v1,v2,t)
    return
        t<=0 and v1 or
        t>=1 and v2 or
        v1+(v2-v1)*t
end

---Inverse function of MATH.cLerp (clamped)
---@param v1 number
---@param v2 number MUSTN'T equal to v1
---@param value number
---@return number
---@nodiscard
function MATH.icLerp(v1,v2,value)
    return v1<v2 and (
        value<=v1 and 0 or
        value>=v2 and 1 or
        (value-v1)/(v2-v1)
    ) or (
        value>=v1 and 0 or
        value<=v2 and 1 or
        (value-v1)/(v2-v1)
    )
end

local clamp,lerp=MATH.clamp,MATH.lerp

---Get mix value (linear) of a list of numbers with a ratio (clamped)
---@param list number[]
---@param t number
---@return number
---@nodiscard
function MATH.lLerp(list,t)
    local index=(#list-1)*clamp(t,0,1)+1
    return lerp(list[floor(index)],list[ceil(index)],index%1)
end

---Inverse function of MATH.lLerp (clamped)
---@param list number[] need #list>2 and STRICTLY ascending, otherwise result is undefined
---@param value number
---@return number
---@nodiscard
function MATH.ilLerp(list,value)
    local i,j=1,#list
    if value<=list[1] then return 0 end
    if value>=list[j] then return 1 end
    while j-i>1 do
        local mid=floor((i+j)/2)
        if value<list[mid] then
            j=mid
        else
            i=mid
        end
    end
    local k=MATH.iLerp(list[i],list[j],value)
    return (i-1+k)/(#list-1)
end

---Specify a line pass (x1,y1) and (x2,y2), got the y value when x=t
---
---Same to the combination of MATH.iLerp and MATH.lerp
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param t number
---@return number
---@nodiscard
function MATH.interpolate(x1,y1,x2,y2,t)
    return y1+(t-x1)*(y2-y1)/(x2-x1)
end

---Same to MATH.interpolate but clamped
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param t number
---@return number
---@nodiscard
function MATH.clampInterpolate(x1,y1,x2,y2,t)
    return x1<x2 and (
        t<=x1 and y1 or
        t>=x2 and y2 or
        y1+(t-x1)*(y2-y1)/(x2-x1)
    ) or (
        t<=x2 and y2 or
        t>=x1 and y1 or
        y1+(t-x1)*(y2-y1)/(x2-x1)
    )
end

---Get a closer value from a to b with difference d
---
---Automatically choose +d or -d, then clamped at b
---@param a number
---@param b number
---@param d number
---@return number
---@nodiscard
function MATH.linearApproach(a,b,d)
    return b>a and min(a+d,b) or max(a-d,b)
end

---Get a closer value from a to b with "exponential speed" k
---
---Can be called multiple times, you'll get same result for same sum of k
---@param a number
---@param b number
---@param k number
---@return number
---@nodiscard
function MATH.expApproach(a,b,k)
    return b+(a-b)*2.718281828459045^-k
end

---Get distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
---@nodiscard
function MATH.distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^.5
end

---Get Minkowski distance between two 2D points
---@param p 0 | number 0 for Chebyshev distance
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@nodiscard
function MATH.mDist2(p,x1,y1,x2,y2)
    return
        p==0 and max(abs(x1-x2),abs(y1-y2)) or
        p==1 and abs(x1-x2)+abs(y1-y2) or
        p==2 and ((x1-x2)^2+(y1-y2)^2)^.5 or
        (abs(x1-x2)^p+abs(y1-y2)^p)^(1/p)
end

---Get Minkowski distance between two 3D points
---@param p 0 | number 0 for Chebyshev distance
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@nodiscard
function MATH.mDist3(p,x1,y1,z1,x2,y2,z2)
    return
        p==0 and max(abs(x1-x2),abs(y1-y2),abs(z1-z2)) or
        p==1 and abs(x1-x2)+abs(y1-y2)+abs(z1-z2) or
        p==2 and ((x1-x2)^2+(y1-y2)^2+(z1-z2)^2)^.5 or
        (abs(x1-x2)^p+abs(y1-y2)^p+abs(z1-z2)^p)^(1/p)
end

---Get Minkowski distance between two vectors
---@param p 0 | number 0 for Chebyshev distance
---@param v1 number[]
---@param v2 number[]
---@nodiscard
function MATH.mDistV(p,v1,v2)
    assert(#v1==#v2,"MATH.mDistV(p,v1,v2): Need #v1==#v2")
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

---Check if a point is in a polygon
---
---By Pedro Gimeno, donated to the public domain
---@param x number
---@param y number
---@param poly number[] {x1,y1,x2,y2,...}
---@param evenOddRule boolean
---@return boolean
---@nodiscard
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

---Get the greatest common divisor of two positive integers
---@param a number
---@param b number
---@return number
---@nodiscard
function MATH.gcd(a,b)
    repeat
        a=a%b
        a,b=b,a
    until b<1
    return a
end

---Calculate the area of a polygon with the Shoelace formula
---@param points number[] {x1,y1,x2,y2,...}
function MATH.polygonArea(points)
    local area=0
    local len=#points
    local x1,y1,x2,y2
    x2,y2=points[len-1],points[len]
    for i=1,len,2 do
        x1,y1=x2,y2
        x2,y2=points[i],points[i+1]
        area=area+x1*y2-x2*y1
    end
    return abs(area/2)
end

return MATH
