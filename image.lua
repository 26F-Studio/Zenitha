local IMG={}

local initialized=false
local IMGlistMeta={
    __index=function(self,k)
        assert(self.__source[k],STRING.repD("No field '$1'",tostring(k)))
        local ok,res=pcall(love.graphics.newImage,self.__source[k])
        if ok then
            self[k]=res
        else
            self[k]=PAPER
            MSG.new('error',STRING.repD("Cannot load image '$1': $2",self.__source[k],res))
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

--- Initialize IMG lib (only once)
--- @param imgTable table<any,string|table> @<path string you like, filePath|recursed table>
--- ## Example
--- ```lua
--- IMG.init{
---     image1='.../image1.jpg',
---     image2='.../image2.png',
---     imagePack={
---         image3_1='.../image3/1.jpg',
---         image3_2='.../image3/2.jpg',
---         image4={
---             '.../image4/1.png',
---             '.../image4/2.png',
---         },
---     },
--- }
--- -- Then you can get image objects same as with get things from table, like this:
--- local image1=IMG.image1
--- local image3_1=IMG.imagePack.image3_1
--- local image4_1=IMG.imagePack.image4[1]
--- ```
function IMG.init(imgTable)
    if initialized then MSG.new('info',"Achievement: attempt to initialize IMG lib twice") return end
    initialized,IMG.init=true,nil
    link(IMG,imgTable)
end

return IMG
