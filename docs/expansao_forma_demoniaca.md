# Expansão: O Lago Velado — cenários, inimigos, Velário e a Forma Demoníaca

> Documento de design. Tudo aqui segue a bíblia do personagem (`docs/noct_personalidade.md`) e o que
> já existe no jogo. Onde algo já está implementado, o texto diz. A ordem de implementação está no fim.

## Visão geral

Depois do Bringer, Noct ganha o Passo da Fenda e consegue atravessar paredes carmesim. Atrás de uma
delas, no Santuário do Ceifador, existe um caminho que ninguém fez: desce até o **Lago Velado**, onde a
própria Fenda guardou a lembrança que Noct escolheu esquecer. Quem guarda é o **Velário**, e ele não é
um inimigo comum: é a parte de Noct que preferia não lembrar.

Derrotar o Velário libera a 9ª memória de Mira, **"Continua andando"**, e com ela a **Forma Demoníaca
Nível 1 (Juramento)**: a primeira vez em que o carmesim deixa de ser surto e vira escolha.

Fase do arco (bíblia): **4 Queda → 5 Revelação**. O tom do Lago é o mais silencioso do jogo até aqui.

Fluxo no mundo:

```
Vila ─ Pântano ─ Cemitério ─ Covil ─ Catedral ─ Santuário ─ Inferno ─ Trono
                                                   │ (parede carmesim, Passo da Fenda)
                                          Margem das Folhas Paradas
                                                   │
                                            Lago Velado (arena do Velário)
                                                   │ (depois da Forma Nível 1)
                                            Coração da Fenda
```

Os outros cenários novos são laterais, ligados a áreas que já existem.

---

## 1. Cenários

### 1.1 Clareira das Folhas Paradas (Bosque das Lembranças Perdidas)

- **Onde:** saída leste do Bosque dos Desgarrados, por uma trilha que só aparece depois do Bringer.
- **Conceito visual:** o mesmo bosque, mais fundo. Árvores retorcidas e sem folhas, troncos ocos, névoa
  baixa até a altura do joelho. As folhas caem devagar demais e, perto das memórias, **param no ar**.
  Brilho carmesim sutil nas raízes que atravessam o caminho.
- **Atmosfera:** silêncio quase total, só vento e um galho estalando longe. É o primeiro lugar do jogo
  em que a música de exploração some.
- **Propósito narrativo:** o lugar em que Noct e Mira caminhavam em silêncio. Ele não diz isso; o jogador
  percebe por uma inscrição numa árvore: duas iniciais, uma riscada e reescrita.
- **Inimigos:** Rastejo-cinza, Lamento, Lobo de névoa.
- **Perigos:** raízes carmesim que pulsam e machucam a cada 2 s; troncos que caem quando o Noct passa
  embaixo (sombra no chão avisa).
- **Exploração:** árvore oca com 50 Geo; tronco caído que vira ponte com o dash.
- **Segredo:** atrás de uma cortina de folhas paradas (só atravessa se o Noct ficar parado 3 s, e as folhas
  voltam a cair), um amuleto: **Folha que Não Cai**.
- **Reforça a história:** iniciais na árvore; folhas que só se movem quando ele para, como se o lugar
  esperasse que ele ficasse.

### 1.2 Pedravelha do Eco (Vila em Ruínas)

- **Onde:** o reflexo da vila, alcançado pelo fundo do Poço de Pedravelha depois da Forma Nível 1.
- **Conceito visual:** a vila de Pedravelha invertida, vazia e destruída. Casas penduradas no teto,
  telhados rachados, postes quebrados de cabeça para baixo, tecidos rasgados balançando num vento que
  sobe. Cores frias, quase cinza; só as janelas têm um resto de luz carmesim.
- **Atmosfera:** os moradores existem como **silhuetas** que repetem a última frase que disseram na vila
  de verdade. Nenhuma reage ao Noct.
- **Propósito narrativo:** mostrar o que a vila vira quando ele vai embora: não um lugar destruído pela
  guerra, mas um lugar de que ninguém lembra. É onde fica o Chamador (ideia anterior, `areas_novas.md`).
- **Inimigos:** Desbotado, Miragem, Sino fendido.
- **Perigos:** gravidade invertida em trechos marcados por tecido carmesim; telhas que caem para cima.
- **Exploração:** a casa do meio (a do banco) existe aqui, mas o banco está vazio dos dois lados.
- **Segredo:** a silhueta da Tessa não está aqui. No lugar dela, a manta pendurada. Interagir dá uma
  fala de Noct e a nota "Ela não é um eco."
