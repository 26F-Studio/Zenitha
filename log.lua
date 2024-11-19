-- use LOG(message) to print & record informations

local floor=math.floor
local format=string.format
local ins=table.insert
local clamp=MATH.clamp

local startTime=os.time()
local showLevel=10
local logs={}

---@alias Zenitha.log {[1]:integer, [2]:integer, [3]:string} level, timestamp, message

local function log(level,message)
    ins(logs,{
        level,
        os.time(),
        message,
    })
end

---@enum (key) Zenitha.logLevel
local logLevelNum={
    debug=15, -- 10~19
    info=25,  -- 20~29
    warn=35,  -- 30~39
    error=45, -- 40~49
}
local logLevelStr={
    '['..AE._G..'DEBUG'..AE..']',
    '['..AE._B..'INFO'..AE..'] ',
    '['..AE._Y..'WARN'..AE..'] ',
    '['..AE._R..'ERROR'..AE..']',
}

---Create a log message
---@overload fun(level:Zenitha.logLevel, message:string)
---@overload fun(message:string) -- logLevel default to 3
---@overload fun(level:integer, message:string) -- Will be converted to this
local LOG=setmetatable({},{
    __call=function(_,_1,_2)
        if not _2 then
            -- LOG(str)
            LOG._(15,_1)
        elseif type(_1)=='number' then
            -- LOG(num,str)
            LOG._(_1,_2)
        else
            -- LOG(str,str)
            LOG._(logLevelNum[_1] or 15,_2)
        end
    end,
    __metatable=true,
})

---@param l Zenitha.log
---@return string
local function dumpLog(l)
    return format("%s\27[3m %2d \27[0;30m%s\27[0m | %s",logLevelStr[floor(l[1]/10)],l[1],os.date("%H:%M:%S",l[2]),l[3])
end

---Create a log message
---@param level integer 10~49
---@param message string
function LOG._(level,message)
    level=clamp(floor(level),10,49)
    log(level,message)
    if level>=showLevel then
        print(dumpLog(logs[#logs]))
    end
end

---Set the minimal level of logs to be printed to console
---@param level integer 10~49
function LOG.setShowLevel(level)
    showLevel=clamp(floor(level),10,49)
end

---Get raw logs data
---@return Zenitha.log[] #READ ONLY, DO NOT MODIFY
function LOG.getLogs()
    return logs
end

---Get all logged strings as a long string
---@return string
function LOG.getString()
    local L={}
    for i=1,#logs do L[i]=dumpLog(logs[i]) end
    return STRING.repD("$1 $2  logs  $3\n",
        ZENITHA.getAppName(),
        ZENITHA.getVersionText(),
        os.date("%Y/%m/%d %A",startTime)
    )..table.concat(L,"\n")
end

return LOG
