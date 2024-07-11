local testVal_1={false,false,false}
local testVal_2={18,260,.26}
local testVal_3={'medium','large','ex-large'}
local testVal_4={} for i=1,9 do table.insert(testVal_4,{name='user'..i}) end
local function _sceneDraw()
    FONT.set(150,'_norm')
    GC.mStr("Zenitha",400,40)
    FONT.set(60,'_norm')
    GC.mStr("Demo Scene",400,200)
    FONT.set(20,'_norm')
    GC.mStr("Powered by LÖVE",400,280)
end

---@type Zenitha.Scene
local scene={
    draw=function()
        GC.setColor(.97,.97,.97,.626)
        _sceneDraw()

        GC.stc_reset()
        GC.stc_circ(400+100*math.cos(love.timer.getTime()*1.26),240+100*math.sin(love.timer.getTime()*1.26),126)
        GC.setColor(COLOR.rainbow_light(love.timer.getTime()))
        _sceneDraw()
        GC.stc_stop()
    end,
    widgetList={
        {type='checkBox',    text='checkBox1', x=260,y=350,w=40,disp=function() return testVal_1[1] end,code=function() testVal_1[1]=not testVal_1[1] end},
        {type='checkBox',    text='checkBox2', x=260,y=400,w=40,disp=function() return testVal_1[2] end,code=function() testVal_1[2]=not testVal_1[2] end},
        {type='checkBox',    text='checkBox3', x=260,y=450,w=40,disp=function() return testVal_1[3] end,code=function() testVal_1[3]=not testVal_1[3] end},

        {type='slider',      text='slider1',   x=460,y=350,w=260,axis={10,26,4},              disp=function() return testVal_2[1] end,code=function(v) testVal_2[1]=v end},
        {type='slider',      text='slider2',   x=460,y=400,w=260,axis={0,620,10},smooth=true, disp=function() return testVal_2[2] end,code=function(v) testVal_2[2]=v end},
        {type='slider_fill', text='slider3',   x=460,y=450,w=260,                             disp=function() return testVal_2[3] end,code=function(v) testVal_2[3]=v end},

        {type='selector',    text='selector1', x=330,y=510,w=200,list={'medium','large','ex-large'},disp=function() return testVal_3[1] end,code=function(v) testVal_3[1]=v end},
        {type='selector',    text='selector2', x=330,y=560,w=200,list={'medium','large','ex-large'},disp=function() return testVal_3[2] end,code=function(v) testVal_3[2]=v end},
        {type='selector',    text='selector3', x=330,y=610,w=200,list={'medium','large','ex-large'},disp=function() return testVal_3[3] end,code=function(v) testVal_3[3]=v end},

        {type='button',      text='Quit',      x=600,y=540,w=200,h=80,code=function() love.event.quit() end},
        {type='button',      text='Console',   x=600,y=620,w=190,h=60,code=WIDGET.c_goScn'_console'},
        {type='button',      text='Text',      x=550,y=690,w=90,h=60,code=function() TEXT:add{text='Sample Text',x=SCR.w0/2,y=SCR.h0/2,k=2,fontSize=50} end},
        {type='button',      text='Wait',      x=650,y=690,w=90,h=60,code=function() WAIT.new{timeout=1} end},
        {type='button',      text='Msg',       x=550,y=760,w=90,h=60,code=function() MSG.new('info',"Test message",5) end},
        {type='button',      text='Task',      x=650,y=760,w=90,h=60,code=function() TASK.new(function() for a=0,MATH.tau,MATH.tau/32 do SYSFX.ripple(1,SCR.w0/2+260*math.cos(a),SCR.h0/2+260*math.sin(a),50) DEBUG.yieldT(.01) end end) end},

        {type='inputBox',    text='inputBox',  x=100,y=650,w=300,h=100,labelPos='bottom'},
        {type='textBox',     name='textBox',   x=100,y=820,w=600,h=160},
        {type='listBox',     name='listBox',   x=100,y=1020,w=600,h=160,drawFunc=function(opt,id,sel)
            FONT.set(30)
            GC.setColor(COLOR.L)
            GC.print(id,10,-6)
            GC.print(opt.name,70,-6)
            if sel then
                GC.setColor(1,1,1,.2)
                GC.rectangle('fill',0,0,600,30)
            end
        end},
    }
}
scene.scrollHeight=626
function scene.load()
    scene.widgetList.textBox:setTexts({"4.textBox","line 2","line 3","line 4","line 5","line 6","line 7"},true)
    scene.widgetList.listBox:setList(testVal_4)
end

return scene
