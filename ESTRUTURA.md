# Estrutura do projeto — NOCT: CRIMSON RIFT

```
hollow-like/
├─ project.godot              configuração do Godot (cena inicial, autoloads, resolução)
├─ CREDITOS.md                autores e licenças dos assets
├─ docs/noct_personalidade.md personalidade de Noct: guia para TODAS as falas dele
│
├─ autoload/                  sistemas globais, sempre ativos (acessíveis de qualquer script)
│  ├─ game_state.gd           GameState: Geo, chefes derrotados, compras, banco, herói + SAVE
│  ├─ settings.gd             Settings: volume da música/efeitos e tela cheia (user://settings.cfg)
│  ├─ audio.gd                Audio: música e efeitos sonoros
│  └─ controls.gd             Controls: teclado/controle, nome dos botões, vibração
│
├─ game/                      código do jogo, separado por assunto
│  ├─ core/                   utilidades usadas em vários lugares (animações, ações de input)
│  ├─ world/                  main (troca de sala, chefes, eventos), desenho da sala, fundo, banco, NPCs
│  ├─ player/                 o herói em camadas: player_body → player_spells → player_combat → player.gd
│  ├─ enemies/                inimigos comuns e projéteis
│  ├─ bosses/<chefe>/         cada chefe na sua pasta, com os ataques dele
│  ├─ spells/                 magias do herói e a Ultimate
│  └─ ui/                     título, HUD, diálogo, loja, pausa
│
├─ data/                      conteúdo do jogo, sem lógica
│  ├─ rooms/<sala>.gd         uma sala por arquivo (mapa, vizinhos, NPCs, cenário)
│  ├─ rooms.gd                índice das salas + legenda dos caracteres do mapa
│  ├─ themes.gd               visual de cada área (tileset, fundo, música)
│  ├─ progression.gd          XP e recompensas de cada nível
│  ├─ shop_items.gd           itens da loja
│  ├─ charms.gd               amuletos (efeito, custo, ícone)
│  ├─ memories.gd             memórias de Mira (texto de cada fragmento)
│  ├─ world_map.gd            posição de cada sala no mapa da pausa
│  └─ asset_paths.gd          TODOS os caminhos de arte e som
│
├─ assets/
│  ├─ hero/                   herói (gerado pelas ferramentas a partir de art_source/)
│  ├─ vendor/music/           trilha (só as faixas usadas; pacotes completos em pacotes/NOCT-audios)
│  └─ vendor/                 pacotes de terceiros, sem alterações
│
├─ art_source/                arte-fonte (pranchas, rostos, prompts) — o Godot ignora esta pasta
├─ tools/                     ferramentas de recorte dos sprites
└─ tests/                     testes automáticos (smoke, regressão, conteúdo, novos assets, história)
```

## Tarefas comuns

