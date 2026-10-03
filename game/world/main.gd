extends Node2D
## Coordena o mundo: monta as salas a partir de data/rooms/, faz as transições,
## cuida dos chefes, do banco e dos eventos do jogo (inimigo morto, morte do herói...).
## Desenho do cenário, fundo e interface ficam em room_view.gd, backdrop.gd e ui/hud.gd.
const Fx := preload("res://game/core/fx.gd")

const PlayerScript := preload("res://game/player/player.gd")
const CrawlerScript := preload("res://game/enemies/enemy_crawler.gd")
const FlyerScript := preload("res://game/enemies/enemy_flyer.gd")
const CasterScript := preload("res://game/enemies/enemy_caster.gd")
const NpcScript := preload("res://game/world/npc.gd")
const BenchScript := preload("res://game/world/bench.gd")
const GatoScript := preload("res://game/bosses/gato/gato.gd")
const BringerScript := preload("res://game/bosses/bringer/bringer.gd")
const DemonSlimeScript := preload("res://game/bosses/demon_slime/demon_slime.gd")
const CharmPickupScript := preload("res://game/world/charm_pickup.gd")
const MemoryScript := preload("res://game/world/memory_pickup.gd")
const TessaScript := preload("res://game/world/tessa.gd")
const RoomViewScript := preload("res://game/world/room_view.gd")
const BackdropScript := preload("res://game/world/backdrop.gd")
const HudScript := preload("res://game/ui/hud.gd")
const Rooms := preload("res://data/rooms.gd")
const Progression := preload("res://data/progression.gd")
const Sprites := preload("res://game/core/sprites.gd")
const MarkerScript := preload("res://game/world/world_marker.gd")
const CrimsonScript := preload("res://game/world/crimson_effect.gd")
const HumanoidScript := preload("res://game/enemies/enemy_humanoid.gd")
const RainScript := preload("res://game/world/rain.gd")

const TILE := 16

# Atalhos de teste (F1 sobe um nível, F2 enche alma e vida). Mude para false ao publicar o jogo.
const DEBUG_KEYS := true

# Estado da sala atual
var room_name := ""
var room: Dictionary
var theme: Dictionary
var tileset: Texture2D
var solid := {}
var rift := {}              # paredes carmesim (X): sólidas, atravessáveis com o Passo da Fenda
var hazards: Array[Rect2] = []
var lava: Array[Vector2i] = []   # células de lava (desenhadas em room_view.gd)
var water: Array[Vector2i] = []  # água parada (w): só visual
var entries := {}
var map_size := Vector2i.ZERO

var world: Node2D             # tudo o que pertence à sala (inimigos, NPCs, colisores...)
var colliders: StaticBody2D
var player: CharacterBody2D
var boss: Node2D
# Música de combate: entra quando um inimigo chega perto, sai alguns segundos depois da luta.
const COMBAT_RANGE := 170.0
const COMBAT_LINGER := 4.0
var combat_timer := 0.0
# Espinhos e lava ferem inimigos comuns como ferem o Noct: 1 de dano, no ritmo da invulnerabilidade dele.
const HAZARD_DAMAGE := 1
const HAZARD_ENEMY_COOLDOWN := 1.0
var time_base := 1.0         # velocidade normal do jogo (cai na câmera lenta do golpe final)
var slowmo_boss: Node2D
var bench_visits := 0
var play_ending := true     # os testes desligam para não trocar de cena no meio
# A revelação depois do Demon Slime (a fenda fala; ver docs/noct_personalidade.md, fase 5).
const REVELATION := [
	"Ela me ouviu primeiro.",
	"@chocado: ...",
	"Mira ouvia o chamado antes de você. Veio sozinha até esta porta.",
	"E a fechou. Com o próprio nome. Com o próprio corpo.",
	"@olhar_baixo: Ela disse que voltava logo.",
	"A porta se abriu de novo quando você a perdeu. A sua dor tem o formato da chave.",
	"O poder que você carrega é o que sobrou do selo dela.",
	"@fechando_olhos: Então não foi por minha causa.",
	"Não foi por sua causa que ela morreu. Mas é por sua causa que eu ainda existo.",
	"Fique. Aqui dentro, ela ainda está esperando.",
]
const CRIMSON_NAMES := ["Forma normal", "Carmesim 1 · Despertar", "Carmesim 2 · Corrupção avançada", "Carmesim 3 · Consumido"]
const BENCH_MOMENTS := [
	["Noct se senta numa ponta do banco. O outro lado fica vazio.", "@cansado: Cinco minutos. Depois o mundo pode voltar a tentar me matar."],
	["Os dedos dele encontram a fita carmesim no pulso. Ficam ali um tempo.", "@fechando_olhos: Um dia de cada vez."],
	["Noct se senta numa ponta do banco. O outro lado fica vazio.", "@calmo: Hoje primeiro. Amanhã depois."],
	["A mão ainda treme um pouco. Ele espera passar.", "@olhar_lateral: Hm."],
]
var interactable: Node2D      # NPC/banco ao alcance do herói
var transitioning := false
var shake_amount := 0.0

