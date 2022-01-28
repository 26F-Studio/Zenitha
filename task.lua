local rem=table.remove
local assert,resume,status=assert,coroutine.resume,coroutine.status
local tasks={}

local TASK={}
function TASK.getCount()
    return #tasks
end
function TASK.update(dt)
    for i=#tasks,1,-1 do
        local T=tasks[i]
        if status(T.thread)=='dead' then
            rem(tasks,i)
        else
            assert(resume(T.thread,dt))
        end
    end
end
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
function TASK.removeTask_code(code)
    for i=#tasks,1,-1 do
        if tasks[i].code==code then
            rem(tasks,i)
        end
    end
end
function TASK.removeTask_iterate(func,...)
    for i=#tasks,1,-1 do
        if func(tasks[i],...) then
            rem(tasks,i)
        end
    end
end
function TASK.clear()
    TABLE.cut(tasks)
end
return TASK
