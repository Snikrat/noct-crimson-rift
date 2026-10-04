extends CharacterBody2D
## Noct, camada 1: constantes, estado, movimento, animação, amuletos e dano.
## As camadas de cima (magias, combate, player.gd) herdam daqui.
const Fx := preload("res://game/core/fx.gd")

const Sprites := preload("res://game/core/sprites.gd")
const Progression := preload("res://data/progression.gd")
const OrbScript := preload("res://game/spells/spell_orb.gd")
const ThunderScript := preload("res://game/spells/spell_thunder.gd")
const DragonScript := preload("res://game/spells/ultimate_dragon.gd")
const ShardScript := preload("res://game/player/shard_return.gd")
const DemonScript := preload("res://game/player/demon_form.gd")

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
const LAND_TIME := 0.14      # aterrissagem depois de uma queda (agachamento + recuperação)
const LAND_MIN_SPEED := 220.0 # só mostra a pose em quedas de verdade (não em degraus)
const ULTIMATE_TIME := 2.5   # preparação (~1.25s) + dragão
# Garras do Gato (depois do Gato Infernal): deslizar e saltar nas paredes.
const WALL_SLIDE_SPEED := 70.0
const WALL_JUMP_VELOCITY := -400.0
const WALL_JUMP_PUSH := 260.0   # empurrão para longe da parede (some como o recuo)
# Amuleto Um Dia de Cada Vez: parado no chão, recupera alma devagar.
const STILL_TIME := 3.0
const STILL_SOUL_RATE := 8.0    # alma por segundo

const MAX_SOUL := 99
const SOUL_PER_HIT := 11
const SPELL_COST := 33
const HAZARD_SOUL_LOSS := SPELL_COST / 3   # cair nos espinhos também custa um pouco de alma
const TAP_TIME := 0.2      # soltar a magia antes disso = lançar; segurar = concentrar
const FOCUS_TIME := 0.9    # tempo concentrando para curar 1 máscara
const SPELL_COOLDOWN := 0.35

