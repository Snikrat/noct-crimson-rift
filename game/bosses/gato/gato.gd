extends CharacterBody2D
## Gato Infernal: chefe com três ataques (investida, salto e cuspe de fogo).
## Com metade da vida entra na fase 2: fica mais rápido e telegrafa menos.

const Sprites := preload("res://game/core/sprites.gd")
const FireballScript := preload("res://game/bosses/gato/gato_fireball.gd")

const BOSS_ID := "gato"
const BOSS_NAME := "Gato Infernal"
const WAKE_LINES := ["@sorrindo: ...Finalmente."]   # inimigo enorme: o sorriso de canto, não alegria
const SIZE := Vector2(64, 44)
const GRAVITY := 1100.0
const MAX_HP := 32
const WAKE_X := 6 * 16          # acorda quando o herói passa deste ponto
const CHARGE_SPEED := 280.0
const LEAP_VELOCITY := -480.0

var level
var hp := MAX_HP
var state := "sleep"
var next_state := ""
var last_attack := ""
var timer := 0.0
var dir := -1
var flash := 0.0
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

	# Quadro 96x53, pés na linha 52, desenhado em dobro do tamanho.
	sprite = Sprites.make_sprite(Sprites.hell_gato(), Vector2(96, 53), 52, SIZE.y / 2)
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	sprite.play("run")
	sprite.speed_scale = 0


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)


func get_hurtbox() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


func is_awake() -> bool:
	return state != "sleep"


func phase2() -> bool:
	return hp <= MAX_HP / 2


func _physics_process(delta: float) -> void:
	timer -= delta
	flash = maxf(flash - delta, 0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 600)
	var p: Node2D = level.player

	match state:
		"sleep":
			velocity.x = 0
			if p.global_position.x > WAKE_X:
				_wake()
		"roar":
			velocity.x = 0
			if timer <= 0:
				_to_idle()
		"idle":
			velocity.x = move_toward(velocity.x, 0, 900 * delta)
			_face(p)
			if timer <= 0:
				_choose_attack()
		"windup":
			velocity.x = 0
			if timer <= 0:
				_start(next_state)
		"charge":
			velocity.x = dir * CHARGE_SPEED * (1.25 if phase2() else 1.0)
			if timer <= 0 or (is_on_wall() and timer < 1.9):
				level.shake(4.0)
				_to_idle()
		"leap":
			if timer <= 0 and is_on_floor():
				level.shake(6.0)
				_to_idle()
		"spit":
			velocity.x = 0
			if timer <= 0:
				if shots_left > 0:
					_spit(p)
				else:
					_to_idle()

	move_and_slide()
	sprite.flip_h = dir > 0  # o desenho olha para a esquerda
	if flash > 0:
		sprite.modulate = Color(1, 0.4, 0.4)
	elif state == "windup":
		sprite.modulate = Color(1.0, 0.75, 0.45)
	else:
		sprite.modulate = Color.WHITE


func _face(p: Node2D) -> void:
	dir = 1 if p.global_position.x > global_position.x else -1


func _wake() -> void:
	state = "roar"
	timer = 1.2
	sprite.speed_scale = 2.0
	level.on_boss_wake(self)


func _to_idle() -> void:
	state = "idle"
	timer = randf_range(0.35, 0.6) if phase2() else randf_range(0.6, 1.0)
	sprite.speed_scale = 0.6


func _choose_attack() -> void:
	var options := ["charge", "leap", "spit"]
	options.erase(last_attack)
	next_state = options[randi() % options.size()]
	last_attack = next_state
	state = "windup"
	timer = 0.3 if phase2() else 0.5
	sprite.speed_scale = 0
	_face(level.player)


func _start(attack: String) -> void:
	state = attack
	var p: Node2D = level.player
	match attack:
		"charge":
			timer = 2.0
			sprite.speed_scale = 2.5
		"leap":
			timer = 0.2
			sprite.speed_scale = 1.5
			velocity.y = LEAP_VELOCITY
			# Calcula a velocidade para cair perto do herói.
			velocity.x = clampf((p.global_position.x - global_position.x) / 0.85, -280, 280)
		"spit":
			shots_left = 5 if phase2() else 3
			timer = 0.1
			sprite.speed_scale = 0.5


func _spit(p: Node2D) -> void:
	shots_left -= 1
	timer = 0.22
	_face(p)
	var fb = FireballScript.new()
	fb.level = level
	fb.position = global_position + Vector2(dir * 30, -10)
	var dist := absf(p.global_position.x - global_position.x)
	fb.velocity = Vector2(dir * clampf(dist * randf_range(0.6, 1.1), 90, 260), randf_range(-320, -220))
	level.add_to_world(fb)


func take_hit(_from_dir: Vector2, damage: int) -> void:
	if hp <= 0 or is_queued_for_deletion():
		return
	if state == "sleep":
		_wake()
	hp -= damage
	flash = 0.1
	if hp <= 0:
		level.on_boss_defeated(self)
		queue_free()
