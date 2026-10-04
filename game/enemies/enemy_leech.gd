extends CharacterBody2D
## Sanguessuga de alma (docs/expansao_forma_demoniaca.md, inimigos especiais): bolsa presa no teto,
## cheia de luz roubada. Cai quando o Noct passa embaixo; se encostar, gruda e drena alma.
## O dash solta (e derruba a sanguessuga). Morta, devolve a alma que roubou. Não tira vida.
## Arte: tools/make_new_enemies.lua (sanguessuga_hang, _fall, _crawl, _latched; quadros 24x24).

const Fx := preload("res://game/core/fx.gd")
const ExpSprites := preload("res://game/enemies/expansion_sprites.gd")

const SIZE := Vector2(14, 16)
const GRAVITY := 900.0
const MAX_HP := 6
const GEO := 18
const DRAIN := 11.0          # alma por segundo grudada
const DROP_RANGE := 14.0     # distância horizontal para cair
const CRAWL_SPEED := 22.0
const CHASE_RANGE := 120.0

var level
var hp := MAX_HP
var state := "hang"          # hang -> fall -> crawl; latched quando gruda no Noct
var dir := -1
var flash := 0.0
var stolen := 0.0
var drain_acc := 0.0
var t := 0.0
var regrab := 0.0            # depois de solta, demora um pouco para grudar de novo
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
	sprite.sprite_frames = ExpSprites.frames("sanguessuga", Vector2(24, 24),
		{"hang": [6, true], "fall": [10, true], "crawl": [8, true], "latched": [10, true]})
	add_child(sprite)
	sprite.play("hang")


## A letra do mapa marca a coluna: ela sobe até o teto mais próximo.
func place_feet_at(feet: Vector2) -> void:
	var y := feet.y
	for i in 40:
		if level.is_solid(Vector2(feet.x, y - 16)):
			break
		y -= 16
	position = Vector2(feet.x, floorf(y / 16) * 16 + SIZE.y / 2)


func get_hurtbox() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


## Não machuca no toque: o efeito dela é grudar e drenar.
func get_damagebox() -> Rect2:
	return Rect2(-99999, -99999, 0, 0)


func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(flash - delta, 0)
	regrab = maxf(regrab - delta, 0)
	var p = level.player
	match state:
		"hang":
			velocity = Vector2.ZERO
			if absf(p.global_position.x - global_position.x) < DROP_RANGE and p.global_position.y > global_position.y:
				state = "fall"
				Audio.play_sfx("rise", 0.1, 1.6)
		"fall", "crawl":
			velocity.y = minf(velocity.y + GRAVITY * delta, 420)
			velocity.x = 0
			if state == "crawl":
				if absf(p.global_position.x - global_position.x) < CHASE_RANGE and absf(p.global_position.y - global_position.y) < 40:
					dir = 1 if p.global_position.x > global_position.x else -1
				velocity.x = dir * CRAWL_SPEED
			move_and_slide()
			if state == "fall" and is_on_floor():
				state = "crawl"
			if regrab <= 0 and p.death_timer <= 0 and get_hurtbox().intersects(p.get_hurtbox()):
				state = "latched"
				Audio.play_sfx("absorb", 0.1, 0.6)
		"latched":
			global_position = p.global_position + Vector2(0, -6)
			# Dash solta; morrer ou trocar de sala também.
			if p.dash_timer > 0 or p.death_timer > 0:
				_detach(p)
				return
			drain_acc += DRAIN * delta
			if drain_acc >= 1.0:
				var n := int(drain_acc)
				drain_acc -= n
				var taken := mini(n, p.soul)
				p.soul -= taken
				stolen += taken
				level.refresh_hud()
	_update_sprite()


## O desenho de cada estado fica numa altura diferente do quadro (pendurada, caindo, no chão).
func _update_sprite() -> void:
	var anim := state if state != "hang" else "hang"
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.position.y = {"hang": 4.0, "fall": 0.0, "crawl": -2.0, "latched": 0.0}[state]
	sprite.flip_h = dir < 0
	sprite.modulate = Color(1, 0.45, 0.5) if flash > 0 else Color.WHITE


func _detach(p) -> void:
	state = "fall"
	regrab = 1.2
	velocity = Vector2(-p.facing * 120, -160)
	Fx.sparks(level.world, global_position, Color(0.5, 0.7, 1.0), 6, 70)


func take_hit(_from_dir: Vector2, damage: int) -> void:
	if hp <= 0 or is_queued_for_deletion():
		return
	hp -= damage
	flash = 0.12
	if state == "hang":
		state = "fall"
	if hp <= 0:
		var p = level.player
		p.soul = mini(p.soul + int(stolen), p.MAX_SOUL)
		level.on_enemy_killed(GEO)
		level.spawn_explosion(global_position, false)
		Fx.sparks(level.world, global_position, Color(0.5, 0.75, 1.0), 14, 120, -40)
		queue_free()
