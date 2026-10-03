extends RefCounted
## Mapa do mundo (menu de pausa): onde cada sala aparece.
## A fileira principal segue a ordem da história; salas laterais ficam acima ou abaixo.
## O tamanho de cada caixa vem do tamanho do mapa da sala (SCALE px por bloco).

const SCALE := 0.3
const GAP := 7.0
# Fileira principal, da esquerda para a direita.
const MAIN_ROW := ["town", "swamp", "cemetery", "lair", "cathedral", "sanctum", "inferno", "demon_lair"]
# Salas fora da fileira: [sala vizinha na fileira, deslocamento em px a partir do centro dela].
const SIDE := {
	"forest": ["town", Vector2(18, 26)],
	"mountain": ["swamp", Vector2(14, -28)],
	"arcane_ruins": ["cathedral", Vector2(0, -26)],
}
