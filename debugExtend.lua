local DEBUG={}


local loadTimeList,lastTimeStamp={},love.timer.getTime()
---Use this a few times in main.lua to mark time used for loading,
---then use `DEBUG.logLoadTime()` to log the times
---@param msg string
function DEBUG.checkLoadTime(msg)
    table.insert(loadTimeList,("%-26s \t%.3fs"):format(tostring(msg)..":",love.timer.getTime()-lastTimeStamp))
    lastTimeStamp=love.timer.getTime()
end

---Log the times marked by `DEBUG.checkLoadTime()`
function DEBUG.logLoadTime()
    for i=1,#loadTimeList do LOG(loadTimeList[i]) end
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
