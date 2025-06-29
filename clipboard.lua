local function _sanitize(content)
    if type(content)=='string' then
        return content
    elseif type(content)=='number' then
        return tostring(content)
    elseif type(content)=='boolean' then
        return content and 'true' or 'false'
    elseif type(content)=='nil' then
        return ''
    else
        MSG('error',"Invalid content type!")
        MSG.traceback()
        return ''
    end
end

if SYSTEM~='Web' then
    local get=love.system.getClipboardText
    local set=love.system.setClipboardText
    return {
        get=function() return get() or '' end,
        set=function(content) set(_sanitize(content)) end,
        setFreshInterval=NULL,
        _update=NULL,
    }
end

if WEB_COMPAT_MODE then
    local _clipboardBuffer=''
    return {
        get=function()
            JS.newPromiseRequest(
                JS.stringFunc(
                    [[
                        window.navigator.clipboard
                            .readText()
                            .then((text) => _$_(text))
                            .catch((e) => {
                                console.warn(e);
                                _$_('');
                            });
                    ]]
                ),
                function(data) _clipboardBuffer=data end,
                function() _clipboardBuffer='' end,
                3,
                'getClipboardText'
            )
            if TASK.lock('clipboard_compat_interval',2.6) then
                _clipboardBuffer=''
                MSG('warn',"Web-Compat mode, paste again to confirm",2.6)
            end
            return _clipboardBuffer
        end,
        set=function(str)
            JS.callJS(JS.stringFunc(
                [[
                    window.navigator.clipboard
                        .writeText('%s')
                        .then(() => console.log('Copied to clipboard'))
                        .catch((e) => console.warn(e));
                ]],
                _sanitize(str)
            ))
        end,
        setFreshInterval=NULL,
        _update=NULL,
    }
end

local getCHN=love.thread.getChannel('CLIP_get')
local setCHN=love.thread.getChannel('CLIP_set')
local trigCHN=love.thread.getChannel('CLIP_trig')

local clipboard_thread=love.thread.newThread('clipboard_thread.lua')
local isStarted,errorMessage=clipboard_thread:start()

if not isStarted then
    MSG("error",errorMessage,26)
end

local freshInterval=1
local timer=-.626
return {
    get=function() return getCHN:peek() or '' end,
    set=function(content) setCHN:push(_sanitize(content)) end,
    setFreshInterval=function(val)
        freshInterval=val
    end,
    _update=function(dt)
        timer=timer+dt
        if timer>freshInterval then
            if isStarted and not clipboard_thread:isRunning() then
                MSG("warn",clipboard_thread:getError(),26)
                isStarted=false
            end
            trigCHN:push(timer)
            timer=0
        end
    end,
}
