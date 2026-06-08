# Changelog



## 2026-06-07 - P02C1 alinhamento da fonte de receitas

- `RecipeBookUI.gd` e `Cauldron.gd` passaram a resolver receitas por uma camada central baseada em `RecipeDatabase`/`Data/recipes`, com fallback legado temporário para `Database.receitas_alquimia`.
- O `SaveManager` não foi alterado e `receitas_descobertas` continua sendo salvo como ids crus.
- A mudança reduz o drift entre Livro e Caldeirão sem migrar o catálogo ainda.

## 2026-06-07 - Documentação do catálogo de transição

- Foi criado `docs/CATALOG_TRANSITION_PLAN.md` para registrar o estado atual do catálogo legado/provisório e a direção do catálogo definitivo.
- A documentação consolida a equivalência entre o catálogo atual do código e os nomes/linhas do design novo, sem alterar gameplay, cenas ou recursos de receita.
- Também foi registrado o risco de drift entre `Database.gd`, `Data/recipes/*.tres`, o Livro de Receitas e o caldeirão durante a migração futura.

## 2026-06-07 - Layout Pass V1 da fazenda e UI arrastável

- O núcleo inicial da fazenda recebeu um ajuste de layout para ganhar respiro visual, reduzindo a sensação de área amontoada.

- O blockout visual ficou mais leve e periférico, com opacidade menor e mais separação entre zonas futuras.

- O painel de objetivos iniciais foi reposicionado para não cobrir tanto o miolo da fazenda.

- Painéis/popup selecionados passaram a aceitar arraste runtime-only por um helper reutilizável de UI, sem salvar posição.

- `SaveManager`, `FarmPlot`, `FarmGridPreview`, `FarmGridManager`, receitas e gameplay central permaneceram preservados.



## 2026-06-07 - Talento Golem Irrigador implementado

- A árvore de talentos ganhou o novo talento `skill_golem_irrigador`, separado do talento `skill_golem` já existente.

- O golem físico agora preserva a prioridade de colheita e, quando não há lote maduro, pode irrigar lote plantado e seco se o talento estiver desbloqueado.

- A rega por golem usa um método público seguro em `FarmPlot` e não consome água do inventário do jogador.

- A interface do Golem V0 foi adicionada para mostrar status, desbloqueio do talento, tarefa atual e prioridade runtime-only.

- A implementação manteve o golem atual, sem criar múltiplos golems, sem novo inventário e sem novo pathfinding.

- `SaveManager`, `Database`, receitas, caldeirão, purificação e expansão permaneceram fora desta mudança.



## 2026-06-07 - UX do caldeirão e receitas ajustada

- As receitas que dependiam de água foram substituídas por combinações com itens existentes e obtíveis em inventário, removendo o requisito de água das receitas ativas.

- O slot do caldeirão agora exibe visualmente o item vinculado usando o texto/ícone da base de dados, em vez de depender de texturas ausentes.

- O drag preview de itens passou a usar um preview textual/ícone consistente e visível seguindo o mouse.

- Ao iniciar uma receita com sucesso, a popup do caldeirão fecha automaticamente; falhas continuam mantendo a UI aberta.



## 2026-06-07 - Missão Inicial V0 da fazenda implementada

- Foi adicionado um painel pequeno de objetivos iniciais na UI para guiar o loop principal da Fase 1.5.

- A Missão Inicial V0 é runtime-only, separada do `QuestManager`, não persiste no save e se oculta após a conclusão.

- O painel acompanha o progresso por leitura de estado existente, incluindo inventário, `FarmPlot`, purificação e expansão liberada.

- A etapa `Colher` passou a exigir observação de lote pronto após o bootstrap da UI e só conclui quando o mesmo lote fica vazio depois disso, reduzindo falso positivo.

- Ao carregar um save, o rastreamento runtime-only dos objetivos iniciais é reiniciado para evitar transições espúrias durante reload, e um save que abre vazio não conclui `Colher` sozinho.

- `QuestBoard`, `QuestManager`, `SaveManager`, `FarmGridPreview` e `FarmGridManager` permaneceram preservados.

- O fluxo runtime-only aceita falso negativo leve após reload em troca de reduzir falso positivo, especialmente na etapa `Colher`.



## 2026-06-06 - Blockout Visual V0 da fazenda implementado

- `Scripts/Main.gd` passou a criar marcadores visuais runtime-only para zonas futuras da fazenda, sem gameplay e sem persistência.

- O blockout marca visualmente áreas para criaturas/animais mágicos, golems/ajudantes, recursos/forrageamento, segunda área corrompida futura e ruína/mistério futura.

- Nenhum `FarmPlot` novo foi criado, `SaveManager` permaneceu intacto e `FarmGridPreview` não foi conectado ao jogo principal.

- A fazenda continua jogável com os plots antigos e o loop validado da Fase 1.



## 2026-06-06 - Plano macro da fazenda documentado

- Foi criado `docs/FARM_LAYOUT_PLAN.md` para registrar o estado atual da fazenda, o problema de concentração do núcleo inicial e as zonas macro recomendadas.

- A documentação separa Fase 1, Fase 1.5 e Fase 2, mantendo solo livre e `FarmGrid` real para a fase futura.

- Também foi registrado que blockout visual pode existir na Fase 1.5, mas sem gameplay, sem novos `FarmPlot` reais e sem acoplar `FarmGridPreview` ao jogo principal.

