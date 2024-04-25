local printEvent=false
local printBigDT=1e99
local printMeta=false
local printUnk=false

---@class Zenitha.MIDI.Event
---@field tick number tick
---@field time number time (second)
---@field type number midi-type number
---@field name 'NoteEnd'|'NoteStart'|'KeyPressure'|'ControlChange'|'ProgramChange'|'ChannelPressure'|'PitchBend'|'MetaEvent'|'SysMes'|'Unknown' readable event type name
---@field channel number? For all event except MetaEvent
---@field note number? NoteEnd & NoteStart
---@field velocity number? NoteEnd & NoteStart & KeyPressure & ChannelPressure
---@field control number? ControlChange
---@field value number? ControlChange & ProgramChange & PitchBend
---@field subType number? MetaEvent
---@field subName string? MetaEvent
---@field data string MetaEvent & SysMes

---@class Zenitha.MIDI
---@field midFormat number
---@field trackCount number
---@field tickPerQuarterNote number
---@field beatPerMinute string for storing multiple-tempo like "100,120"
---@field handler function
---@field playing boolean
---
---@field tracks Zenitha.MIDI.Event[]
---@field trackHeads (number|false)[]
---@field time number
local MIDI={}
MIDI.__index=MIDI

-- local r={0}
-- for i=1,12 do r[i+1]=r[i]+2^(7*i) end -- Offset value of N-byte VLQ
local byte=string.byte
local function VLQ(str)
    local e=1
    while byte(str,e)>127 do e=e+1 end
    if e==1 then
        return byte(str),str:sub(2)
    else
        local sum=0
        for i=1,e do
            sum=sum*2^7+byte(str,i)%128
        end
        return sum,str:sub(e+1)
        -- return sum+r[e],str:sub(e+1) -- why mid doesn't use real VLQ with offset
    end
end

