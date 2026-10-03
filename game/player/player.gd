extends "res://game/player/player_combat.gd"
## Noct, o herói: corre, pula (pulo duplo), dash e luta com socos e chutes de energia.
## Ganha alma (SOUL) nos golpes e gasta em magias ou na cura. Sobe de nível com XP (progression.gd).
## Este arquivo tem o ciclo principal; o resto fica nas camadas que ele herda:
##   player_body (estado, movimento, animação, dano) -> player_spells (magias) -> player_combat (ataques).


# --- Sala e vida -------------------------------------------------------

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)

	meta = Sprites.hero_meta()
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.hero()
	sprite.centered = false
	sprite.animation_finished.connect(_on_anim_finished)
	add_child(sprite)
	sprite.play("idle")
	_apply_offset()

	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)


func set_world_size(size: Vector2) -> void:
	world_size = size
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(size.x)
	cam.limit_bottom = int(size.y)


## Coloca o herói numa sala nova com os pés no ponto indicado.
func enter_room(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)
	safe_pos = position
	_reset_actions()
	cam.reset_smoothing()


## Ações de combate e movimento não atravessam salas nem sobrevivem à morte.
func _reset_actions() -> void:
	_cancel_move()
	velocity = Vector2.ZERO
	recoil_x = 0
	dash_timer = 0
	trail_timer = 0
	dash_cooldown = 0
	coyote_timer = 0
	buffer_timer = 0
	double_jump_timer = 0
	land_timer = 0
	can_double_jump = true
	can_air_dash = true
	was_on_floor = false
	combo_step = 0
	combo_timer = 0
	attack_held = 0
	vertical_timer = 0
	vertical_dir = Vector2.ZERO
	hit_this_swing.clear()
	focusing = false
	focus_progress = 0
	spell_pressed = false
	spell_held = 0
	slamming = false
	slam_recover = 0
	if ultimate_timer > 0:
		invuln_timer = minf(invuln_timer, 0.3)
	ultimate_timer = 0
	sprite.play("idle")
	_apply_offset()


func revive() -> void:
	_reset_actions()
	hp = max_hp
	death_timer = 0
	hurt_timer = 0
	invuln_timer = INVULN_TIME
	velocity = Vector2.ZERO
	recoil_x = 0
	move = ""
	slamming = false
	ultimate_timer = 0
	sprite.play("idle")


# --- Ciclo principal ---------------------------------------------------

func _physics_process(delta: float) -> void:
	if frozen:
		return
	_tick_timers(delta)

	if death_timer > 0:
		velocity.x = 0
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		move_and_slide()
		if death_timer <= delta:
			level.respawn_player()
		return

	if ultimate_timer > 0:
		velocity = Vector2.ZERO
		_update_animation()
		return

	if slamming:
		_process_slam()
		return

	var input_x := Input.get_axis("move_left", "move_right")
	if hurt_timer > 0 or slam_recover > 0:
		input_x = 0

	if is_on_floor():
		coyote_timer = COYOTE_TIME
		can_double_jump = true
		can_air_dash = true
		_update_safe_pos()

	if Input.is_action_just_pressed("up") and level.try_interact():
		pass
	elif Input.is_action_just_pressed("jump"):
		buffer_timer = JUMP_BUFFER
		focusing = false

	if Input.is_action_just_pressed("ultimate") and has("ultimate") and soul >= MAX_SOUL and hurt_timer <= 0:
		_start_ultimate()
		return

	_handle_spells(delta)
	if slamming:
		return
	if focusing:
		input_x = 0
		buffer_timer = 0

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0 and (is_on_floor() or can_air_dash):
		if input_x != 0:
			facing = int(signf(input_x))
		dash_timer = DASH_TIME
		Audio.play_sfx("dash", 0.1)
		dash_cooldown = DASH_COOLDOWN * (0.5 if GameState.has_charm("swift_step") else 1.0)
		focusing = false
		_cancel_move()
		if not is_on_floor():
			can_air_dash = false

	if dash_timer > 0:
		trail_timer -= delta
		if trail_timer <= 0:
			level.spawn_crimson("trail", global_position, facing)
			trail_timer = 0.04
		velocity = Vector2(facing * DASH_SPEED * (1.2 if GameState.has_charm("swift_step") else 1.0), 0)
	else:
		# Durante um golpe no chão o herói anda devagar.
		var slow := 0.35 if move != "" and is_on_floor() else 1.0
		_move(input_x * slow, delta)

	_handle_attack_input(delta)

	var fall_speed := velocity.y
	move_and_slide()
	# Aterrissagem: toca o chão depois de cair rápido.
	if is_on_floor() and not was_on_floor and fall_speed > LAND_MIN_SPEED:
		land_timer = LAND_TIME
		Audio.play_sfx("land", 0.1)
	was_on_floor = is_on_floor()
	_footsteps(delta)

	_process_hits()
	_check_damage()
	_update_animation()
	queue_redraw()

	if global_position.x < -4:
		level.request_exit("left")
	elif global_position.x > world_size.x + 4:
		level.request_exit("right")


func _on_anim_finished() -> void:
	if ultimate_timer > 0:
		match sprite.animation:
			"ultimate_charge":
				sprite.play("ultimate_burst")
				Audio.play_sfx("thunder", 0.0, 0.7)
				level.shake(3.0)
			"ultimate_burst":
				_release_dragon()
		return
	if move != "" and sprite.animation == MOVES[move]["anim"]:
		move = ""
		if attack_queued:
			_start_combo_hit()


# --- Efeitos desenhados atrás do sprite --------------------------------

func _draw() -> void:
	# Concentrando alma: um brilho rosa que cresce até a cura.
	if focusing:
		var k := focus_progress / _focus_time()
		draw_circle(Vector2(0, 6), 10 + k * 18, Color(PINK, 0.12 + k * 0.2))
		draw_arc(Vector2(0, 6), 26 - k * 10, 0, TAU, 24, Color(1, 0.7, 0.85, 0.6 * k), 1.5)

	# Carregando o golpe: aura pulsando.
	if charging:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 60.0)
		draw_circle(Vector2(0, 0), 16 + pulse * 4, Color(PINK, 0.18 + pulse * 0.12))

	# Ataque para cima/baixo sem animação própria: arco de energia.
	if vertical_timer > 0:
		var center := Vector2(0, -14) if vertical_dir == Vector2.UP else Vector2(0, 12)
		var a0 := deg_to_rad(-160) if vertical_dir == Vector2.UP else deg_to_rad(20)
		var span := deg_to_rad(140)
		draw_arc(center, 28, a0, a0 + span, 18, Color(1, 0.75, 0.9, 0.95), 3)
		draw_arc(center, 22, a0 + 0.2, a0 + span - 0.2, 18, Color(PINK, 0.6), 2)