- Nenhum código, cena ou sistema de gameplay foi alterado nesta etapa.



## 2026-06-06 - Demo exportada da Fase 1 validada manualmente

- A build Windows da Fase 1 foi gerada com sucesso em `Builds/Fase1/`.

- Os arquivos exportados `CauldronCrops_Fase1.exe` e `CauldronCrops_Fase1.pck` foram gerados com os export templates da Godot 4.6.2 instalados localmente.

- A demo exportada foi aberta e validada manualmente, e o jogo fechou corretamente ao final do teste.

- `Builds/` permanece fora do versionamento e a validação não alterou gameplay, cenas nem código.



## 2026-06-06 - Preparação da build/demo da Fase 1

- Foi criado um preset de exportação Windows Desktop para a demo da Fase 1.

- O `README.md` recebeu instruções mínimas de execução local e exportação.

- `Builds/` passou a ser ignorado para manter as saídas de build fora do versionamento.

- Nenhum sistema de gameplay foi alterado.



## 2026-06-06 - Validação manual da Fase 1 em save limpo

- O teste de loop completo da Fase 1 foi executado em save limpo e concluído com sucesso.

- A validação cobriu início em save limpo, arar, plantar, regar, colher, usar o caldeirão, abrir o Livro de Receitas, purificar a área, liberar o pocket 2x2, usar um plot liberado, salvar com F5, carregar com F9 e confirmar a persistência da expansão.

- A UI principal permaneceu funcional durante o teste e nenhuma instância do jogo ficou aberta ao final.

- O save antigo foi preservado em backup antes da validação.



## 2026-06-06 - Expansão preparada para múltiplas áreas

- `Main.gd` passou a usar uma estrutura interna de áreas de expansão por `obstacle_id`, mantendo apenas a V0 cadastrada por enquanto.

- O pocket 2x2 atual, o bloqueio visual e a sincronização pós-load continuam funcionando como antes.

- Nenhuma segunda área foi adicionada, nenhum `FarmPlot` novo foi criado e o schema do save foi preservado.



## 2026-06-06 - Feedback visual V0 da Purificação

- Ao concluir a purificação com sucesso, o jogo agora dispara um feedback visual provisório com brilho e mensagem curta `Área purificada!`.

- O efeito é apenas de apresentação, não altera save/load nem a lógica central de desbloqueio.

- O painel continua fechando normalmente após a ação, sem depender do feedback para concluir.



## 2026-06-06 - Painel de Purificação mais claro

- O Painel de Purificação agora diferencia visualmente a entrega de recursos da ação final de purificar.

- Quando faltam requisitos, o painel orienta o jogador com uma mensagem direta para entregar tudo antes de purificar.

- Quando os requisitos ficam completos, o painel passa a indicar explicitamente que a próxima ação é clicar em `Purificar Área`.

- O botão `Purificar Área` recebe destaque visual simples quando fica habilitado.

- A lógica central de purificação, o save e o desbloqueio da área permanecem inalterados.



## 2026-06-06 - Expansão V0 da fazenda reforçada

- O jogo principal mantém o pocket fixo 2x2 de `FarmPlot` atrás da Área Bloqueada V0, sem envolver `FarmGridPreview`.

- `Main.gd` agora expõe uma sincronização explícita para reaplicar o estado da área bloqueada após o carregamento do save.

- O `SaveManager` reforça essa sincronização depois de restaurar o estado de purificação, preservando a liberação visual e funcional dos plots.



## 2026-06-06 - Painel de Requisitos de Purificação V0

- A Área Bloqueada V0 agora abre um `PurificationPanel` em vez de purificar direto no clique.

- Os requisitos podem ser entregues parcialmente por item e o progresso fica salvo por obstáculo em `farm_expansion.purification_progress`.

- O botão `Purificar Área` só fica disponível quando Poção Purificadora Fraca, Escama Brilhante e Trigo estão completos.

- A purificação continua sendo um teste V0 com uma única área bloqueada, sem criar nova área, novo obstáculo ou nova receita.

- Ao purificar, o obstáculo some, a área roxa desaparece e o pocket é liberado.



## 2026-06-05 - Poção Purificadora Fraca no caldeirão V0

- O caldeirão agora produz `pocao_purificadora_fraca` com `agua` + `peixe_comum`.

- `peixe_comum` entrou na lista de itens que o sistema de receitas usa para reconstruir ingredientes no livro e no modo lote.

- O fluxo de purificação continua exigindo também `escama_brilhante` e `trigo` na Área Bloqueada V0.

- O botão debug de poção segue provisório e continua disponível para teste.

- Nenhuma nova área, obstáculo, conexão com FarmGrid ou alteração de save foi criada nesta etapa.



## 2026-06-04 - Area Bloqueada V0

- O obstáculo usa uma lista provisória de requisitos de purificação.

- A lista V0 inclui `pocao_purificadora_fraca`, `escama_brilhante` e `trigo`.

- O feedback agora mostra requisitos faltantes usando nomes do catálogo quando possível.

- Um botão temporário no Debug Panel pode entregar todos os recursos de purificação para teste.

- O obstáculo passa a pedir a lista completa antes de purificar.

- A Poção Purificadora Fraca é apenas um requisito, não o custo inteiro.

- A purificação continua salva em `farm_expansion.purification_obstacles`.

