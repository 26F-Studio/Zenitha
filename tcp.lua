if not love.thread then
    LOG("CP lib is not loaded (need love.thread)")
    return setmetatable({},{
        __index=function(_,k)
            error("attempt to use TCP."..k..", but TCP lib is not loaded (need love.thread)")
        end,
    })
end

---@alias Zenitha.TCP.sendID string? target id, must be: `nil` server broadcast, `'1' '2'...` client id
---@alias Zenitha.TCP.recvID '0' | Zenitha.TCP.sendID | Zenitha.TCP.sendID[] | nil `'0'` server-only, `nil` broadcast, `'1' '2'...` client id
---@alias Zenitha.TCP.MsgEvent
---| 'client.connect' recv: sender=client id
---| 'client.disconnect' recv: sender=client id
---| 'client.sub' {data=client id, ...}
---| 'client.unsub' {data=client id, ...}
---| 'topic.close' ['topic'] = topic name string
---@alias Zenitha.TCP.Request
---| 'topic.sub' recv: sender=client id
---| 'topic.unsub' recv: sender=client id
---@alias Zenitha.TCP.ConfigMsgAction
---| 'close'
---| 'kick'
---| 'setPermission'
---| 'setMaxTopic'
---| 'getTopicInfo'
---| 'createTopic'
---| 'closeTopic'
---| 'subTopic' (client only)
---| 'unsubTopic' (client only)

---@class Zenitha.TCP.Client
---@field conn LuaSocket.client
---@field id string '1' | '2' | ...
---@field sockname string
---@field timestamp number

---@class Zenitha.TCP.MsgPack
---@field event? Zenitha.TCP.MsgEvent
---@field req? Zenitha.TCP.Request
---@field data? any
---@field sender? Zenitha.TCP.sendID
---@field receiver? Zenitha.TCP.recvID
---@field topic? Zenitha.TCP.topicID

---@class Zenitha.TCP.ConfigMsg
---@field action Zenitha.TCP.ConfigMsgAction
---@field data? any

---@param id Zenitha.TCP.recvID
local function checkRecvID(id)
    if id==nil then
        return
    elseif type(id)=='string' then
        if not (id=='' or id:find('[^0-9]')) then
            return id
        end
    elseif type(id)=='table' then
        for i=#id,1,-1 do
            if id[i]=='' or id[i]:find('[^0-9]') then
                table.remove(id,i)
            end
        end
        return id
    end
    return false
end

local function checkTopicName(name)
    if type(name)=='string' and name:byte()>=65 and not name:find('[^0-9A-Za-z_]') then
        return name
    else
        error("Need string of 0-9/A-Z/_ with non-digit leading")
    end
end

local TCP={}

local S_thread=love.thread.newThread(ZENITHA.path..'tcp_thread_server.lua'); S_thread:start(ZENITHA.path)
local S_running=false
local S_confCHN=love.thread.getChannel('tcp_s_config')
local S_rspsCHN=love.thread.getChannel('tcp_s_response')
local S_sendCHN=love.thread.getChannel('tcp_s_send')
local S_recvCHN=love.thread.getChannel('tcp_s_receive')

---@param pack Zenitha.TCP.ConfigMsg
local function S_pushConf(pack) S_confCHN:push(pack) end

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

---Get client connection status
function TCP.S_isRunning()
    if S_rspsCHN:pop()==false then S_running=false end
    return S_running
end

---Start server
---@param port number 0~65535
function TCP.S_start(port)
    if TCP.S_isRunning() then return end
    assert(type(port)=='number' and port>=1 and port<=65535 and port%1==0,"TCP.S_start(port): Need 0~65535")
    TASK.removeTask_code(S_daemonFunc)
    TASK.new(S_daemonFunc)
    S_confCHN:clear()
    S_rspsCHN:clear()
    S_confCHN:push(port)
    local result=S_rspsCHN:demand()
    if result.success then
        S_running=true
    else
        MSG.log('error',result.message)
    end
end

---Stop the TCP server
function TCP.S_stop()
    if not TCP.S_isRunning() then return end
    S_pushConf{action='close'}
    S_sendCHN:clear()
    S_recvCHN:clear()
    S_running=false
end

---Disconnect a client
---@param id Zenitha.TCP.recvID
function TCP.S_kick(id)
    if not TCP.S_isRunning() then return end
    local _id=checkRecvID(id)
    if _id~=false then
        S_pushConf{action='kick',data=_id}
    end
end

local function checkBoolean(v) if v==true then return true elseif v==false then return false end end

---Set whether Broadcast / Message / Topic are allowed or not, default to all `true`
---@param flag {broadcast:boolean, message:boolean, topic:boolean} non-boolean values will be ignored
function TCP.S_setPermission(flag)
    if not TCP.S_isRunning() then return end
    S_pushConf{action='setPermission',data={
        broadcast=checkBoolean(flag.broadcast),
        message=checkBoolean(flag.message),
        topic=checkBoolean(flag.topic),
    }}
