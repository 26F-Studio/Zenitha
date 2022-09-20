local sendCHN=love.thread.getChannel('inputChannel')
local recvCHN=love.thread.getChannel('outputChannel')

local threadCode=[[
    local http=require'socket.http'
    local ltn12=require'ltn12'

    local sendCHN=love.thread.getChannel('inputChannel')
    local recvCHN=love.thread.getChannel('outputChannel')

    while true do
        local arg=sendCHN:demand()

        local data={}
        local _,code,detail=http.request{
            method=arg.method,
            url=arg.url,
            headers=arg.headers,
    
            sink=ltn12.sink.table(data),
        }

        recvCHN:push{
            arg.pool or '_default',
            code,
            table.concat(data),
            detail
        }
    end
]]

local threads={}
local threadCount=1

local msgPool=setmetatable({},{
    __index=function(self,k)
        self[k]={}
        return self[k]
    end
})
local msgCount=0

local trigInterval=.626
local trigTime=0

local HTTP={}

function HTTP.request(arg)
    arg.method=arg.method or arg.body and 'POST' or 'GET'
    assert(type(arg.url)=='string',"Field 'url' need string, get "..type(arg.url))
    assert(arg.headers==nil or type(arg.headers)=='table',"Field 'headers' need table, get "..type(arg.headers))

    if arg.method=='POST' then
        if arg.body~=nil then
            assert(type(arg.body)=='table',"Field 'body' need table, get "..type(arg.body))
            arg.body=JSON.encode(arg.body)
            local headers={
                ['Content-Type']="application/json",
                ['Content-Length']=#arg.body,
            } if arg.headers then TABLE.cover(arg.headers,headers) end
        end
    end

    sendCHN:push(arg)
end

function HTTP.reset()
    for i=1,#threads do threads[i]:release() end
    TABLE.clear(msgPool)
    sendCHN:clear()
    recvCHN:clear()
    for i=1,threadCount do
        threads[i]=love.thread.newThread(threadCode)
        threads[i]:start()
    end
end
function HTTP.setInterval(interval)
    if interval<=0 then interval=1e99 end
    assert(type(interval)=='number',"HTTP.setInterval(interval): interval must be number")
    trigInterval=interval
end
function HTTP.pollMsg(pool)
    if not (type(pool)=='nil' or type(pool)=='string') then error("function HTTP.pollMsg(pool): pool must be nil or string") end
    HTTP.update()
    local p=msgPool[pool or '_default']
    if #p>0 then
        msgCount=msgCount-1
        return table.remove(p)
    end
end

function HTTP.update(dt)
    if dt then
        trigTime=trigTime+dt
        if trigTime>trigInterval then
            trigTime=trigTime%trigInterval
        else
            return
        end
    end
    while recvCHN:getCount()>0 do
        local m=recvCHN:pop()
        table.insert(msgPool[m[1]],{
            code=m[2],
            body=m[3],
            detail=m[4],
        })
        msgCount=msgCount+1
    end
end

setmetatable(HTTP,{__call=function(self,arg)
    return self.request(arg)
end,__metatable=true})

HTTP.reset()

return HTTP
