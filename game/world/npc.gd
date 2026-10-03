extends Node2D
## Morador da cidade: fica parado, olha para o jogador e conversa quando ele aperta W por perto.

const Sprites := preload("res://game/core/sprites.gd")
const TALK_RANGE := 32.0

var level
var kind := "oldman"
var npc_name := ""
var lines: Array = []
var shop := false
var sprite: AnimatedSprite2D
var home := Vector2.ZERO
var patrol_span := 24.0
var patrol_dir := 1
var pause_timer := 1.0


func _ready() -> void:
	add_to_group("interactables")
	var frames := Sprites.npc(kind)
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	sprite = Sprites.make_sprite(frames, tex.get_size(), tex.get_height() - 1, 0)
	add_child(sprite)
	sprite.play("idle")
	sprite.frame = randi() % frames.get_frame_count("idle")


func place_feet_at(feet: Vector2) -> void:
	position = feet
	home = feet


func can_interact(player: Node2D) -> bool:
	return absf(player.global_position.x - global_position.x) < TALK_RANGE \
		and absf(player.global_position.y + 19 - global_position.y) < 24


func prompt() -> String:
	return Controls.key_label("up") + ("  Loja" if shop else "  Falar")


func interact() -> void:
	if shop:
		level.open_shop(npc_name)
	else:
		level.start_dialog(npc_name, lines, sprite.sprite_frames.get_frame_texture("idle", 0))


func _process(delta: float) -> void:
	var p: Node2D = level.player
	var nearby := p and absf(p.position.x - position.x) < 64 and absf(p.position.y + 19 - position.y) < 40
	nearby = nearby or level.hud.dialog.source == self
	var walking := false
	if not nearby and not level.transitioning and not level.is_shop_open():
		pause_timer -= delta
		if pause_timer <= 0:
			var step := Vector2(patrol_dir * (10.0 if kind == "oldman" else 18.0) * delta, 0)
			if absf(position.x + step.x - home.x) > patrol_span or not level.is_solid(position + step + Vector2(patrol_dir * 8, 3)):
				patrol_dir *= -1
				pause_timer = 1.5
			else:
				position += step
				walking = true
	sprite.play("walk" if walking else "idle")
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	sprite.flip_h = patrol_dir < 0 if walking else (p.position.x < position.x if p else false)
