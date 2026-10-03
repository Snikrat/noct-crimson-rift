# Assets de NOCT: CRIMSON RIFT — aproveitamento e consistência

Análise em 03/10/2026. O maior ganho está em aprofundar as áreas existentes, usar os efeitos carmesim de Noct e criar ramificações com o cenário de montanha. Há material para isso sem trocar a identidade do protagonista.

## Escopo e arquivos de consulta

Inventariados **1.023 arquivos**, excluindo `.import`, em `assets/`, `art_source/` e os arquivos de imagem da raiz. Não foram incluídos pacotes externos à pasta do projeto. O inventário registra caminho, tamanho, hash SHA-256 e dimensões das imagens. Foram examinadas 403 prévias representativas de PNG em 11 pranchas, agrupando sequências de animação, além de originais relevantes. Todas as 812 imagens PNG foram inventariadas; não foi feita uma inspeção individual de cada quadro nem playback de cada animação.

- [Catálogo pesquisável de imagens e áudio](assets-audit/gallery.html): abre os originais e permite ouvir os sons localmente.
- [Inventário completo](assets-audit/inventory.json).
- Pranchas de contato: `assets-audit/contact-01.png` a `contact-11.png`.
- Ferramentas de reprodução: `tools/inventory_assets.ps1` e `tools/assets_gallery.ps1`.

Os sons foram comparados por nomes, arquivos e referências no código. Não foi realizada audição completa, medição de loudness ou teste de loops. Arquivos PSD/ASE foram contabilizados como fontes editáveis; a avaliação visual se baseou nas imagens exportadas. A existência de um arquivo não comprova sua autorização de distribuição; as pendências já registradas em `CREDITOS.md` continuam aplicáveis.

Nenhum asset original ou script de gameplay foi alterado nesta análise. A pasta do catálogo possui `.gdignore` para não importar as imagens da auditoria no Godot.

## Inventário

| Categoria | Quantidade | Observação |
|---|---:|---|
| PNG | 812 | 724 de terceiros, 54 do herói, 17 do logo, 16 de arte-fonte e 1 ícone da raiz |
| Áudio | 71 | 50 WAV, 17 OGG e 4 MP3; 69 arquivos únicos por hash |
| GIF | 49 | Principalmente previews de animação |
| PSD / ASE | 46 | 30 PSD e 16 ASE de criação/edição |
| ICO | 1 | Ícone dos atalhos |
| Demais arquivos | 44 | Metadados, documentação, demos e licenças locais |

Há **46 grupos de arquivos com conteúdo idêntico**. Isso inclui cópias de demos e quadros repetidos intencionalmente em animações. Não remover por hash automaticamente: um frame repetido pode fazer parte do ritmo da animação.

## Regras de consistência para novas implementações

1. **Noct continua sendo um lutador arcano.** Socos, chutes e energia são sua linguagem. Os protagonistas com espada, rifle ou roupa vermelha dos pacotes não devem substituir suas animações; servem como referência ou, com contexto narrativo, personagens diferentes.
2. **Carmesim/magenta identifica o Rift e Noct.** Roxo, azul espectral, verde pútrido e laranja infernal podem distinguir inimigos e ambientes. Não tornar tudo vermelho: o contraste ajuda a ler ameaças e poderes.
3. **Manter a escala do mundo.** Tiles de 16 px, viewport 480 × 270 e Noct com altura de referência próxima de 44 px. Ajustar pelo corpo visível e pelos pés, não pelo tamanho total de um PNG com transparência ou aura.
4. **Pixel art precisa de tratamento uniforme.** Preferir escala inteira e nearest para sprites do mundo. Os sprites atuais de Noct passam por redução Lanczos na ferramenta de recorte; antes de alterar esse processo, comparar o resultado com os assets existentes. Não misturar versões nítidas e borradas da mesma animação.
5. **Toda variante deve comunicar comportamento.** Um fantasma com aura ou esqueleto vestido precisa de função legível, não apenas mais vida escondida.
6. **Decoração não compete com chão e perigos.** Árvores, estátuas e fundo devem ter contraste menor que plataformas, inimigos e lava. Objetos desenhados como decoração não devem aparentar colisão quando não a possuem.
7. **Falas seguem o arco de Noct.** Comentários curtos, sarcasmo seco e sinceridade rara; pistas sobre Mira entram por ambiente e eventos, sem monólogos explicativos.

