Use o sprite sheet anexado como REFERÊNCIA VISUAL PRINCIPAL e crie novos sprites para EXATAMENTE O MESMO PERSONAGEM.

O objetivo é expandir este personagem para um moveset completo de um jogo 2D de ação / metroidvania, preservando ao máximo a identidade visual do asset original. Os sprites serão recortados AUTOMATICAMENTE por um programa, então as regras técnicas de grade abaixo são tão importantes quanto as regras artísticas.

=====================================
REGRA PRINCIPAL
=====================================

NÃO REDESENHE O PERSONAGEM.

Não altere: rosto, cabelo, expressão base, roupa, camiseta, estampa da camiseta, acessórios, corrente, botas, tatuagens, anatomia, altura, proporções, largura do tronco, comprimento das pernas, comprimento dos braços, tamanho da cabeça, silhueta, paleta principal, estilo de shading, direção de iluminação, acabamento pixel art.

O personagem precisa parecer EXATAMENTE o mesmo personagem do sprite sheet original, em TODOS os frames, de TODAS as sprite sheets.

Todos os novos sprites devem parecer criados pelo MESMO ARTISTA para o MESMO JOGO.

É melhor criar MENOS animações perfeitamente consistentes do que muitas animações com alterações visuais no personagem.

=====================================
ESPECIFICAÇÃO TÉCNICA — OBRIGATÓRIA
=====================================

Estas regras existem porque os sprites serão cortados por um programa em células de tamanho fixo. Qualquer quebra destas regras gera sprites cortados, tremidos ou com pedaços de outros frames.

-------------------------------------
A) GRADE FIXA
-------------------------------------

- A imagem é uma GRADE de células do MESMO tamanho, sem espaço entre elas.
- Cada animação ocupa UMA LINHA. Os frames vão da esquerda para a direita, na ordem em que tocam.
- Todas as linhas têm o mesmo número de colunas. Se uma animação tiver menos frames, as células que sobrarem ficam TOTALMENTE VAZIAS (transparentes).
- O tamanho da imagem deve ser exatamente: (colunas × largura da célula) por (linhas × altura da célula).
- Tamanho das células por sprite sheet:
  - Sheets 1, 3 e 5 (corpo, aéreos e especiais): célula de 256 × 256 px.
  - Sheets 2 e 4 (golpes no chão e projéteis): célula LARGA de 384 × 256 px, para caber o golpe à frente do corpo.
  - Sheet 6 (efeitos): célula de 256 × 256 px (ou 512 × 256 px para feixes e ondas longas).
- Se a ferramenta não aceitar uma imagem tão grande, gere UMA ANIMAÇÃO POR IMAGEM (uma única linha), mantendo exatamente o mesmo tamanho de célula.

-------------------------------------
B) CADA FRAME DENTRO DA SUA CÉLULA
-------------------------------------

- Personagem E efeitos de cada frame ficam 100% dentro da própria célula, com pelo menos 8 px de margem vazia nas bordas.
- NADA pode encostar, cruzar ou invadir a célula vizinha: nem pé, nem punho, nem rastro, nem brilho, nem partícula.
- NUNCA desenhar duas poses na mesma célula (ex.: pose de mergulho + pose de impacto juntas).
- NUNCA separar o personagem do efeito do mesmo frame em células diferentes (ex.: o soco numa célula e a explosão do soco na célula seguinte, sem personagem).
- Se um efeito for grande demais para caber na célula (feixe longo, onda que atravessa a tela, dragão), desenhe só o início dele junto ao personagem e coloque o efeito completo na SPRITE SHEET 6, como efeito separado.

-------------------------------------
C) ESCALA E ALINHAMENTO IDÊNTICOS
-------------------------------------

