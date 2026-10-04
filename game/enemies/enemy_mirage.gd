extends CharacterBody2D
## Miragem (docs/expansao_forma_demoniaca.md, inimigos especiais): uma silhueta de costas, de alguém
## que o Noct conhece de longe. Quando ele chega perto, some e reaparece perto dele com duas cópias falsas;
## só a verdadeira avança e machuca. A verdadeira é a única que tem reflexo no chão.
## As cópias têm 1 de vida, não machucam e somem ao levar um golpe.
## Visual provisório: silhueta escura de um morador da vila (a arte própria vem depois).

const Sprites := preload("res://game/core/sprites.gd")
const Fx := preload("res://game/core/fx.gd")

const SIZE := Vector2(16, 36)
const GRAVITY := 900.0
const MAX_HP := 9
const GEO := 24
const RANGE := 200.0
const CYCLE := 3.2           # segundos entre um sumiço e outro
const WINDUP := 0.6          # parada antes de avançar
const LUNGE_SPEED := 210.0
const LUNGE_TIME := 0.35
const SILHOUETTE := Color(0.09, 0.07, 0.13)

var level
var hp := MAX_HP
var fake := false
var real: Node2D = null      # cópia: a Miragem verdadeira (somem juntas)
var state := "idle"
var timer := 1.0
var dir := -1
var flash := 0.0
var sprite: AnimatedSprite2D
var fakes: Array = []


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	if fake:
		hp = 1
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.npc("hat-man")
	sprite.play("idle")
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture("idle", 0)
	sprite.position.y = SIZE.y / 2 - tex.get_height() / 2.0
	add_child(sprite)


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)


func get_hurtbox() -> Rect2:
	if state == "gone":
		return Rect2(-99999, -99999, 0, 0)
	return Rect2(global_position - SIZE / 2, SIZE)


## Só machuca a verdadeira, e só enquanto avança.
func get_damagebox() -> Rect2:
	if fake or state != "lunge":
		return Rect2(-99999, -99999, 0, 0)
	return get_hurtbox()


func _physics_process(delta: float) -> void:
	timer -= delta
	flash = maxf(flash - delta, 0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 500)
	velocity.x = 0
	var p: Node2D = level.player
	if fake and (real == null or not is_instance_valid(real) or real.state == "gone"):
		_vanish_fake()
		return
	match state:
		"idle":
			# De costas para o herói.
			dir = -1 if p.global_position.x > global_position.x else 1
			if not fake and timer <= 0 and global_position.distance_to(p.global_position) < RANGE:
				_disappear()
		"gone":
			sprite.modulate.a = 0.0
			if timer <= 0:
				_appear_near(p)
		"windup":
			dir = 1 if p.global_position.x > global_position.x else -1
			if timer <= 0:
				state = "lunge"
				timer = LUNGE_TIME
		"lunge":
			velocity.x = dir * LUNGE_SPEED * (0.0 if fake else 1.0)
			if timer <= 0:
				state = "idle"
				timer = CYCLE
	move_and_slide()
	sprite.flip_h = dir > 0
	if state != "gone":
		var a := clampf(sprite.modulate.a + delta * 4.0, 0, 1)
		sprite.modulate = Color(1, 0.4, 0.45, a) if flash > 0 else Color(SILHOUETTE, a)
	queue_redraw()


func _disappear() -> void:
	state = "gone"
	timer = 0.45
	Audio.play_sfx("rise", 0.05, 0.7)
	Fx.sparks(level.world, global_position, Color(0.5, 0.45, 0.7), 8, 60, -20)


## Reaparece perto do herói; as duas cópias surgem dos outros lados.
func _appear_near(p: Node2D) -> void:
	var spots := [-56.0, 56.0, -96.0]
	spots.shuffle()
	global_position.x = clampf(p.global_position.x + spots[0], 20, p.world_size.x - 20)
	_start_windup()
	if not fake:
		for f in fakes:
			if is_instance_valid(f):
				f.queue_free()
		fakes.clear()
		for i in 2:
			var c = get_script().new()
			c.level = level
			c.fake = true
			c.real = self
			level.add_to_world(c)
			c.place_feet_at(Vector2(clampf(p.global_position.x + spots[i + 1], 20, p.world_size.x - 20), global_position.y + SIZE.y / 2))
			c._start_windup()
			fakes.append(c)


func _start_windup() -> void:
	state = "windup"
	timer = WINDUP
	sprite.modulate.a = 0.0


func _vanish_fake() -> void:
	Fx.sparks(level.world, global_position, Color(0.5, 0.45, 0.7), 6, 50, -20)
	queue_free()


func _draw() -> void:
	# O reflexo: só a verdadeira tem, uma sombra clara e invertida colada nos pés.
	if fake or state == "gone":
		return
	var feet := Vector2(0, SIZE.y / 2)
	var a := sprite.modulate.a * 0.35
	draw_rect(Rect2(feet + Vector2(-6, 1), Vector2(12, 1)), Color(0.6, 0.65, 0.9, a))
	draw_rect(Rect2(feet + Vector2(-4, 3), Vector2(8, 1)), Color(0.6, 0.65, 0.9, a * 0.7))
	draw_rect(Rect2(feet + Vector2(-2, 5), Vector2(4, 1)), Color(0.6, 0.65, 0.9, a * 0.4))


func take_hit(from_dir: Vector2, damage: int) -> void:
	if hp <= 0 or is_queued_for_deletion() or state == "gone":
		return
	if fake:
		_vanish_fake()
		return
	hp -= damage
	flash = 0.12
	if hp <= 0:
		for f in fakes:
			if is_instance_valid(f):
				f.queue_free()
		level.on_enemy_killed(GEO)
		level.spawn_explosion(global_position)
		queue_free()
