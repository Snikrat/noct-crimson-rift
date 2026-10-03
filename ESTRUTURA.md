# Estrutura do projeto — NOCT: CRIMSON RIFT

```
hollow-like/
├─ project.godot              configuração do Godot (cena inicial, autoloads, resolução)
├─ CREDITOS.md                autores e licenças dos assets
├─ docs/noct_personalidade.md personalidade de Noct: guia para TODAS as falas dele
│
├─ autoload/                  sistemas globais, sempre ativos (acessíveis de qualquer script)
│  ├─ game_state.gd           GameState: Geo, chefes derrotados, compras, banco, herói + SAVE
│  ├─ audio.gd                Audio: música e efeitos sonoros
│  └─ controls.gd             Controls: teclado/controle, nome dos botões, vibração
│
├─ game/                      código do jogo, separado por assunto
│  ├─ core/                   utilidades usadas em vários lugares (animações, ações de input)
│  ├─ world/                  main (troca de sala, chefes, eventos), desenho da sala, fundo, banco, NPCs
│  ├─ player/                 o herói
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
│  └─ asset_paths.gd          TODOS os caminhos de arte e som
│
├─ assets/
│  ├─ hero/                   herói (gerado pelas ferramentas a partir de art_source/)
│  ├─ vendor/music/           trilha (só as faixas usadas; pacotes completos em pacotes/NOCT-audios)
│  └─ vendor/                 pacotes de terceiros, sem alterações
│
├─ art_source/                arte-fonte (pranchas, rostos, prompts) — o Godot ignora esta pasta
├─ tools/                     ferramentas de recorte dos sprites
└─ tests/smoke_test.gd        teste automático do jogo inteiro
```

## Tarefas comuns

| Quero... | Onde mexer |
|---|---|
| Criar uma sala nova | copiar um arquivo de `data/rooms/`, desenhar o mapa e registrar em `data/rooms.gd` |
| Mudar falas de um NPC | `data/rooms/town.gd` (falas com `@expressão:` são do herói; seguir `docs/noct_personalidade.md`) |
| Mudar preço ou item da loja | `data/shop_items.gd` |
| Mudar o que cada nível libera | `data/progression.gd` |
| Criar ou ajustar um amuleto | `data/charms.gd` (dados) e `game/player/player.gd` (efeito) |
| Esconder um amuleto numa sala | caractere `C` no mapa + `"charm": "id"` no arquivo da sala |
| Ajustar um chefe | `game/bosses/<chefe>/` |
| Trocar uma animação do herói | colocar a imagem em `art_source/personagem principal/animacoes/`, ajustar `tools/slice_hero.gd` e rodar a ferramenta |
| Trocar a música de uma área, da luta ou de um chefe | `"music"`/`"combat"` e `BOSS_MUSIC` em `data/themes.gd` (caminhos em `data/asset_paths.gd`) |
| Trocar o logo da tela de título | `art_source/logo/logo_sheet.png` e rodar `tools/slice_logo.gd` (quadros em `FRAMES`) |
| Trocar um efeito sonoro | tabela `SFX` em `autoload/audio.gd` |
| Mudar velocidade das animações do herói | `HERO_ANIMS` em `game/core/sprites.gd` |
| Arquivo de arte mudou de lugar | só `data/asset_paths.gd` |

## Comandos

```
# Teste automático (sem janela). Termina com "RESULTADO: N OK, 0 FALHOU".
godot --headless --path . --script tests/smoke_test.gd

# Regressões: saves inválidos, falha de escrita, bônus, dano simultâneo e transições.
godot --headless --path . --script tests/regression_test.gd

# Recortar de novo as animações e os rostos do herói
godot --headless --path . --script tools/slice_hero.gd
godot --headless --path . --script tools/slice_portraits.gd
godot --headless --path . --script tools/slice_logo.gd
```

O save do jogo fica em `user://save.json` (no Windows: `%APPDATA%\NOCT Crimson Rift\save.json`).
Pacotes de assets não usados e os zips originais ficam fora do projeto, em `projetos/jogos/pacotes/`.