- O personagem tem SEMPRE a mesma altura: em pé e parado, mede 176 px da sola da bota ao topo do cabelo, em todas as células de todas as sheets.
- Nunca encolher nem aumentar o personagem entre frames ou entre sheets. Poses agachadas ficam mais baixas porque ele se abaixou, não porque o desenho foi reduzido.
- PONTO DE APOIO (pivô), igual em todas as células:
  - Células 256 × 256: o meio entre os pés fica em x = 128, e a sola das botas em y = 240.
  - Células largas 384 × 256: o meio entre os pés fica em x = 128 (lado esquerdo da célula, sobrando espaço à frente para o golpe), e a sola das botas em y = 240.
- Em frames no chão, as botas tocam exatamente a linha y = 240 em TODOS os frames.
- Em frames no ar, o centro do corpo continua no mesmo x do pivô; só a altura varia.
- O personagem olha SEMPRE para a DIREITA em todos os frames (o jogo espelha para a esquerda).

-------------------------------------
D) PIXEL ART DE VERDADE
-------------------------------------

- Cada pixel da arte é um bloco de exatamente 4 × 4 px na imagem, alinhado à grade de 4 px. Ou seja: o personagem de 176 px de altura tem 44 pixels de arte.
- Sem blur, sem anti-aliasing, sem gradiente suave, sem "pseudo pixel art" borrada.
- Bordas nítidas: cada pixel é totalmente opaco ou totalmente transparente. Brilhos e fumaça mágica são feitos com pixels opacos de cores mais claras, não com transparência parcial.

-------------------------------------
E) FUNDO
-------------------------------------

- Fundo 100% transparente (canal alfa = 0).
- Não usar: cor de fundo, gradiente, névoa, brilho, vinheta ou "glow" espalhado pelo fundo, xadrez desenhado, cenário, chão, sombra no chão, molduras, caixas, painéis, texto, títulos, rótulos, números ou setas.
- O brilho da magia fica SÓ em volta do efeito, dentro da célula, e não vaza para o resto da imagem.

-------------------------------------
F) JUNTO COM A IMAGEM, RESPONDER EM TEXTO
-------------------------------------

Para cada sprite sheet gerada, responder em texto (fora da imagem) com uma tabela:

| Linha | Animação | Nº de frames | Frame(s) de impacto | Loop? |

(O "frame de impacto" é o frame em que o golpe acerta. Isso é usado para programar o dano.)

=====================================
ESTILO VISUAL
=====================================

Manter:
- pixel art 2D detalhada
- estilo action platformer / metroidvania
- proporção aproximada de 1:3
- personagem relativamente alto
- visual urbano, punk, dark fantasy
- roupa predominantemente preta, cabelo escuro
- vermelho / magenta como cores de destaque
- iluminação dramática, sombras fortes, poucos pixels de highlight
- pixel art moderna inspirada em 16-bit / 32-bit evoluído

Não transformar em: ilustração anime, pintura, arte vetorial, concept art, desenho suave, 3D, pseudo-pixel art borrada.

=====================================
CONCEITO DO PERSONAGEM
=====================================

Este personagem é um LUTADOR MÁGICO.

Seu estilo de combate mistura socos, golpes físicos, combos rápidos, golpes pesados, chutes ocasionais e magia concentrada nos punhos (curta, média e longa distância), com mobilidade impulsionada por magia: dash, air dash, teleporte, pulo mágico, double jump, ataques aéreos, especiais, magia carregada e ultimate.

Identidade principal: "um lutador físico extremamente agressivo que canaliza magia através do corpo, especialmente pelos punhos."

Os socos são o foco principal. A magia complementa os golpes físicos.

=====================================
IDENTIDADE DA MAGIA
=====================================

Aparência: agressiva, sobrenatural, energética, instável, poderosa, ligeiramente caótica.

Paleta: vermelho profundo, magenta, rosa escuro, vinho, vermelho luminoso, pequenos highlights rosa claro / vermelho claro.

Os efeitos precisam combinar com os já existentes no sprite sheet de referência.

