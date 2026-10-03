extends Node2D
## Amuleto escondido no mapa (caractere C): flutua brilhando e é pego ao encostar.
const Fx := preload("res://game/core/fx.gd")

const Charms := preload("res://data/charms.gd")

var level
var charm_id := ""
var icon: AtlasTexture
var t := 0.0


func _ready() -> void:
	icon = Charms.icon(charm_id)
	add_child(Fx.glow(Color(1, 0.8, 0.4), 22, 0.5))


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, 14)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	var p: Node2D = level.player
	if p and p.get_hurtbox().intersects(Rect2(global_position - Vector2(10, 10), Vector2(20, 20))):
		_collect()


func _collect() -> void:
	var c: Dictionary = Charms.CHARMS[charm_id]
	GameState.owned_charms[charm_id] = true
	Audio.play_sfx("absorb")
	level.flash_screen(Color(1, 0.85, 0.4), 0.3)
	level.start_dialog("Amuleto encontrado", [
		"%s: %s" % [c["name"], c["desc"]],
		"Equipe sentado num banco: pausa > Amuletos.",
		"@desconfiado: Alguém perdeu isso. Agora é meu.",
	])
	queue_free()


func _draw() -> void:
	var bob := sin(t * 2.5) * 3
	var pulse := 0.5 + 0.5 * sin(t * 4)
	draw_circle(Vector2(0, bob), 14 + pulse * 3, Color(1, 0.8, 0.4, 0.15 + pulse * 0.1))
	draw_texture_rect(icon, Rect2(Vector2(-12, -12 + bob), Vector2(24, 24)), false)
