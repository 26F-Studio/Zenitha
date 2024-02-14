local IMG={}

local initialized=false
local IMGlistMeta={
    __index=function(self,k)
        local path=self.__source[k]
        local ok,res
        if type(path)=='string' then -- string, load image from path
            assert(path,STRING.repD("IMG[]: No field '$1'",tostring(k)))
            ok,res=pcall(love.graphics.newImage,path)
        else -- not string (neither table), keep the value
            ok,res=true,path
        end
        if ok then
            self[k]=res
        else
            self[k]=PAPER
            MSG.new('error',STRING.repD("Cannot load image '$1': $2",path,res))
        end
        return self[k]
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
---@param imgTable table<any, string|table>
---## Example
---```lua
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
----- Then you can get image objects same as with get things from table, like this:
---local image1=IMG.image1
---local image3_1=IMG.imagePack.image3_1
---local image4_1=IMG.imagePack.image4[1]
---```
function IMG.init(imgTable)
    if initialized then
        MSG.new('info',"IMG.init(): Attempt to initialize IMG lib twice")
        return
    end
    initialized,IMG.init=true,nil
    link(IMG,imgTable)
end

return IMG
