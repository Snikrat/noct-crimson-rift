extends CharacterBody2D
## Noct, o herói: corre, pula (pulo duplo), dash e luta com socos e chutes de energia.
## Ganha alma (SOUL) nos golpes e gasta em magias ou na cura.
## Sobe de nível com XP e libera novos golpes (veja progression.gd).

const Sprites := preload("res://game/core/sprites.gd")
const Progression := preload("res://data/progression.gd")
const OrbScript := preload("res://game/spells/spell_orb.gd")
const ThunderScript := preload("res://game/spells/spell_thunder.gd")
const DragonScript := preload("res://game/spells/ultimate_dragon.gd")

const SIZE := Vector2(14, 40)
const SPEED := 150.0
const GRAVITY := 1100.0
const FALL_MULT := 1.4
const MAX_FALL := 500.0
const JUMP_VELOCITY := -430.0
const DOUBLE_JUMP_VELOCITY := -370.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const DASH_SPEED := 360.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.45
const VERTICAL_ATTACK_TIME := 0.14
const POGO_VELOCITY := -380.0
const RECOIL := 120.0
const INVULN_TIME := 1.0
const HURT_TIME := 0.25
const DEATH_TIME := 1.4
const COMBO_WINDOW := 0.5     # tempo para emendar o próximo golpe do combo
const CHARGE_TIME := 0.6      # segurar o ataque por isso para carregar
const SLAM_SPEED := 650.0
const LAND_TIME := 0.12      # pose de aterrissagem depois de uma queda
const LAND_MIN_SPEED := 220.0 # só mostra a pose em quedas de verdade (não em degraus)
const ULTIMATE_TIME := 2.5   # preparação (~1.25s) + dragão

const MAX_SOUL := 99
const SOUL_PER_HIT := 11
const SPELL_COST := 33
const TAP_TIME := 0.2      # soltar a magia antes disso = lançar; segurar = concentrar
const FOCUS_TIME := 0.9    # tempo concentrando para curar 1 máscara
const SPELL_COOLDOWN := 0.35

# Golpes corpo a corpo. frames = quadros da animação que acertam;
# area = caixa do golpe olhando para a direita, relativa ao centro do herói
# (o herói tem 40 px de altura: y = -20 é a cabeça, y = +20 são os pés).
const MOVES := {
	"air_punch": {"anim": "air_punch", "frames": [1, 2], "area": Rect2(2, -22, 42, 34), "damage": 1},
	"air_kick": {"anim": "air_kick", "frames": [1, 1], "area": Rect2(2, -24, 48, 36), "damage": 2, "knock": 180},
	"air_finish": {"anim": "air_finish", "frames": [0, 0], "area": Rect2(0, -10, 40, 40), "damage": 2},
	"punch": {"anim": "jab", "frames": [2, 2], "area": Rect2(2, -20, 46, 36), "damage": 1},
	"combo": {"anim": "cross", "frames": [1, 2], "area": Rect2(2, -22, 54, 38), "damage": 1},
	"kick": {"anim": "kick", "frames": [1, 3], "area": Rect2(0, -24, 44, 32), "damage": 2, "knock": 260},
	"charged": {"anim": "charged", "frames": [3, 3], "area": Rect2(2, -22, 66, 30), "damage": 4, "knock": 320},
	"uppercut": {"anim": "uppercut", "frames": [3, 5], "area": Rect2(-14, -70, 44, 78), "damage": 3},
	# Socos diagonais: para cima (cima + ataque) e para baixo até o chão (baixo + ataque, no chão).
	"up_punch": {"anim": "up_punch", "frames": [3, 5], "area": Rect2(-4, -66, 50, 56), "damage": 1},
	"low_punch": {"anim": "low_punch", "frames": [3, 4], "area": Rect2(-4, -8, 60, 28), "damage": 2},
	"cast": {"anim": "cast", "frames": [99, 99], "area": Rect2(), "damage": 0},  # pose da magia (não acerta)
}

var level
var world_size := Vector2.ZERO
var frozen := false

