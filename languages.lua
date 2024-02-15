---@type string|false
local defaultLang=false
local maxLangLoaded=3
local langLoaded={}
local langPaths={}

local langLib={
    [false]={},
}
setmetatable(langLib,{
    __index=function(self,k)
        local lang=FILE.load(langPaths[k],'-luaon')
        setmetatable(lang,{__index=langLib[k~=defaultLang and defaultLang]})
        self[k]=lang
        table.insert(langLoaded,k)
        if #langLoaded>maxLangLoaded then
            for i=1,#langLoaded do
                if langLoaded[i]~=defaultLang then
                    langLib[table.remove(langLoaded,i)]=nil
                    break
                end
            end
        end
        return self[k]
    end,
})
setmetatable(langLib[false],{
    __index=function(self,k)
        self[k]='['..k..']'
        return self[k]
    end,
})

local LANG={}

---Set the default language
---@param name string
function LANG.setDefault(name)
    assert(type(name)=='string',"LANG.setDefault(name): Need string")
    defaultLang=name
    for k,v in next,langLib do
        if k~=false then
            setmetatable(v,{__index=langLib[k~=defaultLang and defaultLang]})
        end
    end
end

---Set the max loaded language count
---@param n number
function LANG.setMaxLoaded(n)
    assert(type(n)=='number' and n>=1 and n%1==0,"LANG.setMaxLoaded(n): Need int >1")
    maxLangLoaded=n
end

---Add language file info list
---@param data table<string, string> name-path
function LANG.add(data)
    for k,v in next,data do
        assert(type(k)=='string' and type(v)=='string',"LANG.add(data): Need {zh='path1',en='path2',...}")
        langPaths[k]=v
    end
end

---Get a language table, which can be used to get texts like `languageTable.opt --> 'Option'`
---@param name string
---@return table
function LANG.get(name)
    return langLib[name]
end

local textSrc=langLib[false]

---Set the text function source
---@param newSrc table
function LANG.setTextFuncSrc(newSrc)
    assert(type(newSrc)=='table',"LANG.setTextFuncSrc(newSrc): Need table")
    textSrc=newSrc
end

---Shortcut of LANG.get+LANG.setTextFuncSrc, return the language table like LANG.get
---@param name string
---@return table
function LANG.set(name)
    LANG.setTextFuncSrc(LANG.get(name))
    return textSrc
end

local textFuncs=setmetatable({},{
    __index=function(self,k)
        self[k]=function() return textSrc[k] end
        return self[k]
    end,
})

---Get a text-getting function.
---
---You can use LANG('key') instead of LANG.getTextFunc('key')
---@param key string
---@return fun():string
function LANG.getTextFunc(key)
    return textFuncs[key]
end

setmetatable(LANG,{
    -- Works same as LANG.getTextFunc
    __call=function(_,key)
        return textFuncs[key]
    end,
    __metatable=true,
})
return LANG
