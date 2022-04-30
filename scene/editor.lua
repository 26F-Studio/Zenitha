local gc=love.graphics
local ms,kb=love.mouse,love.keyboard
local getTime=love.timer.getTime

local ins,rem=table.insert,table.remove
local max,min=math.max,math.min
local floor,ceil=math.floor,math.ceil
local abs,atan2=math.abs,math.atan2
local sin,cos=math.sin,math.cos
local byte,sub=string.byte,string.sub
local find,match=string.find,string.match

local sArg=STRING.sArg

local UIscale=(SCR.w0^2+SCR.h0^2)^.5/1260

local touchMode=false
local activePages={}
local curPage=false
local pageInfo={COLOR.L,"Page: ",COLOR.LR,false,COLOR.LD,"/",COLOR.lI,false}
local clipboardFreshCD
local escapeHoldTime

local tempInputBox=WIDGET.new{type='inputBox'}
local clipboardText=''
local touches={}

local scene={}

-------------------------------------------------------------

local help=setmetatable({},{__index=function() return '[-]' end})
local globalComboMap={
    ['ctrl+tab']=           {func='switchFile',     args='-next'},
    ['ctrl+shift+tab']=     {func='switchFile',     args='-prev'},

    ['ctrl+w']=             {func='closeFile',      args=''},
    ['ctrl+n']=             {func='newFile',        args=''},
}
local pageComboMap={
    ['left']=               {func='moveCursor',     args='-left'},
    ['right']=              {func='moveCursor',     args='-right'},
    ['up']=                 {func='moveCursor',     args='-up'},
    ['down']=               {func='moveCursor',     args='-down'},
    ['home']=               {func='moveCursor',     args='-home'},
    ['end']=                {func='moveCursor',     args='-end'},
    ['pageup']=             {func='moveCursor',     args='-jump -up'},
    ['pagedown']=           {func='moveCursor',     args='-jump -down'},

    ['ctrl+left']=          {func='moveCursor',     args='-left -jump'},
    ['ctrl+right']=         {func='moveCursor',     args='-right -jump'},
    ['ctrl+up']=            {func='scrollV',        args='-up'},
    ['ctrl+down']=          {func='scrollV',        args='-down'},
    ['ctrl+home']=          {func='moveCursor',     args='-home -jump'},
    ['ctrl+end']=           {func='moveCursor',     args='-end -jump'},
    ['ctrl+pageup']=        {func='scrollV',        args='-up -jump'},
    ['ctrl+pagedown']=      {func='scrollV',        args='-down -jump'},

    ['shift+left']=         {func='moveCursor',     args='-left -hold'},
    ['shift+right']=        {func='moveCursor',     args='-right -hold'},
    ['shift+up']=           {func='moveCursor',     args='-up -hold'},
    ['shift+down']=         {func='moveCursor',     args='-down -hold'},
    ['shift+home']=         {func='moveCursor',     args='-home -hold'},
    ['shift+end']=          {func='moveCursor',     args='-end -hold'},

    ['ctrl+shift+left']=    {func='moveCursor',     args='-left -jump -hold'},
    ['ctrl+shift+right']=   {func='moveCursor',     args='-right -jump -hold'},
    ['ctrl+shift+up']=      {func='moveCursor',     args='-up -hold'},-- Same as no ctrl
    ['ctrl+shift+down']=    {func='moveCursor',     args='-down -hold'},-- Same as no ctrl
    ['ctrl+shift+home']=    {func='moveCursor',     args='-home -jump -hold'},
    ['ctrl+shift+end']=     {func='moveCursor',     args='-end -jump -hold'},

    ['alt+up']=             {func='moveLine',       args='-up'},
    ['alt+down']=           {func='moveLine',       args='-down'},

    ['space']=              {func='insStr',         args=' '},
    ['backspace']=          {func='delete',         args='-left'},
    ['delete']=             {func='delete',         args='-right'},
    ['ctrl+backspace']=     {func='delete',         args='-word -left'},
    ['ctrl+delete']=        {func='delete',         args='-word -right'},
    ['tab']=                {func='indent',         args='-add'},
    ['shift+tab']=          {func='indent',         args='-remove'},
    ['return']=             {func='insLine',        args='-normal'},
    ['ctrl+return']=        {func='insLine',        args='-under'},
    ['shift+return']=       {func='insLine',        args='-above'},

    ['ctrl+a']=             {func='selectAll',      args=''},
    ['ctrl+d']=             {func='duplicate',      args=''},
    ['ctrl+x']=             {func='cut',            args=''},
    ['ctrl+c']=             {func='copy',           args=''},
    ['ctrl+v']=             {func='paste',          args='-clipboard'},

    ['ctrl+z']=             {func='undo',           args=''},
    ['ctrl+y']=             {func='redo',           args=''},
    ['ctrl+s']=             {func='save',           args=''},
}
local alteredComboMap-- If exist, it will map combo to another
local keyAlias={-- Directly ovveride original key
    ['kp+']='+',['kp-']='-',['kp*']='*',['kp/']='/',
    ['kpenter']='return',
    ['kp.']='.',
    ['kp7']='home',['kp1']='end',
    ['kp9']='pageup',['kp3']='pagedown',
}
local unimportantKeys={}-- Combokeys (nothing happen when pressed)
local comboKeyName={}-- Combokeys indicator

if SYSTEM=='Windows' then
    unimportantKeys['lgui'],unimportantKeys['rgui']=true,true
    comboKeyName={
        {color=COLOR.lB,keys={'lctrl','rctrl'},  name='ctrl', text='CTRL'},
        {color=COLOR.lG,keys={'lshift','rshift'},name='shift',text='SHIFT'},
        {color=COLOR.lR,keys={'lalt','ralt'},    name='alt',  text='ALT'},
    }
    TABLE.cover({
        newFile='Press ctrl+N to create a new file',
    },help)
elseif SYSTEM=='macOS' then
    keyAlias['lalt'],keyAlias['ralt']='option','option'
    keyAlias['lgui'],keyAlias['rgui']='command','command'
    comboKeyName={
        {color=COLOR.lB,keys={'lctrl','rctrl'},  name='ctrl',   text='CONTROL'},
        {color=COLOR.lR,keys={'lalt','ralt'},    name='option', text='OPTION'},
        {color=COLOR.lR,keys={'lgui','rgui'},    name='command',text='COMMAND'},
        {color=COLOR.lG,keys={'lshift','rshift'},name='shift',  text='SHIFT'},
    }
    alteredComboMap={
        ['option+shift+left']='ctrl+shift+left',
        ['option+shift+right']='ctrl+shift+right',
        ['option+shift+up']='ctrl+shift+up',
        ['option+shift+down']='ctrl+shift+down',

        ['command+shift+d']='ctrl+d',
        ['command+shift+w']='ctrl+w',
        ['command+shift+z']='ctrl+y',
        ['command+shift+up']='ctrl+shift+home',
        ['command+shift+down']='ctrl+shift+end',
        ['command+shift+left']='shift+home',
        ['command+shift+right']='shift+end',

        ['option+up']='alt+up',
        ['option+down']='alt+down',
        ['option+left']='ctrl+left',
        ['option+right']='ctrl+right',
        ['option+backspace']='ctrl+backspace',
        ['option+delete']='ctrl+delete',

        ['command+a']='ctrl+a',
        ['command+c']='ctrl+c',
        ['command+n']='ctrl+n',
        ['command+s']='ctrl+s',
        ['command+v']='ctrl+v',
        ['command+x']='ctrl+x',
        ['command+z']='ctrl+z',
        ['command+up']='ctrl+home',
        ['command+down']='ctrl+end',
        ['command+left']='home',
        ['command+right']='end',
        ['command+pageup']='ctrl+pageup',
        ['command+pagedown']='ctrl+pagedown',
        ['command+home']='ctrl+home',
        ['command+end']='ctrl+end',
        ['command+backspace']='ctrl+shift+backspace',
        ['command+delete']='ctrl+shift+delete',
    }
    TABLE.cover({
        newFile='Press command+N to create a new file',
    },help)
elseif MOBILE then
    TABLE.cover({
        -- TODO
    },help)
end

for i=1,#comboKeyName do for _,v in next,comboKeyName[i].keys do unimportantKeys[v]=true end end

-------------------------------------------------------------

-- Compile this when enter scene
local rainbowShader=[[
    uniform float phase;
    vec4 effect(vec4 color,sampler2D tex,vec2 texCoord,vec2 scrCoord){
        float iphase=phase-(scrCoord.x/love_ScreenSize.x+scrCoord.y/love_ScreenSize.y)*6.26;
        return vec4(sin(iphase),sin(iphase+2.0944),sin(iphase-2.0944),1.0)*.5+.5;
    }
]]

