if not love.thread then
    LOG("HTTP lib is not loaded (need love.thread)")
    return setmetatable({},{
        __index=function(_,k)
            error("attempt to use HTTP."..k..", but HTTP lib is not loaded (need love.thread)")
        end,
    })
end

local printSend=false
local printRecv=false

---@class Zenitha.HttpRequest
---@field body? table | string must be table if given, will be encoded to json
---@field pool? string default to `'_default'` if not given
---@field method? string default to `'POST'` if body is given, `'GET'` otherwise
---@field headers? table
---@field url? string default to the url set with HTTP.setHost
---@field path? string append to url
---@field _poolPtr? string internal use only
---@field _destroy? true internal use only
---@field printSend? true
---@field printRecv? true

local sendCHN=love.thread.getChannel('inputChannel')
local recvCHN=love.thread.getChannel('outputChannel')

local getCount=sendCHN.getCount

local threads={}
local threadCount=0

---@language LUA
local threadCode=[[
    local id=...
    local printSend,printRecv

    local http=require'socket.http'
    local ltn12=require'ltn12'

    local sendCHN=love.thread.getChannel('inputChannel')
    local recvCHN=love.thread.getChannel('outputChannel')

    while true do
        local arg=sendCHN:demand()

        printSend,arg.printSend=arg.printSend
        printRecv,arg.printRecv=arg.printRecv

        if arg._destroy then
            recvCHN:push{
                destroy=true,
                id=id,
            }
            break
        end

        if printSend then
            print("\n------SEND------")
            for k,v in next,arg do print(k,v) end
        end

        local data={}
        local _,code,detail=http.request{
            method=arg.method,
            url=arg.url,
            headers=arg.headers,
            source=ltn12.source.string(arg.body),

            sink=ltn12.sink.table(data),
        }

        local result={
            pool=arg.pool,
            _poolPtr=arg._poolPtr,
            code=code,
            body=table.concat(data),
            detail=detail,
        }

        if printRecv then
            print("\n------RECV------")
            for k,v in next,result do print(k,v) end
        end
        recvCHN:push(result)
    end
]]

local msgPool=setmetatable({},{
    __index=function(self,k)
        self[k]={}
        return self[k]
    end,
})

local HTTP={
    _msgCount=0,
    _host=false,
}

local function addThread(num)
    for i=1,26 do
        if num<=0 then break end
        if not threads[i] then
            threads[i]=love.thread.newThread(threadCode)
            threads[i]:start(i)
            threadCount=threadCount+1
            num=num-1
        end
    end
end

---Send a HTTP request
---```
---    HTTP.request{
---        pool='login',
---        url='example.com',
---        path='/api/v1/userlogin',
---        headers={
---            ['User-Agent']='Zenitha',
---        },
---        body={username='user'},
---    }
---    local res
---    repeat res=HTTP.pollMsg('login') until res
---    print(res.code,res.body)
---```
---@param arg Zenitha.HttpRequest
function HTTP.request(arg)
    arg.method=arg.method or arg.body and 'POST' or 'GET'
    if arg.url then
        assertf(type(arg.url)=='string',"HTTP.request(arg): arg.url need string, got %s",arg.url)
        if arg.url:sub(1,7)~='http://' then arg.url='http://'..arg.url end
    else
        arg.url=HTTP._host or error("HTTP.request(arg): arg.url need string, or set default host with HTTP.setHost")
    end
    if arg.path then
        assertf(type(arg.path)=='string',"HTTP.request(arg): arg.path need string, got %s",arg.path)
        arg.url=arg.url..arg.path
    end
    assertf(arg.headers==nil or type(arg.headers)=='table',"HTTP.request(arg): arg.headers need table, got %s",arg.headers)

    if arg.body then
        if not arg.headers then arg.headers={} end
        if type(arg.body)=='table' then
            local suc
            suc,arg.body=pcall(JSON.encode,arg.body)
            assert(suc,"HTTP.request(arg): arg.body json-encoding error")
            arg.headers['Content-Type']='application/json'
            arg.headers['Content-Length']=#arg.body
        elseif type(arg.body)=='string' then
            arg.headers['Content-Type']='text/plain'
            arg.headers['Content-Length']=#arg.body
        else
            error("HTTP.request(arg): arg.body need table or string")
        end
    end

    if arg.pool==nil then arg.pool='_default' end
    arg._poolPtr=tostring(msgPool[arg.pool])

    if printSend then arg.printSend=true end
    if printRecv then arg.printRecv=true end

    sendCHN:push(arg)
end

---Kill all threads and clear all message pool
function HTTP.reset()
    for i=1,#threads do
        threads[i]:release()
        threads[i]=false
    end
    TABLE.clear(msgPool)
    sendCHN:clear()
    recvCHN:clear()
    addThread(threadCount)
end

---Set thread count
---@param n number 1-26
function HTTP.setThreadCount(n)
    assert(type(n)=='number' and n>=1 and n<=26 and n%1==0,"HTTP.setThreadCount(n): Need int in [1,26]")
    if n>threadCount then
        addThread(n-threadCount)
    else
        for _=n+1,threadCount do
            sendCHN:push{_destroy=true}
        end
    end
end

---Get thread count
---@return number
function HTTP.getThreadCount()
    return threadCount
end

---Clear a message pool
---@param pool? string pool name
function HTTP.clearPool(pool)
    if pool==nil then pool='_default' end
    assert(type(pool)=='string',"HTTP.clearPool(pool): Need string|nil")
    HTTP._msgCount=HTTP._msgCount-#msgPool[pool]
    msgPool[pool]={}
end

---Delete a message pool
---@param pool string pool name
function HTTP.deletePool(pool)
    assert(type(pool)=='string',"HTTP.deletePool(pool): Need string")
    assert(pool~='_default',"HTTP.deletePool(pool): You cannot delete _default pool")
    HTTP._msgCount=HTTP._msgCount-#msgPool[pool]
    msgPool[pool]=nil
end

---Poll a message from pool (specified if given)
---@param pool string | nil pool name
---@return table?
function HTTP.pollMsg(pool)
    if HTTP._msgCount==0 then return nil end
    if pool~=nil and type(pool)~='string' then error("HTTP.pollMsg(pool): Need string|nil") end
    HTTP._update()
    local p=msgPool[pool or '_default']
    if p[1] then
        HTTP._msgCount=HTTP._msgCount-1
        return table.remove(p,1)
    end
end

---Set default host
---@param host string host url
function HTTP.setHost(host)
    assert(type(host)=='string',"HTTP.setHost(host): Need string")
    if host:sub(1,7)~='http://' then host='http://'..host end
    HTTP._host=host
end

---Update receiving channel and put results into pool (called by Zenitha)
function HTTP._update()
    while getCount(recvCHN)>0 do
        local m=recvCHN:pop()
        if m.destroy then
            threads[m.id]:release()
            threads[m.id]=false
        elseif tostring(msgPool[m.pool])==m._poolPtr then -- If pool were cleared, discard this datapack
            table.insert(msgPool[m.pool],{
                code=m.code,
                body=m.body,
                detail=m.detail,
            })
            HTTP._msgCount=HTTP._msgCount+1
        end
    end
end

setmetatable(HTTP,{
    __call=function(self,arg)
        return self.request(arg)
    end,
    __metatable=true,
})

HTTP.reset()

return HTTP
