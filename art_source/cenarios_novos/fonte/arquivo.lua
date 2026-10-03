-- Tileset "Arquivo Submerso" (16x16, folha 8x3 pecas = 128x48)
local L, S, dir, prev = ...
local hex, hash = L.hex, L.hash

local BR = L.ramp { "#100a20", "#161633", "#19183b", "#212049", "#33325e", "#40295d", "#633c77", "#8f6a9b" }
local WD = L.ramp { "#41193b", "#47222e", "#5a2d2b", "#a4804e" }
local TEAL, TEAL_D, TEAL_DD = hex("#5affe6"), hex("#1a4649"), hex("#0b2b28")
local BACK, BACK2 = hex("#100a20"), hex("#1b0f2b")
local GOLD = hex("#a4804e")

-- tijolo gotico 8x4 em amarracao corrida (periodo 16)
local tone = { 6, 5, 6, 6, 5, 6, 5, 6 }
local function brickInfo(x, y)
  x, y = x % 16, y % 16
  local row = y // 4
  local by = y % 4
  local xx = (x + (row % 2) * 4) % 16
  return row, by, xx % 8, row * 2 + xx // 8
end
local function brick(x, y)
  local row, by, bx, id = brickInfo(x, y)
  if by == 3 or bx == 7 then return hash(x, y, 3) < 0.3 and 1 or 2 end
  local idx = tone[id + 1]
  if by == 0 then idx = idx + 1 end
  if bx == 0 and by < 2 then idx = idx + 1 end
  if by == 2 then idx = idx - 1 end
  if bx == 6 and by > 0 then idx = idx - 1 end
  if hash(x, y, 4) < 0.07 then idx = idx - 1 end
  if idx < 2 then idx = 2 elseif idx > 7 then idx = 7 end
  return idx
end

local flat = {}
for i = 1, 16 do flat[i] = 0 end
local prof = { t = flat, l = flat, r = flat, b = flat }

-- borda molhada: brilho frio no topo, umidade escorrendo embaixo
local function rim(x, y, idx, side, dist)
  if side == "t" and dist == 0 and hash(x, y, 11) < 0.2 then return TEAL end
  if side == "t" and dist == 1 and hash(x, y, 12) < 0.1 then return TEAL_D end
  if side == "b" and dist == 0 and hash(x, y, 13) < 0.25 then return TEAL_D end
  return nil
end

local T = S.set9(brick, BR, prof, rim)
local tiles = {}

-- parede com mancha de agua escorrendo
local streakCols = { [4] = 15, [5] = 11, [10] = 9, [11] = 15, [12] = 6 }
tiles.wet = S.tile(function(x, y)
  local i = brick(x, y)
  local len = streakCols[x]
  if len and y <= len and i > 2 then i = i - 1 end
  return i
end, BR, {}, prof)
for x, len in pairs(streakCols) do
  for y = 0, len do
    if hash(x, y, 14) < 0.12 then tiles.wet:set(x, y, TEAL) end
  end
  tiles.wet:set(x, len + 1, TEAL_D)
end

-- runa entalhada com luz fria
tiles.rune = S.tile(brick, BR, {}, prof)
local glyph = {
  "..#..",
  ".###.",
  "#.#.#",
  "..#..",
  ".#.#.",
  "#...#",
}
for gy, row in ipairs(glyph) do
  for gx = 1, #row do
    if row:sub(gx, gx) == "#" then tiles.rune:set(5 + gx, 4 + gy, TEAL, "rune") end
  end
end
tiles.rune:glow("rune", TEAL, 70, 25)