# Atributos
## Vida máxima = base (níveis, loja, chefes) + bônus de amuletos (Pele de Pedra).
## "max_hp += 1" continua funcionando: soma na base.
var base_max_hp := 5
var max_hp: int:
	get: return base_max_hp + (1 if GameState.has_charm("stone_skin") else 0)
	set(value): base_max_hp = value - (1 if GameState.has_charm("stone_skin") else 0)
var hp := 5
var soul := 0
var nail_damage := 1          # +1 com a Lâmina Afiada da loja (soma no dano de todos os golpes)
var soul_per_hit := SOUL_PER_HIT  # aumenta com o Coração de Alma e com o nível 6
var spell_bonus := 0          # dano extra das magias (recompensa do Bringer of Death)

# Nível
var lvl := 1
var xp := 0
var unlocked := {}            # nome da habilidade -> true

# Movimento
var facing := 1
var coyote_timer := 0.0
var buffer_timer := 0.0
var can_double_jump := true
var can_air_dash := true
var dash_timer := 0.0
var trail_timer := 0.0
var dash_cooldown := 0.0
var double_jump_timer := 0.0
var land_timer := 0.0
var was_on_floor := true
var step_timer := 0.0       # passos enquanto corre (som depende do chão da área)
var invuln_timer := 0.0
var hurt_timer := 0.0
var death_timer := 0.0
var recoil_x := 0.0
var safe_pos := Vector2.ZERO

# Combate
var move := ""                # golpe em andamento ("" = nenhum)
var combo_step := 0
var combo_timer := 0.0
var attack_queued := false
var attack_held := 0.0
var charging := false
var vertical_timer := 0.0     # golpes para cima/baixo (arco desenhado)
var vertical_dir := Vector2.ZERO
var orb_pending := false      # a magia foi lançada e a bola sai quando a pose chegar no soco
const CAST_RELEASE_FRAME := 4
var hit_this_swing := []
var slamming := false
var slam_recover := 0.0
var ultimate_timer := 0.0

# Magia
var spell_pressed := false
var spell_held := 0.0
var spell_cooldown := 0.0
var focusing := false
var focus_progress := 0.0

var sprite: AnimatedSprite2D
var cam: Camera2D
var meta := {}


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


func has(skill: String) -> bool:
	return unlocked.has(skill)


# --- Nível -------------------------------------------------------------

func gain_xp(amount: int) -> void:
	if lvl >= Progression.MAX_LEVEL:
		return
	xp += amount
	while lvl < Progression.MAX_LEVEL and xp >= Progression.XP_FOR_LEVEL[lvl + 1]:
		lvl += 1
		var r: Dictionary = Progression.REWARDS.get(lvl, {})
		if r.has("unlock"):
			unlocked[r["unlock"]] = true
		max_hp += r.get("hp", 0)
		soul_per_hit += r.get("soul", 0)
		hp = max_hp
		level.on_level_up(lvl, r)


## Fração do caminho até o próximo nível (para a barra de XP).
func xp_progress() -> float:
	if lvl >= Progression.MAX_LEVEL:
		return 1.0
	var a: int = Progression.XP_FOR_LEVEL[lvl]
	var b: int = Progression.XP_FOR_LEVEL[lvl + 1]
	return clampf(float(xp - a) / float(b - a), 0, 1)


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


func _tick_timers(delta: float) -> void:
	coyote_timer -= delta
	buffer_timer -= delta
	dash_timer -= delta
	dash_cooldown -= delta
	double_jump_timer -= delta
	land_timer -= delta
	invuln_timer -= delta
	hurt_timer -= delta
	death_timer -= delta
	spell_cooldown -= delta
	combo_timer -= delta
	vertical_timer -= delta
	slam_recover -= delta
	recoil_x = move_toward(recoil_x, 0, 900 * delta)
	if ultimate_timer > 0:
		ultimate_timer -= delta
		if ultimate_timer <= 0:
			invuln_timer = 0.3


