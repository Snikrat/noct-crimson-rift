-- TESTE: o Noct demônio-raposa a partir da folha "Sprite de Guerreiro Raposa Demoníaco.png" (raiz do
-- projeto), convertido em pixel art na escala do jogo, o mais fiel possível à folha.
-- Cada quadro da folha é recortado, reduzido (média por área, sem borrar o alfa), alinhado pelos pés
-- e pelo centro do corpo no quadro do Noct (117x77, pés em 50,64) e levado para uma paleta curta
-- tirada da própria folha (corpo e energia separados, para a pele, o cabelo e a roupa não sumirem no
-- vermelho). Saída: art_source/personagem principal/noct_raposa_teste.aseprite (uma tag por linha).
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/noct_raposa_teste.lua
--   --script-param scale=0.272   tamanho (o Noct base tem 43 px de altura; o da folha, ~158)

local root = app.fs.currentPath
local pc = app.pixelColor
local src = Image{ fromFile = app.fs.joinPath(root, "Sprite de Guerreiro Raposa Demoníaco.png") }
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
}

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
  return out, body, eyes
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
for _, row in ipairs(ROWS) do
  for i, fx in ipairs(row[4]) do
    local img, body, eyes = shrink(fx[1], row[2], fx[2], row[3])
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
    frames[#frames + 1] = { tag = row[1], img = img, body = body, eyes = eyes, feet = feet, cx = n > 0 and sx // n or img.width // 2 }
  end
end
local body_pal = median_cut(body_cols, tonumber(app.params.body_colors or 20))
local energy_pal = median_cut(energy_cols, tonumber(app.params.energy_colors or 10))

-- 2) Paleta, contorno escuro e montagem no quadro do Noct.
local OUTLINE = pc.rgba(18, 6, 16, 255)
local EYE, EYE_HOT = pc.rgba(255, 48, 64, 255), pc.rgba(255, 190, 200, 255)
local out = Sprite(CW, CH, ColorMode.RGB)
local ranges, first = {}, true
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
  -- Contorno de 1 px por fora de tudo (lê bem em qualquer fundo).
  local cell = Image(CW, CH, ColorMode.RGB)
  local ox, oy = AX - f.cx, AY - f.feet
  for y = 0, q.height - 1 do
    for x = 0, w - 1 do
      if pc.rgbaA(q:getPixel(x, y)) > 0 then
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local nx, ny = x + d[1], y + d[2]
          if nx < 0 or ny < 0 or nx >= w or ny >= q.height or pc.rgbaA(q:getPixel(nx, ny)) == 0 then
            local cx, cy = nx + ox, ny + oy
            if cx >= 0 and cy >= 0 and cx < CW and cy < CH then cell:drawPixel(cx, cy, OUTLINE) end
          end
        end
      end
    end
  end
  cell:drawImage(q, Point(ox, oy))
  local fr = first and out.frames[1] or out:newEmptyFrame()
  first = false
  fr.duration = 0.1
  out:newCel(out.layers[1], fr, cell, Point(0, 0))
  local r = ranges[#ranges]
  if r and r[1] == f.tag then r[3] = fr.frameNumber else ranges[#ranges + 1] = { f.tag, fr.frameNumber, fr.frameNumber } end
end
for _, r in ipairs(ranges) do local t = out:newTag(r[2], r[3]); t.name = r[1] end
out:saveAs(app.fs.joinPath(root, "art_source", "personagem principal", "noct_raposa_teste.aseprite"))
print("teste raposa: " .. #frames .. " quadros, paleta " .. #body_pal .. " corpo + " .. #energy_pal .. " energia")
