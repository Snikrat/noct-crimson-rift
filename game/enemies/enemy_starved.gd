extends CharacterBody2D
## Faminto da Fenda (docs/expansao_forma_demoniaca.md, inimigos especiais): cão sem pele com cristais
## carmesim nas costas. Dorme enrolado e só acorda quando o Noct usa a Forma Demoníaca; aí persegue e
## morde, e a mordida rouba barra da Fenda. Com a forma desligada, foge de volta para a toca e dorme.
## Golpeado dormindo, acorda assustado e foge.
## Arte: tools/make_new_enemies.lua (faminto_sleep, _wake, _idle, _run, _bite; quadro 64x40, pés na 38).

const ExpSprites := preload("res://game/enemies/expansion_sprites.gd")
const Fx := preload("res://game/core/fx.gd")

const SIZE := Vector2(40, 20)
const GRAVITY := 900.0
const MAX_HP := 15
const GEO := 30
const SENSE := 260.0         # distância em que sente a forma acordar
const RUN_SPEED := 150.0
const FLEE_SPEED := 120.0
const BITE_RANGE := 46.0
const BITE_FRAMES := [2, 3]
const BITE_AREA := Rect2(4, -16, 36, 22)   # olhando para a direita, relativo ao centro
const GAUGE_STEAL := 15.0

var level
var hp := MAX_HP
var state := "sleep"         # sleep, wake, chase, bite, flee
var dir := 1
var flash := 0.0
var knock := 0.0
var home := Vector2.ZERO
var bite_cooldown := 0.0
var bit_this := false
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
	sprite.sprite_frames = ExpSprites.frames("faminto", Vector2(64, 40),
		{"sleep": [3, true], "wake": [8, false], "idle": [6, true], "run": [14, true], "bite": [14, false]})
	sprite.position.y = SIZE.y / 2 - 38 + 20   # pés na linha 38 do quadro de 40
	sprite.animation_finished.connect(_on_anim_finished)
	add_child(sprite)
	sprite.play("sleep")


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)
	home = position


func get_hurtbox() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


## Só a mordida machuca (encostar dormindo ou correndo não).
func get_damagebox() -> Rect2:
	return Rect2(-99999, -99999, 0, 0)


func _form_on() -> bool:
	var d = level.player.demon
	return d != null and (d.active or d.transforming > 0)


func _physics_process(delta: float) -> void:
	flash = maxf(flash - delta, 0)
	bite_cooldown -= delta
	velocity.y = minf(velocity.y + GRAVITY * delta, 500)
	velocity.x = 0
	var p = level.player
	var dist: float = absf(p.global_position.x - global_position.x)
	match state:
		"sleep":
			if _form_on() and global_position.distance_to(p.global_position) < SENSE:
				_wake()
		"chase":
			if not _form_on():
				_flee()
			else:
				dir = 1 if p.global_position.x > global_position.x else -1
				if dist < BITE_RANGE and absf(p.global_position.y - global_position.y) < 30 and bite_cooldown <= 0:
					_bite()
				elif not _blocked(dir):
					velocity.x = dir * RUN_SPEED
		"bite":
			_bite_hit(p)
		"flee":
			if _form_on():
				state = "chase"
				sprite.play("run")
			else:
				var to_home := home.x - global_position.x
				dir = 1 if to_home > 0 else -1
				if absf(to_home) < 6 or _blocked(dir):
					_sleep()
				else:
					velocity.x = dir * FLEE_SPEED
	velocity.x += knock
	knock = move_toward(knock, 0, 900 * delta)
	move_and_slide()
	sprite.flip_h = dir < 0
	sprite.modulate = Color(1, 0.45, 0.5) if flash > 0 else Color.WHITE


## Parede, beirada, espinhos ou lava à frente.
func _blocked(side: int) -> bool:
	var ahead := global_position + Vector2(side * (SIZE.x / 2 + 4), 0)
	var below := global_position + Vector2(side * (SIZE.x / 2 + 4), SIZE.y / 2 + 4)
	return level.is_solid(ahead) or not level.is_solid(below) or level.is_hazard(below - Vector2(0, 6))


func _wake() -> void:
	state = "wake"
	sprite.play("wake")
	Audio.play_sfx("encounter", 0.1, 1.4)
	Fx.sparks(level.world, global_position + Vector2(0, -10), Color("d9264f"), 10, 80, -30)


func _sleep() -> void:
	state = "sleep"
	sprite.play("sleep")


func _flee() -> void:
	state = "flee"
	sprite.play("run")


func _bite() -> void:
	state = "bite"
	bit_this = false
	sprite.play("bite")
	Audio.play_sfx("slash", 0.1, 1.3)


func _bite_hit(p) -> void:
	if bit_this or sprite.frame < BITE_FRAMES[0] or sprite.frame > BITE_FRAMES[1]:
		return
	var area := BITE_AREA
	if dir < 0:
		area.position.x = -area.position.x - area.size.x
	if Rect2(global_position + area.position, area.size).intersects(p.get_hurtbox()) and p.invuln_timer <= 0:
		bit_this = true
		p.hit_by_boss(dir)
		if p.demon:
			p.demon.gauge = maxf(p.demon.gauge - GAUGE_STEAL, 0.0)   # a mordida rouba barra da Fenda
		Fx.sparks(level.world, p.global_position, Color("ff6f96"), 10, 100)


func _on_anim_finished() -> void:
	match String(sprite.animation):
		"wake":
			if _form_on():
				state = "chase"
				sprite.play("run")
			else:
				_flee()
		"bite":
			bite_cooldown = 0.6
			if state == "bite":
				state = "chase"
				sprite.play("run")


func take_hit(from_dir: Vector2, damage: int) -> void:
	if hp <= 0 or is_queued_for_deletion():
		return
	hp -= damage
	flash = 0.12
	knock = from_dir.x * 120
	if hp <= 0:
		level.on_enemy_killed(GEO)
		level.spawn_explosion(global_position)
		queue_free()
		return
	if state == "sleep":
		_wake()   # acorda assustado; sem a forma, foge
