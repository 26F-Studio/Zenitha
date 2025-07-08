local socket=require'socket'
require'love.timer'
---@type Zenitha.TableExt
local TABLE=require((...)..'tableExtend')
---@type Zenitha.Json
local JSON=require((...)..'json')

local ins,rem=table.insert,table.remove
local function printf(str,...) print(str:format(...)) end

local printEvent=true and function(str,...) printf("[TCP_S EVNT] "..str,...) end or function()end
local printMsg=false and function(str,...) printf("[TCP_S MESG] "..str,...) end or function()end
local printException=true and function(str,...) printf("[TCP_S WARN] "..str,...) end or function()end

local S_confCHN=love.thread.getChannel("tcp_s_config")
local S_rspsCHN=love.thread.getChannel("tcp_s_response")
local S_sendCHN=love.thread.getChannel("tcp_s_send")
local S_recvCHN=love.thread.getChannel("tcp_s_receive")

local server ---@type LuaSocket.server
local clients ---@type table<string, Zenitha.TCP.Client>
local partialDataBuffer ---@type table<Zenitha.TCP.sendID, string>
local topicList={} ---@type table<string, Zenitha.TCP.Topic>
local maxTopicCount=26 ---@type number

local allowBroadcast=true ---@type boolean Allow client sending broadcast message
local allowMessage=true ---@type boolean Allow client sending direct message to specified client(s)
local allowTopic=true ---@type boolean Allow client sending topic messages and sub/unsub requests

local topicTemp={
    maxSub=26,
    maxAliveTime=26,
    sub={},
}

---Send datapack with sender's ID
---@param pack Zenitha.TCP.MsgPack
---@param sender Zenitha.TCP.sendID
local function sendMessage(pack,sender)
    if sender then
        local filter
        if pack.topic then
            if not allowTopic then filter='topic' end
        elseif pack.receiver then
            if not allowMessage then filter='direct' end
        else
            if not allowBroadcast then filter='broadcast' end
        end
        if filter then
            return printException("client %s send illegal %s message",sender,filter)
        end
    end

    ---@type Zenitha.TCP.MsgPack
    local sendPack={
        event=pack.event,
        data=pack.data,
        topic=pack.topic,
        sender=sender,
    }
    local suc,dataStr=pcall(JSON.encode,sendPack)
    if not suc then
        printf("Error in encoding data to json: %s",dataStr)
        return
    end

    if pack.topic then
        -- Send to specified topic subscribers
        local topic=topicList[pack.topic]
        if not topic then
            return printException("Client %s send to non-exist topic '%s'",sender,pack.topic)
        end
        if sender and not TABLE.find(topic.sub,sender) then
            return printException("Client %s send to topic '%s' without sub",sender,pack.topic)
        end
        for i=1,#topic.sub do
            local client=clients[topic.sub[i]]
            if client then
                client.conn:send(dataStr..'\n')
            end
        end
    elseif pack.receiver then
        -- Send to specified ID(s)
        local receiver=type(pack.receiver)=='table' and pack.receiver or {pack.receiver}
        for i=1,#receiver do
            local recvID=receiver[i]
            if not clients[recvID] then
                return printException("Client %s send to non-exist client %s",sender,recvID)
            end
            clients[recvID].conn:send(dataStr..'\n')
        end
    else
        -- Send to everyone
        for _,client in next,clients do
            client.conn:send(dataStr..'\n')
        end
    end
end

local function kickClient(idList)
    for i=1,#idList do
        local id=idList[i]
        local client=clients[id]
        if client then
            client.conn:close()
            printEvent("Kicked %s",client.sockname)
            clients[id]=nil
            partialDataBuffer[id]=nil
        else
            printException("Kick non-exist client %s",id)
        end
    end
end
local function setPermission(flags)
    if flags.broadcast~=nil then
        allowBroadcast=flags.broadcast
        printEvent("Allow Broadcast: ",tostring(allowBroadcast))
    end
    if flags.message~=nil then
        allowMessage=flags.message
        printEvent("Allow Direct Message: ",tostring(allowMessage))
    end
    if flags.topic~=nil then
        allowTopic=flags.topic
        for _,topic in next,topicList do topic.sub={} end
        printEvent("Allow Topic: ",tostring(allowTopic))
    end
end
local function createTopic(data)
    if TABLE.getSize(topicList)>=maxTopicCount then
        S_rspsCHN:push{success=false}
        printException("Failed to create topic: max count reached (%d)",maxTopicCount)
    elseif topicList[data.name] then
        S_rspsCHN:push{success=false}
        printException("Failed to create topic '%s': already exists",data.name)
    else
        ---@type Zenitha.TCP.Topic
        local topic={
            name=data.name,
            createTime=love.timer.getTime(),
            maxAliveTime=data.maxSub or topicTemp.maxAliveTime,
            maxSub=data.maxAliveTime or topicTemp.maxSub,
            sub={},
        }
        topicList[data.name]=topic
        S_rspsCHN:push{success=true}
        printEvent("Topic '%s' created",data.name)
    end
end
local function closeTopic(name)
    local t=topicList[name]
    if not t then
        return printException("Failed to close topic '%s': not exist",name)
    end
    sendMessage({
        event='topic.close',
        topic=name,
    })
    topicList[name]=nil
    printEvent("Topic '%s' closed",name)