A magia deve parecer energia instável, fumaça mágica, fogo sobrenatural, partículas, faíscas, fragmentos de energia, rastros rápidos, pequenas explosões, aura pulsante, energia comprimida nos punhos, ondas de choque e formas abstratas de energia.

IMPORTANTE: NÃO usar fogo comum. A energia deve parecer MAGIA PURA / ENERGIA SOBRENATURAL.

=====================================
LEGIBILIDADE DE GAMEPLAY
=====================================

Cada ataque deve ter, quando aplicável: 1. antecipação, 2. preparação, 3. execução, 4. impacto, 5. recuperação.

O jogador deve identificar claramente quando o ataque começa, a direção, o frame de impacto, a força e a recuperação.

Os efeitos complementam o movimento sem esconder braços, mãos, pernas, torso ou a silhueta principal. A silhueta precisa continuar legível mesmo com efeitos grandes.

=====================================
DIVISÃO EM ETAPAS
=====================================

NÃO gerar uma sprite sheet gigante com tudo. Dividir em 6 sprite sheets independentes, pedidas UMA POR VEZ:

SPRITE SHEET 1 — CORPO E MOVIMENTO
SPRITE SHEET 2 — GOLPES NO CHÃO
SPRITE SHEET 3 — GOLPES AÉREOS
SPRITE SHEET 4 — PROJÉTEIS
SPRITE SHEET 5 — ESPECIAIS E REAÇÕES
SPRITE SHEET 6 — EFEITOS (VFX) SEM PERSONAGEM

Fluxo: gerar a sheet → aprovar visual, consistência E as regras técnicas → só então pedir a próxima. Não avançar automaticamente.

Em TODAS as etapas, usar de novo o sprite sheet original como referência principal e as sheets já aprovadas como referência adicional. Cada etapa HERDA: anatomia, proporções, rosto, cabelo, roupa, acessórios, corrente, botas, tatuagens, ESCALA (176 px em pé), PIVÔ, tamanho do pixel (4 × 4), paleta, shading, luz, estilo e intensidade da magia.

=====================================
SPRITE SHEET 1 — CORPO E MOVIMENTO
=====================================

Célula 256 × 256 px, 8 colunas. Sem ataques.

ROW 1 — IDLE MÁGICO (6 a 8 frames, loop)
Mesma postura relaxada do idle original, com respiração suave: a diferença entre um frame e o seguinte deve ser PEQUENA (ombros e peito sobem e descem poucos pixels). O último frame deve emendar no primeiro sem salto. Magia sutil: partículas subindo, fumaça vermelha / magenta perto das mãos, faíscas, energia pulsando nos punhos, leve aura. O personagem continua sendo o foco.

ROW 2 — CORRIDA (8 frames, loop)
Ciclo de corrida completo e contínuo, mesma altura de cabeça em todos os frames (só um leve sobe-e-desce). Pequenos rastros de energia nos pés.

ROW 3 — PULO: SUBIDA (3 frames)
Preparação, impulso (pequena explosão de magia sob os pés) e subida.

ROW 4 — PULO: TOPO E QUEDA (3 frames, o último em loop enquanto cai)
Ápice, início da queda e queda (energia leve em volta do corpo).

ROW 5 — ATERRISSAGEM (2 a 3 frames)

ROW 6 — DOUBLE JUMP (4 a 6 frames)
Explosão circular abaixo dos pés, anel mágico, partículas e novo impulso vertical. O personagem mantém o mesmo tamanho do pulo normal.

ROW 7 — DASH MÁGICO (5 a 7 frames)
Corpo inclinado para frente, forte rastro vermelho / magenta ATRÁS dele (dentro da célula), afterimage parcial, energia nos pés e nas mãos.

ROW 8 — AIR DASH (5 a 7 frames)
Versão no ar, rastro mais longo (dentro da célula).

