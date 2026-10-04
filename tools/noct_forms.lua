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
local ANIMS = { "crouch_loop", "transform" }
for _, t in ipairs(spr.tags) do
  if not t.name:match("^c%d_") then table.insert(ANIMS, t.name) end
end
if app.params.anims then
  ANIMS = {}
  for n in string.gmatch(app.params.anims, "[^,]+") do table.insert(ANIMS, n) end
end
-- Só existe uma Forma Demoníaca: a raposa de nove caudas, que usa o visual do nível 3 (c3_*).
local LEVELS = { 3 }
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

-- MANTO DE ENERGIA (inspirado no manto de chakra da raposa): a energia cobre o corpo.
-- Por cima do corpo, um véu carmesim translúcido (mais forte a cada nível; no 3 o corpo quase some
-- no manto escuro); em volta, a casca do manto, com bolhas na borda e um contorno escuro.
-- p = 0..1 (força do manto; < 1 só na transição).
local function veil(img, level, p)
  local out = img:clone()
  local t = ({ 0.22, 0.38, 0.62 })[level] * p
  local to = level == 3 and hex("#2a0612") or C.crimson
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 and not is_energy(c) then
        local tt = t
        if level == 3 and is_skin(c) then tt = math.min(0.85, t + 0.15) end
        out:drawPixel(x, y, mix(c, to, tt))
      end
    end
  end
  return out
end

