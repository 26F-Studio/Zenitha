--- @alias Zenitha.TCP.id 0|number|number[] 0 = broadcast, 1+ = clients

--- @class Zenitha.TCP.Client
--- @field client userdata
--- @field id number Starts from 1

--- @class Zenitha.TCP.Message
--- @field sender number 0 = server, 1+ = clients
--- @field data table

local TCP={}



local S_thread=love.thread.newThread("Zenitha/tcp_server.lua"):start()
--- @type boolean
local S_running=false
--- @type userdata[]
local S_clients={}
local S_confCHN=love.thread.getChannel("tcp_s_config")
local S_sendCHN=love.thread.getChannel("tcp_s_send")
local S_recvCHN=love.thread.getChannel("tcp_s_receive")

--- Get client connection status
--- @return boolean
function TCP.S_isRunning()
    return S_running
end

--- Start server
--- @param port number
function TCP.S_start(port)
    S_confCHN:push(port)
    local result=S_confCHN:demand()
    if result.success then
        S_running=true
    else
        MSG.new('error', result.message)
    end
end

--- Stop the TCP server
function TCP.S_stop()
    S_confCHN:push("stop")
    S_recvCHN:clear()
    TABLE.cut(S_clients)
    S_running=false
end

--- Disconnect a client
--- @param id Zenitha.TCP.id
function TCP.S_kick(id)
    if S_running then
    end
end

--- Send data to client(s)
--- @param data table
--- @param id Zenitha.TCP.id
function TCP.S_send(data,id)
    S_sendCHN:push({
        data=data,
        id=id,
    })
end



--- @type love.Thread
local C_thread=love.thread.newThread("Zenitha/tcp_client.lua"):start()
--- @type boolean
local C_running=false
--- @type Zenitha.TCP.Message[]
local C_buffer={}
local C_confCHN=love.thread.getChannel("tcp_c_config")
local C_sendCHN=love.thread.getChannel("tcp_c_send")
local C_recvCHN=love.thread.getChannel("tcp_c_receive")

--- Get client connection status
--- @return boolean
function TCP.C_isRunning()
    return C_running
end

--- Connect to server
--- @param ip string
--- @param port number
function TCP.C_connect(ip,port)
    C_sendCHN:push(ip)
    C_sendCHN:push(port)
    C_running=true
end

--- Disconnect from the server
function TCP.C_disconnect()
    C_sendCHN:push("stop")
    C_recvCHN:clear()
    TABLE.cut(C_buffer)
    C_running=false
end

--- Send data to the server
--- @param data table
--- @param id Zenitha.TCP.id
function TCP.C_send(data,id)
    STRING.packTable(data)
end

--- Receive data from the server
--- @return Zenitha.TCP.Message
function TCP.C_receive()
    return {id={},data=""}
end

return TCP
