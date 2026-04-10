local LOADLIB={}

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
function LOADLIB.pkg(libName)
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
        LOG('error',"Cannot load "..libName..":\n"..tostring(res))
        MSG('error',"Cannot load "..libName..": "..tostring(res):match('[ -~]+'))
    end
end

LOADLIB.ffi=NULL
local suc,ffi=pcall(require,'ffi')
if suc then
    local ffiPath={
        '$1',
        love.filesystem.getSaveDirectory().."/lib/$1",
    }

    local function defaultErrorHandler(errInfo)
        for i=1,#errInfo do
            MSG.log('error',errInfo[i])
        end
    end

    ---A wrapped ffi.load that will try to load XXX library in different paths with an error handler receiving all error informations
    ---@param libName string name of the library, 'xxx' for 'xxx.dll' | 'libxxx.so'
    ---@param handler? fun(errLog:string[]) will call this if loading failed
    ---@return ffi.namespace* | false
    function LOADLIB.ffi(libName,handler)
        local errLog={}
        for i=1,#ffiPath do
            local path=ffiPath[i]
            if SYSTEM=='linux' then path=STRING.repD(path,'lib$1.so') end -- IDK why but my arch linux only works with manual filename completion

            local res
            suc,res=pcall(ffi.load,STRING.repD(path,libName))
            if suc then return res end
            table.insert(errLog,STRING.repD("ffi.load('$1'): $2",libName,res))
        end
        if type(handler)=='function' then handler(errLog) else defaultErrorHandler(errLog) end
        return false
    end

    -- Insert extra path if you really need
    LOADLIB._ffiPath=ffiPath
end

return LOADLIB
