# Expansão de exploração e assets — 03/10/2026

## Como encontrar o conteúdo

- **Vila:** a fenda entre a casa central e o poço leva à Serra do Último Eco. Use a ação de falar/interagir. Os moradores caminham em trechos curtos, param perto de Noct e mantêm lojas e diálogos disponíveis.
- **Serra:** caminho opcional com seis camadas de parallax, dois pequenos desfiladeiros, banco e uma trilha superior até a estátua. A inscrição da estátua entrega 40 Geo e uma memória de Mira. A passagem na extremidade direita reconecta ao cemitério e abre o atalho do vigia.
- **Atalho:** após atravessar a serra, a fenda na plataforma do Forasteiro, na vila, leva diretamente ao cemitério. A fenda oeste do cemitério permite retornar pela serra. O percurso principal vila → pântano → cemitério continua disponível; nenhum chefe é pulado.
- **Cemitério:** lápides, árvores, arbustos e estátuas decoram as plataformas existentes. A lápide na plataforma baixa central entrega 25 Geo; a estátua próxima ao amuleto no alto entrega 35 Geo. As inscrições dão pistas sobre a fenda, os mortos e a passagem do vigia.
- **Emboscadas:** dois esqueletos enterrados no caminho inferior do cemitério. Proximidade na mesma altura inicia 0,85 s de tremor carmesim no solo, seguido por 0,85 s de surgimento. Só então o inimigo pode causar ou receber dano.
- **Pântano:** dois Thing, um na rota inferior e outro na plataforma leste. Perseguem Noct na mesma altura, viram em paredes e respeitam beiradas. Usam o sprite original do pacote do pântano, 7 PV e 10 Geo.
- **Inferno:** cães alternam repouso e patrulha; usam idle, walk, run e jump conforme o estado. A proximidade do herói interrompe o repouso e retoma a perseguição.

## Efeitos de Noct

O atlas carmesim original foi recortado em oito PNGs transparentes, em `assets/hero/vfx/`. Molduras e textos foram excluídos; o fundo foi removido preservando a energia vermelha. O original permanece intacto. `tools/slice_crimson.ps1` reproduz os recortes.

Dash emite rastros a cada 0,04 s; a aterrissagem do mergulho gera impacto e onda de choque. Cura e preparação da Ultimate usam o círculo mágico, que acompanha os pés e desaparece quando a ação é interrompida. As passagens usam os dois recortes de portal. São efeitos cosméticos: o dano permanece nas hitboxes existentes.

## Save e validação

Descobertas, recompensas coletadas e abertura do atalho persistem **ao descansar em um banco**, seguindo o sistema existente. O banco da serra é um checkpoint válido. Saves anteriores sem o campo opcional `discoveries` continuam carregando; IDs desconhecidos são rejeitados. Cada segredo recompensa uma vez por partida e volta a ficar disponível somente se o progresso não salvo for descartado.

Verificações no Godot 4.7.2:

- `tests/smoke_test.gd`: 66 verificações gerais.
- `tests/regression_test.gd`: 30 verificações de combate, save e transições.
- `tests/content_test.gd`: 45 verificações de NPCs, emboscadas, Thing, cães, VFX, segredos, atalhos e save.
- Execução com renderização: prévias em `docs/content-preview/`, ignoradas pelo importador do Godot. Use `--script tests/content_test.gd -- --screenshots` para regenerar; esse teste isola o save e desativa entrada física apenas no processo do teste.

As capturas de VFX exibem os efeitos juntos para inspeção; em jogo aparecem ligados às respectivas ações. As recompensas são valores iniciais, ainda sujeitos a balanceamento por playtest.
