local gc=love.graphics
local ms,kb=love.mouse,love.keyboard
local ins,rem=table.insert,table.remove
local max,min=math.max,math.min
local int,ceil=math.floor,math.ceil

local sArg=STRING.sArg

local tempInputBox=WIDGET.new{type='inputBox'}
local clipboardText=""

local rainbowShader-- We generate shader later

local function freshClipboard()
    clipboardText=love.system.getClipboardText()
    if clipboardText=="" then
        clipboardText=false
    elseif #clipboardText>26 then
        clipboardText=clipboardText:sub(1,21).."...("..#clipboardText..")"
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

-------------------------------------------------------------

local Page={}
Page.__index=Page
function Page.new(args)
    args=args or ''
    local p=setmetatable({
        windowW=SCR.w-100,windowH=SCR.h-100,
        scrollX=0,scrollY=0,
        curX=0,curY=1,
        memX=0,
        selX=false,selY=false,
        charWidth=23,lineHeight=35,
        fileName="*Untitled",
        filePath=false,
        fileInfo={COLOR.L,"*Untitled"},
    },Page)
    if sArg(args,'-welcome') then
        TABLE.connect(p,{
            "-- Welcome to Zenitha editor --",
            "",
            "Type freely on any devices.",
            "",
            "by 26F Studio",
            "",
        })
        p:moveCursor('-auto -end -jump')
    end
    p:saveCurX()
    return p
end