- **Reforça a história:** o banco vazio dos dois lados é a primeira vez que o jogador vê o lugar dele
  vazio também.

### 1.3 Capela da Vigília (Santuário Abandonado)

- **Onde:** lateral da Catedral Profanada, porta lacrada que abre depois do Velário.
- **Conceito visual:** capela gótica pequena. Vitrais quebrados que ainda projetam cor no chão, altar
  partido ao meio, estátuas de santos sem rosto (os rostos foram raspados), centenas de velas apagadas.
  Uma única vela acesa, sempre na mesma fileira.
- **Atmosfera:** eco longo, passos alto demais. Sagrado corrompido, sem demônios à vista.
- **Propósito narrativo:** onde Mira acendia velas "para quem ninguém lembra". A vela acesa é dela.
- **Inimigos:** Penitente acorrentado, Arqueira de vela, Acendedor carmesim.
- **Perigos:** cera derretida no chão (escorrega), vitrais que caem quando o boss da sala toca a parede.
- **Exploração:** confessionário com uma inscrição que só faz sentido depois da 9ª memória.
- **Segredo:** apagar a vela dela (atacar) abre uma passagem; acender de novo (interagir) fecha. Noct
  só consegue apagar se a Forma estiver ativa, e a fala é a mais seca do jogo: "Hm."
- **Reforça a história:** a escolha de apagar a vela é pequena e desconfortável de propósito.

### 1.4 Penhasco da Chuva Eterna

- **Onde:** continuação da Estação, seguindo os trilhos até onde eles acabam no abismo.
- **Conceito visual:** ruínas de uma estação de montanha no topo de penhascos, céu fechado, chuva fina
  constante, vento forte. Trilhos retorcidos pendurados no vazio, cabos de bonde partidos.
- **Atmosfera:** contemplativa e trágica. Dá para ver o mundo inteiro lá embaixo, pequeno.
- **Propósito narrativo:** para onde o trem ia. A pergunta "para onde ela foi naquela manhã" ganha um
  lugar físico, sem resposta.
- **Inimigos:** Lobo de névoa, Arqueira de vela, Faminto da Fenda.
- **Perigos:** rajadas de vento que empurram o Noct (indicadas pela chuva mudando de ângulo), plataformas
  de trilho que balançam.
- **Exploração:** cabine do maquinista com o último horário escrito à mão.
- **Segredo:** pulando do fim dos trilhos com a Forma ativa, o dash aéreo carmesim alcança uma
  plataforma invisível com um banco. O banco tem dois lugares, e a chuva não molha o da esquerda.
- **Reforça a história:** o lugar seco no banco é o único sinal "sobrenatural" gentil do jogo.

### 1.5 Lago Velado (Lago das Memórias) — área do boss

- **Onde:** atrás da parede carmesim do Santuário do Ceifador. Duas salas: **Margem das Folhas Paradas**
  (descida) e **Lago Velado** (arena).
- **Conceito visual:** água preta e parada que reflete tudo errado: o reflexo do Noct chega meio segundo
  atrasado, e às vezes tem alguém sentado ao lado dele no reflexo. Plantas mortas, juncos secos, véus de
  pano preso nos galhos como num funeral. Névoa densa, carmesim só nas bordas da água.
- **Atmosfera:** desconfortável. Algo observa (o Velário fica visível ao fundo, imóvel, durante a descida).
- **Propósito narrativo:** onde a Fenda guarda o que Noct se recusa a lembrar.
- **Inimigos (descida):** Lamento, Miragem, Sanguessuga de alma.
- **Perigos:** água funda que puxa para baixo devagar (fica preso se parar), reflexos que viram mãos.
- **Exploração:** véus com nomes bordados de coisas esquecidas ("o cheiro do café", "a música da festa").
- **Segredo:** um véu sem nome. Interagir: "* Noct não toca."
- **Reforça a história:** é aqui que Noct vê o lugar ao lado dele ocupado pela primeira vez, só no reflexo.

### 1.6 Coração da Fenda (Ruínas Carmesim)

- **Onde:** depois do Lago, só alcançável com a Forma Demoníaca (cristais quebram com o dash carmesim).
- **Conceito visual:** onde a energia do Crimson Rift é mais forte. Cristais carmesim crescendo das paredes,
  rachaduras no chão soltando luz, arquitetura dobrada como se tivesse derretido para dentro.
