local gc_stencil=love.graphics.stencil
local gc_rectangle=love.graphics.rectangle
local gc_circle=love.graphics.circle
local gc_setStencilTest=love.graphics.setStencilTest

local STENCIL={}

STENCIL.start=gc_setStencilTest
function STENCIL.stop()
    gc_setStencilTest()
end

local rect_x,rect_y,rect_w,rect_h
local function stencil_rectangle()
    gc_rectangle('fill',rect_x,rect_y,rect_w,rect_h)
end

function STENCIL.rectangle(x,y,w,h)
    rect_x,rect_y,rect_w,rect_h=x,y,w,h
    gc_stencil(stencil_rectangle)
end

local circle_x,circle_y,circle_r,circle_seg
local function stencil_circle()
    gc_circle('fill',circle_x,circle_y,circle_r,circle_seg)
end

function STENCIL.circle(x,y,r,seg)
    circle_x,circle_y,circle_r,circle_seg=x,y,r,seg
    gc_stencil(stencil_circle)
end

return STENCIL