- Nenhuma conexão real com o caldeirão foi criada nesta etapa.



## 2026-06-04 - Obstáculo Mágico V0

- O projeto ganhou o primeiro obstáculo estático da fazenda, purificável com `pocao_purificadora_fraca`.

- O estado de purificação agora é salvo em `farm_expansion.purification_obstacles`, com compatibilidade para saves antigos.

- Um botão temporário no Debug Panel permite adicionar a poção de teste sem depender do caldeirão.

- Nenhuma área completa, múltiplos obstáculos ou conexão com o FarmGrid foi criada nesta etapa.



## 2026-06-04 - Sistema de Expansão e Purificação da Fazenda

- Foi documentada a direção central da fazenda final como um mapa fixo, artesanal e dividido em áreas desbloqueáveis por purificação alquimica.

- A documentação agora liga caldeirao, pesca e Catálogo de Itens a esse futuro eixo de progressao sem implementar o sistema ainda.

- Nenhum script, cena, asset ou `project.godot` foi alterado nesta etapa.



## 2026-06-04 - Catalogo de Itens V0

- O projeto ganhou um catálogo central mínimo de itens em `Scripts/Database.gd`.

- Pesca, crops e sementes existentes passaram a ter metadados básicos como nome, categoria, raridade, valor_base, tags e origem.

- A UI de inventário passou a consultar o catálogo primeiro para obter ícones/emoji dos itens.

- Nenhuma receita nova foi criada e nenhum balanceamento final foi definido.



## 2026-06-04 - Visibilidade da área com movimento corrigida

- A `MovingFishingArea` do Lago da Fazenda V0 foi reforçada visualmente para aparecer de forma clara no runtime.

- O ponto especial agora tem brilho, anel e pulso mais legíveis, sem mudar a lógica de boost da pesca.

- A pesca fora da área especial continua funcionando normalmente.



## 2026-06-04 - Áreas com Movimento V0 da pesca

- O Lago da Fazenda V0 ganhou uma área especial visível com movimento sutil no cenário.

- Lançar a boia dentro da área favorecida pode promover um resultado `GOOD` para `PERFECT` no popup de sincronia.

- O resto do fluxo da pesca continua igual: boia, puxada fake, popup e recompensa V0 permanecem intactos.



## 2026-06-04 - Recompensa Aquática V0

- O popup de sincronia da pesca passou a gerar recompensas simples no inventário real.

- Bom agora adiciona `peixe_comum`; Perfeito agora adiciona `escama_brilhante`; Errou nao gera item.

- A UI do inventário passa a refletir essas recompensas sem criar um sistema novo de inventário.

- Ainda nao há conexão com caldeirao, receitas ou árvore de alquimia.



## 2026-06-04 - Input do popup de sincronia ajustado

- O Popup de Sincronia V0 da pesca agora aceita tecla Espaço e clique em qualquer área da janela, consumindo esse input para não vazar para outros handlers.

- O Lago da Fazenda V0 passa a bloquear novo lançamento enquanto a sincronia está aberta.

- A identidade da Pesca de Ressonância foi reforçada com textos próprios e resultado fake.

- Ao encerrar o minigame, a Vara de Pesca é forçada como ferramenta ativa para permitir pesca contínua.

- A seleção forçada evita depender do toggle de `select_fishing_rod()`.

- Nenhuma recompensa extra foi adicionada além do fluxo V0 simples.



## 2026-06-04 - Popup de Sincronia V0 da pesca

- O Lago da Fazenda V0 agora abre um popup simples de Pesca de Ressonância quando a puxada fake está ativa e o jogador clica novamente com a Vara de Pesca.

- O popup mostra barra, zona de acerto, marcador móvel e resultados Errou/Bom/Perfeito, com recompensa simples no V0.

- Nenhuma regra de gameplay foi alterada; o lago, a boia e o loop agrícola continuam intactos.



## 2026-06-04 - Limpeza de logs do lago

- Os logs temporários de carregamento do Lago da Fazenda V0 foram removidos após a validação visual no jogo principal.

- Os logs curtos de interação da pesca continuam por enquanto, para ajudar nos testes de lançamento, reposicionamento e puxada fake.

- Nenhuma regra de gameplay foi alterada.



## 2026-06-04 - Puxada Fake V0 da pesca

- O Lago da Fazenda V0 agora entra em um estado de puxada fake alguns segundos depois do lançamento da boia.

- A boia muda visualmente e o jogo mostra que algo puxou a linha, mas ainda nao existe minigame nem recompensa.

- Se o jogador clicar de novo com a Vara ativa durante a puxada fake, o teste é encerrado e volta para o estado inicial.



## 2026-06-04 - Boia V0 da pesca

- O Lago da Fazenda V0 ganhou uma boia visual simples que aparece no ponto clicado quando a `Vara de Pesca` está ativa.

- Clicar novamente com a Vara reposiciona a mesma boia, sem criar boias novas.

- Ainda nao existe minigame, puxada, recompensa ou integração com inventário/caldeirão.



## 2026-06-04 - Lago da Fazenda V0

- O jogo principal recebeu um `FishingSpot` físico/clicável como base do Lago da Fazenda V0.

- O clique no lago agora responde com a `Vara de Pesca` ativa, exibindo apenas feedback de lancamento por enquanto.

