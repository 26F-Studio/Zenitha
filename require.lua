package.cpath=
    package.cpath.. -- Windows, .\?.dll; .\loadall.dll
    ';'..love.filesystem.getSaveDirectory()..'/lib/lib?.so'.. -- Android, %save%/lib/lib?.so
    ';./?.so'.. -- Linux
    ';?.dylib' -- macOS
package.cpath=package.cpath:gsub('\\','/')

local _androidPlatform='armeabi-v7a'
if SYSTEM=='Android' then
    local p=io.popen('uname -m')
    if p then
        local arch=p:read('*a'):lower()
        p:close()
        if arch:find('v8') or arch:find('64') then
            _androidPlatform='arm64-v8a'
        elseif arch:find('x86_64') then
            _androidPlatform='x86_64'
        elseif arch:find('x86') then
            _androidPlatform='x86'
        end
    end
end

local loaded={}

---A more powerful require function, allow loading dynamic libraries
---@param libName string
return function(libName)
    local _require=require
    if SYSTEM=='macOS' then
        _require=package.loadlib(libName..'.dylib','luaopen_'..libName)
    elseif SYSTEM=='Android' then
        if not loaded[libName] then
            love.filesystem.write(
                'lib/lib'..libName..'.so',
                love.filesystem.read('data','libAndroid/'.._androidPlatform..'/lib'..libName..'.so')
            )
            loaded[libName]=true
        end
    end
    -- arg #2: if system is macOS, it's nil, otherwise it's 'libName'
    local success,res=pcall(_require,(SYSTEM~='macOS' or nil) and libName)
    if success and res then
        return res
    else
        print("Cannot load "..libName..": "..res)
        MSG.new('error',"Cannot load "..libName..": "..res:match('[ -~]+'))
    end
end
