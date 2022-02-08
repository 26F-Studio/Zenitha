local initialized=false
local IMGlistMeta={__index=function(self,k)
    local ok,res=pcall(love.graphics.newImage,self.assert(self.__source[k],STRING.repD("No field '$1'",tostring(k))))
    if ok then
        self[k]=res
        return res
    else
        MES.new('error',STRING.repD("Cannot load image '$1': $2",self.__source[k],res))
    end
end}
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
local IMG={
    init=function(_list)
        assert(not initialized,"Achievement: attempt to initialize IMG lib twice")
        initialized,IMG.init=true
        link(IMG,_list)
    end
}
return IMG