ROW 9 — AGACHADO CONCENTRANDO (4 frames, loop)
Personagem agachado, de olhos fechados, concentrando energia nas mãos junto ao peito, com aura suave crescendo. Usado para CURAR.

=====================================
SPRITE SHEET 2 — GOLPES NO CHÃO
=====================================

Célula LARGA 384 × 256 px, 8 colunas, pivô em x = 128. O golpe se estende para a direita, dentro da célula.

ROW 1 — MAGIC JAB (4 a 5 frames)
Soco rápido: preparação curta, braço avançando, impacto (pequena explosão no punho), recuperação.

ROW 2 — MAGIC CROSS (5 a 6 frames)
Soco forte com o outro braço: rotação do tronco, transferência de peso, impacto forte, recuperação. Efeito maior que o jab.

ROW 3 — MAGIC HOOK (5 a 7 frames)
Soco lateral em arco, com arco de energia acompanhando o braço e explosão lateral no contato.

ROW 4 — MAGIC UPPERCUT NO CHÃO (6 a 8 frames)
Preparação baixa, subida do corpo, braço ascendendo, impacto, grande arco mágico vertical (dentro da célula), recuperação. Os pés só saem do chão se for intencional; o corpo não muda de tamanho.

ROW 5 — HEAVY MAGIC PUNCH / GOLPE CARREGADO (6 a 8 frames)
Energia cresce no punho, braço recua, corpo prepara o peso; no impacto: explosão forte e onda de choque À FRENTE do punho, NA MESMA CÉLULA do personagem.

ROW 6 — MAGIC FRONT KICK (5 a 7 frames)
Chute frontal com energia concentrada no pé.

ROW 7 — SPINNING MAGIC KICK (6 a 8 frames)
Giro do corpo, arco circular de energia, impacto lateral.

=====================================
SPRITE SHEET 3 — GOLPES AÉREOS
=====================================

Célula 256 × 256 px, 8 colunas. Personagem centrado no pivô x = 128; em frames no ar, o corpo fica na altura natural do movimento, sem sair da célula.

ROW 1 — AIR MAGIC PUNCH (5 a 7 frames)
ROW 2 — AIR MAGIC DOWN PUNCH (5 a 7 frames), golpe diagonal para baixo.
ROW 3 — AIR MAGIC KICK (5 a 7 frames)
ROW 4 — GROUND SLAM: MERGULHO (4 a 5 frames)
Suspenso, concentra energia, vira o corpo, mergulha e acelera para baixo. O último frame (descendo) deve funcionar em loop.
ROW 5 — GROUND SLAM: IMPACTO (4 a 5 frames)
Personagem já no chão (botas em y = 240): impacto, explosão circular, onda de choque, recuperação. A explosão do impacto fica nesta linha; a onda que corre longe pelo chão vai para a SHEET 6.
ROW 6 — RISING MAGIC UPPERCUT (6 a 8 frames)
Golpe ascendente estilo Shoryuken, com espiral de energia e trilha vertical, tudo dentro da célula.

=====================================
SPRITE SHEET 4 — PROJÉTEIS
=====================================

Célula LARGA 384 × 256 px para o personagem, 8 colunas, pivô x = 128.

ROW 1 — MAGIC PUNCH PROJECTILE: PERSONAGEM (6 a 8 frames)
Preparação, energia no punho, concentração, soco, magia se desprendendo, recuperação. O projétil sai do punho, mas NÃO é desenhado viajando nesta linha.
ROW 2 — SMALL MAGIC BLAST: PERSONAGEM (5 a 7 frames)
ROW 3 — CHARGED MAGIC BLAST: PERSONAGEM (8 frames)
ROW 4 — MAGIC BEAM: PERSONAGEM (8 frames)
Personagem posiciona as duas mãos à frente; desenhar só a origem do feixe nas mãos. O feixe completo vai para a SHEET 6.

Os PROJÉTEIS em si (punho de energia, rajada pequena, rajada carregada) vão na SHEET 6, voando para a DIREITA, cada um em sua linha, 4 a 6 frames em loop.

