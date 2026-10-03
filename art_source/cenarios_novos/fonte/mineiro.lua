-- Monstro "Mineiro Cristalizado" (44x52, de lado virado para a direita, 4 quadros de idle)
local L, S, dir, prev = ...
local hex, hash = L.hex, L.hash

local SKIN = L.ramp { "#40295d", "#633c77", "#8f6a9b", "#b58bc1" }
local SHIRT = L.ramp { "#161633", "#212049", "#33325e", "#6f4b74" }
local PANTS = L.ramp { "#241230", "#41193b", "#47222e", "#5a2d2b" }
local BOOT = L.ramp { "#100a20", "#1b0f2b", "#321e4c" }
local HELM = L.ramp { "#41193b", "#5a2d2b", "#a4804e" }
local METAL = L.ramp { "#33325e", "#6f4b74", "#8f6a9b", "#b58bc1" }
local WOOD = L.ramp { "#41193b", "#5a2d2b", "#a4804e" }
local CR = L.ramp { "#41193b", "#961030", "#e82e52", "#ffaabe" }
local DARK, HAIR = hex("#100a20"), hex("#1b0f2b")
local GLOW = hex("#e82e52")

local W, H = 44, 52

local function vol(c, ramp, cx, cy, rx, ry, base, tag)
  return function(x, y)
    local u, v = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
    c:set(x, y, L.pick(ramp, L.lit(u, v, base or 0.5, 0.5)), tag)
  end
end

local function limb(c, ramp, x0, y0, x1, y1, r0, r1, base)
  local dx, dy = x1 - x0, y1 - y0
  local len = math.sqrt(dx * dx + dy * dy)
  L.capsule(x0, y0, x1, y1, r0, r1, function(x, y, t, s)
    local nx, ny = -dy / len * s, dx / len * s
    c:set(x, y, L.pick(ramp, (base or 0.5) + 0.5 * (nx * L.LX + ny * L.LY)))
  end)
end