- Ainda nao existe minigame, recompensa, areas especiais ou integracao com inventario/caldeirao.



## 2026-06-04 - Vara de Pesca visual na toolbar

- A toolbar principal recebeu a `Vara de Pesca` como ferramenta visual/global, com ícone provisório e tecla `4`.

- A ferramenta ainda nao aciona pesca real; ela serve como base de selecao para o sistema futuro no lago da fazenda.

- O estado visual e o StatusPanel continuam funcionando sem alterar o loop agricola.



## 2026-06-04 - Documento de pesca

- Foi documentado o Fishing System - Pesca de Ressonancia como direção de gameplay para o lago da fazenda.

- A pesca foi registrada como sistema integrado ao lago físico, com áreas especiais opcionais que aumentam a chance de recompensas melhores.

- A implementação ainda não foi feita; esta etapa é apenas de documentação.



## 2026-06-04 - Limpeza de logs repetitivos

- O console foi limpo para reduzir ruído de ações comuns do jogador.

- A água continua funcionando normalmente no inventário real, mas seus logs foram filtrados para nao poluir o debug.

- O feedback visual do `FarmPlot` passou a ser a referencia principal para arar, regar, plantar e colher.



## 2026-06-03 - Feedback visual das ferramentas

- Enxada, Regador, Colheita e os avisos principais do `FarmPlot` passaram a aparecer também como feedback flutuante na tela, além do console.

- O comportamento do gameplay nao mudou; a mudanca foi de comunicacao visual para o jogador.

- O `FarmPlot` continua ativo, o `FarmGrid` continua isolado e a UI reaproveita o helper de texto flutuante existente.



## Checkpoint - Loop de Ferramentas V0

- O jogo principal agora opera com `ToolManager` como controle global de ferramenta ativa.

- Ferramentas com ação real no `FarmPlot`: Enxada prepara lote vazio, Regador rega lote e Colheita colhe lote pronto.

- Semente ficou como item do inventário no jogo principal; a Semente fake continua apenas no `FarmGridPreview`.

- A prioridade de clique ficou: ferramenta ativa primeiro, semente selecionada depois, evitando plantio acidental.

- Água aparece no `StatusPanel`, sai da lista visual comum de inventário e continua armazenada em `GlobalInventory.inventario["agua"]`.

- O Decay Diário segue manual/debug pelo Debug Panel e limpa apenas lotes vazios e arados sem semente.

- `FarmPlot` continua ativo, `FarmGrid` continua isolado e a Área Preparável V0 segue com lotes potenciais pré-instanciados.



## 2026-06-03 - Colheita V0 por ferramenta

- A ferramenta `Colheita` passou a colher lotes prontos no jogo principal usando a mesma lógica manual de recompensa do `FarmPlot`.

- Bonus e drops raros continuam sendo gerados pelo fluxo existente; o golem nao foi alterado.

- Isso ainda nao conecta o FarmGrid ao gameplay e nao cria novo sistema de inventario.



## 2026-06-03 - Decay Diario V0 manual

- O jogo principal ganhou um botao de Debug Panel para simular manualmente a virada do dia em lotes `arado` vazios.

- Lotes vazios e arados voltam ao estado natural; lotes plantados ou prontos para colher permanecem intactos.

- Isso ainda nao usa tempo real e nao altera o FarmGrid, o save ou o golem.



## 2026-06-03 - Visual da Area Preparavel

- O `FarmPlot` passou a distinguir melhor solo natural, terra arada seca e terra arada molhada usando o visual ja existente.

- Lotes nao arados agora usam uma aparencia natural provisoria mais esverdeada; terra arada seca/molhada continua com as texturas adubadas.

- Nenhuma regra de save, golem ou FarmGrid foi alterada.



## 2026-06-03 - Area Preparavel V0

- A cena principal passou a manter os 16 `FarmPlot` antigos na mesma ordem e posicao e adicionar novos lotes potenciais no final da sequencia.

- A Enxada agora pode preparar esses lotes potenciais sem criar lotes livres por clique, e o save continua compatível por indice.

- O FarmGrid continua isolado; esta etapa ainda usa `FarmPlot` e uma grade fixa expandida.



## 2026-06-03 - Enxada V0 no FarmPlot

- A Enxada V0 passou a agir nos `FarmPlot` atuais: lote vazio pode ser preparado/arado e o estado é preservado no save.

- O plantio agora respeita lote arado, evitando plantio acidental em terra ainda nao preparada quando a ferramenta ativa esta em `Nenhuma`.

- Isso nao cria aragem livre nem conecta o FarmGrid ao gameplay; o `FarmGridPreview` continua isolado e a toolbar principal continua apenas como selecao global.



## 2026-06-03 - Separação entre ferramentas, sementes e água

- Foi documentada a separação entre ferramentas como modo de ação, sementes como itens do inventário e água como recurso visual separado no StatusPanel.

- O inventário visual continua escondendo a água, enquanto o `FarmPlot` e o `SaveManager` seguem usando `GlobalInventory.inventario["agua"]` internamente.

- Nenhum script ou cena foi alterado nesta anotação; a mudança aqui é só de arquitetura/documentação.



## 2026-06-03 - Agua no StatusPanel e prioridade de ferramenta

- O StatusPanel voltou a mostrar claramente `Água: X`, lendo diretamente `GlobalInventory.inventario["agua"]`.

