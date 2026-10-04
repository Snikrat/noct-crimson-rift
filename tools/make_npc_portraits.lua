-- Rostos dos personagens que falam no jogo (moradores, Tessa, chefes, Mira e a Fenda), para os
-- diálogos: busto 72x72 no mesmo enquadramento dos rostos do Noct, com luz de cima/esquerda.
-- Cada personagem é montado com formas sombreadas (elipses e polígonos com volume), contorno
-- escuro e detalhes pintados pixel a pixel. Saída: assets/portraits/<id>.png.
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/make_npc_portraits.lua
--   --script-param only=zeno,mira       só esses
--   --script-param sheet=<arquivo.png>  também grava uma prancha (prévia, 4x)

local root = app.fs.currentPath
local pc = app.pixelColor
local S = 72
local out_dir = app.fs.joinPath(root, "assets", "portraits")

local function hex(h)
  local a = #h >= 9 and tonumber(h:sub(8, 9), 16) or 255
  return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), a)
end
local function ramp(list) local r = {} for i, h in ipairs(list) do r[i] = hex(h) end return r end
local function mix(c, to, t)
  local r = pc.rgbaR(c) + (pc.rgbaR(to) - pc.rgbaR(c)) * t
  local g = pc.rgbaG(c) + (pc.rgbaG(to) - pc.rgbaG(c)) * t
  local b = pc.rgbaB(c) + (pc.rgbaB(to) - pc.rgbaB(c)) * t
  return pc.rgba(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5), 255)
end

-- Materiais: rampas do escuro para o claro.
local M = {
  skin = ramp({ "#3a1d1a", "#6b3a2c", "#9c5a40", "#c98660", "#e8b48c" }),
  skin_old = ramp({ "#3a1f1c", "#6e4232", "#a06a50", "#c99474", "#e6c0a0" }),
  skin_pale = ramp({ "#2c1c22", "#5e4048", "#93727a", "#c3a5a6", "#e8d6d2" }),
  skin_fair = ramp({ "#3d1e20", "#784436", "#b06e55", "#dc9f7e", "#f3cdb0" }),
  skin_blue = ramp({ "#141a2e", "#26345a", "#3c5582", "#5b7ba8", "#8eaed0" }),
  white = ramp({ "#4a3a44", "#8a7a84", "#bdb0b4", "#e2d8d6", "#fbf5ef" }),
  beard = ramp({ "#3e3640", "#7a7078", "#b4aab0", "#dcd4d4", "#f6f1ee" }),
  maroon = ramp({ "#1e0812", "#3e0d22", "#651731", "#8d2440", "#b33d55" }),
  crimson = ramp({ "#2a0814", "#5a0f28", "#8c1838", "#bb2a4a", "#df5470" }),
  green = ramp({ "#121a12", "#233523", "#3b5531", "#5a7a40", "#84a056" }),
  brown = ramp({ "#1c120e", "#38241a", "#5a3a26", "#80563a", "#a87a52" }),
  leather = ramp({ "#1e130c", "#3e2716", "#68431f", "#93652e", "#bf9046" }),
  orange_hair = ramp({ "#2c1208", "#5e2810", "#9a4a18", "#cc7428", "#eea040" }),
  dark_hair = ramp({ "#120a0c", "#24151a", "#3a2228", "#56343a", "#76504e" }),
  auburn = ramp({ "#1a0a0a", "#3c1612", "#64281c", "#8e4428", "#b4683a" }),
  violet = ramp({ "#141022", "#262040", "#3c3466", "#5a5090", "#8078b8" }),
  purple = ramp({ "#120818", "#26102e", "#3e1a4a", "#5e2c6a", "#86468e" }),
  black = ramp({ "#08060a", "#121016", "#1c1922", "#2a2632", "#3c3646" }),
  steel = ramp({ "#2a2c34", "#555a66", "#8a909c", "#bcc2cc", "#eef0f4" }),
  gold = ramp({ "#3a2408", "#6e4810", "#a87418", "#dca83a", "#f6dc7a" }),
  demon = ramp({ "#2a0606", "#5e120a", "#9a2410", "#cc4416", "#ee7a2a" }),
  horn = ramp({ "#1a1010", "#3a2420", "#5e3e34", "#8a6250", "#b48c70" }),
  cat = ramp({ "#0e0818", "#221236", "#3a1e5a", "#58307e", "#8050a8" }),
  rift = ramp({ "#1a0410", "#5a0622", "#a8183e", "#e2365e", "#ffc0d4" }),
  shadow = ramp({ "#050307", "#0b070e", "#120c16", "#1a1220", "#24182a" }),
}

local LIGHT = { -0.55, -0.6, 0.58 }
do
  local l = math.sqrt(LIGHT[1] ^ 2 + LIGHT[2] ^ 2 + LIGHT[3] ^ 2)
  LIGHT = { LIGHT[1] / l, LIGHT[2] / l, LIGHT[3] / l }
end
local BAYER = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }

-- Tela: cor e "dono" (forma) de cada pixel, para contornos entre formas.
local Canvas = {}
Canvas.__index = Canvas
local function new_canvas()
  local c = setmetatable({ col = {}, owner = {}, mat = {}, n = 0 }, Canvas)
  return c
end
local function inside(x, y) return x >= 0 and y >= 0 and x < S and y < S end

