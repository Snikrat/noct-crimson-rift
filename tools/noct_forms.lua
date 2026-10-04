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
    local fan = count >= 5 and 2.6 or 1.9                              -- no nível 3 o leque abre mais
    local a1 = 0.6 + spread * fan + math.sin((k + t * 2) * 0.6) * 0.15 -- termina para cima, em leque
    local l = len - math.floor(spread * 5)
    local px, py = x0, y0 + (count > 1 and math.floor((1 - spread) * 3) or 0)
    for s2 = 0, l do
      local u = s2 / l
      local theta = a0 + (a1 - a0) * u * u
      px = px - math.cos(theta)
      py = py - math.sin(theta)
      local r = 0.4 + (count >= 5 and 0.85 or count > 1 and 1.1 or 1.4) * math.sin(math.pi * math.min(1, u * 1.1))
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
-- GOLPES INÉDITOS DAS FORMAS 2 E 3: quem ataca é a energia da raposa (caudas, garras, fogo e a
-- cabeça de raposa formada pelo manto); o corpo do Noct fica numa pose de base, com o manto.
-- Quadro maior que o normal (o golpe vai longe): BIG_W x BIG_H, com o quadro normal colado em
-- (DX, DY); os pés ficam em (ax + DX, ay + DY) (crimson.json).
local DX, DY = 20, 26
local BIG_W, BIG_H = W + 64, H + 30

local function bput(img, x, y, c) if x >= 0 and y >= 0 and x < BIG_W and y < BIG_H then img:drawPixel(x, y, c) end end
local function bempty(img, x, y)
  return x >= 0 and y >= 0 and x < BIG_W and y < BIG_H and pc.rgbaA(img:getPixel(x, y)) == 0
end

-- Pose do corpo: quadro i da animação base anim (com orelhas e olhos só se a cabeça aparece).
local function P(anim, i)
  local list = frames_of(anim)
  if i < 0 then i = #list + 1 + i end
  return { img = list[i], head = head_visible(anim, i) }
end

-- Corpo com o manto da forma, colado no quadro grande. tails = desenhar as caudas paradas
-- (falso quando as próprias caudas são o golpe).
local function body_frame(pose, level, k, n, tails_on)
  local img = pose.img
  local f = form_frame(img, level, k, n, 1, pose.head, not tails_on)
  local big = Image(BIG_W, BIG_H, ColorMode.RGB)
  big:drawImage(f, Point(DX, DY))
  local m = measure(img)
  -- Borda de trás na cintura (base das caudas) e frente do ombro (base das garras).
  local back, front
  for x = 0, W - 1 do if opaque(img, x, m.top + 19) then back = x + 2; break end end
  for x = W - 1, 0, -1 do if opaque(img, x, m.top + 12) then front = x - 1; break end end
  local b = {
    top = m.top + DY, feet = m.feet + DY, hx0 = m.hx0 + DX, hx1 = m.hx1 + DX,
    back = (back or m.hx0 - 2) + DX, front = (front or m.hx1 + 2) + DX,
  }
  b.cx = (b.hx0 + b.hx1) // 2
  return big, b
end

-- Traço grosso de energia saindo de (x0, y0), com o ângulo curvando de a0 até a1 (0 = para trás,
-- pi/2 = para cima, pi = para a frente). rmax = grossura no meio; ponta clara.
local function energy_stroke(img, x0, y0, a0, a1, len, rmax, curve)
  local px, py = x0, y0
  for s2 = 0, len do
    local u = s2 / math.max(1, len)
    local theta = a0 + (a1 - a0) * u ^ (curve or 2)
    px = px - math.cos(theta)
    py = py - math.sin(theta)
    local r = 0.4 + rmax * math.sin(math.pi * math.min(1, u * 1.1))
    for dy = -3, 3 do
      for dx = -3, 3 do
        local d = math.sqrt(dx * dx + dy * dy)
        local qx, qy = math.floor(px + dx + 0.5), math.floor(py + dy + 0.5)
        if d <= r + 0.7 and d > r then
          if bempty(img, qx, qy) then bput(img, qx, qy, C.blood) end
        elseif d <= r then
          bput(img, qx, qy, u > 0.82 and C.tip or (d < r - 0.8 and C.hot or C.crimson))
        end
      end
    end
  end
  return px, py
