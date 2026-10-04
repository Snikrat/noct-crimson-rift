extends "res://game/player/player_spells.gd"
## Noct, camada 3: entrada de ataque, combos, golpes para cima/baixo, golpe no chão e acertos.


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


## Próximo golpe da sequência: jab -> cross -> chute -> soco ascendente -> finalizador
## (combo liberado no nível 2). Cada golpe tem antecipação, golpe, impacto e recuperação.
func _start_combo_hit() -> void:
	var airborne := not is_on_floor()
	if combo_timer <= 0 or (not airborne and not has("combo")):
		combo_step = 0
	var chain := ["air_punch", "air_kick", "air_spin", "air_finish"] if airborne else (["punch", "combo", "kick", "combo4", "finisher"] if has("combo") else ["punch"])
	_start_move(chain[combo_step % chain.size()])
	combo_step += 1


func _start_vertical(dir: Vector2) -> void:
	vertical_timer = VERTICAL_ATTACK_TIME
	vertical_dir = dir
	hit_this_swing.clear()
	Audio.play_sfx("swing")


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
		Fx.sparks(level.world, e.global_position, Color(1, 0.3, 0.45), 8, 110)
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