var room_view: Node2D
var backdrop: CanvasLayer
var hud: CanvasLayer

## Geo fica no GameState (sobrevive à troca de sala e vai para o save).
var geo: int:
	get: return GameState.geo
	set(value): GameState.geo = value


func _ready() -> void:
	room_view = RoomViewScript.new()
	room_view.level = self
	add_child(room_view)
	backdrop = BackdropScript.new()
	add_child(backdrop)
	player = PlayerScript.new()
	player.level = self
	add_child(player)
	hud = HudScript.new()
	hud.level = self
	add_child(hud)

	if GameState.continuing:
		GameState.continuing = false
		GameState.apply_hero(player)
		load_room(GameState.bench_room, "B")
	else:
		GameState.reset()
		load_room("town", "B")


func _process(delta: float) -> void:
	shake_amount = move_toward(shake_amount, 0, 30 * delta)
	player.cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
	_process_debug_keys()
	_update_music(delta)
	_hurt_enemies_on_hazards(delta)
	if boss and is_instance_valid(boss) and boss != slowmo_boss and "hp" in boss and boss.hp <= 0:
		_boss_slowmo(boss)
	interactable = null
	if not transitioning and not hud.shop.is_open():
		var nearest := INF
		for node in get_tree().get_nodes_in_group("interactables"):
			if node.can_interact(player):
				var distance: float = node.global_position.distance_squared_to(player.global_position + Vector2(0, 20))
				if distance < nearest:
					nearest = distance
					interactable = node
	var dialog = hud.dialog
	if dialog.is_open() and dialog.source and interactable != dialog.source:
		dialog.close()


## Inimigos comuns que tocam espinhos ou lava levam o dano normal (com o piscar de sempre).
## Chefes ficam imunes.
func _hurt_enemies_on_hazards(delta: float) -> void:
	if transitioning or hazards.is_empty():
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e is CharacterBody2D or is_boss(e) or e.is_queued_for_deletion() or e.hp <= 0:
			continue
		var cooldown: float = maxf(e.get_meta("hazard_cooldown", 0.0) - delta, 0.0)
		if cooldown <= 0:
			var hb: Rect2 = e.get_hurtbox()
			for h in hazards:
				if hb.intersects(h):
					e.take_hit(Vector2.UP, HAZARD_DAMAGE)
					cooldown = HAZARD_ENEMY_COOLDOWN
					break
		e.set_meta("hazard_cooldown", cooldown)


func is_boss(e: Node) -> bool:
	return "BOSS_ID" in e or (e.get_script() == HumanoidScript and e.kind in ["captain", "wizard", "knight"])


## Áreas com "combat" no tema trocam para a música de luta enquanto há inimigos por perto.
func _update_music(delta: float) -> void:
	if transitioning or not theme.has("combat") or (boss and boss.is_awake()):
		return
	var near := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_in_group("harmful") or "BOSS_ID" in e:
			continue
		if e.global_position.distance_to(player.global_position) < COMBAT_RANGE:
			near = true
			break
	combat_timer = COMBAT_LINGER if near else maxf(combat_timer - delta, 0.0)
	if combat_timer > 0:
		Audio.play_music(theme["combat"], 1.0, 0.0, 0.8)
	else:
		Audio.play_music(theme["music"], 1.0, 0.0, 2.5)


