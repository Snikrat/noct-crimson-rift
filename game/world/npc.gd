extends Node2D
## Morador da cidade: fica parado, olha para o jogador e conversa quando ele aperta W por perto.

const Sprites := preload("res://game/core/sprites.gd")
const TALK_RANGE := 32.0
const GESTURES := ["nod", "stroke_beard", "tip_hat", "wipe_brow", "look_wrist", "listen"]

var level
var kind := "oldman"
var npc_name := ""
var lines: Array = []
var more: Array = []          # conversas seguintes, uma por vez que o herói volta a falar
var talks := 0
var shop := false
var sprite: AnimatedSprite2D
var home := Vector2.ZERO
var patrol_span := 24.0
var patrol_dir := 1
var pause_timer := 1.0
var gesture_timer := randf_range(6.0, 12.0)   # tempo até o próximo gesto (aceno, mão na barba...)
var gesture := ""                             # gesto tocando agora; volta ao idle quando acaba


func _ready() -> void:
	add_to_group("interactables")
	var frames := Sprites.npc(kind)
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	sprite = Sprites.make_sprite(frames, tex.get_size(), tex.get_height() - 1, 0)
	add_child(sprite)
	sprite.play("idle")
	sprite.frame = randi() % frames.get_frame_count("idle")
	# O diálogo pausa o jogo; o morador continua rodando para mexer a boca enquanto fala.
	process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.process_mode = Node.PROCESS_MODE_PAUSABLE


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
		var convo: Array = lines if talks == 0 or more.is_empty() else more[mini(talks - 1, more.size() - 1)]
		talks += 1
		level.start_dialog(npc_name, convo, sprite.sprite_frames.get_frame_texture("idle", 0))


func _process(delta: float) -> void:
	if get_tree().paused:
		var talking := _talking()
		sprite.process_mode = Node.PROCESS_MODE_ALWAYS if talking else Node.PROCESS_MODE_PAUSABLE
		if talking:
			sprite.play("talk")
		return
	sprite.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	sprite.play(_anim_for(walking, delta))
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	sprite.flip_h = patrol_dir < 0 if walking else (p.position.x < position.x if p else false)


## Está falando agora: a caixa de diálogo aberta é dele e ele tem a animação "talk".
func _talking() -> bool:
	return level.hud.dialog.is_open() and level.hud.dialog.source == self and sprite.sprite_frames.has_animation("talk")


## Anda, fala (durante o diálogo, se o morador tiver "talk"), faz um gesto de vez em quando ou fica parado.
func _anim_for(walking: bool, delta: float) -> String:
	var frames := sprite.sprite_frames
	if walking:
		gesture = ""
		return "walk"
	if _talking():
		gesture = ""
		return "talk"
	if gesture != "":
		if sprite.animation == gesture and not sprite.is_playing():
			gesture = ""
		else:
			return gesture
	gesture_timer -= delta
	if gesture_timer <= 0:
		gesture_timer = randf_range(8.0, 16.0)
		var options := GESTURES.filter(func(g): return frames.has_animation(g))
		if not options.is_empty():
			gesture = options.pick_random()
			sprite.stop()
			return gesture
	return "idle"
