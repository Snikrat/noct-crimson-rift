extends RefCounted
## Sala: Mente do Noct
## Não fica no mapa do mundo: na metade da vida, o Bringer of Death arrasta a luta para dentro da
## cabeça de Noct (enter_mind em game/world/main.gd). Ao vencer, Noct volta para o Santuário.
## A legenda dos caracteres do mapa está em data/rooms.gd.

const ROOM := {
	"title": "Mente do Noct",
	"theme": "mind",
	"hidden": true,   # não entra no mapa da pausa nem conta como sala visitada
	"entries": {"BOSS": Vector2(28 * 16 + 8, 14 * 16)},   # onde o Bringer reaparece
	"map": [
		"####################################",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..............######..............#",
		"#..................................#",
		"#..................................#",
		"#...#####..................#####...#",
		"#..................................#",
		"#..................................#",
		"#..L...............................#",
		"####################################",
		"####################################",
		"####################################",
		"####################################",
	],
}
