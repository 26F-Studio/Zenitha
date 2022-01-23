local defaultLang=false
local maxLangLoaded=3
local langLoaded={}
local langPaths={}
local langLib={
    [false]={},
}
setmetatable(langLib,{
    __index=function(self,k)
        local lang=FILE.read(langPaths[k],'-luaon')
        setmetatable(lang,{__index=langLib[k~=defaultLang and defaultLang]})
        self[k]=lang
        table.insert(langLoaded,k)
        if #langLoaded>maxLangLoaded then
            langLib[table.remove(langLoaded,1)]=nil
        end
        return self[k]
    end
})
setmetatable(langLib[false],{
    __index=function(self,k)
        self[k]='['..k..']'
        return self[k]
    end
})

local LANG={}
function LANG.setDefault(name)
    assert(type(name)=='string','Invalid language name')
    defaultLang=name
    for k,v in next,langLib do
        setmetatable(v,{__index=langLib[k~=defaultLang and defaultLang]})
    end
end
function LANG.setMaxLoaded(n)
    assert(type(n)=='number' and n>=1 and n%1==0,'Invalid number')
    maxLangLoaded=n
end
function LANG.add(data)
    for k,v in next,data do
        assert(type(k)=='string','Invalid language name (need string)')
        assert(type(v)=='string','Invalid language file path (need string)')
        langPaths[k]=v
    end
end
function LANG.get(name)
    return langLib[name]
end
return LANG
