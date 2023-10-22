local socket=require("socket")

local S_confCHN=love.thread.getChannel("tcp_s_config")
local S_sendCHN=love.thread.getChannel("tcp_s_send")
local S_recvCHN=love.thread.getChannel("tcp_s_receive")

--- @type Zenitha.TCP._server
local server
--- @type table<string,Zenitha.TCP.Client>
local clients

--- @return Zenitha.TCP.MsgPack
local function parseMessage(message,id)
    local sep=message:find('|')
    if sep then -- Receiver(s) specified
        local recvIDs=STRING.split(message:sub(1,sep-1),',')
        local data=message:sub(sep+1)
        return {
            data=data,
            receiver=recvIDs,
            sender=id,
        }
    else -- Broadcast
        return {
            data=message,
            sender=id,
        }
    end
end

--- @param data string
--- @param receiver Zenitha.TCP.recvID
--- @param sender Zenitha.TCP.sendID
local function sendMessage(data,receiver,sender)
    if receiver==nil then
        for _,client in next,clients do
            if client.id~=sender then
                client.conn:send(sender..'|'..data)
            end
        end
    elseif type(receiver)=='string' then
        if receiver=='0' then
            S_recvCHN:push{
                data=data,
                sender=sender,
            }
        elseif clients[receiver] then
            clients[receiver].conn:send(sender..'|'..data)
        else
            print("Client '"..receiver.."' does not exist")
        end
    elseif type(receiver)=='table' then
        for _,id in next,receiver do
            sendMessage(data,id,sender)
        end
    end
end

local function serverLoop()
    local nextClientId=1
    clients={}

    while true do
        local config=S_confCHN:pop()
        if config then
            if config.action=='close' then
                server:close()
                return
            elseif config.action=='kick' then
                local c=clients[config.id]
                if c then
                    c.conn:close()
                end
            end
        end
        do
            local conn,err=server:accept();
            if not err then
                --- @type Zenitha.TCP.Client
                local c={
                    id=tostring(nextClientId),
                    conn=conn,
                    sockname=conn:getsockname(),
                    timestamp=os.time(),
                }
                print(c.sockname.." connected")
                c.conn:settimeout(0.001)
                clients[c.id]=c

                nextClientId=nextClientId+1
            end
        end

        --- @type Zenitha.TCP.MsgPack
        local data=S_sendCHN:pop()
        if data then
            sendMessage(data.data,'0','0')
        end

        for id,client in next,clients do
            local message,err,partial=client.conn:receive()
            if message then
                print(id..": "..message)
                local pack=parseMessage(message,id)
                sendMessage(pack.data,pack.receiver,id)
            end
        end
    end
end

while true do
    local port=S_confCHN:demand()
    local err
    server,err=socket.bind('*',port)
    if err then
        S_recvCHN:push{
            success=false,
            message="Cannot bind to ('0.0.0.0':"..port.."): "..err,
        }
    else
        print("Server started on port "..port)
        server:settimeout(0.001)
        S_recvCHN:push{success=true}
        serverLoop()
    end
end