local function cloak(base, out, m, level, k, breath, p)
  local thick = math.floor(({ 1, 2, 2 })[level] * p + 0.5)
  local filled, ring = {}, {}
  local frontier = {}
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if opaque(base, x, y) then filled[y * W + x] = 0; table.insert(frontier, y * W + x) end
    end
  end
  -- Casca: camadas cheias (coerentes), mais uma camada de bolhas na borda.
  for r = 1, thick + 1 do
    local nxt = {}
    for _, key in ipairs(frontier) do
      local x, y = key % W, key // W
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = x + d[1], y + d[2]
        local nk = ny * W + nx
        if nx >= 0 and ny >= 0 and nx < W and ny < H and filled[nk] == nil and ny <= m.feet then
          local keep = r <= thick or noise(nx // 2, ny // 2, k // 2 + 3) < 0.35 + 0.3 * breath
          if keep then
            filled[nk] = r
            ring[nk] = r
            table.insert(nxt, nk)
          end
        end
      end
    end
    frontier = nxt
  end
  -- Cores: dentro da casca vermelho vivo; borda externa escura (lê bem em qualquer fundo).
  for key in pairs(ring) do
    local x, y = key % W, key // W
    local outer = false
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      if filled[(y + d[2]) * W + x + d[1]] == nil then outer = true end
    end
    local col
    if outer then col = level == 3 and C.blood or C.deep
    elseif level == 3 then col = (noise(x // 2, y // 2, k // 2) < 0.3) and C.hot or C.red
    else col = (noise(x // 2, y // 2, k // 2) < 0.25) and C.pink or C.crimson end
    put_if_empty(out, x, y, col)
  end
  -- Chamas curtas subindo do alto do manto (ombros e cabeça), no ritmo da respiração.
  local max_len = math.floor(({ 2, 3, 4 })[level] * p + 0.5)
  for x = 0, W - 1 do
    -- Sem chamas em cima da cabeça: ali ficam as orelhas, que precisam ser lidas.
    if x >= m.hx0 - 2 and x <= m.hx1 + 2 then goto next_col end
    for y = math.max(0, m.top - 4), math.min(m.feet, m.top + 20) do
      if filled[y * W + x] ~= nil then
        local n = noise(x, 0, k // 2)
        if n < 0.45 then
          local len = math.floor((0.5 + n) * max_len * (0.6 + 0.6 * breath) + 0.5)
          for i = 1, len do
            put_if_empty(out, x, y - i, i == len and C.tip or (i == 1 and C.crimson or C.pink))
          end
        end
        break
      end
    end
    ::next_col::
  end
end

-- Olhos carmesim (um ponto de luz no rosto).
local function eyes(out, m, level)
  if not m.ex then return end
  local ex, ey = m.ex - 2, m.ey
  put(out, ex, ey, level == 3 and C.eye3 or C.eye)
  put(out, ex - 1, ey, level == 3 and C.eye or C.pink)
end

-- ORELHAS de energia da raposa (no lugar de chifres físicos): triângulos do manto saindo do alto
-- da cabeça, um atrás e um na frente, apontando para cima e um pouco para trás.
local function ear(out, x, y, h, lean, k)
  for i = 0, h - 1 do
    local half = math.floor((h - 1 - i) * 0.45 + 0.3) -- base larga, ponta fina
    local cx = x + math.floor(lean * i + 0.5)
    for dx = -half, half do
      local edge = dx == -half or dx == half
      local tip = i >= h - 2
      local col = tip and ((k // 2) % 2 == 0 and C.tip or C.pink) or (edge and C.deep or (dx >= 0 and C.pink or C.hot))
      put(out, cx + dx, y - i, col)
    end
  end
end

-- Caudas de raposa de ENERGIA no estilo da folha "Guerreiro Raposa Demoníaco" (ver
-- tools/noct_raposa.lua): largas como chama, borda carmesim acesa, miolo vinho escuro com veios,
-- ponta fina curvada e contorno quase preto. Saem da lombar e sobem curvando; nível 1 = 1 cauda,
-- nível 2 = 3, nível 3 = o leque de 9.
local TAIL = { dark = hex("#3c0718"), mid = hex("#9f0c2b"), vein = hex("#db043c"), rim = hex("#ec2a58"), line = hex("#120610") }
local TAIL_SET = {
  [1] = { angles = { 2.0 }, width = 7.5, len = 1.0 },
  [3] = { angles = { 1.25, 1.85, 2.45 }, width = 6.5, len = 0.92 },
  -- Nível 3: leque largo em volta das costas, cada cauda quase reta saindo da raiz (como na folha).
  [5] = { angles = { -0.5, -0.15, 0.2, 0.55, 0.9, 1.25, 1.6, 1.95, 2.3 }, width = 8.5, len = 0.85, fan = true },
}
local function sheet_tail(out, x0, y0, a0, a1, len, width, k)
  local pts = {}
  local px, py = x0, y0
  for s2 = 0, len do
    local u = s2 / len
    local th = a0 + (a1 - a0) * u + (u > 0.75 and (u - 0.75) * 2.4 or 0) + math.sin(k * 0.9 + u * 3) * 0.06
    px, py = px - math.cos(th), py - math.sin(th)
    local r = u < 0.35 and width * (0.45 + 0.55 * u / 0.35) or width * (1 - ((u - 0.35) / 0.65) ^ 1.4)
    pts[#pts + 1] = { x = px, y = py, th = th, u = u, r = math.max(0.5, r) }
  end
  local mask, list = {}, {}
  for _, p in ipairs(pts) do
    local nx, ny = math.sin(p.th), -math.cos(p.th)
    for l = -p.r, p.r + 0.01, 0.5 do
      local qx, qy = math.floor(p.x + nx * l + 0.5), math.floor(p.y + ny * l + 0.5)
      if qx >= 0 and qy >= 0 and qx < W and qy < H then
        local key = qy * W + qx
        local rec = mask[key]
        if not rec then rec = { x = qx, y = qy, lat = 9 }; mask[key] = rec; list[#list + 1] = rec end
        if math.abs(l / p.r) < math.abs(rec.lat) then rec.lat, rec.u = l / p.r, p.u end
      end
    end
  end
  for _, r in ipairs(list) do
    local edge = false
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      if not mask[(r.y + d[2]) * W + r.x + d[1]] then edge = true end
    end
    local col
    if edge or r.u > 0.93 then col = TAIL.rim
    elseif math.abs(r.lat) > 0.7 or r.u > 0.85 then col = TAIL.mid
    else
      local vein = math.floor((r.lat + 1) * 3 + r.u * 4 + k * 0.5) % 4 == 0 and r.u > 0.15
      col = vein and TAIL.vein or (r.u < 0.2 and TAIL.mid or TAIL.dark)
    end
    put(out, r.x, r.y, col)
  end
  for _, r in ipairs(list) do
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      put_if_empty(out, r.x + d[1], r.y + d[2], TAIL.line)
    end
  end
end

local function tails(out, base, m, k, count, len)
  -- Raiz na lombar (borda de trás do corpo na cintura), como na folha.
  local y0 = m.top + 19
  local x0 = nil
  for x = 0, W - 1 do if opaque(base, x, y0) then x0 = x + 2; break end end
  if not x0 then return end
  local set = TAIL_SET[count] or TAIL_SET[1]
  local body_h = m.feet - m.top
  local scale = len / 23          -- len vem menor na transição (as caudas crescem)
  for t = #set.angles, 1, -1 do
    local l = math.floor(body_h * set.len * scale + 0.5)
    local a = set.angles[t]
    local a0, a1 = 0.45, a
    if set.fan then a0, a1 = a - 0.55, a + 0.15 end
    if l >= 4 then sheet_tail(out, x0, y0, a0, a1, l, set.width * math.min(1, scale + 0.2), k + t) end
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

-- Quadros em que a cabeça NÃO é o alto do desenho (punho, perna, chama ou energia por cima, ou
-- deitado): ali as orelhas e os olhos ficariam no lugar errado, então só o manto e as caudas entram.
-- (Análise quadro a quadro das formas; índices dos quadros de cada animação, a partir de 1.)
local NO_HEAD = {
  kick = { 4, 5 }, cross = { 2, 3 }, charged = { 3, 4 }, cast = { 4 }, up_punch = { 4, 5, 6, 7 },
  uppercut = { 4, 5, 6, 7 }, low_punch = { 4, 5 }, slam = { 2 }, air_finish = { 1 },
  death = { 2, 4, 5, 6, 7, 8 }, ultimate_burst = { 3, 4, 5, 6, 7 }, ultimate_pose = { 4 },
  dash = { 6 }, air_dash = { 5 },
}
local function head_visible(anim, i)
  for _, f in ipairs(NO_HEAD[anim] or {}) do if f == i then return false end end
  return true
end

-- p = força da forma (1 = forma completa; menor na transição). head = desenhar orelhas e olhos.
-- no_tails = sem as caudas paradas (nos golpes em que as caudas são a arma).
local function form_frame(img, level, k, n, p, head, no_tails)
  p = p or 1
  if head == nil then head = true end
  local m = measure(img)
  local breath = 0.5 + 0.5 * math.sin(k / math.max(1, n) * math.pi * 2)
  local out = Image(W, H, ColorMode.RGB)
  -- Atrás do corpo: caudas (1, 3, 5) e a casca do manto; depois o corpo com o véu do manto e veios;
  -- na frente: orelhas de energia, olhos e fagulhas.
  local count = math.max(0, math.floor(({ 1, 3, 5 })[level] * p + 0.5))
  if count > 0 and not no_tails then tails(out, img, m, k, count, math.floor(({ 20, 21, 23 })[level] * (0.4 + 0.6 * p))) end
  cloak(img, out, m, level, k, breath, p)
  out:drawImage(veil(img, level, p), Point(0, 0))
  body_energy(out, img, m, level, k)
  if p > 0.3 and head then
    local h = math.floor(({ 6, 7, 8 })[level] * p + 0.5)
    local base_y = m.top - 1
    ear(out, m.hx0 + 2, base_y, h, -0.35, k)        -- orelha de trás
    ear(out, m.hx1 - 3, base_y, h - 1, -0.1, k)     -- orelha da frente
  end
  if head then eyes(out, m, level) end
  if level >= 2 and p >= 1 then sparks(out, img, m, k, level == 2 and 0.012 or 0.02) end
  return out
end

-- TRANSIÇÃO ao transformar: o Noct se curva (agachado) e o manto cresce de nada até a forma
-- completa, com um anel de energia explodindo para fora no meio; termina de pé.
local function transform_frames(level)
  local crouch, idle = frames_of("crouch"), frames_of("idle")
  local seq = { crouch[1], crouch[2], crouch[#crouch], crouch[#crouch], crouch[#crouch], idle[1], idle[1], idle[1] }
  local frames = {}
  for i, img in ipairs(seq) do
    local p = math.min(1, (i - 1) / 5)
    local f = form_frame(img, level, i - 1, #seq, p)
    if i >= 4 and i <= 6 then   -- anel de choque
      local m = measure(img)
      local cx, cy = (m.hx0 + m.hx1) // 2, (m.top + m.feet) // 2
      local r = 10 + (i - 4) * 9
      for a2 = 0, 359, 3 do
        local x = math.floor(cx + math.cos(math.rad(a2)) * r + 0.5)
        local y = math.floor(cy + math.sin(math.rad(a2)) * r * 0.75 + 0.5)
        put_if_empty(f, x, y, i == 6 and C.crimson or C.pink)
      end
    end
    frames[i] = f
  end
  return frames
end

-------------------------------------------------------------------------------
local preview = app.params.preview
local out_spr = preview and Sprite(W, H, ColorMode.RGB) or nil
local first = true
local ranges = {}

for _, level in ipairs(LEVELS) do
  for _, anim in ipairs(ANIMS) do
    local src = (anim == "crouch_loop" or anim == "transform") and {} or frames_of(anim)
    if anim == "crouch_loop" then
      -- A pose abaixada final, repetida, com a aura se mexendo (8 quadros).
      local crouch = frames_of("crouch")
      for i = 1, 8 do src[i] = crouch[#crouch] end
    end
    local frames = {}
    for i, img in ipairs(src) do frames[i] = form_frame(img, level, i - 1, #src, 1, head_visible(anim, i)) end
    if anim == "transform" then frames = transform_frames(level) end
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
