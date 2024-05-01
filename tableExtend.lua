local rnd,floor=math.random,math.floor
local find,gsub=string.find,string.gsub
local rem=table.remove
local next,type,select=next,type,select
local TABLE={}

for k,v in next,table do TABLE[k]=v end

---Get a new filled table
---@param val any value to fill
---@param count number how many elements
---@return any[]
function TABLE.new(val,count)
    local L={}
    for i=1,count do
        L[i]=val
    end
    return L
end

---Get a new table with __index metatable
---@param indexFunc fun(self:table, key:any):any
---@return table
function TABLE.newPool(indexFunc)
    return setmetatable({},{
        __call=function(self,k) return self[k] end,
        __index=indexFunc,
    })
end

---Make a table to be able to auto filled from a source
---@param t table
---@param source table
function TABLE.setAutoFill(t,source)
    setmetatable(t,{
        __index=function(self,k)
            self[k]=source[k]
            return source[k]
        end
    })
end

---Get a copy of [1~#] elements
---@param org any[] original table
---@param depth? number how many layers will be recreate, default to inf
---@return any[]
function TABLE.shift(org,depth)
    if not depth then depth=1e99 end
    local L={}
    for i=1,#org do
        if type(org[i])=='table' and depth>0 then
            L[i]=TABLE.shift(org[i],depth-1)
        else
            L[i]=org[i]
        end
    end
    return L
end

---Connect [1~#] elements of new to the end of org
---@param org any[] original list
---@param new any[] new list
---@return any[] #org with new data
function TABLE.connect(org,new)
    local l0=#org
    for i=1,#new do
        org[l0+i]=new[i]
    end
    return org
end

---Get a table of two lists connected
---@param L1 any[] list 1
---@param L2 any[] list 2
---@return any[]
function TABLE.combine(L1,L2)
    local l={}
    local l0=#L1
    for i=1,l0 do l[i]=L1[i] end
    for i=1,#L2 do l[l0+i]=L2[i] end
    return l
end

---Get a full copy of org, depth = how many layers will be recreate, default to inf
---@param org table original table
---@param depth? number how many layers will be recreate, default to inf
---@return table
function TABLE.copy(org,depth)
    if not depth then depth=1e99 end
    local L={}
    for k,v in next,org do
        if type(v)=='table' and depth>0 then
            L[k]=TABLE.copy(v,depth-1)
        else
            L[k]=v
        end
    end
    return L
end

---For all things in new, push to old
---@param new table
---@param old table
---@param depth? number how many sub-table will be covered, default to inf
function TABLE.cover(new,old,depth)
    if not depth then depth=1e99 end
    for k,v in next,new do
        if type(v)=='table' and type(old[k])=='table' and depth>0 then
            TABLE.cover(v,old[k],depth-1)
        else
            old[k]=v
        end
    end
end

---For all things in org, delete them if it's in sub
---@param org table original table
---@param sub table
function TABLE.subtract(org,sub)
    for _,v in next,sub do
        while true do
            local p=TABLE.findAll(org,v)
            if p then
                rem(org,p)
            else
                break
            end
        end
    end
end

---For all things in new if same type in old, push to old
---@param new table
---@param old table
function TABLE.update(new,old)
    for k,v in next,new do
        if type(v)==type(old[k]) then
            if type(v)=='table' then
                TABLE.update(v,old[k])
            else
                old[k]=v
            end
        end
    end
end

---For all things in new if no val in old, push to old
---@param new table
---@param old table
function TABLE.complete(new,old)
    for k,v in next,new do
        if type(v)=='table' then
            if old[k]==nil then old[k]={} end
            TABLE.complete(v,old[k])
        elseif old[k]==nil then
            old[k]=v
        end
    end
end

--------------------------------------------------------------

---Pop & return random [1~#] of table
---@param t any[]
---@return any
function TABLE.popRandom(t)
    local l=#t
    if l>0 then
        local r=rnd(l)
        r,t[r]=t[r],t[l]
        t[l]=nil
        return r
    end
end

---Remove [1~#] of a table
---@param t table
function TABLE.cut(t)
    for i=1,#t do
        t[i]=nil
    end
end

---Clear table
---@param t table
function TABLE.clear(t)
    for k in next,t do
        t[k]=nil
    end
end

---Remove duplicated value of [1~#]
---@param org any[]
function TABLE.remDup(org)
    local cache={}
    local len=#org
    local i=1
    while i<=len do
        if cache[org[i]] then
            rem(org,i)
            len=len-1
        else
            cache[org[i]]=true
            i=i+1
        end
    end
end

---Remove duplicated value
---@param org table
function TABLE.remDupAll(org)
    local cache={}
    for k,v in next,org do
        if cache[v] then
            org[k]=nil
        else
            cache[v]=true
        end
    end
end

---Reverse [1~#]
---@param org any[]
function TABLE.reverse(org)
    local l=#org
    for i=1,floor(l/2) do
        org[i],org[l+1-i]=org[l+1-i],org[i]
    end
end

---Get a rotated copy of a matrix
---@param matrix any[][]
---@return any[][]
function TABLE.rotate(matrix,dir)
    local icb={}
    if dir=='R' then -- Rotate CW
        for y=1,#matrix[1] do
            icb[y]={}
            for x=1,#matrix do
                icb[y][x]=matrix[x][#matrix[1]-y+1]
            end
        end
    elseif dir=='L' then -- Rotate CCW
        for y=1,#matrix[1] do
            icb[y]={}
            for x=1,#matrix do
                icb[y][x]=matrix[#matrix-x+1][y]
            end
        end
    elseif dir=='F' then -- Rotate 180 degree
        for y=1,#matrix do
            icb[y]={}
            for x=1,#matrix[1] do
                icb[y][x]=matrix[#matrix-y+1][#matrix[1]-x+1]
            end
        end
    elseif dir=='0' then -- Not rotate, just simple copy
        for y=1,#matrix do
            icb[y]={}
            for x=1,#matrix[1] do
                icb[y][x]=matrix[y][x]
            end
        end
    else
        errorf("TABLE.rotate(matrix,dir): Invalid rotate direction '%s'",dir)
    end
    return icb
end

--------------------------------------------------------------

---Check if two list have same elements
---@param a any[]
---@param b any[]
---@return boolean
function TABLE.compare(a,b)
    if #a~=#b then return false end
    if a==b then return true end
    for i=1,#a do
        if a[i]~=b[i] then return false end
    end
    return true
end

---Check if two table have same elements
---@param a table
---@param b table
---@return boolean
function TABLE.equal(a,b)
    if #a~=#b then return false end
    if a==b then return true end
    for k,v in next,a do
        if b[k]~=v then return false end
    end
    return true
end

--------------------------------------------------------------

---Find value in [1~#], like string.find
---@param t any[]
---@param val any
---@param start? number
---@return number|nil
function TABLE.find(t,val,start)
    for i=start or 1,#t do if t[i]==val then return i end end
end

---TABLE.find, but for ordered list only
---@param t any[]
---@param val any
---@return number|nil
function TABLE.findOrdered(t,val)
    if val<t[1] or val>t[#t] then return end
    local i,j=1,#t
    while i<=j do
        local m=floor((i+j)/2)
        if t[m]>val then
            j=m-1
        elseif t[m]<val then
            i=m+1
        else
            return m
        end
    end
end

---Find value in whole table
---@param t table
---@param val any
---@return any
function TABLE.findAll(t,val)
    for k,v in next,t do if v==val then return k end end
end

---Replace value in [1~#], like string.gsub
---@param t any[]
---@param v_old any
---@param v_new any
---@param start? number
function TABLE.replace(t,v_old,v_new,start)
    for i=start or 1,#t do
        if t[i]==v_old then
            t[i]=v_new
        end
    end
end

---Replace value in whole table
---@param t table
---@param v_old any
---@param v_new any
function TABLE.replaceAll(t,v_old,v_new)
    for k,v in next,t do
        if v==v_old then
            t[k]=v_new
        end
    end
end

---Count value in [1~#]
---@param t any[]
---@param val any
---@return number
function TABLE.count(t,val)
    local count=0
    for i=1,#t do
        if t[i]==val then
            count=count+1
        end
    end
    return count
end

---Count value
---@param t table
---@param val any
---@return number
function TABLE.countAll(t,val)
    local count=0
    for _,v in next,t do
        if v==val then
            count=count+1
        end
    end
    return count
end

---Sum table in [1~#]
---@param t number[]
---@return number
function TABLE.sum(t)
    local s=0
    for i=1,#t do
        s=s+t[i]
    end
    return s
end

---Sum table
---@param t Map<number>
---@return number
function TABLE.sumAll(t)
    local s=0
    for _,v in next,t do s=s+v end
    return s
end

---Return next value of [1~#] (by value)
---@param t any[]
---@param val any
---@return any
function TABLE.next(t,val)
    for i=1,#t do if t[i]==val then return t[i%#t+1] end end
end

---Get element count of table
---@param t table
---@return number
function TABLE.getSize(t)
    local size=0
    for _ in next,t do size=size+1 end
    return size
end

---Re-index string value of a table
---@param org table
function TABLE.reIndex(org)
    for k,v in next,org do
        if type(v)=='string' then
            org[k]=org[v]
        end
    end
end

--------------------------------------------------------------

---Return a function that return a value of table
---@param t table
---@param k any
---@return fun():any
function TABLE.func_getVal(t,k)
    return function() return t[k] end
end

---Return a function that reverse a value of table
---@param t table
---@param k any
---@return fun()
function TABLE.func_revVal(t,k)
    return function() t[k]=not t[k] end
end

---Return a function that set a value of table
---@param t table
---@param k any
---@return fun(v:any)
function TABLE.func_setVal(t,k)
    return function(v) t[k]=v end
end

--------------------------------------------------------------

do -- function TABLE.dumpDeflate(t,depth)
    local function dump(L,t,lim)
        local s='{'
        local count=1
        for k,v in next,L do
            -- Key part
            local T=type(k)
            if T=='number' then
                if k==count then
                    k='' -- List part, no brackets needed
                    count=count+1
                else
                    k='['..k..']='
                end
            elseif T=='string' then
                if find(k,'[^0-9a-zA-Z_]') then
                    k='["'..gsub(k,'"','\\"')..'"]='
                else
                    k=k..'='
                end
            elseif T=='boolean' then
                k='['..k..']='
            else
                k='["*'..tostring(k)..'"]='
            end

            -- Value part
            T=type(v)
            if T=='number' or T=='boolean' then
                v=tostring(v)
            elseif T=='string' then
                v='"'..gsub(v,'"','\\"')..'"'
            elseif T=='table' then
                if t>=lim then v=tostring(v) else v=dump(v,t+1,lim) end
            else
                v='*'..tostring(v)
            end
            s=s..k..v..','
        end
        return s..'}'
    end
    ---Dump a simple lua table (no whitespaces)
    ---@param t table
    ---@param depth? number how many layers will be dumped, default to inf
    ---@return string
    function TABLE.dumpDeflate(t,depth)
        assert(type(t)=='table',"Only table can be dumped")
        return dump(t,1,depth or 1e99)
    end
end

do -- function TABLE.dump(t,depth)
    local tabs=setmetatable({[0]='','\t'},{
        __index=function(self,k)
            if k>=260 then error("TABLE.dump(t,depth): Table depth over 260") end
            for i=#self+1,k do
                self[i]=self[i-1]..'\t'
            end
            return self[k]
        end,
    })
    local function dump(L,t,lim)
        local s
        if t then
            s='{\n'
        else
            s='return {\n'
            t=1
        end
        local count=1
        for k,v in next,L do
            -- Key part
            local T=type(k)
            if T=='number' then
                if k==count then
                    k='' -- List part, no brackets needed
                    count=count+1
                else
                    k='['..k..']='
                end
            elseif T=='string' then
                if find(k,'[^0-9a-zA-Z_]') then
                    k='["'..gsub(k,'"','\\"')..'"]='
                else
                    k=k..'='
                end
            elseif T=='boolean' then
                k='['..k..']='
            else
                k='["*'..tostring(k)..'"]='
            end

            -- Value part
            T=type(v)
            if T=='number' or T=='boolean' then
                v=tostring(v)
            elseif T=='string' then
                v='"'..gsub(v,'"','\\"')..'"'
            elseif T=='table' then
                if t>=lim then v=tostring(v) else v=dump(v,t+1,lim) end
            else
                v='*'..tostring(v)
            end
            s=s..tabs[t]..k..v..',\n'
        end
        return s..tabs[t-1]..'}'
    end
    ---Dump a simple lua table
    ---@param t table
    ---@param depth? number how many layers will be dumped, default to inf
    ---@return string
    function TABLE.dump(t,depth)
        assert(type(t)=='table',"Only table can be dumped")
        return dump(t,1,depth or 1e99)
    end
end

do -- function TABLE.newResourceTable(src,loadFunc)
    local function lazyLoadMF(self,k)
        local mt=getmetatable(self)
        local res=mt.__loader(mt.__source[k])
        self[k]=res
        return res
    end
    local function link(A,B,loadFunc)
        setmetatable(A,{
            __source=B,
            __loader=loadFunc,
            __index=lazyLoadMF,
        })
        for k,v in next,B do
            if type(v)=='table' then
                A[k]={}
                link(A[k],v,loadFunc)
            end
        end
    end
    ---Create a new table with lazy load feature
    ---@param src table
    ---@param loadFunc fun(resID:any):any should receive a resource identifier from src table, then return a non-nil value
    ---@param lazy? boolean
    ---@return table
    function TABLE.newResourceTable(src,loadFunc,lazy)
        local new={}
        link(new,src,loadFunc)
        if not lazy then
            TABLE.wakeLazyTable(src,new)
        end
        return new
    end
end
function TABLE.wakeLazyTable(src,lazyT)
    for k,v in next,src do
        if type(v)=='table' then
            TABLE.wakeLazyTable(v,lazyT[k])
        else
            local _=lazyT[k]
        end
    end
end

--------------------------------------------------------------

function TABLE.getFirstValue(...)
    local t={...}
    for i=1,select('#',...) do
        if t[i]~=nil then
            return t[i]
        end
    end
end

function TABLE.getlastValue(...)
    local t={...}
    local last
    for i=1,select('#',...) do
        if t[i]~=nil then
            last=t[i]
        end
    end
    return last
end

return TABLE