- A ferramenta ativa do `ToolManager` passou a ter prioridade sobre a semente selecionada no lote: Regador rega antes de qualquer plantio, e Enxada/Colheita bloqueiam plantio acidental.

- A água continua fora da lista visual comum de inventário; ela segue só como contador no StatusPanel.



## 2026-06-03 - Agua separada do inventario visual

- A agua continua armazenada internamente em `GlobalInventory.inventario["agua"]`, mas deixou de aparecer como item comum na barra visual de inventário.

- O StatusPanel passou a ser a referencia visual principal da água, mostrando o contador separado do restante do inventário.

- Nenhuma regra de gameplay foi alterada; salvar, carregar, FarmPlot e PocoManager continuam usando a agua normalmente por baixo.



## 2026-06-03 - Toolbar principal ajustada

- A Barra de Ferramentas V0 do jogo principal passou a exibir apenas Enxada, Regador e Colheita.

- Os botões de ferramenta agora funcionam como liga/desliga: selecionar a mesma ferramenta novamente volta para Nenhuma.

- A Semente continua existindo apenas no FarmGridPreview como ferramenta fake de teste.



## 2026-06-03 - Icones provisorios da barra de ferramentas

- A Barra de Ferramentas V0 recebeu icones provisórios para Enxada, Semente, Regador e Colheita.

- Os botões continuam apenas como selecao visual/global, sem acionar gameplay real.

- O destaque textual e os atalhos permanecem funcionando como antes.



## 2026-06-02 - Limpeza tecnica da UI

- O print temporario `DEBUG UI: botão livro de receitas clicado` foi removido da UI principal.

- Nenhuma regra de gameplay foi alterada; o Livro de Receitas continua abrindo normalmente.



## 2026-06-02 - Ferramenta Ativa V0 expandida

- A seleção global de ferramentas no jogo principal passou a incluir `Enxada`, `Semente`, `Regador` e `Colheita`.

- A troca acontece por botões na UI e pelas teclas `1`, `2`, `3` e `4`.

- A seleção continua apenas visual/global e ainda não altera gameplay.



## 2026-06-02 - Limpeza tecnica de logs

- O `ToolManager` passou a evitar log repetido quando a mesma ferramenta ja estava selecionada.

- O caldeirao teve removido o print temporario `DEBUG Cauldron: clique recebido`.

- Nenhuma regra de gameplay foi alterada nessa limpeza.



## 2026-06-02 - Ferramenta Ativa V0 no jogo principal

- O projeto ganhou a base de ferramenta ativa global com `ToolManager` como `Autoload`.

- A primeira ferramenta real e apenas visual/global e a `Enxada`, selecionada por botao na UI e pela tecla `1`.

- Nada disso altera o `FarmPlot` nem o gameplay de arar ainda.



## 2026-06-02 - PocoManager ignora cenas dev

- O `PocoManager` passou a ignorar cenas em `res://Scenes/dev/`, evitando gerar agua automaticamente durante testes isolados.

- O comportamento normal do jogo principal permanece igual, porque a guarda so vale para cenas de desenvolvimento.



## 2026-06-02 - Checkpoint do FarmGrid

- O projeto registrou um checkpoint oficial para o FarmGrid V2, deixando claro o que o preview ja validou e o que continua fake.

- O `FarmPlot` foi reafirmado como sistema ativo enquanto o grid permanece em laboratorio.

- A pendencia de logs globais em cenas dev foi documentada como item tecnico em aberto.



## 2026-06-02 - Preview do FarmGrid com colheita fake

- O preview isolado do FarmGrid passou a testar uma ferramenta fake de `Colheita`, selecionada por tecla `4`.

- Crop madura fake agora pode ser colhida em memoria, limpando o tile e devolvendo o estado para `ARADO`.

- Isso completa o loop minimo do preview sem conectar nada ao `FarmPlot` ativo.



## 2026-06-02 - Preview do FarmGrid com crescimento fake

- O preview isolado do FarmGrid passou a simular crescimento fake com a tecla `G`, avancando `remaining_growth_time` apenas em tiles plantados e irrigados.

- O marcador visual do plantio agora muda de tamanho conforme o estagio de crescimento, sem conectar nada ao gameplay principal.

- O `Decay Diario` continua isolado e o `FarmPlot` segue intocado.



## 2026-06-02 - Preview do FarmGrid com Regador fake

- O preview isolado do FarmGrid passou a testar uma ferramenta fake de `Regador`, com seleção por tecla `3`.

- Tiles `ARADO` passam a virar `MOLHADO`, e tiles `PLANTADO` ganham estado de água visual no preview.

- O decay diário agora pode retirar água de tiles plantados sem desmontar o plantio fake.

- Tudo continua isolado e sem conexão com o `FarmPlot` ativo.



## 2026-06-02 - Preview do FarmGrid com Semente fake

- O preview isolado do FarmGrid passou a testar uma ferramenta fake de `Semente`, além da `Enxada` para arar tiles.

- A cena agora planta um crop de debug em memória, permitindo validar a regra de que tiles plantados não voltam para grama no decay diário.

- Isso continua isolado e sem conectar o `FarmPlot` ao gameplay principal.



## 2026-06-02 - Preview do FarmGrid com Enxada e decay

- O preview isolado do FarmGrid passou a testar uma ferramenta ativa simples, com `Enxada` como padrão para arar tiles de grama.

