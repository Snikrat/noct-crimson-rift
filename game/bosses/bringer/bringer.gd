extends CharacterBody2D
## Bringer of Death: chefe da catedral.
## Ataques: golpe de foice de perto, mãos sombrias que caem do alto e teleporte.
## Fase 2 (metade da vida): arrasta a luta para dentro da cabeça de Noct (Mente do Noct, enter_mind em
## main.gd), invoca três mãos de uma vez, se teleporta mais e provoca Noct com Mira sem pausar a luta.
## Ele nunca tocou em Mira: o que ele faz é achar o pior medo de cada um e falar com a voz dele.

const Sprites := preload("res://game/core/sprites.gd")
const SpellScript := preload("res://game/bosses/bringer/bringer_spell.gd")

const BOSS_ID := "bringer"
const BOSS_NAME := "Bringer of Death"
# Sem ironia: a provocação atravessa a armadura de Noct.
const WAKE_LINES := ["Mais uma alma que ouviu a fenda.", "Ela gritou seu nome antes de morrer.", "@furioso: Repete."]
# Fase 2: ao puxar Noct para a própria cabeça e ao chegar lá (balões que não pausam a luta).
const RIFT_LINE := "Vamos ver o que você esconde aí dentro."
const MIND_LINE := "Bem-vindo à sua cabeça, Noct. Eu só acendi a luz."
# Provocações na Mente do Noct, em ordem: [fala do Bringer, resposta de Noct ou ""].
# Ele confessa a mentira cedo: não precisa ter feito nada com Mira, o medo de Noct faz o trabalho.
const TAUNTS := [
	["Eu menti. Nunca vi a sua Mira.", "@chocado: ..."],
	["Mas você acreditou na hora. Porque é exatamente o que você teme.", "@furioso: Cala a boca."],
	["Eu não tiro nada de ninguém. Só mostro o que vocês já perderam.", ""],
	["O lado esquerdo do banco. Ainda vazio?", "@sombrio: ..."],
	["A fita no seu pulso. Pra lembrar de voltar... pra quem?", "@furioso: Não fala dela."],
	["\"Volto logo.\" Quantas vezes você leu esse bilhete?", ""],
	["Cada golpe seu tem gosto de medo. Continua.", "@maligno: Então engole."],
	["Ela não está aqui. Você está. Sozinho, como sempre quis parecer.", "@furioso: Repete."],
]
const TAUNT_EVERY := Vector2(6.0, 8.5)   # intervalo (s) entre provocações
const SIZE := Vector2(30, 52)
const GRAVITY := 1100.0
const MAX_HP := 40
const WAKE_X := 6 * 16
const WALK_SPEED := 55.0
const MELEE_RANGE := 90.0
# Quadros 140x93: o corpo fica em x≈105 e os pés na linha 91 (desenho olhando para a esquerda).
const BODY_X := 105.0
const FEET_Y := 91.0
const SCYTHE_FRAMES := [4, 6]   # quadros do ataque em que a foice machuca
const SCYTHE_AREA := Rect2(-100, -40, 112, 66)  # olhando para a esquerda, relativo ao centro

var level
var hp := MAX_HP
var state := "sleep"
var timer := 0.0
var dir := -1
var flash := 0.0
var last_action := ""
var dying := false
var sprite: AnimatedSprite2D
var mind_done := false      # já puxou Noct para a Mente do Noct (só uma vez por luta)
var in_mind := false
var taunt_timer := 0.0
var taunt_index := 0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.bringer()
	sprite.centered = false
	sprite.animation_finished.connect(_on_anim_finished)
	add_child(sprite)
	sprite.play("idle")
	_update_facing()


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)


func get_hurtbox() -> Rect2:
	if dying or state == "rift":
		return Rect2(-99999, -99999, 0, 0)
	return Rect2(global_position - SIZE / 2, SIZE)


func is_awake() -> bool:
	return state != "sleep" and not dying


func phase2() -> bool:
	return hp <= MAX_HP / 2


## Corpo não fica no centro do quadro, então o deslocamento muda ao virar.
func _update_facing() -> void:
	sprite.flip_h = dir > 0
	var body_x := (140 - BODY_X) if dir > 0 else BODY_X
	sprite.offset = Vector2(-body_x, -FEET_Y - 1)
	sprite.position.y = SIZE.y / 2


func _physics_process(delta: float) -> void:
	timer -= delta
	flash = maxf(flash - delta, 0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 600)
	velocity.x = 0
	var p: Node2D = level.player

	if in_mind and not dying and state != "rift":
		_taunt(delta)
	if not dying:
		match state:
			"sleep":
				if p.global_position.x > WAKE_X:
					_wake()
			"idle":
				_face(p)
				if timer <= 0:
					_choose_action(p)
			"walk":
				_face(p)
				velocity.x = dir * WALK_SPEED * (1.3 if phase2() else 1.0)
				if absf(p.global_position.x - global_position.x) < MELEE_RANGE:
					_start_attack()
				elif timer <= 0:
					_to_idle()
			"attack":
				_scythe_hit(p)
			"rift":
				# Segurança: se a troca de sala não acontecer, volta a lutar aqui mesmo.
				if timer <= 0:
					_to_idle()
			"vanish":
				sprite.modulate.a = clampf(timer / 0.3, 0, 1)
				if timer <= 0:
					_reappear(p)
			"appear":
				sprite.modulate.a = clampf(1.0 - timer / 0.3, 0, 1)
				if timer <= 0:
					sprite.modulate.a = 1
					_start_attack()

	move_and_slide()
	if flash > 0:
		sprite.modulate = Color(1, 0.4, 0.4, sprite.modulate.a)
	elif state not in ["vanish", "appear"]:
		sprite.modulate = Color(1, 1, 1, 1)


