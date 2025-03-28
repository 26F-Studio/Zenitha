local data=love.data or {
    encode=NULL,
    compress=NULL,
    decompress=NULL,
    decode=NULL,
}
local type,assert,tostring,tonumber=type,assert,tostring,tonumber
local floor,min=math.floor,math.min
local log,lg=math.log,math.log10
local match,find,format=string.match,string.find,string.format
local sub,gsub=string.sub,string.gsub
local rep,rev=string.rep,string.reverse
local upper,lower=string.upper,string.lower
local char,byte=string.char,string.byte

---If you are sure that you won't need STRING.install() to use things like `str:trim()`,  
---you can delete the next line (---@class stringlib) to prevent this strEx lib extending the methods for class string
---@class stringlib
local STRING={}

for k,v in next,string do STRING[k]=v end

--------------------------------------------------------------
-- LuaJIT extension wrapper

local suc,buffer=pcall(require,'string.buffer')
if not suc then
    LOG('warn','Failed to load string.buffer module, using altBuffer')
    buffer=({require})[1]'Zenitha.altBuffer'
end

local buffer_new=buffer.new
local buf_put,buf_get do
    local buf=buffer_new()
    buf_put,buf_get=buf.put,buf.get
end

STRING.newBuf=buffer.new
STRING.encBuf=buffer.encode
STRING.decBuf=buffer.decode

--------------------------------------------------------------
-- Installer

---Install stringExtend into the lua basic "string library",
---so that you can use these extended functions with `str:xxx(...)` format
function STRING.install()
    function STRING.install() error("STRING.install: Attempt to install stringExtend library twice") end
    for k,v in next,STRING do
        string[k]=v
    end
end

---Install `str[n]` and `str[n]="c"` syntax. The editted string will be stored into STRING._
---
---Notice that `str[n]="ccc"` will removed the n-th character then put "ccc" into it, changing string length
---
---And will potentially make all `:` call (like `str:find(...)`) slightly slower than before
function STRING.installIndex()
    function STRING.installIndex() error("STRING.installIndex: Attempt to install stringIndex syntax twice") end
    local meta=getmetatable('')
    local string=string
    function meta.__index(str,n)
        if type(n)~='number' then
            return string[n]
        else
            return sub(str,n,n)
        end
    end
    STRING._='' -- Editted string stored here
    function meta.__newindex(str,n,c)
        STRING._=sub(str,1,n-1)..c..sub(str,n+1)
    end
end

---Install stringPath syntax. Warning: conflict with normal auto-tonumber operation
---
---`- "script/main.lua"` Get the file name from path  
---`"script" / "main.lua"` Combine folder and file name
---`"script/main.lua" - n` Get the level n directory name
---`"script/main.lua" % "lua,js"` Check if the file match the postfix
function STRING.installPath()
    function STRING.installPath() error("STRING.installPath: Attempt to install stringPath syntax twice") end
    local meta=getmetatable('')
    function meta.__unm(path) return match(path,".+/(.+)$") or path end
    function meta.__div(folder,file) return folder.."/"..file end
    function meta.__sub(path,layer)
        while layer>0 do
            path=match(path,"(.+)/") or path
            layer=layer-1
        end
        return path
    end
    function meta.__mod(file,postfixs)
        local postfix=match(file,"%.(.-)$")
        postfixs=STRING.split(postfixs,',')
        for i=1,#postfixs do
            if postfix==postfixs[i] then return true end
        end
        return false
    end
end

--------------------------------------------------------------
-- Builder (Util)

---Convert time (second) to "MM:SS"
---@param t number
---@return string
---@nodiscard
function STRING.time_simp(t)
    return format('%02d:%02d',floor(t/60),floor(t%60))
end

---Convert time (second) to seconds~year string (max 3 units)
---@param t number
---@return string
---@nodiscard
function STRING.time(t)
    return
        t<0 and "-0.000″" or
        t<60 and format('%.3f″',t) or
        t<3600 and format('%d′%05.2f″',floor(t/60),floor(t%60*100)/100) or
        t<86400 and format('%d:%.2d′%05.1f″',floor(t/3600),floor(t/60%60),floor(t%60*10)/10) or
        t<2629728 and format('%dd %d:%.2d′',floor(t/86400),floor(t/3600%3600),floor(t/60%60)) or
        t<31556736 and format('%dm%dd%dh',floor(t/2629728),floor(t/86400%86400),floor(t/3600%3600)) or
        t<3155673600 and format('%dy%dm%dd',floor(t/31556736),floor(t/2629728%2629728),floor(t/86400%86400)) or
        format('%.2fcentury',floor(t/3155673600))
