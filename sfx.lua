local type=type
local ins,rem=table.insert,table.remove
local floor,rnd=math.floor,math.random
local clamp=MATH.clamp

---@type string[]
local nameList={}
---@type table<string, love.Source[]>
local srcMap={}
---@type table<string, {base:number, top:number}>
local packSetting={}

local volume=1
local stereo=1

local noteVal={
    C=1,c=1,
    D=3,d=3,
    E=5,e=5,
    F=6,f=6,
    G=8,g=8,
    A=10,a=10,
    B=12,b=12,
}
local noteName={'C','C#','D','D#','E','F','F#','G','G#','A','A#','B'}
local function _getTuneHeight(tune)
    local octave=tonumber(tune:sub(-1,-1))
    if octave then
        local tuneHeight=noteVal[tune:sub(1,1)]
        if tuneHeight then
            tuneHeight=tuneHeight+(octave-1)*12
            local s=tune:sub(2,2)
            if s=='s' or s=='#' then
                tuneHeight=tuneHeight+1
            elseif s=='f' or s=='b' then
                tuneHeight=tuneHeight-1
            end
            return tuneHeight
        end
    end
end

local SFX={}

---@param name string
---@param path string
---@param lazyLoad? boolean
local function loadOne(name,path,lazyLoad)
    assert(type(name)=='string',"SFX.load: name must be string")
    assert(type(path)=='string',"SFX.load: path must be string")
    if love.filesystem.getInfo(path) and FILE.isSafe(path) then
        if srcMap[name] then
            rem(nameList,TABLE.find(nameList,name))
            for _,src in next,srcMap[name] do
                if type(src)=='userdata' then
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
---@overload fun(pathTable:table,lazyLoad?:boolean)
---@param name string
---@param path string
---@param lazyLoad? boolean If true, the file will be loaded when it's played for the first time
function SFX.load(name,path,lazyLoad)
    if type(name)=='table' then
        local success=0
        local fail=0
        for k,v in next,name do
            if loadOne(k,v,path) then
                success=success+1
            else
                fail=fail+1
            end
        end
        if fail>0 then
            LOG(fail.." SFX files missing")
        end
        LOG(("%d SFX files added, total %d"):format(success,#nameList))
    else
        if loadOne(name,path,lazyLoad) then
            LOG("SFX loaded: "..name)
        else
            LOG("No SFX: "..path)
        end
    end
    table.sort(nameList)
end

---Load SFX samples from specified directory
---@param pack {name:string, path:string, base:string}
---## Example
---```lua
---SFX.loadSample{name='bass',path='assets/sample/bass',base='A2'}
---```
function SFX.loadSample(pack)
    assert(type(pack)=='table',"Usage: SFX.loadsample(table)")
    assert(pack.name,"No field: name")
    assert(pack.path,"No field: path")
    local num=1
    while love.filesystem.getInfo(pack.path..'/'..num..'.ogg') do
        srcMap[pack.name..num]={love.audio.newSource(pack.path..'/'..num..'.ogg','static')}
        num=num+1
    end
    local base=(_getTuneHeight(pack.base) or 37)-1
    local top=base+num-1
    packSetting[pack.name]={base=base,top=top}
    LOG((num-1).." "..pack.name.." samples loaded")
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

---Get note name with note number
---
---1 --> ' C1'
---13 --> 'C#2'
---@param note number Note number, 1~127
---@return string Note name, e.g. 'C4'
function SFX.getNoteName(note)
    if note<1 then
        return '---'
    else
        note=note-1
        local octave=floor(note/12)+1
        return noteName[note%12+1]..octave
    end
end

---Play a sample
---@param pack string
---@param ... string|number 0~1 number for volume, big integer and string for tune
---## Example
---```lua
---SFX.playSample('piano', .7,'C4','E4', .9,'G4')
---```
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
                local tune=type(a)=='string' and _getTuneHeight(a) or a -- Absolute tune in number
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
---@param vol? number 0~1
---@param pos? number -1~1
---@param pitch? number +12 for an octave
function SFX.play(name,vol,pos,pitch)
    vol=(vol or 1)*volume
    if vol<=0 then return end

    local S=srcMap[name] -- Source list
    if not S then return end
    if type(S[1])=='string' then -- Do the lazy load
        local path=tostring(S[1]) -- to avoid syntax checker error
        local src=love.filesystem.getInfo(path) and FILE.isSafe(path) and love.audio.newSource(path,'static')
        assert(src,"WTF why path data can be bad")
        S[1]=src
    end

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
    S:setPitch(pitch and 1.0594630943592953^pitch or 1)
    S:play()
end

---Remove references of stopped SFX sources
function SFX.releaseFree()
    for _,L in next,srcMap do
        for i,src in next,L do
            if not src:isPlaying() then
                src:release()
                rem(L,i)
            end
        end
    end
end

return SFX