=====================================
SPRITE SHEET 5 — ESPECIAIS E REAÇÕES
=====================================

Célula 256 × 256 px, 8 colunas (use 2 linhas seguidas para animações com mais de 8 frames).

ROW 1 — MAGIC CHARGE (8 frames, loop)
ROW 2 — MAGIC SHIELD / PARRY (5 frames)
ROW 3 — TELEPORT: SAÍDA (4 frames), o personagem se desfaz em partículas.
ROW 4 — TELEPORT: CHEGADA (4 frames), o personagem se recompõe.
ROWS 5–6 — ULTIMATE: PERSONAGEM (12 a 16 frames)
Abaixa o corpo, energia surge, partículas são puxadas, magia envolve os braços, aura cresce, prepara e desfere o soco, recupera a postura. A explosão gigante / dragão de energia vai na SHEET 6.
ROW 7 — DANO LEVE (3 frames)
ROW 8 — DANO FORTE / KNOCKBACK (4 frames)
ROW 9 — MORTE (6 a 8 frames)
Cai e termina deitado no chão, com a cabeça na mesma altura de chão (y = 240).
ROW 10 — LEVANTAR (4 frames)

Ao receber dano, a aura enfraquece e os efeitos mágicos diminuem.

=====================================
SPRITE SHEET 6 — EFEITOS (VFX), SEM PERSONAGEM
=====================================

Nesta etapa NÃO desenhar o personagem. Célula 256 × 256 px (ou 512 × 256 px para feixes e ondas longas), cada efeito em sua linha, centralizado na célula, 3 a 8 frames.

- punch impact, heavy punch impact, kick impact
- small / medium / large magic explosion
- jump burst, double jump burst
- dash trail, air dash trail
- small projectile, medium projectile, large projectile, punch-shaped projectile (voando para a direita, em loop)
- energy beam (512 × 256, apontando para a direita, em loop de sustentação)
- shockwave, ground shockwave (512 × 256)
- teleport particles
- magic circle, aura, charging energy, magic charging orb
- parry impact, shield, shield breaking
- ULTIMATE: dragão / explosão de energia gigante (pode usar célula 1024 × 512, apontando para a direita)

=====================================
ERROS A EVITAR (vieram das tentativas anteriores)
=====================================

- Frames encostados ou se sobrepondo → pedaços de um frame aparecem no outro.
- Personagem mudando de tamanho entre frames da mesma animação.
- Duas poses na mesma célula.
- Efeito do golpe numa célula e o personagem em outra.
- Feixe ou projétil longo atravessando várias células.
- Texto, rótulos ou molduras dentro da imagem.
- Fundo com cor, névoa ou brilho espalhado.
- Pixels borrados ou meio transparentes.
- Personagem olhando para a esquerda.

=====================================
ORDEM DE PRIORIDADE FINAL
=====================================

1. CONSISTÊNCIA DO PERSONAGEM
2. REGRAS TÉCNICAS DA GRADE (tamanho de célula, pivô, escala, fundo transparente)
3. LEGIBILIDADE DAS POSES
4. QUALIDADE DA ANIMAÇÃO
5. CONSISTÊNCIA DA MAGIA
6. QUALIDADE DOS EFEITOS
7. QUANTIDADE DE FRAMES

Se precisar sacrificar algo, reduza a quantidade de frames ou efeitos. NUNCA sacrifique a identidade do personagem nem as regras da grade.

=====================================
RESULTADO ESPERADO
=====================================

Um pacote profissional de sprites para um personagem jogável de metroidvania / action platformer: um lutador mágico urbano, agressivo, rápido e estiloso, que canaliza energia sobrenatural vermelha / magenta através dos punhos e do próprio corpo, imediatamente reconhecível em TODOS os frames, com todos os frames prontos para serem cortados automaticamente numa grade fixa.
