--- @alias Zenitha.TCP.sendID '0'|string 0 = server/broadcast, 1+ = client id
--- @alias Zenitha.TCP.recvID Zenitha.TCP.sendID|string[] 0 = server/broadcast, 1+ = client id

--- @class Zenitha.TCP._server
--- @field settimeout function
--- @field accept function
--- @field send function
--- @field receive function
--- @field close function

--- @class Zenitha.TCP.Client
--- @field conn Zenitha.TCP._server
--- @field id string '1'|'2'|...
--- @field sockname string
--- @field timestamp number

--- @class Zenitha.TCP.MsgPack
--- @field data string
--- @field receiver Zenitha.TCP.recvID
--- @field sender? Zenitha.TCP.sendID

local TCP={}



local S_thread=love.thread.newThread('Zenitha/tcp_server.lua'); S_thread:start()
local S_running=false
local S_confCHN=love.thread.getChannel('tcp_s_config')
local S_sendCHN=love.thread.getChannel('tcp_s_send')
local S_recvCHN=love.thread.getChannel('tcp_s_receive')

--- Get client connection status
function TCP.S_isRunning()
    return S_running
end

--- Start server
--- @param port number
function TCP.S_start(port)
    TASK.new(function()
        local T=0
        while 1 do
            T=T+coroutine.yield()
            if T>1 then
                T=0
                if not S_thread:isRunning() then
                    print(S_thread:getError())
                    return
                end
            end
        end
    end)
    S_confCHN:push(port)
    local result=S_recvCHN:demand()
    if result.success then
        S_running=true
    else
        MSG.new('error', result.message)
    end
end

--- Stop the TCP server
function TCP.S_stop()
    S_confCHN:push{action='close'}
    S_sendCHN:clear()
    S_recvCHN:clear()
    S_running=false
end

--- Disconnect a client
--- @param id Zenitha.TCP.recvID
function TCP.S_kick(id)
    if S_running then
        S_confCHN:push{action='kick',id=id}
    end
end

--- Send data to client(s)
--- @param data table
--- @param id Zenitha.TCP.recvID
function TCP.S_send(data,id)
    --- @type Zenitha.TCP.MsgPack
    local pack={
        data=STRING.packTable(data),
        receiver=id,
    }
    S_sendCHN:push(pack)
end

--- Receive data from client(s)
--- @return Zenitha.TCP.MsgPack
function TCP.S_receive()
    return S_recvCHN:pop()
end



local C_thread=love.thread.newThread('Zenitha/tcp_client.lua'); C_thread:start()
local C_running=false
local C_confCHN=love.thread.getChannel('tcp_c_config')
local C_sendCHN=love.thread.getChannel('tcp_c_send')
local C_recvCHN=love.thread.getChannel('tcp_c_receive')

--- Get client connection status
function TCP.C_isRunning()
    return C_running
end

--- Connect to server
--- @param ip string
--- @param port number
function TCP.C_connect(ip,port)
    C_sendCHN:push(ip)
    C_sendCHN:push(port)
    local result=C_recvCHN:demand()
    if result.success then
        C_running=true
    else
        MSG.new('error', result.message)
    end
end

--- Disconnect from the server
function TCP.C_disconnect()
    C_confCHN:push{action='close'}
    C_sendCHN:clear()
    C_recvCHN:clear()
    C_running=false
end

--- Send data to server
--- @param data table
--- @param id Zenitha.TCP.recvID
function TCP.C_send(data,id)
    --- @type Zenitha.TCP.MsgPack
    local pack={
        data=STRING.packTable(data),
        receiver=id,
    }
    C_sendCHN:push(pack)
end

--- Receive data from server
--- @return Zenitha.TCP.MsgPack
function TCP.C_receive()
    return C_recvCHN:pop()
end

return TCP
