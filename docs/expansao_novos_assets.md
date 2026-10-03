# Bosque e encontros opcionais

Os cinco pacotes adicionados à raiz foram integrados ao jogo. Os ZIPs originais permanecem intactos. A instalação reproduzível está em `tools/install_new_assets.ps1`; apenas imagens de gameplay e textos de licença/instruções foram copiados para `assets/vendor`.

## Rotas

- **Vila → Bosque dos Desgarrados:** use a fenda perto da carroça, a leste. O bosque tem banco, acampamento, duas pequenas travessias sobre espinhos e uma trilha superior.
- **Bosque → Pântano:** siga pela extremidade direita ou use a passagem a leste. O caminho principal da vila ao pântano continua disponível.
- **Bosque ↔ Serra:** passagem no trecho leste do bosque; retorno pela fenda no início da serra.
- **Catedral ↔ Ruína do Selo Vazio:** porta marcada por um crânio na plataforma superior leste da catedral. A ruína tem seu próprio banco e uma saída de retorno; não permite saltar o Bringer ou outros chefes.

## Combate

| Encontro | Vida | Recompensa | Comportamento |
|---|---:|---:|---|
| Saqueador leve | 5 | 10 Geo | Patrulha, aproximação, aviso de 0,5 s, espada e recuperação. Pode ser interrompido por golpes. |
| Saqueador pesado | 9 | 18 Geo | Mais lento; preparação de 0,8 s e recuperação maior. Resiste à interrupção durante a preparação/ataque. |
| Capitão dos Desgarrados | 18 | 80 Geo | Encontro único na serra, com barra de vida e alcance maior. |
| Vigia Errante | 20 | 90 Geo | Cavaleiro pacífico na plataforma superior do bosque. Converse, feche o diálogo e interaja novamente para aceitar o duelo. A vitória o poupa e libera novas falas. O duelo pode ser ignorado. |
| Custódio do Selo | 28 | 120 Geo | Mago da ruína. Alterna golpe próximo e dois selos no chão; cada selo avisa por 0,75 s antes do raio e pode ser desfeito com um golpe durante o aviso. |

Humanoides usam hitboxes de espada apenas nos momentos ativos do ataque; o corpo pode receber golpes, mas não causa dano por contato. Avisos mostram preparação e direção. Recuperação abre oportunidade para contra-ataques. Salvar guarda vitórias únicas, não a vida parcial de uma luta.

## Exploração e narrativa

O esconderijo na trilha superior do bosque entrega **45 Geo** e uma pista sobre viajantes levados ao Custódio. Depois de derrotar o mago, o arquivo sob a porta de crânio entrega **60 Geo** e uma pista sobre a resposta da energia carmesim à ausência. Falas de Noct seguem o guia de personalidade; Mira e a origem do Rift continuam sem uma explicação definitiva.

O bosque usa as quatro camadas de fundo do Garden's Forest, árvores e arbustos no mundo e folhas com parallax à frente, sob a interface. Os objetos Undead escolhidos foram recortados pela região visível, alinhados ao chão, reduzidos e tingidos; os pisos top-down não foram usados como plataformas. Ossos e cristais entram no bosque, ruínas/crânios/porta no santuário do mago, e lápide/crânios no cemitério.

Vitórias do capitão, mago e cavaleiro, além dos tesouros, persistem **ao descansar em um banco**. Saves anteriores sem essas descobertas continuam válidos. Cavaleiro poupado reaparece como personagem de diálogo; capitão e mago derrotados não reaparecem.

## Verificação

`tests/new_assets_test.gd` cobre os novos personagens, animações, preparação/dano/recuperação, selos, recompensas únicas, estado pacífico do cavaleiro, conexões, recortes e checkpoint. Saves de teste são isolados do save do jogador. Com `-- --screenshots`, gera prévias em `docs/content-preview/`.

Também foram executados os testes anteriores de smoke, regressão e conteúdo. A documentação dos arquivos originais e créditos está em `CREDITOS.md` e `docs/analise_novos_assets.md`. Garden's Forest chegou sem autoria/licença no ZIP; isso está registrado nos créditos, sem inventar uma licença.

Resultado final: **220 verificações passaram** (66 smoke, 30 regressão, 46 conteúdo anterior e 78 novos assets), sem erros ou avisos de recursos na execução headless. As prévias renderizadas de bosque, capitão, cavaleiro e mago foram inspecionadas para conferir escala, transparência, alinhamento e leitura dos avisos.

Valores de vida, alcance e recompensas são o primeiro balanceamento, a refinar após jogar os encontros.
