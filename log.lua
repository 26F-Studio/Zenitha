-- Use LOG(message) to print & record informations

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
local logColor={AE._G,AE._B,AE._Y,AE._R}
local logStr={
    '['..AE._G..'DEBUG'..AE..']',
    '['..AE._B..'INFO'..AE..'] ',
    '['..AE._Y..'WARN'..AE..'] ',
    '['..AE._R..'ERROR'..AE..']'
}

local LOG={}

setmetatable(LOG,{
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
---@cast LOG + fun(level:Zenitha.logLevel, message:string)
---@cast LOG + fun(message:string) -- logLevel default to 3
---@cast LOG + fun(level:integer, message:string) -- Will be converted to this

---@param l Zenitha.log
---@return string
local function dumpLog(l)
    local lv=floor(l[1]/10)
    return format("\27[30m %s %s\27[7m%2d\27[0m%s\27[0m %s",os.date("%H:%M:%S",l[2]),logColor[lv],l[1],logStr[lv],l[3])
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
