# Evolução do Projeto

## Etapa ativa — Coexistência de objetivos, produção e HUD / testes manuais adiados (2026-10-03)

Baseline reproduziu objetivo da Clareira encobrindo aviso do caldeirão. Ambos agora buscam espaço livre de tela, considerando Mochila, ferramentas, botões visíveis do Caderno e objetivos iniciais arrastados. Produção tem prioridade; tracker evita seu retângulo. Altura natural do tracker acompanha conteúdo/minimização; resize e eventos de layout recalculam posições. Área vazia do VBox legado das lojas não é tratada como botão visível. Sem mudança de estoque, timers, progresso ou save.

`HUDPanelCoexistenceSmokeTest`: 305 verificações em cinco resoluções, resultado pronto/preparo/lote ativo/lote pausado/cancelamento pendente, arraste, minimização, acesso geométrico ao cancelamento e estados invariáveis. Manual continua adiado: coexistência durante gameplay, arraste/resize, minimizar e interagir com baú/caldeirão sem captura indevida de cliques. Resoluções menores que 800×720 e posições arbitrárias sem espaço livre não recebem aceite de usabilidade.

Suíte completa 43/43, importação sem erros e inspeção técnica OpenGL/D3D12. Save pessoal intacto por hash/tamanho/data; avisos transitórios de ações não fazem parte desta coordenação dos painéis persistentes.

Próximo incremento recomendado: consolidar o checklist integrado das pendências manuais e auditar os riscos técnicos restantes do recorte atual antes de ampliar conteúdo. Não presumir fechamento artístico ou aprovação manual.

## Checkpoint anterior — Orientação contextual da expedição (2026-10-03)

Objetivo troca instruções estáticas por próxima ação: reunir carvão faltante, preparar quantidade faltante, retirar do baú quando há mistura, aguardar/recolher no caldeirão ou resolver cancelamento pendente. Com carga suficiente, levar ao Bosque/interagir com a Clareira conforme região. Consulta somente leitura de HOME/cache; nenhuma transferência, produção automática ou alteração de progressão/save.

`GroveObjectiveGuidanceSmokeTest`: 37 verificações de contexto/estoques/produção, viagem real/cache, JSON, minimização e três resoluções; suíte 42/42, importação e inspeção OpenGL/D3D12. Manual adiado: transições de orientação em gameplay, produção, depósito/retirada/viagem e minimização. Coexistência global de painéis/conforto/arte não presumidos aprovados.

Próximo incremento recomendado: conferir coexistência dos painéis de objetivos/produção/HUD e corrigir sobreposições concretas durante gameplay, sem novos sistemas/conteúdo.

## Checkpoint anterior — Requisitos de restauração claros (2026-10-03)

Herbário apresenta disponível/necessário somando Baú da Vila e Mochila, com recusa de materiais/recompensa e orientação de depósito/nova tentativa. Clareira conta apenas misturas na Mochila e explica que o baú remoto não é usado. Consultas não consomem recursos; custos, recompensas, marcos, transações e save preservados. Textos contrastados/quebrados; avisos do Herbário substituem anteriores, sem empilhar.

Regressão `RestorationFeedbackSmokeTest`: 18 verificações; suíte 41/41, importação e inspeção OpenGL/D3D12. Manual adiado: legibilidade sobre o mapa, contadores após transferir no baú, falta de materiais/espaço e retry, visita à Clareira com carga na Mochila versus baú. Pendências anteriores continuam separadas, sem aprovação presumida.

Próximo incremento recomendado: revisar orientação do objetivo da expedição para indicar a próxima ação conforme descoberta, materiais disponíveis e mistura carregada, evitando instruções repetidas/desatualizadas. Sem novas etapas de progressão, quests ou recompensas.

## Checkpoint anterior — Avisos de capacidade na pesca/coleta (2026-10-03)

Recusa de coleta informa quantidade/item, preservação no chão e depósito/retorno. Pesca distingue falta de espaço antes da sincronia de captura já obtida/preservada, listando itens e explicando entrega automática integral. Avisos curtos de capacidade permanecem quatro segundos antes de sumir; no lago, posição contida na tela sem capturar input. Painel da pesca opaco, textos quebrados e reposicionamento mantêm Fechar acessível em janela menor.