- **Atmosfera:** sobrenatural e pulsante; o fundo bate como um coração lento.
- **Propósito narrativo:** prepara a revelação do Trono do Demônio. Inscrições em pedra, na letra de Mira,
  falando de "uma porta que chama".
- **Inimigos:** Acendedor carmesim, Faminto da Fenda, Sino fendido, Carapaça de lápide.
- **Perigos:** rachaduras que explodem em sequência; cristais que refletem projéteis.
- **Exploração:** atalho de volta ao Inferno.
- **Segredo:** sala onde a Forma não termina enquanto o Noct estiver dentro dela, e ele começa a perder
  vida devagar. Um aviso do que o Nível 3 será.
- **Reforça a história:** "sofrer funciona" vira lugar físico.

---

## 2. Inimigos

Notação: PV em golpes do Noct sem bônus (dano 1), Geo ao morrer. XP = 2 × Geo (regra atual).

### Básicos

| Nome | Visual | Comportamento | Ataque | Dificuldade | Função | Fraqueza |
|---|---|---|---|---|---|---|
| **Rastejo-cinza** | bicho do tamanho de um gato, feito de cinza de lareira, olhos de brasa | anda em bando de 3, foge quando um morre | mordida rápida | baixa (2 PV, 3 Geo) | encher espaço, ensinar a usar o combo | morre com um golpe carregado em área |
| **Desbotado** | morador da vila sem cor, rosto liso | anda devagar até o Noct, para e "lembra" (treme) antes de atacar | agarrão que prende 1 s | baixa (4 PV, 5 Geo) | humanoide corrompido; peso emocional | o tremor é a janela de ataque |
| **Lobo de névoa** | lobo magro feito de névoa, só a mandíbula sólida | circula fora do alcance e investe | investida em linha | média-baixa (5 PV, 7 Geo) | besta sombria, pune quem fica parado | some 0,3 s antes de investir: o dash atravessa |
| **Lamento** | espectro pequeno de pano rasgado | flutua em seno, chora (som) quando o Noct se aproxima | toque frio | baixa (3 PV, 4 Geo) | espectro fraco; sinaliza memórias próximas | morre com magia |

### Intermediários

| Nome | Visual | Comportamento | Ataque | Dificuldade | Função | Fraqueza |
|---|---|---|---|---|---|---|
| **Penitente acorrentado** | guerreiro de armadura quebrada, corrente presa ao próprio pescoço | patrulha; ao ver o Noct, gira a corrente | corrente em arco (alcance 3 blocos) e golpe de chão | média (12 PV, 18 Geo) | guerreiro corrompido; testa distância | a corrente prende numa parede se errar |
| **Arqueira de vela** | espectro com arco de cera, flecha acesa | fica no alto, recua se o Noct sobe | 3 flechas em leque; flecha acesa deixa fogo no chão | média (8 PV, 15 Geo) | arqueiro espectral; controle de área | a vela no arco apaga com magia e ela fica sem flechas 4 s |
| **Acendedor carmesim** | sacristão encurvado com turíbulo de energia carmesim | mantém distância, teleporta curto | esferas carmesim que perseguem devagar | média (10 PV, 20 Geo) | conjurador | interromper o canto (2 golpes) cancela a esfera |
| **Carapaça de lápide** | criatura com uma lápide inteira como casco | avança devagar, imune de frente | esmaga ao virar | média-alta (16 PV, 22 Geo) | blindada; ensina a pular por cima | só leva dano pelas costas ou com golpe para baixo |
| **Procissão** | quatro figuras encapuzadas carregando um andor vazio | parada; quando o Noct entra na linha, dispara | investida longa que atravessa a sala | média (14 PV, 20 Geo) | monstro de investida | bate na parede e fica atordoado 2 s |

### Especiais

