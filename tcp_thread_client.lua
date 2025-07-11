local socket=require'socket'
---@type Zenitha.Json
local JSON=require((...)..'json')

local function printf(str,...) print(str:format(...)) end

local C_confCHN=love.thread.getChannel("tcp_c_config")
local C_rspsCHN=love.thread.getChannel("tcp_c_response")
local C_sendCHN=love.thread.getChannel("tcp_c_send")
local C_recvCHN=love.thread.getChannel("tcp_c_receive")

---@type LuaSocket.client
local client

---Send datapack with sender's ID
---@param pack Zenitha.TCP.MsgPack
local function sendMessage(pack)
    local suc,dataStr=pcall(JSON.encode,pack)
    if not suc then
        printf("Error in encoding data to json: %s",dataStr)
        return
    end
    client:send(dataStr..'\n')
end

local partialDataBuffer=''
local function clientLoop()
    while true do
        -- Process config action
        ---@type Zenitha.TCP.ConfigMsg
        local cfg=C_confCHN:pop()
        if cfg then
            if cfg.action=='close' then
                client:close()
                printf("[TCP_C] Disconnected from server")
                return
            elseif cfg.action=='subTopic' then
                sendMessage{req='topic.sub',data=cfg.data}
            elseif cfg.action=='unsubTopic' then
                sendMessage{req='topic.unsub',data=cfg.data}
            end
        end

        -- Send Data
        ---@type Zenitha.TCP.MsgPack
        local pack=C_sendCHN:pop()
        if pack then sendMessage(pack) end

        -- Receive data
        local message,err,partial=client:receive('*l')
        if message then
            message=partialDataBuffer..message
            partialDataBuffer=''
            local suc,recvPack=pcall(JSON.decode,message) ---@type boolean, Zenitha.TCP.MsgPack
            if suc then
                C_recvCHN:push(recvPack)
            else
                printf("[TCP_C] Error in decoding message: %s",recvPack)
            end
        elseif err=='timeout' then
            if partial then
                partialDataBuffer=partialDataBuffer..partial
            end
        elseif err=='closed' then
            printf("[TCP_C] Server disconnected")
            return
        end
    end
end

while true do
    local ip=C_confCHN:demand()
    local port=C_confCHN:demand()
    local err
    client,err=socket.connect(ip,port)
    if err then
        C_rspsCHN:push{
            success=false,
            message=("Cannot bind to %s:%s, reason: %s"):format(ip,port,err),
        }
    else
        printf("[TCP_C] Connected to %s:%s",ip,port)
        client:settimeout(0.01)
        C_rspsCHN:push{success=true}
        clientLoop()
    end
    C_rspsCHN:push(false)
end
