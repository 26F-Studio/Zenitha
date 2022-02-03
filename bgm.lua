local audio=love.audio

local nameList={}
local srcLib={}
local lastLoadNames={}
local nowPlay={}-- Now playing name(s) & source(s), like {{name='foo',source=bar},...}

local defaultBGM=false
local maxLoadedCount=3
local volume=1

local function _updateSources()
    local n=#lastLoadNames
    while #lastLoadNames>maxLoadedCount do
        local name=lastLoadNames[n]
        if srcLib[name].source:isPlaying() then
            n=n-1
            if n<=0 then return end
        else
            srcLib[name].source=srcLib[name].source:release() and nil
            table.remove(lastLoadNames,n)
            return
        end
    end
end
local function _addFile(name,path)
    if not srcLib[name] then
        table.insert(nameList,name)
        srcLib[name]={
            name=name,path=path,source=false,
            vol=0,volChanging=false,
            pitch=1,pitchChanging=false,
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
            table.insert(lastLoadNames,1,name)
            _updateSources()
            return true
        else
            LOG(STRING.repD("Wrong path for BGM '$1': $2",obj.name,obj.path),5)
        end
    elseif name then
        LOG("No BGM: "..name,5)
    end
end

local function task_setVolume(obj,ve,time,stop)
    local vs=obj.vol
    local t=0
    while true do
        t=math.min(t+coroutine.yield(),time)
        local v=MATH.lerp(vs,ve,t/time)
        obj.source:setVolume(v)
        obj.vol=v
        if t==time then
            if v==0 and stop then
                obj.source:stop()
            end
            obj.volChanging=false
            return true
        end
    end
end
local function clearVolumeTask(obj)
    TASK.removeTask_iterate(function(task)
        return task.code==task_setVolume and task.args[1]==obj
    end,obj)
end

local function task_setPitch(obj,pe)
    local ps=obj.pitch
    local t=0
    while true do
        t=math.min(t+coroutine.yield(),1)
        local p=MATH.lerp(ps,pe,t)
        obj.source:setPitch(p)
        obj.pitch=p
        if t==1 then
            obj.pitchChanging=false
            return true
        end
    end
end
local function clearPitchTask(obj)
    TASK.removeTask_iterate(function(task)
        return task.code==task_setPitch and task.args[1]==obj
    end,obj)
end

local BGM={}

function BGM.getList() return nameList end
function BGM.getCount() return #nameList end

function BGM.setDefault(bgms)
    if type(bgms)=='string' then
        bgms={bgms}
    elseif type(bgms)=='table' then
        for i=1,#bgms do assert(type(bgms[i])=='string',"BGM list must be list of strings") end
    else
        error("BGM.play(name,args): name must be string or table")
    end
    defaultBGM=bgms
end
function BGM.setMaxSources(count)
    assert(type(count)=='number' and count>0 and count%1==0,"BGM.setMaxSources(count): count must be a positive integer")
    maxLoadedCount=count
    _updateSources()
end
function BGM.setVol(vol)
    assert(type(vol)=='number' and vol>=0 and vol<=1,"BGM.setVol(vol): count must be in range 0~1")
    volume=vol
    for i=1,#nowPlay do
        local np=nowPlay[i]
        if not np.volChanging then
            np.source:setVolume(vol)
            if vol==0 then
                np.source:pause()
            end
        end
    end
end
function BGM.load(name,path)
    if type(name)=='table' then
        for i=1,#name do
            _addFile(name[i].name,name[i].path)
        end
    else
        _addFile(name,path)
    end
    table.sort(nameList)
    LOG(BGM.getCount().." BGM files added")
end

function BGM.play(bgms,args)
    if not args then args='' end
    if not bgms then bgms=defaultBGM end
    if not bgms then return end

    if type(bgms)=='string' then bgms={bgms} end
    -- if TABLE.compare(nowPlay,bgms) then return end

    assert(type(bgms)=='table',"BGM.play(name,args): name must be string or table")

    BGM.stop()

    for i=1,#bgms do
        local bgm=bgms[i]
        if type(bgm)~='string' then error("BGM list can only be list of string") end
        if not _tryLoad(bgm) or STRING.sArg(args,'-preLoad') then goto _CONTINUE_ end

        local obj=srcLib[bgms[i]]
        obj.vol=1
        obj.pitch=1
        obj.volChanging=false
        obj.pitchChanging=false

        local source=obj.source
        source:seek(0)
        source:setPitch(1)
        source:setVolume(volume)
        source:play()

        table.insert(nowPlay,obj)
        clearVolumeTask(obj)

        ::_CONTINUE_::
    end
end
function BGM.stop(args)
    if not args then args='' end

    if #nowPlay>0 then
        for i=1,#nowPlay do
            local obj=nowPlay[i]
            clearVolumeTask(obj)
            if STRING.sArg(args,'-sdout') then
                obj.source:stop()
                obj.volChanging=false
            else
                TASK.new(task_setVolume,obj,0,false,true)
                obj.volChanging=true
            end
        end
        TABLE.cut(nowPlay)
    end
end
function BGM.set(bgms,mode,...)
    if type(bgms)=='string' then
        if bgms=='all' then
            bgms=nowPlay
        else
            bgms={srcLib[bgms]}
        end
    elseif type(bgms)=='table' then
        for i=1,#bgms do
            assert(type(bgms[i])=='string',"BGM list must be list of strings")
            bgms[i]=srcLib[bgms[i]]
        end
    else
        error("BGM.play(name,args): name must be string or table")
    end
    for i=1,#bgms do
        local obj=bgms[i]
        if obj.source then
            if mode=='volume' then
                clearVolumeTask(obj)

                local vol,time=...
                if not time then time=1 end

                assert(type(vol)=='number' and vol>=0 and vol<=1,"BGM.set(...,volume): volume must be in range 0~1")
                assert(type(time)=='number' and time>=0,"BGM.set(...,time): time must be positive number")

                TASK.new(task_setVolume,obj,vol,time)
            elseif mode=='pitch' then
                clearPitchTask(obj)

                local pitch,time=...
                if not pitch then pitch=1 end
                if not time then time=1 end

                assert(type(pitch)=='number' and pitch>0 and pitch<=32,"BGM.set(...,pitch): pitch must be in range 0~32")
                assert(type(time)=='number' and time>=0,"BGM.set(...,time): time must be positive number")

                TASK.new(task_setPitch,obj,pitch,time)
            elseif mode=='seek' then
                local time=...
                assert(type(time)=='number' and time>=0 and time<=obj.source:getDuration(),"BGM.set(...,time): time must be in range 0~[song length]")
                obj.source:seek(...)
            else
                error("BGM.set(...,mode): mode must be 'volume', 'pitch', or 'seek'")
            end
        end
    end
end
function BGM.isPlaying()
    return #nowPlay>0
end

return BGM
