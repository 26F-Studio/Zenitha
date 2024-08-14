local debugPrint=false

local zPath,confCHN,sendCHN,readCHN=...

local connTimeout,pongTimeout=16,2.6
local sleepInterval,pingInterval=6,0.26
local lastRecvTime,lastSendTime

local timer=require'love.timer'.getTime
local sleep=require'love.timer'.sleep
local CHN_demand,CHN_getCount=confCHN.demand,confCHN.getCount
local CHN_push,CHN_pop,CHN_peek=confCHN.push,confCHN.pop,confCHN.peek

local SOCK=require'socket'.tcp()
---@type Zenitha.Json
local JSON=require(zPath..'json')

do-- Connect
    local conf=CHN_demand(confCHN)
    local host=conf.host
    local port=conf.port
    local path=conf.path
    local headers=conf.headers
    connTimeout=conf.connTimeout
    pongTimeout=conf.pongTimeout
    sleepInterval=conf.sleepInterval
    pingInterval=conf.pingInterval

    SOCK:settimeout(connTimeout)
    local res,err=SOCK:connect(host,port)
    if debugPrint then print('Conn<',res,err) end
    assert(res,err)

    -- WebSocket handshake
    local sendMes='GET '..path..' HTTP/1.1\r\n'..
        'Host: '..host..':'..port..'\r\n'..
        'Connection: Upgrade\r\n'..
        'Upgrade: websocket\r\n'..
        'Sec-WebSocket-Version: 13\r\n'..
        'Sec-WebSocket-Key: osT3F7mvlojIvf3/8uIsJQ==\r\n'..-- secKey
        headers..
        '\r\n'
    if debugPrint then
        print('Send>')
        print(sendMes)
    end
    SOCK:send(sendMes)

    -- First line of HTTP
    res,err=SOCK:receive('*l')
    if debugPrint then print('Headers<',res,err) end
    assert(res,err)
    local code,ctLen
    code=res:find(' ')
    code=res:sub(code+1,code+3)

    -- Get body length from headers and remove headers
    repeat
        res,err=SOCK:receive('*l')
        if debugPrint then print('Body<',res,err) end
        assert(res,err)
        if not ctLen and res:find('content-length') then
            ctLen=tonumber(res:match('%d+')) or 0
        end
    until res==''

    -- Result
    if code=='101' then
        CHN_push(readCHN,'success')
    end

    -- Content(?)
    if ctLen then
        res,err=SOCK:receive(ctLen)
        if debugPrint then print('Extra<',res,err) end
        if code~='101' then
            res=JSON.decode(assert(res,err))
            error((code or "XXX")..":"..(res and res.reason or "Server Error"))
        end
    end

    SOCK:settimeout(0)
    lastRecvTime,lastSendTime=timer(),timer()
end

local yield=coroutine.yield
local byte,char=string.byte,string.char
local band,bor,bxor=bit.band,bit.bor,bit.bxor
local shl,shr=bit.lshift,bit.rshift

local mask_key={1,14,5,14}
local mask_str=char(unpack(mask_key))
local function _send(op,message)
    lastSendTime=timer()

    -- Message type
    SOCK:send(char(bor(op,0x80)))

    if message then
        -- Length
        local length=#message
        if length>65535 then
            SOCK:send(char(bor(127,0x80),0,0,0,0,band(shr(length,24),0xff),band(shr(length,16),0xff),band(shr(length,8),0xff),band(length,0xff)))
        elseif length>125 then
            SOCK:send(char(bor(126,0x80),band(shr(length,8),0xff),band(length,0xff)))
        else
            SOCK:send(char(bor(length,0x80)))
        end
        local msgbyte={byte(message,1,length)}
        for i=1,length do
            msgbyte[i]=bxor(msgbyte[i],mask_key[(i-1)%4+1])
        end
        SOCK:send(mask_str..char(unpack(msgbyte)))
    else
        SOCK:send('\128'..mask_str)
    end
    if op==8 then
        error("Client Close")
    end
end
local sendThread=coroutine.wrap(function()
    while true do
        while CHN_getCount(sendCHN)>=2 do
            _send(CHN_pop(sendCHN),CHN_pop(sendCHN))
        end
        yield()
    end
end)

local function _receive(sock,len)
    lastRecvTime=timer()
    local buffer=""
    while true do
        local r,e,p=sock:receive(len)
        if r then
            buffer=buffer..r
            len=len-#r
        elseif p then
            buffer=buffer..p
            len=len-#p
        elseif e then
            return nil,e
        end
        if len==0 then
            return buffer
        end
        yield()
    end
end
local readThread=coroutine.wrap(function()
    local res,err
    local op,fin
    local lBuffer=""-- Long multi-pack buffer
    while true do
        -- Byte 0-1
        res,err=_receive(SOCK,2)
        assert(res,err)

        op=band(byte(res,1),0x0f)
        fin=band(byte(res,1),0x80)==0x80

        -- Calculating data length
        local length=band(byte(res,2),0x7f)
        if length==126 then
            res,err=_receive(SOCK,2)
            assert(res,err)
            length=shl(byte(res,1),8)+byte(res,2)
        elseif length==127 then
            -- 'res' is 'lenData' here
            res,err=_receive(SOCK,8)
            assert(res,err)
            local _,_,_,_,_5,_6,_7,_8=byte(res,1,8)
            length=shl(_5,24)+shl(_6,16)+shl(_7,8)+_8
        end
        res,err=_receive(SOCK,length)
        assert(res,err)

        -- React
        if op==8 then-- 8=close
            CHN_push(readCHN,8)-- close
            if type(res)=='string' then
                CHN_push(readCHN,res:sub(3))--[Warning] 2 bytes close code at start so :sub(3)
            else
                CHN_push(readCHN,"WS closed")
            end
            error("Server Close")
        elseif op==0 then-- 0=continue
            lBuffer=lBuffer..res
            if fin then
                CHN_push(readCHN,lBuffer)
                if debugPrint then print('mMes<',lBuffer) end
                lBuffer=""
            end
        elseif op==9 then-- 9=ping
            _send(10,res)
        else
            CHN_push(readCHN,op)
            if fin then
                CHN_push(readCHN,res)
                if debugPrint then print('Mes<',res) end
                lBuffer=""
            else
                lBuffer=res
            end
        end
        yield()
    end
end)

local success,err

while true do-- Running
    while CHN_peek(confCHN) do
        local c=CHN_pop(confCHN)
        local n=c[1]
        if n=='connTimeout' then
            connTimeout=c[2]
        elseif n=='pongTimeout' then
            pongTimeout=c[2]
        elseif n=='sleepInterval' then
            sleepInterval=c[2]
        elseif n=='pingInterval' then
            pingInterval=c[2]
        end
    end
    local t=timer()
    if t-lastRecvTime>pongTimeout then
        err="Pong timeout"
        break
    elseif t-lastSendTime>pingInterval then
        _send(9)
    end
    success,err=pcall(sendThread)
    if not success or err then break end
    success,err=pcall(readThread)
    if not success or err then break end
    sleep(sleepInterval)
end

SOCK:close()
CHN_push(readCHN,8)-- close
CHN_push(readCHN,err or "Disconnected")
error()
