-- Tileset "Minas da Fenda" (16x16, folha 8x3 pecas = 128x48)
local L, S, dir, prev = ...
local hex, hash = L.hex, L.hash

local ROCK = L.ramp { "#100a20", "#1b0f2b", "#321e4c", "#40295d", "#633c77", "#6f4b74", "#8f6a9b", "#b58bc1" }
local CR = L.ramp { "#41193b", "#961030", "#e82e52", "#ffaabe" }
local WD = L.ramp { "#41193b", "#47222e", "#5a2d2b", "#a4804e" }
local IRON, IRONHI = hex("#6f4b74"), hex("#b58bc1")
local GLOW = hex("#e82e52")

-- pedra de caverna: Voronoi periodico, sombreado de travesseiro
local seeds = {
  { 3.5, 3.5, 0.00 }, { 11.0, 2.0, 0.06 }, { 7.0, 9.5, -0.05 },
  { 14.5, 10.5, 0.03 }, { 2.0, 13.5, -0.02 },
}
local function rock(x, y)
  local d1, d2, i, dx, dy = S.voronoi(x % 16, y % 16, seeds, 16)
  local e = d2 - d1
  if e < 0.9 then return hash(x, y, 3) < 0.35 and 1 or 2 end
  local m = math.max(d1, 0.01)
  local lit = (dx / m) * L.LX + (dy / m) * L.LY
  local edge = math.max(0, 1 - (e - 0.9) / 3)
  local b = 0.40 + seeds[i][3] + lit * 0.42 * edge + (hash(x, y, 9) - 0.5) * 0.07
  local idx = 3 + math.floor(b * 4.6)
  if idx < 3 then idx = 3 elseif idx > 7 then idx = 7 end
  return idx
end

local prof = {
  t = { 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1 },
  l = { 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1 },
  r = { 0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0 },
  b = { 1, 1, 0, 0, 1, 2, 2, 1, 0, 0, 0, 1, 1, 0, 0, 1 },
}

local T = S.set9(rock, ROCK, prof)

local function copy(c)
  local n = L.canvas(c.w, c.h)
  n:blit(c, 0, 0)
  return n
end