| Nome | Visual | Comportamento | Ataque | Dificuldade | Função | Fraqueza |
|---|---|---|---|---|---|---|
| **Miragem** | silhueta de alguém que o Noct conhece de longe, sempre de costas | teleporta, deixa 2 cópias falsas | a verdadeira ataca por trás | média-alta (9 PV, 24 Geo) | ilusões e memória | a verdadeira é a única com reflexo na água |
| **Sino fendido** | sino de igreja rachado com pernas de ferro | fica num ponto e toca | onda de som em área (círculo que cresce) | média (12 PV, 20 Geo) | ataque em área, controla posição | dentro da rachadura (golpe de cima) leva dano dobrado |
| **Sanguessuga de alma** | bolsa translúcida presa no teto, cheia de luz azul roubada | desce quando o Noct passa embaixo | gruda e drena 11 de alma por segundo | média (6 PV, 18 Geo) | dreno de energia; pune ficar sem se mexer | soltar com dash; a alma roubada volta ao matar |
| **Faminto da Fenda** | cão sem pele com cristais carmesim nas costas | dorme; **acorda quando o Noct usa a Forma** e o persegue | mordida que rouba barra da Fenda | alta (15 PV, 30 Geo) | reage à energia demoníaca | com a Forma desligada, foge e se esconde |

---

## 3. Boss: Velário, o Carcereiro das Lembranças

### Conceito e lore

Quando Mira morreu, a dor era grande demais para caber em Noct. A Fenda, que se alimenta de dor, fez com
a parte dele que se recusava a lembrar um **carcereiro**. Ele pegou a última lembrança, a mais pesada, e a
trancou no fundo do Lago Velado. O nome vem do véu de funeral que ele usa: **Velário**.

Ele não é cruel. Acredita sinceramente que está protegendo o Noct. Cada golpe dele é um "não olha".
Ao contrário do Bringer, que usa os medos dos outros, o Velário **é** um medo do Noct.

Significado: **resistir à verdade**. Vencer o Velário não é destruir o medo; é aceitar a dor de lembrar.

### Arena: Lago Velado

Uma faixa larga de chão de pedra sobre água preta, com duas plataformas laterais baixas e uma alta no
centro. Véus pendurados no alto. Ao fundo, centenas de lanternas apagadas boiando.
- **Fase 1:** água parada, chão firme, névoa baixa. Reflexos atrasados.
- **Fase 2:** o lago sobe 1 bloco nas bordas (água rasa, só visual), as lanternas acendem em carmesim, os
  véus pegam fogo de baixo para cima.

### Fase 1: o Carcereiro

- **Aparência:** alto (cerca de duas vezes o Noct), armadura de carcereiro gasta, coberta por um véu preto
  longo que esconde o rosto e arrasta no chão. Na mão esquerda, uma **lanterna-gaiola** com uma linha de
  luz carmesim presa dentro (a memória). Na direita, uma **chave-lâmina** do tamanho de uma espada. Molho
  de chaves na cintura que tilinta a cada passo.
- **Postura:** contida, defensiva. Anda pouco, protege a lanterna com o corpo. Nunca corre.
- **Ataques:**
  1. **Golpe da chave:** ergue a chave-lâmina (aviso de 0,6 s) e desce em arco na frente. Dano 1.
  2. **Tranca:** crava a chave no chão; correntes correm pelo chão nos dois sentidos. Pula para desviar.
  3. **Véu:** gira o véu e some na névoa; reaparece do outro lado do Noct com um golpe da chave.
  4. **Esquecer:** ergue a lanterna, a tela escurece por 1,5 s e só a luz da lanterna aparece. Durante
     o escuro, duas mãos de sombra surgem do chão onde o Noct estava (igual às mãos do Bringer, mais lentas).
- **Fala ao acordar:**
  - Velário: "Volta. Aqui embaixo não tem nada seu."
  - Noct: "@desconfiado: Engraçado. Parece meu."

### Transição (50% da vida)

O Noct acerta a lanterna por acidente. Ela racha. O Velário cai de joelhos, abraça a lanterna.
- Velário: "Você não quer lembrar. Eu sou a prova."
- Noct: "@serio: ..."
O véu rasga sozinho, de baixo para cima. A tela pisca carmesim, a água sobe, a música troca.

### Fase 2: o Despido

- **Aparência:** sem armadura e sem véu, ele é um amontoado de véus vivos e correntes, mais largo, curvado
  para a frente, com vários braços de pano. No lugar do rosto, um **espelho** que reflete o Noct. A lanterna
  rachada agora está fundida no peito, e a luz carmesim vaza pelas rachaduras.
