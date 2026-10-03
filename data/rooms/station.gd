extends RefCounted
## Sala: Estação (opcional, fase 5-6 do arco). A estação da memória "O lado esquerdo".
## Sem inimigos e sem música de luta: chuva, um banco e um trem que nunca chega.
## A passagem na Serra só abre depois da memória "Volto logo" (as últimas pegadas de Mira levam até aqui).
## No banco daqui Noct senta à direita; a cena muda em main.gd (rest_at_bench).
const T := preload("res://data/themes.gd")
const ROOM := {
	"title": "Estação", "theme": "station",
	"left": "", "right": "",
	"intro": ["@neutro: Estação.", "@olhar_baixo: ...O trem ainda atrasa."],
	"entries": {"MOUNTAIN": Vector2(40, 224)},
	"props": [
		["street-lamp", 120, 14], ["sign", 296, 14], ["street-lamp", 472, 14],
		["crate-stack", 600, 14], ["barrel", 640, 14],
	],
	"markers": [
		{"feet": Vector2(40, 224), "title": "Trilha da serra", "target": "mountain", "entry": "STATION", "portal": true},
		{"feet": Vector2(296, 224), "title": "Quadro de horários", "discovery": "station_board",
		 "lines": ["* Os horários foram riscados. Todos, menos o último trem da noite.", "@sarcastico: Pontual como sempre."]},
		{"feet": Vector2(664, 224), "title": "Fim da plataforma", "discovery": "station_tracks",
		 "lines": ["* Na lama, pegadas pequenas vão até a beira dos trilhos.", "* Nenhuma volta.", "@olhar_baixo: ...", "@fechando_olhos: Você disse que voltava logo."]},
	],
	"map": [
		".............................................",
		".............................................",
		".............................................",
		".............................................",
		".............................................",
		"......###########################............",
		".............................................",
		".............................................",
		".............................................",
		".............................................",
		".............................................",
		".............................................",
		".............................................",
		"..L.........B................................",
		"#############################################",
		"#############################################",
		"#############################################",
	],
}
