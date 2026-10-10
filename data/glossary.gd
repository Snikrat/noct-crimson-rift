extends RefCounted
## Glossário de personagens: aba "Glossário" da pausa (game/ui/glossary_view.gd).
## Versão curta de docs/glossario_personagens.md, sem spoilers adiantados: cada verbete só aparece
## depois que o jogador conhece o personagem ("requires"), e cada parágrafo ("parts") só entra
## quando a história chega nele. Os verbetes ainda trancados aparecem como "???".
##
## Condições (iguais para "requires" e para o primeiro item de cada parte):
##   ""             sempre
##   "room:<id>"    sala visitada          "boss:<id>"   chefe derrotado
##   "memory:<id>"  memória de Mira achada "memories:N"  pelo menos N memórias achadas
##   "flag:<id>"    marco da história      "disc:<id>"   descoberta (inscrição, duelo, atalho)

const ORDER := [
	"noct", "mira", "tessa", "zeno", "livia", "brom", "forasteiro",
	"capitao", "vigia", "custodio", "capataz", "vigias",
	"gato", "bringer", "velario", "demon_slime",
	"fenda", "forma",
]

const ENTRIES := {
	"noct": {"name": "Noct", "role": "O viajante", "requires": "", "parts": [
		["", "Aceita trabalhos, entra em ruínas por dinheiro e chama isso de liberdade. Na verdade, está fugindo."],
		["", "Carrega no pulso uma fita carmesim e não diz de onde ela veio. Responde quase tudo com sarcasmo."],
		["", "Desde que perdeu alguém, uma energia carmesim responde a ele. Ele a odeia. E precisa dela."],
		["boss:bringer", "Na catedral, depois do Ceifador cair, continuou golpeando. Admitiu que a fenda gostou de cada golpe. Ele também."],
		["boss:velario", "No Lago Velado, recuperou a lembrança que tinha escondido de si mesmo: a promessa de continuar andando."],
		["boss:demon_slime", "No Trono, ouviu da fenda o que procurava desde o começo: não foi por causa dele que ela morreu."],
		["flag:ending_leave", "Escolheu ir embora. Amarrou a fita de novo, mais firme. Um dia de cada vez."],
		["flag:ending_stay", "Escolheu ficar na fenda, num banco onde o outro lado finalmente não está vazio."],
	]},
	"mira": {"name": "Mira", "role": "A dona da fita", "requires": "memories:1", "parts": [
		["", "A única pessoa que atravessou as defesas de Noct. Ria do sarcasmo dele em vez de se assustar."],
		["memory:the_lie", "Sabia quando ele mentia: ele coça a sobrancelha."],
		["memory:the_ribbon", "Amarrou a fita carmesim no pulso dele numa noite de chuva. \"Pra você lembrar de voltar.\""],
		["memory:the_seat", "Adorava raposas. Contava as que apareciam na beira dos trilhos e dizia que vinham por ela. Ele a chamava de raposinha."],
		["memory:one_day", "Foi ela quem ensinou: \"Um dia de cada vez.\""],
		["memory:the_hum", "Nas últimas semanas, ouvia um zumbido que ninguém mais ouvia. Alguém chamando do outro lado de uma porta."],
		["memory:last_night", "Saiu antes de amanhecer e deixou um bilhete: \"Volto logo. Não faz nada idiota.\" Não voltou."],
		["memory:the_promise", "Na última noite, fez Noct prometer que continuaria andando, e que nunca abriria a porta com raiva."],
		["boss:demon_slime", "Ouvia a fenda antes dele. Foi sozinha até a porta e a fechou com o próprio corpo."],
	]},
	"tessa": {"name": "Tessa", "role": "Também ouve a fenda", "requires": "flag:tessa_saved", "parts": [
		["", "Noct a soltou de uma carroça dos saqueadores, no Bosque. Iam entregá-la ao Custódio porque ela ouve a fenda."],
		["", "Diz que parece alguém chamando do outro lado de uma porta."],
		["flag:tessa_thanked", "Em Pedravelha, apareceu enrolada numa manta grande demais pra ela. Ele disse que era dele. \"Era.\""],
		["flag:tessa_cathedral", "Seguiu Noct até a catedral. Ele a mandou embora com frieza, e esperou ela sumir na estrada antes de seguir."],
		["flag:ending_leave", "Dias depois, sentou na outra ponta do banco. Ele não pediu que ela fosse embora."],
	]},
	"zeno": {"name": "Velho Zeno", "role": "Morador de Pedravelha", "requires": "room:town", "parts": [
		["", "O primeiro a receber Noct na vila. Avisa que o pântano a leste engoliu muitos viajantes."],
		["", "Ensina que o banco guarda a alma de quem cai. Velhos sabem dessas coisas."],
	]},
	"livia": {"name": "Irmã Lívia", "role": "Religiosa de Pedravelha", "requires": "room:town", "parts": [
		["", "Entende a alma que Noct arranca das criaturas e ensina a curar e a lançar magias com ela."],
		["", "Perguntou da fita no pulso dele. \"É só uma fita.\" Os dois sabem que é mentira."],
	]},
	"brom": {"name": "Ferreiro Brom", "role": "Ferreiro de Pedravelha", "requires": "room:town", "parts": [
		["", "Mantém a loja da vila. Quem vai enfrentar o que vive além do cemitério passa por ele antes."],
	]},
	"forasteiro": {"name": "Forasteiro", "role": "Viajante de chapéu", "requires": "room:town", "parts": [
		["", "Mora no alto da vila e conhece os caminhos: a serra, o atalho do vigia, o Gato Infernal além do cemitério."],
		["", "Ouviu dizer que Noct entra nas ruínas por dinheiro. \"E o resto?\" \"O resto ocupa a cabeça.\""],
	]},
	"capitao": {"name": "Capitão dos Desgarrados", "role": "Líder dos saqueadores", "requires": "disc:bandit_captain", "parts": [
		["", "Comandava os saqueadores do Bosque e da Serra. Perguntou se Noct ia bancar o herói. \"Não. Só não gosto de você.\""],
		["disc:forest_cache", "Não era só roubo: o bando entregava ao Custódio da catedral quem ouvisse a fenda."],
	]},
	"vigia": {"name": "Vigia Errante", "role": "Guardião da trilha", "requires": "room:forest", "parts": [
		["", "Guardou uma trilha do Bosque por tanto tempo que esqueceu para quem."],
		["disc:knight_duel", "Pediu um duelo sem mortes, para ver se Noct ainda sabia onde o golpe termina. \"Ainda sabe parar.\""],
	]},
	"custodio": {"name": "Custódio do Selo", "role": "Mago da Ruína", "requires": "disc:evil_wizard", "parts": [
		["", "Prendia no selo quem ouvisse a fenda. \"Então pertence ao selo.\" \"Não pertenço a nada.\""],
		["disc:ruins_memory", "Seus registros falam de almas capturadas. A energia carmesim não obedece ao selo: responde à ausência."],
		["disc:archive_page", "A página arrancada completa: responde à ausência de quem foi amado. O selo pede um nome em troca."],
	]},
	"capataz": {"name": "O capataz", "role": "Minas da Fenda", "requires": "disc:mines_journal", "parts": [
		["", "Só restou o diário. O veio cantava quando alguém na vila chorava. Mandou parar de cavar. Ninguém parou."],
		["", "Os mineiros ainda andam pelas galerias, cobertos de cristal."],
	]},
	"vigias": {"name": "Os vigias", "role": "Cemitério Esquecido", "requires": "disc:watcher_note", "parts": [
		["", "Fecharam os túmulos, mas não aquilo que ouviu seus nomes. Deixaram aberta a passagem pela serra."],
	]},
	"gato": {"name": "Gato Infernal", "role": "Fera do Covil", "requires": "room:lair", "parts": [
		["", "Uma fera de fogo além do cemitério. O primeiro inimigo grande o bastante para Noct sorrir. \"...Finalmente.\""],
		["boss:gato", "Suas garras ficaram cravadas nas luvas de Noct. \"Bom gatinho.\""],
	]},
	"bringer": {"name": "Bringer of Death", "role": "O Ceifador da catedral", "requires": "room:sanctum", "parts": [
		["", "Disse que ela gritou o nome de Noct antes de morrer. O sarcasmo sumiu: \"Repete.\""],
		["boss:bringer", "Arrastou a luta para dentro da cabeça de Noct e admitiu: nunca viu Mira. Só acha o pior medo de cada um e fala com a voz dele."],
	]},
	"velario": {"name": "Velário, o Carcereiro", "role": "Guardião do Lago Velado", "requires": "room:lake", "parts": [
		["", "Usa um véu de funeral e protege uma lanterna. \"Volta. Aqui embaixo não tem nada seu.\" \"Engraçado. Parece meu.\""],
		["boss:velario", "Era a parte de Noct que preferiu esquecer. Não era cruel: achava que protegia. Abriu a lanterna com as próprias mãos."],
	]},
	"demon_slime": {"name": "Demon Slime", "role": "Senhor do Trono", "requires": "room:demon_lair", "parts": [
		["", "\"Foi a sua dor que abriu a porta. Eu só entrei.\""],
		["boss:demon_slime", "Caiu. A fenda, não."],
	]},
	"fenda": {"name": "A Fenda", "role": "Crimson Rift", "requires": "", "parts": [
		["", "Uma rachadura carmesim que respira perto de Pedravelha. Algumas pessoas ouvem um chamado vindo dela."],
		["disc:mines_journal", "Cresce com perda. O veio das minas cantava quando alguém chorava."],
		["room:rift_heart", "No Coração da Fenda, ela bate no mesmo ritmo que o coração de Noct."],
		["boss:demon_slime", "A porta reabriu quando Noct perdeu Mira. A dor dele tem o formato da chave. O poder dele é o que sobrou do selo dela."],
	]},
	"forma": {"name": "Forma Demoníaca", "role": "A raposa", "requires": "boss:velario", "parts": [
		["", "Depois da promessa, o carmesim subiu e, dessa vez, Noct não deixou ele tomar conta. Por um instante, ele se dobrou atrás dele como uma cauda."],
		["", "A forma de raposa nasce da memória, não da raiva. \"Lembrando de você, então.\""],
	]},
}


## A condição está cumprida na partida atual?
static func unlocked(req: String) -> bool:
	if req == "":
		return true
	var kind := req.get_slice(":", 0)
	var id := req.get_slice(":", 1)
	match kind:
		"room": return GameState.visited.has(id)
		"boss": return GameState.defeated_bosses.has(id)
		"memory": return GameState.memories.has(id)
		"memories": return GameState.memories.size() >= int(id)
		"flag": return GameState.flags.has(id)
		"disc": return GameState.discoveries.has(id)
	return false


## Parágrafos já liberados de um verbete.
static func text_of(id: String) -> Array:
	var out := []
	for part in ENTRIES[id]["parts"]:
		if unlocked(part[0]):
			out.append(part[1])
	return out