local function freshClipboard()
    clipboardText=love.system.getClipboardText()
    if clipboardText=='' then
        clipboardText=false
    else
        clipboardText=clipboardText:gsub('[\r\n]','')
        if #clipboardText>26 then
            clipboardText=clipboardText:sub(1,21).."...("..#clipboardText..")"
        end
    end
end

local function nextWordState(state,t)
    return
        t=='eof' and
            'stop'
        or (
            state=='ready' and (
                t=='space' and 'ready' or
                t=='word' and 'words' or
                t=='sign' and 'signs' or
                t=='other' and 'stop' or
                error('wtf why char type is '..tostring(t))
            ) or
            state=='words' and (
                t=='word' and 'words' or 'stop'
            ) or
            state=='signs' and (
                t=='sign' and 'signs' or 'stop'
            ) or
            error("wtf why state is "..tostring(state))
        )
end

local function freshPageInfo()
    pageInfo[4]=curPage
    pageInfo[8]=#activePages
end

local function ifSelecting()
    if kb.isDown('lshift','rshift') then
        return true
    elseif touchMode and #touches>0 then
        for i=1,#touches do
            if touches[i].keep then
                return true
            end
        end
    end
end

-------------------------------------------------------------

local Page={}
Page.__index=Page
function Page.new(args)
    args=args or ''
    local P=setmetatable({
        windowW=SCR.w0-100,windowH=SCR.h0-100,
        scrollX=0,scrollY=0,
        curX=0,curY=1,
        memX=0,
        selX=false,selY=false,
        charWidth=24,lineHeight=35,
        baseX=1,
        baseY=3,
        fileName="*Untitled",
        filePath=false,
        fileInfo={COLOR.L,"*Untitled"},

        lastMoveTime=-1e6,
        lastInputTime=-1e6,
    },Page)
    if sArg(args,'-welcome') then
        TABLE.connect(P,{
            "-- Welcome to Zenitha editor --",
            '',
            "Type freely on any device.",
            '',
        })
        P:moveCursor('-auto -end -jump')
    else
        P[1]=''
    end
    P:saveCurX()
    return P
end

function Page:loadFile(args,file)
    -- Parse file path and name
    self.filePath=file:getFilename()
    self.fileName=self.filePath:match('.+\\(.+)$') or self.filePath
    self.fileInfo={COLOR.L,self.fileName.."  ",COLOR.DL,self.filePath}

    -- Load file data
    self:delete('-all')
    self:paste('-file',(file:read()))

    -- Reset cursor and scroll
    self.curX,self.curY=0,1
    self:freshScroll()
    self:saveCurX()
end

function Page:undo()
    -- TODO
    MES.new('warn','not implemented yet')
end

function Page:redo()
    -- TODO
    MES.new('warn','not implemented yet')
end

function Page:save()
    if self.filePath then
        -- TODO
        MES.new('warn','not implemented yet')
    end
end

