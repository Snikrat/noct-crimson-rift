extends RefCounted
## Mapa do mundo (menu de pausa): onde cada sala aparece.
## A fileira principal segue a ordem da história; salas laterais ficam acima ou abaixo.
## O tamanho de cada caixa vem do tamanho do mapa da sala (SCALE px por bloco).

const SCALE := 0.5
const GAP := 10.0
# Fileira principal, da esquerda para a direita.
const MAIN_ROW := ["town", "swamp", "cemetery", "lair", "cathedral", "sanctum", "inferno", "demon_lair"]
# Salas fora da fileira: [sala vizinha na fileira, deslocamento em px a partir do centro dela].
const SIDE := {
	"forest": ["town", Vector2(26, 42)],
	"mountain": ["swamp", Vector2(22, -44)],
	"arcane_ruins": ["cathedral", Vector2(0, -42)],
	"mines": ["town", Vector2(-38, 0)],
	"archive": ["cathedral", Vector2(36, -42)],
}
