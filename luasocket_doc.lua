---@meta

---@class LTN12.Sink
---@class LTN12.Source

---@class LuaSocket
---@field headers.canonic table
---@field _DATAGRAMSIZE number
---@field _SETSIZE number
---@field _SOCKETINVALID number
---@field _VERSION string
---@field _DEBUG boolean
local socket={}

---@return LuaSocket.server
---@param address string
---@param port string
---@param backlog? number
function socket.bind(address,port,backlog) end

---@param address string
---@param port number
---@param locaddr? string
---@param locport? number
---@param family? 'inet' | 'inet6'
---@return LuaSocket.client
function socket.connect(address,port,locaddr,locport,family) end
socket.connect4=socket.connect
socket.connect6=socket.connect

---@param recvt LuaSocket.master[]
---@param sendt LuaSocket.master[]
---@param timeout? number?
function socket.select(recvt,sendt,timeout) end

---Throw an exception, like assert
function socket.try(ret1,ret2,...) end

---Patch a function to be the finalizer of a SAFE function, if the SAFE function crashed, the finalizer function will be called
---@param finalizer function
function socket.newtry(finalizer) end

---Create a SAFE function which calling it is silimar to pcall the original function, but can only handle try/assert/error
---@param func function
function socket.protect(func) end

---Return retD+1, retD+2, ...
---@param D number
---@param ret1 any
---@param ret2 any
---@param ... any
function socket.skip(D,ret1,ret2,...) end

---LTN12
---@param mode string
---@param sock LuaSocket.master
---@return LTN12.Sink
function socket.sink(mode,sock) end

---@param mode string
---@param sock LuaSocket.master
---@param length? number
---@return LTN12.Source
function socket.source(mode,sock,length) end

---Just sleep
---@param time number
function socket.sleep(time) end

---Just getTime
---@return number ms
function socket.gettime() end



---@class LuaSocket.master
local master={}

---@param address string
---@param port string
---@return number? success, string errInfo
function master:bind(address,port) end

---@param address string
---@param port string
---@return number? success, string errInfo
function master:connect(address,port) end

function master:close() end

---@return boolean hasData
function master:dirty() end

---@return string
function master:getsockname() end

---@return number bytesRecv, number bytesSent, number secLifetime
function master:getstats() end

---@return number
function master:gettimeout() end

---Wait for a connection, then transform into a server object
---@param backlog number
function master:listen(backlog) end

---For throttling of bandwidth
---@param received number bytes
---@param sent number bytes
---@param age number seconds
function master:setstats(received,sent,age) end

---@param value? number nil or negative means block
---@param mode? 'b' | 't'
function master:settimeout(value,mode) end

---@return string
function master:getfd() end

---@param fd string
function master:setfd(fd) end



---@class LuaSocket.server: LuaSocket.master
local server={}

---@return LuaSocket.client
function server:accept() end

---@param option string
function server:getoption(option) end

---@param option string
---@param value? any
function server:setoption(option,value) end



---@class LuaSocket.client: LuaSocket.master
local client={}

---@param option string
function client:getoption(option) end

---@param option string
---@param value? any
function client:setoption(option,value) end

---@return string
function client:getpeername() end

---@param pattern? '*l' | '*a' | number
---@param prefix? string
function client:receive(pattern,prefix) end

---Send data string between i and j (byte) if given
---@param data string
---@param i? number
---@param j? number
function client:send(data,i,j) end

---Close one side of a full-duplex connection
---@param mode? 'both' | 'send' | 'receive'
function client:shutdown(mode) end