## Avaliação dos pacotes

| Pacote / grupo | Material disponível | Situação atual | Melhor aproveitamento |
|---|---|---|---|
| Noct: `assets/hero` e `art_source` | 54 PNG exportados, pranchas de movimentos, 30 retratos e atlas de combate | Moveset e retratos usados; atlas de combate não é referenciado pelo recortador atual | VFX carmesim, rastros, impacto do mergulho e portais de atalhos |
| Gothicvania Cemetery — 112 PNG | Fantasmas comuns/com aura, esqueletos vestidos e emergindo, árvores, lápides, estátua e tiles | Gato, caminhada do esqueleto e camadas do cenário usados; várias variantes e objetos livres | Cemitério mais expressivo, emboscadas anunciadas, salas laterais e guardião espectral |
| Gothicvania Swamp — 63 PNG | Aranha, fantasma, criatura `Thing`, vegetação, tiles e personagens do pacote | Aranha/fantasma e cenário usados; `Thing` não referenciado | Criatura terrestre do pântano e decoração de rotas secretas |
| Gothicvania Church — 116 PNG | Mago, anjo, duas sequências de carniçal, mortes em fogo, cenário e lutador do pacote | Mago/anjo/primeira corrida do carniçal e recortes de cenário usados | Variação de animação, mortes próprias da área e detalhes arquitetônicos |
| Gothicvania Town — 132 PNG | Quatro moradores com idle/walk, igreja, barris, caixas, casas, telhados, escadas e madeira | Moradores parados, casas e parte dos props já usados | Patrulhas curtas dos NPCs, interior/rua lateral, caixas e barris interativos |
| Gothicvania Legacy — 54 PNG | Cão com idle/walk/run/jump, olho, caveira e lava | Corrida/salto do cão, olho/caveira e cenário infernal usados | Cão alterna repouso, patrulha e perseguição sem criar nova criatura |
| Bringer of Death — 114 PNG | Animações com/sem efeitos, hurt, morte, magia e spritesheets | Chefe usa versão com efeitos; hurt carregado, mas não reproduzido no combate atual | Telegraphs claros e efeitos separados; reação visual sem cancelar todo ataque |
| Demon Slime — 60 PNG | Idle/walk/cleave/hurt/death | Chefe implementado; animação hurt carregada, mas não iniciada ao receber golpe | Reação a stagger específico, sem permitir stun lock |
| Magic Pack 9 — 50 PNG | Quatro efeitos: Dark-Bolt, Fire-bomb, Lightning e spark, em quadros e sheets | Fire-bomb/Lightning usados; `Sprites.spark()` existe sem chamadas; Dark-Bolt não usado | Ataque de inimigo arcano, projétil telegrafado, efeito de carga |
| Final — 10 PNG | Quatro camadas do título, tiles, vegetação, estátua e imagens de apresentação | Camadas usadas no título; `Tiles`, `brush` e `Salt` livres | Jardins abandonados/ruínas perto da vila, com validação de escala e contraste |
| MountainDuskGodot — 6 PNG | Sky, far/near clouds, far mountains, mountains e trees, mais uma faixa musical | Não referenciado pelos temas atuais | Rota opcional de montanha ligando vila e cemitério, com parallax |
| Sword Icons — 7 PNG | Sete folhas 192 × 160 com células usadas de 32 px | Oito amuletos usam recortes das folhas 6/7 | Selecionar ícones de relíquias com silhueta simples; limitar novos amuletos ao que o combate precisa |
| Music / sons | 11 faixas em `vendor/music`, música da vila, faixas de demos e 48 SFX RPG | Trilha principal já tem funções por área/combate/chefe | Usar sons adicionais para ações novas e manter a identidade musical existente |

As contagens por pacote são arquivos PNG, não personagens ou animações distintas. Muitas imagens são quadros individuais, atlases e exportações alternativas do mesmo conteúdo.

## Implementações recomendadas

### Prioridade 1 — acabamento e variedade nas áreas atuais

**1. Impactos, rastros e círculos carmesim de Noct.**

