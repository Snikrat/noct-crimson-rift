-- Magia da forma carmesim 3: a Raposa Espectral Carmesim (arte do Felippe, em alta resolução)
-- vira a tira do projétil em escala do jogo, sem redesenhar a arte:
--   1. separa os 8 quadros da sequência: o corpo de cada raposa (alfa > 128) é uma mancha só, e o
--      brilho em volta vai para a mancha mais próxima (o brilho de um quadro encosta no outro);
--   2. reduz cada quadro pela MESMA escala (média de área, alfa pré-multiplicado), preservando o
--      crescimento da raposa ao longo da sequência; os veios claros e os olhos não somem na média;
--   3. limpa o brilho quase invisível e reduz a paleta (carmesim, sem pontilhado);
--   4. alinha pelo focinho (a raposa avança para a direita) e centra na vertical.
-- Grava art_source/vfx/raposa_espectral.aseprite (tags grow/fly/burst) e
-- assets/hero/crimson/c3_spell_ball.png (tira horizontal). O tamanho do quadro vai para crimson.json.
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/make_fox_spell.lua

local root = app.fs.currentPath
local pc = app.pixelColor
local SRC = app.fs.joinPath(root, "art_source", "vfx", "Sequência de Raposa Espectral Carmesim.png")
local SCALE = tonumber(app.params.scale or "0.16")
local COLORS = tonumber(app.params.colors or "32")
local A_MIN = 40      -- alfa do original que conta como arte (brilho)
local A_BODY = 128    -- alfa do corpo de cada raposa
local MIN_BODY = 3000 -- pixels mínimos de um corpo (o resto são fagulhas)
local A_CUT = 72      -- depois de reduzir: abaixo disso some (fiapos de brilho)
local BRIGHT = 225    -- luminância dos veios e olhos no original
local PAD = 2

local img = Image{ fromFile = SRC }
local W, H = img.width, img.height
local alpha = {}
for y = 0, H - 1 do
  for x = 0, W - 1 do alpha[y * W + x] = pc.rgbaA(img:getPixel(x, y)) end
end

