-- Biblioteca de desenho pixel a pixel para os scripts de cenarios_novos.
-- Tudo e desenhado num "canvas" em memoria e depois copiado para uma Image do Aseprite.
local L = {}
local pc = app.pixelColor

L.LX, L.LY = -0.6, -0.8 -- luz vindo de cima-esquerda

function L.hex(h, a)
  h = h:gsub("#", "")
  return { tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16), a or 255 }
end

function L.ramp(list)
  local r = {}
  for i, h in ipairs(list) do r[i] = L.hex(h) end
  return r
end

function L.pick(ramp, b)
  if b < 0 then b = 0 end
  if b > 0.999 then b = 0.999 end
  return ramp[math.floor(b * #ramp) + 1]
end

function L.hash(x, y, s)
  x, y, s = math.floor(x), math.floor(y), math.floor(s or 0)
  local n = (x * 73856093) ~ (y * 19349663) ~ (s * 83492791)
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65535
end

local C = {}
C.__index = C

function L.canvas(w, h)
  return setmetatable({ w = w, h = h, px = {}, tag = {} }, C)
end

function C:inb(x, y) return x >= 0 and y >= 0 and x < self.w and y < self.h end

function C:set(x, y, col, tag)
  x, y = math.floor(x), math.floor(y)
  if not col or not self:inb(x, y) then return end
  local k = y * self.w + x
  self.px[k] = col
  self.tag[k] = tag
end

function C:get(x, y)
  x, y = math.floor(x), math.floor(y)
  if not self:inb(x, y) then return nil end
  return self.px[y * self.w + x]
end

function C:gettag(x, y)
  x, y = math.floor(x), math.floor(y)
  if not self:inb(x, y) then return nil end
  return self.tag[y * self.w + x]
end

function C:erase(x, y)
  x, y = math.floor(x), math.floor(y)
  if not self:inb(x, y) then return end
  local k = y * self.w + x
  self.px[k] = nil
  self.tag[k] = nil
end

-- compoe uma cor com alfa (0..255) por cima do que existe
function C:over(x, y, col, a)
  x, y = math.floor(x), math.floor(y)
  if not self:inb(x, y) then return end
  local k = y * self.w + x
  local e = self.px[k]
  if not e or e[4] == 0 then
    self.px[k] = { col[1], col[2], col[3], a }
    return
  end
  local fa, ea = a / 255, e[4] / 255
  local oa = fa + ea * (1 - fa)
  local function mix(i) return math.floor((col[i] * fa + e[i] * ea * (1 - fa)) / oa + 0.5) end
  self.px[k] = { mix(1), mix(2), mix(3), math.floor(oa * 255 + 0.5) }
end

function C:blit(src, ox, oy)
  for k, v in pairs(src.px) do
    self:set(k % src.w + ox, k // src.w + oy, v, src.tag[k])
  end
end

function C:toImage()
  local img = Image(self.w, self.h, ColorMode.RGB)
  img:clear(pc.rgba(0, 0, 0, 0))
  for k, v in pairs(self.px) do
    img:drawPixel(k % self.w, k // self.w, pc.rgba(v[1], v[2], v[3], v[4]))
  end
  return img
end

-- halo de brilho em volta dos pixels marcados com `tag`
function C:glow(tag, col, a1, a2)
  local src = {}
  for k, t in pairs(self.tag) do if t == tag then src[#src + 1] = k end end
  local done = {}
  local function ring(r, a)
    local nxt = {}
    for _, k in ipairs(src) do
      local x, y = k % self.w, k // self.w
      for dy = -r, r do
        for dx = -r, r do
          if math.abs(dx) + math.abs(dy) <= r + (r > 1 and 1 or 0) then
            local nx, ny = x + dx, y + dy
            if self:inb(nx, ny) then
              local kk = ny * self.w + nx
              if self.tag[kk] ~= tag and not done[kk] then nxt[kk] = true end
            end
          end
        end
      end
    end
    for kk in pairs(nxt) do
      done[kk] = true
      self:over(kk % self.w, kk // self.w, col, a)
    end
  end
  ring(1, a1)
  if a2 and a2 > 0 then ring(2, a2) end
end

----------------------------------------------------------------------------
-- Primitivas geometricas (amostragem no centro do pixel)

function L.poly(pts, fn)
  local minY, maxY = math.huge, -math.huge
  for _, p in ipairs(pts) do
    minY = math.min(minY, p[2]); maxY = math.max(maxY, p[2])
  end
  for y = math.floor(minY), math.ceil(maxY) do
    local yc = y + 0.5
    local xs = {}
    for i = 1, #pts do
      local a, b = pts[i], pts[i % #pts + 1]
      if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then
        xs[#xs + 1] = a[1] + (yc - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
      end
    end
    table.sort(xs)
    for i = 1, #xs - 1, 2 do
      for x = math.ceil(xs[i] - 0.5), math.floor(xs[i + 1] - 0.5) do fn(x, y) end
    end
  end
end

function L.ellipse(cx, cy, rx, ry, fn)
  for y = math.floor(cy - ry - 1), math.ceil(cy + ry + 1) do
    for x = math.floor(cx - rx - 1), math.ceil(cx + rx + 1) do
      local u, v = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      if u * u + v * v <= 1 then fn(x, y, u, v) end
    end
  end
end

-- capsula (segmento grosso, com raio afinando de r0 a r1); fn(x,y,t,s) com s em -1..1
function L.capsule(x0, y0, x1, y1, r0, r1, fn)
  local dx, dy = x1 - x0, y1 - y0
  local len2 = dx * dx + dy * dy
  local len = math.sqrt(len2)
  local rm = math.max(r0, r1)
  for y = math.floor(math.min(y0, y1) - rm - 1), math.ceil(math.max(y0, y1) + rm + 1) do
    for x = math.floor(math.min(x0, x1) - rm - 1), math.ceil(math.max(x0, x1) + rm + 1) do
      local px, py = x + 0.5 - x0, y + 0.5 - y0
      local t = len2 > 0 and (px * dx + py * dy) / len2 or 0
      if t < 0 then t = 0 elseif t > 1 then t = 1 end
      local qx, qy = px - dx * t, py - dy * t
      local d = math.sqrt(qx * qx + qy * qy)
      local r = r0 + (r1 - r0) * t
      if d <= r then
        local s = len > 0 and (dx * py - dy * px) / len / r or 0
        fn(x, y, t, s)
      end
    end
  end
end

function L.line(x0, y0, x1, y1, fn)
  x0, y0, x1, y1 = math.floor(x0), math.floor(y0), math.floor(x1), math.floor(y1)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  local i = 0
  while true do
    fn(x0, y0, i)
    i = i + 1
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

-- brilho de "travesseiro" para um volume eliptico (u,v em -1..1)
function L.lit(u, v, base, k)
  return (base or 0.5) + (k or 0.45) * (u * L.LX + v * L.LY)
end

----------------------------------------------------------------------------
-- Cristal (fragmento facetado): cols = {escuro, medio, claro, destaque}
function L.shard(c, bx, by, tx, ty, w, cols, tag)
  local dx, dy = tx - bx, ty - by
  local len = math.sqrt(dx * dx + dy * dy)
  local ux, uy = dx / len, dy / len
  local px, py = -uy, ux
  local litSide = (px * L.LX + py * L.LY) > 0 and 1 or -1
  local rm = w / 2 + 1
  for y = math.floor(math.min(by, ty) - rm), math.ceil(math.max(by, ty) + rm) do
    for x = math.floor(math.min(bx, tx) - rm), math.ceil(math.max(bx, tx) + rm) do
      local rx, ry = x + 0.5 - bx, y + 0.5 - by
      local t = (rx * ux + ry * uy) / len
      local s = rx * px + ry * py
      if t >= -0.05 and t <= 1 then
        local hw = (t < 0.55) and w / 2 or (w / 2) * (1 - t) / 0.45
        if math.abs(s) <= hw + 0.15 then
          local side = s * litSide
          local col
          if side >= -0.35 and side <= 0.65 and t > 0.12 and t < 0.92 then
            col = (t > 0.45) and cols[4] or cols[3]
          elseif side > 0 then
            col = cols[3]
          else
            col = (math.abs(s) > hw - 0.9) and cols[1] or cols[2]
          end
          if t > 0.9 then col = cols[4] end
          c:set(x, y, col, tag)
        end
      end
    end
  end
end

----------------------------------------------------------------------------
-- Saida

function L.preview(c, path, scale, bg)
  local img = Image(c.w * scale, c.h * scale, ColorMode.RGB)
  img:clear(pc.rgba(bg[1], bg[2], bg[3], 255))
  for y = 0, c.h - 1 do
    for x = 0, c.w - 1 do
      local v = c:get(x, y)
      if v then
        local a = v[4] / 255
        local col = pc.rgba(
          math.floor(v[1] * a + bg[1] * (1 - a)),
          math.floor(v[2] * a + bg[2] * (1 - a)),
          math.floor(v[3] * a + bg[3] * (1 - a)), 255)
        for yy = 0, scale - 1 do
          for xx = 0, scale - 1 do img:drawPixel(x * scale + xx, y * scale + yy, col) end
        end
      end
    end
  end
  img:saveAs(path)
end

-- monta a paleta do sprite com as cores realmente usadas
function L.applyPalette(spr, canvases)
  local seen, list = {}, {}
  for _, c in ipairs(canvases) do
    for _, v in pairs(c.px) do
      local key = string.format("%02x%02x%02x", v[1], v[2], v[3])
      if not seen[key] then seen[key] = true; list[#list + 1] = v end
    end
  end
  local pal = Palette(#list + 1)
  pal:setColor(0, Color { r = 0, g = 0, b = 0, a = 0 })
  for i, v in ipairs(list) do pal:setColor(i, Color { r = v[1], g = v[2], b = v[3], a = 255 }) end
  spr:setPalette(pal)
end

function L.saveTileset(c, dir, name)
  local spr = Sprite(c.w, c.h, ColorMode.RGB)
  spr.cels[1].image = c:toImage()
  spr.layers[1].name = name
  spr.gridBounds = Rectangle(0, 0, 16, 16)
  L.applyPalette(spr, { c })
  spr:saveAs(dir .. "/" .. name .. ".aseprite")
  spr:saveCopyAs(dir .. "/" .. name .. ".png")
  spr:close()
end

function L.saveAnim(frames, dir, name, durMs, tagName)
  local w, h = frames[1].w, frames[1].h
  local spr = Sprite(w, h, ColorMode.RGB)
  local layer = spr.layers[1]
  layer.name = name
  for i, c in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame() end
    spr:newCel(layer, spr.frames[i], c:toImage(), Point(0, 0))
    spr.frames[i].duration = durMs / 1000
  end
  local tag = spr:newTag(1, #frames)
  tag.name = tagName
  L.applyPalette(spr, frames)
  spr:saveAs(dir .. "/" .. name .. ".aseprite")
  app.command.ExportSpriteSheet {
    ui = false,
    askOverwrite = false,
    type = SpriteSheetType.HORIZONTAL,
    textureFilename = dir .. "/" .. name .. "_sheet.png",
    dataFilename = dir .. "/" .. name .. "_sheet.json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    listTags = true,
  }
  spr:saveCopyAs(dir .. "/" .. name .. ".gif")
  spr:close()
end

return L
