-- Rostos do Noct na Forma Demoníaca, para os diálogos: uma versão de cada uma das 30 expressões
-- para cada nível (N1 Juramento, N2 Ruptura, N3 Consumido), no mesmo visual das formas do jogo
-- (tools/noct_forms.lua): manto de energia de raposa em volta do corpo, duas orelhas de energia no
-- lugar dos chifres, caudas de energia (1, 3 e 5) subindo por trás dos ombros, véu carmesim por cima
-- e olhos acesos. O Noct não é redesenhado: a forma é uma camada sobre o rosto original.
--
-- Base: art_source/portraits/noct_wide/<expressão>.png (o mesmo rosto um pouco mais afastado,
-- gerado por tools/slice_portraits.gd). Saída: assets/hero/crimson/portrait_c<n>_<expressão>.png (72x72).
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/make_portraits.lua
--   --script-param faces=neutro,serio   só essas expressões
--   --script-param sheet=<arquivo.png>  também grava uma prancha com todas (prévia)

local root = app.fs.currentPath
local pc = app.pixelColor
local S = 72
local base_dir = app.fs.joinPath(root, "art_source", "portraits", "noct_wide")
local out_dir = app.fs.joinPath(root, "assets", "hero", "crimson")

local FACES = {
  "neutro", "serio", "desconfiado", "irritado", "bravo", "furioso", "surpreso", "chocado", "confuso", "pensativo",
  "determinado", "confiante", "sorrindo", "sarcastico", "cansado", "triste", "dor", "ferido", "sangrando", "olhar_lateral",
  "olhar_cima", "olhar_baixo", "fechando_olhos", "calmo", "sombrio", "maligno", "magia_olhos", "magia_aura", "em_combate", "ultimate",
}
if app.params.faces then
  FACES = {}
  for n in string.gmatch(app.params.faces, "[^,]+") do table.insert(FACES, n) end
end

-- Centro dos olhos (esquerdo, direito) em cada expressão, medido na base afastada.
local EYES = {
  neutro = { 32, 44, 46, 44 }, serio = { 28, 45, 42, 45 }, desconfiado = { 31, 48, 42, 48 }, irritado = { 34, 49, 46, 49 },
  bravo = { 33, 49, 46, 49 }, furioso = { 32, 49, 46, 49 }, surpreso = { 34, 44, 47, 44 }, chocado = { 33, 44, 45, 45 },
  confuso = { 31, 44, 45, 45 }, pensativo = { 31, 47, 46, 47 }, determinado = { 32, 47, 44, 47 }, confiante = { 34, 45, 46, 45 },
  sorrindo = { 33, 43, 44, 45 }, sarcastico = { 32, 46, 45, 47 }, cansado = { 30, 48, 43, 49 }, triste = { 35, 51, 46, 51 },
  dor = { 31, 49, 45, 49 }, ferido = { 34, 47, 46, 47 }, sangrando = { 30, 49, 41, 49 }, olhar_lateral = { 33, 47, 45, 47 },
  olhar_cima = { 33, 40, 47, 40 }, olhar_baixo = { 33, 50, 45, 50 }, fechando_olhos = { 32, 47, 45, 47 }, calmo = { 33, 47, 46, 47 },
  sombrio = { 34, 50, 47, 50 }, maligno = { 33, 50, 46, 50 }, magia_olhos = { 35, 51, 47, 51 }, magia_aura = { 34, 46, 46, 46 },
  em_combate = { 33, 47, 45, 48 }, ultimate = { 33, 47, 46, 48 },
}
-- Olhos fechados: sem brilho de olho aceso, só o rosto tingido.
local CLOSED = { fechando_olhos = true, dor = true }

local function hex(h) return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255) end
-- Mesma paleta das formas no jogo (tools/noct_forms.lua).
local C = {
  dark = hex("#320514"), deep = hex("#5f0622"), blood = hex("#850a2f"), red = hex("#a6232c"),
  crimson = hex("#bd1a45"), hot = hex("#e2174b"), pink = hex("#ee3f6f"), tip = hex("#f692b1"),
  eye = hex("#ff5a8a"), eye3 = hex("#ffd0de"), black = hex("#120610"), shade3 = hex("#2a0612"),
}

