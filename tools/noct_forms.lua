-- Formas carmesim (Forma Demoníaca) do Noct, refeitas como CAMADA por cima do Noct base, sem
-- redesenhar o corpo (docs/expansao_forma_demoniaca.md, "Visual"):
-- O demônio é uma RAPOSA: chifres de energia (não físicos) e caudas de energia, mais a cada nível.
--   Nível 1 Juramento: 1 cauda, um chifre de energia atrás, aura curta, olhos carmesim, tom leve.
--   Nível 2 Ruptura:   3 caudas, dois chifres de energia, fagulhas pretas, aura mais forte.
--   Nível 3 Consumido: 5 caudas, chifres maiores, rosto escurecido com só os olhos acesos.
-- Em todos, um pouco de energia por cima do corpo (borda de trás acesa e veios), de leve.
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

-- Chifre de ENERGIA (não é chifre físico): curva saindo do alto da cabeça, com a ponta piscando.
-- dir = -1 (para trás) ou 1 (para a frente).
local function horn(out, x, y, dir, len, k)
  for i = 0, len - 1 do
    local px, py = x + dir * math.floor(i * 0.6 + 0.5), y - i
    local tip = i >= len - 2
    put(out, px, py, tip and ((k // 2) % 2 == 0 and C.tip or C.pink) or (i < 2 and C.crimson or C.hot))
    if i < len - 2 then put(out, px - dir, py, i < 2 and C.blood or C.crimson) end
  end
end

-- Caudas de raposa de ENERGIA saindo do baixo das costas: grossas no meio, curvando para cima,
-- com a ponta clara. count = quantas caudas (mais a cada nível); abrem em leque e balançam.
local function tails(out, base, m, k, count, len)
  -- Base das caudas na cintura (lombar), não no quadril: assim elas não ficam baixas, nem na corrida.
  local y0 = m.top + 19
  local x0 = nil
  for x = 0, W - 1 do if opaque(base, x, y0) then x0 = x + 2; break end end
  if not x0 then return end
  -- Desenha da cauda mais de trás para a da frente, para cada uma ter contorno próprio.
  for t = count, 1, -1 do
    local spread = count == 1 and 0.5 or (t - 1) / (count - 1)
    local a0 = 0.05 + spread * 0.8                                    -- sai para trás e um pouco para cima
    local a1 = 0.7 + spread * 1.9 + math.sin((k + t * 2) * 0.6) * 0.15 -- termina para cima, em leque
    local l = len - math.floor(spread * 5)
    local px, py = x0, y0 + (count > 1 and math.floor((1 - spread) * 3) or 0)
    for s2 = 0, l do
      local u = s2 / l
      local theta = a0 + (a1 - a0) * u * u
      px = px - math.cos(theta)
      py = py - math.sin(theta)
      local r = 0.4 + (count > 1 and 1.1 or 1.4) * math.sin(math.pi * math.min(1, u * 1.1))
      for dy = -2, 2 do
        for dx = -2, 2 do
          local d = math.sqrt(dx * dx + dy * dy)
          local qx, qy = math.floor(px + dx + 0.5), math.floor(py + dy + 0.5)
          if d <= r + 0.7 and d > r then
            put_if_empty(out, qx, qy, C.blood)                    -- contorno da cauda
          elseif d <= r then
            local col = u > 0.82 and C.tip or (d < r - 0.8 and C.hot or C.crimson)
            if u < 0.12 then col = C.blood end
            put(out, qx, qy, col)
          end
        end
      end
    end
  end
end

-- Um pouco de energia por cima do corpo, sutil: brilho na borda de trás e faíscas soltas.
local function body_energy(out, base, m, level, k)
  local amount = level == 1 and 0.02 or level == 2 and 0.035 or 0.05
  for y = m.top + 2, m.feet - 4 do
    local first = true
    for x = 0, W - 1 do
      if opaque(base, x, y) then
        local c = out:getPixel(x, y)
        if first and noise(0, y // 2, k // 2) < 0.5 + level * 0.12 then
          out:drawPixel(x, y, mix(c, C.hot, 0.45))   -- borda de trás acesa
        elseif noise(x // 2, y // 2, k // 3 + 11) < amount then
          out:drawPixel(x, y, mix(c, C.pink, 0.5))   -- veio de energia passando
        end
        first = false
      end
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
  -- Demônio-raposa. Atrás do corpo: caudas de energia (1, 3 e 5) e aura; depois o corpo com um
  -- pouco de energia por cima; na frente: chifres de energia, olhos e fagulhas.
  tails(out, img, m, k, ({ 1, 3, 5 })[level], ({ 20, 21, 23 })[level])
  aura(img, out, m, level, k, breath)
  out:drawImage(body, Point(0, 0))
  body_energy(out, img, m, level, k)
  local back_x = m.hx0 + 3
  horn(out, back_x, m.top + 1, -1, level == 3 and 8 or 6, k)
  if level >= 2 then horn(out, m.hx1 - 3, m.top + 1, 1, level == 3 and 6 or 4, k) end
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
