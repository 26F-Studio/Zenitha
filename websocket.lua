local host=
    'game.techmino.org'
    -- '192.168.223.2'
    -- '192.168.114.102'
    -- '127.0.0.1'
local port='10026'
local path='/tech/socket/v1'
local seckey="osT3F7mvlojIvf3/8uIsJQ=="

--[[
    websocket client pure lua implement for love2d
    by flaribbit, editted by MrZ
    usage:
        local client=require("websocket").new("127.0.0.1",5000)
        function client:onmessage(s) print(s) end
        function client:onopen() self:send("hello from love2d") end
        function client:onclose() print("closed") end
        function love.update()
            client:update()
        end
]]
local socket=require"socket"
local timer=love.timer.getTime
local char,byte=string.char,string.byte
local band,bor,bxor=bit.band,bit.bor,bit.bxor
local shl,shr=bit.lshift,bit.rshift
local OPcode={
    continue=0,
    text=1,
    binary=2,
    close=8,
    ping=9,
    pong=10,
}

---@class Socket
---@field socket userdata socket-tcp object
local Sock={}

Sock.__index=Sock

--- socket opened
function Sock:onopen() end

--- receive a message
---@param message string
function Sock:onmessage(message) end

--- closed
---@param code number
---@param reason string
function Sock:onclose(code,reason) end

--- error
---@param error string
function Sock:onerror(error) end

