extends RefCounted
## Sala: Margem das Folhas Paradas (descida até o Lago Velado; docs/expansao_forma_demoniaca.md, 1.5).
## Só se chega pela fenda sob o altar do Santuário do Ceifador, depois do Bringer.
## Véus com nomes bordados de coisas esquecidas e um reflexo atrasado. Segue para a Capela da Vigília.
## A legenda dos caracteres do mapa está em data/rooms.gd.
const T := preload("res://data/themes.gd")
const ROOM := {
	"title": "Margem das Folhas Paradas", "theme": "lake",
	"left": "", "right": "vigil_chapel", "right_entry": "L",
	"intro": ["@olhar_lateral: Água parada. De novo.", "@desconfiado: ...O meu reflexo está atrasado."],
	"entries": {"SANCTUM": Vector2(72, 224)},
	"tessa": {"stage": "lake", "feet": Vector2(456, 224)},   # Tessa (game/world/tessa.gd), depois do Bringer
	"markers": [
		{"feet": Vector2(40, 224), "title": "Voltar ao Santuário", "target": "sanctum", "entry": "LAKE", "portal": true},
		{"feet": Vector2(264, 224), "title": "Véus bordados",
		 "lines": ["* Véus presos nos galhos secos. Cada um tem um nome bordado.", "* \"O cheiro do café.\" \"A música da festa.\" \"O nome da rua.\"", "@olhar_baixo: Coisas que alguém esqueceu."]},
		{"feet": Vector2(360, 96), "title": "Véu sem nome",
		 "lines": ["* Um véu sem nada bordado. Ainda úmido.", "* Noct não toca."]},
		{"feet": Vector2(600, 224), "title": "Reflexo na água",
		 "lines": ["* No reflexo, o Noct chega meio segundo atrasado.", "* Por um instante, tem alguém sentado ao lado dele na margem.", "@fechando_olhos: Não."]},
	],
	"map": [
		"################################################",
		"#..............................................#",
		"#..............................................#",
		"#..............................................#",
		"#.................................l............#",
		"#............l.................................#",
		"#...................#######....................#",
		"#.......................s......................#",
		"#..............................................#",
		"#.........######...............#####...........#",
		"#.................................s.............",
		"#...............................................",
		"#...............................................",
		"#..L....B.................m.........wwwwwwwwwR..",
		"################################################",
		"################################################",
		"################################################",
		"################################################",
	],
}
