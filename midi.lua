local debug=false

---@class Zenitha.MIDI.Event
---@field tick number tick
---@field type number midi-type number
---@field name 'NoteStart' | 'NoteEnd' | 'ControlChange' | 'ProgramChange' | 'PitchBend' | 'MetaEvent' readable event type name
---@field channel number? For all event except MetaEvent
---@field note number? NoteStart & NoteEnd
---@field velocity number? NoteStart & NoteEnd
---@field control number? ControlChange
---@field value number? ControlChange & ProgramChange & PitchBend
---@field subType number? MetaEvent
---@field data string MetaEvent

---@class Zenitha.MIDI
---@field midFormat number
---@field trackCount number
---@field tickPerQuarterNote number
---@field beatPerMinute number|number[] list when has multiple SetTempo event
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
local function VLQ(str)
    local e=1
    while str:byte(e)>127 do e=e+1 end
    if e==1 then
        return str:byte(),str:sub(2)
    else
        local sum=0
        for i=1,e do
            sum=sum*2^7+str:byte(i)%128
        end
        return sum,str:sub(e+1)
        -- return sum+r[e],str:sub(e+1) -- why mid doesn't use real VLQ with offset
    end
end

local read=STRING.readChars
---@param sData string
---@param handler fun(event:Zenitha.MIDI.Event)
---@return Zenitha.MIDI
function MIDI.newSong(sData,handler)
    assert(type(sData)=='string',"MIDI.newSong(songData,handler): songData need string")
    assert(type(handler)=='function',"MIDI.newSong(songData,handler): handler need function")
    local Song={
        handler=handler,
        playing=true,
    }
    local bpmList={}

    local sec
    assert(type(sData)=='string',"file not found")

    sec,sData=read(sData,8)
    assert(sec=='MThd\0\0\0\6',"not a midi file")

    sec,sData=read(sData,2)
    Song.midFormat=STRING.binNum(sec)

    sec,sData=read(sData,2)
    Song.trackCount=STRING.binNum(sec)

    sec,sData=read(sData,2)
    Song.tickPerQuarterNote=STRING.binNum(sec)

    Song.tracks={}
    for _=1,Song.trackCount do
        if debug then print("TRACK ".._..":") end
        local track={}
        sec,sData=read(sData,4)
        assert(sec=='MTrk',"not a midi track")

        sec,sData=read(sData,4)
        local trackDataLen=STRING.binNum(sec)
        local tData
        tData,sData=read(sData,trackDataLen)

        local tickAnchor,timeAnchor=0,0
        local tickPerSecond=26
        local tick=0
        repeat
            local dTick
            dTick,tData=VLQ(tData)
            if debug and dTick>0 then print("D "..dTick) end
            tick=tick+dTick

            local time=timeAnchor+(tick-tickAnchor)/tickPerSecond

            ---@type Zenitha.MIDI.Event
            local event={tick=tick,time=time}

            sec,tData=read(tData,1)
            event.type=sec:byte()
            if event.type>=0x90 and event.type<=0x9F then
                event.name='NoteStart'
                event.channel=event.type-0x90
                sec,tData=read(tData,2)
                event.note=sec:byte(1)
                event.velocity=sec:byte(2)
            elseif event.type>=0x80 and event.type<=0x8F then
                event.name='NoteEnd'
                event.channel=event.type-0x80
                sec,tData=read(tData,2)
                event.note=sec:byte(1)
                event.velocity=sec:byte(2)
            elseif event.type>=0xB0 and event.type<=0xBF then
                event.name='ControlChange'
                event.channel=event.type-0xB0
                sec,tData=read(tData,2)
                event.control=sec:byte(1)
                event.value=sec:byte(2)
            elseif event.type>=0xC0 and event.type<=0xCF then
                event.name='ProgramChange'
                event.channel=event.type-0xC0
                sec,tData=read(tData,1)
                event.value=sec:byte()
            elseif event.type>=0xE0 and event.type<=0xEF then
                event.name='PitchBend'
                event.channel=event.type-0xE0
                sec,tData=read(tData,2)
                event.value=STRING.binNum(sec)
            elseif event.type==0xFF then
                event.name='MetaEvent'
                event.subType,tData=VLQ(tData)
                local len
                len,tData=VLQ(tData)
                event.data,tData=read(tData,len)
                if event.subType==0x51 then -- SetTempo
                    timeAnchor=timeAnchor+(tick-tickAnchor)/tickPerSecond
                    tickAnchor=tick
                    local bpm=60000000/STRING.binNum(event.data)
                    tickPerSecond=Song.tickPerQuarterNote*bpm/60
                    table.insert(bpmList,bpm)
                    if debug then print("MetaEvent: SetTempo",bpm) end
                elseif event.subType==0x58 then -- TimeSignature
                    if debug then print("MetaEvent: TimeSignature",event.data:byte(1),event.data:byte(2),event.data:byte(3),event.data:byte(4)) end
                elseif event.subType==0x59 then -- KeySignature
                    if debug then print("MetaEvent: KeySignature",event.data:byte(1),event.data:byte(2)) end
                end
            elseif debug then
                print("UNK",event.type)
            end
            if event.name then
                if debug and event.name~='MetaEvent' then
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
    assert(#Song.tracks==Song.trackCount,"redundancy track")
    assert(#sData==0,"redundancy data")

    Song.time=0
    Song.trackHeads=TABLE.new(1,Song.trackCount)
    Song.beatPerMinute=
        #bpmList==1 and bpmList[1] or
        #bpmList>1 and bpmList or
        0

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

function MIDI:update(dt)
    if not self.playing then return end
    self.time=self.time+dt
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
