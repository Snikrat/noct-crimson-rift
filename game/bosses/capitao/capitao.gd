extends CharacterBody2D
## Capitão dos Desgarrados: chefe da Serra. Líder dos saqueadores que vendem ao Custódio quem ouve a fenda.
## Ataques: talho por cima (de perto), estocada com investida (meia distância) e rede de captura
## (de longe: prende Noct e o deixa lento). Com metade da vida perde a paciência: grita, chama um
## dos rapazes e passa a varrer com a cimitarra. Provoca Noct durante a luta sem pausar (balões).
## Desenho do PixelLab (tools/make_capitao.gd), olhando para a direita.

const NetScript := preload("res://game/bosses/capitao/capitao_net.gd")
const HumanoidScript := preload("res://game/enemies/enemy_humanoid.gd")
const DIR := "res://assets/enemies/capitao/"

const BOSS_ID := "capitao"
const BOSS_NAME := "Capitão dos Desgarrados"
const WAKE_LINES := ["Vai bancar o herói?", "@neutro: Não.", "@sarcastico: Só não gosto de você."]
const INTRO_LINE := "Vivo vale mais. Mas morto também serve."
const RAGE_LINE := "Chega de brincadeira. RAPAZES!"
# Provocações em ordem: [fala do Capitão, resposta de Noct ou ""].
const TAUNTS := [
	["O Custódio paga por cabeça. A sua vale o dobro.", "@sarcastico: Ele vai pedir desconto."],
	["Quem ouve a fenda não dorme direito. Eu só ajudo a dormir.", ""],
	["Corre, garoto. Os outros também correram.", "@serio: Quantos você vendeu?"],
	["Perdi a conta. Nome não paga comida.", "@furioso: ..."],
]
const NET_LINE := "@irritado: Uma rede. Sério?"
const DEATH_LINES := ["A lista... tá no esconderijo. Ele vai mandar outro.", "@olhar_baixo: Que mande."]
const TAUNT_EVERY := Vector2(7.0, 10.0)

const SIZE := Vector2(20, 50)
const CELL := Vector2(112, 80)
const FEET := 72.0
const GRAVITY := 1000.0
const MAX_HP := 26
const GEO := 80
const WAKE_RANGE := 170.0
const WALK_SPEED := 62.0
const LUNGE_SPEED := 330.0
# [animação, quadros, fps, loop]
const ANIMS := [["idle", 8, 7, true], ["run", 8, 12, true], ["slash", 10, 14, false], ["lunge", 8, 14, false],
	["throw_net", 8, 13, false], ["hurt", 4, 12, false], ["death", 10, 10, false], ["taunt", 8, 9, false],
	["rage", 10, 10, false], ["spin", 8, 16, false]]
# Quadros em que cada golpe machuca, e a área (olhando para a direita, relativa ao centro do corpo).
const HIT_FRAMES := {"slash": [7, 8], "lunge": [4, 7], "spin": [3, 6]}
const HIT_AREA := {
	"slash": Rect2(0, -30, 46, 56),
	"lunge": Rect2(0, -14, 50, 22),
	"spin": Rect2(-4, -22, 50, 32),
}
const NET_FRAME := 5   # quadro do arremesso em que a rede sai da mão

var level
var kind := "captain"          # mantém o nome do ator de data/rooms/mountain.gd
var discovery := ""
var hp := MAX_HP
var state := "wait"
var timer := 0.0
var dir := -1
var flash := 0.0
var home := Vector2.ZERO
var last_attack := ""
var attack := ""
var net_done := false
var raged := false
var taunt_timer := 0.0
var taunt_index := 0
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for a in ANIMS:
		var tex: Texture2D = load(DIR + a[0] + ".png")
		frames.add_animation(a[0])
		frames.set_animation_speed(a[0], a[2])
		frames.set_animation_loop(a[0], a[3])
		for i in a[1]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * CELL.x, 0, CELL.x, CELL.y)
			frames.add_frame(a[0], at)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = Vector2(-CELL.x / 2, -FEET - 1)
	sprite.position.y = SIZE.y / 2
	add_child(sprite)
	sprite.play("idle")
	sprite.animation_finished.connect(_on_anim_finished)
	if discovery != "" and GameState.discoveries.has(discovery):
		queue_free()


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)
	home = position


func is_awake() -> bool:
	return state not in ["wait", "dead"]


func phase2() -> bool:
	return hp <= MAX_HP / 2


func get_hurtbox() -> Rect2:
	return Rect2() if state == "dead" else Rect2(global_position - SIZE / 2, SIZE)


## Só o golpe machuca, nos quadros certos; encostar no corpo não tira vida (é um duelo de espada).
func get_damagebox() -> Rect2:
	if level.transitioning or level.is_dialog_open() or not HIT_FRAMES.has(state):
		return Rect2()
	var f: Array = HIT_FRAMES[state]
	if sprite.frame < f[0] or sprite.frame > f[1]:
		return Rect2()
	var area: Rect2 = HIT_AREA[state]
	if dir < 0:
		area.position.x = -area.position.x - area.size.x
	area.position += global_position
	return area


