extends RefCounted
## Monta as animações (SpriteFrames) a partir dos PNGs dos pacotes Gothicvania.

const Paths := preload("res://data/asset_paths.gd")
const ENEMIES := Paths.ENEMIES
const SWAMP := Paths.SWAMP


## Adiciona uma animação a partir de um padrão de arquivo com %d (começando em 1).
static func add_anim(frames: SpriteFrames, anim: String, pattern: String, count: int, fps: float, loop := true, first := 1) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in range(first, first + count):
		frames.add_frame(anim, load(pattern % i))


const HERO_DIR := Paths.HERO

# Velocidade (quadros/s) e se repete, para cada animação do herói.
# Um terceiro valor "pingpong" faz a animação ir e voltar (1-2-3-4-3-2) em vez de reiniciar.
const HERO_ANIMS := {
	"air_punch": [20, false], "air_kick": [20, false], "air_spin": [22, false], "air_finish": [20, false],
	# Noct v2: respiração lenta (0,5 s por quadro); idle_var = abaixa a cabeça; walk = caminhada.
	"idle": [2, true, "pingpong"], "idle_var": [2, false], "walk": [7, true],
	# Pulo completo: jump = impulso, subida, topo; land = agachamento e recuperação.
	"run": [14, true], "run_start": [12, false], "run_stop": [10, false], "air_dash": [50, false],
	"jump": [12, false], "fall": [8, false], "land": [14, false],
	"jab": [18, false], "cross": [16, false], "kick": [16, false], "charged": [12, false],
	"up_punch": [20, false], "low_punch": [16, false], "uppercut": [18, false], "cast": [22, false],
	"slam": [10, false], "dash": [50, false], "double_jump": [30, false],
	"crouch": [4.5, false], "hurt": [14, false], "death": [8, false],
	"ultimate_charge": [14, false], "ultimate_burst": [12, false], "ultimate_pose": [8, false],
	# Olhando para cima: inclina a cabeça e depois respira (tools/noct_look_up.lua).
	"look_up": [14, false], "look_up_loop": [3, true],
}


# Formas carmesim (tools/remaster_hero.gd): c<nível>_<animação>, só as animações básicas.
const CRIMSON_DIR := HERO_DIR + "crimson/"
const CRIMSON_LEVELS := 3
# Refeitas sobre o Noct base por tools/noct_forms.lua (aura, chifres, olhos; ver o documento da
# Forma Demoníaca): mesmas animações básicas e velocidades do Noct normal.
const CRIMSON_ANIMS := {
	# Parado, andar, correr, dash e abaixado vêm da folha "Guerreiro Raposa Demoníaco"
	# (tools/noct_raposa.lua): 6 quadros de chama em loop, por isso mais rápidos que os do Noct base.
	"idle": [8, true], "walk": [10, true], "run": [12, true], "run_start": [12, false],
	"run_stop": [10, false], "jump": [12, false], "fall": [8, false], "land": [14, false],
	"double_jump": [30, false], "dash": [30, false], "air_dash": [30, false], "crouch": [8, false],
	# Abaixado: depois de cN_crouch, a energia continua se mexendo.
	"crouch_loop": [6, true],
	# Transição ao transformar (tools/noct_forms.lua): curva, o manto cresce, anel de choque.
	"transform": [14, false],
	"look_up": [14, false], "look_up_loop": [3, true],
	# Golpes da Forma Demoníaca (tools/noct_forms.lua), em quadro maior (crimson.json).
	"tailburst": [14, false], "air_barrage": [20, false], "air_foxfire": [18, false],
	# Combo da folha de golpes (tools/noct_raposa.lua).
	"fox_claw": [14, false], "fox_spin": [16, false], "fox_leap": [14, false], "fox_spirit": [12, false],
	"fox_rush": [11, false],
}


