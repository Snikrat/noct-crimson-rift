extends Node2D
## Trovão (estilo Howling Wraiths): cai do céu acertando tudo logo acima do herói.
## A origem deste nó fica nos pés do herói.

const Sprites := preload("res://game/core/sprites.gd")
const DAMAGE := 3
const HIT_START := 0.1
const HIT_END := 0.4
const AREA := Rect2(-30, -120, 60, 122)

var t := 0.0
var hit := []
var damage := DAMAGE


func _ready() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.lightning()
	sprite.centered = false
	sprite.offset = Vector2(-32, -128)
	sprite.animation_finished.connect(queue_free)
	add_child(sprite)
	sprite.play("strike")


func _physics_process(delta: float) -> void:
	t += delta
	if t < HIT_START or t > HIT_END:
		return
	var box := Rect2(global_position + AREA.position, AREA.size)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in hit or not box.intersects(e.get_hurtbox()):
			continue
		hit.append(e)
		e.take_hit(Vector2.UP, damage)
