-- Mente do Noct: arena da fase 2 do Bringer of Death (a luta acontece dentro da cabeça de Noct).
-- Gera no Aseprite as fontes (art_source/cenarios_novos/mente_do_noct_*.aseprite) e as imagens do jogo
-- (assets/areas/mente_do_noct/). Paleta: a do portal e da parede carmesim (art_source/vfx/).
-- Rodar na raiz do projeto:
--   Aseprite.exe -b --script tools/make_mind.lua
-- Depois dá para retocar os .aseprite à mão e exportar de novo cada um como PNG (Arquivo > Exportar).

local SRC = "art_source/cenarios_novos/"
local OUT = "assets/areas/mente_do_noct/"
app.fs.makeAllDirectories(OUT)

-- Paleta carmesim, do mais escuro ao mais claro.
local HEX = {
	"#0e0207", "#12050d", "#1a050d", "#2c0b16", "#3a0a1d", "#4a1626", "#5a0b22", "#6e0d2a",
	"#9c1238", "#b3173f", "#d9264f", "#e52d5e", "#ff6f96", "#ff7ea3", "#ffd0dd", "#ffd9e4",
}
local C = {}
for i, h in ipairs(HEX) do
	C[i] = app.pixelColor.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255)
end
local CLEAR = app.pixelColor.rgba(0, 0, 0, 0)

-- Ruído determinístico (a arte sai igual toda vez que o script roda).
local function hash(x, y, s)
	local n = x * 374761393 + y * 668265263 + s * 1442695041
	n = (n ~ (n >> 13)) * 1274126177
	n = n ~ (n >> 16)
	return (n & 0xffff) / 65535
end

local function smooth(t) return t * t * (3 - 2 * t) end

-- Ruído suave; com `period` ele se repete (para os tiles emendarem).
local function vnoise(x, y, cell, seed, period)
	local gx, gy = x / cell, y / cell
	local x0, y0 = math.floor(gx), math.floor(gy)
	local fx, fy = smooth(gx - x0), smooth(gy - y0)
	local function h(ix, iy)
		if period then ix, iy = ix % period, iy % period end
		return hash(ix, iy, seed)
	end
	local a = h(x0, y0) + (h(x0 + 1, y0) - h(x0, y0)) * fx
	local b = h(x0, y0 + 1) + (h(x0 + 1, y0 + 1) - h(x0, y0 + 1)) * fx
	return a + (b - a) * fy
end

local BAYER = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }
local function bayer(x, y) return (BAYER[y % 4 + 1][x % 4 + 1] + 0.5) / 16 end