func _face(p: Node2D) -> void:
	var new_dir := 1 if p.global_position.x > global_position.x else -1
	if new_dir != dir:
		dir = new_dir
		_update_facing()


func _wake() -> void:
	state = "idle"
	timer = 1.0
	sprite.play("cast")
	level.on_boss_wake(self)


func _to_idle() -> void:
	state = "idle"
	timer = randf_range(0.3, 0.6) if phase2() else randf_range(0.6, 1.0)
	sprite.play("idle")


func _choose_action(p: Node2D) -> void:
	var dist := absf(p.global_position.x - global_position.x)
	var options := []
	if dist < MELEE_RANGE:
		options = ["attack", "attack", "teleport"]
	else:
		options = ["walk", "cast", "teleport"]
		if phase2():
			options.append("cast")
	options.erase(last_action)
	var action: String = options[randi() % options.size()]
	last_action = action
	match action:
		"attack":
			_start_attack()
		"walk":
			state = "walk"
			timer = 1.6
			sprite.play("walk")
		"cast":
			state = "cast"
			sprite.play("cast")
		"teleport":
			state = "vanish"
			timer = 0.3
			Audio.play_sfx("rise", 0.05, 0.5)


func _start_attack() -> void:
	state = "attack"
	_face(level.player)
	sprite.play("attack")
	Audio.play_sfx("slash", 0.05, 0.7)


func _scythe_hit(p: Node2D) -> void:
	if sprite.frame < SCYTHE_FRAMES[0] or sprite.frame > SCYTHE_FRAMES[1]:
		return
	var area := SCYTHE_AREA
	if dir > 0:
		area.position.x = -area.position.x - area.size.x
	var box := Rect2(global_position + area.position, area.size)
	if box.intersects(p.get_hurtbox()):
		p.hit_by_boss(dir)


## Invoca as mãos sombrias: uma no herói (fase 2: mais duas dos lados).
func _cast_spells() -> void:
	var p: Node2D = level.player
	var feet_y := _ground_below(p.global_position)
	var offsets := [0.0]
	if phase2():
		offsets = [0.0, -70.0, 70.0]
	for ox in offsets:
		var s = SpellScript.new()
		s.level = level
		s.position = Vector2(p.global_position.x + ox, feet_y)
		level.add_to_world(s)


## Procura o chão logo abaixo de um ponto (para a mão nascer no chão, não no ar).
func _ground_below(pos: Vector2) -> float:
	var y := pos.y
	for i in 30:
		if level.is_solid(Vector2(pos.x, y)):
			return floorf(y / 16) * 16
		y += 8
	return pos.y + 19


func _reappear(p: Node2D) -> void:
	# Surge do outro lado do herói, sem sair da arena.
	var side := -1 if p.global_position.x > global_position.x else 1
	var x := p.global_position.x + side * 70
	x = clampf(x, 40, level.player.world_size.x - 40)
	global_position.x = x
	velocity = Vector2.ZERO
	state = "appear"
	timer = 0.3
	_face(p)


func _on_anim_finished() -> void:
	match sprite.animation:
		"attack":
			_to_idle()
		"cast":
			if state == "cast":
				_cast_spells()
				_to_idle()
		"death":
			level.on_boss_defeated(self)
			queue_free()


## Metade da vida: para, conjura e puxa a luta para dentro da cabeça de Noct.
func _start_rift() -> void:
	mind_done = true
	state = "rift"
	timer = 3.0
	velocity = Vector2.ZERO
	sprite.modulate.a = 1
	sprite.play("cast")
	level.say(self, BOSS_NAME, RIFT_LINE, 2.4, 64.0)
	level.enter_mind(self)


## Chamado por main.gd depois da troca de sala: reaparece na Mente do Noct e retoma a luta.
func arrive_in_mind(feet: Vector2) -> void:
	in_mind = true
	place_feet_at(feet)
	velocity = Vector2.ZERO
	state = "appear"
	timer = 0.6
	sprite.modulate.a = 0
	sprite.play("idle")
	_face(level.player)
	taunt_timer = 4.5
	level.say(self, BOSS_NAME, MIND_LINE, 3.2, 64.0)


## Provocações na Mente do Noct: uma fala de tempos em tempos, às vezes com a resposta de Noct.
func _taunt(delta: float) -> void:
	taunt_timer -= delta
	if taunt_timer > 0:
		return
	taunt_timer = randf_range(TAUNT_EVERY.x, TAUNT_EVERY.y)
	# Depois da última, volta a repetir as do meio da lista (sem as respostas, Noct já não responde).
	var i := taunt_index if taunt_index < TAUNTS.size() else randi_range(2, TAUNTS.size() - 1)
	var reply: String = TAUNTS[i][1] if taunt_index < TAUNTS.size() else ""
	taunt_index += 1
	level.say(self, BOSS_NAME, TAUNTS[i][0], 3.2, 64.0)
	level.flash_screen(Color(0.8, 0.05, 0.2), 0.25)
	level.shake(2.0)
	if reply != "":
		get_tree().create_timer(1.6, false).timeout.connect(func():
			if is_instance_valid(self) and not dying and is_instance_valid(level.player):
				level.say(level.player, "", reply, 2.4))


func take_hit(_from_dir: Vector2, damage: int) -> void:
	if dying or state == "rift":
		return
	if state == "sleep":
		_wake()
	hp -= damage
	flash = 0.1
	if hp > 0 and phase2() and not mind_done:
		_start_rift()
		return
	if hp <= 0:
		dying = true
		state = "dead"
		sprite.modulate = Color.WHITE
		sprite.play("death")
		level.shake(8.0)
