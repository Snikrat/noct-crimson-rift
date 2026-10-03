# Torre, Poço, Estação e Garras do Gato — 03/10/2026

Três áreas opcionais e uma habilidade de movimento, a partir das ideias da seção 5. Minas da Fenda e Arquivo Submerso ficam com outro trabalho e não foram tocados.

## Como encontrar

- **Torre de Pedravelha** (`data/rooms/tower.gd`): porta na vila, entre o primeiro poste e a casa do meio. O térreo tem banco e fica aberto desde o começo, mas a subida só é possível com as **Garras do Gato**. Riscos de altura no piso do meio; no topo, a **luneta** marca a região de Pedravelha no mapa da pausa e o **sino rachado** esconde 40 Geo.
- **Poço de Pedravelha** (`data/rooms/well.gd`): use o poço da vila. Descida curta com dois fantasmas, uma faixa de espinhos e água parada no fundo. O amuleto **Um Dia de Cada Vez** fica atrás de uma parede carmesim (Passo da Fenda, depois do Bringer).
- **Estação** (`data/rooms/station.gd`): os **trilhos velhos** na Serra só levam até lá depois da memória "Volto logo" (Inferno). Chuva, nenhum inimigo, quadro de horários, pegadas que não voltam e o banco em que Noct senta **à direita**. Se a memória "O lado esquerdo" já foi encontrada, a narração acrescenta "Não estava frio."

## Garras do Gato

Liberadas ao derrotar o Gato Infernal (a vitória ganhou duas linhas explicando). No ar, segurando a direção de uma parede, Noct desliza devagar; pular o lança para longe dela e devolve o pulo duplo e o dash aéreo. Dá para subir uma parede só, emendando saltos. Constantes `WALL_SLIDE_SPEED`, `WALL_JUMP_VELOCITY` e `WALL_JUMP_PUSH` em `player_body.gd`.

## Amuleto novo

| Amuleto | Custo | Efeito |
|---|---:|---|
| Um Dia de Cada Vez | 1 | Parado no chão por 3 s, recupera 8 de alma por segundo |

## Arte provisória (para refazer no Aseprite)

Tudo usa assets que já estavam no projeto. A lista do que vale desenhar:

- **Noct grudado na parede**: animação `wall_slide` (2 a 3 quadros). O código já usa essa animação se ela existir no `SpriteFrames` do herói; até lá aparece o quadro de queda, de costas para a parede.
- **Fachada da torre** na vila e **interior** (vigas, sino rachado, luneta). Hoje: portal carmesim e recortes da catedral.
- **Estação**: cobertura, banco duplo, relógio parado, quadro de horários e trilhos. Hoje: chão da vila tingido de azul, postes e placa da vila.
- **Poço**: pedra úmida e corda partida. Hoje: pedra da catedral tingida de azul.
- **Ícone** do amuleto Um Dia de Cada Vez (32×32). Hoje: um ícone de espada do pacote.

## Mudanças de sistema

- Marcadores aceitam `"requires": "memory:<id>"` e `"boss:<id>"`, além de descobertas, e `"locked_lines"` para o texto enquanto estão fechados.
- Caractere `w` = água parada (só visual); `"rain": true` no tema liga a chuva (`game/world/rain.gd`).
- Seis descobertas novas no save (`tower_marks`, `tower_view`, `tower_bell`, `well_note`, `station_board`, `station_tracks`). Saves antigos continuam válidos.

## Verificação

`tests/areas_test.gd` (53 verificações): salas registradas, portas com chão, subida impossível sem as Garras e possível com elas, deslizar na parede, luneta, recompensa única do sino, água e nicho do poço, amuleto, trilhos fechados e abertos pela memória, chuva, banco da estação e save. Os testes anteriores continuam passando. Com `-- --screenshots`, gera `tower_bottom`, `tower_top`, `well` e `station` em `docs/content-preview/`.
