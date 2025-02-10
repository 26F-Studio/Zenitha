if not (love.audio and love.sound) then
    LOG("BGM lib is not loaded (need love.audio & love.sound)")
    return setmetatable({
        load=function()
            error("attempt to use BGM.load, but BGM lib is not loaded (need love.audio & love.sound)")
        end
    },{
        __index=function(t,k)
            t[k]=NULL
            return t[k]
        end
    })
end

---@class Zenitha.BgmObj
---@field name string
---@field path string
---@field source love.Source | false
---@field vol number
---@field volChanging boolean
---@field pitch number
---@field pitchChanging boolean
---@field lowgain number
---@field lowgainChanging boolean
---@field highgain number
---@field highgainChanging boolean

local audio=love.audio
local effectsSupported=audio and audio.isEffectsSupported()
local ins=table.insert

---@type string[]
local nameList={}

---@type string[]
local lastLoadNames={}

---@type string[]
local lastPlay=NONE

---@type table<string, Zenitha.BgmObj>
local srcLib={}

---@type Zenitha.BgmObj[]
local nowPlay={}

---@type false | string | string[]
local defaultBGM=false
local maxLoadedCount=3
local volume=1

---@async
local function task_setVolume(obj,ve,time,stop)
    local vs=obj.vol
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local v=MATH.lerp(vs,ve,t)
        obj.vol=v
        obj.source:setVolume(v*volume)
        if t==1 then
            obj.volChanging=false
            break
        end
    end
    if stop then
        obj.source:stop()
    end
    obj.volChanging=false
    return true
end
---@async
local function task_setPitch(obj,pe,time)
    local ps=obj.pitch
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local p=MATH.lerp(ps,pe,t)
        obj.pitch=p
        obj.source:setPitch(p)
        if t==1 then
            obj.pitchChanging=false
            return true
        end
    end
end
---@async
local function task_setLowgain(obj,pe,time)
    local ps=obj.lowgain
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local p=MATH.lerp(ps,pe,t)
        obj.lowgain=p
        obj.source:setFilter{type='bandpass',lowgain=obj.lowgain^9.42,highgain=obj.highgain^9.42,volume=1}
        if t==1 then
            obj.lowgainChanging=false
            return true
        end
    end
end
---@async
local function task_setHighgain(obj,pe,time)
    local ps=obj.highgain
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local p=MATH.lerp(ps,pe,t)
        obj.highgain=p
        obj.source:setFilter{type='bandpass',lowgain=obj.lowgain^9.42,highgain=obj.highgain^9.42,volume=1}
        if t==1 then
            obj.highgainChanging=false
            return true
        end
    end
end
local function _clearTask(obj,mode)
    local taskFunc=
        mode=='volume' and task_setVolume or
        mode=='pitch' and task_setPitch or
        mode=='lowgain' and task_setLowgain or
        mode=='highgain' and task_setHighgain or
        'any'
    TASK.removeTask_iterate(function(task)
        return task.args[1]==obj and (taskFunc=='any' or task.code==taskFunc)
    end,obj)
end

local function _updateSources()
    local n=#lastLoadNames
    while #lastLoadNames>maxLoadedCount and n>0 do
        local name=lastLoadNames[n]
        if srcLib[name].source and not srcLib[name].source:isPlaying() then
            srcLib[name].source:release()
            srcLib[name].source=false
            _clearTask(srcLib[name],'any')
        end
        n=n-1
    end
end
local function _addFile(name,path)
    if not srcLib[name] then
        ins(nameList,name)
        srcLib[name]={
            name=name,
            path=path,
            source=false,
            vol=0,
            volChanging=false,
            pitch=1,
            pitchChanging=false,
            lowgain=1,
            lowgainChanging=false,
            highgain=1,
            highgainChanging=false,
        }
    end
end
local function _tryLoad(name)
    if srcLib[name] then
        local obj=srcLib[name]
        if obj.source then
            return true
        else
            local suc,res=pcall(audio.newSource,obj.path,'stream')
            if suc then
                obj.source=res
                obj.source:setLooping(true)
                ins(lastLoadNames,1,name)
                return true
            else
                LOG('info',("Wrong path for BGM '%s': %s"):format(obj.name,obj.path))
            end
        end
    elseif name then
        LOG('info',"No BGM: "..name)
    end
end

local BGM={}

---Get the loaded BGMs' name list, READ ONLY
---@return table
function BGM.getList() return nameList end

