extends RefCounted
## Amuletos: itens equipáveis que mudam o herói. (Os ids, como "red_blade", ficam fixos por causa dos saves.) Cada um ocupa "cost" encaixes (NOTCHES no total).
## Equipar/remover só sentado num banco (menu de pausa > Amuletos).
## O efeito de cada amuleto é aplicado no herói (game/player/player.gd) e em main.gd (Geo).

const Paths := preload("res://data/asset_paths.gd")
const NOTCHES := 4
const ICON_SIZE := 32

# icon = índice do ícone (coluna) na folha assets/ui/charm_icons.png (32x32 cada; fonte: art_source/amuletos/amuletos.aseprite, um quadro por ícone)
const CHARMS := {
	"red_blade": {"name": "Punho Rubro", "desc": "Todos os golpes causam +1 de dano.", "cost": 2, "icon": 0},
	"swift_step": {"name": "Passo Veloz", "desc": "Dash 20% mais rápido e recarrega na metade do tempo.", "cost": 1, "icon": 1},
	"hungry_heart": {"name": "Coração Faminto", "desc": "Cada golpe recolhe +6 de alma.", "cost": 1, "icon": 2},
	"quick_focus": {"name": "Foco Rápido", "desc": "Concentrar alma para curar é 40% mais rápido.", "cost": 2, "icon": 3},
	"stone_skin": {"name": "Pele de Pedra", "desc": "+1 máscara de vida.", "cost": 2, "icon": 4},
	"long_reach": {"name": "Alcance Longo", "desc": "A área dos golpes fica 30% maior.", "cost": 1, "icon": 5},
	"sharp_spell": {"name": "Magia Afiada", "desc": "Magias (bola, trovão e mergulho) causam +1 de dano.", "cost": 2, "icon": 6},
	"geo_magnet": {"name": "Ímã de Geo", "desc": "Inimigos derrotados dão 50% mais Geo.", "cost": 1, "icon": 7},
	"one_day": {"name": "Um Dia de Cada Vez", "desc": "Parado no chão por 3 s, recupera alma devagar.", "cost": 1, "icon": 8},
}

# Ordem em que aparecem no menu.
const ORDER := ["red_blade", "swift_step", "hungry_heart", "quick_focus", "stone_skin", "long_reach", "sharp_spell", "geo_magnet", "one_day"]


static func icon(id: String) -> AtlasTexture:
	var i: int = CHARMS[id]["icon"]
	var atlas := AtlasTexture.new()
	atlas.atlas = load(Paths.CHARM_ICONS)
	atlas.region = Rect2(i * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE)
	return atlas
