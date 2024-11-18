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

---
---@param name string name of the library, 'fmod' for 'fmod.dll'|'libfmod.so'
---@return ffi.namespace*
---@overload fun(name:string):result:false,errInfo:string[]
return function(name)
    local errLog={}
    for i=1,#path do
        local suc,res
        suc,res=pcall(ffi.load,STRING.repD(path[i],name))
        if suc then
            return res
        else
            table.insert(errLog,"Loading FMOD lib:"..res)
        end
    end
    return false,errLog
end
