local gc=love.graphics
local kb=love.keyboard
local ins,rem=table.insert,table.remove

local outputBox=WIDGET.new{type='textBox',x=20,y=20,w=999,h=999,fontSize=25,fontType='_basic',lineHeight=25,fixContent=true}
local inputBox=WIDGET.new{type='inputBox',x=20,y=999,w=999,h=80,fontType='_basic'}

local function log(str)outputBox:push(str) end

log{COLOR.lP,"Zenitha Console"}
log{COLOR.lC,"© Copyright 2019–2022 26F Studio. Some rights reserved."}
log{COLOR.dR,"WARNING: DO NOT RUN ANY CODE THAT YOU DON'T UNDERSTAND."}

local history,hisPtr={"?"},false
local sumode=false

local commands={} do
    --[[ format of table 'commands':
        key: the command name
        value: a table containing the following two elements:
            code: code to run when call
            description: a string that shows when user types 'help'.
            details: an array of strings containing documents, shows when user types 'help [command]'.
    ]]

    local cmdList={}-- List of all non-alias commands

    -- Basic
    commands.help={
        code=function(arg)-- Initial version by user670
            if #arg>0 then
                -- help [command]
                if commands[arg] then
                    if commands[arg].description then
                        log{COLOR.LD,("%s"):format(commands[arg].description)}
                    end
                    if commands[arg].details then
                        for _,v in ipairs(commands[arg].details) do log(v) end
                    else
                        log{COLOR.Y,("No details for command '%s'"):format(arg)}
                    end
                else
                    log{COLOR.Y,("No command called '%s'"):format(arg)}
                end
            else
                -- help
                for i=1,#cmdList do
                    local cmd=cmdList[i]
                    local body=commands[cmd]
                    log(
                        body.description and
                            {COLOR.L,cmd,COLOR.LD,STRING.repD(" $1 $2",("·"):rep(16-#cmd),body.description)}
                        or
                            log{COLOR.L,cmd}
                    )
                end
            end
        end,
        description="Display help messages",
        details={
            "Display help messages.",
            "",
            "Aliases: help ?",
            "",
            "Usage:",
            "help",
            "help [command_name]",
        },
    }commands["?"]="help"
    commands["#"]={
        description="Run arbitrary Lua code",
        details={
            "Run arbitrary Lua code.",
            "",
            "Usage: #[lua_source_code]",
            "",
            "print() can be used to print text into this window.",
        },
    }
    commands.exit={
        code=WIDGET.c_backScn,
        description="Return to the last menu",
        details={
            "Return to the last menu.",
            "",
            "Aliases: exit quit",
            "",
            "Usage: exit",
        },
    }commands.quit="exit"
    commands.echo={
        code=function(str) if str~="" then log(str) end end,
        description="Print a message",
        details={
            "Print a message to this window.",
            "",
            "Usage: echo [message]",
        },
    }
    commands.cls={
        code=function() outputBox:clear() end,
        description="Clear the window",
        details={
            "Clear the log output.",
            "",
            "Usage: cls",
        },
    }

    -- File
    do-- tree
        local function tree(path,name,depth)
            local info=love.filesystem.getInfo(path..name)
            if info.type=='file' then
                log(("\t\t"):rep(depth)..name)
            elseif info.type=='directory' then
                log(("\t\t"):rep(depth)..name..">")
                local L=love.filesystem.getDirectoryItems(path..name)
                for _,subName in next,L do
                    tree(path..name.."/",subName,depth+1)
                end
            else
                log("Unknown item type: %s (%s)"):format(name,info.type)
            end
        end
        commands.tree={
            code=function()
                local L=love.filesystem.getDirectoryItems''
                for _,name in next,L do
                    if not FILE.isSafe(name) then
                        tree('',name,0)
                    end
                end
            end,
            description="List all files & directories",
            details={
                "List all files & directories in saving directory",
                "",
                "Usage: tree",
            },
        }
    end
    do-- del
        local function delFile(name)
            if love.filesystem.remove(name) then
                log{COLOR.Y,("Deleted: '%s'"):format(name)}
            else
                log{COLOR.R,("Failed to delete: '%s'"):format(name)}
            end
        end
        local function delDir(name)
            if #love.filesystem.getDirectoryItems(name)==0 then
                if love.filesystem.remove(name) then
                    log{COLOR.Y,("Directory deleted: '%s'"):format(name)}
                else
                    log{COLOR.R,("Failed to delete directory '%s'"):format(name)}
                end
            else
                log{COLOR.R,"Directory '"..name.."' is not empty"}
            end
        end
        local function recursiveDelDir(dir)
            local containing=love.filesystem.getDirectoryItems(dir)
            if #containing==0 then
                if love.filesystem.remove(dir) then
                    log{COLOR.Y,("Succesfully deleted directory '%s'"):format(dir)}
                else
                    log{COLOR.R,("Failed to delete directory '%s'"):format(dir)}
                end
            else
                for _,name in next,containing do
                    local path=dir.."/"..name
                    local info=love.filesystem.getInfo(path)
                    if info then
                        if info.type=='file' then
                            delFile(path)
                        elseif info.type=='directory' then
                            recursiveDelDir(path)
                        else
                            log("Unknown item type: %s (%s)"):format(name,info.type)
                        end
                    end
                end
                delDir(dir)
            end
        end
        commands.del={
            code=function(name)
                local recursive=name:sub(1,3)=="-s "
                if recursive then
                    name=name:sub(4)
                end

                if name~='' then
                    local info=love.filesystem.getInfo(name)
                    if info then
                        if info.type=='file' then
                            if not recursive then
                                delFile(name)
                            else
                                log{COLOR.R,("'%s' is not a directory."):format(name)}
                            end
                        elseif info.type=='directory' then
                            (recursive and recursiveDelDir or delDir)(name)
                        else
                            log("Unknown item type: %s (%s)"):format(name,info.type)
                        end
                    else
                        log{COLOR.R,("No file called '%s'"):format(name)}
                    end
                else
                    log{COLOR.I,"Usage: del [filename|dirname]"}
                    log{COLOR.I,"Usage: del -s [dirname]"}
                end
            end,
            description="Delete a file or directory",
            details={
                "Attempt to delete a file or directory (in saving directory)",
                "",
                "Aliases: del rm",
                "",
                "Usage: del [filename|dirname]",
                "Usage: del -s [dirname]",
            }
        }
        commands.rm=commands.del
    end
    commands.mv={
        code=function(arg)
            -- Check arguments
            arg=arg:split(" ")
            if #arg>2 then
                log{COLOR.lY,"Warning: file names must have no spaces"}
                return
            elseif #arg<2 then
                log{COLOR.I,"Usage: ren [oldfilename] [newfilename]"}
                return
            end

            -- Check file exist
            local info
            info=love.filesystem.getInfo(arg[1])
            if not (info and info.type=='file') then
                log{COLOR.R,("'%s' is not a file!"):format(arg[1])}
                return
            end
            info=love.filesystem.getInfo(arg[2])
            if info then
                log{COLOR.R,("'%s' already exists!"):format(arg[2])}
                return
            end

            -- Read file
            local data,err1=love.filesystem.read('data',arg[1])
            if not data then
                log{COLOR.R,("Failed to read file '%s': "):format(arg[1],err1 or "Unknown error")}
                return
            end

            -- Write file
            local res,err2=love.filesystem.write(arg[2],data)
            if not res then
                log{COLOR.R,("Failed to write file: "):format(err2 or "Unknown error")}
                return
            end

            -- Delete file
            if not love.filesystem.remove(arg[1]) then
                log{COLOR.R,("Failed to delete old file ''"):format(arg[1])}
                return
            end

            log{COLOR.Y,("Succesfully renamed file '%s' to '%s'"):format(arg[1],arg[2])}
        end,
        description="Rename or move a file (in saving directory)",
        details={
            "Rename or move a file (in saving directory)",
            {COLOR.lY,"Warning: file name with space is not allowed"},
            "",
            "Aliases: mv ren",
            "",
            "Usage: mv [oldfilename] [newfilename]",
        },
    }commands.ren="mv"
    commands.print={
        code=function(name)
            if name~='' then
                local info=love.filesystem.getInfo(name)
                if info then
                    if info.type=='file' then
                        log{COLOR.lC,"/* "..name.." */"}
                        for l in love.filesystem.lines(name) do
                            log(l)
                        end
                        log{COLOR.lC,"/* END */"}
                    else
                        log{COLOR.R,("Unprintable item: %s (%s)"):format(name,info.type)}
                    end
                else
                    log{COLOR.R,("No file called '%s'"):format(name)}
                end
            else
                log{COLOR.I,"Usage: print [filename]"}
            end
        end,
        description="Print file content",
        details={
            "Print a file to this window.",
            "",
            "Usage: print [filename]",
        },
    }

    -- System
    commands.crash={
        code=function() error("ERROR") end,
        description="Manually crash the game",
        details={
            "Manually crash the game",
            "",
            "Usage: crash",
        },
    }
    commands.mes={
        code=function(arg)
            if
                arg=='check' or
                arg=='info' or
                arg=='broadcast' or
                arg=='warn' or
                arg=='error'
            then
                MES.new(arg,"Test message",6)
            else
                log{COLOR.I,"Show a message on the up-left corner"}
                log""
                log{COLOR.I,"Usage: mes <check|info|broadcast|warn|error>"}
            end
        end,
        description="Show a message",
        details={
            "Show a message on the up-left corner",
            "",
            "Usage: mes <check|info|warn|error>",
        },
    }
    commands.log={
        code=function()
            local l=LOG.getLogs()
            for i=1,#l do
                log(l[i])
            end
        end,
        description="Show the logs",
        details={
            "Show the logs",
            "",
            "Usage: log",
        },
    }
    commands.openurl={
        code=function(url)
            if url~="" then
                local res,err=pcall(love.system.openURL,url)
                if not res then
                    log{COLOR.R,"[ERR] ",COLOR.L,err}
                end
            else
                log{COLOR.I,"Usage: openurl [url]"}
            end
        end,
        description="Open a URL",
        details={
            "Attempt to open a URL with your device.",
            "",
            "Usage: openurl [url]",
        },
    }
    commands.scrinfo={
        code=function()
            for _,v in next,SCR.info() do
                log(v)
            end
        end,
        description="Display window info.",
        details={
            "Display information about the game window.",
            "",
            "Usage: scrinfo",
        },
    }
    commands.wireframe={
        code=function(bool)
            if bool=="on" or bool=="off" then
                gc.setWireframe(bool=="on")
                log("Wireframe: "..(gc.isWireframe() and "on" or "off"))
            else
                log{COLOR.I,"Usage: wireframe <on|off>"}
            end
        end,
        description="Turn on/off wireframe mode",
        details={
            "Enable or disable wireframe drawing mode.",
            "",
            "Usage: wireframe <on|off>",
        },
    }
    commands.gammacorrect={
        code=function(bool)
            if bool=="on" or bool=="off" then
                love['_setGammaCorrect'](bool=="on")
                log("GammaCorrect: "..(gc.isGammaCorrect() and "on" or "off"))
            else
                log{COLOR.I,"Usage: gammacorrect <on|off>"}
            end
        end,
        description="Turn on/off gamma correction",
        details={
            "Enable or disable gamma correction.",
            "",
            "Usage: gammacorrect <on|off>",
        },
    }
    commands.fn={
        code=function(n)
            n=tonumber(n)
            if n and n%1==0 and n>=1 and n<=12 then
                love.keypressed("f"..n)
            else
                log{COLOR.I,"Usage: fn [1~12]"}
            end
        end,
        description="Simulates a Function key press",
        details={
            "Acts as if you have pressed a function key (i.e. F1-F12) on a keyboard.",
            "Useful if you are on a mobile device without access to these keys.",
            "",
            "Usage: fn <1-12>",
        },
    }
    commands.playbgm={
        code=function(bgm)
            if bgm~='' then
                BGM.play(bgm)
            else
                log{COLOR.I,"Usage: playbgm [bgmName]"}
            end
        end,
        description="Play a BGM",
        details={
            "Play a BGM.",
            "",
            "Usage: playbgm [bgmName]"
        },
    }
    commands.stopbgm={
        code=function()
            BGM.stop()
        end,
        description="Stop BGM",
        details={
            "Stop the currently playing BGM.",
            "",
            "Usage: stopbgm"
        },
    }
    commands.setbg={
        code=function(name)
            if name~='' then
                if name~=BG.cur then
                    if BG.set(name) then
                        log(("Background set to '%s'"):format(name))
                    else
                        log(("Set background failed"):format(name))
                    end
                else
                    log(("Background already set to '%s'"):format(name))
                end
            else
                log{COLOR.I,"Usage: setbg [bgName]"}
            end
        end,
        description="Set background",
        details={
            "Set a background.",
            "",
            "Usage: setbg [bgName]",
        },
    }
    commands.test={
        code=function()
            SCN.go('_test','none')
        end,
        description="Enter test scene",
        details={
            "Go to an empty test scene",
            "",
            "Usage: test",
        },
    }
    do-- app
        local APPs={
            {
                code="calc",
                scene='app_calc',
                description="A simple calculator"
            },
            {
                code="15p",
                scene='app_15p',
                description="15 Puzzle (sliding puzzle)"
            },
            {
                code="grid",
                scene='app_schulteG',
                description="Schulte Grid"
            },
            {
                code="pong",
                scene='app_pong',
                description="Pong (2P)"
            },
            {
                code="atoz",
                scene='app_AtoZ',
                description="A to Z (typing)"
            },
            {
                code="uttt",
                scene='app_UTTT',
                description="Ultimate Tic-Tac-Toe (2P)"
            },
            {
                code="cube",
                scene='app_cubefield',
                description="Cubefield, original game by Max Abernethy"
            },
            {
                code="2048",
                scene='app_2048',
                description="2048 with some new features. Original by Asher Vollmer"
            },
            {
                code="ten",
                scene='app_ten',
                description="Just Get Ten"
            },
            {
                code="tap",
                scene='app_tap',
                description="Clicking/Tapping speed test"
            },
            {
                code="dtw",
                scene='app_dtw',
                description="Don't Touch White (Piano Tiles)"
            },
            {
                code="can",
                scene='app_cannon',
                description="A simple cannon shooting game"
            },
            {
                code="drp",
                scene='app_dropper',
                description="Dropper"
            },
            {
                code="rfl",
                scene='app_reflect',
                description="Reflect (2P)"
            },
            {
                code="poly",
                scene='app_polyforge',
                description="Polyforge. Original by ImpactBlue Studios"
            },
            {
                code="link",
                scene='app_link',
                description="Connect tiles (Shisen-Sho)"
            },
            {
                code="arm",
                scene='app_arithmetic',
                description="Arithmetic"
            },
            {
                code="piano",
                scene='app_piano',
                description="A simple keyboard piano"
            },
            {
                code="mem",
                scene='app_memorize',
                description="Number memorize"
            },
            {
                code="trp",
                scene='app_triple',
                description="A Match-3 Game. Original idea from Sanlitun / Triple Town"
            },
            {
                code="sw",
                scene='app_stopwatch',
                description="A stopwatch"
            },
            {
                code="mj",
                scene='app_mahjong',
                description="A simple mahjong game (1 player)"
            },
            {
                code="spin",
                scene='app_spin',
                description="¿"
            },
        }
        commands.app={
            code=function(name)
                if name=="-list" then
                    for i=1,#APPs do
                        log(STRING.repD("$1 $2 $3",APPs[i].code,("·"):rep(10-#APPs[i].code),APPs[i].description))
                    end
                elseif name~='' then
                    for i=1,#APPs do
                        if APPs[i].code==name then
                            SCN.go(APPs[i].scene)
                            return
                        end
                    end
                    log{COLOR.I,"No applet with this name. Type app -list to view all applets"}
                else
                    log{COLOR.I,"Usage:"}
                    log{COLOR.I,"app -list"}
                    log{COLOR.I,"app [appName]"}
                end
            end,
            description="Enter a applet scene",
            details={
                "Go to an applet scene",
                "",
                "Usage:",
                "app -list",
                "app [appName]",
            },
        }
    end
    commands.resetall={
        code=function(arg)
            if arg=="sure" then
                log"FINAL WARNING!"
                log"Please remember that resetting everything will delete all saved data. Delete them anyway?"
                log"Once the data has been deleted, there is no way to recover it."
                log"Type: resetall really"
            elseif arg=="really" then
                BGM.stop()
                WIDGET.unFocus(true)
                inputBox._visible=false
                table.remove(WIDGET.active,TABLE.find(WIDGET.active,inputBox))
                commands.cls.code()
                outputBox:clear()
                outputBox.h=SCR.h0-140
                local button=WIDGET.new{type='button',name='bye',text=Zenitha.getAppName().." is fun. Bye.",pos={.5,1},x=0,y=-60,w=426,h=100,code=function()
                    WIDGET.active.bye._visible=false
                    outputBox.h=SCR.h0-20
                    TASK.new(function()
                        DEBUG.yieldT(0.5)
                        for i=10,0,-1 do
                            log{COLOR.R,STRING.repD("Deleting all data in $1...",i)}
                            DEBUG.yieldT(1)
                        end
                        outputBox._visible=false
                        DEBUG.yieldT(0.26)
                        FILE.clear_s('')
                        love.event.quit()
                    end)
                end}
                ins(WIDGET.active,button)
            else
                log"Are you sure you want to reset everything?"
                log"This will delete EVERYTHING in your saved game data, just like factory reset."
                log"This cannot be undone."
                log"Type: resetall sure"
            end
        end,
        description="Reset everything and delete all saved data.",
    }
    commands.su={
        code=function(code)
            if sumode then
                log{COLOR.Y,"You are already in su mode. Use # to run any lua code"}
                log{COLOR.Y,"已经进入最高权限模式了, 请使用 # 执行任意lua代码"}
            elseif code=="7126" then
                sumode=true
                log{COLOR.Y,"* SU MODE ON - DO NOT RUN ANY CODES IF YOU DO NOT KNOW WHAT THEY DO *"}
                log{COLOR.Y,"* Now you should use the _CL(message) function to print into this console *"}
                log{COLOR.Y,"* 最高权限模式开启, 请不要执行任何自己不懂确切含义的代码 *"}
                log{COLOR.Y,"* 从现在开始请使用_CL(信息)函数在控制台打印信息 *"}
                _CL=log
            else
                log{COLOR.Y,"Password incorrect"}
            end
        end,
    }

    for cmd,body in next,commands do
        if type(body)=='function' then
            commands[cmd]={code=body}
        end
        if type(body)~='string' then
            ins(cmdList,cmd)
        end
    end
    table.sort(cmdList)
    TABLE.reIndex(commands)
end

local combKey={
    x=function()
        love.system.setClipboardText(inputBox:getText())
        inputBox:clear()
    end,
    c=function()
        love.system.setClipboardText(inputBox:getText())
    end,
    v=function()
        inputBox:addText(love.system.getClipboardText())
    end,
}

-- Environment for user's function
local userG={
    timer=love.timer.getTime,

    assert=assert,error=error,
    tonumber=tonumber,tostring=tostring,
    select=select,next=next,
    ipairs=ipairs,pairs=pairs,
    type=type,
    pcall=pcall,xpcall=xpcall,
    rawget=rawget,rawset=rawset,rawlen=rawlen,rawequal=rawequal,
    setfenv=setfenv,setmetatable=setmetatable,
    -- require=require,
    -- load=load,loadfile=loadfile,dofile=dofile,
    -- getfenv=getfenv,getmetatable=getmetatable,
    -- collectgarbage=collectgarbage,

    math={},string={},table={},bit={},coroutine={},
    debug={},package={},io={},os={},
}
function userG.print(...)
    local args,L={...},{}
    for k,v in next,args do ins(L,{k,v}) end
    table.sort(L,function(a,b) return a[1]<b[1] end)
    local i=1
    while L[1] do
        if i==L[1][1] then
            log(tostring(L[1][2]))
            rem(L,1)
        else
            log("nil")
        end
        i=i+1
    end
end
userG._G=userG
TABLE.complete(math,userG.math)
TABLE.complete(string,userG.string)userG.string.dump=nil
TABLE.complete(table,userG.table)
TABLE.complete(bit,userG.bit)
TABLE.complete(coroutine,userG.coroutine)
local dangerousLibMeta={__index=function() error("No way.") end,__metatable=true}
setmetatable(userG.debug,dangerousLibMeta)
setmetatable(userG.package,dangerousLibMeta)
setmetatable(userG.io,dangerousLibMeta)
setmetatable(userG.os,dangerousLibMeta)

local scene={}

function scene.enter()
    outputBox.w,outputBox.h=SCR.w0-40,math.max(SCR.h0-120,20)
    inputBox.y,inputBox.w=math.max(SCR.h0-120,20)+20,SCR.w0-40
    outputBox:reset()
    inputBox:reset()
    WIDGET.focus(inputBox)
    BG.set('none')
end

function scene.wheelMoved(_,y)
    WHEELMOV(y,'scrollup','scrolldown')
end

function scene.keyDown(key,isRep)
    if key=='return' or key=='kpenter' then
        local input=STRING.trim(inputBox:getText())
        if input=='' then return end

        -- Write History
        ins(history,input)
        if history[27] then
            rem(history,1)
        end
        hisPtr=false

        -- Execute
        if input:byte()==35 then
            -- Execute lua code
            log{COLOR.lC,"> "..input}
            local code,err=loadstring(input:sub(2))
            if code then
                local resultColor
                if sumode then
                    resultColor=COLOR.lY
                else
                    setfenv(code,userG)
                    resultColor=COLOR.lG
                end
                local success,result=pcall(code)
                if success then
                    if result~=nil then
                        log{resultColor,">> "..tostring(result)}
                    else
                        log{resultColor,"done"}
                    end
                else
                    log{COLOR.R,result}
                end
            else
                log{COLOR.R,"[SyntaxErr] ",COLOR.R,err}
            end
        else
            -- Execute builtin command
            log{COLOR.lS,"> "..input}
            local p=input:find(" ")
            local cmd,arg
            if p then
                cmd=input:sub(1,p-1):lower()
                arg=input:sub(input:find("%S",p+1) or -1)
            else
                cmd=input
                arg=''
            end
            if commands[cmd] then
                commands[cmd].code(arg)
            else
                log{COLOR.R,"No command called "..cmd}
            end
        end
        inputBox:clear()

        -- Insert empty line
        log""
    elseif key=='up' then
        if not hisPtr then
            hisPtr=#history
            if hisPtr>0 then
                inputBox:setText(history[hisPtr])
            end
        elseif hisPtr>1 then
            hisPtr=hisPtr-1
            inputBox:setText(history[hisPtr])
        end
    elseif key=='down' then
        if hisPtr then
            hisPtr=hisPtr+1
            if history[hisPtr] then
                inputBox:setText(history[hisPtr])
            else
                hisPtr=false
                inputBox:clear()
            end
        end
    elseif key=='tab' then
        local str=inputBox:getText()
        if str~='' and not str:find("%s") then
            local res={}
            for c in next,commands do
                if c:find(str,nil,true)==1 then
                    ins(res,c)
                end
            end

            if #res>1 then
                log(">Commands that start with '"..str.."' :")
                table.sort(res)
                for i=1,#res do log{COLOR.LD,res[i]} end
            elseif #res==1 then
                inputBox:setText(res[1])
            end
        end
    elseif key=='scrollup'   then outputBox:scroll(0,5)
    elseif key=='scrolldown' then outputBox:scroll(0,-5)
    elseif key=='pageup'     then outputBox:scroll(0,25)
    elseif key=='pagedown'   then outputBox:scroll(0,-25)
    elseif key=='home'       then outputBox:scroll(0,1e99)
    elseif key=='end'        then outputBox:scroll(0,-1e99)
    elseif combKey[key] and kb.isDown('lctrl','rctrl') then combKey[key]()
    elseif key=='escape' then
        if not isRep then
            SCN.back()
        end
    else
        if not WIDGET.isFocus(inputBox) then
            WIDGET.focus(inputBox)
        end
        return true
    end
end

scene.widgetList={
    outputBox,
    inputBox,
}

return scene