end

-- Rastro do golpe: arco fino e claro por onde a ponta passou.
local function arc(img, cx, cy, r, a0, a1, col)
  local steps = math.max(4, math.floor(math.abs(a1 - a0) * r))
  for s = 0, steps do
    local a = a0 + (a1 - a0) * s / steps
    local x = math.floor(cx - math.cos(a) * r + 0.5)
    local y = math.floor(cy - math.sin(a) * r + 0.5)
    if bempty(img, x, y) then bput(img, x, y, col) end
  end
end

-- Garra de energia: braço de energia saindo do ombro e três unhas claras na ponta.
local function claw(img, x0, y0, ang, len)
  if len <= 0 then return end
  local ex, ey = energy_stroke(img, x0, y0, ang, ang, len, 1.6)
  for c = -1, 1 do
    local a = ang + c * 0.5
    for i = 1, 5 do
      bput(img, math.floor(ex - math.cos(a) * i + 0.5), math.floor(ey - math.sin(a) * i + 0.5), i >= 3 and C.tip or C.pink)
    end
  end
end

-- Bola de fogo de raposa (com rastro opcional para trás).
local function orb(img, cx, cy, r, trail)
  for i = 1, trail or 0 do
    bput(img, cx - r - i, cy, i < 3 and C.hot or C.blood)
    if i % 2 == 0 then bput(img, cx - r - i, cy - 1, C.crimson) end
  end
  for dy = -r - 1, r + 1 do
    for dx = -r - 1, r + 1 do
      local d = math.sqrt(dx * dx + dy * dy)
      if d <= r + 0.6 then
        bput(img, cx + dx, cy + dy, d < r * 0.4 and C.tip or (d < r * 0.75 and C.pink or (d <= r - 0.3 and C.hot or C.blood)))
      end
    end
  end
end

-- Anel de choque (elipse).
local function ring(img, cx, cy, r, col, flat)
  for a = 0, 359, 3 do
    local x = math.floor(cx + math.cos(math.rad(a)) * r + 0.5)
    local y = math.floor(cy + math.sin(math.rad(a)) * r * (flat or 0.7) + 0.5)
    if bempty(img, x, y) then bput(img, x, y, col) end
  end
end

