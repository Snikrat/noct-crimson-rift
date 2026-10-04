-- Peças do Coração da Fenda (docs/expansao_forma_demoniaca.md, 1.6), desenhadas por script no Aseprite:
--   cristal carmesim: bloco de 16x16 em três arranjos (idle_a/b/c, 4 quadros pulsando) e a quebra (shatter, 32x32);
--   rachadura: 16x56, pés (superfície do chão) na linha 44: idle, warn (acendendo) e burst (coluna de energia).
-- Fontes: art_source/cenarios_novos/coracao_da_fenda_*.aseprite. Jogo: assets/areas/coracao_da_fenda/.
-- Rodar na raiz do projeto:
--   Aseprite.exe -b --script tools/make_rift_props.lua

local K = dofile(app.fs.joinPath(app.fs.filePath(debug.getinfo(1).source:sub(2)), "pixel_kit.lua"))
local put, poly, ellipse, thick, erase, get, hash = K.put, K.poly, K.ellipse, K.thick, K.erase, K.get, K.hash
local OUT = "assets/areas/coracao_da_fenda/"
local SRC = "art_source/cenarios_novos/"

---------------------------------------------------------------------------
-- Cristal: pedra escura com pontas de cristal saindo dela; o miolo pulsa.
---------------------------------------------------------------------------
local LAYOUTS = {
	a = { { 3, 15, 4, 13, -1 }, { 8, 15, 5, 15, 0 }, { 13, 15, 3, 10, 1 } },
	b = { { 2, 15, 3, 9, -1 }, { 6, 15, 5, 14, -1 }, { 11, 15, 5, 12, 1 }, { 14, 7, 2, 6, 2 } },
	c = { { 4, 15, 6, 15, 0 }, { 11, 15, 4, 11, 1 }, { 1, 6, 2, 5, -2 } },
}

local function shard(c, bx, by, w, h, lean, pulse)
	-- Lâmina de cristal: base larga em (bx, by), ponta h px acima, inclinada por "lean".
	local tipx, tipy = bx + lean, by - h
	poly(c, { { bx - w / 2, by }, { bx + w / 2, by }, { tipx + 0.6, tipy }, { tipx - 0.6, tipy } }, "CRIM",
		function(x, y)
			local k = (by - y) / h
			if x < bx + lean * k - 0.3 then return (k > 0.6) and 5 or 4 end
			return (k > 0.75) and 3 or 2
		end)
	-- Fio de luz no meio e ponta acesa.
	for y = math.floor(tipy + 1), by - 2 do
		local k = (by - y) / h
		put(c, bx + lean * k, y, "CRIM", (k > 0.7) and (5 + pulse) or 4 + pulse)
	end
	put(c, tipx, tipy, "CRIM", 6)
end