Fonte: `art_source/Atlas de Sprites Pixel Art_ Combate Mágico.png`, principalmente linha 6: explosões pequena/média/grande, onda de choque, coluna de energia, círculo mágico e rastros. O recortador atual não usa esse arquivo. Usar a explosão na aterrissagem do slam, um rastro curto no dash e círculo de carga na Ultimate. Primeiro recortar e limpar a arte; ela tem fundo, linhas e textos e não é uma sheet pronta para importação. Os rótulos de células da prancha não correspondem diretamente à resolução real, portanto não usar “256×256” como medida literal sem conferir.

Implementação: recortes derivados fora de `vendor`, metadados de pivô, novos métodos de animação em `Sprites` e gatilhos nos sistemas atuais. Começar com VFX sem alterar dano/custos para validar consistência. Duração curta; não esconder as hitboxes dos inimigos ou o chão durante a luta.

**2. Cemitério com lápides, árvores e estátua.**

Fonte: `CEMETERY_ENV/sliced-objects/stone-1.png` a `stone-4.png`, `tree-1.png` a `tree-3.png`, `statue.png`, `bush-small.png`, `bush-large.png`. A infraestrutura de `props` já aceita caminhos completos. Distribuir em zonas narrativas e esconder uma rota lateral atrás de composição visual, preservando a leitura do piso. Uma lápide pode iniciar uma fala curta de Noct, mas não afirmar que é de Mira sem definir a história.

Implementação pequena: dados de sala e props. Uma interação narrativa exige nó próprio; apenas desenhar a lápide não cria interação ou colisão.

**3. Esqueleto emerge antes de perseguir.**

Fonte: `ENEMIES/skeleton/skeleton-rise/` e `skeleton-rise-clothed/`, seis quadros 44 × 52; variante vestida em `skeleton/Sprites/walk-clothed/`, oito quadros. Surge em locais fixos quando Noct chega perto. Poeira/sinal no solo e animação antes de contato ofensivo evitam dano injusto. Pode substituir alguns encontros repetidos do cemitério.

Implementação: estados dormant → rise → walk no inimigo; manter proteção contra dupla recompensa; definir hurtbox e dano de contato por estado.

**4. `Thing` como criatura exclusiva do pântano.**

Fonte: `SWAMP_SPRITES/Thing/walk thing/thing1.png` a `thing4.png`, 33 × 45. Silhueta verde e apodrecida combina com a área. Recomendo perseguidor lento de chão, com resistência intermediária e recuo legível, usando a base do crawler. O pacote fornece caminhada; não há ataque de cuspe/veneno confirmado. Uma habilidade desse tipo exigiria novo efeito e sistema próprio, então não deve entrar automaticamente só pelo nome da criatura.

Implementação: animação, configuração do tipo, spawn e símbolo de mapa. Verificar colisão e centro do corpo visível.

**5. Cães infernais com repouso e patrulha.**

Fonte: `LEGACY/hell-hound/Idle/` (11 quadros) e `Walk/` (12), além de Run/Jump já usados. Idle longe do jogador, walk na patrulha e run ao perseguir. Reaproveita a IA atual com escolha de animação por comportamento. Não precisa acrescentar mais inimigos para obter variedade.

**6. Morte de inimigos por tema.**

Fonte: `ENEMIES/EnemyDeath/Sprites/` e `CHURCH_SPRITES/fx/enemy-death/enemy-death-sprites/`. Hoje a explosão azul do pântano é usada amplamente. Usar dissolução/chama apropriada nos inimigos infernais e manter azul para espectrais melhora a leitura visual. Não mudar a morte de Noct para esses sprites.

### Prioridade 2 — exploração e vida no mundo

**7. Mirante / rota de montanha opcional.**

Fonte: seis camadas em `mountainduskgodot/MountainDuskGodot/MountainsLayers/`. A paleta roxa, rosa e laranja conversa com o crepúsculo da vila. Camadas têm 240 px de altura; o viewport tem 270. Usar alinhamento inferior e completar a margem superior com cor de céu ou ajustar o canvas, evitando faixa vazia ou estiramento irregular.

