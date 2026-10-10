extends CharacterBody2D
## Demon Slime: chefe final, no fundo do Inferno.
## Ataques: golpe de cutelo de perto, chuva de fogo, salto com ondas de fogo pelo chão.
## Fase 2 (metade da vida): mais rápido e invoca caveiras de fogo.

const Sprites := preload("res://game/core/sprites.gd")
const FireballScript := preload("res://game/bosses/gato/gato_fireball.gd")
const ProjectileScript := preload("res://game/enemies/enemy_projectile.gd")
const FlyerScript := preload("res://game/enemies/enemy_flyer.gd")

const BOSS_ID := "demon_slime"
const BOSS_NAME := "Demon Slime"
const WAKE_LINES := ["Você carrega a ausência dela como uma lâmina.", "@magia_olhos: Foi você que abriu a fenda?", "Foi a sua dor que abriu a porta. Eu só entrei.", "@maligno: Então eu fecho com você dentro."]
# Se Noct salvou a Tessa, a fenda tenta com ela o que fez com Mira (ideias/arco_tessa.md).
const TESSA_LINES := ["Ela também me ouve. A da manta.", "Eu chamo, ela vem. Igual à outra.", "@furioso: Ela não vem.", "@serio: Eu disse pra ela esperar. E dessa vez alguém ouviu."]
const SIZE := Vector2(56, 92)
const GRAVITY := 1100.0
const MAX_HP := 70
const WAKE_X := 6 * 16
const WALK_SPEED := 50.0
const CLEAVE_RANGE := 115.0
# Quadros 288x160: corpo em x≈145, pés na linha 158 (desenho olhando para a esquerda).
const FRAME_W := 288.0
const BODY_X := 145.0
const FEET_Y := 158.0
const CLEAVE_FRAMES := [9, 11]                  # quadros em que o cutelo machuca
const CLEAVE_AREA := Rect2(-130, -60, 140, 106)  # olhando para a esquerda, relativo ao centro

var level
var hp := MAX_HP
var state := "sleep"
var timer := 0.0
var dir := -1
var flash := 0.0
var last_action := ""
var dying := false
var shots_left := 0
var sprite: AnimatedSprite2D


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
	sprite.sprite_frames = Sprites.demon_slime()
	sprite.centered = false
	sprite.animation_finished.connect(_on_anim_finished)
	add_child(sprite)
	sprite.play("idle")
	_update_facing()


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)


func get_hurtbox() -> Rect2:
	if dying:
		return Rect2(-99999, -99999, 0, 0)
	return Rect2(global_position - SIZE / 2, SIZE)


func is_awake() -> bool:
	return state != "sleep" and not dying


func phase2() -> bool:
	return hp <= MAX_HP / 2


## O corpo não fica no centro do quadro, então o deslocamento muda ao virar.
func _update_facing() -> void:
	sprite.flip_h = dir > 0
	var body_x := (FRAME_W - BODY_X) if dir > 0 else BODY_X
	sprite.offset = Vector2(-body_x, -FEET_Y - 1)
	sprite.position.y = SIZE.y / 2


func _physics_process(delta: float) -> void:
	timer -= delta
	flash = maxf(flash - delta, 0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 700)
	if state != "leap":
		velocity.x = 0
	var p: Node2D = level.player

	if not dying:
		match state:
			"sleep":
				if p.global_position.x > WAKE_X:
					_wake()
			"idle":
				_face(p)
				if timer <= 0:
					_choose_action(p)
			"walk":
				_face(p)
				velocity.x = dir * WALK_SPEED * (1.35 if phase2() else 1.0)
				if absf(p.global_position.x - global_position.x) < CLEAVE_RANGE:
					_start_cleave()
				elif timer <= 0:
					_to_idle()
			"cleave":
				_cleave_hit(p)
			"rain":
				if timer <= 0:
					if shots_left > 0:
						_drop_fireball(p)
					else:
						_to_idle()
			"leap":
				if timer <= 0 and is_on_floor():
					_land()

	move_and_slide()
	if flash > 0:
		sprite.modulate = Color(1, 0.45, 0.45)
	elif state == "cleave" and sprite.frame < CLEAVE_FRAMES[0]:
		sprite.modulate = Color(1.0, 0.8, 0.55)  # aviso do golpe
	else:
		sprite.modulate = Color.WHITE


