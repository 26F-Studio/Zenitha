return function(class)
    return setmetatable({},{__index=class})
end