func _move(input_x: float, delta: float) -> void:
	if input_x != 0 and move == "":
		facing = int(signf(input_x))
	velocity.x = input_x * SPEED + recoil_x

	var g := GRAVITY * (FALL_MULT if velocity.y > 0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, MAX_FALL)

	if buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		buffer_timer = 0
		coyote_timer = 0
		Audio.play_sfx("jump")
	elif Input.is_action_just_pressed("jump") and can_double_jump and not is_on_floor():
		velocity.y = DOUBLE_JUMP_VELOCITY
		can_double_jump = false
		buffer_timer = 0
		double_jump_timer = 0.30
		Audio.play_sfx("jump", 0.1, 1.25)

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT


# --- Ataques -----------------------------------------------------------

func _handle_attack_input(delta: float) -> void:
	if hurt_timer > 0 or focusing:
		return
	if Input.is_action_just_pressed("attack"):
		attack_held = 0.0
		if Input.is_action_pressed("up"):
			if has("uppercut"):
				_start_move("uppercut")
			else:
				_start_move("up_punch")
		elif Input.is_action_pressed("down"):
			if is_on_floor():
				_start_move("low_punch")
			elif move.begins_with("air_") or (combo_timer > 0 and String(sprite.animation).begins_with("air_")):
				_start_slam()
			else:
				_start_vertical(Vector2.DOWN)
		elif move != "":
			attack_queued = true   # emenda o próximo golpe quando este acabar
		else:
			_start_combo_hit()
	elif Input.is_action_pressed("attack"):
		attack_held += delta
		if has("charged") and attack_held >= CHARGE_TIME and move == "" and not charging:
			charging = true
			Audio.play_sfx("charge", 0.0, 1.4)
	elif Input.is_action_just_released("attack"):
		if charging:
			charging = false
			_start_move("charged")
			velocity.x = 0
		attack_held = 0.0


## Próximo golpe da sequência: soco de energia -> rajada -> chute (combo liberado no nível 2).
func _start_combo_hit() -> void:
	var airborne := not is_on_floor()
	if combo_timer <= 0 or (not airborne and not has("combo")):
		combo_step = 0
	var chain := ["air_punch", "air_kick", "air_finish"] if airborne else (["punch", "combo", "kick"] if has("combo") else ["punch"])
	_start_move(chain[combo_step % chain.size()])
	combo_step += 1


func _start_move(name: String) -> void:
	move = name
	attack_queued = false
	hit_this_swing.clear()
	combo_timer = COMBO_WINDOW + 0.4
	sprite.play(MOVES[name]["anim"])
	Audio.play_sfx("swing", 0.08, 0.8 if name in ["kick", "charged"] else 1.0)


func _start_vertical(dir: Vector2) -> void:
	vertical_timer = VERTICAL_ATTACK_TIME
	vertical_dir = dir
	hit_this_swing.clear()
	Audio.play_sfx("swing")


func _cancel_move() -> void:
	move = ""
	orb_pending = false
	attack_queued = false
	charging = false


func _footsteps(delta: float) -> void:
	if is_on_floor() and absf(velocity.x) > 60 and move == "" and dash_timer <= 0:
		step_timer -= delta
		if step_timer <= 0:
			step_timer = 0.3
			Audio.play_sfx("step_" + level.theme.get("step", "rock"), 0.12)
	else:
		step_timer = 0.05


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


func _move_rect(name: String) -> Rect2:
	var area: Rect2 = _reach(MOVES[name]["area"])
	if facing < 0:
		area.position.x = -area.position.x - area.size.x
	return Rect2(global_position + area.position, area.size)


func _vertical_rect() -> Rect2:
	if vertical_dir == Vector2.UP:
		return Rect2(global_position + _reach(Rect2(-20, -60, 40, 38)).position, _reach(Rect2(-20, -60, 40, 38)).size)
	return Rect2(global_position + _reach(Rect2(-20, 14, 40, 36)).position, _reach(Rect2(-20, 14, 40, 36)).size)


## Alcance Longo: aumenta a área do golpe em 30%, mantendo o lado de onde ela sai.
func _reach(area: Rect2) -> Rect2:
	if not GameState.has_charm("long_reach"):
		return area
	var grown := Rect2(area.position * 1.3, area.size * 1.3)
	return grown


func _focus_time() -> float:
	return FOCUS_TIME * (0.6 if GameState.has_charm("quick_focus") else 1.0)


