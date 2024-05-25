local fs=love.filesystem
local FILE={}

---Check if a file exists
---@param path string
---@param filterType? love.FileType
function FILE.exist(path,filterType)
    return not not fs.getInfo(path,filterType)
end

---Check if a file is safe to read/write (not in save directory)
---@param file string
function FILE.isSafe(file)
    return fs.getRealDirectory(file)~=fs.getSaveDirectory()
end

---Load a file with a specified mode
---(Auto detect if mode not given, not accurate)
---@param path string
---@param args? string|'-luaon'|'-lua'|'-json'|'-string'|'-canskip'
---@return any
function FILE.load(path,args)
    if not args then args='' end
    if fs.getInfo(path) then
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
            local func,err_mes=loadstring("--[["..STRING.simplifyPath(path)..']]'..s)
            if func then
                setfenv(func,{})
                local res=func()
                return assert(res,"FILE.load: Decode error")
            else
                error("FILE.load: Decode error: "..err_mes)
            end
        elseif mode=='lua' then
            local func,err_mes=loadstring("--[["..STRING.simplifyPath(path)..']]'..s)
            if func then
                local res=func()
                return assert(res,"FILE.load: run error")
            else
                error("FILE.load: Compile error: "..err_mes)
            end
        elseif mode=='json' then
            local res,data=pcall(JSON.decode,s)
            return res and data or error("FILE.load: Decode error")
        elseif mode=='string' then
            return s
        else
            error("FILE.load: Unknown mode")
        end
    elseif not STRING.sArg(args,'-canskip') then
        errorf("FILE.load: file '%s' doesn't exist",path)
    end
end

---Save a file with a specified mode
---(Default to JSON, then LuaON, then string)
---@param data any
---@param path string
---@param args? string|'-d'|'-luaon'|'-expand'
function FILE.save(data,path,args)
    if not args then args='' end
    assert(not (STRING.sArg(args,'-d') and fs.getInfo(path)),"FILE.save: File already exist")

    if type(data)=='table' then
        if STRING.sArg(args,'-luaon') then
            if STRING.sArg(args,'-expand') then
                data=TABLE.dump(data)
            else
                data='return'..TABLE.dumpDeflate(data)
            end
            if not data then
                error("FILE.save: Luaon-encoding error")
            end
        else
            local res
            res,data=pcall(JSON.encode,data)
            assert(res,"FILE.save: Json-encoding error")
        end
    else
        data=tostring(data)
    end

    local F=fs.newFile(path)
    assert(F:open('w'),"FILE.save: Open error")
    F:write(data)
    F:flush()
    F:close()
end

---Clear a directory
---@param path string
function FILE.clear(path)
    if not FILE.isSafe(path) and fs.getInfo(path).type=='directory' then
        for _,name in next,fs.getDirectoryItems(path) do
            name=path..'/'..name
            if not FILE.isSafe(name) then
                local t=fs.getInfo(name).type
                if t=='file' then
                    fs.remove(name)
                end
            end
        end
    end
end

---Delete a directory recursively
---@param path string|''
function FILE.clear_s(path)
    if path=='' or (not FILE.isSafe(path) and fs.getInfo(path).type=='directory') then
        for _,name in next,fs.getDirectoryItems(path) do
            name=path..'/'..name
            if not FILE.isSafe(name) then
                local t=fs.getInfo(name).type
                if t=='file' then
                    fs.remove(name)
                elseif t=='directory' then
                    FILE.clear_s(name)
                    fs.remove(name)
                end
            end
        end
        fs.remove(path)
    end
end
return FILE
