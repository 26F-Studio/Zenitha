local gc=love.graphics
local testVal_1={false,false,false}
local testVal_2={18,260,.26}
local testVal_3={'medium','large','ex-large'}
local testVal_4={} for i=1,9 do table.insert(testVal_4,{name='user'..i}) end
local function _sceneDraw()
    FONT.set(150,'_basic')
    GC.mStr("Zenitha",400,40)
    FONT.set(60,'_basic')
    GC.mStr("Demo Scene",400,200)
    FONT.set(20,'_basic')
    GC.mStr("Powered by LÖVE",400,280)
end
local scene={
    draw=function()
        gc.setColor(.97,.97,.97,.626)
        _sceneDraw()

        GC.stc_reset()
        GC.stc_circ(400+100*math.cos(love.timer.getTime()*1.26),240+100*math.sin(love.timer.getTime()*1.26),126)
        gc.setColor(COLOR.rainbow_light(love.timer.getTime()))
        _sceneDraw()
        GC.stc_stop()
    end,
    widgetList={
        WIDGET.new{type='checkBox',    text='checkBox1', x=260,y=350,w=40,disp=function() return testVal_1[1] end,code=function() testVal_1[1]=not testVal_1[1] end},
        WIDGET.new{type='checkBox',    text='checkBox2', x=260,y=400,w=40,disp=function() return testVal_1[2] end,code=function() testVal_1[2]=not testVal_1[2] end},
        WIDGET.new{type='checkBox',    text='checkBox3', x=260,y=450,w=40,disp=function() return testVal_1[3] end,code=function() testVal_1[3]=not testVal_1[3] end},

        WIDGET.new{type='slider',      text='slider1',   x=460,y=350,w=260,axis={10,26,4},              disp=function() return testVal_2[1] end,code=function(v) testVal_2[1]=v end},
        WIDGET.new{type='slider',      text='slider2',   x=460,y=400,w=260,axis={0,620,10},smooth=true, disp=function() return testVal_2[2] end,code=function(v) testVal_2[2]=v end},
        WIDGET.new{type='slider_fill', text='slider3',   x=460,y=450,w=260,                             disp=function() return testVal_2[3] end,code=function(v) testVal_2[3]=v end},

        WIDGET.new{type='selector',    text='selector1', x=330,y=510,w=200,list={'medium','large','ex-large'},disp=function() return testVal_3[1] end,code=function(v) testVal_3[1]=v end},
        WIDGET.new{type='selector',    text='selector2', x=330,y=560,w=200,list={'medium','large','ex-large'},disp=function() return testVal_3[2] end,code=function(v) testVal_3[2]=v end},
        WIDGET.new{type='selector',    text='selector3', x=330,y=610,w=200,list={'medium','large','ex-large'},disp=function() return testVal_3[3] end,code=function(v) testVal_3[3]=v end},

        WIDGET.new{type='button',      text='Quit',      x=600,y=540,w=200,h=100,code=function() love.event.quit() end},
        WIDGET.new{type='button',      text='Console',   x=600,y=630,w=160,h=60,code=WIDGET.c_goScn'_console'},

        WIDGET.new{type='inputBox',    text='inputBox',  x=100,y=650,w=300,h=100,labelPos='down'},
        WIDGET.new{type='textBox',     name='textBox',   x=100,y=820,w=600,h=160},
        WIDGET.new{type='listBox',     name='listBox',   x=100,y=1020,w=600,h=160,drawFunc=function(opt,id,sel)
            FONT.set(30)
            gc.setColor(COLOR.L)
            gc.print(id,10,-6)
            gc.print(opt.name,70,-6)
            if sel then
                gc.setColor(1,1,1,.2)
                gc.rectangle('fill',0,0,600,30)
            end
        end},
    }
}
scene.scrollHeight=626
function scene.init()
    scene.widgetList.textBox:setTexts({"5.textBox","line 2","line 3","line 4","line 5","line 6","line 7"},true)
    scene.widgetList.listBox:setList(testVal_4)
end

return scene