-- plataforma: laje de pedra com misula
local function slab(kind)
  local c = L.canvas(16, 16)
  local x0 = (kind == "L") and 1 or 0
  local x1 = (kind == "R") and 14 or 15
  for y = 0, 5 do
    for x = x0, x1 do
      local col
      if y == 0 then col = hash(x, y, 41) < 0.2 and TEAL or BR[8]
      elseif y == 1 then col = BR[7]
      elseif y == 5 then col = BR[2]
      elseif y == 4 then col = BR[4]
      else col = hash(x, y, 42) < 0.1 and BR[4] or BR[5] end
      if x % 16 == 7 and y > 0 then col = BR[2] end
      if kind == "L" and x == x0 and y > 0 then col = BR[6] end
      if kind == "R" and x == x1 and y > 0 then col = BR[3] end
      c:set(x, y, col)
    end
  end
  if kind == "L" then c:erase(1, 0); c:erase(1, 5) end
  if kind == "R" then c:erase(14, 0); c:erase(14, 5) end
  -- misula em degraus sob as pontas
  if kind ~= "M" then
    for y = 6, 10 do
      local w = 11 - y
      for i = 0, w do
        local x = (kind == "L") and (2 + (y - 6) + i) or (13 - (y - 6) - i)
        local col = BR[4]
        if i == 0 then col = (kind == "L") and BR[6] or BR[3] end
        if y == 10 then col = BR[3] end
        c:set(x, y, col)
      end
    end
  else
    -- gotas pingando por baixo
    c:set(4, 6, TEAL_D); c:over(4, 7, TEAL, 140); c:over(4, 9, TEAL, 200)
    c:set(11, 6, TEAL_D); c:over(11, 8, TEAL, 120)
  end
  return c
end
tiles.platL, tiles.platM, tiles.platR = slab("L"), slab("M"), slab("R")

-- topo encharcado (poca de agua no chao)
tiles.Tpuddle = S.tile(brick, BR, { t = true }, prof, rim)
for x = 2, 13 do
  tiles.Tpuddle:set(x, 0, hash(x, 0, 45) < 0.35 and TEAL or TEAL_D)
  tiles.Tpuddle:set(x, 1, TEAL_DD)
end

----------------------------------------------------------------------------
-- estante de livros
local BOOKS = {
  L.ramp { "#41193b", "#5a2d2b", "#a4804e" },
  L.ramp { "#0b2b28", "#325507", "#4f7011" },
  L.ramp { "#19183b", "#33325e", "#6f4b74" },
  L.ramp { "#40295d", "#633c77", "#8f6a9b" },
  L.ramp { "#41193b", "#47222e", "#5a2d2b" },
  L.ramp { "#0b2b28", "#1a4649", "#5affe6" },
}

local function shelfFrame(c, y0, y1)
  for y = y0, y1 do
    for x = 2, 13 do c:set(x, y, (x % 5 == 0) and BACK2 or BACK) end
    c:set(0, y, WD[3]); c:set(1, y, WD[2]); c:set(14, y, WD[2]); c:set(15, y, WD[1])
  end
end

local function board(c, y)
  for x = 0, 15 do
    c:set(x, y, (x == 15) and WD[2] or (hash(x, y, 51) < 0.15 and WD[3] or WD[4]))
    c:set(x, y + 1, (hash(x, y, 52) < 0.2) and TEAL_D or WD[1])
  end
end

local function books(c, baseY, maxH, seed)
  local x = 2
  local n = 0
  while x <= 13 do
    n = n + 1
    local hw = hash(n, seed, 1)
    local w = (hw < 0.3) and 3 or ((hw < 0.85) and 2 or 1)
    if x + w - 1 > 13 then w = 13 - x + 1 end
    local h = maxH - math.floor(hash(n, seed, 2) * 3)
    local pick = 1 + math.floor(hash(n, seed, 3) * 5.99)
    if pick == 6 and hash(n, seed, 4) < 0.6 then pick = 4 end
    local R = BOOKS[pick]
    local band = w >= 2 and hash(n, seed, 8) < 0.5
    for i = 0, w - 1 do
      for y = baseY - h + 1, baseY do
        local col = R[2]
        if w == 3 and i == 0 then col = R[3] end
        if i == w - 1 and w >= 2 then col = R[1] end
        if band and y == baseY - h + 2 and i < w - 1 then col = GOLD end
        if y == baseY and hash(x + i, y, seed) < 0.4 then col = R[1] end
        c:set(x + i, y, col)
      end
    end
    if hash(n, seed, 6) < 0.25 then c:set(x, baseY, TEAL) end
    x = x + w
    if hash(n, seed, 7) < 0.15 then x = x + 1 end
  end
