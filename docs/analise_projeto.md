# Análise do projeto — NOCT: CRIMSON RIFT

Data: 03/10/2026.

## Ajustes realizados após a análise

Os problemas técnicos abaixo foram corrigidos: compra de alma soma +5 e saves antigos recuperam o bônus de nível; save valida estrutura, versão, números, habilidades, compras, banco e amuletos antes de alterar a partida; gravação usa arquivo temporário e informa falhas; Continuar inválido permanece no título; recompensas de morte não se repetem; transições cancelam ações pendentes; mergulho respeita lava/espinhos e retorna à posição segura se cair sem chão. Trocar amuletos no banco grava imediatamente e atualiza o checkpoint. Atalhos de debug só funcionam em builds de desenvolvimento.

Foi acrescentado `tests/regression_test.gd`, usando arquivo de save exclusivo do teste. Os achados abaixo ficam preservados como registro da análise original. Expansão de mapas, narrativa, balanceamento, opções e exportação continuam como próximos passos de desenvolvimento.

Validação após os ajustes: **66 verificações gerais e 30 de regressão aprovadas, sem falhas**. A regressão encerra sem avisos de recursos; o teste geral ainda registra 6 instâncias e 3 recursos em uso na saída, mesmo após liberar a cena e esperar efeitos pendentes. A origem desses avisos permanece pendente. Testes executados em modo headless; avaliação visual e campanha manual continuam necessárias.

## Escopo e validação

Revisão dos scripts de jogo, autoloads, duas cenas, dados das oito salas, progressão, amuletos, caminhos de assets, ferramentas de recorte e documentação. Executado `tests/smoke_test.gd` no Godot 4.7.2, em modo headless: **66 OK, 0 FALHOU**, código de saída 0. O teste usa `test_save.json`, separado do save do jogador.

O encerramento registrou 10 instâncias ObjectDB não liberadas e 5 recursos ainda em uso. A causa não foi isolada; isso não demonstra, por si só, um vazamento durante partidas longas. Não houve avaliação visual em janela, teste de controle físico ou uma campanha percorrida inteiramente com movimentos normais. Os testes usam teleporte, invulnerabilidade e redução da vida dos chefes, portanto não comprovam dificuldade, acessibilidade de todas as plataformas ou equilíbrio da campanha.

Nenhum script ou dado de gameplay foi alterado nesta análise.

## Estado atual

O projeto já possui um ciclo jogável completo: título, exploração, combate, XP, compras, checkpoints, morte, retomada do save e diálogo final. A resolução lógica é 480 × 270, com janela configurada para 1440 × 810 e renderização GL Compatibility.

- Movimento: pulo variável, pulo duplo, coyote time, buffer de pulo, dash terrestre/aéreo e pogo.
- Combate: socos direcionais, combo, chute, golpe carregado, uppercut e recuo.
- Magias: projétil, trovão, cura por concentração, mergulho e Ultimate do dragão.
- Progressão: dez níveis, seis habilidades desbloqueáveis, bônus de vida e alma.
- Conteúdo: oito salas, nove tipos de inimigos comuns, três chefes com segunda fase e quatro NPCs na vila.
- Economia: Geo, sete itens da loja, oito amuletos e quatro encaixes.
- Interface: HUD, diálogo com 30 expressões, loja, pausa, amuletos, controles e créditos.
- Áudio: efeitos, vibração, músicas por área/chefe e transição entre exploração e combate.

O mundo segue uma sequência: Vila → Pântano → Cemitério → Gato Infernal → Catedral → Bringer → Inferno → Demon Slime. Existem plataformas e colecionáveis laterais, mas as conexões entre salas são lineares. Dash e pulo duplo já estão disponíveis no início; as habilidades liberadas por XP ampliam principalmente o combate. Para aumentar a exploração típica de um metroidvania, faltam ramificações, atalhos e obstáculos que respondam a habilidades adquiridas.

## Arquitetura

`project.godot` inicia o título e registra Controls, Audio e GameState. As cenas de título e mundo contêm apenas o nó raiz com seu script; os personagens, colisores, interfaces e cenário são criados em código.

`main.gd` interpreta mapas textuais, cria entidades, troca salas, controla arenas, recompensas, checkpoints e eventos. `player.gd` reúne movimento, golpes, magias, dano e animações. `data/` concentra conteúdo, e `asset_paths.gd` centraliza caminhos. `Sprites` monta animações a partir de imagens e dos metadados gerados pelas ferramentas.

A separação entre dados, apresentação e estado global facilita acrescentar conteúdo. A criação quase integral em código dificulta ajustar salas, colisores e interfaces diretamente pelo editor do Godot. Não é necessário reescrever tudo: cenas reutilizáveis podem ser introduzidas gradualmente, começando pelas entidades que exigirem mais ajustes visuais.

## Problemas confirmados pela leitura do código

### 1. Compra de alma depende da ordem de evolução

Em `game/ui/shop.gd:79`, o Coração de Alma atribui `soul_per_hit = 16`. O nível 6 soma mais 3 em `game/player/player.gd:201`.

