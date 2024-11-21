local printEvent=true
local printMsg=false
local printException=true

local zPath=(...):match('.+%.')

require'love.timer'
local socket=require'socket'
---@type Zenitha.TableExt
local TABLE=require(zPath..'tableExtend')
---@type Zenitha.Json
local JSON=require(zPath..'json')

local ins,rem=table.insert,table.remove
local function printf(str,...) print(str:format(...)) end

local S_confCHN=love.thread.getChannel("tcp_s_config")
local S_sendCHN=love.thread.getChannel("tcp_s_send")
local S_recvCHN=love.thread.getChannel("tcp_s_receive")
local S_recvBusCHN=love.thread.getChannel("tcp_s_receiveBus")

local server ---@type LuaSocket.server
local clients ---@type table<string, Zenitha.TCP.Client>
local partialDataBuffer ---@type table<Zenitha.TCP.sendID, string>
local busList={} ---@type table<number | string, Zenitha.TCP.Bus>
local maxBusCount=26 ---@type number
local allowBroadcast=true ---@type boolean

local busTemplate={
    maxMember=26,
    maxAliveTime=26,
    members={},
}

---Send datapack with sender's ID
---@param pack Zenitha.TCP.MsgPack
---@param sender Zenitha.TCP.sendID
local function sendMessage(pack,sender)
    ---@type Zenitha.TCP.MsgPack
    local sendPack={
        config=pack.config,
        data=pack.data,
        bus=pack.bus,
        sender=sender,
    }
    local suc,dataStr=pcall(JSON.encode,sendPack)
    if not suc then
        printf("Error in encoding data to json: %s",dataStr)
        return
    end

    if pack.bus then
        -- Send to specified bus subscribers
        local busName=pack.bus
        local bus=busList[busName]
        if bus then
            for i=1,#bus.members do
                if bus.members[i]=='0' then
                    S_recvBusCHN:push(sendPack)
                else
                    local client=clients[bus.members[i]]
                    if client then
                        client.conn:send(dataStr..'\n')
                    end
                end
            end
        end
    elseif pack.receiver then
        -- Send to specified ID(s)
        local receiver=type(pack.receiver)=='table' and pack.receiver or {pack.receiver}
        for i=1,#receiver do
            local recvID=receiver[i]
            if recvID=='0' then
                S_recvCHN:push(sendPack)
            elseif clients[recvID] then
                clients[recvID].conn:send(dataStr..'\n')
            else
                if printException then
                    printf("[TCP_S] Client '%s' does not exist",receiver)
                end
            end
        end
    elseif allowBroadcast then
        -- Send to everyone when receiver not specified
        S_recvCHN:push(sendPack)
        for _,client in next,clients do
            if client.id~=sender then
                client.conn:send(dataStr..'\n')
            end
        end
    end
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
                if printEvent then
                    printf("[TCP_S] Server closed")
                end
                return
            elseif cfg.action=='kick' then
                for i=1,#cfg.id do
                    local client=clients[cfg.id[i]]
                    if client then
                        client.conn:close()
                        if printEvent then
                            printf("[TCP_S] Kicked %s",client.sockname)
                        end
                        clients[cfg.id[i]]=nil
                        partialDataBuffer[cfg.id[i]]=nil
                    else
                        if printException then
                            printf("[TCP_S] Client '%s' does not exist",cfg.id)
                        end
                    end
                end
            elseif cfg.action=='setAllowBroadcast' then
                allowBroadcast=cfg.flag
            elseif cfg.action=='setMaxBus' then
                maxBusCount=cfg.count
            elseif cfg.action=='setBusMaxAliveTime' then
                busTemplate.maxAliveTime=cfg.time
            elseif cfg.action=='setBusMaxMember' then
                busTemplate.maxMember=cfg.count
            elseif cfg.action=='bus.get' then
                S_recvCHN:push(TABLE.copy(busList))
            elseif cfg.action=='bus.join' then
                local bus=busList[cfg.bus]
                if bus then ins(bus.members,'0') end
            elseif cfg.action=='bus.quit' then
                local bus=busList[cfg.bus]
                if bus then
                    local p=TABLE.find(bus.members,'0')
                    if p then rem(bus.members,p) end
                end
            elseif cfg.action=='bus.create' then
                if #busList>=maxBusCount then
                    S_recvCHN:push{success=false}
                    if printException then
                        printf("[TCP_S] Bus count reached max count (%d)",maxBusCount)
                    end
                elseif busList[cfg.bus] then
                    S_recvCHN:push{success=false}
                    if printException then
                        printf("[TCP_S] Bus '%s' already exists",cfg.bus)
                    end
                else
                    ---@type Zenitha.TCP.Bus
                    local bus={
                        name=cfg.bus,
                        createTime=love.timer.getTime(),
                        maxAliveTime=busTemplate.maxAliveTime,
                        maxMember=busTemplate.maxMember,
                        members={},
                    }
                    ins(busList,bus)
                    busList[cfg.bus]=bus
                    S_recvCHN:push{success=true}
                    if printEvent then
                        printf("[TCP_S] Bus '%s' created",cfg.bus)
                    end
                end
            elseif cfg.action=='bus.close' then
                local oldCount=#busList
                for i=1,#busList do
                    if busList[i].name==cfg.bus then
                        sendMessage({
                            config='bus.close',
                            bus=cfg.bus,
                        },'0')
                        busList[busList[i].name]=nil
                        rem(busList,i)
                        break
                    end
                end
                if #busList==oldCount and printException then
                    printf("[TCP_S] no Bus called '%s'",cfg.bus)
                end
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
                if printEvent then
                    printf("[TCP_S] %s connected",c.sockname)
                end
                c.conn:settimeout(0.01)
                clients[c.id]=c
                partialDataBuffer[c.id]=''

                newClientId=newClientId+1
            end
        end

        -- Send Data
        ---@type Zenitha.TCP.MsgPack?
        local pack=S_sendCHN:pop()
        if pack then sendMessage(pack,'0') end

        -- Receive data
        for id,client in next,clients do
            local message,err,partial=client.conn:receive('*l')
            if message then
                if printMsg then
                    printf("[TCP_S] (%s) %s",id,message)
                end
                message=partialDataBuffer[id]..message
                partialDataBuffer[id]=''

                local suc,recvPack=pcall(JSON.decode,message) ---@type boolean, Zenitha.TCP.MsgPack
                if suc then
                    if recvPack.config then
                        if recvPack.config=='bus.get' then
                            local list={}
                            for i=1,#busList do
                                ins(list,busList[i].name)
                            end
                            sendMessage({
                                config='bus.get',
                                receiver=id,
                                data=list,
                            },'0')
                        elseif recvPack.config=='bus.join' then
                            local bus=busList[recvPack.bus]
                            if bus and not TABLE.find(bus.members,id) then
                                ins(bus.members,id)
                                sendMessage({
                                    config='bus.join',
                                    bus=recvPack.bus,
                                    data=id,
                                },'0')
                            end
                        elseif recvPack.config=='bus.quit' then
                            local bus=busList[recvPack.bus]
                            if bus then
                                local p=TABLE.find(bus.members,id)
                                if p then rem(bus.members,p) end
                            end
                            sendMessage({
                                config='bus.quit',
                                bus=recvPack.bus,
                                data=id,
                            },id)
                        elseif printException then
                            printf("[TCP_S] unknown config key '%s'",recvPack.config)
                        end
                    else
                        sendMessage(recvPack,id)
                    end
                else
                    printf("Error in encoding data to json: %s",recvPack)
                    return
                end
            elseif err=='timeout' then
                if partial and partial[1] then
                    partialDataBuffer[id]=partialDataBuffer[id]..partial
                    if printMsg then
                        printf("[TCP_S] (p%s) %s",id,partial)
                    end
                end
            elseif err=='closed' then
                partialDataBuffer[id]=nil
                clients[id]=nil
                if printEvent then
                    printf("[TCP_S] %s disconnected",client.sockname)
                end
            end
        end

        -- Update buses
        for i=#busList,1,-1 do
            local bus=busList[i]
            if #bus.members==0 then
                if not bus.startIdleTime then
                    bus.startIdleTime=love.timer.getTime()
                else
                    if love.timer.getTime()-bus.startIdleTime>bus.maxAliveTime then
                        sendMessage({
                            config='bus.close',
                            bus=bus.name,
                        },'0')
                        busList[bus.name]=nil
                        rem(busList,i)
                    end
                end
            elseif bus.startIdleTime then
                bus.startIdleTime=nil
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
            message=("Cannot bind to port %s, reason: %s"):format(port,err),
        }
    else
        if printEvent then
            printf("[TCP_S] Server started on port %d",port)
        end
        server:settimeout(0.01)
        S_recvCHN:push{success=true}
        serverLoop()
    end
end
