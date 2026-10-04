extends CharacterBody2D
## Velário, o Carcereiro das Lembranças: chefe do Lago Velado (docs/expansao_forma_demoniaca.md, seção 3).
## A parte do Noct que preferiu esquecer, transformada pela Fenda em carcereiro. Não é cruel: acha que protege.
## Fase 1 (Carcereiro): golpe da chave, Tranca (correntes no chão), Véu (some e surge atrás) e
##   Esquecer (ergue a lanterna, a tela escurece e mãos de sombra sobem do chão).
## Transição (metade da vida): ajoelha abraçando a lanterna, ela racha e o véu rasga.
## Fase 2 (Despido): golpe duplo, salto com onda de choque, chuva de gaiolas e maré carmesim;
##   abaixo de 20%, "Não olha.": escuridão e ataques mais rápidos. Provoca o Noct sem pausar a luta.
## Arte: tools/make_velario.lua (quadros 192x136, pés na linha 130, corpo em x=96, olhando para a direita).

const Fx := preload("res://game/core/fx.gd")
const Sprites := preload("res://game/core/sprites.gd")
const HazardScript := preload("res://game/bosses/velario/velario_hazard.gd")
const HandScript := preload("res://game/bosses/bringer/bringer_spell.gd")
const Paths := preload("res://data/asset_paths.gd")

const BOSS_ID := "velario"
const BOSS_NAME := "Velário, o Carcereiro"
const WAKE_LINES := ["Volta. Aqui embaixo não tem nada seu.", "@desconfiado: Engraçado. Parece meu."]
const BREAK_LINES := ["Você não quer lembrar. Eu sou a prova.", "@serio: ..."]
# Provocações da fase 2: [fala do Velário, resposta do Noct ou ""]. Sem ironia nas respostas.
const TAUNTS := [
	["Ela pediu uma coisa. Você vai odiar lembrar o quê.", ""],
	["Eu guardei para você não ter que carregar.", "@furioso: Ninguém pediu."],
	["Se você lembrar, vai ter que cumprir.", ""],
	["Toda noite você chega perto. E volta.", "@sombrio: ..."],
	["Ela sabia que podia não voltar.", "@furioso: Me devolve."],
]
const TAUNT_EVERY := Vector2(6.5, 9.0)

const FRAME := Vector2(192, 136)
const BODY_X := 96.0
const FEET_Y := 130.0
const SIZE := Vector2(30, 76)
const GRAVITY := 1100.0
const MAX_HP := 70
const WAKE_RANGE := 230.0
const WALK_SPEED := 38.0
const WALK2_SPEED := 78.0
const MELEE_RANGE := 96.0
# Golpes (área olhando para a direita, relativa ao centro do corpo) e quadros que machucam.
const HITS := {
	"attack": {"frames": [[3, 4]], "area": Rect2(-4, -58, 92, 78)},
	"attack2": {"frames": [[2, 3], [5, 6]], "area": Rect2(-6, -60, 104, 82)},
}
const ANIMS := {
	"idle": [5, true], "walk": [7, true], "attack": [11, false], "lock": [10, false], "raise": [8, false],
	"transform": [6, false], "idle2": [7, true], "walk2": [10, true], "attack2": [14, false],
	"leap": [10, false], "roar": [9, false], "death": [7, false],
}

static var _frames: SpriteFrames

var level
var hp := MAX_HP
var state := "sleep"
var timer := 0.0
var dir := -1
var flash := 0.0
var phase := 1
var last_action := ""
var dying := false
var desperate := false
var sprite: AnimatedSprite2D
var lantern_glow: Sprite2D
var hit_windows_done := []
var leap_target := 0.0
var roar_kind := "cages"
var taunt_timer := 0.0
var taunt_index := 0


static func frames() -> SpriteFrames:
	if _frames == null:
		_frames = SpriteFrames.new()
		_frames.remove_animation("default")
		for anim in ANIMS:
			var path: String = "res://assets/enemies/velario/%s.png" % anim
			var tex: Texture2D = load(path)
			var count := int(tex.get_width() / FRAME.x)
			Sprites.add_sheet(_frames, anim, path, FRAME, 0, count - 1, ANIMS[anim][0], ANIMS[anim][1])
	return _frames


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames()
	sprite.centered = false
	sprite.animation_finished.connect(_on_anim_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	add_child(sprite)
	lantern_glow = Fx.glow(Color(1, 0.12, 0.3), 26, 0.35)
	add_child(lantern_glow)
	sprite.play("idle")
	_update_facing()


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)


