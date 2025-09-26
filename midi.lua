local printEvent=false
local printBigDT=1e99
local printMeta=false
local printUnk=false

---@class Zenitha.MIDI.Event
---@field tick number tick
---@field time number time (second)
---@field type number midi-type number
---@field name 'NoteEnd' | 'NoteStart' | 'KeyPressure' | 'ControlChange' | 'ProgramChange' | 'ChannelPressure' | 'PitchBend' | 'MetaEvent' | 'SysMes' | 'Unknown' readable event type name
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
---@field eof boolean
---
---@field tracks Zenitha.MIDI.Event[]
---@field trackHeads (number | false)[]
---@field time number
local MIDI={}
MIDI.__index=MIDI

-- local r={0}
-- for i=1,12 do r[i+1]=r[i]+2^(7*i) end -- Offset value of N-byte VLQ
---@param buf string.buffer
local function VLQ(buf)
    local ptr=buf:ref()
    if ptr[0]<=127 then
        buf:skip(1)
        return ptr[0]
    else
        local endOffset=1 while ptr[endOffset]>127 do endOffset=endOffset+1 end
        local sum=0
        for offset=0,endOffset do
            sum=sum*2^7+ptr[offset]%128
        end
        buf:skip(endOffset+1)
        return sum
        -- return sum+r[e-1] -- why MID doesn't use real VLQ with offset
    end
end

