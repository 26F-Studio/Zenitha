local zPath=(...):match('.+%.')

local defaultHost='127.0.0.1'
local defaultPort='80'
local defaultPath=''

-- lua + LÖVE threading websocket client
-- Original pure lua ver. by flaribbit and Particle_G
-- Threading version by MrZ

---@class Zenitha.WebSocket.ConnectArgs
---@field host? string
---@field port? string
---@field path? string
---@field subPath string
---@field head? table
---@field pingInterval? number default to 6
---@field keepAliveTime? number default to 16
---@field timeout? number

---@alias Zenitha.WebSocket.status 'connecting'|'running'|'dead'

---@class Zenitha.WebSocket
---@field host string
---@field port string
---@field path string
---@field head string
---@field timeout number
---@field thread love.Thread
---@field confCHN love.Channel
---@field sendCHN love.Channel
---@field readCHN love.Channel
---@field pingInterval number
---@field keepAliveTime number
---@field status Zenitha.WebSocket.status
---@field lastPingTime number
---@field lastPongTime number
local WS={}
WS.__index=WS
WS.__metatable=true

---Set deafult host, port and path for websocket connection
---@param host? string
---@param port? string
---@param path? string
function WS.switchHost(host,port,path)
    assert(host==nil or type(host)=='string','WS.switchHost: need string (if exist)')
    assert(port==nil or type(port)=='string','WS.switchHost: need string (if exist)')
    assert(path==nil or type(path)=='string','WS.switchHost: need string (if exist)')

    WS.closeAll()
    defaultHost=host or defaultHost
    defaultPort=port or defaultPort
    defaultPath=path or defaultPath
end

---@param args Zenitha.WebSocket.ConnectArgs
function WS.new(args)
    assert(args.host==nil or type(args.host)=='string','WS.new: arg.host must be string (if exist)')
    assert(args.port==nil or type(args.port)=='string','WS.new: arg.port must be string (if exist)')
    assert(args.path==nil or type(args.path)=='string','WS.new: arg.path must be string (if exist)')
    assert(type(args.subPath)=='string','WS.new: arg.subPath must be string')
    assert(args.head==nil or type(args.head)=='table','WS.new: arg.head must be table (if exist)')
    assert(args.pingInterval==nil or type(args.pingInterval)=='number','WS.new: arg.pingInterval must be number (if exist)')
    assert(args.keepAliveTime==nil or type(args.keepAliveTime)=='number','WS.new: arg.keepAliveTime must be number (if exist)')
    assert(args.timeout==nil or type(args.timeout)=='number','WS.new: arg.timeout must be number (if exist)')

    -- Encode header as string
    local head=""
    for k,v in next,args.head or {} do
        head=head..k..": "..v..'\r\n'
    end

    -- Create websocket object
    ---@type Zenitha.WebSocket
    local ws=setmetatable({
        host=args.host or defaultHost,
        port=args.port or defaultPort,
        path=args.path or defaultPath..args.subPath,
        head=head,
        timeout=args.timeout or 2.6,
        thread=love.thread.newThread(zPath:gsub('%.','/')..'websocket_thread.lua'),
        pingInterval=args.pingInterval or 6,
        keepAliveTime=args.keepAliveTime or 16,
        lastPingTime=0,
        lastPongTime=0,
    },{__index=WS})
    return ws
end

---@return boolean success Will fail if this websocket is still/already running
function WS:connect()
    if self.thread:isRunning() then return false end
    self.status='connecting'
    self.confCHN=love.thread.newChannel()
    self.sendCHN=love.thread.newChannel()
    self.readCHN=love.thread.newChannel()
    self.confCHN:push(self.host)
    self.confCHN:push(self.port)
    self.confCHN:push(self.path)
    self.confCHN:push(self.head)
    self.confCHN:push(self.timeout or 2.6)
    self.thread:start(zPath,self.confCHN,self.sendCHN,self.readCHN)
    return true
end

---@param time number
function WS:setSleepInterval(time)
    assert(type(time)=='number','WS:setSleepInterval(time): time must be number')
    self.confCHN:push(time)
end

---@enum Zenitha.WebSocket.OPcode
local OPname={
    [0]='continue',
    [1]='text',
    [2]='binary',
    [8]='close',
    [9]='ping',
    [10]='pong',
}
local OPcode={
    continue=0,
    text=1,
    binary=2,
    close=8,
    ping=9,
    pong=10,
}

---@param message string
---@param op? Zenitha.WebSocket.OPcode leave nil for binary
function WS:send(message,op)
    assert(type(message)=='string','WS.send: message must be string')
    if self.status=='running' then
        self.sendCHN:push(op and OPcode[op] or 2)-- 2=binary
        self.sendCHN:push(message)
        self.lastPingTime=love.timer.getTime()
    end
    self:update()
end

---@return string?, (Zenitha.WebSocket.OPcode | number)?
function WS:read()
    self:update()
    if self.status~='connecting' and self.readCHN:getCount()>=2 then
        local op,message=self.readCHN:pop(),self.readCHN:pop()
        if op==8 then-- 8=close
            self.status='dead'
        elseif op==9 then-- 9=ping
            self:send(message or "",'pong')
        end
        self.lastPongTime=love.timer.getTime()
        return message,OPname[op] or op
    end
end

function WS:close()
    self.sendCHN:push(8)-- 8=close
    self.sendCHN:push("")
    self.status='dead'
end

function WS:update()
    if self.status=='dead' then return end
    local time=love.timer.getTime()
    if self.thread:isRunning() then
        if self.status=='connecting' then
            local mes=self.readCHN:pop()
            if mes then
                if mes=='success' then
                    self.status='running'
                    self.lastPingTime=time
                    self.lastPongTime=time
                else
                    self.status='dead'
                    MSG.new('warn',"WS failed: "..mes)
                end
            end
        elseif self.status=='running' then
            if time-self.lastPingTime>self.pingInterval then
                self:send("",'ping')
            end
            if time-self.lastPongTime>self.keepAliveTime then
                self:close()
            end
        end
    else
        self.status='dead'
        local err=self.thread:getError()
        if err then
            MSG.new('warn',"WS error: "..err:match(":.-:(.-)\n"))
        end
    end
end

return WS