-- Valor 0..1 numa rampa de índices da paleta, com pontilhado ordenado entre os degraus.
local function ramp(ids, v, x, y)
	v = math.max(0, math.min(0.9999, v))
	local f = v * (#ids - 1)
	local i = math.floor(f)
	if f - i > bayer(x, y) then i = i + 1 end
	return C[ids[math.min(i + 1, #ids)]]
end

local function new_sprite(w, h)
	local spr = Sprite(w, h, ColorMode.RGB)
	local pal = Palette(#C)
	for i, h2 in ipairs(HEX) do pal:setColor(i - 1, Color(app.pixelColor.rgbaR(C[i]), app.pixelColor.rgbaG(C[i]), app.pixelColor.rgbaB(C[i]))) end
	spr:setPalette(pal)
	return spr
end

local function layer_image(spr, name, first)
	local layer = first and spr.layers[1] or spr:newLayer()
	layer.name = name
	local img = Image(spr.width, spr.height, ColorMode.RGB)
	img:clear(CLEAR)
	return layer, img
end

local function put(img, x, y, c)
	if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end

local function finish(spr, layers, aseprite, png)
	for _, l in ipairs(layers) do spr:newCel(l[1], 1, l[2], Point(0, 0)) end
	spr:saveAs(aseprite)
	spr:saveCopyAs(png)
	spr:close()
end

---------------------------------------------------------------------------
-- 1) Tileset 8x3 tiles de 16 px: "matéria de pensamento" (pedra escura com veias carmesim).
--    Bloco 3x3 nas colunas 0-2, isolado em (3,2), variações de meio em (3,1)/(4,1) e de topo em (4,2).
---------------------------------------------------------------------------
local T = 16
-- Centros das células de cada variação {x, y, borda acesa?}.
local CELLS = {
	[0] = { { 3, 3, false }, { 11, 2, true }, { 7, 9, false }, { 1, 12, true }, { 13, 11, false } },
	[1] = { { 4, 2, true }, { 12, 5, false }, { 6, 10, true }, { 14, 13, false }, { 1, 7, false } },
	[2] = { { 2, 4, false }, { 9, 3, true }, { 12, 10, true }, { 5, 12, false }, { 15, 1, false } },
}
local function draw_piece(img, col, row, up, down, left, right, kind)
	local ox, oy = col * T, row * T
	for y = 0, T - 1 do
		for x = 0, T - 1 do
			-- Massa: células (como neurônios empedrados) que se repetem a cada tile.
			local pts = CELLS[kind == "spark" and (col - 2) or 0]
			local d1, d2, near = 99, 99, nil
			for _, p in ipairs(pts) do
				local dx = math.abs(x - p[1]); dx = math.min(dx, T - dx)
				local dy = math.abs(y - p[2]); dy = math.min(dy, T - dy)
				local d = math.sqrt(dx * dx + dy * dy)
				if d < d1 then d1, d2, near = d, d1, p elseif d < d2 then d2 = d end
			end
			local border = d2 - d1
			-- Luz vinda de cima à esquerda dentro de cada célula.
			local lit = ((near[1] - x) + (near[2] - y)) / 10
			local c = ramp({ 3, 4, 5, 6 }, 0.35 + lit - d1 / 14, x, y)
			if border < 1.0 then
				c = near[3] and C[7] or C[2]
				if kind == "spark" and near[3] then c = (border < 0.5) and C[13] or C[11] end
			end
			-- Bordas expostas ao ar.
			local edge = 99
			if up then edge = math.min(edge, y) end
			if left then edge = math.min(edge, x) end
			if right then edge = math.min(edge, T - 1 - x) end
			if up and y <= 3 then
				local top = { C[14], C[12], C[9], C[7] }
				c = top[y + 1]
				if y == 0 and hash(x + col * 16, 0, 5) < 0.25 then c = C[16] end
			elseif (left and x <= 1) or (right and x >= T - 2) then
				c = (math.min(x, T - 1 - x) == 0) and C[7] or C[5]
			elseif down and y >= T - 2 then
				c = (y == T - 1) and C[1] or C[3]
			end
			-- Cantos arredondados quando dois lados estão expostos.
			local cx = left and x or (right and T - 1 - x or 99)
			local cy = up and y or (down and T - 1 - y or 99)
			if cx + cy <= 1 then c = CLEAR
			elseif cx + cy == 2 and up and cy <= 1 then c = C[12] end
			img:drawPixel(ox + x, oy + y, c)
		end
	end
	-- Topo especial: um olho de fenda entreaberto na superfície (pensamento acordando).
	if kind == "eye" then
		local pts = { { 5, 6, 12 }, { 6, 5, 12 }, { 7, 5, 13 }, { 8, 5, 13 }, { 9, 5, 12 }, { 10, 6, 12 },
			{ 6, 7, 11 }, { 7, 7, 9 }, { 8, 7, 9 }, { 9, 7, 11 }, { 7, 6, 16 }, { 8, 6, 15 } }
		for _, p in ipairs(pts) do img:drawPixel(ox + p[1], oy + p[2], C[p[3]]) end
	end
end

do
	local spr = new_sprite(8 * T, 3 * T)
	local layer, img = layer_image(spr, "tiles", true)
	for row = 0, 2 do
		for col = 0, 2 do
			draw_piece(img, col, row, row == 0, row == 2, col == 0, col == 2)
		end
	end
	draw_piece(img, 3, 2, true, true, true, true)
	draw_piece(img, 3, 1, false, false, false, false, "spark")
	draw_piece(img, 4, 1, false, false, false, false, "spark")
	draw_piece(img, 4, 2, true, false, false, false, "eye")
	finish(spr, { { layer, img } }, SRC .. "mente_do_noct_tileset.aseprite", OUT .. "tileset.png")
end

---------------------------------------------------------------------------
-- 2) Fundo distante (480x270, cobre a tela): o vazio da cabeça de Noct, um redemoinho de energia
--    em volta da Fenda e sinapses carmesim acendendo.
---------------------------------------------------------------------------
local W, H = 480, 270
local CX, CY = 240, 118

do
	local spr = new_sprite(W, H)
	local sky_l, sky = layer_image(spr, "vazio", true)
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local dx, dy = x - CX, (y - CY) * 1.35
			local d = math.sqrt(dx * dx + dy * dy)
			local ang = math.atan(dy, dx)
			local v = 0.06 + 0.22 * (y / H) ^ 1.6
			local swirl = 0.5 + 0.5 * math.sin(d * 0.085 - ang * 3 + vnoise(x, y, 40, 3) * 4)
			local fall = math.max(0, 1 - d / 260)
			v = v + swirl * 0.42 * fall * fall + vnoise(x, y, 28, 4) * 0.12 + fall ^ 3 * 0.25
			sky:drawPixel(x, y, ramp({ 2, 3, 4, 5, 6, 7, 8 }, v, x, y))
		end
	end

	-- Sinapses: filamentos que saem da Fenda e acendem nas pontas.
	local syn_l, syn = layer_image(spr, "sinapses")
	math.randomseed(7)
	for i = 1, 22 do
		local a = (i / 22) * math.pi * 2 + math.random() * 0.4
		local r = 14 + math.random() * 10
		local x, y = CX + math.cos(a) * r, CY + math.sin(a) * r * 0.75
		local len = 50 + math.random(0, 140)
		for s = 1, len do
			a = a + (math.random() - 0.5) * 0.35
			x, y = x + math.cos(a), y + math.sin(a) * 0.8
			local c = (s % 9 == 0) and C[11] or C[8]
			if s > len * 0.6 then c = C[7] end
			put(syn, math.floor(x), math.floor(y), c)
			-- Galhos curtos.
			if math.random() < 0.025 then
				local bx, by, ba = x, y, a + (math.random() < 0.5 and 0.9 or -0.9)
				for _ = 1, math.random(6, 18) do
					bx, by = bx + math.cos(ba), by + math.sin(ba) * 0.8
					put(syn, math.floor(bx), math.floor(by), C[7])
				end
				put(syn, math.floor(bx), math.floor(by), C[12])
			end
		end
		local nx, ny = math.floor(x), math.floor(y)
		for _, p in ipairs({ { 0, -1 }, { -1, 0 }, { 1, 0 }, { 0, 1 } }) do put(syn, nx + p[1], ny + p[2], C[11]) end
		put(syn, nx, ny, C[15])
	end
	-- Fagulhas paradas (as que sobem são desenhadas no jogo, game/world/motes.gd).
	for i = 1, 160 do
		local x, y = math.random(0, W - 1), math.random(0, H - 1)
		put(syn, x, y, (i % 5 == 0) and C[13] or C[9])
	end

	-- A Fenda: uma rachadura vertical que respira luz no meio do pensamento.
	local rift_l, rift = layer_image(spr, "fenda")
	local top, bottom = 18, 226
	for y = top, bottom do
		local t = (y - top) / (bottom - top)
		local half = math.sin(t * math.pi) ^ 0.8 * 3.5 + 0.5
		local cx = CX + (vnoise(0, y, 14, 9) - 0.5) * 18 + math.sin(y * 0.11) * 2
		for x = math.floor(cx - half - 8), math.floor(cx + half + 8) do
			local d = math.abs(x + 0.5 - cx)
			local c
			if d < half * 0.35 then c = C[16]
			elseif d < half * 0.7 then c = C[15]
			elseif d < half then c = C[13]
			elseif d < half + 2 then c = C[12]
			elseif d < half + 5 and bayer(x, y) < 0.6 then c = C[9]
			elseif d < half + 8 and bayer(x, y) < 0.25 then c = C[8]
			end
			if c then put(rift, x, y, c) end
		end
	end
	finish(spr, { { sky_l, sky }, { syn_l, syn }, { rift_l, rift } },
		SRC .. "mente_do_noct_fundo.aseprite", OUT .. "fundo.png")
end

---------------------------------------------------------------------------
-- 3) Ecos (camada mais perto, transparente, repete na horizontal): ilhas soltas com pedaços da vida
--    de Noct: o banco da estação com o lado esquerdo vazio, a porta que Mira fechou, o poste da
--    estação e a fita carmesim atravessando tudo.
---------------------------------------------------------------------------
do
	local spr = new_sprite(W, H)
	local isl_l, isl = layer_image(spr, "ilhas", true)

	-- Ilha: topo achatado, base em ponta irregular, borda de cima acesa.
	local function island(cx, ty, hw, depth, seed)
		for x = cx - hw, cx + hw do
			local k = (x - cx) / hw
			local top = ty + math.floor((k * k) * 3 + (vnoise(x, 0, 5, seed) - 0.5) * 2)
			local bot = ty + math.floor(depth * (1 - math.abs(k)) ^ 1.4 + 3 + vnoise(x, 1, 4, seed + 1) * 6)
			for y = top, bot do
				local c
				local dy = y - top
				if dy == 0 then c = (hash(x, y, seed) < 0.3) and C[14] or C[12]
				elseif dy == 1 then c = C[9]
				elseif dy == 2 then c = C[7]
				else
					local v = 0.55 - (y - top) / (depth + 6) * 0.5 + vnoise(x, y, 4, seed + 2) * 0.25
					c = ramp({ 2, 3, 4, 5, 6 }, v, x, y)
					if math.abs(vnoise(x, y, 5, seed + 3) - 0.5) < 0.03 then c = C[8] end
				end
				put(isl, x, y, c)
			end
		end
		-- Gotas de energia pingando da ponta.
		for i = 0, 2 do
			local x = cx + (i - 1) * math.floor(hw / 4)
			local y0 = ty + math.floor(depth * (1 - math.abs((x - cx) / hw)) ^ 1.4) + 6
			for y = y0, y0 + 2 + i do put(isl, x, y, C[9]) end
			put(isl, x, y0 + 4 + i, C[12])
		end
	end

	island(84, 168, 46, 34, 31)
	island(250, 88, 30, 26, 41)
	island(398, 150, 40, 30, 51)

	local obj_l, obj = layer_image(spr, "objetos")
	local function rect(x0, y0, x1, y1, c)
		for y = y0, y1 do for x = x0, x1 do put(obj, x, y, c) end end
	end

	-- Banco da estação (ilha da esquerda). Noct à direita; o lado esquerdo vazio, só um contorno aceso.
	do
		local by = 167   -- linha do chão da ilha
		rect(60, by - 9, 108, by - 8, C[6])        -- assento
		rect(60, by - 10, 108, by - 10, C[9])       -- borda do assento
		rect(60, by - 20, 108, by - 19, C[6])       -- encosto
		rect(60, by - 21, 108, by - 21, C[9])
		for _, lx in ipairs({ 63, 84, 105 }) do rect(lx, by - 18, lx + 1, by - 1, C[5]) end
		-- Lugar vazio: o contorno pontilhado de quem sentava ali (o espelho de Noct).
		local function noct_shape(x, y)
			return (x >= 92 and x <= 97 and y >= by - 30 and y <= by - 25) or (x >= 91 and x <= 98 and y >= by - 24 and y <= by - 11)
				or (x >= 96 and x <= 104 and y >= by - 10 and y <= by - 8) or (x >= 102 and x <= 104 and y >= by - 7 and y <= by - 1)
		end
		local function ghost(x, y) return noct_shape(168 - x, y) end
		for y = by - 31, by do
			for x = 60, 80 do
				if ghost(x, y) and not (ghost(x - 1, y) and ghost(x + 1, y) and ghost(x, y - 1) and ghost(x, y + 1)) and (x + y) % 2 == 0 then
					put(obj, x, y, (hash(x, y, 3) < 0.3) and C[15] or C[12])
				end
			end
		end
		-- Noct sentado à direita: silhueta escura.
		rect(92, by - 30, 97, by - 25, C[2])        -- cabeça
		rect(91, by - 24, 98, by - 11, C[2])        -- tronco
		rect(96, by - 10, 104, by - 8, C[2])        -- coxa
		rect(102, by - 7, 104, by - 1, C[2])        -- perna
		put(obj, 91, by - 14, C[11])                -- a fita no pulso
		put(obj, 92, by - 14, C[13])
	end

	-- A porta (ilha do meio): moldura de pedra e luz carmesim vazando pela fresta.
	do
		local fy = 87
		rect(238, fy - 40, 262, fy - 1, C[5])       -- moldura
		rect(241, fy - 37, 259, fy - 1, C[2])       -- vão escuro
		rect(238, fy - 41, 262, fy - 41, C[9])
		for y = fy - 36, fy - 1 do                  -- fresta acesa
			put(obj, 250, y, C[16])
			put(obj, 249, y, C[13])
			put(obj, 251, y, C[12])
			if bayer(248, y) < 0.5 then put(obj, 248, y, C[9]) end
			if bayer(252, y) < 0.5 then put(obj, 252, y, C[9]) end
		end
		for x = 242, 258 do                          -- luz escorrendo por baixo
			if math.abs(x - 250) < 7 then put(obj, x, fy, C[12]) end
		end
	end

	-- Poste da estação (ilha da direita), lâmpada carmesim.
	do
		local py = 149
		rect(410, py - 44, 411, py - 1, C[5])
		rect(406, py - 2, 415, py - 1, C[6])
		rect(405, py - 46, 414, py - 45, C[6])
		rect(404, py - 44, 406, py - 41, C[13])
		put(obj, 405, py - 43, C[16])
		for i = 1, 5 do put(obj, 405 + (i % 2), py - 40 + i * 2, C[9]) end
	end

	-- Fita carmesim atravessando a camada (emenda nas bordas: seno com período da largura).
	local rib_l, rib = layer_image(spr, "fita")
	for x = 0, W - 1 do
		local y = 128 + math.sin(x / W * math.pi * 2 * 2) * 26 + math.sin(x / W * math.pi * 2 * 5) * 6
		local yi = math.floor(y)
		local twist = math.abs(math.cos(x / W * math.pi * 2 * 6))
		if not (x > 52 and x < 118 and yi > 140) and not (x > 232 and x < 268 and yi > 40 and yi < 92)
			and not (x > 395 and x < 420 and yi > 95) then
			put(rib, x, yi, (twist > 0.6) and C[13] or C[11])
			if twist > 0.3 then put(rib, x, yi + 1, C[10]) end
			if twist > 0.75 then put(rib, x, yi + 2, C[8]) end
		end
	end
	finish(spr, { { isl_l, isl }, { obj_l, obj }, { rib_l, rib } },
		SRC .. "mente_do_noct_ecos.aseprite", OUT .. "ecos.png")
end
