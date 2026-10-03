-- Monstro "Grimorio Voraz" (40x40, de lado virado para a direita, 4 quadros de voo)
-- As capas batem como asas: a boca abre e fecha a cada ciclo.
local L, S, dir, prev = ...
local hex, hash = L.hex, L.hash

local LEA = L.ramp { "#241230", "#41193b", "#5a2d2b", "#961030" }
local PAGE_L, PAGE_M, PAGE_D = hex("#b58bc1"), hex("#8f6a9b"), hex("#6f4b74")
local TOOTH, TOOTH_HI = hex("#b58bc1"), hex("#ffaabe")
local GOLD, GOLD_D = hex("#a4804e"), hex("#5a2d2b")
local TEAL, TEAL_D, TEAL_DD = hex("#5affe6"), hex("#1a4649"), hex("#0b2b28")
local MOUTH = { hex("#241230"), hex("#41193b"), hex("#961030") }
local RIB, RIB_HI = hex("#e82e52"), hex("#ffaabe")
local PUPIL = hex("#100a20")

local W, Hh = 40, 40
local LEN = 23

local function jaw(c, hx, hy, deg, up)
  local a = math.rad(deg)
  local dx, dy = math.cos(a), up and -math.sin(a) or math.sin(a)
  local nx, ny = -math.sin(a), up and -math.cos(a) or math.cos(a)
  for y = 0, Hh - 1 do
    for x = 0, W - 1 do
      local vx, vy = x + 0.5 - hx, y + 0.5 - hy
      local s = vx * dx + vy * dy
      local t = vx * nx + vy * ny
      local col
      if t >= 3 and t < 6.2 and s >= -0.5 and s <= LEN + 0.8 then
        if up then
          col = (t >= 5.2) and LEA[4] or ((t >= 4) and LEA[3] or LEA[2])
        else
          col = (t >= 5.2) and LEA[1] or ((t >= 4) and LEA[2] or LEA[3])
        end
        if s > LEN - 2.2 then col = (up and t >= 5.2) and TOOTH_HI or GOLD end
        if s > LEN - 2.2 and not up and t >= 5.2 then col = GOLD_D end
      elseif t >= 0 and t < 3 and s >= 0.5 and s <= LEN - 0.5 then
        col = (math.floor(t) % 2 == 0) and PAGE_L or PAGE_M
        if s > LEN - 1.5 then col = PAGE_M end
        if s < 3 or hash(x, y, 7) < 0.06 then col = PAGE_D end
      elseif t >= -3 and t < 0 and s >= 2 and s <= LEN - 1.5 then
        local q = (s - 2) % 3.2
        local hw = 1.6 * (1 + t / 3)
        if math.abs(q - 1.6) <= hw then col = (t < -1.2) and TOOTH_HI or TOOTH end
      end
      if col then c:set(x, y, col) end
    end
  end
  return dx, dy, nx, ny
end

local function frame(f)
  local up = ({ 16, 30, 42, 30 })[f]
  local lo = ({ 10, 18, 24, 18 })[f]
  local bob = ({ 1, 0, -1, 0 })[f]
  local sway = ({ 0, 1, 2, 1 })[f]
  local hx, hy = 10, 20 + bob
  local c = L.canvas(W, Hh)

  -- interior da boca
  local ua, la = math.rad(up), math.rad(lo)
  for y = 0, Hh - 1 do
    for x = 0, W - 1 do
      local vx, vy = x + 0.5 - hx, y + 0.5 - hy
      local r = math.sqrt(vx * vx + vy * vy)
      local ang = math.atan(-vy, vx)
      if r > 1 and r < 11.5 and ang < ua and ang > -la then
        if r < 6 then c:set(x, y, MOUTH[1])
        elseif r < 9 then c:set(x, y, MOUTH[2])
        else c:over(x, y, MOUTH[3], (r < 10.5) and 230 or 120) end
      end
    end
  end

  jaw(c, hx, hy, lo, false)

  -- fita marcadora carmesim pendendo da lombada, balancando no voo
  local pts = { { hx, hy + 5 }, { hx + 1, hy + 10 }, { hx - 1 + sway, hy + 14 }, { hx - 2 + sway * 1.5, hy + 17 } }
  for i = 1, #pts - 1 do
    local a, b = pts[i], pts[i + 1]
    L.capsule(a[1], a[2], b[1], b[2], 1.1, 1.0, function(x, y, t, s)
      c:set(x, y, (s < -0.3) and RIB_HI or RIB, "rib")
    end)
  end
  local tip = pts[#pts]
  c:set(tip[1] - 1, tip[2] + 2, RIB, "rib"); c:set(tip[1] + 1, tip[2] + 2, RIB, "rib")

  local dx, dy, nx, ny = jaw(c, hx, hy, up, true)

  -- lombada com faixas douradas
  L.ellipse(hx - 1.5, hy, 4, 7, function(x, y, u, v)
    local col = L.pick(LEA, L.lit(u, v, 0.55, 0.55))
    if y == math.floor(hy - 4) or y == math.floor(hy + 3) then
      col = (u < 0.2) and GOLD or GOLD_D
    end
    c:set(x, y, col)
  end)

  -- olho azul-esverdeado na capa de cima
  local ex, ey = hx + dx * 10 + nx * 4.6, hy + dy * 10 + ny * 4.6
  L.ellipse(ex, ey, 3.2, 3.0, function(x, y, u, v)
    local d = u * u + v * v
    local col = (d > 0.6) and TEAL_D or TEAL
    if d > 0.6 and v > 0.2 then col = TEAL_DD end
    c:set(x, y, col, "eye")
  end)
  local px = math.floor(ex + 0.9)
  for yy = -1, 1 do c:set(px, math.floor(ey) + yy, PUPIL, "eye") end
  c:set(math.floor(ex - 1), math.floor(ey - 1), PAGE_L, "eye")
  -- palpebra de couro
  for x = math.floor(ex - 2), math.floor(ex + 2) do c:set(x, math.floor(ey - 3), LEA[2]) end

  -- paginas soltas esvoacando atras
  local py = hy - 9 + ({ 0, 1, 0, -1 })[f]
  c:set(2, py, PAGE_L); c:set(3, py, PAGE_L); c:set(3, py + 1, PAGE_M); c:set(4, py + 1, PAGE_M)
  local py2 = hy + 9 + ({ 0, -1, 0, 1 })[f]
  c:set(1, py2, PAGE_M); c:set(2, py2, PAGE_L); c:set(2, py2 - 1, PAGE_D)
  c:over(5 - f % 2, hy - 12 + f, TEAL, 160)
  c:over(33, hy - 2 - f, TEAL, 120)

  c:glow("eye", TEAL, 70, 25)
  c:glow("rib", RIB, 40, 0)
  return c
end

local frames = {}
for f = 1, 4 do frames[f] = frame(f) end
L.saveAnim(frames, dir, "grimorio_voraz", 110, "voo")

local strip = L.canvas(W * 4, Hh)
for f = 1, 4 do strip:blit(frames[f], (f - 1) * W, 0) end
L.preview(strip, prev .. "/prev_grimorio.png", 6, hex("#161633"))
