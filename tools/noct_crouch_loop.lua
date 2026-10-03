-- Formas carmesim abaixadas: cria c1/c2/c3_crouch_loop no noct.aseprite.
-- São 8 quadros com o corpo do último quadro de cN_crouch (a pose abaixada) e só a energia
-- carmesim se mexendo: as cores fortes da energia giram pela própria rampa (brilho que pulsa e
-- sobe pela chama). O corpo e o desenho não mudam. O jogo toca cN_crouch e depois repete o loop.
--
-- Uso (na pasta do projeto), e depois exportar:
--   Aseprite.exe -b --script tools/noct_crouch_loop.lua
--   Aseprite.exe -b --script-param modo=exportar --script tools/noct_aseprite.lua

local ase_path = app.fs.joinPath(app.fs.currentPath, "art_source", "personagem principal", "noct.aseprite")
local LOOP_FRAMES = 8
local FPS = 10
local WAVE = {0, 2, 3, 2, 0, -2, -3, -2}   -- passos na rampa de cores, um por quadro

local spr = app.open(ase_path)
local layer = spr.layers[1]

local function find_tag(name)
  for _, t in ipairs(spr.tags) do
    if t.name == name then return t end
  end
end

-- Refazer do zero: apaga loops antigos (de trás para frente para não mexer nos números).
for lv = 3, 1, -1 do
  local old = find_tag("c" .. lv .. "_crouch_loop")
  if old then
    local from, to = old.fromFrame.frameNumber, old.toFrame.frameNumber
    spr:deleteTag(old)
    for f = to, from, -1 do spr:deleteFrame(f) end
  end
end
-- Guarda o fim de cada tag: quadros novos no fim do arquivo esticariam a última tag.
local tag_end = {}
for _, t in ipairs(spr.tags) do tag_end[t.name] = t.toFrame.frameNumber end
local last_frame = 0
for _, t in ipairs(spr.tags) do last_frame = math.max(last_frame, t.toFrame.frameNumber) end
while #spr.frames > last_frame do spr:deleteFrame(#spr.frames) end

-- Energia carmesim: vermelhos e rosas (do escuro ao vivo). O logo da regata fica de fora porque
-- só conta a energia ligada ao lado de fora do desenho (o logo fica cercado pela regata preta),
-- e as botas, que têm o mesmo vermelho escuro, porque a faixa dos pés não entra (FEET).
local FEET = 7
local function is_energy(c)
  local r, g, b, a = app.pixelColor.rgbaR(c), app.pixelColor.rgbaG(c), app.pixelColor.rgbaB(c), app.pixelColor.rgbaA(c)
  return a > 0 and r >= 110 and g < 110 and r > b * 1.1 and r > g * 2.2
end

local function luma(c)
  return 0.3 * app.pixelColor.rgbaR(c) + 0.59 * app.pixelColor.rgbaG(c) + 0.11 * app.pixelColor.rgbaB(c)
end

local function outer_energy(img, feet_y)
  local w, h = img.width, math.min(img.height, feet_y - FEET)
  local mark, stack = {}, {}
  local function key(x, y) return y * w + x end
  -- Sementes: energia vizinha de pixel transparente ou da borda.
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local c = img:getPixel(x, y)
      if is_energy(c) then
        for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
          local nx, ny = x + d[1], y + d[2]
          if nx < 0 or ny < 0 or nx >= w or ny >= h or app.pixelColor.rgbaA(img:getPixel(nx, ny)) == 0 then
            if not mark[key(x, y)] then
              mark[key(x, y)] = true
              table.insert(stack, {x, y})
            end
            break
          end
        end
      end
    end
  end
  while #stack > 0 do
    local p = table.remove(stack)
    for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
      local nx, ny = p[1] + d[1], p[2] + d[2]
      if nx >= 0 and ny >= 0 and nx < w and ny < h and not mark[key(nx, ny)] and is_energy(img:getPixel(nx, ny)) then
        mark[key(nx, ny)] = true
        table.insert(stack, {nx, ny})
      end
    end
  end
  return mark
end

local ranges = {}
for lv = 1, 3 do
  local tag = find_tag("c" .. lv .. "_crouch")
  local base = layer:cel(tag_end[tag.name])
  local src = Image(spr.width, spr.height, ColorMode.RGB)
  src:drawImage(base.image, base.position)
  -- Linha dos pés: a última linha com pixels.
  local feet_y = 0
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      if app.pixelColor.rgbaA(src:getPixel(x, y)) > 0 then feet_y = y; break end
    end
  end
  local mark = outer_energy(src, feet_y)
  -- Rampa: as cores de energia do quadro, da mais escura para a mais clara.
  local seen, ramp = {}, {}
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      if mark[y * src.width + x] then
        local c = src:getPixel(x, y)
        if not seen[c] then seen[c] = true; table.insert(ramp, c) end
      end
    end
  end
  table.sort(ramp, function(a, b) return luma(a) < luma(b) end)
  local index = {}
  for i, c in ipairs(ramp) do index[c] = i end
  local first = nil
  for k = 0, LOOP_FRAMES - 1 do
    local frame = spr:newEmptyFrame(#spr.frames + 1)
    frame.duration = 1 / FPS
    local img = src:clone()
    if #ramp > 1 then
      for y = 0, img.height - 1 do
        for x = 0, img.width - 1 do
          if mark[y * img.width + x] then
            -- Desloca a cor pela rampa numa onda que sobe pela chama (faixas de 3 px).
            local i = index[img:getPixel(x, y)]
            local wave = WAVE[(k + (img.height - y) // 3) % #WAVE + 1]
            img:drawPixel(x, y, ramp[math.max(1, math.min(#ramp, i + wave))])
          end
        end
      end
    end
    spr:newCel(layer, frame, img, Point(0, 0))
    first = first or frame.frameNumber
  end
  table.insert(ranges, {"c" .. lv .. "_crouch_loop", first, first + LOOP_FRAMES - 1, #ramp})
end
for name, e in pairs(tag_end) do find_tag(name).toFrame = spr.frames[e] end
for _, r in ipairs(ranges) do
  local t = spr:newTag(r[2], r[3])
  t.name = r[1]
  t.color = Color{ r = 200, g = 40, b = 70 }
  print(r[1] .. ": quadros " .. r[2] .. "-" .. r[3] .. ", " .. r[4] .. " cores de energia")
end
spr:saveAs(ase_path)