---Get the loaded BGMs' count
---@return number
function BGM.getCount() return #nameList end

---Set the default BGM(s) to play when `BGM.play()` is called without arguments
---@param bgms string | string[]
function BGM.setDefault(bgms)
    if type(bgms)=='string' then
        bgms={bgms}
    elseif type(bgms)=='table' then
        for i=1,#bgms do assert(type(bgms[i])=='string',"BGM.setDefault(bgms): Need string|list<string>") end
    else
        error("BGM.setDefault(bgms): Need string|list<string>")
    end
    defaultBGM=bgms
end

---Set the max count of loaded BGMs
---
---When loaded BGMs' count exceeds this value, some not-playing BGM source will be released
---@param count number
function BGM.setMaxSources(count)
    assert(type(count)=='number' and count>0 and count%1==0,"BGM.setMaxSources(count): Need int >=1")
    maxLoadedCount=count
    _updateSources()
end

---Set the volume of BGM module
---@param vol number
function BGM.setVol(vol)
    assert(type(vol)=='number' and vol>=0 and vol<=1,"BGM.setVol(vol): Need in [0,1]")
    volume=vol
    for i=1,#nowPlay do
        local bgm=nowPlay[i]
        if not bgm.volChanging then
            bgm.source:setVolume(bgm.vol*vol)
        end
    end
end

---Load BGM(s) from file(s)
---@param name string | string[]
---@param path string
---@overload fun(map:table<string, string>)
function BGM.load(name,path)
    if type(name)=='table' then
        for k,v in next,name do
            _addFile(k,v)
        end
    else
        _addFile(name,path)
    end
    table.sort(nameList)
    LOG(BGM.getCount().." BGM files added")
end

---Play BGM(s), stop previous playing BGM(s) if exists
---Multi-channel BGMs must be exactly same length, all sources will be set to loop mode
---@param bgms? false | string | string[]
---@param args? string | '-preLoad' | '-noloop' | '-sdin'
function BGM.play(bgms,args)
    if not bgms then bgms=defaultBGM end
    if not bgms then return end
    if not args then args='' end

    bgms=type(bgms)=='string' and {bgms} or type(bgms)=='table' and bgms or {false}
    for i=1,#bgms do
        if type(bgms[i])~='string' then
            error("BGM.play(bgms,args): bgms need string|list<string>")
        end
    end

    if
        TABLE.equal(lastPlay,bgms) and
        srcLib[lastPlay[1]] and srcLib[lastPlay[1]].source and
        srcLib[lastPlay[1]].source:isPlaying()
    then
        return
    end

    if not STRING.sArg(args,'-preLoad') then
        lastPlay=bgms
    end

    if STRING.sArg(args,'-preLoad') then
        for _,bgm in next,bgms do
            _tryLoad(bgm)
        end
    else
        BGM.stop()

        local sourceReadyToPlay={}
        for _,bgm in next,bgms do
            if _tryLoad(bgm) then
                local obj=srcLib[bgm]
                obj.vol=0
                obj.pitch=1
                obj.lowgain=1
                obj.highgain=1
                obj.volChanging=false
                obj.pitchChanging=false
                obj.lowgainChanging=false
                obj.highgainChanging=false

                _clearTask(obj)

                ---@type love.Source
                local source=obj.source
                source:setLooping(not STRING.sArg(args,'-noloop'))
                source:setPitch(1)
                source:seek(0)
                source:setFilter()
                if STRING.sArg(args,'-sdin') then
                    obj.vol=1
                    source:setVolume(volume)
                else
                    source:setVolume(0)
                    BGM.set(bgm,'volume',1,.626)
                end
                ins(sourceReadyToPlay,source)

                table.insert(nowPlay,obj)
            end
        end
        for i=1,#sourceReadyToPlay do
            sourceReadyToPlay[i]:play()
        end
    end

    _updateSources()
    return true
end

---Stop current playing BGM(s), fade out if time is given
---@param time? nil | number
function BGM.stop(time)
    assert(time==nil or type(time)=='number' and time>=0,"BGM.stop(time): Need >=0")
    if nowPlay[1] then
        for i=1,#nowPlay do
            local obj=nowPlay[i]
            _clearTask(obj,'volume')
            if time==0 then
                obj.source:stop()
                obj.volChanging=false
            else
                TASK.new(task_setVolume,obj,0,time or .626,true)
                obj.volChanging=true
            end
        end
        TABLE.clear(nowPlay)
        lastPlay=NONE
    end
