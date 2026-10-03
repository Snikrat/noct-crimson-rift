extends RefCounted
## Amuletos: itens equipáveis que mudam o herói. Cada um ocupa "cost" encaixes (NOTCHES no total).
## Equipar/remover só sentado num banco (menu de pausa > Amuletos).
## O efeito de cada amuleto é aplicado no herói (game/player/player.gd) e em main.gd (Geo).

const Paths := preload("res://data/asset_paths.gd")
const NOTCHES := 4
const ICON_SIZE := 32

# icon = [folha de ícones (1-7), coluna, linha] em assets/vendor/sword-icons/espadas_N.png
const CHARMS := {
	"red_blade": {"name": "Lâmina Rubra", "desc": "Todos os golpes causam +1 de dano.", "cost": 2, "icon": [6, 0, 0]},
	"swift_step": {"name": "Passo Veloz", "desc": "Dash 20% mais rápido e recarrega na metade do tempo.", "cost": 1, "icon": [6, 1, 0]},
	"hungry_heart": {"name": "Coração Faminto", "desc": "Cada golpe recolhe +6 de alma.", "cost": 1, "icon": [6, 3, 2]},
	"quick_focus": {"name": "Foco Rápido", "desc": "Concentrar alma para curar é 40% mais rápido.", "cost": 2, "icon": [6, 4, 0]},
	"stone_skin": {"name": "Pele de Pedra", "desc": "+1 máscara de vida.", "cost": 2, "icon": [6, 0, 3]},
	"long_reach": {"name": "Alcance Longo", "desc": "A área dos golpes fica 30% maior.", "cost": 1, "icon": [6, 0, 1]},
	"sharp_spell": {"name": "Magia Afiada", "desc": "Magias (bola, trovão e mergulho) causam +1 de dano.", "cost": 2, "icon": [7, 1, 3]},
	"geo_magnet": {"name": "Ímã de Geo", "desc": "Inimigos derrotados dão 50% mais Geo.", "cost": 1, "icon": [7, 3, 4]},
}

# Ordem em que aparecem no menu.
const ORDER := ["red_blade", "swift_step", "hungry_heart", "quick_focus", "stone_skin", "long_reach", "sharp_spell", "geo_magnet"]


static func icon(id: String) -> AtlasTexture:
	var i: Array = CHARMS[id]["icon"]
	var atlas := AtlasTexture.new()
	atlas.atlas = load(Paths.SWORD_ICONS + "espadas_%d.png" % i[0])
	atlas.region = Rect2(i[1] * ICON_SIZE, i[2] * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	return atlas