local function frame(f)
  local oy = ({ 0, 1, 2, 1 })[f]
  local hy = ({ 0, 0, 1, 0 })[f]
  local glowA = ({ 55, 80, 105, 80 })[f]
  local c = L.canvas(W, H)

  -- perna de tras (mais escura)
  limb(c, PANTS, 18, 37 + hy, 15, 44, 2.4, 2.0, 0.3)
  limb(c, PANTS, 15, 44, 16, 48.5, 2.0, 1.8, 0.28)
  L.poly({ { 12.5, 48 }, { 18, 47.5 }, { 20.5, 49.5 }, { 20.5, 52 }, { 12.5, 52 } },
    vol(c, BOOT, 16, 49, 5, 3, 0.35))

  -- cristais nas costas (base escondida dentro do tronco)
  local shards = {
    { 16, 22, 7, 6, 5.2 }, { 20, 19, 19, 2.5, 4.4 }, { 13, 27, 3.5, 17, 4.2 },
    { 24, 18, 28, 8.5, 3.0 }, { 13, 32, 5.5, 29.5, 3.0 },
  }
  for _, s in ipairs(shards) do L.shard(c, s[1], s[2] + oy, s[3], s[4] + oy, s[5], CR, "cr") end

  -- tronco curvado
  L.poly({
    { 12, 31 + oy }, { 12.5, 24 + oy }, { 16, 18 + oy }, { 22, 15 + oy }, { 28, 15.5 + oy },
    { 32, 19 + oy }, { 32.5, 26 + oy }, { 29, 33 + oy }, { 27.5, 38 + hy }, { 15, 38.5 + hy }, { 12.5, 35 + hy },
  }, vol(c, SHIRT, 21, 24 + oy, 11, 12, 0.55))
  -- rasgo na camisa mostrando as costelas
  L.ellipse(18, 29 + oy, 2.6, 1.8, vol(c, SKIN, 18, 28 + oy, 3, 2, 0.4))
  c:set(17, 29 + oy, SKIN[1]); c:set(19, 29 + oy, SKIN[1]); c:set(18, 30 + oy, SKIN[1])
  -- linha de sombra separando costas e barriga
  L.line(14, 33 + hy, 26, 35 + hy, function(x, y) c:set(x, y, SHIRT[1]) end)
  -- suspensorio
  L.line(27, 17 + oy, 24, 35 + hy, function(x, y) c:set(x, y, HELM[2]) end)
  -- barra rasgada
  for x = 14, 27, 3 do c:set(x, 38 + hy, SHIRT[1]); c:set(x + 1, 37 + hy, SHIRT[2]) end

  -- quadril / cinto
  L.ellipse(21, 38 + hy, 7.5, 2.8, vol(c, PANTS, 20, 37 + hy, 8, 3, 0.55))
  for x = 14, 28 do c:set(x, 36 + hy, HAIR) end
  c:set(24, 36 + hy, HELM[3]); c:set(25, 36 + hy, HELM[2])

  -- perna da frente
  limb(c, PANTS, 24, 38 + hy, 27, 44, 2.7, 2.2, 0.55)
  limb(c, PANTS, 27, 44, 25, 48.5, 2.2, 1.9, 0.5)
  c:set(26, 43, PANTS[1]); c:set(27, 42, PANTS[1]) -- remendo no joelho
  L.poly({ { 21.5, 48 }, { 27, 47.5 }, { 30.5, 49.5 }, { 30.5, 52 }, { 21.5, 52 } },
    vol(c, BOOT, 25, 49, 6, 3, 0.6))
  for x = 23, 28 do c:set(x, 48, BOOT[3]) end

  -- pescoco e cabeca
  limb(c, SKIN, 28, 19 + oy, 31, 21 + oy, 2.6, 2.4, 0.45)
  L.ellipse(34, 21 + oy, 4.6, 4.4, vol(c, SKIN, 34, 21 + oy, 4.6, 4.4, 0.55))
  L.poly({ { 31, 24 + oy }, { 37.5, 24 + oy }, { 37, 27.5 + oy }, { 32, 27 + oy } },
    vol(c, SKIN, 34, 24 + oy, 4, 3, 0.4))
  -- boca aberta com dentes
  for x = 34, 38 do c:set(x, 24 + oy, DARK) end
  for x = 35, 37 do c:set(x, 25 + oy, DARK) end
  if f == 3 then for x = 35, 36 do c:set(x, 26 + oy, DARK) end end
  c:set(34, 24 + oy, SKIN[4]); c:set(36, 24 + oy, SKIN[4]); c:set(38, 24 + oy, SKIN[3])
  -- nariz, orelha, cabelo
  c:set(39, 21 + oy, SKIN[3]); c:set(39, 22 + oy, SKIN[2])
  c:set(31, 21 + oy, SKIN[2]); c:set(31, 22 + oy, SKIN[1])
  for y = 19, 23 do c:set(29, y + oy, HAIR) end
  for y = 19, 21 do c:set(30, y + oy, HAIR) end
  c:set(28, 24 + oy, HAIR)
  -- olho fundo brilhando
  for x = 35, 37 do c:set(x, 19 + oy, PANTS[1]) end
  c:set(35, 20 + oy, PANTS[1])
  c:set(36, 20 + oy, CR[3], "eye"); c:set(37, 20 + oy, CR[4], "eye")

  -- capacete de mineiro com lanterna cristalizada
  L.ellipse(33.5, 17.5 + oy, 5.6, 3.6, function(x, y)
    if y <= 17 + oy then vol(c, HELM, 32, 15 + oy, 6, 4, 0.6)(x, y) end
  end)
  for x = 28, 40 do c:set(x, 18 + oy, HELM[2]) end
  for x = 29, 40 do c:set(x, 19 + oy, HELM[1]) end
  c:set(32, 15 + oy, HELM[1]); c:set(33, 16 + oy, HELM[1]) -- amassado
  for y = 15, 17 do c:set(38, y + oy, METAL[2]) end
  c:set(39, 15 + oy, CR[4], "eye"); c:set(40, 15 + oy, CR[3], "eye")
  c:set(39, 16 + oy, CR[3], "eye"); c:set(40, 16 + oy, CR[2], "eye")

  -- cabo da picareta
  limb(c, WOOD, 29, 27 + oy, 34.6, 43 + oy, 1.1, 1.1, 0.5)

  -- braco da frente
  L.ellipse(27, 21 + oy, 3.6, 3.4, vol(c, SHIRT, 26, 20 + oy, 4, 4, 0.6))
  limb(c, SHIRT, 27, 22 + oy, 28.5, 28.5 + oy, 2.6, 2.3, 0.55)
  limb(c, SKIN, 28.5, 28.5 + oy, 32, 33 + oy, 2.0, 1.8, 0.55)
  c:set(27, 30 + oy, SHIRT[1]); c:set(29, 30 + oy, SHIRT[2]) -- manga rasgada
  L.shard(c, 26, 19 + oy, 23.5, 13.5 + oy, 2.6, CR, "cr") -- cristal no ombro
  L.ellipse(32.3, 33.5 + oy, 2.2, 2.0, vol(c, SKIN, 32, 33 + oy, 2.2, 2.0, 0.6))
  c:set(33, 34 + oy, SKIN[1]); c:set(32, 35 + oy, SKIN[1])

  -- cabeca da picareta (arco de metal)
  local cx, cy = 35, 44 + oy
  local dx, dy = 6 / 19, 18 / 19
  local px, py = dy, -dx
  local prevP
  for i = -13, 13 do
    local s = i / 2
    local k = (s / 6.5) ^ 2
    local p = { cx + px * s - dx * 1.8 * k, cy + py * s - dy * 1.8 * k, 1.9 * (1 - math.abs(s) / 6.5) ^ 0.7 + 0.5 }
    if prevP then limb(c, METAL, prevP[1], prevP[2], p[1], p[2], prevP[3], p[3], 0.6) end
    prevP = p
  end
  L.ellipse(cx, cy, 1.8, 1.8, vol(c, METAL, cx, cy, 1.8, 1.8, 0.35))

  c:glow("cr", GLOW, glowA, math.floor(glowA / 3))
  c:glow("eye", GLOW, 70, 0)
  return c
end

local frames = {}
for f = 1, 4 do frames[f] = frame(f) end
L.saveAnim(frames, dir, "mineiro_cristalizado", 170, "idle")

local strip = L.canvas(W * 4, H)
for f = 1, 4 do strip:blit(frames[f], (f - 1) * W, 0) end
L.preview(strip, prev .. "/prev_mineiro.png", 5, hex("#1b1230"))
