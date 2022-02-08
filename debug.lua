local yield=coroutine.yield
local DEBUG={}

-- Wait for the scene swapping animation to finish
function DEBUG.yieldUntilNextScene()
    while SCN.swapping do yield() end
end

function DEBUG.yieldN(frames)
    for _=1,frames do yield() end
end

return DEBUG
