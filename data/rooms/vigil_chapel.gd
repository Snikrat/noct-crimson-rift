extends RefCounted
## Sala: Capela da Vigília (Águas Veladas, entre a Margem e o Penhasco; docs/expansao_forma_demoniaca.md, 1.3).
## Capela afundada na beira do lago: vitrais quebrados, santos sem rosto, centenas de velas apagadas
## e uma única vela acesa, sempre na mesma fileira. Era onde Mira acendia velas "para quem ninguém lembra".
## A legenda dos caracteres do mapa está em data/rooms.gd.
const T := preload("res://data/themes.gd")
const ROOM := {
	"title": "Capela da Vigília", "theme": "chapel",
	"left": "lake_shore", "left_entry": "R", "right": "rain_cliff", "right_entry": "L",
	"intro": ["@olhar_cima: Capela. No fundo de um lago.", "@sarcastico: Alguém rezou muito errado."],
	"markers": [
		{"feet": Vector2(200, 224), "title": "Santos sem rosto",
		 "lines": ["* Estátuas de santos. Os rostos foram raspados com cuidado.", "@desconfiado: Não foi raiva. Foi capricho."]},
		{"feet": Vector2(488, 224), "title": "Altar partido",
		 "lines": ["* O altar está partido ao meio. As velas em volta, todas apagadas.", "* Menos uma."]},
		{"feet": Vector2(520, 64), "title": "Vela acesa",
		 "lines": ["* Uma vela acesa, na mesma fileira de sempre. A cera ainda escorre.", "* Embaixo, riscado na pedra: \"para quem ninguém lembra\".", "@olhar_baixo: ...", "@neutro: Hm."]},
		{"feet": Vector2(856, 224), "title": "Confessionário", "requires": "boss:velario",
		 "locked_lines": ["* Uma inscrição na madeira, gasta demais para ler."],
		 "lines": ["* Agora dá para ler: \"ela não estava com medo\".", "@fechando_olhos: Eu sei."]},
	],
	"map": [
		"############################################################",
		"#..........................................................#",
		"#..........................................................#",
		"#..........................................................#",
		"#.........................########.........................#",
		"#..........................................................#",
		"#................F............m............................#",
		"#.............######....................######.............#",
		"#..........................................................#",
		"#...................................................F......#",
		"......#####.......................................#####.....",
		"............................................................",
		"............................................................",
		"..L...............l.........##.##...........l............R..",
		"############################################################",
		"############################################################",
		"############################################################",
		"############################################################",
	],
}
