-- Velário, o Carcereiro das Lembranças: chefe do Lago Velado (docs/expansao_forma_demoniaca.md, seção 3).
-- Gera no Aseprite a fonte (art_source/inimigos/velario.aseprite, uma tag por animação) e as tiras do jogo
-- (assets/enemies/velario/<animação>.png, quadros de 192x136 lado a lado, pés na linha 130, corpo em x=96,
-- desenho olhando para a direita).
-- Rodar na raiz do projeto:
--   Aseprite.exe -b --script tools/make_velario.lua
-- O desenho é montado por poses (corpo, véu, chave-lâmina, lanterna) e depois recebe contorno e luz
-- de cima à esquerda, no mesmo estilo dos outros sprites. Dá para retocar o .aseprite à mão.

local W, H = 192, 136
local FEET = 130
local X0 = 96
local SRC = "art_source/inimigos/velario.aseprite"
local OUT = "assets/enemies/velario/"
app.fs.makeAllDirectories(OUT)

local function rgb(h, a)
	return app.pixelColor.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), a or 255)
end

-- Rampas (escuro -> claro). Véu frio e quase preto, ferro, carmesim da Fenda, latão das chaves, espelho.
local RAMPS = {
	VEIL = { "#07060b", "#110e18", "#1c1826", "#2b2638", "#3d3650" },
	IRON = { "#15161b", "#2b2e36", "#4a4f5a", "#6b717d", "#9aa0aa" },
	CRIM = { "#3a0a1d", "#6e0d2a", "#9c1238", "#d9264f", "#ff6f96", "#ffd0dd" },
	BRASS = { "#2a2010", "#4e3d1c", "#7a6230", "#a88a4a" },
	MIRROR = { "#1d232c", "#3a4656", "#617488", "#9cb0c4", "#dce7f2" },
	OUT = { "#050308" },
}
local NOSHADE = { CRIM = true, MIRROR = true, OUT = true }
local NOOUT = { SMEAR = true }
RAMPS.SMEAR = RAMPS.CRIM
local COL = {}
for k, r in pairs(RAMPS) do
	COL[k] = {}
	for i, h in ipairs(r) do COL[k][i] = rgb(h) end
end

local function hash(x, y, s)
	local n = math.floor(x) * 374761393 + math.floor(y) * 668265263 + (s or 0) * 1442695041
	n = (n ~ (n >> 13)) * 1274126177
	n = n ~ (n >> 16)
	return (n & 0xffff) / 65535
end

---------------------------------------------------------------------------
-- Tela: material + degrau da rampa por pixel.
---------------------------------------------------------------------------
local function canvas()
	return { m = {}, l = {}, glows = {} }
end

local function idx(x, y) return y * W + x end