-- 1a. Corpos: manchas ligadas com alfa > A_BODY.
local lab = {}
local bodies = {}
local DIRS = { 1, -1, W, -W }
local function neighbors(i)
  local x = i % W
  local out = {}
  if x < W - 1 then out[#out + 1] = i + 1 end
  if x > 0 then out[#out + 1] = i - 1 end
  if i + W < W * H then out[#out + 1] = i + W end
  if i - W >= 0 then out[#out + 1] = i - W end
  return out
end
local tmp = {}
for i = 0, W * H - 1 do
  if not tmp[i] and alpha[i] > A_BODY then
    local st, pix = { i }, {}
    tmp[i] = true
    while #st > 0 do
      local j = table.remove(st)
      pix[#pix + 1] = j
      for _, k in ipairs(neighbors(j)) do
        if not tmp[k] and alpha[k] > A_BODY then tmp[k] = true; st[#st + 1] = k end
      end
    end
    if #pix >= MIN_BODY then
      local x0 = W
      for _, j in ipairs(pix) do if j % W < x0 then x0 = j % W end end
      bodies[#bodies + 1] = { pix = pix, x0 = x0 }
    end
  end
end
table.sort(bodies, function(a, b) return a.x0 < b.x0 end)

-- 1b. Brilho: cada pixel com alfa > A_MIN vai para o corpo mais próximo (busca em largura a partir
-- de todos os corpos ao mesmo tempo). Fagulhas soltas que não encostam em nada ficam de fora.
local queue, head = {}, 1
for id, b in ipairs(bodies) do
  for _, j in ipairs(b.pix) do lab[j] = id; queue[#queue + 1] = j end
end
while head <= #queue do
  local j = queue[head]; head = head + 1
  for _, k in ipairs(neighbors(j)) do
    if not lab[k] and alpha[k] > A_MIN then lab[k] = lab[j]; queue[#queue + 1] = k end
  end
end
queue = nil

-- 2. Reduz um quadro.
local function lum(p) return 0.3 * pc.rgbaR(p) + 0.59 * pc.rgbaG(p) + 0.11 * pc.rgbaB(p) end
local function shrink(id)
  local bx0, by0, bx1, by1 = W, H, -1, -1
  for i, l in pairs(lab) do
    if l == id then
      local x, y = i % W, i // W
      if x < bx0 then bx0 = x end
      if x > bx1 then bx1 = x end
      if y < by0 then by0 = y end
      if y > by1 then by1 = y end
    end
  end
  local sw, sh = bx1 - bx0 + 1, by1 - by0 + 1
  local ow, oh = math.max(1, math.floor(sw * SCALE + 0.5)), math.max(1, math.floor(sh * SCALE + 0.5))
  local out = Image(ow, oh, ColorMode.RGB)
  local fx, fy = sw / ow, sh / oh
  for oy = 0, oh - 1 do
    for ox = 0, ow - 1 do
      local r, g, b, a, n = 0, 0, 0, 0, 0
      local br, bg, bb, nb, best = 0, 0, 0, 0, 0
      for y = by0 + math.floor(oy * fy), by0 + math.floor((oy + 1) * fy) - 1 do
        for x = bx0 + math.floor(ox * fx), bx0 + math.floor((ox + 1) * fx) - 1 do
          n = n + 1
          local i = y * W + x
          if lab[i] == id then
            local p = img:getPixel(x, y)
            local pa = alpha[i]
            r = r + pc.rgbaR(p) * pa
            g = g + pc.rgbaG(p) * pa
            b = b + pc.rgbaB(p) * pa
            a = a + pa
            local L = lum(p)
            if pa > 200 and L > BRIGHT * 0.6 and L > best then
              best, br, bg, bb = L, pc.rgbaR(p), pc.rgbaG(p), pc.rgbaB(p)
            end
            if pa > 200 and L > BRIGHT * 0.6 then nb = nb + 1 end
          end
        end
      end
      if a > 0 and n > 0 then
        local av = a / n
        if av >= A_CUT then
          local cr, cg, cb = r / a, g / a, b / a
          -- Veios claros e olhos (finos no original): puxa a cor para o ponto mais claro.
          local share = nb / n
          if share > 0.10 then
            local t = math.min(0.75, share * 3)
            cr, cg, cb = cr + (br - cr) * t, cg + (bg - cg) * t, cb + (bb - cb) * t
          end
          -- 3. Alfa em poucos degraus: brilho translúcido de leve, corpo opaco.
          local q = av > 190 and 255 or (av > 120 and 190 or 120)
          out:drawPixel(ox, oy, pc.rgba(math.floor(cr), math.floor(cg), math.floor(cb), q))
        end
      end
    end
  end
  return out
end

local frames = {}
local CW, CH = 0, 0
for id = 1, #bodies do
  local f = shrink(id)
  frames[id] = f
  CW = math.max(CW, f.width)
  CH = math.max(CH, f.height)
  print(string.format("quadro %d: %dx%d", id, f.width, f.height))
end
CW, CH = CW + PAD * 2, CH + PAD * 2
if CH % 2 == 1 then CH = CH + 1 end

-- 4. Sprite: focinho alinhado à direita, centro vertical no meio do quadro.
local spr = Sprite(CW, CH, ColorMode.RGB)
spr.layers[1].name = "raposa"
for i = 2, #frames do spr:newEmptyFrame() end
for i, f in ipairs(frames) do
  local px = CW - PAD - f.width
  local py = math.floor((CH - f.height) / 2)
  spr:newCel(spr.layers[1], spr.frames[i], f, Point(px, py))
  spr.frames[i].duration = 0.07
end

app.activeSprite = spr
app.command.ColorQuantization{ ui = false, maxColors = COLORS, withAlpha = false }
app.command.ChangePixelFormat{ format = "indexed", dithering = "none" }
app.command.ChangePixelFormat{ format = "rgb" }

if #frames == 8 then
  spr:newTag(1, 3).name = "grow"
  spr:newTag(4, 6).name = "fly"
  spr:newTag(7, 8).name = "burst"
end
spr:saveAs(app.fs.joinPath(root, "art_source", "vfx", "raposa_espectral.aseprite"))

-- Tira horizontal para o jogo.
local strip = Image(CW * #frames, CH, ColorMode.RGB)
for i = 1, #frames do
  local cel = spr.layers[1]:cel(i)
  if cel then strip:drawImage(cel.image, Point((i - 1) * CW + cel.position.x, cel.position.y)) end
end
strip:saveAs(app.fs.joinPath(root, "assets", "hero", "crimson", "c3_spell_ball.png"))
print(string.format("quadro final %dx%d, %d quadros", CW, CH, #frames))
