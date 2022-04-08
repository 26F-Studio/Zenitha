local gc=love.graphics
local ms,kb=love.mouse,love.keyboard
local ins,rem=table.insert,table.remove
local max,min=math.max,math.min
local int,ceil=math.floor,math.ceil

local sArg=STRING.sArg

local activePages={}
local curPage=false
local pageInfo={COLOR.L,"Page: ",COLOR.LR,false,COLOR.LD,"/",COLOR.lI,false}
local clipboardFreshCD
local escapeHoldTime

local tempInputBox=WIDGET.new{type='inputBox'}
local clipboardText=""

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
    if clipboardText=="" then
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
        charWidth=23,lineHeight=35,
        baseX=1,
        baseY=4,
        fileName="*Untitled",
        filePath=false,
        fileInfo={COLOR.L,"*Untitled"},
    },Page)
    if sArg(args,'-welcome') then
        TABLE.connect(P,{
            "-- Welcome to Zenitha editor --",
            "",
            "Type freely on any devices.",
            "",
        })
        P:moveCursor('-auto -end -jump')
    else
        P[1]=""
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
end

function Page:redo()
    -- TODO
end

function Page:save()
    if self.filePath then
        -- TODO
    end
end

-- Control
function Page:scrollV(args)
    local dy=sArg(args,'-up') and -1 or sArg(args,'-down') and 1
    if not dy then return end
    if sArg(args,'-jump') then dy=max(1,int(self.windowH/self.lineHeight))*dy end
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
            local l=jump and max(1,int(self.windowH/self.lineHeight)) or 1
            if self.curY>l then
                self.curY=self.curY-l
            else
                self.curY=1
                self.curX=0
            end
            self.curX=min(self.memX,#self[self.curY])
        elseif sArg(args,'-down') then
            local l=jump and max(1,int(self.windowH/self.lineHeight)) or 1
            if self.curY<=#self-l then
                self.curY=self.curY+l
            else
                self.curY=#self
                self.curX=#self[self.curY]
            end
            self.curX=min(self.memX,#self[self.curY])
        end
        if not sArg(args,'-auto') then
            if not hold or self.selX==self.curX and self.selY==self.curY then
                self.selX,self.selY=false,false
            end
            self:freshScroll()
        end
    end
end

function Page:saveCurX()
    self.memX=self.curX
end

function Page:freshScroll()
    self.scrollX=MATH.interval(self.scrollX,ceil(self.curX-(self.windowW-100)/self.charWidth),self.curX)
    self.scrollY=MATH.interval(self.scrollY,ceil(self.curY-self.windowH/self.lineHeight),self.curY-1)
end

-- Edit
function Page:insStr(str)
    if str=="" or not str then return end
    if self.selX then self:delete('-normal') end
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
    if sArg(args,'-all') then
        TABLE.cut(self)
        self[1]=""
        self.scrollX,self.scrollY=0,0
        self.curX,self.curY=0,1
        self.memX=0
        self.selX,self.selY=false,false
        result=true
        SFX.play(tempInputBox.sound_clear)
    elseif self.selX then
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
        SFX.play(tempInputBox.sound_del)
    elseif sArg(args,'-word') then
        if sArg(args,'-left') then
            self:moveCursor('-hold -jump -left')
        elseif sArg(args,'-right') then
            self:moveCursor('-hold -jump -right')
        end
        self:delete('')
    else
        if sArg(args,'-left') then
            if self.curX==0 then
                if self.curY>1 then
                    self.curX=#self[self.curY-1]
                    self[self.curY-1]=self[self.curY-1]..self[self.curY]
                    rem(self,self.curY)
                    self.curY=self.curY-1
                    result=true
                    SFX.play(tempInputBox.sound_bksp)
                end
            else
                local l=self[self.curY]
                l=l:sub(1,self.curX-1,0)..l:sub(self.curX+1)
                self[self.curY]=l
                self.curX=max(self.curX-1,0)
                result=true
                SFX.play(tempInputBox.sound_bksp)
            end
        elseif sArg(args,'-right') then
            if self.curX==#self[self.curY] then
                if self.curY<#self then
                    self[self.curY]=self[self.curY]..self[self.curY+1]
                    rem(self,self.curY+1)
                    result=true
                    SFX.play(tempInputBox.sound_bksp)
                end
            else
                local l=self[self.curY]
                l=l:sub(1,self.curX)..l:sub(self.curX+2)
                self[self.curY]=l
                result=true
                SFX.play(tempInputBox.sound_bksp)
            end
        end
    end
    if result then
        self:freshScroll()
        self:saveCurX()
    end
end

function Page:insLine(args)
    if sArg(args,'-normal') then
        ins(self,self.curY+1,self[self.curY]:sub(self.curX+1))
        self[self.curY]=self[self.curY]:sub(1,self.curX)
        self.curY=self.curY+1
        self.curX=0
    elseif sArg(args,'-under') then
        ins(self,self.curY+1,"")
        self.curY=self.curY+1
        self.curX=0
    elseif sArg(args,'-above') then
        ins(self,self.curY,"")
        self.curX=0
    end
    if not sArg(args,'-auto') then
        SFX.play(tempInputBox.sound_input)
    end
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
        if self.curY==#self then lineAdded=true; ins(self,"") end
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
    if self.selX then self:delete('-normal') end

    -- Get paste data
    local str
    if sArg(args,'-clipboard') then
        str=love.system.getClipboardText()
    elseif sArg(args,'-data') then
        str=data
    end
    if not str or str=="" then return end

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
function Page:draw(x,y)
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
    FONT.set(30,'_codePixel')
    gc.setColor(COLOR.dL)
    for i=self.scrollY+1,min(self.scrollY+lineCount,#self) do
        GC.safePrint(self[i],100+self.baseX,lineH*(i-1)+self.baseY)
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
        rainbowShader:send('phase',love.timer.getTime()*2.6%6.2832)
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

    -- Real cursor
    gc.setLineWidth(4)
    gc.setColor(.26,1,.26,(-love.timer.getTime()%.4*4)^2)
    _x,_y=100+charW*self.curX,lineH*self.curY
    -- gc.line(_x,_y-lineH,_x,_y)-- Normal cursor style, if you dislike the 'Z' one
    gc.line(_x-4,_y-lineH,_x+2,_y-lineH,_x,_y,_x+6,_y)

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

local help=setmetatable({},{__index=function()return '[-]' end})
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

local scene={}

function scene.enter()
    BG.set('none')
    clipboardFreshCD=0
    escapeHoldTime=0
    freshClipboard()

    if type(rainbowShader)=='string' then rainbowShader=gc.newShader(rainbowShader) end
    if type(comboKeyName[1].name)=='string' then
        for i=1,#comboKeyName do
            comboKeyName[i].text=gc.newText(FONT.get(15,'_codePixel'),comboKeyName[i].text)
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
    for i=1,#comboKeyName do
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
                P:insStr(STRING.shiftChar(key))
            elseif combo==key then
                P:insStr(key)
            else
                MES.new('info',"Unknown combo: "..combo,1.26)
            end
        end
    elseif key=='escape' then
        if P and P.selX then
            P.selX,P.selY=false,false
        elseif not isRep then
            MES.new('info',"Hold esc to quit",.26)
        end
    else
        MES.new('info',"Unknown operation: "..combo,1.26)
    end
end
function scene.mouseDown(x,y,k)
    if not curPage then return end
    local P=activePages[curPage]

    -- Outside mouse posion
    local mx,my=x-50,y-50
    if not (mx>0 and mx<P.windowW and my>0 and my<P.windowH) then return end

    -- Inside position
    mx,my=mx-100+P.scrollX*P.charWidth,my+P.scrollY*P.lineHeight
    if mx<0 then-- Select line
        local ty=int(my/P.lineHeight)+1

        if not (kb.isDown('lshift','rshift') and P.selX) then
            P.selX,P.selY=0,ty
        end
        P.curX,P.curY=0,ty+1
        P:moveCursor('-mouse')
    else-- Select char
        if kb.isDown('lshift','rshift') then
            if not P.selX then P.selX,P.selY=P.curX,P.curY end
            P.curX,P.curY=int(mx/P.charWidth+.5),int(my/P.lineHeight)+1
            P:moveCursor('-mouse -hold')
        else
            P.selX,P.selY=false,false
            P.curX,P.curY=int(mx/P.charWidth+.5),int(my/P.lineHeight)+1
            P:moveCursor('-mouse')
        end
    end
    P:saveCurX()
end
function scene.mouseMove(x,y)
    if not curPage then return end
    local P=activePages[curPage]
    if ms.isDown(1) or ms.isDown(2) then
        if not P.selX then P.selX,P.selY=P.curX,P.curY end
        local mx,my=x-50,y-50
        mx,my=mx-100+P.scrollX*P.charWidth,my+P.scrollY*P.lineHeight
        P.curX,P.curY=int(mx/P.charWidth+.5),int(my/P.lineHeight)+1
        P:moveCursor('-mouse')
        P:saveCurX()
    end
end
function scene.mouseUp(x,y,k)
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
    gc.clear(0,0,0)
    if curPage then
        activePages[curPage]:draw(50,50)
        gc.replaceTransform(SCR.xOy_ul)
        FONT.set(20,'_codePixel')
        gc.print(pageInfo,50,5)
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
                gc.draw(comboKeyName[i].text,x,-45)
                x=x+comboKeyName[i].text:getWidth()+10
            end
        end
    else
        FONT.set(35,'_codePixel')
        GC.mStr(help.newFile,SCR.w0/2,SCR.h0/2-26,'center')
    end
end

return scene
