local CLASS={}

function CLASS.inherit(o,class)
    o.__parent=class
    setmetatable(o,{__index=class})
end
function CLASS.instance(class)
    return setmetatable({__class=class},{__index=class})
end

return CLASS
