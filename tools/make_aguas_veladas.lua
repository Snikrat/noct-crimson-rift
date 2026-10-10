-- Águas Veladas: Capela da Vigília e Penhasco da Chuva Eterna (docs/expansao_forma_demoniaca.md, 1.3 e 1.4).
-- Gera no Aseprite as fontes (art_source/cenarios_novos/capela_da_vigilia_*.aseprite e penhasco_da_chuva_*.aseprite)
-- e as imagens do jogo (assets/areas/capela_da_vigilia/ e assets/areas/penhasco_da_chuva/): tileset 8x3 no formato
-- autotile, fundo (fundo.png) e objetos de cenário ("props" das salas).
-- Rodar na raiz do projeto:
--   Aseprite.exe -b --script tools/make_aguas_veladas.lua
-- Depois dá para retocar os .aseprite à mão e exportar de novo cada um como PNG (Arquivo > Exportar).

local SRC = "art_source/cenarios_novos/"
local CHAPEL = "assets/areas/capela_da_vigilia/"
local CLIFF = "assets/areas/penhasco_da_chuva/"
app.fs.makeAllDirectories(SRC)
app.fs.makeAllDirectories(CHAPEL)
app.fs.makeAllDirectories(CLIFF)

local function rgb(h, a)
	return app.pixelColor.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), a or 255)
end
local function list(hexes)
	local out = {}
	for i, h in ipairs(hexes) do out[i] = rgb(h) end
	return out
end
local CLEAR = app.pixelColor.rgba(0, 0, 0, 0)

-- Capela: pedra gótica fria (quase preta), vidro dos vitrais, cera das velas e a única chama.
local S = list({ "#06070c", "#0b0e17", "#111623", "#182032", "#212a40", "#2c3852", "#3b4965", "#55647e", "#7a88a0" })
local GLASS = {
	{ rgb("#5e1a28"), rgb("#9c3242"), rgb("#c95a63") },   -- vermelho
	{ rgb("#1c3a66"), rgb("#346aa8"), rgb("#62a0d8") },   -- azul
	{ rgb("#7a5a1e"), rgb("#bf9338"), rgb("#e6c66a") },   -- ouro
	{ rgb("#24503f"), rgb("#3f8462"), rgb("#6fb88e") },   -- verde
	{ rgb("#3a2560"), rgb("#64459a"), rgb("#9479c8") },   -- violeta
}
local WAX = list({ "#2a2b31", "#43444b", "#62626a", "#85837f", "#a8a397" })
local FLAME = list({ "#5a2a12", "#b8521e", "#e88a2e", "#ffc65a", "#fff0bf", "#fffbe8" })
local WOOD = list({ "#0f0b0a", "#1a1311", "#271c17", "#382820", "#4d382b" })
local WATER = list({ "#04080e", "#07101a", "#0b1826", "#102134", "#182c42" })

-- Penhasco: rocha molhada, musgo frio, ferrugem dos trilhos, metal, céu fechado e o lago lá embaixo.
local R = list({ "#05070b", "#0a0e15", "#10161f", "#17202c", "#202b3a", "#2a3749", "#38485e", "#506279", "#7387a0", "#a8bccf" })
local MOSS = list({ "#16231f", "#22352d", "#30493c" })
local RUST = list({ "#1e100c", "#3a1e14", "#5c301c", "#83482a", "#a8653a" })
local METAL = list({ "#15181e", "#262b34", "#3c434f", "#5c6572", "#8a94a2" })
local PAINT = list({ "#12252a", "#1d3a40", "#2b5359", "#3e6f72" })
local SKY = list({ "#080b11", "#0d1119", "#131924", "#1a2230", "#222c3b", "#2c3747", "#374354", "#465265", "#5a6679" })
local LAKE = list({ "#0c141e", "#132030", "#1b2c40", "#263a52", "#344b66", "#4a6380" })

-- Ruído determinístico (a arte sai igual toda vez que o script roda).
local function hash(x, y, s)
	local n = x * 374761393 + y * 668265263 + s * 1442695041
	n = (n ~ (n >> 13)) * 1274126177
	n = n ~ (n >> 16)
	return (n & 0xffff) / 65535
end

local function smooth(t) return t * t * (3 - 2 * t) end

-- Ruído suave; com `period` (em células) ele se repete (para os tiles emendarem).
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

