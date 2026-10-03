-- Logo da tela de título em pixel art (NOCT / CRIMSON RIFT / Break the Rift. Become the weapon.).
-- Desenha tudo no Aseprite, em pixels de jogo (1:1 com a tela de 480x270), em três camadas
-- (aura, letras, texto) e 15 quadros: abertura (0-7), pulso em loop (8-13) e saída (14).
-- Salva o .aseprite editável e exporta cada quadro achatado como logo_NN.png.
-- Uso:
--   Aseprite.exe -b --script-param src=<arquivo.aseprite> --script-param out=<pasta> --script tools/make_logo.lua

local W, H = 300, 112
local OUT = app.params.out
local SRC = app.params.src

local pc = app.pixelColor
local function hex(s)
  return pc.rgba(tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16), 255)
end

-- Paleta: ferro escuro das letras, rampa carmesim da fenda/aura e o claro do subtítulo.
local K = {
  outline = hex("#0b0509"),
  d0 = hex("#150d14"), d1 = hex("#21151d"), d2 = hex("#30212b"), d3 = hex("#4e3a46"), d4 = hex("#8c7383"),
  r0 = hex("#3a0613"), r1 = hex("#650a1d"), r2 = hex("#9e122a"), r3 = hex("#d6233a"), r4 = hex("#ff5d5a"),
  r5 = hex("#ffc4b8"), w = hex("#fff6f0"),
  pale = hex("#e9dadd"), pale2 = hex("#b29ca6"),
}

-- ---------------------------------------------------------------- formas
local function idx(x, y) return y * W + x + 1 end
local function inside_poly(px, py, pts)
  local c = false
  local j = #pts
  for i = 1, #pts do
    local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
    if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then c = not c end
    j = i
  end
  return c
end
local function fill_poly(mask, pts, ox, oy, val)
  local x0, y0, x1, y1 = 1e9, 1e9, -1e9, -1e9
  for _, p in ipairs(pts) do
    x0 = math.min(x0, p[1]); x1 = math.max(x1, p[1]); y0 = math.min(y0, p[2]); y1 = math.max(y1, p[2])
  end
  for y = math.floor(y0 + oy), math.ceil(y1 + oy) do
    for x = math.floor(x0 + ox), math.ceil(x1 + ox) do
      if x >= 0 and x < W and y >= 0 and y < H and inside_poly(x + 0.5 - ox, y + 0.5 - oy, pts) then
        mask[idx(x, y)] = val
      end
    end
  end
end
local function in_ell(px, py, cx, cy, a, b, p)
  return (math.abs(px - cx) / a) ^ p + (math.abs(py - cy) / b) ^ p <= 1
end

local Y0 = 19          -- topo das maiúsculas
local CAP = 48
local LX = { N = 58, O = 106, C = 157, T = 198 }
local OC = { x = LX.O + 23, y = Y0 + 24 }   -- centro do O (a fenda)
local OIN = { a = 11.5, b = 19.5 }

local letter = {}   -- 1 = ferro das letras (NOCT)
local onlyO = {}    -- só o anel do O (para a abertura)
local inner = {}    -- miolo do O
for i = 1, W * H do letter[i] = 0; onlyO[i] = 0; inner[i] = 0 end

-- N: haste grossa com corte em ponta, diagonal pesada e haste fina com espinho.
fill_poly(letter, {{2,5},{12,-1},{14,2},{14,44},{9,49},{2,55},{4,45}}, LX.N, Y0, 1)
fill_poly(letter, {{9,-1},{17,-1},{40,45},{39,49},{32,49}}, LX.N, Y0, 1)
fill_poly(letter, {{34,4},{40,0},{46,-7},{42,4},{42,46},{37,50},{34,46}}, LX.N, Y0, 1)
-- serifas em espinho no pé da haste fina e no topo da grossa
fill_poly(letter, {{30,48},{37,44},{44,50},{37,50}}, LX.N, Y0, 1)
fill_poly(letter, {{0,2},{9,0},{12,4},{4,6}}, LX.N, Y0, 1)