`CollectionCapacityFeedbackSmokeTest`: 18 verificações, três resoluções, recusa/retenção, duração, captura dupla, JSON e depósito → retomada única. Suíte 40/40, importação e OpenGL/D3D12 conferidos. Manual adiado: leitura no mundo, voltar do Bosque após depósito, captura bloqueada na sincronia/fechar/load/liberar espaço. Sem alteração de aquisição, recompensas, coleção, capacidade, persistência ou armazenamento remoto.

Próximo incremento recomendado: revisar clareza dos requisitos/recusas da restauração já existente (Herbário e Clareira), distinguindo recursos da Mochila e acesso ao armazenamento da vila. Sem novos projetos/recompensas ou expansão de sistemas.

## Checkpoint anterior — Avisos persistentes do caldeirão (2026-10-03)

Produção manual, resultado pronto, lote em andamento/sem espaço e cancelamento pendente agora têm aviso opaco fixo no canto inferior direito. Exibe resultado/quantidade, preparos entregues, tempo e orientação para liberar espaço/recolher ou repetir cancelamento. Resize, câmera e retorno ao cache não deslocam o aviso para fora da tela. Sem alterar receitas, timers, destino, reservas, restituição ou save.

Regressão `CauldronFeedbackSmokeTest`: 87 verificações, três resoluções de 800×720 a 1280×720, JSON em memória, entrega e cancelamento/restituição com capacidade bloqueada. Suíte 39/39; conferência técnica OpenGL/D3D12. Checklist manual adiado: clareza durante produção, depósito no baú e retry de resultado/cancelamento, câmera/resize e retorno do Bosque. Picking real, conforto e arte não são aprovados por esses testes.

Próximo incremento recomendado: revisar e uniformizar avisos de Mochila cheia na pesca/coleta existentes, preservando recursos/capturas pendentes. Não ampliar conteúdo/economia/NPCs automaticamente.

## Checkpoint anterior — Caldeirão e Livro adaptados (2026-10-03)

Continuidade autorizada após a HUD responsiva: popup do caldeirão com fundo opaco, slots delineados e botões dentro da borda. Layout compacto de 320 px de altura em janela baixa, mantendo a Mochila acessível acima em janela estreita. Livro adapta tamanho, quebra títulos/textos e oferece rolagem nos detalhes com acompanhamento do foco. Arraste e posições runtime-only preservados; resize contém os painéis. Custos, tempos, origem dos ingredientes, produção/cancelamento e save não mudam.

Regressão `AlchemyDialogLayoutSmokeTest`: 131 verificações, catálogo inteiro, descrição longa sintética, cinco resoluções de 800×600 a 1920×1080, drop/captura do fundo, troca de popup, lote de duas unidades, restituição à origem e fechamento nos dois hosts. Inspeção técnica OpenGL/D3D12. Checklist manual adiado: arrastar ingredientes da Mochila, experimentar mistura, navegar/rolar receitas, digitar quantidade, produzir/cancelar e fechar/reabrir/redimensionar/arrastar os painéis. Picking real e conforto/arte não são aprovados pela regressão.

Próximo incremento recomendado: clareza dos estados existentes de produção, resultado pronto e falta de espaço, sem criar fila/destino novo ou mudar receitas. Casos manuais da expedição e capacidade continuam separados e pendentes abaixo.

## Checkpoint anterior — HUD responsiva (2026-10-03)

O autor informou que não poderá testar agora e autorizou continuar a construção, consolidando um checklist posteriormente. Não aguardar cada roteiro manual para executar incrementos delimitados e verificáveis; manter pendências explícitas, sem convertê-las em aprovação. A segunda expedição permanece implementada, com aceites parciais preservados abaixo.

Checkpoint: Mochila adapta largura e quantidade de slots por página à janela, até 12; ferramentas usam ícone/número com tooltip em modo compacto. Objetivos permanecem arrastáveis/minimizáveis, com botão acompanhando o painel e posição contida na janela. Resize feito no Bosque é aplicado no retorno à HOME em cache. Capacidade 12/16/20, estoques, seleção e save v4 não mudam.

