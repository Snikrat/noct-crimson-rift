extends RefCounted
## Sala: Santuário do Ceifador
## A legenda dos caracteres do mapa está em data/rooms.gd.

const T := preload("res://data/themes.gd")

const ROOM := {
	"title": "Santuário do Ceifador",
	"theme": "cathedral",
	"left": "cathedral",
	"right": "inferno",
	"entries": {"MIND": Vector2(26 * 16 + 8, 14 * 16), "LAKE": Vector2(320, 14 * 16)},   # volta da Mente do Noct (onde o Bringer estava) e do Lago Velado
	# Fenda sob o altar: desce ao Lago Velado (Velário) depois do Bringer.
	"markers": [{"feet": Vector2(288, 224), "title": "Fenda sob o altar", "target": "lake_shore", "entry": "SANCTUM", "portal": true,
		"requires": "boss:bringer", "locked_lines": ["* Embaixo do altar, a pedra está quente.", "@desconfiado: Tem alguma coisa respirando aí embaixo."]}],
	"gate": [[0, 10], [0, 11], [0, 12], [0, 13], [35, 10], [35, 11], [35, 12], [35, 13]],
	"props": [
		[T.CHURCH_ENV + "backgrounds.png", 90, 14, T.CHURCH_TORCH],
		[T.CHURCH_ENV + "backgrounds.png", 288, 14, T.CHURCH_ALTAR],
		[T.CHURCH_ENV + "backgrounds.png", 490, 14, T.CHURCH_TORCH],
	],
	"map": [
		"####################################",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"#..................................#",
		"....#####..................#####....",
		"....................................",
		"....................................",
		"..L.......................D.....R...",
		"####################################",
		"####################################",
		"####################################",
		"####################################",
	],
}