- A cena também ganhou um `Decay Diario` em memória, que limpa tiles arados ou molhados sem crop e devolve o estado para grama.

- Isso continua isolado, sem conectar o `FarmPlot` ao gameplay principal.



## 2026-06-02 - Preview do FarmGrid com Solo Vivo

- O preview isolado do FarmGrid passou a visualizar o tipo de solo alquimico com borda colorida.

- Clique direito alterna `soil_type` em memória, sem mexer no `FarmPlot` ativo.

- A cena continua apenas como laboratório visual para a fundação do Farm System V2.



## 2026-06-02 - Preview visual do FarmGrid

- Criação de `Scenes/dev/FarmGridPreview.tscn` e `Scripts/dev/FarmGridPreview.gd` como preview visual isolado do grid futuro.

- A cena desenha um grid 5x5 em memória, alterna estados de tile ao clique e não conecta nada ao gameplay principal.

- O sistema atual de `FarmPlot` continua intocado e ativo no jogo normal.



## 2026-06-02 - Debug runner do FarmGrid

- Adição do botão temporário `Testar FarmGrid` no Debug Panel para executar `FarmGridManagerSmokeTest` manualmente.

- O botão roda apenas o teste isolado em memória e mostra o resultado no console e na última ação do painel.

- Nenhuma mecânica do jogo foi conectada; `FarmPlot` continua sendo o sistema ativo.



## 2026-06-02 - Smoke test do FarmGridManager

- Criação de `Scripts/dev/FarmGridManagerSmokeTest.gd` como teste manual isolado para validar `FarmGridManager` e `FarmTileData` em memória.

- O teste confirma criação de grid, acesso a tiles e serialização save/load sem conectar ao gameplay.

- Continua sendo uma ferramenta de desenvolvimento, não uma mecânica do jogo.



## 2026-06-02 - FarmGridManager base

- Criação de `Scripts/data/FarmGridManager.gd` como gerenciador isolado de dados para o Farm System V2.

- O gerenciador funciona como `RefCounted`, sem cena, sem Autoload e sem conexão com o gameplay atual.

- A estrutura já prepara criação, leitura e serialização futura de grids com `FarmTileData`.



## 2026-06-02 - FarmTileData base

- Criação de `Scripts/data/FarmTileData.gd` como `Resource` isolado para representar tiles futuros do Farm System V2.

- O recurso ainda não é usado no gameplay atual; `FarmPlot` continua sendo o sistema ativo.

- A base já inclui campos de solo, crop, umidade, modificadores e dados de save para a futura fazenda em grid.



## 2026-06-02 - Farm System V2 documentado

- Criação de `docs/FARM_SYSTEM_V2.md` para registrar a visão futura de fazenda baseada em tiles/grid.

- A documentação define o conceito de Solo Vivo Alquímico, integração com caldeirão, pesca, fazendinhas e golems.

- O sistema atual de lotes continua sendo a base funcional do protótipo.



## 2026-06-02 - Base do TimeManager

- Criação de `Scripts/TimeManager.gd` como fundação técnica para o sistema futuro de tempo real e debug.

- O script ainda não está conectado ao gameplay, não é Autoload e mantém o modo real desligado por padrão.

- A integração com `SeasonManager`, `SaveManager`, plantações, golems e UI continua para fases futuras.



## 2026-06-01 - Documento de tempo real

- Criação do documento `docs/TIME_SYSTEM.md` para registrar a direção futura do tempo real do jogo.

- O sistema final de tempo ficou documentado como tempo real, mas o protótipo continua em modo debug/controlável por enquanto.

- Nenhuma lógica de tempo foi implementada nesta etapa.



## 2026-06-01 - Status do jogo V1

- Expansão do `StatusPanel` existente na UI principal para mostrar moedas, estação, ano, água, alquimia, golems e estado do Baú da Vila.

- A atualização do status é informativa e provisória, pensada para teste rápido do protótipo.

- A barra de status não interfere no caldeirão, no Livro de Receitas ou no Debug Panel.



## 2026-06-01 - Save minimo dos lotes

- O save passou a registrar o estado dos lotes de plantacao em um array ordenado por `lotes_terra`.

- O carregamento restaura estado, semente, rega, tempo restante e estado de colheita sem quebrar saves antigos.

- O comportamento continua minimo e provisório; o mundo completo ainda não é salvo.



## 2026-06-01 - Popup da UI liberado

- O popup do caldeirão passou a reativar o `PopupLayer` ao abrir, evitando que a interface fique escondida mesmo quando o clique chega ao handler.

- O Livro de Receitas também passou a garantir que o `PopupLayer` do caldeirão esteja visível ao ser aberto, porque ele é instanciado dentro dessa camada.

- A lógica de abertura continua a mesma; a correção foi só de visibilidade e camada.



## 2026-05-31

- Criação da documentação inicial do projeto.

- Registro do estado atual do projeto para continuidade entre sessões.

- Auto-colheita do `GolemManager` desativada temporariamente com flag para permitir teste manual do loop principal.



## 2026-05-31 - Inventário e caldeirão

- Correção do clique direito nos slots do inventário para permitir venda/ação secundária.

- Adição de fallback de caminho para ícones de item em `InventorySlot` e `DropSlot`.

- Melhoria das mensagens de aviso quando o item não possui imagem associada.



