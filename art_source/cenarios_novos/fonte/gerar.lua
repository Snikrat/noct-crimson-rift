-- Uso: Aseprite.exe -b --script gerar.lua [--script-param so=minas|arquivo|mineiro|grimorio] [--script-param prev=<pasta>]
local src = debug.getinfo(1, "S").source:sub(2)
local here = app.fs.filePath(src)
local dir = app.fs.filePath(here) -- cenarios_novos/
local prev = app.params["prev"] or app.fs.joinPath(dir, "fonte")

local L = dofile(app.fs.joinPath(here, "lib.lua"))
local S = loadfile(app.fs.joinPath(here, "solo.lua"))(L)

local only = app.params["so"]
local log = io.open(app.fs.joinPath(prev, "gerar_log.txt"), "w")
for _, name in ipairs { "minas", "arquivo", "mineiro", "grimorio" } do
  if not only or only == name then
    local chunk, err = loadfile(app.fs.joinPath(here, name .. ".lua"))
    local ok, e = false, err
    if chunk then ok, e = xpcall(chunk, debug.traceback, L, S, dir, prev) end
    log:write(name .. ": " .. (ok and "ok" or tostring(e)) .. "\n")
  end
end
log:close()
