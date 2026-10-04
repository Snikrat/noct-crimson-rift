-- Inimigos novos da expansão (docs/expansao_forma_demoniaca.md, seção 2), desenhados por script no Aseprite:
--   Lamento (32x40), Miragem (32x48, pés na 46), Sanguessuga de alma (24x24) e Faminto da Fenda (64x40, pés na 38).
-- Fontes: art_source/inimigos/<nome>.aseprite (uma tag por animação). Jogo: assets/enemies/expansao/<nome>_<anim>.png.
-- Todos olham para a direita. Rodar na raiz do projeto:
--   Aseprite.exe -b --script tools/make_new_enemies.lua

local K = dofile(app.fs.joinPath(app.fs.filePath(debug.getinfo(1).source:sub(2)), "pixel_kit.lua"))
local put, poly, ellipse, thick, curve, erase, get, hash = K.put, K.poly, K.ellipse, K.thick, K.curve, K.erase, K.get, K.hash
local OUT = "assets/enemies/expansao/"
local SRC = "art_source/inimigos/"
local TAU = math.pi * 2

local function frames(n, fn)
	local list = {}
	for i = 0, n - 1 do list[#list + 1] = fn(i, i / n) end
	return list
end

---------------------------------------------------------------------------
-- Lamento: espectro pequeno de pano rasgado, capuz com o rosto oco, chorando.
---------------------------------------------------------------------------
local function lamento(p)
	local c = K.canvas(32, 40)
	local t = p.t
	local bob = math.floor(math.sin(t * TAU) * 1.5 + 0.5)
	local tip = 7 + math.sin(t * TAU + 1) * 3
	local A = 215
	-- Mortalha: ombros, barriga e cauda rasgada que ondula para trás.
	local function fold(x, y)
		local f = math.sin(x * 0.9 + y * 0.25 - t * TAU)
		return f > 0.4 and 4 or (f < -0.5 and 2 or 3)
	end
	poly(c, { { 9, 15 + bob }, { 22, 15 + bob }, { 24, 23 + bob }, { 19, 31 + bob }, { tip, 37 }, { 10, 30 + bob }, { 8, 23 + bob } }, "PALE", fold, A)
	-- Rasgos na barra.
	for x = 6, 25 do
		for y = 26, 39 do
			if get(c, x, y) and hash(x, y, 5) < 0.18 + (y - 26) * 0.03 then erase(c, x, y) end
		end
	end
	-- Braço de pano caído na frente (cobrindo o choro).
	thick(c, 20, 18 + bob, 24, 23 + bob, 1.2, "PALE", 4, A)
	put(c, 25, 24 + bob, "PALE", 5)
	-- Capuz e rosto oco.
	ellipse(c, 16, 11 + bob, 6.5, 7, "PALE", function(x, y, dx, dy) return (dx < -0.2 and dy < 0) and 5 or 4 end, A)
	ellipse(c, 18.5, 12 + bob, 3, 4, "SHADOW", 1)
	put(c, 17, 11 + bob, "SOUL", 5); put(c, 20, 11 + bob, "SOUL", 5)     -- olhos
	put(c, 18, 14 + bob, "SHADOW", 1); put(c, 19, 15 + bob, "SHADOW", 1) -- boca aberta
	-- Lágrima caindo.
	local ty = 13 + bob + math.floor((t * 12) % 12)
	if ty < 34 then put(c, 17, ty, "SOUL", 5); put(c, 17, ty - 1, "SOUL", 3) end
	c.glows[#c.glows + 1] = { 18, 12 + bob, 8, 0.35, 111, 163, 224 }
	return K.render(c)
end

---------------------------------------------------------------------------
-- Miragem: silhueta de costas (casaco, cabelo bagunçado), luz fria de um lado e carmesim do outro.
---------------------------------------------------------------------------
local function miragem(p)
	local c = K.canvas(32, 48)
	local lean = p.lean or 0
	local bob = p.bob or 0
	local step = p.step or 0
	local crouch = p.crouch or 0
	local top = 6 + bob + crouch * 3
	-- Pernas.
	thick(c, 14 + lean * 0.3, 33 + crouch * 2, 13 - step, 45, 1.6, "SHADOW", 2)
	thick(c, 18 + lean * 0.3, 33 + crouch * 2, 19 + step, 45, 1.6, "SHADOW", 2)
	put(c, 12 - step, 46, "SHADOW", 2); put(c, 20 + step, 46, "SHADOW", 2)
	-- Casaco até o joelho, com fendas.
	local function fold(x, y) return (math.sin(x * 1.1) > 0.3) and 3 or 2 end
	poly(c, { { 10 + lean, top + 12 }, { 22 + lean, top + 12 }, { 24 + lean * 0.5, 37 }, { 8 + lean * 0.5, 37 } }, "SHADOW", fold)
	erase(c, 16 + lean * 0.5, 36); erase(c, 16 + lean * 0.5, 35)
	-- Braços.
	local ar = p.arms or 0
	thick(c, 10 + lean, top + 13, 9 + lean * 0.6 - ar, top + 25 - ar * 3, 1.4, "SHADOW", 3)
	thick(c, 22 + lean, top + 13, 23 + lean * 0.6 + ar, top + 25 - ar * 3, 1.4, "SHADOW", 3)
	-- Pescoço, cabeça (de costas) e cabelo em mechas.
	thick(c, 16 + lean, top + 9, 16 + lean, top + 12, 1.4, "SHADOW", 3)
	ellipse(c, 16 + lean, top + 5, 4.5, 5, "SHADOW", 3)
	for i, s in ipairs({ { -4, -2 }, { -2, -5 }, { 1, -6 }, { 3, -4 }, { 5, -1 } }) do
		thick(c, 16 + lean, top + 4, 16 + lean + s[1], top + 4 + s[2], 0.6, "SHADOW", 3)
	end
	-- Luz de borda: fria à direita, um fio carmesim à esquerda.
	local rim = {}
	for y = 0, 47 do
		for x = 0, 31 do
			if get(c, x, y) then
				if not get(c, x + 1, y) then rim[#rim + 1] = { x, y, "PALE", 3 }
				elseif not get(c, x - 1, y) and y < 37 then rim[#rim + 1] = { x, y, "CRIM", 1 } end
			end
		end
	end
	for _, r in ipairs(rim) do put(c, r[1], r[2], r[3], r[4]) end
	if p.smear then
		for i = 1, 14 do
			put(c, 4 + hash(i, 1, 3) * 8, 14 + hash(i, 2, 3) * 26, "SMEAR", 2)
		end
	end
	return K.render(c)
end

---------------------------------------------------------------------------
-- Sanguessuga de alma: bolsa translúcida cheia de luz azul roubada, com gavinhas.
---------------------------------------------------------------------------
local function sanguessuga(p)
	local c = K.canvas(24, 24)
	local cx, cy = 12, p.cy or 12
	local rx, ry = p.rx or 6.5, p.ry or 7
	if p.stalk then thick(c, 12, 0, 12, cy - ry + 1, 0.6, "FLESH", 3) end
	-- Gavinhas (presas).
	for i, a in ipairs(p.tendrils or { 2.0, 1.57, 1.14 }) do
		local x0, y0 = cx + math.cos(a) * rx * 0.8, cy + math.sin(a) * ry * 0.8
		local len = p.tlen or 5
		local bend = math.sin((p.t or 0) * TAU + i * 2) * 1.5
		curve(c, { x0, y0 }, { x0 + math.cos(a) * len * 0.6 + bend, y0 + math.sin(a) * len * 0.6 },
			{ x0 + math.cos(a) * len, y0 + math.sin(a) * len - bend }, 0.6, 0.4, "FLESH", 4)
	end
	-- Membrana translúcida, veias escuras e a luz roubada dentro.
	ellipse(c, cx, cy, rx, ry, "PALE", function(x, y, dx, dy) return (dx < -0.3 and dy < -0.2) and 4 or 2 end, 205)
	for v = 0, 2 do
		local a = v * 2.1 + 0.4
		for r = 2, math.floor(rx) do
			put(c, cx + math.cos(a + r * 0.2) * r, cy + math.sin(a + r * 0.2) * r * (ry / rx), "SHADOW", 3)
		end
	end
	local pw = p.power or 1
	ellipse(c, cx + 0.5, cy + 1, rx * 0.55, ry * 0.55, "SOUL", function(x, y, dx, dy) return (dx * dx + dy * dy < 0.3) and 6 or 4 end)
	put(c, cx - 2, cy - 3, "SOUL", 6)
	c.glows[#c.glows + 1] = { cx, cy + 1, 7 + pw * 2, 0.25 + pw * 0.1, 111, 163, 224 }
	return K.render(c)
end

---------------------------------------------------------------------------
-- Faminto da Fenda: cão sem pele, costelas à mostra, cristais carmesim nas costas.
---------------------------------------------------------------------------
local function lerp(a, b, t) return a + (b - a) * t end

local function faminto(p)
	local c = K.canvas(64, 40)
	local s = p.sleep or 0          -- 1 = enrolado dormindo
	local bob = p.bob or 0
	local ph = p.phase or 0         -- passada
	local bx, by = 30 + (p.dx or 0), lerp(22, 30, s) + bob
	local hx, hy = lerp(48, 42, s) + (p.hx or 0), lerp(17, 31, s) + bob + (p.hy or 0)
	local jaw = p.jaw or 0
	local pw = p.power or 1
	-- Cauda.
	local wag = math.sin(ph * TAU) * 2
	curve(c, { bx - 13, by - 2 }, { bx - 19, by - 6 + wag }, { bx - 24 + s * 6, by - 4 + wag + s * 6 }, 1.6, 0.5, "FLESH", 3)
	-- Pernas de trás (a de longe mais escura).
	local function leg(x0, y0, swing, far)
		local knee = { x0 + swing * 0.5 + 2, y0 + 7 }
		local paw = { x0 + swing, 38 }
		if s > 0.5 then knee = { x0 + 5, by + 5 }; paw = { x0 + 9, by + 7 } end
		thick(c, x0, y0, knee[1], knee[2], 1.8, "FLESH", far and 1 or 3)
		thick(c, knee[1], knee[2], paw[1], paw[2], 1.3, "FLESH", far and 1 or 3)
		put(c, paw[1] + 1, paw[2], "BONE", far and 1 or 2)
	end
	local sw = math.sin(ph * TAU) * 6
	leg(bx - 10, by + 3, -sw, true)
	leg(bx + 10, by + 3, sw, true)
	-- Tronco magro com costelas.
	ellipse(c, bx, by, 14, lerp(7, 6, s), "FLESH", function(x, y, dx, dy)
		local f = math.sin(x * 1.3)
		return (dy < -0.3) and 4 or (f > 0.6 and 2 or 3)
	end)
	for i = 0, 4 do
		local rx = bx - 2 + i * 3
		thick(c, rx, by + 1, rx - 1, by + 5, 0.5, "BONE", 2)
	end
	-- Cristais carmesim nas costas.
	for i, cr in ipairs({ { -8, 5 }, { -3, 8 }, { 2, 6 }, { 7, 9 }, { 11, 5 } }) do
		local x0 = bx + cr[1]
		local y0 = by - lerp(6, 5, s)
		local hgt = cr[2] * (0.6 + 0.4 * math.min(pw, 2) / 2)
		local tilt = -1.5 - s * 2
		poly(c, { { x0 - 1.5, y0 }, { x0 + 1.5, y0 }, { x0 + tilt + 0.5, y0 - hgt }, { x0 + tilt - 0.5, y0 - hgt + 1 } }, "CRIM",
			function(x, y) return (y < y0 - hgt * 0.6) and 6 or ((x < x0) and 3 or 4) end)
	end
	c.glows[#c.glows + 1] = { bx, by - 8, 14, 0.12 + pw * 0.12 }
	-- Pernas da frente.
	leg(bx - 8, by + 4, sw, false)
	leg(bx + 11, by + 4, -sw, false)
	-- Pescoço e cabeça: crânio com o focinho comprido e a mandíbula.
	thick(c, bx + 10, by - 2, hx - 3, hy + 1, 3, "FLESH", 3)
	ellipse(c, hx, hy, 6, 4.5, "FLESH", function(x, y, dx, dy) return dy < -0.2 and 4 or 3 end)
	poly(c, { { hx + 2, hy - 3 }, { hx + 11, hy }, { hx + 11, hy + 2 }, { hx + 2, hy + 2 } }, "FLESH", 3)
	-- Mandíbula (abre ao morder) e dentes.
	local jy = hy + 3 + jaw * 4
	poly(c, { { hx + 1, hy + 2 }, { hx + 10, jy }, { hx + 9, jy + 2 }, { hx, hy + 4 } }, "FLESH", 2)
	for i = 0, 3 do
		put(c, hx + 4 + i * 2, hy + 3, "BONE", 4)
		if jaw > 0.3 then put(c, hx + 3 + i * 2, jy, "BONE", 3) end
	end
	put(c, hx + 1, hy - 4, "BONE", 3); put(c, hx - 1, hy - 5, "BONE", 3)   -- orelha de osso
	if s < 0.7 then
		put(c, hx + 2, hy - 1, "CRIM", 6); put(c, hx + 3, hy - 1, "CRIM", 5)
	else
		put(c, hx + 2, hy - 1, "FLESH", 1)   -- olho fechado dormindo
	end
	return K.render(c)
end

---------------------------------------------------------------------------
-- Animações
---------------------------------------------------------------------------
K.build(32, 40, {
	{ name = "fly", fps = 8, frames = frames(6, function(i, t) return { t = t } end) },
}, lamento, SRC .. "lamento.aseprite", OUT, "lamento")

K.build(32, 48, {
	{ name = "idle", fps = 4, frames = frames(4, function(i, t) return { bob = (i == 1 or i == 2) and 1 or 0, arms = 0 } end) },
	{ name = "windup", fps = 8, frames = { { crouch = 0.5, lean = -1, arms = 1 }, { crouch = 1, lean = -2, arms = 2 } } },
	{ name = "lunge", fps = 10, frames = { { lean = 4, step = 3, arms = 2, smear = true }, { lean = 5, step = 4, arms = 3, smear = true } } },
}, miragem, SRC .. "miragem.aseprite", OUT, "miragem")

K.build(24, 24, {
	{ name = "hang", fps = 6, frames = frames(4, function(i, t)
		local k = math.sin(t * TAU)
		return { t = t, stalk = true, rx = 6.5 - k * 0.4, ry = 7 + k * 0.5, power = 1 }
	end) },
	{ name = "fall", fps = 10, frames = { { t = 0, cy = 12, rx = 5.5, ry = 8, tendrils = { -2.0, -1.57, -1.14 }, tlen = 4 },
		{ t = 0.5, cy = 12, rx = 5.5, ry = 8.5, tendrils = { -2.1, -1.57, -1.04 }, tlen = 5 } } },
	{ name = "crawl", fps = 8, frames = frames(4, function(i, t)
		return { t = t, cy = 17, rx = 7.5 + math.sin(t * TAU) * 0.6, ry = 5, tendrils = { 2.6, 1.8, 1.3, 0.5 }, tlen = 4 }
	end) },
	{ name = "latched", fps = 10, frames = frames(4, function(i, t)
		return { t = t, cy = 12, rx = 8 + math.sin(t * TAU) * 0.5, ry = 6, tendrils = { 3.0, 2.2, 0.9, 0.1 }, tlen = 6, power = 2 }
	end) },
}, sanguessuga, SRC .. "sanguessuga.aseprite", OUT, "sanguessuga")

K.build(64, 40, {
	{ name = "sleep", fps = 3, frames = frames(4, function(i, t) return { sleep = 1, bob = (i == 1 or i == 2) and 1 or 0, power = 0.4 } end) },
	{ name = "wake", fps = 8, frames = frames(4, function(i, t) return { sleep = 1 - (i + 1) / 4, power = 0.6 + i * 0.5, jaw = (i == 3) and 0.6 or 0 } end) },
	{ name = "idle", fps = 6, frames = frames(4, function(i, t) return { phase = t * 0.15, bob = (i == 1 or i == 2) and 1 or 0, power = 1.4 } end) },
	{ name = "run", fps = 14, frames = frames(6, function(i, t)
		return { phase = t, bob = math.floor(math.sin(t * TAU * 2) * 1.5 + 0.5), hy = 1, power = 1.8 }
	end) },
	{ name = "bite", fps = 14, frames = {
		{ hx = -3, hy = -2, jaw = 0.3, power = 1.8 }, { hx = -4, hy = -3, jaw = 0.8, power = 2 },
		{ hx = 4, hy = 1, jaw = 1, dx = 3, phase = 0.25, power = 2.2 }, { hx = 3, hy = 1, jaw = 0, dx = 3, phase = 0.25, power = 2 },
		{ hx = 0, jaw = 0, power = 1.6 } } },
}, faminto, SRC .. "faminto.aseprite", OUT, "faminto")
