local CLASS={}

function CLASS.simple(class)
    return setmetatable({},{__index=class})
end

function CLASS.deep(class)
    return setmetatable(TABLE.copy(class),getmetatable(class))
end

return CLASS
