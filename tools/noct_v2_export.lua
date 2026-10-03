-- Leva o Noct v2 para o jogo: cada tag do noct_v2.aseprite (corpo + vfx juntos) vira a tira
-- assets/hero/<tag>.png. Depois: remontar o noct.aseprite (tools/noct_aseprite.lua modo=montar),
-- rodar tools/noct_crouch_loop.lua e tools/noct_look_up.lua e exportar (modo=exportar).
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/noct_v2_export.lua

local root = app.fs.currentPath
local spr = app.open(app.fs.joinPath(root, "art_source", "personagem principal", "noct_v2.aseprite"))
local w, h = spr.width, spr.height
for _, tag in ipairs(spr.tags) do
  local n = tag.frames
  local out = Image(w * n, h, ColorMode.RGB)
  for i = 0, n - 1 do
    local img = Image(w, h, ColorMode.RGB)
    img:drawSprite(spr, tag.fromFrame.frameNumber + i)
    out:drawImage(img, Point(i * w, 0))
  end
  out:saveAs(app.fs.joinPath(root, "assets", "hero", tag.name .. ".png"))
end
print("Noct v2: " .. #spr.tags .. " tiras exportadas")
