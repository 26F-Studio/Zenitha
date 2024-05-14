local rnd,floor=math.random,math.floor
local find,gsub=string.find,string.gsub
local rem=table.remove
local next,type,select=next,type,select
local TABLE={}

for k,v in next,table do TABLE[k]=v end

--------------------------------------------------------------
-- Builder

---Create a new filled table
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

---Create a copy of [1~#] elements
---@param org any[] original table
---@param depth? number how many layers will be recreate, default to inf
---@return any[]
function TABLE.copy(org,depth)
    if not depth then depth=1e99 end
    local L={}
    for i=1,#org do
        if type(org[i])=='table' and depth>0 then
            L[i]=TABLE.copy(org[i],depth-1)
        else
            L[i]=org[i]
        end
    end
    return L
end

---Create a full copy of org, depth = how many layers will be recreate, default to inf
---@param org table original table
---@param depth? number how many layers will be recreate, default to inf
---@return table
function TABLE.copyAll(org,depth)
    if not depth then depth=1e99 end
    local L={}
    for k,v in next,org do
        if type(v)=='table' and depth>0 then
            L[k]=TABLE.copyAll(v,depth-1)
        else
            L[k]=v
        end
    end
    return L
end

---Create a table of two lists connected
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

---Create a rotated copy of a matrix
---@param matrix any[][]
---@param direction 'R'|'L'|'F'|'0' CW, CCW, 180 deg, 0 deg (copy)
---@return any[][]
function TABLE.rotate(matrix,direction)
    local icb={}
    if direction=='R' then -- Rotate CW
        for y=1,#matrix[1] do
            icb[y]={}
            for x=1,#matrix do
                icb[y][x]=matrix[x][#matrix[1]-y+1]
            end
        end
    elseif direction=='L' then -- Rotate CCW
        for y=1,#matrix[1] do
            icb[y]={}
            for x=1,#matrix do
                icb[y][x]=matrix[#matrix-x+1][y]
            end
        end
    elseif direction=='F' then -- Rotate 180 degree
        for y=1,#matrix do
            icb[y]={}
            for x=1,#matrix[1] do
                icb[y][x]=matrix[#matrix-y+1][#matrix[1]-x+1]
            end
        end
    elseif direction=='0' then -- No rotation, just copy
        for y=1,#matrix do
            icb[y]={}
            for x=1,#matrix[1] do
                icb[y][x]=matrix[y][x]
            end
        end
    else
        errorf("TABLE.rotate(matrix,dir): Invalid rotate direction '%s'",direction)
    end
    return icb
end

---Create a new table with __index and __call, both cause indexFunc to be called
---@param indexFunc fun(self:table, key:any):any
---@return table
function TABLE.newPool(indexFunc)
    return setmetatable({},{
        __call=indexFunc,
        __index=indexFunc,
    })
end

--------------------------------------------------------------
-- Set operation

---Check if two table have same elements in [1~#]
---@param a any[]
---@param b any[]
---@return boolean
function TABLE.equal(a,b)
    if #a~=#b then return false end
    if a==b then return true end
    for i=1,#a do
        if a[i]~=b[i] then return false end
    end
    return true
end

---Check if two whole table have same elements
---@param a table
---@param b table
---@return boolean
function TABLE.equalAll(a,b)
    if #a~=#b then return false end
    if a==b then return true end
    for k,v in next,a do
        if b[k]~=v then return false end
    end
    return true
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

---Delete items in [1~#] of org which also in [1~#] of sub
---@param org table
---@param sub table
function TABLE.subtract(org,sub)
    for i=#org,1,-1 do
        for j=#sub,1,-1 do
            if org[i]==sub[j] then
                rem(org,i)
                break
            end
        end
    end
end

---Delete all items in org which also in sub
---@param org table
---@param sub table
function TABLE.subtractAll(org,sub)
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

---Update old table with new table (recursive when both table type and below specifiled depth)
---@param new table
---@param old table
---@param depth? number how many layer will be entered, default to inf
function TABLE.update(old,new,depth)
    if not depth then depth=1e99 end
    for k,v in next,new do
        if type(v)=='table' and type(old[k])=='table' and depth>0 then
            TABLE.update(old[k],v,depth-1)
        else
            old[k]=v
        end
    end
end

---Update old table with new table when same type (recursive)
---@param old table
---@param new table
function TABLE.updateType(old,new)
    for k,v in next,new do
        if type(v)==type(old[k]) then
            if type(v)=='table' then
                TABLE.updateType(old[k],v)
            else
                old[k]=v
            end
        end
    end
end

---Update old table with new table when no value (recursive)
---@param old table
---@param new table
function TABLE.updateMissing(old,new)
    for k,v in next,new do
        if type(v)=='table' then
            if old[k]==nil then old[k]={} end
            TABLE.updateMissing(old[k],v)
        elseif old[k]==nil then
            old[k]=v
        end
    end
end

--------------------------------------------------------------
-- Editing

---Clear [1~#] of a table
---@param t table
function TABLE.clear(t)
    for i=1,#t do
        t[i]=nil
    end
end

---Clear all table
---@param t table
function TABLE.clearAll(t)
    for k in next,t do
        t[k]=nil
    end
end

---Remove duplicated value of [1~#]
---@param org any[]
function TABLE.removeDuplicate(org)
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

---Remove duplicated value in whole table
---@param org table
function TABLE.removeDuplicateAll(org)
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

---Shuffle [1~#]
---@param org any[]
function TABLE.shuffle(org)
    local l=#org
    for i=l,2,-1 do
        local r=rnd(i)
        org[i],org[r]=org[r],org[i]
    end
end

---Re-index string value as key
---## Example
---```lua
---local t={a=print,b='a'}
---TABLE.reIndex(t)
---t.b('Hello Zenitha')
---```
---@param org table
function TABLE.reIndex(org)
    for k,v in next,org do
        if type(v)=='string' then
            org[k]=org[v]
        end
    end
end

--------------------------------------------------------------
-- Find & Replace

---Find value in [1~#], like string.find
---@param t any[]
---@param val any
---@param start? number
---@return number|nil
function TABLE.find(t,val,start)
    for i=start or 1,#t do if t[i]==val then return i end end
end

---TABLE.find for ordered list only, faster (binary search)
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

--------------------------------------------------------------
-- Dump

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

--------------------------------------------------------------
-- Information

---Get element count of table
---@param t table
---@return number
function TABLE.getSize(t)
    local size=0
    for _ in next,t do size=size+1 end
    return size
end

---Count value repeating time in [1~#]
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

---Count value repeating time in whole table
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

---Return next value of [1~#] (by value) (like _G.next)
---@param t any[]
---@param val any
---@return any
function TABLE.next(t,val)
    if val==nil then return t[1] end
    for i=1,#t do if t[i]==val then return t[i+1] end end
end

--------------------------------------------------------------
-- (Utility) Foreach

---Execute func(table[i],i) in [1~#]
---@param t any[]
---@param f fun(v:any, i:number)
---@param rev? boolean Reverse the order, allow removing elements
function TABLE.foreach(t,f,rev)
    if rev then
        for i=#t,1,-1 do
            f(t[i],i)
        end
    else
        for i=1,#t do
            f(t[i],i)
        end
    end
end

---Execute func(table[k],k) for all elements in table (allow removing elements according to lua manual)
---@param t table
---@param f fun(v:any, k:number)
function TABLE.foreachAll(t,f)
    for k,v in next,t do
        f(v,k)
    end
end

--------------------------------------------------------------
-- (Utility) Shortcuts

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
-- (Utility) Lazy loading

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
    local function wakeLazyTable(src,lazyT)
        for k,v in next,src do
            if type(v)=='table' then
                wakeLazyTable(v,lazyT[k])
            else
                local _=lazyT[k]
            end
        end
    end
    ---Create a new table with lazy load feature
    ---@param src table resourceID table
    ---@param loadFunc fun(resID:any):any Will receive resourceID from src table, must return a non-nil value
    ---@param lazy? boolean
    ---@return table
    function TABLE.newResourceTable(src,loadFunc,lazy)
        local new={}
        link(new,src,loadFunc)
        if not lazy then
            wakeLazyTable(src,new)
        end
        return new
    end
end

--------------------------------------------------------------
-- (Utility) Get value

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
