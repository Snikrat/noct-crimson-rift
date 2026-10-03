extends Node
## Música e efeitos sonoros do jogo inteiro (título, jogo e pausa).
## Registrado como autoload "Audio": use Audio.play_sfx("attack") de qualquer script.

const Paths := preload("res://data/asset_paths.gd")

const SFX := {
	"rise": Paths.SFX_DIR + "rise.ogg",
	"switch": Paths.SFX_SWITCH,
	# RPG Essentials
	"jump": Paths.RPG_SFX + "12_Player_Movement_SFX/30_Jump_03.wav",
	"land": Paths.RPG_SFX + "12_Player_Movement_SFX/45_Landing_01.wav",
	"swing": Paths.RPG_SFX + "12_Player_Movement_SFX/56_Attack_03.wav",
	"impact": Paths.RPG_SFX + "10_Battle_SFX/15_Impact_flesh_02.wav",
	"player_hit": Paths.RPG_SFX + "12_Player_Movement_SFX/61_Hit_03.wav",
	"dash": Paths.RPG_SFX + "10_Battle_SFX/35_Miss_Evade_02.wav",
	"step_grass": Paths.RPG_SFX + "12_Player_Movement_SFX/03_Step_grass_03.wav",
	"step_rock": Paths.RPG_SFX + "12_Player_Movement_SFX/08_Step_rock_02.wav",
	"step_wood": Paths.RPG_SFX + "12_Player_Movement_SFX/12_Step_wood_03.wav",
	"step_water": Paths.RPG_SFX + "12_Player_Movement_SFX/14_Step_water_02.wav",
	"respawn": Paths.RPG_SFX + "12_Player_Movement_SFX/88_Teleport_02.wav",
	"bite": Paths.RPG_SFX + "10_Battle_SFX/08_Bite_04.wav",
	"slash": Paths.RPG_SFX + "10_Battle_SFX/22_Slash_04.wav",
	"enemy_death": Paths.RPG_SFX + "10_Battle_SFX/69_Enemy_death_01.wav",
	"encounter": Paths.RPG_SFX + "10_Battle_SFX/55_Encounter_02.wav",
	"explosion": Paths.RPG_SFX + "8_Atk_Magic_SFX/04_Fire_explosion_04_medium.wav",
	"thunder": Paths.RPG_SFX + "8_Atk_Magic_SFX/18_Thunder_02.wav",
	"wind": Paths.RPG_SFX + "8_Atk_Magic_SFX/25_Wind_01.wav",
	"earth": Paths.RPG_SFX + "8_Atk_Magic_SFX/30_Earth_02.wav",
	"charge": Paths.RPG_SFX + "8_Atk_Magic_SFX/45_Charge_05.wav",
	"heal": Paths.RPG_SFX + "8_Buffs_Heals_SFX/02_Heal_02.wav",
	"level_up": Paths.RPG_SFX + "8_Buffs_Heals_SFX/16_Atk_buff_04.wav",
	"rest": Paths.RPG_SFX + "8_Buffs_Heals_SFX/17_Def_buff_01.wav",
	"absorb": Paths.RPG_SFX + "8_Buffs_Heals_SFX/39_Absorb_04.wav",
	"hover": Paths.RPG_SFX + "10_UI_Menu_SFX/001_Hover_01.wav",
	"confirm": Paths.RPG_SFX + "10_UI_Menu_SFX/013_Confirm_03.wav",
	"back": Paths.RPG_SFX + "10_UI_Menu_SFX/029_Decline_09.wav",
	"denied": Paths.RPG_SFX + "10_UI_Menu_SFX/033_Denied_03.wav",
	"equip": Paths.RPG_SFX + "10_UI_Menu_SFX/070_Equip_10.wav",
	"unequip": Paths.RPG_SFX + "10_UI_Menu_SFX/071_Unequip_01.wav",
	"buy": Paths.RPG_SFX + "10_UI_Menu_SFX/079_Buy_sell_01.wav",
	"pause": Paths.RPG_SFX + "10_UI_Menu_SFX/092_Pause_04.wav",
	"unpause": Paths.RPG_SFX + "10_UI_Menu_SFX/098_Unpause_04.wav",
}
const MUSIC_VOLUME := -12.0

var music: AudioStreamPlayer        # a que está tocando agora (music_a ou music_b)
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var resume_at := {}                # caminho -> segundo onde a faixa parou
var music_path := ""
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_streams := {}


func _ready() -> void:
	# Continua tocando com o jogo pausado (sons do menu de pausa).
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Dois tocadores para cruzar uma música com a outra.
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	for m in [music_a, music_b]:
		m.volume_db = MUSIC_VOLUME
		add_child(m)
	music = music_a
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6
		add_child(p)
		sfx_players.append(p)
	for key in SFX:
		sfx_streams[key] = load(SFX[key])


## Toca um efeito sonoro com uma leve variação de tom para não ficar repetitivo.
func play_sfx(sound: String, pitch_variation := 0.08, pitch := 1.0) -> void:
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx_streams[sound]
			p.pitch_scale = pitch * randf_range(1 - pitch_variation, 1 + pitch_variation)
			p.play()
			return


## Troca a música com um cruzamento suave (crossfade segundos). Se já for a mesma, só ajusta o tom.
## fade_in > 0 começa baixinho. Uma faixa que sai no meio continua de onde parou quando volta
## (exploração -> combate -> exploração não recomeça a música da área).
func play_music(path: String, pitch := 1.0, fade_in := 0.0, crossfade := 0.0) -> void:
	music.pitch_scale = pitch
	if path == music_path and music.playing:
		return
	var old := music
	if old.playing and music_path != "":
		resume_at[music_path] = old.get_playback_position()
		_fade(old, -40.0, crossfade, true)
	music = music_b if old == music_a else music_a
	music_path = path
	var stream: AudioStream = load(path)
	if "loop" in stream:
		stream.loop = true
	if "loop_offset" in stream:
		stream.loop_offset = Paths.MUSIC_LOOP_OFFSETS.get(path, 0.0)
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music.stream = stream
	music.pitch_scale = pitch
	var fade := maxf(fade_in, crossfade)
	music.volume_db = -40.0 if fade > 0 else MUSIC_VOLUME
	var from: float = resume_at.get(path, 0.0)
	music.play(from if from < stream.get_length() - 1.0 else 0.0)
	_fade(music, MUSIC_VOLUME, fade, false)


## Abaixa a música até sumir (ex.: ao sair do título).
func fade_out_music(duration: float) -> void:
	var tw := _fade(music, -40.0, duration, true)
	music_path = ""
	if tw:
		await tw.finished


var _fades := {}  # tocador -> tween em andamento (um novo fade cancela o anterior)


## Libera os playbacks antes de encerrar uma sessão (também usado pelos testes).
func stop_all() -> void:
	for tween in _fades.values():
		if tween.is_valid():
			tween.kill()
	_fades.clear()
	for player in sfx_players + [music_a, music_b]:
		player.stop()
		player.stream = null
	music_path = ""


func _fade(player: AudioStreamPlayer, to_db: float, duration: float, stop_after: bool) -> Tween:
	if _fades.has(player) and _fades[player].is_valid():
		_fades[player].kill()
	if duration <= 0:
		player.volume_db = to_db
		if stop_after:
			player.stop()
		return null
	var tw := create_tween()
	tw.tween_property(player, "volume_db", to_db, duration)
	if stop_after:
		tw.tween_callback(player.stop)
	_fades[player] = tw
	return tw
