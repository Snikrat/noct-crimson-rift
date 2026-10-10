# Pedravelha — PixelLab

Arte própria da vila em escala nativa, tiles de 16×16 px e atores de aproximadamente 46 px.
Os IDs dos objetos, correções de fachadas e efeitos estão em `pixellab.json`.

- `tileset.png` / `tileset.json`: atlas Wang 4×4 e metadados originais; a seleção das peças está em `game/world/room_view.gd`.
- Fachadas e objetos: arquivos PNG transparentes separados. O carregador recorta as margens transparentes ao apoiar cada objeto na rua. As caixas antigas são reduzidas à metade, com filtro nearest; o banco da praça é o de ferro gótico original (`assets/props/bench.png`). Cada objeto afunda alguns pixels no calçamento (`prop_sink` em `data/rooms/town.gd`) para ficar apoiado no chão. Monumento e cabana foram redesenhados no PixelLab já no tamanho dobrado (96×128 e 192×128), então entram em escala 1.
- `background.png` e `middleground.png`: montanhas e silhuetas de árvores/telhados em velocidades diferentes de parallax.
- `vfx/`: 12 clips individuais, cada um com PNG e JSON de recortes e duração dos quadros. Os efeitos também estão salvos em **My effects** no PixelLab.
- `game/world/pixel_effect.gd`: reproduz os recortes sem assumir que o atlas é uma faixa horizontal. Os pontos de origem da exportação do PixelLab podem ficar fora do canvas; os pontos visuais usados pelo jogo são explícitos em `data/rooms/town.gd`.

A praça fica entre a casa de Zeno e o poço. O banco é um único objeto interativo, com espaço à direita para Tessa. Capela, ferraria e hospedaria têm os respectivos moradores por perto. O acesso às minas continua protegido pela parede carmesim; o atalho do vigia continua exigindo sua descoberta. Os retornos das salas usam os pontos de entrada atualizados.

Âmbar indica abrigo; carmesim e magenta ficam nas memórias, no descanso e nas passagens da Fenda. Névoa, poeira e folhas ficam atrás dos atores. Faíscas da forja são disparos separados por quatro segundos; o brilho do banco só toca ao descansar.

Validação: `tests/pedravelha_test.gd`, `tests/content_test.gd` e `tests/smoke_test.gd`. Para gerar as quatro prévias em `docs/content-preview/`, execute o primeiro com renderização e `-- --screenshots`.