local function noise(x, y, k)
  local n = (x * 374761393 + y * 668265263 + k * 2147483647) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return (n % 1000) / 1000
end
local function mix(c, to, t)
  local r = pc.rgbaR(c) + (pc.rgbaR(to) - pc.rgbaR(c)) * t
  local g = pc.rgbaG(c) + (pc.rgbaG(to) - pc.rgbaG(c)) * t
  local b = pc.rgbaB(c) + (pc.rgbaB(to) - pc.rgbaB(c)) * t
  return pc.rgba(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5), 255)
end
local function lum(c) return (pc.rgbaR(c) * 3 + pc.rgbaG(c) * 6 + pc.rgbaB(c)) / 10 end
local function inside(x, y) return x >= 0 and y >= 0 and x < S and y < S end
local function alpha(img, x, y) return inside(x, y) and pc.rgbaA(img:getPixel(x, y)) or 0 end
local function put(img, x, y, c) if inside(x, y) then img:drawPixel(x, y, c) end end
local function put_if_empty(img, x, y, c) if inside(x, y) and pc.rgbaA(img:getPixel(x, y)) == 0 then img:drawPixel(x, y, c) end end
local function is_skin(c)
  local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
  return r > 120 and g > 60 and b < 120 and r > g * 1.15 and g > b
end

-- Base limpa: o redimensionamento deixa uma franja clara e semitransparente em volta do busto;
-- ela vira transparente (meio-tom fraco) ou a cor escura do vizinho (franja clara na borda).
local function clean(img)
  local out = Image(S, S, ColorMode.RGB)
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) >= 140 then out:drawPixel(x, y, pc.rgba(pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), 255)) end
    end
  end
  for pass = 1, 2 do
    local fix = {}
    for y = 0, S - 1 do
      for x = 0, S - 1 do
        local c = out:getPixel(x, y)
        if pc.rgbaA(c) > 0 then
          local edge = false
          for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            if alpha(out, x + d[1], y + d[2]) == 0 and y + d[2] < S then edge = true end
          end
          local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
          local sat = math.max(r, g, b) - math.min(r, g, b)
          if edge and lum(c) > 120 and sat < 70 then table.insert(fix, { x, y }) end
        end
      end
    end
    for _, p in ipairs(fix) do
      local x, y = p[1], p[2]
      local best = nil
      for dy = -2, 2 do
        for dx = -2, 2 do
          local c = inside(x + dx, y + dy) and out:getPixel(x + dx, y + dy) or 0
          if pc.rgbaA(c) > 0 and lum(c) < 110 and (not best or lum(c) < lum(best)) then best = c end
        end
      end
      if best then out:drawPixel(x, y, best) else out:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end
    end
  end
  return out
end

-- Medidas do busto: topo do cabelo e a faixa da cabeça logo abaixo dele.
local function measure(img)
  local m = { top = S, hx0 = S, hx1 = 0 }
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      if alpha(img, x, y) > 0 then m.top = math.min(m.top, y) end
    end
  end
  for y = m.top, m.top + 6 do
    for x = 0, S - 1 do
      if alpha(img, x, y) > 0 then m.hx0 = math.min(m.hx0, x); m.hx1 = math.max(m.hx1, x) end
    end
  end
  return m
end

-- Distância (passos de 4 vizinhos) de cada pixel vazio até o busto, até "maxd".
local function distance_field(img, maxd)
  local dist, frontier = {}, {}
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      if alpha(img, x, y) > 0 then dist[y * S + x] = 0; table.insert(frontier, y * S + x) end
    end
  end
  for r = 1, maxd do
    local nxt = {}
    for _, key in ipairs(frontier) do
      local x, y = key % S, key // S
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = x + d[1], y + d[2]
        if inside(nx, ny) and dist[ny * S + nx] == nil then
          dist[ny * S + nx] = r
          table.insert(nxt, ny * S + nx)
        end
      end
    end
    frontier = nxt
  end
  return dist
end

-- AURA: brilho escuro e esparso em volta (atrás de tudo), mais largo a cada nível.
local function aura(out, dist, level)
  local reach = ({ 5, 7, 9 })[level]
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local d = dist[y * S + x]
      if d and d > 0 and d <= reach then
        local f = 1 - d / (reach + 1)
        local n = noise(x, y, 7 + level)
        if n < f * 0.55 then put_if_empty(out, x, y, f > 0.6 and C.deep or C.dark) end
      end
    end
  end