# --- Salas -------------------------------------------------------------

## Monta a sala e coloca o herói na entrada indicada (L, R ou B).
func load_room(name: String, entry: String) -> void:
	room_name = name
	room = Rooms.ROOMS[name]
	GameState.visited[name] = true
	theme = Rooms.THEMES[room["theme"]]
	tileset = load(theme["tileset"])
	backdrop.set_theme_layers(theme)
	RenderingServer.set_default_clear_color(theme["clear"])

	if world:
		remove_child(world)
		world.queue_free()
	world = Node2D.new()
	add_child(world)
	move_child(world, room_view.get_index() + 1)  # na frente do cenário, atrás do herói
	solid.clear()
	rift.clear()
	hazards.clear()
	lava.clear()
	water.clear()
	entries.clear()
	boss = null
	hud.dialog.close()

	var rows: Array = room["map"]
	var w := 0
	for row in rows:
		w = maxi(w, row.length())
	map_size = Vector2i(w, rows.size())
	var npcs: Dictionary = room.get("npcs", {})

	for y in map_size.y:
		var row: String = rows[y]
		for x in w:
			var c := row[x] if x < row.length() else "."
			# Personagens ficam com os pés na base da célula onde foram marcados.
			var feet := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			match c:
				"#":
					solid[Vector2i(x, y)] = true
				"X":
					solid[Vector2i(x, y)] = true
					rift[Vector2i(x, y)] = true
				"^":
					hazards.append(Rect2(x * TILE + 2, y * TILE + 8, TILE - 4, 8))
				"w":
					water.append(Vector2i(x, y))
				"~":
					lava.append(Vector2i(x, y))
					hazards.append(Rect2(x * TILE, y * TILE + 5, TILE, TILE - 5))
				"K":
					_spawn(CrawlerScript, feet, {"kind": "hound"})
				"Z":
					_spawn(FlyerScript, feet - Vector2(0, TILE / 2.0), {"kind": "skull"})
				"O":
					_spawn(FlyerScript, feet - Vector2(0, TILE / 2.0), {"kind": "eye"})
				"M":
					if not GameState.defeated_bosses.has("demon_slime"):
						boss = _spawn(DemonSlimeScript, feet, {})
				"C":
					var charm_id: String = room.get("charm", "")
					if charm_id != "" and not GameState.owned_charms.has(charm_id):
						_spawn(CharmPickupScript, feet, {"charm_id": charm_id})
				"L", "R":
					entries[c] = feet
				"B":
					entries["B"] = feet
					_spawn(BenchScript, feet, {})
				"E":
					_spawn(CrawlerScript, feet, {"kind": "spider"})
				"S":
					_spawn(CrawlerScript, feet, {"kind": "skeleton"})
				"Q":
					_spawn(CrawlerScript, feet, {"kind": "skeleton", "emerging": true})
				"T":
					_spawn(CrawlerScript, feet, {"kind": "thing"})
				"H":
					_spawn(CrawlerScript, feet, {"kind": "ghoul"})
				"N":
					_spawn(CrawlerScript, feet, {"kind": "miner"})
				"V":
					_spawn(FlyerScript, feet - Vector2(0, TILE / 2.0), {"kind": "grimoire"})
				"F":
					_spawn(FlyerScript, feet - Vector2(0, TILE / 2.0), {})
				"A":
					_spawn(FlyerScript, feet - Vector2(0, TILE / 2.0), {"kind": "angel"})
				"W":
					_spawn(CasterScript, feet, {})
				"G":
					if not GameState.defeated_bosses.has("gato"):
						boss = _spawn(GatoScript, feet, {})
				"D":
					if not GameState.defeated_bosses.has("bringer"):
						boss = _spawn(BringerScript, feet, {})
				_:
					if npcs.has(c):
						var n: Dictionary = npcs[c]
						_spawn(NpcScript, feet, {"kind": n["kind"], "npc_name": n["name"],
							"lines": n["lines"], "more": n.get("more", []), "shop": n.get("shop", false), "patrol_span": n.get("patrol", 24.0)})

	_build_colliders()
	_build_props()
	for id in room.get("entries", {}):
		entries[id] = room["entries"][id]
	if room.has("tessa") and TessaScript.appears(room["tessa"]["stage"]):
		_spawn(TessaScript, room["tessa"]["feet"], {"stage": room["tessa"]["stage"]})
	for mem in room.get("memories", []):
		if not GameState.memories.has(mem["id"]):
			_spawn(MemoryScript, mem["feet"], {"memory_id": mem["id"]})
	for marker in room.get("markers", []):
		var props: Dictionary = marker.duplicate()
		var feet: Vector2 = props["feet"]
		props.erase("feet")
		_spawn(MarkerScript, feet, props)
	for actor in room.get("actors", []):
		var props: Dictionary = actor.duplicate()
		var feet: Vector2 = props["feet"]
		props.erase("feet")
		var discovery_id: String = props.get("discovery", "")
		if discovery_id != "" and GameState.discoveries.has(discovery_id) and props["kind"] != "knight":
			continue
		_spawn(HumanoidScript, feet, props)

	if theme.get("rain", false):
		world.add_child(RainScript.new())
	player.set_world_size(Vector2(map_size * TILE))
	var spawn: Vector2 = entries.get(entry, entries.values()[0])
	player.enter_room(spawn)
	room_view.queue_redraw()
	hud.show_banner(room["title"])
	combat_timer = 0.0
	Audio.play_music(theme["music"], 1.0, 0.0, 1.0)
	# Comentário de Noct na primeira vez que chega na área (passa sozinho).
	if room.has("intro") and not GameState.seen_intros.has(name):
		GameState.seen_intros[name] = true
		hud.dialog.start("", room["intro"], null, 3.2)


