-- use LOG(message) to print messages

local ins=table.insert

local startDate=os.date("%Y/%m/%d %A")
local logs={}

local function log(message)
    ins(logs,os.date("[%H:%M:%S] ")..message)
end

local LOG=setmetatable({},{
    __call=function(_,message)
        print(message)
        log(message)
    end,
    __metatable=true,
})

---Get raw logs data
---@return string[] @READ ONLY, DO NOT MODIFY
function LOG.getLogs()
    return logs
end

---Get all logged strings as a big string
---@return string
function LOG.getString()
    return
        STRING.repD("$1 $2  logs  $3\n",
            Zenitha.getAppName(),
            Zenitha.getVersionText(),
            startDate
        )..table.concat(logs,"\n")
end

return LOG