func get_hurtbox() -> Rect2:
	if dying or state in ["transform", "vanish"]:
		return Rect2(-99999, -99999, 0, 0)
	return Rect2(global_position - SIZE / 2, SIZE)


func is_awake() -> bool:
	return state != "sleep" and not dying


func _update_facing() -> void:
	sprite.flip_h = dir < 0
	sprite.offset = Vector2(-BODY_X, -FEET_Y - 1)
	sprite.position.y = SIZE.y / 2


func _physics_process(delta: float) -> void:
	timer -= delta
	flash = maxf(flash - delta, 0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 600)
	if state != "leap":
		velocity.x = 0
	var p: Node2D = level.player
	if phase == 2 and not dying and state != "transform":
		_taunt(delta)
	if not dying:
		match state:
			"sleep":
				if absf(p.global_position.x - global_position.x) < WAKE_RANGE:
					_wake()
			"idle":
				_face(p)
				if timer <= 0:
					_choose_action(p)
			"walk":
				_face(p)
				velocity.x = dir * (WALK2_SPEED if phase == 2 else WALK_SPEED)
				if absf(p.global_position.x - global_position.x) < MELEE_RANGE:
					_start_attack()
				elif timer <= 0:
					_to_idle()
			"attack":
				_melee_hit(p)
			"leap":
				if sprite.frame in [1, 2, 3]:
					velocity.x = clampf((leap_target - global_position.x) * 3.0, -260, 260)
				else:
					velocity.x = 0
			"vanish":
				sprite.modulate.a = clampf(timer / 0.35, 0, 1)
				if timer <= 0:
					_reappear(p)
			"appear":
				sprite.modulate.a = clampf(1.0 - timer / 0.35, 0, 1)
				if timer <= 0:
					sprite.modulate.a = 1
					_start_attack()
	move_and_slide()
	global_position.x = clampf(global_position.x, 30, p.world_size.x - 30)
	if flash > 0:
		sprite.modulate = Color(1, 0.45, 0.45, sprite.modulate.a)
	elif state not in ["vanish", "appear"]:
		sprite.modulate = Color(1, 1, 1, 1)
	_place_glow()


## Brilho que acompanha a lanterna (na mão na fase 1, no peito na fase 2).
func _place_glow() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var local := Vector2(13, -14) if phase == 1 else Vector2(4, -20)
	if state == "raise":
		local = Vector2(14, -50)
	lantern_glow.position = Vector2(local.x * (1 if dir > 0 else -1), local.y)
	var base := 0.32 if phase == 1 else 0.5
	lantern_glow.modulate.a = (base + 0.08 * sin(t * 4.0)) * sprite.modulate.a
	lantern_glow.z_index = 60   # continua visível na escuridão do Esquecer


func _face(p: Node2D) -> void:
	var new_dir := 1 if p.global_position.x > global_position.x else -1
	if new_dir != dir:
		dir = new_dir
		_update_facing()


func _anim(name: String) -> String:
	if phase == 2 and name in ["idle", "walk"]:
		return name + "2"
	return name


func _wake() -> void:
	state = "idle"
	timer = 1.2
	sprite.play("raise")
	level.on_boss_wake(self)


func _to_idle() -> void:
	state = "idle"
	var fast := 0.6 if desperate else 1.0
	timer = (randf_range(0.35, 0.7) if phase == 2 else randf_range(0.7, 1.1)) * fast
	sprite.play(_anim("idle"))