## Dano extra dos golpes (loja + Lâmina Rubra) e das magias (grimório + Magia Afiada).
func _melee_bonus() -> int:
	return nail_damage - 1 + (1 if GameState.has_charm("red_blade") else 0)


func _spell_bonus() -> int:
	return spell_bonus + (1 if GameState.has_charm("sharp_spell") else 0)


## Chamado ao equipar/remover amuletos: ajusta a vida se a máxima mudou.
func on_charms_changed() -> void:
	hp = mini(hp, max_hp)
	level.refresh_hud()


func _process_hits() -> void:
	if orb_pending and move == "cast" and sprite.frame >= CAST_RELEASE_FRAME:
		_release_orb()
	if move != "":
		var m: Dictionary = MOVES[move]
		if sprite.animation == m["anim"] and sprite.frame >= m["frames"][0] and sprite.frame <= m["frames"][1]:
			_hit_area(_move_rect(move), Vector2(facing, 0), m["damage"] + _melee_bonus(), m.get("knock", 0.0))
	if vertical_timer > 0:
		var landed := _hit_area(_vertical_rect(), vertical_dir, 1 + _melee_bonus(), 0.0)
		if vertical_dir == Vector2.DOWN and not "spike" in hit_this_swing:
			for h in level.hazards:
				if _vertical_rect().intersects(h):
					hit_this_swing.append("spike")
					landed = true
					break
		if landed and vertical_dir == Vector2.DOWN:
			velocity.y = POGO_VELOCITY
			can_double_jump = true
			can_air_dash = true


## Acerta todos os inimigos na área (cada um uma vez por golpe). Retorna true se acertou algo.
func _hit_area(area: Rect2, dir: Vector2, damage: int, knock: float) -> bool:
	var landed := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in hit_this_swing or not area.intersects(e.get_hurtbox()):
			continue
		hit_this_swing.append(e)
		if not landed:
			Audio.play_sfx("impact", 0.12)
		e.take_hit(dir, damage)
		if knock > 0 and "knock" in e:
			e.knock = dir.x * knock
		soul = mini(soul + soul_per_hit + (6 if GameState.has_charm("hungry_heart") else 0), MAX_SOUL)
		landed = true
	if landed:
		if dir.x != 0:
			recoil_x = -facing * RECOIL
		level.hitstop(0.05 if damage >= 3 else 0.035)
		if damage >= 3:
			level.shake(3.0)
	return landed


# --- Magias e cura -----------------------------------------------------

func _handle_spells(delta: float) -> void:
	if Input.is_action_just_pressed("spell") and hurt_timer <= 0:
		if Input.is_action_pressed("up"):
			_cast_thunder()
		else:
			spell_pressed = true
			spell_held = 0.0

	if spell_pressed:
		if Input.is_action_pressed("spell"):
			spell_held += delta
			if spell_held >= TAP_TIME and not focusing \
					and is_on_floor() and soul >= SPELL_COST and hp < max_hp:
				focusing = true
				level.spawn_crimson("circle", global_position + Vector2(0, 19), facing, _focus_time(), self)
				_cancel_move()
		else:
			if spell_held < TAP_TIME:
				_cast_orb()
			spell_pressed = false
			focusing = false
			focus_progress = 0

	if not focusing:
		focus_progress = 0
		return
	if not is_on_floor() or hp >= max_hp or soul < SPELL_COST:
		focusing = false
		return
	focus_progress += delta
	if focus_progress >= _focus_time():
		soul -= SPELL_COST
		hp += 1
		focus_progress = 0
		Audio.play_sfx("heal")
		focusing = hp < max_hp and soul >= SPELL_COST
		if focusing:
			level.spawn_crimson("circle", global_position + Vector2(0, 19), facing, _focus_time(), self)
			sprite.frame = 0  # a aura recomeça a crescer para a próxima máscara
			sprite.play("crouch")
		level.refresh_hud()


## Começa a pose da magia; a bola sai do punho no quadro CAST_RELEASE_FRAME.
func _cast_orb() -> void:
	if soul < SPELL_COST or spell_cooldown > 0:
		return
	spell_cooldown = SPELL_COOLDOWN
	_start_move("cast")
	orb_pending = true