end

local byteUnits={[0]=" B"," KB"," MB"," GB"," TB"," PB"," EB"," ZB"," YB"}
---Convert a file size number to readable string  
---input `2^26` --> `"64 MB"`
---@param s number number in byte
---@nodiscard
function STRING.fileSize(s)
    if s<=0 then
        return "0 B"
    else
        local u=floor(log(s,1024)+1e-6)
        local n=1024^u
        local digits=floor(lg(s/n))+1
        return format('%g%s',floor(s/n*10^(3-digits))/10^(3-digits),byteUnits[u])
    end
end

local numUnits={'','K','M','B','T','Qa','Qt','Sx','Sp','Oc','No'}
local preNumUnits={'','U','D','T','Qa','Qt','Sx','Sp','O','N'}
local secNumUnits={'Dc','Vg','Tg','Qd','Qi','Se','St','Og','Nn','Ce'} -- Ce is next-level unit, but DcCe is not used so used here
for _,preU in next,preNumUnits do for _,secU in next,secNumUnits do table.insert(numUnits,preU..secU) end end
---Convert a positive integer to a approximate integer with large unit
---@param num number
---@return string
---@nodiscard
function STRING.bigInt(num)
    if num<1000 then
        return tostring(num)
    elseif num~=1e999 then
        local e=floor(lg(num)/3)
        return (num/10^(e*3))..numUnits[e+1]
    else
        return 'INF'
    end
end

