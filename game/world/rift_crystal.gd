extends Node2D
## Cristal carmesim do Coração da Fenda ("k" no mapa): bloco sólido que só quebra com o dash da
## Forma Demoníaca (game/player/demon_form.gd, dash_tick). Volta inteiro quando a sala é carregada de novo.
const Fx := preload("res://game/core/fx.gd")

const TILE := 16
const DEEP := Color("3a0a1d")
const MID := Color("9c1238")
const BRIGHT := Color("d9264f")
const HOT := Color("ff6f96")
const WHITE_HOT := Color("ffd0dd")

var level
var cell := Vector2i.ZERO
var t := 0.0


func _ready() -> void:
	add_to_group("rift_crystals")
	var g := Fx.glow(Color(1, 0.12, 0.3), 14, 0.3)
	g.position = Vector2(TILE / 2.0, TILE / 2.0)
	g.z_index = 0
	add_child(g)


func place_feet_at(feet: Vector2) -> void:
	cell = Vector2i(floori(feet.x / TILE), floori((feet.y - 1) / TILE))
	position = Vector2(cell * TILE)
	level.solid[cell] = true


func shatter() -> void:
	level.solid.erase(cell)
	level.rebuild_colliders()
	Fx.sparks(level.world, global_position + Vector2(8, 8), HOT, 16, 140)
	Audio.play_sfx("explosion", 0.1, 1.5)
	level.shake(3.0)
	queue_free()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


## Três pontas de cristal em pixels, com o miolo pulsando.
func _draw() -> void:
	draw_rect(Rect2(0, 0, TILE, TILE), Color(0.05, 0.01, 0.03))
	var pulse := 0.75 + 0.25 * sin(t * 3.0 + cell.y)
	for s in [[2, 5, 14], [7, 4, 16], [11, 4, 12]]:
		var x0: int = s[0]
		var w: int = s[1]
		var h: int = s[2]
		for y in h:
			var k := float(y) / h
			var half := int(roundf(w * 0.5 * (1.0 - k * 0.8)))
			var cx := x0 + w / 2
			for x in range(cx - half, cx + half + 1):
				var c := BRIGHT if x < cx else MID
				if x == cx - half:
					c = HOT
				if y > h - 3 and x == cx:
					c = WHITE_HOT
				draw_rect(Rect2(x, TILE - y - 1, 1, 1), Color(c, pulse if c == WHITE_HOT else 1.0))
	draw_rect(Rect2(0, TILE - 1, TILE, 1), DEEP)