func _physics_process(delta: float) -> void:
	timer -= delta
	flash = maxf(flash - delta, 0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 500)
	var p: Node2D = level.player
	var dx: float = p.global_position.x - global_position.x
	var paused: bool = level.transitioning or level.is_dialog_open() or p.death_timer > 0
	if paused and state not in ["dead"]:
		velocity.x = 0
		if state in ["run"]:
			sprite.play("idle")
	else:
		match state:
			"wait":
				velocity.x = 0
				_face(dx)
				if absf(dx) < WAKE_RANGE and absf(p.global_position.y - global_position.y) < 60:
					_wake()
			"intro":
				velocity.x = 0
				_face(dx)
				if sprite.animation == "idle":
					sprite.play("taunt")
					level.say(self, BOSS_NAME, INTRO_LINE, 2.8, 60.0)
			"think":
				velocity.x = move_toward(velocity.x, 0, 800 * delta)
				_face(dx)
				_taunt(delta)
				if timer <= 0:
					_choose(absf(dx))
			"run":
				_face(dx)
				_taunt(delta)
				velocity.x = dir * WALK_SPEED * (1.3 if raged else 1.0)
				if absf(dx) < 56 or timer <= 0:
					_start("slash")
			"windup":
				velocity.x = 0
				# Vira para Noct até o fim do aviso; no último instante o lado do golpe fica fixo.
				if timer > 0.15:
					_face(dx)
				if timer <= 0:
					_start(attack)
			"slash", "spin":
				velocity.x = move_toward(velocity.x, 0, 600 * delta)
				if state == "spin":
					velocity.x = dir * 70.0
			"lunge":
				velocity.x = dir * LUNGE_SPEED if sprite.frame >= 2 and sprite.frame <= 5 else 0.0
			"throw_net":
				velocity.x = 0
				if not net_done and sprite.frame >= NET_FRAME:
					net_done = true
					_throw_net(p)
			"recover", "hurt":
				velocity.x = move_toward(velocity.x, 0, 900 * delta)
				if timer <= 0:
					_to_think()
			"rage":
				velocity.x = 0
			"dead":
				velocity.x = move_toward(velocity.x, 0, 400 * delta)
	# Não persegue para fora da serra nem cai das bordas da plataforma.
	if is_on_floor() and velocity.x != 0:
		var ahead := position + Vector2(signf(velocity.x) * (SIZE.x / 2 + 6), SIZE.y / 2 + 4)
		if not level.is_solid(ahead) or level.is_hazard(ahead - Vector2(0, 7)):
			velocity.x = 0
	move_and_slide()
	sprite.flip_h = dir < 0
	if flash > 0:
		sprite.modulate = Color(1, 0.5, 0.5)
	elif state == "windup":
		sprite.modulate = Color(1.0, 0.82, 0.55)
	else:
		sprite.modulate = Color.WHITE
	queue_redraw()


func _face(dx: float) -> void:
	if absf(dx) > 4:
		dir = 1 if dx > 0 else -1


func _wake() -> void:
	state = "intro"
	level.boss = self
	level.on_boss_wake(self)   # portão, faixa com o nome, música e a troca de falas


func _to_think() -> void:
	state = "think"
	timer = randf_range(0.35, 0.65) if raged else randf_range(0.6, 1.0)
	sprite.play("idle")


## Escolhe pelo alcance: perto talha, meia distância investe, longe joga a rede (e às vezes avança).
func _choose(dist: float) -> void:
	var options: Array
	if dist < 64:
		options = ["slash", "spin"] if raged else ["slash", "slash", "lunge"]
	elif dist < 170:
		options = ["lunge", "lunge", "run"] + (["spin"] if raged else [])
	else:
		options = ["throw_net", "run"]
	if options.size() > 1:
		options.erase(last_attack)
	var pick: String = options[randi() % options.size()]
	last_attack = pick
	if pick == "run":
		state = "run"
		timer = 1.6
		sprite.play("run")
		return
	attack = pick
	state = "windup"
	timer = {"slash": 0.45, "lunge": 0.5, "throw_net": 0.4, "spin": 0.55}[pick] * (0.7 if raged else 1.0)
	sprite.play("idle")
	Audio.play_sfx("charge", 0.05, 0.85)


func _start(name: String) -> void:
	state = name
	net_done = false
	sprite.play(name)
	Audio.play_sfx("swing", 0.05, 0.7 if name == "slash" else 0.85)
	if name == "slash":
		get_tree().create_timer(0.5, false).timeout.connect(func():
			if is_instance_valid(self) and state == "slash":
				level.shake(3.0)
				Audio.play_sfx("land", 0.1, 0.6))


func _throw_net(p: Node2D) -> void:
	var net := NetScript.new()
	net.level = level
	net.position = global_position + Vector2(dir * 18, -14)
	var dist := clampf(absf(p.global_position.x - global_position.x), 60, 260)
	net.velocity = Vector2(dir * dist / 0.75, -230)
	level.add_to_world(net)


