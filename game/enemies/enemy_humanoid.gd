extends CharacterBody2D
## Humanos e mago: preparação legível, golpe ativo e recuperação vulnerável.
const Sprites := preload("res://game/core/sprites.gd")
const StrikeScript := preload("res://game/enemies/arcane_strike.gd")
const KINDS := {
	"light": {"hp": 5, "size": Vector2(18, 34), "speed": 58.0, "geo": 10, "windup": 0.5, "recover": 0.6},
	"heavy": {"hp": 9, "size": Vector2(22, 36), "speed": 40.0, "geo": 18, "windup": 0.8, "recover": 0.9},
	"captain": {"hp": 18, "size": Vector2(22, 36), "speed": 48.0, "geo": 80, "windup": 0.75, "recover": 0.85},
	"wizard": {"hp": 28, "size": Vector2(28, 58), "speed": 38.0, "geo": 120, "windup": 0.85, "recover": 1.05},
	"knight": {"hp": 20, "size": Vector2(22, 42), "speed": 60.0, "geo": 90, "windup": 0.65, "recover": 0.75},
}
var level
var kind := "light"
var discovery := ""
var size := Vector2.ZERO
var hp := 5
var MAX_HP := 5
var BOSS_NAME := ""
var state := "patrol"
var timer := 1.5
var dir := -1
var flash := 0.0
var knock := 0.0
var home := Vector2.ZERO
var attack_index := 0
var attack_elapsed := 0.0
var cast_done := false
var challenged := false
var sprite: AnimatedSprite2D

func _ready() -> void:
	var cfg: Dictionary = KINDS[kind]
	size = cfg["size"]
	hp = cfg["hp"]
	MAX_HP = hp
	BOSS_NAME = {"captain": "Capitão dos Desgarrados", "wizard": "Custódio do Selo", "knight": "Vigia Errante"}.get(kind, "Saqueador")
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	add_child(shape)
	var cell := Vector2(48, 48)
	var feet := 45.0
	var factor := 1.1
	if kind == "wizard":
		cell = Vector2(250, 250)
		feet = 167
		factor = 0.7
	elif kind == "knight":
		cell = Vector2(180, 180)
		feet = 114
		factor = 0.85
	sprite = Sprites.make_sprite(Sprites.humanoid(kind), cell, feet, 0)
	sprite.scale = Vector2.ONE * factor
	sprite.position.y = size.y / 2
	add_child(sprite)
	sprite.play("idle")
	_update_animation()
	if kind == "knight":
		state = "friendly"
		add_to_group("interactables")
	else:
		add_to_group("enemies")
	if discovery != "" and GameState.discoveries.has(discovery):
		if kind == "knight":
			state = "spared"
		else:
			queue_free()

func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, size.y / 2)
	home = position

func is_awake() -> bool:
	return state not in ["patrol", "idle", "friendly", "spared", "dead"]

func get_hurtbox() -> Rect2:
	return Rect2(global_position - size / 2, size) if state not in ["friendly", "spared", "dead"] else Rect2()

func get_damagebox() -> Rect2:
	if level.transitioning or level.is_dialog_open():
		return Rect2()
	if state != "attack" or attack_elapsed < 0.25 or attack_elapsed > 0.48 or (kind == "wizard" and attack_index % 2 == 0):
		return Rect2()
	var reach := 72.0 if kind in ["wizard", "knight", "captain"] else 48.0
	return Rect2(global_position + Vector2(4 if dir > 0 else -reach - 4, -size.y / 2), Vector2(reach, size.y))

func can_interact(p: Node2D) -> bool:
	return state in ["friendly", "spared"] and absf(p.position.x - position.x) < 42 and absf(p.position.y - position.y) < 35

func prompt() -> String:
	return Controls.key_label("up") + ("  Aceitar duelo" if challenged and state == "friendly" else "  Falar")

func interact() -> void:
	if state == "spared":
		level.start_dialog(BOSS_NAME, ["Você teve a chance de me matar. Não o fez.", "@olhar_lateral: Não era isso que você pediu.", "Os saqueadores guardam a serra. Na catedral, procure a porta marcada pelo crânio."])
	elif challenged:
		add_to_group("enemies")
		state = "alert"
		timer = 0.8
		level.boss = self
		level.hud.show_banner("Duelo · Vigia Errante")
		Audio.play_sfx("encounter")
	else:
		challenged = true
		level.start_dialog(BOSS_NAME, ["Guardei esta trilha até esquecer para quem.", "@cansado: Parece cansativo.", "Mostre que ainda escolhe onde o golpe termina. Um duelo; sem mortes.", "Use a ação de interação novamente para aceitar. Você pode seguir pela trilha sem lutar."])

