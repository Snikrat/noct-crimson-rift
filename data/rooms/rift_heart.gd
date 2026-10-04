extends RefCounted
## Sala: Coração da Fenda (docs/expansao_forma_demoniaca.md, 1.6). Onde a energia do Crimson Rift é mais forte.
## Entra pela fenda no fundo do Lago Velado, depois do Velário. Rachaduras ("j") explodem em sequência;
## o Faminto da Fenda ("f") dorme até o Noct usar a Forma Demoníaca. A parede de cristal ("k") só quebra
## com o dash da forma e guarda o atalho para o Inferno.
## A legenda dos caracteres do mapa está em data/rooms.gd.
const T := preload("res://data/themes.gd")
const ROOM := {
	"title": "Coração da Fenda", "theme": "rift_heart",
	"left": "", "right": "",
	"intro": ["@olhar_lateral: Bate. Como um coração.", "@desconfiado: ...No mesmo ritmo que o meu."],
	"entries": {"LAKE": Vector2(56, 224), "INFERNO": Vector2(744, 224)},
	"markers": [
		{"feet": Vector2(40, 224), "title": "Fenda do lago", "target": "lake", "entry": "RIFT", "portal": true},
		{"feet": Vector2(312, 224), "title": "Inscrição na pedra",
		 "lines": ["* Letras riscadas fundo na pedra. Uma letra que ele conhece.", "* \"A porta chama de noite. Se eu responder com raiva, ela abre pra todo mundo.\"", "@olhar_baixo: ...", "@fechando_olhos: Você esteve aqui."]},
		{"feet": Vector2(616, 112), "title": "Cristal rachado",
		 "lines": ["* Dentro do cristal, uma fita parada no ar.", "@sombrio: Hm."]},
		{"feet": Vector2(776, 224), "title": "Atalho para o Inferno", "target": "inferno", "entry": "L", "portal": true},
	],
	"map": [
		"##################################################",
		"#........................................##......#",
		"#........................................##......#",
		"#........................................##......#",
		"#.............................Z..........##......#",
		"#........................................##......#",
		"#.................#######................##......#",
		"#....................s................#######....#",
		"#........................................kk......#",
		"#.......######...........................kk......#",
		"#............................#####.......kk......#",
		"#........................................kk......#",
		"#........................................kk......#",
		"#.L...........jjj.....f....jj......j.....kk...f..#",
		"##################################################",
		"##################################################",
		"##################################################",
		"##################################################",
	],
}
