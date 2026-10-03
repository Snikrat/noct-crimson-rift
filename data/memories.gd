extends RefCounted
## Memórias de Mira: fragmentos escondidos pelas salas (chave "memories" do arquivo da sala).
## Cada uma libera um texto curto na aba "Memórias" da pausa. Escritas pela bíblia de Noct:
## mostram Mira viva (rindo do sarcasmo, pegando as mentiras) e só aos poucos o que aconteceu.
## "noct" é o que ele diz (ou não diz) ao encontrar o fragmento.
## As três últimas ficam atrás de paredes carmesim (Passo da Fenda, depois do Bringer).

const ORDER := ["first_sarcasm", "the_lie", "the_ribbon", "the_seat", "one_day", "afraid", "the_hum", "last_night"]

const MEMORIES := {
	"first_sarcasm": {"title": "Tenta de novo amanhã", "lines": [
		"Na primeira vez que ele foi grosso com ela, Mira riu.",
		"\"Isso era pra me assustar?\"",
		"\"Funcionou?\"",
		"\"Não. Tenta de novo amanhã.\"",
		"Ele tentou. Todo dia. Nunca funcionou.",
	], "noct": "@olhar_lateral: Hm."},
	"the_lie": {"title": "A sobrancelha", "lines": [
		"\"Estou bem.\"",
		"\"Você coça a sobrancelha quando mente.\"",
		"Ele parou de coçar.",
		"\"Agora você está mentindo com a mão parada. É pior.\"",
	], "noct": "@sarcastico: Ela era insuportável."},
	"the_ribbon": {"title": "A fita", "lines": [
		"Numa noite de chuva, ela amarrou a fita carmesim no pulso dele.",
		"\"Pra você lembrar de voltar.\"",
		"\"Lembrar de quê?\"",
		"\"De mim, idiota.\"",
	], "noct": "@fechando_olhos: ..."},
	"the_seat": {"title": "O lado esquerdo", "lines": [
		"No banco da estação, ela sempre sentava à esquerda. Ele, à direita.",
		"Nunca combinaram. Só ficou assim.",
		"Quando o trem atrasava, ela encostava a cabeça no ombro dele e dizia que era por causa do frio.",
		"Não estava frio.",
	], "noct": "@olhar_baixo: Não estava frio."},
	"one_day": {"title": "Um dia de cada vez", "lines": [
		"\"Como você aguenta?\"",
		"\"Não aguento tudo. Só hoje.\"",
		"\"E amanhã?\"",
		"\"Amanhã a gente vê. Um dia de cada vez.\"",
	], "noct": "@calmo: Um dia de cada vez."},
	"afraid": {"title": "Sobrancelha", "lines": [
		"\"Você tem medo de alguma coisa?\"",
		"\"Não.\"",
		"Ela olhou para a sobrancelha dele.",
		"\"...De perder você.\"",
		"Foi a única vez que ele disse em voz alta.",
	], "noct": "@fechando_olhos: Eu devia ter dito mais vezes."},
	"the_hum": {"title": "Alguém chamando", "lines": [
		"Nas últimas semanas, Mira ouvia um zumbido que ninguém mais ouvia.",
		"\"Parece alguém chamando do outro lado de uma porta.\"",
		"Ele disse que era cansaço.",
		"Ela sorriu, do jeito que sorria quando ele estava errado e ela não ia discutir.",
	], "noct": "@olhar_baixo: Eu disse que era cansaço."},
	"last_night": {"title": "Volto logo", "lines": [
		"Ela saiu antes de amanhecer. Deixou um bilhete na mesa.",
		"\"Volto logo. Não faz nada idiota.\"",
		"O bilhete ainda está no bolso dele, dobrado em quatro.",
		"Ele nunca foi idiota o suficiente para jogá-lo fora.",
	], "noct": "@triste: Você disse que voltava logo."},
}
