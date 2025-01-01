if not love.graphics then
    LOG("IMG lib is not loaded (need love.graphics)")
    return setmetatable({},{
        __index=function(_)
            error("attempt to use IMG lib, but IMG lib is not loaded (need love.graphics)")
        end
    })
end

local IMG={}

local initialized=false
local IMGlistMeta={
    __index=function(self,k)
        local path=self.__source[k]
        assertf(path~=nil,"IMG[]: No field '%s'",k)
        if type(path)=='string' then
            -- string: Load image with path
            local suc,res=pcall(ZENITHA.graphics.newImage,path)
            if not suc then
                MSG.log('error',("Cannot load image '%s': %s"):format(path,res))
                res=PAPER
            end
            self[k]=res
            return res
        else
            -- other types: Copy value to the table
            self[k]=path
            return path
        end
    end,
    __metatable=true,
}
local function link(A,B)
    A.__source=B
    setmetatable(A,IMGlistMeta)
    for k,v in next,B do
        if type(v)=='table' then
            A[k]={}
            link(A[k],v)
        end
    end
end

---Initialize IMG lib (only once)
---### Example
---```
---IMG.init{
---    image1='.../image1.jpg',
---    image2='.../image2.png',
---    imagePack={
---        image3_1='.../image3/1.jpg',
---        image3_2='.../image3/2.jpg',
---        image4={
---            '.../image4/1.png',
---            '.../image4/2.png',
---        },
---    },
---}
----- Then you can get image objects same as with get things from table like this:
---local image1=IMG.image1
---local image3_1=IMG.imagePack.image3_1
---local image4_1=IMG.imagePack.image4[1]
---```
---@param imgTable Map<string | table>
function IMG.init(imgTable)
    if initialized then
        LOG('warn',"IMG.init: Attempt to initialize twice")
        return
    end
    initialized,IMG.init=true,nil
    link(IMG,imgTable)
    return imgTable
end

return IMG
