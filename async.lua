if not love.thread then
    LOG("ASYNC lib is not loaded (need love.thread)")
    return setmetatable({},{
        __index=function(_,k)
            error("attempt to use ASYNC."..k..", but ASYNC lib is not loaded (need love.thread)")
        end,
    })
end

local resPool={}

local ASYNC={}

local resCHN=love.thread.newChannel()
local getCount=resCHN.getCount

---@type Map<love.Thread>
local threads={}

local function refreshThreads()
    for k,v in next,threads do
        if not v:isRunning() then
            threads[k]=nil
        end
    end
end

---@language LUA
local thread_lua=[[
    local resCHN,rtn,cmd,args,traceback=...

    local func,err=loadstring(cmd,"<async>"..tostring(rtn))
    if func then
        local suc, res = pcall(func, args)
        if suc then
            resCHN:push({
                rtn=rtn,
                res=res,
            })
        else
            resCHN:push({
                rtn=rtn,
                err=traceback:gsub('@@@',res),
            })
        end
    else
        resCHN:push({
            rtn=rtn,
            err=traceback:gsub('@@@',err),
        })
    end
]]
---Run a Lua function asynchronously in another love2d thread
---@param rtn string | any Use ASYNC.get(rtn) to get the result later
---@param cmd string Lua code string (cannot be function because cannot pass non-data objects to love2d thread)
---@param args? any parameter to pass to the Lua code
---@return boolean success whether the thread was started
function ASYNC.runLua(rtn,cmd,args)
    refreshThreads()
    if threads[rtn] then return false end
    threads[rtn]=love.thread.newThread(thread_lua)
    threads[rtn]:start(
        resCHN,
        rtn,
        cmd,
        args,
        debug.traceback('@@@',2)
    )
    return true
end

---@language BAT|SH
local thread_cmd=[[
    local resCHN,rtn,cmd=...

    local f=io.popen(cmd,'r')
    local res=f:read('*a')
    f:close()

    resCHN:push{
        rtn=rtn,
        res=res,
    }
]]
---Run a system command asynchronously in another love2d thread
---@param rtn string | any Use ASYNC.get(rtn) to get the result later
---@param cmd string command to run with io.popen
---@return boolean success whether the thread was started
function ASYNC.runCmd(rtn,cmd)
    refreshThreads()
    if threads[rtn] then return false end
    threads[rtn]=love.thread.newThread(thread_cmd)
    threads[rtn]:start(
        resCHN,
        rtn,
        cmd
    )
    return true
end

---Get the result of an asynchronous operation started with ASYNC.runLua or ASYNC.runCmd
---@param rtn string | any The return key used in ASYNC.runLua or ASYNC.runCmd
function ASYNC.get(rtn)
    refreshThreads()
    while getCount(resCHN)>0 do
        local m=resCHN:pop()
        if m.err then
            LOG('error',m.err)
        else
            resPool[m.rtn]=m.res
        end
    end

    if resPool[rtn]~=nil then
        local res=resPool[rtn]
        resPool[rtn]=nil
        return res
    end
end

return ASYNC