-- Control
function Page:scrollV(args)
    local dy=sArg(args,'-up') and -1 or sArg(args,'-down') and 1
    if not dy then return end
    if sArg(args,'-jump') then dy=max(1,floor(self.windowH/self.lineHeight))*dy end
    self.scrollY=max(min(self.scrollY+dy,#self-1),0)
end

function Page:scrollH(args)
    local dx=sArg(args,'-left') and 1 or sArg(args,'-right') and -1
    if not dx then return end
    self.scrollX=max(self.scrollX+dx,0)
end

function Page:moveCursor(args)
    if sArg(args,'-mouse') then
        if self.curY<1 then self.curY=1; self.curX=0 end
        if self.curY>#self then self.curY=#self; self.curX=#self[self.curY] end
        if self.curX<0 then self.curX=0 end
        if self.curX>#self[self.curY] then self.curX=#self[self.curY] end
        if self.selX==self.curX and self.selY==self.curY then
            self.selX,self.selY=false,false
        end
    else
        local hold=sArg(args,'-hold')
        local jump=sArg(args,'-jump')
        if not sArg(args,'-auto') and hold and not self.selX then
            self.selX,self.selY=self.curX,self.curY
        end
        if sArg(args,'-left') then
            if jump then
                if not hold and self.selX then self.selX,self.selY=false,false end
                local state='ready'
                while true do
                    state=nextWordState(state,
                        self.curX==0 and (self.curY==1 and 'eof' or 'space') or
                        STRING.type(self[self.curY]:sub(self.curX,self.curX))
                    )
                    if state=='stop' then break end
                    if self.curX==0 then
                        self.curY=self.curY-1
                        self.curX=#self[self.curY]
                        break
                    else
                        self.curX=self.curX-1
                    end
                end
            elseif not hold and self.selX then
                self.curX,self.curY=self:getSelArea()
                self.selX,self.selY=false,false
            else
                if self.curX==0 then
                    if self.curY>1 then
                        self:moveCursor('-auto -up')
                        self.curX=#self[self.curY]
                    end
                else
                    self.curX=self.curX-1
                end
            end
            self:saveCurX()
        elseif sArg(args,'-right') then
            if jump then
                if not hold and self.selX then self.selX,self.selY=false,false end
                local state='ready'
                while true do
                    state=nextWordState(state,
                        self.curX==#self[self.curY] and (self.curY==#self and 'eof' or 'space') or
                        STRING.type(self[self.curY]:sub(self.curX+1,self.curX+1))
                    )
                    if state=='stop' then break end
                    if self.curX==#self[self.curY] then
                        self.curY=self.curY+1
                        self.curX=0
                        break
                    else
                        self.curX=self.curX+1
                    end
                end
            elseif not hold and self.selX then
                local _
                _,_,self.curX,self.curY=self:getSelArea()
                self.selX,self.selY=false,false
            else
                if self.curX==#self[self.curY] then
                    if self.curY<#self then
                        self:moveCursor('-auto -down')
                        self.curX=0
                    end
                else
                    self.curX=self.curX+1
                end
            end
            self:saveCurX()
        elseif sArg(args,'-home') then
            if jump then
                self.curY=1
            end
            self.curX=0
            self:saveCurX()
        elseif sArg(args,'-end') then
            if jump then
                self.curY=#self
            end
            self.curX=#self[self.curY]
            self:saveCurX()
        elseif sArg(args,'-up') then
            local l=jump and max(1,floor(self.windowH/self.lineHeight)) or 1
            if self.curY>l then
                self.curY=self.curY-l
                self.curX=min(self.memX,#self[self.curY])
            else
                self.curY=1
                self.curX=0
            end
        elseif sArg(args,'-down') then
            local l=jump and max(1,floor(self.windowH/self.lineHeight)) or 1
            if self.curY<=#self-l then
                self.curY=self.curY+l
                self.curX=min(self.memX,#self[self.curY])
            else
                self.curY=#self
                self.curX=#self[self.curY]
            end
        end
        if not sArg(args,'-auto') then
            if not hold or self.selX==self.curX and self.selY==self.curY then
                self.selX,self.selY=false,false
            end
            self:freshScroll()
        end
    end
    self.lastMoveTime=getTime()
end

function Page:saveCurX()
    self.memX=self.curX
end

function Page:freshScroll()
    self.scrollX=MATH.clamp(self.scrollX,ceil(self.curX-(self.windowW-100)/self.charWidth),self.curX)
    self.scrollY=MATH.clamp(self.scrollY,ceil(self.curY-self.windowH/self.lineHeight),self.curY-1)
end

-- Edit
function Page:insStr(str)
    if str=='' or not str then return end
    if self.selX then self:delete() end
    local l=self[self.curY]
    l=l:sub(1,self.curX)..str..l:sub(self.curX+1)
    self.curX=self.curX+#str
    self[self.curY]=l
    self:freshScroll()
    self:saveCurX()
    SFX.play(tempInputBox.sound_input)
end

function Page:indent(args)
    if sArg(args,'-add') then
        if self.selX then
            local _,startY,_,endY=self:getSelArea()
            if self.curY==endY and self.curX==0 then
                endY=endY-1
            else
                self.curX=self.curX+4
            end
            self.selX=self.selX+4
            for l=startY,endY do self[l]='    '..self[l] end
        else
            self:insStr('    ')
        end
    elseif sArg(args,'-remove') then
        local startX,startY,endX,endY=self:getSelArea()
        local pos

        -- Cut head
        pos=string.find(self[startY],'%S') or #self[startY]
        if pos>1 then
            startX=max(startX-4,pos-5,0)
            self[startY]=self[startY]:sub(min(pos,5))
        end

        if endY>startY then
            -- Cut body
            for l=startY+1,endY-1 do
                pos=string.find(self[l],'%S') or #self[l]
                if pos>1 then self[l]=self[l]:sub(min(pos,5)) end
            end

            -- Cut tail
            pos=string.find(self[endY],'%S') or #self[endY]
            if pos>1 then
                endX=max(endX-4,pos-5,0)
                self[endY]=self[endY]:sub(min(pos,5))
            end
        end
        if self.selY==endY then
            self.curX,self.selX=startX,self.selX and endX
        else
            self.curX,self.selX=endX,self.selX and startX
        end
    end
    self:saveCurX()
end

function Page:delete(args)
    if not args then args='' end
    local result=false-- If delete was successful
    if sArg(args,'-all') then-- Clear all file content
        TABLE.cut(self)
        self[1]=''
        self.scrollX,self.scrollY=0,0
        self.curX,self.curY=0,1
        self.memX=0
        self.selX,self.selY=false,false
        result=true
    elseif self.selX then-- Delete selected area
        local startX,startY,endX,endY=self:getSelArea()
        if startY==endY then
            self[startY]=self[startY]:sub(1,startX)..self[startY]:sub(endX+1)
        else
            self[startY]=self[startY]:sub(1,startX)..self[endY]:sub(endX+1)
            for _=startY+1,endY do rem(self,startY+1) end
        end
        self.curX,self.curY=startX,startY
        self.selX,self.selY=false,false
        result=true
    elseif sArg(args,'-word') then-- Delete word
        if sArg(args,'-left') then
            self:moveCursor('-hold -jump -left')
        elseif sArg(args,'-right') then
            self:moveCursor('-hold -jump -right')
        end
        self:delete('')
    else-- Delete single char
        if sArg(args,'-left') then
            if self.curX==0 then
                if self.curY>1 then
                    self.curX=#self[self.curY-1]
                    self[self.curY-1]=self[self.curY-1]..self[self.curY]
                    rem(self,self.curY)
                    self.curY=self.curY-1
                    result=true
                end
            else
                local l=self[self.curY]
                l=l:sub(1,self.curX-1,0)..l:sub(self.curX+1)
                self[self.curY]=l
                self.curX=max(self.curX-1,0)
                result=true
            end
        elseif sArg(args,'-right') then
            if self.curX==#self[self.curY] then
                if self.curY<#self then
                    self[self.curY]=self[self.curY]..self[self.curY+1]
                    rem(self,self.curY+1)
                    result=true
                end
            else
                local l=self[self.curY]
                l=l:sub(1,self.curX)..l:sub(self.curX+2)
                self[self.curY]=l
                result=true
            end
        end
    end
    if result then
        if not sArg(args,'-auto') then
            SFX.play(tempInputBox.sound_bksp)
            self.lastInputTime=getTime()
        end
        self:freshScroll()
        self:saveCurX()
    end
end

function Page:insLine(args)
    local spaces=not sArg(args,'-auto') and self[self.curY]:match('^ +') or ''
    if sArg(args,'-normal') then
        ins(self,self.curY+1,self[self.curY]:sub(self.curX+1))
        self[self.curY]=self[self.curY]:sub(1,self.curX)
        self.curY=self.curY+1
    elseif sArg(args,'-under') then
        ins(self,self.curY+1,'')
        self.curY=self.curY+1
        self.curX=0
    elseif sArg(args,'-above') then
        ins(self,self.curY,'')
        self.curX=0
    end
    if not sArg(args,'-auto') then
        SFX.play(tempInputBox.sound_input)
        if spaces~='' then self[self.curY]=spaces..self[self.curY] end
    end
    self.curX=#spaces
    self:freshScroll()
    self:saveCurX()
end

function Page:moveLine(args)
    if sArg(args,'-up') then
        local _,startY,endX,endY=self:getSelArea()
        if startY>1 then
            if startY~=endY and endX==0 then endY=endY-1 end
            ins(self,endY,rem(self,startY-1))
            self.curY=self.curY-1
            if self.selY then self.selY=self.selY-1 end
            self:freshScroll()
            self:saveCurX()
        end
    elseif sArg(args,'-down') then
        local _,startY,endX,endY=self:getSelArea()
        if endY<#self then
            if startY~=endY and endX==0 then endY=endY-1 end
            ins(self,startY,rem(self,endY+1))
            self.curY=self.curY+1
            if self.selY then self.selY=self.selY+1 end
            self:freshScroll()
            self:saveCurX()
        end
    end
end

function Page:duplicate()
    local _,startY,endX,endY=self:getSelArea()
    if startY~=endY and endX==0 then endY=endY-1 end

    if startY==endY then
        ins(self,startY+1,self[startY])
    else
        for i=startY,endY do ins(self,endY+1,self[i]) end
    end
end

-- Select
function Page:getSelArea()
    if self.selX then
        if self.curY>self.selY or (self.curY==self.selY and self.curX>self.selX) then
            return self.selX,self.selY,self.curX,self.curY
        else
            return self.curX,self.curY,self.selX,self.selY
        end
    else
        return self.curX,self.curY,self.curX,self.curY
    end
end

function Page:selectAll()
    self.selX,self.selY=0,1
    self.curX,self.curY=#self[#self],#self
end

function Page:cut()
    local lineAdded=false
    if not self.selX then
        if self.curY==#self then lineAdded=true; ins(self,'') end
        self.selX,self.selY=0,self.curY
        self.curX,self.curY=0,self.curY+1
    end
    self:copy()
    self:delete()
    if lineAdded then self:delete('-left') end
    self:freshScroll()
    SFX.play(tempInputBox.sound_clear)
end

function Page:copy()
    local strings={}
    local startX,startY,endX,endY=self:getSelArea()
    if startY==endY then
        strings[1]=self[startY]:sub(startX+1,endX)
    else
        strings[1]=self[startY]:sub(startX+1)
        for i=startY+1,endY-1 do strings[#strings+1]=self[i] end
        strings[#strings+1]=self[endY]:sub(1,endX)
    end
    love.system.setClipboardText(table.concat(strings,'\n'))
    freshClipboard()
end

function Page:paste(args,data)
    -- Delete selection first
    if self.selX then self:delete() end

    -- Get paste data
    local str
    if sArg(args,'-clipboard') then
        str=love.system.getClipboardText()
    elseif sArg(args,'-data') then
        str=data
    end
    if not str or str=='' then return end

    -- Remove \r
    str=str:gsub('\r',''):gsub('\t','    ')
    if str:sub(-1)=='\n' then str=str..'\n' end

    -- Split into lines and insert them
    str=STRING.split(str,'\n')
    for i=1,#str-1 do
        self:insStr(str[i])
        self:insLine('-auto -normal')
    end
    self:insStr(str[#str])
    self:freshScroll()
end

-- Render
local charRender={
    ['\0']=function(x,y,w,h)
        gc.setColor(COLOR.LD)
        gc.setLineWidth(1)
        gc.rectangle('line',x,y+3,w,h-6)
        gc.line(x+3,y+6,x+w-3,y+h-6)
        gc.line(x+3,y+h-6,x+w-3,y+6)
    end,
    ['\t']=function(x,y,w,h,t)
        gc.setColor(COLOR.DL)
        gc.setLineWidth(2)
        local dx=(t%.8*.3-.1)*w
        gc.translate(dx,0)
        gc.line(x+w*.2,y+h*.5,x+w*.8,y+h*.5)
        gc.line(x+w*.65,y+h*.6,x+w*.8, y+h*.5,x+w*.65,y+h*.4)
        gc.translate(-dx,0)
    end,
    ['\r']=function(x,y,w,h,t)
        gc.setColor(COLOR.DL)
        gc.setLineWidth(2)
        local dx=(abs(((t*6%2-1)^2)*.1)-.1)*w
        gc.translate(-dx,0)
        gc.line(x+w*.8,y+h*.7,x+w*.2,y+h*.7)
        gc.line(x+w*.35,y+h*.8,x+w*.2, y+h*.7,x+w*.35,y+h*.6)
        gc.translate(dx,0)
    end,
    ['\n']=function(x,y,w,h,t)
        gc.setColor(COLOR.DL)
        gc.setLineWidth(2)
        local dy=(abs(((t*6%2-1)^2)*.1)-.05)*w
        gc.translate(0,dy)
        gc.line(x+w*.2,y+h*.3,x+w*.2,y+h*.7)
        gc.line(x+w*.1,y+h*.6,x+w*.2,y+h*.7,x+w*.3,y+h*.6)
        gc.translate(0,-dy)
    end,
    [' ']=function(x,y,w,h,t)
        gc.setColor(COLOR.lD)
        gc.rectangle('fill',x+.28*w,y+.42*h+2.6*sin(t*4+(floor(x/w/4)*11-y/h)),.24*w,.16*h)
    end,
}
local colorData={}
local colorList={'LR','LF','LO','LY','LA','LK','LG','LJ','LC','LI','LS','LB','LP','LV','LM','LW'}
for k,v in next,colorList do colorList[k]=COLOR[v] end
local wordColor={
    _sign='DL',
    ['do']='lS',
    ['else']='lS',
    ['elseif']='lS',
    ['end']='lS',
    ['for']='lS',
    ['function']='lS',
    ['if']='lS',
    ['repeat']='lS',
    ['return']='lS',
    ['then']='lS',
    ['until']='lS',
    ['while']='lS',

    ['true']='lM',
    ['false']='lM',
    ['nil']='lM',
} for k,v in next,wordColor do wordColor[k]=COLOR[v] end
setmetatable(wordColor,{__index=function(_,k)
    local s=0
    for i=1,#k do
        s=s+byte(k,i)*(26+i)
    end
    return colorList[s%#colorList+1]
end})
function Page:draw(x,y)
    local _time=getTime()
    local _x,_y,_w
    local charW,lineH=self.charWidth,self.lineHeight
    local winW,winH=self.windowW,self.windowH
    local lineCount=ceil(winH/lineH)

    -- Basic position
    gc.translate(x,y)

    -- Stencil
    GC.stc_setPen('replace',1)
    GC.stc_rect(0,0,winW,winH)
    GC.stc_setComp('gequal',1)

    -- Move camera
    local camX,camY=self.scrollX*charW,self.scrollY*lineH
    gc.push('transform')
    gc.translate(-camX,-camY)

    if camX<100 then
        -- Seperate line
        gc.setLineWidth(2)
        gc.line(100,camY,100,camY+winH)

        -- Line numbers
        FONT.set(25,'_codePixel')
        gc.setColor(COLOR.LD)
        for i=self.scrollY+1,min(self.scrollY+lineCount,#self) do
            gc.printf(i,-5,lineH*(i-1)+6,100,'right')
        end
    end

    -- File data
    do
        local baseX,baseY=self.baseX,self.baseY
        local firstChar=1+floor(max(self.scrollX-100/charW,0))
        local lastChar=ceil((self.scrollX*charW+self.windowW-100)/charW)
        gc.setLineWidth(1)
        FONT.set(30,'_codePixel')
        local multiLineComment=false-- Attention: string value means the finishing pattern
        local multiLineString=false
        for cy=self.scrollY+1,min(self.scrollY+lineCount,#self) do
            local line=self[cy]

            TABLE.cut(colorData)
            local currentWord=''
            local parsePointer=1
            local parseState=false
            local commentMode=multiLineComment-- Attention: string value means the finishing pattern
            local stringMode=multiLineString-- Attention: string value means the finishing pattern

            -- Coloring
            for cx=1,#line+1 do
                local char=sub(line,cx,cx)
                local t=char~='' and STRING.type(char)

                if t==parseState then
                    currentWord=currentWord..char
                else
                    colorData[parsePointer]=cx
                    if parseState then
                        local stopString
                        -- Special case: Annoying strings/comments
                        if stringMode then
                            if find(currentWord,'[\"\']') and stringMode==match(currentWord,'[\"\']') then
                                stopString=true
                            end
                        elseif not commentMode and not stringMode then
                            if find(currentWord,'[\"\']') then
                                stringMode=match(currentWord,'[\"\']')
                            elseif sub(currentWord,1,2)=='--' then
                                commentMode=true
                            elseif match(currentWord,'%-%-%[=*%[') then
                                multiLineComment='%]'..(match(currentWord,'=+') or '')..'%]'
                                commentMode=true
                            elseif match(currentWord,'%[=*%[') then
                                multiLineString='%]'..(match(currentWord,'=+') or '')..'%]'
                                stringMode=true
                            end
                        end

                        -- Coloring prev word
                        colorData[parsePointer-1]=
                            commentMode and COLOR.dG or
                            stringMode and COLOR.dO or
                            parseState=='sign' and wordColor._sign or
                            wordColor[currentWord] or
                            wordColor._sign

                        -- Stop string
                        if stopString then
                            stringMode=false
                        end

                        -- Stop multiline string/comment
                        if multiLineComment and currentWord:match(multiLineComment) then
                            multiLineComment=false
                            commentMode=false
                        elseif multiLineString and currentWord:match(multiLineString) then
                            multiLineString=false
                            stringMode=false
                        end
                    end

                    parsePointer=parsePointer+2
                    parseState=t
                    currentWord=char
                end
            end

            -- Try to displaying
            local cx=1
            parsePointer=1
            while cx<=#line do
                local char=sub(line,cx,cx)
                local ifDisplay=cx+#char-1>=firstChar and cx<=lastChar

                -- Apply coloring
                if cx==colorData[parsePointer] then
                    gc.setColor(colorData[parsePointer+1])
                    parsePointer=parsePointer+2
                end

                if byte(char)<=127 then
                    if ifDisplay then
                        _x,_y=(cx-1)*charW+100,(cy-1)*lineH
                        _w=charRender[char]
                        if charRender[char] then
                            _w(_x,_y,charW,lineH,_time)
                        else
                            gc.printf(char,_x+baseX,_y+baseY,charW,'center')
                        end
                    end
                    cx=cx+1
                else
                    -- Calculate utf8 length
                    local utf8offset=1
                    local cb=byte(char)-128
                    while true do
                        cb=cb-2^(7-utf8offset)
                        if cb<0 then break end
                        utf8offset=utf8offset+1
                    end

                    -- Draw utf8 string block
                    if ifDisplay then
                        local utf8str=sub(line,cx,cx+utf8offset-1)
                        _x,_y=(cx-1)*charW+100,(cy-1)*lineH
                        _w=#utf8str*charW
                        gc.rectangle('line',_x+3,_y+2,_w-6,lineH-4)
                        if not GC.safePrintf(utf8str,_x+baseX,_y+baseY,_w,'center') then
                            gc.line(_x+3,_y+2,_x+_w-3,_y+lineH-2)-- Invalid utf8 mark
                        end
                    end

                    cx=cx+utf8offset
                end
            end
        end
    end

    -- Stencil selection
    if self.selX then
        GC.stc_setPen('replace',2)
        local startX,startY,endX,endY=self:getSelArea()
        if startY==endY then-- One line selected
            _x,_y=max(camX,100+charW*startX),lineH*(startY-1)
            _w=charW*(endX-startX)-max(camX-(100+charW*startX),0)
            if _y+lineH>camY and _y<camY+winH and _x+_w>camX and _x<camX+winW then
                GC.stc_rect(_x,_y,_w,lineH)
            end
        else-- Multiple lines selected
            -- Head
            _x,_y=max(camX,100+charW*startX),lineH*(startY-1)
            _w=winW-_x+camX
            if _y+lineH>camY and _y<camY+winH then
                GC.stc_rect(_x,_y,_w,lineH)
            end

            -- Middle
            _x=max(camX,100)
            _w=winW+min(camX-100,0)
            for l=startY+1,endY-1 do
                _y=lineH*(l-1)
                if _y+lineH>camY and _y<camY+winH then
                    GC.stc_rect(_x,_y,_w,lineH)
                end
            end

            -- Tail
            _x,_y=max(camX,100),lineH*(endY-1)
            _w=charW*endX-max(camX-100,0)
            if _y+lineH>camY and _y<camY+winH and _x+_w>camX then
                GC.stc_rect(_x,_y,_w,lineH)
            end
        end
        -- Prepare to draw selection color
        gc.pop()
        GC.stc_setComp('gequal',2)

        -- Rainbow layer
        gc.setBlendMode('multiply','premultiplied')
        rainbowShader:send('phase',_time*2.6%6.2832)
        gc.setShader(rainbowShader)
        gc.rectangle('fill',0,0,winW,winH)
        gc.setShader()

        -- Light layer
        gc.setBlendMode('add','premultiplied')
        gc.setColor(COLOR.lD)
        gc.rectangle('fill',0,0,winW,winH)

        -- Restore graphic states
        gc.setBlendMode('alpha')
        GC.stc_setComp('gequal',1)
        gc.push('transform')
        gc.translate(-camX,-camY)
    end

    -- Cursor
    gc.setLineWidth(4)
    local moveTime=_time-self.lastMoveTime
    local inputTime=_time-self.lastInputTime
    gc.setColor(.26,1,.26,(-min(inputTime,moveTime)%.4*4)^2.6)
    _x,_y=100+charW*self.curX,lineH*self.curY
    _w=(max(.26-inputTime,0)/.26)^2*26
    -- gc.line(_x,_y-lineH,_x,_y)-- Normal cursor style, if you dislike the 'Z' one
    gc.line(_x-4,_y-lineH-_w,_x+2,_y-lineH-_w,_x,_y+_w,_x+6,_y+_w)

    -- Select cursor
    if self.selX then
        gc.setColor(COLOR.B)
        _x,_y=100+charW*self.selX,lineH*self.selY
        gc.line(_x,_y-lineH,_x,_y)
    end

    -- Memory cursor
    if self.curX~=self.memX then
        gc.setColor(1,1,.26,.3)
        _x,_y=100+charW*self.memX,lineH*self.curY
        gc.line(_x,_y-lineH,_x,_y)
    end

    -- Highlight line
    if not self.selX then
        gc.setColor(1,1,1,.355)
        gc.setLineWidth(2)
        _x,_y=max(camX,100),lineH*self.curY
        _w=winW+min(camX-100,0)
        gc.line(_x,_y,_x+_w,_y)
        _y=_y-lineH
        gc.line(_x,_y,_x+_w,_y)
    end

    -- Cancel camera
    gc.pop()

    -- Stop stencil
    GC.stc_stop()

    gc.setColor(COLOR.L)

    -- Frame
    gc.setLineWidth(2)
    gc.rectangle('line',0,0,winW,winH)

    -- Scrollbar
    if #self>=lineCount then
        gc.rectangle('fill',winW,self.scrollY/(#self-1)*(winH-lineCount/#self*winH),-20,lineCount/#self*winH)
    end

    -- Draw fileinfo
    FONT.set(15,'_codePixel')
    GC.safePrint(self.fileInfo,0,-18)
end

-------------------------------------------------------------

local globalFuncs={}

function globalFuncs.switchFile(args)
    if sArg(args,'-next') then
        curPage=curPage%#activePages+1
    elseif sArg(args,'-prev') then
        curPage=(curPage-2)%#activePages+1
    end
    freshPageInfo()
end

function globalFuncs.closeFile()
    if not curPage then return end
    rem(activePages,curPage)
    if not activePages[curPage] then
        curPage=curPage>1 and curPage-1
    end
    freshPageInfo()
end

function globalFuncs.newFile(args)
    ins(activePages,Page.new(args))
    curPage=#activePages
    freshPageInfo()
end

-------------------------------------------------------------

local Menu={}
Menu.__index=Menu
function Menu.new(M)
    M.label=gc.newText(FONT.get(40),M.name)
    M.pressLight=0
    if not M.color then M.color=COLOR.L end
    if not M.r then M.r=60 end
    M.x=M.x*UIscale
    M.y=M.y*UIscale
    M.r=M.r*UIscale
    if M.list then
        M.expand=false
        M.expandState=0
    end
    return setmetatable(M,Menu)
end
function Menu:update(dt)
    if self.pressLight>0 then
        self.pressLight=max(self.pressLight-5*dt,0)
    end
    if self.list then
        if self.expand then
            for j=1,#self.list do
                self.list[j]:update(dt)
            end
            if self.expandState<1 then
                self.expandState=min(self.expandState+6.26*dt,1)
            end
        else
            if self.expandState>0 then
                self.expandState=max(self.expandState-6.26*dt,0)
            end
        end
    end
end
function Menu:draw()
    if self.xOy then gc.replaceTransform(self.xOy) end
    gc.translate(self.x,self.y)

    local lw=3+(self.expandState and self.expandState*17 or 0)
    gc.setLineWidth(lw)

    gc.setColor(1,1,1,.5+self.pressLight*.3)
    gc.circle('fill',0,0,self.r-lw)

    FONT.get(40)
    local k=min(1,1.2*self.r/self.label:getWidth())
    gc.setColor(COLOR.D)
    GC.outDraw(self.label,0,0,nil,k,1,8)
    gc.setColor(self.color)
    GC.draw(self.label,nil,nil,nil,k)
    gc.circle('line',0,0,self.r-lw/2)

    if self.list and self.expandState>0 then
        gc.scale(1-(1-self.expandState)^2.6)
        for j=1,#self.list do
            self.list[j]:draw()
        end
    end

    gc.translate(-self.x,-self.y)
end
function Menu:press(x,y)
    if self.xOy then
        x,y=self.xOy:inverseTransformPoint(x,y)
    end
    if (x-self.x)^2+(y-self.y)^2<=self.r^2 then
        if self.list then
            self:switch()
        elseif self.func then
            if type(self.func)=='string' then
                scene.keyDown(self.func)
            elseif type(self.func)=='function' then
                self.func(self.args)
            end
            self.pressLight=1
        end
        return true
    else
        if self.list and self.expand then
            for i=1,#self.list do
                if self.list[i]:press(x-self.x,y-self.y) then return true end
            end
        end
    end
end
function Menu:switch()
    if self.list then
        self.expand=not self.expand
    end
end
function Menu:expand()
    if self.list then
        self.expand=true
    end
end
function Menu:fold()
    if self.list then
        self.expand=false
    end
end

local function ZKB(key)
    scene.keyDown(key)
end

local touchMenu; touchMenu={
    Menu.new{
        name='File',
        xOy=SCR.xOy_ul,
        color=COLOR.lY,
        x=50,y=200,r=100,
        list={
            Menu.new{name='Close',  x=160,y=40,color=COLOR.lY,func='ctrl+w'},
            Menu.new{name='New',    x=280,y=40,color=COLOR.lY,func='ctrl+n'},
            Menu.new{name='Save',   x=400,y=40,color=COLOR.lY,func='ctrl+s'},
            Menu.new{name='<-',     x=160,y=160,color=COLOR.lY,func='ctrl+shift+tab'},
            Menu.new{name='->',     x=280,y=160,color=COLOR.lY,func='ctrl+tab'},
        },
    },
    Menu.new{
        name='Select',
        xOy=SCR.xOy_dl,
        color=COLOR.LP,
        x=50,y=-400,r=100,
        list={
            Menu.new{name='PgUp', x=160,y=-60,color=COLOR.LP,func='pageup'},
            Menu.new{name='PgDn', x=160,y=60, color=COLOR.LP,func='pagedown'},
            Menu.new{name='MvUp', x=280,y=-60,color=COLOR.LP,func='alt+up'},
            Menu.new{name='MvDn', x=280,y=60, color=COLOR.LP,func='alt+down'},
            Menu.new{name='All',    x=400,y=-60,color=COLOR.LP,func='ctrl+a'},
        },
    },
    Menu.new{
        name='Edit',
        xOy=SCR.xOy_dl,
        color=COLOR.LS,
        x=50,y=-50,r=100,
        list={
            Menu.new{name='Duplicate',  x=160,y=-160,color=COLOR.LS,func='ctrl+d'},
            Menu.new{name='Undo',       x=160,y=-40, color=COLOR.LS,func='ctrl+z'},
            Menu.new{name='Cut',        x=280,y=-40, color=COLOR.LS,func='ctrl+x'},
            Menu.new{name='Copy',       x=400,y=-40, color=COLOR.LS,func='ctrl+c'},
            Menu.new{name='Paste',      x=520,y=-40, color=COLOR.LS,func='ctrl+v'},
        },
    },
    Menu.new{
        name='Keyboard',
        xOy=SCR.xOy_dr,
        color=COLOR.lR,
        x=-50,y=-50,r=100,
        list={
            Menu.new{name='`',x=-1390,y=-465,r=45,color=COLOR.dL,func=ZKB,args='`'},
            Menu.new{name='!',x=-1295,y=-465,r=45,color=COLOR.dL,func=ZKB,args='!'},
            Menu.new{name='@',x=-1185,y=-465,r=45,color=COLOR.dL,func=ZKB,args='@'},
            Menu.new{name='#',x=-1075,y=-465,r=45,color=COLOR.dL,func=ZKB,args='#'},
            Menu.new{name='$',x=-965, y=-465,r=45,color=COLOR.dL,func=ZKB,args='$'},
            Menu.new{name='%',x=-855, y=-465,r=45,color=COLOR.dL,func=ZKB,args='%'},
            Menu.new{name='^',x=-745, y=-465,r=45,color=COLOR.dL,func=ZKB,args='^'},
            Menu.new{name='&',x=-635, y=-465,r=45,color=COLOR.dL,func=ZKB,args='&'},
            Menu.new{name='*',x=-525, y=-465,r=45,color=COLOR.dL,func=ZKB,args='*'},
            Menu.new{name='(',x=-415, y=-465,r=45,color=COLOR.dL,func=ZKB,args='('},
            Menu.new{name=')',x=-305, y=-465,r=45,color=COLOR.dL,func=ZKB,args=')'},
            Menu.new{name='_',x=-195, y=-465,r=45,color=COLOR.dL,func=ZKB,args='_'},
            Menu.new{name='+',x=-85,  y=-465,r=45,color=COLOR.dL,func=ZKB,args='+'},

            Menu.new{name='1',x=-1340,y=-380,r=55,color=COLOR.LO,func=ZKB,args='1'},
            Menu.new{name='2',x=-1230,y=-380,r=55,color=COLOR.LO,func=ZKB,args='2'},
            Menu.new{name='3',x=-1120,y=-380,r=55,color=COLOR.LO,func=ZKB,args='3'},
            Menu.new{name='4',x=-1010,y=-380,r=55,color=COLOR.LO,func=ZKB,args='4'},
            Menu.new{name='5',x=-900, y=-380,r=55,color=COLOR.LO,func=ZKB,args='5'},
            Menu.new{name='6',x=-790, y=-380,r=55,color=COLOR.LO,func=ZKB,args='6'},
            Menu.new{name='7',x=-680, y=-380,r=55,color=COLOR.LO,func=ZKB,args='7'},
            Menu.new{name='8',x=-570, y=-380,r=55,color=COLOR.LO,func=ZKB,args='8'},
            Menu.new{name='9',x=-460, y=-380,r=55,color=COLOR.LO,func=ZKB,args='9'},
            Menu.new{name='0',x=-350, y=-380,r=55,color=COLOR.LO,func=ZKB,args='0'},
            Menu.new{name='-',x=-240, y=-380,r=55,color=COLOR.dL,func=ZKB,args='-'},
            Menu.new{name='=',x=-130, y=-380,r=55,color=COLOR.dL,func=ZKB,args='='},
            Menu.new{name='<-',x=-20, y=-380,r=55,color=COLOR.dL,func=ZKB,args='backspace'},

            Menu.new{name='q',x=-1330,y=-270,r=55,color=COLOR.LG,func=ZKB,args='q'},
            Menu.new{name='w',x=-1220,y=-270,r=55,color=COLOR.LG,func=ZKB,args='w'},
            Menu.new{name='e',x=-1110,y=-270,r=55,color=COLOR.LG,func=ZKB,args='e'},
            Menu.new{name='r',x=-1000,y=-270,r=55,color=COLOR.LG,func=ZKB,args='r'},
            Menu.new{name='t',x=-890, y=-270,r=55,color=COLOR.LG,func=ZKB,args='t'},
            Menu.new{name='y',x=-780, y=-270,r=55,color=COLOR.LG,func=ZKB,args='y'},
            Menu.new{name='u',x=-670, y=-270,r=55,color=COLOR.LG,func=ZKB,args='u'},
            Menu.new{name='i',x=-560, y=-270,r=55,color=COLOR.LG,func=ZKB,args='i'},
            Menu.new{name='o',x=-450, y=-270,r=55,color=COLOR.LG,func=ZKB,args='o'},
            Menu.new{name='p',x=-340, y=-270,r=55,color=COLOR.LG,func=ZKB,args='p'},
            Menu.new{name='[',x=-230, y=-270,r=55,color=COLOR.dL,func=ZKB,args='['},
            Menu.new{name=']',x=-120, y=-270,r=55,color=COLOR.dL,func=ZKB,args=']'},
            Menu.new{name='\\',x=-10, y=-270,r=55,color=COLOR.dL,func=ZKB,args='\\'},

            Menu.new{name='a',x=-1290,y=-165,r=55,color=COLOR.LG,func=ZKB,args='a'},
            Menu.new{name='s',x=-1180,y=-165,r=55,color=COLOR.LG,func=ZKB,args='s'},
            Menu.new{name='d',x=-1070,y=-165,r=55,color=COLOR.LG,func=ZKB,args='d'},
            Menu.new{name='f',x=-960, y=-165,r=55,color=COLOR.LG,func=ZKB,args='f'},
            Menu.new{name='g',x=-850, y=-165,r=55,color=COLOR.LG,func=ZKB,args='g'},
            Menu.new{name='h',x=-740, y=-165,r=55,color=COLOR.LG,func=ZKB,args='h'},
            Menu.new{name='j',x=-630, y=-165,r=55,color=COLOR.LG,func=ZKB,args='j'},
            Menu.new{name='k',x=-520, y=-165,r=55,color=COLOR.LG,func=ZKB,args='k'},
            Menu.new{name='l',x=-410, y=-165,r=55,color=COLOR.LG,func=ZKB,args='l'},
            Menu.new{name=';',x=-300, y=-165,r=55,color=COLOR.dL,func=ZKB,args=';'},
            Menu.new{name="'",x=-190, y=-165,r=55,color=COLOR.dL,func=ZKB,args="'"},
            Menu.new{name='"',x=-80,  y=-165,r=55,color=COLOR.dL,func=ZKB,args='"'},

            Menu.new{name='z',x=-1250,y=-60, r=55,color=COLOR.LG,func=ZKB,args='z'},
            Menu.new{name='x',x=-1140,y=-60, r=55,color=COLOR.LG,func=ZKB,args='x'},
            Menu.new{name='c',x=-1030,y=-60, r=55,color=COLOR.LG,func=ZKB,args='c'},
            Menu.new{name='v',x=-920, y=-60, r=55,color=COLOR.LG,func=ZKB,args='v'},
            Menu.new{name='b',x=-810, y=-60, r=55,color=COLOR.LG,func=ZKB,args='b'},
            Menu.new{name='n',x=-700, y=-60, r=55,color=COLOR.LG,func=ZKB,args='n'},
            Menu.new{name='m',x=-590, y=-60, r=55,color=COLOR.LG,func=ZKB,args='m'},
            Menu.new{name=',',x=-480, y=-60, r=55,color=COLOR.dL,func=ZKB,args=','},
            Menu.new{name='.',x=-370, y=-60, r=55,color=COLOR.dL,func=ZKB,args='.'},
            Menu.new{name='/',x=-260, y=-60, r=55,color=COLOR.dL,func=ZKB,args='/'},
            Menu.new{name='|',x=-150, y=-60, r=55,color=COLOR.dL,func=ZKB,args='|'},

            Menu.new{name='CAP',x=-1410,y=-180,r=65,color=COLOR.dR,func=function() touchMenu.Keyboard.list,touchMenu.Keyboard.list2=touchMenu.Keyboard.list2,touchMenu.Keyboard.list end},
        },
        list2={
            Menu.new{name='~',x=-1390,y=-465,r=45,color=COLOR.lR,func=ZKB,args='~'},
            Menu.new{name='!',x=-1295,y=-465,r=45,color=COLOR.dL,func=ZKB,args='!'},
            Menu.new{name='@',x=-1185,y=-465,r=45,color=COLOR.dL,func=ZKB,args='@'},
            Menu.new{name='#',x=-1075,y=-465,r=45,color=COLOR.dL,func=ZKB,args='#'},
            Menu.new{name='$',x=-965, y=-465,r=45,color=COLOR.dL,func=ZKB,args='$'},
            Menu.new{name='%',x=-855, y=-465,r=45,color=COLOR.dL,func=ZKB,args='%'},
            Menu.new{name='^',x=-745, y=-465,r=45,color=COLOR.dL,func=ZKB,args='^'},
            Menu.new{name='&',x=-635, y=-465,r=45,color=COLOR.dL,func=ZKB,args='&'},
            Menu.new{name='*',x=-525, y=-465,r=45,color=COLOR.dL,func=ZKB,args='*'},
            Menu.new{name='(',x=-415, y=-465,r=45,color=COLOR.dL,func=ZKB,args='('},
            Menu.new{name=')',x=-305, y=-465,r=45,color=COLOR.dL,func=ZKB,args=')'},
            Menu.new{name='_',x=-195, y=-465,r=45,color=COLOR.dL,func=ZKB,args='_'},
            Menu.new{name='+',x=-85,  y=-465,r=45,color=COLOR.dL,func=ZKB,args='+'},

            Menu.new{name='1',x=-1340,y=-380,r=55,color=COLOR.LO,func=ZKB,args='1'},
            Menu.new{name='2',x=-1230,y=-380,r=55,color=COLOR.LO,func=ZKB,args='2'},
            Menu.new{name='3',x=-1120,y=-380,r=55,color=COLOR.LO,func=ZKB,args='3'},
            Menu.new{name='4',x=-1010,y=-380,r=55,color=COLOR.LO,func=ZKB,args='4'},
            Menu.new{name='5',x=-900, y=-380,r=55,color=COLOR.LO,func=ZKB,args='5'},
            Menu.new{name='6',x=-790, y=-380,r=55,color=COLOR.LO,func=ZKB,args='6'},
            Menu.new{name='7',x=-680, y=-380,r=55,color=COLOR.LO,func=ZKB,args='7'},
            Menu.new{name='8',x=-570, y=-380,r=55,color=COLOR.LO,func=ZKB,args='8'},
            Menu.new{name='9',x=-460, y=-380,r=55,color=COLOR.LO,func=ZKB,args='9'},
            Menu.new{name='0',x=-350, y=-380,r=55,color=COLOR.LO,func=ZKB,args='0'},
            Menu.new{name='-',x=-240, y=-380,r=55,color=COLOR.dL,func=ZKB,args='-'},
            Menu.new{name='=',x=-130, y=-380,r=55,color=COLOR.dL,func=ZKB,args='='},
            Menu.new{name='<-',x=-20, y=-380,r=55,color=COLOR.dL,func=ZKB,args='backspace'},

            Menu.new{name='Q',x=-1330,y=-270,r=55,color=COLOR.lO,func=ZKB,args='Q'},
            Menu.new{name='W',x=-1220,y=-270,r=55,color=COLOR.lO,func=ZKB,args='W'},
            Menu.new{name='E',x=-1110,y=-270,r=55,color=COLOR.lO,func=ZKB,args='E'},
            Menu.new{name='R',x=-1000,y=-270,r=55,color=COLOR.lO,func=ZKB,args='R'},
            Menu.new{name='T',x=-890, y=-270,r=55,color=COLOR.lO,func=ZKB,args='T'},
            Menu.new{name='Y',x=-780, y=-270,r=55,color=COLOR.lO,func=ZKB,args='Y'},
            Menu.new{name='U',x=-670, y=-270,r=55,color=COLOR.lO,func=ZKB,args='U'},
            Menu.new{name='I',x=-560, y=-270,r=55,color=COLOR.lO,func=ZKB,args='I'},
            Menu.new{name='O',x=-450, y=-270,r=55,color=COLOR.lO,func=ZKB,args='O'},
            Menu.new{name='P',x=-340, y=-270,r=55,color=COLOR.lO,func=ZKB,args='P'},
            Menu.new{name='{',x=-230, y=-270,r=55,color=COLOR.lR,func=ZKB,args='{'},
            Menu.new{name='}',x=-120, y=-270,r=55,color=COLOR.lR,func=ZKB,args='}'},
            Menu.new{name='\\',x=-10, y=-270,r=55,color=COLOR.dL,func=ZKB,args='\\'},

            Menu.new{name='A',x=-1290,y=-165,r=55,color=COLOR.lO,func=ZKB,args='A'},
            Menu.new{name='S',x=-1180,y=-165,r=55,color=COLOR.lO,func=ZKB,args='S'},
            Menu.new{name='D',x=-1070,y=-165,r=55,color=COLOR.lO,func=ZKB,args='D'},
            Menu.new{name='F',x=-960, y=-165,r=55,color=COLOR.lO,func=ZKB,args='F'},
            Menu.new{name='G',x=-850, y=-165,r=55,color=COLOR.lO,func=ZKB,args='G'},
            Menu.new{name='H',x=-740, y=-165,r=55,color=COLOR.lO,func=ZKB,args='H'},
            Menu.new{name='J',x=-630, y=-165,r=55,color=COLOR.lO,func=ZKB,args='J'},
            Menu.new{name='K',x=-520, y=-165,r=55,color=COLOR.lO,func=ZKB,args='K'},
            Menu.new{name='L',x=-410, y=-165,r=55,color=COLOR.lO,func=ZKB,args='L'},
            Menu.new{name=':',x=-300, y=-165,r=55,color=COLOR.lR,func=ZKB,args=':'},
            Menu.new{name="'",x=-190, y=-165,r=55,color=COLOR.dL,func=ZKB,args="'"},
            Menu.new{name='"',x=-80,  y=-165,r=55,color=COLOR.dL,func=ZKB,args='"'},

            Menu.new{name='Z',x=-1250,y=-60, r=55,color=COLOR.lO,func=ZKB,args='Z'},
            Menu.new{name='X',x=-1140,y=-60, r=55,color=COLOR.lO,func=ZKB,args='X'},
            Menu.new{name='C',x=-1030,y=-60, r=55,color=COLOR.lO,func=ZKB,args='C'},
            Menu.new{name='V',x=-920, y=-60, r=55,color=COLOR.lO,func=ZKB,args='V'},
            Menu.new{name='B',x=-810, y=-60, r=55,color=COLOR.lO,func=ZKB,args='B'},
            Menu.new{name='N',x=-700, y=-60, r=55,color=COLOR.lO,func=ZKB,args='N'},
            Menu.new{name='M',x=-590, y=-60, r=55,color=COLOR.lO,func=ZKB,args='M'},
            Menu.new{name='<',x=-480, y=-60, r=55,color=COLOR.lR,func=ZKB,args='<'},
            Menu.new{name='>',x=-370, y=-60, r=55,color=COLOR.lR,func=ZKB,args='>'},
            Menu.new{name='?',x=-260, y=-60, r=55,color=COLOR.lR,func=ZKB,args='?'},
            Menu.new{name='|',x=-150, y=-60, r=55,color=COLOR.dL,func=ZKB,args='|'},

            Menu.new{name='CAP',x=-1410,y=-180,r=65,color=COLOR.lR,func=function() touchMenu.Keyboard.list,touchMenu.Keyboard.list2=touchMenu.Keyboard.list2,touchMenu.Keyboard.list end},
        },
    },
}
local touchMenuMeta={__index=function(self,k)
    for i=1,#self do
        if self[i].name==k then
            return self[i]
        end
    end
end}
do
    local function f(m)
        setmetatable(m,touchMenuMeta)
        for i=1,#m do if m[i].list then f(m[i].list) end end
    end
    f(touchMenu)
end

local directPad={
    xOy=SCR.xOy_ur,
    x=-220*UIscale,y=260*UIscale,
    r=160*UIscale,r2=160*.3*UIscale,
    barDist=0,barAngle=0,
    touchID=nil,

    moveX=0,moveY=0,
}
function directPad:press(x,y,id)
    self.touchID=id
    self:move(x,y)
    self:update(1e-26)
end
function directPad:move(x,y)
    self.barDist=min(MATH.distance(x,y,self.x,self.y),self.r)
    self.barAngle=atan2(y-self.y,x-self.x)
end
function directPad:release()
    self.touchID=nil
    self.barDist=0
    self.barAngle=0
    self.moveX,self.moveY=0,0
end
function directPad:getDirection()
    if self.barDist>=self.r2 then
        local a=self.barAngle%6.283185307179586/6.283185307179586
        return
            a<1/8 and 'right' or
            a<3/8 and 'down' or
            a<5/8 and 'left' or
            a<7/8 and 'up' or
            'right'
    end
end
function directPad:update(dt)
    if self.touchID and self.barDist>=self.r2 then
        local dx,dy=self.barDist/self.r*cos(self.barAngle),self.barDist/self.r*sin(self.barAngle)

        local a=self:getDirection()
        if a=='right' then    dy=0
        elseif a=='down' then dx=0
        elseif a=='left' then dy=0
        elseif a=='up' then   dx=0
        end

        if dx~=0 then
            dx=dx*dt*6.26
            if dx>0 then
                if self.moveX<=0 then
                    self.moveX=0
                    scene.keyDown('right')
                end
            else
                if self.moveX>=0 then
                    self.moveX=0
                    scene.keyDown('left')
                end
            end
            self.moveX=self.moveX+dx
            if abs(self.moveX)>1 then
                scene.keyDown(self.moveX>0 and 'right' or 'left')
                self.moveX=self.moveX*.8
            end
        end

        if dy~=0 then
            dy=dy*dt*6.26
            if dy>0 then
                if self.moveY<=0 then
                    self.moveY=0
                    scene.keyDown('down')
                end
            else
                if self.moveY>=0 then
                    self.moveY=0
                    scene.keyDown('up')
                end
            end
            self.moveY=self.moveY+dy
            if abs(self.moveY)>1 then
                scene.keyDown(self.moveY>0 and 'down' or 'up')
                self.moveY=self.moveY*.8
            end
        end
    end
end
function directPad:draw()
    gc.push('transform')
    gc.replaceTransform(self.xOy)
    gc.translate(self.x,self.y)

    gc.setColor(.3,.626,.4,.5)
    if self.barDist>=self.r2 then
        GC.stc_reset()
        GC.stc_setComp('notequal',1)
        GC.stc_setPen('replace',1)
        GC.stc_circ(0,0,self.r2)

        local a=self:getDirection()
        if a=='right' then    a=6.2832*0/4
        elseif a=='down' then a=6.2832*1/4
        elseif a=='left' then a=6.2832*2/4
        elseif a=='up' then   a=6.2832*3/4
        end
        gc.setLineWidth(self.r)
        gc.arc('fill','pie',0,0,self.r,a-.7854,a+.7854)
        GC.stc_stop()
    end

    gc.setLineWidth(6)

    local rootR1=self.r/2^.5-3
    local rootR2=self.r2/2^.5+3
    gc.setColor(.2,.626,.26,.5)
    gc.line(-rootR1,-rootR1,-rootR2,-rootR2)
    gc.line(-rootR1,rootR1,-rootR2,rootR2)
    gc.line(rootR1,-rootR1,rootR2,-rootR2)
    gc.line(rootR1,rootR1,rootR2,rootR2)

    gc.circle('line',0,0,self.r2)
    gc.setColor(.3,1,.4,self.barDist>self.r2 and .9 or .3)
    gc.circle('line',0,0,self.r)
    gc.setColor(.8,1,.9,.6)
    gc.circle('fill',self.barDist*cos(self.barAngle),self.barDist*sin(self.barAngle),self.r2)
    gc.pop()
end

-------------------------------------------------------------

function scene.enter()
    BG.set('none')
    touchMode=false
    clipboardFreshCD=0
    escapeHoldTime=0
    freshClipboard()

    if type(rainbowShader)=='string' then rainbowShader=gc.newShader(rainbowShader) end
    if type(comboKeyName[1].name)=='string' then
        for i=1,#comboKeyName do
            comboKeyName[i].label=gc.newText(FONT.get(15,'_codePixel'),comboKeyName[i].text)
        end
    end
    if #activePages==0 then globalFuncs.newFile('-welcome') end
end

function scene.keyDown(key,isRep)
    -- Do nothing when press combokey itself
    if unimportantKeys[key] then return end

    -- Translate keys
    if keyAlias[key] then key=keyAlias[key] end

    -- Generate combo
    local combo=key
    for i=#comboKeyName,1,-1 do
        if kb.isDown(unpack(comboKeyName[i].keys)) then
            combo=comboKeyName[i].name..'+'..combo
        end
    end

    -- Translate combo (for macOS)
    if alteredComboMap and alteredComboMap[combo] then combo=alteredComboMap[combo] end

    -- Execute
    local P=activePages[curPage]
    if pageComboMap[combo] then
        if P then
            P[pageComboMap[combo].func](P,pageComboMap[combo].args)
        end
    elseif globalComboMap[combo] then
        globalFuncs[globalComboMap[combo].func](globalComboMap[combo].args)
    elseif #key==1 then
        if P then
            if combo=='shift+'..key then
                P.lastInputTime=getTime()
                P:insStr(STRING.shiftChar(key))
            elseif combo==key then
                P.lastInputTime=getTime()
                P:insStr(key)
            else
                MES.new('info',"Unknown combo: "..combo,1.26)
            end
        end
    elseif key=='escape' then
        if P and P.selX then
            P.selX,P.selY=false,false
        elseif touchMode then
            touchMode=false
        elseif not isRep then
            MES.new('info',"Hold esc to quit",.26)
        end
    else
        MES.new('info',"Unknown operation: "..combo,1.26)
    end
end
function scene.mouseDown(x,y,k)
    if k==1 then
        if not curPage then return end
        local P=activePages[curPage]

        -- Outside mouse posion
        local mx,my=x-50,y-50
        if not (mx>0 and mx<P.windowW and my>0 and my<P.windowH) then return end

        -- Inside position
        mx,my=mx-100+P.scrollX*P.charWidth,my+P.scrollY*P.lineHeight
        if mx<0 then-- Select line
            local ty=floor(my/P.lineHeight)+1

            if not (ifSelecting() and P.selX) then
                P.selX,P.selY=0,min(ty,#P)
            end
            P.curX,P.curY=0,ty+1
            P:moveCursor('-mouse')
        else-- Select char
            if ifSelecting() then
                if not P.selX then P.selX,P.selY=P.curX,P.curY end
                P.curX,P.curY=floor(mx/P.charWidth+.5),floor(my/P.lineHeight)+1
                P:moveCursor('-mouse -hold')
            else
                P.selX,P.selY=false,false
                P.curX,P.curY=floor(mx/P.charWidth+.5),floor(my/P.lineHeight)+1
                P:moveCursor('-mouse')
            end
        end
        P:saveCurX()
    elseif k==2 then
        scene.touchDown(x,y,'m2')
    end
end
function scene.mouseMove(x,y,dx,dy)
    if not curPage then return end
    local P=activePages[curPage]
    if ms.isDown(1) then
        if not P.selX then P.selX,P.selY=P.curX,P.curY end
        local mx,my=x-50,y-50
        mx,my=mx-100+P.scrollX*P.charWidth,my+P.scrollY*P.lineHeight
        P.curX,P.curY=floor(mx/P.charWidth+.5),floor(my/P.lineHeight)+1
        P:moveCursor('-mouse')
        P:saveCurX()
    elseif ms.isDown(2) then
        scene.touchMove(x,y,dx,dy,'m2')
    end
end
function scene.mouseUp(x,y,k)
    if k==1 then
        -- Nothing, maybe
    elseif k==2 then
        scene.touchUp(x,y,'m2')
    end
end

function scene.touchDown(x,y,id)
    if not touchMode then touchMode=true return end

    local _x,_y=SCR.xOy:transformPoint(x,y)
    for i=1,#touchMenu do
        local M=touchMenu[i]
        if M:press(_x,_y) then return end
    end

    _x,_y=directPad.xOy:inverseTransformPoint(_x,_y)
    if (_x-directPad.x)^2+(_y-directPad.y)^2<=directPad.r^2 then
        directPad:press(_x,_y,id)
        return
    end

    ins(touches,{x=x,y=y,id=id,keep=true,time=getTime()})
end
function scene.touchUp(x,y,id)
    if directPad.touchID==id then
        directPad:release()
    else
        for i=1,#touches do
            if touches[i].id==id then
                local T=rem(touches,i)
                if T.keep and getTime()-T.time<.26 then
                    scene.mouseDown(x,y,1)
                end
                return
            end
        end
    end
end
function scene.touchMove(x,y,dx,dy,id)
    if directPad.touchID==id then
        directPad:move(directPad.xOy:inverseTransformPoint(SCR.xOy:transformPoint(x,y)))
    else
        for i=1,#touches do
            local T=touches[i]
            if T.keep and T.id==id then
                if (T.x-x)^2+(T.y-y)^2>=62 then
                    T.keep=false
                end
                break
            end
        end
        WHEELMOV(dy/50,'ctrl+up','ctrl+down')
    end
end

function scene.wheelMoved(dx,dy)
    local P=activePages[curPage]
    if not P then return end
    while dy>0 do dy=dy-1; P:scrollV('-up') end
    while dy<0 do dy=dy+1; P:scrollV('-down') end
    while dx>0 do dx=dx-1; P:scrollH('-left') end
    while dx<0 do dx=dx+1; P:scrollH('-right') end
end
function scene.fileDropped(file)
    globalFuncs.newFile()
    activePages[curPage]:loadFile('-drop',file)
end

function scene.update(dt)
    if touchMode then
        for i=1,#touchMenu do
            touchMenu[i]:update(dt)
        end
        directPad:update(dt)
    end

    clipboardFreshCD=clipboardFreshCD+dt
    if clipboardFreshCD>=1 then
        clipboardFreshCD=0
        freshClipboard()
    end
    if kb.isDown('escape') then
        escapeHoldTime=escapeHoldTime+dt
        if escapeHoldTime>2 then
            escapeHoldTime=-1e99
            SCN.back()
        end
    else
        escapeHoldTime=0
    end
end

function scene.draw()
    gc.clear(.08,.05,.02)
    if curPage then
        FONT.set(20,'_codePixel')
        gc.print(pageInfo,162,5)
        activePages[curPage]:draw(50,50)
        gc.replaceTransform(SCR.xOy_ul)
        if clipboardText then
            gc.replaceTransform(SCR.xOy_ur)
            FONT.set(20,'_codePixel')
            gc.setColor(COLOR.LD)
            GC.safePrintf(clipboardText,-2605,5,2600,'right')
        end
        gc.replaceTransform(SCR.xOy_dl)
        local x=50
        FONT.set(15,'_codePixel')
        for i=1,#comboKeyName do
            if kb.isDown(unpack(comboKeyName[i].keys)) then
                gc.setColor(comboKeyName[i].color)
                gc.draw(comboKeyName[i].label,x,-45)
                x=x+comboKeyName[i].label:getWidth()+10
            end
        end
    else
        FONT.set(35,'_codePixel')
        GC.mStr(help.newFile,SCR.w0/2,SCR.h0/2-26)
    end

    if touchMode then
        for i=1,#touchMenu do
            touchMenu[i]:draw()
        end
        directPad:draw()
    end
end

return scene