function Page:loadFile(file)
    -- Parse file path and name
    self.filePath=file:getFilename()
    self.fileName=self.filePath:match('.+\\(.+)$') or self.filePath
    self.fileInfo={COLOR.L,self.fileName.."  ",COLOR.DL,self.filePath}

    -- Load file data
    self:delete('-all')
    self:paste((file:read()))

    -- Reset cursor and scroll
    self.curX,self.curY=0,1
    self:updateScroll()
    self:saveCurX()
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
    self.scrollY=max(min(self.scrollY+dy,#self-1),0)
end

function Page:scrollH(args)
    local dx=sArg(args,'-left') and 1 or sArg(args,'-right') and -1
    if not dx then return end
    if sArg(args,'-jump') then dx=10*dx end
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
        if not sArg(args,'-auto') and sArg(args,'-hold') and not self.selX then
            self.selX,self.selY=self.curX,self.curY
        end
        if sArg(args,'-left') then
            if sArg(args,'-jump') then
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
            if sArg(args,'-jump') then
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
            if sArg(args,'-jump') then
                self.curY=1
            end
            self.curX=0
            self:saveCurX()
        elseif sArg(args,'-end') then
            if sArg(args,'-jump') then
                self.curY=#self
            end
            self.curX=#self[self.curY]
            self:saveCurX()
        elseif sArg(args,'-up') then
            local l=sArg(args,'-jump') and 26 or 1
            if self.curY>l then
                self.curY=self.curY-l
            else
                self.curY=1
                self.curX=0
            end
            self.curX=min(self.memX,#self[self.curY])
        elseif sArg(args,'-down') then
            local l=sArg(args,'-jump') and 26 or 1
            if self.curY<=#self-l then
                self.curY=self.curY+l
            else
                self.curY=#self
                self.curX=#self[self.curY]
            end
            self.curX=min(self.memX,#self[self.curY])
        end
        if not sArg(args,'-auto') then
            if not sArg(args,'-hold') or self.selX==self.curX and self.selY==self.curY then
                self.selX,self.selY=false,false
            end
            self:updateScroll()
        end
    end
end

function Page:saveCurX()
    self.memX=self.curX
end

function Page:updateScroll()
    self.scrollY=MATH.interval(self.scrollY,ceil(self.curY-self.windowH/self.lineHeight),self.curY-1)
end

-- Edit
function Page:insStr(str)
    if str=="" then return end
    if self.selX then self:delete('-normal') end
    local l=self[self.curY]
    l=l:sub(1,self.curX)..str..l:sub(self.curX+1)
    self.curX=self.curX+#str
    self[self.curY]=l
    self:saveCurX()
    SFX.play(tempInputBox.sound_input)
end

function Page:indent(args)
    if sArg(args,'-add') then
        if self.selX then
            local _,startY,_,endY=self:getSelArea()
            for l=startY,endY do
                self[l]='    '..self[l]
            end
            self.selX=self.selX+4
            self.curX=self.curX+4
        else
            self:insStr('    ')
        end
    elseif sArg(args,'-remove') then
        local _,startY,_,endY=self:getSelArea()
        for l=startY,endY do
            if self[l]:sub(1,4)=='    ' then
                self[l]=self[l]:sub(5)
            end
        end
        self.selX=self.selX-4
        self.curX=self.curX-4
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
    else
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
        SFX.play(tempInputBox.sound_bksp)
        self:updateScroll()
        self:saveCurX()
    end
end

function Page:insLine(args)
    if sArg(args,'-normal') then
        ins(self,self.curY+1,self[self.curY]:sub(self.curX+1))
        self[self.curY]=self[self.curY]:sub(1,self.curX)
        self.curY=self.curY+1
        self.curX=0
    elseif sArg(args,'-newLine') then
        ins(self,self.curY+1,"")
        self.curY=self.curY+1
        self.curX=0
    end
    self:updateScroll()
    self:saveCurX()
end

function Page:moveLine(args)
    if sArg(args,'-up') then
        local _,startY,endX,endY=self:getSelArea()
        if startY>1 then
            if endX==0 then endY=endY-1 end
            ins(self,endY,rem(self,startY-1))
            self.curY=self.curY-1
            if self.selY then self.selY=self.selY-1 end
            self:updateScroll()
            self:saveCurX()
        end
    elseif sArg(args,'-down') then
        local _,startY,endX,endY=self:getSelArea()
        if endY<#self then
            if endX==0 then endY=endY-1 end
            ins(self,startY,rem(self,endY+1))
            self.curY=self.curY+1
            if self.selY then self.selY=self.selY+1 end
            self:updateScroll()
            self:saveCurX()
        end
    end
end

function Page:duplicateLine()
    local _,startY,_,endY=self:getSelArea()
    if startY==endY then
        ins(self,startY+1,self[startY])
        self:moveCursor('-auto -down')
    else
        for i=startY,endY do ins(self,i+1,self[i]) end
        self:moveCursor('-auto -down')
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
    self:updateScroll()
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
end

function Page:paste(data)
    if self.selX then self:delete('-normal') end
    local str=data or love.system.getClipboardText()
    str=str:gsub('\r','')
    str=str:gsub('\t','    ')
    if str:sub(-1)=='\n' then str=str..'\n' end
    str=STRING.split(str,'\n')
    for i=1,#str-1 do
        self:insStr(str[i])
        self:insLine('-normal')
    end
    self:insStr(str[#str])
    self:updateScroll()
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
        GC.safePrint(self[i],101,lineH*(i-1)+4)
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

local activePages={}
local curPage=false

local scene={}

function scene.enter()
    BG.set('none')
    curPage=Page.new('-welcome')
    ins(activePages,curPage)
    freshClipboard()
    rainbowShader=rainbowShader or gc.newShader[[
        uniform float phase;
        vec4 effect(vec4 color,sampler2D tex,vec2 texCoord,vec2 scrCoord){
            float iphase=phase-(scrCoord.x/love_ScreenSize.x+scrCoord.y/love_ScreenSize.y)*6.26;
            return vec4(
                sin(iphase),
                sin(iphase+2.0944),
                sin(iphase-2.0944),
                1.0
            )*.5+.5;
        }
    ]]
end

local keyMap={
    ['left']=               {func='moveCursor',  args='-left'},
    ['right']=              {func='moveCursor',  args='-right'},
    ['up']=                 {func='moveCursor',  args='-up'},
    ['down']=               {func='moveCursor',  args='-down'},
    ['home']=               {func='moveCursor',  args='-home'},
    ['end']=                {func='moveCursor',  args='-end'},
    ['pageup']=             {func='moveCursor',  args='-jump -up'},
    ['pagedown']=           {func='moveCursor',  args='-jump -down'},

    ['ctrl+left']=          {func='moveCursor',  args='-left -jump'},
    ['ctrl+right']=         {func='moveCursor',  args='-right -jump'},
    ['ctrl+up']=            {func='scrollV',     args='-up'},
    ['ctrl+down']=          {func='scrollV',     args='-down'},
    ['ctrl+home']=          {func='moveCursor',  args='-home -jump'},
    ['ctrl+end']=           {func='moveCursor',  args='-end -jump'},
    ['ctrl+pageup']=        {func='scrollV',     args='-up -jump'},
    ['ctrl+pagedown']=      {func='scrollV',     args='-down -jump'},

    ['shift+left']=         {func='moveCursor',  args='-left -hold'},
    ['shift+right']=        {func='moveCursor',  args='-right -hold'},
    ['shift+up']=           {func='moveCursor',  args='-up -hold'},
    ['shift+down']=         {func='moveCursor',  args='-down -hold'},
    ['shift+home']=         {func='moveCursor',  args='-home -hold'},
    ['shift+end']=          {func='moveCursor',  args='-end -hold'},

    ['ctrl+shift+left']=    {func='moveCursor',  args='-left -jump -hold'},
    ['ctrl+shift+right']=   {func='moveCursor',  args='-right -jump -hold'},
    ['ctrl+shift+up']=      {func='moveCursor',  args='-up -hold'},-- Same as no ctrl
    ['ctrl+shift+down']=    {func='moveCursor',  args='-down -hold'},-- Same as no ctrl
    ['ctrl+shift+home']=    {func='moveCursor',  args='-home -jump -hold'},
    ['ctrl+shift+end']=     {func='moveCursor',  args='-end -jump -hold'},

    ['alt+up']=             {func='moveLine',    args='-up'},
    ['alt+down']=           {func='moveLine',    args='-down'},

    ['ctrl+a']=             {func='selectAll'},
    ['ctrl+d']=             {func='duplicateLine'},
    ['ctrl+x']=             {func='cut'},
    ['ctrl+c']=             {func='copy'},
    ['ctrl+v']=             {func='paste'},

    ['space']=              {func='insStr',      args=' '},
    ['tab']=                {func='indent',      args='-add'},
    ['shift+tab']=          {func='indent',      args='-remove'},
    ['return']=             {func='insLine',     args='-normal'},
    ['ctrl+return']=        {func='insLine',     args='-newLine'},

    ['ctrl+tab']=           {func='switchFile',  args='-next'},
    ['ctrl+shift+tab']=     {func='switchFile',  args='-prev'},

    ['backspace']=          {func='delete',      args='-left'},
    ['delete']=             {func='delete',      args='-right'},
}

local keyAlias={
    ['kp+']='+',['kp-']='-',['kp*']='*',['kp/']='/',
    ['kpenter']='return',
    ['kp.']='.',
    ['kp7']='home',['kp1']='end',
    ['kp9']='pageup',['kp3']='pagedown',
}

local comboKeys={
    ['lctrl']=true,['rctrl']=true,
    ['lshift']=true,['rshift']=true,
    ['lalt']=true,['ralt']=true,
}

function scene.keyDown(key)
    if curPage then
        if comboKeys[key] then return end
        if keyAlias[key] then key=keyAlias[key] end
        local combo=key
        if kb.isDown('lalt','ralt') then combo='alt+'..combo end
        if kb.isDown('lshift','rshift') then combo='shift+'..combo end
        if kb.isDown('lctrl','rctrl') then combo='ctrl+'..combo end
        if keyMap[combo] then
            curPage[keyMap[combo].func](curPage,keyMap[combo].args)
        elseif #key==1 then
            if combo=='shift+'..key then
                curPage:insStr(STRING.shiftChar(key))
            elseif combo==key then
                curPage:insStr(key)
            else
                MES.new('info',"Unknown combo: "..combo)
            end
        elseif key=='escape' then
            if curPage.selX then
                curPage.selX=false
                curPage.selY=false
            end
        else
            MES.new('info',"Unknown key: "..combo)
        end
    else

    end
end
function scene.mouseDown(x,y,k)
    if not curPage then return end
    local p=curPage

    -- Outside mouse posion
    local mx,my=x-50,y-50
    if not (mx>0 and mx<p.windowW and my>0 and my<p.windowH) then return end

    -- Inside position
    mx,my=mx-100+p.scrollX*p.charWidth,my+p.scrollY*p.lineHeight
    if mx<0 then-- Select line
        local ty=int(my/p.lineHeight)+1

        if not (kb.isDown('lshift','rshift') and p.selX) then
            p.selX,p.selY=0,ty
        end
        p.curX,p.curY=0,ty+1
        p:moveCursor('-mouse')
    else-- Select char
        if kb.isDown('lshift','rshift') then
            if not p.selX then p.selX,p.selY=p.curX,p.curY end
            p.curX,p.curY=int(mx/p.charWidth+.5),int(my/p.lineHeight)+1
            p:moveCursor('-mouse -hold')
        else
            p.selX,p.selY=false,false
            p.curX,p.curY=int(mx/p.charWidth+.5),int(my/p.lineHeight)+1
            p:moveCursor('-mouse')
        end
    end
    p:saveCurX()
end
function scene.mouseMove(x,y)
    if not curPage then return end
    local p=curPage
    if ms.isDown(1) or ms.isDown(2) then
        if not p.selX then p.selX,p.selY=p.curX,p.curY end
        local mx,my=x-50,y-50
        mx,my=mx-100+p.scrollX*p.charWidth,my+p.scrollY*p.lineHeight
        p.curX,p.curY=int(mx/p.charWidth+.5),int(my/p.lineHeight)+1
        p:moveCursor('-mouse')
        p:saveCurX()
    end
end
function scene.mouseUp(x,y,k)
end
function scene.wheelMoved(dx,dy)
    if not curPage then return end
    while dy>0 do dy=dy-1; curPage:scrollV('-up') end
    while dy<0 do dy=dy+1; curPage:scrollV('-down') end
    while dx>0 do dx=dx-1; curPage:scrollH('-left') end
    while dx<0 do dx=dx+1; curPage:scrollH('-right') end
end
function scene.fileDropped(file)
    if curPage then
        curPage:delete('-all')
    else
        curPage=Page.new()
        ins(activePages,curPage)
    end
    curPage:loadFile(file)
end

local clipboardFreshCD=0
function scene.update(dt)
    clipboardFreshCD=clipboardFreshCD+dt
    if clipboardFreshCD>=1 then
        clipboardFreshCD=0
        freshClipboard()
    end
end

function scene.draw()
    gc.clear(0,0,0)
    if curPage then curPage:draw(50,50) end
    if clipboardText then
        gc.replaceTransform(SCR.xOy_ur)
        FONT.set(20,'_codePixel')
        gc.setColor(COLOR.LD)
        GC.safePrintf(clipboardText,-2605,5,2600,'right')
    end
end

return scene
