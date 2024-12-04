local DEBUG={}


local loadTimeList,lastTimeStamp={},ZENITHA.timer.getTime()
---Use this a few times in main.lua to mark time used for loading,
---then use `DEBUG.logLoadTime()` to log the times
---@param msg string
function DEBUG.checkLoadTime(msg)
    local t=ZENITHA.timer.getTime()
    table.insert(loadTimeList,{msg=tostring(msg),time=t-lastTimeStamp})
    lastTimeStamp=t
end

---Log the times marked by `DEBUG.checkLoadTime()`
function DEBUG.logLoadTime()
    local maxLen=0
    for i=1,#loadTimeList do maxLen=math.max(maxLen,#loadTimeList[i].msg) end
    for i=1,#loadTimeList do
        local m=loadTimeList[i]
        LOG('info',
            m.msg..": "..
            (" "):rep(maxLen-#m.msg)..
            ("%d"):format(m.time*1000).." ms"
        )
    end
end

---Set metatable for _G, print messages when a new variable is created
function DEBUG.runVarMonitor()
    setmetatable(_G,{__newindex=function(self,k,v)
        print(">>"..k)
        print(debug.traceback():match("\n.-\n\t(.-): "))
        rawset(self,k,v)
    end})
end

---Set Visible collectgarbage call
function DEBUG.setCollectGarbageVisible()
    local _gc=collectgarbage
    collectgarbage=function()
        _gc()
        print(debug.traceback())
    end
end

---Shortcut for `print(debug.traceback())`
function DEBUG.trace()
    print(debug.traceback("DEBUG",2))
end

return DEBUG
