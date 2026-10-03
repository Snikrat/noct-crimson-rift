extends RefCounted
## Caminho opcional: os degraus superiores levam a uma memória; a base reconecta ao cemitério.
const P := preload("res://data/asset_paths.gd")
const ENV := P.CEMETERY_ENV + "sliced-objects/"
const ROOM := {
	"title": "Serra do Último Eco", "theme": "mountain",
	"memories": [{"id": "one_day", "feet": Vector2(1128, 256)}],   # fragmentos de memória de Mira
	"left": "town", "left_entry": "MOUNTAIN",
	"right": "cemetery", "right_entry": "MOUNTAIN", "exit_discovery": "mountain_pass",
	"intro": ["@olhar_cima: Ainda dá pra ver a vila daqui.", "@sarcastico: Lugar bonito. Melhor ir embora antes que vire importante."],
	"entries": {"FOREST": Vector2(216, 320), "STATION": Vector2(1000, 320)},
	"actors": [
		{"feet": Vector2(392, 320), "kind": "light"},
		{"feet": Vector2(840, 320), "kind": "captain", "discovery": "bandit_captain"},
	],
	"props": [[ENV + "tree-1.png", 192, 20], [ENV + "statue.png", 648, 8], [ENV + "stone-2.png", 1120, 20]],
	"markers": [
		{"feet": Vector2(216, 320), "title": "Descida do bosque", "style": "trail", "facing": -1, "target": "forest", "entry": "SERRA"},
		{"feet": Vector2(1000, 320), "title": "Trilhos velhos", "style": "trail", "target": "station", "entry": "MOUNTAIN", "requires": "memory:last_night",
		 "locked_lines": ["* Trilhos velhos, cobertos de mato. Somem na neblina.", "@olhar_lateral: Não levam a lugar nenhum que importe."]},
		{"feet": Vector2(648, 128), "title": "Pedra dos viajantes", "discovery": "mountain_memory", "reward": 40,
		 "lines": ["Entre nomes gastos, alguém gravou: 'Se eu me perder, procure onde o céu ainda alcança a vila.'", "Os dedos de Noct encontram a fita carmesim no pulso.", "@triste: Você sempre escolhia os lugares altos.", "@fechando_olhos: ...Ainda estou procurando."]},
	],
	"map": [
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		".....................................########...................................",
		"................................................................................",
		"..............................#####............#####............................",
		"................................................................................",
		".......................#####...........................#####....................",
		"................................................................................",
		"................#####.........................................#####.............",
		"................................................................................",
		".........#####......................................................#####.......",
		"................................................................................",
		"................................................................................",
		"..L...................................B......................................R..",
		"##################...########################...################################",
		"##################...########################...################################",
		"##################^^^########################^^^################################",
		"################################################################################",
	],
}
