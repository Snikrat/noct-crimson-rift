extends RefCounted
## Temas visuais das áreas (tileset, cores, fundo em camadas, música) e recortes de cenário.

const Paths := preload("res://data/asset_paths.gd")
const SWAMP_ENV := Paths.SWAMP_ENV
const TOWN_ENV := Paths.TOWN_ENV
const CHURCH_ENV := Paths.CHURCH_ENV
const CEMETERY_ENV := Paths.CEMETERY_ENV
const LAVA_ENV := Paths.LAVA_ENV
const MUSIC_TOWN := Paths.MUSIC_TOWN
const MOUNTAIN := Paths.VENDOR + "mountainduskgodot/MountainDuskGodot/MountainsLayers/"
# "step": som dos passos (grass, rock, wood, water; padrão rock). "music" toca ao explorar; "combat" (opcional) entra quando um inimigo chega perto e sai depois da luta.

# Como desenhar cada área. blocks = colunas (px) de blocos de chão no tileset,
# block_w = largura do bloco em tiles, top = linha (px) do topo da superfície,
# rows = quantas linhas de tile vêm do tileset antes de virar cor sólida.
const THEMES := {
	"forest": {
		"tileset": CEMETERY_ENV + "tileset.png", "tint": Color(0.7, 0.82, 0.85),
		"blocks": [64], "block_w": 4, "top": 58, "rows": 2,
		"rock": Color("101822"), "side": Color("263540"), "clear": Color("202f37"),
		"step": "grass", "music": Paths.MUSIC_LIVING_SCORN, "combat": Paths.MUSIC_PIXEL_DAMNATION,
		"foreground": Paths.FOREST + "frontleaves.png",
		"layers": [
			{"tex": [Paths.FOREST + "background4.png"], "scroll": 0.02, "align": "bottom", "cover": true},
			{"tex": [Paths.FOREST + "background3.png"], "scroll": 0.08, "align": "bottom"},
			{"tex": [Paths.FOREST + "background2.png"], "scroll": 0.18, "align": "bottom"},
			{"tex": [Paths.FOREST + "background1.png"], "scroll": 0.3, "align": "bottom"},
		],
	},
	"mountain": {
		"tileset": CEMETERY_ENV + "tileset.png",
		"blocks": [64], "block_w": 4, "top": 58, "rows": 2,
		"rock": Color("21152e"), "side": Color("493250"), "clear": Color("533d65"),
		"step": "rock", "music": Paths.MUSIC_AMBIENT_4, "combat": Paths.MUSIC_LIVING_SCORN,
		"layers": [
			{"tex": [MOUNTAIN + "sky.png"], "scroll": 0.02, "align": "bottom", "cover": true},
			{"tex": [MOUNTAIN + "far-clouds.png"], "scroll": 0.06, "align": "bottom"},
			{"tex": [MOUNTAIN + "far-mountains.png"], "scroll": 0.12, "align": "bottom"},
			{"tex": [MOUNTAIN + "mountains.png"], "scroll": 0.25, "align": "bottom"},
			{"tex": [MOUNTAIN + "near-clouds.png"], "scroll": 0.35, "align": "bottom"},
			{"tex": [MOUNTAIN + "trees.png"], "scroll": 0.5, "align": "bottom"},
		],
	},
	# Pedra da igreja tingida de vermelho ("tint"), lava animada nos poços (caractere ~).
	"inferno": {
		"tileset": CHURCH_ENV + "tileset.png", "tint": Color(1.0, 0.58, 0.5),
		"blocks": [0, 64, 128], "block_w": 3, "top": 166, "rows": 2,
		"rock": Color("2a0f14"), "side": Color("7a2d22"), "clear": Color("341a37"),
		"lava_tile": LAVA_ENV + "lava-tile.png",
		"music": Paths.MUSIC_REALM_OF_TORMENT, "combat": Paths.MUSIC_HEAVY_BATTLE_2,
		"layers": [
			{"tex": [LAVA_ENV + "background.png"], "scroll": 0.08, "align": "bottom"},
			{"tex": [LAVA_ENV + "middle-rocks.png"], "scroll": 0.3, "align": "bottom", "gap": 260},
		],
	},
	"cathedral": {
		"tileset": CHURCH_ENV + "tileset.png",
		"blocks": [0, 64, 128], "block_w": 3, "top": 166, "rows": 2,
		"rock": Color("1b0f2b"), "side": Color("4a3a5e"), "clear": Color("272638"),
		"music": Paths.MUSIC_AMBIENT_4, "combat": Paths.MUSIC_UNHOLY_SURGE,
		"layers": [],
	},
	"town": {
		"tileset": TOWN_ENV + "layers/tileset.png",
		"blocks": [320], "block_w": 2, "top": 136, "rows": 2,
		"rock": Color("1a1320"), "side": Color("3b2a3a"), "clear": Color("854a62"),
		"music": MUSIC_TOWN,
		"layers": [
			{"tex": [TOWN_ENV + "layers/background.png"], "scroll": 0.05, "align": "center"},
			{"tex": [TOWN_ENV + "layers/middleground.png"], "scroll": 0.3, "align": "center"},
		],
	},
	"swamp": {
		"tileset": SWAMP_ENV + "tileset.png",
		"blocks": [32, 224, 32, 128], "block_w": 5, "top": 6, "rows": 3,
		"rock": Color("1e201e"), "side": Color("3a3a24"), "clear": Color("2f2f1c"),
		"step": "water", "music": Paths.MUSIC_LIVING_SCORN, "combat": Paths.MUSIC_PIXEL_DAMNATION,
		"layers": [
			{"tex": [SWAMP_ENV + "background.png"], "scroll": 0.1, "align": "center"},
			{"tex": [SWAMP_ENV + "mid-layer-01.png", SWAMP_ENV + "mid-layer-02.png"], "scroll": 0.35, "align": "center"},
		],
	},
	"cemetery": {
		"tileset": CEMETERY_ENV + "tileset.png",
		"blocks": [64], "block_w": 4, "top": 58, "rows": 2,
		"rock": Color("0a0a20"), "side": Color("2a1d3a"), "clear": Color("000022"),
		"step": "grass", "music": Paths.MUSIC_AMBIENT_4, "combat": Paths.MUSIC_HEAVY_BATTLE_1,
		"spike_src": Rect2(128, 72, 16, 24),
		"layers": [
			{"tex": [CEMETERY_ENV + "background.png"], "scroll": 0.05, "align": "bottom"},
			{"tex": [CEMETERY_ENV + "mountains.png"], "scroll": 0.2, "align": "bottom"},
			{"tex": [CEMETERY_ENV + "graveyard.png"], "scroll": 0.45, "align": "bottom"},
		],
	},
}

# Cenário da catedral: pedaços da imagem de fundos da igreja (já vêm com o fundo escuro).
const CHURCH_WINDOW := Rect2(0, 0, 152, 192)
const CHURCH_PILLAR := Rect2(160, 0, 140, 192)
const CHURCH_ALTAR := Rect2(304, 0, 144, 192)
const CHURCH_GARGOYLE := Rect2(456, 0, 88, 192)
const CHURCH_TORCH := Rect2(552, 0, 72, 192)


# Música de cada chefe (entra quando ele acorda).
const BOSS_MUSIC := {
	"gato": Paths.MUSIC_REVENGES_WAITING,
	"bringer": Paths.MUSIC_SILVER_BULLET,
	"demon_slime": Paths.MUSIC_APOCALYPTIC_CARNAGE,
}
