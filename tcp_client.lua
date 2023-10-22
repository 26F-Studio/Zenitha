local socket=require("socket")

local C_confCHN=love.thread.getChannel("tcp_c_config")
local C_sendCHN=love.thread.getChannel("tcp_c_send")
local C_recvCHN=love.thread.getChannel("tcp_c_receive")

--- @type Zenitha.TCP._server
local server

--- @return Zenitha.TCP.MsgPack
local function parseMessage(message)
    local sep=message:find('|')
    return sep and {
        data=message:sub(sep+1),
        sender=message:sub(1,sep-1),
    } or {data=message}
end

local function serverLoop()
    while true do
        local config=C_confCHN:pop()
        if config then
            if config.action=='close' then
                server:close()
                return
            end
        end

        local message,status,partial=server:receive()
        if message then C_recvCHN:push(parseMessage(message)) end
        if status=='closed' then return end

        --- @type Zenitha.TCP.MsgPack
        local data=C_sendCHN:pop()
        if data then
            if type(receiver)=='table' then receiver=table.concat(receiver,',') end
            server:send(receiver..'|'..data)
        end
    end
end

while true do
    local port=C_confCHN:demand()
    local err
    server,err=socket.tcp()
    if err then
        C_recvCHN:push{
            success=false,
            message="Cannot bind to ('0.0.0.0':"..port.."): "..err,
        }
    else
        server:settimeout(0.001)
        C_recvCHN:push{success=true}
        serverLoop()
    end
end
