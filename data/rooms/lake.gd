extends RefCounted
## Sala: Lago Velado, arena do Velário (docs/expansao_forma_demoniaca.md, seção 3).
## Fase 1 com chão firme e névoa; na fase 2 a música troca e as lanternas acendem (game/bosses/velario/).
## Depois da luta, a lembrança "Continua andando" libera a Forma Demoníaca Nível 1 (main.gd).
## A legenda dos caracteres do mapa está em data/rooms.gd ("Y" = Velário).
const T := preload("res://data/themes.gd")
const ROOM := {
	"title": "Lago Velado", "theme": "lake",
	"left": "rain_cliff", "left_entry": "R", "right": "",
	"gate": [[0, 10], [0, 11], [0, 12], [0, 13]],
	"entries": {"RIFT": Vector2(584, 224)},
	"markers": [
		{"feet": Vector2(616, 224), "title": "Fenda do fundo do lago", "target": "rift_heart", "entry": "LAKE", "portal": true,
		 "requires": "boss:velario", "locked_lines": ["* A água no fundo pulsa em vermelho, presa por alguma coisa."]},
		{"feet": Vector2(568, 224), "title": "Lanterna apagada", "requires": "boss:velario",
		 "locked_lines": ["* Uma lanterna boia parada, presa no fundo por uma corrente."],
		 "lines": ["* A lanterna está aberta e vazia.", "@olhar_baixo: ...", "@fechando_olhos: Continua andando. Tá."]},
	],
	"map": [
		"########################################",
		"#......................................#",
		"#......................................#",
		"#......................................#",
		"#......................................#",
		"#......................................#",
		"#......................................#",
		"#..............##########..............#",
		"#......................................#",
		"#......................................#",
		".....#####....................#####....#",
		".......................................#",
		".......................................#",
		"..L.....wwwww.............Y....wwwwwwww#",
		"########################################",
		"########################################",
		"########################################",
		"########################################",
	],
}