## Medidas de cada tira do herói (gerado por tools/remaster_hero.gd): quadros, w, h e ponto dos pés (ax, ay).
## Todas as animações do corpo usam o mesmo quadro e o mesmo ponto dos pés.
## Inclui as formas carmesim (crimson.json).
static func hero_meta() -> Dictionary:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HERO_DIR + "hero.json"))
	if FileAccess.file_exists(CRIMSON_DIR + "crimson.json"):
		meta.merge(JSON.parse_string(FileAccess.get_file_as_string(CRIMSON_DIR + "crimson.json")))
	# Animações feitas direto no Aseprite (noct.aseprite) não têm entrada no json: todas usam o
	# mesmo quadro do Idle, e o número de quadros sai da largura da tira.
	var missing := {}
	for anim in HERO_ANIMS:
		missing[anim] = HERO_DIR + anim + ".png"
	for lv in range(1, CRIMSON_LEVELS + 1):
		for anim in crimson_anims():
			missing["c%d_%s" % [lv, anim]] = CRIMSON_DIR + "c%d_%s.png" % [lv, anim]
	# O número de quadros sempre sai da largura da tira (as tiras do Aseprite podem mudar).
	for key in missing:
		if not ResourceLoader.exists(missing[key]) or not meta.has("idle"):
			continue
		if not meta.has(key):
			meta[key] = meta["idle"].duplicate()
		var tex: Texture2D = load(missing[key])
		meta[key]["frames"] = tex.get_width() / int(meta[key]["w"])
	return meta


## Projétil da magia do herói: surge (0-2), voa em loop (3-5) e se desfaz (6-7).
static func spell_ball() -> SpriteFrames:
	var m: Dictionary = hero_meta()["spell_ball"]
	var size := Vector2(m["w"], m["h"])
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_sheet(f, "grow", HERO_DIR + "spell_ball.png", size, 0, 2, 20, false)
	add_sheet(f, "fly", HERO_DIR + "spell_ball.png", size, 3, 5, 14)
	add_sheet(f, "burst", HERO_DIR + "spell_ball.png", size, 6, 7, 14, false)
	return f


## Magia da forma carmesim 3: a Raposa Espectral (tools/make_fox_spell.lua), 8 quadros de mesma
## largura, com o focinho na borda direita. Mesmas fases da bola: surge, voa em loop, se desfaz.
const FOX_SPELL := CRIMSON_DIR + "c3_spell_ball.png"
const FOX_SPELL_FRAMES := 8

static func fox_spell() -> SpriteFrames:
	var tex: Texture2D = load(FOX_SPELL)
	var size := Vector2(tex.get_width() / float(FOX_SPELL_FRAMES), tex.get_height())
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_sheet(f, "grow", FOX_SPELL, size, 0, 2, 20, false)
	add_sheet(f, "fly", FOX_SPELL, size, 3, 5, 12)
	add_sheet(f, "burst", FOX_SPELL, size, 6, 7, 14, false)
	return f


static func hero() -> SpriteFrames:
	var meta := hero_meta()
	var f := SpriteFrames.new()
	f.remove_animation("default")
	for anim in HERO_ANIMS:
		var m: Dictionary = meta[anim]
		add_sheet(f, anim, HERO_DIR + anim + ".png", Vector2(m["w"], m["h"]), 0, int(m["frames"]) - 1,
			HERO_ANIMS[anim][0], HERO_ANIMS[anim][1])
		if HERO_ANIMS[anim].size() > 2 and HERO_ANIMS[anim][2] == "pingpong":
			# Repete os quadros do meio de trás para frente: 0 1 2 3 -> 0 1 2 3 2 1
			var count := f.get_frame_count(anim)
			for i in range(count - 2, 0, -1):
				f.add_frame(anim, f.get_frame_texture(anim, i))
	_add_crimson(f, meta)
	return f


## Animações das formas carmesim: todas as do Noct base (mesma velocidade) e as próprias delas.
static func crimson_anims() -> Dictionary:
	var all := HERO_ANIMS.duplicate()
	all.merge(CRIMSON_ANIMS, true)
	return all


static func _add_crimson(f: SpriteFrames, meta: Dictionary) -> void:
	var anims := crimson_anims()
	for lv in range(1, CRIMSON_LEVELS + 1):
		for anim in anims:
			var key := "c%d_%s" % [lv, anim]
			if not meta.has(key):
				continue
			var m: Dictionary = meta[key]
			var cfg: Array = anims[anim]
			add_sheet(f, key, CRIMSON_DIR + key + ".png", Vector2(m["w"], m["h"]), 0, int(m["frames"]) - 1, cfg[0], cfg[1])
			if cfg.size() > 2 and cfg[2] == "pingpong":
				var count := f.get_frame_count(key)
				for i in range(count - 2, 0, -1):
					f.add_frame(key, f.get_frame_texture(key, i))

