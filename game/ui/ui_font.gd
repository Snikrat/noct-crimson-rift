extends RefCounted
## Tipografia pixel do jogo (feita no Aseprite; tools/make_hud_ui.gd gera o .fnt).
## Vira a fonte padrão de todo texto desenhado com ThemeDB.fallback_font.
## Os caracteres que ela não tem (maiúsculas acentuadas, aspas, "·"...) caem na fonte antiga.

const Paths := preload("res://data/asset_paths.gd")


static func install() -> void:
	var font := load(Paths.UI_FONT) as FontFile
	if font == null or ThemeDB.fallback_font == font:
		return
	font.fallbacks = [ThemeDB.fallback_font]
	ThemeDB.fallback_font = font

