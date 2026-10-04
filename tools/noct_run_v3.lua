-- Corrida redesenhada do Noct (protótipo): tronco, cabeça e braços dos quadros da corrida v2;
-- pernas desenhadas à mão num ciclo novo de 6 quadros (contato, passagem, impulso para cada
-- perna), com as cores da calça e as botas do Idle v2. Saída: noct_run_v3.aseprite.
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/noct_run_v3.lua

local root = app.fs.currentPath
local pc = app.pixelColor
local v2 = app.open(app.fs.joinPath(root, "art_source", "personagem principal", "noct_v2.aseprite"))
local W, H = v2.width, v2.height

local function tag(n) for _, t in ipairs(v2.tags) do if t.name == n then return t end end end
local function cel_image(frame)
  local img = Image(W, H, ColorMode.RGB)
  local cel = v2.layers[1]:cel(frame)
  if cel then img:drawImage(cel.image, cel.position) end
  return img
end
local function hex(h) return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255) end

local OUTLINE = hex("#120610")
local PANTS = { front = hex("#22141e"), back = hex("#190c19"), light = hex("#2e1e2a"), lighter = hex("#3d2635") }

-- Bota do Idle (a da frente), recortada como carimbo. Âncora = tornozelo (topo da bota).
local idle = cel_image(tag("idle").fromFrame.frameNumber)
local GROUND = 0
for y = H - 1, 0, -1 do
  local any = false
  for x = 0, W - 1 do if pc.rgbaA(idle:getPixel(x, y)) > 0 then any = true; break end end
  if any then GROUND = y; break end
end
local BOOT_H = 8
local boot = Image(12, BOOT_H, ColorMode.RGB)
local BOOT_X0 = 48                                -- bota da frente do Idle começa perto daqui
for y = 0, BOOT_H - 1 do
  for x = 0, 11 do
    local c = idle:getPixel(BOOT_X0 + x, GROUND - BOOT_H + 1 + y)
    if pc.rgbaA(c) > 0 then boot:drawPixel(x, y, c) end
  end
end
local BOOT_ANKLE_X = 3                             -- coluna do tornozelo dentro do carimbo
-- Pé para trás (sola virada para trás): a bota girada 90°, que é exata em pixel art.
local function stamp_boot_back(img, ax, ay)
  for y = 0, BOOT_H - 1 do
    for x = 0, 11 do
      local c = boot:getPixel(x, y)
      -- (x, y) -> (BOOT_H - 1 - y, x): o tornozelo (BOOT_ANKLE_X, 0) vai para (BOOT_H - 1, BOOT_ANKLE_X)
      if pc.rgbaA(c) > 0 then img:drawPixel(ax - (BOOT_H - 1) + (BOOT_H - 1 - y), ay - BOOT_ANKLE_X + x - 2, c) end
    end
  end
end
local function stamp_boot(img, ax, ay)
  for y = 0, BOOT_H - 1 do
    for x = 0, 11 do
      local c = boot:getPixel(x, y)
      if pc.rgbaA(c) > 0 then img:drawPixel(ax - BOOT_ANKLE_X + x, ay + y, c) end
    end
  end
end

