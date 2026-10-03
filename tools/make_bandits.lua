-- Padroniza os sprites dos bandidos (leve e pesado; o capitão usa o pesado) na escala do Noct.
-- Não redesenha nada: só ajustes técnicos sobre os quadros originais do pacote Bandits.
--   1. Escala única 44/37 (o idle do bandido leve fica com 44 px, a mesma altura do idle do Noct;
--      o pesado mantém a proporção original e fica com 45 px). Reamostragem RotSprite, sem cores novas.
--   2. Alfa binário (sem semitransparência nas bordas).
--   3. Todos os quadros, das duas variantes, no MESMO tamanho de quadro e com o MESMO ponto de origem:
--      pés numa linha fixa e o centro da cabeça no meio do quadro (o flip não desloca o corpo).
--      Um quadro que desce abaixo da linha dos pés sobe até ela; nada encosta na borda.
-- Saída: <out>/<variante>/<anim>.png (tira horizontal), <art>/bandido_<variante>.aseprite (com tags)
-- e <out>/bandits.json com o tamanho do quadro e a origem.
-- Uso:
--   Aseprite.exe -b --script-param src=assets/vendor/bandits/Sprites --script-param out=assets/enemies/bandits
--     --script-param art=art_source/inimigos --script tools/make_bandits.lua

local SRC, OUT, ART = app.params.src, app.params.out, app.params.art
local METHOD = app.params.method or "rotsprite"
local SCALE = 44 / 37
local MARGIN = 2
local CELL = 48
local KINDS = { { "light", "Light Bandit", "leve" }, { "heavy", "Heavy Bandit", "pesado" } }
local ANIMS = {
  { "idle", "Idle" }, { "combat_idle", "Combat Idle" }, { "run", "Run" }, { "attack", "Attack" },
  { "recover", "Recover" }, { "hurt", "Hurt" }, { "death", "Death" }, { "jump", "Jump" },
}
local pc = app.pixelColor

local function frame_files(dir)
  local list = {}
  for _, f in ipairs(app.fs.listFiles(dir)) do
    local n = f:match("_(%d+)%.png$")
    if n then list[#list + 1] = { tonumber(n), app.fs.joinPath(dir, f) } end
  end
  table.sort(list, function(a, b) return a[1] < b[1] end)
  return list
end

local function bbox(img)
  local x0, y0, x1, y1 = math.huge, math.huge, -1, -1
  for it in img:pixels() do
    if pc.rgbaA(it()) > 0 then
      x0 = math.min(x0, it.x); x1 = math.max(x1, it.x); y0 = math.min(y0, it.y); y1 = math.max(y1, it.y)
    end
  end
  return x0, y0, x1, y1
end

-- 1. Carrega e reescala cada variante; guarda os quadros em tamanho cheio.
local scaled = {}
for _, k in ipairs(KINDS) do
  local spr = Sprite(CELL, CELL, ColorMode.RGB)
  local order = {}
  for _, a in ipairs(ANIMS) do
    for _, f in ipairs(frame_files(app.fs.joinPath(SRC, k[2], a[2]))) do
      local frame = #order == 0 and spr.frames[1] or spr:newEmptyFrame()
      spr:newCel(spr.layers[1], frame, Image { fromFile = f[2] }, Point(0, 0))
      order[#order + 1] = a[1]
    end
  end
  local size = math.floor(CELL * SCALE + 0.5)
  app.command.SpriteSize { ui = false, width = size, height = size, lockRatio = true, method = METHOD }
  local frames = {}
  for i, anim in ipairs(order) do
    local full = Image(spr.width, spr.height, ColorMode.RGB)
    local cel = spr.layers[1]:cel(i)
    if cel then full:drawImage(cel.image, cel.position) end
    for it in full:pixels() do
      local c = it()
      it(pc.rgbaA(c) >= 128 and pc.rgba(pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), 255) or 0)
    end
    frames[#frames + 1] = { anim = anim, img = full }
  end
  spr:close()
  scaled[k[1]] = frames
end

-- 2. Origem de cada variante: pés = base do idle; x = centro da cabeça (6 linhas do topo) no idle.
local function origin(frames)
  local img = frames[1].img
  local _, top, _, feet = bbox(img)
  local hx0, hx1 = math.huge, -1
  for it in img:pixels() do
    if pc.rgbaA(it()) > 0 and it.y < top + 6 then hx0 = math.min(hx0, it.x); hx1 = math.max(hx1, it.x) end
  end
  return math.floor((hx0 + hx1) / 2 + 0.5), feet
end

-- 3. Caixa comum (relativa à origem) de todos os quadros das duas variantes.
local left, right, up = 0, 0, 0
for _, k in ipairs(KINDS) do
  local frames = scaled[k[1]]
  local ox, oy = origin(frames)
  for _, fr in ipairs(frames) do
    local x0, y0, x1, y1 = bbox(fr.img)
    fr.dy = math.min(0, oy - y1)       -- sobe o quadro que passa da linha dos pés
    fr.ox, fr.oy = ox, oy
    left = math.max(left, ox - x0)
    right = math.max(right, x1 - ox)
    up = math.max(up, oy - (y0 + fr.dy))
  end
end
local half = math.max(left, right + 1) + MARGIN
local W, H = half * 2, up + 1 + MARGIN * 2
local AX, AY = half, up + MARGIN       -- coluna da origem e linha dos pés no quadro final

-- 4. Monta, salva o .aseprite editável e exporta as tiras.
app.fs.makeAllDirectories(ART)
for _, k in ipairs(KINDS) do
  local frames = scaled[k[1]]
  local spr = Sprite(W, H, ColorMode.RGB)
  spr.layers[1].name = "bandido " .. k[3]
  local strips, first = {}, {}
  for i, fr in ipairs(frames) do
    local frame = i == 1 and spr.frames[1] or spr:newEmptyFrame()
    local img = Image(W, H, ColorMode.RGB)
    img:drawImage(fr.img, Point(AX - fr.ox, AY - fr.oy + fr.dy))
    spr:newCel(spr.layers[1], frame, img, Point(0, 0))
    strips[fr.anim] = strips[fr.anim] or {}
    table.insert(strips[fr.anim], img)
    first[fr.anim] = first[fr.anim] or i
  end
  for _, a in ipairs(ANIMS) do
    local tag = spr:newTag(first[a[1]], first[a[1]] + #strips[a[1]] - 1)
    tag.name = a[1]
  end
  spr:saveAs(app.fs.joinPath(ART, "bandido_" .. k[3] .. ".aseprite"))
  spr:close()
  local dir = app.fs.joinPath(OUT, k[1])
  app.fs.makeAllDirectories(dir)
  for _, a in ipairs(ANIMS) do
    local list = strips[a[1]]
    local sheet = Image(W * #list, H, ColorMode.RGB)
    for i, img in ipairs(list) do sheet:drawImage(img, Point((i - 1) * W, 0)) end
    sheet:saveAs(app.fs.joinPath(dir, a[1] .. ".png"))
  end
end

local json = io.open(app.fs.joinPath(OUT, "bandits.json"), "w")
json:write(string.format('{"w": %d, "h": %d, "ax": %d, "ay": %d, "scale": %.4f}\n', W, H, AX, AY, SCALE))
json:close()
print(string.format("quadro %dx%d, origem (%d, %d)", W, H, AX, AY))
