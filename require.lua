package.cpath=package.cpath..';'..love.filesystem.getSaveDirectory()..'/lib/lib?.so;'..'?.dylib'

local _androidPlatform
if love.system.getOS()=='Android' then
    local p=io.popen('uname -m')
    local arch=p:read('*a'):lower()
    p:close()
    if arch:find('v8') or arch:find('64') then
        _androidPlatform='arm64-v8a'
    else
        _androidPlatform='armeabi-v7a'
    end
end

local loaded={}

return function(libName)
    local _require=require
    if love.system.getOS()=='OS X' then
        _require=package.loadlib(libName..'.dylib','luaopen_'..libName)
        libName=nil
    elseif love.system.getOS()=='Android' then
        if not loaded[libName] then
            love.filesystem.write(
                'lib/lib'..libName..'.so',
                love.filesystem.read('data','libAndroid/'.._androidPlatform..'/lib'..libName..'.so')
            )
            loaded[libName]=true
        end
    end
    local success,res=pcall(_require,libName)
    if success and res then
        return res
    else
        MES.new('error',"Cannot load "..libName..": "..res)
    end
end