-- O: anel em amêndoa com coroa de espinhos em cima e embaixo; o miolo é a fenda.
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local px, py = x + 0.5, y + 0.5
    if in_ell(px, py, OC.x, OC.y, 23, 25, 2.3) then
      if in_ell(px, py, OC.x, OC.y, OIN.a, OIN.b, 1.7) then
        inner[idx(x, y)] = 1
      else
        letter[idx(x, y)] = 1; onlyO[idx(x, y)] = 1
      end
    end
  end
end
for _, s in ipairs({{{19,1},{23,-7},{27,1}}, {{19,47},{23,56},{27,47}}, {{-2,22},{-6,24},{-2,26}}, {{48,22},{52,24},{48,26}}}) do
  fill_poly(letter, s, LX.O, Y0, 1); fill_poly(onlyO, s, LX.O, Y0, 1)
end

-- C: arco aberto à direita com terminais farpados.
local CC = { x = LX.C + 20, y = Y0 + 24 }
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local px, py = x + 0.5, y + 0.5
    if in_ell(px, py, CC.x, CC.y, 20, 25, 2.2) and not in_ell(px, py, CC.x + 2, CC.y, 12, 19, 2.0) then
      if not (px > CC.x + 5 and math.abs(py - CC.y) < 14) then letter[idx(x, y)] = 1 end
    end
  end
end
fill_poly(letter, {{26,4},{38,-5},{36,6},{31,13},{27,9}}, LX.C, Y0, 1)
fill_poly(letter, {{27,39},{31,35},{37,42},{40,52},{28,46}}, LX.C, Y0, 1)

-- T: barra arqueada com pontas em lança e haste que termina em ponta.
fill_poly(letter, {{-1,-3},{10,2},{34,2},{45,-3},{41,10},{31,8},{13,8},{3,10}}, LX.T, Y0, 1)
fill_poly(letter, {{17,6},{27,6},{27,42},{22,53},{17,42}}, LX.T, Y0, 1)
fill_poly(letter, {{27,30},{32,27},{27,36}}, LX.T, Y0, 1)

-- ---------------------------------------------------------------- ruído
local function hash(x, y, s)
  local h = (x * 374761393 + y * 668265263 + s * 982451653) & 0xffffffff
  h = ((h ~ (h >> 13)) * 1274126177) & 0xffffffff
  return ((h ~ (h >> 16)) & 0xffff) / 65535
end
local function noise(x, y, s)
  local xi, yi = math.floor(x), math.floor(y)
  local fx, fy = x - xi, y - yi
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local a = hash(xi, yi, s) + (hash(xi + 1, yi, s) - hash(xi, yi, s)) * fx
  local b = hash(xi, yi + 1, s) + (hash(xi + 1, yi + 1, s) - hash(xi, yi + 1, s)) * fx
  return a + (b - a) * fy
end
local BAYER = {{0,8,2,10},{12,4,14,6},{3,11,1,9},{15,7,13,5}}
local function bayer(x, y) return (BAYER[y % 4 + 1][x % 4 + 1] + 0.5) / 16 end

