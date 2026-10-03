extends Node2D
## Banco: sentar cura tudo e vira o ponto de retorno quando o herói morre.

const SPRITE := preload("res://assets/props/bench.png")  # fonte: art_source/vfx/bench.aseprite
const Fx := preload("res://game/core/fx.gd")

var level


func _ready() -> void:
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
	level.rest_at_bench()


func _draw() -> void:
	draw_texture(SPRITE, Vector2(-24, -32))
