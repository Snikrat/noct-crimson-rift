-- Kit de desenho dos sprites gerados por script no Aseprite (o mesmo jeito de tools/make_velario.lua):
-- monta cada quadro por formas (polígono, elipse, traço grosso) com material + degrau de rampa,
-- depois aplica luz de cima à esquerda, contorno escuro e brilho carmesim. Uso:
--   local K = dofile(app.fs.joinPath(app.fs.filePath(debug.getinfo(1).source:sub(2)), "pixel_kit.lua"))

local K = {}

local function rgb(h, a)
	return app.pixelColor.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), a or 255)
end
K.rgb = rgb

-- Rampas (escuro -> claro), na paleta do jogo.
K.RAMPS = {
	VEIL = { "#07060b", "#110e18", "#1c1826", "#2b2638", "#3d3650" },
	PALE = { "#1a1a2a", "#2f3248", "#4d5470", "#7a83a3", "#b4bdd6", "#e4e9f5" },
	IRON = { "#15161b", "#2b2e36", "#4a4f5a", "#6b717d", "#9aa0aa" },
	CRIM = { "#3a0a1d", "#6e0d2a", "#9c1238", "#d9264f", "#ff6f96", "#ffd0dd" },
	FLESH = { "#1c0709", "#3d0f14", "#5e1a1e", "#83302c", "#a8503f", "#c97a5c" },
	BONE = { "#3b3330", "#6b6058", "#9c9186", "#cfc6b8" },
	SOUL = { "#0d1b33", "#1c3a66", "#3a6aa8", "#6fa3e0", "#b8dcff", "#eef8ff" },
	SHADOW = { "#050409", "#0c0912", "#15111d", "#221c2d" },
	OUT = { "#050308" },
}
K.NOSHADE = { CRIM = true, SOUL = true, OUT = true, GLOW = true }
K.NOOUT = { SMEAR = true, GLOW = true }
K.RAMPS.SMEAR = K.RAMPS.CRIM
K.RAMPS.GLOW = K.RAMPS.SOUL
K.COL = {}
for k, r in pairs(K.RAMPS) do
	K.COL[k] = {}
	for i, h in ipairs(r) do K.COL[k][i] = rgb(h) end
end

function K.hash(x, y, s)
	local n = math.floor(x) * 374761393 + math.floor(y) * 668265263 + (s or 0) * 1442695041
	n = (n ~ (n >> 13)) * 1274126177
	n = n ~ (n >> 16)
	return (n & 0xffff) / 65535
end

function K.canvas(w, h)
	return { w = w, h = h, m = {}, l = {}, a = {}, glows = {} }
end

local function idx(c, x, y) return y * c.w + x end

-- alpha opcional (0..255) para materiais translúcidos.
function K.put(c, x, y, mat, l, alpha)
	x, y = math.floor(x + 0.5), math.floor(y + 0.5)
	if x < 0 or y < 0 or x >= c.w or y >= c.h then return end
	local r = K.RAMPS[mat]
	l = math.max(1, math.min(#r, l))
	local i = idx(c, x, y)
	c.m[i] = mat
	c.l[i] = l
	c.a[i] = alpha
end

function K.erase(c, x, y)
	x, y = math.floor(x + 0.5), math.floor(y + 0.5)
	if x < 0 or y < 0 or x >= c.w or y >= c.h then return end
	local i = idx(c, x, y)
	c.m[i] = nil; c.l[i] = nil; c.a[i] = nil
end

function K.get(c, x, y)
	if x < 0 or y < 0 or x >= c.w or y >= c.h then return nil end
	return c.m[idx(c, x, y)]
end

local function lvl(lv, ...)
	if type(lv) == "function" then return lv(...) end
	return lv
end

function K.poly(c, pts, mat, lv, alpha)
	local miny, maxy = 1e9, -1e9
	for _, p in ipairs(pts) do miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2]) end
	for y = math.floor(miny), math.ceil(maxy) do
		local xs = {}
		local yc = y + 0.5
		for i = 1, #pts do
			local a, b = pts[i], pts[i % #pts + 1]
			if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then
				xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1])
			end
		end
		table.sort(xs)
		for i = 1, #xs - 1, 2 do
			for x = math.floor(xs[i] + 0.5), math.floor(xs[i + 1] - 0.5) do
				K.put(c, x, y, mat, lvl(lv, x, y), alpha)
			end
		end
	end
end

function K.ellipse(c, cx, cy, rx, ry, mat, lv, alpha)
	for y = math.floor(cy - ry), math.ceil(cy + ry) do
		for x = math.floor(cx - rx), math.ceil(cx + rx) do
			local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1 then K.put(c, x, y, mat, lvl(lv, x, y, dx, dy), alpha) end
		end
	end
end