func _release_orb() -> void:
	orb_pending = false
	if soul < SPELL_COST:
		return
	soul -= SPELL_COST
	var orb = OrbScript.new()
	orb.level = level
	orb.dir = facing
	orb.damage += _spell_bonus()
	if has("wave"):
		orb.damage += 1
		orb.scale = Vector2(1.4, 1.4)
	orb.position = global_position + Vector2(facing * 24, -8)
	level.add_to_world(orb)
	Audio.play_sfx("wind", 0.1, 1.3)
	recoil_x = -facing * 90


func _cast_thunder() -> void:
	if soul < SPELL_COST or spell_cooldown > 0:
		return
	soul -= SPELL_COST
	spell_cooldown = SPELL_COOLDOWN
	var thunder = ThunderScript.new()
	thunder.position = global_position + Vector2(0, SIZE.y / 2)
	thunder.damage += _spell_bonus()
	level.add_to_world(thunder)
	Audio.play_sfx("thunder", 0.1)
	level.shake(3.0)
	velocity.y = minf(velocity.y, -60)


## Finalização do combo aéreo: baixo + ataque mergulha sem gastar alma.
func _start_slam() -> void:
	slamming = true
	_cancel_move()
	combo_timer = 0
	combo_step = 0
	charging = false
	spell_pressed = false
	focusing = false
	dash_timer = 0
	velocity = Vector2(0, SLAM_SPEED)
	invuln_timer = maxf(invuln_timer, 0.2)
	sprite.play("slam")
	sprite.pause()
	sprite.frame = 0
	Audio.play_sfx("rise", 0.05, 0.6)


func _process_slam() -> void:
	velocity = Vector2(0, SLAM_SPEED)
	move_and_slide()
	# Mergulhar protege contra criaturas, mas não permite atravessar lava/espinhos.
	if hurt_timer <= 0:
		for hazard in level.hazards:
			if get_hurtbox().intersects(hazard):
				_take_damage(0, true)
				return
	if global_position.y > world_size.y + SIZE.y:
		_take_damage(0, true)
		return
	invuln_timer = maxf(invuln_timer, 0.1)
	_update_animation()
	if not is_on_floor():
		return
	slamming = false
	slam_recover = 0.3
	level.spawn_crimson("impact", global_position + Vector2(0, 20), facing, 0.35)
	level.spawn_crimson("shockwave", global_position + Vector2(0, 20), facing, 0.45)
	sprite.frame = 1
	hit_this_swing.clear()
	var blast := Rect2(global_position + Vector2(-72, -30), Vector2(144, 40))
	_hit_area(blast, Vector2.UP, 4 + _melee_bonus(), 0.0)
	level.shake(8.0)
	Audio.play_sfx("earth", 0.05)


## ULTIMATE: gasta toda a alma e invoca o Dragão de Energia, que acerta tudo na tela.
func _start_ultimate() -> void:
	level.spawn_crimson("circle", global_position + Vector2(0, 19), facing, ULTIMATE_TIME, self)
	soul = 0
	_cancel_move()
	focusing = false
	spell_pressed = false
	ultimate_timer = ULTIMATE_TIME
	invuln_timer = ULTIMATE_TIME + 0.5
	velocity = Vector2.ZERO
	# 1) Em pé acumulando poder -> 2) agachado carregando a esfera -> 3) pose final, que solta o dragão.
	sprite.play("ultimate_charge")
	level.show_cutin("ultimate", 1.3)
	Audio.play_sfx("charge", 0.0, 0.9)
	level.shake(2.0)


## Fim da preparação: explosão de aura e o dragão sai.
func _release_dragon() -> void:
	sprite.play("ultimate_pose")
	Audio.play_sfx("explosion", 0.0, 0.6)
	level.shake(6.0)
	var dragon = DragonScript.new()
	dragon.level = level
	dragon.dir = facing
	dragon.damage = 15 + spell_bonus * 2
	dragon.position = global_position + Vector2(facing * 20, -6)
	level.add_to_world(dragon)


# --- Animação ----------------------------------------------------------