- **Postura:** desesperada. Não protege mais nada; ataca para não ser olhado.
- **Ataques:**
  1. **Golpe duplo da chave:** dois arcos seguidos, o segundo avança.
  2. **Corrente varredora:** uma corrente atravessa a arena inteira na altura do chão; depois, uma na altura
     do pulo. Exige pulo e depois dash/agachar.
  3. **Chuva de gaiolas:** gaiolas caem do alto em 5 pontos marcados por sombras (ataque em área).
  4. **Maré carmesim:** bate no chão e uma onda carmesim corre pelo chão em direção ao Noct.
  5. **Salto do carcereiro:** pula até a posição do Noct e cai com onda de choque.
  6. **Desespero (abaixo de 20%):** "Não olha." A tela fica quase preta, só os olhos carmesim do Noct e a luz do
     peito do Velário aparecem por 3 s, enquanto ele ataca mais rápido.
- **Provocações durante a fase 2 (balões, sem pausar):**
  - "Ela pediu uma coisa. Você vai odiar lembrar o quê."
  - "Eu guardei para você não ter que carregar."
  - "Se você lembrar, vai ter que cumprir."
  - Noct (uma vez): "@furioso: Me devolve."

### Narrativa da luta e trilha emocional

Começa com desconfiança e ironia (Noct ainda acha que é mais um guardião). Na transição, ele percebe que o
inimigo protege a lanterna como ele protege a fita. Na fase 2, o sarcasmo some. A última fala dele antes do
golpe final é "Me devolve.", sem ironia nenhuma.

Música: fase 1 com a faixa ambiente sombria (`Ambient4`), fase 2 com a de chefe (`Revenge's Waiting`).

### Derrota

O Velário não explode nem morre de forma violenta. Ele se ajoelha, olha a lanterna no peito e a abre com as
próprias mãos.
- Velário: "Então lembra. E não diz que eu não avisei."
A luz carmesim sai, vira uma fita, e se enrola no pulso do Noct por cima da fita de Mira.

---

## 4. Evento pós-boss: a lembrança "Continua andando"

A tela escurece até só sobrar a chuva. Narração em caixa (linhas com `* `), sem música.

> * A última noite. Chuva no telhado.
> * Mira estava acordada. Ele fingia que não.
> "Promete uma coisa."
> "@cansado: Depende."
> "Se eu demorar pra voltar... você continua andando."
> "@sarcastico: Andar eu já sei."
> "Não. Continua. Come, dorme, briga com alguém. Vive um dia de cada vez."
> * Ele não respondeu. Ela esperou.
> "E outra. Se um dia você ouvir uma porta chamando... não abre com raiva."
> "Raiva abre tudo. Abre lembrando de mim."
> "@olhar_baixo: ...Prometo."
> * A mão dele não foi até a sobrancelha.
> "Não coçou." Ela sorriu. "Tá vendo? Você consegue."

Volta ao Lago. O Noct de joelhos, a mão na fita.
> "@fechando_olhos: Eu prometi."
> * A energia carmesim sobe. Dessa vez, ele não deixa ela tomar conta.
> "@magia_olhos: Lembrando de você, então."

**Impacto emocional:** a memória mostra que Mira sabia que podia não voltar e se preocupou com ele, não com
ela. Revela que a única promessa de verdade que ele fez foi continuar vivendo, e ele acha que vem quebrando
essa promessa desde então. É a contradição central da bíblia ("acredita que desistiu, continua andando")
dita pela boca dela.

**Pista sobre a Fenda:** "uma porta chamando" e "não abre com raiva" preparam a revelação do Trono (Mira
ouvia a fenda e a fechou). Também explica o sistema: o poder controlado vem da memória, o poder
descontrolado vem da raiva.

**Consequência:** a memória entra como 9ª na aba Memórias (`the_promise`), e o Noct desbloqueia a Forma
Demoníaca Nível 1. Faixa na tela: "FORMA DEMONÍACA · NÍVEL 1: JURAMENTO".

---

## 5. Sistema de transformação

### Conceito

A Forma Demoníaca é o carmesim canalizado conscientemente. Cada nível é o Noct aceitando um pouco mais da
Fenda e se reconhecendo um pouco menos.
- **Nível 1, Juramento:** o poder aberto "lembrando de mim". Controlado, contido, ainda o Noct.

### Barra da Fenda (recurso)

- Barra própria, separada da alma (alma continua sendo magia e cura).
- Aparece no HUD como um **anel carmesim fino em volta da órbita de alma**, enchendo no sentido horário.
  Quando cheia, o anel pulsa e o rosto do Noct no HUD ganha os olhos carmesim.
- **Enche:** +3 por golpe que acerta, +12 por dano recebido, +6 por magia que acerta. Máximo 100.
- **Não enche** durante a Forma, nem durante a Ressaca.
- Esvazia devagar fora de combate (−2 por segundo depois de 6 s sem lutar), para a Forma ser uma
  decisão de luta e não algo que se guarda para sempre.