Não há tileset de chão nesse pacote. Usar um conjunto de piso coerente da vila/cemitério e testar a transição de paleta. Criar ramificação e reconexão real, com amuleto/atalho como recompensa; uma nona sala apenas em sequência não resolve a linearidade.

O nome `summer nights.ogg` não basta para decidir se combina com a trilha de metal. A faixa está no catálogo para audição. Uma primeira implementação pode usar trilha já adotada, conforme a função narrativa da sala.

**8. NPCs caminhando em trechos curtos.**

Fonte: `TOWN_SPRITES/bearded-walk/` e `hat-man-walk/`, seis quadros cada; `oldman-walk/`, 12; `woman-walk/`, seis. Brom pode circular perto da oficina, Lívia pela praça e Zeno caminhar devagar. O NPC deve parar e olhar para Noct durante a conversa. Manter Brom acessível, sem patrulha que obrigue o jogador a perseguir a loja.

Implementação média: NPC atual é Node2D sem movimentação física; precisa de limites seguros definidos nos dados ou conversão para personagem com colisão. Não mover diretamente por cima de buracos/escadas só porque existe animação walk.

**9. Caixas e barris quebráveis com Geo limitado.**

Fonte: `TOWN_ENV/props-sliced/crate.png`, `crate-stack.png`, `barrel.png`. O pacote tem objeto inteiro, sem animação de destruição confirmada. Usar pedaços derivados ou partículas de madeira. Precisa de hitbox própria, separada dos inimigos, para não conceder XP/alma como criatura.

Se tiver recompensa permanente, salvar IDs dos objetos coletados. Como salas são reconstruídas ao entrar, caixas com Geo infinito criariam farming acidental. Uma opção inicial simples é decoração quebrável sem recompensa.

**10. Fantasma guardião com aura.**

Fonte: `ENEMIES/ghost/Sprites/` e `SpritesHalo/`, quatro quadros 37 × 65 por versão. Pode proteger uma lápide ou relíquia em sala lateral. A aura azul sinaliza proteção; um golpe carregado pode quebrá-la. Isso dá função ao visual e aproveita uma habilidade existente.

Implementação média: tipo próprio de voador, estados protegidos e vulneráveis e feedback claro. A aura não deve ser incluída inteira na colisão do corpo. Evitar imunidade longa que apenas estenda a luta.

**11. Dark-Bolt para um inimigo arcano.**

Fonte: `MAGIC/Dark-Bolt.png` e `sprites/Dark-Bolt/`. Roxo combina com o Bringer e a catedral. Recomendo ao mago variante ou a um encontro opcional, com aviso antes do disparo e velocidade esquivável. É mais consistente reservar esse roxo a magia inimiga; Noct mantém o carmesim.

`spark.png` é azul/branco e já tem construtor em `Sprites`, sem uso atual. Pode servir como núcleo de projétil ou indicador de carga, desde que sua cor comunique função distinta.

**12. Portais carmesim para atalhos.**

Fonte: portais e teleporte no atlas de Noct. Usar como transporte fixo desbloqueado entre bancos/áreas, depois de exploração ou chefe. Evitar teleporte livre no moveset inicialmente: muda a dificuldade e pode atravessar bloqueios de progressão.

Implementação maior: recorte/limpeza do atlas, destinos definidos, desbloqueios persistidos, atualização do schema/validação do save e transição segura. O efeito visual pronto não resolve o sistema de fast travel.

### Prioridade 3 — expansão após consolidar a campanha

- **Jardins/ruínas com Final:** `Tiles.png`, `brush.png`, `Salt.png` (estátua) e cenário do título podem sustentar sala lateral mais contemplativa. O pacote tem contraste e detalhe próprios; validar piso, escala e recoloração antes de misturar diretamente com Gothicvania. Se alterar forma/cor, revisar a nota local do autor sobre atribuição.
- **Relíquias com Sword Icons:** escolher poucos símbolos legíveis para efeitos ligados a punhos, energia, dash e foco. Os ícones são majoritariamente armas; acrescentar dezenas de amuletos só para ocupar as folhas enfraquece a identidade e o balanceamento.
- **Stagger de chefes:** Bringer e Demon Slime têm hurt carregado. Não reproduzir hurt em todo soco, pois pode cancelar ataques e permitir stun lock. Reservar para quebra de postura ou dano carregado com cooldown definido.
- **Carniçal alternativo:** segunda corrida do pacote Church pode variar postura/animação. Não anunciar novo tipo de inimigo sem conferir se a sequência diferencia comportamento de forma útil.

