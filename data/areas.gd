extends RefCounted
## Áreas do mundo: cada área junta alguns cenários (salas) com a cara do seu chefe e termina na sala dele.
## "rooms" são os cenários da área; a sala do chefe é sempre a última da lista.
## "extras" são salas laterais que pertencem à área mas não contam como cenário (ex.: a Estação, só da história).
## "defeated" diz quando o chefe da área está vencido: "boss:<id>" (chefe) ou o id de uma descoberta
## (minichefes humanos, que viram descoberta ao cair).
## Pedravelha é o refúgio: não tem chefe.
## A sala "mind" (Mente do Noct) não pertence a nenhuma área: é a arena de uma luta, não um lugar do mapa.

const AREAS := [
	{"id": "pedravelha", "name": "Pedravelha", "color": Color(0.85, 0.7, 0.4),
	 "rooms": ["town", "tower", "well"], "boss_room": "", "boss": "", "defeated": ""},
	{"id": "desgarrados", "name": "Trilha dos Desgarrados", "color": Color(0.45, 0.75, 0.4),
	 "rooms": ["forest", "mountain"], "extras": ["station"],
	 "boss_room": "mountain", "boss": "Capitão dos Saqueadores", "defeated": "bandit_captain"},
	{"id": "esquecidas", "name": "Terras Esquecidas", "color": Color(0.55, 0.6, 0.85),
	 "rooms": ["swamp", "cemetery", "lair"],
	 "boss_room": "lair", "boss": "Gato Infernal", "defeated": "boss:gato"},
	{"id": "catedral", "name": "Domínio do Ceifador", "color": Color(0.8, 0.75, 0.9),
	 "rooms": ["cathedral", "arcane_ruins", "archive", "sanctum"],
	 "boss_room": "sanctum", "boss": "Bringer of Death", "defeated": "boss:bringer"},
	{"id": "lago", "name": "Águas Veladas", "color": Color(0.4, 0.8, 0.85),
	 "rooms": ["lake_shore", "lake"],
	 "boss_room": "lake", "boss": "Velário, o Carcereiro", "defeated": "boss:velario"},
	{"id": "fenda", "name": "A Fenda", "color": Color(0.95, 0.3, 0.35),
	 "rooms": ["mines", "rift_heart", "inferno", "demon_lair"],
	 "boss_room": "demon_lair", "boss": "Demon Slime", "defeated": "boss:demon_slime"},
]


## Área de uma sala ({} se a sala não pertence a nenhuma, como a Mente do Noct).
static func area_of(room: String) -> Dictionary:
	for a in AREAS:
		if room in a["rooms"] or room in a.get("extras", []):
			return a
	return {}


static func area_name(room: String) -> String:
	return area_of(room).get("name", "")