-- Sombreia um pixel pelo vetor normal (nx, ny, nz) na rampa; "lift" clareia/escurece a forma toda.
local function shade(r, nx, ny, nz, x, y, lift, ambient)
  local v = nx * LIGHT[1] + ny * LIGHT[2] + nz * LIGHT[3]
  local t = (ambient or 0.18) + (1 - (ambient or 0.18)) * math.max(0, v) + (lift or 0)
  t = math.max(0, math.min(0.999, t))
  local f = t * (#r - 1)
  local i = math.floor(f)
  local frac = f - i
  if frac * 16 > BAYER[y % 4 + 1][x % 4 + 1] + 0.5 and frac > 0.42 and frac < 0.62 then i = i + 1
  elseif frac >= 0.62 then i = i + 1 end
  return r[math.min(#r, i + 1)]
end

-- Elipse com volume de esfera. opts: lift, ambient, clip(x,y)->bool, flat (sem volume).
function Canvas:ellipse(cx, cy, rx, ry, mat, opts)
  opts = opts or {}
  self.n = self.n + 1
  local id = self.n
  for y = math.floor(cy - ry - 1), math.ceil(cy + ry + 1) do
    for x = math.floor(cx - rx - 1), math.ceil(cx + rx + 1) do
      local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      local d2 = dx * dx + dy * dy
      if d2 <= 1 and inside(x, y) and (not opts.clip or opts.clip(x, y)) then
        local nz = math.sqrt(math.max(0, 1 - d2))
        local k = y * S + x
        self.col[k] = shade(mat, dx * (opts.flat or 1), dy * (opts.flat or 1), nz, x, y, opts.lift, opts.ambient)
        self.owner[k] = id
        self.mat[k] = mat
      end
    end
  end
  return id
end

local function point_in_poly(pts, x, y)
  local c = false
  local j = #pts
  for i = 1, #pts do
    local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
    if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then c = not c end
    j = i
  end
  return c
end

-- Polígono com volume de "almofada": a borda curva para fora (largura "bevel").
function Canvas:poly(pts, mat, opts)
  opts = opts or {}
  local bevel = opts.bevel or 6
  self.n = self.n + 1
  local id = self.n
  local mask = {}
  local x0, y0, x1, y1 = S, S, 0, 0
  for _, p in ipairs(pts) do
    x0, y0 = math.min(x0, p[1]), math.min(y0, p[2])
    x1, y1 = math.max(x1, p[1]), math.max(y1, p[2])
  end
  for y = math.max(0, math.floor(y0)), math.min(S - 1, math.ceil(y1)) do
    for x = math.max(0, math.floor(x0)), math.min(S - 1, math.ceil(x1)) do
      if point_in_poly(pts, x + 0.5, y + 0.5) and (not opts.clip or opts.clip(x, y)) then mask[y * S + x] = true end
    end
  end
  -- Distância até a borda (bordas da tela não contam: o busto continua para fora do quadro).
  local dist, frontier = {}, {}
  for k in pairs(mask) do
    local x, y = k % S, k // S
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local nx, ny = x + d[1], y + d[2]
      if inside(nx, ny) and not mask[ny * S + nx] then dist[k] = 1; table.insert(frontier, k); break end
    end
  end
  local r = 1
  while #frontier > 0 and r < bevel + 2 do
    local nxt = {}
    for _, k in ipairs(frontier) do
      local x, y = k % S, k // S
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nk = (y + d[2]) * S + x + d[1]
        if mask[nk] and not dist[nk] then dist[nk] = r + 1; table.insert(nxt, nk) end
      end
    end
    frontier = nxt
    r = r + 1
  end
  local function D(x, y)
    local k = y * S + x
    if not inside(x, y) then return bevel + 2 end
    if not mask[k] then return 0 end
    return dist[k] or bevel + 2
  end
  for k in pairs(mask) do
    local x, y = k % S, k // S
    local gx, gy = D(x + 1, y) - D(x - 1, y), D(x, y + 1) - D(x, y - 1)
    local gl = math.sqrt(gx * gx + gy * gy)
    local e = math.max(0, 1 - (D(x, y) - 1) / bevel)
    local nx, ny = 0, 0
    if gl > 0 then nx, ny = -gx / gl * e, -gy / gl * e end
    if opts.tilt then nx, ny = nx + opts.tilt[1], ny + opts.tilt[2] end
    local nz = math.sqrt(math.max(0.05, 1 - nx * nx - ny * ny))
    self.col[k] = shade(mat, nx, ny, nz, x, y, opts.lift, opts.ambient)
    self.owner[k] = id
    self.mat[k] = mat
  end
  return id
end

-- Pixel/linha/estampa direta (detalhes pintados), sem mudar o dono.
function Canvas:px(x, y, c)
  x, y = math.floor(x + 0.5), math.floor(y + 0.5)
  if not inside(x, y) then return end
  local k = y * S + x
  self.col[k] = c
  if not self.owner[k] then self.n = self.n + 1; self.owner[k] = -1 end
end
function Canvas:line(x0, y0, x1, y1, c)
  local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  n = math.max(1, math.ceil(n))
  for i = 0, n do self:px(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, c) end
end
-- Estampa: linhas de texto, cada caractere uma cor da tabela "pal" ("." = nada).
function Canvas:stamp(rows, x, y, pal)
  for j, row in ipairs(rows) do
    for i = 1, #row do
      local ch = row:sub(i, i)
      if pal[ch] then self:px(x + i - 1, y + j - 1, pal[ch]) end
    end
  end
end
function Canvas:get(x, y) return self.col[y * S + x] end
-- Tinge pixels já pintados dentro de uma elipse (sombra, brilho, reflexo).
function Canvas:tint(cx, cy, rx, ry, to, t, soft)
  for y = math.floor(cy - ry), math.ceil(cy + ry) do
    for x = math.floor(cx - rx), math.ceil(cx + rx) do
      local k = y * S + x
      local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      local d2 = dx * dx + dy * dy
      if inside(x, y) and d2 <= 1 and self.col[k] then
        local tt = soft and t * (1 - d2) or t
        self.col[k] = mix(self.col[k], to, tt)
      end
    end
  end
end

-- Contornos: borda externa escura e linha fina entre formas (a da frente escurece na borda).
function Canvas:finish(outline)
  local img = Image(S, S, ColorMode.RGB)
  local col = {}
  for k, c in pairs(self.col) do col[k] = c end
  for k, c in pairs(self.col) do
    local x, y = k % S, k // S
    local me = self.owner[k]
    if me and me > 0 then
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = x + d[1], y + d[2]
        local nk = ny * S + nx
        if inside(nx, ny) then
          local other = self.owner[nk]
          if other and other > 0 and other < me and self.mat[k] ~= self.mat[nk] then
            col[k] = mix(c, self.mat[k][1], 0.55)
            break
          end
        end
      end
    end
  end
  for k, c in pairs(col) do img:drawPixel(k % S, k // S, c) end
  if outline ~= false then
    local add = {}
    for y = 0, S - 1 do
      for x = 0, S - 1 do
        if not self.col[y * S + x] then
          for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local nx, ny = x + d[1], y + d[2]
            local nk = ny * S + nx
            if inside(nx, ny) and self.col[nk] then
              local m = self.mat[nk]
              add[y * S + x] = m and mix(m[1], hex("#000000"), 0.35) or hex("#0a060a")
              break
            end
          end
        end
      end
    end
    for k, c in pairs(add) do img:drawPixel(k % S, k // S, c) end
  end
  return img
end

-- --------------------------------------------------------------------------------------------
-- Peças comuns de rosto.

-- Olho simples de frente (2-3 px): branco, íris e brilho; "lid" = pálpebra/sombra por cima.
local function eye(cv, x, y, iris, opts)
  opts = opts or {}
  local white = opts.white or hex("#e8dcd4")
  local lid = opts.lid or hex("#2a1414")
  if opts.closed then
    cv:line(x - 2, y, x + 2, y, lid)
    return
  end
  cv:px(x - 2, y, white); cv:px(x + 2, y, white)
  cv:px(x - 1, y, iris); cv:px(x, y, iris); cv:px(x + 1, y, opts.dark or mix(iris, hex("#000000"), 0.5))
  cv:px(x - 1, y + 1, white); cv:px(x, y + 1, mix(iris, hex("#000000"), 0.3)); cv:px(x + 1, y + 1, white)
  cv:px(x - 1, y, opts.glint or white)
  cv:line(x - 3, y - 1, x + 2, y - 1, lid)
  cv:px(x + 3, y, lid)
end

local function glow_eye(cv, x, y, core, halo)
  cv:tint(x + 0.5, y + 0.5, 3, 2.2, halo, 0.6, true)
  cv:px(x, y, core); cv:px(x + 1, y, core)
  cv:px(x - 1, y, halo); cv:px(x + 2, y, halo)
end

-- --------------------------------------------------------------------------------------------
-- Personagens. Cada um devolve a imagem 72x72.

local P = {}

-- VELHO ZENO: chapéu pontudo vinho e caído, pena laranja, barba branca comprida, colete verde.
P.zeno = function()
  local cv = new_canvas()
  -- Ombros: casaco vinho e colete verde.
  cv:poly({ { 6, 72 }, { 10, 58 }, { 22, 52 }, { 50, 52 }, { 62, 58 }, { 66, 72 } }, M.maroon, { bevel = 7 })
  cv:poly({ { 24, 72 }, { 26, 56 }, { 46, 56 }, { 48, 72 } }, M.green, { bevel = 4 })
  -- Rosto.
  cv:ellipse(36, 37, 12, 14, M.skin_old)
  cv:ellipse(23.5, 38, 2.5, 4, M.skin_old, { lift = -0.1 })                -- orelha
  -- Barba: massa branca do queixo até o peito.
  cv:poly({ { 23, 40 }, { 49, 40 }, { 50, 50 }, { 46, 62 }, { 40, 70 }, { 36, 72 }, { 31, 69 }, { 25, 60 }, { 22, 49 } }, M.beard, { bevel = 7 })
  -- Bigode.
  cv:poly({ { 28, 45 }, { 36, 42 }, { 44, 45 }, { 46, 49 }, { 41, 47 }, { 36, 46 }, { 31, 47 }, { 26, 49 } }, M.beard, { bevel = 2, lift = 0.1 })
  -- Nariz grande.
  cv:ellipse(38, 40, 3, 3.5, M.skin_old, { lift = 0.05 })
  -- Chapéu: aba larga e copa pontuda caída para trás.
  cv:poly({ { 14, 31 }, { 22, 24 }, { 50, 23 }, { 60, 29 }, { 52, 32 }, { 22, 32 } }, M.maroon, { bevel = 3 })
  cv:poly({ { 22, 25 }, { 26, 13 }, { 34, 6 }, { 46, 4 }, { 58, 8 }, { 64, 16 }, { 60, 18 }, { 52, 12 }, { 46, 13 }, { 48, 25 } }, M.maroon, { bevel = 5 })
  cv:poly({ { 22, 25 }, { 48, 25 }, { 49, 28 }, { 21, 28 } }, M.leather, { bevel = 1 })   -- faixa
  -- Pena laranja na faixa.
  for i = 0, 12 do
    local x, y = 47 + i * 0.9, 25 - i * 1.4 + (i * i) * 0.05
    cv:px(x, y, M.orange_hair[4]); cv:px(x + 1, y, M.orange_hair[3])
    if i % 2 == 0 then cv:px(x + 2, y + 1, M.orange_hair[5]) end
  end
  -- Sobrancelhas brancas e olhos pequenos, simpáticos.
  cv:line(28, 33, 33, 32, M.beard[4]); cv:line(39, 32, 44, 33, M.beard[4])
  cv:line(28, 34, 33, 34, M.beard[2])
  cv:line(30, 36, 33, 35, hex("#2a1414")); cv:px(31, 37, hex("#3a2a20")); cv:px(32, 37, hex("#5a4030"))
  cv:line(40, 35, 43, 36, hex("#2a1414")); cv:px(41, 37, hex("#3a2a20")); cv:px(42, 37, hex("#5a4030"))
  -- Rugas.
  cv:px(27, 38, M.skin_old[2]); cv:px(45, 38, M.skin_old[2]); cv:line(33, 30, 39, 30, M.skin_old[3])
  -- Sombra do chapéu na testa.
  cv:tint(36, 30, 13, 2.5, M.skin_old[1], 0.45)
  -- Fios na barba.
  for i = 0, 7 do cv:line(27 + i * 3, 52, 28 + i * 2.6, 64 - math.abs(i - 3.5), M.beard[2]) end
  return cv:finish()
end

-- IRMÃ LÍVIA: touca branca emoldurando o rosto, vestido carmesim, gola branca, olhar sereno.
P.livia = function()
  local cv = new_canvas()
  cv:poly({ { 8, 72 }, { 12, 60 }, { 24, 54 }, { 48, 54 }, { 60, 60 }, { 64, 72 } }, M.crimson, { bevel = 7 })
  cv:poly({ { 24, 56 }, { 36, 64 }, { 48, 56 }, { 46, 53 }, { 26, 53 } }, M.white, { bevel = 3 })    -- gola
  cv:ellipse(36, 51, 5, 5, M.skin_fair, { lift = -0.15 })                                           -- pescoço
  -- Véu/touca atrás.
  cv:poly({ { 18, 58 }, { 17, 36 }, { 22, 22 }, { 36, 15 }, { 50, 22 }, { 55, 36 }, { 54, 58 }, { 46, 54 }, { 26, 54 } }, M.white, { bevel = 8 })
  -- Rosto.
  cv:ellipse(36, 39, 11, 13, M.skin_fair)
  -- Cabelo castanho na testa.
  cv:poly({ { 25, 33 }, { 28, 27 }, { 36, 25 }, { 44, 27 }, { 47, 33 }, { 42, 30 }, { 36, 31 }, { 30, 30 } }, M.auburn, { bevel = 2 })
  -- Faixa da touca por cima.
  cv:poly({ { 22, 30 }, { 25, 23 }, { 36, 19 }, { 47, 23 }, { 50, 30 }, { 46, 27 }, { 36, 24 }, { 26, 27 } }, M.white, { bevel = 2, lift = 0.1 })
  eye(cv, 31, 39, hex("#4a6a4a"), { lid = hex("#3a1a18") })
  eye(cv, 42, 39, hex("#4a6a4a"), { lid = hex("#3a1a18") })
  cv:line(28, 35, 33, 35, M.auburn[2]); cv:line(40, 35, 45, 35, M.auburn[2])
  cv:line(37, 41, 38, 44, M.skin_fair[2]); cv:px(36, 45, M.skin_fair[2])                       -- nariz
  cv:line(34, 48, 39, 48, hex("#8a3a3a")); cv:px(35, 49, hex("#b05a58")); cv:px(38, 49, hex("#b05a58"))
  cv:tint(30, 44, 2.5, 1.5, hex("#d0705e"), 0.3, true); cv:tint(43, 44, 2.5, 1.5, hex("#d0705e"), 0.3, true)
  -- Pequeno pingente.
  cv:px(36, 58, M.gold[4]); cv:px(36, 59, M.gold[3]); cv:px(35, 59, M.gold[3]); cv:px(37, 59, M.gold[3]); cv:px(36, 60, M.gold[2])
  return cv:finish()
end

-- FORASTEIRO: chapéu de aba larga inclinado, rosto comprido com barba por fazer, colete marrom.
P.forasteiro = function()
  local cv = new_canvas()
  cv:poly({ { 6, 72 }, { 10, 60 }, { 22, 54 }, { 50, 54 }, { 62, 60 }, { 66, 72 } }, M.brown, { bevel = 7 })
  cv:poly({ { 28, 72 }, { 29, 56 }, { 36, 62 }, { 43, 56 }, { 44, 72 } }, M.white, { bevel = 3, lift = -0.1 })  -- camisa
  cv:poly({ { 29, 55 }, { 36, 62 }, { 33, 64 }, { 26, 57 } }, M.white, { bevel = 1 })
  cv:poly({ { 43, 55 }, { 36, 62 }, { 39, 64 }, { 46, 57 } }, M.white, { bevel = 1 })
  cv:ellipse(36, 52, 5, 5, M.skin, { lift = -0.15 })
  cv:ellipse(36, 39, 10, 15, M.skin)
  cv:ellipse(26, 40, 2, 3.5, M.skin, { lift = -0.1 })
  -- Cabelo castanho saindo do chapéu.
  cv:poly({ { 25, 34 }, { 26, 26 }, { 46, 26 }, { 47, 34 }, { 44, 30 }, { 28, 30 } }, M.brown, { bevel = 2 })
  -- Barba por fazer.
  for y = 44, 53 do for x = 28, 44 do
    local dx, dy = (x - 36) / 10, (y - 39) / 15
    if dx * dx + dy * dy < 1 and (x + y) % 2 == 0 and y > 45 then cv:px(x, y, mix(cv:get(x, y) or M.skin[3], M.dark_hair[2], 0.45)) end
  end end
  -- Chapéu.
  cv:poly({ { 10, 30 }, { 18, 24 }, { 54, 20 }, { 64, 24 }, { 56, 29 }, { 20, 31 } }, M.leather, { bevel = 3, lift = -0.05 })
  cv:poly({ { 22, 25 }, { 24, 12 }, { 32, 8 }, { 44, 8 }, { 50, 12 }, { 50, 23 } }, M.leather, { bevel = 5 })
  cv:poly({ { 23, 22 }, { 50, 20 }, { 50, 23 }, { 23, 25 } }, M.maroon, { bevel = 1 })
  cv:tint(36, 32, 12, 4, M.skin[1], 0.55)                  -- sombra da aba nos olhos
  eye(cv, 31, 36, hex("#6a4a2a"), { white = hex("#b8a090") })
  eye(cv, 41, 36, hex("#6a4a2a"), { white = hex("#b8a090") })
  cv:line(28, 33, 33, 33, M.brown[1]); cv:line(39, 33, 44, 33, M.brown[1])
  cv:line(37, 38, 38, 43, M.skin[2]); cv:px(37, 44, M.skin[2])
  cv:line(33, 48, 39, 48, hex("#4a2018")); cv:px(40, 47, hex("#4a2018"))   -- meio sorriso torto
  -- Palha no canto da boca.
  cv:line(40, 48, 45, 50, M.gold[4]); cv:px(46, 50, M.gold[3])
  return cv:finish()
end

-- TESSA: moça de vestido azul-violeta, cabelo castanho-avermelhado preso e despenteado,
-- olhar atento (ela ouve a fenda): um brilho carmesim discreto nos olhos.
P.tessa = function()
  local cv = new_canvas()
  -- Cabelo atrás (solto até os ombros).
  cv:poly({ { 20, 60 }, { 18, 40 }, { 22, 24 }, { 36, 16 }, { 50, 24 }, { 54, 40 }, { 52, 60 }, { 46, 54 }, { 26, 54 } }, M.auburn, { bevel = 6 })
  cv:poly({ { 8, 72 }, { 12, 60 }, { 24, 55 }, { 48, 55 }, { 60, 60 }, { 64, 72 } }, M.violet, { bevel = 7 })
  cv:poly({ { 27, 55 }, { 36, 62 }, { 45, 55 } }, M.skin_fair, { bevel = 3 })            -- decote
  cv:ellipse(36, 52, 4.5, 5, M.skin_fair, { lift = -0.15 })
  cv:ellipse(36, 39, 11, 13, M.skin_fair)
  -- Franja e mechas.
  cv:poly({ { 24, 36 }, { 25, 27 }, { 32, 22 }, { 42, 22 }, { 48, 28 }, { 48, 34 }, { 44, 29 }, { 38, 31 }, { 33, 27 }, { 29, 32 } }, M.auburn, { bevel = 3 })
  cv:line(25, 36, 23, 48, M.auburn[3]); cv:line(47, 34, 49, 46, M.auburn[3])
  cv:line(46, 26, 50, 20, M.auburn[4]); cv:line(30, 24, 27, 19, M.auburn[4])           -- fios soltos
  -- Fita/presilha.
  cv:px(47, 27, M.crimson[4]); cv:px(48, 27, M.crimson[3]); cv:px(47, 28, M.crimson[3])
  eye(cv, 31, 39, hex("#8a2a44"), { lid = hex("#2a1010"), glint = hex("#ff8aa8") })
  eye(cv, 42, 39, hex("#8a2a44"), { lid = hex("#2a1010"), glint = hex("#ff8aa8") })
  cv:line(28, 35, 33, 34, M.auburn[2]); cv:line(40, 34, 45, 35, M.auburn[2])
  cv:line(37, 41, 37, 44, M.skin_fair[2]); cv:px(36, 45, M.skin_fair[2])
  cv:line(34, 48, 39, 48, hex("#8a3a3a")); cv:px(36, 49, hex("#b05a58"))
  -- Sardas e um arranhão (estava presa).
  for _, p in ipairs({ { 29, 43 }, { 31, 44 }, { 42, 44 }, { 44, 43 }, { 33, 43 } }) do cv:px(p[1], p[2], M.skin_fair[2]) end
  cv:line(44, 46, 46, 44, hex("#a03838"))
  -- Corda marcada no ombro.
  cv:line(14, 64, 24, 58, M.leather[3])
  return cv:finish()
end

-- FERREIRO BROM: cabeça raspada, barba laranja cheia, pescoço largo, avental de couro.
P.brom = function()
  local cv = new_canvas()
  cv:poly({ { 2, 72 }, { 6, 58 }, { 20, 50 }, { 52, 50 }, { 66, 58 }, { 70, 72 } }, M.maroon, { bevel = 8 })
  cv:poly({ { 20, 72 }, { 22, 58 }, { 50, 58 }, { 52, 72 } }, M.white, { bevel = 4, lift = -0.05 })
  cv:line(24, 58, 18, 50, M.leather[2]); cv:line(48, 58, 54, 50, M.leather[2])
  cv:ellipse(36, 50, 9, 6, M.skin_fair, { lift = -0.1 })
  cv:ellipse(36, 35, 13, 15, M.skin_fair)
  cv:ellipse(23, 37, 2.5, 4, M.skin_fair)
  cv:ellipse(49, 37, 2.5, 4, M.skin_fair, { lift = -0.15 })
  -- Laterais do cabelo raspado e barba.
  cv:poly({ { 23, 34 }, { 24, 26 }, { 27, 28 }, { 26, 36 } }, M.orange_hair, { bevel = 1, lift = -0.1 })
  cv:poly({ { 49, 34 }, { 48, 26 }, { 45, 28 }, { 46, 36 } }, M.orange_hair, { bevel = 1, lift = -0.1 })
  cv:poly({ { 24, 38 }, { 30, 44 }, { 42, 44 }, { 48, 38 }, { 49, 48 }, { 44, 58 }, { 36, 62 }, { 28, 58 }, { 23, 48 } }, M.orange_hair, { bevel = 6 })
  cv:poly({ { 29, 45 }, { 36, 43 }, { 43, 45 }, { 44, 48 }, { 36, 46 }, { 28, 48 } }, M.orange_hair, { bevel = 2, lift = 0.15 })
  cv:ellipse(36, 40, 3, 3, M.skin_fair, { lift = 0.05 })
  cv:line(29, 31, 34, 30, M.orange_hair[2]); cv:line(38, 30, 43, 31, M.orange_hair[2])
  eye(cv, 31, 34, hex("#3a4a6a")); eye(cv, 41, 34, hex("#3a4a6a"))
  cv:tint(32, 22, 6, 3, M.skin_fair[5], 0.35, true)                 -- brilho da careca
  for i = 0, 6 do cv:line(28 + i * 2.5, 50, 29 + i * 2.3, 58, M.orange_hair[2]) end
  return cv:finish()
end

-- BRINGER OF DEATH: capuz roxo esfarrapado, rosto de caveira pálido na sombra, olhos violeta.
P.bringer = function()
  local cv = new_canvas()
  cv:poly({ { 2, 72 }, { 8, 56 }, { 18, 46 }, { 54, 46 }, { 64, 56 }, { 70, 72 } }, M.purple, { bevel = 8 })
  cv:poly({ { 14, 60 }, { 16, 30 }, { 24, 12 }, { 36, 6 }, { 48, 12 }, { 56, 30 }, { 58, 60 }, { 46, 52 }, { 26, 52 } }, M.purple, { bevel = 8 })
  -- Abertura do capuz (escuro) e o rosto.
  cv:ellipse(36, 36, 11, 14, M.black, { lift = -0.3 })
  cv:ellipse(36, 37, 8, 10, M.skin_pale, { lift = -0.15 })
  -- Órbitas, nariz e dentes da caveira.
  cv:ellipse(32, 35, 2.6, 2.2, M.black, { flat = 0, lift = -0.5 })
  cv:ellipse(40, 35, 2.6, 2.2, M.black, { flat = 0, lift = -0.5 })
  glow_eye(cv, 31, 35, hex("#e8b8ff"), hex("#9a4ad8"))
  glow_eye(cv, 39, 35, hex("#e8b8ff"), hex("#9a4ad8"))
  cv:px(36, 39, M.black[1]); cv:px(35, 40, M.black[2]); cv:px(37, 40, M.black[2])
  for x = 32, 40 do cv:px(x, 43, x % 2 == 0 and M.skin_pale[5] or M.skin_pale[2]) end
  cv:line(32, 44, 40, 44, M.skin_pale[1])
  -- Sombra do capuz por cima do rosto.
  cv:tint(36, 28, 10, 5, M.black[1], 0.6)
  -- Rasgos na borda do manto e fecho.
  for _, x in ipairs({ 16, 22, 50, 56 }) do cv:line(x, 66, x + 1, 72, M.purple[1]) end
  cv:ellipse(36, 52, 3, 2.5, M.steel, { lift = -0.1 })
  return cv:finish()
end

-- DEMON SLIME: demônio vermelho de chifres curvos com fogo nas pontas, sorriso de presas, olhos amarelos.
P.demon_slime = function()
  local cv = new_canvas()
  cv:poly({ { 0, 72 }, { 4, 58 }, { 18, 52 }, { 54, 52 }, { 68, 58 }, { 72, 72 } }, M.demon, { bevel = 9, lift = -0.15 })
  cv:ellipse(36, 52, 11, 7, M.demon, { lift = -0.2 })
  -- Chifres.
  cv:poly({ { 22, 26 }, { 14, 20 }, { 8, 10 }, { 10, 4 }, { 14, 12 }, { 22, 18 }, { 28, 22 } }, M.horn, { bevel = 3 })
  cv:poly({ { 50, 26 }, { 58, 20 }, { 64, 10 }, { 62, 4 }, { 58, 12 }, { 50, 18 }, { 44, 22 } }, M.horn, { bevel = 3 })
  cv:ellipse(36, 36, 15, 15, M.demon)
  cv:ellipse(36, 44, 12, 8, M.demon, { lift = 0.05 })       -- mandíbula larga
  -- Fogo nas pontas dos chifres.
  for _, f in ipairs({ { 9, 4 }, { 62, 4 } }) do
    cv:ellipse(f[1] + 0.5, f[2] - 1, 2.5, 3.5, ramp({ "#6a1a04", "#b8400a", "#ee8a1a", "#ffd04a", "#fff2b0" }), { lift = 0.25 })
    cv:px(f[1], f[2] - 5, hex("#ffd04a"))
  end
  -- Sobrancelhas pesadas e olhos.
  cv:poly({ { 24, 30 }, { 34, 32 }, { 34, 34 }, { 24, 33 } }, M.demon, { bevel = 1, lift = -0.3 })
  cv:poly({ { 48, 30 }, { 38, 32 }, { 38, 34 }, { 48, 33 } }, M.demon, { bevel = 1, lift = -0.3 })
  glow_eye(cv, 29, 35, hex("#fff2a0"), hex("#e8a020"))
  glow_eye(cv, 42, 35, hex("#fff2a0"), hex("#e8a020"))
  cv:line(35, 38, 34, 42, M.demon[1]); cv:px(37, 42, M.demon[1])
  -- Boca com presas.
  cv:poly({ { 26, 45 }, { 46, 45 }, { 43, 51 }, { 29, 51 } }, M.black, { bevel = 1, lift = -0.4 })
  for x = 27, 45, 3 do cv:px(x, 46, hex("#f0e0c0")); cv:px(x + 1, 46, hex("#f0e0c0")); cv:px(x, 47, hex("#c8b090")) end
  cv:line(29, 50, 30, 48, hex("#f0e0c0")); cv:line(43, 50, 42, 48, hex("#f0e0c0"))
  -- Rachaduras de lava na pele.
  cv:line(22, 40, 25, 44, hex("#ffb040")); cv:line(50, 40, 47, 45, hex("#ffb040"))
  cv:line(30, 60, 34, 56, hex("#ffb040")); cv:line(44, 62, 42, 56, hex("#ff8a20"))
  return cv:finish()
end

-- GATO INFERNAL: cabeça de pantera roxa, orelhas pontudas, olhos amarelo-esverdeados, presas.
P.gato = function()
  local cv = new_canvas()
  cv:poly({ { 4, 72 }, { 10, 58 }, { 22, 52 }, { 50, 52 }, { 62, 58 }, { 68, 72 } }, M.cat, { bevel = 8 })
  cv:poly({ { 18, 26 }, { 16, 8 }, { 30, 20 } }, M.cat, { bevel = 3 })
  cv:poly({ { 54, 26 }, { 56, 8 }, { 42, 20 } }, M.cat, { bevel = 3 })
  cv:poly({ { 20, 22 }, { 19, 13 }, { 26, 20 } }, M.crimson, { bevel = 1, lift = -0.2 })
  cv:poly({ { 52, 22 }, { 53, 13 }, { 46, 20 } }, M.crimson, { bevel = 1, lift = -0.2 })
  cv:ellipse(36, 36, 17, 15, M.cat)
  cv:ellipse(36, 45, 9, 7, M.cat, { lift = 0.1 })          -- focinho
  cv:ellipse(36, 41, 3, 2, M.black, { lift = -0.2 })       -- nariz
  -- Olhos de gato (pupila em fenda).
  for _, x in ipairs({ 28, 44 }) do
    cv:ellipse(x, 34, 4, 2.6, ramp({ "#4a5a08", "#8aa010", "#c8d830", "#e8f070", "#fffcc0" }), { lift = 0.2 })
    cv:line(x, 32, x, 36, M.black[1])
  end
  cv:line(23, 31, 31, 32, M.cat[1]); cv:line(49, 31, 41, 32, M.cat[1])
  -- Boca e presas.
  cv:line(36, 43, 36, 46, M.black[1]); cv:line(31, 48, 36, 46, M.black[1]); cv:line(41, 48, 36, 46, M.black[1])
  cv:line(32, 48, 32, 51, hex("#f0e8f0")); cv:line(40, 48, 40, 51, hex("#f0e8f0"))
  -- Bigodes.
  for i = 0, 2 do
    cv:line(28, 44 + i, 14, 41 + i * 3, M.violet[4]); cv:line(44, 44 + i, 58, 41 + i * 3, M.violet[4])
  end
  -- Marcas de brasa.
  cv:line(30, 24, 32, 28, hex("#e2365e")); cv:line(42, 24, 40, 28, hex("#e2365e"))
  return cv:finish()
end

-- VELÁRIO, O CARCEREIRO: capuz preto sem rosto, só dois pontos vermelhos, corrente com chaves e
-- a luz vermelha da lanterna vindo de baixo.
P.velario = function()
  local cv = new_canvas()
  cv:poly({ { 0, 72 }, { 6, 54 }, { 18, 44 }, { 54, 44 }, { 66, 54 }, { 72, 72 } }, M.black, { bevel = 9 })
  cv:poly({ { 14, 58 }, { 15, 30 }, { 22, 12 }, { 36, 4 }, { 50, 12 }, { 57, 30 }, { 58, 58 }, { 46, 50 }, { 26, 50 } }, M.black, { bevel = 9, lift = 0.05 })
  cv:ellipse(36, 34, 10, 14, M.shadow, { lift = -0.4 })
  cv:ellipse(36, 36, 7, 10, M.shadow, { lift = -0.8, flat = 0 })
  glow_eye(cv, 31, 34, hex("#ffb0c0"), hex("#c01838"))
  glow_eye(cv, 39, 34, hex("#ffb0c0"), hex("#c01838"))
  -- Corrente atravessando o peito, com chaves.
  for i = 0, 18 do
    local x, y = 14 + i * 2.4, 56 + math.sin(i * 0.35) * 3
    cv:px(x, y, i % 2 == 0 and M.steel[4] or M.steel[2]); cv:px(x + 1, y, M.steel[3])
  end
  cv:stamp({ ".gg.", "g..g", ".gg.", "..g.", "..gg", "..g.", "..gg" }, 44, 59, { g = M.gold[3] })
  cv:stamp({ ".gg.", "g..g", ".gg.", "..g.", "..gg", "..g." }, 49, 60, { g = M.gold[4] })
  -- Luz vermelha da lanterna (de baixo, à direita).
  cv:tint(60, 72, 22, 14, hex("#c01838"), 0.55, true)
  cv:tint(48, 52, 10, 10, hex("#c01838"), 0.25, true)
  return cv:finish()
end

-- CAPITÃO DOS DESGARRADOS: bandido de pele azulada, capuz de couro com enfeite dourado, cicatriz.
P.capitao = function()
  local cv = new_canvas()
  cv:poly({ { 2, 72 }, { 6, 58 }, { 20, 50 }, { 52, 50 }, { 66, 58 }, { 70, 72 } }, M.steel, { bevel = 8, lift = -0.15 })
  cv:poly({ { 10, 72 }, { 14, 60 }, { 24, 54 }, { 48, 54 }, { 58, 60 }, { 62, 72 } }, M.leather, { bevel = 6 })
  cv:poly({ { 16, 56 }, { 17, 30 }, { 24, 14 }, { 36, 9 }, { 48, 14 }, { 55, 30 }, { 56, 56 }, { 46, 52 }, { 26, 52 } }, M.brown, { bevel = 7 })
  cv:ellipse(36, 38, 10, 13, M.skin_blue)
  cv:ellipse(36, 50, 7, 4, M.skin_blue, { lift = -0.1 })
  -- Testeira dourada do capuz.
  cv:poly({ { 23, 28 }, { 27, 22 }, { 36, 19 }, { 45, 22 }, { 49, 28 }, { 45, 26 }, { 36, 24 }, { 27, 26 } }, M.gold, { bevel = 2 })
  cv:px(36, 21, hex("#ff5a6a")); cv:px(36, 22, hex("#a01828"))
  cv:poly({ { 24, 31 }, { 34, 34 }, { 34, 35 }, { 24, 33 } }, M.skin_blue, { bevel = 1, lift = -0.4 })
  cv:poly({ { 48, 31 }, { 38, 34 }, { 38, 35 }, { 48, 33 } }, M.skin_blue, { bevel = 1, lift = -0.4 })
  eye(cv, 30, 36, hex("#e8c040"), { white = hex("#c8d0d8"), lid = hex("#0a1020") })
  eye(cv, 42, 36, hex("#e8c040"), { white = hex("#c8d0d8"), lid = hex("#0a1020") })
  cv:line(37, 38, 38, 43, M.skin_blue[2]); cv:px(37, 44, M.skin_blue[1])
  cv:line(32, 47, 41, 46, hex("#0a1020")); cv:px(32, 48, hex("#0a1020"))           -- boca de desdém
  cv:line(41, 31, 45, 42, hex("#a8c8e8")); cv:line(42, 31, 46, 42, M.skin_blue[1])  -- cicatriz
  -- Barba rala escura.
  for x = 30, 42, 2 do cv:px(x, 50, M.skin_blue[1]) end
  -- Ombreira com rebites.
  for _, p in ipairs({ { 12, 62 }, { 16, 59 }, { 56, 59 }, { 60, 62 } }) do cv:px(p[1], p[2], M.gold[4]) end
  return cv:finish()
end

-- CUSTÓDIO DO SELO: mago de capuz roxo com acabamento dourado, rosto na sombra com olhos acesos
-- e o cajado de cristal escuro atrás do ombro.
P.custodio = function()
  local cv = new_canvas()
  -- Cajado.
  cv:line(58, 72, 62, 20, M.brown[3]); cv:line(59, 72, 63, 20, M.brown[2])
  cv:poly({ { 62, 4 }, { 68, 12 }, { 66, 22 }, { 60, 24 }, { 56, 14 } }, M.purple, { bevel = 3, lift = 0.1 })
  cv:px(62, 13, hex("#ff4a6a")); cv:px(62, 14, hex("#c01838"))
  cv:poly({ { 2, 72 }, { 6, 56 }, { 18, 46 }, { 54, 46 }, { 64, 56 }, { 68, 72 } }, M.violet, { bevel = 8 })
  cv:poly({ { 14, 58 }, { 16, 30 }, { 24, 10 }, { 36, 2 }, { 46, 8 }, { 52, 18 }, { 56, 30 }, { 58, 58 }, { 46, 50 }, { 26, 50 } }, M.violet, { bevel = 8 })
  -- Acabamento dourado do capuz e da gola.
  cv:poly({ { 20, 56 }, { 21, 32 }, { 26, 20 }, { 28, 22 }, { 24, 34 }, { 24, 54 } }, M.gold, { bevel = 1 })
  cv:poly({ { 52, 56 }, { 51, 32 }, { 46, 20 }, { 44, 22 }, { 48, 34 }, { 48, 54 } }, M.gold, { bevel = 1 })
  cv:ellipse(36, 36, 10, 13, M.shadow, { lift = -0.3 })
  glow_eye(cv, 31, 35, hex("#ffe0a0"), hex("#e07a20"))
  glow_eye(cv, 40, 35, hex("#ffe0a0"), hex("#e07a20"))
  cv:line(33, 46, 39, 46, M.black[1])
  -- Selo dourado no peito.
  cv:ellipse(36, 60, 4, 4, M.gold, { lift = 0.05 })
  cv:line(36, 57, 36, 63, M.gold[1]); cv:line(33, 60, 39, 60, M.gold[1])
  return cv:finish()
end

-- VIGIA ERRANTE: elmo prateado com fenda do visor, pluma e um lenço vermelho gasto.
P.vigia = function()
  local cv = new_canvas()
  cv:poly({ { 2, 72 }, { 6, 58 }, { 20, 50 }, { 52, 50 }, { 66, 58 }, { 70, 72 } }, M.steel, { bevel = 8 })
  cv:poly({ { 20, 56 }, { 26, 50 }, { 46, 50 }, { 52, 56 }, { 46, 62 }, { 26, 62 } }, M.crimson, { bevel = 4 })   -- lenço
  cv:poly({ { 42, 60 }, { 48, 60 }, { 52, 72 }, { 44, 72 } }, M.crimson, { bevel = 3, lift = -0.1 })
  -- Pluma.
  cv:poly({ { 36, 10 }, { 44, 2 }, { 58, 2 }, { 66, 10 }, { 60, 8 }, { 50, 8 }, { 42, 12 } }, M.white, { bevel = 2 })
  -- Elmo.
  cv:poly({ { 22, 50 }, { 20, 30 }, { 24, 16 }, { 36, 9 }, { 48, 16 }, { 52, 30 }, { 50, 50 }, { 42, 54 }, { 30, 54 } }, M.steel, { bevel = 9 })
  cv:poly({ { 35, 10 }, { 37, 10 }, { 38, 52 }, { 34, 52 } }, M.steel, { bevel = 1, lift = 0.15 })               -- crista
  -- Visor.
  cv:poly({ { 23, 31 }, { 49, 31 }, { 48, 35 }, { 24, 35 } }, M.black, { bevel = 1, lift = -0.4 })
  glow_eye(cv, 30, 33, hex("#ffd0d8"), hex("#a8183e"))
  for y = 40, 48, 3 do cv:line(27, y, 33, y, M.steel[1]); cv:line(39, y, 45, y, M.steel[1]) end                  -- respiros
  -- Arranhões e amassados.
  cv:line(42, 20, 46, 26, M.steel[2]); cv:line(24, 40, 26, 44, M.steel[2])
  for _, p in ipairs({ { 22, 48 }, { 50, 48 }, { 36, 52 } }) do cv:px(p[1], p[2], M.gold[3]) end
  return cv:finish()
end

-- MIRA: só uma silhueta escura de mulher (cabelo longo, ombros), com a borda acesa em carmesim.
P.mira = function()
  local cv = new_canvas()
  -- Brilho carmesim fraco atrás, para a silhueta destacar no fundo escuro.
  cv:ellipse(37, 40, 26, 30, ramp({ "#1e0812", "#24091a", "#2c0b1e", "#340d22", "#3c0f26" }), { flat = 0, ambient = 0.6 })
  local sil = ramp({ "#07040a", "#0d0811", "#140c18", "#1a1020", "#201426" })
  cv:poly({ { 6, 72 }, { 10, 62 }, { 22, 56 }, { 50, 56 }, { 62, 62 }, { 66, 72 } }, sil, { bevel = 6 })
  cv:poly({ { 18, 66 }, { 17, 44 }, { 20, 28 }, { 28, 18 }, { 38, 15 }, { 48, 19 }, { 54, 30 }, { 56, 46 }, { 58, 68 }, { 50, 60 }, { 24, 60 } }, sil, { bevel = 8 })
  cv:ellipse(37, 38, 10, 13, sil, { lift = -0.05 })
  cv:ellipse(37, 53, 4, 5, sil)
  local img = cv:finish(false)
  -- Contraluz carmesim: só a borda de um lado acende; o rosto não tem traços.
  local rim, rim2 = hex("#a8183e"), hex("#e2365e")
  local copy = img:clone()
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      if pc.rgbaA(copy:getPixel(x, y)) > 0 then
        local r1 = x + 1 < S and pc.rgbaA(copy:getPixel(x + 1, y)) == 0
        local r2 = x + 2 < S and pc.rgbaA(copy:getPixel(x + 2, y)) == 0
        local up = y > 0 and pc.rgbaA(copy:getPixel(x, y - 1)) == 0
        if r1 and y < 66 then img:drawPixel(x, y, (y % 5 == 0) and rim2 or rim)
        elseif (r2 or up) and y < 60 and x > 30 then img:drawPixel(x, y, mix(copy:getPixel(x, y), rim, 0.35)) end
      end
    end
  end
  return img
end

-- A FENDA: um rasgo vertical no escuro, carmesim com o miolo branco-quente, cristais e faíscas.
P.fenda = function()
  local cv = new_canvas()
  local void = ramp({ "#050206", "#0c0410", "#160818", "#200c22", "#2c102c" })
  cv:ellipse(36, 38, 30, 33, void, { lift = -0.1 })
  -- Rasgo em zigue-zague.
  local pts_l, pts_r = {}, {}
  local xs = { 36, 33, 38, 32, 37, 34, 39, 35, 36 }
  for i, x in ipairs(xs) do
    local y = 6 + (i - 1) * 8
    local w = 1 + math.sin((i - 1) / (#xs - 1) * math.pi) * 6
    table.insert(pts_l, { x - w, y }); table.insert(pts_r, 1, { x + w, y })
  end
  local pts = {}
  for _, p in ipairs(pts_l) do table.insert(pts, p) end
  for _, p in ipairs(pts_r) do table.insert(pts, p) end
  cv:tint(36, 38, 16, 32, hex("#5a0622"), 0.6, true)
  cv:poly(pts, M.rift, { bevel = 5, ambient = 0.5 })
  for i, x in ipairs(xs) do cv:line(x, 6 + (i - 1) * 8, xs[i + 1] or x, 6 + i * 8, hex("#fff0f4")) end
  -- Olho na fenda: a coisa do outro lado olhando de volta.
  cv:ellipse(36.5, 38, 4, 2.5, ramp({ "#ffd0dd", "#ffe4ec", "#fff2f6", "#ffffff", "#ffffff" }))
  cv:ellipse(36.5, 38, 1.2, 2.4, M.black, { flat = 0, lift = -0.5 })
  -- Cristais em volta e faíscas.
  for _, c in ipairs({ { 14, 60, 4, 9 }, { 58, 58, 3, 8 }, { 20, 18, 2, 5 }, { 54, 22, 2, 6 } }) do
    cv:poly({ { c[1], c[2] - c[4] }, { c[1] + c[3], c[2] }, { c[1], c[2] + 2 }, { c[1] - c[3], c[2] } }, M.rift, { bevel = 2, lift = -0.1 })
  end
  for _, p in ipairs({ { 24, 30 }, { 48, 44 }, { 28, 52 }, { 46, 14 }, { 22, 42 }, { 50, 60 } }) do cv:px(p[1], p[2], hex("#ff8aa8")) end
  return cv:finish()
end

local ORDER = { "zeno", "livia", "brom", "forasteiro", "tessa", "bringer", "demon_slime", "gato", "velario", "capitao", "custodio", "vigia", "mira", "fenda" }
local list = ORDER
if app.params.only then
  list = {}
  for n in string.gmatch(app.params.only, "[^,]+") do table.insert(list, n) end
end
app.fs.makeAllDirectories(out_dir)
local made = {}
for _, id in ipairs(list) do
  local img = P[id]()
  img:saveAs(app.fs.joinPath(out_dir, id .. ".png"))
  table.insert(made, img)
end
print(string.format("%d rostos de personagens gravados", #made))

if app.params.sheet then
  local K, cols = tonumber(app.params.k or "4"), math.min(#made, tonumber(app.params.cols or "5"))
  local rows = math.ceil(#made / cols)
  local sheet = Image(cols * (S * K + 4) + 4, rows * (S * K + 4) + 4, ColorMode.RGB)
  sheet:clear(pc.rgba(20, 10, 16, 255))
  for i, img in ipairs(made) do
    local ox = 4 + ((i - 1) % cols) * (S * K + 4)
    local oy = 4 + ((i - 1) // cols) * (S * K + 4)
    for y = 0, S * K - 1 do
      for x = 0, S * K - 1 do
        local c = img:getPixel(x // K, y // K)
        sheet:drawPixel(ox + x, oy + y, pc.rgbaA(c) > 0 and c or pc.rgba(38, 13, 26, 255))
      end
    end
  end
  sheet:saveAs(app.params.sheet)
end
