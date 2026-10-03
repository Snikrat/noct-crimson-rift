extends CharacterBody2D
## Noct, camada 1: constantes, estado, movimento, animação, amuletos e dano.
## As camadas de cima (magias, combate, player.gd) herdam daqui.

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
# Forma carmesim (0 = normal, 1-3 = níveis). Por enquanto só troca as animações básicas.
var crimson_level := 0
var crouching := false        # segurando baixo no chão
const CROUCH_HEIGHT := 0.6    # fração da altura que continua levando dano agachado
const CRIMSON_ALIAS := {"fall": "jump", "land": "crouch"}   # animações sem versão carmesim própria


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
	move = name
	attack_queued = false
	hit_this_swing.clear()
	combo_timer = COMBO_WINDOW + 0.4
	sprite.play(MOVES[name]["anim"])
	Audio.play_sfx("swing", 0.08, 0.8 if name in ["kick", "charged"] else 1.0)


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
	return nail_damage - 1 + (1 if GameState.has_charm("red_blade") else 0)


func _spell_bonus() -> int:
	return spell_bonus + (1 if GameState.has_charm("sharp_spell") else 0)


## Chamado ao equipar/remover amuletos: ajusta a vida se a máxima mudou.
func on_charms_changed() -> void:
	hp = mini(hp, max_hp)
	level.refresh_hud()


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
	if crimson_level > 0:
		var key := "c%d_%s" % [crimson_level, CRIMSON_ALIAS.get(anim, anim)]
		if sprite.sprite_frames.has_animation(key):
			anim = key
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
	elif focusing or crouching:
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


const PINK := Color(1.0, 0.25, 0.55)
