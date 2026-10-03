extends Node2D
## VFX cosmético: nunca altera hitboxes ou dano.

var kind := "trail"
var lifetime := 0.24
var age := 0.0
var facing := 1
var follow: Node2D
var textures: Array[Texture2D] = []

func _ready() -> void:
	z_index = 2
	var names: Array = ["trail1", "trail2", "trail3"] if kind == "trail" else [kind]
	for file in names:
		textures.append(load("res://assets/hero/vfx/" + file + ".png"))

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime or (follow and not is_instance_valid(follow)):
		queue_free()
		return
	if is_instance_valid(follow):
		if not follow.focusing and follow.ultimate_timer <= 0:
			queue_free()
			return
		global_position = follow.global_position + Vector2(0, 19)
	queue_redraw()

func _draw() -> void:
	if textures.is_empty():
		return
	var progress := clampf(age / lifetime, 0, 0.999)
	var tex := textures[mini(int(progress * textures.size()), textures.size() - 1)]
	var size := tex.get_size()
	var growth := 1.0 + progress * 0.35 if kind in ["impact", "shockwave"] else 1.0
	size *= growth
	var offset := Vector2(-size.x / 2, -size.y)
	if kind == "trail":
		offset = Vector2(-size.x if facing > 0 else 0, -size.y / 2)
		if facing < 0:
			offset.x = size.x
			size.x *= -1
	draw_texture_rect(tex, Rect2(offset, size), false, Color(1, 0.75, 1, 1.0 - progress))