Validação: regressão nova com 230 verificações, cinco resoluções (800×720, 1024×768, 1280×720, 1920×1080 e 2560×1440), renderização OpenGL/D3D12 e suíte completa 37/37. Baseline sem o componente reproduziu a sobreposição. Isto não valida picking do sistema operacional, conforto ou direção artística; larguras abaixo de 800 e alturas menores não têm aceite de usabilidade.

Fila manual adiada: produção em viagem (concluir/cancelar em lotes separados), save anterior à restauração sem apagar progresso, intervalo da fonte renovável, captura pendente, bloqueios do caldeirão por capacidade, saves legados reais, conforto/arte/balanceamento e resize/paginação/objetivos da HUD. Manter os roteiros existentes para compor o checklist futuro.

Próximo incremento recomendado: legibilidade e adaptação dos painéis do caldeirão/Livro em janelas menores, após analisar seus contratos. Não iniciar economia, NPCs ou novos sistemas por consequência desta autorização.

## Baseline anterior — Segunda expedição / Clareira recuperável (2026-10-03)

Autor escolheu novo conteúdo e autorizou iniciar o recorte grande. Implementados descoberta → carvão → preparo no caldeirão da vila → retorno com 2 misturas na Mochila → restauração externa → receita agrícola útil. Uma subárea do Bosque existente, fonte determinística renovável e duas receitas; sem economia, NPCs, combate, lore definitiva, nova região ou rede de armazenamento.

Plano/contratos/roteiro: `FIRST_EXTERNAL_REGION_VERTICAL_SLICE.md`, seção Segunda expedição; Decisão 100 e contexto §46. Save externo preserva HOME em cache e F9 retorna à vila; campos opcionais mantêm v3/v4 anteriores. A recompensa reutiliza Poção de Crescimento, com redução persistente do tempo agrícola. Alvo de duração 20–30 minutos ainda não validado; não confundir percurso funcional com balanceamento final.

Checkpoint automatizado com `GroveRestorationSliceSmokeTest` (72 verificações) e renderização técnica OpenGL/D3D12. Fechamento do Livro preserva a HUD nos dois hosts, após regressão reproduzida. Próximo passo: playtest manual do recorte e retorno sobre ritmo/clareza. Arte, captura pendente, capacidade na entrega/refund e saves legados reais continuam com pendências próprias. Não ampliar o conteúdo automaticamente.

Aceite manual parcial em 2026-10-03: descoberta da clareira, aprendizado/minimização do objetivo, coleta de 4 carvões e preparo de duas misturas pelo Livro com HUD acessível aprovados no roteiro proposto. Próximo teste: restauração e recompensa agrícola; depois save/load. Renovação cronometrada, capacidade cheia, ritmo e arte não foram presumidos aprovados. Registro somente documental, sem nova suíte ou gameplay.

Aceite seguinte em 2026-10-03: restauração com duas misturas na Mochila, consumo/recompensa únicos, canteiro verde/objetivo oculto, fabricação da Infusão da Clareira e efeito da poção no cultivo aprovados no roteiro proposto. Próximo teste: save/load no Bosque restaurado, reabertura/revisita e depois produção em viagem. Não apagar progresso; duração/balanceamento e arte permanecem pendentes. Somente documentação, sem nova suíte ou gameplay.

Aceite seguinte em 2026-10-03: persistência no Bosque restaurado (F5/F9, retorno com itens/receita, revisita e reabertura/load sem consumo/recompensa repetidos) aprovada no roteiro proposto. Próximo teste: produção em viagem, conclusão e cancelamento em lotes separados. Save anterior à restauração, capacidade cheia, duração/balanceamento e arte permanecem pendentes. Apenas documentação, sem nova suíte/código/save.

## Baseline operacional anterior — 2026-10-02/03

As fases numeradas abaixo registram o planejamento histórico; não representam uma fila ainda não implementada. O fechamento da V0 foi aprovado. A evolução pós-V0 já entregou exploração do Bosque, acesso a recursos da vila e Fases A–E da Mochila.

O fechamento integrado posterior corrigiu a persistência de colheitas recusadas e validou viagem → marco de expansão → HUD no retorno → depósito seletivo → save/load. Suíte de 34 testes aprovada; roteiro manual de capacidade, marcos e persistência do caldeirão permanece pendente em `PERSONAL_INVENTORY_ARCHITECTURE_PLAN.md`.

