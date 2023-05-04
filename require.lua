package.cpath=package.cpath..';'..love.filesystem.getSaveDirectory()..'/lib/lib?.so;./?.so;?.dylib'

local _androidPlatform='armeabi-v7a'
if love.system.getOS()=='Android' then
    local p=io.popen('uname -m')
    if type(p)=='userdata' then
    local arch=p:read('*a'):lower()
    p:close()
    if arch:find('v8') or arch:find('64') then
        _androidPlatform='arm64-v8a'
        end
    end
end

local loaded={}

--- A more powerful require function, allow loading dynamic libraries
--- @param libName string
return function(libName)
    local _require=require
    if love.system.getOS()=='OS X' then
        _require=package.loadlib(libName..'.dylib','luaopen_'..libName)
    elseif love.system.getOS()=='Android' then
        if not loaded[libName] then
            love.filesystem.write(
                'lib/lib'..libName..'.so',
                love.filesystem.read('data','libAndroid/'.._androidPlatform..'/lib'..libName..'.so')
            )
            loaded[libName]=true
        end
    end

    -- arg #2: if system is OS X, it's nil, otherwise it's 'libName'
    local success,res=pcall(_require,(not love.system.getOS()=='OS X' or nil) and libName)
    if success and res then
        return res
    else
        MSG.new('error',"Cannot load "..libName..": "..res)
    end
end
