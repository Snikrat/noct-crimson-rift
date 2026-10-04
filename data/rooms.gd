extends RefCounted
## Dados das salas do mundo: mapa em texto, tema visual, vizinhos, NPCs e cenário.
##
## Legenda dos mapas:
##   #  chão/parede          ^  espinhos
##   L  entrada pela esquerda   R  entrada pela direita
##   B  banco (descansa, cura e salva o ponto de retorno)
##   E  aranha   S  esqueleto   F  fantasma voador
##   Q  esqueleto enterrado (aviso + surgimento)   T  Thing (pântano)
##   H  carniçal em chamas   W  mago   A  anjo caído
##   K  cão infernal   Z  caveira de fogo   O  olho demoníaco   ~  lava
##   N  mineiro cristalizado (Minas da Fenda)   V  grimório voraz (Arquivo Submerso)
##   G  chefe Gato Infernal   D  chefe Bringer of Death   M  chefe Demon Slime   Y  chefe Velário (Lago Velado)
##   C  amuleto escondido (qual amuleto: chave "charm" da sala)
##   X  parede carmesim: sólida; com o Passo da Fenda (depois do Bringer), dash contra ela atravessa
##   w  água parada (só visual: Noct anda dentro dela)
##   "memories": [{"id": ..., "feet": Vector2(x, y)}] = fragmentos de memória de Mira (data/memories.gd)
##   1-9  NPC (definido em "npcs" da sala; com "shop": true vira loja)
##
## Falas: texto normal é o NPC falando. "@expressão: texto" é Noct respondendo, com o rosto dele na caixa.
## Expressões: neutro, serio, desconfiado, irritado, bravo, furioso, surpreso, chocado, confuso, pensativo,
##   determinado, confiante, sorrindo, sarcastico, cansado, triste, dor, ferido, sangrando, olhar_lateral,
##   olhar_cima, olhar_baixo, fechando_olhos, calmo, sombrio, maligno, magia_olhos, magia_aura, em_combate, ultimate.
## "@: texto" escolhe sozinho pela vida: sangrando (1 de vida), ferido (pouca vida) ou neutro.
## Personalidade e tom de Noct: docs/noct_personalidade.md (consultar antes de escrever falas).
## NPC com "more": [[...], [...]] tem conversas novas a cada vez que Noct volta a falar (a última se repete).
## "intro": falas de Noct na primeira vez que ele chega na sala (balão sobre ele; passam com o botão).
## Para ligar salas, deixe a borda do mapa aberta (sem #) e preencha "left"/"right".


const Themes := preload("res://data/themes.gd")
const THEMES := Themes.THEMES
const BOSS_MUSIC := Themes.BOSS_MUSIC
const TOWN_ENV := Themes.TOWN_ENV

# Cada sala fica no seu próprio arquivo em data/rooms/. Para criar uma área nova,
# copie um desses arquivos, desenhe o mapa e adicione a sala aqui.
const ROOMS := {
	"forest": preload("res://data/rooms/forest.gd").ROOM,
	"arcane_ruins": preload("res://data/rooms/arcane_ruins.gd").ROOM,
	"archive": preload("res://data/rooms/archive.gd").ROOM,
	"mines": preload("res://data/rooms/mines.gd").ROOM,
	"mountain": preload("res://data/rooms/mountain.gd").ROOM,
	"town": preload("res://data/rooms/town.gd").ROOM,
	"swamp": preload("res://data/rooms/swamp.gd").ROOM,
	"cemetery": preload("res://data/rooms/cemetery.gd").ROOM,
	"lair": preload("res://data/rooms/lair.gd").ROOM,
	"cathedral": preload("res://data/rooms/cathedral.gd").ROOM,
	"sanctum": preload("res://data/rooms/sanctum.gd").ROOM,
	"inferno": preload("res://data/rooms/inferno.gd").ROOM,
	"demon_lair": preload("res://data/rooms/demon_lair.gd").ROOM,
	"tower": preload("res://data/rooms/tower.gd").ROOM,
	"well": preload("res://data/rooms/well.gd").ROOM,
	"station": preload("res://data/rooms/station.gd").ROOM,
	"mind": preload("res://data/rooms/mind.gd").ROOM,
	"lake_shore": preload("res://data/rooms/lake_shore.gd").ROOM,
	"lake": preload("res://data/rooms/lake.gd").ROOM,
}
