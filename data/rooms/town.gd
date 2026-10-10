extends RefCounted
## Sala: Vila de Pedravelha
## A legenda dos caracteres do mapa está em data/rooms.gd.

const T := preload("res://data/themes.gd")
const ART := "res://assets/areas/pedravelha/"

const ROOM := {
	"title": "Vila de Pedravelha",
	"memories": [{"id": "first_sarcasm", "feet": Vector2(536, 256)}, {"id": "afraid", "feet": Vector2(40, 256)}],
	"tessa": {"stage": "town", "feet": Vector2(520, 256)},
	# Efeitos de abrigo ficam atrás dos atores. Carmesim acompanha apenas a Fenda e Mira.
	"ambient_effects": [
		["lantern", Vector2(416, 192), Vector2(5, 7), 0.9],
		["lantern", Vector2(608, 192), Vector2(5, 7), 0.9],
		["smoke", Vector2(1112, 126), Vector2(8, 36), 0.45],
		["sparks", Vector2(1104, 223), Vector2(5, 8), 0.6, 4.0],
		["dust", Vector2(933, 238), Vector2(24, 54), 0.45],
		["fireflies", Vector2(550, 224), Vector2(11, 9), 0.65],
		["mist", Vector2(88, 253), Vector2(38, 14), 0.18],
		["mist", Vector2(1344, 253), Vector2(38, 14), 0.18],
		["leaves", Vector2(442, 174), Vector2(25, 19), 0.45],
		["well-drip", Vector2(644, 238), Vector2(12, 30), 0.55],
		["rift-wall", Vector2(80, 208), Vector2.ZERO, 0.65, 0.0, true],
	],
	"theme": "town",
	"trim_props": true,
	"street_band": ART + "tileset.png",   # calçada atrás dos objetos, com sombra de contato (street_band.gd)
	# Quanto cada objeto afunda no calçamento (px): a base cobre a primeira fileira de pedras.
	# Árvore, poço, hospedaria e cabana têm pontas finas (raízes, placa, roda) abaixo da base.
	"prop_sink": {"default": 2, "tree.png": 5, "well.png": 3, "inn.png": 4, "wagon.png": 5, "monument.png": 3},
	"intro": ["@olhar_lateral: Pedravelha. Duas saídas, uma torre e gente demais olhando pela janela.", "@neutro: Quieta demais pra tão perto da fenda."],   # comentário de Noct na 1ª visita
	"left": "",
	"right": "swamp",
	"entries": {"MOUNTAIN": Vector2(568, 256), "FOREST": Vector2(1336, 256), "MINES": Vector2(56, 256), "TOWER": Vector2(232, 256), "WELL": Vector2(644, 256)},
	"markers": [
		{"feet": Vector2(568, 256), "title": "Trilha da serra", "target": "mountain", "entry": "L", "style": "scenery"},
		{"feet": Vector2(1192, 176), "title": "Atalho do vigia", "target": "cemetery", "entry": "MOUNTAIN", "portal": true, "requires": "mountain_pass"},
		{"feet": Vector2(1336, 256), "title": "Trilha do bosque", "target": "forest", "entry": "L", "style": "trail"},
		{"feet": Vector2(56, 256), "title": "Minas da Fenda", "target": "mines", "entry": "L", "style": "mine"},   # atrás da parede carmesim
		{"feet": Vector2(232, 256), "title": "Porta da torre", "target": "tower", "entry": "TOWN", "style": "scenery"},   # a porta está pintada no arco da torre
		{"feet": Vector2(644, 256), "title": "Poço", "target": "well", "entry": "TOWN", "style": "well"},
	],
	# Cenário: [arquivo em props-sliced, centro x em px, linha do chão]
	"props": [
		[ART + "sealed-house.png", 128, 16],
		[ART + "tower.png", 232, 16],
		[ART + "house.png", 344, 16],
		[ART + "tree.png", 440, 16],
		[ART + "monument.png", 568, 16],
		[ART + "well.png", 644, 16],
		[ART + "chapel.png", 928, 16],
		[ART + "forge.png", 1104, 16],
		[ART + "inn.png", 1272, 16],
		[ART + "wagon.png", 744, 16],
		["street-lamp", 416, 16], ["street-lamp", 608, 16],
		["crate-stack", 1024, 16, Rect2(0, 0, 73, 68), 0.5],
	],
	"npcs": {
		"1": {"kind": "oldman", "name": "Velho Zeno", "lines": [
			"Mais um viajante... O pântano a leste engoliu muitos antes de você.",
			"@sarcastico: Um pântano com apetite. Ótimo.",
			"Hm. Se estiver ferido, descanse no banco. Ele guarda sua alma quando você cai.",
			"@olhar_lateral: Hm.",
		], "more": [
			["Você parece cansado.", "@sarcastico: Excelente trabalho investigativo.", "Durma um pouco no banco. Velhos sabem dessas coisas.", "@olhar_lateral: Velhos sabem de muita coisa."],
			["Tem medo do que tem lá fora, rapaz?", "@neutro: Constantemente.", "Você está brincando.", "@sarcastico: Talvez."],
		]},
		"2": {"kind": "woman", "name": "Irmã Lívia", "lines": [
			"Cada golpe seu arranca um pouco de ALMA das criaturas.",
			"@olhar_baixo: Eu sei o que ela faz. Não pedi por ela.",
			"Ninguém pede. Mas ela responde a você.",
			"@serio: Então que responda menos.",
			"Segure L para concentrar essa alma e curar suas feridas.",
			"Ou solte-a de uma vez: L lança um raio, e W + L chama o trovão.",
			"@sarcastico: Curar e explodir coisas. Versátil.",
		], "more": [
			["Essa fita no seu pulso. De onde veio?", "@olhar_baixo: De algum lugar.", "Isso não respondeu.", "@sarcastico: Perceptivo.", "...", "@fechando_olhos: É só uma fita."],
			["Você nunca fala sobre você.", "@serio: Estou falando agora.", "Você sabe o que eu quis dizer.", "@olhar_lateral: Infelizmente."],
		]},
		"3": {"kind": "bearded", "name": "Ferreiro Brom", "shop": true, "patrol": 12.0, "lines": []},
		"4": {"kind": "hat-man", "name": "Forasteiro", "patrol": 8.0, "lines": [
			"Veio pela estrada? Hm. Você tem jeito para isso.",
			"A trilha ao lado da praça sobe para a serra. O vigia deixou um atalho do outro lado; abra-o e volte por aqui.",
			"@sarcastico: Prática.",
			"Use o golpe para baixo (S + J no ar) para quicar sobre os espinhos.",
			"Além do cemitério vive o Gato Infernal. Junte Geo e fale com o Brom antes de ir.",
			"@confiante: Perigoso? ...Finalmente alguma coisa interessante.",
		], "more": [
			["Você sempre é tão insuportável?", "@confiante: Você continua aqui."],
			["Dizem que você entra nas ruínas por dinheiro.", "@neutro: Dinheiro paga comida.", "E o resto?", "@sombrio: O resto ocupa a cabeça."],
		]},
	},
	"map": [
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................................",
		"#.......................................................................####............",
		"######..................................................................................",
		"#....X..........................................................####....................",
		"#....X..................................................................................",
		"#....X...............1........B...........................2.........3..........4.....R..",
		"########################################################################################",
		"########################################################################################",
		"########################################################################################",
		"########################################################################################",
	],
}