func _on_anim_finished() -> void:
	match sprite.animation:
		"taunt":
			if state == "intro":
				taunt_timer = 5.0
				_to_think()
		"slash", "lunge", "throw_net", "spin":
			state = "recover"
			timer = (0.55 if raged else 0.85) if sprite.animation != "throw_net" else 0.4
			sprite.play("idle")
		"hurt":
			if state == "hurt":
				sprite.play("idle")
		"rage":
			_call_the_boys()
			_to_think()
		"death":
			pass


## Provocações durante a luta: uma fala de tempos em tempos, às vezes com a resposta de Noct.
func _taunt(delta: float) -> void:
	taunt_timer -= delta
	if taunt_timer > 0 or taunt_index >= TAUNTS.size():
		return
	taunt_timer = randf_range(TAUNT_EVERY.x, TAUNT_EVERY.y)
	var line: Array = TAUNTS[taunt_index]
	taunt_index += 1
	level.say(self, BOSS_NAME, line[0], 3.0, 60.0)
	if line[1] != "":
		get_tree().create_timer(1.8, false).timeout.connect(func():
			if is_instance_valid(self) and state != "dead":
				level.say(level.player, "", line[1], 2.2))


## A rede acertou Noct (capitao_net.gd): ele comenta só na primeira vez.
func on_net_hit() -> void:
	if not has_meta("net_line"):
		set_meta("net_line", true)
		level.say(level.player, "", NET_LINE, 2.0)


## Metade da vida: pisa forte, grita e um dos rapazes desce a serra para ajudar.
func _start_rage() -> void:
	raged = true
	state = "rage"
	velocity = Vector2.ZERO
	sprite.play("rage")
	level.say(self, BOSS_NAME, RAGE_LINE, 2.6, 60.0)
	level.shake(4.0)
	Audio.play_sfx("encounter", 0.0, 0.9)


func _call_the_boys() -> void:
	var x := clampf(home.x - dir * 140.0, home.x - 170.0, home.x + 170.0)
	var feet := Vector2(x, position.y + SIZE.y / 2)
	if level.is_solid(feet + Vector2(0, 4)) and not level.is_solid(feet - Vector2(0, 8)):
		var bandit = level._spawn(HumanoidScript, feet, {"kind": "light"})
		bandit.state = "alert"
		bandit.timer = 0.6


func take_hit(from_dir: Vector2, damage: int) -> void:
	if state in ["dead", "rage"] or is_queued_for_deletion():
		return
	if state == "wait":
		_wake()
	hp -= damage
	flash = 0.12
	if hp <= 0:
		_defeat()
		return
	if phase2() and not raged:
		_start_rage()
		return
	# Só cambaleia fora dos golpes (no meio do ataque ele aguenta e termina).
	if state in ["think", "run", "recover"]:
		state = "hurt"
		timer = 0.32
		velocity.x = from_dir.x * 120
		sprite.play("hurt")


func _defeat() -> void:
	state = "dead"
	velocity.x = 0
	sprite.modulate = Color.WHITE
	sprite.play("death")
	if discovery != "":
		GameState.discoveries[discovery] = true
	level.on_enemy_killed(GEO)
	if level.boss == self:
		level.boss = null
	level.hud.show_banner("Capitão derrotado · +%d Geo" % GEO)
	level.shake(6.0)
	level.set_gate(false)
	Audio.play_music(level.theme["music"], 1.0, 0.0, 2.5)
	level.say(self, BOSS_NAME, DEATH_LINES[0], 3.2, 40.0)
	get_tree().create_timer(2.2, false).timeout.connect(func():
		if is_instance_valid(level) and is_instance_valid(level.player):
			level.say(level.player, "", DEATH_LINES[1], 2.2))
	# O corpo fica um pouco no chão e some.
	var fade := create_tween()
	fade.tween_interval(3.5)
	fade.tween_property(sprite, "modulate:a", 0.0, 0.8)
	fade.tween_callback(queue_free)


func _draw() -> void:
	if state == "dead":
		return
	# Sombra de contato nos pés.
	draw_set_transform(Vector2(0, SIZE.y / 2), 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 13, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if state == "windup":
		# Aviso: brilho na lâmina e linha do alcance no chão.
		var color := Color(1, 0.72, 0.3)
		var reach: float = {"slash": 46.0, "lunge": 120.0, "spin": 46.0, "throw_net": 0.0}.get(attack, 0.0)
		var tip := Vector2(dir * 14, -SIZE.y / 2 - 6)
		draw_line(tip, tip + Vector2(0, 5), color, 2)
		draw_circle(tip + Vector2(0, 8), 1, color)
		if reach > 0:
			draw_line(Vector2(0, SIZE.y / 2 - 1), Vector2(dir * reach, SIZE.y / 2 - 1), Color(color, 0.45), 1)