local function put(c, x, y, mat, l)
	x, y = math.floor(x + 0.5), math.floor(y + 0.5)
	if x < 0 or y < 0 or x >= W or y >= H then return end
	local r = RAMPS[mat]
	l = math.max(1, math.min(#r, l))
	c.m[idx(x, y)] = mat
	c.l[idx(x, y)] = l
end

local function erase(c, x, y)
	x, y = math.floor(x + 0.5), math.floor(y + 0.5)
	c.m[idx(x, y)] = nil
	c.l[idx(x, y)] = nil
end

local function get(c, x, y)
	if x < 0 or y < 0 or x >= W or y >= H then return nil end
	return c.m[idx(x, y)]
end

-- Polígono preenchido (par-ímpar). lv: número ou função(x, y).
local function poly(c, pts, mat, lv)
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
				put(c, x, y, mat, type(lv) == "function" and lv(x, y) or lv)
			end
		end
	end
end

local function ellipse(c, cx, cy, rx, ry, mat, lv)
	for y = math.floor(cy - ry), math.ceil(cy + ry) do
		for x = math.floor(cx - rx), math.ceil(cx + rx) do
			local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1 then put(c, x, y, mat, type(lv) == "function" and lv(x, y, dx, dy) or lv) end
		end
	end
end

local function thick(c, x0, y0, x1, y1, r, mat, lv)
	local len = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
	local steps = math.max(1, math.ceil(len * 2))
	for i = 0, steps do
		local t = i / steps
		local x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
		if r < 0.75 then
			put(c, x, y, mat, lv)
		else
			ellipse(c, x, y, r, r, mat, lv)
		end
	end
end

local function ring(c, cx, cy, r, mat, lv)
	for a = 0, 47 do
		local t = a / 48 * math.pi * 2
		put(c, cx + math.cos(t) * r, cy + math.sin(t) * r, mat, lv)
	end
end

---------------------------------------------------------------------------
-- Peças
---------------------------------------------------------------------------

-- Chave-lâmina: argola atrás da mão, haste longa, dentes na ponta, fio enferrujado de carmesim.
local function key(c, hx, hy, ang, len)
	local dx, dy = math.cos(ang), math.sin(ang)
	local nx, ny = -dy, dx
	-- A ponta nunca atravessa o chão: apoia nele.
	if dy > 0.05 and hy + dy * len > FEET - 1 then len = math.floor((FEET - 1 - hy) / dy) end
	ring(c, hx - dx * 7, hy - dy * 7, 3.5, "IRON", 3)
	ring(c, hx - dx * 7, hy - dy * 7, 2.6, "IRON", 2)
	thick(c, hx - dx * 3, hy - dy * 3, hx + dx * len, hy + dy * len, 1.1, "IRON", 3)
	for i = 8, len - 2 do
		put(c, hx + dx * i + nx * 1.4, hy + dy * i + ny * 1.4, "CRIM", (i % 7 < 2) and 3 or 2)
	end
	local tx, ty = hx + dx * len, hy + dy * len
	for _, t in ipairs({ { 3, 7 }, { 9, 5 }, { 13, 3 } }) do
		local bx, by = tx - dx * t[1], ty - dy * t[1]
		thick(c, bx, by, bx - nx * t[2], by - ny * t[2], 0.9, "IRON", 2)
	end
	-- Guarda (travessa) logo à frente da mão.
	thick(c, hx + dx * 2 + nx * 3, hy + dy * 2 + ny * 3, hx + dx * 2 - nx * 3, hy + dy * 2 - ny * 3, 0.8, "IRON", 4)
end

-- Rastro do golpe: arco carmesim entre dois ângulos (sem contorno).
local function smear(c, hx, hy, a0, a1, r0, r1)
	local steps = math.max(8, math.floor(math.abs(a1 - a0) * r1 * 1.2))
	for i = 0, steps do
		local t = a0 + (a1 - a0) * i / steps
		local k = i / steps
		-- Faixa que engrossa até o fim do golpe; borda de fora mais clara.
		local inner = r1 - 2 - math.floor(k * 9)
		for r = inner, r1 do
			local edge = r1 - r
			local l = edge == 0 and 6 or (edge <= 1 and 5 or (edge <= 4 and 4 or 2))
			if edge > 4 and hash(r, i, 3) > 0.5 then l = 0 end
			if l > 0 then put(c, hx + math.cos(t) * r, hy + math.sin(t) * r, "SMEAR", l) end
		end
	end
end

-- Lanterna-gaiola pendurada na mão (hx, hy). cracked = rachada (transição).
local function lantern(c, hx, hy, swing, power, cracked)
	local x = hx + swing
	thick(c, hx, hy, x, hy + 3, 0.5, "IRON", 3)
	ring(c, x, hy + 1, 1.5, "IRON", 3)
	local top, bot = hy + 4, hy + 16
	poly(c, { { x - 3, top }, { x + 3, top }, { x + 5, top + 2 }, { x - 5, top + 2 } }, "IRON", 3)
	for y = top + 2, bot - 1 do
		for xx = x - 4, x + 4 do
			put(c, xx, y, "CRIM", 1)
		end
	end
	-- A linha de luz presa dentro (a memória).
	for y = top + 3, bot - 2 do
		local wx = x + math.floor(math.sin(y * 0.9 + swing) * 1.5 + 0.5)
		put(c, wx, y, "CRIM", 5 + (power > 1 and 1 or 0))
		put(c, wx + 1, y, "CRIM", 4)
	end
	for _, bx in ipairs({ -4, -1, 2, 4 }) do
		for y = top + 2, bot - 1 do put(c, x + bx, y, "IRON", 2) end
	end
	poly(c, { { x - 5, bot }, { x + 5, bot }, { x + 3, bot + 2 }, { x - 3, bot + 2 } }, "IRON", 2)
	if cracked then
		for i = 0, 5 do
			put(c, x - 2 + i, top + 3 + (i % 2) * 2 + i, "CRIM", 6)
		end
	end
	c.glows[#c.glows + 1] = { x, (top + bot) / 2, 10 + power * 4, 0.28 + power * 0.12 }
end

-- Chaves de latão penduradas no cinto.
local function belt_keys(c, x, y, swing)
	for i, ox in ipairs({ -7, -3, 2 }) do
		local kx = x + ox + math.floor(swing * (i % 2 == 0 and -0.5 or 0.5) + 0.5)
		thick(c, kx, y + 1, kx, y + 5, 0.5, "BRASS", 3)
		put(c, kx + 1, y + 4, "BRASS", 2)
		put(c, kx, y, "BRASS", 4)
	end
end

---------------------------------------------------------------------------
-- Fase 1: o Carcereiro (véu inteiro, lanterna na mão da frente, chave na de trás).
---------------------------------------------------------------------------
local function body1(c, p)
	local k = p.kneel or 0
	local bob = p.bob or 0
	local lean = p.lean or 0
	local sway = p.sway or 0
	local yS = FEET - 64 + bob + k * 22
	local x = X0 + (p.dx or 0)
	-- Ombreira de trás.
	ellipse(c, x - 10 + lean, yS + 3, 6, 4, "IRON", 2)
	-- Braço de trás (chave).
	if p.key then
		thick(c, x - 9 + lean, yS + 4, p.key[1], p.key[2], 2.6, "VEIL", 2)
	end
	-- Manto: dobras verticais.
	local hem = 19 + k * 8
	local function fold(px, py)
		local f = math.sin((px - sway * 0.6) * 0.62 + py * 0.035)
		if f > 0.55 then return 3 elseif f < -0.45 then return 1 end
		return 2
	end
	poly(c, { { x - 13 + lean, yS }, { x + 12 + lean, yS }, { x + hem + sway, FEET + 0.5 }, { x - hem - 2 + sway, FEET + 0.5 } }, "VEIL", fold)
	-- Barra rasgada.
	for px = x - hem - 3 + sway, x + hem + 1 + sway do
		local cut = math.floor(hash(px - math.floor(sway), 1, 7) * 4)
		for y = FEET - cut + 1, FEET do erase(c, px, y) end
	end
	-- Cinto e chaves.
	thick(c, x - 12 + lean * 0.6, yS + 23, x + 13 + lean * 0.6, yS + 23, 0.9, "IRON", 2)
	belt_keys(c, x + lean * 0.6, yS + 24, sway)
	-- Cabeça coberta pelo véu, caindo sobre os ombros.
	local hx = x + 2 + lean
	poly(c, { { hx - 8, yS - 12 }, { hx + 8, yS - 10 }, { hx + 14, yS + 7 }, { hx - 15, yS + 7 } }, "VEIL", 2)
	ellipse(c, hx, yS - 11, 8, 10, "VEIL", function(px, py, dx, dy) return (dx < -0.2 and dy < 0) and 4 or 3 end)
	-- Rosto escondido: sombra funda e um brilho carmesim atrás do véu.
	ellipse(c, hx + 5, yS - 9, 3, 5, "VEIL", 1)
	put(c, hx + 6, yS - 10, "CRIM", 3)
	-- Renda na borda do véu.
	for i = 0, 18, 2 do put(c, hx + 8 + i * 0.32, yS - 10 + i, "VEIL", 5) end
	-- Ombreira da frente.
	ellipse(c, x + 10 + lean, yS + 4, 6, 4, "IRON", 3)
	put(c, x + 10 + lean, yS + 1, "IRON", 5)
	-- Chave-lâmina (depois do corpo, para o golpe aparecer por cima).
	if p.key then
		if p.smear then smear(c, p.key[1], p.key[2], p.smear[1], p.smear[2], 18, 46) end
		key(c, p.key[1], p.key[2], p.ang, 48)
		ellipse(c, p.key[1], p.key[2], 2.6, 2.6, "IRON", 3)
	end
	if p.ground_key then
		key(c, x + 8, FEET - 2, 0.05, 44)
	end
	-- Braço da frente e lanterna.
	local lh = p.lan or { x + 11 + lean, yS + 25 }
	thick(c, x + 10 + lean, yS + 5, lh[1], lh[2], 2.6, "VEIL", 3)
	ellipse(c, lh[1], lh[2], 2.4, 2.4, "IRON", 3)
	lantern(c, lh[1], lh[2], p.swing or 0, p.power or 1, p.cracked)
end

---------------------------------------------------------------------------
-- Fase 2: o Despido (montanha de véus, espelho no lugar do rosto, lanterna fundida no peito).
---------------------------------------------------------------------------
local function body2(c, p)
	local k = p.kneel or 0
	local bob = p.bob or 0
	local lean = p.lean or 0
	local sway = p.sway or 0
	local x = X0 + (p.dx or 0)
	local yS = FEET - 58 + bob + k * 18 + (p.lift or 0)
	local feet = FEET + (p.lift or 0)
	-- Tentáculos de pano nas costas, com correntes.
	for i, t in ipairs({ { -14, -18, -26, -30 }, { -18, -6, -32, -10 }, { -10, -24, -12, -40 } }) do
		local wob = math.sin((p.t or 0) * 1.7 + i * 2) * 3
		local ax, ay = x - 6 + lean, yS + 6
		local mx, my = x + t[1] + lean, yS + t[2] + wob
		local ex, ey = x + t[3] + lean + wob, yS + t[4] + wob * 0.5
		thick(c, ax, ay, mx, my, 2.2, "VEIL", 2)
		thick(c, mx, my, ex, ey, 1.4, "VEIL", 3)
		for j = 0, 3 do
			local u = j / 4
			put(c, mx + (ex - mx) * u, my + (ey - my) * u + 1, "IRON", 4)
		end
	end
	-- Corpo curvado para a frente.
	local hem = 25 + k * 6
	local function fold(px, py)
		local f = math.sin((px - sway) * 0.5 + py * 0.08)
		if f > 0.5 then return 3 elseif f < -0.4 then return 1 end
		return 2
	end
	poly(c, { { x - 19 + lean, yS + 6 }, { x - 4 + lean, yS - 4 }, { x + 14 + lean, yS + 2 },
		{ x + hem - 2 + sway, feet + 0.5 }, { x - hem + sway, feet + 0.5 } }, "VEIL", fold)
	-- Tiras rasgadas embaixo.
	for px = x - hem - 1 + sway, x + hem + sway do
		local hgt = hash(px - math.floor(sway), 2, 11)
		local cut = hgt < 0.32 and math.floor(6 + hgt * 40) or math.floor(hgt * 3)
		for y = feet - cut + 1, feet do erase(c, px, y) end
	end
	-- Correntes penduradas da cintura.
	for _, cx in ipairs({ x - 10, x + 4 }) do
		for y = yS + 22, feet - 8 do
			if (y + cx) % 3 ~= 0 then put(c, cx + lean * 0.5 + math.sin(y * 0.3 + sway) * 1.2, y, "IRON", (y % 3 == 1) and 4 or 2) end
		end
	end
	-- Lanterna fundida no peito: rachaduras de luz atravessando o pano.
	local lx, ly = x + 2 + lean, yS + 15
	local power = p.power or 1
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2 + 0.4
		local len = 6 + hash(i, 5, 2) * 8 + power * 2
		for r = 4, len do
			local jx = math.floor(math.sin(r * 1.3 + i) + 0.5)
			put(c, lx + math.cos(a) * r + jx, ly + math.sin(a) * r, "CRIM", r > len - 2 and 3 or 4)
		end
	end
	ellipse(c, lx, ly, 5, 6, "CRIM", function(px, py, dx, dy) return (dx * dx + dy * dy < 0.35) and 6 or 4 end)
	for _, bx in ipairs({ -3, 0, 3 }) do
		for y = ly - 5, ly + 5 do
			if hash(bx, y, 9) < 0.7 then put(c, lx + bx, y, "IRON", 2) end
		end
	end
	c.glows[#c.glows + 1] = { lx, ly, 14 + power * 5, 0.32 + power * 0.14 }
	-- Braço da chave.
	if p.key then
		thick(c, x + 8 + lean, yS + 2, p.key[1], p.key[2], 2.8, "VEIL", 3)
		if p.smear then smear(c, p.key[1], p.key[2], p.smear[1], p.smear[2], 16, 50) end
		key(c, p.key[1], p.key[2], p.ang, 52)
		ellipse(c, p.key[1], p.key[2], 2.8, 2.8, "IRON", 3)
	end
	-- Segundo braço de pano, garra de ferro.
	local cl = p.claw or { x + 16 + lean, yS + 22 }
	thick(c, x - 2 + lean, yS + 6, cl[1], cl[2], 2.2, "VEIL", 2)
	for j = -1, 1 do thick(c, cl[1], cl[2], cl[1] + 4, cl[2] + j * 2 + 2, 0.6, "IRON", 4) end
	-- Cabeça: espelho oval com restos do véu em volta, refletindo uma silhueta pequena (o Noct).
	local hx, hy = x + 12 + lean, yS + 1
	ellipse(c, hx - 1, hy - 2, 9, 10, "VEIL", 2)
	ellipse(c, hx, hy, 6, 8, "MIRROR", function(px, py, dx, dy)
		local v = 3 - dy * 1.4 - dx * 0.6
		if math.abs(dx + dy * 0.6 + 0.35) < 0.18 then v = 5 end
		return math.floor(v + 0.5)
	end)
	-- A silhueta refletida e a rachadura.
	thick(c, hx + 1, hy - 2, hx + 1, hy + 4, 0.5, "MIRROR", 1)
	put(c, hx + 1, hy - 3, "MIRROR", 1)
	put(c, hx, hy, "MIRROR", 1); put(c, hx + 2, hy, "MIRROR", 1)
	for i = 0, 5 do put(c, hx - 4 + i, hy - 6 + i + (i % 2), "OUT", 1) end
	if p.eyes then
		put(c, hx - 2, hy - 1, "CRIM", 6); put(c, hx + 3, hy - 1, "CRIM", 6)
	end
end

---------------------------------------------------------------------------
-- Acabamento: luz, contorno e brilho -> Image RGBA.
---------------------------------------------------------------------------
local function render(c, extra)
	-- Luz de cima à esquerda: borda exposta clareia, borda de baixo escurece.
	local nl = {}
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local i = idx(x, y)
			local m = c.m[i]
			if m and not NOSHADE[m] and m ~= "SMEAR" then
				local l = c.l[i]
				if not get(c, x - 1, y) or not get(c, x, y - 1) then l = l + 1
				elseif not get(c, x + 1, y) or not get(c, x, y + 1) then l = l - 1 end
				nl[i] = math.max(1, math.min(#RAMPS[m], l))
			end
		end
	end
	for i, l in pairs(nl) do c.l[i] = l end
	local img = Image(W, H, ColorMode.RGB)
	img:clear(app.pixelColor.rgba(0, 0, 0, 0))
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local m = c.m[idx(x, y)]
			if m then
				img:drawPixel(x, y, COL[m][c.l[idx(x, y)]])
			else
				-- Contorno: vizinho opaco (exceto rastro).
				for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
					local n = get(c, x + d[1], y + d[2])
					if n and not NOOUT[n] then
						img:drawPixel(x, y, COL.OUT[1])
						break
					end
				end
			end
		end
	end
	-- Brilho carmesim da lanterna: tinge o que está perto e acende um halo no vazio.
	for _, g in ipairs(c.glows) do
		local gx, gy, gr, gs = g[1], g[2], g[3], g[4]
		for y = math.floor(gy - gr), math.ceil(gy + gr) do
			for x = math.floor(gx - gr), math.ceil(gx + gr) do
				if x >= 0 and y >= 0 and x < W and y < H then
					local d = math.sqrt((x - gx) ^ 2 + (y - gy) ^ 2) / gr
					if d < 1 then
						local f = (1 - d) * gs
						local px = img:getPixel(x, y)
						local a = app.pixelColor.rgbaA(px)
						local cr, cg, cb = 217, 38, 79
						if a == 0 then
							if f > 0.2 and hash(x, y, 13) < f * 0.7 then
								img:drawPixel(x, y, app.pixelColor.rgba(cr, cg, cb, math.floor(f * 255 * 0.7)))
							end
						else
							local r, gg, b = app.pixelColor.rgbaR(px), app.pixelColor.rgbaG(px), app.pixelColor.rgbaB(px)
							img:drawPixel(x, y, app.pixelColor.rgba(
								math.min(255, math.floor(r + (cr - r) * f * 0.8)),
								math.min(255, math.floor(gg + (cg - gg) * f * 0.6)),
								math.min(255, math.floor(b + (cb - b) * f * 0.6)), a))
						end
					end
				end
			end
		end
	end
	if extra then extra(img) end
	return img
end

-- Brasas carmesim subindo (rasgo do véu, morte).
local function embers(c, n, x0, x1, y0, y1, seed)
	for i = 1, n do
		local x = x0 + hash(i, seed, 21) * (x1 - x0)
		local y = y0 + hash(i, seed, 22) * (y1 - y0)
		put(c, x, y, "CRIM", hash(i, seed, 23) < 0.3 and 6 or 5)
	end
end

---------------------------------------------------------------------------
-- Poses
---------------------------------------------------------------------------
local P = math.pi
local function idle_key(yS) return { X0 - 18, yS + 26 } end

local ANIMS = {}
local ORDER = {}
local function anim(name, fps, frames)
	ANIMS[name] = { fps = fps, frames = frames }
	ORDER[#ORDER + 1] = name
end

local function yS1(bob, kneel) return FEET - 64 + (bob or 0) + (kneel or 0) * 22 end

-- Fase 1 --------------------------------------------------------------------
do
	local f = {}
	for i = 0, 3 do
		local bob = (i == 1 or i == 2) and 1 or 0
		local y = yS1(bob)
		f[#f + 1] = { body = 1, bob = bob, sway = ({ 0, 1, 0, -1 })[i + 1], swing = ({ 0, 1, 0, -1 })[i + 1],
			key = { X0 - 16, y + 27 }, ang = P * 0.42 }
	end
	anim("idle", 5, f)
end
do
	local f = {}
	for i = 0, 5 do
		local bob = ({ 0, 1, 2, 0, 1, 2 })[i + 1]
		local y = yS1(bob)
		f[#f + 1] = { body = 1, bob = bob, sway = ({ -2, -1, 1, 2, 1, -1 })[i + 1], swing = ({ -1, 0, 1, 1, 0, -1 })[i + 1],
			lean = 1, key = { X0 - 15, y + 27 }, ang = P * 0.40 }
	end
	anim("walk", 7, f)
end
do
	-- Golpe da chave: ergue atrás da cabeça (antecipação), desce na frente (quadros 3-4 machucam), recupera.
	local y = yS1(0)
	anim("attack", 11, {
		{ body = 1, lean = -1, key = { X0 - 14, y + 18 }, ang = P * 0.15 },
		{ body = 1, lean = -2, bob = -1, key = { X0 - 10, y - 2 }, ang = -P * 0.62 },
		{ body = 1, lean = -3, bob = -1, key = { X0 - 6, y - 8 }, ang = -P * 0.80, power = 1.4 },
		{ body = 1, lean = 3, key = { X0 + 18, y + 10 }, ang = -P * 0.02, smear = { -P * 0.80, -P * 0.02 } },
		{ body = 1, lean = 4, bob = 1, key = { X0 + 20, y + 18 }, ang = P * 0.22, smear = { -P * 0.3, P * 0.22 } },
		{ body = 1, lean = 2, bob = 1, key = { X0 + 14, y + 24 }, ang = P * 0.35 },
		{ body = 1, lean = 0, key = { X0 - 6, y + 26 }, ang = P * 0.40 },
	})
end
do
	-- Tranca: crava a chave no chão (quadro 4) e as correntes saem pelo chão (código).
	local y = yS1(0)
	anim("lock", 10, {
		{ body = 1, key = { X0 + 6, y + 6 }, ang = -P * 0.5 },
		{ body = 1, bob = -2, key = { X0 + 8, y - 6 }, ang = -P * 0.5, power = 1.3 },
		{ body = 1, bob = -2, key = { X0 + 8, y - 8 }, ang = -P * 0.5, power = 1.6 },
		{ body = 1, bob = 3, lean = 2, key = { X0 + 14, y + 22 }, ang = P * 0.5, smear = { P * 0.5, P * 0.5 } },
		{ body = 1, bob = 3, lean = 2, key = { X0 + 14, y + 22 }, ang = P * 0.5 },
		{ body = 1, bob = 1, lean = 1, key = { X0 + 6, y + 24 }, ang = P * 0.45 },
	})
end
do
	-- Esquecer: ergue a lanterna acima da cabeça; a tela escurece (código).
	local y = yS1(0)
	anim("raise", 8, {
		{ body = 1, key = { X0 - 16, y + 27 }, ang = P * 0.42, lan = { X0 + 14, y + 16 } },
		{ body = 1, bob = -1, key = { X0 - 16, y + 26 }, ang = P * 0.42, lan = { X0 + 14, y + 2 }, power = 1.5 },
		{ body = 1, bob = -2, key = { X0 - 16, y + 25 }, ang = P * 0.42, lan = { X0 + 12, y - 24 }, power = 2.2 },
		{ body = 1, bob = -2, key = { X0 - 16, y + 25 }, ang = P * 0.42, lan = { X0 + 12, y - 25 }, power = 2.6, swing = 1 },
		{ body = 1, bob = -1, key = { X0 - 16, y + 26 }, ang = P * 0.42, lan = { X0 + 14, y + 4 }, power = 1.5 },
	})
end
do
	-- Transição: cai de joelhos abraçando a lanterna, ela racha e o véu rasga de baixo para cima.
	local f = {}
	for i = 0, 2 do
		local kn = (i + 1) / 3
		local y = yS1(0, kn)
		f[#f + 1] = { body = 1, kneel = kn, ground_key = i >= 1, key = (i == 0) and { X0 - 12, y + 26 } or nil, ang = P * 0.5,
			lan = { X0 + 6, y + 12 }, power = 1 + i * 0.4 }
	end
	local y = yS1(0, 1)
	f[#f + 1] = { body = 1, kneel = 1, ground_key = true, lan = { X0 + 6, y + 12 }, power = 3, cracked = true }
	for i = 1, 3 do
		f[#f + 1] = { body = 1, kneel = 1, ground_key = true, lan = { X0 + 6, y + 12 }, power = 3 + i * 0.5, cracked = true, tear = i / 3 }
	end
	f[#f + 1] = { body = 2, kneel = 0.6, power = 3, eyes = true, key = { X0 + 6, FEET - 6 }, ang = P * 0.05 }
	f[#f + 1] = { body = 2, kneel = 0.2, power = 2.5, eyes = true, key = { X0 + 18, FEET - 30 }, ang = P * 0.25, t = 1 }
	anim("transform", 7, f)
end

-- Fase 2 --------------------------------------------------------------------
local function yS2(bob, kneel, lift) return FEET - 58 + (bob or 0) + (kneel or 0) * 18 + (lift or 0) end
do
	local f = {}
	for i = 0, 3 do
		local bob = ({ 0, 1, 2, 1 })[i + 1]
		local y = yS2(bob)
		f[#f + 1] = { body = 2, bob = bob, t = i, sway = ({ 0, 1, 2, 1 })[i + 1], eyes = true, power = 1.6 + (i % 2) * 0.3,
			key = { X0 + 20, y + 26 }, ang = P * 0.30 }
	end
	anim("idle2", 7, f)
end
do
	local f = {}
	for i = 0, 5 do
		local bob = ({ 0, 2, 3, 0, 2, 3 })[i + 1]
		local y = yS2(bob)
		f[#f + 1] = { body = 2, bob = bob, t = i, lean = 2, sway = ({ -3, -1, 2, 3, 1, -2 })[i + 1], eyes = true, power = 1.6,
			key = { X0 + 20, y + 26 }, ang = P * 0.28 }
	end
	anim("walk2", 10, f)
end
do
	-- Golpe duplo: dois arcos; machucam os quadros 2-3 e 5-6.
	local y = yS2(0)
	anim("attack2", 14, {
		{ body = 2, t = 0, lean = -2, eyes = true, key = { X0 + 4, y - 4 }, ang = -P * 0.7, power = 2 },
		{ body = 2, t = 1, lean = -3, eyes = true, key = { X0 + 2, y - 10 }, ang = -P * 0.85, power = 2.4 },
		{ body = 2, t = 2, lean = 4, eyes = true, key = { X0 + 24, y + 8 }, ang = 0, smear = { -P * 0.85, 0 }, power = 2.4 },
		{ body = 2, t = 3, lean = 5, eyes = true, key = { X0 + 26, y + 20 }, ang = P * 0.3, smear = { -P * 0.2, P * 0.3 }, power = 2 },
		{ body = 2, t = 4, lean = 3, eyes = true, key = { X0 + 22, y + 26 }, ang = P * 0.75, power = 2.2 },
		{ body = 2, t = 5, lean = 6, eyes = true, key = { X0 + 28, y + 14 }, ang = -P * 0.08, smear = { P * 0.75, P * 1.92 }, dx = 4, power = 2.6 },
		{ body = 2, t = 6, lean = 6, eyes = true, key = { X0 + 30, y + 6 }, ang = -P * 0.25, smear = { -P * 0.08, -P * 0.25 }, dx = 6, power = 2.2 },
		{ body = 2, t = 7, lean = 2, eyes = true, key = { X0 + 20, y + 24 }, ang = P * 0.3, dx = 3, power = 1.8 },
	})
end
do
	-- Salto do carcereiro: agacha, sobe, cai e esmaga (quadro 4 = impacto).
	local y = yS2(0)
	anim("leap", 10, {
		{ body = 2, t = 0, kneel = 0.6, eyes = true, key = { X0 + 18, yS2(0, 0.6) + 26 }, ang = P * 0.4, power = 2 },
		{ body = 2, t = 1, lift = -10, eyes = true, key = { X0 + 10, yS2(0, 0, -10) + 4 }, ang = -P * 0.35, power = 2.4 },
		{ body = 2, t = 2, lift = -14, eyes = true, key = { X0 + 10, yS2(0, 0, -14) + 4 }, ang = -P * 0.28, power = 2.6 },
		{ body = 2, t = 3, lift = -8, eyes = true, key = { X0 + 22, yS2(0, 0, -8) + 10 }, ang = P * 0.25, smear = { -P * 0.4, P * 0.25 }, power = 2.6 },
		{ body = 2, t = 4, kneel = 0.8, eyes = true, key = { X0 + 26, FEET - 6 }, ang = P * 0.05, power = 3 },
		{ body = 2, t = 5, kneel = 0.4, eyes = true, key = { X0 + 22, yS2(0, 0.4) + 24 }, ang = P * 0.3, power = 2 },
	})
end
do
	-- Rugido: abre os braços e o peito acende (chuva de gaiolas e maré carmesim saem no quadro 3).
	local y = yS2(0)
	anim("roar", 9, {
		{ body = 2, t = 0, kneel = 0.3, eyes = true, key = { X0 + 18, yS2(0, 0.3) + 24 }, ang = P * 0.35, power = 2 },
		{ body = 2, t = 1, bob = -2, lean = -2, eyes = true, key = { X0 + 26, y + 2 }, ang = -P * 0.25, claw = { X0 - 4, y - 8 }, power = 3 },
		{ body = 2, t = 2, bob = -3, lean = -3, eyes = true, key = { X0 + 28, y }, ang = -P * 0.3, claw = { X0 - 8, y - 12 }, power = 4 },
		{ body = 2, t = 3, bob = -3, lean = -3, eyes = true, key = { X0 + 28, y - 1 }, ang = -P * 0.3, claw = { X0 - 8, y - 13 }, power = 4.5 },
		{ body = 2, t = 4, bob = -1, lean = -1, eyes = true, key = { X0 + 24, y + 14 }, ang = P * 0.1, power = 3 },
		{ body = 2, t = 5, eyes = true, key = { X0 + 20, y + 26 }, ang = P * 0.3, power = 2 },
	})
end
do
	-- Morte: ajoelha, abre o peito com as mãos e se desfaz em brasas; sobra só uma fita de luz.
	local f = {}
	for i = 0, 2 do
		local kn = 0.4 + i * 0.3
		f[#f + 1] = { body = 2, t = i, kneel = kn, eyes = i < 2, ground_key = false, power = 2 + i,
			claw = { X0 + 4, yS2(0, kn) + 12 } }
	end
	for i = 1, 6 do
		f[#f + 1] = { body = 2, t = 3, kneel = 1, power = 4 + i * 0.5, claw = { X0 + 4, yS2(0, 1) + 12 }, dissolve = i / 6 }
	end
	f[#f + 1] = { ribbon = true }
	anim("death", 8, f)
end

---------------------------------------------------------------------------
-- Montagem
---------------------------------------------------------------------------
local function draw_frame(p, frame_index)
	local c = canvas()
	if p.ribbon then
		-- Só a fita de luz subindo (a memória liberada).
		for y = FEET - 76, FEET - 20 do
			local x = X0 + 4 + math.sin(y * 0.18) * 6
			put(c, x, y, "CRIM", (y % 5 == 0) and 6 or 5)
			put(c, x + 1, y, "CRIM", 4)
		end
		c.glows[#c.glows + 1] = { X0 + 4, FEET - 46, 22, 0.35 }
		return render(c)
	end
	if p.body == 2 then body2(c, p) else body1(c, p) end
	if p.tear then
		-- O véu rasga de baixo para cima: some uma faixa irregular e brasas marcam a borda.
		local cutoff = FEET - p.tear * 60
		for y = math.floor(cutoff), FEET do
			for x = 0, W - 1 do
				local m = get(c, x, y)
				if m == "VEIL" and hash(x, y, 31) < 0.55 + p.tear * 0.3 then
					c.m[idx(x, y)] = "CRIM"; c.l[idx(x, y)] = (hash(x, y, 32) < 0.06) and 4 or ((hash(x, y, 33) < 0.4) and 2 or 1)
				end
			end
		end
		embers(c, 30, X0 - 26, X0 + 26, cutoff - 12, cutoff + 4, frame_index)
	end
	if p.dissolve then
		-- Desfaz de cima para baixo em brasas.
		local front = 20 + p.dissolve * (FEET - 10)
		for y = 0, H - 1 do
			for x = 0, W - 1 do
				if get(c, x, y) and y < front + hash(x, 0, 41) * 10 then
					if hash(x, y, 42 + frame_index) < 0.06 then
						c.m[idx(x, y)] = "CRIM"; c.l[idx(x, y)] = 5
					else
						erase(c, x, y)
					end
				end
			end
		end
		embers(c, 40, X0 - 30, X0 + 30, math.max(4, front - 40), front, frame_index)
		for y = math.max(4, math.floor(front - 50)), math.floor(front) do
			local x = X0 + 4 + math.sin(y * 0.18) * 6
			put(c, x, y, "CRIM", 5)
		end
	end
	return render(c)
end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "velario"
local total = 0
local images = {}
for _, name in ipairs(ORDER) do
	local a = ANIMS[name]
	local strip = Image(W * #a.frames, H, ColorMode.RGB)
	strip:clear(app.pixelColor.rgba(0, 0, 0, 0))
	local first = total + 1
	for i, p in ipairs(a.frames) do
		local img = draw_frame(p, i)
		strip:drawImage(img, Point((i - 1) * W, 0))
		total = total + 1
		if total > 1 then spr:newEmptyFrame() end
		spr:newCel(spr.layers[1], total, img, Point(0, 0))
		spr.frames[total].duration = 1 / a.fps
	end
	local tag = spr:newTag(first, total)
	tag.name = name
	strip:saveAs(OUT .. name .. ".png")
	images[#images + 1] = name
end
spr:saveAs(SRC)
spr:close()
print("velario: " .. total .. " quadros em " .. #images .. " animações")