end
tiles.shelfTop = L.canvas(16, 16)
shelfFrame(tiles.shelfTop, 4, 13)
for x = 0, 15 do
  tiles.shelfTop:set(x, 0, WD[4])
  tiles.shelfTop:set(x, 1, WD[3])
  tiles.shelfTop:set(x, 2, WD[2])
  tiles.shelfTop:set(x, 3, WD[1])
end
for x = 3, 12, 3 do tiles.shelfTop:set(x, 1, GOLD) end
books(tiles.shelfTop, 13, 8, 61)
board(tiles.shelfTop, 14)

tiles.shelfMid = L.canvas(16, 16)
shelfFrame(tiles.shelfMid, 0, 15)
books(tiles.shelfMid, 5, 6, 62)
board(tiles.shelfMid, 6)
books(tiles.shelfMid, 13, 6, 63)
board(tiles.shelfMid, 14)

tiles.shelfBot = L.canvas(16, 16)
shelfFrame(tiles.shelfBot, 0, 11)
books(tiles.shelfBot, 5, 6, 64)
board(tiles.shelfBot, 6)
-- livros caidos, empilhados de lado
local pile = { { 2, 11, 9, BOOKS[3] }, { 4, 9, 7, BOOKS[1] }, { 3, 8, 3, BOOKS[2] } }
for _, b in ipairs(pile) do
  local bx, by, w, R = b[1], b[2], b[3], b[4]
  for x = bx, bx + w - 1 do
    tiles.shelfBot:set(x, by - 1, R[3]); tiles.shelfBot:set(x, by, R[2])
  end
  tiles.shelfBot:set(bx + w - 1, by - 1, BOOKS[1][3]); tiles.shelfBot:set(bx + w - 1, by, hex("#8f6a9b"))
end
tiles.shelfBot:set(12, 10, BOOKS[4][3]); tiles.shelfBot:set(12, 11, BOOKS[4][2]); tiles.shelfBot:set(13, 11, BOOKS[4][1])
for y = 12, 15 do
  for x = 0, 15 do
    local col = (y == 12) and WD[4] or ((y == 15) and WD[1] or WD[3])
    if x == 0 and y > 12 then col = WD[2] end
    if x == 15 then col = WD[1] end
    if y == 14 and (x == 4 or x == 11) then col = WD[2] end
    tiles.shelfBot:set(x, y, col)
  end
end
for x = 0, 15 do if hash(x, 15, 66) < 0.4 then tiles.shelfBot:set(x, 15, TEAL_D) end end
tiles.shelfBot:set(6, 13, TEAL); tiles.shelfBot:set(6, 14, TEAL_D)