end

-- CAUDAS de raposa de energia, por trás dos ombros: finas na base, cheias e felpudas no meio,
-- ponta afilada e clara; borda em tufos (pelo de chama) e contorno escuro próprio de cada cauda.
-- Cada cauda: base (x0, y0), controle (cx, cy) e ponta (tx, ty) de uma Bézier, largura máxima "w".
local function tail(out, x0, y0, cx, cy, tx, ty, w, seed)
  local n = 90
  local fill = {}
  local px0, py0 = x0, y0
  for i = 0, n do
    local u = i / n
    local a, b, c = (1 - u) * (1 - u), 2 * (1 - u) * u, u * u
    local px, py = a * x0 + b * cx + c * tx, a * y0 + b * cy + c * ty
    local tx_, ty_ = px - px0, py - py0
    local tl = math.sqrt(tx_ * tx_ + ty_ * ty_)
    if tl > 0 then tx_, ty_ = tx_ / tl, ty_ / tl else tx_, ty_ = 0, -1 end
    px0, py0 = px, py
    local prof
    if u < 0.6 then prof = 0.35 + 0.65 * math.sin(math.pi / 2 * u / 0.6)
    else prof = math.cos(math.pi / 2 * (u - 0.6) / 0.4) ^ 0.6 end
    local wave = 1 + 0.16 * math.sin(u * math.pi * 2 * 4.5 + seed) * math.min(1, u * 4) * (1 - u)
    local r = math.max(0.6, w * prof * wave)
    local R = math.ceil(r) + 1
    for dy = -R, R do
      for dx = -R, R do
        local d = math.sqrt(dx * dx + dy * dy)
        local qx, qy = math.floor(px + dx + 0.5), math.floor(py + dy + 0.5)
        if d <= r and inside(qx, qy) then
          local key = qy * S + qx
          local depth = d / r
          local side = (dx * ty_ - dy * tx_) >= 0 and 1 or -1     -- de que lado da linha central
          local old = fill[key]
          if not old or depth < old[1] then fill[key] = { depth, u, side, dx, dy } end
        end
      end
    end
  end
  for key in pairs(fill) do
    local x, y = key % S, key // S
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local nk = (y + d[2]) * S + x + d[1]
      if not fill[nk] then put(out, x + d[1], y + d[2], C.dark) end
    end
  end
  for key, f in pairs(fill) do
    local x, y = key % S, key // S
    local depth, u, side, dx, dy = f[1], f[2], f[3], f[4], f[5]
    local lit = (dx + dy) < 0                                  -- lado virado para cima/esquerda
    local col
    if u > 0.88 then col = depth < 0.55 and C.eye3 or C.tip
    elseif u > 0.76 then col = depth < 0.45 and C.tip or (lit and C.tip or C.pink)
    elseif depth > 0.8 then col = lit and C.crimson or C.blood
    elseif depth < 0.3 then col = C.hot
    else col = lit and C.pink or C.crimson end
    if u < 0.14 then col = depth > 0.5 and C.deep or C.blood end    -- base some atrás do ombro
    put(out, x, y, col)
  end
end

local TAILS = {
  -- {x0, y0, cx, cy, tx, ty, largura}: da base atrás do ombro até a ponta (desenhadas na ordem).
  [1] = { { 26, 72, -4, 52, 12, 10, 7.5 } },
  [2] = {
    { 46, 72, 78, 50, 60, 10, 6.0 },
    { 24, 72, -6, 66, 2, 30, 6.0 },
    { 27, 72, 2, 40, 18, 6, 6.6 },
  },
  [3] = {
    { 46, 72, 82, 62, 70, 30, 5.0 },
    { 45, 72, 74, 40, 56, 6, 5.3 },
    { 23, 72, -8, 72, -2, 44, 5.0 },
    { 25, 72, -6, 48, 4, 18, 5.3 },
    { 28, 72, 6, 36, 24, 4, 5.5 },
  },
}

