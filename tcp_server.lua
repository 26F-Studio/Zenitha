local socket=require("socket")
local S_confCHN=love.thread.getChannel("tcp_s_config")
local S_sendCHN=love.thread.getChannel("tcp_s_send")
local S_recvCHN=love.thread.getChannel("tcp_s_receive")

local function send(clients,data,id)
    if id==0 then
        for _,v in pairs(clients) do
            v:send(data)
        end
    elseif type(id)=='number' then
        clients[id]:send(data)
    else
        for _,v in pairs(id) do
            clients[v]:send(data)
        end
    end
end

local function serverLoop(server)
    local currentId=0 -- store the total connections
    local clients={}  -- e.g. clients[1] = 0xSocketAddress
    -- start the loop to listening connection
    while true do
        local config=S_confCHN:demand()
        if config.action=="stop" then
            server:close()
            break
        end
        do
            local connection,err=server:accept();
            if not err then
                currentId=currentId+1
                local client={
                    id=currentId,
                    connection=connection,
                    sockName=connection:getsockname(),
                    timestamp=os.time(),
                }
                client:settimeout(0.001)
                clients[client.id]=client
            end
        end

        local data=S_sendCHN:pop()
        if data then
            send(clients,data.data,data.id)
        end

        for id,client in pairs(clients) do
            local message,err,partial=client:receive() -- accept data from client
            -- 1,2,3,4|...
            if message then
                -- {id:idList,action:string,data:string}
                send(clients,"{id:client.id,data:data}",0)-- todo
            else
                print(err)
            end
        end
    end
end

while true do
    --- @type {action:string,data:{}}
    local config=S_confCHN:demand()
    if config.action=="connect" then
        local server,err=socket.bind("*", config.data.port)
        if err then
            S_confCHN:push({
                success=false,
                message="Cannot bind to ('0.0.0.0':"..config.data.port.."): "..err,
            })
        else
            server:settimeout(0.001)
            S_confCHN:push({success=true})
            serverLoop(server)
        end
    end
end
