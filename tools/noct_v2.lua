-- Noct v2: recriação no Aseprite a partir do noct.aseprite, fiel ao design.
-- Gera art_source/personagem principal/noct_v2.aseprite com duas camadas:
--   corpo: o personagem com paleta enxuta (uma rampa por material), sem pixels soltos;
--   vfx:   a energia carmesim separada do corpo.
-- Etapa 1 (esta): idle, idle_var (variação) e run.
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/noct_v2.lua

local root = app.fs.currentPath
local src_path = app.fs.joinPath(root, "art_source", "personagem principal", "noct.aseprite")
local out_path = app.fs.joinPath(root, "art_source", "personagem principal", "noct_v2.aseprite")
local PALETTE_SIZE = 32

local pc = app.pixelColor
local src = app.open(src_path)
local W, H = src.width, src.height

local function tag(name)
  for _, t in ipairs(src.tags) do if t.name == name then return t end end
end

local function frame_image(n)
  local img = Image(W, H, ColorMode.RGB)
  img:drawSprite(src, n)
  return img
end

local function frames_of(name)
  local t, list = tag(name), {}
  for i = 0, t.frames - 1 do table.insert(list, frame_image(t.fromFrame.frameNumber + i)) end
  return list
end

-- Linha dos pés (última linha com pixels).
local function feet(img)
  for y = H - 1, 0, -1 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then return y end
    end
  end
  return H - 1
end

-- Energia carmesim (rosa/vermelho vivo). As botas têm vermelho escuro: a faixa dos pés não entra.
local function is_energy(c, y, feet_y)
  local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
  if pc.rgbaA(c) == 0 then return false end
  if r > 150 and g < 90 and r > b * 1.2 then return true end
  return y < feet_y - 9 and r >= 110 and g < 40 and r > g * 3 and b < 90
end

-- Separa corpo e energia.
local function split(img)
  local body, vfx = img:clone(), Image(W, H, ColorMode.RGB)
  local fy = feet(img)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if is_energy(c, y, fy) then
        vfx:drawPixel(x, y, c)
        body:drawPixel(x, y, pc.rgba(0, 0, 0, 0))
      end
    end
  end
  return body, vfx
end

