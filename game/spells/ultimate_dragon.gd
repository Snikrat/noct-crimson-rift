extends Node2D
## ULTIMATE: o Dragão de Energia surge do herói, avança rugindo e acerta todos os inimigos na tela.

const Paths := preload("res://data/asset_paths.gd")
const TEX_PATH := Paths.HERO + "dragon.png"
const HIT_TIME := 0.45     # quando o golpe acerta
const LIFE := 1.3

var level
var dir := 1
var damage := 15
var t := 0.0
var hit_done := false
var sprite: Sprite2D


func _ready() -> void:
	z_index = 5
	sprite = Sprite2D.new()
	var tex: Texture2D = load(TEX_PATH)
	sprite.texture = tex
	sprite.flip_h = dir < 0
	# A boca do dragão fica do lado direito da imagem: ancora a cauda no herói.
	sprite.offset = Vector2(tex.get_width() / 2.0 * dir, -10)
	sprite.modulate = Color(1, 1, 1, 0)
	sprite.scale = Vector2(0.4, 0.4)
	add_child(sprite)
	level.flash_screen(Color(1, 0.2, 0.5), 0.35)


func _process(delta: float) -> void:
	t += delta
	var k := clampf(t / HIT_TIME, 0, 1)
	sprite.scale = Vector2.ONE * lerpf(0.4, 1.25, k)
	position.x += dir * 120 * delta
	if t < HIT_TIME:
		sprite.modulate.a = k
	else:
		sprite.modulate.a = clampf(1.0 - (t - HIT_TIME) / (LIFE - HIT_TIME), 0, 1)
		# Treme levemente enquanto ruge.
		sprite.position = Vector2(randf_range(-2, 2), randf_range(-2, 2))
	if not hit_done and t >= HIT_TIME:
		hit_done = true
		_strike()
	if t >= LIFE:
		queue_free()


## Acerta todos os inimigos visíveis na tela.
func _strike() -> void:
	var cam: Camera2D = level.player.cam
	var center := cam.get_screen_center_position()
	var view := Rect2(center - Vector2(240, 135), Vector2(480, 270))
	for e in get_tree().get_nodes_in_group("enemies"):
		if view.intersects(e.get_hurtbox()):
			e.take_hit(Vector2(dir, 0), damage)
	level.shake(12.0)
	level.hitstop(0.25)
	Audio.play_sfx("explosion", 0.0, 0.5)
	level.flash_screen(Color(1, 1, 1), 0.25)