func _face(p: Node2D) -> void:
	var new_dir := 1 if p.global_position.x > global_position.x else -1
	if new_dir != dir:
		dir = new_dir
		_update_facing()


func _wake() -> void:
	state = "idle"
	timer = 1.2
	level.on_boss_wake(self)
	level.shake(8.0)
	Audio.play_sfx("earth", 0.0, 0.5)


func _to_idle() -> void:
	state = "idle"
	timer = randf_range(0.4, 0.7) if phase2() else randf_range(0.8, 1.2)
	sprite.play("idle")


func _choose_action(p: Node2D) -> void:
	var dist := absf(p.global_position.x - global_position.x)
	var options := ["cleave", "cleave", "rain"] if dist < CLEAVE_RANGE else ["walk", "walk", "rain", "leap"]
	if phase2() and get_tree().get_nodes_in_group("summoned").size() < 2:
		options.append("summon")
	if options.size() > 1:
		options.erase(last_action)
	var action: String = options[randi() % options.size()]
	last_action = action
	match action:
		"cleave":
			_start_cleave()
		"walk":
			state = "walk"
			timer = 1.8
			sprite.play("walk")
		"rain":
			state = "rain"
			shots_left = 7 if phase2() else 4
			timer = 0.3
			sprite.play("idle")
			Audio.play_sfx("rise", 0.0, 0.5)
		"leap":
			state = "leap"
			timer = 0.25
			velocity = Vector2(clampf((p.global_position.x - global_position.x) / 0.9, -260, 260), -520)
			sprite.play("walk")
		"summon":
			_summon_skulls()
			_to_idle()


func _start_cleave() -> void:
	state = "cleave"
	_face(level.player)
	sprite.play("cleave")
	sprite.speed_scale = 1.25 if phase2() else 1.0


func _cleave_hit(p: Node2D) -> void:
	if sprite.frame < CLEAVE_FRAMES[0] or sprite.frame > CLEAVE_FRAMES[1]:
		return
	if sprite.frame == CLEAVE_FRAMES[0]:
		level.shake(5.0)
	var area := CLEAVE_AREA
	if dir > 0:
		area.position.x = -area.position.x - area.size.x
	if Rect2(global_position + area.position, area.size).intersects(p.get_hurtbox()):
		p.hit_by_boss(dir)


## Chuva de fogo: bolas caem do alto perto do herói.
func _drop_fireball(p: Node2D) -> void:
	shots_left -= 1
	timer = 0.22 if phase2() else 0.32
	var fb = FireballScript.new()
	fb.level = level
	fb.position = Vector2(p.global_position.x + randf_range(-90, 90), 24)
	fb.velocity = Vector2(randf_range(-20, 20), 40)
	level.add_to_world(fb)


## Aterrissagem do salto: tremor e duas ondas de fogo correndo pelo chão.
func _land() -> void:
	level.shake(9.0)
	Audio.play_sfx("earth", 0.0, 0.6)
	for side in [-1, 1]:
		var wave = ProjectileScript.new()
		wave.level = level
		wave.velocity = Vector2(side * 170, 0)
		wave.position = global_position + Vector2(side * 30, SIZE.y / 2 - 7)
		level.add_to_world(wave)
	_to_idle()


func _summon_skulls() -> void:
	Audio.play_sfx("rise", 0.0, 0.4)
	for side in [-1, 1]:
		var s = FlyerScript.new()
		s.level = level
		s.kind = "skull"
		s.add_to_group("summoned")
		level.add_to_world(s)
		s.place_feet_at(global_position + Vector2(side * 60, -70))


func _on_anim_finished() -> void:
	match sprite.animation:
		"cleave":
			sprite.speed_scale = 1.0
			_to_idle()
		"hurt":
			_to_idle()
		"death":
			level.on_boss_defeated(self)
			queue_free()


func take_hit(_from_dir: Vector2, damage: int) -> void:
	if dying:
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
		level.shake(10.0)
		# As caveiras invocadas somem junto.
		for s in get_tree().get_nodes_in_group("summoned"):
			level.spawn_explosion(s.global_position, false)
			s.queue_free()


## Falas do despertar (main.gd, on_boss_wake): as de sempre, mais a tentação com a Tessa se ela foi salva.
func wake_lines() -> Array:
	var lines: Array = WAKE_LINES.duplicate()
	if GameState.flags.has("tessa_saved"):
		lines.append_array(TESSA_LINES)
	return lines