-- ---------------------------------------------------------------- fontes do texto
local BIG = {   -- 7 linhas; desenhada com hastes de 2px e altura dobrada
  C = {".###.","#...#","#....","#....","#....","#...#",".###."},
  R = {"####.","#...#","#...#","####.","#.#..","#..#.","#...#"},
  I = {"###",".#.",".#.",".#.",".#.",".#.","###"},
  M = {"#.....#","##...##","#.#.#.#","#..#..#","#.....#","#.....#","#.....#"},
  S = {".####","#....","#....",".###.","....#","....#","####."},
  O = {".###.","#...#","#...#","#...#","#...#","#...#",".###."},
  N = {"#....#","##...#","#.#..#","#..#.#","#...##","#....#","#....#"},
  F = {"#####","#....","#....","####.","#....","#....","#...."},
  T = {"#####","..#..","..#..","..#..","..#..","..#..","..#.."},
}
local SMALL = { -- 5 linhas
  B = {"##.","#.#","##.","#.#","##."}, R = {"##.","#.#","##.","#.#","#.#"},
  E = {"###","#..","##.","#..","###"}, A = {".#.","#.#","###","#.#","#.#"},
  K = {"#.#","#.#","##.","#.#","#.#"}, T = {"###",".#.",".#.",".#.",".#."},
  H = {"#.#","#.#","###","#.#","#.#"}, I = {"###",".#.",".#.",".#.","###"},
  F = {"###","#..","##.","#..","#.."}, C = {".##","#..","#..","#..",".##"},
  O = {".#.","#.#","#.#","#.#",".#."}, M = {"#...#","##.##","#.#.#","#...#","#...#"},
  W = {"#...#","#...#","#.#.#","##.##","#...#"}, P = {"##.","#.#","##.","#..","#.."},
  N = {"#..#","##.#","#.##","#..#","#..#"}, ["."] = {".",".",".",".","#"},
}

