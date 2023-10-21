--- @alias Zenitha.TCP.id 0|number|number[] 0 = broadcast, 1+ = clients

--- @class Zenitha.TCP.Client
--- @field client userdata
--- @field id number Starts from 1

--- @class Zenitha.TCP.Message
--- @field sender number 0 = server, 1+ = clients
--- @field data string

local TCP={}



local S_thread=love.thread.newThread("Zenitha/tcp_server.lua"):start()
--- @type boolean
local S_running=false
--- @type userdata[]
local S_clients={}
local S_sendCHN=love.thread.getChannel("tcp_send")
local S_recvCHN=love.thread.getChannel("tcp_receive")

--- Get client connection status
--- @return boolean
function TCP.S_isRunning()
    return S_running
end

--- Start server
--- @param port number
function TCP.S_start(port)
    S_sendCHN:push(port)
    S_running=true
end

--- Stop the TCP server
function TCP.S_stop()
    S_sendCHN:push("stop")
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
--- @param data string
--- @param id Zenitha.TCP.id
function TCP.S_send(data,id)

end



--- @type love.Thread
local C_thread=love.thread.newThread("Zenitha/tcp_client.lua"):start()
--- @type boolean
local C_running=false
--- @type Zenitha.TCP.Message[]
local C_buffer={}
local C_sendCHN=love.thread.getChannel("tcp_send")
local C_recvCHN=love.thread.getChannel("tcp_receive")

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
--- @param data string
--- @param id Zenitha.TCP.id
function TCP.C_send(data,id)

end

--- Receive data from the server
--- @return Zenitha.TCP.Message
function TCP.C_receive()

    return {id={},data=""}
end

return TCP
