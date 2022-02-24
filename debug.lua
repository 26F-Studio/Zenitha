local yield=coroutine.yield
local DEBUG={}

-- Use DEBUG.checkLoadTime(mes) a few times in main.lua to mark time used for loading
-- Then use DEBUG.logLoadTime() to log the times
local loadTimeList,lastTimeStamp={},love.timer.getTime()
function DEBUG.checkLoadTime(mes)
    assert(type(mes)=='string',"DEBUG.checkLoadTime(mes): mes must be string")
    table.insert(loadTimeList,("%-26s \t%.3fs"):format(mes..":",love.timer.getTime()-lastTimeStamp))
    lastTimeStamp=love.timer.getTime()
end
function DEBUG.logLoadTime()
    for i=1,#loadTimeList do LOG(loadTimeList[i]) end
end

function DEBUG.runVarMonitor()
    setmetatable(_G,{__newindex=function(self,k,v)
        print('>>'..k)
        print(debug.traceback():match("\n.-\n\t(.-): "))
        rawset(self,k,v)
    end})
end

-- Wait for the scene swapping animation to finish
function DEBUG.yieldUntilNextScene()
    while SCN.swapping do yield() end
end

function DEBUG.yieldN(frames)
    for _=1,frames do yield() end
end

function DEBUG.yieldT(time)
    local t=love.timer.getTime()
    while love.timer.getTime()-t<time do yield() end
end

return DEBUG
