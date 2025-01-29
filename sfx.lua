local SFX={}

local sub=string.sub
local floor=math.floor

local noteVal={C=0,c=0,D=2,d=2,E=4,e=4,F=5,f=5,G=7,g=7,A=9,a=9,B=11,b=11}
local noteName={'C','C#','D','D#','E','F','F#','G','G#','A','A#','B'}

---Convert note name to note number (C4=60, same as MIDI)
---@param tune string Note name, like 'C4'
---@return number #Note number, -1 if invalid
function SFX.getTuneHeight(tune)
    local octave=tonumber(tune:sub(-1,-1))
    if not octave then return -1 end
    local tuneHeight=noteVal[sub(tune,1,1)]
    if not tuneHeight then return -1 end
    local s=sub(tune,2,2)
    return tuneHeight+(octave+1)*12+(
        (s=='s' or s=='#') and  1 or
        (s=='f' or s=='b') and -1 or
        0
    )
end

---Get note name with note number (60=C4, same as MIDI)
---@param note number Note number, must > 0
---@return string #Note name, '--' if invalid
function SFX.getNoteName(note)
    if note<0 then return '--' end
    return noteName[note%12+1]..(floor(note/12)-1)
end

if not (love.filesystem and love.audio and love.sound) then
    LOG("SFX lib is not loaded (need love.filesystem & love.audio & love.sound)")
    SFX[('load')]=function()
        error("attempt to use SFX.load, but SFX lib is not loaded (need love.filesystem & love.audio & love.sound)")
    end
    return setmetatable(SFX,{
        __index=function(t,k)
            t[k]=NULL
            return t[k]
        end
    })
end

local type=type
local ins,rem=table.insert,table.remove
local rnd,clamp=math.random,MATH.clamp

---@type string[]
local nameList={}
---@type table<string, (string | love.Source)[]>
local srcMap={}
---@type table<string, {base:number, top:number}>
local packSetting={}

local volume=1
local stereo=1

---@param name string
---@param path string
---@param lazyLoad? boolean
local function loadOne(name,path,lazyLoad)
    assert(type(name)=='string',"SFX.load: name need string")
    assert(type(path)=='string',"SFX.load: path need string")
    if love.filesystem.getInfo(path) then
        if srcMap[name] then
            TABLE.delete(nameList,name)
            for _,src in next,srcMap[name] do
                if type(src)~='string' then
                    src:release()
                end
            end
        end
        ins(nameList,name)
        srcMap[name]={lazyLoad and path or love.audio.newSource(path,'static')}
        return true
    end
end