## Junta blocos vizinhos da mesma linha em um único colisor.
func _build_colliders() -> void:
	if colliders and is_instance_valid(colliders):
		colliders.get_parent().remove_child(colliders)
		colliders.queue_free()
	colliders = StaticBody2D.new()
	world.add_child(colliders)
	for y in map_size.y:
		var x := 0
		while x < map_size.x:
			if not solid.has(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < map_size.x and solid.has(Vector2i(x, y)):
				x += 1
			var rect := RectangleShape2D.new()
			rect.size = Vector2((x - start) * TILE, TILE)
			var shape := CollisionShape2D.new()
			shape.shape = rect
			shape.position = Vector2(start * TILE + rect.size.x / 2.0, y * TILE + TILE / 2.0)
			colliders.add_child(shape)


## Objetos de cenário: [arquivo, centro x em px, linha do chão] e, opcional, o recorte da imagem.
## Nomes sem caminho vêm da pasta de objetos da cidade.
func _build_props() -> void:
	for p in room.get("props", []):
		var path: String = p[0] if "/" in p[0] else Rooms.TOWN_ENV + "props-sliced/" + p[0] + ".png"
		var tex: Texture2D = load(path)
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		var tex_size := tex.get_size()
		if p.size() > 3:
			s.region_enabled = true
			s.region_rect = p[3]
			tex_size = p[3].size
		var factor: float = p[4] if p.size() > 4 else 1.0
		s.scale = Vector2.ONE * factor
		tex_size *= factor
		s.position = Vector2(p[1] - tex_size.x / 2.0, p[2] * TILE - tex_size.y)
		if p.size() > 5:
			s.modulate = p[5]
		s.z_index = -1
		world.add_child(s)


func _spawn(script: GDScript, feet: Vector2, props: Dictionary) -> Node2D:
	var e = script.new()
	e.level = self
	for key in props:
		e.set(key, props[key])
	world.add_child(e)
	e.place_feet_at(feet)
	return e


func add_to_world(node: Node) -> void:
	world.add_child(node)


## Fim do jogo: revelação, a escolha (fase 6 da bíblia) e a cena final com os créditos.
func _ending_sequence() -> void:
	await hud.dialog.finished
	hud.dialog.start("A Fenda", REVELATION)
	await hud.dialog.finished
	hud.dialog.ask("", "* Noct olha para a fita carmesim no pulso.", ["Ficar na fenda", "Ir embora"])
	var picked: int = await hud.dialog.chosen
	GameState.ending_choice = "stay" if picked == 0 else "leave"
	GameState.flags["ending_seen"] = true
	GameState.save_game(player)
	await hud.fade_to(1.0, 1.2).finished
	Audio.fade_out_music(1.0)
	get_tree().change_scene_to_file("res://game/ui/ending.tscn")


## Passo da Fenda: liberado ao derrotar o Bringer of Death (a fenda "gostou de cada golpe").
func has_rift_step() -> bool:
	return GameState.defeated_bosses.has("bringer")


## Garras do Gato: liberadas ao derrotar o Gato Infernal (deslizar e saltar nas paredes).
func has_wall_grip() -> bool:
	return GameState.defeated_bosses.has("gato")


## Requisito de passagens e inscrições: descoberta, "memory:<id>" ou "boss:<id>".
func requirement_met(req: String) -> bool:
	if req.begins_with("memory:"):
		return GameState.memories.has(req.trim_prefix("memory:"))
	if req.begins_with("boss:"):
		return GameState.defeated_bosses.has(req.trim_prefix("boss:"))
	return GameState.discoveries.has(req)


## Luneta da torre: as salas da região de Pedravelha aparecem no mapa da pausa.
const REGION := ["town", "forest", "mountain", "swamp", "cemetery", "tower", "well"]
func reveal_region() -> void:
	for r in REGION:
		GameState.visited[r] = true


func is_rift(cell: Vector2i) -> bool:
	return rift.has(cell)


func is_solid(world_pos: Vector2) -> bool:
	return solid.has(Vector2i((world_pos / TILE).floor()))


## Chamado pelo herói quando ele sai pela borda da sala.
func request_exit(side: String) -> void:
	var target: String = room.get(side, "")
	if transitioning or target == "":
		return
	if room.has("exit_discovery") and side == "right":
		GameState.discoveries[room["exit_discovery"]] = true
	var entry: String = room.get(side + "_entry", "L" if side == "right" else "R")
	_transition(func(): load_room(target, entry))


func use_passage(target: String, entry: String) -> void:
	if transitioning or not Rooms.ROOMS.has(target):
		return
	_transition(func(): load_room(target, entry))


func respawn_player() -> void:
	_transition(func():
		load_room(GameState.bench_room, "B")
		player.revive()
		Audio.play_sfx("respawn")
		on_player_died())


func _transition(action: Callable) -> void:
	transitioning = true
	player.frozen = true
	await hud.fade_to(1.0, 0.2).finished
	action.call()
	player.frozen = false
	await hud.fade_to(0.0, 0.3).finished
	transitioning = false


# --- Efeitos -----------------------------------------------------------

func spawn_crimson(kind: String, pos: Vector2, facing := 1, duration := 0.24, follow: Node2D = null) -> void:
	var effect := CrimsonScript.new()
	effect.kind = kind
	effect.position = pos
	effect.facing = facing
	effect.lifetime = duration
	effect.follow = follow
	world.add_child(effect)

## Explosão de quando um inimigo morre.
func spawn_explosion(pos: Vector2, sound := true) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Sprites.explosion()
	s.position = pos
	s.animation_finished.connect(s.queue_free)
	world.add_child(s)
	s.play("boom")
	Fx.sparks(world, pos, Color(1, 0.55, 0.25), 14, 120, 120)
	if sound:
		Audio.play_sfx("explosion", 0.1)


func shake(amount: float) -> void:
	shake_amount = maxf(shake_amount, amount)
	Controls.rumble(amount / 12.0, amount / 10.0, 0.12 + amount * 0.02)


## Congela o jogo por um instante para dar peso aos golpes.
func hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = time_base


## Golpe final num chefe: câmera lenta, zoom e clarão por um instante.
func _boss_slowmo(b: Node2D) -> void:
	slowmo_boss = b
	time_base = 0.3
	Engine.time_scale = time_base
	flash_screen(Color(1, 0.85, 0.9), 0.5)
	Audio.play_sfx("thunder", 0.0, 0.6)
	var tw := create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(player.cam, "zoom", Vector2.ONE * 1.15, 0.25)
	await get_tree().create_timer(1.1, true, false, true).timeout
	time_base = 1.0
	Engine.time_scale = 1.0
	var back := create_tween().set_ignore_time_scale(true)
	back.tween_property(player.cam, "zoom", Vector2.ONE, 0.4)


func show_cutin(face: String, duration := 1.2, color := Color(1, 0.2, 0.45)) -> void:
	hud.show_cutin(face, duration, color)


func flash_screen(color: Color, duration: float) -> void:
	hud.flash_screen(color, duration)


func refresh_hud() -> void:
	hud.refresh()


# --- Chefes ------------------------------------------------------------

## Fecha (ou abre) o portão da arena trocando as células "gate" da sala.
func set_gate(closed: bool) -> void:
	for c in room.get("gate", []):
		var cell := Vector2i(c[0], c[1])
		if closed:
			solid[cell] = true
		else:
			solid.erase(cell)
	_build_colliders()
	room_view.queue_redraw()


func on_boss_wake(b: Node2D) -> void:
	set_gate(true)
	Audio.play_sfx("encounter", 0.0)
	hud.show_banner(b.BOSS_NAME)
	shake(6.0)
	if "WAKE_LINES" in b:
		hud.dialog.start(b.BOSS_NAME, b.WAKE_LINES, null, 2.4)
	Audio.play_music(Rooms.BOSS_MUSIC.get(b.BOSS_ID, theme["music"]), 1.0, 0.0, 0.6)


func on_boss_defeated(b: Node2D) -> void:
	GameState.defeated_bosses[b.BOSS_ID] = true
	boss = null
	var lines: Array
	match b.BOSS_ID:
		"gato":
			geo += 200
			player.max_hp += 1
			lines = [
				"O Gato Infernal foi derrotado! +200 Geo.",
				"Você absorve a essência da fera: +1 máscara de vida.",
				"@sarcastico: Bom gatinho.",
				"As garras da fera ficaram cravadas nas luvas. GARRAS DO GATO: no ar, encoste numa parede para deslizar e pule para saltar dela.",
				"@olhar_cima: ...Agora aquela torre fica interessante.",
			]
		"demon_slime":
			geo += 500
			lines = [
				"O Demon Slime foi derrotado! +500 Geo.",
				"O Inferno estremece. No centro do salão, a fenda continua aberta.",
				"@cansado: Acabou?",
				"* A fenda responde.",
			]
		"bringer":
			geo += 300
			player.spell_bonus += 1
			lines = [
				"O Bringer of Death foi derrotado! +300 Geo.",
				"Você toma o grimório do Ceifador: suas magias causam +1 de dano.",
				"A catedral silencia... por enquanto.",
				"Noct continua golpeando muito depois de o Ceifador parar de se mexer.",
				"@fechando_olhos: Ele mentiu. Tinha que estar mentindo.",
				"@olhar_baixo: E a fenda gostou de cada golpe. ...Eu também.",
				"As paredes carmesim deixam de ser paredes para ele. PASSO DA FENDA: dash contra uma parede carmesim para atravessá-la.",
			]
	player.hp = player.max_hp
	player.gain_xp({"gato": 150, "bringer": 250, "demon_slime": 600}.get(b.BOSS_ID, 200))
	for i in 6:
		spawn_explosion(b.global_position + Vector2(randf_range(-40, 40), randf_range(-30, 20)), i == 0)
	shake(10.0)
	hitstop(0.3)
	set_gate(false)
	combat_timer = 0.0
	Audio.play_music(theme["music"], 1.0, 0.0, 2.5)
	start_dialog("Vitória", lines)
	if b.BOSS_ID == "demon_slime" and play_ending:
		_ending_sequence()


# --- Interação, banco e eventos ----------------------------------------

## O herói apertou "cima". Retorna true se isso foi usado para conversar/descansar.
func try_interact() -> bool:
	var dialog = hud.dialog
	if dialog.is_open():
		return true   # a própria caixa passa as falas (ela roda com o jogo pausado)
	if dialog.just_closed():
		return true   # o botão que fechou a conversa não abre outra
	if interactable:
		interactable.interact()
		if dialog.is_open():
			dialog.source = interactable
		return true
	return false


func start_dialog(who: String, lines: Array, npc_tex: Texture2D = null) -> void:
	hud.dialog.start(who, lines, npc_tex)


func open_shop(npc_name: String) -> void:
	hud.shop.open(npc_name)


## O herói está ao lado de um banco (pode trocar amuletos).
func is_at_bench() -> bool:
	return interactable != null and interactable.has_method("rest_here")


func is_dialog_open() -> bool:
	return hud.dialog.is_open()


func is_shop_open() -> bool:
	return hud.shop.is_open()


## Descansar no banco cura tudo, vira o ponto de retorno e salva o jogo.
func rest_at_bench() -> void:
	player.hp = player.max_hp
	GameState.bench_room = room_name
	var saved := GameState.save_game(player)
	Audio.play_sfx("rest")
	if saved:
		hud.show_saved()
	var save_note := "Jogo salvo." if saved else "Não foi possível salvar. Tente descansar novamente."
	var lines := ["As feridas se fecham e a alma se acalma. " + save_note]
	# O lugar vazio e a fita: gestos que Noct nunca comenta.
	if room_name == "station":
		# Só aqui ele escolhe o lado: o direito. O esquerdo era dela.
		lines.append("* Ele senta à direita. O lado esquerdo fica vazio.")
		if GameState.memories.has("the_seat"):
			lines.append("* Não estava frio.")
		lines.append("@fechando_olhos: Um dia de cada vez.")
	elif room_name == "town" and GameState.flags.has("tessa_saved") and not GameState.flags.has("tessa_jacket"):
		GameState.flags["tessa_jacket"] = true
		lines.append("Antes de se sentar, Noct tira a jaqueta e a deixa dobrada perto de onde Tessa dorme. Não diz nada.")
		lines.append("@cansado: Hm.")
	else:
		lines.append_array(BENCH_MOMENTS[bench_visits % BENCH_MOMENTS.size()])
		bench_visits += 1
	if not GameState.owned_charms.is_empty():
		lines.append("Sentado aqui, você pode trocar amuletos: pausa > Amuletos.")
	start_dialog("Banco", lines)


func on_enemy_killed(amount: int) -> void:
	Audio.play_sfx("enemy_death", 0.15)
	geo += int(amount * 1.5) if GameState.has_charm("geo_magnet") else amount
	player.gain_xp(Progression.xp_for_geo(amount))


func on_player_died() -> void:
	geo = 0


func on_level_up(new_level: int, reward: Dictionary) -> void:
	hud.show_level_up(new_level, reward)
	# O Rift cresce com ele: comentário curto de Noct em alguns níveis.
	if reward.has("noct") and not hud.dialog.is_open():
		hud.dialog.start("", reward["noct"], null, 2.8)
	Audio.play_sfx("level_up")
	flash_screen(Color(1, 0.3, 0.6), 0.4)
	shake(3.0)


## Atalhos de teste para experimentar as habilidades sem precisar ganhar XP.
func _process_debug_keys() -> void:
	if not DEBUG_KEYS or not OS.is_debug_build() or transitioning or get_tree().paused:
		return
	if Input.is_action_just_pressed("debug_level"):
		if player.lvl < Progression.MAX_LEVEL:
			player.gain_xp(Progression.XP_FOR_LEVEL[player.lvl + 1] - player.xp)
		else:
			hud.show_banner("Nível máximo", 1.5)
	if Input.is_action_just_pressed("debug_crimson"):
		player.crimson_level = (player.crimson_level + 1) % (CRIMSON_NAMES.size())
		hud.show_banner(CRIMSON_NAMES[player.crimson_level], 1.8)
		if player.crimson_level > 0:
			flash_screen(Color(0.9, 0.1, 0.25), 0.35)
			Audio.play_sfx("charge", 0.0, 1.6 + player.crimson_level * 0.2)
		else:
			Audio.play_sfx("unequip")
	if Input.is_action_just_pressed("debug_soul"):
		player.soul = player.MAX_SOUL
		player.hp = player.max_hp
		Audio.play_sfx("switch", 0.0, 1.4)