-- CASCA DO MANTO: faixa de energia colada no busto, com bolhas largas na borda e contorno escuro
-- (lê bem no fundo do quadro). Por dentro mais quente, por fora mais fundo.
local function cloak(out, dist, m, level)
  local thick = ({ 2, 2, 3 })[level]
  local shell = {}
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local d = dist[y * S + x]
      if d and d > 0 then
        local over_head = y < m.top + 6 and x > m.hx0 + 4 and x < m.hx1 - 4
        local bump = 0
        if not over_head then
          if noise(x // 4, y // 4, 3 + level) < 0.5 then bump = 1 end
          if noise(x // 5, y // 5, 13 + level) < 0.22 then bump = bump + 1 end
        end
        if d <= thick + bump then shell[y * S + x] = d end
      end
    end
  end
  for key, d in pairs(shell) do
    local x, y = key % S, key // S
    local outer = false
    for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local nx, ny = x + o[1], y + o[2]
      if inside(nx, ny) and not shell[ny * S + nx] and (dist[ny * S + nx] or 0) > 0 then outer = true end
    end
    local col
    if outer then col = level == 3 and C.dark or C.deep
    elseif d == 1 then col = level == 3 and C.hot or C.pink
    else col = level == 3 and C.red or C.crimson end
    put(out, x, y, col)
  end
  -- Chamas curtas subindo dos ombros (fora da cabeça, onde ficam as orelhas).
  local len = ({ 3, 4, 6 })[level]
  for x = 0, S - 1 do
    if x < m.hx0 - 2 or x > m.hx1 + 2 then
      for y = 0, S - 1 do
        if shell[y * S + x] then
          local n = noise(x // 2, 1, level)
          if n < 0.5 then
            local l = math.floor((0.4 + n * 1.4) * len + 0.5)
            for i = 1, l do put_if_empty(out, x, y - i, i == l and C.tip or (i == 1 and C.crimson or C.pink)) end
            put_if_empty(out, x - 1, y - 1, C.deep)
          end
          break
        end
      end
    end
  end
end

-- VÉU: o busto tingido de carmesim (no N3, quase todo escuro, só os olhos acesos).
local function veil(img, level)
  local out = Image(S, S, ColorMode.RGB)
  local t = ({ 0.2, 0.32, 0.62 })[level]
  local to = level == 3 and C.shade3 or C.crimson
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local tt = t
        if level == 3 and is_skin(c) then tt = 0.74 end
        out:drawPixel(x, y, mix(c, to, tt))
      end
    end
  end
  return out
end

-- Energia sutil sobre o corpo: a borda do busto acesa, mais forte a cada nível.
local function body_energy(out, base, m, level)
  for y = m.top, S - 1 do
    for x = 0, S - 1 do
      if alpha(base, x, y) > 0 then
        local edge = alpha(base, x - 1, y) == 0 or alpha(base, x + 1, y) == 0 or alpha(base, x, y - 1) == 0
        if edge then
          out:drawPixel(x, y, mix(out:getPixel(x, y), level == 3 and C.red or C.hot, 0.35 + level * 0.1))
        elseif alpha(base, x - 2, y) == 0 or alpha(base, x + 2, y) == 0 or alpha(base, x, y - 2) == 0 then
          out:drawPixel(x, y, mix(out:getPixel(x, y), C.crimson, 0.2))
        end
      end
    end
  end
end

-- ORELHAS de energia da raposa (no lugar de chifres): saem do alto da cabeça, curvando de leve
-- para fora, com contorno escuro, parte de dentro mais funda e ponta clara.
local function ear(out, x, y, h, lean)
  local half_base = h * 0.4
  local prev = nil
  for i = 0, h - 1 do
    local u = i / (h - 1)
    local half = half_base * (1 - u) ^ 0.9 + 0.35
    local cx = x + lean * h * u * u
    local x0, x1 = math.floor(cx - half + 0.5), math.floor(cx + half + 0.5)
    for px = x0 - 1, x1 + 1 do
      local col
      if px == x0 - 1 or px == x1 + 1 then col = C.dark
      elseif u > 0.8 then col = C.tip
      elseif math.abs(px - cx) < half * 0.5 and u < 0.62 and u > 0.12 then col = C.blood   -- dentro da orelha
      elseif px < cx then col = C.pink
      else col = C.hot end
      put(out, px, y - i, col)
    end
    prev = cx
  end
  put(out, math.floor(prev + 0.5), y - h, C.dark)
end

-- OLHOS acesos (um núcleo de 2 pixels e um halo).
local function eyes(out, e, level)
  for side = 0, 1 do
    local ex, ey = e[1 + side * 2], e[2 + side * 2]
    local core = level == 3 and C.eye3 or C.eye
    for dy = -1, 1 do
      for dx = -2, 2 do
        local qx, qy = ex + dx, ey + dy
        if inside(qx, qy) and math.abs(dx) + math.abs(dy) <= 2 then
          local c = out:getPixel(qx, qy)
          out:drawPixel(qx, qy, mix(c, level == 3 and C.hot or C.crimson, level == 3 and 0.55 or 0.4))
        end
      end
    end
    put(out, ex, ey, core)
    put(out, ex - 1, ey, level == 1 and C.pink or C.eye)
  end
end

-- Fagulhas pretas (N2+) soltas em volta.
local function sparks(out, dist, level)
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local d = dist[y * S + x]
      if d and d >= 3 and d <= 9 and noise(x, y, 99) < (level == 2 and 0.012 or 0.022) then
        put_if_empty(out, x, y, C.black)
      end
    end
  end
end

local function crimson_portrait(base, face, level)
  local m = measure(base)
  local dist = distance_field(base, 12)
  local out = Image(S, S, ColorMode.RGB)
  -- Atrás: caudas e aura; depois a casca do manto; o busto com véu e energia; na frente as orelhas e os olhos.
  for i, t in ipairs(TAILS[level]) do tail(out, t[1], t[2], t[3], t[4], t[5], t[6], t[7], i * 7 + level) end
  aura(out, dist, level)
  cloak(out, dist, m, level)
  local body = veil(base, level)
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local c = body:getPixel(x, y)
      if pc.rgbaA(c) > 0 then out:drawPixel(x, y, c) end
    end
  end
  body_energy(out, base, m, level)
  local h = ({ 14, 16, 19 })[level]
  local mid = (m.hx0 + m.hx1) / 2
  ear(out, math.floor(mid - 9), m.top + 6, h, -0.35)        -- orelha de trás
  ear(out, math.floor(mid + 8), m.top + 5, h - 1, 0.25)     -- orelha da frente
  if not CLOSED[face] then eyes(out, EYES[face], level) end
  -- Limpa pixels de contorno soltos (sem vizinho opaco).
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      if pc.rgbaA(out:getPixel(x, y)) > 0 and alpha(base, x, y) == 0 then
        local n = 0
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do if alpha(out, x + d[1], y + d[2]) > 0 then n = n + 1 end end
        if n == 0 and out:getPixel(x, y) ~= C.black then out:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end
      end
    end
  end
  if level >= 2 then sparks(out, dist, level) end
  return out
end

local made = {}
for _, face in ipairs(FACES) do
  local raw = Image{ fromFile = app.fs.joinPath(base_dir, face .. ".png") }
  local base = clean(raw)
  for level = 1, 3 do
    local img = crimson_portrait(base, face, level)
    img:saveAs(app.fs.joinPath(out_dir, string.format("portrait_c%d_%s.png", level, face)))
    table.insert(made, img)
  end
end
print(string.format("%d rostos da forma gravados", #made))

-- Prancha de prévia: uma expressão por coluna, um nível por linha, em 3x, no fundo do quadro do diálogo.
if app.params.sheet then
  local K, cols = 3, math.min(#FACES, 10)
  local rows = math.ceil(#FACES / cols) * 3
  local sheet = Image(cols * (S * K + 4) + 4, rows * (S * K + 4) + 4, ColorMode.RGB)
  sheet:clear(pc.rgba(20, 10, 16, 255))
  for i, img in ipairs(made) do
    local f, level = (i - 1) // 3, (i - 1) % 3
    local ox = 4 + (f % cols) * (S * K + 4)
    local oy = 4 + ((f // cols) * 3 + level) * (S * K + 4)
    for y = 0, S * K - 1 do
      for x = 0, S * K - 1 do
        local c = img:getPixel(x // K, y // K)
        sheet:drawPixel(ox + x, oy + y, pc.rgbaA(c) > 0 and c or pc.rgba(38, 13, 26, 255))
      end
    end
  end
  sheet:saveAs(app.params.sheet)
end