| Quero... | Onde mexer |
|---|---|
| Criar uma sala nova | copiar um arquivo de `data/rooms/`, desenhar o mapa e registrar em `data/rooms.gd` |
| Mudar falas de um NPC | `data/rooms/town.gd` (falas com `@expressão:` são do herói; seguir `docs/noct_personalidade.md`) |
| Mudar preço ou item da loja | `data/shop_items.gd` |
| Mudar o que cada nível libera | `data/progression.gd` |
| Criar ou ajustar um amuleto | `data/charms.gd` (dados) e `game/player/player_body.gd` (efeito, seção Amuletos) |
| Esconder um amuleto numa sala | caractere `C` no mapa + `"charm": "id"` no arquivo da sala |
| Ajustar um chefe | `game/bosses/<chefe>/` |
| Trocar uma animação do herói | colocar a imagem em `art_source/personagem principal/animacoes/`, ajustar `tools/slice_hero.gd` e rodar a ferramenta |
| Trocar a música de uma área, da luta ou de um chefe | `"music"`/`"combat"` e `BOSS_MUSIC` em `data/themes.gd` (caminhos em `data/asset_paths.gd`) |
| Trocar as barras do HUD ou a fonte pixel | arte em `art_source/ui/hud/` (feita no Aseprite) e rodar `tools/make_hud_ui.gd`; posição das barras em `BARS_POS` (`game/ui/hud.gd`) |
| Trocar o logo da tela de título | `art_source/logo/logo_sheet.png` e rodar `tools/slice_logo.gd` (quadros em `FRAMES`) |
| Trocar um efeito sonoro | tabela `SFX` em `autoload/audio.gd` |
| Trocar as formas carmesim (níveis 1-3) | `art_source/personagem principal/carmesim/niveis_carmesim.png` e rodar `tools/slice_crimson.gd`; velocidades em `CRIMSON_ANIMS` (`game/core/sprites.gd`) |
| Esconder uma memória de Mira | texto em `data/memories.gd` + `"memories": [{"id", "feet"}]` no arquivo da sala |
| Criar uma parede carmesim (Passo da Fenda) | caractere `X` no mapa (sólido; atravessa com dash depois do Bringer) |
| Ajustar o salto na parede (Garras do Gato) | `WALL_*` e `_wall_side`/`_wall_jump` em `game/player/player_body.gd`; liberado em `has_wall_grip` (`main.gd`) |
| Passagem que exige memória ou chefe | marcador com `"requires": "memory:<id>"` ou `"boss:<id>"` e, opcional, `"locked_lines"` |
| Água parada ou chuva numa área | caractere `w` no mapa (cor `"water"` no tema) / `"rain": true` no tema (`data/themes.gd`) |
| Mudar falas/etapas da Tessa | `game/world/tessa.gd` e a chave `"tessa"` nas salas (Bosque, vila, catedral) |
| Mudar o final (revelação, escolha, epílogo) | `REVELATION` e `_ending_sequence` em `game/world/main.gd`; epílogo e créditos em `game/ui/ending.gd` |
| Mudar o mapa da pausa | `data/world_map.gd` |
| Mudar velocidade das animações do herói | `HERO_ANIMS` em `game/core/sprites.gd` |
| Arquivo de arte mudou de lugar | só `data/asset_paths.gd` |
| Criar uma área com tileset próprio | PNG 8x3 tiles de 16 px em `assets/areas/<área>/` (bloco 3x3 nas colunas 0-2, isolado em (3,2)) e tema com `"autotile": true` em `data/themes.gd`; fontes .aseprite em `art_source/cenarios_novos/` |

## Comandos

```
# Teste automático (sem janela). Termina com "RESULTADO: N OK, 0 FALHOU".
godot --headless --path . --script tests/smoke_test.gd
godot --headless --path . --script tests/regression_test.gd
godot --headless --path . --script tests/content_test.gd
godot --headless --path . --script tests/new_assets_test.gd
godot --headless --path . --script tests/story_test.gd
godot --headless --path . --script tests/areas_test.gd

# Regressões: saves inválidos, falha de escrita, bônus, dano simultâneo e transições.
godot --headless --path . --script tests/regression_test.gd

# Recortar de novo as animações e os rostos do herói
godot --headless --path . --script tools/slice_hero.gd
godot --headless --path . --script tools/slice_portraits.gd
godot --headless --path . --script tools/slice_logo.gd
godot --headless --path . --script tools/slice_crimson.gd
```

O save do jogo fica em `user://save.json` (no Windows: `%APPDATA%\NOCT Crimson Rift\save.json`).
Pacotes de assets não usados e os zips originais ficam fora do projeto, em `projetos/jogos/pacotes/`.

## Herói (game/player/)

Cada arquivo herda do anterior, então todos enxergam as mesmas variáveis:

| Arquivo | O que tem |
|---|---|
| `player_body.gd` | constantes, estado, movimento, passos, dados dos golpes, amuletos, animação, dano e morte |
| `player_spells.gd` | bola de energia, trovão, cura e Ultimate |
| `player_combat.gd` | entrada de ataque, combos (chão e ar), golpes para cima/baixo, golpe no chão, acertos |
| `player.gd` | `_ready`, troca de sala, renascer e o ciclo principal (`_physics_process`) |

Uma camada de baixo não pode chamar funções de uma de cima (o Godot dá erro ao carregar).

## Cópia de segurança (Git)

O projeto é um repositório Git local. Antes de mudanças grandes:

```
git add -A
git commit -m "o que mudou"
```

Para ver o histórico: `git log --oneline`. Para desfazer mudanças não salvas num arquivo: `git restore caminho/do/arquivo`.
