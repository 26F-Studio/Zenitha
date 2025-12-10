--[[
DEVELOPMENT PURPOSE ONLY

This module helps you compile your whole love2d project to lua bytecode (love2d exclusive), so this file is not loaded in Zenitha/init.lua.

How to use (IMPORTANT):
1. Make sure the saving folder is empty, or at least not having same filename to your project folder (will be overwritten)
2. Add `require("Zenitha.compile")()` to THE LAST LINE of main.lua (everything after this line will be stripped)
3. Run your project, and the process will exit immediately after compiling.
4. Check outputs in console, and check saving folder for compiled files.
5. Copy all compiled files to your project folder and choose "replacing all"
6. Build your project.
7. Recover your project folder with version control system, or make a backup before step 5.
]]
---@diagnostic disable-next-line
local _hoverMouseHereToRead

if not love.filesystem then
    LOG("COMPILE lib is not loaded (need love.filesystem)")
    return setmetatable({},{
        __index=function(_,k)
            error("attempt to use COMPILE."..k..", but COMPILE lib is not loaded (need love.filesystem)")
        end,
    })
end

local fs=love.filesystem

local _compileSelf=true
local _stripDebugInfo=true

local function compileFile(path)
    if fs.getRealDirectory(path)==fs.getSaveDirectory() then
        return false,"Skipped file in save directory: "..path
    end

    local file=fs.read('string',path)
    ---@cast file string

    if path=='main.lua' then
        local requirePos=file:find("require[^\n]*Zenitha[./]compile")
        assert(requirePos,"Failed to find the fixed require statement in main.lua, please read instructions carefully.")
        file=file:sub(1,requirePos-1)
    end

    local func,res=loadstring(file,path)
    if func then
        fs.write(path,string.dump(func,_stripDebugInfo))
        return true
    else
        return false,res
    end
end

---@param path string
local function compileObj(path)
    if path:sub(1,1)=='.' then
        print("Skipped hidden file/directory: "..path)
        return
    end
    local t=fs.getInfo(path).type
    if t=='file' then
        if path:sub(-4)=='.lua' then
            local suc,msg=compileFile(path)
            if suc then
                print("Compiled "..path)
            else
                print("Failed to compile "..path..": "..msg)
            end
        end
    elseif t=='directory' and (_compileSelf or path~='Zenitha') then
        local contents=fs.getDirectoryItems(path)
        if next(contents) then
            if #path>0 then fs.createDirectory(path) end
            for _,name in next,contents do
                compileObj((#path>0 and path..'/' or '')..name)
            end
        end
    end
end

---Compile all .lua files into bytecodes
---@param compileSelf? boolean default to true
---@param stripDebugInfo? boolean default to true
local function start(compileSelf,stripDebugInfo)
    _compileSelf=not not compileSelf
    _stripDebugInfo=not not stripDebugInfo
    compileObj('')
    os.exit()
end

return start
