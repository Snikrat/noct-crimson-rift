-- Noct olhando para cima: cria look_up e look_up_loop (base e c1/c2/c3) no noct.aseprite.
-- Parte dos quadros do Idle de cada forma, sem redesenhar: só a cabeça se move.
--   meio:  o queixo vai 1 px para a frente (começa a levantar o rosto);
--   cima:  a cabeça sobe 1 px e inclina para trás (topo 1 px para trás, queixo 2 px para a
--          frente), com os mesmos pixels do Idle.
-- look_up = [meio, cima] (toca uma vez); look_up_loop = cima em dois quadros do Idle (respira).
--
-- Uso (na pasta do projeto), e depois exportar:
--   Aseprite.exe -b --script tools/noct_look_up.lua
--   Aseprite.exe -b --script-param modo=exportar --script tools/noct_aseprite.lua

local ase_path = app.fs.joinPath(app.fs.currentPath, "art_source", "personagem principal", "noct.aseprite")
local HEAD = 11        -- altura da cabeça em px (corpo de 44 px)
local FORMS = {{"", "idle"}, {"c1_", "c1_idle"}, {"c2_", "c2_idle"}, {"c3_", "c3_idle"}}

local spr = app.open(ase_path)
local layer = spr.layers[1]

local function find_tag(name)
  for _, t in ipairs(spr.tags) do
    if t.name == name then return t end
  end
end

-- Refazer do zero: apaga as tags/quadros de olhar para cima já existentes (de trás para frente).
local old = {}
for _, t in ipairs(spr.tags) do
  if t.name:match("look_up") then table.insert(old, {t.name, t.fromFrame.frameNumber, t.toFrame.frameNumber}) end
end
table.sort(old, function(a, b) return a[2] > b[2] end)
for _, o in ipairs(old) do
  spr:deleteTag(find_tag(o[1]))
  for f = o[3], o[2], -1 do spr:deleteFrame(f) end
end
-- Quadros novos vão no fim; guardo o fim de cada tag para nenhuma esticar.
local tag_end = {}
for _, t in ipairs(spr.tags) do tag_end[t.name] = t.toFrame.frameNumber end

-- Pixel do corpo (não é energia carmesim): serve para achar o topo da cabeça sob a chama.
local function is_body(c)
  local r, g, b, a = app.pixelColor.rgbaR(c), app.pixelColor.rgbaG(c), app.pixelColor.rgbaB(c), app.pixelColor.rgbaA(c)
  if a == 0 then return false end
  return not (r > 140 and g < 90 and b > 46 and r > b * 1.2) and not (r >= 110 and g < 60 and r > g * 2.5)
end

local function frame_image(n)
  local cel = layer:cel(n)
  local img = Image(spr.width, spr.height, ColorMode.RGB)
  if cel then img:drawImage(cel.image, cel.position) end
  return img
end

-- Topo e coluna central da cabeça (pixels do corpo na faixa de cima).
local function head_box(img)
  local top = nil
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      if is_body(img:getPixel(x, y)) then top = y; break end
    end
    if top then break end
  end
  local xs = {}
  for y = top, top + HEAD - 1 do
    for x = 0, img.width - 1 do
      if is_body(img:getPixel(x, y)) then table.insert(xs, x) end
    end
  end
  table.sort(xs)
  return top, xs[1], xs[#xs]
end

-- Inclina a cabeça para trás (olhar para o alto): cada linha da cabeça anda na horizontal
-- conforme a altura (topo para trás, queixo para a frente; o Noct olha para a direita) e a
-- cabeça sobe "up" px. SHEAR[k] = deslocamento da linha k da cabeça, a partir do topo.
local SHEAR = {
  half = {0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1},
  full = {-1, -1, -1, 0, 0, 0, 1, 1, 1, 2, 2},
}

local function tilt(src, up, mode)
  local top, x0, x1 = head_box(src)
  local shear = SHEAR[mode]
  local out = src:clone()
  local y_from = math.max(0, top - 8)          -- inclui a chama do cabelo, acima da cabeça
  local y_to = top + HEAD - 2                  -- a última linha (queixo/pescoço) fica no lugar
  -- Tira a cabeça do lugar e desenha de novo deslocada. A linha y_to fica (queixo/pescoço):
  -- assim a cabeça que sobe não se solta do corpo.
  for y = y_from, y_to - up do
    for x = x0 - 4, x1 + 4 do out:drawPixel(x, y, Color{ a = 0 }) end
  end
  for y = y_from, y_to do
    local k = math.max(1, y - top + 1)
    local dx = shear[math.min(k, #shear)]
    for x = x0 - 4, x1 + 4 do
      local c = src:getPixel(x, y)
      if app.pixelColor.rgbaA(c) > 0 then out:drawPixel(x + dx, y - up, c) end
    end
  end
  return out
end

local ranges = {}
for _, form in ipairs(FORMS) do
  local idle = find_tag(form[2])
  local f0 = idle.fromFrame.frameNumber
  local f2 = math.min(f0 + 2, tag_end[form[2]])
  local a, b = frame_image(f0), frame_image(f2)
  local seq = {
    {form[1] .. "look_up", {tilt(a, 0, "half"), tilt(a, 1, "full")}, 1 / 14},
    {form[1] .. "look_up_loop", {tilt(a, 1, "full"), tilt(b, 1, "full")}, 1 / 3},
  }
  for _, s in ipairs(seq) do
    local first = #spr.frames + 1
    for _, img in ipairs(s[2]) do
      local frame = spr:newEmptyFrame(#spr.frames + 1)
      frame.duration = s[3]
      spr:newCel(layer, frame, img, Point(0, 0))
    end
    table.insert(ranges, {s[1], first, #spr.frames})
  end
end
for name, e in pairs(tag_end) do find_tag(name).toFrame = spr.frames[e] end
for _, r in ipairs(ranges) do
  local t = spr:newTag(r[2], r[3])
  t.name = r[1]
  t.color = r[1]:match("^c%d_") and Color{ r = 200, g = 40, b = 70 } or Color{ r = 90, g = 120, b = 200 }
  print(r[1] .. ": quadros " .. r[2] .. "-" .. r[3])
end
spr:saveAs(ase_path)