## Adiciona uma animação recortando quadros [first, last] de uma spritesheet horizontal.
static func add_sheet(frames: SpriteFrames, anim: String, path: String, frame_size: Vector2, first: int, last: int, fps: float, loop := true) -> void:
	var tex: Texture2D = load(path)
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in range(first, last + 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(Vector2(i * frame_size.x, 0), frame_size)
		frames.add_frame(anim, atlas)


const MAGIC := Paths.MAGIC
const TOWN_SPRITES := Paths.TOWN_SPRITES

# Quantidade de quadros da animação parada de cada NPC da cidade.
const NPC_IDLE_FRAMES := {"oldman": 8, "woman": 7, "bearded": 5, "hat-man": 4}


static func npc(kind: String) -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "idle", TOWN_SPRITES + kind + "-idle/" + kind + "-idle-%d.png", NPC_IDLE_FRAMES[kind], 7)
	add_anim(f, "walk", TOWN_SPRITES + kind + "-walk/" + kind + "-walk-%d.png", 12 if kind == "oldman" else 6, 8)
	return f


## Orbe de faísca: quadros 0-2 voando, 3-6 explodindo.
static func spark() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_sheet(f, "fly", MAGIC + "spark.png", Vector2(32, 32), 0, 2, 14)
	add_sheet(f, "burst", MAGIC + "spark.png", Vector2(32, 32), 3, 6, 16, false)
	return f


static func hell_gato() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "run", ENEMIES + "hell-gato/Sprites/hell-gato-%d.png", 4, 10)
	return f


## Bola de fogo do chefe: quadro 7 voando, 8-13 explodindo.
static func fireball() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_sheet(f, "fly", MAGIC + "Fire-bomb.png", Vector2(64, 64), 7, 7, 1)
	add_sheet(f, "boom", MAGIC + "Fire-bomb.png", Vector2(64, 64), 8, 13, 16, false)
	return f


const CHURCH := Paths.CHURCH_SPRITES
const BRINGER := Paths.BRINGER


## Animação a partir de arquivos f-01.png, f-02.png... (padrão do pacote da igreja).
static func add_church_anim(frames: SpriteFrames, anim: String, dir: String, count: int, fps: float, loop := true) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in range(1, count + 1):
		frames.add_frame(anim, load(CHURCH + dir + "/f-%02d.png" % i))


static func ghoul() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_church_anim(f, "walk", "burning-ghoul/run 1/sprites", 8, 14)
	return f


static func wizard() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_church_anim(f, "idle", "wizard/Idle/sprites", 5, 7)
	add_church_anim(f, "fire", "wizard/Fire/sprites", 10, 12, false)
	return f


static func angel() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_church_anim(f, "fly", "angel/idle/sprites", 8, 10)
	add_church_anim(f, "attack", "angel/attack/sprites", 3, 8)
	return f


static func church_fireball() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "fly", CHURCH + "fx/fireball/fireball-sprites/fireball%d.png", 3, 12)
	return f


static func bringer() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "idle", BRINGER + "Idle/Bringer-of-Death_Idle_%d.png", 8, 9)
	add_anim(f, "walk", BRINGER + "Walk/Bringer-of-Death_Walk_%d.png", 8, 10)
	add_anim(f, "attack", BRINGER + "Attack/Bringer-of-Death_Attack_%d.png", 10, 12, false)
	add_anim(f, "cast", BRINGER + "Cast/Bringer-of-Death_Cast_%d.png", 9, 12, false)
	add_anim(f, "hurt", BRINGER + "Hurt/Bringer-of-Death_Hurt_%d.png", 3, 12, false)
	add_anim(f, "death", BRINGER + "Death/Bringer-of-Death_Death_%d.png", 10, 9, false)
	return f


static func bringer_spell() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "spell", BRINGER + "Spell/Bringer-of-Death_Spell_%d.png", 16, 16, false)
	return f


# --- Inferno -----------------------------------------------------------

static func hell_hound() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "idle", Paths.LEGACY + "hell-hound/Idle/frame%d.png", 11, 8)
	add_anim(f, "walk", Paths.LEGACY + "hell-hound/Walk/frame%d.png", 12, 10)
	add_anim(f, "run", Paths.LEGACY + "hell-hound/Run/frame%d.png", 5, 12)
	add_anim(f, "jump", Paths.LEGACY + "hell-hound/Jump/frame%d.png", 6, 10, false)
	return f


static func fire_skull() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "fly", Paths.LEGACY + "fire-skull/frame%d.png", 8, 12)
	return f


