local loadlib={}

package.cpath=
    package.cpath..                                           -- Windows, .\?.dll; .\loadall.dll
    ';'..love.filesystem.getSaveDirectory()..'/lib/lib?.so'.. -- Android, %save%/lib/lib?.so
    ';./?.so'..                                               -- Linux
    ';?.dylib'                                                -- macOS
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

local pkgLoaded={}

---A more powerful require function using package.loadlib
---@param libName string
function loadlib.pkg(libName)
    local _require=require
    if SYSTEM=='macOS' then
        _require=package.loadlib(libName..'.dylib','luaopen_'..libName)
    elseif SYSTEM=='Android' then
        if not pkgLoaded[libName] then
            love.filesystem.write(
                'lib/lib'..libName..'.so',
                love.filesystem.read('data','libAndroid/'.._androidPlatform..'/lib'..libName..'.so')
            )
            pkgLoaded[libName]=true
        end
    end
    -- arg #2: if system is macOS, it's nil, otherwise it's 'libName'
    local suc,res=pcall(_require,(SYSTEM~='macOS' or nil) and libName)
    if suc and res then
        return res
    else
        LOG('error',"Cannot load "..libName..": "..res)
        MSG('error',"Cannot load "..libName..": "..res:match('[ -~]+'))
    end
end

local suc,ffi=pcall(require,'ffi')
if suc then
    local ffiPath={
        '$1',
        love.filesystem.getSaveDirectory().."/lib/$1",
    }
    if SYSTEM=='Linux' then
        for i=1,#ffiPath do
            ffiPath[i]=ffiPath[i]:gsub('$1','lib$1.so')
        end
    end

    local function defaultErrorHandler(errInfo)
        for i=1,#errInfo do
            MSG.log('error',errInfo[i])
        end
    end

    ---A wrapped ffi.load that will try to load FMOD library in different paths with an error handler receiving all error informations
    ---@param libName string name of the library, 'fmod' for 'fmod.dll'|'libfmod.so'
    ---@param handler? fun(errLog:string[]) will call this if loading failed
    ---@return ffi.namespace*|false
    function loadlib.ffi(libName,handler)
        local errLog={}
        for i=1,#ffiPath do
            local res
            suc,res=pcall(ffi.load,STRING.repD(ffiPath[i],libName))
            if suc then
                return res
            else
                table.insert(errLog,STRING.repD("ffi.load('$1'): $2",libName,res))
            end
        end
        (type(handler)=='function' and handler or defaultErrorHandler)(errLog)
        return false
    end
else
    loadlib.ffi=NULL
end

return loadlib
