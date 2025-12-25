if not love.filesystem then
    LOG("FILE lib is not loaded (need love.filesystem)")
    return setmetatable({},{
        __index=function(_,k)
            error("attempt to use FILE."..k..", but FILE lib is not loaded (need love.filesystem)")
        end,
    })
end

local fs=love.filesystem
local FILE={}

---Check if a file exists
---@param path string
---@param filterType? love.FileType
---@return {type: love.FileType, size: number, modtime: number}
function FILE.exist(path,filterType)
    return fs.getInfo(path,filterType)
end

---Check if a file is safe to read (in project, not save directory)
---@param file string
function FILE.isSafe(file)
    return fs.getRealDirectory(file)~=fs.getSaveDirectory()
end

---Load a file with a specified mode
---(Auto detect if mode not given, not accurate)
---@param path string
---@param args? string | '-luaon' | '-lua' | '-json' | '-string'
---@param venv? table Used as environment for LuaON
---@return any
function FILE.load(path,args,venv)
    if not args then args='' end
    assert(fs.getInfo(path),"FILE.load: File not exist")

    local F=fs.newFile(path)
    assert(F:open'r',"FILE.load: Open error")
    local s=F:read()
    F:close()
    local mode=
        STRING.sArg(args,'-luaon') and 'luaon' or
        STRING.sArg(args,'-lua') and 'lua' or
        STRING.sArg(args,'-json') and 'json' or
        STRING.sArg(args,'-string') and 'string' or

        s:sub(1,9):find('return%s*%{') and 'luaon' or
        (s:sub(1,1)=='[' and s:sub(-1)==']' or s:sub(1,1)=='{' and s:sub(-1)=='}') and 'json' or
        'string'

    if mode=='luaon' then
        s=(s:match("^%s*{") and "return" or "")..s
        local func,err_mes=loadstring(s,STRING.simplifyPath(path))
        if func then
            setfenv(func,venv or {})
            local res=func()
            return assert(res,"FILE.load: Decode error")
        else
            error("FILE.load: Decode error: "..err_mes)
        end
    elseif mode=='lua' then
        local func,err_mes=loadstring(s,STRING.simplifyPath(path))
        assert(func,"FILE.load: Compile error: "..err_mes)
        return func()
    elseif mode=='json' then
        local suc,res=pcall(JSON.decode,s)
        return suc and res or error("FILE.load: Decode error")
    elseif mode=='string' then
        return s
    else
        error("FILE.load: Unknown mode")
    end
end

---Save table(string) to a file
---(Default dump method for table is JSON)
---@param data any
---@param path string
---@param args? string | '-json' | '-luaon' | '-expand'
function FILE.save(data,path,args)
    if not args then args='' end

    if type(data)=='table' then
        local suc
        if STRING.sArg(args,'-luaon') then
            local expand=STRING.sArg(args,'-expand')
            suc,data=pcall(expand and TABLE.dump or TABLE.dumpDeflate,data)
            assert(suc,"FILE.save: Luaon-encoding error: "..data)
            data=(expand and "return " or "return")..data
        else
            suc,data=pcall(JSON.encode,data)
            assert(suc,"FILE.save: Json-encoding error: "..data)
        end
    elseif type(data)~='string' then
        error("FILE.save: data need table | string")
    end

    local F=fs.newFile(path)
    assert(F:open('w'),"FILE.save: Open error")
    F:write(data)
    F:flush()
    F:close()
end

---@enum (key) Zenitha.folderDeleteMode
local folderMode={
    all=true,
    clear=true,
    keepFolder=true,
    shallow=true,
    __=true,
}

---Deleta a file / folder / symlink (other types are ignored)
---@param path string
---@param mode? Zenitha.folderDeleteMode (only available for folder) `'all'` (default option) - delete whole folder, `'clear'` - delete everything in folder, `'keepFolder'` - keep folder structure, `'shallow'` - only delete files in first layer
---@param rmSymlink? boolean if true, delete symlink
---@return boolean? success always `nil` when deleting folder with `'keepFolder'` or `'shallow'` mode
function FILE.delete(path,mode,rmSymlink)
    if mode==nil then mode='all' end
    assert(folderMode[mode],"FILE.delete: mode need 'all' | 'clear' | 'keepFolder' | 'clear' | 'shallow'")

    if path~='' and (FILE.isSafe(path) or not fs.getInfo(path)) then return false end

    local t=fs.getInfo(path).type
    if t=='file' then
        return fs.remove(path)
    elseif t=='directory' then
        if mode=='__' then return end
        for _,name in next,fs.getDirectoryItems(path) do
            FILE.delete(path..'/'..name,mode=='shallow' and '__' or mode=='clear' and 'all' or mode,rmSymlink)
        end
        if mode=='all' then
            return fs.remove(path)
        end
    elseif t=='symlink' and rmSymlink then
        return fs.remove(path)
    else
        return false
    end
end

return FILE
