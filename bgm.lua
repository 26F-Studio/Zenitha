local audio=love.audio
local effectsSupported=audio.isEffectsSupported()
local ins=table.insert

local nameList={}
local srcLib={}-- Stored bgm objects: {name='foo', source=bar, ...}, more info at function _addFile()
local lastLoadNames={}
local nowPlay={}-- Playing bgm objects
local lastPlay=NONE-- Directly stored last played bgm name(s)

--- @type false|string|string[]
local defaultBGM=false
local maxLoadedCount=3
local volume=1

local function task_setVolume(obj,ve,time,stop)
    local vs=obj.vol
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local v=MATH.mix(vs,ve,t)
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
local function task_setPitch(obj,pe,time)
    local ps=obj.pitch
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local p=MATH.mix(ps,pe,t)
        obj.pitch=p
        obj.source:setPitch(p)
        if t==1 then
            obj.pitchChanging=false
            return true
        end
    end
end
local function task_setLowgain(obj,pe,time)
    local ps=obj.lowgain
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local p=MATH.mix(ps,pe,t)
        obj.lowgain=p
        obj.source:setFilter{type='bandpass',lowgain=obj.lowgain^9.42,highgain=obj.highgain^9.42,volume=1}
        if t==1 then
            obj.lowgainChanging=false
            return true
        end
    end
end
local function task_setHighgain(obj,pe,time)
    local ps=obj.highgain
    local t=0
    while true do
        t=time~=0 and math.min(t+coroutine.yield()/time,1) or 1
        local p=MATH.mix(ps,pe,t)
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
            srcLib[name].source=srcLib[name].source:release() and nil
            _clearTask(srcLib[name],'any')
        end
        n=n-1
    end
end
local function _addFile(name,path)
    if not srcLib[name] then
        ins(nameList,name)
        srcLib[name]={
            name=name,path=path,source=false,
            vol=0,volChanging=false,
            pitch=1,pitchChanging=false,
            lowgain=1,lowgainChanging=false,
            highgain=1,highgainChanging=false,
        }
    end
end
local function _tryLoad(name)
    if srcLib[name] then
        local obj=srcLib[name]
        if obj.source then
            return true
        elseif love.filesystem.getInfo(obj.path) then
            obj.source=audio.newSource(obj.path,'stream')
            obj.source:setLooping(true)
            ins(lastLoadNames,1,name)
            return true
        else
            LOG(STRING.repD("Wrong path for BGM '$1': $2",obj.name,obj.path),5)
        end
    elseif name then
        LOG("No BGM: "..name,5)
    end
end

local BGM={}

--- Get the loaded BGMs' name list, READ ONLY
--- @return table
function BGM.getList() return nameList end

--- Get the loaded BGMs' count
--- @return number
function BGM.getCount() return #nameList end

--- Set the default BGM(s) to play when BGM.play() is called without arguments
--- @param bgms string|string[]
function BGM.setDefault(bgms)
    if type(bgms)=='string' then
        bgms={bgms}
    elseif type(bgms)=='table' then
        for i=1,#bgms do assert(type(bgms[i])=='string',"BGM list must be list of strings") end
    else
        error("BGM must be string or table")
    end
    defaultBGM=bgms
end

--- Set the max count of loaded BGMs
---
--- When loaded BGMs' count exceeds this value, some not-playing BGM source will be released
--- @param count number
function BGM.setMaxSources(count)
    assert(type(count)=='number' and count>0 and count%1==0,"Source count must be positive integer")
    maxLoadedCount=count
    _updateSources()
end

--- Set BGM volume
--- @param vol number
function BGM.setVol(vol)
    assert(type(vol)=='number' and vol>=0 and vol<=1,"Volume must be in range 0~1")
    volume=vol
    for i=1,#nowPlay do
        local bgm=nowPlay[i]
        if not bgm.volChanging then
            bgm.source:setVolume(bgm.vol*vol)
        end
    end
end

--- Load BGM(s) from file(s)
--- @param name string|string[]
--- @param path string|string[]
--- @overload fun(map:table)
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

--- Play BGM(s), stop previous playing BGM(s) if exists
--- Multi-channel BGMs must be exactly same length, all sources will be set to loop mode
--- @param bgms? false|string|string[]
--- @param args? string|'-preLoad'|'-noloop'|'-sdin'
function BGM.play(bgms,args)
    if not bgms then bgms=defaultBGM end
    if not bgms then return end
    if not args then args='' end

    if type(bgms)=='string' then bgms={bgms} end
    assert(type(bgms)=='table',"BGM must be string or table")

    if
        TABLE.compare(lastPlay,bgms) and
        srcLib[lastPlay[1]] and srcLib[lastPlay[1]].source and
        srcLib[lastPlay[1]].source:isPlaying()
    then
        return
    end

    BGM.stop()

    if not STRING.sArg(args,'-preLoad') then
        lastPlay=bgms
    end

    if STRING.sArg(args,'-preLoad') then
        for _,bgm in next,bgms do
            assert(type(bgm)=='string',"BGM list can only be list of string")
            _tryLoad(bgm)
        end
    else
        local sourceReadyToPlay={}
        for _,bgm in next,bgms do
            assert(type(bgm)=='string',"BGM list can only be list of string")
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

                local source=obj.source
                source:setLooping(not STRING.sArg(args,'-noloop'))
                source:setPitch(1)
                source:seek(0)
                source:setFilter()
                if STRING.sArg(args,'-sdin') then
                    obj.vol=1
                    source:setVolume(volume)
                    BGM.set(bgm,'volume',1,0)
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