-- Valor 0..1 numa rampa de cores, com pontilhado ordenado entre os degraus.
local function ramp(cols, v, x, y)
	v = math.max(0, math.min(0.9999, v))
	local f = v * (#cols - 1)
	local i = math.floor(f)
	if f - i > bayer(x, y) then i = i + 1 end
	return cols[math.min(i + 1, #cols)]
end

local function with_alpha(c, a)
	return app.pixelColor.rgba(app.pixelColor.rgbaR(c), app.pixelColor.rgbaG(c), app.pixelColor.rgbaB(c), a)
end

local function new_sprite(w, h, palettes)
	local spr = Sprite(w, h, ColorMode.RGB)
	local all = {}
	for _, p in ipairs(palettes) do for _, c in ipairs(p) do all[#all + 1] = c end end
	local pal = Palette(#all)
	for i, c in ipairs(all) do
		pal:setColor(i - 1, Color(app.pixelColor.rgbaR(c), app.pixelColor.rgbaG(c), app.pixelColor.rgbaB(c)))
	end
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
	x, y = math.floor(x), math.floor(y)
	if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end

local function get(img, x, y)
	if x >= 0 and y >= 0 and x < img.width and y < img.height then return img:getPixel(x, y) end
	return CLEAR
end

local function rect(img, x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

local function line(img, x0, y0, x1, y1, c)
	local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0), 1)
	for i = 0, n do put(img, x0 + (x1 - x0) * i / n + 0.5, y0 + (y1 - y0) * i / n + 0.5, c) end
end

-- Linha por uma lista de pontos {x, y}.
local function polyline(img, pts, c, dx, dy)
	for i = 1, #pts - 1 do
		line(img, pts[i][1] + (dx or 0), pts[i][2] + (dy or 0), pts[i + 1][1] + (dx or 0), pts[i + 1][2] + (dy or 0), c)
	end
end

local function finish(spr, layers, aseprite, png)
	for _, l in ipairs(layers) do spr:newCel(l[1], 1, l[2], Point(0, 0)) end
	spr:saveAs(aseprite)
	spr:saveCopyAs(png)
	spr:close()
end

-- Objeto de cenário numa camada só.
local function prop(w, h, palettes, name, src, out, draw)
	local spr = new_sprite(w, h, palettes)
	local layer, img = layer_image(spr, name, true)
	draw(img, w, h)
	finish(spr, { { layer, img } }, src, out)
end

---------------------------------------------------------------------------
-- Tileset 8x3 tiles de 16 px no formato autotile (game/world/room_view.gd): bloco 3x3 nas colunas 0-2,
-- isolado em (3,2), variações de meio em (3,1)/(4,1) e de topo em (4,2). Opcional: espinho em (5,1).
---------------------------------------------------------------------------
local T = 16
local function make_tileset(mat, palettes, src, out)
	local spr = new_sprite(8 * T, 3 * T, palettes)
	local layer, img = layer_image(spr, "tiles", true)
	local function piece(col, row, up, down, left, right, kind)
		local ox, oy = col * T, row * T
		for y = 0, T - 1 do
			for x = 0, T - 1 do
				local c = mat.fill(x, y, kind)
				if up and y < mat.top_h then c = mat.top(x, y, kind)
				elseif left and x <= 1 then c = mat.left(x, y)
				elseif right and x >= T - 2 then c = mat.right(T - 1 - x, y)
				elseif down and y >= T - 2 then c = mat.bottom(T - 1 - y, x)
				end
				-- Cantos cortados quando dois lados estão expostos.
				local cx = left and x or (right and T - 1 - x or 99)
				local cy = up and y or (down and T - 1 - y or 99)
				if cx + cy <= 1 then c = CLEAR end
				img:drawPixel(ox + x, oy + y, c)
			end
		end
		if mat.extra then mat.extra(img, ox, oy, kind) end
	end
	for row = 0, 2 do
		for col = 0, 2 do
			piece(col, row, row == 0, row == 2, col == 0, col == 2)
		end
	end
	piece(3, 2, true, true, true, true)
	piece(3, 1, false, false, false, false, "var1")
	piece(4, 1, false, false, false, false, "var2")
	piece(4, 2, true, false, false, false, "top2")
	if mat.spike then mat.spike(img, 5 * T, 1 * T) end
	finish(spr, { { layer, img } }, src, out)
end

-- Capela: cantaria gótica (blocos 16x8 desencontrados), tampa de laje no topo.
local chapel_mat = {
	top_h = 4,
	fill = function(x, y)
		local r = y // 8
		local off = (r % 2) * 8
		local bx, by = (x + off) % 16, y % 8
		if by == 7 or bx == 15 then return S[2] end
		local v = 0.42 + (hash(r, 0, 11) - 0.5) * 0.2
		if by == 0 or bx == 0 then v = v + 0.22 elseif by == 6 or bx == 14 then v = v - 0.2 end
		v = v + (vnoise(x, y, 4, 12, 4) - 0.5) * 0.3
		if hash(x, y, 13) < 0.04 then v = v - 0.25 end
		return ramp({ S[3], S[4], S[5], S[6] }, v, x, y)
	end,
	top = function(x, y, kind)
		if y == 0 then return (hash(x, 0, 14) < 0.2) and S[9] or S[8] end
		if y == 1 then return S[7] end
		if y == 2 then return (hash(x, 2, 15) < 0.3) and S[5] or S[6] end
		return S[2]
	end,
	left = function(x) return x == 0 and S[7] or S[6] end,
	right = function(d) return d == 0 and S[1] or S[3] end,
	bottom = function(d) return d == 0 and S[1] or S[2] end,
	extra = function(img, ox, oy, kind)
		if kind == "var1" then
			-- Rachadura atravessando a pedra.
			local pts = { { 4, 0 }, { 6, 3 }, { 5, 6 }, { 8, 8 }, { 9, 11 }, { 12, 13 }, { 12, 15 } }
			polyline(img, pts, S[1], ox, oy)
			polyline(img, pts, S[6], ox + 1, oy)
		elseif kind == "var2" then
			-- Nicho votivo com uma vela apagada (as centenas de velas).
			for y = 3, 12 do
				local hw = (y < 6) and (y - 3) or 3
				for x = 8 - hw, 7 + hw do img:drawPixel(ox + x, oy + y, S[1]) end
			end
			for y = 4, 12 do img:drawPixel(ox + 8 + ((y < 6) and (y - 4) or 4), oy + y, S[6]) end
			rect(img, ox + 7, oy + 9, ox + 8, oy + 12, WAX[3])
			img:drawPixel(ox + 7, oy + 9, WAX[4])
			img:drawPixel(ox + 7, oy + 8, WAX[1])
			rect(img, ox + 4, oy + 13, ox + 11, oy + 13, S[7])
		elseif kind == "top2" then
			-- Cera escorrida pela borda da laje.
			for _, d in ipairs({ { 3, 4 }, { 4, 6 }, { 9, 3 }, { 12, 5 } }) do
				for y = 0, d[2] do img:drawPixel(ox + d[1], oy + y, (y == 0) and WAX[5] or WAX[4]) end
				img:drawPixel(ox + d[1], oy + d[2] + 1, WAX[3])
			end
			rect(img, ox + 2, oy, ox + 5, oy, WAX[5])
			rect(img, ox + 8, oy, ox + 13, oy, WAX[5])
		end
	end,
}

-- Penhasco: rocha molhada em camadas, brilho de água no topo e musgo frio.
local cliff_mat = {
	top_h = 4,
	fill = function(x, y, kind)
		local n = vnoise(x, y, 8, 21, 2)
		local v = 0.45 + 0.22 * math.sin((y + n * 6) / 16 * math.pi * 4) + (vnoise(x, y, 4, 22, 4) - 0.5) * 0.3
		if math.abs(vnoise(x, y, 4, 23, 4) - 0.5) < 0.035 then return R[2] end
		local c = ramp({ R[3], R[4], R[5], R[6], R[7] }, v, x, y)
		if hash(x, y, 24) < 0.015 then c = R[9] end
		return c
	end,
	top = function(x, y)
		if y == 0 then return (hash(x, 0, 25) < 0.18) and R[10] or R[9] end
		if y == 1 then return (hash(x, 1, 26) < 0.35) and MOSS[3] or R[7] end
		if y == 2 then return (hash(x, 2, 27) < 0.4) and MOSS[2] or R[5] end
		return (hash(x, 3, 28) < 0.3) and MOSS[1] or R[3]
	end,
	left = function(x, y) return x == 0 and ((y % 5 == 2) and R[9] or R[7]) or R[5] end,
	right = function(d) return d == 0 and R[1] or R[3] end,
	bottom = function(d, x)
		if d == 0 then return (x % 5 == 1) and R[7] or R[1] end   -- gotas pingando
		return R[2]
	end,
	extra = function(img, ox, oy, kind)
		if kind == "var1" then
			-- Grampo de ferro cravado na rocha, escorrendo ferrugem.
			rect(img, ox + 6, oy + 4, ox + 9, oy + 6, METAL[2])
			rect(img, ox + 7, oy + 4, ox + 8, oy + 5, RUST[4])
			img:drawPixel(ox + 7, oy + 4, RUST[5])
			for y = 7, 15 do
				img:drawPixel(ox + 7 + ((y > 11) and 1 or 0), oy + y, (y < 11) and RUST[3] or RUST[2])
				if y < 10 then img:drawPixel(ox + 8, oy + y, RUST[2]) end
			end
		elseif kind == "var2" then
			-- Veio de quartzo claro.
			local pts = { { 0, 9 }, { 4, 8 }, { 7, 10 }, { 11, 9 }, { 15, 11 } }
			polyline(img, pts, R[8], ox, oy)
			polyline(img, pts, R[2], ox, oy + 1)
		elseif kind == "top2" then
			-- Poça de chuva no topo, refletindo o céu.
			rect(img, ox + 3, oy, ox + 12, oy + 1, LAKE[4])
			rect(img, ox + 4, oy, ox + 10, oy, LAKE[6])
			img:drawPixel(ox + 6, oy, R[10])
			rect(img, ox + 4, oy + 2, ox + 11, oy + 2, R[3])
		end
	end,
	-- Pontas de trilho partido e lascas de rocha no fundo dos poços.
	spike = function(img, ox, oy)
		local shards = { { 2, 10, METAL }, { 7, 15, RUST }, { 12, 12, METAL } }
		for _, s in ipairs(shards) do
			local cx, hgt, pal = s[1], s[2], s[3]
			for y = 0, hgt - 1 do
				local yy = 15 - y
				local hw = math.floor((hgt - y) / hgt * 2.5 + 0.5)
				for x = cx - hw, cx + hw do
					local c = (x == cx - hw) and pal[5] or ((x == cx + hw) and pal[1] or pal[3])
					if pal == METAL and hash(x, yy, 29) < 0.3 then c = RUST[3] end
					put(img, ox + x, oy + yy, c)
				end
			end
			put(img, ox + cx, oy + 15 - hgt, pal[5])
		end
		rect(img, ox, oy + 14, ox + 15, oy + 15, R[3])
		rect(img, ox, oy + 14, ox + 15, oy + 14, R[5])
	end,
}

make_tileset(chapel_mat, { S, WAX }, SRC .. "capela_da_vigilia_tileset.aseprite", CHAPEL .. "tileset.png")
make_tileset(cliff_mat, { R, MOSS, RUST, METAL, LAKE }, SRC .. "penhasco_da_chuva_tileset.aseprite", CLIFF .. "tileset.png")

---------------------------------------------------------------------------
-- Capela da Vigília: fundo (480x270, cobre a tela). Parede de cantaria, três janelas góticas com os
-- vitrais quebrados (pelos buracos, a água escura do lago), feixes coloridos caindo até o chão,
-- colunas e prateleiras com centenas de velas apagadas.
---------------------------------------------------------------------------
local W, H = 480, 270
local FLOOR_Y = 240

-- Janela gótica: meia-largura na altura yy (a partir do topo), arco em ponta.
local function arch_hw(yy, hw, arch_h)
	if yy < 0 then return -1 end
	if yy >= arch_h then return hw end
	local r = arch_h
	local d = arch_h - yy
	return hw - r + math.sqrt(r * r - d * d)
end

do
	local spr = new_sprite(W, H, { S, WATER, WAX, GLASS[1], GLASS[2], GLASS[3], GLASS[4], GLASS[5] })
	local wall_l, wall = layer_image(spr, "parede", true)
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local r = y // 14
			local off = (r % 2) * 16
			local bx, by = (x + off) % 32, y % 14
			local fall = 0.1 + 0.22 * (y / H) - math.abs(x - W / 2) / W * 0.1
			local c
			if by == 13 or bx == 31 then c = S[1]
			else
				local v = fall + (hash((x + off) // 32, r, 31) - 0.5) * 0.12 + (vnoise(x, y, 6, 32) - 0.5) * 0.12
				if by == 0 then v = v + 0.06 end
				c = ramp({ S[1], S[2], S[3], S[4] }, v, x, y)
			end
			wall:drawPixel(x, y, c)
		end
	end
	-- Chão de lajes.
	for y = FLOOR_Y, H - 1 do
		for x = 0, W - 1 do
			local c
			if y == FLOOR_Y then c = S[6]
			elseif (x + ((y - FLOOR_Y) // 10) * 13) % 40 == 0 or (y - FLOOR_Y) % 10 == 0 then c = S[1]
			else c = ramp({ S[2], S[3], S[4] }, 0.5 - (y - FLOOR_Y) / 60 + (vnoise(x, y, 5, 33) - 0.5) * 0.3, x, y) end
			wall:drawPixel(x, y, c)
		end
	end

	-- Janelas: guarda a cor do vidro que sobrou (para projetar os feixes).
	local glass_at = {}
	local wins = { { 88, 26, 26, 42, 176 }, { 240, 18, 32, 52, 184 }, { 392, 26, 26, 42, 176 } }
	local win_l, win = layer_image(spr, "vitrais")
	for wi, wdef in ipairs(wins) do
		local cx, top, hw, arch_h, bottom = wdef[1], wdef[2], wdef[3], wdef[4], wdef[5]
		for y = top - 5, bottom + 6 do
			local whw = arch_hw(y - top, hw, arch_h)
			local fhw = arch_hw(y - top + 5, hw + 5, arch_h + 3)
			for x = math.floor(cx - fhw), math.ceil(cx + fhw) do
				local d = math.abs(x + 0.5 - cx)
				if y > bottom then
					-- Peitoril.
					if y <= bottom + 2 and d <= hw + 7 then put(win, x, y, (y == bottom + 1) and S[8] or S[6])
					elseif y <= bottom + 6 and d <= hw + 5 then put(win, x, y, S[3]) end
				elseif d > whw and d <= fhw then
					-- Moldura de pedra (luz vinda de dentro: borda interna mais clara).
					put(win, x, y, (d - whw < 1.5) and S[7] or ((d - whw < 3.5) and S[5] or S[4]))
				elseif d <= whw then
					-- Vitral: células de vidro com chumbo, metade quebrada mostrando a água.
					local gx, gy = (x - cx + 64) / 7, (y - top) / 9
					local ix, iy = math.floor(gx), math.floor(gy)
					local fx, fy = gx - ix, gy - iy
					local lead = fx < 0.16 or fy < 0.13
					local broken = vnoise(x, y, 11, 40 + wi) + (y - top) / (bottom - top) * 0.25 > 0.62
						or hash(ix, iy, 41 + wi) < 0.18
					local c
					if broken then
						local v = 0.15 + 0.35 * (1 - (y - top) / (bottom - top)) + (vnoise(x, y * 0.2, 6, 42) - 0.5) * 0.3
						c = ramp(WATER, v, x, y)
						-- Bordas do vidro quebrado: lascas soltas.
						if hash(x, y, 43) < 0.06 then c = S[6] end
					elseif lead then c = S[1]
					else
						local g = GLASS[math.floor(hash(ix, iy, 44 + wi) * 5) + 1]
						local v = (fx + fy) / 2
						c = (v < 0.35) and g[3] or ((v < 0.75) and g[2] or g[1])
						glass_at[x .. "," .. y] = g
					end
					-- Mainel central e travessa.
					if math.abs(x + 0.5 - cx) < 1.5 and y > top + arch_h * 0.6 then c = S[6] end
					if y == top + arch_h + 20 or y == top + arch_h + 21 then c = S[5] end
					put(win, x, y, c)
				end
			end
		end
	end

	-- Feixes: cada pixel abaixo de uma janela olha para trás (na diagonal) e pega a cor do vidro que
	-- sobrou naquela coluna da janela (onde o vidro quebrou, não passa cor).
	local col_glass = {}
	for _, wdef in ipairs(wins) do
		for x = wdef[1] - wdef[3], wdef[1] + wdef[3] do
			for y = wdef[5], wdef[2] + wdef[4], -1 do
				local g = glass_at[x .. "," .. y]
				if g then col_glass[x] = g; break end
			end
		end
	end
	local beam_l, beam = layer_image(spr, "feixes")
	for y = 60, H - 1 do
		for x = 0, W - 1 do
			for _, wdef in ipairs(wins) do
				local dist = y - wdef[5]
				if dist > 6 then
					local g = col_glass[math.floor(x - dist * 0.42)]
					if g and math.abs(math.floor(x - dist * 0.42) - wdef[1]) <= wdef[3] then
						local a = 0.42 - dist / 260
						if y >= FLOOR_Y then a = 0.6 end   -- poça de cor no chão
						if bayer(x, y) < a then put(beam, x, y, (y >= FLOOR_Y) and g[2] or g[1]) end
					end
				end
			end
		end
	end

	-- Colunas entre as janelas.
	local col_l, cols = layer_image(spr, "colunas")
	for _, cx in ipairs({ 14, 164, 316, 466 }) do
		for y = 0, FLOOR_Y - 1 do
			for x = cx - 10, cx + 10 do
				local t = (x - cx) / 10
				local v = 0.55 - t * 0.35 - math.abs(t) ^ 3 * 0.3 - (y / H) * 0.1
				local c = ramp({ S[2], S[3], S[4], S[5], S[6] }, v, x, y)
				if (x - cx + 10) % 5 == 0 then c = S[2] end   -- caneluras
				put(cols, x, y, c)
			end
		end
		rect(cols, cx - 13, 30, cx + 13, 34, S[6])
		rect(cols, cx - 13, 30, cx + 13, 30, S[8])
		rect(cols, cx - 13, FLOOR_Y - 8, cx + 13, FLOOR_Y - 1, S[5])
		rect(cols, cx - 13, FLOOR_Y - 8, cx + 13, FLOOR_Y - 8, S[7])
	end

	-- Velas apagadas: prateleiras em degraus no pé da parede e nos peitoris (centenas).
	local wax_l, wax = layer_image(spr, "velas")
	local function candle_row(x0, x1, base, seed, tall)
		local x = x0
		local i = 0
		while x < x1 do
			local h = 2 + math.floor(hash(i, seed, 50) * (tall or 5))
			local wdt = (hash(i, seed, 51) < 0.3) and 2 or 1
			for yy = base - h, base - 1 do
				for xx = x, x + wdt - 1 do put(wax, xx, yy, (xx == x) and WAX[3] or WAX[2]) end
			end
			put(wax, x, base - h - 1, WAX[1])   -- pavio
			x = x + wdt + 1 + ((hash(i, seed, 52) < 0.25) and 1 or 0)
			i = i + 1
		end
		rect(wax, x0 - 1, base, x1, base, S[6])
		rect(wax, x0 - 1, base + 1, x1, base + 2, S[2])
	end
	for _, wdef in ipairs(wins) do candle_row(wdef[1] - wdef[3] - 4, wdef[1] + wdef[3] + 4, wdef[5] + 1, wdef[1], 4) end
	for i, tier in ipairs({ { 206, 2 }, { 218, 3 }, { 230, 4 } }) do
		candle_row(28 + i * 6, 150 - i * 6, tier[1], tier[2] * 7, 5)
		candle_row(330 + i * 6, 452 - i * 6, tier[1], tier[2] * 13, 5)
	end
	candle_row(180, 300, FLOOR_Y - 1, 99, 6)

	finish(spr, { { wall_l, wall }, { win_l, win }, { beam_l, beam }, { col_l, cols }, { wax_l, wax } },
		SRC .. "capela_da_vigilia_fundo.aseprite", CHAPEL .. "fundo.png")
end

---------------------------------------------------------------------------
-- Capela da Vigília: objetos de cenário.
---------------------------------------------------------------------------
-- Luz de vitral: feixe diagonal translúcido caindo do alto até uma poça colorida no chão (com as
-- linhas do chumbo projetadas).
local function beam_prop(file, order)
	prop(96, 160, { GLASS[1], GLASS[2], GLASS[3], GLASS[4], GLASS[5] }, "feixe",
		SRC .. "capela_da_vigilia_" .. file .. ".aseprite", CHAPEL .. file .. ".png", function(img, w, h)
		for y = 0, h - 1 do
			local x0 = 6 + y * 0.36
			for x = math.floor(x0), math.floor(x0 + 32) do
				local u = (x - x0) / 32
				local strip = math.max(1, math.min(4, math.floor(u * 4) + 1))
				local g = GLASS[order[strip]]
				local lead = math.abs(u * 4 - math.floor(u * 4 + 0.5)) < 0.05
				local edge = math.min(u, 1 - u)
				local a = math.floor(26 + 28 * (y / h) + math.min(edge * 6, 1) * 18)
				if not lead and y < h - 6 then
					put(img, x, y, with_alpha(g[2], a))
					if hash(x, y, 60) < 0.012 then put(img, x, y, with_alpha(g[3], 150)) end   -- poeira acesa
				end
			end
		end
		-- Poça de cor no chão.
		local cx = 6 + (h - 3) * 0.36 + 16
		for y = h - 6, h - 1 do
			local ry = (y - (h - 6)) / 5
			local hw = 18 + ry * 10
			for x = math.floor(cx - hw), math.floor(cx + hw) do
				local u = (x - (cx - hw)) / (2 * hw)
				local strip = math.max(1, math.min(4, math.floor(u * 4) + 1))
				local lead = math.abs(u * 4 - math.floor(u * 4 + 0.5)) < 0.06
				local edge = math.min(u, 1 - u) * 2
				if not lead and bayer(x, y) < 0.35 + edge then
					put(img, x, y, with_alpha(GLASS[order[strip]][(y == h - 1) and 2 or 3], 120 + math.floor(edge * 60)))
				end
			end
		end
	end)
end
beam_prop("vitral_luz_a", { 1, 3, 2, 5 })
beam_prop("vitral_luz_b", { 2, 4, 1, 3 })

-- Santo sem rosto num pedestal. O rosto foi raspado com cuidado: só riscos claros na pedra.
local function saint(file, pose)
	prop(28, 60, { S, GLASS[1] }, "santo", SRC .. "capela_da_vigilia_" .. file .. ".aseprite", CHAPEL .. file .. ".png",
		function(img, w, h)
		-- Pedestal.
		rect(img, 2, 50, 25, 59, S[4])
		rect(img, 1, 49, 26, 50, S[6])
		rect(img, 1, 49, 26, 49, S[8])
		rect(img, 3, 52, 24, 52, S[2])
		rect(img, 2, 58, 25, 59, S[2])
		for x = 2, 25 do if x > 18 then put(img, x, 54, S[3]) end end
		-- Manto: trapézio com dobras, luz vinda da esquerda.
		for y = 16, 48 do
			local t = (y - 16) / 32
			local hw = 5 + t * 5
			for x = math.floor(14 - hw), math.floor(13 + hw) do
				local u = (x - (14 - hw)) / (2 * hw)
				local v = 0.75 - u * 0.6
				if (x + math.floor(y / 6)) % 5 == 0 and y > 24 then v = v - 0.3 end   -- dobras
				put(img, x, y, ramp({ S[3], S[4], S[5], S[6], S[7] }, v, x, y))
			end
		end
		-- Reflexo vermelho do vitral na borda direita.
		for y = 26, 46 do if hash(y, 0, 61) < 0.6 then put(img, math.floor(13 + 5 + (y - 16) / 32 * 5), y, GLASS[1][2]) end end
		-- Cabeça com véu.
		for y = 4, 15 do
			local hw = (y < 7) and (y - 1) or 5
			if y > 12 then hw = 4 end
			for x = 14 - hw, 13 + hw do
				put(img, x, y, ramp({ S[4], S[5], S[6], S[7] }, 0.8 - (x - (14 - hw)) / (2 * hw) * 0.6, x, y))
			end
		end
		-- Rosto raspado: o oval do rosto mais claro, todo riscado, sem feição nenhuma.
		for y = 7, 13 do
			for x = 11, 16 do
				local c = S[7]
				if (x + y * 2) % 3 == 0 then c = S[9] elseif (x * 3 + y) % 4 == 0 then c = S[5] end
				put(img, x, y, c)
			end
		end
		line(img, 11, 8, 16, 10, S[9])
		line(img, 11, 11, 16, 12, S[8])
		if pose == "halo" then
			-- Mãos juntas no peito e uma auréola partida atrás da cabeça.
			rect(img, 12, 21, 15, 24, S[7])
			put(img, 12, 21, S[8])
			for a = 0, 40 do
				local ang = math.pi * (0.95 + a / 40 * 1.15)
				if a < 15 or a > 22 then
					put(img, 14 + math.cos(ang) * 9, 8 + math.sin(ang) * 7, (a < 15) and S[7] or S[6])
				end
			end
		else
			-- Braço estendido segurando um livro fechado; uma rachadura atravessa o manto.
			line(img, 18, 20, 23, 26, S[6])
			line(img, 18, 21, 23, 27, S[5])
			rect(img, 21, 25, 26, 29, S[4])
			rect(img, 21, 25, 26, 25, S[7])
			rect(img, 22, 26, 25, 28, S[3])
			polyline(img, { { 9, 30 }, { 12, 34 }, { 11, 38 }, { 15, 42 }, { 14, 48 } }, S[1])
			polyline(img, { { 10, 30 }, { 13, 34 }, { 12, 38 }, { 16, 42 }, { 15, 48 } }, S[7])
		end
	end)
end
saint("santo_sem_rosto_a", "halo")
saint("santo_sem_rosto_b", "book")

-- Velas apagadas em grupo, alturas diferentes, cera escorrida e pavio preto.
local function candles(file, w, h, seed)
	prop(w, h, { WAX }, "velas", SRC .. "capela_da_vigilia_" .. file .. ".aseprite", CHAPEL .. file .. ".png",
		function(img)
		local x, i = 1, 0
		while x < w - 3 do
			local ch = 3 + math.floor(hash(i, seed, 70) * (h - 6))
			local cw = (hash(i, seed, 71) < 0.45) and 3 or 2
			local base = h - 2 - ((hash(i, seed, 72) < 0.3) and 1 or 0)
			for yy = base - ch, base do
				for xx = x, x + cw - 1 do
					local c = (xx == x) and WAX[5] or ((xx == x + cw - 1) and WAX[3] or WAX[4])
					put(img, xx, yy, c)
				end
			end
			-- Borda derretida e pavio.
			put(img, x + cw - 1, base - ch, WAX[3])
			put(img, x + (cw // 2), base - ch - 1, WAX[1])
			if hash(i, seed, 73) < 0.5 then put(img, x - 1, base - ch + 2 + math.floor(hash(i, seed, 74) * 3), WAX[4]) end
			x = x + cw + ((hash(i, seed, 75) < 0.4) and 1 or 0)
			i = i + 1
		end
		-- Cera acumulada na base.
		rect(img, 0, h - 1, w - 1, h - 1, WAX[3])
		for xx = 0, w - 1 do if hash(xx, seed, 76) < 0.5 then put(img, xx, h - 2, WAX[4]) end end
	end)
end
candles("velas_apagadas", 64, 16, 1)
candles("velas_apagadas_b", 40, 12, 2)

-- A única vela acesa: chama pequena e um halo quente.
prop(32, 40, { WAX, FLAME }, "vela", SRC .. "capela_da_vigilia_vela_acesa.aseprite", CHAPEL .. "vela_acesa.png",
	function(img, w, h)
	local cx, fy = 16, 23
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local dx, dy = x + 0.5 - cx, (y - fy) * 0.85
			local d = math.sqrt(dx * dx + dy * dy)
			if d < 15 then
				local a = (1 - d / 15) ^ 1.6
				if bayer(x, y) < a * 1.4 then put(img, x, y, with_alpha((d < 7) and FLAME[3] or FLAME[2], math.floor(40 + a * 90))) end
			end
		end
	end
	-- Vela.
	for y = 26, h - 2 do
		put(img, cx - 2, y, WAX[5])
		put(img, cx - 1, y, rgb("#e8dcc0"))
		put(img, cx, y, rgb("#cdbf9f"))
		put(img, cx + 1, y, WAX[4])
	end
	rect(img, cx - 2, 26, cx + 1, 26, rgb("#fff0cf"))
	put(img, cx + 2, 28, WAX[5]); put(img, cx + 2, 29, WAX[5]); put(img, cx + 2, 30, WAX[4])
	rect(img, cx - 4, h - 1, cx + 3, h - 1, WAX[4])
	put(img, cx - 1, 25, WAX[1])   -- pavio
	-- Chama.
	local flame = { { 0, 18, 6 }, { -1, 19, 5 }, { 0, 19, 6 }, { -1, 20, 5 }, { 0, 20, 6 }, { 1, 20, 4 },
		{ -2, 21, 3 }, { -1, 21, 5 }, { 0, 21, 6 }, { 1, 21, 4 }, { -2, 22, 4 }, { -1, 22, 6 }, { 0, 22, 5 },
		{ 1, 22, 4 }, { -1, 23, 5 }, { 0, 23, 4 }, { -1, 24, 3 }, { -1, 17, 4 }, { -1, 16, 3 } }
	for _, p in ipairs(flame) do put(img, cx + p[1], p[2], FLAME[p[3]]) end
end)

-- Altar partido ao meio (fica em cima dos blocos ##.## do mapa): duas metades da laje inclinadas
-- para a fenda, toalha rasgada e castiçais caídos.
prop(96, 32, { S, WAX, GLASS[3] }, "altar", SRC .. "capela_da_vigilia_altar_partido.aseprite", CHAPEL .. "altar_partido.png",
	function(img, w, h)
	local function slab(x0, x1, y0, y1, dir)
		for x = x0, x1 do
			local t = (x - x0) / (x1 - x0)
			local top = math.floor(y0 + (y1 - y0) * t + 0.5)
			for y = top, top + 6 do
				local c = (y == top) and S[8] or ((y == top + 1) and S[6] or ((y == top + 6) and S[2] or S[4]))
				if y > top + 1 and y < top + 6 and hash(x, y, 80) < 0.08 then c = S[3] end
				put(img, x, y, c)
			end
			for y = top + 7, h - 1 do put(img, x, y, (x % 9 == 0) and S[1] or S[3]) end   -- base com relevo
		end
		-- Ponta quebrada na fenda: lascas irregulares.
		local ex = (dir > 0) and x1 or x0
		for i = 0, 6 do put(img, ex + dir * ((i % 3 == 0) and 1 or 0), math.floor(y1) + i, S[1]) end
	end
	slab(8, 44, 20, 24, 1)
	slab(52, 88, 23, 19, -1)
	-- Entulho na fenda.
	for _, p in ipairs({ { 46, 30 }, { 47, 29 }, { 49, 30 }, { 50, 31 }, { 45, 31 }, { 48, 31 } }) do put(img, p[1], p[2], S[5]) end
	-- Toalha rasgada caindo da metade esquerda, com a cruz bordada desbotada.
	for x = 10, 34 do
		local top = math.floor(20 + 4 * (x - 8) / 36 + 0.5) - 1
		local bottom = top + 6 + math.floor(hash(x, 0, 81) * 4)
		if x > 30 then bottom = top + 2 + (x % 2) end
		for y = top, bottom do put(img, x, y, (y == top) and WAX[5] or ((x % 4 == 0) and WAX[3] or WAX[4])) end
	end
	rect(img, 20, 23, 20, 28, GLASS[3][1])
	rect(img, 18, 25, 22, 25, GLASS[3][1])
	-- Velas apagadas em cima (seguem a inclinação) e uma caída.
	for i, x in ipairs({ 12, 16, 26, 58, 64, 72, 82 }) do
		local top = (x < 48) and (20 + 4 * (x - 8) / 36) or (23 - 4 * (x - 52) / 36)
		local ch = 3 + (i * 3) % 6
		for y = math.floor(top) - ch, math.floor(top) - 1 do
			put(img, x, y, WAX[5]); put(img, x + 1, y, WAX[3])
		end
		put(img, x, math.floor(top) - ch - 1, WAX[1])
	end
	line(img, 36, 18, 41, 20, WAX[4])
	line(img, 36, 19, 41, 21, WAX[3])
end)

-- Confessionário de madeira escura (a inscrição só se lê depois do Velário).
prop(48, 64, { WOOD, S }, "confessionario", SRC .. "capela_da_vigilia_confessionario.aseprite", CHAPEL .. "confessionario.png",
	function(img, w, h)
	-- Telhado em ponta.
	for y = 0, 10 do
		local hw = math.floor(y * 2.4)
		for x = 24 - hw, 23 + hw do put(img, x, y, (math.abs(x + 0.5 - 24) > hw - 2) and WOOD[5] or WOOD[3]) end
	end
	rect(img, 0, 11, 47, 13, WOOD[4])
	rect(img, 0, 11, 47, 11, WOOD[5])
	-- Corpo: três vãos (padre no meio com treliça, cortinas nos lados).
	rect(img, 2, 14, 45, 61, WOOD[2])
	for _, x in ipairs({ 2, 16, 31, 45 }) do rect(img, x, 14, x + 1, 61, WOOD[4]); put(img, x, 14, WOOD[5]) end
	for x = 18, 30 do
		for y = 18, 40 do
			local c = WOOD[1]
			if (x + y) % 4 == 0 or (x - y) % 4 == 0 then c = WOOD[3] end
			put(img, x, y, c)
		end
	end
	rect(img, 18, 42, 30, 59, WOOD[3])
	rect(img, 19, 43, 29, 58, WOOD[2])
	for _, x0 in ipairs({ 4, 33 }) do
		for x = x0, x0 + 10 do
			for y = 16, 59 do
				local c = ((x - x0) % 3 == 0) and S[2] or S[3]
				if y > 50 and hash(x, y, 90) < 0.3 then c = WOOD[1] end   -- barra rasgada
				put(img, x, y, c)
			end
		end
	end
	rect(img, 0, 62, 47, 63, WOOD[4])
	rect(img, 0, 62, 47, 62, WOOD[5])
	-- Faixa entalhada (a inscrição gasta).
	for x = 8, 40 do if hash(x, 0, 91) < 0.55 then put(img, x, 12, WOOD[2]) end end
end)

---------------------------------------------------------------------------
-- Penhasco da Chuva Eterna: fundo (480x270, cobre a tela). Céu fechado, montanhas na névoa, o lago
-- parado lá embaixo (a chuva não mexe na água), paredões dos lados, o cabo do bonde partido no meio
-- do vão e um pilar de viaduto com os trilhos pendurados.
---------------------------------------------------------------------------
do
	local spr = new_sprite(W, H, { SKY, LAKE, R, METAL })
	local sky_l, sky = layer_image(spr, "ceu", true)
	local HORIZON = 196
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local c
			if y < HORIZON then
				local v = 0.08 + 0.62 * (y / HORIZON) ^ 1.4
				local cloud = vnoise(x, y * 3.2, 46, 101) * 0.6 + vnoise(x, y * 2, 18, 102) * 0.4
				v = v + (cloud - 0.5) * 0.35
				c = ramp(SKY, v, x, y)
			else
				-- Lago: liso, reflete o céu de cima de cabeça para baixo, sem nenhuma onda.
				local my = HORIZON - (y - HORIZON) * 1.5
				local v = 0.25 + 0.5 * (math.max(my, 0) / HORIZON) ^ 1.4 - (y - HORIZON) / 220
				c = ramp(LAKE, v, x, y)
				if y == HORIZON then c = LAKE[6] end
			end
			sky:drawPixel(x, y, c)
		end
	end
	-- Montanhas ao longe, apagadas pela névoa, com reflexo no lago.
	local far_l, far = layer_image(spr, "montanhas")
	for x = 0, W - 1 do
		local ridge = 150 + vnoise(x, 0, 60, 103) * 34 + vnoise(x, 0, 14, 104) * 9
		for y = math.floor(ridge), HORIZON - 1 do
			local v = 0.55 - (y - ridge) / 120 + (vnoise(x, y, 10, 105) - 0.5) * 0.1
			put(far, x, y, ramp({ SKY[3], SKY[4], SKY[5], SKY[6] }, v, x, y))
		end
		for y = HORIZON + 1, HORIZON + math.floor((HORIZON - ridge) * 0.5) do
			if bayer(x, y) < 0.5 then put(far, x, y, LAKE[3]) end
		end
	end
	-- Névoa no pé das montanhas.
	for y = HORIZON - 14, HORIZON - 1 do
		for x = 0, W - 1 do
			if bayer(x, y) < (y - (HORIZON - 14)) / 20 * vnoise(x, y, 24, 106) then put(far, x, y, SKY[8]) end
		end
	end

	-- Paredões dos dois lados, caindo até o lago.
	local wall_l, wall = layer_image(spr, "paredoes")
	local function cliff_side(left)
		for y = 40, H - 1 do
			local edge = 70 + (y - 40) * 0.18 + vnoise(0, y, 16, left and 107 or 108) * 26
			if left and y < 70 then edge = edge - (70 - y) * 1.5 end
			if not left and y < 56 then edge = edge - (56 - y) * 1.8 end
			for i = 0, math.floor(edge) do
				local x = left and i or (W - 1 - i)
				local v = 0.38 - (edge - i < 3 and -0.25 or 0) + (vnoise(x, y, 7, 109) - 0.5) * 0.35
					+ 0.15 * math.sin(y * 0.4 + vnoise(x, y, 12, 110) * 5)
				local c = ramp({ R[1], R[2], R[3], R[4], R[5] }, v, x, y)
				if edge - i < 1.5 then c = R[6] end
				put(wall, x, y, c)
			end
		end
	end
	cliff_side(true)
	cliff_side(false)

	-- Cabo do bonde: das torres nos paredões até o meio do vão, partido e pendurado dos dois lados.
	local obj_l, obj = layer_image(spr, "cabo_e_viaduto")
	local function tower(x, base, hgt)
		for y = base - hgt, base do
			local hw = math.floor((y - (base - hgt)) / hgt * 3)
			put(obj, x - hw - 1, y, METAL[2]); put(obj, x + hw + 1, y, METAL[1])
			if (y - base) % 6 == 0 then line(obj, x - hw - 1, y, x + hw + 1, y - 6, METAL[2]) end
		end
		rect(obj, x - 6, base - hgt, x + 6, base - hgt + 1, METAL[3])
	end
	tower(34, 66, 40)
	tower(446, 52, 40)
	-- Metade esquerda do cabo: catenária até o meio e depois o pedaço caído.
	local function cable(x0, y0, x1, y1, sag, drop_len)
		local lx, ly
		for i = 0, 100 do
			local t = i / 100
			local x = x0 + (x1 - x0) * t
			local y = y0 + (y1 - y0) * t + sag * 4 * t * (1 - t)
			put(obj, x, y, SKY[1])
			lx, ly = x, y
		end
		for i = 1, drop_len do put(obj, lx + math.sin(i * 0.15) * 1.5, ly + i, SKY[1]) end
		put(obj, lx - 1, ly + drop_len + 1, SKY[1]); put(obj, lx + 1, ly + drop_len + 1, SKY[1])
	end
	cable(34, 27, 214, 58, 18, 44)
	cable(446, 13, 262, 50, 20, 30)
	-- Pilar do viaduto saindo da névoa, com os trilhos pendurados do topo.
	for y = 132, HORIZON + 3 do
		local hw = 7 + (y - 132) * 0.06
		for x = math.floor(238 - hw), math.floor(238 + hw) do
			local c = ramp({ SKY[2], SKY[3], SKY[4] }, 0.6 - (x - 238 + hw) / (2 * hw) * 0.5 + (y - 132) / 300, x, y)
			put(obj, x, y, c)
		end
	end
	rect(obj, 226, 130, 252, 133, SKY[3])
	polyline(obj, { { 226, 130 }, { 220, 136 }, { 218, 146 }, { 221, 158 }, { 219, 168 } }, SKY[1])
	polyline(obj, { { 252, 131 }, { 257, 140 }, { 256, 152 }, { 259, 160 } }, SKY[1])
	for i = 0, 4 do line(obj, 219 + (i % 2), 140 + i * 6, 223 + (i % 2), 141 + i * 6, SKY[2]) end

	finish(spr, { { sky_l, sky }, { far_l, far }, { wall_l, wall }, { obj_l, obj } },
		SRC .. "penhasco_da_chuva_fundo.aseprite", CLIFF .. "fundo.png")
end

---------------------------------------------------------------------------
-- Penhasco da Chuva Eterna: objetos de cenário.
---------------------------------------------------------------------------
-- Trilho com dormentes, para assentar no chão.
local function rail(img, x0, x1, y)
	rect(img, x0, y, x1, y, METAL[4])
	rect(img, x0, y + 1, x1, y + 1, METAL[2])
	for x = x0, x1 do
		if hash(x, y, 120) < 0.25 then put(img, x, y, RUST[4]) end
		if (x - x0) % 6 < 3 then rect(img, x, y + 2, x, y + 3, (x - x0) % 6 == 0 and WOOD[4] or WOOD[3]) end
	end
end

prop(64, 6, { METAL, RUST, WOOD }, "trilho", SRC .. "penhasco_da_chuva_trilho.aseprite", CLIFF .. "trilho.png",
	function(img, w, h)
	rail(img, 0, w - 1, 2)
	put(img, 20, 1, METAL[5])
	put(img, 44, 1, METAL[5])
end)

-- Trilhos pendurados: deitados na plataforma (à direita) e torcidos para baixo no vazio (à esquerda).
prop(96, 70, { METAL, RUST, WOOD }, "trilhos", SRC .. "penhasco_da_chuva_trilhos_pendurados.aseprite",
	CLIFF .. "trilhos_pendurados.png", function(img, w, h)
	rail(img, 40, 95, 2)
	local a = { { 40, 2 }, { 33, 4 }, { 27, 10 }, { 24, 20 }, { 25, 31 }, { 21, 42 }, { 18, 52 }, { 20, 61 }, { 17, 68 } }
	local b = { { 40, 3 }, { 36, 7 }, { 34, 15 }, { 36, 24 }, { 33, 34 }, { 34, 44 }, { 31, 52 } }
	polyline(img, a, METAL[4]); polyline(img, a, METAL[2], 1, 0)
	polyline(img, b, RUST[4]); polyline(img, b, RUST[2], 1, 0)
	-- Dormentes soltos ainda presos aos trilhos, tortos.
	for _, s in ipairs({ { 26, 12, 34, 16 }, { 24, 26, 34, 27 }, { 22, 40, 32, 39 }, { 19, 54, 25, 57 } }) do
		line(img, s[1], s[2], s[3], s[4], WOOD[4])
		line(img, s[1], s[2] + 1, s[3], s[4] + 1, WOOD[2])
	end
	-- Pingos de ferrugem.
	for _, p in ipairs({ { 18, 69 }, { 31, 56 }, { 31, 58 } }) do put(img, p[1], p[2], RUST[3]) end
end)

-- Torre do bonde: o cabo vem da esquerda, passa na roldana e cai partido, com o gancho vazio.
prop(80, 160, { METAL, RUST, SKY }, "cabo", SRC .. "penhasco_da_chuva_cabo_bonde.aseprite", CLIFF .. "cabo_bonde.png",
	function(img, w, h)
	local top = 30
	for y = top, h - 1 do
		local t = (y - top) / (h - 1 - top)
		local hw = math.floor(3 + t * 6)
		local lx, rx = 22 - hw, 22 + hw
		put(img, lx, y, METAL[4]); put(img, lx + 1, y, METAL[3])
		put(img, rx, y, METAL[2]); put(img, rx - 1, y, METAL[3])
		if (y - top) % 12 == 0 then
			line(img, lx, y, rx, y + 12, METAL[3])
			line(img, rx, y, lx, y + 12, METAL[2])
			rect(img, lx, y, rx, y, METAL[3])
		end
		if hash(lx, y, 130) < 0.15 then put(img, lx, y, RUST[4]) end
	end
	rect(img, 6, 140, 38, 159, CLEAR)
	for y = 140, h - 1 do
		local hw = math.floor(3 + (y - top) / (h - 1 - top) * 6)
		put(img, 22 - hw, y, METAL[4]); put(img, 22 + hw, y, METAL[2])
	end
	rect(img, 10, h - 3, 34, h - 1, METAL[2])
	rect(img, 10, h - 3, 34, h - 3, METAL[3])
	-- Braço e roldana.
	rect(img, 4, top - 3, 62, top - 1, METAL[3])
	rect(img, 4, top - 3, 62, top - 3, METAL[5])
	line(img, 22, top - 1, 6, top + 12, METAL[2])
	line(img, 22, top - 1, 56, top + 12, METAL[2])
	for a = 0, 23 do
		local ang = a / 24 * math.pi * 2
		put(img, 58 + math.cos(ang) * 4, top + 3 + math.sin(ang) * 4, METAL[4])
	end
	put(img, 58, top + 3, METAL[5])
	-- Cabo que chega (da estação, à esquerda).
	for x = 0, 58 do
		local t = x / 58
		put(img, x, 6 + (top - 7) * t + 8 * t * (1 - t) * 0, SKY[1])
	end
	-- Cabo partido caindo da roldana, com o gancho do bonde preso e a ponta desfiada.
	local lx, ly = 62, top + 3
	for y = top + 3, 128 do
		local x = 62 + math.sin((y - top) * 0.07) * 3
		put(img, x, y, METAL[1])
		lx, ly = x, y
		if y == 92 then
			rect(img, x - 1, y, x + 1, y + 2, METAL[3])
			line(img, x, y + 3, x, y + 10, METAL[3])
			polyline(img, { { x, y + 10 }, { x - 4, y + 12 }, { x - 4, y + 15 }, { x - 1, y + 16 } }, METAL[4])
			put(img, x - 3, y + 14, RUST[4])
		end
	end
	line(img, lx, ly, lx - 3, ly + 5, METAL[1])
	line(img, lx, ly, lx + 2, ly + 6, METAL[1])
	line(img, lx, ly, lx, ly + 7, METAL[2])
end)

-- Cabine do maquinista em ruínas: teto desabado de um lado, vidros quebrados, porta pendurada.
prop(88, 64, { PAINT, RUST, METAL, R, LAKE }, "cabine", SRC .. "penhasco_da_chuva_cabine_maquinista.aseprite",
	CLIFF .. "cabine_maquinista.png", function(img, w, h)
	local function roof_y(x)
		if x <= 48 then return 12 end
		return 12 + math.floor((x - 48) * 0.45)
	end
	for x = 4, 83 do
		local ry = roof_y(x)
		for y = ry, 55 do
			local v = 0.6 - (x - 4) / 80 * 0.3 - (y - ry) / 120
			local c = ramp(PAINT, v, x, y)
			if vnoise(x, y, 5, 140) > 0.62 then c = (hash(x, y, 141) < 0.5) and RUST[3] or RUST[2] end
			if y == 33 or y == 34 then c = (y == 33) and PAINT[4] or PAINT[1] end   -- friso
			put(img, x, y, c)
		end
		-- Ferrugem escorrendo da borda do teto.
		if hash(x, 0, 142) < 0.2 then for y = ry + 1, ry + 4 + x % 6 do put(img, x, y, RUST[3]) end end
		put(img, x, ry, METAL[4])
		put(img, x, ry - 1, (x <= 48) and METAL[3] or METAL[2])
	end
	-- Janelas com vidro quebrado.
	for _, wx in ipairs({ 10, 30 }) do
		rect(img, wx, 17, wx + 14, 29, R[1])
		rect(img, wx - 1, 16, wx + 15, 16, PAINT[1])
		for y = 17, 29 do
			for x = wx, wx + 14 do
				local d = (x - wx) + (29 - y)
				if d < 7 and hash(x, y, 143) < 0.85 then put(img, x, y, (d < 3) and LAKE[6] or LAKE[4]) end
				if x - wx + y - 17 > 22 and hash(x, y, 144) < 0.7 then put(img, x, y, LAKE[3]) end
			end
		end
	end
	-- Vão da porta aberta e a porta pendurada por uma dobradiça.
	rect(img, 54, 26, 66, 55, R[1])
	for i = 0, 26 do
		local x = 67 + math.floor(i * 0.35)
		rect(img, x, 27 + i, x + 9, 27 + i, (i % 9 == 0) and PAINT[4] or PAINT[2])
	end
	-- Chassi e rodas.
	rect(img, 2, 56, 85, 58, METAL[2])
	rect(img, 2, 56, 85, 56, METAL[3])
	for _, wx in ipairs({ 18, 66 }) do
		for a = 0, 31 do
			local ang = a / 32 * math.pi * 2
			for r = 0, 5 do
				local px, py = wx + math.cos(ang) * r, 59 + math.sin(ang) * r
				if py <= 63 then put(img, px, py, (r == 5) and METAL[4] or ((r < 2) and METAL[3] or METAL[1])) end
			end
		end
	end
	-- Destroços do teto no chão.
	for _, p in ipairs({ { 76, 62, 82, 61 }, { 70, 63, 86, 63 } }) do line(img, p[1], p[2], p[3], p[4], METAL[3]) end
end)

-- Sinal da linha na beira do penhasco: braço caído e lanterna quebrada.
prop(24, 56, { METAL, RUST }, "sinal", SRC .. "penhasco_da_chuva_sinal_quebrado.aseprite", CLIFF .. "sinal_quebrado.png",
	function(img, w, h)
	rect(img, 10, 6, 11, 55, METAL[3])
	rect(img, 10, 6, 10, 55, METAL[4])
	rect(img, 6, 52, 15, 55, METAL[2])
	rect(img, 6, 52, 15, 52, METAL[3])
	for y = 10, 50, 5 do put(img, 12, y, RUST[4]) end
	-- Braço do semáforo pendurado para baixo.
	line(img, 12, 8, 19, 22, RUST[4])
	line(img, 13, 8, 20, 22, RUST[2])
	rect(img, 18, 22, 21, 24, RUST[3])
	-- Lanterna: aro torto, sem vidro.
	rect(img, 7, 1, 14, 6, METAL[2])
	rect(img, 8, 2, 13, 5, METAL[1])
	put(img, 9, 3, LAKE[4]); put(img, 12, 4, LAKE[3])
	put(img, 7, 0, METAL[3]); put(img, 14, 0, METAL[3])
end)

print("Águas Veladas: arte gerada em " .. CHAPEL .. " e " .. CLIFF)
