local love=love
local max,min=math.max,math.min
local trigDist=0

--- Convert wheel movement to arrow key presses by trigger love.keypressed event
--- @param y number @wheel movement
--- @param key1 string @key name when scroll up ('up')
--- @param key2 string @key name when scroll down ('down')
return function(y,key1,key2)
    if y>0 then
        trigDist=max(trigDist,0)+y^1.2
    elseif y<0 then
        if trigDist>0 then trigDist=0 end
        trigDist=min(trigDist,0)-(-y)^1.2
    end
    while trigDist>=1 do
        love.keypressed(key1 or 'up')
        trigDist=trigDist-1
    end
    while trigDist<=-1 do
        love.keypressed(key2 or 'down')
        trigDist=trigDist+1
    end
end
