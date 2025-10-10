--[[ DEVELOPMENT PURPOSE ONLY
This module helps you compile your whole love2d project to lua bytecode, so this file is not loaded in Zenitha/init.lua.

How to use (IMPORTANT):
1. Make sure the saving folder is empty, or at least not having same filename to your project folder (will be overwritten)
2. Add `require'Zenitha.compile'()` to THE LAST LINE of main.lua (everything after this line will be ignored)
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
        end
    })
end

local fs=love.filesystem

local function compileFile(inPath,outPath)
    if fs.getRealDirectory(inPath)==fs.getSaveDirectory() then
        return false,"Skipped file in save directory: "..inPath
    end

    local file=fs.read('string',inPath)
    ---@cast file string

    if inPath=='main.lua' then file=file:gsub("\nrequire%S+Zenitha%.compile.*$","") end

    local func,res=loadstring(file)
    if func then
        fs.write(outPath,string.dump(func,true))
        return true
    else
        return false,res
    end
end

---Compile all .lua files into bytecodes
---@param inputFile? string specific file to compile
---@param outputFile? string specific output filename
local function compile(inputFile,outputFile)
    if not inputFile then inputFile='' end
    if inputFile:sub(1,1)=='.' then
        print("Skipped hidden file/directory: "..inputFile)
        return
    end
    local t=fs.getInfo(inputFile).type
    if t=='file' then
        if inputFile:sub(-4)==".lua" then
            local suc,msg=compileFile(inputFile,outputFile or inputFile)
            if suc then
                print("Compiled "..inputFile)
            else
                print("Failed to compile "..inputFile..": "..msg)
            end
        end
    elseif t=='directory' and inputFile~='Zenitha' then
        local contents=fs.getDirectoryItems(inputFile)
        if next(contents) then
            if #inputFile>0 then fs.createDirectory(inputFile) end
            for _,name in next,contents do
                compile((#inputFile>0 and inputFile..'/' or '')..name)
            end
        end
    end
    if inputFile=='' then os.exit() end
end

return compile