## 2026-05-31 - Salvamento mínimo

- Criação do `SaveManager` como Autoload para salvar e carregar progresso básico do protótipo.

- Salvamento em `user://savegame.json`.

- Inclusão de atalhos temporários de teste: `F5` para salvar e `F9` para carregar.

- Escopo inicial do save: inventário, receitas descobertas, pontos de alquimia, moedas, estação, ano, água e quests simples.



## 2026-05-31 - Livro de receitas

- Criação da primeira versão do Livro de Receitas para consultar receitas descobertas.

- Integração do livro na UI principal com botão dedicado.

- Exibição de ingredientes, resultado e quantidade maxima fabricavel com base no inventário atual.

- Consulta separada da produção em lote, que fica para uma etapa futura.



## 2026-05-31 - Livro e lote

- O Livro de Receitas passou a ficar acima do caldeirão para evitar conflito visual com o popup de mistura.

- Adição de produção em lote a partir do Livro de Receitas.

- Inclusão de barra de progresso abaixo do caldeirão para acompanhar o lote em andamento.

- Clique no caldeirão agora cancela a produção em lote e devolve os ingredientes ainda não processados.

- O Livro passou a atualizar a quantidade máxima fabricável conforme o inventário muda.



## 2026-05-31 - Colheita compartilhada

- A lógica de recompensas da colheita passou a ser compartilhada entre a colheita manual e o Golem Coletor V1.

- O golem agora deposita todos os bônus coletados no Baú da Vila, em vez de apenas um item básico.

- A deposição do golem ganhou feedback flutuante resumido no mundo.

- O fluxo principal continua igual para o jogador; a mudança só alinhou as recompensas entre manual e automatizado.



## 2026-05-31 - Cancelamento visível do lote

- Adição do botão `Cancelar producao` na área da barra de progresso do caldeirão.

- O cancelamento agora devolve os ingredientes das unidades restantes do lote.

- O cancelamento por clique no caldeirão foi mantido como atalho secundário.

- Redução dos prints de diagnóstico agora que o vínculo do caldeirão já está validado.

- A interface de lote continua provisória, mas mais clara para teste manual.



## 2026-05-31 - UI provisoria do caldeirao

- Substituição da imagem decorativa antiga do popup por um placeholder temporário próprio do projeto.

- Reorganização visual do popup do caldeirão para acomodar slots, botões, resultado e área de produção em lote com mais folga.

- Nenhuma mudança na lógica da produção em lote.

- A arte final do caldeirão continua para depois.



## 2026-05-31 - Fundo de rocha da UI

- Criação de um placeholder pixel art de rocha para o fundo do popup do caldeirão.

- Aplicação do fundo como `NinePatchRect` para preencher o popup de forma estável.

- Manutenção da UI e da lógica do caldeirão como provisórias, apenas com ajuste visual.



## 2026-05-31 - Fonte pixel art provisoria

- Adoção da fonte Pixelify Sans para a interface principal, popup do caldeirão e Livro de Receitas.

- Caminho da fonte: `res://Assets/fonts/PixelifySans-Regular.ttf`.

- Licença registrada em `res://Assets/fonts/OFL.txt` sob SIL Open Font License 1.1.

- Criação do tema provisório `res://Themes/pixel_ui_theme.tres`.

- Decisão explícita de não usar fonte Minecraft nem clone direto.

- A fonte foi verificada com textos em português contendo acentos.



## 2026-05-31 - Esquema de receitas

- Criação da documentação técnica `docs/RECIPES_SCHEMA.md`.

- Registro do formato atual das receitas em `Database.gd`.

- Comparação entre `Resource .tres`, JSON e CSV para a migração futura.

- Recomendação documentada: manter o protótipo no formato atual por enquanto e migrar depois para `Resource .tres`.



## 2026-05-31 - Estrutura inicial de Resource para receitas

- Criação do `RecipeData` em `Scripts/data/RecipeData.gd` como base tipada para receitas.

- Criação de duas receitas `.tres` de teste em `Data/recipes/` para validar a estrutura sem conectar o jogo ainda.

- Manutenção do fluxo atual do caldeirao e do Livro de Receitas sem alteracoes.

- Preparacao para um futuro `RecipeDatabase.gd` que consiga ler `Resource` e comparar com o sistema antigo.



## 2026-05-31 - Leitor estrutural de receitas

- Criação de `Scripts/data/RecipeDatabase.gd` como leitor apenas de validação.

- Carregamento de receitas `.tres` de `res://Data/recipes/` sem substituir o sistema antigo.

- Validação basica de campos obrigatorios de `RecipeData`.

- Comparacao dos ids de Resources com `Database.receitas_alquimia` para orientar a migracao futura.



## 2026-05-31 - Livro de Receitas em paralelo

- O Livro de Receitas passou a usar `RecipeDatabase` para exibir dados ricos quando o `RecipeData` existe e esta completo.

- O fallback antigo com `Database.receitas_alquimia` continua obrigatório e ativo.

- A produção em lote segue usando somente o sistema legado por enquanto.

- A exibição rica melhora nome, descricao, categoria, ingredientes, resultado e tempo sem trocar o fluxo principal.



## 2026-05-31 - Cobertura total das receitas legadas

- Criação dos `.tres` faltantes em `Data/recipes/` para cobrir todas as receitas atuais do sistema legado.

