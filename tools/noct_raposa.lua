-- FORMAS CARMESIM do Noct demônio-raposa a partir da folha "Sprite de Guerreiro Raposa Demoníaco.png" (raiz do
-- projeto), convertido em pixel art na escala do jogo, o mais fiel possível à folha.
-- Cada quadro da folha é recortado, reduzido (média por área, sem borrar o alfa), alinhado pelos pés
-- e pelo centro do corpo no quadro do Noct (117x77, pés em 50,64) e levado para uma paleta curta
-- tirada da própria folha (corpo e energia separados, para a pele, o cabelo e a roupa não sumirem no
-- vermelho). É a única Forma Demoníaca do jogo (c3_*: a folha inteira, com o leque de caudas).
-- LEVEL_TAILS/strip_fan/sheet_tail fazem versões com menos caudas (níveis 1 e 2), que hoje não
-- entram no jogo.
-- A segunda folha ("... - golpes.png") tem os golpes do combo (garra, giro, salto, espírito da raposa
-- e investida da raposa), que vão no quadro grande dos golpes (181x107, pés em 70,90).
-- Saída: art_source/personagem principal/noct_raposa.aseprite e noct_raposa_golpes.aseprite (tags
-- c3_<linha>) e as tiras do jogo em assets/hero/crimson (parado, andar, correr, dash, abaixar, o giro
-- das caudas e os golpes c3_fox_*).
-- Rodar DEPOIS de tools/noct_forms.lua, que grava as outras animações das formas.
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/noct_raposa.lua
--   --script-param scale=0.272   tamanho (o Noct base tem 43 px de altura; o da folha, ~158)

local root = app.fs.currentPath
local pc = app.pixelColor
local SRC = {
  Image{ fromFile = app.fs.joinPath(root, "Sprite de Guerreiro Raposa Demoníaco.png") },
  Image{ fromFile = app.fs.joinPath(root, "Sprite de Guerreiro Raposa Demoníaco - golpes.png") },
}
local src = SRC[1]
local S = tonumber(app.params.scale or 0.272)
local CW, CH, AX, AY = 117, 77, 50, 64
local BODY_SHARE = tonumber(app.params.body_share or 0.3)

-- Quadros da folha (x0, x1) por linha (y0, y1), achados pelos vãos transparentes.
local ROWS = {
  { "idle", 11, 202, { { 14, 218 }, { 237, 453 }, { 475, 679 }, { 699, 918 }, { 934, 1157 }, { 1182, 1404 } } },
  { "walk", 213, 404, { { 11, 249 }, { 268, 488 }, { 501, 704 }, { 724, 933 }, { 953, 1174 }, { 1195, 1415 } } },
  { "run", 412, 607, { { 10, 224 }, { 240, 452 }, { 470, 690 }, { 700, 920 }, { 932, 1170 }, { 1182, 1418 } } },
  { "attack", 609, 802, { { 12, 234 }, { 252, 460 }, { 472, 702 }, { 708, 936 }, { 940, 1204 }, { 1206, 1436 } } },
  { "dash", 814, 941, { { 18, 251 }, { 275, 511 }, { 517, 764 }, { 767, 1031 }, { 1032, 1429 } } },
  { "crouch", 947, 1078, { { 118, 375 }, { 422, 677 }, { 721, 956 }, { 995, 1258 } } },
  -- Folha de golpes (quadro grande).
  { "fox_claw", 8, 192, { { 16, 222 }, { 224, 464 }, { 466, 734 }, { 736, 951 }, { 953, 1211 }, { 1213, 1433 } }, sheet = 2 },
  { "fox_spin", 194, 391, { { 14, 225 }, { 227, 487 }, { 489, 712 }, { 714, 950 }, { 952, 1194 }, { 1196, 1439 } }, sheet = 2 },
  { "fox_leap", 393, 600, { { 10, 222 }, { 224, 452 }, { 454, 699 }, { 701, 934 }, { 936, 1193 }, { 1195, 1439 } }, sheet = 2 },
  { "fox_spirit", 602, 801, { { 15, 231 }, { 233, 465 }, { 467, 706 }, { 708, 957 }, { 959, 1224 }, { 1226, 1439 } }, sheet = 2 },
  { "fox_rush", 803, 1024, { { 14, 247 }, { 249, 469 }, { 471, 769 }, { 771, 1191 }, { 1193, 1433 } }, sheet = 2 },
}
-- Quadro grande dos golpes: os pés no mesmo ponto do quadro normal colado em (20, 26).
local BW, BH, BAX, BAY = 181, 107, 70, 90

