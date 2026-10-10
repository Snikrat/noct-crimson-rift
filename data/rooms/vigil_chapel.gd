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
	# Arte própria (tools/make_aguas_veladas.lua): feixes dos vitrais, santos sem rosto, o altar partido em cima
	# dos blocos ##.##, fileiras de velas apagadas e a única vela acesa na plataforma de cima.
	"props": [
		[T.CHAPEL_ART + "vitral_luz_a.png", 140, 14],
		[T.CHAPEL_ART + "vitral_luz_b.png", 360, 14],
		[T.CHAPEL_ART + "vitral_luz_a.png", 640, 14],
		[T.CHAPEL_ART + "santo_sem_rosto_a.png", 184, 14],
		[T.CHAPEL_ART + "santo_sem_rosto_b.png", 220, 14],
		[T.CHAPEL_ART + "velas_apagadas_b.png", 260, 14],
		[T.CHAPEL_ART + "velas_apagadas.png", 420, 14],
		[T.CHAPEL_ART + "altar_partido.png", 488, 13],
		[T.CHAPEL_ART + "velas_apagadas.png", 560, 14],
		[T.CHAPEL_ART + "confessionario.png", 856, 14],
		[T.CHAPEL_ART + "velas_apagadas_b.png", 136, 10],
		[T.CHAPEL_ART + "velas_apagadas.png", 856, 10],
		[T.CHAPEL_ART + "velas_apagadas_b.png", 272, 7],
		[T.CHAPEL_ART + "velas_apagadas.png", 704, 7],
		[T.CHAPEL_ART + "velas_apagadas.png", 452, 4],
		[T.CHAPEL_ART + "velas_apagadas_b.png", 498, 4],
		[T.CHAPEL_ART + "vela_acesa.png", 520, 4],
	],
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