---Simple vcs encryption
---@param text string
---@param key string
---@return string
---@nodiscard
function STRING.vcsEncrypt(text,key)
    local keyLen=#key
    local buf=buffer_new(#text)
    for i=1,#text do
        buf_put(buf,char((byte(text,i)-32+byte(key,(i-1)%keyLen+1))%95+32))
    end
    return buf_get(buf)
end

---Simple vcs decryption
---@param text string
---@param key string
---@return string
---@nodiscard
function STRING.vcsDecrypt(text,key)
    local keyLen=#key
    local buf=buffer_new(#text)
    for i=1,#text do
        buf_put(buf,char((byte(text,i)-32-byte(key,(i-1)%keyLen+1))%95+32))
    end
    return buf_get(buf)
end

---Return 16 byte string. Not powerful hash, just simply protect the original text
---@param text string
---@param seedRange? integer default to 26
---@param seed? integer default to 0
---@return string
---@nodiscard
function STRING.digezt(text,seedRange,seed)
    if not seed then seed=0 end
    if not seedRange then seedRange=26 end
    local out={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

    for i=1,#text do
        local c=byte(text,i)
        seed=(seed+c)%seedRange
        c=c+seed
        local pos=c*i%16
        local step=(c+i)%4+1
        local times=2+(c%6)
        for _=1,times do
            out[pos+1]=(out[pos+1]+c)%256
            pos=(pos+step)%16
        end
    end
    local result=buffer_new(16)
    for i=1,16 do result:put(char(out[i])) end
    return result:get()
end

---Split a string by sep
---@param str string
---@param sep string
---@param regex? boolean
---@return string[]
---@nodiscard
function STRING.split(str,sep,regex)
    local L={}
    local p1=1 -- start
    local p2 -- target
    if regex then
        while p1<=#str do
            local p3
            p2,p3=find(str,sep,p1)
            if not p2 then
                L[#L+1]=sub(str,p1,#str)
                break
            end
            L[#L+1]=sub(str,p1,p2-1)
            p1=p3+1
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

---Split a string into single-byte strings
---@return char[]
---@nodiscard
function STRING.atomize(str)
    local l={}
    for i=1,#str do
        l[i]=sub(str,i,i)
    end
    return l
end

--------------------------------------------------------------
-- Edit (Util)

---Replace dollars. Replace all $n with ..., like string.format
---@param str string
---@param ... any
---@return string
---@nodiscard
function STRING.repD(str,...)
    local l={...}
    for i=#l,1,-1 do
        str=gsub(str,'$'..i,l[i])
    end
    return str
end

---Paste new string into original string, won't exceed the length of original string
---@param str1 string original string
---@param str2 string new string
---@param pos integer start position to paste
---@return string
---@nodiscard
function STRING.paste(str1,str2,pos)
    if pos<2-#str2 or pos>#str1 or str2=='' then
        return str1
    else
        local maxPos=#str1-#str2+1
        if pos<0 then pos=pos+#str1+1 end
        if pos<1 then
            str2=sub(str2,2-pos)
            return str2..sub(str1,1+#str2)
        elseif pos>maxPos then
            return sub(str1,1,pos-1)..sub(str2,1,maxPos-pos-1)
        else
            return sub(str1,1,pos-1)..str2..sub(str1,pos+#str2)
        end
    end
end

local shiftMap={
    ['1']='!',['2']='@',['3']='#',['4']='$',['5']='%',
    ['6']='^',['7']='&',['8']='*',['9']='(',['0']=')',
    ['`']='~',['-']='_',['=']='+',
    ['[']='{',[']']='}',['\\']='|',
    [';']=':',['\'']='"',
    [',']='<',['.']='>',['/']='?',
}
---Single-byte string.upper, but can also shift numbers to signs
---@param str char
---@return string
---@nodiscard
function STRING.shift(str)
    return shiftMap[str] or upper(str)
end

local unshiftMap={
    ['!']='1',['@']='2',['#']='3',['$']='4',['%']='5',
    ['^']='6',['&']='7',['*']='8',['(']='9',[')']='0',
    ['~']='`',['_']='-',['+']='=',
    ['{']='[',['}']=']',['|']='\\',
    [':']=';',['"']='\'',
    ['<']=',',['>']='.',['?']='/',
}
---Single-byte string.lower, but can also unshift signs to numbers
---@param str char
---@return string
---@nodiscard
function STRING.unshift(str)
    return unshiftMap[str] or lower(str)
end

---Trim %s at both ends of the string
---@param str string
---@return string
---@nodiscard
function STRING.trim(str)
    -- local p=find(str,'%S')
    -- if not p then return '' end
    -- str=rev(sub(str,p))
    -- return rev(sub(str,(find(str,'%S'))))
    return match(str,"^%s*(.-)%s*$") or ""
end

---Remove all non-ASCII characters
---@param str string
---@return string
function STRING.filterASCII(str)
    return (gsub(str,'[^%z%s\x21-\x7E]',''))
end

---Trim spaces and tabs at the beginning of all lines, useful for inline multi-line strings  
---(Will remove ending \n)
---### Example
---```
---do
---    local s=STRING.trimIndent[=[
---        Hello
---        World
---    ]=] --> "Hello\nWorld"
---end
---```
---@param str string
---@param keep? boolean | integer Max number of leading spaces to be trimmed: `nil`- all  `number` - as you want  `true` - same with line#1
---@return string
---@nodiscard
function STRING.trimIndent(str,keep)
    if keep then
        local list=STRING.split(str,'\n')
        local s=keep==nil and 1e99 or type(keep)=='number' and keep+1 or #list[1]:match('^%s*')+1
        if s==1 then return str end

        for i=1,#list do
            list[i]=sub(list[i],min(s,find(list[i],'%S') or #list[i]+1))
        end
        return table.concat(list,'\n')
    else
        return (gsub('\n'..str,'\n[ \t]+','\n'):sub(2))
    end
end

---Get string before pattern
---@param str string
---@param sep string
---@param regex? boolean
---@return string?
---@nodiscard
function STRING.before(str,sep,regex)
    local p=find(str,sep,1,regex)
    if p then return sub(str,1,p-1) end
end

---Get string after pattern
---@param str string
---@param sep string
---@param regex? boolean
---@return string?
---@nodiscard
function STRING.after(str,sep,regex)
    local _,p=find(str,sep,1,regex)
    if p then return sub(str,p+1) end
end

---**Warning:** don't support number format like .26, must have digits before the dot, like 0.26
---@param str string
---@return integer | nil, string | nil
---@nodiscard
function STRING.cutUnit(str)
    local _s,_e=find(str,'^-?%d+%.?%d*')
    if _e==#str then -- All numbers
        return tonumber(str),nil
    elseif not _s then -- No numbers
        return nil,str
    else
        return tonumber(sub(str,_s,_e)),sub(str,_e+1)
    end
end

local b16=STRING.atomize('123456789ABCDEF') b16[0]='0'
---Simple url encoding
---@param str string
---@return string
---@nodiscard
function STRING.urlEncode(str)
    local buf=buffer_new()
    for i=1,#str do
        if match(sub(str,i,i),'[a-zA-Z0-9]') then
            buf_put(buf,sub(str,i,i))
        else
            local b=byte(str,i)
            buf_put(buf,'%'..b16[bit.rshift(b,4)]..b16[b%16])
        end
    end
    return buf_get(buf)
end

---Cut a line off a string
---@param str string
---@return string, string #One line (do not include \n), and the rest of string
---@nodiscard
function STRING.readLine(str)
    local p=find(str,'\n')
    if p then
        return sub(str,1,p-1),sub(str,p+1)
    else
        return str,''
    end
end

---Shorten a path by cutting off long directory name
---### Example
---```
---STRING.simplifyPath('Documents/Project/xxx.lua') --> 'D/P/xxx.lua'
---STRING.simplifyPath('Documents/Project/xxx.lua',3) --> 'Doc/Pro/xxx.lua'
---```
---@param path string
---@param len? integer default to 1
---@return string
---@nodiscard
function STRING.simplifyPath(path,len)
    local l=STRING.split(path,'/')
    for i=1,#l-1 do l[i]=sub(l[i],1,len or 1) end
    return table.concat(l,'/')
end

--------------------------------------------------------------
-- Parse (Util)

---Scan arg, scan if str has the arg (format of str is like `'-json -q'`, switch is like `'-q'`)
---@param str string
---@param switch string
---@return boolean
---@nodiscard
function STRING.sArg(str,switch)
    if find(str..' ',switch..' ') then
        return true
    else
        return false
    end
end

---Count the number of occurrences of a regex pattern in a string
---@param str string
---@param regex string
---@return integer
---@nodiscard
function STRING.count(str,regex)
    local _,count=gsub(str,regex,'')
    return count
end

---Calculate the edit distance between two strings
---@param s1 string
---@param s2 string
---@return integer
---@nodiscard
function STRING.editDist(s1,s2) -- By Copilot
    local len1,len2=#s1,#s2
    local t1,t2={},{}
    for i=1,len1 do t1[i]=s1:sub(i,i) end
    for i=1,len2 do t2[i]=s2:sub(i,i) end

    local dp={}
    for i=0,len1 do dp[i]={} for j=0,len2 do dp[i][j]=0 end end
    dp[0][0]=0
    for i=1,len1 do dp[i][0]=i end
    for i=1,len2 do dp[0][i]=i end

    for i=1,len1 do
        for j=1,len2 do
            dp[i][j]=t1[i]==t2[j] and dp[i-1][j-1] or min(dp[i-1][j],dp[i][j-1],dp[i-1][j-1])+1
        end
    end
    return dp[len1][len2]
end

---Check if the string is a valid email address
---@param str string
---@return boolean
---@nodiscard
function STRING.simpEmailCheck(str)
    local list=STRING.split(str,'@')
    if #list~=2 then return false end
    if sub(list[1],-1)=='.' or sub(list[2],-1)=='.' then return false end
    local e1,e2=STRING.split(list[1],'.'),STRING.split(list[2],'.')
    if #e1*#e2==0 then return false end
    for _,v in next,e1 do if #v==0 then return false end end
    for _,v in next,e2 do if #v==0 then return false end end
    return true
end

---Get the type of a character
---@param c string
---@return 'space' | 'word' | 'sign' | 'other'
---@nodiscard
function STRING.type(c)
    assert(type(c)=='string' and #c==1,"Need single-charater string")
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

---Parse binary number from string
---@param str string
---@return number
---@nodiscard
function STRING.binNum(str)
    assert(type(str)=='string',"STRING.binNum: Need string")
    local size=#str
    assert(size<=8,"Too long data")
    local num=byte(str,1)
    for i=2,size do
        num=num*256+byte(str,i)
    end
    -- if signed then
    --     local huge=2^(size*8-1)
    --     if num>=huge then
    --         num=num-huge*2
    --     end
    -- end
    return num
end

--------------------------------------------------------------
---Base conversion

local baseN=STRING.atomize('123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ') baseN[0]='0'
---Convert a integer to string with any base
---@param num number
---@param base integer
---@param len? integer target number of digits
---@return string
---@nodiscard
function STRING.toBase(num,base,len)
    local buf=buffer_new()
    local neg
    if num<0 then
        neg=true
        num=-num
    end
    assert(base>0,"STRING.toBase: Base must be positive integer")
    if base<10 then
        while num>0 do
            buf_put(buf,num%base)
            num=floor(num/base)
        end
    else
        while num>0 do
            buf_put(buf,baseN[num%base])
            num=floor(num/base)
        end
    end
    if len then buf_put(buf,rep('0',len-#buf)) end
    if neg then buf_put(buf,'-') end
    return rev(buf_get(buf))
end

---Convert a integer to binary string  
---Short cut, `STRING.toBase(num,2,len)`
---@param num number
---@param len? integer
---@return string
---@nodiscard
function STRING.toBin(num,len)
    return STRING.toBase(num,2,len)
end

---Convert a integer to octal string  
---Short cut, `STRING.toBase(num,8,len)`
---@param num number
---@param len? integer
---@return string
---@nodiscard
function STRING.toOct(num,len)
    return STRING.toBase(num,8,len)
end

---Convert an integer to hexadecimal string  
---Short cut, `STRING.toBase(num,16,len)`
---@param num number
---@param len? integer
---@return string
---@nodiscard
function STRING.toHex(num,len)
    return STRING.toBase(num,16,len)
end

--------------------------------------------------------------
-- Pack & Unpack

---Pack binary data into string (Zlib+Base64)
---@param str string
---@return string
---@nodiscard
function STRING.packBin(str)
    ---@type string
    return data.encode('string','base64',data.compress('string','zlib',str))
end

---Unpack binary data from string (Zlib+Base64)
---@param str string
---@return string | any
---@nodiscard
function STRING.unpackBin(str)
    return data.decompress('string','zlib',data.decode('string','base64',str))
end

---Pack text data into string (Gzip+Base64)
---@param str string
---@return string
---@nodiscard
function STRING.packText(str)
    ---@type string
    return data.encode('string','base64',data.compress('string','gzip',str))
end

---Unpack text data from string (Gzip+Base64)
---@param str string
---@return string | any
---@nodiscard
function STRING.unpackText(str)
    return data.decompress('string','gzip',data.decode('string','base64',str))
end

---Pack table into string (JSON+Gzip+Base64)
---@param t table
---@return string
---@nodiscard
function STRING.packTable(t)
    return STRING.packText(JSON.encode(t))
end

---Unpack table from string (JSON+Gzip+Base64)
---@param str string
---@return table
---@nodiscard
function STRING.unpackTable(str)
    return JSON.decode(STRING.unpackText(str))
end

--------------------------------------------------------------
-- UTF8 wrapper

local utf8=require'utf8'

---Simple utf8 coding
---@param num integer
---@return string
---@nodiscard
function STRING.UTF8(num)
    assertf(type(num)=='number',"Wrong type (%s)",type(num))
    assertf(num>=0 and num<2^31,"Out of range (%d)",num)
    -- if     num<2^7  then return char(num)
    -- elseif num<2^11 then return char(192+floor(num/2^06),128+num%2^6)
    -- elseif num<2^16 then return char(224+floor(num/2^12),128+floor(num/2^06)%2^6,128+num%2^6)
    if num<0x10ffff then return utf8.char(num)
    elseif num<2^21 then return char(240+floor(num/2^18),128+floor(num/2^12)%2^6,128+floor(num/2^06)%2^6,128+num%2^6)
    elseif num<2^26 then return char(248+floor(num/2^24),128+floor(num/2^18)%2^6,128+floor(num/2^12)%2^6,128+floor(num/2^06)%2^6,128+num%2^6)
    else                 return char(252+floor(num/2^30),128+floor(num/2^24)%2^6,128+floor(num/2^18)%2^6,128+floor(num/2^12)%2^6,128+floor(num/2^06)%2^6,128+num%2^6)
    end
end

---Get the (unicode) char count of (part of) a utf8 string
---@param str string an utf8 string
---@param i? integer start byte (cannot start from middle of a char)
---@param j? integer end byte
---@param lax? boolean
---@nodiscard
---@diagnostic disable-next-line
function STRING.u8len(str,i,j,lax) end
STRING.u8len=utf8[('len')]

---Get a utf8 string with codepoint numbers
---@param ... integer
---@return string
---@nodiscard
---@diagnostic disable-next-line
function STRING.u8char(...) end
STRING.u8char=utf8[('char')]

---Get the codepoint(s) of a utf8 string
---@param str string
---@param i? integer start byte (cannot start from middle of a char)
---@param j? integer end byte
---@param lax? boolean
---@return integer ...
---@nodiscard
---@diagnostic disable-next-line
function STRING.u8byte(str,i,j,lax) end
STRING.u8byte=utf8[('codepoint')]

---Starting from `i` byte, get the start byte of `n` utf8 characters
---@param str string
---@param n integer char count
---@param i? integer start byte
---@return integer p end byte
---@nodiscard
---@diagnostic disable-next-line
function STRING.u8offset(str,n,i) end
STRING.u8offset=utf8[('offset')]

---Get a char iterator function of a utf8 string, similar to `str:gmatch('.')`
---
--- ```
--- for bytePos,codepoint in STRING.u8codes(str) do
---    -- code here
--- end
---@param str string
---@param lax? boolean
---@return fun(s:string, p:integer): integer,integer
---@diagnostic disable-next-line
function STRING.u8codes(str,lax) end
STRING.u8codes=utf8[('codes')]

---Matches exactly one UTF-8 byte sequence, assuming that the subject is a valid UTF-8 string
STRING.u8pattern="[\0-\x7F\xC2-\xFD][\x80-\xBF]*"

--------------------------------------------------------------
-- UTF8 util

local upperData,lowerData,diaData do
    local split=STRING.split
    local function parseStrPair(fname)
        local d
        if love and love.filesystem and type(love.filesystem.read)=='function' then
            d=love.filesystem.read(fname)
        else
            local f=io.open(fname,'r')
            if f then
                d=f:read('a')
                f:close()
            end
        end

        if not d then
            print("ERROR: Failed to read the data from "..fname)
            return {}
        end
        d=split(gsub(d,'\n',','),',')
        ---@cast d any
        for i=1,#d do
            d[i]=split(d[i],'=')
        end
        return d
    end
    upperData=parseStrPair(ZENITHA.path..'upcaser.txt')
    lowerData=parseStrPair(ZENITHA.path..'lowcaser.txt')
    diaData=parseStrPair(ZENITHA.path..'diacritics.txt')
end

---string.upper with utf8 support, warning: very low performance, 
---@param str string
---@return string
---@nodiscard
function STRING.upperUTF8(str)
    for i=1,#upperData do
        local pair=upperData[i]
        str=gsub(str,pair[1],pair[2])
    end
    return str
end

---string.lower with utf8 support, warning: very low performance, 
---@param str string
---@return string
---@nodiscard
function STRING.lowerUTF8(str)
    for i=1,#lowerData do
        local pair=lowerData[i]
        str=gsub(str,pair[1],pair[2])
    end
    return str
end

---remove diacritics, warning: low performance
---@param str string
---@return string
---@nodiscard
function STRING.remDiacritics(str)
    for _,pair in next,diaData do
        str=gsub(str,pair[1],pair[2])
    end
    return str
end

--------------------------------------------------------------
-- Table

STRING.base64=STRING.atomize('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/')
STRING._b16=b16
STRING._byteUnits=byteUnits
STRING._numUnits=numUnits
STRING._preNumUnits=preNumUnits
STRING._secNumUnits=secNumUnits

return STRING