-- Energia = vermelho dominante (inclusive o vinho escuro de dentro das caudas).
local function is_energy(r, g, b) return r > 40 and r > g * 2.4 and r > b * 1.05 end

-- Reduz um retângulo da folha: média por área (cor ponderada pelo alfa).
local function shrink(x0, y0, x1, y1)
  local w, h = math.floor((x1 - x0 + 1) * S + 0.5), math.floor((y1 - y0 + 1) * S + 0.5)
  local out = Image(w, h, ColorMode.RGB)
  local body = {}                -- 1 = o pixel novo é corpo; 0 = energia
  local eyes = {}                -- quantos pixels de olho aceso (vermelho puro e forte) caem nele
  for ty = 0, h - 1 do
    local sy0, sy1 = y0 + math.floor(ty / S), math.min(y1, y0 + math.floor((ty + 1) / S) - 1)
    for tx = 0, w - 1 do
      local sx0, sx1 = x0 + math.floor(tx / S), math.min(x1, x0 + math.floor((tx + 1) / S) - 1)
      -- Soma separada de corpo e de energia: o pixel novo fica com a cor de um só dos dois (o que
      -- ocupa mais; o corpo ganha com menos), para a pele, o cabelo e a roupa não virarem lama.
      local a, n, ne = 0, 0, 0
      local sum = { [true] = { 0, 0, 0, 0 }, [false] = { 0, 0, 0, 0 } }
      for sy = sy0, sy1 do
        for sx = sx0, sx1 do
          local c = src:getPixel(sx, sy)
          local ca = pc.rgbaA(c)
          local cr, cg, cb = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
          a, n = a + ca, n + 1
          if ca > 200 and cr > 215 and cg < 100 and cb < 120 then ne = ne + 1 end
          if ca > 0 then
            local t = sum[ca > 150 and not is_energy(cr, cg, cb)]
            t[1], t[2], t[3], t[4] = t[1] + cr * ca, t[2] + cg * ca, t[3] + cb * ca, t[4] + ca
          end
        end
      end
      if n > 0 and a / n > 120 then
        local fb = sum[true][4] / a
        local t = fb > BODY_SHARE and sum[true] or sum[false]
        if t[4] == 0 then t = sum[true][4] > 0 and sum[true] or sum[false] end
        out:drawPixel(tx, ty, pc.rgba(math.floor(t[1] / t[4] + 0.5), math.floor(t[2] / t[4] + 0.5), math.floor(t[3] / t[4] + 0.5), 255))
        body[ty * w + tx] = (t == sum[true]) and 1 or 0
        if ne >= 2 then eyes[ty * w + tx] = ne end
      end
    end
  end
  -- Corpo "de verdade" (core): o maior pedaço ligado de pixels de corpo. Pedaços soltos (o miolo
  -- vinho escuro das caudas, separado do corpo pela borda acesa) ficam de fora. As cores continuam
  -- vindo da separação simples (body), que é a que deixa as caudas da folha com textura.
  local seen, best = {}, nil
  for k0, v in pairs(body) do
    if v == 1 and not seen[k0] then
      local comp, stack = {}, { k0 }
      seen[k0] = true
      while #stack > 0 do
        local k = table.remove(stack)
        comp[#comp + 1] = k
        local x, y = k % w, k // w
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local nx, ny = x + d[1], y + d[2]
          local nk = ny * w + nx
          if nx >= 0 and ny >= 0 and nx < w and ny < h and body[nk] == 1 and not seen[nk] then
            seen[nk] = true
            stack[#stack + 1] = nk
          end
        end
      end
      if not best or #comp > #best then best = comp end
    end
  end
  local core = {}
  for k, v in pairs(body) do core[k] = 0 end
  for _, k in ipairs(best or {}) do core[k] = 1 end
  return out, body, eyes, core
end

-- Paleta: corte pela mediana, separado para corpo e energia.
local function median_cut(colors, k)
  local boxes = { colors }
  while #boxes < k do
    local bi, best, axis = nil, -1, 1
    for i, box in ipairs(boxes) do
      if #box > 1 then
        for ax = 1, 3 do
          local lo, hi = 255, 0
          for _, c in ipairs(box) do lo = math.min(lo, c[ax]); hi = math.max(hi, c[ax]) end
          if hi - lo > best then best, bi, axis = hi - lo, i, ax end
        end
      end
    end
    if not bi then break end
    local box = table.remove(boxes, bi)
    table.sort(box, function(p, q) return p[axis] < q[axis] end)
    local mid = #box // 2
    local a, b = {}, {}
    for i, c in ipairs(box) do if i <= mid then a[#a + 1] = c else b[#b + 1] = c end end
    boxes[#boxes + 1] = a
    boxes[#boxes + 1] = b
  end
  local pal = {}
  for _, box in ipairs(boxes) do
    local r, g, b = 0, 0, 0
    for _, c in ipairs(box) do r, g, b = r + c[1], g + c[2], b + c[3] end
    pal[#pal + 1] = { r // #box, g // #box, b // #box }
  end
  return pal
end
local function nearest(pal, r, g, b)
  local best, bc = 1e9, nil
  for _, p in ipairs(pal) do
    -- Distância com peso perceptual simples (verde pesa mais).
    local d = 2 * (p[1] - r) ^ 2 + 4 * (p[2] - g) ^ 2 + 3 * (p[3] - b) ^ 2
    if d < best then best, bc = d, p end
  end
  return pc.rgba(bc[1], bc[2], bc[3], 255)
end

-- 1) Reduz todos os quadros.
local frames = {}
local body_cols, energy_cols = {}, {}
for ri, row in ipairs(ROWS) do
  src = SRC[row.sheet or 1]
  for i, fx in ipairs(row[4]) do
    local img, body, eyes, core = shrink(fx[1], row[2], fx[2], row[3])
    -- Pés = linha mais baixa com corpo; centro = média x do corpo.
    local feet, sx, n = 0, 0, 0
    for y = 0, img.height - 1 do
      for x = 0, img.width - 1 do
        local bv = body[y * img.width + x]
        if bv and bv > 0.5 then feet = math.max(feet, y); sx = sx + x; n = n + 1 end
        if bv then
          local c = img:getPixel(x, y)
          local t = { pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c) }
          if bv > 0.5 then body_cols[#body_cols + 1] = t else energy_cols[#energy_cols + 1] = t end
        end
      end
    end
    -- Pés de verdade: o pixel mais baixo perto do centro do corpo (as botas são vermelho escuro e
    -- contam como energia, então não dá para usar só o corpo).
    local cx0 = n > 0 and sx // n or img.width // 2
    for y = 0, img.height - 1 do
      for x = math.max(0, cx0 - 9), math.min(img.width - 1, cx0 + 9) do
        if body[y * img.width + x] then feet = math.max(feet, y) end
      end
    end
    frames[#frames + 1] = { tag = row[1], row = ri, big = row.sheet == 2, nbody = n, i = i, img = img, body = body, core = core, eyes = eyes, feet = feet, cx = n > 0 and sx // n or img.width // 2 }
  end
end
-- Quadros em que o corpo quase some (o Noct vira o espírito da raposa): ficam alinhados pela posição
-- média do corpo nos outros quadros da mesma linha, e pelos pés mais baixos da linha.
do
  local stats = {}
  for _, f in ipairs(frames) do
    local st = stats[f.row] or { n = {}, cx = 0, k = 0, feet = 0 }
    stats[f.row] = st
    st.n[#st.n + 1] = f.nbody
  end
  for _, st in pairs(stats) do table.sort(st.n); st.med = st.n[(#st.n + 1) // 2] end
  for _, f in ipairs(frames) do
    local st = stats[f.row]
    f.ghost = f.nbody < st.med * 0.35
    if not f.ghost then st.cx, st.k, st.feet = st.cx + f.cx, st.k + 1, math.max(st.feet, f.feet) end
  end
  for _, f in ipairs(frames) do
    local st = stats[f.row]
    if f.ghost and st.k > 0 then f.cx, f.feet = st.cx // st.k, st.feet end
    -- Nos golpes o chão da linha vale para todos os quadros (o salto sobe de verdade).
    if f.big and st.feet > 0 then f.feet = st.feet end
  end
end
local body_pal = median_cut(body_cols, tonumber(app.params.body_colors or 20))
local energy_pal = median_cut(energy_cols, tonumber(app.params.energy_colors or 10))

-- Raiz das caudas: a lombar (borda de trás do corpo, na metade da altura).
local function tail_root(body, w, h)
  local top, bottom = nil, 0
  for y = 0, h - 1 do for x = 0, w - 1 do if body[y * w + x] == 1 then top = top or y; bottom = y end end end
  if not top then return nil end
  local yr = top + math.floor((bottom - top) * 0.5)
  for x = 0, w - 1 do if body[yr * w + x] == 1 then return x + 2, yr, top, bottom end end
end

-- Nos níveis 1 e 2 o leque da folha sai: fica o corpo e só a energia colada nele (2 px, o brilho
-- do manto).
local function strip_fan(q, body, w, h)
  local near = {}
  for y = 0, h - 1 do for x = 0, w - 1 do
    if body[y * w + x] == 1 then
      for dy = -2, 2 do for dx = -2, 2 do near[(y + dy) * w + x + dx] = true end end
    end
  end end
  for y = 0, h - 1 do for x = 0, w - 1 do
    local k = y * w + x
    if body[k] ~= 1 and not near[k] then q:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end
  end end
end

-- CAUDA NO ESTILO DA FOLHA: larga como chama, borda carmesim acesa, miolo vinho escuro com veios
-- claros correndo ao longo dela, ponta fina curvada e contorno quase preto. a0 -> a1 = ângulo do
-- caminho (0 = para trás, pi/2 = para cima); k = quadro (balanço).
local function sheet_tail(img, x0, y0, a0, a1, len, width, k, pal)
  local W2, H2 = img.width, img.height
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
      if qx >= 0 and qy >= 0 and qx < W2 and qy < H2 then
        local key = qy * W2 + qx
        local rec = mask[key]
        if not rec then rec = { x = qx, y = qy, lat = 9 }; mask[key] = rec; list[#list + 1] = rec end
        if math.abs(l / p.r) < math.abs(rec.lat) then rec.lat, rec.u = l / p.r, p.u end
      end
    end
  end
  for _, r in ipairs(list) do
    local edge = false
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      if not mask[(r.y + d[2]) * W2 + r.x + d[1]] then edge = true end
    end
    local col
    if edge or math.abs(r.lat) > 0.78 or r.u > 0.9 then col = pal.rim
    elseif math.abs(r.lat) > 0.55 then col = pal.mid
    else
      -- Veios claros ao longo da cauda (como as listras de energia da folha).
      local vein = math.floor((r.lat + 1) * 3 + r.u * 4 + k * 0.5) % 4 == 0 and r.u > 0.15
      col = vein and pal.vein or (r.u < 0.2 and pal.mid or pal.dark)
    end
    img:drawPixel(r.x, r.y, col)
  end
end

-- 2) Paleta, contorno escuro e montagem no quadro do Noct.
local function lum(c) return c[1] * 0.3 + c[2] * 0.59 + c[3] * 0.11 end
table.sort(energy_pal, function(p, q) return lum(p) < lum(q) end)
local function rgba(c) return pc.rgba(c[1], c[2], c[3], 255) end
local TAIL_PAL = {
  dark = rgba(energy_pal[1]), mid = rgba(energy_pal[math.max(2, #energy_pal // 2 - 1)]),
  vein = rgba(energy_pal[#energy_pal // 2 + 1]), rim = rgba(energy_pal[#energy_pal - 1]),
}
-- Caudas dos níveis 1 e 2: quantas e para onde apontam (ângulo final; 0 = para trás, pi/2 = cima).
local LEVEL_TAILS = { { 2.0 }, { 1.25, 1.85, 2.45 } }

local OUTLINE = pc.rgba(18, 6, 16, 255)
local EYE, EYE_HOT = pc.rgba(255, 48, 64, 255), pc.rgba(255, 190, 200, 255)
local out = Sprite(CW, CH, ColorMode.RGB)
local out_big = Sprite(BW, BH, ColorMode.RGB)
local cells = {}   -- c<n>_<linha> -> quadros
local ranges, first = {}, true
local ranges_big, first_big = {}, true
for _, lv in ipairs({ 3 }) do
for _, f in ipairs(frames) do
  local img, w = f.img, f.img.width
  local q = Image(img.width, img.height, ColorMode.RGB)
  for y = 0, img.height - 1 do
    for x = 0, w - 1 do
      local bv = f.body[y * w + x]
      if bv then
        local c = img:getPixel(x, y)
        q:drawPixel(x, y, nearest(bv > 0.5 and body_pal or energy_pal, pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)))
      end
    end
  end
  -- Olhos acesos: no alto do corpo (faixa da cabeça), onde a folha tem o vermelho puro dos olhos.
  local top = nil
  for y = 0, q.height - 1 do
    for x = 0, w - 1 do if f.body[y * w + x] == 1 then top = top or y end end
  end
  for key, ne in pairs(f.eyes) do
    local x, y = key % w, key // w
    local near = f.body[key] == 1 or f.body[key + 1] == 1 or f.body[key - 1] == 1 or f.body[key + w] == 1
    if top and y >= top + 2 and y <= top + 14 and near then q:drawPixel(x, y, ne >= 4 and EYE_HOT or EYE) end
  end
  -- Some com pedacinhos soltos (fagulhas de menos de 5 px que viram sujeira na escala do jogo).
  local seen = {}
  for y = 0, q.height - 1 do
    for x = 0, w - 1 do
      local k0 = y * w + x
      if not seen[k0] and pc.rgbaA(q:getPixel(x, y)) > 0 then
        local stack, comp = { k0 }, {}
        seen[k0] = true
        while #stack > 0 do
          local k = table.remove(stack)
          comp[#comp + 1] = k
          local cx, cy = k % w, k // w
          for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local nx, ny = cx + d[1], cy + d[2]
            local nk = ny * w + nx
            if nx >= 0 and ny >= 0 and nx < w and ny < q.height and not seen[nk] and pc.rgbaA(q:getPixel(nx, ny)) > 0 then
              seen[nk] = true
              stack[#stack + 1] = nk
            end
          end
        end
        if #comp < 5 then for _, k in ipairs(comp) do q:drawPixel(k % w, k // w, pc.rgba(0, 0, 0, 0)) end end
      end
    end
  end
  local shift = 0
  if LEVEL_TAILS[lv] then
    strip_fan(q, f.core, w, q.height)
    local xr, yr, top, bottom = tail_root(f.core, w, q.height)
    if xr then
      -- As caudas ficam atrás do corpo: desenha num quadro à parte e põe o corpo por cima.
      local pad = 40
      local big = Image(w + pad, q.height + pad, ColorMode.RGB)
      local tails = LEVEL_TAILS[lv]
      for t = #tails, 1, -1 do
        local len = math.floor((bottom - top) * (lv == 1 and 1.0 or 0.92))
        sheet_tail(big, xr + pad, yr + pad, 0.45, tails[t], len, lv == 1 and 7.5 or 6.5, f.i + t, TAIL_PAL)
      end
      big:drawImage(q, Point(pad, pad))
      q = big
      w = big.width
      shift = pad
    end
  end
  -- Contorno de 1 px por fora de tudo (lê bem em qualquer fundo).
  local cw, ch, ax, ay = CW, CH, AX, AY
  if f.big then cw, ch, ax, ay = BW, BH, BAX, BAY end
  local cell = Image(cw, ch, ColorMode.RGB)
  local ox, oy = ax - f.cx - shift, ay - f.feet - shift
  for y = 0, q.height - 1 do
    for x = 0, w - 1 do
      if pc.rgbaA(q:getPixel(x, y)) > 0 then
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local nx, ny = x + d[1], y + d[2]
          if nx < 0 or ny < 0 or nx >= w or ny >= q.height or pc.rgbaA(q:getPixel(nx, ny)) == 0 then
            local cx, cy = nx + ox, ny + oy
            if cx >= 0 and cy >= 0 and cx < cw and cy < ch then cell:drawPixel(cx, cy, OUTLINE) end
          end
        end
      end
    end
  end
  cell:drawImage(q, Point(ox, oy))
  local spr, rgs = out, ranges
  if f.big then spr, rgs = out_big, ranges_big end
  local fr
  if f.big then fr = first_big and spr.frames[1] or spr:newEmptyFrame(); first_big = false
  else fr = first and spr.frames[1] or spr:newEmptyFrame(); first = false end
  fr.duration = 0.1
  spr:newCel(spr.layers[1], fr, cell, Point(0, 0))
  local r = rgs[#rgs]
  local name = "c" .. lv .. "_" .. f.tag
  cells[name] = cells[name] or {}
  table.insert(cells[name], cell)
  if r and r[1] == name then r[3] = fr.frameNumber else rgs[#rgs + 1] = { name, fr.frameNumber, fr.frameNumber } end
end
end
for _, r in ipairs(ranges) do local t = out:newTag(r[2], r[3]); t.name = r[1] end
out:saveAs(app.fs.joinPath(root, "art_source", "personagem principal", "noct_raposa.aseprite"))
for _, r in ipairs(ranges_big) do local t = out_big:newTag(r[2], r[3]); t.name = r[1] end
out_big:saveAs(app.fs.joinPath(root, "art_source", "personagem principal", "noct_raposa_golpes.aseprite"))

-- Garra mais comprida: na folha a garra só vai até o braço esticado; no jogo ela solta três
-- rasgos de energia à frente da mão (quadros 4 e 5 do golpe), no estilo da folha (núcleo claro,
-- brilho carmesim e borda escura).
local CLAW_LEN = { [4] = 40, [5] = 32 }
local SLASH = { core = pc.rgba(255, 214, 226, 255), hot = pc.rgba(255, 77, 122, 255),
  mid = pc.rgba(208, 24, 72, 255), deep = pc.rgba(110, 13, 42, 255) }
local function claw_reach(cell, i)
  local L = CLAW_LEN[i]
  if not L then return end
  local w, h = cell.width, cell.height
  -- Mão = pixel mais à frente na altura dos braços (as caudas ficam atrás).
  local hx, hy = nil, nil
  for y = BAY - 40, BAY - 14 do
    for x = w - 1, 0, -1 do
      if pc.rgbaA(cell:getPixel(x, y)) > 0 then
        if not hx or x > hx then hx, hy = x, y end
        break
      end
    end
  end
  if not hx then return end
  local function put(x, y, c) if x >= 0 and y >= 0 and x < w and y < h then cell:drawPixel(x, y, c) end end
  local function empty(x, y) return x >= 0 and y >= 0 and x < w and y < h and pc.rgbaA(cell:getPixel(x, y)) == 0 end
  for k, o in ipairs({ -5, 0, 5 }) do
    local len = L + ({ -4, 2, -6 })[k]
    local pts = {}
    for t = 0, len do
      local u = t / len
      -- Arco de garra: sobe um pouco e cai no fim; grosso no meio, fino nas pontas.
      local y = hy + o - math.sin(u * math.pi) * 4 + u * u * 5
      pts[#pts + 1] = { math.floor(hx + 1 + t + 0.5), math.floor(y + 0.5), u, math.sin(u * math.pi) * 1.6 }
    end
    for _, q in ipairs(pts) do
      local r = math.floor(q[4] + 1.5)
      for dy = -r, r do if empty(q[1], q[2] + dy) then put(q[1], q[2] + dy, math.abs(dy) == r and SLASH.deep or SLASH.mid) end end
    end
    for _, q in ipairs(pts) do
      local r = math.floor(q[4] + 0.5)
      for dy = -r, r do put(q[1], q[2] + dy, (dy == 0 and q[3] > 0.1 and q[3] < 0.9) and SLASH.core or SLASH.hot) end
    end
  end
end
for i, cell in ipairs(cells["c3_fox_claw"] or {}) do claw_reach(cell, i) end

-- 3) Tiras do jogo. Cada animação do jogo pega uma linha da folha (ou parte dela).
local crimson_dir = app.fs.joinPath(root, "assets", "hero", "crimson")
local function save_strip(key, list, cw, ch, dx, dy)
  local strip = Image(cw * #list, ch, ColorMode.RGB)
  for i, c in ipairs(list) do strip:drawImage(c, Point((i - 1) * cw + (dx or 0), dy or 0)) end
  strip:saveAs(app.fs.joinPath(crimson_dir, key .. ".png"))
end
local function pick(list, ids) local t = {} for _, i in ipairs(ids) do t[#t + 1] = list[i] end return t end
for _, lv in ipairs({ 3 }) do
  local c = function(tag) return cells["c" .. lv .. "_" .. tag] end
  save_strip("c" .. lv .. "_idle", c("idle"), CW, CH)
  save_strip("c" .. lv .. "_walk", c("walk"), CW, CH)
  save_strip("c" .. lv .. "_run", c("run"), CW, CH)
  save_strip("c" .. lv .. "_dash", c("dash"), CW, CH)
  save_strip("c" .. lv .. "_air_dash", c("dash"), CW, CH)
  save_strip("c" .. lv .. "_crouch", pick(c("crouch"), { 1, 2 }), CW, CH)
  save_strip("c" .. lv .. "_crouch_loop", c("crouch"), CW, CH)
end
-- Finalizador do nível 3 (o giro das caudas e a garra da folha), no quadro grande dos golpes
-- (181x107, pés em 70,90 = quadro normal colado em 20,26).
save_strip("c3_tailburst", cells["c3_attack"], BW, BH, BAX - AX, BAY - AY)
-- Golpes do combo novo (folha de golpes).
for _, k in ipairs({ "fox_claw", "fox_spin", "fox_leap", "fox_spirit", "fox_rush" }) do
  save_strip("c3_" .. k, cells["c3_" .. k], BW, BH)
end
print("raposa: " .. #frames .. " quadros da folha, paleta " .. #body_pal .. " corpo + " .. #energy_pal .. " energia")
for k, v in pairs(TAIL_PAL) do print(k, string.format("#%06x", v & 0xffffff)) end