local function crystal(p)
	local c = K.canvas(16, 16)
	-- Pedra de fundo (encaixa com os blocos vizinhos: sem contorno nas bordas).
	for y = 0, 15 do
		for x = 0, 15 do
			local v = hash(x, y, 77) < 0.12 and 1 or 2
			if y == 15 then v = 1 end
			put(c, x, y, "SHADOW", v)
		end
	end
	for x = 0, 15 do if hash(x, 3, 9) < 0.5 then put(c, x, 0, "VEIL", 3) end end
	for _, s in ipairs(LAYOUTS[p.layout]) do shard(c, s[1], s[2], s[3], s[4], s[5], p.pulse) end
	c.glows[#c.glows + 1] = { 8, 9, 10, 0.12 + p.pulse * 0.12 }
	return K.render(c, false)
end

-- Quebra: estilhaços voando para fora a partir do centro de um quadro 32x32 (o bloco fica no meio).
local function shatter(p)
	local c = K.canvas(32, 32)
	local k = p.k
	for i = 1, 14 do
		local a = hash(i, 1, 5) * math.pi * 2
		local spd = 6 + hash(i, 2, 5) * 12
		local x = 16 + math.cos(a) * spd * k * 1.4
		local y = 16 + math.sin(a) * spd * k * 1.4 + k * k * 10
		local sz = (hash(i, 3, 5) < 0.4) and 2 or 1
		if k < 0.95 then
			for dx = 0, sz - 1 do for dy = 0, sz - 1 do put(c, x + dx, y + dy, "CRIM", (i % 3 == 0) and 6 or (k < 0.5 and 5 or 4)) end end
		end
	end
	-- Clarão no começo.
	if k < 0.15 then ellipse(c, 16, 16, 5, 5, "CRIM", 6, 220) end
	return K.render(c, false)
end

---------------------------------------------------------------------------
-- Rachadura: fenda no chão que acende e solta uma coluna de energia.
---------------------------------------------------------------------------
local FEET = 44
local CRACK = { { 1, 1 }, { 3, 2 }, { 5, 1 }, { 7, 3 }, { 9, 2 }, { 11, 4 }, { 13, 2 }, { 15, 3 } }

local function crack(p)
	local c = K.canvas(16, 56)
	local glow = p.glow or 0      -- 0..1
	-- Fenda no chão: linha quebrada e um galho para baixo.
	for i = 1, #CRACK - 1 do
		local a, b = CRACK[i], CRACK[i + 1]
		thick(c, a[1], FEET + a[2], b[1], FEET + b[2], 0.5, glow > 0.05 and "CRIM" or "SHADOW", glow > 0.05 and math.floor(2 + glow * 4) or 1)
	end
	thick(c, 7, FEET + 3, 6, FEET + 8, 0.5, glow > 0.05 and "CRIM" or "SHADOW", glow > 0.05 and math.floor(1 + glow * 3) or 1)
	if glow > 0.3 then
		-- Brasas saindo da fenda.
		for i = 1, math.floor(glow * 6) do
			put(c, 2 + hash(i, p.seed or 0, 3) * 12, FEET - 1 - hash(i, p.seed or 0, 4) * glow * 8, "CRIM", 5)
		end
		c.glows[#c.glows + 1] = { 8, FEET + 2, 8, glow * 0.5 }
	end
	-- Coluna de energia.
	local col = p.col or 0          -- altura (0..1)
	local fade = p.fade or 0
	if col > 0 then
		local h = math.floor(40 * col)
		local half = 4 - fade * 2
		for y = FEET - h, FEET + 1 do
			local wob = math.floor(math.sin(y * 0.45 + (p.seed or 0)) * 0.7 + (hash(y, p.seed or 0, 6) - 0.5) * 1.2 + 0.5)
			for x = 8 - half + wob, 8 + half + wob - 1 do
				local edge = math.abs(x - 7.5 - wob)
				local l = edge < 1.2 and 6 or (edge < 2.5 and 5 or 4)
				if fade > 0 and hash(x, y, 11 + (p.seed or 0)) < fade * 0.8 then l = 0 end
				if l > 0 then put(c, x, y, "CRIM", l, math.floor(255 * (1 - fade * 0.5))) end
			end
		end
		-- Ponta irregular.
		for i = 0, 3 do put(c, 6 + i, FEET - h - 1 - (i % 2), "CRIM", 5) end
		c.glows[#c.glows + 1] = { 8, FEET - h / 2, 14, 0.4 * (1 - fade) }
	end
	return K.render(c, false)
end

---------------------------------------------------------------------------
local function pulse_frames(layout)
	local f = {}
	for i, pv in ipairs({ 0, 0, 1, 0 }) do f[i] = { layout = layout, pulse = pv } end
	return f
end

K.build(16, 16, {
	{ name = "idle_a", fps = 4, frames = pulse_frames("a") },
	{ name = "idle_b", fps = 4, frames = pulse_frames("b") },
	{ name = "idle_c", fps = 4, frames = pulse_frames("c") },
}, crystal, SRC .. "coracao_da_fenda_cristal.aseprite", OUT, "cristal")

K.build(32, 32, {
	{ name = "shatter", fps = 16, frames = { { k = 0.05 }, { k = 0.2 }, { k = 0.38 }, { k = 0.56 }, { k = 0.74 }, { k = 0.9 } } },
}, shatter, SRC .. "coracao_da_fenda_cristal_quebra.aseprite", OUT, "cristal")

K.build(16, 56, {
	{ name = "idle", fps = 1, frames = { { glow = 0 } } },
	{ name = "warn", fps = 6, frames = { { glow = 0.25, seed = 1 }, { glow = 0.5, seed = 2 }, { glow = 0.75, seed = 3 }, { glow = 1, seed = 4 } } },
	{ name = "burst", fps = 14, frames = {
		{ glow = 1, col = 0.4, seed = 1 }, { glow = 1, col = 1, seed = 2 }, { glow = 1, col = 1, seed = 3 },
		{ glow = 0.8, col = 0.95, fade = 0.4, seed = 4 }, { glow = 0.4, col = 0.85, fade = 0.8, seed = 5 } } },
}, crack, SRC .. "coracao_da_fenda_rachadura.aseprite", OUT, "rachadura")
