# Novos assets — 03/10/2026

Foram encontrados cinco ZIPs na raiz: Bandits, EVil Wizard 2, Hero Knight, Garden's Forest e Free-Undead-Tileset-Top-Down-Pixel-Art. São 372 arquivos PNG/TXT inspecionados, incluindo 366 PNGs; esse número inclui prévias, versões alternativas, folhas para Tiled e um cupom promocional. Os oito novos PNGs em assets/hero/vfx são da implementação carmesim anterior, não desses pacotes.

Os ZIPs originais foram preservados. A extração para análise está em docs/assets-audit/new-packages, dentro da pasta ignorada pelo importador do Godot. Nenhum desses pacotes foi conectado ao gameplay nesta etapa.

## Melhor aproveitamento

| Pacote | Proposta para NOCT | Compatibilidade e preparação | Prioridade |
|---|---|---|---|
| Bandits | Saqueadores leves na serra e nos limites da vila; um capitão pesado guardando uma recompensa opcional | Perspectiva lateral, cores terrosas, quadros 48×48; personagem parado ocupa aproximadamente 26×38 px. Próximo da escala de Noct, cujo idle tem 44 px de altura. Já inclui idle, combat idle, corrida, ataque, recuperação, dano, salto e morte. | Alta |
| Garden's Forest | Bosque sombrio opcional ligado à vila ou ao pântano, com um encontro e pistas sobre viajantes desaparecidos | Sete imagens 512×300: quatro fundos, árvores, arbustos e folhas à frente. Azul acinzentado, troncos avermelhados e pequenos pontos vermelhos combinam com o jogo. Requer piso/colisões existentes; o pacote é cenário, não uma fase completa. | Alta |
| EVil Wizard 2 | Miniboss arcano em uma ruína lateral da catedral; guardião de um selo, sem substituir o Bringer | Duas animações de ataque, idle, corrida, dano, morte, salto e queda. Quadros 250×250, mas o idle ocupa aproximadamente 57×95 px: há bastante margem transparente. Reduzir com nearest e alinhar pelos pés. Manter maior que Noct, distinguindo-o dos magos comuns. | Média/alta |
| Hero Knight | Cavaleiro errante, vigia ou rival opcional; diálogo inicial e duelo com golpes de espada | Perspectiva lateral, tons frios de armadura; idle ocupa cerca de 47×51 px em quadros 180×180. Pode permanecer um pouco mais alto que Noct. Possui dois ataques, corrida, dano, morte, salto e queda; não há escudo/defesa separado no ZIP. | Média |
| Undead Top Down | Ossos, pilhas de crânios, lápides selecionadas, cristais, portas de crânio e detalhes em ruínas | Paleta mais clara e desenho visto de cima. Objetos precisam ser escolhidos individualmente, com sombra e perspectiva verificadas no cenário lateral. Pisos, água e costas não encaixam diretamente no atual mundo de plataformas. | Seletiva |

## Encontros sugeridos

**Saqueador leve:** patrulha, percebe Noct, aproxima-se e prepara um único corte. Mostrar preparação antes da hitbox de espada; permitir punição durante recuperação. Isso acrescenta uma leitura de combate diferente dos crawlers que hoje causam dano por contato. O arquivo de ataque possui oito quadros; mapear a hitbox aos quadros ativos após inspeção em movimento.

**Capitão pesado:** encontro único no caminho da serra. Mais resistente, golpe mais lento e recuperação maior; pode guardar Geo ou um segredo. Sua presença precisa de motivo narrativo: sobreviventes saqueando viajantes, em vez de humanos hostis espalhados sem contexto pela vila.

**Bosque:** usar as camadas com parallax e preservar a leitura das plataformas. Folhas à frente devem ser limitadas para não esconder inimigos ou sinais de emboscada. A composição de prévia em new-packages/forest.png confirma que o conjunto tem uma atmosfera mais fechada que o pântano. Um acampamento de saqueadores daria propósito à área.

**Mago:** alternar duas preparações e ataques, com janela vulnerável. O pacote não traz uma folha separada de projéteis; magias à distância podem reutilizar efeitos já existentes, se necessárias. Sua corrupção deve aparecer na arena, nas falas e nos padrões, preservando o carmesim como assinatura de Noct.

**Cavaleiro:** primeiro acessível como personagem de diálogo. Pode defender uma passagem opcional ou desafiar Noct; duas animações de ataque sustentam um duelo simples. Não prometer parry, escudo ou ataque à distância como conteúdo pronto desses sprites: seriam sistemas novos.

**Undead:** os objetos separados incluem 51 variantes de lápides, 54 de ossos, 12 de cristais, 15 de ruínas, três portas de crânio e outras variantes. Muitos são versões com sombras diferentes, não objetos distintos. Árvores e estruturas grandes deixam evidente a visão de cima; os elementos pequenos são os candidatos mais seguros. As seis folhas Animation são animações de objetos/ambientação, não um conjunto de inimigos andando e atacando em visão lateral.

## Integração técnica

- Bandits começa os arquivos em **0**; o helper add_anim atual começa em 1. É necessário um helper com índice inicial configurável, sem perder o primeiro quadro.
- Wizard e Knight são folhas horizontais; add_sheet já atende aos recortes. Wizard usa células 250×250; Knight, 180×180. O tamanho da folha não é o tamanho do personagem ou da hitbox.
- Os novos humanoides merecem máquina de estados própria: patrulha, alerta, preparação, golpe, recuperação, dano e morte. Reutilizar crawler sem essas fases desperdiçaria suas animações.
- Forest pode usar o sistema de temas/backdrop atual. Manter a escala dos tiles, a filtragem nearest e sinais carmesim visíveis.
- Importar apenas as imagens utilizadas e os arquivos de licença para assets/vendor; folhas redundantes, prévias e COUPON.png não precisam entrar no jogo.

## Licenças encontradas no próprio pacote

Wizard e Knight contêm declaração CC0. Bandits contém EULA de Sven Thole, com uso em projetos comerciais/não comerciais e menção a crédito; conservar o arquivo e adicionar autoria aos créditos na integração. Undead aponta para craftpix.net/file-licenses, sem reproduzir os termos no ZIP. Garden's Forest não trouxe arquivo de licença; sua origem ainda não está identificada nesta análise. Esta etapa não verificou condições externas de distribuição.

## Ordem recomendada

1. Saqueador leve e capitão pesado na serra: maior ganho imediato de variedade no combate.
2. Bosque opcional com acampamento: aproveita as sete camadas e os encontros novos.
3. Mago em ruína opcional: encontro mais elaborado com recompensa própria.
4. Cavaleiro com diálogo e duelo: requer definir seu papel na história.
5. Pequenos objetos Undead aprovados em teste visual: enriquecer cemitério e ruínas sem misturar perspectivas indiscriminadamente.

Ferramenta reproduzível: tools/audit_new_assets.ps1. Inventário e três folhas de contato: docs/assets-audit/new-packages/.