----------------------------------------------------------------------------
-- agua rasa (semi-transparente)
local function crest(x) return (x % 8 < 4) and 1 or 2 end
tiles.water = L.canvas(16, 16)
for y = 0, 15 do
  for x = 0, 15 do
    local col = { 11, 43, 40, 200 }
    local streak = hash((x + y * 3) // 4, y, 82) < 0.1
    if streak then col = { 26, 70, 73, 200 } end
    if hash(x, y, 83) < 0.015 then col = { 90, 255, 230, 110 } end
    tiles.water:set(x, y, col)
  end
end

local function surface(withPage)
  local c = L.canvas(16, 16)
  for x = 0, 15 do
    local cy = crest(x)
    c:set(x, cy, { 90, 255, 230, (hash(x, 0, 84) < 0.3) and 255 or 220 })
    c:set(x, cy + 1, { 90, 255, 230, 110 })
    for y = cy + 2, 15 do
      local col = (y < 9) and { 26, 70, 73, 170 } or { 11, 43, 40, 200 }
      if y < 9 and hash(x, y, 85) < 0.06 then col = { 90, 255, 230, 90 } end
      c:set(x, y, col)
    end
  end
  if withPage then
    -- pagina boiando e ondulacao
    local page = hex("#b58bc1"); local pageS = hex("#8f6a9b")
    for x = 5, 11 do c:set(x, 1, page); c:set(x, 2, pageS) end
    c:set(5, 1, pageS); c:set(11, 2, hex("#6f4b74"))
    c:set(7, 2, hex("#40295d")); c:set(9, 2, hex("#40295d"))
    c:set(3, 2, TEAL); c:set(13, 2, TEAL)
  end
  return c
end
tiles.surf = surface(false)
tiles.surfPage = surface(true)

-- vela de chama fria (decoracao)
tiles.candle = L.canvas(16, 16)
do
  local c = tiles.candle
  local wax, waxS, waxD = hex("#b58bc1"), hex("#8f6a9b"), hex("#6f4b74")
  for y = 9, 13 do c:set(7, y, wax); c:set(8, y, waxS) end
  c:set(6, 10, waxS); c:set(6, 11, waxD); c:set(9, 12, waxD)
  c:set(7, 8, hex("#1b0f2b"))
  for x = 5, 10 do c:set(x, 14, (x == 5) and hex("#6f4b74") or hex("#33325e")) end
  for x = 4, 11 do c:set(x, 15, (x == 4) and hex("#33325e") or hex("#212049")) end
  c:set(7, 7, TEAL, "f"); c:set(7, 6, TEAL, "f"); c:set(8, 6, TEAL_D, "f")
  c:set(7, 5, TEAL, "f"); c:set(6, 6, TEAL_D, "f"); c:set(7, 4, { 90, 255, 230, 160 }, "f")
  c:glow("f", TEAL, 80, 35)
end

-- goteiras do teto (decoracao)
tiles.drips = L.canvas(16, 16)
do
  local c = tiles.drips
  for x = 1, 14 do if hash(x, 0, 91) < 0.6 then c:set(x, 0, TEAL_DD) end end
  local drips = { { 3, 3, 6 }, { 9, 5, 9 }, { 13, 2, 5 } }
  for _, d in ipairs(drips) do
    local x, len, drop = d[1], d[2], d[3]
    c:set(x, 0, TEAL_D)
    for y = 1, len do c:set(x, y, { 90, 255, 230, 220 - y * 25 }) end
    c:set(x, drop, TEAL); c:over(x, drop + 1, TEAL, 110)
  end
end

----------------------------------------------------------------------------
local sheet = L.canvas(128, 48)
local layout = {
  { T.TL, T.T, T.TR, tiles.platL, tiles.platM, tiles.platR, tiles.shelfTop, tiles.surf },
  { T.L, T.M, T.R, tiles.wet, tiles.rune, tiles.drips, tiles.shelfMid, tiles.water },
  { T.BL, T.B, T.BR, T.ONE, tiles.Tpuddle, tiles.candle, tiles.shelfBot, tiles.surfPage },
}
for r, row in ipairs(layout) do
  for col, t in ipairs(row) do sheet:blit(t, (col - 1) * 16, (r - 1) * 16) end
end
L.saveTileset(sheet, dir, "arquivo_submerso_tileset")
L.preview(sheet, prev .. "/prev_arquivo.png", 6, hex("#161633"))

local demo = L.canvas(160, 96)
local function put(t, cx, cy) demo:blit(t, cx * 16, cy * 16) end
for cx = 0, 9 do
  for cy = 4, 5 do
    local t = T.M
    if cy == 4 then t = (cx == 0) and T.TL or ((cx == 9) and T.TR or T.T) end
    if cy == 5 and cx == 0 then t = T.L end
    if cy == 5 and cx == 9 then t = T.R end
    put(t, cx, cy)
  end
end
put(tiles.Tpuddle, 2, 4); put(tiles.rune, 3, 5); put(tiles.wet, 7, 5)
for cx = 4, 6 do put(tiles.surf, cx, 4); put(tiles.water, cx, 5) end
put(tiles.surfPage, 5, 4)
put(tiles.shelfTop, 1, 1); put(tiles.shelfMid, 1, 2); put(tiles.shelfBot, 1, 3)
put(tiles.shelfTop, 2, 1); put(tiles.shelfMid, 2, 2); put(tiles.shelfBot, 2, 3)
put(tiles.platL, 5, 2); put(tiles.platM, 6, 2); put(tiles.platR, 7, 2)
put(tiles.candle, 8, 3); put(tiles.drips, 6, 3)
put(T.ONE, 9, 1)
L.preview(demo, prev .. "/demo_arquivo.png", 4, hex("#161633"))
