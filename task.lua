local resume,status=coroutine.resume,coroutine.status
local assert,rawset=assert,rawset
local rem=table.remove
local timer=ZENITHA.timer.getTime

local TASK={}

-- Locks
---@type Map<number>
local locks=setmetatable({},{
    __index=function(self,k) rawset(self,k,-1e99) return -1e99 end,
    __newindex=function(self,k) rawset(self,k,-1e99) end,
})

---Attempt to set a labeled lock
---
---Can only succeed if the same-name lock is not set or has expired
---
---### Example
---```
----- Making 'name' sound cannot be played in next 0.26 seconds
---if TASK.lock('sound_name',0.26) then playSound('name') end
---```
---@param name any
---@param time? number
---@return boolean 
function TASK.lock(name,time)
    if timer()>=locks[name] then
        locks[name]=timer()+(time or 1e99)
        return true
    else
        return false
    end
end

---Same as `TASK.lock`, but lock will be forced set even if the lock is not expired
---@param name any
---@param time? number
---@return boolean succeed
function TASK.forceLock(name,time)
    local res=timer()>=locks[name]
    locks[name]=timer()+(time or 1e99)
    return res
end

---Invalidate a lock
---@param name any
function TASK.unlock(name)
    locks[name]=-1e99
end

---Get the time remaining of a lock, false if not locked or expired
---@param name any
---@return number | false
function TASK.getLock(name)
    local v=locks[name]-timer()
    return v>0 and v
end

---Remove the locks which are already expired
function TASK.freshLock()
    for k,v in next,locks do
        if timer()>v then locks[k]=nil end
    end
end

---Invalidate all locks
function TASK.clearLock()
    for k in next,locks do
        locks[k]=nil
    end
end


local tasks={}

---Update all tasks (called by Zenitha)
---@param dt number
function TASK._update(dt)
    local i,n=1,#tasks
    while i<=n do
        local T=tasks[i]
        if not T or status(T.thread)=='dead' then
            rem(tasks,i)
            n=n-1
        else
            assert(resume(T.thread,dt))
            i=i+1
        end
    end
end

---Wrap a function into coroutine then Zenitha will resume it automatically for each main loop cycle.  
---Immediately resume when `TASK.new()`, then trigger by time with `dt` passed to it through `coroutine.yield` inside
---@generic T
---@param code async fun(...:T)
---@param ... T First-call arguments when called
function TASK.new(code,...)
    local thread=coroutine.create(code)
    assert(resume(thread,...))
    if status(thread)~='dead' then
        tasks[#tasks+1]={
            thread=thread,
            code=code,
            args={...},
        }
    end
end

---Get the number of tasks  
---Warning: the result is not accurate during TASK._update, tasks removed during the update still count
---@return number
function TASK.getCount()
    return #tasks
end

---Remove task(s) by specified code(the function which created the task)
---@param code function
function TASK.removeTask_code(code)
    for i=1,#tasks do
        if tasks[i] and tasks[i].code==code then
            tasks[i]=false
        end
    end
end

---Iterate through tasks, remove them if the given function returns true
---@param func function
---@param ... any Arguments passed to the given function
function TASK.removeTask_iterate(func,...)
    for i=1,#tasks do
        if tasks[i] and func(tasks[i],...) then
            tasks[i]=false
        end
    end
end

---Remove all tasks
function TASK.clear()
    for k in next,locks do
        tasks[k]=nil
    end
end

local yield=coroutine.yield

---Yield for some times
---@param count number
function TASK.yieldN(count)
    for _=1,count do yield() end
end

---Yield for some seconds
---@param time number
function TASK.yieldT(time)
    local t=timer()
    while timer()-t<time do yield() end
end

local getLock=TASK.getLock
---Yield until a lock expired
---@param name string
function TASK.yieldL(name)
    while getLock(name) do yield() end
end

---Yield until the scene swapping animation finished
function TASK.yieldUntilNextScene()
    while SCN.swapping do yield() end
end

return TASK