-- veio de cristal embutido na pedra
local function vein(c, pts, seed)
  local core = {}
  for i = 1, #pts - 1 do
    local a, b = pts[i], pts[i + 1]
    L.line(a[1], a[2], b[1], b[2], function(x, y)
      core[y * 16 + x] = true
      c:set(x, y, hash(x, y, seed) < 0.22 and CR[4] or CR[3], "vein")
      -- engrossa o miolo do veio longe das pontas
      if i > 1 and i < #pts - 1 and hash(x, y, seed + 2) < 0.6 then
        core[(y + 1) * 16 + x] = true
        c:set(x, y + 1, CR[3], "vein")
      end
    end)
  end
  for k in pairs(core) do
    local x, y = k % 16, k // 16
    for _, d in ipairs { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
      local nx, ny = x + d[1], y + d[2]
      if nx >= 0 and nx < 16 and ny >= 0 and ny < 16 and not core[ny * 16 + nx] and c:get(nx, ny) then
        if hash(nx, ny, seed + 1) < 0.55 then c:set(nx, ny, CR[2]) end
      end
    end
  end
  c:glow("vein", GLOW, 60, 0)
end

-- madeira
local function beamH(c, x0, x1, y0, y1, bolts)
  for y = y0, y1 do
    for x = x0, x1 do
      local col
      if y == y0 then col = hash(x, y, 21) < 0.15 and WD[3] or WD[4]
      elseif y == y1 then col = WD[1]
      elseif y == y1 - 1 then col = WD[2]
      else col = hash(x // 4 + y * 7, y, 22) < 0.3 and WD[2] or WD[3] end
      if x == x0 or x == x1 then col = (y == y0) and WD[3] or WD[2] end
      c:set(x, y, col)
    end
  end
  for _, bx in ipairs(bolts or {}) do
    c:set(bx, y0 + 2, IRONHI); c:set(bx, y0 + 3, IRON)
  end
end

local function postV(c, x0, x1, y0, y1)
  for y = y0, y1 do
    for x = x0, x1 do
      local col
      if x == x0 then col = hash(x, y, 23) < 0.15 and WD[3] or WD[4]
      elseif x == x1 then col = WD[1]
      elseif x == x1 - 1 then col = WD[2]
      else col = hash(x, y // 4 + x * 5, 24) < 0.3 and WD[2] or WD[3] end
      c:set(x, y, col)
    end
  end
end

local function brace(c, x0, y0, x1, y1, r)
  L.capsule(x0, y0, x1, y1, r, r, function(x, y, t, s)
    local col
    if s < -0.5 then col = WD[4] elseif s < 0.35 then col = WD[3] elseif s < 0.75 then col = WD[2] else col = WD[1] end
    if col == WD[3] and hash(math.floor(t * 9), math.floor(s * 3), 25) < 0.3 then col = WD[2] end
    c:set(x, y, col)
  end)
end

local tiles = {}

-- plataforma de tabuas velhas
local function plank(kind)
  local c = L.canvas(16, 16)
  local x0 = (kind == "L") and 1 or 0
  local x1 = (kind == "R") and 14 or 15
  for y = 0, 4 do
    for x = x0, x1 do
      local col
      if y == 0 then col = hash(x, y, 31) < 0.18 and WD[3] or WD[4]
      elseif y == 4 then col = WD[1]
      else col = hash(x // 3, y, 32 + x // 5) < 0.3 and WD[2] or WD[3] end
      local seam = (x % 8 == 4)
      if seam then col = (y == 0) and WD[2] or WD[1] end
      if (kind == "L" and x == x0) then col = (y == 0) and WD[3] or WD[2] end
      if (kind == "R" and x == x1) then col = WD[1] end
      c:set(x, y, col)
    end
  end
  if kind == "L" then c:erase(1, 0); c:erase(1, 4) end
  if kind == "R" then c:erase(14, 0); c:erase(14, 4) end
  if kind == "M" then c:erase(10, 0); c:erase(11, 0); c:set(10, 1, WD[2]); c:set(11, 1, WD[2]) end
  -- travessa por baixo
  local jx0 = (kind == "L") and 3 or 0
  local jx1 = (kind == "R") and 12 or 15
  for x = jx0, jx1 do
    c:set(x, 5, WD[2])
    c:set(x, 6, WD[1])
  end
  -- pregos
  local nails = { L = { 3, 10 }, M = { 2, 6, 13 }, R = { 5, 12 } }
  for _, nx in ipairs(nails[kind]) do c:set(nx, 2, IRONHI) end
  -- escoras curtas nas pontas
  if kind == "L" then brace(c, 4, 6, 7, 11, 1.1) end
  if kind == "R" then brace(c, 11, 6, 8, 11, 1.1) end
  return c
end
tiles.platL, tiles.platM, tiles.platR = plank("L"), plank("M"), plank("R")

-- escora de madeira (viga, poste, juncoes, mao-francesa, base)
tiles.beam = L.canvas(16, 16)
beamH(tiles.beam, -1, 16, 0, 7, { 4, 12 }) -- pontas fora do tile: emenda sem corte
tiles.post = L.canvas(16, 16); postV(tiles.post, 5, 10, 0, 15)
tiles.post:set(7, 4, IRONHI); tiles.post:set(7, 11, IRONHI)

tiles.jointL = L.canvas(16, 16)
postV(tiles.jointL, 5, 10, 0, 15)
brace(tiles.jointL, 10, 13, 15, 8, 1.4)
beamH(tiles.jointL, 2, 16, 0, 7, { 7, 13 })
tiles.jointL:erase(2, 0); tiles.jointL:erase(2, 7)

tiles.jointR = L.canvas(16, 16)
postV(tiles.jointR, 5, 10, 0, 15)
brace(tiles.jointR, 5, 13, 0, 8, 1.4)
beamH(tiles.jointR, -1, 13, 0, 7, { 2, 8 })
tiles.jointR:erase(13, 0); tiles.jointR:erase(13, 7)

tiles.postBase = L.canvas(16, 16)
postV(tiles.postBase, 5, 10, 0, 12)
for y = 12, 15 do
  for x = 3, 12 do
    local col
    if y == 12 then col = ROCK[7] elseif x == 3 then col = ROCK[6] elseif x == 12 then col = ROCK[3]
    elseif y == 15 then col = ROCK[3] else col = ROCK[5] end
    if (x == 3 or x == 12) and y == 12 then col = nil end
    if col then tiles.postBase:set(x, y, col) end
  end
end
tiles.postBase:set(5, 13, ROCK[4]); tiles.postBase:set(9, 14, ROCK[4])

tiles.brace = L.canvas(16, 16)
brace(tiles.brace, 1, 15, 15, 1, 2.3)
tiles.brace:set(3, 12, IRONHI); tiles.brace:set(12, 3, IRONHI)

-- variacoes de pedra com veios
tiles.veinA = copy(T.M)
vein(tiles.veinA, { { 2, 4 }, { 5, 6 }, { 8, 6 }, { 10, 9 }, { 13, 10 } }, 50)
tiles.veinB = copy(T.M)
vein(tiles.veinB, { { 3, 13 }, { 6, 10 }, { 7, 7 }, { 11, 5 }, { 12, 2 } }, 60)
vein(tiles.veinB, { { 7, 7 }, { 4, 5 } }, 61)

-- topo com cristais brotando do chao
tiles.Tcrys = copy(T.T)
L.shard(tiles.Tcrys, 4, 10, 2, 1, 3.2, CR, "cr")
L.shard(tiles.Tcrys, 6, 11, 7, 3, 2.6, CR, "cr")
L.shard(tiles.Tcrys, 12, 10, 14, 2, 3.0, CR, "cr")
tiles.Tcrys:glow("cr", GLOW, 70, 0)

-- aglomerado de cristal (decoracao, fundo transparente)
tiles.cluster = L.canvas(16, 16)
L.shard(tiles.cluster, 5, 16, 1, 7, 3.6, CR, "cr")
L.shard(tiles.cluster, 11, 16, 14, 6, 3.6, CR, "cr")
L.shard(tiles.cluster, 8, 16, 7.5, 1.5, 4.6, CR, "cr")
L.shard(tiles.cluster, 3, 16, 1.5, 12, 2.2, CR, "cr")
L.shard(tiles.cluster, 13, 16, 15, 12, 2.0, CR, "cr")
for x = 2, 13 do
  if hash(x, 15, 70) < 0.5 then tiles.cluster:set(x, 15, ROCK[4]) end
end
tiles.cluster:set(4, 15, ROCK[5]); tiles.cluster:set(10, 15, ROCK[5]); tiles.cluster:set(11, 14, ROCK[3])
tiles.cluster:glow("cr", GLOW, 80, 30)

-- estalactite de cristal pendurada no teto
tiles.stal = L.canvas(16, 16)
L.shard(tiles.stal, 8, 0, 8, 13, 4.6, CR, "cr")
L.shard(tiles.stal, 4, 0, 5, 8, 3.0, CR, "cr")
L.shard(tiles.stal, 12, 0, 11, 6, 2.8, CR, "cr")
for x = 1, 14 do
  tiles.stal:set(x, 0, ROCK[3])
  if x > 2 and x < 13 then tiles.stal:set(x, 1, hash(x, 1, 71) < 0.5 and ROCK[2] or ROCK[3]) end
end
tiles.stal:glow("cr", GLOW, 80, 30)

-- monta a folha
local sheet = L.canvas(128, 48)
local layout = {
  { T.TL, T.T, T.TR, tiles.platL, tiles.platM, tiles.platR, tiles.jointL, tiles.beam },
  { T.L, T.M, T.R, tiles.veinA, tiles.veinB, tiles.cluster, tiles.jointR, tiles.post },
  { T.BL, T.B, T.BR, T.ONE, tiles.Tcrys, tiles.stal, tiles.brace, tiles.postBase },
}
for r, row in ipairs(layout) do
  for col, t in ipairs(row) do sheet:blit(t, (col - 1) * 16, (r - 1) * 16) end
end

L.saveTileset(sheet, dir, "minas_da_fenda_tileset")
L.preview(sheet, prev .. "/prev_minas.png", 6, hex("#1b1230"))

-- amostra montada (para revisao)
local demo = L.canvas(160, 96)
local function put(t, cx, cy) demo:blit(t, cx * 16, cy * 16) end
for cx = 0, 9 do
  for cy = 3, 5 do
    local t = T.M
    if cy == 3 then t = (cx == 0) and T.TL or ((cx == 9) and T.TR or T.T) end
    if cy > 3 and cx == 0 then t = T.L end
    if cy > 3 and cx == 9 then t = T.R end
    put(t, cx, cy)
  end
end
put(tiles.Tcrys, 4, 3); put(tiles.veinA, 2, 4); put(tiles.veinB, 6, 5)
put(tiles.cluster, 7, 2)
put(tiles.jointL, 1, 0); put(tiles.beam, 2, 0); put(tiles.beam, 3, 0); put(tiles.jointR, 4, 0)
put(tiles.post, 1, 1); put(tiles.postBase, 1, 2); put(tiles.post, 4, 1); put(tiles.postBase, 4, 2)
put(tiles.platL, 6, 1); put(tiles.platM, 7, 1); put(tiles.platR, 8, 1)
put(tiles.stal, 8, 0)
put(T.ONE, 9, 1)
L.preview(demo, prev .. "/demo_minas.png", 4, hex("#1b1230"))
