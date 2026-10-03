-- Noct no Aseprite: monta e exporta art_source/personagem principal/noct.aseprite.
--
-- Montar (a partir das tiras geradas por tools/remaster_hero.gd):
--   Aseprite.exe -b --script-param modo=montar --script tools/noct_aseprite.lua
-- Exportar (depois de editar no Aseprite, grava as tiras do jogo de volta):
--   Aseprite.exe -b --script-param modo=exportar --script tools/noct_aseprite.lua
--
-- O arquivo tem um quadro por quadro do jogo e uma tag por animação (idle, run, ...,
-- c1_idle ...). Todos os quadros têm o mesmo tamanho e o mesmo ponto dos pés (hero.json).
-- Rodar a partir da pasta do projeto (hollow-like).

local root = app.fs.currentPath
local hero_dir = app.fs.joinPath(root, "assets", "hero")
local crimson_dir = app.fs.joinPath(hero_dir, "crimson")
local ase_path = app.fs.joinPath(root, "art_source", "personagem principal", "noct.aseprite")

-- Ordem das animações e quadros por segundo (iguais a HERO_ANIMS/CRIMSON_ANIMS em game/core/sprites.gd).
local ANIMS = {
  {"idle", 4}, {"run", 14}, {"jump", 10}, {"fall", 8}, {"land", 1}, {"double_jump", 30},
  {"dash", 50}, {"crouch", 4.5}, {"jab", 18}, {"cross", 16}, {"kick", 16}, {"charged", 12},
  {"up_punch", 20}, {"low_punch", 16}, {"uppercut", 18}, {"cast", 22}, {"slam", 10},
  {"air_punch", 20}, {"air_kick", 20}, {"air_finish", 20}, {"hurt", 14}, {"death", 8},
  {"ultimate_charge", 14}, {"ultimate_burst", 12}, {"ultimate_pose", 8},
}
local CRIMSON = {{"idle", 4}, {"run", 11}, {"jump", 10}, {"double_jump", 14}, {"dash", 22}, {"crouch", 6}}
for lv = 1, 3 do
  for _, a in ipairs(CRIMSON) do
    table.insert(ANIMS, {"c" .. lv .. "_" .. a[1], a[2], true})
  end
end

local function strip_path(anim, crimson)
  return app.fs.joinPath(crimson and crimson_dir or hero_dir, anim .. ".png")
end

local function cell_size()
  local img = Image{ fromFile = strip_path("idle") }
  return img.width // 6, img.height   -- o idle tem 6 quadros
end

local function montar()
  local w, h = cell_size()
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = "noct"
  local first = true
  local ranges = {}
  for _, a in ipairs(ANIMS) do
    local strip = Image{ fromFile = strip_path(a[1], a[3]) }
    local n = strip.width // w
    local start = nil
    for i = 0, n - 1 do
      local frame
      if first then
        frame = spr.frames[1]
        first = false
      else
        frame = spr:newEmptyFrame()
      end
      frame.duration = 1 / a[2]
      local img = Image(w, h, ColorMode.RGB)
      img:drawImage(strip, Point(-i * w, 0))
      spr:newCel(spr.layers[1], frame, img, Point(0, 0))
      start = start or frame
    end
    table.insert(ranges, {a[1], start.frameNumber, start.frameNumber + n - 1})
  end
  -- As tags só são criadas no fim: uma tag criada antes cresce junto com os quadros novos.
  for _, r in ipairs(ranges) do
    local tag = spr:newTag(r[2], r[3])
    tag.name = r[1]
    tag.color = r[1]:match("^c%d_") and Color{ r = 200, g = 40, b = 70 } or Color{ r = 90, g = 120, b = 200 }
  end
  spr:saveAs(ase_path)
  print("noct.aseprite: " .. #spr.frames .. " quadros, " .. #spr.tags .. " tags")
end

local function exportar()
  local spr = app.open(ase_path)
  local w, h = spr.width, spr.height
  local maxn = 0
  for _, tag in ipairs(spr.tags) do maxn = math.max(maxn, tag.frames) end
  local atlas = Image(w * maxn, h * #spr.tags, ColorMode.RGB)   -- uma linha por animação
  for row, tag in ipairs(spr.tags) do
    local crimson = tag.name:match("^c%d_") ~= nil
    local n = tag.frames
    local out = Image(w * n, h, ColorMode.RGB)
    for i = 0, n - 1 do
      local img = Image(w, h, ColorMode.RGB)
      img:drawSprite(spr, tag.fromFrame.frameNumber + i)
      out:drawImage(img, Point(i * w, 0))
    end
    out:saveAs(strip_path(tag.name, crimson))
    atlas:drawImage(out, Point(0, (row - 1) * h))
  end
  atlas:saveAs(app.fs.joinPath(hero_dir, "noct_atlas.png"))
  print("exportadas " .. #spr.tags .. " tiras")
end

if app.params["modo"] == "exportar" then exportar() else montar() end