end

---Set current playing BGM(s) states
---@param bgms 'all' | string | string[]
---@param mode 'volume' | 'lowgain' | 'highgain' | 'volume' | 'pitch' | 'seek'
---@param ... any
function BGM.set(bgms,mode,...)
    if type(bgms)=='string' then
        if bgms=='all' then
            bgms=nowPlay
        else
            bgms={srcLib[bgms]}
        end
    elseif type(bgms)=='table' then
        bgms=TABLE.copy(bgms)
        for i=1,#bgms do
            if type(bgms[i])~='string' then
                error("BGM.set(bgms,mode,...): bgms need string|list<string>")
            end
            bgms[i]=srcLib[bgms[i]]
        end
    else
        error("BGM.set(bgms,mode,...): bgms need string|list<string>")
    end
    for i=1,#bgms do
        local obj=bgms[i]
        if obj and obj.source then
            if mode=='volume' then
                _clearTask(obj,'volume')

                local vol,timeUse=...
                if not timeUse then timeUse=1 end

                assert(type(vol)=='number' and vol>=0 and vol<=1,"BGM.set(...,volume): Need in [0,1]")
                assert(type(timeUse)=='number' and timeUse>=0,"BGM.set(...,time): Need >=0")

                TASK.new(task_setVolume,obj,vol,timeUse)
            elseif mode=='pitch' then
                _clearTask(obj,'pitch')

                local pitch,timeUse=...
                if not pitch then pitch=1 end
                if not timeUse then timeUse=1 end

                assert(type(pitch)=='number' and pitch>0 and pitch<=32,"BGM.set(...,pitch): Need in (0,32]")
                assert(type(timeUse)=='number' and timeUse>=0,"BGM.set(...,time): Need >=0")

                TASK.new(task_setPitch,obj,pitch,timeUse)
            elseif mode=='seek' then
                local time=...
                assert(type(time)=='number',"BGM.set(...,time): Need number")
                obj.source:seek(MATH.clamp(time,0,obj.source:getDuration()))
            elseif mode=='lowgain' then
                if effectsSupported then
                    _clearTask(obj,'lowgain')
                    local lowgain,timeUse=...
                    if not lowgain then lowgain=1 end
                    if not timeUse then timeUse=1 end

                    assert(type(lowgain)=='number' and lowgain>=0 and lowgain<=1,"BGM.set(...,lowgain): Need in [0,1]")
                    assert(type(timeUse)=='number' and timeUse>=0,"BGM.set(...,time): Need >=0")

                    TASK.new(task_setLowgain,obj,lowgain,timeUse)
                    obj.lowgain=lowgain
                    obj.source:setFilter{type='bandpass',lowgain=obj.lowgain,highgain=obj.highgain,volume=1}
                end
            elseif mode=='highgain' then
                if effectsSupported then
                    _clearTask(obj,'highgain')
                    local highgain,timeUse=...
                    if not highgain then highgain=1 end
                    if not timeUse then timeUse=1 end

                    assert(type(highgain)=='number' and highgain>=0 and highgain<=1,"BGM.set(...,highgain): Need in [0,1]")
                    assert(type(timeUse)=='number' and timeUse>=0,"BGM.set(...,time): Need >=0")

                    TASK.new(task_setHighgain,obj,highgain,timeUse)
                    obj.highgain=highgain
                    obj.source:setFilter{type='bandpass',lowgain=obj.lowgain,highgain=obj.highgain,volume=1}
                end
            else
                error("BGM.set(...,mode): Need 'volume'|'lowgain'|'highgain'|'volume'|'pitch'|'seek'")
            end
        end
    end
end

---Get current playing BGM(s) name list (from last called `BGM.play(THIS,...)`)
---@return string[]
function BGM.getPlaying()
    return TABLE.copy(lastPlay)
end

---Get if BGM playing now
---@return boolean
function BGM.isPlaying()
    return nowPlay[1] and nowPlay[1].source:isPlaying()
end

---Get time of BGM playing now, 0 if not exists
---@return number | 0
function BGM.tell()
    local src=nowPlay[1] and nowPlay[1].source
    if src then
        return src:tell()%src:getDuration() -- bug of love2d, tell() may return value greater than duration
    else
        return 0
    end
end

---Get duration of BGM playing now, 0 if not exists
---@return number | 0
function BGM.getDuration()
    if nowPlay[1] then
        return nowPlay[1].source:getDuration()
    else
        return 0
    end
end

return BGM
