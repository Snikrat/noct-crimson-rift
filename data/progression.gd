extends RefCounted
## Sistema de nível do herói: XP necessário e o que cada nível libera.

const MAX_LEVEL := 10

# XP total necessário para chegar em cada nível (índice = nível).
const XP_FOR_LEVEL := [0, 0, 40, 100, 180, 280, 400, 550, 720, 920, 1150]

# O que cada nível dá. "unlock" libera uma habilidade; "hp"/"soul" são bônus de atributo.
const REWARDS := {
	2: {"unlock": "combo", "title": "Combo de Socos",
		"text": "Aperte o ataque várias vezes: soco, rajada e um chute de 2 de dano."},
	3: {"hp": 1, "title": "Vigor", "text": "+1 máscara de vida."},
	4: {"unlock": "wave", "title": "Onda de Energia",
		"text": "Sua magia vira uma onda maior que causa +1 de dano."},
	5: {"unlock": "charged", "title": "Golpe Carregado",
		"text": "Segure o ataque e solte para um soco devastador (4 de dano)."},
	6: {"hp": 1, "soul": 3, "title": "Espírito Forte", "text": "+1 máscara e mais alma a cada golpe."},
	7: {"unlock": "uppercut", "title": "Uppercut",
		"text": "Cima + ataque: um gancho para cima que causa 3 de dano, sem saltar."},
	8: {"unlock": "slam", "title": "Impacto no Solo",
		"text": "Durante o combo aéreo, baixo + ataque: mergulha e explode o chão, sem gastar alma."},
	9: {"hp": 1, "title": "Vigor", "text": "+1 máscara de vida."},
	10: {"unlock": "ultimate", "title": "ULTIMATE: Dragão de Energia",
		"text": "Com a alma cheia, aperte U (ou Y no controle) para invocar o dragão."},
}


## XP que cada inimigo dá ao morrer: o dobro do Geo dele.
static func xp_for_geo(geo: int) -> int:
	return geo * 2
