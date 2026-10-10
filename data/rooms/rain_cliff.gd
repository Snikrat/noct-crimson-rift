extends RefCounted
## Sala: Penhasco da Chuva Eterna (Águas Veladas, última sala antes do Lago Velado; docs/expansao_forma_demoniaca.md, 1.4).
## Onde os trilhos da Estação acabam: ruínas de uma parada de montanha na beira do abismo, chuva que não para
## e trilhos retorcidos pendurados no vazio. Lá embaixo dá para ver o lago. Banco logo antes da arena do Velário.
## A legenda dos caracteres do mapa está em data/rooms.gd.
const T := preload("res://data/themes.gd")
const ROOM := {
	"title": "Penhasco da Chuva Eterna", "theme": "cliff",
	"left": "vigil_chapel", "left_entry": "R", "right": "lake", "right_entry": "L",
	"intro": ["@olhar_lateral: Os trilhos vêm dar aqui.", "@sombrio: E o resto do caminho caiu."],
	"markers": [
		{"feet": Vector2(264, 192), "title": "Trilhos pendurados",
		 "lines": ["* Os trilhos acabam no ar, torcidos para baixo.", "* Um cabo de bonde balança na chuva, sem bonde nenhum.", "@sarcastico: Linha desativada. Avisaram tarde."]},
		{"feet": Vector2(696, 144), "title": "Cabine do maquinista", "discovery": "cliff_cabin", "reward": 45,
		 "lines": ["* Na parede da cabine, o último horário, escrito à mão.", "* \"Primeiro trem da manhã. Um passageiro.\"", "@olhar_baixo: Um."]},
		{"feet": Vector2(960, 96), "title": "Beira do penhasco",
		 "lines": ["* Lá embaixo, o lago. Parado, mesmo com a chuva caindo nele.", "@desconfiado: A chuva não mexe na água."]},
	],
	"map": [
		"........................................................................",
		"........................................................................",
		"........................................................................",
		"........................................................................",
		"........................................................................",
		"..................................................F.....................",
		"..........................................................#####.........",
		"........................................................................",
		"..........................F.............................................",
		"........................................#######.........................",
		"......................####..............................................",
		"...............................###......................................",
		"...............####..............................#####..................",
		"..................................##....................................",
		"........................................................................",
		"..L......m................................l...............m....B.....R..",
		"##############......##########.......###########......##################",
		"##############......##########.......###########......##################",
		"##############^^^^^^##########^^^^^^^###########^^^^^^##################",
		"########################################################################",
	],
}
