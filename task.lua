local resume,status=coroutine.resume,coroutine.status
local assert,rawset=assert,rawset
local rem=table.remove
local timer=love.timer.getTime

local TASK={}

-- Locks
local locks=setmetatable({},{
    __index=function(self,k) rawset(self,k,-1e99) return -1e99 end,
    __newindex=function(self,k) rawset(self,k,-1e99) end,
})

--- Attempt to set a labeled lock
---
--- Can only succeed if the same-name lock is not set or has expired
--- @param name any
--- @param time? number
--- @return boolean
function TASK.lock(name,time)
    if timer()>=locks[name] then
        locks[name]=timer()+(time or 1e99)
        return true
    else
        return false
    end
end

--- Invalidate a lock
--- @param name any
function TASK.unlock(name)
    locks[name]=-1e99
end

--- Get the time remaining of a lock, false if not locked or expired
--- @param name any
--- @return number|false
function TASK.getLock(name)
    local v=locks[name]-timer()
    return v>0 and v
end

--- Invalidate all locks
function TASK.clearLock()
    for k in next,locks do
        locks[k]=nil
    end
end


local tasks={}

--- Update all tasks (called by Zenitha)
--- @param dt number
function TASK._update(dt)
    for i=#tasks,1,-1 do
        local T=tasks[i]
        if status(T.thread)=='dead' then
            rem(tasks,i)
        else
            assert(resume(T.thread,dt))
        end
    end
end

--- Create a new task
--- @param code function
--- @param ... any @Arguments passed to the function
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

--- Get the number of tasks
--- @return number
function TASK.getCount()
    return #tasks
end

--- Remove task(s) by specified code(the function which created the task)
--- @param code function
function TASK.removeTask_code(code)
    for i=#tasks,1,-1 do
        if tasks[i].code==code then
            rem(tasks,i)
        end
    end
end

--- Iterate through tasks, remove them if the given function returns true
--- @param func function
--- @param ... any @Arguments passed to the given function
function TASK.removeTask_iterate(func,...)
    for i=#tasks,1,-1 do
        if func(tasks[i],...) then
            rem(tasks,i)
        end
    end
end

--- Remove all tasks
function TASK.clear()
    TABLE.cut(tasks)
end

return TASK