Aceites adicionais em 2026-10-03: expansão/navegação da Mochila, marcos/capacidade até 20, coleta repetida sem novo aumento, seleção na segunda página, transferências e save/reabertura aprovados; também produção em andamento/retomada/cancelamento do caldeirão, com consumo/resultado/restituição únicos no roteiro proposto. Colheita recusada por Mochila cheia, save/reabertura/load e retomada após depósito também aprovados. Captura pendente, bloqueios do caldeirão por capacidade e saves legados permanecem separados. Próxima revisão: aceite visual do estado atual com captura/feedback do autor. Não forçar cenário com F10/edição do save, presumir aprovação artística ou iniciar novos sistemas.

Primeiro pacote de polimento visual executado após autorização de continuidade: remoção dos blocos opacos dos lotes intocados, camadas estáveis terreno → solo → objetos, caldeirão verde limpo reaproveitado, grama suavizada, detalhes no baú e HUD/objetivos opacos. Renderização da Fazenda, solo arado e transferência conferida; aceite manual pendente. Decisão 96 delimita o incremento, sem mudança de save ou gameplay.

Segundo pacote visual implementado após autorização: fundo contínuo sem bordas cinzas, trilhas e vegetação baixa não interativas, golem de pedra/musgo, lago com margem e arco de entrada distinto das raízes corrompidas. Posicionamento funcional, sensores, navegação, cultivo e save não mudam. Inspeção OpenGL/D3D12 conferida; aceite visual/manual dos dois pacotes permanece pendente. Decisão 97 registra contratos e limites.

Após auditoria somente leitura e autorização de implementação, origem agrícola estabilizada em `FarmOrigin=(680,760)`. Lotes/pocket/piloto e pontos derivados não dependem mais do viewport; pedra de investigação fica fora do pocket. IDs/ordem/estados e contratos v4/v3 preservados; saves antigos assumem o layout canônico, pois não registravam a origem anterior. Objetos fixos, limites e gameplay mantidos. Suíte 35/35 e renderização OpenGL/D3D12 conferidas; save pessoal intacto. Decisão 98 e estado atual de `FARM_LAYOUT_PLAN.md` registram contratos e roteiro.

Autor aprovou em 2026-10-03 cultivo/save/load após redimensionar e fechar/reabrir em outro tamanho de janela, conforme roteiro de lote inicial. Também aprovou Bosque → resize → retorno, conferindo grade/culturas e acesso à pesca/baú/caldeirão, purificação → pedra → quatro lotes → Herbário, entrega física do golem com o personagem no caminho e criação/plantio/rega de um lote livre abaixo do lado direito da grade, sem sobreposição. Roteiros funcionais propostos deste layout concluídos; ajustar apenas problemas concretos de playtest futuro. A composição artística ainda não é final; os roteiros da Mochila/persistência do caldeirão permanecem pendentes e devem ser tratados separadamente. Conteúdo/economia/NPCs e rede de armazenamento precisam de escopo próprio; não iniciar automaticamente novos sistemas. Arquivos locais de arte permanecem preservados.

Checkpoint técnico seguinte: percurso purificação → pedra → quatro culturas → Herbário coberto no teste integrado, incluindo consumo/recompensa/marco únicos e JSON em cena recriada/resolução diferente. Nenhuma mudança de gameplay. Callbacks/sinais com navegação real não validam picking do mouse/hitboxes da UI; o próximo passo manual acima não foi substituído.

Auditoria seguinte reproduziu conflito de prioridade com enxada ativa: o fallback agrícola consumia cliques antes do picking dos objetos. Corrigido apenas esse despacho e ampliada a regressão para objetos/lotes e solo livre (Decisão 99). Autor validou em 2026-10-03 abrir baú/caldeirão com enxada ativa, fechar painéis e arar um lote inicial. Este roteiro específico está aprovado; demais validações manuais acima permanecem pendentes. Nenhum sistema novo autorizado por este checkpoint.

## Fase 0 - Estado atual

- O projeto já possui o loop principal validado em sua base atual.
- O golem automático foi desativado temporariamente para estabilizar testes manuais.
- A base de receitas entrou em transição para `RecipeResolver` sobre `RecipeDatabase` / `Data/recipes`, com fallback legado temporário.

## Fase 1.5 - Layout macro, helpers runtime-only e preparação da fazenda

