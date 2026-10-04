-- Formas carmesim (Forma Demoníaca) do Noct, refeitas como CAMADA por cima do Noct base, sem
-- redesenhar o corpo (docs/expansao_forma_demoniaca.md, "Visual"):
--   Nível 1 Juramento: aura com chamas curtas no ritmo da respiração, um chifre de aura do lado
--                      esquerdo (atrás), olhos carmesim, leve tom carmesim.
--   Nível 2 Ruptura:   dois chifres sólidos, cauda de energia, fagulhas pretas, aura mais forte.
--   Nível 3 Consumido: chifres maiores e asas de energia, rosto escurecido, só os olhos acesos.
-- Lê as animações base do noct.aseprite e grava assets/hero/crimson/c<n>_<anim>.png.
-- Rodar DEPOIS de exportar o noct.aseprite (modo=exportar), que regrava as tiras antigas.
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/noct_forms.lua
--   --script-param preview=1 grava só art_source/personagem principal/noct_forms.aseprite

local root = app.fs.currentPath
local pc = app.pixelColor
local spr = app.open(app.fs.joinPath(root, "art_source", "personagem principal", "noct.aseprite"))
local W, H = spr.width, spr.height
local crimson_dir = app.fs.joinPath(root, "assets", "hero", "crimson")

-- Animações de cada forma (as básicas). crouch_loop = a pose abaixada com a aura se mexendo.
-- TODAS as animações do Noct base (movimento, golpes, combos, magia, dano, morte, Ultimate),
-- para a forma valer em tudo, mais o crouch_loop. A Forma Demoníaca (demon_form.gd) só desenha
-- por código quando falta a arte.
local ANIMS = { "crouch_loop" }
for _, t in ipairs(spr.tags) do
  if not t.name:match("^c%d_") then table.insert(ANIMS, t.name) end
end
if app.params.anims then
  ANIMS = {}
  for n in string.gmatch(app.params.anims, "[^,]+") do table.insert(ANIMS, n) end
end
local LEVELS = { 1, 2, 3 }
if app.params.levels then
  LEVELS = {}
  for n in string.gmatch(app.params.levels, "[^,]+") do table.insert(LEVELS, tonumber(n)) end
end

local function hex(h) return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255) end
local C = {
  dark = hex("#320514"), deep = hex("#5f0622"), blood = hex("#850a2f"), red = hex("#a6232c"),
  crimson = hex("#bd1a45"), hot = hex("#e2174b"), pink = hex("#ee3f6f"), tip = hex("#f692b1"),
  eye = hex("#ff5a8a"), eye3 = hex("#ffd0de"), black = hex("#120610"),
}

local function tag(n) for _, t in ipairs(spr.tags) do if t.name == n then return t end end end
local function frames_of(name)
  local t, list = tag(name), {}
  if not t then return list end
  for i = 0, t.frames - 1 do
    local img = Image(W, H, ColorMode.RGB)
    img:drawSprite(spr, t.fromFrame.frameNumber + i)
    table.insert(list, img)
  end
  return list
end

-- Número "aleatório" fixo por pixel e quadro (o mesmo resultado a cada execução).
local function noise(x, y, k)
  local n = (x * 374761393 + y * 668265263 + k * 2147483647) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return (n % 1000) / 1000
end

local function is_energy(c)
  local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
  return r > 150 and g < 90 and r > b * 1.2
end
local function is_skin(c)
  local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
  return r > 140 and g > 80 and b < 120 and r > g and g > b
end
local function mix(c, to, t)
  local r = pc.rgbaR(c) + (pc.rgbaR(to) - pc.rgbaR(c)) * t
  local g = pc.rgbaG(c) + (pc.rgbaG(to) - pc.rgbaG(c)) * t
  local b = pc.rgbaB(c) + (pc.rgbaB(to) - pc.rgbaB(c)) * t
  return pc.rgba(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5), pc.rgbaA(c))
end
local function darken(c, t) return mix(c, pc.rgba(0, 0, 0, 255), t) end

local function opaque(img, x, y)
  return x >= 0 and y >= 0 and x < W and y < H and pc.rgbaA(img:getPixel(x, y)) > 0
end
local function put(img, x, y, c) if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end end
local function put_if_empty(img, x, y, c) if x >= 0 and y >= 0 and x < W and y < H and pc.rgbaA(img:getPixel(x, y)) == 0 then img:drawPixel(x, y, c) end end

