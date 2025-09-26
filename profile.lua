local clock=os.clock
local getInfo=debug.getinfo

local profile={}

---@class Zenitha.Profile.FuncInfo
---@field name string | "?" function name
---@field src string source file and line no.

-- Registered information of functions
---@type table<function, Zenitha.Profile.FuncInfo>
local _reg={}
-- Time of last call
---@type table<function, number>
local _tCall={}
-- Total execution time
---@type table<function, number>
local _tRun={}
-- Number of calls
---@type table<function, number>
local _callCnt={}

-- Internal functions, to be ignored by profiler
---@type table<function, true>
local _internal={}

local function _hooker(event,info)
    if not info then info=getInfo(2,'fnS') end
    local f=info.func
    if _internal[f] then return end

    -- Record definition
    if not _reg[f] then
        local pack={
            name=info.name,
            src=info.short_src,
        }
        if not pack.name then
            if info.linedefined>0 then
                pack.name="[anonymous]"
            elseif info.what=='main' then
                pack.name="[file]"
            else
                pack.name="?"
            end
        end
        if pack.src:sub(1,9)==[[[string "]] then pack.src=pack.src:sub(9,-2) end
        if info.linedefined>0 then pack.src=pack.src..":"..info.linedefined end
        _reg[f]=pack
        _callCnt[f]=0
        _tRun[f]=0
    end

    if _tCall[f] then
        _tRun[f]=_tRun[f]+(clock()-_tCall[f])
        _tCall[f]=nil
    end
    if event=='tail call' then
        _hooker('return',getInfo(3,'fnS'))
        _hooker('call',info)
    elseif event=='call' then
        _tCall[f]=clock()
    else -- event=='return'
        _callCnt[f]=_callCnt[f]+1
    end
end
local function _comp(a,b)
    local dt=_tRun[b]-_tRun[a]
    return dt==0 and _callCnt[b]<_callCnt[a] or dt<0
end

function profile.start()
    if jit then
        jit.off()
        jit.flush()
    end
    debug.sethook(_hooker,'cr')
end

function profile.stop()
    debug.sethook()
    for f in next,_tCall do
        local dt=clock()-_tCall[f]
        _tRun[f]=_tRun[f]+dt
        _tCall[f]=nil
    end
    -- merge closures
    local lookup={}
    for f,info in next,_reg do
        local id=info.name..info.src
        local f2=lookup[id]
        if f2 then
            _callCnt[f2]=_callCnt[f2]+(_callCnt[f] or 0)
            _tRun[f2]=_tRun[f2]+(_tRun[f] or 0)
            _reg[f],_callCnt[f],_tRun[f]=nil,nil,nil
        else
            lookup[id]=f
        end
    end
    collectgarbage()
end

function profile.reset()
    for f in next,_callCnt do
        _callCnt[f]=0
        _tRun[f]=0
        _tCall[f]=nil
    end
    collectgarbage()
end

---Iterates all functions that have been called since the profile was started.
---@param limit? number limit the number of functions to return
function profile.query(limit)
    local report={}
    for f,n in next,_callCnt do
        if n>0 then
            report[#report+1]=f
        end
    end
    table.sort(report,_comp)
    if limit then for i=#report,limit+1 do report[i]=nil end end

    for i=1,#report do
        local f=report[i]
        -- local dt=_tCall[f] and clock()-_tCall[f] or 0 -- should add this to _tElapsed[f], but we don't need query while profiler is still running
        report[i]={i,_reg[f].name,string.format("%.6f",_tRun[f]):sub(1,8),_callCnt[f],_reg[f].src}
    end
    return report
end

local headStr={"#","Name","Time","Calls","Source"}
---Generate the datasheet
---@param limit? number limit the number of functions to return
---@return string #a huge multi-line string
function profile.report(limit)
    local report=profile.query(limit)
    local maxLen={}
    for c=1,#headStr do maxLen[c]=#headStr[c] end
    for r=1,#report do
        for c=1,#headStr do
            maxLen[c]=math.max(maxLen[c],#tostring(report[r][c]))
        end
    end

    local rowSep,header
    do
        for i=1,#headStr do
            maxLen[i]=math.max(maxLen[i],#headStr[i])
            local s=tostring(headStr[i])
            headStr[i]=s..(" "):rep(maxLen[i]-#s)
        end
        header=" | "..table.concat(headStr," | ").." | "

        local _rowSep={" +-"}
        for i=1,#headStr do
            table.insert(_rowSep,("-"):rep(maxLen[i]))
            table.insert(_rowSep,i<#maxLen and "-+-" or "-+ ")
        end
        rowSep=table.concat(_rowSep)
    end
    local output={rowSep,header,rowSep}

    for i=1,#report do
        local line={}
        for j=1,#headStr do
            local s=tostring(report[i][j])
            line[j]=s..(" "):rep(maxLen[j]-#s)
        end
        table.insert(output," | "..table.concat(line," | ").." | ")
    end
    return table.concat(output,"\n")
end

local switch=false
---Turn profile mode on/off
---
---Automatically copy the report to clipboard when turned off
---@return boolean #current state
function profile.switch()
    switch=not switch
    if not switch then
        profile.stop()
        local res=profile.report()
        print(res)
        CLIPBOARD.set(res)
        profile.reset()
        return false
    else
        profile.start()
        return true
    end
end

-- store all internal profiler functions
for _,v in next,profile do
    if type(v)=='function' then
        _internal[v]=true
    end
end

return profile
