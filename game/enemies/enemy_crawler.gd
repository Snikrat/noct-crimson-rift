extends CharacterBody2D
## Inimigo de chão (aranha, esqueleto ou carniçal): anda e vira em paredes e beiradas.
## O carniçal ("chase") corre atrás do herói quando ele está perto e na mesma altura.
## O cão infernal ("leap") também persegue e dá saltos em direção ao herói.
## O mineiro cristalizado (Minas da Fenda) anda devagar e persegue quando o herói chega perto.

const Sprites := preload("res://game/core/sprites.gd")
const GRAVITY := 900.0

# Ajustes de cada tipo. frame/feet descrevem os PNGs (tamanho do quadro e linha dos pés).
const KINDS := {
	"spider": {"size": Vector2(22, 14), "hp": 3, "speed": 45.0, "geo": 3, "frame": Vector2(32, 21), "feet": 20},
	"skeleton": {"size": Vector2(16, 36), "hp": 5, "speed": 28.0, "geo": 6, "frame": Vector2(44, 52), "feet": 51},
	"ghoul": {"size": Vector2(18, 36), "hp": 4, "speed": 50.0, "geo": 8, "frame": Vector2(57, 60), "feet": 59, "chase": 110.0},
	"hound": {"size": Vector2(30, 20), "hp": 6, "speed": 60.0, "geo": 12, "frame": Vector2(64, 48), "feet": 47, "chase": 150.0, "leap": true},
	"thing": {"size": Vector2(18, 34), "hp": 7, "speed": 24.0, "geo": 10, "frame": Vector2(33, 45), "feet": 44, "chase": 88.0},
	# "faces_right": o desenho olha para a direita (os dos pacotes olham para a esquerda).
	"miner": {"size": Vector2(20, 38), "hp": 6, "speed": 22.0, "geo": 9, "frame": Vector2(44, 52), "feet": 51, "chase": 72.0, "faces_right": true},
}

var level
var kind := "spider"
var size := Vector2.ZERO
var hp := 3
var speed := 40.0
var geo := 3
var dir := -1
var flash := 0.0
var knock := 0.0
var leaping := false
var leap_cooldown := 1.0
const LEAP_VELOCITY := -330.0
const LEAP_SPEED := 175.0
var sprite: AnimatedSprite2D
var emerging := false
var ambush_state := "active"
var ambush_timer := 0.0
var patrol_timer := 2.0
var resting := false


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var cfg: Dictionary = KINDS[kind]
	size = cfg["size"]
	hp = cfg["hp"]
	speed = cfg["speed"]
	geo = cfg["geo"]

	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)

	var frames: SpriteFrames
	match kind:
		"spider": frames = Sprites.spider()
		"skeleton": frames = Sprites.skeleton()
		"ghoul": frames = Sprites.ghoul()
		"hound": frames = Sprites.hell_hound()
		"thing": frames = Sprites.thing()
		"miner": frames = Sprites.crystal_miner()
	sprite = Sprites.make_sprite(frames, cfg["frame"], cfg["feet"], size.y / 2)
	add_child(sprite)
	sprite.play("walk")
	if emerging and kind == "skeleton":
		ambush_state = "buried"
		sprite.visible = false


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, KINDS[kind]["size"].y / 2)


func get_hurtbox() -> Rect2:
	if ambush_state != "active":
		return Rect2()
	return Rect2(global_position - size / 2, size)


