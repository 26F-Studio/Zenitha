local rnd,floor=math.random,math.floor
local gsub,match,gmatch=string.gsub,string.match,string.gmatch
local rem=table.remove
local next,type,select=next,type,select

---@class Zenitha.TableExt
local TABLE={}

for k,v in next,table do TABLE[k]=v end

--------------------------------------------------------------
-- Builder

---Create a new filled table
---
---You can also use `TABLE.newSize`, which is alias of `table.new` from luajit:
---https://luajit.org/extensions.html
---@generic V
---@param val V value to fill
---@param count integer how many elements
---@return V[]
---@nodiscard
function TABLE.new(val,count)
    local L={}
    for i=1,count do
        L[i]=val
    end
    return L
end

---Create a new table with specific size allocated (from luajit)
---
---Fallback to `return {}` if failed to require `table.new`
---@param nArray? integer the size of "list part" of the table
---@param nHash? integer the size of "hash part" of the table
---@return table
---@nodiscard
---@diagnostic disable-next-line
function TABLE.newSize(nArray,nHash) return {} end
pcall(function() TABLE[('newSize')]=require'table.new' end)

---Create a new filled matrix
---@generic V
---@param val V value to fill
---@param height integer
---@param width integer
---@return Mat<V>
---@nodiscard
function TABLE.newMat(val,height,width)
    local L={}
    for y=1,height do
        L[y]={}
        for x=1,width do
            L[y][x]=val
        end
    end
    return L
end