## Cada animação tem um tamanho de quadro e um ponto dos pés diferente (hero.json).
func _apply_offset() -> void:
	var m: Dictionary = meta[sprite.animation]
	var ax: float = m["ax"]
	if sprite.flip_h:
		ax = m["w"] - 1 - ax
	sprite.offset = Vector2(-ax, -m["ay"] - 1)
	sprite.position.y = SIZE.y / 2


func _play(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


func _update_animation() -> void:
	if death_timer > 0:
		_apply_offset()
		return
	sprite.flip_h = facing < 0
	var blink := invuln_timer > 0 and hurt_timer <= 0 and ultimate_timer <= 0 and not slamming \
		and int(invuln_timer * 20) % 2 == 0
	sprite.modulate.a = 0.35 if blink else 1.0

	if ultimate_timer > 0:
		pass  # a sequência da Ultimate é controlada por _on_anim_finished
	elif slamming or slam_recover > 0:
		pass  # quadro controlado pelo mergulho
	elif hurt_timer > 0:
		_play("hurt")
	elif move != "":
		pass  # animação do golpe já está tocando
	elif focusing:
		_play("crouch")
	elif dash_timer > 0:
		_play("dash")
	elif land_timer > 0 and is_on_floor():
		_play("land")
	elif not is_on_floor():
		if double_jump_timer > 0:
			_play("double_jump")
		else:
			_play("jump" if velocity.y < 0 else "fall")
	elif absf(velocity.x) > 10:
		_play("run")
	else:
		_play("idle")
	_apply_offset()


# --- Dano --------------------------------------------------------------

func get_hurtbox() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


func _check_damage() -> void:
	if invuln_timer > 0:
		return
	var hb := get_hurtbox()
	for h in level.hazards:
		if hb.intersects(h):
			_take_damage(0, true)
			return
	for e in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("harmful"):
		var damagebox: Rect2 = e.get_damagebox() if e.has_method("get_damagebox") else e.get_hurtbox()
		if hb.intersects(damagebox):
			var dir := signf(global_position.x - e.global_position.x)
			_take_damage(dir if dir != 0 else -facing, false)
			return


## Golpes de chefe que não vêm do corpo (ex.: foice do Bringer).
func hit_by_boss(knock_dir: float) -> void:
	if invuln_timer > 0 or death_timer > 0:
		return
	_take_damage(knock_dir, false)


func _take_damage(knock_dir: float, from_hazard: bool) -> void:
	slamming = false
	slam_recover = 0
	hp -= 1
	invuln_timer = INVULN_TIME
	hurt_timer = HURT_TIME
	dash_timer = 0
	vertical_timer = 0
	_cancel_move()
	focusing = false
	focus_progress = 0
	spell_pressed = false
	level.refresh_hud()
	level.hitstop(0.12)
	Audio.play_sfx("player_hit")
	level.shake(5.0)
	if hp <= 0:
		_die()
		return
	if from_hazard:
		global_position = safe_pos
		velocity = Vector2.ZERO
		recoil_x = 0
	else:
		velocity.y = -220
		recoil_x = knock_dir * 240


func _die() -> void:
	death_timer = DEATH_TIME
	hurt_timer = 0
	invuln_timer = DEATH_TIME + INVULN_TIME
	velocity = Vector2.ZERO
	recoil_x = 0
	sprite.modulate.a = 1.0
	sprite.flip_h = facing < 0
	sprite.play("death")
	level.show_cutin("dor", 1.0, Color(0.7, 0.1, 0.15))


## Guarda o último chão firme longe de espinhos, para voltar ao cair neles.
func _update_safe_pos() -> void:
	var foot_y := global_position.y + SIZE.y / 2 + 2
	var half_w := SIZE.x / 2
	if not (level.is_solid(Vector2(global_position.x - half_w, foot_y)) and level.is_solid(Vector2(global_position.x + half_w, foot_y))):
		return
	var area := get_hurtbox().grow(24)
	for h in level.hazards:
		if area.intersects(h):
			return
	safe_pos = global_position


# --- Efeitos desenhados atrás do sprite --------------------------------

const PINK := Color(1.0, 0.25, 0.55)


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