### Ativação

- Tecla **R** no teclado; **analógico direito apertado** (R3) no controle.
- Só com a barra cheia e a Forma desbloqueada.
- **Animação de transformação de 0,6 s:** o Noct se curva, a aura explode para fora, onda de choque que
  empurra inimigos próximos e causa 2 de dano. Invulnerável durante a animação.

### Duração

- **12 segundos** de base. A barra esvazia durante a Forma (aparece drenando no anel).
- Cada inimigo que morre durante a Forma devolve **+1,5 s** (no máximo até a barra cheia).
- **Pode ser cancelada** apertando de novo (sai sem Ressaca se ainda tiver mais da metade da barra).
- Termina sozinha quando a barra zera.

### Vantagens (Nível 1)

- **Dano corpo a corpo +1** em todos os golpes (soco, combo, aéreos, carregado, uppercut).
- **Velocidade +15%** no chão.
- **Dash carmesim:** o dash causa 1 de dano em quem atravessa e quebra cristais carmesim.
- **Corte carmesim:** o último golpe do combo no chão e o finalizador aéreo soltam uma lâmina carmesim
  curta (2 de dano, alcance de 5 blocos).
- **Alma +50%** por golpe (a raiva alimenta).

### Riscos e limitações

- **Sem cura:** enquanto a Forma está ativa, segurar a magia não cura. Ele não consegue se acalmar.
- **Ressaca:** ao fim (não cancelada), 2,5 s em que o Noct anda 25% mais devagar, não ganha alma e a aura
  falha. É a janela de vulnerabilidade.
- **Inimigos que reagem:** o Faminto da Fenda acorda e persegue quando a Forma é ativada.
- **Narrativo:** a cada uso a fala muda. As primeiras vezes são contidas; depois de muitas, o Noct começa a
  falar como no Bringer ("Então engole."), um aviso do que o Nível 2 vai ser.

### Visual do Nível 1

Uma camada por cima do sprite atual do Noct, sem redesenhá-lo:
- **Aura carmesim** ao redor do corpo, com chamas curtas subindo em ritmo de respiração.
- **Um chifre de aura** só do lado esquerdo da cabeça, translúcido, que acompanha a cabeça em todas as poses.
- **Olhos carmesim** brilhando (um ponto de luz no rosto, visível mesmo no escuro).
- **Fagulhas** saindo das mãos e dos pés em cada golpe.
- **Leve tom carmesim** no sprite inteiro.
- Na Ressaca, a aura falha e pisca como uma lâmpada morrendo.

### Progressão futura (só o Nível 1 é liberado agora)

| Nível | Nome | Visual | Ganha | Custo | Quando |
|---|---|---|---|---|---|
| 1 | **Juramento** | aura, um chifre de aura, olhos carmesim | +1 dano, velocidade, dash e corte carmesim | sem cura, Ressaca | derrotar o Velário |
| 2 | **Ruptura** | dois chifres sólidos, cauda de energia, fagulhas pretas | +2 dano, pulo triplo, magia vira carmesim perfurante | barra drena 2× mais rápido; ao fim, perde 1 de vida | depois da revelação no Trono do Demônio |
| 3 | **Consumido** | chifres e asas de energia, rosto escurecido, só os olhos | dano enorme, golpes encadeiam sozinhos | o jogador perde parte do controle (golpes extras involuntários); perde vida enquanto ativa | só no final "Ficar na fenda" (ou num modo pós-jogo) |

A estrutura no código já prevê os níveis (`demon_level`), mas só o 1 pode ser desbloqueado.

---

## 6. Ordem de implementação

1. **Forma Demoníaca Nível 1:** barra da Fenda, ativação, duração, vantagens, riscos, HUD e a camada visual
   (aura, chifre, olhos). Liberada pelo menu de hacks (F1) para testar antes do boss existir.
2. **Velário e o Lago Velado:** sprites do boss feitos no Aseprite (fase 1, transição, fase 2, morte), arena,
   a parede carmesim no Santuário, a lembrança e o desbloqueio.
3. **Inimigos novos**, começando pelos que o Lago usa (Lamento, Miragem, Sanguessuga de alma).
4. **Cenários laterais** (Clareira, Capela, Penhasco, Pedravelha do Eco, Coração da Fenda), um por vez.