function K.thick(c, x0, y0, x1, y1, r, mat, lv, alpha)
	local len = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
	local steps = math.max(1, math.ceil(len * 2))
	for i = 0, steps do
		local t = i / steps
		local x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
		if r < 0.75 then K.put(c, x, y, mat, lvl(lv, x, y), alpha)
		else K.ellipse(c, x, y, r, r, mat, lv, alpha) end
	end
end

-- Curva de Bézier quadrática grossa (raio r0 -> r1).
function K.curve(c, p0, p1, p2, r0, r1, mat, lv)
	local steps = 24
	for i = 0, steps do
		local t = i / steps
		local u = 1 - t
		local x = u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]
		local y = u * u * p0[2] + 2 * u * t * p1[2] + t * t * p2[2]
		local r = r0 + (r1 - r0) * t
		if r < 0.75 then K.put(c, x, y, mat, lvl(lv, x, y))
		else K.ellipse(c, x, y, r, r, mat, lv) end
	end
end

-- Luz, contorno e brilho -> Image RGBA.
function K.render(c, outline)
	local W, H = c.w, c.h
	local nl = {}
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local i = idx(c, x, y)
			local m = c.m[i]
			if m and not K.NOSHADE[m] and m ~= "SMEAR" then
				local l = c.l[i]
				if not K.get(c, x - 1, y) or not K.get(c, x, y - 1) then l = l + 1
				elseif not K.get(c, x + 1, y) or not K.get(c, x, y + 1) then l = l - 1 end
				nl[i] = math.max(1, math.min(#K.RAMPS[m], l))
			end
		end
	end
	for i, l in pairs(nl) do c.l[i] = l end
	local img = Image(W, H, ColorMode.RGB)
	img:clear(app.pixelColor.rgba(0, 0, 0, 0))
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local i = idx(c, x, y)
			local m = c.m[i]
			if m then
				local col = K.COL[m][c.l[i]]
				if c.a[i] then
					col = app.pixelColor.rgba(app.pixelColor.rgbaR(col), app.pixelColor.rgbaG(col), app.pixelColor.rgbaB(col), c.a[i])
				end
				img:drawPixel(x, y, col)
			elseif outline ~= false then
				for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
					local n = K.get(c, x + d[1], y + d[2])
					local ni = idx(c, x + d[1], y + d[2])
					if n and not K.NOOUT[n] and not (c.a[ni] and c.a[ni] < 200) then
						img:drawPixel(x, y, K.COL.OUT[1])
						break
					end
				end
			end
		end
	end
	for _, g in ipairs(c.glows) do
		local gx, gy, gr, gs = g[1], g[2], g[3], g[4]
		local cr, cg, cb = g[5] or 217, g[6] or 38, g[7] or 79
		for y = math.floor(gy - gr), math.ceil(gy + gr) do
			for x = math.floor(gx - gr), math.ceil(gx + gr) do
				if x >= 0 and y >= 0 and x < W and y < H then
					local d = math.sqrt((x - gx) ^ 2 + (y - gy) ^ 2) / gr
					if d < 1 then
						local f = (1 - d) * gs
						local px = img:getPixel(x, y)
						local a = app.pixelColor.rgbaA(px)
						if a > 0 then
							local r, gg, b = app.pixelColor.rgbaR(px), app.pixelColor.rgbaG(px), app.pixelColor.rgbaB(px)
							img:drawPixel(x, y, app.pixelColor.rgba(
								math.min(255, math.floor(r + (cr - r) * f * 0.7)),
								math.min(255, math.floor(gg + (cg - gg) * f * 0.6)),
								math.min(255, math.floor(b + (cb - b) * f * 0.6)), a))
						end
					end
				end
			end
		end
	end
	return img
end

-- Gera tiras PNG (uma por animação) e um .aseprite com uma tag por animação.
-- anims = { {name=, fps=, frames={pose,...}}, ... }; draw(pose, i) -> Image.
function K.build(W, H, anims, draw, src, out_dir, prefix)
	app.fs.makeAllDirectories(out_dir)
	local spr = Sprite(W, H, ColorMode.RGB)
	spr.layers[1].name = prefix
	local total = 0
	for _, a in ipairs(anims) do
		local strip = Image(W * #a.frames, H, ColorMode.RGB)
		strip:clear(app.pixelColor.rgba(0, 0, 0, 0))
		local first = total + 1
		for i, p in ipairs(a.frames) do
			local img = draw(p, i)
			strip:drawImage(img, Point((i - 1) * W, 0))
			total = total + 1
			if total > 1 then spr:newEmptyFrame() end
			spr:newCel(spr.layers[1], total, img, Point(0, 0))
			spr.frames[total].duration = 1 / a.fps
		end
		local tag = spr:newTag(first, total)
		tag.name = a.name
		strip:saveAs(out_dir .. prefix .. "_" .. a.name .. ".png")
	end
	spr:saveAs(src)
	spr:close()
	print(prefix .. ": " .. total .. " quadros")
end

return K