func _physics_process(delta: float) -> void:
	if ambush_state != "active":
		_process_ambush(delta)
		return
	flash = maxf(flash - delta, 0)
	knock = move_toward(knock, 0, 600 * delta)
	leap_cooldown -= delta
	velocity.y = minf(velocity.y + GRAVITY * delta, 400)
	if leaping:
		_process_leap()
		return
	var ahead := global_position + Vector2(dir * (size.x / 2 + 4), size.y / 2 + 4)
	if is_on_floor() and knock == 0 and not level.is_solid(ahead):
		dir = -dir
	var move_speed := speed
	var chasing := false
	var chase: float = KINDS[kind].get("chase", 0.0)
	var p: Node2D = level.player
	if chase > 0 and knock == 0 and absf(p.global_position.y - global_position.y) < 40 \
			and absf(p.global_position.x - global_position.x) < 160:
		var want := 1 if p.global_position.x > global_position.x else -1
		# Só persegue se não for cair da beirada.
		if level.is_solid(global_position + Vector2(want * (size.x / 2 + 4), size.y / 2 + 4)):
			dir = want
			move_speed = chase
			chasing = true
		# O cão infernal salta quando o herói está a poucos passos.
		if KINDS[kind].get("leap", false) and is_on_floor() and leap_cooldown <= 0 \
				and absf(p.global_position.x - global_position.x) < 120:
			dir = want
			leaping = true
			leap_cooldown = 1.6
			velocity = Vector2(dir * LEAP_SPEED, LEAP_VELOCITY)
			sprite.play("jump")
			Audio.play_sfx("bite", 0.1, 0.8)
			return
	if kind == "hound":
		patrol_timer -= delta
		if chasing or flash > 0:
			resting = false
			patrol_timer = 2.5
		elif patrol_timer <= 0:
			resting = not resting
			patrol_timer = 1.4 if resting else 3.0
		if resting:
			move_speed = 0
		sprite.play("run" if chasing else ("idle" if resting else "walk"))
	velocity.x = dir * move_speed + knock
	move_and_slide()
	if is_on_wall() and knock == 0:
		dir = -dir
	_face()
	sprite.modulate = Color(1, 0.35, 0.35) if flash > 0 else Color.WHITE


## Vira o desenho para o lado em que anda (os dos pacotes olham para a esquerda).
func _face() -> void:
	sprite.flip_h = (dir > 0) != KINDS[kind].get("faces_right", false)


## No ar durante o salto: segue reto até tocar o chão.
func _process_leap() -> void:
	velocity.x = dir * LEAP_SPEED + knock
	move_and_slide()
	_face()
	sprite.modulate = Color(1, 0.35, 0.35) if flash > 0 else Color.WHITE
	if is_on_floor() and velocity.y >= 0:
		leaping = false
		sprite.play("walk")


func take_hit(from_dir: Vector2, damage: int) -> void:
	if ambush_state != "active" or hp <= 0 or is_queued_for_deletion():
		return
	hp -= damage
	flash = 0.12
	knock = from_dir.x * 180
	if hp <= 0:
		level.on_enemy_killed(geo)
		level.spawn_explosion(global_position)
		queue_free()


func _process_ambush(delta: float) -> void:
	var p: Node2D = level.player
	if ambush_state == "buried" and absf(p.position.x - position.x) < 100 and absf(p.position.y - position.y) < 48:
		ambush_state = "warning"
		ambush_timer = 0.85
	if ambush_state == "warning":
		ambush_timer -= delta
		queue_redraw()
		if ambush_timer <= 0:
			ambush_state = "rising"
			ambush_timer = 0.85
			sprite.visible = true
			sprite.play("rise")
			queue_redraw()
	elif ambush_state == "rising":
		ambush_timer -= delta
		if ambush_timer <= 0:
			ambush_state = "active"
			dir = 1 if p.position.x > position.x else -1
			sprite.play("walk")


func _draw() -> void:
	if ambush_state == "warning":
		var pulse := 0.5 + 0.5 * sin(ambush_timer * 32)
		var feet := Vector2(0, size.y / 2 - 1)
		draw_line(feet + Vector2(-18, 0), feet + Vector2(18, 0), Color(1, 0.2, 0.45, 0.5 + pulse * 0.5), 2)
		for x in [-12, -4, 5, 13]:
			draw_line(feet + Vector2(x, -2), feet + Vector2(x + 3, -5 - pulse * 3), Color(0.8, 0.55, 0.65), 1)
