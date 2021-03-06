if GetOption("linter") == nil then
    AddOption("linter", true)
end

function onSave()
    if GetOption("linter") then
        local ft = CurView().Buf.FileType
        local file = CurView().Buf.Path
        local devnull = "/dev/null"
        if OS == "windows" then
            devnull = "NUL"
        end
        if ft == "Go" then
            lint("gobuild", "go build -o " .. devnull, "%f:%l: %m")
            lint("golint", "golint " .. CurView().Buf.Path, "%f:%l:%d+: %m")
        elseif ft == "Lua" then
            lint("luacheck", "luacheck --no-color " .. file, "%f:%l:%d+: %m")
        elseif ft == "Python" then
            lint("pyflakes", "pyflakes " .. file, "%f:%l: %m")
        elseif ft == "C" then
            lint("gcc", "gcc -fsyntax-only -Wall -Wextra " .. file, "%f:%l:%d+:.+: %m")
        elseif ft == "D" then
            lint("dmd", "dmd -color=off -o- -w -wi -c " .. file, "%f%(%l%):.+: %m")
        elseif ft == "Java" then
            lint("javac", "javac " .. file, "%f:%l: error: %m")
        elseif ft == "JavaScript" then
            lint("jshint", "jshint " .. file, "%f: line %l,.+, %m")
        end
    else
        CurView():ClearAllGutterMessages()
    end
end

function lint(linter, cmd, errorformat)
    CurView():ClearGutterMessages(linter)

    JobStart(cmd, "", "", "linter.onExit", linter, errorformat)
end

function onExit(output, linter, errorformat)
    local lines = split(output, "\n")

    local regex = errorformat:gsub("%%f", "(.+)"):gsub("%%l", "(%d+)"):gsub("%%m", "(.+)")
    for _,line in ipairs(lines) do
        -- Trim whitespace
        line = line:match("^%s*(.+)%s*$")
        if string.find(line, regex) then
            local file, line, msg = string.match(line, regex)
            if basename(CurView().Buf.Path) == basename(file) then
                CurView():GutterMessage(linter, tonumber(line), msg, 2)
            end
        end
    end
end

function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end

function basename(file)
    local name = string.gsub(file, "(.*/)(.*)", "%2")
    return name
end
