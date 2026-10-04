extends Node2D
## Corte carmesim da Forma Demoníaca: meia-lua de energia que sai no fim dos combos,
## voa ~5 blocos, atravessa inimigos (2 de dano) e some na parede.
const Fx := preload("res://game/core/fx.gd")

const SPEED := 300.0
const RANGE := 80.0
const DAMAGE := 2
const SIZE := Vector2(18, 34)

var level
var dir := 1
var travelled := 0.0
var hit := []


func _ready() -> void:
	z_index = 2
	var g := Fx.glow(Color(1, 0.15, 0.35), 22, 0.7)
	add_child(g)
	Audio.play_sfx("swing", 0.05, 0.6)


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	position.x += dir * step
	travelled += step
	var box := Rect2(global_position - SIZE / 2, SIZE)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in hit or not box.intersects(e.get_hurtbox()):
			continue
		hit.append(e)
		e.take_hit(Vector2(dir, 0), DAMAGE)
		Fx.sparks(level.world, e.global_position, Color("ff6f96"), 10, 120)
	if travelled >= RANGE or level.is_solid(global_position + Vector2(dir * 6, 0)):
		Fx.sparks(level.world, global_position, Color("d9264f"), 8, 80)
		queue_free()
	queue_redraw()


## Meia-lua em pixels: arcos concêntricos que afinam no fim do alcance.
func _draw() -> void:
	var k := 1.0 - travelled / RANGE
	var a0 := -PI / 2.0 if dir > 0 else PI / 2.0
	var cols := [Color("ffd0dd"), Color("ff6f96"), Color("d9264f"), Color("6e0d2a")]
	for i in cols.size():
		var r := 15.0 - i * 2.0
		for s in 13:
			var ang := a0 + dir * PI * s / 12.0
			var p := (Vector2(cos(ang), sin(ang)) * r).round()
			draw_rect(Rect2(p + Vector2(-dir * 6, 0), Vector2.ONE * (2 if i < 2 else 1)), Color(cols[i], (0.95 - i * 0.18) * (0.4 + 0.6 * k)))
