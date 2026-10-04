extends "res://game/player/player_body.gd"
## Noct, camada 2: magia (bola de energia), trovão, cura e a Ultimate.


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
					and is_on_floor() and soul >= SPELL_COST and hp < max_hp and (demon == null or demon.can_heal()):
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
			sprite.play(_form_anim("crouch"))
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
	sprite.play(_form_anim("ultimate_charge"))
	level.show_cutin("ultimate", 1.3)
	Audio.play_sfx("charge", 0.0, 0.9)
	level.shake(2.0)


## Fim da preparação: explosão de aura e o dragão sai.
func _release_dragon() -> void:
	sprite.play(_form_anim("ultimate_pose"))
	Audio.play_sfx("explosion", 0.0, 0.6)
	level.shake(6.0)
	var dragon = DragonScript.new()
	dragon.level = level
	dragon.dir = facing
	dragon.damage = 15 + spell_bonus * 2
	dragon.position = global_position + Vector2(facing * 20, -6)
	level.add_to_world(dragon)