func _physics_process(delta: float) -> void:
	flash = maxf(0, flash - delta)
	knock = move_toward(knock, 0, 600 * delta)
	velocity.y = minf(400, velocity.y + 900 * delta)
	velocity.x = knock
	var p: Node2D = level.player
	var dx: float = p.position.x - position.x
	var near := absf(dx) < 190 and absf(p.position.y - position.y) < 60
	if state in ["friendly", "spared"]:
		_face_player(dx)
	elif state == "dead":
		timer -= delta
		if timer <= 0:
			queue_free()
	elif not level.transitioning and not level.is_dialog_open() and not p.frozen and p.death_timer <= 0:
		timer -= delta
		match state:
			"patrol", "idle":
				if near:
					state = "alert"
					timer = 0.35
					_face_player(dx)
					if discovery != "":
						level.boss = self
						level.hud.show_banner(BOSS_NAME)
				elif timer <= 0:
					state = "idle" if state == "patrol" else "patrol"
					timer = 1.2 if state == "idle" else 2.0
				if state == "patrol":
					velocity.x += dir * float(KINDS[kind]["speed"]) * 0.5
			"alert":
				_face_player(dx)
				if timer <= 0:
					state = "chase"
			"chase":
				_face_player(dx)
				if absf(dx) < (150 if kind == "wizard" else 62) and absf(p.position.y - position.y) < 65:
					_begin_windup()
				elif not near and absf(dx) > 300:
					state = "patrol"
					timer = 2
				else:
					velocity.x += dir * float(KINDS[kind]["speed"])
			"windup":
				# O aviso final mantém o lado do golpe legível para a esquiva.
				if timer > 0.2:
					_face_player(dx)
				if timer <= 0:
					_begin_attack()
			"attack":
				attack_elapsed += delta
				if kind == "wizard" and attack_index % 2 == 0 and not cast_done and attack_elapsed >= 0.35:
					cast_done = true
					_cast_seals()
				if timer <= 0:
					state = "recover"
					timer = KINDS[kind]["recover"]
					sprite.play("recover" if sprite.sprite_frames.has_animation("recover") else "idle")
			"recover", "hurt":
				if timer <= 0:
					state = "chase"
	var ahead := position + Vector2(dir * (size.x / 2 + 5), size.y / 2 + 4)
	if is_on_floor() and velocity.x != knock and (not level.is_solid(ahead) or absf(position.x - home.x) > 180):
		velocity.x = knock
		if state == "patrol":
			dir *= -1
	move_and_slide()
	if is_on_wall() and state == "patrol":
		dir *= -1
	_update_animation()
	queue_redraw()

func _begin_windup() -> void:
	state = "windup"
	timer = KINDS[kind]["windup"]
	attack_index += 1
	_update_animation()
	queue_redraw()
	Audio.play_sfx("charge", 0.05, 1.3 if kind == "wizard" else 0.85)

func _begin_attack() -> void:
	state = "attack"
	timer = 0.8 if kind == "wizard" else 0.67
	attack_elapsed = 0
	cast_done = false
	sprite.play("attack2" if attack_index % 2 == 0 and sprite.sprite_frames.has_animation("attack2") else "attack1")
	Audio.play_sfx("swing", 0.05, 0.75)
	queue_redraw()

func _cast_seals() -> void:
	var feet: Vector2 = level.player.position + Vector2(0, 20)
	for offset in [-32, 32]:
		var pos := feet + Vector2(offset, 0)
		for y in range(0, 65, 4):
			if level.is_solid(pos + Vector2(0, y + 2)):
				pos.y = floorf((pos.y + y + 2) / 16) * 16
				var seal := StrikeScript.new()
				seal.level = level
				seal.position = pos
				level.add_to_world(seal)
				break

func _face_player(dx: float) -> void:
	# Evita alternar a orientação quando os corpos se sobrepõem.
	if absf(dx) > 4:
		dir = 1 if dx > 0 else -1

func _update_animation() -> void:
	# Bandits olha para a esquerda no PNG; mago e cavaleiro para a direita.
	sprite.flip_h = dir > 0 if kind in ["light", "heavy", "captain"] else dir < 0
	sprite.modulate = Color(1, 0.55, 0.7) if flash > 0 else Color.WHITE
	if state in ["patrol", "chase"]:
		sprite.play("run" if absf(velocity.x) > 1 else "idle")
	elif state in ["idle", "friendly", "spared", "alert", "windup"]:
		sprite.play("combat_idle" if state in ["alert", "windup"] and sprite.sprite_frames.has_animation("combat_idle") else "idle")

func take_hit(from_dir: Vector2, damage: int) -> void:
	if hp <= 0 or state in ["friendly", "spared", "dead"] or is_queued_for_deletion():
		return
	hp -= damage
	flash = 0.15
	knock = from_dir.x * 140
	if hp <= 0:
		_defeat()
	elif state not in ["attack", "windup"] or kind == "light":
		state = "hurt"
		timer = 0.3
		sprite.play("hurt")

func _defeat() -> void:
	if discovery != "":
		GameState.discoveries[discovery] = true
	if kind == "knight":
		level.geo += KINDS[kind]["geo"]
		level.player.gain_xp(preload("res://data/progression.gd").xp_for_geo(KINDS[kind]["geo"]))
		Audio.play_sfx("absorb")
	else:
		level.on_enemy_killed(KINDS[kind]["geo"])
	if level.boss == self:
		level.boss = null
	if kind == "knight":
		state = "spared"
		remove_from_group("enemies")
		sprite.play("idle")
		level.start_dialog(BOSS_NAME, ["Ainda sabe parar. Leve isto. Você vai precisar mais do que eu.", "+90 Geo. O Vigia Errante reconhece sua vitória.", "@olhar_baixo: ...Continue guardando a trilha."])
	else:
		state = "dead"
		timer = 0.85 if kind == "wizard" else 0.5
		sprite.play("death")
		if kind == "wizard":
			level.hud.show_banner("Selo desfeito · +120 Geo")
		elif kind == "captain":
			level.hud.show_banner("Capitão derrotado · +80 Geo")

func _draw() -> void:
	if state == "windup":
		var color := Color(0.75, 0.4, 1) if kind == "wizard" else Color(1, 0.72, 0.3)
		var point := Vector2(dir * 16, -size.y / 2 - 9)
		draw_line(point, point + Vector2(0, 6), color, 2)
		draw_circle(point + Vector2(0, 9), 1, color)
		var reach := 72.0 if kind in ["wizard", "knight", "captain"] else 48.0
		draw_line(Vector2(0, size.y / 2 - 1), Vector2(dir * reach, size.y / 2 - 1), Color(color, 0.45), 1)
