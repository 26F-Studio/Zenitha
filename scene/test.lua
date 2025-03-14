local ins,rem=table.insert,table.remove

---@type Zenitha.Scene
local scene={}

local backCounter
local list,timer
local function _push(msg)
    ins(list,{msg,120})
    timer=1
end

function scene.load()
    backCounter=5
    list={}
    timer=0
end

function scene.gamepadDown(key)
    _push("[gamepadDown] <"..key..">")
end
function scene.gamepadUp(key)
    _push{COLOR.LD,"[gamepadUp] <"..key..">"}
end
function scene.keyDown(key,isRep)
    if isRep then return end
    _push("[keyDown] <"..key..">")
    if key=='escape' then
        backCounter=backCounter-1
        if backCounter==0 then
            SCN.back()
        else
            MSG('info',backCounter,2.6)
        end
    end
    return true
end
function scene.keyUp(key)
    _push{COLOR.LD,"[keyUp] <"..key..">"}
end
function scene.mouseClick(x,y)
    SYSFX.ripple(2,x,y,50)
    _push("[mouseClick]")
end
function scene.mouseDown(x,y,k)
    SYSFX.rect(2,x-10,y-10,20,20)
    _push(("[mouseDown] <%d: %d, %d>"):format(k,x,y))
    return true
end
function scene.mouseMove(x,y)
    SYSFX.rect(2,x-3,y-3,6,6)
end
function scene.mouseUp(x,y,k)
    SYSFX.rectRipple(1,x-10,y-10,20,20)
    _push{COLOR.LD,"[mouseUp] <"..k..">"}
end
function scene.touchClick(x,y)
    SYSFX.ripple(2,x,y,50)
    _push("[touchClick]")
end
function scene.touchDown(x,y)
    if #love.touch.getTouches()>=6 then scene.keyDown('escape') end
    SYSFX.rect(2,x-10,y-10,20,20)
    _push(("[touchDown] <%d, %d>"):format(x,y))
end
function scene.touchMove(x,y)
    SYSFX.rect(2,x-3,y-3,6,6)
end
function scene.touchUp(x,y)
    SYSFX.rectRipple(1,x-10,y-10,20,20)
    _push{COLOR.LD,"[touchUp]"}
end
function scene.wheelMove(dx,dy)
    _push(("[wheelMove] <%d, %d>"):format(dx,dy))
    return true
end
function scene.fileDrop(file)
    _push(("[fileDrop] <%s>"):format(file:getFilename()))
end
function scene.folderDrop(path)
    _push(("[folderDrop] <%s>"):format(path))
end

function scene.update(dt)
    if timer>0 then
        timer=timer-dt/.526
    end
    for i=#list,1,-1 do
        list[i][2]=list[i][2]-1
        if list[i][2]==0 then
            rem(list,i)
        end
    end
end

function scene.draw()
    GC.replaceTransform(SCR.xOy_ul)
    FONT.set(15,'_norm')
    local l=#list
    for i=1,l do
        GC.setColor(1,1,1,list[i][2]/30)
        GC.print(list[i][1],20,20*(l-i+1))
    end
end

return scene
