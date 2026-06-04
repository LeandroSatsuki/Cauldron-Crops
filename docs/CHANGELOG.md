# Changelog

## 2026-06-04 - Lago da Fazenda V0
- O jogo principal recebeu um `FishingSpot` físico/clicável como base do Lago da Fazenda V0.
- O clique no lago agora responde com a `Vara de Pesca` ativa, exibindo apenas feedback de lancamento por enquanto.
- Ainda nao existe boia, minigame, recompensa, areas especiais ou integracao com inventario/caldeirao.

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
