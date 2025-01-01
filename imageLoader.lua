if not love.graphics then
    LOG("IMG lib is not loaded (need love.graphics)")
    return setmetatable({},{
        __index=function(_)
            error("attempt to use IMG lib, but IMG lib is not loaded (need love.graphics)")
        end
    })
end

local IMG={}

function IMG._loader(path)
    -- Non-string: Just keep the value as it is
    if type(path)~='string' then return path end

    -- string: Load image with path
    local suc,res=pcall(love.graphics.newImage,path)
    if not suc then
        MSG.log('error',("Cannot load image '%s': %s"):format(path,res))
        return PAPER
    end
    return res
end

---Initialize IMG lib (only once)
---### Example
---```
---IMG.init{
---    img1='.../img1.jpg',
---    img2='.../img2.png',
---    imgPack={
---        img3_1='.../img3/1.jpg',
---        img3_2='.../img3/2.jpg',
---        img4={
---            '.../img4/1.png',
---            '.../img4/2.png',
---        },
---    },
---}
----- Now you can get image objects same as with get things from the index table:
---local img1=IMG.img1
---local img3_1=IMG.imgPack.img3_1
---local img4_1=IMG.imgPack.img4[1]
---
---```
---`IMG.init(index)` is actually an overload of `IMG.init(IMG,index)`.
---
---You can make your own lib with `lib=IMG.init(index,true)`, and init in this way can help language server doing auto-completion for you.
---
---Note: This is actually a wrapper of TABLE.linkSource + IMG._loader. Explore the cool implementation of `TABLE.linkSource` yourself!
---@overload fun(index: Map<string | table>)
---@generic T
---@param index T
---@param export? boolean
---@return T
function IMG.init(index,export)
    local lib=export and {} or IMG
    TABLE.linkSource(lib,index,IMG._loader)
    return lib
end

return IMG
