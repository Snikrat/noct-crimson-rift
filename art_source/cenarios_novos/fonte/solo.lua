-- Montagem das pecas de terreno 16x16 (topo, meio, bordas, cantos) a partir
-- de uma funcao de preenchimento que devolve um indice na rampa (1 = rachadura).
local L = ...
local S = {}

-- ex = {t=,l=,r=,b=} lados expostos; prof = perfis {t={16},l={16},r={16},b={16}}
-- rim(x,y,idx,lado,dist) pode personalizar a cor da borda; devolve cor ou nil
function S.tile(fill, ramp, ex, prof, rim)
  local c = L.canvas(16, 16)
  local n = #ramp
  for y = 0, 15 do
    for x = 0, 15 do
      local top = ex.t and prof.t[x + 1] or -99
      local left = ex.l and prof.l[y + 1] or -99
      local right = ex.r and 15 - prof.r[y + 1] or 99
      local bot = ex.b and 15 - prof.b[x + 1] or 99
      local dt, dl, dr, db = y - top, x - left, right - x, bot - y
      local inside = dt >= 0 and dl >= 0 and dr >= 0 and db >= 0
      if inside then
        if ex.t and ex.l and dt + dl < 2 then inside = false end
        if ex.t and ex.r and dt + dr < 2 then inside = false end
        if ex.b and ex.l and db + dl < 2 then inside = false end
        if ex.b and ex.r and db + dr < 2 then inside = false end
      end
      if inside then
        local idx = fill(x, y)
        if ex.l then
          if dl == 0 then idx = math.max(idx, n - 2)
          elseif dl == 1 then idx = math.max(idx, n - 3) end
        end
        if ex.r then
          if dr == 0 then idx = math.min(idx, 3)
          elseif dr == 1 then idx = math.max(2, math.min(idx - 1, n - 4)) end
        end
        if ex.b then
          if db == 0 then idx = 2
          elseif db == 1 then idx = math.min(idx, 3)
          elseif db == 2 then idx = math.min(idx, n - 3) end
        end
        if ex.t then
          if dt == 0 then idx = (L.hash(x, y, 5) < 0.75) and n or n - 1
          elseif dt == 1 then idx = math.max(idx, n - 2)
          elseif dt == 2 then idx = math.max(idx, n - 3) end
        end
        if idx < 1 then idx = 1 end
        if idx > n then idx = n end
        local col = ramp[idx]
        if rim then
          local side, dist
          if ex.t and dt <= 1 then side, dist = "t", dt
          elseif ex.b and db <= 1 then side, dist = "b", db end
          local alt = rim(x, y, idx, side, dist)
          if alt then col = alt end
        end
        c:set(x, y, col)
      end
    end
  end
  return c
end

-- os 9 pedacos do bloco 3x3 + bloco isolado
function S.set9(fill, ramp, prof, rim)
  local T = {}
  local function mk(t, l, r, b) return S.tile(fill, ramp, { t = t, l = l, r = r, b = b }, prof, rim) end
  T.TL = mk(true, true, false, false)
  T.T = mk(true, false, false, false)
  T.TR = mk(true, false, true, false)
  T.L = mk(false, true, false, false)
  T.M = mk(false, false, false, false)
  T.R = mk(false, false, true, false)
  T.BL = mk(false, true, false, true)
  T.B = mk(false, false, false, true)
  T.BR = mk(false, false, true, true)
  T.ONE = mk(true, true, true, true)
  return T
end

-- Voronoi periodico (periodo P) para pedras
function S.voronoi(x, y, seeds, P)
  local d1, d2, best, bdx, bdy = 1e9, 1e9, 1, 0, 0
  for i, s in ipairs(seeds) do
    for ox = -1, 1 do
      for oy = -1, 1 do
        local dx = x + 0.5 - (s[1] + ox * P)
        local dy = y + 0.5 - (s[2] + oy * P)
        local d = math.sqrt(dx * dx + dy * dy)
        if d < d1 then d2 = d1; d1 = d; best = i; bdx = dx; bdy = dy
        elseif d < d2 then d2 = d end
      end
    end
  end
  return d1, d2, best, bdx, bdy
end

return S
