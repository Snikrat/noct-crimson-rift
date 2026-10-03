extends Node2D
## Banco: sentar cura tudo e vira o ponto de retorno quando o herói morre.

var level


func _ready() -> void:
	add_to_group("interactables")


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
	var wood := Color("6b4a3a")
	var dark := Color("3d2a26")
	var iron := Color("2a2533")
	# pés de ferro
	draw_rect(Rect2(-17, -10, 3, 10), iron)
	draw_rect(Rect2(14, -10, 3, 10), iron)
	# assento e encosto
	draw_rect(Rect2(-20, -12, 40, 4), wood)
	draw_rect(Rect2(-20, -9, 40, 1), dark)
	draw_rect(Rect2(-18, -24, 3, 12), iron)
	draw_rect(Rect2(15, -24, 3, 12), iron)
	draw_rect(Rect2(-19, -24, 38, 3), wood)
	draw_rect(Rect2(-19, -19, 38, 3), wood)
	draw_arc(Vector2(0, -24), 6, PI, TAU, 10, iron, 2)