func _choose_action(p: Node2D) -> void:
	var dist := absf(p.global_position.x - global_position.x)
	var options := []
	if phase == 1:
		options = ["attack", "attack", "veil"] if dist < MELEE_RANGE else ["walk", "lock", "veil", "raise"]
	else:
		options = ["attack", "attack", "leap"] if dist < MELEE_RANGE else ["walk", "leap", "roar", "roar"]
	if options.size() > 1:
		options.erase(last_action)
	var action: String = options[randi() % options.size()]
	last_action = action
	match action:
		"attack":
			_start_attack()
		"walk":
			state = "walk"
			timer = 1.4 if phase == 2 else 1.8
			sprite.play(_anim("walk"))
		"lock":
			state = "lock"
			sprite.play("lock")
		"raise":
			state = "raise"
			sprite.play("raise")
			Audio.play_sfx("charge", 0.0, 0.5)
		"veil":
			state = "vanish"
			timer = 0.35
			Audio.play_sfx("rise", 0.05, 0.4)
		"leap":
			state = "leap"
			leap_target = clampf(p.global_position.x, 40, p.world_size.x - 40)
			sprite.play("leap")
			Audio.play_sfx("dash", 0.0, 0.5)
		"roar":
			state = "roar"
			roar_kind = "tide" if roar_kind == "cages" else "cages"
			sprite.play("roar")
			Audio.play_sfx("charge", 0.0, 0.4)


func _start_attack() -> void:
	state = "attack"
	_face(level.player)
	hit_windows_done.clear()
	var anim := "attack2" if phase == 2 else "attack"
	sprite.play(anim)
	sprite.speed_scale = 1.25 if desperate else 1.0
	Audio.play_sfx("slash", 0.05, 0.6 if phase == 1 else 0.8)


func _melee_hit(p: Node2D) -> void:
	var anim := String(sprite.animation)
	if not HITS.has(anim):
		return
	var h: Dictionary = HITS[anim]
	for w in h["frames"]:
		if sprite.frame >= w[0] and sprite.frame <= w[1]:
			var area: Rect2 = h["area"]
			if dir < 0:
				area.position.x = -area.position.x - area.size.x
			if Rect2(global_position + area.position, area.size).intersects(p.get_hurtbox()):
				p.hit_by_boss(dir)


## Ataques que saem num quadro certo da animação.
func _on_frame_changed() -> void:
	if dying and sprite.animation != "death":
		return
	match String(sprite.animation):
		"lock":
			if sprite.frame == 3:
				_spawn_chains()
		"raise":
			if sprite.frame == 2 and state == "raise":
				_forget()
		"leap":
			if sprite.frame == 4:
				_land_shock()
		"roar":
			if sprite.frame == 3:
				if roar_kind == "cages":
					_rain_cages()
				else:
					_tide()


func _feet() -> Vector2:
	return global_position + Vector2(0, SIZE.y / 2)


func _spawn_hazard(kind: String, pos: Vector2, props := {}) -> Node2D:
	var h = HazardScript.new()
	h.level = level
	h.kind = kind
	h.position = pos
	for k in props:
		h.set(k, props[k])
	level.add_to_world(h)
	return h


## Tranca: correntes correm pelo chão para os dois lados.
func _spawn_chains() -> void:
	level.shake(4.0)
	Audio.play_sfx("earth", 0.05, 0.8)
	for s in [-1, 1]:
		_spawn_hazard("chain", _feet() + Vector2(s * 20, 0), {"dir": s, "speed": 170.0 if phase == 1 else 230.0})


## Esquecer: escurece a tela e mãos de sombra sobem onde o Noct está.
func _forget(duration := 1.6) -> void:
	_spawn_hazard("dark", global_position, {"dark_time": duration})
	Audio.play_sfx("rise", 0.0, 0.4)
	var p: Node2D = level.player
	var eyes := Fx.glow(Color(1, 0.2, 0.35), 10, 0.6)
	eyes.z_index = 60
	eyes.position = Vector2(0, -14)
	p.add_child(eyes)
	get_tree().create_timer(duration, false).timeout.connect(eyes.queue_free)
	for i in 2:
		get_tree().create_timer(0.35 + i * 0.5, false).timeout.connect(func():
			if not is_instance_valid(self) or dying or not is_instance_valid(level.player):
				return
			var hand = HandScript.new()
			hand.level = level
			hand.position = Vector2(level.player.global_position.x, _ground_below(level.player.global_position))
			level.add_to_world(hand))


func _ground_below(pos: Vector2) -> float:
	var y := pos.y
	for i in 30:
		if level.is_solid(Vector2(pos.x, y)):
			return floorf(y / 16) * 16
		y += 8
	return pos.y + 19


## Véu: some na névoa e reaparece do outro lado do Noct.
func _reappear(p: Node2D) -> void:
	var side := -1 if p.global_position.x > global_position.x else 1
	global_position.x = clampf(p.global_position.x + side * 64, 40, p.world_size.x - 40)
	velocity = Vector2.ZERO
	state = "appear"
	timer = 0.35
	_face(p)


