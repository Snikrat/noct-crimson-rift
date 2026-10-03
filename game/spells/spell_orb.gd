extends Node2D
## Bola de energia do herói (estilo Vengeful Spirit): voa reto, atravessa inimigos e some na parede.

const Sprites := preload("res://game/core/sprites.gd")
const SPEED := 320.0
const LIFETIME := 1.2
const DAMAGE := 2
const SIZE := Vector2(34, 18)

var level
var dir := 1
var life := LIFETIME
var done := false
var hit := []
var damage := DAMAGE
var sprite: AnimatedSprite2D


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.spell_ball()
	sprite.flip_h = dir < 0
	sprite.animation_finished.connect(_on_anim_finished)
	add_child(sprite)
	sprite.play("grow")


func _on_anim_finished() -> void:
	if sprite.animation == "grow":
		sprite.play("fly")
	elif sprite.animation == "burst":
		queue_free()


func _physics_process(delta: float) -> void:
	if done:
		return
	life -= delta
	position.x += dir * SPEED * delta
	var box := Rect2(global_position - SIZE * scale / 2, SIZE * scale)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in hit or not box.intersects(e.get_hurtbox()):
			continue
		hit.append(e)
		e.take_hit(Vector2(dir, 0), damage)
	if life <= 0 or level.is_solid(global_position + Vector2(dir * 8, 0)):
		done = true
		sprite.play("burst")
