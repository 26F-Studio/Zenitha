local ffi=require'ffi'

local path={
    '$1',
    love.filesystem.getSaveDirectory().."/lib/$1",
}
if SYSTEM=='Linux' then
    for i=1,#path do
        path[i]=path[i]:gsub('$1','lib$1.so')
    end
end

local function defaultErrorHandler(errInfo)
    for i=1,#errInfo do
        MSG.errorLog(errInfo[i])
    end
end

---A wrapped ffi.load that will try to load FMOD library in different paths with an error handler receiving all error informations
---@param name string name of the library, 'fmod' for 'fmod.dll'|'libfmod.so'
---@param handler? fun(errLog:string[]) will call this if loading failed
---@return ffi.namespace*|false
return function(name,handler)
    local errLog={}
    for i=1,#path do
        local suc,res
        suc,res=pcall(ffi.load,STRING.repD(path[i],name))
        if suc then
            return res
        else
            table.insert(errLog,STRING.repD("ffi.load('$1'): $2",name,res))
        end
    end
    (type(handler)=='function' and handler or defaultErrorHandler)(errLog)
    return false
end
