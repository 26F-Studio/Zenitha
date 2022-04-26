local initialized=false
local IMGlistMeta={
    __index=function(self,k)
        assert(self.__source[k],STRING.repD("No field '$1'",tostring(k)))
        local ok,res=pcall(love.graphics.newImage,self.__source[k])
        if ok then
            self[k]=res
        else
            self[k]=PAPER
            MES.new('error',STRING.repD("Cannot load image '$1': $2",self.__source[k],res))
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
local IMG={
    init=function(_list)
        if initialized then MES.new('info',"Achievement: attempt to initialize IMG lib twice") return end
        initialized,IMG.init=true,nil
        link(IMG,_list)
    end
}
return IMG
