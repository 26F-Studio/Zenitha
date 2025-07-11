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
----- Initialize the IMG lib with a index table
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
---```
--- By the way, the index table **CAN** include non-string value, they won't be loaded as a path string, but just keep the value as it is.
---
---Advanced usage: `IMG.init(index)` is overload of `IMG.init(index,IMG)`, so you can create your own lib with `lib=IMG.init(index,true)`, in this way you can help language server doing auto-completion for you.
---
---Interesting fact: This is actually a simple wrapping of `TABLE.linkSource` + `IMG._loader`
---@overload fun(index: Map<string | table>)
---@generic T
---@param index T
---@param export? true
---@return T
function IMG.init(index,export)
    local lib=export and {} or IMG
    TABLE.linkSource(lib,index,IMG._loader)
    return lib
end

return IMG
