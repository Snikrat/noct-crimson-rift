extends RefCounted
## Sala: Poço de Pedravelha (opcional). Descida curta a partir do poço da vila, com água escura no fundo.
## O nicho atrás da parede carmesim (Passo da Fenda, depois do Bringer) guarda o amuleto Um Dia de Cada Vez.
## "w" no mapa = água parada (só visual).
const T := preload("res://data/themes.gd")
const ROOM := {
	"title": "Poço de Pedravelha", "theme": "well",
	"left": "", "right": "",
	"charm": "one_day",
	"intro": ["@olhar_lateral: Água parada. Ninguém tira água daqui faz tempo.", "@desconfiado: ...Mas alguém desceu."],
	"entries": {"TOWN": Vector2(184, 64)},
	"markers": [
		{"feet": Vector2(168, 64), "title": "Subir para a vila", "target": "town", "entry": "WELL", "style": "rope"},
		{"feet": Vector2(280, 320), "title": "Inscrição na pedra", "discovery": "well_note",
		 "lines": ["Riscado na pedra molhada: 'Ela desceu aqui antes de nós. Disse que o barulho vinha de baixo.'", "@desconfiado: Barulho.", "@olhar_baixo: ...Ela também ouvia daqui."]},
	],
	"map": [
		"##############################",
		"#########............#########",
		"#########............#########",
		"#########............#########",
		"##############.......#########",
		"#########............#########",
		"#########......F.....#########",
		"#########............#########",
		"#########.......##############",
		"#########............#########",
		"#########............#########",
		"#########...^^^^^^...#########",
		"#########..###################",
		"#########............#########",
		"#########............#########",
		"#########.....F......#########",
		"#########............#########",
		"#####...Xwwwwwwwwwwww#########",
		"#####...Xwwwwwwwwwwww#########",
		"#####.C.Xwwwwwwwwwwww#########",
		"##############################",
		"##############################",
	],
}