end

local function clientSubTopic(recvPack,id)
    if not allowTopic then
        return printException("Client %s send illegal sub request",id)
    end
    local topic=topicList[recvPack.data]
    if not topic then
        return printException("Client %s sub a non-exist topic '%s'",id,recvPack.data)
    end
    if TABLE.find(topic.sub,id) then
        return printException("Client %s sub already-subscribed topic '%s'",id,recvPack.data)
    end
    ins(topic.sub,id)
    sendMessage({
        event='client.sub',
        topic=recvPack.data,
        data=id,
    })
    printEvent("Client %s sub topic '%s'",id,recvPack.data)
end
local function clientUnsubTopic(recvPack,id)
    if not allowTopic then
        return printException("Client %s send illegal unsub request",id)
    end
    local topic=topicList[recvPack.data]
    if not topic then
        return printException("Client %s unsub a non-exist topic '%s'",id,recvPack.data)
    end
    local p=TABLE.find(topic.sub,id)
    if not p then
        return printException("Client %s unsub a non-subscribed topic '%s'",id,recvPack.data)
    end
    rem(topic.sub,p)
    sendMessage({
        event='client.unsub',
        topic=recvPack.data,
        data=id,
    })
    printEvent("Client %s unsub topic '%s'",id,recvPack.data)
end

local function serverLoop()
    local newClientId=1
    clients={}
    partialDataBuffer={}

    while true do
        -- Process config action
        ---@type Zenitha.TCP.ConfigMsg
        local cfg=S_confCHN:pop()
        if cfg then
            if cfg.action=='close' then
                server:close()
                printEvent("Server closed")
                return
            elseif cfg.action=='kick' then
                kickClient(cfg.data)
            elseif cfg.action=='setPermission' then
                setPermission(cfg.data)
            elseif cfg.action=='setMaxTopic' then
                maxTopicCount=cfg.data
            elseif cfg.action=='getTopicInfo' then
                S_rspsCHN:push(TABLE.copyAll(topicList))
            elseif cfg.action=='createTopic' then
                createTopic(cfg.data)
            elseif cfg.action=='closeTopic' then
                closeTopic(cfg.data)
            end
        end

        -- Accept new connection
        do
            local conn,err=server:accept()
            if not err then
                ---@type Zenitha.TCP.Client
                local c={
                    id=tostring(newClientId),
                    conn=conn,
                    sockname=conn:getsockname(),
                    timestamp=os.time(),
                }
                c.conn:settimeout(0.01)
                clients[c.id]=c
                partialDataBuffer[c.id]=''
                newClientId=newClientId+1
                S_recvCHN:push{
                    event='client.connect',
                    sender=c.id,
                }
                printEvent("%s connected",c.sockname)
            end
        end

        -- Send Data
        ---@type Zenitha.TCP.MsgPack?
        local pack=S_sendCHN:pop()
        if pack then sendMessage(pack) end

        -- Receive data
        for id,client in next,clients do
            local message,err,partial=client.conn:receive('*l')
            if message then
                printMsg("(%s) %s",id,message)
                message=partialDataBuffer[id]..message
                partialDataBuffer[id]=''

                ---@type boolean, Zenitha.TCP.MsgPack
                local suc,recvPack=pcall(JSON.decode,message)
                if suc then
                    if recvPack.req then
                        -- Config message
                        if recvPack.req=='topic.sub' then
                            clientSubTopic(recvPack,id)
                        elseif recvPack.req=='topic.unsub' then
                            clientUnsubTopic(recvPack,id)
                        else
                            printException("unknown req from client %s: %s",id,tostring(recvPack.req))
                        end
                    else
                        -- Common message
                        sendMessage(recvPack,id)
                    end
                    recvPack.sender=id
                    S_recvCHN:push(recvPack)
                else
                    printf("Error in encoding data to json: %s",recvPack)
                    return
                end
            elseif err=='timeout' then
                if partial and partial[1] then
                    partialDataBuffer[id]=partialDataBuffer[id]..partial
                    printMsg("(p%s) %s",id,partial)
                end
            elseif err=='closed' then
                partialDataBuffer[id]=nil
                clients[id]=nil
                S_recvCHN:push{
                    event='client.disconnect',
                    sender=id,
                }
                printEvent("%s disconnected",client.sockname)
            end
        end

        -- Update topics
        for name,topic in next,topicList do
            if #topic.sub==0 then
                if not topic.startIdleTime then
                    topic.startIdleTime=love.timer.getTime()
                else
                    if love.timer.getTime()-topic.startIdleTime>topic.maxAliveTime then
                        closeTopic(name)
                    end
                end
            elseif topic.startIdleTime then
                topic.startIdleTime=nil
            end
        end
    end
end

while true do
    local port=S_confCHN:demand()
    local err
    server,err=socket.bind('*',port)
    if err then
        S_rspsCHN:push{
            success=false,
            message=("Cannot bind to port %s, reason: %s"):format(port,err),
        }
    else
        printEvent("Server started on port %d",port)
        server:settimeout(0.01)
        S_rspsCHN:push{success=true}
        serverLoop()
    end
end
