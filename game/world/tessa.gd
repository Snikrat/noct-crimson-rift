extends "res://game/world/npc.gd"
## Tessa: alguém que também ouve a fenda. Noct a solta dos saqueadores no Bosque e ela reaparece
## na vila, na catedral e na Margem das Folhas Paradas, depois do Bringer (fases "vínculos", "medo" e
## "revelação" da bíblia). Ela também entra no final. Na margem, Noct faz o contrário do que fez com Mira:
## em vez de dizer que o chamado é cansaço, acredita nela (ideias/arco_tessa.md).
## Usa o desenho da moradora da vila com outra cor.
## Linhas que começam com "* " são narração (sem nome na caixa).

const TINT := Color(0.72, 0.82, 1.0)

var stage := "captive"     # captive (Bosque), town (vila), cathedral (catedral), lake (Margem das Folhas Paradas)


## Ela aparece nesta sala agora?
static func appears(stage_name: String) -> bool:
	var f: Dictionary = GameState.flags
	match stage_name:
		"captive":
			return not f.has("tessa_saved")
		"town":
			# Depois do Bringer o chamado a puxa até o lago; ela só volta à vila depois de encontrar Noct lá.
			return f.has("tessa_saved") and not _at_lake()
		"cathedral":
			return f.has("tessa_thanked") and not f.has("tessa_cathedral")
		"lake":
			return _at_lake()
	return false


## Tessa está na margem do lago esperando o Noct (depois do Bringer, antes da conversa de lá).
static func _at_lake() -> bool:
	var f: Dictionary = GameState.flags
	return f.has("tessa_cathedral") and GameState.defeated_bosses.has("bringer") and not f.has("tessa_lake")


func _ready() -> void:
	kind = "woman"
	npc_name = "Tessa"
	patrol_span = 0.0 if stage != "town" else 16.0
	super._ready()
	sprite.modulate = TINT


func prompt() -> String:
	return Controls.key_label("up") + ("  Soltar" if stage == "captive" else "  Falar")


func interact() -> void:
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture("idle", 0)
	match stage:
		"captive":
			if _bandits_near():
				level.hud.show_banner("Ainda há saqueadores por perto.", 1.6)
				Audio.play_sfx("denied", 0.0)
				return
			GameState.flags["tessa_saved"] = true
			level.start_dialog(npc_name, [
				"* Uma mulher amarrada à carroça. As cordas são novas.",
				"Vai me soltar ou vai ficar olhando?",
				"@neutro: Pensando.",
				"* Noct corta as cordas.",
				"Eles iam me entregar pro Custódio. Disseram que eu ouço a fenda.",
				"@olhar_lateral: E ouve?",
				"...Às vezes. Parece alguém chamando do outro lado de uma porta.",
				"@olhar_baixo: ...",
				"@serio: Vai pra Pedravelha. Fica longe da trilha.",
				"Obrigada. Eu sou Tessa.",
				"@sarcastico: Não transforma isso numa coisa sentimental.",
			], tex)
			_leave()
		"town":
			level.start_dialog(npc_name, _town_lines(), tex)
		"cathedral":
			GameState.flags["tessa_cathedral"] = true
			level.start_dialog(npc_name, [
				"Eu te segui.",
				"@irritado: Volta pra vila.",
				"O chamado é mais forte aqui. Eu preciso saber o que é.",
				"@serio: Aqui você atrapalha.",
				"Você está com medo por mim.",
				"@irritado: Estou com pressa.",
				"...",
				"Tá. Eu volto.",
				"* Ele espera até ela sumir na estrada antes de seguir.",
			], tex)
			_leave()
		"lake":
			GameState.flags["tessa_lake"] = true
			level.start_dialog(npc_name, [
				"* Tessa está sentada na margem, os pés quase na água parada.",
				"* Está enrolada na manta dele. Tremendo, e não é de frio.",
				"@irritado: Eu mandei você voltar.",
				"Eu voltei. Ele me chamou de novo.",
				"Tá mais alto agora. Parece alguém chamando do outro lado de uma porta.",
				"@olhar_baixo: ...",
				"* A mão dele vai até a sobrancelha. Para no meio do caminho.",
				"Você vai dizer que é cansaço?",
				"@fechando_olhos: Não.",
				"@serio: Eu acredito em você.",
				"* Ela olha pra ele como se esperasse uma piada. Não vem nenhuma.",
				"@neutro: Volta pra Pedravelha. Senta no banco. Espera.",
				"E se você não voltar?",
				"@olhar_lateral: Volto. Não faz nada idiota.",
				"* Ela sorri de canto. Ele não sabe de onde tirou essa frase.",
				"* Ele sabe.",
			], tex)
			_leave()


## Conversa na vila, pela ordem da história: frio -> manta (deixada no banco) -> despedida
## -> esperando (depois da margem do lago) -> a promessa (depois do Velário).
func _town_lines() -> Array:
	var f: Dictionary = GameState.flags
	if f.has("tessa_lake"):
		if GameState.defeated_bosses.has("velario"):
			return [
				"Você voltou.",
				"@sarcastico: Ainda não. Só passei pra ver se você obedeceu.",
				"Obedeci. Tá mais baixo aqui. O chamado.",
				"@calmo: Bom.",
				"Você tá diferente.",
				"@olhar_lateral: Lembrei de uma coisa.",
				"Boa ou ruim?",
				"@fechando_olhos: Uma promessa.",
			]
		return [
			"Tô esperando. Do jeito que você mandou.",
			"@olhar_lateral: Hm. Primeira vez que alguém me obedece.",
		]
	if f.has("tessa_jacket") and not f.has("tessa_thanked"):
		f["tessa_thanked"] = true
		return [
			"* Ela está enrolada numa manta escura, grande demais pra ela.",
			"É sua?",
			"@olhar_lateral: Era.",
			"...Obrigada.",
			"@sarcastico: Você já disse isso uma vez. Chega.",
		]
	if f.has("tessa_thanked"):
		return [
			"Você vai pra catedral, não vai?",
			"@neutro: Vou.",
			"E volta?",
			"@olhar_lateral: Hoje primeiro. Amanhã depois.",
			"Isso não é uma resposta.",
			"@sarcastico: Perceptiva.",
		]
	return [
		"Achei que você não ia voltar.",
		"@neutro: Passei por aqui.",
		"Faz frio nessa vila à noite. Ninguém avisa.",
		"@olhar_lateral: Hm.",
	]


func _bandits_near() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_in_group("harmful") and e.global_position.distance_to(global_position) < 320:
			return true
	return false


## Some depois que a conversa acaba (vai embora pela estrada).
func _leave() -> void:
	remove_from_group("interactables")
	await level.hud.dialog.finished
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)