-- Medidas do corpo no quadro: topo da cabeça, faixa da cabeça, linha dos pés, borda de trás.
local function measure(img)
  local m = { top = nil, feet = 0, hx0 = W, hx1 = 0 }
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 and not is_energy(c) then
        m.top = m.top or y
        m.feet = y
      end
    end
  end
  m.top = m.top or 0
  for y = m.top, m.top + 4 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 and not is_energy(c) then m.hx0 = math.min(m.hx0, x); m.hx1 = math.max(m.hx1, x) end
    end
  end
  -- Rosto: pele mais à frente nas linhas dos olhos.
  m.ex, m.ey = nil, m.top + 6
  for y = m.top + 5, m.top + 8 do
    for x = W - 1, 0, -1 do
      if is_skin(img:getPixel(x, y)) then
        if not m.ex or x > m.ex then m.ex, m.ey = x, y end
        break
      end
    end
  end
  return m
end

-- Tom do corpo: carmesim leve (1), mais forte (2), escurecido com só os olhos (3).
local function tint(img, level)
  local out = img:clone()
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 and not is_energy(c) then
        if level == 1 then
          out:drawPixel(x, y, mix(c, C.blood, 0.12))
        elseif level == 2 then
          out:drawPixel(x, y, mix(c, C.blood, 0.22))
        else
          local d = is_skin(c) and 0.55 or 0.35
          out:drawPixel(x, y, mix(darken(c, d), C.dark, 0.25))
        end
      end
    end
  end
  return out
end