-- Paleta enxuta: o quantizador do Aseprite sobre todos os quadros do corpo.
local function build_palette(images)
  local tmp = Sprite(W, H * #images, ColorMode.RGB)
  local sheet = Image(W, H * #images, ColorMode.RGB)
  for i, img in ipairs(images) do sheet:drawImage(img, Point(0, (i - 1) * H)) end
  tmp:newCel(tmp.layers[1], tmp.frames[1], sheet, Point(0, 0))
  app.command.ColorQuantization{ ui = false, withAlpha = false, maxColors = PALETTE_SIZE }
  local pal = {}
  local p = tmp.palettes[1]
  for i = 0, #p - 1 do
    local c = p:getColor(i)
    if c.alpha > 0 then table.insert(pal, { c.red, c.green, c.blue }) end
  end
  tmp:close()
  return pal
end

local function nearest(pal, c)
  local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
  local best, bd = pal[1], math.huge
  for _, p in ipairs(pal) do
    -- Distância "redmean": aproxima a percepção sem puxar marrons escuros para o carmesim.
    local rm = (p[1] + r) / 2
    local dr, dg, db = p[1] - r, p[2] - g, p[3] - b
    local d = (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db
    if d < bd then bd, best = d, p end
  end
  return pc.rgba(best[1], best[2], best[3], 255)
end

-- Aplica a paleta e tira pixels soltos (cor sem nenhum vizinho igual vira a cor vizinha mais comum).
local function clean(img, pal)
  local out = img:clone()
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 and pal then out:drawPixel(x, y, nearest(pal, c)) end
    end
  end
  local res = out:clone()
  for y = 1, H - 2 do
    for x = 1, W - 2 do
      local c = out:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local same, count, best, bestn = false, {}, nil, 0
        for dy = -1, 1 do
          for dx = -1, 1 do
            if not (dx == 0 and dy == 0) then
              local n = out:getPixel(x + dx, y + dy)
              if n == c then same = true end
              if pc.rgbaA(n) > 0 then
                count[n] = (count[n] or 0) + 1
                if count[n] > bestn then bestn, best = count[n], n end
              end
            end
          end
        end
        -- Só limpa dentro do desenho (com 5+ vizinhos), para não comer contorno nem pontas.
        if not same and best and bestn >= 3 then
          local opaque = 0
          for _, v in pairs(count) do opaque = opaque + v end
          if opaque >= 7 then res:drawPixel(x, y, best) end
        end
      end
    end
  end
  return res
end

-- Desloca para cima as linhas [y0, y1] (respiração: peito e cabeça sobem 1 px).
local function lift(img, y0, y1, dy)
  local out = img:clone()
  if dy < 0 then   -- descendo: a linha de cima fica vazia
    for y = y0, y0 - dy - 1 do
      for x = 0, W - 1 do out:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end
    end
  end
  for y = y0, y1 do
    for x = 0, W - 1 do out:drawPixel(x, y - dy, img:getPixel(x, y)) end
  end
  return out
end

-- Topo do desenho.
local function top(img)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then return y end
    end
  end
  return 0
end

-------------------------------------------------------------------------------
local idle_src, run_src = frames_of("idle"), frames_of("run")
local bodies, vfxs = {}, {}
for i, img in ipairs(idle_src) do bodies["idle" .. i], vfxs["idle" .. i] = split(img) end
for i, img in ipairs(run_src) do bodies["run" .. i], vfxs["run" .. i] = split(img) end
local all = {}
for _, img in ipairs(idle_src) do table.insert(all, img) end
for _, img in ipairs(run_src) do table.insert(all, img) end
-- Paleta do Noct v2: rampas fixas por material, escolhidas entre as cores do próprio Idle
-- (um quantizador automático juntava óculos e sombra da pele com o carmesim).
local function hex(h) return { tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16) } end
local RAMPS = {
  contorno = { "#120610" },
  roupa = { "#190c19", "#22141e", "#2e1e2a", "#3d2635", "#46373e" },     -- regata, calça
  cabelo = { "#230d1b", "#2e161d", "#451821", "#4d2525", "#5f2d3a" },    -- cabelo, sombra quente
  pele = { "#6c3329", "#85543f", "#a55b40", "#c17247", "#d08257", "#e98e5a" },
  corrente = { "#695a5e", "#89636a", "#9d8481" },
  botas = { "#1f0712", "#320514", "#470721", "#5f0622", "#850a2f" },
  logo = { "#7e212a", "#a6232c", "#bd1a45", "#ee3f6f" },
  tatuagem = { "#5e4346", "#7f3b2b", "#854743", "#a2492e" },
}
local pal = {}
for _, ramp in pairs(RAMPS) do for _, h in ipairs(ramp) do table.insert(pal, hex(h)) end end

-- Energia que fica por fora do corpo (não cobre o punho/braço desenhado no quadro do corpo).
local function aura_outside(vfx, body)
  local out = Image(W, H, ColorMode.RGB)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = vfx:getPixel(x, y)
      if pc.rgbaA(c) > 0 and pc.rgbaA(body:getPixel(x, y)) == 0 then out:drawPixel(x, y, c) end
    end
  end
  return out
end

-- IDLE: um corpo só (quadro 1 limpo), respirando: peito e cabeça sobem 1 px no meio do ciclo.
-- A energia dos punhos usa os quadros com brilho do Idle original (antes o brilho piscava).
local base = clean(bodies.idle1, pal)
-- O corpo do Idle fica com os punhos inteiros (a energia do próprio quadro faz parte da mão).
base = clean(idle_src[1], pal)
-- Retoques à mão no Idle (a base de todo o Noct v2). O Noct não usa óculos: a faixa escura
-- dos olhos (sobra das pranchas) vira pele com o olho, e o brinco fica destacado.
local RETOQUES = {
  {48, 28, "#a55b40"}, {49, 28, "#c17247"}, {50, 28, "#2e161d"}, {51, 28, "#85543f"},
  {50, 29, "#c17247"}, {51, 29, "#6c3329"},
  {46, 31, "#9d8481"},
}
for _, r in ipairs(RETOQUES) do
  local c = hex(r[3])
  base:drawPixel(r[1], r[2], pc.rgba(c[1], c[2], c[3], 255))
end
local t0 = top(base)

-- Cabeça menor (pedido: a cabeça destoava do corpo): o volume do cabelo perde 1 linha (no meio
-- do cabelo) e 1 coluna (na nuca). Rosto, óculos e queixo ficam como estão.
local function shrink_head(img, head_top)
  local out = img:clone()
  local hx0, hx1 = W, 0
  for y = head_top, head_top + 10 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then hx0 = math.min(hx0, x); hx1 = math.max(hx1, x) end
    end
  end
  local cut_row = head_top + 2            -- linha de cabelo que sai
  for y = cut_row, head_top + 1, -1 do
    for x = hx0 - 1, hx1 + 1 do out:drawPixel(x, y, out:getPixel(x, y - 1)) end
  end
  for x = hx0 - 1, hx1 + 1 do out:drawPixel(x, head_top, pc.rgba(0, 0, 0, 0)) end
  local cut_col = hx0 + 2                 -- coluna de cabelo da nuca que sai
  for y = head_top, head_top + 5 do
    for x = cut_col, hx0, -1 do out:drawPixel(x, y, out:getPixel(x - 1, y)) end
    out:drawPixel(hx0 - 1, y, pc.rgba(0, 0, 0, 0))
  end
  return out
end
base = shrink_head(base, t0)

-- Respiração sutil: só ombros e peito sobem 1 px (a cabeça não se mexe).
local chest = t0 + 17                       -- até o meio do peito (a cintura fica parada)
local breath = lift(base, t0 + 12, chest, 1)
local idle_body = { base, base, breath, breath }
local idle_vfx = { aura_outside(vfxs.idle2, base), aura_outside(vfxs.idle4, base),
  aura_outside(vfxs.idle6, breath), aura_outside(vfxs.idle4, breath) }

-- IDLE_VAR: o Noct abaixa a cabeça (cansaço), fica e volta. Cabeça = 11 linhas do topo.
local head_down = lift(base, t0 + 1, t0 + 10, -1)
local idle_var_body = { base, head_down, head_down, head_down, base }
local idle_var_vfx = { idle_vfx[1], idle_vfx[2], idle_vfx[2], idle_vfx[1], idle_vfx[1] }

-- RUN: os 8 quadros limpos com a mesma paleta; energia na camada separada.
local run_body, run_vfx = {}, {}
for i = 1, #run_src do
  run_body[i] = clean(run_src[i], pal)
  run_vfx[i] = Image(W, H, ColorMode.RGB)   -- a energia do Run já está no próprio quadro
end

-------------------------------------------------------------------------------
local out = Sprite(W, H, ColorMode.RGB)
local lbody = out.layers[1]
lbody.name = "corpo"
local lvfx = out:newLayer()
lvfx.name = "vfx"
-- Paleta do projeto: as cores do corpo + as da energia.
out:setPalette(src.palettes[1])

local ranges, first = {}, true
local function add(name, bodies_, vfx_, fps)
  local start = nil
  for i = 1, #bodies_ do
    local fr
    if first then fr = out.frames[1]; first = false else fr = out:newEmptyFrame() end
    fr.duration = 1 / fps
    out:newCel(lbody, fr, bodies_[i], Point(0, 0))
    out:newCel(lvfx, fr, vfx_[i], Point(0, 0))
    start = start or fr.frameNumber
  end
  table.insert(ranges, { name, start, start + #bodies_ - 1 })
end
add("idle", idle_body, idle_vfx, 3)
add("idle_var", idle_var_body, idle_var_vfx, 3)
add("run", run_body, run_vfx, 14)
for _, r in ipairs(ranges) do
  local t = out:newTag(r[2], r[3])
  t.name = r[1]
end
out:saveAs(out_path)
print("noct_v2: " .. #out.frames .. " quadros")
