-- Noct v2: recriação no Aseprite a partir do noct_v1.aseprite (remaster), fiel ao design.
-- Gera art_source/personagem principal/noct_v2.aseprite com duas camadas:
--   corpo: o personagem com paleta enxuta (uma rampa por material), sem pixels soltos;
--   vfx:   a energia carmesim separada do corpo.
-- Etapa 1 (esta): idle, idle_var (variação) e run.
--
-- Uso (na pasta do projeto): Aseprite.exe -b --script tools/noct_v2.lua

local root = app.fs.currentPath
-- Fonte congelada: o noct.aseprite do remaster (antes do v2 entrar no jogo).
local src_path = app.fs.joinPath(root, "art_source", "personagem principal", "noct_v1.aseprite")
local out_path = app.fs.joinPath(root, "art_source", "personagem principal", "noct_v2.aseprite")
local PALETTE_SIZE = 32

local pc = app.pixelColor
local src = app.open(src_path)
local W, H = src.width, src.height

local function tag(name)
  for _, t in ipairs(src.tags) do if t.name == name then return t end end
end

local function frame_image(n)
  local img = Image(W, H, ColorMode.RGB)
  img:drawSprite(src, n)
  return img
end

local function frames_of(name)
  local t, list = tag(name), {}
  for i = 0, t.frames - 1 do table.insert(list, frame_image(t.fromFrame.frameNumber + i)) end
  return list
end

-- Linha dos pés (última linha com pixels).
local function feet(img)
  for y = H - 1, 0, -1 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then return y end
    end
  end
  return H - 1
end

-- Energia carmesim (rosa/vermelho vivo). As botas têm vermelho escuro: a faixa dos pés não entra.
local function is_energy(c, y, feet_y)
  local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
  if pc.rgbaA(c) == 0 then return false end
  if r > 150 and g < 90 and r > b * 1.2 then return true end
  return y < feet_y - 9 and r >= 110 and g < 40 and r > g * 3 and b < 90
end

-- Separa corpo e energia.
local function split(img)
  local body, vfx = img:clone(), Image(W, H, ColorMode.RGB)
  local fy = feet(img)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if is_energy(c, y, fy) then
        vfx:drawPixel(x, y, c)
        body:drawPixel(x, y, pc.rgba(0, 0, 0, 0))
      end
    end
  end
  return body, vfx
end