--- Stop current playing BGM(s), fade out if time is given
--- @param time? nil|number
function BGM.stop(time)
    assert(time==nil or type(time)=='number' and time>=0,"Given stopping time must be positive number, but got "..tostring(time))
    if #nowPlay>0 then
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
        TABLE.cut(nowPlay)
        lastPlay=NONE
    end
end

--- Set (current playing) BGM(s) states
--- @param mode 'volume'|'lowgain'|'highgain'|'volume'|'pitch'|'seek'
--- @param ... any
function BGM.set(bgms,mode,...)
    if type(bgms)=='string' then
        if bgms=='all' then
            bgms=nowPlay
        else
            bgms={srcLib[bgms]}
        end
    elseif type(bgms)=='table' then
        bgms=TABLE.shift(bgms)
        for i=1,#bgms do
            assert(type(bgms[i])=='string',"BGM list must be list of strings")
            bgms[i]=srcLib[bgms[i]]
        end
    else
        error("BGM.play(name,args): name must be string or table")
    end
    for i=1,#bgms do
        local obj=bgms[i]
        if obj and obj.source then
            if mode=='volume' then
                _clearTask(obj,'volume')

                local vol,time=...
                if not time then time=1 end

                assert(type(vol)=='number' and vol>=0 and vol<=1,"BGM.set(...,volume): volume must be in range 0~1")
                assert(type(time)=='number' and time>=0,"BGM.set(...,time): time must be positive number")

                TASK.new(task_setVolume,obj,vol,time)
            elseif mode=='pitch' then
                _clearTask(obj,'pitch')

                local pitch,changeTime=...
                if not pitch then pitch=1 end
                if not changeTime then changeTime=1 end

                assert(type(pitch)=='number' and pitch>0 and pitch<=32,"BGM.set(...,pitch): pitch must be in range 0~32")
                assert(type(changeTime)=='number' and changeTime>=0,"BGM.set(...,time): time must be positive number")

                TASK.new(task_setPitch,obj,pitch,changeTime)
            elseif mode=='seek' then
                local time=...
                assert(type(time)=='number',"BGM.set(...,time): time must be number")
                obj.source:seek(MATH.clamp(time,0,obj.source:getDuration()))
            elseif mode=='lowgain' then
                if effectsSupported then
                    _clearTask(obj,'lowgain')
                    local lowgain,changeTime=...
                    if not lowgain then lowgain=1 end
                    if not changeTime then changeTime=1 end

                    assert(type(lowgain)=='number' and lowgain>=0 and lowgain<=1,"BGM.set(...,lowgain,highgain): lowgain must be in range 0~1")
                    assert(type(changeTime)=='number' and changeTime>=0,"BGM.set(...,time): time must be positive number")

                    TASK.new(task_setLowgain,obj,lowgain,changeTime)
                    obj.lowgain=lowgain
                    obj.source:setFilter{type='bandpass',lowgain=obj.lowgain,highgain=obj.highgain,volume=1}
                end
            elseif mode=='highgain' then
                if effectsSupported then
                    _clearTask(obj,'highgain')
                    local highgain,changeTime=...
                    if not highgain then highgain=1 end
                    if not changeTime then changeTime=1 end

                    assert(type(highgain)=='number' and highgain>=0 and highgain<=1,"BGM.set(...,lowgain,highgain): highgain must be in range 0~1")
                    assert(type(changeTime)=='number' and changeTime>=0,"BGM.set(...,time): time must be positive number")

                    TASK.new(task_setHighgain,obj,highgain,changeTime)
                    obj.highgain=highgain
                    obj.source:setFilter{type='bandpass',lowgain=obj.lowgain,highgain=obj.highgain,volume=1}
                end
            else
                error("BGM.set(...,mode): mode must be 'volume', 'pitch', or 'seek'")
            end
        end
    end
end

--- Get (current playing) BGM(s) name list
function BGM.getPlaying()
    return TABLE.shift(lastPlay)
end

--- Get if BGM playing now
function BGM.isPlaying()
    return #nowPlay>0 and nowPlay[1].source:isPlaying()
end

--- Get time of BGM playing now
function BGM.tell()
    if nowPlay[1] then
        return nowPlay[1].source:tell()
    end
end

--- Get duration of BGM playing now
function BGM.getDuration()
    if nowPlay[1] then
        return nowPlay[1].source:getDuration()
    end
end

return BGM