--- read a message
---@return string|nil res message
---@return number|nil head websocket frame header
---@return string|nil err error message
function Sock:read()
    local res,err,part
    ::AGAIN_RECIEVE::
    res,err,part=self.socket:receive(self._length-#self._buffer)
    if err=="closed" then
        return nil,nil,err
    end
    if part or res then
        self._buffer=self._buffer..(part or res)
    else
        return nil,nil,nil
    end
    if not self._head then
        if #self._buffer<2 then
            return nil,nil,"buffer length less than 2"
        end
        local length=band(byte(self._buffer,2),0x7f)
        if length==126 then
            if self._length==2 then
                self._length=4 goto AGAIN_RECIEVE
            end
            if #self._buffer<4 then
                return nil,nil,"buffer length less than 4"
            end
            local b1,b2=byte(self._buffer,3,4)
            self._length=shl(b1,8)+b2
        elseif length==127 then
            if self._length==2 then
                self._length=10
                goto AGAIN_RECIEVE
            end
            if #self._buffer<10 then
                return nil,nil,"buffer length less than 10"
            end
            local b5,b6,b7,b8=byte(self._buffer,7,10)
            self._length=shl(b5,24)+shl(b6,16)+shl(b7,8)+b8
        else
            self._length=length
        end
        self._head,self._buffer=byte(self._buffer,1),""
        goto AGAIN_RECIEVE
    end
    if #self._buffer>=self._length then
        local ret,head=self._buffer,self._head
        self._length,self._buffer,self._head=2,"",nil
        return ret,head,nil
    else
        return nil,nil,"buffer length less than "..self._length
    end
end

local mask_key={1,14,5,14}
local function send(sock,opcode,message) print(sock)
    -- message type
    sock:send(char(bor(0x80,opcode)))

    -- empty message
    if not message then
        sock:send(char(0x80,unpack(mask_key)))
        return 0
    end

    -- message length
    local length=#message
    if length>65535 then
        sock:send(char(bor(127,0x80),
            0,0,0,0,
            band(shr(length,24),0xff),
            band(shr(length,16),0xff),
            band(shr(length,8),0xff),
            band(length,0xff)))
    elseif length>125 then
        sock:send(char(bor(126,0x80),
            band(shr(length,8),0xff),
            band(length,0xff)))
    else
        sock:send(char(bor(length,0x80)))
    end

    -- message
    sock:send(char(unpack(mask_key)))
    local msgbyte={byte(message,1,length)}
    for i=1,length do
        msgbyte[i]=bxor(msgbyte[i],mask_key[(i-1)%4+1])
    end
    return sock:send(char(unpack(msgbyte)))
end

--- send a message
---@param message string
---@param op string
function Sock:send(message,op)
    if type(message)=='string' then
        self.lastPingTime=timer()
        self.sendTimer=1
        send(self.socket,op and OPcode[op] or 2,message)
    else
        MES.new('error',"Attempt to send non-string value!")
        MES.traceback()
    end
end

--- send a ping message
function Sock:ping()
    self.sendTimer=1
    self.lastPingTime=timer()
    send(self.socket,9--[[ping]],"tech_cli_ping")
end

--- send a pong message (no need)
function Sock:pong(message)
    self.pongTimer=0
    self.lastPongTime=timer()
    send(self.socket,101--[[pong]],message)
end

--- close websocket connection
---@param code integer|nil
---@param message string|nil
function Sock:close(code,message)
    if code and message then
        send(self.socket,8--[[close]],char(shr(code,8),band(code,0xff))..message)
    else
        send(self.socket,8--[[close]],nil)
    end
    self.status='closing'
end



local WS={}
local socks={}setmetatable(socks,{__index=function(_,name) WS.new(name)return socks[name] end})

---@return Socket
function WS.new(name,_subpath,_body,_timeout)
    local m={
        real=true,

        socket=socket.tcp(),
        _path=path..(_subpath or ""),
        _body=_body or "",
        _connectTimer=_timeout or 6,

        _continue="",
        _buffer="",
        _length=2,
        _head=nil,

        errMes=false,
        errCode=false,

        lastPingTime=0,
        lastPongTime=timer(),
        pingInterval=6,
        sendTimer=0,
        alertTimer=0,
        pongTimer=0,

        status=_subpath and 'tcpopening' or 'closed',--'tcpopening','connecting','open','closed','closing'
    }
    if _subpath then
        m.socket:settimeout(0)
        m.socket:connect(host,port)
    end
    setmetatable(m,Sock)
    socks[name]=m
    return m
end

function WS.send(name,message)
    if socks[name].status=='open' then
        socks[name]:send(message)
    end
end
function WS.read(name) return socks[name]:read() end
function WS.close(name) socks[name]:close() end
function WS.alert(name) socks[name].alertTimer=2.6 end

function WS.setPingInterval(name,interval) socks[name].pingInterval=interval end
function WS.setOnMessage(name,func) socks[name].onmessage=func end
function WS.setOnClose(name,func) socks[name].onclose=func end
function WS.setOnError(name,func) socks[name].onerror=func end
function WS.status(name) return socks[name].status end
function WS.getTimers(name)
    local self=socks[name]
    return self.pongTimer,self.sendTimer,self.alertTimer
end

function WS.switchHost(_1,_2,_3) WS.closeAll()host,port,path=_1,_2 or port,_3 or path end
function WS.closeAll() for _,s in next,socks do s:close() end end
function WS.update(dt)
    local t=timer()
    for name,self in next,socks do
        local sock=self.socket
        if self.status=='tcpopening' then
            local _,err=sock:connect(host,port)
            if err=="already connected" then
                if not self._body then self._body="" end
                sock:send(
                    "GET "..(self._path or "/").." HTTP/1.1\r\n"..
                    "Host: "..host..":"..port.."\r\n"..
                    "Connection: Upgrade\r\n"..
                    "Upgrade: websocket\r\n"..
                    'Content-Type: application/json\r\n'..
                    'Content-Length: '..#self._body..'\r\n'..
                    'Sec-WebSocket-Version: 13\r\n'..
                    "Sec-WebSocket-Key: "..seckey.."\r\n\r\n"..
                    self._body
                )
                self.status='connecting'
                self._length=2
                self._body=nil
            else
                self._connectTimer=self._connectTimer-dt
                if self._connectTimer<0 then
                    self.errMes=err or "Timeout"
                    self.status='closed'
                    self:onerror(self.errMes)
                    WS.alert(name)
                    MES.new('warn',"WS closed: "..self.errMes)
                end
            end
        elseif self.status=='connecting' then
            local res=sock:receive("*l")
            if res then
                repeat res=sock:receive("*l") until res==""
                self:onopen()
                self.status='open'
                self.lastPingTime=t
                self.lastPongTime=t
                self.pongTimer=1
            end
        elseif self.status=='open' or self.status=='closing' then
            local res,head,err=self:read()
            if err=="closed" then
                self.errMes="Closed"
                self.status='closed'
                WS.alert(name)
                MES.new('warn',"WS connect failed")
                return
            elseif res then
                local opcode=band(head,0x0f)
                local fin=band(head,0x80)==0x80
                if opcode==8--[[close]] then
                    if res~="" then
                        self.errCode=shl(byte(res,1),8)+byte(res,2)
                        self.errMes=res:sub(3)
                        self:onclose(self.errCode,self.errMes)
                    else
                        self:onclose(1005,"")
                    end
                    sock:close()
                    self.status='closed'
                elseif opcode==9--[[ping]] then
                    self:pong(res)
                elseif opcode==10--[[pong]] then
                    -- do nothing
                elseif opcode==0--[[continue]] then
                    self._continue=self._continue..res
                    if fin then self:onmessage(self._continue) end
                else
                    if fin then self:onmessage(res)else self._continue=res end
                end
            end
            if self.sendTimer>0 then self.sendTimer=self.sendTimer-dt end
            if self.pongTimer>0 then self.pongTimer=self.pongTimer-dt end
            if self.alertTimer>0 then self.alertTimer=self.alertTimer-dt end
            if t-self.lastPingTime>self.pingInterval then self:ping() end
        end
    end
end

return WS