-- Paleta enxuta: o quantizador do Aseprite sobre todos os quadros do corpo.
local function build_palette(images)
  local tmp = Sprite(W, H * #images, ColorMode.RGB)
  local sheet = Image(W, H * #images, ColorMode.RGB)
  for i, img in ipairs(images) do sheet:drawImage(img, Point(0, (i - 1) * H)) end
  tmp:newCel(tmp.layers[1], tmp.frames[1], sheet, Point(0, 0))
  app.command.ColorQuantization{ ui = false, withAlpha = false, maxColors = PALETTE_SIZE }
  local pal = {}
  local p = tmp.palettes[1]
  for i = 0, #p - 1 do
    local c = p:getColor(i)
    if c.alpha > 0 then table.insert(pal, { c.red, c.green, c.blue }) end
  end
  tmp:close()
  return pal
end

local function nearest(pal, c)
  local r, g, b = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
  local best, bd = pal[1], math.huge
  for _, p in ipairs(pal) do
    -- Distância "redmean": aproxima a percepção sem puxar marrons escuros para o carmesim.
    local rm = (p[1] + r) / 2
    local dr, dg, db = p[1] - r, p[2] - g, p[3] - b
    local d = (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db
    if d < bd then bd, best = d, p end
  end
  return pc.rgba(best[1], best[2], best[3], 255)
end

-- Aplica a paleta e tira pixels soltos (cor sem nenhum vizinho igual vira a cor vizinha mais comum).
local function clean(img, pal)
  local out = img:clone()
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 and pal then out:drawPixel(x, y, nearest(pal, c)) end
    end
  end
  local res = out:clone()
  for y = 1, H - 2 do
    for x = 1, W - 2 do
      local c = out:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local same, count, best, bestn = false, {}, nil, 0
        for dy = -1, 1 do
          for dx = -1, 1 do
            if not (dx == 0 and dy == 0) then
              local n = out:getPixel(x + dx, y + dy)
              if n == c then same = true end
              if pc.rgbaA(n) > 0 then
                count[n] = (count[n] or 0) + 1
                if count[n] > bestn then bestn, best = count[n], n end
              end
            end
          end
        end
        -- Só limpa dentro do desenho (com 5+ vizinhos), para não comer contorno nem pontas.
        if not same and best and bestn >= 3 then
          local opaque = 0
          for _, v in pairs(count) do opaque = opaque + v end
          if opaque >= 7 then res:drawPixel(x, y, best) end
        end
      end
    end
  end
  return res
end

-- Desloca para cima as linhas [y0, y1] (respiração: peito e cabeça sobem 1 px).
local function lift(img, y0, y1, dy)
  local out = img:clone()
  if dy < 0 then   -- descendo: a linha de cima fica vazia
    for y = y0, y0 - dy - 1 do
      for x = 0, W - 1 do out:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end
    end
  end
  for y = y0, y1 do
    for x = 0, W - 1 do out:drawPixel(x, y - dy, img:getPixel(x, y)) end
  end
  return out
end

-- Topo do desenho.
local function top(img)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then return y end
    end
  end
  return 0
end

-------------------------------------------------------------------------------
local idle_src, run_src = frames_of("idle"), frames_of("run")
local bodies, vfxs = {}, {}
for i, img in ipairs(idle_src) do bodies["idle" .. i], vfxs["idle" .. i] = split(img) end
for i, img in ipairs(run_src) do bodies["run" .. i], vfxs["run" .. i] = split(img) end
local all = {}
for _, img in ipairs(idle_src) do table.insert(all, img) end
for _, img in ipairs(run_src) do table.insert(all, img) end
-- Paleta do Noct v2: rampas fixas por material, escolhidas entre as cores do próprio Idle
-- (um quantizador automático juntava óculos e sombra da pele com o carmesim).
local function hex(h) return { tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16) } end
local RAMPS = {
  contorno = { "#120610" },
  roupa = { "#190c19", "#22141e", "#2e1e2a", "#3d2635", "#46373e" },     -- regata, calça
  cabelo = { "#230d1b", "#2e161d", "#451821", "#4d2525", "#5f2d3a" },    -- cabelo, sombra quente
  pele = { "#6c3329", "#85543f", "#a55b40", "#c17247", "#d08257", "#e98e5a" },
  corrente = { "#695a5e", "#89636a", "#9d8481" },
  botas = { "#1f0712", "#320514", "#470721", "#5f0622", "#850a2f" },
  logo = { "#7e212a", "#a6232c", "#bd1a45", "#ee3f6f" },
  tatuagem = { "#5e4346", "#7f3b2b", "#854743", "#a2492e" },
}
local pal = {}
for _, ramp in pairs(RAMPS) do for _, h in ipairs(ramp) do table.insert(pal, hex(h)) end end

-- Energia que fica por fora do corpo (não cobre o punho/braço desenhado no quadro do corpo).
local function aura_outside(vfx, body)
  local out = Image(W, H, ColorMode.RGB)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = vfx:getPixel(x, y)
      if pc.rgbaA(c) > 0 and pc.rgbaA(body:getPixel(x, y)) == 0 then out:drawPixel(x, y, c) end
    end
  end
  return out
end

-- IDLE: um corpo só (quadro 1 limpo), respirando: peito e cabeça sobem 1 px no meio do ciclo.
-- A energia dos punhos usa os quadros com brilho do Idle original (antes o brilho piscava).
local base = clean(bodies.idle1, pal)
-- O corpo do Idle fica com os punhos inteiros (a energia do próprio quadro faz parte da mão).
base = clean(idle_src[1], pal)
-- Retoques à mão no Idle (a base de todo o Noct v2). O Noct não usa óculos: a faixa escura
-- dos olhos (sobra das pranchas) vira pele com o olho, e o brinco fica destacado.
local RETOQUES = {
  {48, 28, "#a55b40"}, {49, 28, "#c17247"}, {50, 28, "#2e161d"}, {51, 28, "#85543f"},
  {50, 29, "#c17247"}, {51, 29, "#6c3329"},
  {46, 31, "#9d8481"},
}
for _, r in ipairs(RETOQUES) do
  local c = hex(r[3])
  base:drawPixel(r[1], r[2], pc.rgba(c[1], c[2], c[3], 255))
end
local t0 = top(base)

-- Cabeça menor (pedido: a cabeça destoava do corpo): o volume do cabelo perde 1 linha (no meio
-- do cabelo) e 1 coluna (na nuca). Rosto, óculos e queixo ficam como estão.
local function shrink_head(img, head_top)
  local out = img:clone()
  local hx0, hx1 = W, 0
  for y = head_top, head_top + 10 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then hx0 = math.min(hx0, x); hx1 = math.max(hx1, x) end
    end
  end
  local cut_row = head_top + 2            -- linha de cabelo que sai
  for y = cut_row, head_top + 1, -1 do
    for x = hx0 - 1, hx1 + 1 do out:drawPixel(x, y, out:getPixel(x, y - 1)) end
  end
  for x = hx0 - 1, hx1 + 1 do out:drawPixel(x, head_top, pc.rgba(0, 0, 0, 0)) end
  local cut_col = hx0 + 2                 -- coluna de cabelo da nuca que sai
  for y = head_top, head_top + 5 do
    for x = cut_col, hx0, -1 do out:drawPixel(x, y, out:getPixel(x - 1, y)) end
    out:drawPixel(hx0 - 1, y, pc.rgba(0, 0, 0, 0))
  end
  return out
end
base = shrink_head(base, t0)

-- Respiração: cabeça e peito sobem 1 px juntos, no mesmo quadro, devagar (a cintura fica parada).
-- grow_top (subpixel: só o contorno de cima cresce) fica disponível para outras animações.
local chest = t0 + 17
local function grow_top(img, y0, y1)
  local out = img:clone()
  for x = 0, W - 1 do
    for y = math.max(1, y0), y1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        if pc.rgbaA(img:getPixel(x, y - 1)) == 0 then out:drawPixel(x, y - 1, c) end
        break
      end
    end
  end
  return out
end
-- (Testado e descartado: a versão subpixel ficou sutil demais.) Cabeça e peito sobem 1 px juntos.
local breath = lift(base, t0, chest, 1)
local idle_body = { base, base, breath, breath }
local idle_vfx = { aura_outside(vfxs.idle2, base), aura_outside(vfxs.idle4, base),
  aura_outside(vfxs.idle6, breath), aura_outside(vfxs.idle4, breath) }

-- IDLE_VAR: o Noct abaixa a cabeça (cansaço), fica e volta. Cabeça = 11 linhas do topo.
local head_down = lift(base, t0 + 1, t0 + 10, -1)
local idle_var_body = { base, head_down, head_down, head_down, base }
local idle_var_vfx = { idle_vfx[1], idle_vfx[2], idle_vfx[2], idle_vfx[1], idle_vfx[1] }

-- CABEÇA DO NOCT: a cabeça do Idle v2 (sem óculos, com brinco, cabelo menor) vira um carimbo e
-- substitui a cabeça das outras animações, para ser sempre a mesma cabeça.
local HEAD_ROWS = 11
local function head_stamp(img)
  local ht = top(img)
  local stamp = Image(W, HEAD_ROWS, ColorMode.RGB)
  local front = 0
  for y = 0, HEAD_ROWS - 1 do
    for x = 0, W - 1 do
      local c = img:getPixel(x, ht + y)
      if pc.rgbaA(c) > 0 then
        stamp:drawPixel(x, y, c)
        if y >= 5 and y <= 7 then front = math.max(front, x) end
      end
    end
  end
  return { img = stamp, front = front }
end
local HEAD = head_stamp(base)

-- Troca a cabeça de um quadro pela cabeça do Noct v2, alinhando topo e frente do rosto.
local function put_head(img)
  local ht = top(img)
  local front, back = 0, W
  for y = ht + 5, ht + 7 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then front = math.max(front, x) end
    end
  end
  for y = ht, ht + 3 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then back = math.min(back, x) end
    end
  end
  local out = img:clone()
  -- Apaga a cabeça antiga (linhas da cabeça, da nuca até a frente do rosto).
  for y = ht, ht + HEAD_ROWS - 2 do
    for x = back - 1, front + 1 do out:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end
  end
  local dx = front - HEAD.front
  for y = 0, HEAD_ROWS - 1 do
    for x = 0, W - 1 do
      local c = HEAD.img:getPixel(x, y)
      if pc.rgbaA(c) > 0 then out:drawPixel(x + dx, ht + y, c) end
    end
  end
  return out
end

-- Apaga pedacinhos soltos (menos de "limit" pixels sem encostar no resto): sobras de recorte.
local function drop_specks(img, limit)
  local out, seen = img:clone(), {}
  for sy = 0, H - 1 do
    for sx = 0, W - 1 do
      local k = sy * W + sx
      if not seen[k] and pc.rgbaA(img:getPixel(sx, sy)) > 0 then
        local stack, comp = { { sx, sy } }, {}
        seen[k] = true
        while #stack > 0 do
          local p = table.remove(stack)
          table.insert(comp, p)
          for dy = -1, 1 do for dx = -1, 1 do
            local nx, ny = p[1] + dx, p[2] + dy
            if nx >= 0 and ny >= 0 and nx < W and ny < H and not seen[ny * W + nx]
              and pc.rgbaA(img:getPixel(nx, ny)) > 0 then
              seen[ny * W + nx] = true
              table.insert(stack, { nx, ny })
            end
          end end
        end
        if #comp < limit then
          for _, p in ipairs(comp) do out:drawPixel(p[1], p[2], pc.rgba(0, 0, 0, 0)) end
        end
      end
    end
  end
  return out
end

-- Tira os fiapos de energia soltos em volta do corpo (energia com poucos vizinhos de corpo),
-- sem mexer no logo da regata nem no brilho que fica dentro da mão.
local function remove_wisps(img)
  local out = img
  for _ = 1, 2 do
    local fy = feet(out)
    local res = out:clone()
    for y = 1, H - 2 do
      for x = 1, W - 2 do
        local c = out:getPixel(x, y)
        if is_energy(c, y, fy) then
          local solid = 0
          for dy = -1, 1 do for dx = -1, 1 do
            local n = out:getPixel(x + dx, y + dy)
            if pc.rgbaA(n) > 0 and not is_energy(n, y + dy, fy) then solid = solid + 1 end
          end end
          if solid < 3 then res:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end
        end
      end
    end
    out = res
  end
  return out
end

-- RUN: os 8 quadros limpos com a mesma paleta e a cabeça do Noct v2; energia na camada separada.
local run_body, run_vfx = {}, {}
-- Corrida mais limpa: sem os fiapos de energia nas costas (piscavam a cada quadro) e com um
-- balanço regular: cabeça embaixo nos dois apoios (quadros 1 e 5) e 1 px acima nos outros.
local RUN_BOB = { 0, -1, -1, -1, 0, -1, -1, -1 }
local run_top = {}
for i = 1, #run_src do
  run_body[i] = put_head(clean(drop_specks(remove_wisps(run_src[i]), 10), pal))
  run_vfx[i] = Image(W, H, ColorMode.RGB)
  run_top[i] = top(run_body[i])
end
local low = 0
for i = 1, #run_top do low = math.max(low, run_top[i]) end
for i = 1, #run_body do
  local dy = run_top[i] - (low + RUN_BOB[i])   -- > 0: precisa subir; < 0: precisa descer
  if dy > 0 then
    local moved = Image(W, H, ColorMode.RGB)
    moved:drawImage(run_body[i], Point(0, -dy))   -- fase no ar: o corpo todo sobe
    run_body[i] = moved
  elseif dy < 0 then
    run_body[i] = lift(run_body[i], run_top[i], run_top[i] + 20, dy)   -- apoio: o tronco desce
  end
end

-- A corrida que vale no jogo é a ORIGINAL (a primeira, antes da remodelagem), a pedido: os 8
-- quadros de art_source/personagem principal/extra/run_original.png, sem nenhuma mudança, só
-- encaixados no quadro único com o ponto dos pés antigo (31, 41) no ponto dos pés do Noct v2.
-- A versão limpa acima continua servindo de base para o arranque (run_start).
local RUN_ORIGINAL = { w = 41, h = 42, ax = 31, ay = 41, frames = 8 }
local run_clean = run_body
local orig = Image{ fromFile = app.fs.joinPath(root, "art_source", "personagem principal", "extra", "run_original.png") }
local hero_meta = json.decode(io.open(app.fs.joinPath(root, "assets", "hero", "hero.json")):read("a"))
local OX, OY = hero_meta.idle.ax, hero_meta.idle.ay
run_body, run_vfx = {}, {}
for i = 0, RUN_ORIGINAL.frames - 1 do
  local img = Image(W, H, ColorMode.RGB)
  local part = Image(RUN_ORIGINAL.w, RUN_ORIGINAL.h, ColorMode.RGB)
  part:drawImage(orig, Point(-i * RUN_ORIGINAL.w, 0))
  img:drawImage(part, Point(OX - RUN_ORIGINAL.ax, OY - RUN_ORIGINAL.ay))
  run_body[i + 1] = img
  run_vfx[i + 1] = Image(W, H, ColorMode.RGB)
end

-- WALK: caminhada com a paleta e a cabeça do Noct v2.
local walk_body, walk_vfx = {}, {}
-- (A caminhada da prancha de movimentos ficou com outro traço e foi descartada.) A base é a
-- caminhada do nível carmesim 1 (c1_run), do mesmo traço do Idle: a chama do cabelo sai com a
-- cabeça do Noct v2 e a energia restante vai para a camada vfx.
for i, img in ipairs(frames_of("c1_run")) do
  local body, vfx = split(img)
  walk_body[i] = put_head(clean(drop_specks(body, 60), pal))
  -- Sem a chama do cabelo (a forma normal não tem): a energia acima dos ombros sai.
  local v = aura_outside(vfx, walk_body[i])
  local cut = top(walk_body[i]) + HEAD_ROWS + 2
  for y = 0, cut do for x = 0, W - 1 do v:drawPixel(x, y, pc.rgba(0, 0, 0, 0)) end end
  walk_vfx[i] = drop_specks(v, 3)
end

-------------------------------------------------------------------------------
local out = Sprite(W, H, ColorMode.RGB)
local lbody = out.layers[1]
lbody.name = "corpo"
local lvfx = out:newLayer()
lvfx.name = "vfx"
-- Paleta do projeto: as cores do corpo + as da energia.
out:setPalette(src.palettes[1])

local ranges, first = {}, true
local function add(name, bodies_, vfx_, fps)
  local start = nil
  for i = 1, #bodies_ do
    local fr
    if first then fr = out.frames[1]; first = false else fr = out:newEmptyFrame() end
    fr.duration = 1 / fps
    out:newCel(lbody, fr, bodies_[i], Point(0, 0))
    out:newCel(lvfx, fr, vfx_[i], Point(0, 0))
    start = start or fr.frameNumber
  end
  table.insert(ranges, { name, start, start + #bodies_ - 1 })
end
add("idle", idle_body, idle_vfx, 2)   -- respiração lenta: 0,5 s por quadro
add("idle_var", idle_var_body, idle_var_vfx, 2)
add("walk", walk_body, walk_vfx, 7)
add("run", run_body, run_vfx, 14)

-- DEMAIS ANIMAÇÕES: mesma limpeza e energia separada; a cabeça do Noct v2 entra onde a cabeça
-- está de pé no alto do desenho (HEAD_OK: true = todos os quadros, ou a lista dos quadros).
local REST = {
  "jump", "fall", "land", "double_jump", "dash", "crouch", "jab", "cross", "kick", "charged",
  "up_punch", "low_punch", "uppercut", "cast", "slam", "air_punch", "air_kick", "air_finish",
  "hurt", "death", "ultimate_charge", "ultimate_burst", "ultimate_pose",
}
-- Conferido quadro a quadro: onde a cabeça está deitada, inclinada ou coberta por energia
-- (punho/arco acima da cabeça), a cabeça original fica.
local function set(list) local t = {} for _, i in ipairs(list) do t[i] = true end return t end
local rest = {}
local HEAD_OK = {
  jump = true, fall = true, land = true, crouch = true, double_jump = true, jab = true, hurt = true,
  air_punch = true, air_kick = true, ultimate_charge = true,
  dash = set{1, 2, 3, 4, 5, 7, 8}, cross = set{1, 4}, kick = set{1, 2}, charged = set{1, 2},
  cast = set{1, 2, 3, 5, 6, 7, 8}, up_punch = set{1, 2, 3, 8}, uppercut = set{1, 2, 3, 8},
  low_punch = set{1, 2, 3, 6, 7}, slam = set{1}, air_finish = set{2, 3}, death = set{1, 3},
  ultimate_burst = set{1, 2, 8}, ultimate_pose = set{1, 2, 3},
}
for _, name in ipairs(REST) do
  local t = tag(name)
  local bodies_, vfx_ = {}, {}
  for i, img in ipairs(frames_of(name)) do
    local body, vfx = split(img)
    body = clean(drop_specks(body, 8), pal)
    local ok = HEAD_OK[name]
    if ok == true or (type(ok) == "table" and ok[i]) or app.params.all_heads then body = put_head(body) end
    bodies_[i] = body
    vfx_[i] = vfx
  end
  local fps = 1 / src.frames[t.fromFrame.frameNumber].duration
  if name == "land" then
    -- PULO COMPLETO, aterrissagem: o agachamento e depois a recuperação (o corpo do Idle v2
    -- encolhido 2 px na cintura, como os joelhos ainda dobrados) antes de voltar ao Idle.
    table.insert(bodies_, lift(base, t0, t0 + 24, -2))
    table.insert(vfx_, Image(W, H, ColorMode.RGB))
    fps = 14
  end
  rest[name] = { bodies_, vfx_, fps }
end
-- PULO COMPLETO, subida: impulso (o mesmo agachamento da aterrissagem, com a energia nos pés),
-- subida e topo.
table.insert(rest.jump[1], 1, rest.land[1][1])
table.insert(rest.jump[2], 1, rest.land[2][1])
rest.jump[3] = 12
-- COMBO NO CHÃO: o chute (golpe 3) ganha antecipação, a guarda do jab, para emendar sem pulo
-- de pose depois do cross.
table.insert(rest.kick[1], 1, rest.jab[1][1])
table.insert(rest.kick[2], 1, Image(W, H, ColorMode.RGB))
-- COMBO AÉREO: o chute aéreo ganha antecipação (o soco aéreo recolhido) e entra um golpe novo,
-- o corte giratório (air_spin): os quadros do pulo duplo em que a energia gira em volta do corpo.
table.insert(rest.air_kick[1], 1, rest.air_punch[1][1])
table.insert(rest.air_kick[2], 1, rest.air_punch[2][1])
rest.air_spin = { {}, {}, 22 }
for i = 3, 6 do
  table.insert(rest.air_spin[1], rest.double_jump[1][i])
  table.insert(rest.air_spin[2], rest.double_jump[2][i])
end
table.insert(REST, "air_spin")
-- AIR DASH: os quadros do dash com o corpo esticado e o rastro (sem os agachados do começo/fim).
rest.air_dash = { {}, {}, rest.dash[3] }
for i = 2, 6 do
  table.insert(rest.air_dash[1], rest.dash[1][i])
  table.insert(rest.air_dash[2], rest.dash[2][i])
end
table.insert(REST, "air_dash")
-- INÍCIO E PARADA DA CORRIDA: arranque agachado (1º quadro do dash, sem o rastro) e o primeiro
-- passo; parada = freada agachada (último quadro do dash) e a recuperação da aterrissagem.
local empty = Image(W, H, ColorMode.RGB)
rest.run_start = { { rest.dash[1][1], run_body[1] }, { empty, empty }, 12 }   -- arranque -> 1º quadro da corrida original
rest.run_stop = { { rest.dash[1][#rest.dash[1]], rest.land[1][#rest.land[1]] }, { empty, empty }, 10 }
table.insert(REST, "run_start")
table.insert(REST, "run_stop")
for _, name in ipairs(REST) do add(name, rest[name][1], rest[name][2], rest[name][3]) end
for _, r in ipairs(ranges) do
  local t = out:newTag(r[2], r[3])
  t.name = r[1]
end
out:saveAs(out_path)
print("noct_v2: " .. #out.frames .. " quadros")
