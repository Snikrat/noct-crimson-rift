# Glossário de personagens — Noct Crimson Rift

> A história de cada personagem do jogo, montada **só com o que já existe** no repositório: falas,
> memórias, inscrições, chefes e documentos de design. Onde a história ainda não foi escrita, o texto
> marca **Lacuna**. Antes de escrever falas novas, leia também a bíblia do protagonista
> (`docs/noct_personalidade.md`).
>
> **Contém spoilers do jogo inteiro**, inclusive dos dois finais.

Legenda das fontes: entre parênteses fica o arquivo onde o fato aparece no jogo.

---

## Índice

- **Protagonista:** [Noct](#noct)
- **Quem já se foi:** [Mira](#mira)
- **Gente de Pedravelha:** [Tessa](#tessa) · [Velho Zeno](#velho-zeno) · [Irmã Lívia](#irmã-lívia) · [Ferreiro Brom](#ferreiro-brom) · [Forasteiro](#forasteiro)
- **Humanos na estrada:** [Capitão dos Desgarrados](#capitão-dos-desgarrados) · [Vigia Errante](#vigia-errante) · [Custódio do Selo](#custódio-do-selo) · [O capataz das minas](#o-capataz-das-minas) · [Os vigias do cemitério](#os-vigias-do-cemitério)
- **Chefes:** [Gato Infernal](#gato-infernal) · [Bringer of Death](#bringer-of-death) · [Velário, o Carcereiro](#velário-o-carcereiro) · [Demon Slime](#demon-slime)
- **Forças:** [A Fenda (Crimson Rift)](#a-fenda-crimson-rift) · [A Forma Demoníaca (a raposa)](#a-forma-demoníaca-a-raposa)
- **Planejado, ainda fora do jogo:** [O Chamador](#o-chamador-planejado)
- **Criaturas:** [Bestiário curto](#bestiário-curto)
- [Linha do tempo](#linha-do-tempo) · [Lacunas em aberto](#lacunas-em-aberto)

---

## Noct

**Quem é:** o protagonista. Um homem que perdeu sua razão para viver e passa a história inteira sem
perceber que está construindo outra. Viaja aceitando trabalhos, entra em ruínas "por dinheiro" e chama
isso de liberdade; na verdade, está fugindo.

**Aparência:** sem óculos, com brincos. Leva no pulso uma **fita carmesim** que era de Mira e nunca tira.

**Antes do jogo:** viveu com **Mira** a única relação que atravessou suas defesas. Ela ria do sarcasmo
dele, sabia quando ele mentia (ele coça a sobrancelha) e o chamava de idiota com carinho. Ele a chamava de
**"raposinha"**. Sentavam no banco da estação, ela à esquerda, ele à direita. Nas últimas semanas, Mira
ouvia um zumbido "como alguém chamando do outro lado de uma porta"; ele disse que era cansaço. Ela saiu
antes de amanhecer deixando um bilhete ("Volto logo. Não faz nada idiota.") e não voltou. Pouco depois,
o **Crimson Rift** começou a se manifestar nele. (`data/memories.gd`)

**A dúvida que o move:** "E se ela morreu por minha causa?"

**Durante o jogo:**
- Chega a **Pedravelha**, solta **Tessa** dos saqueadores no Bosque, recusa o papel de herói diante do
  Capitão ("Só não gosto de você.") e aceita o duelo do Vigia Errante.
- Vence o **Gato Infernal** ("...Finalmente.") e herda as Garras do Gato.
- Na catedral, o **Bringer of Death** diz que Mira gritou o nome dele antes de morrer. O sarcasmo some:
  "Repete." O Bringer arrasta a luta para dentro da cabeça dele (Mente do Noct). Ao vencer, Noct continua
  golpeando o Ceifador caído e admite: "E a fenda gostou de cada golpe. ...Eu também." Ganha o **Passo da
  Fenda** (atravessa paredes carmesim). (`game/world/main.gd`)
- No **Lago Velado**, enfrenta o **Velário**, a parte dele que escolheu esquecer, e recupera a última
  lembrança: a promessa de "continuar andando" e de nunca abrir a porta com raiva. A partir daí o poder
  vira escolha, não surto: nasce a **Forma Demoníaca**.
- No **Trono do Demônio**, vence o **Demon Slime** e ouve a revelação da Fenda: Mira ouvia o chamado
  antes dele e fechou a porta com o próprio corpo; foi a dor dele que a reabriu, e o poder dele é o que
  sobrou do selo dela. "Então não foi por minha causa."

**Os finais (`game/ui/ending.gd`):**
- **Final Eco ("Ficar na fenda"):** ele entra na fenda e se senta num banco onde o outro lado finalmente
  está ocupado, por uma voz que se parece com a dela, mas nunca ri do sarcasmo nem sabe quando ele mente.
  Em Pedravelha, ninguém mais fecha a fenda.
- **Final Um dia de cada vez ("Ir embora"):** "Ela fechou essa porta pra eu poder ir embora." Ele desamarra
  a fita, quase a deixa, e amarra de novo, mais firme. A fenda se fecha. Dias depois, no banco de
  Pedravelha, **Tessa** se senta do outro lado (se foi salva) e ele não pede que ela vá embora; ou ele fica
  sozinho um pouco mais. "...Talvez amanhã valha a pena."

**Traços a preservar:** sarcasmo como armadura, afeto por ação, o lugar vazio no banco, o sorriso de canto
diante de inimigos enormes, odeia e gosta do Rift. Detalhes completos em `docs/noct_personalidade.md`.

---

## Mira

**Quem era:** a mulher que Noct amou. Morta antes do começo do jogo. Ainda **sem arte**: o retrato é uma
silhueta feminina escura. Fala no jogo só em memórias.

**Como era (`data/memories.gd`):**
- Na primeira vez que ele foi grosso, ela riu: "Isso era pra me assustar? ...Tenta de novo amanhã."
- Pegava as mentiras dele pela sobrancelha: "Agora você está mentindo com a mão parada. É pior."
- Amarrou a fita carmesim no pulso dele numa noite de chuva: "Pra você lembrar de voltar. ...De mim, idiota."
- Sentava sempre à esquerda no banco da estação. Encostava a cabeça no ombro dele "por causa do frio".
  Não estava frio.
- Ensinou a frase **"Um dia de cada vez"**.
- Foi a única pessoa para quem ele disse em voz alta que tinha medo: "...De perder você."
- Gostava de lugares altos (pedra da Serra: "Você sempre escolhia os lugares altos").

**Raposas:** Mira adorava raposas e tinha com elas uma ligação forte, quase estranha: contava as que
apareciam na beira dos trilhos e dizia que vinham por ela. Noct a chamava de **"raposinha"**, primeiro para
irritar, depois por costume; ela nunca deixou ele parar. Ele usa o apelido de novo na promessa
("...Prometo, raposinha."). No banco, às vezes uma raposa para na beira da luz e fica olhando ("...Oi.").
**O porquê da ligação não é explicado** e deve continuar só sugerido.

**O que aconteceu com ela (revelado aos poucos):**
1. Ouvia um zumbido que ninguém mais ouvia (`the_hum`).
2. Desceu o Poço de Pedravelha antes dos outros, dizendo que o barulho vinha de baixo (`data/rooms/well.gd`).
3. Esteve no Coração da Fenda e riscou na pedra: "A porta chama de noite. Se eu responder com raiva, ela
   abre pra todo mundo." (`data/rooms/rift_heart.gd`)
4. Na última noite, sabia que podia não voltar e fez Noct prometer continuar andando e nunca abrir a porta
   com raiva (`PROMISE_MEMORY`, `game/world/main.gd`).
5. Saiu antes de amanhecer. Pegadas pequenas na estação vão até os trilhos e nenhuma volta
   (`data/rooms/station.gd`).
6. Segundo a Fenda, fechou a porta "com o próprio nome. Com o próprio corpo" (`REVELATION`).

**Pistas soltas ligadas a ela:** na Torre, riscos de altura com dois nomes raspados, um bem mais baixo;
atrás do sino, moedas embrulhadas num pano com um nó carmesim igual ao da fita. No Arquivo Submerso, o selo
"pede um nome em troca".

**Lacuna:** aparência, origem, família, como os dois se conheceram, como era o dia a dia fora da estação,
e por que ela ouvia a Fenda.

---

## Tessa

**Quem é:** uma mulher que também ouve a Fenda ("Parece alguém chamando do outro lado de uma porta", a
mesma frase de Mira). Usa o desenho da moradora da vila com outra cor. (`game/world/tessa.gd`)

**História no jogo:**
- **Bosque:** está amarrada a uma carroça pelos saqueadores, que iam entregá-la ao **Custódio** porque ela
  ouve a fenda. Noct corta as cordas, manda ela para Pedravelha e corta o agradecimento: "Não transforma
  isso numa coisa sentimental."
- **Vila:** reclama do frio à noite. Depois aparece enrolada numa jaqueta escura grande demais para ela,
  que Noct deixou no banco sem dizer nada. "É sua?" "Era." Na despedida, pergunta se ele volta da
  catedral: "Hoje primeiro. Amanhã depois."
- **Catedral:** segue Noct porque o chamado é mais forte ali. Ele a afasta com frieza ("Aqui você
  atrapalha." "Estou com pressa.") e espera ela sumir na estrada antes de seguir. É a fase do **medo** da
  bíblia: ele já tem algo a perder.
- **Final Um dia de cada vez:** é quem se senta do outro lado do banco e repete, quase palavra por
  palavra, a cena que resume Noct na bíblia. Ela fica. Ele não pede que ela vá embora.

**No design futuro:** em Pedravelha do Eco, a silhueta dela **não** está lá; só a jaqueta pendurada:
"Ela não é um eco." (`docs/expansao_forma_demoniaca.md`, 1.2)

**Lacuna:** de onde ela vem, a família, e o que exatamente ela ouve.

---

## Velho Zeno

**Quem é:** morador antigo de Pedravelha, o primeiro a receber Noct. Avisa que o pântano a leste "engoliu
muitos" e ensina que o banco "guarda sua alma quando você cai". Tem o jeito de velho que sabe mais do que
diz ("Velhos sabem dessas coisas." / "Velhos sabem de muita coisa."). (`data/rooms/town.gd`)

**Papel:** tutorial do banco e primeiro alvo do sarcasmo de Noct ("Excelente trabalho investigativo.",
"Constantemente." "Você está brincando." "Talvez.").

**Lacuna:** passado, e o que ele sabe sobre a fenda e sobre a vila.

## Irmã Lívia

**Quem é:** religiosa de Pedravelha que entende a **alma** que Noct arranca das criaturas: "Ninguém pede.
Mas ela responde a você." Ensina a cura e as magias. (`data/rooms/town.gd`)

**Papel na história:** é quem pergunta da fita ("De onde veio?" "De algum lugar." ... "É só uma fita." — a
última frase é mentira, e os dois sabem) e quem diz "Você nunca fala sobre você".

**Lacuna:** a ordem a que pertence e a relação dela com a Catedral Profanada.

## Ferreiro Brom

**Quem é:** ferreiro de Pedravelha e dono da loja (`data/shop_items.gd`). O Forasteiro recomenda falar com
ele antes de enfrentar o Gato Infernal.

**Lacuna:** não tem nenhuma fala de história ainda (a lista de falas dele está vazia).

## Forasteiro

**Quem é:** viajante de chapéu que vive no alto da vila. Conhece a região: aponta a trilha da serra, o
atalho do vigia e o Gato Infernal além do cemitério, e ensina o golpe para baixo. Ouviu dizer que Noct
entra nas ruínas por dinheiro ("Dinheiro paga comida." "E o resto?" "O resto ocupa a cabeça.").
(`data/rooms/town.gd`)

**Lacuna:** nome, origem e por que está em Pedravelha.

---

## Capitão dos Desgarrados

**Quem é:** líder dos saqueadores do Bosque e da Serra. Não é só ladrão: o bando **vende ao Custódio**
quem ouve a fenda. No esconderijo, uma lista de nomes e a ordem "Entregar os que ouvirem a fenda ao
Custódio da catedral." (`data/rooms/forest.gd`)

**Encontro:** "Vai bancar o herói?" "Não." "Só não gosto de você." — o código moral de Noct em uma linha.
(`game/enemies/enemy_humanoid.gd`)

## Vigia Errante

**Quem é:** guardião de uma trilha do Bosque, há tanto tempo que esqueceu para quem guarda: "...Guardei
esta trilha até esquecer para quem."

**Encontro:** encosta a lâmina no pescoço de Noct ("Bonita. Vai usar ou é decoração?") e propõe um duelo
sem mortes, "para mostrar que ainda escolhe onde o golpe termina". É opcional. Ao perder, entrega Geo:
"Ainda sabe parar." Noct responde, sem ironia: "...Continue guardando a trilha."

**Leitura:** espelha Noct (alguém que continua de pé por hábito) e testa justamente o que o Rift ameaça
tirar dele: parar o golpe.

**Lacuna:** quem ele guardava. Não está claro se ele tem ligação com os vigias do cemitério.

## Custódio do Selo

**Quem é:** mago que vive na **Ruína do Selo Vazio**, acima da catedral. Recebe dos saqueadores as pessoas
que ouvem a fenda e as prende: "Você ouviu a fenda. Então pertence ao selo." Noct: "Não pertenço a nada."
(`data/rooms/arcane_ruins.gd`, `game/enemies/enemy_humanoid.gd`)

**O que ele guardava:** registros de **almas capturadas**. Uma anotação diz que a energia carmesim "não
obedece ao selo. Responde à ausência." A página seguinte, arrancada, está no **Arquivo Submerso**:
"...responde à ausência de quem foi amado. O selo pede um nome em troca."

**Leitura:** o Custódio tentava repetir à força o selo que Mira fez por vontade própria.

**Lacuna:** quem ele era antes, se conheceu Mira, e o que fazia com as almas.

## O capataz das minas

Só aparece no diário, nas **Minas da Fenda**: "O veio canta quando alguém na vila chora. Mandei parar de
cavar. Ninguém parou." Os mineiros viraram **mineiros cristalizados** que ainda andam pelas galerias.
Noct: "Cresce com perda. ...Então eu sou uma jazida." (`data/rooms/mines.gd`)

## Os vigias do cemitério

Deixaram uma carta sob a estátua: "Fechamos os túmulos. Não fechamos aquilo que ouviu nossos nomes." Foram
eles que abriram a passagem pela serra. (`data/rooms/cemetery.gd`)

**Lacuna:** quantos eram e o que aconteceu com eles.

---

## Gato Infernal

**Quem é:** fera de fogo que vive no **Covil**, além do cemitério. Sem fala. É o primeiro inimigo enorme e
arranca de Noct o sorriso de canto: "...Finalmente." (`game/bosses/gato/gato.gd`)

**Depois da luta:** Noct absorve a essência da fera (+1 máscara) e as garras ficam cravadas nas luvas
(**Garras do Gato**: deslizar e saltar de paredes). "Bom gatinho."

**Lacuna:** origem da fera e ligação com a fenda.

## Bringer of Death

**Quem é:** o Ceifador da catedral. Não tem poder sobre os mortos: **acha o pior medo de cada um e fala com
a voz dele**. Nunca tocou em Mira. (`game/bosses/bringer/bringer.gd`)

**A luta:**
- Ao acordar: "Mais uma alma que ouviu a fenda." / "Ela gritou seu nome antes de morrer." — Noct: "Repete."
- Na metade da vida, arrasta a luta para a **Mente do Noct**: "Bem-vindo à sua cabeça, Noct. Eu só acendi a luz."
- Lá dentro, admite: "Eu menti. Nunca vi a sua Mira. Mas você acreditou na hora. Porque é exatamente o que
  você teme." E provoca com tudo o que só Noct sabe: o lado esquerdo do banco, a fita, o bilhete, o apelido
  "Raposinha".

**Depois:** Noct continua golpeando o corpo caído (o "Noct consumido" da bíblia). Toma o grimório do
Ceifador e ganha o Passo da Fenda. A fenda sob o altar do Santuário passa a levar ao Lago Velado.

**Lacuna:** de onde ele veio e se serve a alguém.

## Velário, o Carcereiro

**Quem é:** a parte de Noct que preferiu esquecer, transformada pela Fenda em carcereiro quando Mira
morreu. Trancou a última lembrança, a mais pesada, numa lanterna no fundo do **Lago Velado**. O nome vem do
véu de funeral. **Não é cruel: acha que protege.** O Bringer usa os medos dos outros; o Velário **é** um
medo de Noct. (`game/bosses/velario/velario.gd`, `docs/expansao_forma_demoniaca.md` seção 3)

**A luta:**
- "Volta. Aqui embaixo não tem nada seu." — "Engraçado. Parece meu."
- A lanterna racha: "Você não quer lembrar. Eu sou a prova." O véu rasga; na fase 2 (o Despido) o rosto é
  um espelho que reflete Noct.
- "Ela pediu uma coisa. Você vai odiar lembrar o quê." / "Ela sabia que podia não voltar." — "Me devolve."
- Abaixo de 20%: "Não olha."
- Ao perder, abre a lanterna com as próprias mãos: "Então lembra. E não diz que eu não avisei."

**Depois:** a luz da lanterna vira uma fita e se enrola no pulso de Noct por cima da fita de Mira. Libera a
memória "Continua andando" e a Forma Demoníaca.

**Arredores:** na Margem das Folhas Paradas, véus com coisas esquecidas bordadas ("O cheiro do café." "O
nome da rua."), um véu sem nome ainda úmido e um reflexo atrasado em que, por um instante, alguém está
sentado ao lado dele.

## Demon Slime

**Quem é:** o chefe final, no **Trono do Demônio**, no fundo do Inferno. Entrou pela porta que a dor de
Noct abriu: "Foi a sua dor que abriu a porta. Eu só entrei." Começa a luta com "Você carrega a ausência
dela como uma lâmina." Noct: "Então eu fecho com você dentro." (`game/bosses/demon_slime/demon_slime.gd`)

**Depois:** cai, mas a fenda continua aberta, e é ela quem fala a revelação final.

**Lacuna:** se o Demon Slime é uma criatura da fenda ou algo que veio de fora dela.

---

## A Fenda (Crimson Rift)

**O que é:** uma porta que chama de noite. Tem **voz própria** no jogo (retrato "A Fenda") e se alimenta de
perda: o veio das minas "canta quando alguém na vila chora", a energia "responde à ausência de quem foi
amado", e no Coração da Fenda ela bate "no mesmo ritmo" que o coração de Noct.

**O que ela revela (`REVELATION`, `game/world/main.gd`):** Mira a ouvia primeiro, veio sozinha até a porta e
a fechou com o próprio corpo. A porta reabriu quando Noct a perdeu ("A sua dor tem o formato da chave"). O
poder de Noct é o que sobrou do selo dela. "Não foi por sua causa que ela morreu. Mas é por sua causa que eu
ainda existo." E pede: "Fique. Aqui dentro, ela ainda está esperando." — é essa proposta que o Final Eco
aceita.

**Quem a ouve:** Mira, Tessa, as pessoas caçadas pelos Desgarrados e presas pelo Custódio. Noct a sente,
mas a relação dele é outra: ele a carrega.

## A Forma Demoníaca (a raposa)

**O que é:** a transformação de Noct, liberada ao vencer o Velário. É **uma só**: um guerreiro raposa
demoníaco de cauda em leque (a arte da folha "Guerreiro Raposa Demoníaco"). Os chifres são de energia, com
energia sutil pelo corpo; a magia própria é a **Raposa Espectral Carmesim**. A forma persiste ao trocar de
sala e só a morte a desfaz. (`game/player/demon_form.gd`)

**Origem na história:** depois da promessa, "a energia carmesim sobe. Dessa vez, ele não deixa ela tomar
conta. Por um instante, ela se dobra atrás dele como uma cauda." A primeira fala ao transformar é
"Lembrando de você, então." O poder controlado vem da **memória**; o descontrolado, da **raiva**.

**Ligação com Mira:** apenas sugerida (a raposinha, as raposas que param para olhá-lo, a cauda de energia).
O jogo nunca a afirma.

**Nome interno:** o código ainda chama o nível de "Juramento". Os níveis 1 e 2 antigos foram removidos.

---

## O Chamador (planejado)

**Status:** não está no jogo. É ideia de design (`ideias/areas_novas.md`, `docs/expansao_forma_demoniaca.md`).

Chefe de **Pedravelha do Eco**, a vila invertida do outro lado da fenda (o lugar do Final Eco). A arena tem
ao fundo a porta de que Mira falava. Ele fala com frases de Mira, sempre um pouco erradas: "Um dia de cada
vez... não. Fica. Todos os dias. Aqui." Noct: "Essa frase não é sua."

---

## Bestiário curto

Criaturas sem nome próprio, com o que o jogo já diz sobre elas.

| Criatura | Onde | O que se sabe |
|---|---|---|
| Saqueadores (leves e pesados) | Bosque, Serra | Bando dos Desgarrados; caçam quem ouve a fenda. |
| Thing | Pântano | Criatura do pântano que persegue na mesma altura. |
| Esqueletos enterrados | Cemitério | Mortos que "não dormem quando a fenda respira"; surgem do chão com tremor carmesim. |
| Mineiros cristalizados | Minas da Fenda | Os mineiros que não pararam de cavar o veio. |
| Grimórios vorazes | Arquivo Submerso | Livros do Custódio que mordem. |
| Cães infernais, olhos demoníacos, anjos caídos, caveiras de fogo | Inferno | Do outro lado da fenda. |
| Lamento | Lago Velado | Espectro fraco e lento que chora quando Noct chega perto. |
| Miragem | Lago | Silhueta de costas de alguém que Noct conhece de longe; só a verdadeira tem reflexo. |
| Sanguessuga de alma | Lago | Bolsa no teto cheia de luz roubada; drena alma e a devolve ao morrer. |
| Faminto da Fenda | Lago | Cão sem pele com cristais carmesim; só acorda quando Noct usa a Forma Demoníaca. |

---

## Linha do tempo

1. Noct conhece Mira. Ela o apelida de idiota; ele a chama de raposinha.
2. Fita carmesim, banco da estação, "um dia de cada vez".
3. Mira começa a ouvir o zumbido; desce o Poço; vai ao Coração da Fenda.
4. Última noite: a promessa. Ela sai antes de amanhecer e fecha a porta com o próprio corpo.
5. Noct a perde. A dor reabre a porta; o Rift desperta nele. O Velário tranca a última lembrança.
6. Os Desgarrados passam a caçar quem ouve a fenda para o Custódio.
7. **Começo do jogo:** Noct chega a Pedravelha.
8. Bosque (Tessa, Vigia) → Serra (Capitão) → Pântano → Cemitério → Gato Infernal.
9. Catedral → Ruína do Custódio → Bringer of Death (Mente do Noct) → Passo da Fenda.
10. Lago Velado → Velário → a promessa → Forma Demoníaca → Coração da Fenda.
11. Inferno → Demon Slime → revelação → escolha: **Eco** ou **Um dia de cada vez**.

As ordens dos itens 3 e 6 são inferidas das pistas; o jogo não as data.

## Lacunas em aberto

- Aparência, origem e passado de **Mira** (e o motivo da ligação com raposas, que deve continuar sem resposta por ora).
- Passado de **Noct** antes de Mira: família, de onde vem, como ganhou a vida.
- Histórias de **Zeno, Lívia, Brom e Forasteiro**; Brom não tem nenhuma fala de história.
- Origem de **Tessa** e por que ela ouve a fenda.
- Quem o **Vigia Errante** guardava; quem eram os vigias do cemitério.
- Passado do **Custódio** e o destino das almas capturadas.
- Origem do **Gato Infernal**, do **Bringer** e do **Demon Slime**.
- Os dois nomes raspados nos riscos da Torre e o pano com nó carmesim atrás do sino.
- O **Chamador** e Pedravelha do Eco ainda não existem no jogo.
