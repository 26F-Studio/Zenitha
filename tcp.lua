if not love.thread then
    LOG("CP lib is not loaded (need love.thread)")
    return setmetatable({},{
        __index=function(_,k)
            error("attempt to use TCP."..k..", but TCP lib is not loaded (need love.thread)")
        end
    })
end

---@alias Zenitha.TCP.sendID string 0 = server, 1+ = client id
---@alias Zenitha.TCP.recvID Zenitha.TCP.sendID | Zenitha.TCP.sendID[] | nil 0 = server, 1+ = client id, nil = broadcast

---@class Zenitha.TCP.Client
---@field conn LuaSocket.client
---@field id string '1' | '2' | ...
---@field sockname string
---@field timestamp number

---@class Zenitha.TCP.MsgPack
---@field config? Zenitha.TCP.MsgCfg
---@field data? any
---@field sender? Zenitha.TCP.sendID
---@field receiver? Zenitha.TCP.recvID
---@field bus? Zenitha.TCP.busID

---@class Zenitha.TCP.ConfigMsg
---@field action Zenitha.TCP.ConfigMsgAction
---@field id string
---@field flag boolean
---@field count number
---@field time number
---@field bus string

local ins,rem=table.insert,table.remove

local TCP={}

local S_thread=love.thread.newThread(ZENITHA.path..'tcp_thread_server.lua'); S_thread:start(ZENITHA.path)
local S_running=false
local S_confCHN=love.thread.getChannel('tcp_s_config')
local S_sendCHN=love.thread.getChannel('tcp_s_send')
local S_recvCHN=love.thread.getChannel('tcp_s_receive')
---@async
local function S_daemonFunc()
    while true do
        TASK.yieldT(0.626)
        if not S_thread:isRunning() then
            print(S_thread:getError())
            return
        end
    end
end

local function checkRecvID(id)
    if id==nil then return end
    if type(id)=='number' then id=tostring(id)
    elseif type(id)=='string' then id={id}
    end
    for i=#id,1,-1 do
        if id[i]:find('[^0-9A-Za-z_]') then
            rem(id,i)
        end
    end
    return id
end

---Get client connection status
function TCP.S_isRunning()
    return S_running
end

---Start server
---@param port number 0~65535
function TCP.S_start(port)
    if S_running then return end
    assert(type(port)=='number' and port>=1 and port<=65535 and port%1==0,"TCP.S_start(port): Need 0~65535")
    TASK.removeTask_code(S_daemonFunc)
    TASK.new(S_daemonFunc)
    S_confCHN:push(port)
    local result=S_recvCHN:demand()
    if result.success then
        S_running=true
    else
        MSG.log('error',result.message)
    end
end

---Stop the TCP server
function TCP.S_stop()
    if not S_running then return end
    S_confCHN:push{action='close'}
    S_sendCHN:clear()
    S_recvCHN:clear()
    S_running=false
end

---Disconnect a client
---@param id Zenitha.TCP.recvID
function TCP.S_kick(id)
    if not S_running then return end
    S_confCHN:push{action='kick',id=checkRecvID(id)}
end

---Set whether brodcast is allowed or not
---@param flag boolean only `true` take effect
function TCP.S_setAllowBroadcast(flag)
    S_confCHN:push{action='setAllowBroadcast',flag=flag==true}
end

---Send data to client(s)
---@param data any must be lua or love object
---@param id Zenitha.TCP.recvID
function TCP.S_send(data,id)
    if not S_running then return end
    ---@type Zenitha.TCP.MsgPack
    local pack={
        data=data,
        receiver=checkRecvID(id),
    }
    S_sendCHN:push(pack)
end

---Receive data from client(s)
---@return Zenitha.TCP.MsgPack?
function TCP.S_receive()
    return S_recvCHN:pop()
end



local C_thread=love.thread.newThread(ZENITHA.path..'tcp_thread_client.lua'); C_thread:start(ZENITHA.path)
local C_running=false
local C_confCHN=love.thread.getChannel('tcp_c_config')
local C_sendCHN=love.thread.getChannel('tcp_c_send')
local C_recvCHN=love.thread.getChannel('tcp_c_receive')
---@async
local function C_daemonFunc()
    while true do
        TASK.yieldT(0.626)
        if not C_thread:isRunning() then
            print(C_thread:getError())
            return
        end
    end
end

---Get client connection status
function TCP.C_isRunning()
    return C_running
end

---Connect to server
---@param ip string
---@param port number
function TCP.C_connect(ip,port)
    if C_running then return end
    TASK.removeTask_code(C_daemonFunc)
    TASK.new(C_daemonFunc)
    C_confCHN:push(ip)
    C_confCHN:push(port)
    local result=C_recvCHN:demand()
    if result.success then
        C_running=true
    else
        MSG.log('error',result.message)
    end
end

---Disconnect from the server
function TCP.C_disconnect()
    if not C_running then return end
    C_confCHN:push{action='close'}
    C_sendCHN:clear()
    C_recvCHN:clear()
    C_running=false
end

---Send data to server
---@param data any must be lua or love object
---@param id Zenitha.TCP.recvID
function TCP.C_send(data,id)
    ---@type Zenitha.TCP.MsgPack
    local pack={
        data=data,
        receiver=checkRecvID(id),
    }
    C_sendCHN:push(pack)
end

---Receive data from server
---@return Zenitha.TCP.MsgPack?
function TCP.C_receive()
    return C_recvCHN:pop()
end



--------------------------------------------------------------
-- Use the following pub/sub features when you need more scalable communication.