## Áudio adicional disponível

Dos 48 efeitos RPG, **15 não estão na tabela `Audio.SFX`**. Mapeamento sugerido pelos nomes; confirmar com audição e volume antes de usar:

| Arquivo | Aplicação coerente | Prioridade |
|---|---|---|
| `52_Dive_02.wav` | Preparação/descida do slam | Alta |
| `03_Claw_03.wav` | Ataque de cão/fera | Alta |
| `77_flesh_02.wav` | Variação moderada de impacto orgânico | Média |
| `051_use_item_01.wav` | Uso de relíquia/ação de objeto | Média |
| `39_Block_03.wav` | Aura do guardião bloqueia golpe | Média |
| `46_Poison_01.wav`, `21_Debuff_01.wav` | Futuro veneno do pântano | Baixa; sistema ainda não existe |
| `30_Revive_03.wav` | Respawn, se funcionar melhor que teleport atual | Opcional |
| `48_Speed_up_02.wav` | Ativação de bônus temporário | Baixa; não adicionar consumível só para usar som |
| `44_Sleep_01.wav` | Descanso/evento específico | Opcional; banco já tem som |
| `42_Cling_climb_03.wav` | Escalada futura | Adiar: falta animação e mecânica do Noct |
| `26_Swim_Submerged_02.wav`, `22_Water_02.wav` | Água/natação futura | Adiar: falta mecânica e animação |
| `13_Ice_explosion_01.wav` | Poder/área de gelo futura | Fora da prioridade temática atual |
| `51_Flee_02.wav` | Fuga de criatura/NPC em evento | Opcional |

A trilha em `vendor/music` já está distribuída pelas áreas e chefes. As faixas de demos e cópias da música da vila não são conteúdo novo de gameplay. Não trocar músicas automaticamente só porque estão disponíveis.

## Material que deve ficar como fonte ou referência

- Telas “Gothicvania”, “Press Enter”, “Controls” e “Thanks for playing” dos demos não pertencem à identidade NOCT.
- Arquivos Phaser, HTML, XML, TPS, PSD/ASE e previews são suporte do pacote; não carregá-los como recursos de gameplay.
- Protagonistas de Cemetery/Swamp/Church têm armas, vestimentas e cores diferentes de Noct. Suas animações não são intercambiáveis com o herói.
- Sheets “No Effect” do Bringer não representam chefe adicional; são alternativa técnica da mesma arte.
- Pranchas com títulos, grades e fundos exigem extração. Não importar diretamente como sprites do jogo.
- `Social/moon.png` e screenshots de Final são apresentações; para jogo, usar as camadas exportadas e os tiles, não screenshots com cenário completo achatado.

## Sequência prática sugerida

1. **Acabamento:** props de cemitério, morte por área, sons do slam e seleção de animações do cão. Pouco impacto em progressão/save.
2. **Variedade de encontros:** Thing e esqueletos emergindo; validar telegrafia, colisores, recompensas e dificuldade antes de espalhar pelo mapa.
3. **Identidade do Rift:** recortar VFX do atlas de Noct e aplicá-los a dash/slam/Ultimate, mantendo parâmetros de combate no primeiro passe.
4. **Exploração:** rota de montanha com ramificação, segredo e retorno; depois portais desbloqueáveis.
5. **Vida e narrativa:** NPCs móveis e eventos ambientais ligados à fenda/Mira, seguindo o guia do personagem.

Antes de novos IDs persistentes, atualizar validação do save, limites e testes. Antes de aumentar vida/atributos/amuletos, atualizar os limites atuais de GameState, que refletem o conteúdo da campanha existente.

Para qualquer implementação visual, conferir no jogo a 480 × 270: pés ancorados, ausência de fundo/grade no recorte, contraste de plataformas, timing do aviso, correspondência entre desenho e dano e comportamento na troca de sala. O catálogo apoia a seleção de arte; não substitui essa validação.
