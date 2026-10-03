extends Node2D
## Fragmento de memória de Mira: um pedaço de fita carmesim flutuando. Pego ao encostar;
## libera o texto na aba "Memórias" da pausa (data/memories.gd).
const Fx := preload("res://game/core/fx.gd")

const Memories := preload("res://data/memories.gd")
const SHEET := preload("res://assets/hero/vfx/memory_ribbon.png")  # fonte: art_source/vfx/memory.aseprite
const FRAMES := 6
const SIZE := Vector2(22, 28)

var level
var memory_id := ""
var t := 0.0


func _ready() -> void:
	var glow := Fx.glow(Color(1, 0.15, 0.35), 30, 0.6)
	glow.z_index = 0
	glow.show_behind_parent = true
	add_child(glow)


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
	Fx.sparks(level.world, global_position, Color(1, 0.3, 0.45), 26, 120, 40, 2.0)
	level.hud.show_banner("Memória de Mira · %d/%d" % [GameState.memories.size(), Memories.ORDER.size()], 2.2)
	var lines: Array = m["lines"].duplicate()
	lines.append(m["noct"])
	level.start_dialog(m["title"], lines)
	queue_free()


func _draw() -> void:
	var bob := roundf(sin(t * 2.0) * 3)
	var frame := int(t * 7) % FRAMES
	var src := Rect2(Vector2(frame * SIZE.x, 0), SIZE)
	# O nó da fita (pixel 11,8 de cada quadro) fica 4px acima do centro do halo.
	draw_texture_rect_region(SHEET, Rect2(Vector2(-11, -12 + bob), SIZE), src)