# Golpes corpo a corpo. frames = quadros da animação que acertam;
# area = caixa do golpe olhando para a direita, relativa ao centro do herói
# (o herói tem 40 px de altura: y = -20 é a cabeça, y = +20 são os pés).
const MOVES := {
	"air_punch": {"anim": "air_punch", "frames": [1, 2], "area": Rect2(2, -22, 42, 34), "damage": 1},
	"air_kick": {"anim": "air_kick", "frames": [2, 2], "area": Rect2(2, -24, 48, 36), "damage": 2, "knock": 180},
	# Corte giratório: a energia gira em volta do corpo e acerta dos dois lados.
	"air_spin": {"anim": "air_spin", "frames": [1, 2], "area": Rect2(-26, -30, 52, 50), "damage": 2},
	"air_finish": {"anim": "air_finish", "frames": [0, 0], "area": Rect2(0, -10, 40, 40), "damage": 2},
	"punch": {"anim": "jab", "frames": [2, 2], "area": Rect2(2, -20, 46, 36), "damage": 1},
	"combo": {"anim": "cross", "frames": [1, 2], "area": Rect2(2, -22, 54, 38), "damage": 1},
	"kick": {"anim": "kick", "frames": [2, 4], "area": Rect2(0, -24, 44, 32), "damage": 2, "knock": 260},
	# Combo no chão: jab -> cross -> chute -> soco ascendente -> finalizador (soco no chão).
	"combo4": {"anim": "up_punch", "frames": [3, 5], "area": Rect2(-4, -54, 52, 50), "damage": 2},
	"finisher": {"anim": "low_punch", "frames": [3, 4], "area": Rect2(-6, -26, 66, 46), "damage": 3, "knock": 340},
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
var shatter: Node2D = null    # fragmentos voando até o chão seguro depois dos espinhos
var wall_dir := 0             # lado da parede em que está agarrado (-1/1; 0 = nenhuma)
var still_timer := 0.0        # tempo parado no chão (amuleto Um Dia de Cada Vez)
var still_soul := 0.0

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
# Forma carmesim (0 = normal, 1-3 = níveis). Por enquanto só troca as animações básicas.
var crimson_level := 0
var aura: Sprite2D            # brilho carmesim em volta do herói (criado em player.gd)
var demon: Node2D             # Forma Demoníaca: barra da Fenda, transformação e visual (demon_form.gd)
var crouching := false        # segurando baixo no chão
const WALK_FRACTION := 0.6    # abaixo desta fração da velocidade, anda (walk) em vez de correr
const START_FROM := ["idle", "idle_var", "walk", "land", "run_stop", "look_up", "look_up_loop"]
var idle_time := 0.0          # segundos parado no Idle
const IDLE_VAR_AFTER := 8.0   # depois disso o Noct abaixa a cabeça (idle_var)
var looking_up := false       # segurando cima parado no chão: olha para cima e a câmera sobe
var look_hold := 0.0
var look_offset := Vector2.ZERO   # deslocamento da câmera (somado ao tremor em main.gd)
const LOOK_DELAY := 0.3       # segundos segurando cima antes de olhar (um toque continua sendo "falar")
const LOOK_CAMERA := 48.0     # quanto a câmera sobe, em px
const LOOK_SPEED := 160.0
const CROUCH_HEIGHT := 0.6    # fração da altura que continua levando dano agachado
const CRIMSON_ALIAS := {"fall": "jump", "land": "crouch"}   # usado só se a forma não tiver a animação


# --- Habilidades e nível -----------------------------------------------

func has(skill: String) -> bool:
	return unlocked.has(skill)


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


# --- Movimento ---------------------------------------------------------

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
	velocity.x = input_x * SPEED * (demon.speed_mult() if demon else 1.0) + recoil_x

	var g := GRAVITY * (FALL_MULT if velocity.y > 0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, MAX_FALL)

	if wall_dir != 0 and velocity.y > WALL_SLIDE_SPEED:
		velocity.y = WALL_SLIDE_SPEED

	if buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		buffer_timer = 0
		coyote_timer = 0
		Audio.play_sfx("jump")
	elif buffer_timer > 0 and wall_dir != 0:
		_wall_jump()
	elif Input.is_action_just_pressed("jump") and can_double_jump and not is_on_floor():
		velocity.y = DOUBLE_JUMP_VELOCITY
		can_double_jump = false
		buffer_timer = 0
		double_jump_timer = 0.30
		Audio.play_sfx("jump", 0.1, 1.25)

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT


## Garras do Gato: no ar, empurrando contra uma parede, retorna o lado dela (-1/1); senão 0.
func _wall_side(input_x: float) -> int:
	if not level.has_wall_grip() or is_on_floor() or input_x == 0 or move != "" or hurt_timer > 0:
		return 0
	var dir := int(signf(input_x))
	var x := global_position.x + dir * (SIZE.x / 2 + 2)
	for y in [global_position.y - SIZE.y / 2 + 6, global_position.y + SIZE.y / 2 - 6]:
		if not level.is_solid(Vector2(x, y)):
			return 0
	return dir


func _wall_jump() -> void:
	velocity.y = WALL_JUMP_VELOCITY
	recoil_x = -wall_dir * WALL_JUMP_PUSH
	facing = -wall_dir
	buffer_timer = 0
	can_double_jump = true
	can_air_dash = true
	Fx.sparks(level.world, global_position + Vector2(wall_dir * SIZE.x / 2, 0), Color(1, 0.3, 0.45), 6, 70, 40)
	Audio.play_sfx("jump", 0.1, 1.1)
	wall_dir = 0


## Um Dia de Cada Vez: depois de STILL_TIME parado no chão, a alma volta devagar.
func _still_soul(delta: float, input_x: float) -> void:
	if not GameState.has_charm("one_day") or not is_on_floor() or input_x != 0 or move != "" \
			or focusing or dash_timer > 0 or hurt_timer > 0:
		still_timer = 0.0
		return
	still_timer += delta
	if still_timer < STILL_TIME or soul >= MAX_SOUL:
		return
	still_soul += STILL_SOUL_RATE * delta
	if still_soul >= 1.0:
		soul = mini(soul + int(still_soul), MAX_SOUL)
		still_soul -= int(still_soul)
		level.refresh_hud()


func _footsteps(delta: float) -> void:
	if is_on_floor() and absf(velocity.x) > 60 and move == "" and dash_timer <= 0:
		step_timer -= delta
		if step_timer <= 0:
			step_timer = 0.3
			Audio.play_sfx("step_" + level.theme.get("step", "rock"), 0.12)
	else:
		step_timer = 0.05


# --- Golpes (dados e áreas) --------------------------------------------

func _start_move(name: String) -> void:
	# Cada golpe (inclusive o próximo do combo) sai para o lado que o jogador está apertando.
	# O golpe atual não vira no meio, então área e efeitos seguem o lado escolhido aqui.
	var input_x := Input.get_axis("move_left", "move_right")
	if input_x != 0:
		facing = int(signf(input_x))
		sprite.flip_h = facing < 0
	move = name
	attack_queued = false
	hit_this_swing.clear()
	combo_timer = COMBO_WINDOW + 0.4
	sprite.play(_form_anim(MOVES[name]["anim"]))
	if demon:
		demon.on_move_started(name)
	Audio.play_sfx("swing", 0.08, 0.8 if name in ["kick", "charged", "combo4", "finisher"] else 1.0)


func _cancel_move() -> void:
	move = ""
	orb_pending = false
	attack_queued = false
	charging = false


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


# --- Amuletos ----------------------------------------------------------

func _focus_time() -> float:
	return FOCUS_TIME * (0.6 if GameState.has_charm("quick_focus") else 1.0)


## Dano extra dos golpes (loja + Lâmina Rubra) e das magias (grimório + Magia Afiada).
func _melee_bonus() -> int:
	return nail_damage - 1 + (1 if GameState.has_charm("red_blade") else 0) + (demon.damage_bonus() if demon else 0)


func _spell_bonus() -> int:
	return spell_bonus + (1 if GameState.has_charm("sharp_spell") else 0)


## Chamado ao equipar/remover amuletos: ajusta a vida se a máxima mudou.
func on_charms_changed() -> void:
	hp = mini(hp, max_hp)
	level.refresh_hud()


# --- Animação ----------------------------------------------------------

## Cada animação tem um tamanho de quadro e um ponto dos pés diferente (hero.json).
## Brilho em volta do herói: forma carmesim (níveis), cura e Ultimate. Só visual.
func _update_aura() -> void:
	if aura == null:
		return
	var energy: float = [0.0, 0.22, 0.38, 0.55][crimson_level]
	if focusing:
		energy = maxf(energy, 0.35)
	if ultimate_timer > 0:
		energy = maxf(energy, 0.7)
	var t := Time.get_ticks_msec() / 1000.0
	aura.modulate.a = energy * (0.8 + 0.2 * sin(t * 5.0))
	aura.visible = energy > 0.01


func _apply_offset() -> void:
	var m: Dictionary = meta[sprite.animation]
	var ax: float = m["ax"]
	if sprite.flip_h:
		ax = m["w"] - 1 - ax
	sprite.offset = Vector2(-ax, -m["ay"] - 1)
	sprite.position.y = SIZE.y / 2


## A animação na forma carmesim atual (c<n>_<anim>) quando existe; senão, a normal.
func _form_anim(anim: String) -> String:
	if crimson_level > 0 and sprite.sprite_frames.has_animation("c%d_%s" % [crimson_level, anim]):
		return "c%d_%s" % [crimson_level, anim]
	return anim


## Nome da animação atual sem o prefixo da forma carmesim ("c2_run" -> "run").
func _base_anim() -> String:
	var a := String(sprite.animation)
	if a.length() > 3 and a[0] == "c" and a[1].is_valid_int() and a[2] == "_":
		return a.substr(3)
	return a


func _has_anim(anim: String) -> bool:
	return sprite.sprite_frames.has_animation(anim)


func _play(anim: String) -> void:
	if crimson_level > 0:
		var key := "c%d_%s" % [crimson_level, anim]
		if not sprite.sprite_frames.has_animation(key):
			key = "c%d_%s" % [crimson_level, CRIMSON_ALIAS.get(anim, anim)]
		if sprite.sprite_frames.has_animation(key):
			anim = key
	# Animações com continuação (crouch carmesim, olhar para cima): o _loop segue depois delas.
	if sprite.animation == anim + "_loop":
		return
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
	var idle_before := idle_time
	idle_time = 0.0

	if ultimate_timer > 0:
		pass  # a sequência da Ultimate é controlada por _on_anim_finished
	elif slamming or slam_recover > 0:
		pass  # quadro controlado pelo mergulho
	elif hurt_timer > 0:
		_play("hurt")
	elif move != "":
		pass  # animação do golpe já está tocando
	elif focusing or crouching:
		_play("crouch")
	elif dash_timer > 0:
		_play("air_dash" if not is_on_floor() and sprite.sprite_frames.has_animation("air_dash") else "dash")
	elif land_timer > 0 and is_on_floor():
		_play("land")
	elif wall_dir != 0:
		# Sem animação própria ainda (desenhar no Aseprite: "wall_slide"); de costas para a parede.
		facing = -wall_dir
		sprite.flip_h = facing < 0
		_play("wall_slide" if sprite.sprite_frames.has_animation("wall_slide") else "fall")
	elif not is_on_floor():
		if double_jump_timer > 0:
			_play("double_jump")
		else:
			_play("jump" if velocity.y < 0 else "fall")
	elif looking_up:
		_play("look_up")
	elif absf(velocity.x) > 10:
		# Andar devagar (analógico pela metade) = walk; correr a partir do Idle = arranque antes.
		var gait := "walk" if absf(velocity.x) < SPEED * WALK_FRACTION and _has_anim("walk") else "run"
		if gait == "run" and _base_anim() in START_FROM and _has_anim("run_start"):
			_play("run_start")
		elif _base_anim() == "run_start" and sprite.is_playing():
			pass
		else:
			_play(gait)
	elif _base_anim() == "run" and _has_anim("run_stop"):
		_play("run_stop")   # freada antes de parar
	elif _base_anim() == "run_stop" and sprite.is_playing():
		pass
	else:
		# Parado um tempo (forma normal): o Noct abaixa a cabeça uma vez (idle_var) e volta.
		idle_time = idle_before + get_physics_process_delta_time()
		if sprite.animation == "idle_var" and sprite.is_playing():
			pass
		elif idle_time > IDLE_VAR_AFTER and crimson_level == 0 and sprite.sprite_frames.has_animation("idle_var"):
			sprite.play("idle_var")
			idle_time = 0.0
		else:
			_play("idle")
	_apply_offset()
	_update_aura()


# --- Dano --------------------------------------------------------------

func get_hurtbox() -> Rect2:
	if crouching:
		var h := SIZE.y * CROUCH_HEIGHT
		return Rect2(global_position + Vector2(-SIZE.x / 2, SIZE.y / 2 - h), Vector2(SIZE.x, h))
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
	if level.debug_menu != null and level.debug_menu.god_mode:
		return   # "Invencível" do menu de hacks (F1)
	slamming = false
	slam_recover = 0
	hp -= 1
	if demon:
		demon.on_hurt()
	if from_hazard:
		soul = maxi(soul - HAZARD_SOUL_LOSS, 0)
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
		_shatter_to_safe_pos()
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
	sprite.play(_form_anim("death"))
	level.show_cutin("dor", 1.0, Color(0.7, 0.1, 0.15))


## Espinhos: Noct se desfaz em fragmentos carmesim que voam até o último chão seguro.
func _shatter_to_safe_pos() -> void:
	_end_shatter()
	velocity = Vector2.ZERO
	recoil_x = 0
	hurt_timer = 0
	shatter = ShardScript.new()
	shatter.from = global_position
	shatter.to = safe_pos
	level.world.add_child(shatter)
	invuln_timer = ShardScript.TOTAL + INVULN_TIME
	sprite.visible = false
	if aura:
		aura.visible = false
	level.flash_screen(Color(0.9, 0.1, 0.3), 0.2)
	Audio.play_sfx("absorb", 0.0, 0.7)


## Enquanto os fragmentos voam o Noct fica invisível seguindo o meio deles (a câmera vai junto).
func _process_shatter() -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(shatter):
		_end_shatter()
		return
	if not shatter.done:
		global_position = shatter.center()
		return
	global_position = safe_pos
	_end_shatter()
	was_on_floor = true
	sprite.play("idle")
	_apply_offset()
	Audio.play_sfx("absorb", 0.0, 1.3)


## Volta a mostrar o Noct; os fragmentos que ainda brilham somem sozinhos.
func _end_shatter() -> void:
	shatter = null
	sprite.visible = true


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


const PINK := Color(1.0, 0.25, 0.55)
