local CLASS={}

function CLASS.inherit(class,o)
    o.__parent=class
    return setmetatable(o,{__index=class})
end

return CLASS
