extends Node2D
## Rachadura do Coração da Fenda ("j" no mapa): o chão brilha cada vez mais forte e explode numa coluna
## de energia carmesim. Rachaduras vizinhas explodem em sequência (o atraso vem da coluna no mapa).
## Machuca pelo grupo "harmful" só durante a explosão.
## Arte: tools/make_rift_props.lua (rachadura_idle, _warn, _burst; 16x56, superfície do chão na linha 44).
const Fx := preload("res://game/core/fx.gd")
const Sprites := preload("res://game/core/sprites.gd")
const DIR := "res://assets/areas/coracao_da_fenda/"

const PERIOD := 2.6
const WARN := 0.7
const BURST := 0.35
const FEET_Y := 44

static var _frames: SpriteFrames

var level
var t := 0.0
var sprite: AnimatedSprite2D


static func frames() -> SpriteFrames:
	if _frames == null:
		_frames = SpriteFrames.new()
		_frames.remove_animation("default")
		Sprites.add_sheet(_frames, "idle", DIR + "rachadura_idle.png", Vector2(16, 56), 0, 0, 1, true)
		Sprites.add_sheet(_frames, "warn", DIR + "rachadura_warn.png", Vector2(16, 56), 0, 3, 6, false)
		Sprites.add_sheet(_frames, "burst", DIR + "rachadura_burst.png", Vector2(16, 56), 0, 4, 14, false)
	return _frames


func _ready() -> void:
	add_to_group("harmful")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames()
	sprite.centered = false
	sprite.offset = Vector2(-8, -FEET_Y)
	add_child(sprite)
	sprite.play("idle")


func place_feet_at(feet: Vector2) -> void:
	position = feet
	t = fmod(feet.x / 16.0 * 0.22, PERIOD)


func _phase() -> float:
	return fmod(t, PERIOD)


func get_hurtbox() -> Rect2:
	if _phase() > PERIOD - BURST:
		return Rect2(global_position + Vector2(-7, -40), Vector2(14, 40))
	return Rect2(-99999, -99999, 0, 0)


func _process(delta: float) -> void:
	var before := _phase()
	t += delta
	var ph := _phase()
	var warn_from := PERIOD - BURST - WARN
	# O quadro segue o tempo (as rachaduras ficam em sequência mesmo com a animação parada).
	if ph >= PERIOD - BURST:
		if before < PERIOD - BURST:
			Fx.sparks(level.world, global_position + Vector2(0, -6), Color("ff6f96"), 8, 120, 60)
			Audio.play_sfx("rise", 0.15, 1.2)
		_show("burst", (ph - (PERIOD - BURST)) / BURST)
	elif ph >= warn_from:
		_show("warn", (ph - warn_from) / WARN)
	else:
		_show("idle", 0.0)


func _show(anim: String, k: float) -> void:
	if sprite.animation != anim:
		sprite.animation = anim
	sprite.pause()
	var n := sprite.sprite_frames.get_frame_count(anim)
	sprite.frame = clampi(int(k * n), 0, n - 1)
