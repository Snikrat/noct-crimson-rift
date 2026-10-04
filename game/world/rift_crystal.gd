extends Node2D
## Cristal carmesim do Coração da Fenda ("k" no mapa): bloco sólido que só quebra com o dash da
## Forma Demoníaca (game/player/demon_form.gd, dash_tick). Volta inteiro quando a sala é carregada de novo.
## Arte: tools/make_rift_props.lua (cristal_idle_a/b/c, 16x16; cristal_shatter, 32x32).
const Fx := preload("res://game/core/fx.gd")
const Sprites := preload("res://game/core/sprites.gd")
const DIR := "res://assets/areas/coracao_da_fenda/"

const TILE := 16
const LAYOUTS := ["a", "b", "c"]

static var _frames: SpriteFrames

var level
var cell := Vector2i.ZERO
var sprite: AnimatedSprite2D


static func frames() -> SpriteFrames:
	if _frames == null:
		_frames = SpriteFrames.new()
		_frames.remove_animation("default")
		for l in LAYOUTS:
			Sprites.add_sheet(_frames, "idle_" + l, DIR + "cristal_idle_%s.png" % l, Vector2(16, 16), 0, 3, 4, true)
		Sprites.add_sheet(_frames, "shatter", DIR + "cristal_shatter.png", Vector2(32, 32), 0, 5, 16, false)
	return _frames


func _ready() -> void:
	add_to_group("rift_crystals")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames()
	sprite.centered = false
	add_child(sprite)
	var g := Fx.glow(Color(1, 0.12, 0.3), 14, 0.25)
	g.position = Vector2(TILE / 2.0, TILE / 2.0)
	g.z_index = 0
	add_child(g)


func place_feet_at(feet: Vector2) -> void:
	cell = Vector2i(floori(feet.x / TILE), floori((feet.y - 1) / TILE))
	position = Vector2(cell * TILE)
	level.solid[cell] = true
	# Arranjo e começo do pulso variam por bloco, para a parede não parecer carimbada.
	var pick := absi(cell.x * 7 + cell.y * 13) % LAYOUTS.size()
	sprite.play("idle_" + LAYOUTS[pick])
	sprite.frame = absi(cell.x + cell.y * 3) % 4


func shatter() -> void:
	level.solid.erase(cell)
	level.rebuild_colliders()
	# Os estilhaços ficam no mundo depois que o bloco some.
	var burst := AnimatedSprite2D.new()
	burst.sprite_frames = frames()
	burst.position = global_position + Vector2(TILE / 2.0, TILE / 2.0)
	burst.z_index = 2
	burst.animation_finished.connect(burst.queue_free)
	level.add_to_world(burst)
	burst.play("shatter")
	Fx.sparks(level.world, global_position + Vector2(8, 8), Color("ff6f96"), 10, 120)
	Audio.play_sfx("explosion", 0.1, 1.5)
	level.shake(3.0)
	queue_free()