-- Rasteriza uma linha de texto em uma máscara: devolve {mask, largura}.
local function text_mask(str, font, sx, sy, gap, space)
  local cells, x = {}, 0
  for ch in str:gmatch(".") do
    if ch == " " then
      x = x + space
    else
      local g = font[ch]
      for r, row in ipairs(g) do
        for c = 1, #row do
          if row:sub(c, c) == "#" then
            for yy = 0, sy - 1 do for xx = 0, sx - 1 do
              cells[#cells + 1] = {x + (c - 1) * sx + xx, (r - 1) * sy + yy, r}
            end end
          end
        end
      end
      x = x + #g[1] * sx + gap
    end
  end
  return cells, x - gap
end

local title_cells, title_w = text_mask("CRIMSON RIFT", BIG, 2, 2, 3, 8)
local TITLE_X, TITLE_Y = math.floor((W - title_w) / 2), 77
local tag_cells, tag_w = text_mask("BREAK THE RIFT. BECOME THE WEAPON.", SMALL, 1, 1, 1, 3)
local TAG_X, TAG_Y = math.floor((W - tag_w) / 2), 98

-- ---------------------------------------------------------------- render de um quadro
local function put(img, x, y, c) if x >= 0 and x < W and y >= 0 and y < H then img:drawPixel(x, y, c) end end
local function get(m, x, y) if x < 0 or x >= W or y < 0 or y >= H then return 0 end return m[idx(x, y)] end

-- o: tabela de opções do quadro.
--   letters: "none" | "O" | "all";  look: "silhouette" | "full" | "flash"
--   slit (0-1): quanto da fenda está aberta;  glow (0-1): força do miolo do O
--   aura (px), auraK (força), seed (animação do fogo), text, tag, dissolve, spark
local function render(o)
  local aura, lets, txt = Image(W, H, ColorMode.RGB), Image(W, H, ColorMode.RGB), Image(W, H, ColorMode.RGB)
  local vis = {}
  for i = 1, W * H do
    local v = 0
    if o.letters == "all" then v = letter[i] elseif o.letters == "O" then v = onlyO[i] end
    if v == 1 and o.dissolve and hash(i, 7, o.seed) < 0.55 then v = 0 end
    vis[i] = v
  end

  -- Fenda: largura por linha; fontes de luz = letras visíveis + fenda.
  local slitHalf = {}
  local src = {}
  for i = 1, W * H do src[i] = vis[i] end
  if o.spark then src[idx(math.floor(OC.x), math.floor(OC.y))] = 1 end
  if o.slit > 0 then
    for y = 0, H - 1 do
      local dy = (y + 0.5 - OC.y) / OIN.b
      if math.abs(dy) <= o.slit then
        local hw = math.floor((1 - dy * dy) * (2.2 + (o.pulse or 0)) + 0.5)
        slitHalf[y] = hw
        for x = math.floor(OC.x) - hw - 1, math.floor(OC.x) + hw do src[idx(x, y)] = 1 end
      end
    end
  end

  -- Aura: distância até as fontes, com fogo que sobe e pontilhado ordenado.
  if o.aura > 0 then
    -- distância chanfrada (reto 1, diagonal 1.41) em duas passadas: aura arredondada, não quadrada
    local dist = {}
    for i = 1, W * H do dist[i] = (src[i] == 1) and 0 or 999 end
    local D = 1.41
    for y = 0, H - 1 do for x = 0, W - 1 do
      local i, d = idx(x, y), dist[idx(x, y)]
      if x > 0 then d = math.min(d, dist[i - 1] + 1) end
      if y > 0 then
        d = math.min(d, dist[i - W] + 1)
        if x > 0 then d = math.min(d, dist[i - W - 1] + D) end
        if x < W - 1 then d = math.min(d, dist[i - W + 1] + D) end
      end
      dist[i] = d
    end end
    for y = H - 1, 0, -1 do for x = W - 1, 0, -1 do
      local i, d = idx(x, y), dist[idx(x, y)]
      if x < W - 1 then d = math.min(d, dist[i + 1] + 1) end
      if y < H - 1 then
        d = math.min(d, dist[i + W] + 1)
        if x < W - 1 then d = math.min(d, dist[i + W + 1] + D) end
        if x > 0 then d = math.min(d, dist[i + W - 1] + D) end
      end
      dist[i] = d
    end end
    local ramp = {K.r0, K.r1, K.r2, K.r3}
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        local d = dist[idx(x, y)]
        if d > 0 and d <= o.aura then
          local v = 1 - (d - 1) / o.aura
          local n = noise(x / 5, (y + o.seed * 3) / 4, 11)
          local up = math.max(0, (OC.y - y) / 30)      -- o fogo é mais alto em cima
          v = v * (0.55 + 0.8 * n) * o.auraK + up * n * 0.35 * o.auraK
          local lv = math.floor(v * 4 + bayer(x, y) - 0.5)
          if lv >= 1 then put(aura, x, y, ramp[math.min(lv, 4)]) end
        end
      end
    end
    -- Raios curtos saindo das letras e brasas subindo.
    if o.letters == "all" and not o.dissolve then
      for b = 1, 7 do
        -- nasce na borda de uma letra e corre para fora dela
        local x, y, dirx = 0, 0, 1
        for try = 0, 400 do
          x = math.floor(LX.N - 4 + hash(b, 1 + try * 5, o.seed) * 192)
          y = math.floor(Y0 - 4 + hash(b, 2 + try * 5, o.seed) * 58)
          if get(vis, x, y) == 1 then
            if get(vis, x + 1, y) == 0 then dirx = 1; break end
            if get(vis, x - 1, y) == 0 then dirx = -1; break end
          end
        end
        for s = 1, 6 + math.floor(hash(b, 4, o.seed) * 6) do
          x = x + dirx; y = y + (hash(b, 10 + s, o.seed) < 0.5 and -1 or 1)
          if get(src, x, y) == 0 and dist[idx(math.max(0, math.min(W - 1, x)), math.max(0, math.min(H - 1, y)))] <= o.aura then
            put(aura, x, y, s < 4 and K.r4 or K.r3)
          end
        end
      end
      for e = 1, 14 do
        local ex = math.floor(LX.N + hash(e, 21, 0) * 186)
        local ey = Y0 + 40 - ((math.floor(hash(e, 22, 0) * 48) + o.seed * 7) % 56)
        if ey >= 0 and get(src, ex, ey) == 0 then put(aura, ex, ey, hash(e, 23, 0) < 0.4 and K.r5 or K.r4) end
      end
    end
  end

  -- Miolo do O: brilho vermelho que cresce em direção à fenda.
  if o.glow > 0 then
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        if inner[idx(x, y)] == 1 then
          local dx = math.abs(x + 0.5 - OC.x) / OIN.a
          local v = (1 - dx) * o.glow
          local lv = math.floor(v * 3 + bayer(x, y) * 0.9)
          local c = ({K.outline, K.r0, K.r1, K.r2})[math.max(0, math.min(lv, 3)) + 1]
          put(lets, x, y, c)
        end
      end
    end
  end
  for y, hw in pairs(slitHalf) do
    local cx = math.floor(OC.x)
    for x = cx - hw - 1, cx + hw do
      local off = (x < cx) and (cx - 1 - x) or (x - cx)
      local c = (off == 0) and K.w or (off == 1 and K.r5) or (off >= hw and K.r3) or K.r4
      if off > hw then c = K.r2 end
      put(lets, x, y, c)
    end
  end

  -- Letras: contorno escuro, ferro com degradê, aresta de cima clara e de baixo avermelhada.
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local i = idx(x, y)
      if vis[i] == 1 then
        local c
        if o.look == "silhouette" then
          c = K.d0
          if get(vis, x, y - 1) == 0 or get(vis, x + 1, y) == 0 or get(vis, x - 1, y) == 0 or get(vis, x, y + 1) == 0 then c = K.r1 end
        elseif o.look == "flash" then
          c = K.d3
          if get(vis, x, y - 1) == 0 or get(vis, x - 1, y) == 0 or get(vis, x + 1, y) == 0 or get(vis, x, y + 1) == 0 then c = K.r5 end
        else
          local t = (y - Y0) / CAP
          c = t < 0.3 and K.d2 or (t < 0.7 and K.d1 or K.d0)
          if get(vis, x, y - 2) == 0 and get(vis, x, y - 1) == 1 then c = K.d3 end
          if get(vis, x, y - 1) == 0 or get(vis, x - 1, y) == 0 then c = K.d4 end
          if get(vis, x, y + 1) == 0 or get(vis, x + 1, y) == 0 then c = K.r2 end
          if (get(vis, x, y + 1) == 0 or get(vis, x + 1, y) == 0) and (get(vis, x, y - 1) == 0 or get(vis, x - 1, y) == 0) then c = K.r3 end
        end
        put(lets, x, y, c)
      elseif get(vis, x - 1, y) + get(vis, x + 1, y) + get(vis, x, y - 1) + get(vis, x, y + 1) > 0 and inner[i] == 0 then
        put(lets, x, y, K.outline)
      elseif o.dissolve and letter[i] == 1 and hash(i, 9, o.seed) < 0.25 then
        put(lets, x, y, hash(i, 8, o.seed) < 0.5 and K.r4 or K.r3)
      end
    end
  end

  if o.spark then
    local cx, cy = math.floor(OC.x), math.floor(OC.y)
    put(lets, cx, cy, K.w); put(lets, cx - 1, cy, K.r5); put(lets, cx + 1, cy, K.r5)
    put(lets, cx, cy - 1, K.r5); put(lets, cx, cy + 1, K.r5)
    put(lets, cx - 2, cy, K.r3); put(lets, cx + 2, cy, K.r3); put(lets, cx, cy - 3, K.r3); put(lets, cx, cy + 3, K.r3)
  end

  -- Texto: CRIMSON RIFT em carmesim e o subtítulo claro, ambos com contorno.
  local function stamp(cells, ox, oy, colorFor)
    local m = {}
    for _, c in ipairs(cells) do m[(oy + c[2]) * W + ox + c[1]] = c end
    for _, c in ipairs(cells) do
      local x, y = ox + c[1], oy + c[2]
      for dy = -1, 1 do for dx = -1, 1 do
        if not m[(y + dy) * W + x + dx] then put(txt, x + dx, y + dy, K.outline) end
      end end
    end
    for _, c in ipairs(cells) do put(txt, ox + c[1], oy + c[2], colorFor(c, m)) end
  end
  if o.text then
    stamp(title_cells, TITLE_X, TITLE_Y, function(c, m)
      if not m[(TITLE_Y + c[2] - 1) * W + TITLE_X + c[1]] then return K.r5 end
      if c[3] <= 2 then return K.r4 elseif c[3] >= 6 then return K.r2 end
      return K.r3
    end)
  end
  if o.tag then
    stamp(tag_cells, TAG_X, TAG_Y, function(c) return c[3] <= 2 and K.pale or K.pale2 end)
    -- filetes com losango dos dois lados do subtítulo
    local y = TAG_Y + 2
    for side = -1, 1, 2 do
      local x0 = side < 0 and TAG_X - 5 or TAG_X + tag_w + 4
      for k = 0, 34 do
        local x = x0 + side * k
        if k < 22 or bayer(x, y) < (34 - k) / 13 then put(txt, x, y, k < 3 and K.r4 or K.r2) end
      end
      put(txt, x0, y - 1, K.r3); put(txt, x0, y + 1, K.r3); put(txt, x0 - side, y, K.r5)
    end
  end
  return aura, lets, txt
end

-- ---------------------------------------------------------------- quadros
local FRAMES = {
  -- abertura
  {letters = "none", slit = 0, glow = 0, aura = 3, auraK = 0.8, seed = 0, spark = true, look = "full", ms = 90},
  {letters = "none", slit = 0.3, glow = 0, aura = 4, auraK = 0.9, seed = 1, look = "full", ms = 90},
  {letters = "none", slit = 0.7, glow = 0.5, aura = 5, auraK = 0.9, seed = 2, look = "full", ms = 90},
  {letters = "O", slit = 1, glow = 0.8, aura = 6, auraK = 0.9, seed = 3, look = "silhouette", ms = 90},
  {letters = "all", slit = 1, glow = 0.8, aura = 5, auraK = 0.8, seed = 4, look = "silhouette", ms = 90},
  {letters = "all", slit = 1, glow = 1, aura = 8, auraK = 1, seed = 5, look = "silhouette", ms = 90},
  {letters = "all", slit = 1, glow = 1, aura = 11, auraK = 1.3, seed = 6, look = "flash", pulse = 1, text = true, ms = 90},
  {letters = "all", slit = 1, glow = 1, aura = 9, auraK = 1.05, seed = 7, look = "full", text = true, tag = true, ms = 90},
}
-- loop: o fogo sobe e a fenda pulsa
for k = 0, 5 do
  FRAMES[#FRAMES + 1] = {letters = "all", slit = 1, glow = 1, aura = 9, auraK = (k % 3 == 0) and 0.95 or 0.85,
    seed = 10 + k, look = "full", text = true, tag = true, pulse = (k % 3 == 0) and 0.8 or 0, ms = 240}
end
-- saída: o logo se desfaz em faíscas
FRAMES[#FRAMES + 1] = {letters = "all", slit = 1, glow = 0.6, aura = 12, auraK = 1.2, seed = 30, look = "full",
  dissolve = true, text = false, tag = false, pulse = 1.5, ms = 300}

local spr = Sprite(W, H, ColorMode.RGB)
local lAura = spr.layers[1]; lAura.name = "aura"
local lLets = spr:newLayer(); lLets.name = "letras"
local lText = spr:newLayer(); lText.name = "texto"
for i = 2, #FRAMES do spr:newEmptyFrame() end
for i, o in ipairs(FRAMES) do
  local a, l, t = render(o)
  spr:newCel(lAura, i, a, Point(0, 0))
  spr:newCel(lLets, i, l, Point(0, 0))
  spr:newCel(lText, i, t, Point(0, 0))
  spr.frames[i].duration = o.ms / 1000
end
local function tag(a, b, name) local tg = spr:newTag(a, b); tg.name = name end
tag(1, 8, "abertura"); tag(9, 14, "loop"); tag(15, 15, "saida")

spr:saveAs(SRC)
for i = 1, #FRAMES do
  local img = Image(spr.spec)
  img:drawSprite(spr, i)
  img:saveAs(app.fs.joinPath(OUT, string.format("logo_%02d.png", i - 1)))
end
print("logo: " .. #FRAMES .. " quadros")