Comprar primeiro e atingir o nível 6 resulta em 19. Atingir o nível 6 primeiro deixa o valor em 14, e comprar depois resulta em 16: o bônus de nível deixa de compor o atributo. A compra deveria somar seu bônus ou o atributo deveria ser calculado a partir das fontes permanentes.

### 2. Save aceita estrutura inválida

`autoload/game_state.gd:84` verifica apenas se o JSON é um Dictionary. Não valida versão, campos do herói, tipos, sala do banco ou IDs dos amuletos antes de modificar o estado.

Um JSON sintaticamente válido pode passar por `load_game()` e falhar posteriormente: uma sala inexistente é usada como chave em `Rooms.ROOMS`; um herói incompleto é acessado por campos obrigatórios em `apply_hero`; um amuleto desconhecido é usado como chave em `used_notches`. A validação deveria ocorrer antes do `reset()` e da aplicação dos dados.

### 3. Gravação não trata falha e não protege o save anterior

`autoload/game_state.gd:79` abre diretamente o arquivo final em WRITE e chama `store_string` sem verificar se a abertura funcionou. `main.gd` apresenta “Jogo salvo” sem receber um resultado da operação.

Se a abertura falhar, a chamada usa uma referência nula. Uma interrupção durante a escrita pode deixar o arquivo incompleto. Recomenda-se escrita em arquivo temporário, verificação de erro, substituição do arquivo final e mensagem coerente com o resultado.

### 4. Morte de inimigos comuns não possui proteção contra chamadas repetidas

Crawler, Flyer, Caster e Gato aplicam recompensas e chamam `queue_free()` quando a vida acaba, sem marcar a morte ou ignorar novos hits. Como `queue_free()` é adiado, duas fontes de dano no mesmo quadro podem chamar novamente a recompensa antes da remoção. Bringer e Demon Slime já usam `dying` para impedir isso.

O risco está no código; não foi reproduzido no smoke test. A correção deve ser acompanhada de teste com duas fontes de dano simultâneas.

## Pontos que exigem testes específicos

- `enter_room()` limpa apenas parte do estado do herói. Golpe atual, projétil pendente, recuo, ataque vertical e Ultimate podem sobreviver à troca de sala. Testar transições durante essas ações antes de definir o comportamento desejado.
- `_process_slam()` retorna antes da rotina normal de dano e saída da sala. Verificar contato com lava/espinhos e casos sem chão; a rotina também mantém invulnerabilidade durante o mergulho.
- Amuletos são equipados depois que o banco grava o save. Sair ao título imediatamente após equipar não grava a alteração; é preciso descansar novamente. Decidir se esse comportamento deve ser mantido e comunicado ou se a troca deve persistir automaticamente.
- Investigar os avisos de recursos ao encerrar com execução verbose e teste de repetidas trocas de cena.
- Validar visualmente textos longos, tabela de controles, créditos, descrições da loja e diálogos na resolução lógica de 480 × 270.

## Limites do teste existente

O smoke test cobre bem o caminho principal, mas não cobre saves malformados, falhas de escrita, todas as combinações de amuletos, compra antes/depois do nível 6, dano simultâneo, todos os ataques das duas fases dos chefes ou trajetos reais entre todas as plataformas. É útil manter esse teste e adicionar casos pequenos para os problemas específicos, sem substituir a validação de uma partida normal.

## Conteúdo e preparação para distribuição

A documentação de Noct fornece uma identidade consistente e um arco de luto, vínculo e relação com a fenda. O diálogo final atual encerra a campanha, mas não apresenta a revelação sobre Mira e os poderes descrita no guia. Existe espaço para desenvolver essa ligação por eventos e pistas durante a exploração.

Os atalhos de debug permanecem ativos (`main.gd:26`), incluindo subir nível pelo controle. Não foi encontrado `export_presets.cfg` ou repositório Git nesta pasta. Antes de distribuir uma versão, configurar exportação e condicionar ferramentas de debug à compilação de desenvolvimento.

`CREDITOS.md` registra pendências de identificação/licença para alguns pacotes. Esta análise não verificou essas licenças externamente; as pendências documentadas precisam ser resolvidas na preparação da distribuição.

## Ordem sugerida para continuar

1. Corrigir cálculo do bônus de alma, validar saves e tratar gravação.
2. Proteger recompensas de morte e testar ações durante transições.
3. Fazer uma campanha normal para medir alcance dos pulos, legibilidade, ritmo de XP, economia e dificuldade dos chefes.
4. Acrescentar ramificações, atalhos e desafios de exploração que aproveitem as habilidades.
5. Desenvolver pistas e eventos narrativos relacionados a Mira e à fenda.
6. Configurar versionamento, exportação e opções de áudio/controles conforme o alvo de distribuição.

A base permite continuar com mudanças graduais. Os próximos passos mais úteis são consolidar persistência e combate e depois expandir a exploração, preservando a identidade e os sistemas já implementados.
