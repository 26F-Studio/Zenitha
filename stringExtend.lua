local data=love.data
local assert,tostring,tonumber=assert,tostring,tonumber
local floor,format=math.floor,string.format
local find,sub,gsub=string.find,string.sub,string.gsub
local rep,upper=string.rep,string.upper
local char,byte=string.char,string.byte

local STRING={}

function STRING.install()-- Install stringExtend into the lua basic "string library", so that you can use these extended functions with `str:xxx(...)` format
    STRING.install=nil
    for k,v in next,STRING do
        string[k]=v
    end
end

function STRING.repD(str,...)-- "Replace dollars". Replace all $n with ..., like string.format
    local l={...}
    for i=#l,1,-1 do
        str=gsub(str,'$'..i,l[i])
    end
    return str
end

function STRING.sArg(str,switch)-- "Scan arg", scan if str has the arg (format of str is like '-json -q', arg is like '-q')
    if find(str..' ',switch..' ') then
        return true
    end
end

do-- function STRING.shiftChar(c)-- "Capitalize" a character like string.upper, but can also shift numbers to signs
    local shiftMap={
        ['1']='!',['2']='@',['3']='#',['4']='$',['5']='%',
        ['6']='^',['7']='&',['8']='*',['9']='(',['0']=')',
        ['`']='~',['-']='_',['=']='+',
        ['[']='{',[']']='}',['\\']='|',
        [';']=':',['\'']='"',
        [',']='<',['.']='>',['/']='?',
    }
    function STRING.shiftChar(c)
        return shiftMap[c] or upper(c)
    end
end

function STRING.trim(str)-- Trim %s at both ends of the string
    if not str:find('%S') then return'' end
    str=str:sub((str:find('%S'))):reverse()
    return str:sub((str:find('%S'))):reverse()
end