local read=STRING.readChars
---@param sData string
---@param handler fun(event: Zenitha.MIDI.Event)
---@return Zenitha.MIDI
---## Example
---```lua
---MIDI.newSong(FILE.load("music.mid"),function(event)
---    if event.name=='NoteStart' then
---        SFX.playSample('lead',event.velocity/127,event.note)
---    end
---end):play()
---```
function MIDI.newSong(sData,handler)
    assert(type(sData)=='string',"MIDI.newSong(songData,handler): songData need string")
    assert(type(handler)=='function',"MIDI.newSong(songData,handler): handler need function")
    local Song={
        playing=true,
        time=0,
        handler=handler,
    }

    local bpmEvents={}

    local sec
    assert(type(sData)=='string',"file not found")

    sec,sData=read(sData,8)
    assert(sec=='MThd\0\0\0\6',"File head missing")

    sec,sData=read(sData,2)
    Song.midFormat=STRING.binNum(sec)
    if printMeta then printf("Format: %d",Song.midFormat) end

    sec,sData=read(sData,2)
    Song.trackCount=STRING.binNum(sec)
    Song.trackHeads=TABLE.new(1,Song.trackCount)
    if printMeta then printf("Track count: %d",Song.trackCount) end

    sec,sData=read(sData,2)
    Song.tickPerQuarterNote=STRING.binNum(sec)
    if printMeta then printf("TPQN: %d",Song.tickPerQuarterNote) end

    Song.tracks={}
    for t=1,Song.trackCount do
        if printMeta then print("TRACK "..t) end
        local track={}
        sec,sData=read(sData,4)
        assert(sec=='MTrk',"Track head missing")

        sec,sData=read(sData,4)
        local trackDataLen=STRING.binNum(sec)
        local tData
        tData,sData=read(sData,trackDataLen)

        local tick=0
        local prevType
        repeat
            local dTick
            dTick,tData=VLQ(tData)
            if dTick>printBigDT then print("D "..dTick) end
            tick=tick+dTick

            ---@type Zenitha.MIDI.Event
            local event={tick=tick}

            event.type=tData:byte()
            if event.type<0x80 then
                if prevType then
                    event.type=prevType
                else
                    event.name='Unknown'
                    event.data,tData=read(tData,1)
                    if printUnk then printf("Unknown event: %02X",event.type) end
                    tData=tData:sub(2)
                end
            else
                prevType=event.type
                tData=tData:sub(2)
            end

            if event.type>=0x80 and event.type<=0x8F then
                event.name='NoteEnd'
                event.channel=event.type%0x10
                sec,tData=read(tData,2)
                event.note=sec:byte(1)
                event.velocity=sec:byte(2)
            elseif event.type>=0x90 and event.type<=0x9F then
                event.name='NoteStart'
                event.channel=event.type%0x10
                sec,tData=read(tData,2)
                event.note=sec:byte(1)
                event.velocity=sec:byte(2)
            elseif event.type>=0xA0 and event.type<=0xAF then
                event.name='KeyPressure'
                event.channel=event.type%0x10
                sec,tData=read(tData,2)
                event.note=sec:byte(1)
                event.velocity=sec:byte(2)
            elseif event.type>=0xB0 and event.type<=0xBF then
                event.name='ControlChange'
                event.channel=event.type%0x10
                sec,tData=read(tData,2)
                event.control=sec:byte(1)
                event.value=sec:byte(2)
            elseif event.type>=0xC0 and event.type<=0xCF then
                event.name='ProgramChange'
                event.channel=event.type%0x10
                sec,tData=read(tData,1)
                event.value=sec:byte()
            elseif event.type>=0xD0 and event.type<=0xDF then
                event.name='ChannelPressure'
                event.channel=event.type%0x10
                sec,tData=read(tData,1)
                event.velocity=sec:byte()
            elseif event.type>=0xE0 and event.type<=0xEF then
                event.name='PitchBend'
                event.channel=event.type%0x10
                sec,tData=read(tData,2)
                event.value=STRING.binNum(sec)
            elseif event.type==0xFF then -- MetaEvent
                prevType=nil
                event.name='MetaEvent'
                event.subType,tData=VLQ(tData)
                local len
                len,tData=VLQ(tData)
                event.data,tData=read(tData,len)
                if event.subType<=0x07 then -- Texts
                    event.subName=
                        event.subType==0x01 and '' or
                        event.subType==0x02 and 'CopyRight' or
                        event.subType==0x03 and 'TrackName' or
                        event.subType==0x04 and 'InstrumentName' or
                        event.subType==0x05 and 'Lyric' or
                        event.subType==0x06 and 'Marker' or
                        event.subType==0x07 and 'CuePoint' or ''
                    if printMeta then printf("MetaEvent-%sText: %s",event.subName,event.data) end
                elseif event.subType==0x20 then -- MIDIChannelPrefix
                    event.subName='MIDIChannelPrefix'
                    if printMeta then print("MetaEvent-MIDIChannelPrefix",event.data:byte()) end
                elseif event.subType==0x2F then -- EndOfTrack
                    event.subName='EndOfTrack'
                    if printMeta then print("MetaEvent-EndOfTrack") end
                elseif event.subType==0x51 then -- SetTempo, Save value for calculating all events' real time
                    event.subName='SetTempo'
                    local bpm=MATH.roundUnit(60000000/STRING.binNum(event.data),0.001)
                    if #bpmEvents==0 or bpm~=bpmEvents[#bpmEvents].bpm then
                        table.insert(bpmEvents,{tick=tick,bpm=bpm})
                        if printMeta then printf("MetaEvent-SetTempo: %d",bpm) end
                    end
                elseif event.subType==0x54 then -- SMPTEOffset
                    event.subName='SMPTEOffset'
                    if printMeta then print("MetaEvent-SMPTEOffset: ",event.data:byte(1,-1)) end
                elseif event.subType==0x58 then -- TimeSignature
                    event.subName='TimeSignature'
                    if printMeta then print("MetaEvent-TimeSignature: ",event.data:byte(1,-1)) end
                elseif event.subType==0x59 then -- KeySignature
                    event.subName='KeySignature'
                    if printMeta then print("MetaEvent-KeySignature: ",event.data:byte(1,-1)) end
                elseif event.subType==0x7F then -- SequencerSpecific
                    event.subName='SequencerSpecific'
                    if printMeta then print("MetaEvent-SequencerSpecific: ",event.data:byte(1,-1)) end
                else
                    event.name=nil -- Undefined
                    if printMeta then print("MetaEvent-Undefined",event.subType,event.data) end
                end
            elseif event.type>=0xF0 then -- System events, shouldn't appear in .mid file...?
                prevType=nil
                event.name='SysMes'
                if event.type==0xF0 then -- SysEx
                    event.subName='SysEx'
                    event.data,tData=read(tData,(assert((tData:find('\xF7')))))
                    event.data=event.data:sub(1,-2)
                elseif event.type==0xF2 then -- Song Position Pointer
                    event.subName='SongPositionPointer'
                    event.data,tData=read(tData,2)
                elseif event.type==0xF3 then -- Song Select
                    event.subName='SongSelect'
                    event.data,tData=read(tData,1)
                elseif event.type==0xF6 then event.subName='TuneRequest'
                elseif event.type==0xF8 then event.subName='TimingClock'
                elseif event.type==0xFA then event.subName='Start'
                elseif event.type==0xFB then event.subName='Continue'
                elseif event.type==0xFC then event.subName='Stop'
                elseif event.type==0xFE then event.subName='ActiveSensing'
                elseif event.type==0xFF then event.subName='Reset'
                else event.name=nil -- Undefined codepoints
                end
            end
            if event.name then
                if printEvent and event.type>=0x80 and event.type<=0xEF then
                    local n=event.name
                    print(n,
                        (n=='NoteStart' or n=='NoteEnd') and event.note or
                        n=='ControlChange' and event.control or
                        (n=='ProgramChange' or n=='PitchBend') and event.value or
                        "?"
                    )
                end
                table.insert(track,event)
            end
        until #tData==0
        table.insert(Song.tracks,track)
    end
    assert(#Song.tracks==Song.trackCount,"Track count doesn't match")
    assert(#sData==0,"Redundancy data")

    -- Calculate time of each event
    for i=1,Song.trackCount do
        local bpmPointer=1
        local tickPerSecond=Song.tickPerQuarterNote*120/60
        if printMeta then
            printf("Track %d init tickPerSecond is %f",i,tickPerSecond)
        end
        local tickAnchor,timeAnchor=0,0
        local track=Song.tracks[i]
        for j=1,#track do
            local event=track[j]
            if bpmPointer>0 and event.tick>=bpmEvents[bpmPointer].tick then
                timeAnchor,tickAnchor=timeAnchor+(bpmEvents[bpmPointer].tick-tickAnchor)/tickPerSecond,bpmEvents[bpmPointer].tick
                tickPerSecond=Song.tickPerQuarterNote*bpmEvents[bpmPointer].bpm/60
                if printMeta then
                    printf("tickPerSecond change to %f, timeAnchor=%f",tickPerSecond,timeAnchor)
                end
                bpmPointer=bpmPointer+1
                if not bpmEvents[bpmPointer] then bpmPointer=-1 end -- No more bpm change
            end
            event.time=timeAnchor+(event.tick-tickAnchor)/tickPerSecond
        end
    end

    -- Simplify bpmEvents to a bpm list
    if #bpmEvents>0 then
        for i=1,#bpmEvents do bpmEvents[i]=bpmEvents[i].bpm end
        Song.beatPerMinute=table.concat(bpmEvents,',')
    elseif bpmEvents[1] then
        Song.beatPerMinute=tostring(bpmEvents[1].bpm)
    else
        Song.beatPerMinute="120"
    end
    if printMeta then printf("BPM: %d",Song.beatPerMinute) end

    return setmetatable(Song,MIDI)
end

---@param t number
function MIDI:seek(t)
    self.playing=true
    self.time=t
    for i=1,#self.trackHeads do
        local p=1
        self.trackHeads[i]=p
    end
end

function MIDI:reset()
    self.playing=true
    self.time=0
    for i=1,#self.trackHeads do
        self.trackHeads[i]=1
    end
end

function MIDI:step(minDT)
    if not self.playing then return end
    local heads=self.trackHeads
    local nearestTime=1e99
    for i=1,self.trackCount do
        local event=self.tracks[i][heads[i]]
        if event then
            nearestTime=math.min(nearestTime,event.time)
        end
    end
    nearestTime=math.max(nearestTime,minDT)
    self:update()
end

function MIDI:update(dt)
    if not self.playing then return end
    if dt then self.time=self.time+dt end
    local heads=self.trackHeads
    local dead=true
    for i=1,self.trackCount do
        while true do
            local event=self.tracks[i][heads[i]]
            if event then
                dead=false
                if self.time>=event.time then
                    self.handler(event)
                    heads[i]=heads[i]+1
                else
                    break
                end
            else
                break
            end
        end
    end
    if dead then
        self.playing=false
    end
end

---Play the song with TASK.new
function MIDI:play()
    local upd=MIDI.update
    local yield=coroutine.yield
    TASK.new(function()
        while self.playing do
            upd(self,yield())
        end
    end)
end

return MIDI
