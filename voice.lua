if not (love.audio and love.sound) then
    LOG("VOC lib is not loaded (need love.audio & love.sound)")
    return setmetatable({
        _update=NULL,
    },{
        __index=function(_,k)
            error("attempt to use VOC."..k..", but VOC lib is not loaded (need love.audio & love.sound)")
        end
    })
end

local rem=table.remove

local initialized=false
local volume=1
local crossTime=.08
local diversion=0

local voiceQueue={}
local voiceSet={} -- {vocSet1={'voc1_1', 'voc1_2', ...}, vocSet2={'voc2_1', ...}, ...}
local sourceBank={} -- {vocName1={SRC1s}, vocName2={SRC2s}, ...}

local VOC={}

---Set the cross time of voice, make voices more continuous
---@param time number
function VOC.setCrossTime(time)
    assert(type(time)=='number' and time>=0,"VOC.setCrossTime(time): Need >=0")
    crossTime=time
end

---Set the diversion range of voice, make voices more natural
---@param range number
function VOC.setDiversion(range)
    assert(type(range)=='number' and range>=0 and range<12,"VOC.setDiversion(range): Need in [0,12)")
    diversion=range
end

---Set the volume of voice module
---@param vol number
function VOC.setVol(vol)
    assert(type(vol)=='number' and vol>=0 and vol<=1,"VOC.setVol(vol): Need in [0,1]")
    volume=vol
end

---Get the number of voice files in the bank
---@return number
function VOC.getCount() return 0 end

---Get the number of voice files in the bank
---@return number
function VOC.getQueueCount() return 0 end

---Get the number of voice files in the bank
---@return number #Free channel id
function VOC.getFreeChannel() return 0 end

---Load voice files from specified path
---
---Only available after `VOC.init()`
---@param path string Path to the folder contains voice files, including the last '/'
---@diagnostic disable-next-line: unused-local
function VOC.load(path) error("VOC.load(path): Call VOC.init() first") end

---Add a voice to specified (or a free) queue
---
---Only available after `VOC.load()`
---@param name string
---@param channelID? number
---@diagnostic disable-next-line: unused-local
function VOC.play(name,channelID) end

---Update all voice channels (called by Zenitha)
---
---For each channel, play next voice if current ended
function VOC._update() end

---Initialize VOC lib (only once), must be called before use
---@param list table
function VOC.init(list)
    if initialized then
        LOG('warn',"VOC.init: Attempt to initialize twice")
        return
    end
    initialized,VOC.init=true,nil
    voiceQueue,sourceBank,voiceSet={},{},{}

    local count=#list

    local function _loadVoiceFile(path,N,vocName)
        local fullPath=path..vocName..'.ogg'
        local suc,res=pcall(love.audio.newSource,fullPath,'stream')
        if suc then
            sourceBank[vocName]={res}
            table.insert(voiceSet[N],vocName)
            return true
        end
    end
    -- Load voice with string
    local function _getVoice(str)
        local L=sourceBank[str]
        local n=1
        while L[n]:isPlaying() do
            n=n+1
            if not L[n] then
                L[n]=L[1]:clone()
                L[n]:seek(0)
                break
            end
        end
        return L[n]
    end

    function VOC.load(path)
        for i=1,count do
            voiceSet[list[i]]={}

            local n=0
            repeat n=n+1 until not _loadVoiceFile(path,list[i],list[i]..'_'..n)

            if n==1 then
                if not _loadVoiceFile(path,list[i],list[i]) then
                    LOG('info',"No VOC: "..list[i])
                end
            end
            if not voiceSet[list[i]][1] then
                voiceSet[list[i]]=nil
            end
        end
    end

    function VOC.getCount() return count end

    function VOC.getQueueCount() return #voiceQueue end

    function VOC.getFreeChannel()
        local l=#voiceQueue
        for i=1,l do
            if #voiceQueue[i]==0 then return i end
        end
        voiceQueue[l+1]={s=0}
        return l+1
    end

    function VOC.play(name,channelID)
        if volume>0 then
            local _=voiceSet[name]
            if not _ then return end
            if channelID then
                local L=voiceQueue[channelID]
                L[#L+1]=_[math.random(#_)]
                L.s=1
                -- Add to queue[chn]
            else
                voiceQueue[VOC.getFreeChannel()]={s=1,_[math.random(#_)]}
                -- Create new channel & play
            end
        end
    end

    function VOC._update()
        for i=#voiceQueue,1,-1 do
            local Q=voiceQueue[i]
            if Q.s==0 then -- Free channel, auto delete when >3
                if i>3 then
                    rem(voiceQueue,i)
                end
            elseif Q.s==1 then -- Waiting load source
                Q[1]=_getVoice(Q[1])
                Q[1]:setVolume(volume)
                Q[1]:setPitch((2^(1/12))^(diversion*(math.random()*2-1)))
                Q[1]:play()
                Q.s=Q[2] and 2 or 4
            elseif Q.s==2 then -- Playing 1,ready 2
                if Q[1]:getDuration()-Q[1]:tell()<crossTime then
                    Q[2]=_getVoice(Q[2])
                    Q[2]:setVolume(volume)
                    Q[1]:setPitch((2^(1/12))^(diversion*(math.random()*2-1)))
                    Q[2]:play()
                    Q.s=3
                end
            elseif Q.s==3 then -- Playing 12 same time
                if not Q[1]:isPlaying() then
                    for j=1,#Q do
                        Q[j]=Q[j+1]
                    end
                    Q.s=Q[2] and 2 or 4
                end
            elseif Q.s==4 then -- Playing last
                if not Q[1].isPlaying(Q[1]) then
                    Q[1]=nil
                    Q.s=0
                end
            end
        end
    end
end

return VOC