func _land_shock() -> void:
	level.shake(7.0)
	Audio.play_sfx("earth", 0.05, 0.7)
	level.spawn_crimson("shockwave", _feet(), dir, 0.45)
	_spawn_hazard("shock", _feet())


## Chuva de gaiolas: cinco pontos marcados, um deles em cima do Noct.
func _rain_cages() -> void:
	level.shake(3.0)
	var px: float = level.player.global_position.x
	var xs := [px]
	for i in 4:
		xs.append(clampf(px + (i - 1.5) * 72 + randf_range(-14, 14), 30, level.player.world_size.x - 30))
	for i in xs.size():
		var x: float = xs[i]
		_spawn_hazard("cage", Vector2(x, _ground_below(Vector2(x, global_position.y - 40))), {"warn": 0.7 + i * 0.12})


## Maré carmesim: duas ondas baixas correndo pelo chão (pule por cima).
func _tide() -> void:
	level.shake(5.0)
	level.flash_screen(Color(0.6, 0.02, 0.12), 0.25)
	for s in [-1, 1]:
		_spawn_hazard("tide", _feet() + Vector2(s * 24, 0), {"dir": s, "speed": 210.0 if not desperate else 260.0, "life": 4.0})


func _on_anim_finished() -> void:
	sprite.speed_scale = 1.0
	match String(sprite.animation):
		"attack", "attack2", "lock", "leap", "roar":
			if state != "transform" and not dying:
				_to_idle()
		"raise":
			if state in ["raise", "idle"]:
				_to_idle()
		"transform":
			phase = 2
			state = "idle"
			timer = 0.8
			sprite.play("idle2")
			taunt_timer = 3.0
			Audio.play_music(Paths.MUSIC_REVENGES_WAITING, 1.0, 0.0, 0.4)
			level.flash_screen(Color(0.9, 0.1, 0.25), 0.5)
			level.shake(8.0)
		"death":
			level.on_boss_defeated(self)
			queue_free()


## Metade da vida: ajoelha abraçando a lanterna; ela racha e o véu rasga.
func _start_transform() -> void:
	state = "transform"
	velocity = Vector2.ZERO
	sprite.modulate.a = 1
	sprite.play("transform")
	Audio.play_sfx("thunder", 0.0, 0.5)
	level.say(self, BOSS_NAME, BREAK_LINES[0], 2.6, 96.0)
	get_tree().create_timer(1.8, false).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(level.player):
			level.say(level.player, "", BREAK_LINES[1], 1.6))


## Provocações da fase 2 (balões que não pausam a luta).
func _taunt(delta: float) -> void:
	taunt_timer -= delta
	if taunt_timer > 0:
		return
	taunt_timer = randf_range(TAUNT_EVERY.x, TAUNT_EVERY.y)
	var i := taunt_index if taunt_index < TAUNTS.size() else randi_range(0, TAUNTS.size() - 1)
	var reply: String = TAUNTS[i][1] if taunt_index < TAUNTS.size() else ""
	taunt_index += 1
	level.say(self, BOSS_NAME, TAUNTS[i][0], 3.0, 96.0)
	if reply != "":
		get_tree().create_timer(1.6, false).timeout.connect(func():
			if is_instance_valid(self) and not dying and is_instance_valid(level.player):
				level.say(level.player, "", reply, 2.2))


func take_hit(_from_dir: Vector2, damage: int) -> void:
	if dying or state in ["transform", "vanish"]:
		return
	if state == "sleep":
		_wake()
	hp -= damage
	flash = 0.1
	if hp <= 0:
		dying = true
		state = "dead"
		sprite.speed_scale = 1.0
		sprite.modulate = Color.WHITE
		sprite.play("death")
		level.say(self, BOSS_NAME, "Então lembra. E não diz que eu não avisei.", 3.0, 96.0)
		level.shake(8.0)
		return
	if phase == 1 and hp <= MAX_HP / 2:
		_start_transform()
	elif phase == 2 and not desperate and hp <= MAX_HP / 5:
		desperate = true
		level.say(self, BOSS_NAME, "Não olha.", 2.0, 96.0)
		_forget(3.0)
