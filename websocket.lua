if not love.thread then
    LOG("WS lib is not loaded (need love.thread)")
    return setmetatable({},{
        __index=function(_,k)
            error("attempt to use WS."..k..", but WS lib is not loaded (need love.thread)")
        end,
    })
end

local defaultHost='127.0.0.1'
local defaultPort='80'
local defaultPath='/'

-- lua + LÖVE threading websocket client
-- Original pure lua ver. by flaribbit and Particle_G
-- Threading version by MrZ

---@class Zenitha.WebSocket.ConnectArgs
---@field host? string
---@field port? string
---@field path? string
---@field subPath? string
---@field headers? table
---@field connTimeout? number default to 2.6
---@field pongTimeout? number default to 16
---@field sleepInterval? number default to 0.26
---@field pingInterval? number default to 6

---@alias Zenitha.WebSocket.state 'connecting' | 'running' | 'dead'

---@class Zenitha.WebSocket
---@field host string
---@field port string
---@field path string
---@field headers string
---@field thread love.Thread
---@field confCHN love.Channel
---@field sendCHN love.Channel
---@field readCHN love.Channel
---@field connTimeout number
---@field pongTimeout number
---@field sleepInterval number
---@field pingInterval number
---@field state Zenitha.WebSocket.state
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

    defaultHost=host or defaultHost
    defaultPort=port or defaultPort
    defaultPath=path or defaultPath
end

---@param args Zenitha.WebSocket.ConnectArgs
---@return Zenitha.WebSocket
function WS.new(args)
    assert(args.host==nil or type(args.host)=='string','WS.new: arg.host must be string (if exist)')
    assert(args.port==nil or type(args.port)=='string','WS.new: arg.port must be string (if exist)')
    assert(args.path==nil or type(args.path)=='string','WS.new: arg.path must be string (if exist)')
    assert(args.subPath==nil or type(args.subPath)=='string','WS.new: arg.subPath must be string (if exist)')
    assert(args.headers==nil or type(args.headers)=='table','WS.new: arg.headers must be table (if exist)')
    assert(args.connTimeout==nil or type(args.connTimeout)=='number','WS.new: arg.connTimeout must be number (if exist)')
    assert(args.pongTimeout==nil or type(args.pongTimeout)=='number','WS.new: arg.pongTimeout must be number (if exist)')
    assert(args.sleepInterval==nil or type(args.sleepInterval)=='number','WS.new: arg.sleepInterval must be number (if exist)')
    assert(args.pingInterval==nil or type(args.pingInterval)=='number','WS.new: arg.pingInterval must be number (if exist)')

    -- Encode header as string
    local heders=""
    for k,v in next,args.headers or {} do
        heders=heders..k..": "..v..'\r\n'
    end

    -- Create websocket object
    ---@type Zenitha.WebSocket
    local ws=setmetatable({
        state='dead',
        host=args.host or defaultHost,
        port=args.port or defaultPort,
        path=args.path or defaultPath..(args.subPath or ''),
        headers=heders,
        thread=love.thread.newThread(ZENITHA.path..'websocket_thread.lua'),
        connTimeout=args.connTimeout or 2.6,
        pongTimeout=args.pongTimeout or 16,
        sleepInterval=args.sleepInterval or 0.26,
        pingInterval=args.pingInterval or 6,
    },{__index=WS})
    return ws
end

---@return boolean success Will fail if this websocket is still/already running
function WS:connect()
    if self.thread:isRunning() then return false end
    self.state='connecting'
    self.confCHN=love.thread.newChannel()
    self.sendCHN=love.thread.newChannel()
    self.readCHN=love.thread.newChannel()
    self.confCHN:push{
        host=self.host,
        port=self.port,
        path=self.path,
        headers=self.headers,
        connTimeout=self.connTimeout,
        pongTimeout=self.pongTimeout,
        sleepInterval=self.sleepInterval,
        pingInterval=self.pingInterval,
    }
    self.thread:start(ZENITHA.path,self.confCHN,self.sendCHN,self.readCHN)
    return true
end

---@param name 'connTimeout' | 'pongTimeout' | 'sleepInterval' | 'pingInterval'
---@param value any
function WS:conf(name,value)
    assert(type(value)=='number','WS:confTime(name,time): time must be number')
    self.confCHN:push({name,value})
end

---@enum Zenitha.WebSocket.OPcode
local OPname={
    [0]='continue',
    [1]='text',
    [2]='binary',
    -- 3-7 reserved
    [8]='close',
    [9]='ping',
    [10]='pong',
    -- 11-15 reserved
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
---@param op? Zenitha.WebSocket.OPcode | number leave nil for binary
function WS:send(message,op)
    assert(type(message)=='string','WS.send: message must be string')
    if self.state=='running' then
        self.sendCHN:push(OPcode[op] or op or 2) -- 2=binary
        self.sendCHN:push(message)
    end
    self:update()
end

---@return string?, (Zenitha.WebSocket.OPcode | number)?
function WS:receive()
    self:update()
    if self.state~='connecting' and self.readCHN:getCount()>=2 then
        local op,message=self.readCHN:pop(),self.readCHN:pop()
        if op==8 then -- 8=close
            self.state='dead'
        end
        return message,OPname[op] or op
    end
end

function WS:close()
    self.sendCHN:push(8) -- 8=close
    self.sendCHN:push("")
end

function WS:update()
    if self.state=='dead' then return end
    if self.thread:isRunning() then
        if self.state=='connecting' then
            local mes=self.readCHN:pop()
            if mes then
                if mes=='success' then
                    self.state='running'
                else
                    self.state='dead'
                    MSG.log('warn',"WS failed: "..mes)
                end
            end
        end
    else
        self.state='dead'
        local err=self.thread:getError()
        if err then
            MSG.log('warn',"WS error: "..(err:match(":.-:(.-)\n") or err or "?"))
        end
    end
end

return WS