- O `RecipeDatabase` agora possui cobertura completa do catálogo legado atual.

- `Database.gd` continua sendo a fonte funcional da produção e do caldeirão.

- A camada `RecipeDatabase` segue sendo apenas leitura e apresentacao por enquanto.



## 2026-05-31 - Golem Coletor V1

- Criação do Baú da Vila V1 como alvo físico simples para depósito.

- Anexação do `Golem.gd` à cena do golem físico.

- O golem físico agora procura lote maduro, colhe 1 item e deposita no baú.

- `FarmPlot` passou a oferecer uma colheita segura para o golem via `harvest_by_golem()`.

- `GolemManager` continua desligado e a colheita invisível segue desativada.

- O Baú da Vila ainda não tem UI nem salvamento.



## 2026-05-31 - UI do Baú da Vila

- Criação de uma interface simples para o Baú da Vila com lista textual de conteúdo.

- Adição de clique no baú para abrir o painel pela UI principal.

- Adição do botão `Retirar Tudo`, transferindo itens para o inventário global.

- O baú continua separado do inventário do jogador; salvamento fica para depois.

- A retirada individual ainda não existe nesta etapa.



## 2026-05-31 - Presenca fisica do golem

- Ajuste de ordem visual por Y para o golem, baú e lotes usando z_index dinâmico.

- O golem agora usa um ponto de interação separado do centro visual da crop.

- Criação de um sensor simples para fazer as crops balançarem quando o golem passa perto.

- O movimento continua em linha reta; pathfinding completo fica para depois.



## 2026-05-31 - Navegacao do golem

- O golem passou a usar `NavigationAgent2D` para mover-se em direção a lotes e ao Baú da Vila.

- O caldeirão ganhou obstáculo físico simples para evitar travessia direta no mundo.

- A cena principal agora cria uma região de navegação simples cobrindo a área jogável inicial.

- O ajuste visual manteve o golem acima do solo arado durante o deslocamento.

- A solução é provisória e ainda não substitui um sistema completo de pathfinding com obstáculos refinados.



## 2026-05-31 - Colisao fisica do golem

- O golem físico passou a usar `CharacterBody2D` com colisão própria para respeitar obstáculos do mundo.

- O caldeirão continua sendo tratado como obstáculo físico do cenário.

- A navegação segue simples e apoiada por `NavigationAgent2D`, mas agora o corpo físico impede atravessar o caldeirão.

- A ordem visual dos lotes continua baseada em Y, com o golem acima do solo arado sem usar rota manual em L.



## 2026-05-31 - Desvio ao travar

- O golem agora detecta quando ficou travado contra o caldeirão ou outro obstáculo.

- Ao travar, ele calcula um desvio simples ao redor do caldeirão e tenta retomar o destino original.

- O destino final e o callback da ação continuam preservados durante o desvio.

- Se o travamento se repetir demais, a tentativa atual pode ser abortada com aviso.

- O comportamento segue provisório e ainda depende de refinamento futuro da região de navegação.



## 2026-05-31 - Camada visual do campo

- A terra arada e a base do lote passaram a ficar em camada visual baixa, separada da planta.

- O golem passou a usar um `z_index` levemente acima do campo para não ficar escondido pela terra arada.

- Tooltip, VFX e efeitos de colheita continuam acima dos visuais principais do lote.

- A ordenação por Y do protótipo foi mantida, só com offsets mais seguros para leitura.



## 2026-05-31 - Terra fora da herança visual

- A terra arada e o visual de solo deixaram de herdar a ordenação do `FarmPlot`.

- Isso evita que lotes mais abaixo na tela cubram parcialmente o golem quando ele passa entre as plantações.

- A crop continua com camada própria e os efeitos/tooltip seguem acima.

- A solução ainda é provisória e pode virar um sistema formal de camadas depois.



## 2026-06-01 - Save do Baú da Vila

- O conteúdo do Baú da Vila passou a entrar no save mínimo em `village_chest_inventory`.

- Saves antigos continuam compatíveis mesmo sem esse campo novo.

- O estado dos lotes e das crops continua fora do salvamento por enquanto.

- A UI do baú é atualizada novamente após o load quando a cena já está em jogo.



## 2026-06-01 - Debug Panel V1

- Criação de um painel temporário de debug na UI principal para acelerar testes do protótipo.

- O painel abre e fecha com `F10` e não aparece no fluxo normal do jogo.

- Ferramentas incluídas para inventário, receitas, lotes, save e Baú da Vila.

- O painel é apenas de protótipo e não substitui sistemas reais de progressão.



## 2026-06-01 - Debug Panel e input

- Ajuste do `DebugPanel` para não bloquear cliques do mundo quando está fechado.

- O painel agora fica em `mouse_filter = Ignore` ao fechar e só captura input dentro da própria área quando aberto.

- O fluxo normal de caldeirão e Livro de Receitas volta a receber clique normalmente com o painel fechado.



## 2026-06-01 - UI e input

- Os painéis temporários e modais da UI passaram a usar `mouse_filter = Ignore` quando fechados.

- `RecipeBookUI`, `QuestBoard`, `SkillTree`, `SellMenu`, `VillageChestPanel` e `DebugPanel` só bloqueiam input quando estão visíveis.

- A UI principal voltou a deixar o clique do mundo passar quando nenhum painel está aberto.
