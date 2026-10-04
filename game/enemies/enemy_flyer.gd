extends CharacterBody2D
## Inimigo voador.
## - ghost (fantasma): flutua perto de casa e persegue o jogador quando ele chega perto.
## - angel (anjo caído): mantém distância e, de tempos em tempos, mergulha em rasante no herói.
## - skull (caveira de fogo): igual ao anjo, mas mais rápida e insistente.
## - eye (olho demoníaco): fica afastado e atira bolas de fogo na direção do herói.
## - grimoire (grimório voraz, Arquivo Submerso): paira acima do herói e mergulha mordendo.
## - lament (Lamento, Lago Velado): espectro fraco e lento; chora quando o herói chega perto.
##   Arte: tools/make_new_enemies.lua (lamento_fly.png).

const Sprites := preload("res://game/core/sprites.gd")
const ProjectileScript := preload("res://game/enemies/enemy_projectile.gd")
const ExpSprites := preload("res://game/enemies/expansion_sprites.gd")

const KINDS := {
	"ghost": {"size": Vector2(20, 30), "hp": 3, "speed": 70.0, "range": 160.0, "geo": 4},
	"angel": {"size": Vector2(26, 40), "hp": 5, "speed": 60.0, "range": 220.0, "geo": 10,
		"hover": Vector2(0, -60), "swoop": 2.2},
	"skull": {"size": Vector2(24, 28), "hp": 4, "speed": 75.0, "range": 230.0, "geo": 9,
		"hover": Vector2(0, -40), "swoop": 1.5},
	"eye": {"size": Vector2(20, 20), "hp": 3, "speed": 55.0, "range": 240.0, "geo": 8,
		"hover": Vector2(90, -50), "shoot": 2.2},
	# "faces_right": o desenho olha para a direita (os dos pacotes olham para a esquerda).
	"grimoire": {"size": Vector2(22, 22), "hp": 4, "speed": 65.0, "range": 220.0, "geo": 9,
		"hover": Vector2(0, -44), "swoop": 1.9, "faces_right": true},
	"lament": {"size": Vector2(18, 26), "hp": 3, "speed": 42.0, "range": 130.0, "geo": 4,
		"wail": true, "faces_right": true},
}
const SWOOP_SPEED := 240.0
const SWOOP_TIME := 0.55
const SWOOP_COOLDOWN := 2.2

var level
var kind := "ghost"
var size := Vector2.ZERO
var hp := 3
var home := Vector2.ZERO
var flash := 0.0
var t := 0.0
var swoop_timer := 0.0
var swoop_cooldown := 1.0
var wailed := false
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemies")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	size = KINDS[kind]["size"]
	hp = KINDS[kind]["hp"]
	var circle := CircleShape2D.new()
	circle.radius = size.x / 2
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	match kind:
		"angel": sprite.sprite_frames = Sprites.angel()
		"skull": sprite.sprite_frames = Sprites.fire_skull()
		"eye": sprite.sprite_frames = Sprites.flying_eye()
		"grimoire": sprite.sprite_frames = Sprites.grimoire()
		"lament": sprite.sprite_frames = ExpSprites.frames("lamento", Vector2(32, 40), {"fly": [8, true]})
		_: sprite.sprite_frames = Sprites.ghost()
	add_child(sprite)
	sprite.play("fly")


func place_feet_at(pos: Vector2) -> void:
	position = pos
	home = pos


func get_hurtbox() -> Rect2:
	return Rect2(global_position - size / 2, size)


func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(flash - delta, 0)
	swoop_timer -= delta
	swoop_cooldown -= delta
	var cfg: Dictionary = KINDS[kind]
	var p: Node2D = level.player
	var near: bool = p and global_position.distance_to(p.global_position) < cfg["range"]
	if cfg.get("wail", false) and near and not wailed:
		wailed = true
		Audio.play_sfx("rise", 0.1, 0.45)   # o choro do Lamento

	if swoop_timer > 0:
		pass  # mergulhando: mantém a velocidade do rasante
	elif cfg.has("swoop") and near and swoop_cooldown <= 0:
		# Rasante na direção do herói.
		velocity = (p.global_position - global_position).normalized() * SWOOP_SPEED * (1.2 if kind == "skull" else 1.0)
		swoop_timer = SWOOP_TIME
		swoop_cooldown = cfg["swoop"]
		if sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")
	elif cfg.has("shoot") and near and swoop_cooldown <= 0:
		swoop_cooldown = cfg["shoot"]
		_shoot_at(p)
	else:
		var target := home + Vector2(sin(t) * 20, cos(t * 1.3) * 10)
		if near:
			# Anjo e caveira pairam acima do herói; o olho fica de lado; o fantasma vai direto nele.
			var hover: Vector2 = cfg.get("hover", Vector2.ZERO)
			if hover.x != 0:
				hover.x *= -1 if p.global_position.x > global_position.x else 1
			target = p.global_position + hover
		var desired: Vector2 = (target - global_position).normalized() * cfg["speed"]
		velocity = velocity.move_toward(desired, 200 * delta)
		if sprite.animation != "fly":
			sprite.play("fly")
	move_and_slide()

	# Os desenhos dos pacotes olham para a esquerda; os com "faces_right", para a direita.
	if absf(velocity.x) > 5:
		sprite.flip_h = (velocity.x > 0) != cfg.get("faces_right", false)
	sprite.modulate = Color(1, 0.35, 0.35) if flash > 0 else cfg.get("tint", Color.WHITE)


## Bola de fogo do olho demoníaco, mirada no herói.
func _shoot_at(p: Node2D) -> void:
	var fb = ProjectileScript.new()
	fb.level = level
	fb.velocity = (p.global_position - global_position).normalized() * 130
	fb.position = global_position
	level.add_to_world(fb)
	Audio.play_sfx("rise", 0.1, 1.8)


func take_hit(from_dir: Vector2, damage: int) -> void:
	if hp <= 0 or is_queued_for_deletion():
		return
	hp -= damage
	flash = 0.12
	velocity = from_dir * 240
	swoop_timer = 0
	if hp <= 0:
		level.on_enemy_killed(KINDS[kind]["geo"])
		level.spawn_explosion(global_position)
		queue_free()
