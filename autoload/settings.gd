extends Node
## Preferências do jogador (volume da música, volume dos efeitos, tela cheia), salvas em user://settings.cfg.
## Registrado como autoload "Settings" (antes do Audio): cria os canais de áudio "Music" e "SFX"
## e instala a tipografia pixel do jogo.

const UiFont := preload("res://game/ui/ui_font.gd")

const PATH := "user://settings.cfg"

var music := 0.8        # 0..1
var sfx := 0.8          # 0..1
var fullscreen := false


func _ready() -> void:
	UiFont.install()
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		music = clampf(float(cfg.get_value("audio", "music", music)), 0.0, 1.0)
		sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
		fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	apply()


## Aplica as preferências agora (volumes e modo da janela).
func apply() -> void:
	_set_volume("Music", music)
	_set_volume("SFX", sfx)
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func _set_volume(bus: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(i, value <= 0.001)