-- Aura: anel em volta da silhueta (mais grosso a cada nível) e chamas subindo das bordas de cima.
-- k = quadro (anima a aura), breath = 0..1 (ritmo da respiração).
local function aura(base, out, m, level, k, breath)
  local rings = level == 1 and { 0.38 } or level == 2 and { 0.62, 0.25 } or { 0.9, 0.55, 0.25 }
  local ring_colors = { C.crimson, C.red, C.blood }
  local prev = {}
  for y = 0, H - 1 do for x = 0, W - 1 do if opaque(base, x, y) then prev[y * W + x] = true end end end
  local filled = {}
  for k2, _ in pairs(prev) do filled[k2] = true end
  for r, chance in ipairs(rings) do
    local new = {}
    for key in pairs(filled) do
      local x, y = key % W, key // W
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = x + d[1], y + d[2]
        if nx >= 0 and ny >= 0 and nx < W and ny < H and not filled[ny * W + nx] and ny < m.feet - 1 then
          new[ny * W + nx] = true
        end
      end
    end
    for key in pairs(new) do
      local x, y = key % W, key // W
      local flick = noise(x // 2, y // 3, k // 2 + r * 7)   -- manchas de 2x3 px: aura em blocos, não chuvisco
      if flick < chance * (0.75 + 0.5 * breath) then put_if_empty(out, x, y, ring_colors[r]) end
      filled[key] = true
    end
  end
  -- Chamas: das colunas com borda de cima livre, na metade de cima do corpo, sobem pela respiração.
  local max_len = level == 1 and 2 or level == 2 and 4 or 6
  for x = 0, W - 1 do
    for y = m.top, math.min(m.feet, m.top + 22) do
      if opaque(base, x, y) then
        if not opaque(base, x, y - 1) then
          local n = noise(x, 0, k // 2)
          if n < 0.55 then
            local len = math.floor((0.4 + n) * max_len * (0.6 + 0.6 * breath) + 0.5)
            for i = 1, len do
              local t = i / math.max(1, len)
              local col = t < 0.4 and C.crimson or t < 0.8 and C.pink or C.tip
              put_if_empty(out, x - (i > 2 and 1 or 0), y - 1 - i, col)
            end
          end
        end
        break
      end
    end
  end
end

-- Olhos carmesim (um ponto de luz no rosto).
local function eyes(out, m, level)
  if not m.ex then return end
  local ex, ey = m.ex - 2, m.ey
  put(out, ex, ey, level == 3 and C.eye3 or C.eye)
  put(out, ex - 1, ey, level == 3 and C.eye or C.pink)
end

-- Chifre: curva saindo do alto da cabeça. dir = -1 (para trás) ou 1 (para a frente).
local function horn(out, x, y, dir, len, solid)
  local pts = {}
  for i = 0, len - 1 do
    table.insert(pts, { x + dir * math.floor(i * 0.6 + 0.5), y - i })
  end
  for i, p in ipairs(pts) do
    if solid then
      put(out, p[1], p[2], i == #pts and C.red or C.dark)
      if i < #pts - 1 then put(out, p[1] - dir, p[2], C.dark) end
      put(out, p[1] + dir, p[2], i < #pts - 1 and C.red or C.dark)
    else
      put(out, p[1], p[2], i > #pts - 2 and C.tip or C.pink)
      if i < #pts - 1 then put(out, p[1] - dir, p[2], C.hot) end
    end
  end
end

-- Cauda de energia (nível 2+): onda saindo do baixo das costas.
local function tail(out, base, m, k)
  local x0, y0 = nil, m.top + 24
  for x = 0, W - 1 do if opaque(base, x, y0) then x0 = x; break end end
  if not x0 then return end
  for i = 1, 9 do
    local wave = math.floor(math.sin((i + k) * 0.9) * 1.5 + 0.5)
    put_if_empty(out, x0 - i, y0 + i // 2 + wave, i > 6 and C.pink or C.crimson)
  end
end

-- Asas de energia (nível 3): três penas de energia saindo das costas, batendo devagar.
local function wings(out, base, m, k)
  local y0 = m.top + 13
  local x0 = nil
  for x = 0, W - 1 do if opaque(base, x, y0) then x0 = x + 3; break end end
  if not x0 then return end
  local flap = math.floor(math.sin(k * 0.8) * 2 + 0.5)
  for f, len in ipairs({ 14, 12, 9 }) do
    for i = 0, len do
      local px = x0 - i
      local py = y0 - math.floor(i * (0.9 - f * 0.18) + 0.5) - flap + f * 2
      put_if_empty(out, px, py, i > len - 3 and C.tip or (f == 1 and C.pink or C.crimson))
      put_if_empty(out, px, py + 1, C.blood)
    end
  end
end

-- Fagulhas pretas (nível 2+) em volta do corpo.
local function sparks(out, base, m, k, amount)
  for y = math.max(0, m.top - 6), m.feet do
    for x = 0, W - 1 do
      if not opaque(out, x, y) and noise(x, y, k) < amount then
        local near = opaque(base, x + 2, y) or opaque(base, x - 2, y) or opaque(base, x, y + 2)
        if near then put(out, x, y, C.black) end
      end
    end
  end
end

local function form_frame(img, level, k, n)
  local m = measure(img)
  local breath = 0.5 + 0.5 * math.sin(k / math.max(1, n) * math.pi * 2)
  local body = tint(img, level)
  local out = Image(W, H, ColorMode.RGB)
  -- Atrás do corpo: asas, aura e cauda; depois o corpo; por cima: chifres, olhos e fagulhas.
  if level == 3 then wings(out, img, m, k) end
  aura(img, out, m, level, k, breath)
  if level >= 2 then tail(out, img, m, k) end
  out:drawImage(body, Point(0, 0))
  local back_x = m.hx0 + 3
  if level == 1 then
    horn(out, back_x, m.top + 1, -1, 6, false)
  else
    horn(out, back_x, m.top + 1, -1, level == 2 and 6 or 8, true)
    horn(out, m.hx1 - 3, m.top + 1, 1, level == 2 and 4 or 6, true)
  end
  eyes(out, m, level)
  if level >= 2 then sparks(out, img, m, k, level == 2 and 0.012 or 0.02) end
  return out
end

-------------------------------------------------------------------------------
local preview = app.params.preview
local out_spr = preview and Sprite(W, H, ColorMode.RGB) or nil
local first = true
local ranges = {}
for _, level in ipairs(LEVELS) do
  for _, anim in ipairs(ANIMS) do
    local src = anim == "crouch_loop" and {} or frames_of(anim)
    if anim == "crouch_loop" then
      -- A pose abaixada final, repetida, com a aura se mexendo (8 quadros).
      local crouch = frames_of("crouch")
      for i = 1, 8 do src[i] = crouch[#crouch] end
    end
    local frames = {}
    for i, img in ipairs(src) do frames[i] = form_frame(img, level, i - 1, #src) end
    local key = "c" .. level .. "_" .. anim
    if #frames > 0 then
      if preview then
        local start
        for _, img in ipairs(frames) do
          local fr = first and out_spr.frames[1] or out_spr:newEmptyFrame()
          first = false
          fr.duration = 0.1
          out_spr:newCel(out_spr.layers[1], fr, img, Point(0, 0))
          start = start or fr.frameNumber
        end
        table.insert(ranges, { key, start, start + #frames - 1 })
      else
        local strip = Image(W * #frames, H, ColorMode.RGB)
        for i, img in ipairs(frames) do strip:drawImage(img, Point((i - 1) * W, 0)) end
        strip:saveAs(app.fs.joinPath(crimson_dir, key .. ".png"))
      end
    end
  end
end
if preview then
  for _, r in ipairs(ranges) do local t = out_spr:newTag(r[2], r[3]); t.name = r[1] end
  out_spr:saveAs(app.fs.joinPath(root, "art_source", "personagem principal", "noct_forms.aseprite"))
  print("prévia: " .. #out_spr.frames .. " quadros")
else
  print("formas: " .. #LEVELS * #ANIMS .. " tiras gravadas")
end
