extends RefCounted
## Itens à venda na loja do Ferreiro Brom. O efeito de cada um fica em game/ui/shop.gd.
## Itens com "charm" dão um amuleto (ver data/charms.gd).

const ITEMS := [
	{"id": "mask", "name": "Fragmento de Máscara", "desc": "Ganha +1 máscara de vida.", "price": 80, "max": 2},
	{"id": "soul", "name": "Coração de Alma", "desc": "Cada golpe recolhe +5 de alma.", "price": 60, "max": 1},
	{"id": "blade", "name": "Luvas de Ferro", "desc": "Todos os seus golpes causam +1 de dano.", "price": 150, "max": 1},
	{"id": "charm_swift", "name": "Amuleto: Passo Veloz", "desc": "Dash mais rápido e com metade da recarga. Equipe num banco.", "price": 100, "max": 1, "charm": "swift_step"},
	{"id": "charm_hungry", "name": "Amuleto: Coração Faminto", "desc": "Cada golpe recolhe +6 de alma. Equipe num banco.", "price": 120, "max": 1, "charm": "hungry_heart"},
	{"id": "charm_geo", "name": "Amuleto: Ímã de Geo", "desc": "Inimigos dão 50% mais Geo. Equipe num banco.", "price": 90, "max": 1, "charm": "geo_magnet"},
	{"id": "charm_spell", "name": "Amuleto: Magia Afiada", "desc": "Magias causam +1 de dano. Equipe num banco.", "price": 200, "max": 1, "charm": "sharp_spell"},
]