---Load SFX name-path pairs
---@overload fun(name:string, path:string, lazyLoad?:boolean) In lazeLoad mode, the file will be loaded when it's played for the first time
---@overload fun(pathTable:table<string, string>, lazyLoad?:boolean) Batch Name-Path load
---@overload fun(path:string, metaInfo:table<string, {[1]:number, [2]:number}>) Load one SFX file with clips with Name-{start,length} pairs
function SFX.load(_1,_2,_3)
    if type(_1)=='string' and type(_2)=='string' then
        if loadOne(_1,_2,_3) then
            LOG("SFX loaded: ".._1)
        else
            LOG("No SFX: ".._2)
        end
    elseif type(_1)=='table' then
        local success=0
        local fail=0
        for k,v in next,_1 do
            if loadOne(k,v) then
                success=success+1
            else
                fail=fail+1
            end
        end
        if fail>0 then
            LOG(fail.." SFX files missing")
        end
        LOG(("%d SFX files added, total %d"):format(success,#nameList))
    elseif type(_1)=='string' and type(_2)=='table' then
        local metaDec=love.sound.newDecoder(_1)
        local duration=metaDec:getDuration()
        local fullSize=
            metaDec:getSampleRate()*
            metaDec:getDuration()*
            metaDec:getBitDepth()*
            metaDec:getChannelCount()/8
        local meta=_2
        for n,t in next,meta do
            local dec=love.sound.newDecoder(_1,math.ceil(t[2]/duration*fullSize))
            dec:seek(t[1])
            ins(nameList,n)
            srcMap[n]={love.audio.newSource(dec:decode(),'static')}
        end
    else
        LOG("SFX.load: need (name,path,bool?) or ({name=path,...},bool?) or (path,{name={start,len},...})")
    end
    table.sort(nameList)
end

---Load SFX samples from specified directory  
---Files should be 1.ogg, 2.ogg, ..., and 1 semitone higher then previous one  
---shrink: drop a bit of samples at the end of each clip, to avoid error due to compressing
---### Example
---```
---SFX.loadSample{name='bass',path='assets/sample/bass',base='A2',shrink=0.01}
---```
---@param pack {name:string, path:string, base:string, count:number, shrink?:number}
function SFX.loadSample(pack)
    assert(type(pack)=='table',"Usage: SFX.loadsample(table)")
    assert(pack.name,"SFX.loadSample: need field 'name'")
    assert(pack.path,"SFX.loadSample: need field 'path'")
    local base=(SFX.getTuneHeight(pack.base) or 37)-1
    if pack.path:match('%.[a-z]+$') then
        -- Single file mode
        local dcd=love.sound.newDecoder(pack.path)
        local duration=dcd:getDuration()
        local fullSize=
            dcd:getSampleRate()*
            dcd:getDuration()*
            dcd:getBitDepth()*
            dcd:getChannelCount()/8
        dcd=love.sound.newDecoder(pack.path,fullSize/pack.count*(1-(pack.shrink or 0)))
        for n=1,pack.count do
            dcd:seek((n-1)*duration/pack.count)
            srcMap[pack.name..n]={love.audio.newSource(dcd:decode())}
        end
        packSetting[pack.name]={base=base,top=base+pack.count-1}
        LOG(pack.count.." "..pack.name.." samples loaded")
    else
        -- path/1.ogg mode
        local num=1
        while love.filesystem.getInfo(pack.path..'/'..num..'.ogg') do
            srcMap[pack.name..num]={love.audio.newSource(pack.path..'/'..num..'.ogg','static')}
            num=num+1
        end
        local top=base+num-1
        packSetting[pack.name]={base=base,top=top}
        LOG((num-1).." "..pack.name.." samples loaded")
    end
end

---Get the number of SFX files loaded (not include SFX samples)
---@return number
function SFX.getCount()
    return #nameList
end

---Set the volume of SFX module
---@param vol number
function SFX.setVol(vol)
    assert(type(vol)=='number' and vol>=0 and vol<=1,"SFX.setVol(vol): Need in [0,1]")
    volume=vol
end

---Set the stereo of SFX module
---@param s number 0~1
function SFX.setStereo(s)
    assert(type(s)=='number' and s>=0 and s<=1,"SFX.setStereo(s): Need in [0,1]")
    stereo=s
end

---Play a sample
---### Example
---```
---SFX.playSample('piano', .7,'C4','E4', .9,'G4')
---```
---@param pack string
---@param ... string | number 0~1 number for volume, big integer and string for tune
function SFX.playSample(pack,...)
    if ... then
        local arg={...}
        local vol
        for i=1,#arg do
            local a=arg[i]
            if type(a)=='number' and a<=1 then
                vol=a
            else
                local base=packSetting[pack].base
                local top=packSetting[pack].top
                local tune=type(a)=='string' and SFX.getTuneHeight(a) or a -- Absolute tune in number
                local playTune=tune+rnd(-2,2)
                if playTune<=base then -- Too low notes
                    playTune=base+1
                elseif playTune>top then -- Too high notes
                    playTune=top
                end
                SFX.play(pack..playTune-base,vol,nil,tune-playTune)
            end
        end
    end
end

---Play a SFX
---@param name string
---@param vol? number 0~1, default to 1
---@param pos? number -1~1, default to 0
---@param pitch? number 0 = default, 12 = an Octave higher
function SFX.play(name,vol,pos,pitch)
    vol=(vol or 1)*volume
    if vol<=0 then return end

    local S=srcMap[name] -- Source list
    if not S then return end
    if type(S[1])=='string' then -- Do the lazy load
        local path=tostring(S[1]) -- to avoid syntax checker error
        local src=love.filesystem.getInfo(path) and love.audio.newSource(path,'static')
        S[1]=assert(src,"WTF why path data can be bad")
    end

    ---@cast S love.Source[]

    local n=1
    while S[n]:isPlaying() do
        n=n+1
        if not S[n] then
            S[n]=S[1]:clone()
            S[n]:seek(0)
            break
        end
    end

    S=S[n] -- AU_SRC
    if S:getChannelCount()==1 then
        if pos then
            pos=clamp(pos,-1,1)*stereo
            S:setPosition(pos,1-pos^2,0)
        else
            S:setPosition(0,0,0)
        end
    end
    S:setVolume(vol^1.626)
    S:setPitch(pitch and (2^(1/12))^pitch or 1)
    S:play()
end

---Remove references of stopped SFX sources
function SFX.releaseFree()
    for _,L in next,srcMap do
        for i,src in next,L do
            ---@cast src love.Source
            if not src:isPlaying() then
                src:release()
                rem(L,i)
            end
        end
    end
end

return SFX