end

---Send data to client(s)
---@param data any must be lua or love object
---@param id Zenitha.TCP.recvID | Zenitha.TCP.topicID
function TCP.S_send(data,id)
    if not TCP.S_isRunning() then return end
    ---@type Zenitha.TCP.MsgPack
    local pack
    if type(id)=='string' and id:byte()>=65 then
        pack={
            data=data,
            topic=checkTopicName(id),
        }
    else
        local _id=checkRecvID(id)
        if _id~=false then
            ---@type Zenitha.TCP.MsgPack
            pack={
                data=data,
                receiver=_id,
            }
        end
    end
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
local C_rspsCHN=love.thread.getChannel('tcp_c_response')
local C_sendCHN=love.thread.getChannel('tcp_c_send')
local C_recvCHN=love.thread.getChannel('tcp_c_receive')

---@param pack Zenitha.TCP.ConfigMsg
local function C_pushConf(pack) C_confCHN:push(pack) end

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
    if C_rspsCHN:pop()==false then C_running=false end
    return C_running
end

---Connect to server
---@param ip string
---@param port number
function TCP.C_connect(ip,port)
    if TCP.C_isRunning() then return end
    TASK.removeTask_code(C_daemonFunc)
    TASK.new(C_daemonFunc)
    C_confCHN:push(ip)
    C_confCHN:push(port)
    local result=C_rspsCHN:demand()
    if result.success then
        C_running=true
    else
        MSG.log('error',result.message)
    end
end

---Disconnect from the server
function TCP.C_disconnect()
    if not TCP.C_isRunning() then return end
    C_confCHN:push{action='close'}
    C_sendCHN:clear()
    C_recvCHN:clear()
    C_running=false
end

---Send data to server
---@param data any must be lua or love object
---@param id Zenitha.TCP.recvID | Zenitha.TCP.topicID
function TCP.C_send(data,id)
    if not TCP.C_isRunning() then return end
    ---@type Zenitha.TCP.MsgPack
    local pack
    if type(id)=='string' and id:byte()>=65 then
        pack={
            data=data,
            topic=checkTopicName(id),
        }
    else
        local _id=checkRecvID(id)
        if _id~=false then
            ---@type Zenitha.TCP.MsgPack
            pack={
                data=data,
                receiver=_id,
            }
        end
    end
    C_sendCHN:push(pack)
end

---Receive data from server
---@return Zenitha.TCP.MsgPack?
function TCP.C_receive()
    if not TCP.C_isRunning() then return end
    return C_recvCHN:pop()
end

--------------------------------------------------------------
-- Simple Publish-Subscribe Pattern model
-- Use the following Topic features when you need more scalable communication.

---@alias Zenitha.TCP.topicID string [0-9A-Za-z_]+ but not starting with digit

---@class Zenitha.TCP.Topic
---@field name string
---@field createTime number
---@field maxSub number
---@field maxAliveTime number
---@field startIdleTime? number
---@field sub table

---@param count number
function TCP.S_setMaxTopicCount(count)
    if not TCP.S_isRunning() then return end
    assert(type(count)=='number' and count>0 and count%1==0,"TCP.S_setMaxTopicCount(count): Need positive int")
    S_pushConf{action='setMaxTopic',data=count}
end

---@param name Zenitha.TCP.topicID
---@param maxSub? number default to 26 subscribers
---@param maxAliveTime? number default to 26s
---@return boolean # Success or not, will fail when reached max count
function TCP.S_createTopic(name,maxSub,maxAliveTime)
    if not TCP.S_isRunning() then return false end
    if not pcall(checkTopicName,name) then return false end
    S_rspsCHN:clear()
    S_pushConf{
        action='createTopic',
        data={
            name=name,
            maxSub=maxSub,
            maxAliveTime=maxAliveTime,
        },
    }
    return S_rspsCHN:demand().success
end

---@param name Zenitha.TCP.topicID
function TCP.S_closeTopic(name)
    if not TCP.S_isRunning() then return end
    S_pushConf{action='closeTopic',data=checkTopicName(name)}
end

---@return string[] # List of Topic names
function TCP.S_getTopicInfo()
    if not TCP.S_isRunning() then return {} end
    S_rspsCHN:clear()
    S_pushConf{action='getTopicInfo'}
    return S_rspsCHN:demand()
end

---@param name Zenitha.TCP.topicID
function TCP.C_subTopic(name)
    if not TCP.C_isRunning() then return end
    C_pushConf{
        action='subTopic',
        data=checkTopicName(name),
    }
end

---@param name Zenitha.TCP.topicID
function TCP.C_unsubTopic(name)
    if not TCP.C_isRunning() then return end
    C_pushConf{
        action='unsubTopic',
        data=checkTopicName(name),
    }
end

return TCP