### Objetivo

Organizar o mapa e os suportes de UI/ajuda sem criar um novo sistema de gameplay nem mexer em save/schema.

### Já concluído ou em estado estável

- Layout Pass V1 da fazenda com blockout visual leve, envelope macro fixo e leitura espacial melhor.
- Painéis arrastáveis em runtime-only, sem persistência de posição.
- Missão Inicial V0 runtime-only, separada do `QuestManager`.
- UI base do inventário e do caldeirão é feita com escopo mínimo, usando `anchors`, `size_flags_*` e `mouse_filter` corretamente, sem polimento visual antes do loop básico estar estável.
- Golem Irrigador como talento do golem físico existente, sem criar nova entidade.
- Transição inicial do catálogo de receitas com `RecipeResolver`, mantendo fallback legado temporário.
- Primeira leva definitiva de receitas resource-first implementada sem novos IDs de item:
  - `Infusão Purificadora`
  - `Saquinho de Semente Mista`

### Fechado na Fase 1.5

- Layout macro final documentado e aplicado em blockout runtime-only.
- Envelope do mapa fixado e validado com a área inicial centrada no caldeirão.
- Segunda área corrompida reservada visualmente.
- Leitura das zonas reservadas refinada sem transformar isso em novo gameplay.
- Fase 1 mantida intacta enquanto a fazenda ganha forma maior.

## Fase 2 - Fechamento técnico do grid

### Objetivo

Fechar o contrato técnico do grid sem substituir de vez o protótipo em `FarmPlot`.

### Entregas da Fase 2

- Consolidar a ponte runtime-only no `Main` espelhando os plots vivos em `FarmGridManager`, sem tirar `FarmPlot` da fonte de verdade.
- Fazer o golem físico ler o snapshot do grid como contrato real de seleção de alvo.
- Fazer o save/load consumir `farm_grid` como contrato real de persistência.
- Manter bloqueios e validações de interação em cima do snapshot do grid e do `FarmPlot` legado.
- Validar o fechamento com `git diff --check` e launch headless do Godot.

### Reservado para a próxima evolução

- Implementar solo livre / `FarmGrid` real.
- Permitir criação e remoção de lotes como autoridade de gameplay.
- Tornar a segunda área corrompida funcional.
- Avaliar a migração real para `FarmGrid`, se aprovada.
- Expandir o save além do mínimo atual apenas se o loop exigir.
- Revisar a UI do caldeirão.
- Revisar o inventário.
- Revisar a venda.
- Decidir se o golem físico continua ativo ou permanece desativado.
- Preparar a UI de status para leitura rápida do estado geral.

### Observação de escopo

A Fase 2 deve concentrar as mudanças sistêmicas de fato; a Fase 1.5 existe para preparar layout, leitura espacial e compatibilidade runtime-only sem reabrir o save.

### Estado atual do fechamento técnico

- O `FarmGridManager` já está ligado ao jogo principal como snapshot runtime-only do `Main`.
- O golem físico e o save passaram a ler esse snapshot como contrato real de gameplay/persistência.
- `FarmPlot` continua como fonte de verdade runtime enquanto a migração completa não acontece.
- Os itens de UI/inventário/venda permanecem como refinamento posterior e não bloqueiam o contrato técnico do grid.

## Fase 3 - Dados escaláveis

- Definir o formato final para crops, itens e receitas.
- Avaliar `Resource .tres`, JSON ou CSV.
- Criar um padrão de receitas mais amplo.
- Documentar a arquitetura de tempo real antes de conectar gameplay.
- Criar a base do `TimeManager` sem integrar ao gameplay ainda.
- Criar smoke tests manuais para validar a fundação do grid.
- Evoluir o grid já fechado na fase anterior para authority de gameplay somente quando a migração definitiva for aprovada.

## Fase 4 - Conteúdo

- Novas crops.
- Novas receitas.
- Missões.
- Progressão.
- Upgrades.
- Consolidar a transição de lotes fixos para grid/tile sem alterar o protótipo atual.

## Fase 5 - Polimento

- Arte final pixel art.
- Áudio.
- Animações.
- Balanceamento.
- UX.
- Refinar a UI de status e os indicadores provisórios.
- Integrar o tempo real apenas quando o protótipo estiver estável.
