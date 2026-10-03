extends Node2D
## Fragmento de memória de Mira: um pedaço de fita carmesim flutuando. Pego ao encostar;
## libera o texto na aba "Memórias" da pausa (data/memories.gd).

const Memories := preload("res://data/memories.gd")

var level
var memory_id := ""
var t := 0.0


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, 16)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	var p: Node2D = level.player
	if p and p.get_hurtbox().intersects(Rect2(global_position - Vector2(9, 12), Vector2(18, 24))):
		_collect()


func _collect() -> void:
	var m: Dictionary = Memories.MEMORIES[memory_id]
	GameState.memories[memory_id] = true
	Audio.play_sfx("absorb", 0.0, 0.8)
	level.flash_screen(Color(0.9, 0.15, 0.3), 0.4)
	level.hud.show_banner("Memória de Mira · %d/%d" % [GameState.memories.size(), Memories.ORDER.size()], 2.2)
	var lines: Array = m["lines"].duplicate()
	lines.append(m["noct"])
	level.start_dialog(m["title"], lines)
	queue_free()


func _draw() -> void:
	var bob := sin(t * 2.0) * 3
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	draw_circle(Vector2(0, bob), 12 + pulse * 3, Color(1, 0.15, 0.3, 0.12 + pulse * 0.08))
	# Fita: duas pontas que balançam a partir de um nó.
	var knot := Vector2(0, bob - 4)
	for side in [-1, 1]:
		var pts := PackedVector2Array()
		for i in 7:
			var k := i / 6.0
			pts.append(knot + Vector2(side * (2 + k * 5) + sin(t * 3 + k * 4) * 1.5, k * 13))
		draw_polyline(pts, Color(0.92, 0.12, 0.28), 2.0)
	draw_circle(knot, 2.2, Color(1, 0.4, 0.5))