static func flying_eye() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "fly", Paths.LEGACY + "flying-eye/flying-eye-demon%d.png", 8, 10)
	return f


static func demon_slime() -> SpriteFrames:
	var d := Paths.DEMON_SLIME
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "idle", d + "01_demon_idle/demon_idle_%d.png", 6, 8)
	add_anim(f, "walk", d + "02_demon_walk/demon_walk_%d.png", 12, 12)
	add_anim(f, "cleave", d + "03_demon_cleave/demon_cleave_%d.png", 15, 13, false)
	add_anim(f, "hurt", d + "04_demon_take_hit/demon_take_hit_%d.png", 5, 14, false)
	add_anim(f, "death", d + "05_demon_death/demon_death_%d.png", 22, 11, false)
	return f


static func lightning() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_sheet(f, "strike", MAGIC + "Lightning.png", Vector2(64, 128), 0, 9, 18, false)
	return f


# --- Minas da Fenda e Arquivo Submerso (desenhados no Aseprite, olham para a direita) ---

static func crystal_miner() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_sheet(f, "walk", Paths.MINES + "mineiro_cristalizado_sheet.png", Vector2(44, 52), 0, 3, 6)
	return f


static func grimoire() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_sheet(f, "fly", Paths.ARCHIVE + "grimorio_voraz_sheet.png", Vector2(40, 40), 0, 3, 9)
	return f


static func spider() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "walk", SWAMP + "Sprites/Spider/walk/spider%d.png", 4, 10)
	return f


static func skeleton() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "walk", ENEMIES + "skeleton/Sprites/Walk/skeleton-%d.png", 8, 8)
	add_anim(f, "rise", ENEMIES + "skeleton/skeleton-rise/skeleton-rise-%d.png", 6, 8, false)
	return f


static func thing() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "walk", SWAMP + "Sprites/Thing/walk thing/thing%d.png", 4, 9)
	return f


const BANDITS := "res://assets/enemies/bandits/"
const BANDIT_CELL := Vector2(62, 58)   # quadro comum dos bandidos (bandits.json)
const BANDIT_FEET := 55.0              # linha dos pés no quadro

static func humanoid(kind: String) -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	if kind in ["light", "heavy", "captain"]:
		# Padronizados no Aseprite na escala do Noct (tools/make_bandits.lua): quadro e origem únicos.
		var folder := BANDITS + ("light/" if kind == "light" else "heavy/")
		for spec in [["idle", 7, true], ["combat_idle", 7, true], ["run", 12, true], ["attack1", 12, false],
				["recover", 10, false], ["hurt", 12, false], ["death", 1, false]]:
			var file: String = "attack" if spec[0] == "attack1" else spec[0]
			var tex: Texture2D = load(folder + file + ".png")
			add_sheet(f, spec[0], folder + file + ".png", BANDIT_CELL, 0, int(tex.get_width() / BANDIT_CELL.x) - 1, spec[1], spec[2])
	else:
		var wizard := kind == "wizard"
		var folder := Paths.EVIL_WIZARD if wizard else Paths.HERO_KNIGHT
		var cell := Vector2(250, 250) if wizard else Vector2(180, 180)
		for spec in [["idle", "Idle", 8 if wizard else 11, true], ["run", "Run", 8, true],
				["attack1", "Attack1", 8 if wizard else 7, false], ["attack2", "Attack2", 8 if wizard else 7, false],
				["hurt", "Take hit" if wizard else "Take Hit", 3 if wizard else 4, false], ["death", "Death", 7 if wizard else 11, false]]:
			add_sheet(f, spec[0], folder + spec[1] + ".png", cell, 0, spec[2] - 1, 10 if wizard else 12, spec[3])
	return f


static func ghost() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "fly", SWAMP + "Sprites/Ghost/Flying/Ghost%d.png", 4, 8)
	return f


static func explosion() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	add_anim(f, "boom", SWAMP + "Sprites/Enemy-Death/Explosion/Enemy-Death%d.png", 6, 14, false)
	return f


## Cria um AnimatedSprite2D com os pés do desenho alinhados com a base do colisor.
## frame_size: tamanho de cada quadro; feet_y: linha (em pixels) onde ficam os pés no quadro.
static func make_sprite(frames: SpriteFrames, frame_size: Vector2, feet_y: float, half_height: float) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames
	s.centered = false
	s.offset = Vector2(-frame_size.x / 2.0, -feet_y - 1)
	s.position.y = half_height
	return s