---Create the subset list of a list, like string.sub
---
---leave `start&stop` as `nil` will simply copy
---@generic T
---@param org T original table
---@param start? integer start pos (default 1)
---@param stop? integer end pos (default #org)
---@return T
---@nodiscard
function TABLE.sub(org,start,stop)
    if not start then start=1 end
    local L={}
    for i=0,(stop or #org)-start do
        L[i+1]=org[start+i]
    end
    return L
end

---Create a copy of [1~#] elements
---@generic V
---@param org V[] original table
---@param depth? integer how many layers will be recreate, default to inf
---@return V[]
---@nodiscard
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
---@generic T
---@param org T original table
---@param depth? integer how many layers will be recreate, default to inf
---@return T
---@nodiscard
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

---Get a new table which keys and values are swapped
---@generic K, V
---@param org {[K]:V}
---@return {[V]:K}
function TABLE.inverse(org)
    local T={}
    for k,v in next,org do
        T[v]=k
    end
    return T
end

---Get keys of a table as a list
---@generic K
---@param org {[K]:any}
---@return K[]
---@nodiscard
function TABLE.getKeys(org)
    local L={}
    local n=0
    for k in next,org do
        n=n+1
        L[n]=k
    end
    return L
end

---Get values of a table as a list
---@generic V
---@param org {[any]:V}
---@return V[]
---@nodiscard
function TABLE.getValues(org)
    local L={}
    local n=0
    for _,v in next,org do
        n=n+1
        L[n]=v
    end
    return L
end

---Set all values to k
---@generic T1, T2
---@param org {[any]:T1}
---@param val? T2 default to `true`
---@return {[T1]:T2}
---@nodiscard
function TABLE.getValueSet(org,val)
    if val==nil then val=true end
    local T={}
    for _,v in next,org do
        T[v]=val
    end
    return T
end

---**Create** a table of two lists combined
---For **Appending** a table, use `TABLE.append`
---@generic T1, T2
---@param L1 T1[] list 1
---@param L2 T2[] list 2
---@return (T1 | T2)[]
---@nodiscard
function TABLE.combine(L1,L2)
    local L={}
    local l0=#L1
    for i=1,l0 do L[i]=L1[i] end
    for i=1,#L2 do L[l0+i]=L2[i] end
    return L
end

---Transpose a matrix
---@generic V
---@param matrix Mat<V>
---@return Mat<V>
function TABLE.transpose(matrix)
    if #matrix==0 then return matrix end
    local w,h=#matrix[1],#matrix
    if w>h then
        for y=h+1,w do matrix[y]={} end
        for y=2,w do
            for x=1,y-1 do
                matrix[y][x],matrix[x][y]=matrix[x][y],matrix[y][x]
            end
        end
    else
        for y=2,h do
            for x=1,y-1 do
                matrix[y][x],matrix[x][y]=matrix[x][y],matrix[y][x]
            end
        end
        for y=h+1,w do matrix[y]=nil end
    end
    return matrix
end

---Create a transposed copy of a matrix
---This one is faster then `TABLE.transpose` but creates new table
---@generic V
---@param matrix Mat<V>
---@return Mat<V>
---@nodiscard
function TABLE.transposeNew(matrix)
    local newMat={}
    for y=1,#matrix[1] do
        newMat[y]={}
        for x=1,#matrix do
            newMat[y][x]=matrix[x][y]
        end
    end
    return newMat
end

---Create a rotated copy of a matrix
---@generic V
---@param matrix Mat<V>
---@param direction 'R' | 'L' | 'F' | '0' CW, CCW, 180 deg, 0 deg (copy)
---@return Mat<V>
---@nodiscard
function TABLE.rotateNew(matrix,direction)
    local iMat={}
    if direction=='R' then -- Rotate CW
        for y=1,#matrix[1] do
            iMat[y]={}
            for x=1,#matrix do
                iMat[y][x]=matrix[x][#matrix[1]-y+1]
            end
        end
    elseif direction=='L' then -- Rotate CCW
        for y=1,#matrix[1] do
            iMat[y]={}
            for x=1,#matrix do
                iMat[y][x]=matrix[#matrix-x+1][y]
            end
        end
    elseif direction=='F' then -- Rotate 180 degree
        for y=1,#matrix do
            iMat[y]={}
            for x=1,#matrix[1] do
                iMat[y][x]=matrix[#matrix-y+1][#matrix[1]-x+1]
            end
        end
    elseif direction=='0' then -- No rotation, just copy
        for y=1,#matrix do
            iMat[y]={}
            for x=1,#matrix[1] do
                iMat[y][x]=matrix[y][x]
            end
        end
    else
        errorf("TABLE.rotateNew: Invalid rotate direction '%s'",direction)
    end
    return iMat
end
TABLE.rotate=TABLE.rotateNew

--------------------------------------------------------------
-- Set operation

---Check if two table have same elements in [1~#]
---@param a any[]
---@param b any[]
---@return boolean
---@nodiscard
function TABLE.equal(a,b)
    if #a~=#b then return false end
    if a==b then return true end
    for i=1,#a do
        if a[i]~=b[i] then return false end
    end
    return true
end

---Check if two whole table have same elements
---**Warning**: won't check whether two table have same keys of hash part
---@param a table
---@param b table
---@return boolean
---@nodiscard
function TABLE.equalAll(a,b)
    if #a~=#b then return false end
    if a==b then return true end
    for k,v in next,a do
        if b[k]~=v then return false end
    end
    return true
end

---**Append** [1~#] elements of new to the end of org
---For **Creating** a new table, use `TABLE.combine`
---@generic T1, T2
---@param org T1[] original list
---@param new T2[] new list
---@return (T1 | T2)[]
function TABLE.append(org,new)
    local l0=#org
    for i=1,#new do
        org[l0+i]=new[i]
    end
    return org
end

---Delete items in [1~#] of org which also in [1~#] of sub
---@generic V
---@param org V[]
---@param sub table
---@return V[]
function TABLE.subtract(org,sub)
    for i=#org,1,-1 do
        for j=#sub,1,-1 do
            if org[i]==sub[j] then
                rem(org,i)
                break
            end
        end
    end
    return org
end

---Delete all items in org which also in sub
---@generic T
---@param org T
---@param sub table
---@return T
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
    return org
end

---Update old table with new table (recursive when both table type and below specifiled depth)
---@generic T
---@param new T
---@param old table
---@param depth? integer how many layer will be entered, default to inf
---@return T
function TABLE.update(old,new,depth)
    if not depth then depth=1e99 end
    for k,v in next,new do
        if type(v)=='table' and type(old[k])=='table' and depth>0 then
            TABLE.update(old[k],v,depth-1)
        else
            old[k]=v
        end
    end
    return old
end

---Update old table with new table when same type (recursive)
---@generic T
---@param old T
---@param new table
---@return T
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
    return old
end

---Update old table with new table when no value (recursive)
---@generic T
---@param old T
---@param new table
---@return T
function TABLE.updateMissing(old,new)
    for k,v in next,new do
        if type(v)=='table' then
            if old[k]==nil then old[k]={} end
            TABLE.updateMissing(old[k],v)
        elseif old[k]==nil then
            old[k]=v
        end
    end
    return old
end

--------------------------------------------------------------
-- Editing

---`table.clear` from luajit extension, clear the whole table but preserve the allocated array/hash sizes
---
---Fallback to `TABLE.clearAll` if failed to require `table.clear`
---
---@param org table
function TABLE.clear(org)
    for k in next,org do
        org[k]=nil
    end
end
pcall(function() TABLE[('clear')]=require'table.clear' end)

---Clear whole table (pure lua implementation)
---
---Recommend to use `TABLE.clear` instead
---@generic T
---@param org T
---@return T
function TABLE.clearAll(org)
    for k in next,org do
        org[k]=nil
    end
    return org
end

---Clear [1~#] of a table (pure lua implementation)
---@generic V
---@param org V[]
---@return V[]
function TABLE.clearList(org)
    for i=1,#org do
        org[i]=nil
    end
    return org
end

---Clear whole table but keep the tree structure
---@generic T
---@param org T
---@return T
function TABLE.clearRecursive(org)
    for k,v in next,org do
        if type(v)=='table' then
            TABLE.clearRecursive(v)
        else
            org[k]=nil
        end
    end
    return org
end

---Remove a specific value of [1~#]
---@generic V
---@param org V[]
---@return V[]
function TABLE.delete(org,value)
    for i=#org,1,-1 do
        if org[i]==value then
            rem(org,i)
        end
    end
    return org
end

---Remove a specific value in whole table
---@generic T
---@param org T
---@return T
function TABLE.deleteAll(org,value)
    for k,v in next,org do
        if v==value then
            org[k]=nil
        end
    end
    return org
end

---Remove duplicated value of [1~#]
---@generic V
---@param org V[]
---@return V[]
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
    return org
end

---Remove duplicated value in whole table
---@generic T
---@param org T
---@return T
function TABLE.removeDuplicateAll(org)
    local cache={}
    for k,v in next,org do
        if cache[v] then
            org[k]=nil
        else
            cache[v]=true
        end
    end
    return org
end

---Reverse [1~#]
---@generic V
---@param org V[]
---@return V[]
function TABLE.reverse(org)
    local l=#org
    for i=1,floor(l/2) do
        org[i],org[l+1-i]=org[l+1-i],org[i]
    end
    return org
end

---Get random [1~#] of table
---@generic V
---@param org V[]
---@return V
---@nodiscard
function TABLE.getRandom(org)
    local l=#org
    if l>0 then
        return org[rnd(l)]
    else
        error("TABLE.popRandom(org): Table is empty")
    end
end

---Remove & return random [1~#] of table (not really "pop"!)
---@generic V
---@param org V[]
---@return V
---@nodiscard
function TABLE.popRandom(org)
    local l=#org
    if l>0 then
        local r=rnd(l)
        r,org[r]=org[r],org[l]
        org[l]=nil
        return r
    else
        error("TABLE.popRandom(org): Table is empty")
    end
end

---Sort [1~#] elements
---Just normal table.sort, but return the original table for convenience
---@generic V
---@param org V[]
---@param comp? fun(a:V,b:V):boolean default to `<`
---@return V[]
---@nodiscard
function TABLE.sort(org,comp)
    table.sort(org,comp)
    return org
end

---Shuffle [1~#]
---@generic V
---@param org V[]
---@return V[]
function TABLE.shuffle(org)
    for i=#org,2,-1 do
        local r=rnd(i)
        org[i],org[r]=org[r],org[i]
    end
    return org
end

---Re-index string value as key
---### Example
---```
---local t={a=print,b='a'}
---TABLE.reIndex(t)
---t.b('Hello Zenitha')
---```
---@generic T
---@param org T
---@return T
function TABLE.reIndex(org)
    for k,v in next,org do
        if type(v)=='string' then
            org[k]=org[v]
        end
    end
    return org
end

---Flatten a nested table to a flat table (no table type value included)
---### Example
---```
---local T={a=1,b={c=2},d={e={f=3}}}
---TABLE.flatten(T)
-----[[ Now T is
---{
---    ['a']=1,
---    ['b/c']=2
---    ['d/e/f']=3
---}
---]]
---```
---@param org table
---@param depth? integer how many layer will be entered and flattened, default to inf
---@return table
function TABLE.flatten(org,depth)
    if not depth then depth=1e99 end
    while depth>0 do
        local tKeyList={}
        for k,v in next,org do
            if type(v)=='table' then
                table.insert(tKeyList,k)
            end
        end
        if #tKeyList==0 then return org end
        for i=1,#tKeyList do
            local key=tKeyList[i]
            for k,v in next,org[key] do
                org[key..'/'..k]=v
            end
            org[key]=nil
        end
        depth=depth-1
    end
    return org
end

--------------------------------------------------------------
-- Find & Replace

---Find value in [1~#], like string.find
---@param org any[]
---@param val any
---@param start? integer
---@return integer? key
---@nodiscard
function TABLE.find(org,val,start)
    for i=start or 1,#org do if org[i]==val then return i end end
end

---TABLE.find for ordered list only, faster (binary search)
---@param org any[]
---@param val any
---@return integer | nil key
---@nodiscard
function TABLE.findOrdered(org,val)
    if val<org[1] or val>org[#org] then return nil end
    local i,j=1,#org
    while i<=j do
        local m=floor((i+j)/2)
        if org[m]>val then
            j=m-1
        elseif org[m]<val then
            i=m+1
        else
            return m
        end
    end
end

---Find value in whole table
---@generic K, V
---@param org {[K]:V}
---@param val V
---@return K | nil key
---@nodiscard
function TABLE.findAll(org,val)
    for k,v in next,org do if v==val then return k end end
    return nil
end

---Replace value in [1~#], like string.gsub
---@generic T1, T2
---@param org T1[]
---@param v_old T1
---@param v_new T2
---@param start? integer
---@return (T1 | T2)[]
function TABLE.replace(org,v_old,v_new,start)
    for i=start or 1,#org do
        if org[i]==v_old then
            org[i]=v_new
        end
    end
    return org
end

---Replace value in whole table
---@generic K, V1, V2
---@param org {[K]:V1}
---@param v_old V1
---@param v_new V2
---@return {[K]:V1|V2}
function TABLE.replaceAll(org,v_old,v_new)
    for k,v in next,org do
        if v==v_old then
            org[k]=v_new
        end
    end
    return org
end

---Find the minimum value (and key)
---if you don't need the key and the list is short, use `math.min(unpack(t))` for better performance
---@generic V
---@param org V[]
---@return V | number minVal, integer | nil key `minVal` will be inf when empty
---@nodiscard
function TABLE.min(org)
    local min,key=MATH.inf,nil
    for i=1,#org do
        if org[i]<min then
            min,key=org[i],i
        end
    end
    return min,key
end

---Find the minimum value (and key) in whole table
---@generic K, V
---@param org {[K]:V}
---@return V | number minVal, K | nil key `minVal` will be inf when empty
---@nodiscard
function TABLE.minAll(org)
    local min,key=MATH.inf,nil
    for k,v in next,org do
        if v<min then
            min,key=v,k
        end
    end
    return min,key
end

---Find the maximum value (and key)
---if you don't need the key and the list is short, use `math.max(unpack(t))` for better performance
---@generic V
---@param org V[]
---@return V | number maxVal, integer | nil key `maxVal` will be -inf when empty
---@nodiscard
function TABLE.max(org)
    local max,key=-MATH.inf,nil
    for i=1,#org do
        if org[i]>max then
            max,key=org[i],i
        end
    end
    return max,key
end

---Find the maximum value (and key) in whole table
---@generic K, V
---@param org {[K]:V}
---@return V | number maxVal, K | nil key `maxVal` will be -inf when empty
---@nodiscard
function TABLE.maxAll(org)
    local max,key=-MATH.inf,nil
    for k,v in next,org do
        if v>max then
            max,key=v,k
        end
    end
    return max,key
end

--------------------------------------------------------------
-- Dump

do -- function TABLE.dumpDeflate(org,depth)
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
                if k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                    k=k..'='
                else
                    k='["'..gsub(k,'"',[[\"]])..'"]='
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
                v='"'..gsub(v,'"',[[\"]])..'"'
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
    ---@param org table
    ---@param depth? integer how many layers will be dumped, default to inf
    ---@return string
    ---@nodiscard
    function TABLE.dumpDeflate(org,depth)
        assert(type(org)=='table',"TABLE.dumpDeflate: need table")
        return dump(org,1,depth or 1e99)
    end
end

do -- function TABLE.dump(org,depth)
    local tabs=setmetatable({[0]='','\t'},{
        __index=function(self,k)
            if k>=260 then error("TABLE.dump(org,depth): Table depth over 260") end
            for i=#self+1,k do
                self[i]=self[i-1]..'\t'
            end
            return self[k]
        end,
    })
    local function dump(L,t,lim)
        local s='{\n'
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
                if k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                    k=k..'='
                else
                    k='["'..gsub(k,'"',[[\"]])..'"]='
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
                v='"'..gsub(v,'"',[[\"]])..'"'
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
    ---@param org table
    ---@param depth? integer how many layers will be dumped, default to inf
    ---@return string
    ---@nodiscard
    function TABLE.dump(org,depth)
        assert(type(org)=='table',"TABLE.dump: need table")
        return dump(org,1,depth or 1e99)
    end
end

--------------------------------------------------------------
-- Information

---Get element count of table
---@param org table
---@return integer
---@nodiscard
function TABLE.getSize(org)
    local size=0
    for _ in next,org do size=size+1 end
    return size
end

---Count value repeating time in [1~#]
---@param org any[]
---@param val any
---@return integer
---@nodiscard
function TABLE.count(org,val)
    local count=0
    for i=1,#org do
        if org[i]==val then
            count=count+1
        end
    end
    return count
end

---Count value repeating time in whole table
---@param org table
---@param val any
---@return integer
---@nodiscard
function TABLE.countAll(org,val)
    local count=0
    for _,v in next,org do
        if v==val then
            count=count+1
        end
    end
    return count
end

---Return next value of [1~#] (by value), like _G.next
---Return nil if input is the last value
---Return list[1] if input is nil
---@generic K, V
---@param org {[K]:V}
---@param val V
---@param loop? boolean loop back to first value when reaching the end
---@return V | nil nextValue nil when not found
---@nodiscard
function TABLE.next(org,val,loop)
    if val==nil then return org[1] end
    for i=1,#org do
        if org[i]==val then
            return org[loop and i==#org and 1 or i+1]
        end
    end
    return nil
end

---Return previous value of [1~#] (by value), like TABLE.next but reversed
---Return nil if input is the first value
---Return list[#list] if input is nil
---@generic K, V
---@param org {[K]:V}
---@param val V
---@param loop? boolean loop back to last value when reaching the start
---@return V | nil prevValue nil when not found
---@nodiscard
function TABLE.prev(org,val,loop)
    if val==nil then return org[#org] end
    for i=#org,1,-1 do
        if org[i]==val then
            return org[loop and i==1 and 1 or i-1]
        end
    end
    return nil
end

--------------------------------------------------------------
-- (Utility) Foreach

---Execute func(table[i],i) in [1~#], and optional element removing
---@generic V
---@param org V[]
---@param f fun(v:V, i:integer): boolean return `true` to remove element (do this in reverse mode for better performance)
---@param rev? boolean Reverse the iterating order
---@return V[]
function TABLE.foreach(org,f,rev)
    if rev then
        for i=#org,1,-1 do
            if f(org[i],i) then
                rem(org,i)
            end
        end
    else
        local remCount=0
        for i=1,#org do
            if f(org[i-remCount],i) then
                rem(org,i-remCount)
                remCount=remCount+1
            end
        end
    end
    return org
end

---Execute func(table[k],k) in whole table, and optional element removing
---@generic K, V
---@param org {[K]:V}
---@param f fun(v:V, k:K): boolean return `true` to remove element (**Warning**: Won't shrink the list part when removing list element)
---@return {[K]:V}
function TABLE.foreachAll(org,f)
    for k,v in next,org do
        if f(v,k) then org[k]=nil end
    end
    return org
end

---Apply a function to value in [1~#]
---@generic V1, V2
---@param org V1[]
---@param f fun(v:V1): V2
---@return V2[]
function TABLE.applyeach(org,f)
    for i=1,#org do
        org[i]=f(org[i])
    end
    return org
end

---Apply a function to value in whole table
---@generic K, V1, V2
---@param org {[K]:V1}
---@param f fun(V1): V2
---@return {[K]:V2}
function TABLE.applyeachAll(org,f)
    for k,v in next,org do
        org[k]=f(v)
    end
    return org
end

---Apply a function to value in matrix
---@generic V1, V2
---@param org Mat<V1>
---@param f fun(V1): V2
---@return Mat<V2>
function TABLE.applyeachMat(org,f)
    for y=1,#org do
        for x=1,#org[y] do
            org[y][x]=f(org[y][x])
        end
    end
    return org
end

--------------------------------------------------------------
-- (Utility) Shortcuts

---Return a function that return a value of table
---@param org table
---@param k any
---@return fun(): any
---@nodiscard
function TABLE.func_getVal(org,k)
    return function() return org[k] end
end

---Return a function that reverse a value of table
---@param org table
---@param k any
---@return fun()
---@nodiscard
function TABLE.func_revVal(org,k)
    return function() org[k]=not org[k] end
end

---Return a function that set a value of table
---@param org table
---@param k any
---@return fun(v:any)
---@nodiscard
function TABLE.func_setVal(org,k)
    return function(v) org[k]=v end
end

--------------------------------------------------------------
-- (Utility) Lazy loading

---Make a table to be able to auto filled from a source
---@generic T
---@param org T
---@param source table
---@return T
function TABLE.setAutoFill(org,source)
    return setmetatable(org,{
        __index=function(self,k)
            self[k]=source[k]
            return source[k]
        end,
    })
end

do -- function TABLE.linkSource(src,loadFunc)
    local function lazyLoadMF(self,k)
        local mt=getmetatable(self)
        local res=mt.__loader(mt.__source[k])
        self[k]=res
        return res
    end
    local function link(lib,index,loadFunc)
        setmetatable(lib,{
            __source=index,
            __loader=loadFunc,
            __index=lazyLoadMF,
        })
        for k,v in next,index do
            if type(v)=='table' then
                lib[k]={}
                link(lib[k],v,loadFunc)
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
    ---@generic T
    ---@param lib T lib table to be linked
    ---@param src table resourceID table
    ---@param loadFunc fun(resID:any): any Will receive resourceID from src table, must return a non-nil value
    ---@param noLazy? boolean
    ---@return T
    function TABLE.linkSource(lib,src,loadFunc,noLazy)
        link(lib,src,loadFunc)
        if noLazy then wakeLazyTable(src,lib) end
        return lib
    end
end

--------------------------------------------------------------
-- (Utility) Get value

---Get first non-nil value in all arguments
---@generic V
---@param ... V
---@return V?
function TABLE.getFirstValue(...)
    local t={...}
    for i=1,select('#',...) do
        if t[i]~=nil then
            return t[i]
        end
    end
end

---Get last non-nil value in all arguments
---@generic V
---@param ... V
---@return V?
function TABLE.getlastValue(...)
    local t={...}
    for i=select('#',...),1,-1 do
        if t[i]~=nil then
            return t[i]
        end
    end
end

--------------------------------------------------------------
-- (Utility) PathIndex

---Get value in a table by a path-like string
---@param org table
---@param str string
---@param sep? char Single-byte separator string (no need to consider escape), default to '.'
---@return any
---@nodiscard
function TABLE.pathIndex(org,str,sep)
    local pattern=sep and '[^%'..sep..']+' or '[^%.]+'
    for k in gmatch(str,pattern) do
        org=org[k]
    end
    return org
end

return TABLE
