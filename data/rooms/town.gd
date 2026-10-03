extends RefCounted
## Sala: Vila de Pedravelha
## A legenda dos caracteres do mapa está em data/rooms.gd.

const T := preload("res://data/themes.gd")

const ROOM := {
	"title": "Vila de Pedravelha",
	"theme": "town",
	"intro": ["@olhar_lateral: Pedravelha... quieta demais pra uma cidade tão perto da fenda."],   # comentário de Noct na 1ª visita
	"left": "",
	"right": "swamp",
	"entries": {"MOUNTAIN": Vector2(376, 256), "FOREST": Vector2(840, 256)},
	"markers": [
		{"feet": Vector2(376, 256), "title": "Trilha da serra", "target": "mountain", "entry": "L", "portal": true},
		{"feet": Vector2(712, 176), "title": "Atalho do vigia", "target": "cemetery", "entry": "MOUNTAIN", "portal": true, "requires": "mountain_pass"},
		{"feet": Vector2(840, 256), "title": "Trilha do bosque", "target": "forest", "entry": "L", "portal": true},
	],
	# Cenário: [arquivo em props-sliced, centro x em px, linha do chão]
	"props": [
		["house-a", 104, 16], ["street-lamp", 230, 16], ["house-c", 330, 16],
		["well", 470, 16], ["street-lamp", 560, 16], ["house-b", 660, 16],
		["crate-stack", 780, 16], ["wagon", 860, 16], ["sign", 930, 16],
	],
	"npcs": {
		"1": {"kind": "oldman", "name": "Velho Zeno", "lines": [
			"Mais um viajante... O pântano a leste engoliu muitos antes de você.",
			"@sarcastico: Um pântano com apetite. Ótimo.",
			"Hm. Se estiver ferido, descanse no banco. Ele guarda sua alma quando você cai.",
			"@olhar_lateral: ...Valeu.",
		]},
		"2": {"kind": "woman", "name": "Irmã Lívia", "lines": [
			"Cada golpe seu arranca um pouco de ALMA das criaturas.",
			"@olhar_baixo: Eu sei o que ela faz. Não pedi por ela.",
			"Segure L para concentrar essa alma e curar suas feridas.",
			"Ou solte-a de uma vez: L lança um raio, e W + L chama o trovão.",
			"@sarcastico: Curar e explodir coisas. Versátil.",
		]},
		"3": {"kind": "bearded", "name": "Ferreiro Brom", "shop": true, "patrol": 12.0, "lines": []},
		"4": {"kind": "hat-man", "name": "Forasteiro", "patrol": 8.0, "lines": [
			"Como subiu até aqui? Hm. Você tem jeito para isso.",
			"A fenda perto das casas leva à serra. O vigia deixou um atalho do outro lado; abra-o e volte por aqui.",
			"@sarcastico: Prática.",
			"Use o golpe para baixo (S + J no ar) para quicar sobre os espinhos.",
			"Além do cemitério vive o Gato Infernal. Junte Geo e fale com o Brom antes de ir.",
			"@confiante: Perigoso? ...Finalmente alguma coisa interessante.",
		]},
	},
	"map": [
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#...........................................................",
		"#.............................................4.............",
		"#...........................................#####...........",
		"#.....................####..................................",
		"#...........................................................",
		"#...........................................................",
		"#.......B........1...........2..........3................R..",
		"############################################################",
		"############################################################",
		"############################################################",
		"############################################################",
	],
}
