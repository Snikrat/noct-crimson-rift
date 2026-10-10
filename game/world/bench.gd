extends Node2D
## Banco: sentar cura tudo e vira o ponto de retorno quando o herói morre.

const SPRITE := preload("res://assets/props/bench.png")  # fonte: art_source/vfx/bench.aseprite
const Fx := preload("res://game/core/fx.gd")

var level
var bench_texture: Texture2D = SPRITE
var bench_region := Rect2(0, 0, 48, 32)
var bench_scale := 1.0


func _ready() -> void:
	if level.room.has("bench_texture"):
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bench_texture = load(level.room["bench_texture"])
		bench_region = bench_texture.get_image().get_used_rect()
		bench_scale = level.room.get("bench_scale", 1.0)
	add_to_group("interactables")
	# Brilho suave na joia carmesim do encosto.
	var glow := Fx.glow(Color(1, 0.15, 0.35), 10, 0.35)
	glow.position = Vector2(0, -29)
	add_child(glow)


func place_feet_at(feet: Vector2) -> void:
	position = feet


func can_interact(player: Node2D) -> bool:
	return absf(player.global_position.x - global_position.x) < 24 \
		and absf(player.global_position.y + 19 - global_position.y) < 8


func prompt() -> String:
	return Controls.key_label("up") + "  Descansar"


## Marca este nó como banco (usado para saber se dá para trocar amuletos).
func rest_here() -> void:
	pass


func interact() -> void:
	if level.room.has("bench_texture"):
		var effect := preload("res://game/world/pixel_effect.gd").new()
		effect.setup("bench-rest", Vector2(10, 14), false)
		effect.position = position - Vector2(0, 3)
		level.world.add_child(effect)
	level.rest_at_bench()


func _draw() -> void:
	var size := bench_region.size * bench_scale
	draw_texture_rect_region(bench_texture, Rect2(Vector2(-size.x / 2.0, -size.y), size), bench_region)