-- Cabeça de raposa feita de energia, olhando para a frente: crânio, focinho, orelhas, olho e
-- mandíbula que abre (open = px de abertura).
local function fox_head(img, x, y, s, open)
  for dy = -s, s + open do
    for dx = -s, s * 2 do
      local inside
      if dx <= 0 then
        inside = (dx / s) ^ 2 + (dy / s) ^ 2 <= 1                     -- crânio
      elseif dy <= 0 then
        inside = dy >= -s + dx * 0.5                                   -- focinho de cima
      else
        inside = dy >= open and dy <= open + 2 and dx <= s * 2 - 2     -- mandíbula de baixo
      end
      if inside then
        local edge = (dx <= 0 and (dx / s) ^ 2 + (dy / s) ^ 2 > 0.7) or dy == open + 2 or (dx > 0 and dy <= 0 and dy <= -s + dx * 0.5 + 1)
        bput(img, x + dx, y + dy, edge and C.blood or ((dx + dy) % 5 == 0 and C.pink or C.hot))
      end
    end
  end
  -- Dentes (em cima e embaixo) e língua de luz dentro da boca aberta.
  for dx = 3, s * 2 - 2, 2 do
    bput(img, x + dx, y + 1, C.tip)
    if open > 2 then bput(img, x + dx, y + open - 1, C.tip) end
  end
  -- Olho e duas orelhas para trás.
  bput(img, x + 1, y - s // 2, C.eye3)
  bput(img, x + 2, y - s // 2, C.eye3)
  for e = 0, 1 do
    local ex = x - 2 - e * 4
    for i = 0, s - 1 do
      local half = (s - 1 - i) // 3
      for dx = -half, half do
        bput(img, ex - i // 2 + dx, y - s + 1 - i, i >= s - 2 and C.tip or (e == 0 and C.hot or C.crimson))
      end
    end
  end
end

-- Monta um golpe: para cada pose, o corpo com o manto, e por cima o desenho do ataque.
local function make_move(level, poses, tails_on, draw)
  local frames = {}
  for i, pose in ipairs(poses) do
    local big, m = body_frame(pose, level, i - 1, #poses, tails_on)
    draw(big, m, i)
    frames[i] = big
  end
  return frames
end
local function rep(pose, n) local t = {} for i = 1, n do t[i] = pose end return t end

local NEW_MOVES = {}

-- ===== NÍVEL 2, RUPTURA: as três caudas e as garras do manto viram as armas =====
NEW_MOVES[2] = {
  -- Chicote das caudas: as três caudas passam por cima da cabeça e chicoteiam à frente.
  tailwhip = function(level)
    local ang = { 1.2, 1.8, 2.6, 3.05, 2.9, 2.0 }
    local len = { 18, 23, 28, 32, 27, 20 }
    return make_move(level, rep(P("jab", 1), 6), false, function(img, m, i)
      if i >= 3 and i <= 5 then arc(img, m.back + 8, m.top - 2, len[i] + 2, ang[i - 1], ang[i], C.tip) end
      for t = 1, 3 do
        energy_stroke(img, m.back, m.top + 19 + t, 1.7, ang[i] - (t - 2) * 0.2, len[i] + 18 - t * 2, 1.2, 0.6)
      end
    end)
  end,
  -- Garra do manto: um braço de energia sai do ombro, rasga à frente e volta.
  claw = function(level)
    local poses = { P("cross", 1), P("cross", 1), P("cross", 2), P("cross", 3), P("cross", 3), P("cross", 4) }
    local len = { 4, 12, 24, 34, 22, 6 }
    return make_move(level, poses, true, function(img, m, i)
      if i == 4 then
        for s = -1, 1 do arc(img, m.front + 26, m.top + 12 + s * 4, 10, 0.9, 2.2, C.tip) end
      end
      claw(img, m.front, m.top + 12, math.pi - 0.1, len[i])
    end)
  end,
  -- Pião das caudas: abaixado, as três caudas giram em volta do corpo (acerta dos dois lados).
  tailspin = function(level)
    return make_move(level, rep(P("crouch", -1), 6), false, function(img, m, i)
      local cy = m.feet - 10
      ring(img, m.cx, cy, 26, C.blood, 0.45)
      for t = 0, 2 do
        local a = (i - 1) * 1.05 + t * 2.09
        energy_stroke(img, m.cx, cy, a, a + 0.7, 26, 1.1)
      end
    end)
  end,
  -- Finalizador: as caudas sobem bem alto e desabam na frente, rachando o chão.
  tailslam = function(level)
    local poses = { P("jab", 1), P("jab", 1), P("jab", 1), P("crouch", -1), P("crouch", -1), P("crouch", -1), P("jab", 1) }
    local ang = { 1.5, 1.6, 1.7, 3.6, 3.75, 3.75, 2.2 }
    local len = { 22, 28, 34, 34, 32, 28, 18 }
    return make_move(level, poses, false, function(img, m, i)
      for t = 1, 3 do
        energy_stroke(img, m.back, m.top + 18 + t, 1.7, ang[i] - (t - 2) * 0.15, len[i] + 18 - t, 1.4, 0.6)
      end
      if i >= 4 and i <= 6 then
        local gx = m.front + 24
        for dx = -12, 12 do   -- rachadura no chão e pedaços subindo
          if (dx + i) % 3 ~= 0 then bput(img, gx + dx, m.feet + 1, C.hot) end
          if dx % 4 == 0 then bput(img, gx + dx, m.feet - math.floor(math.abs(dx) / 3) - (i - 3) * 2, C.pink) end
        end
        ring(img, gx, m.feet - 3, 6 + (i - 4) * 8, i == 6 and C.crimson or C.tip, 0.4)
      end
    end)
  end,
  -- No ar: chicote das caudas.
  air_tailwhip = function(level)
    local ang = { 1.4, 2.2, 2.9, 3.15, 2.4 }
    local len = { 18, 24, 30, 28, 20 }
    return make_move(level, rep(P("air_punch", 1), 5), false, function(img, m, i)
      if i >= 2 and i <= 4 then arc(img, m.back + 8, m.top - 2, len[i] + 2, ang[i - 1], ang[i], C.tip) end
      for t = 1, 3 do
        energy_stroke(img, m.back, m.top + 19 + t, 1.7, ang[i] - (t - 2) * 0.22, len[i] + 18 - t * 2, 1.2, 0.6)
      end
    end)
  end,
  -- No ar: garra para baixo, em diagonal.
  air_claw = function(level)
    local len = { 6, 16, 28, 30, 12 }
    return make_move(level, rep(P("air_kick", 1), 5), true, function(img, m, i)
      if i == 3 then arc(img, m.front + 14, m.top + 30, 12, 1.6, 3.4, C.tip) end
      claw(img, m.front, m.top + 14, math.pi + 0.55, len[i])
    end)
  end,
}

-- ===== NÍVEL 3, CONSUMIDO: cinco caudas, garras em X, fogo de raposa e a cabeça da raposa =====
NEW_MOVES[3] = {
  -- Rajada de caudas: as cinco caudas furam à frente, uma por vez, em alturas diferentes.
  barrage = function(level)
    return make_move(level, rep(P("jab", 1), 7), false, function(img, m, i)
      for t = 1, 5 do
        local active = (i - 1) == t or (i - 2) == t
        local a = active and (math.pi - 0.05 + (t - 3) * 0.09) or (1.1 + t * 0.28)
        energy_stroke(img, m.back, m.top + 16 + t, active and 1.7 or 0.5, a, active and 50 or 15, active and 1.1 or 0.8, active and 0.7 or 2)
      end
    end)
  end,
  -- Garras em X: duas garras do manto cruzam à frente (uma de cima, outra de baixo).
  xclaws = function(level)
    local poses = { P("cross", 1), P("cross", 2), P("cross", 2), P("cross", 3), P("cross", 3), P("cross", 4) }
    local len = { 6, 14, 26, 34, 24, 8 }
    return make_move(level, poses, true, function(img, m, i)
      claw(img, m.front, m.top + 6, math.pi + 0.45 - i * 0.1, len[i])
      claw(img, m.front, m.top + 20, math.pi - 0.45 + i * 0.1, len[i])
      if i == 4 then ring(img, m.front + 30, m.top + 13, 8, C.tip) end
    end)
  end,
  -- Fogo de raposa: três bolas giram em volta do Noct e disparam à frente.
  foxfire = function(level)
    local poses = {}
    for i, img in ipairs(frames_of("cast")) do poses[i] = { img = img, head = head_visible("cast", i) } end
    return make_move(level, poses, true, function(img, m, i)
      local cy = m.top + 18
      local n = #poses
      for t = 0, 2 do
        if i <= n - 3 then
          local a = i * 0.9 + t * 2.09
          orb(img, m.cx + math.floor(math.cos(a) * 17), cy + math.floor(math.sin(a) * 11), 2)
        else
          orb(img, m.front + (i - n + 3) * 16 + t * 5, cy - 5 + t * 5, 3, 6)
        end
      end
    end)
  end,
  -- Mordida da raposa: o manto forma uma cabeça de raposa que avança e morde.
  foxbite = function(level)
    local d = frames_of("dash")
    local poses = {}
    local pick = { 1, 2, 3, #d, #d, #d, #d }
    for i, f in ipairs(pick) do poses[i] = { img = d[f], head = head_visible("dash", f) } end
    local open = { 1, 3, 5, 7, 0, 0, 0 }
    local reach = { 2, 8, 16, 22, 28, 18, 8 }
    return make_move(level, poses, true, function(img, m, i)
      -- Pescoço de energia ligando o manto à cabeça.
      energy_stroke(img, m.front - 2, m.top + 13, math.pi, math.pi, reach[i], 2.0)
      fox_head(img, m.front + reach[i] + 2, m.top + 12, 7, open[i])
      if i == 5 then ring(img, m.front + reach[i] + 12, m.top + 14, 9, C.tip) end
    end)
  end,
  -- Finalizador: as cinco caudas se abrem em volta do corpo inteiro e explodem em anéis.
  tailburst = function(level)
    local poses = { P("crouch", 1), P("crouch", -1), P("crouch", -1), P("idle", 1), P("idle", 1), P("idle", 1), P("idle", 1), P("idle", 1) }
    return make_move(level, poses, false, function(img, m, i)
      local cy = m.top + 20
      local grow = math.min(1, i / 4)
      for t = 0, 4 do
        local a = t * 1.256 + i * 0.15
        energy_stroke(img, m.cx, cy, a, a + 0.5, math.floor(14 + 20 * grow), 1.2)
      end
      if i >= 4 and i <= 7 then
        ring(img, m.cx, cy, 14 + (i - 4) * 11, C.tip)
        ring(img, m.cx, cy, 9 + (i - 4) * 11, C.hot)
      end
    end)
  end,
  -- No ar: rajada de caudas.
  air_barrage = function(level)
    return make_move(level, rep(P("air_punch", 1), 6), false, function(img, m, i)
      for t = 1, 5 do
        local active = (i - 1) == t
        energy_stroke(img, m.back, m.top + 16 + t, active and 1.7 or 0.5, active and (math.pi - 0.1 + (t - 3) * 0.1) or (1.1 + t * 0.28),
          active and 46 or 14, active and 1.1 or 0.8, active and 0.7 or 2)
      end
    end)
  end,
  -- No ar: fogo de raposa disparado para baixo, em diagonal.
  air_foxfire = function(level)
    return make_move(level, rep(P("air_kick", 1), 5), true, function(img, m, i)
      for t = 0, 2 do
        if i <= 2 then
          orb(img, m.cx - 10 + t * 10, m.top - 2 + (t % 2) * 3, 2)
        else
          local s = (i - 2) * 12
          orb(img, m.front + s + t * 4, m.top + 14 + s + t * 3 - 4, 3)
        end
      end
    end)
  end,
}

-- Medidas dos golpes no crimson.json: quadro grande, pés no mesmo ponto do quadro normal.
local MOVE_W, MOVE_H, MOVE_DX, MOVE_DY = BIG_W, BIG_H, DX, DY

-------------------------------------------------------------------------------
local preview = app.params.preview
local out_spr = preview and Sprite(W, H, ColorMode.RGB) or nil
local first = true
local ranges = {}
if app.params.moves == "only" then ANIMS = {} end
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
-- Golpes inéditos (níveis 2 e 3), em quadro grande: assets/hero/crimson/c<n>_<golpe>.png.
local move_count = 0
for _, level in ipairs(LEVELS) do
  for name, make in pairs(NEW_MOVES[level] or {}) do
    local frames = make(level)
    local strip = Image(MOVE_W * #frames, MOVE_H, ColorMode.RGB)
    for i, img in ipairs(frames) do strip:drawImage(img, Point((i - 1) * MOVE_W, 0)) end
    strip:saveAs(app.fs.joinPath(app.params.moves_out or crimson_dir, "c" .. level .. "_" .. name .. ".png"))
    move_count = move_count + 1
  end
end
print("golpes novos: " .. move_count .. " (quadro " .. MOVE_W .. "x" .. MOVE_H .. ", pés + " .. MOVE_DX .. "," .. MOVE_DY .. ")")
if preview then
  for _, r in ipairs(ranges) do local t = out_spr:newTag(r[2], r[3]); t.name = r[1] end
  out_spr:saveAs(app.fs.joinPath(root, "art_source", "personagem principal", "noct_forms.aseprite"))
  print("prévia: " .. #out_spr.frames .. " quadros")
else
  print("formas: " .. #LEVELS * #ANIMS .. " tiras gravadas")
end