---@alias Zenitha.TCP.busID string [0-9A-Za-z_]+
---@alias Zenitha.TCP.MsgCfg
---| 'bus.get' recv: data=Bus name list
---| 'bus.join' recv: data=joined client id
---| 'bus.quit' recv: data=quited client id
---| 'bus.close' recv: data=quited client id
---@alias Zenitha.TCP.ConfigMsgAction
---| 'bus.get' send
---| 'bus.join' send: bus=Bus name
---| 'bus.quit' send

---@class Zenitha.TCP.Bus
---@field name string
---@field createTime number
---@field maxMember number
---@field maxAliveTime number
---@field startIdleTime? number
---@field members table

local S_busRecvCHN=love.thread.getChannel('tcp_s_receiveBus')
local S_busPackBuffer={} ---@type Zenitha.TCP.MsgPack[]

local function checkBusName(name)
    assert(type(name)=='string' and not name:find('[^0-9A-Za-z_]'),"Need string of 0-9/A-Z/_")
end

---@param count number
function TCP.S_Bus_setMaxCount(count)
    assert(type(count)=='number' and count>0 and count%1==0,"TCP.S_Bus_setMaxCount(count): Need positive int")
    S_confCHN:push{action='setMaxBus',count=count}
end

---@param time number Negative numbers treated as 0
function TCP.S_Bus_setDefaultMaxAliveTime(time)
    assert(type(time)=='number' and time>=0,"TCP.S_Bus_setDefaultMaxAliveTime(time): Need number")
    S_confCHN:push{action='setBusMaxAliveTime',time=time}
end

---@param count number
function TCP.S_Bus_setDefaultMaxMemberCount(count)
    assert(type(count)=='number' and count>0 and count%1==0,"TCP.S_Bus_setMaxCount(count): Need positive int")
    S_confCHN:push{action='setBusMaxMember',count=count}
end

---@param name Zenitha.TCP.busID
---@param maxMember? number
---@param maxAliveTime? number
---@return boolean #Success or not, will fail when reached max count
function TCP.S_Bus_new(name,maxMember,maxAliveTime)
    if not S_running then return false end
    checkBusName(name)
    S_confCHN:push{
        action='bus.create',
        bus=name,
        maxMember=maxMember,
        maxAliveTime=maxAliveTime,
    }
    return S_recvCHN:demand().success
end

---@return string[] #List of Bus names
function TCP.S_Bus_get()
    if not S_running then return {} end
    S_confCHN:push{action='bus.get'}
    local list=S_recvCHN:demand()
    for i=#list,1,-1 do
        if not pcall(checkBusName,list[i]) then
            rem(list,i)
        end
    end
    return list
end

---@param name Zenitha.TCP.busID
function TCP.S_Bus_join(name)
    if not S_running then return false end
    checkBusName(name)
    S_confCHN:push{
        action='bus.join',
        bus=name,
    }
end

---@param name Zenitha.TCP.busID
function TCP.S_Bus_quit(name)
    checkBusName(name)
    S_confCHN:push{
        action='bus.quit',
        bus=name,
    }
end

---@param name Zenitha.TCP.busID
function TCP.S_Bus_del(name)
    if not S_running then return false end
    checkBusName(name)
    S_confCHN:push{
        action='bus.close',
        bus=name,
    }
end

---@param name Zenitha.TCP.busID
---@param data any must be lua or love object
function TCP.S_Bus_send(name,data)
    checkBusName(name)
    ---@type Zenitha.TCP.MsgPack
    local pack={
        data=data,
        bus=name,
    }
    S_sendCHN:push(pack)
end

---@param name Zenitha.TCP.busID
---@return Zenitha.TCP.MsgPack
function TCP.S_Bus_receive(name)
    checkBusName(name)
    while true do
        ---@type Zenitha.TCP.MsgPack
        local pack=S_busRecvCHN:pop()
        if not pack then break end
        ins(S_busPackBuffer,pack)
    end
    for i=1,#S_busPackBuffer do
        if S_busPackBuffer[i].bus==name then
            return rem(S_busPackBuffer,i)
        end
    end
end

local C_busRecvCHN=love.thread.getChannel("tcp_c_receiveBus")
local C_busPackBuffer={} ---@type Zenitha.TCP.MsgPack[]

---Send Bus getting request, receive data from C_receive
function TCP.C_Bus_get()
    if not C_running then return false end
    C_confCHN:push{action='bus.get'}
end

---@param name Zenitha.TCP.busID
function TCP.C_Bus_join(name)
    checkBusName(name)
    C_confCHN:push{
        action='bus.join',
        bus=name,
    }
end

---@param name Zenitha.TCP.busID
function TCP.C_Bus_quit(name)
    checkBusName(name)
    C_confCHN:push{
        action='bus.quit',
        bus=name,
    }
end

---@param name Zenitha.TCP.busID
---@param data any must be lua or love object
function TCP.C_Bus_send(name,data)
    checkBusName(name)
    ---@type Zenitha.TCP.MsgPack
    local pack={
        data=data,
        bus=name,
    }
    C_sendCHN:push(pack)
end

---@param name Zenitha.TCP.busID
---@return Zenitha.TCP.MsgPack
function TCP.C_Bus_receive(name)
    checkBusName(name)
    while true do
        ---@type Zenitha.TCP.MsgPack
        local pack=C_busRecvCHN:pop()
        if not pack then break end
        ins(C_busPackBuffer,pack)
    end
    for i=1,#C_busPackBuffer do
        if C_busPackBuffer[i].bus==name then
            return rem(C_busPackBuffer,i)
        end
    end
end

return TCP