-- Segmento grosso (coxa ou canela): preenche, contorna e acende a borda da frente.
local function limb(img, x1, y1, x2, y2, width, fill)
  local mask = {}
  local minx, maxx = math.min(x1, x2) - width, math.max(x1, x2) + width
  local miny, maxy = math.min(y1, y2) - width, math.max(y1, y2) + width
  local dx, dy = x2 - x1, y2 - y1
  local len2 = math.max(1, dx * dx + dy * dy)
  for y = miny, maxy do
    for x = minx, maxx do
      local t = math.max(0, math.min(1, ((x - x1) * dx + (y - y1) * dy) / len2))
      local px, py = x1 + t * dx, y1 + t * dy
      if (x - px) ^ 2 + (y - py) ^ 2 <= (width / 2) ^ 2 + 0.3 then mask[y * W + x] = true end
    end
  end
  for k in pairs(mask) do img:drawPixel(k % W, k // W, fill) end
  for k in pairs(mask) do
    local x, y = k % W, k // W
    if not mask[y * W + x + 1] then img:drawPixel(x, y, PANTS.light) end   -- borda da frente acesa
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local nx, ny = x + d[1], y + d[2]
      if not mask[ny * W + nx] and pc.rgbaA(img:getPixel(nx, ny)) == 0 then img:drawPixel(nx, ny, OUTLINE) end
    end
  end
end

-- Ciclo de 6 quadros. Para cada perna: joelho e tornozelo relativos ao quadril (x para a frente,
-- y para baixo). planted = pé no chão (o tornozelo fica na linha do chão, o corpo pode balançar).
-- bob = quanto o tronco desce (+) ou sobe (-) no quadro.
local CYCLE = {
  { bob = 0, A = { k = { 4, 6 }, a = { 8, 0, planted = true } }, B = { k = { -3, 5 }, a = { -9, 7 } } },
  { bob = 1, A = { k = { 1, 6 }, a = { 0, 0, planted = true } }, B = { k = { 3, 4 }, a = { -2, 6 } } },
  { bob = -1, A = { k = { -3, 6 }, a = { -7, 9 } }, B = { k = { 6, 3 }, a = { 7, 7 } } },
}
-- Segunda metade: as pernas trocam de papel.
for i = 1, 3 do
  local c = CYCLE[i]
  CYCLE[i + 3] = { bob = c.bob, A = c.B, B = c.A }
end
-- Tronco e braços de cada quadro (quadros da corrida v2, alternando o braço da frente).
local TORSO_FROM = { 1, 2, 3, 5, 6, 7 }
local HIP_Y = 46

local run = tag("run")
local out = Sprite(W, H, ColorMode.RGB)
out:setPalette(v2.palettes[1])
local first = true
for i, pose in ipairs(CYCLE) do
  local src = cel_image(run.fromFrame.frameNumber + TORSO_FROM[i] - 1)
  -- Linha do quadril da corrida (o tronco vem inclinado e mais baixo que no Idle).
  local hip_y = HIP_Y
  -- Centro do quadril: média dos pixels do tronco na linha do quadril.
  local s, n = 0, 0
  for x = 0, W - 1 do if pc.rgbaA(src:getPixel(x, hip_y - 2)) > 0 then s = s + x; n = n + 1 end end
  local hip_x = n > 0 and s // n or W // 2
  local img = Image(W, H, ColorMode.RGB)
  local hy = hip_y + pose.bob
  -- Perna de trás primeiro (mais escura), depois a da frente.
  for _, leg in ipairs({ { pose.B, PANTS.back, -1 }, { pose.A, PANTS.front, 1 } }) do
    local L, fill, side = leg[1], leg[2], leg[3]
    local hx = hip_x + side
    local kx, ky = hx + L.k[1], hy + L.k[2]
    local ax = hx + L.a[1]
    local ay = L.a.planted and (GROUND - BOOT_H + 1) or (hy + L.a[2])
    limb(img, hx, hy, kx, ky, 5, fill)
    limb(img, kx, ky, ax, ay, 4, fill)
    if not L.a.planted and L.a[1] < -3 then stamp_boot_back(img, ax, ay) else stamp_boot(img, ax, ay) end
  end
  -- Tronco por cima (só o que está acima do quadril), com o balanço. Perto do quadril só entra
  -- o miolo do corpo, para as coxas antigas (esticadas para trás) não sobrarem.
  for y = 0, hip_y do
    local xa, xb = 0, W - 1
    if y > hip_y - 6 then xa, xb = hip_x - 7, hip_x + 9 end
    for x = xa, xb do
      local c = src:getPixel(x, y)
      if pc.rgbaA(c) > 0 and y + pose.bob >= 0 then img:drawPixel(x, y + pose.bob, c) end
    end
  end
  local fr = first and out.frames[1] or out:newEmptyFrame()
  first = false
  fr.duration = 1 / 12
  out:newCel(out.layers[1], fr, img, Point(0, 0))
end
local t = out:newTag(1, #out.frames)
t.name = "run"
out:saveAs(app.fs.joinPath(root, "art_source", "personagem principal", "noct_run_v3.aseprite"))
print("corrida v3: " .. #out.frames .. " quadros, chão em y=" .. GROUND)
