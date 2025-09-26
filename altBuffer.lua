---In case luajit's string.buffer cannot be load successfully, use this alternative implementation to keep Zenitha working with
---a minimized implementation which is enough for Zenitha's usage, check the code below for more details
---@class Zenitha.AltBuffer
local altBuffer=setmetatable({},{__index=function(_,k) error("Zenitha.AltBuffer: Invalid method '"..tostring(k).."'") end})
altBuffer.__index=altBuffer

---@class Zenitha.AltBufferRef
---@field src Zenitha.AltBuffer
local altBufRef={}

local type=type
local sub=string.sub

---@param self Zenitha.AltBufferRef
function altBufRef.__index(self,k)
    if type(k)=='number' then
        k=k+1
        if k>#self.src[0] then
            self.src:_bake()
        end
        return sub(self.src[0],k,k)
    else
        error("Zenitha.AltBufferRef: Invalid method '"..tostring(k).."'")
    end
end

function altBuffer.__tostring(self)
    self:_bake()
    return self[0]
end

function altBuffer.__len(self)
    self:_bake()
    return #self[0]
end

function altBuffer.__concat(v1,v2)
    return
        (
            type(v1)=='string' and v1 or
            type(v1)=='table' and v1._bake and v1:_bake() and v1[0] or
            tostring(v1)
        )..
        (
            type(v2)=='string' and v2 or
            type(v2)=='table' and v2._bake and v2:_bake() and v2[0] or
            tostring(v2)
        )
end

function altBuffer.new()
    return setmetatable({[0]=""},altBuffer)
end

---@param c string | Zenitha.AltBufferRef
function altBuffer:put(c)
    if type(c)=='string' then
        if #c>0 then
            self[#self+1]=c
        end
    else
        for i=0,#c.src do
            if #c.src[i]>0 then
                self[#self+1]=c.src[i]
            end
        end
    end
    return self
end

local rem=table.remove
function altBuffer:get(c)
    if not c then
        self[0]=table.concat(self)
        for i=1,#self do self[i]=nil end
        return self[0]
    end
    while #self[0]<c and #self>0 do
        self[0]=self[0]..rem(self,1)
    end
    local result
    if #self[0]>c then
        result=sub(self[0],1,c)
        self[0]=sub(self[0],c+1)
    else
        result=self[0]
        self[0]=""
    end
    return result
end

---@param c number
function altBuffer:skip(c)
    if #self[0]>0 then
        if c<#self[0] then
            self[0]=sub(self[0],c+1)
            return
        else
            c=c-#self[0]
            self[0]=""
        end
    end
    while c>0 and #self>0 do
        if #self[1]>=c then
            self[1]=sub(self[1],c+1)
            return
        else
            c=c-#self[1]
            rem(self,1)
        end
    end
    return self
end

function altBuffer:_bake()
    if #self>0 then
        self[0]=self[0]..table.concat(self)
        for i=1,#self do self[i]=nil end
    end
    return self
end

function altBuffer:ref()
    return setmetatable({src=self},altBufRef)
end

function altBuffer:encode() error("Zenitha.AltBuffer: Buffer.encode not implemented") end

function altBuffer:decode() error("Zenitha.AltBuffer: Buffer.decode not implemented") end

return altBuffer