---### Example
---```
---MIDI.newSong(FILE.load("music.mid"),function(event)
---    if event.name=='NoteStart' then
---        SFX.playSample('lead',event.velocity/127,event.note)
---    end
---end):play()
---```
---@param sData string
---@param handler fun(event: Zenitha.MIDI.Event)
---@return Zenitha.MIDI
function MIDI.newSong(sData,handler)
    assert(type(sData)=='string',"MIDI.newSong(songData,handler): songData need string")
    local songBuf=STRING.newBuf()
    songBuf:put(sData)
    assert(type(handler)=='function',"MIDI.newSong(songData,handler): handler need function")
    local Song={
        eof=false,
        time=0,
        handler=handler,
    }

    local bpmEvents={}

    local buf

    buf=songBuf:get(8)
    assert(buf=='MThd\0\0\0\6',"File head missing")

    buf=songBuf:get(2)
    Song.midFormat=STRING.binNum(buf)
    if printMeta then printf("Format: %d",Song.midFormat) end

    buf=songBuf:get(2)
    Song.trackCount=STRING.binNum(buf)
    Song.trackHeads=TABLE.new(1,Song.trackCount)
    if printMeta then printf("Track count: %d",Song.trackCount) end

    buf=songBuf:get(2)
    Song.tickPerQuarterNote=STRING.binNum(buf)
    if printMeta then printf("TPQN: %d",Song.tickPerQuarterNote) end

    Song.tracks={}
    for t=1,Song.trackCount do
        if printMeta then print("TRACK "..t) end
        local track={}
        buf=songBuf:get(4)
        assert(buf=='MTrk',"Track head missing")

        buf=songBuf:get(4)
        local trackDataLen=STRING.binNum(buf)
        local trackBuf=STRING.newBuf()
        trackBuf:put(songBuf:get(trackDataLen))

        local tick=0
        local prevType
        repeat
            local dTick
            dTick=VLQ(trackBuf)
            if dTick>printBigDT then print("D "..dTick) end
            tick=tick+dTick

            ---@type Zenitha.MIDI.Event
            ---@diagnostic disable-next-line
            local event={tick=tick}

            event.type=trackBuf:ref()[0]
            if event.type<0x80 then
                if prevType then
                    event.type=prevType
                else
                    event.name='Unknown'
                    event.data=trackBuf:get(1)
                    if printUnk then printf("Unknown event: %02X",event.type) end
                    trackBuf:skip(1)
                end
            else
                prevType=event.type
                trackBuf:skip(1)
            end

            if event.type>=0x80 and event.type<=0x8F then
                event.name='NoteEnd'
                event.channel=event.type%0x10
                buf=trackBuf:get(2)
                event.note=buf:byte(1)
                event.velocity=buf:byte(2)
            elseif event.type>=0x90 and event.type<=0x9F then
                event.name='NoteStart'
                event.channel=event.type%0x10
                buf=trackBuf:get(2)
                event.note=buf:byte(1)
                event.velocity=buf:byte(2)
            elseif event.type>=0xA0 and event.type<=0xAF then
                event.name='KeyPressure'
                event.channel=event.type%0x10
                buf=trackBuf:get(2)
                event.note=buf:byte(1)
                event.velocity=buf:byte(2)
            elseif event.type>=0xB0 and event.type<=0xBF then
                event.name='ControlChange'
                event.channel=event.type%0x10
                buf=trackBuf:get(2)
                event.control=buf:byte(1)
                event.value=buf:byte(2)
            elseif event.type>=0xC0 and event.type<=0xCF then
                event.name='ProgramChange'
                event.channel=event.type%0x10
                buf=trackBuf:get(1)
                event.value=buf:byte()
            elseif event.type>=0xD0 and event.type<=0xDF then
                event.name='ChannelPressure'
                event.channel=event.type%0x10
                buf=trackBuf:get(1)
                event.velocity=buf:byte()
            elseif event.type>=0xE0 and event.type<=0xEF then
                event.name='PitchBend'
                event.channel=event.type%0x10
                buf=trackBuf:get(2)
                event.value=STRING.binNum(buf)
            elseif event.type==0xFF then -- MetaEvent
                prevType=nil
                event.name='MetaEvent'
                event.subType=VLQ(trackBuf)
                local len
                len=VLQ(trackBuf)
                event.data=trackBuf:get(len)
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
                    event.data=''
                    while true do
                        local c=trackBuf:get(1)
                        if c=='\xF7' then break end
                        assert(c~='',"SysEx not closed")
                        event.data=event.data..c
                    end
                elseif event.type==0xF2 then -- Song Position Pointer
                    event.subName='SongPositionPointer'
                    event.data=trackBuf:get(2)
                elseif event.type==0xF3 then -- Song Select
                    event.subName='SongSelect'
                    event.data=trackBuf:get(1)
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
        until #trackBuf==0
        table.insert(Song.tracks,track)
    end
    assert(#Song.tracks==Song.trackCount,"Track count doesn't match")
    assert(#songBuf==0,"Redundancy data")

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
    if bpmEvents[1] then
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

---Seek in seconds (WIP)
---@param t number
function MIDI:seek(t)
    self.eof=false
    self.time=t
    for i=1,#self.trackHeads do
        local s,e=1,#self.tracks[i]
        while e>s do
            local m=math.floor((s+e)/2)
            if self.tracks[i][m].time<t then s=m+1 else e=m end
        end
        self.trackHeads[i]=s
    end
end

---Seek to 0
function MIDI:reset()
    self.eof=false
    self.time=0
    for i=1,#self.trackHeads do
        self.trackHeads[i]=1
    end
end

---Update the song to next note, with optional minimum delta time
---@param minDT? number
function MIDI:step(minDT)
    if self.eof then return end
    local heads=self.trackHeads
    local nearestTime=1e99
    for i=1,self.trackCount do
        local event=self.tracks[i][heads[i]]
        if event then
            nearestTime=math.min(nearestTime,event.time)
        end
    end
    self:update(math.max(nearestTime,minDT or 0)-self.time+2^-40)
end

---Update the song, trigger the events if need
---@param dt number
function MIDI:update(dt)
    if self.eof then return end
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
        self.eof=true
    end
end

---A shortcut to play the song with TASK object.
---
---You can also manually call `:update(dt)` until `.eof` to do excatly the same thing.
function MIDI:play()
    TASK.new(function()
        local yield,upd=coroutine.yield,MIDI.update
        while not self.eof do
            upd(self,yield())
        end
    end)
end

return MIDI