function STRING.split(str,sep,regex)-- Split a string by sep
    local L={}
    local p1=1-- start
    local p2-- target
    if regex then
        while p1<=#str do
            p2=find(str,sep,p1) or #str+1
            L[#L+1]=sub(str,p1,p2-1)
            p1=p2+#sep
        end
    else
        while p1<=#str do
            p2=find(str,sep,p1,true) or #str+1
            L[#L+1]=sub(str,p1,p2-1)
            p1=p2+#sep
        end
    end
    return L
end

function STRING.simpEmailCheck(str)-- Check if the string is a valid email address
    str=STRING.split(str,'@')
    if #str~=2 then return false end
    if str[1]:sub(-1)=='.' or str[2]:sub(-1)=='.' then return false end
    local e1,e2=STRING.split(str[1],'.'),STRING.split(str[2],'.')
    if #e1*#e2==0 then return false end
    for _,v in next,e1 do if #v==0 then return false end end
    for _,v in next,e2 do if #v==0 then return false end end
    return true
end

function STRING.time_simp(t)-- Convert time (second) to MM:SS
    return format('%02d:%02d',floor(t/60),floor(t%60))
end

function STRING.time(t)-- Convert time (second) to SS or MM:SS or HH:MM:SS
    if t<60 then
        return format('%.3f″',t)
    elseif t<3600 then
        return format('%d′%05.2f″',floor(t/60),floor(t%60*100)/100)
    else
        return format('%d:%.2d′%05.2f″',floor(t/3600),floor(t/60%60),floor(t%60*100)/100)
    end
end

function STRING.cutUnit(s)-- Warning: don't support number format like .26, must have digits before the dot, like 0.26
    local _s,_e=s:find('^-?%d+%.?%d*')
    if _e==#s then-- All numbers
        return tonumber(s),nil
    elseif not _s then-- No numbers
        return nil,s
    else
        return tonumber(s:sub(_s,_e)),s:sub(_e+1)
    end
end

function STRING.type(c)
    assert(type(c)=='string' and #c==1,'function STRING.type(c): c must be a single-charater string')
    local t=byte(c)
    if t==9 or t==10 or t==13 or t==32 then
        return 'space'
    elseif t>=48 and t<=57 or t>=65 and t<=90 or t>=97 and t<=122 then
        return 'word'
    elseif t>=33 and t<=47 or t>=58 and t<=64 or t>=91 and t<=96 or t>=123 and t<=126 then
        return 'sign'
    else
        return 'other'
    end
end

do-- function STRING.base64(num)-- Convert one number to base64
    STRING.base64={} for c in string.gmatch('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/','.') do
        table.insert(STRING.base64,c)
    end
    setmetatable(STRING.base64,{
        __call=function(self,k)
            return self[k]
        end,
        __index=function()
            error('function STRING.base64(num): num must be 1~64')
        end,
        __newindex=function()
            error('STRING.base64 is read-only')
        end,
        __metatable=true,
    })
end

function STRING.UTF8(num)-- Simple utf8 coding
    assert(type(num)=='number','Wrong type ('..type(num)..')')
    assert(num>=0 and num<2^31,'Out of range ('..num..')')
    if num<2^7 then return char(num)
    elseif num<2^11 then return char(192+floor(num/2^06),128+num%2^6)
    elseif num<2^16 then return char(224+floor(num/2^12),128+floor(num/2^06)%2^6,128+num%2^6)
    elseif num<2^21 then return char(240+floor(num/2^18),128+floor(num/2^12)%2^6,128+floor(num/2^06)%2^6,128+num%2^6)
    elseif num<2^26 then return char(248+floor(num/2^24),128+floor(num/2^18)%2^6,128+floor(num/2^12)%2^6,128+floor(num/2^06)%2^6,128+num%2^6)
    elseif num<2^31 then return char(252+floor(num/2^30),128+floor(num/2^24)%2^6,128+floor(num/2^18)%2^6,128+floor(num/2^12)%2^6,128+floor(num/2^06)%2^6,128+num%2^6)
    end
end

do-- function STRING.bigInt(num)-- Convert a number to a approximate integer with large unit
    local lg=math.log10
    local units={'','K','M','B','T','Qa','Qt','Sx','Sp','Oc','No'}
    local preUnits={'','U','D','T','Qa','Qt','Sx','Sp','O','N'}
    local secUnits={'Dc','Vg','Tg','Qd','Qi','Se','St','Og','Nn','Ce'}-- Ce is next-level unit, but DcCe is not used so used here
    for _,preU in next,preUnits do for _,secU in next,secUnits do table.insert(units,preU..secU) end end
    function STRING.bigInt(num)
        if num<1000 then
            return tostring(num)
        elseif num~=1e999 then
            local e=floor(lg(num)/3)
            return (num/10^(e*3))..units[e+1]
        else
            return 'INF'
        end
    end
end

do-- function STRING.toBin, STRING.toOct, STRING.toHex(num,len)
    function STRING.toBin(num,len)
        local s=''
        while num>0 do
            s=(num%2)..s
            num=floor(num/2)
        end
        return len and rep('0',len-#s)..s or s
    end
    function STRING.toOct(num,len)
        local s=''
        while num>0 do
            s=(num%8)..s
            num=floor(num/8)
        end
        return len and rep('0',len-#s)..s or s
    end
    local b16={[0]='0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}
    function STRING.toHex(num,len)
        local s=''
        while num>0 do
            s=b16[num%16]..s
            num=floor(num/16)
        end
        return len and rep('0',len-#s)..s or s
    end
end

do-- function STRING.urlEncode(str)-- Simple url encoding
    local rshift=bit.rshift
    local b16={[0]='0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    function STRING.urlEncode(str)
        local out=''
        for i=1,#str do
            if str:sub(i,i):match('[a-zA-Z0-9]') then
                out=out..str:sub(i,i)
            else
                local b=str:byte(i)
                out=out..'%'..b16[rshift(b,4)]..b16[b%16]
            end
        end
        return out
    end
end

function STRING.vcsEncrypt(text,key)-- Simple vcs encryption
    local keyLen=#key
    local result=''
    local buffer=''
    for i=0,#text-1 do
        buffer=buffer..char((byte(text,i+1)-32+byte(key,i%keyLen+1))%95+32)
        if #buffer==26 then
            result=result..buffer
            buffer=''
        end
    end
    return result..buffer
end
function STRING.vcsDecrypt(text,key)-- Simple vcs decryption
    local keyLen=#key
    local result=''
    local buffer=''
    for i=0,#text-1 do
        buffer=buffer..char((byte(text,i+1)-32-byte(key,i%keyLen+1))%95+32)
        if #buffer==26 then
            result=result..buffer
            buffer=''
        end
    end
    return result..buffer
end
function STRING.digezt(text)-- Return 16 byte string. Not powerful hash, just simply protect the original text
    local out={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local seed=26
    for i=1,#text do
        local c=byte(text,i)
        seed=(seed+c)%26
        c=c+seed
        local pos=c*i%16
        local step=(c+i)%4+1
        local times=2+(c%6)
        for _=1,times do
            out[pos+1]=(out[pos+1]+c)%256
            pos=(pos+step)%16
        end
    end
    local result=''
    for i=1,16 do result=result..char(out[i]) end
    return result
end

function STRING.readLine(str)-- Return [a line], [the rest of the string]
    local p=str:find('\n')
    if p then
        return str:sub(1,p-1),str:sub(p+1)
    else
        return str,''
    end
end
function STRING.readChars(str,n)-- Return [n characters], [the rest of the string]
    return sub(str,1,n),sub(str,n+1)
end

function STRING.packBin(str)-- Zlib+Base64
    return data.encode('string','base64',data.compress('string','zlib',str))
end
function STRING.unpackBin(str)
    local res
    res,str=pcall(data.decode,'string','base64',str)
    if not res then return end
    res,str=pcall(data.decompress,'string','zlib',str)
    if res then return str end
end
function STRING.packText(str)-- Gzip+Base64
    return data.encode('string','base64',data.compress('string','gzip',str))
end
function STRING.unpackText(str)
    local res
    res,str=pcall(data.decode,'string','base64',str)
    if not res then return end
    res,str=pcall(data.decompress,'string','gzip',str)
    if res then return str end
end
function STRING.packTable(t)-- JSON+Gzip+Base64
    return STRING.packText(JSON.encode(t))
end
function STRING.unpackTable(t)
    return JSON.decode(STRING.unpackText(t))
end

return STRING
