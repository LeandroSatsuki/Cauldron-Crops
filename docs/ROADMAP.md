# Evolução do Projeto

## Etapa ativa — Checkpoint jogável pós-V0 (2026-10-03)

Preparação autorizada de build Windows local, sem novos sistemas ou mudança de gameplay. Exportador existente ganha modo Playtest: checkout do commit isolado, suíte opcional completa, exclusão de testes internos/docs/ferramentas e auditoria do PCK. Transformação somente no projeto temporário configura save `CauldronCropsPlaytest`; executável direto também não usa o progresso habitual. V0 aprovada permanece histórica, não reaberta.

Pacote local `Builds/Playtest`: EXE/PCK, launcher de compatibilidade, instruções, manifesto com commit/hashes, logs e cópia desta documentação. Todos os casos abaixo continuam pendentes conforme sua pré-condição. Este ambiente começa sem progresso anterior; aceites antigos não precisam ser repetidos como condição de aprovação dos ajustes de interface. Não importar/apagar save pessoal. Resultado de exportação/auditoria ainda em verificação neste commit de preparação.

## Checkpoint anterior — Fallback de HUD sem espaço livre (2026-10-03)

Quando nenhuma candidata fica livre, a busca deixa de retornar sempre ao canto inferior direito. Primeiro minimiza a área sobre controles visíveis/habilitados e slots da Mochila; depois a sobreposição restante; por fim a distância ao canto preferido. Produção, orientação da Clareira e aviso temporário usam essa política, incluindo proteção do cancelamento do lote. Não move/minimiza objetivos automaticamente nem altera gameplay/save. A escolha é limitada às candidatas; saturação total não permite prometer zero sobreposição.

`HUDCrowdedFallbackSmokeTest`: 28 verificações, três resoluções de 800×720 a 1280×720, fixtures sem espaço livre e saturação inevitável, determinismo, arrastes com lote ativo, botões minimizar/cancelar e snapshots invariáveis. Renderização OpenGL inspecionada: no caso extremo há sobreposição de conteúdo, mas os controles testados permanecem descobertos. Manual UI-06 adiado, sem presumir picking ou conforto aprovados.

Fechamento técnico: suíte 46/46, importação sem erros, inspeção OpenGL e save pessoal intacto por hash/tamanho/data. Arte local não relacionada e UID preexistente ficam fora da publicação.

Próximo recorte recomendado: preparar um checkpoint jogável e revisar o checklist consolidado de playtest antes de ampliar conteúdo. Não criar novas mecânicas por consequência deste ajuste.

## Checkpoint anterior — Avisos temporários do caldeirão contidos (2026-10-03)

Baseline reproduziu aviso fora da tela. Caldeirão converte seu ponto do mundo para tela e reutiliza helper com quatro segundos de leitura, quebra de linha, contorno e mouse ignorado. Aviso novo substitui o anterior; componente local contém largura/posição após resize e busca espaço livre se tocar HUD/produção/objetivo da Clareira, reservando altura para saída animada. Sucesso, lote pronto, cancelamento concluído e recusa de resultado usam o mesmo caminho. Nenhuma mudança de estoque, produção, entrega, refund, timers ou save; helper global/outros sistemas permanecem intactos.

Regressão `CauldronTemporaryFeedbackSmokeTest`: 33 verificações em 800×600, 800×720, 1280×720 e 1920×1080, câmera com offsets efetivamente aplicados, resize com aviso ativo, substituição, duração/saída, input ignorado, distinção Golem/Mochila e snapshots invariáveis. Aviso renderizado em OpenGL. Não promete ausência de sobreposição quando não existe espaço livre; fallback extremo continua separado.

Manual adiado: ler avisos de sucesso/recusa/cancelamento no mapa, câmera/resize e repetição, sem forçar capacidade no save pessoal. Próximo recorte recomendado: revisar fallback quando objetivos/painéis ocupam todo o espaço livre, preservando controles e escolha de minimização do jogador, sem criar gerenciador global de janelas.

Fechamento: suíte 45/45, reteste final do aviso (33), feedback de produção (87) e coexistência (305), importação sem erros e inspeção OpenGL. Save pessoal intacto por hash/tamanho/data; arquivos locais não relacionados excluídos do checkpoint.

## Checkpoint anterior — Gravação protegida do save (2026-10-03)

Gravação prepara `savegame.json.tmp`, confere conteúdo após flush/leitura, prepara `.bak.tmp` com o principal anterior e promove para `.bak` antes de substituir o principal. Falhas retornam false e mostram aviso; arquivo principal JSON inválido não é sobrescrito nem promovido ao backup. Temporários órfãos não são carregados. Load permanece explícito do principal, sem recuperação silenciosa; aviso menciona backup quando existe. Novo jogo explicitamente solicitado remove os arquivos associados. Schema v3/v4 e regras de snapshot/aplicação/gameplay permanecem.

Regressão `ProtectedSaveFileSmokeTest`: 19 verificações de I/O, Unicode/v3/v4, primeiro save/substituição, bloqueios reais e falhas simuladas de promoção, temporário incompleto, principal inválido/backup preservado e save/load/recusa com aviso/limpeza reais. Runner recusa execução fora de `Builds/QA`, protegendo user:// pessoal. Não equivale a garantia contra falha física de disco/queda de energia; validação JSON do helper confere integridade de arquivo, não substitui preflight de domínio no load.

Manual adiado: salvar normalmente duas vezes, reabrir/carregar e conferir progresso; aviso de erro só se surgir naturalmente, nunca forçar falha no save pessoal. Checklist integrado abaixo continua vigente. Próximo incremento recomendado: reproduzir e corrigir avisos temporários legados do caldeirão com câmera/resize, sem mudar produção/refund ou criar fila global.

Fechamento técnico: suíte 44/44, importação sem erros e aviso de recusa renderizado/inspecionado em OpenGL. Hash/tamanho/data do save pessoal preservados. A mensagem de falha no fixture é esperada.

## Checkpoint anterior — Checklist integrado e auditoria de riscos (2026-10-03)

Consolidação documental, sem mudança de código, gameplay ou save. A fila manual está abaixo, com aceites anteriores preservados e casos condicionais explicitamente separados. Não solicitar teste imediato enquanto o autor estiver indisponível. Última suíte executada: 43/43 no checkpoint `3d2240f`; não é uma nova execução nesta auditoria.

Auditoria delimitada identificou gravação direta do save sem proteção intermediária, avisos temporários ainda no caminho legado e fallback de layout sem garantia quando não existe espaço livre. Não há perda de save reproduzida nem auditoria exaustiva de todos os sistemas. Próximo incremento recomendado: proteger a gravação do save contra falhas/interrupções, com testes de arquivo isolados e sem mudar o schema v4, gameplay ou save pessoal. Esta recomendação ainda não foi implementada.

### Checklist integrado — validação manual adiada

Fonte operacional para os checkpoints pós-V0 atuais. Roteiros e contratos originais permanecem em [Mochila](PERSONAL_INVENTORY_ARCHITECTURE_PLAN.md) e [segunda expedição](FIRST_EXTERNAL_REGION_VERTICAL_SLICE.md). Não reabrir a V0 nem tratar autorização de continuidade como aceite dos testes.

Já aprovados pelo autor nos roteiros de 2026-10-03: coordenadas agrícolas/resize/viagem e acesso com enxada; logística do golem com personagem no caminho; marcos 12 → 16 → 20, navegação/transferências/persistência da Mochila; produção e cancelamento comuns retomados após load; colheita recusada persistida e retomada; descoberta/coleta/preparo da Clareira, restauração/recompensa/efeito agrícola e persistência após restauração. Não exigir repetição completa destes aceites; os ajustes posteriores de interface ainda precisam da conferência específica abaixo.

Preparação segura: usar a sessão existente, anotar quantidades/capacidade/estado de produção antes de cada caso e não apagar progresso. F5/F9 aqui são atalhos dentro do jogo, não comandos do editor. Nunca reativar F10, editar o save pessoal ou fabricar enchimento artificial para testar. Caso sem pré-condição disponível fica **não executado**, não aprovado. Compatibilidade com save antigo só em cópia/ambiente separado, nunca sobrescrevendo o atual. Não provocar falha de disco ou encerramento durante gravação no save pessoal.

#### Bloco A — Interface e interação (primeira sessão disponível)

- [ ] **UI-01 — HUD/objetivos:** em 1280×720 e janela estreita de 800×720, conferir páginas da Mochila, seleção/desseleção e ferramentas compactas. Minimizar/expandir e arrastar objetivos iniciais; redimensionar e viajar ao Bosque/redimensionar/voltar. Esperado: acesso a todos os itens, toggle acompanhando painel, sem mudar capacidade/quantidades. Janelas menores não são homologadas.
- [ ] **UI-02 — Baú/caldeirão/Livro:** com enxada selecionada, abrir baú e conferir Mochila ao lado, quantidade digitada e mover tudo nos dois sentidos; fechar e arar um lote. Abrir caldeirão, arrastar ingredientes, misturar, abrir/navegar/rolar Livro, digitar quantidade, produzir e fechar/reabrir/arrastar/redimensionar. Esperado: controles acessíveis, HUD não desaparece, cliques nos painéis não causam movimento/cultivo. Conferência das interfaces novas, não revogação do aceite anterior de picking.
- [ ] **UI-03 — Painéis persistentes:** com produção e objetivo da Clareira ativos quando disponíveis, conferir resultado pronto/em preparo/lote/pausa/cancelamento pendente; minimizar objetivo e mover objetivos iniciais/redimensionar. Esperado: avisos legíveis e separados da Mochila/ferramentas/Caderno, botão de cancelar acessível; câmera não arrasta aviso. Não forçar estados indisponíveis. Se não houver espaço livre pela posição escolhida, registrar e minimizar/mover objetivos; não considerar garantida ausência de colisão em qualquer posição.
- [ ] **UI-04 — Orientação e requisitos:** conforme estados disponíveis, ler próxima ação, falta de carvão/misturas, orientação de retirada do baú e produção. Conferir requisitos do Herbário (baú + Mochila) e Clareira (só Mochila) após transferências/load. Esperado: contador acompanha estoque atual, local externo não consome baú, objetivo concluído permanece oculto. Se projetos já concluídos, não apagar progresso: conferência pré-conclusão fica condicional.

Conferência adicional de apresentação:

- [ ] **UI-05 — Avisos temporários do caldeirão:** ler sucesso, lote pronto e cancelamento; recusa de resultado somente se surgir naturalmente. Mover câmera/redimensionar enquanto aviso aparece e repetir interação. Esperado: aviso contido, quebrado e legível por quatro segundos antes da saída; mensagem nova substitui anterior e não captura cliques. Não exigir ausência de colisão se todos os espaços livres forem ocupados pelo usuário; registrar esse caso separadamente.

- [ ] **UI-06 — HUD sem espaço livre:** durante produção normal, reduzir a janela e arrastar objetivos para perto dos painéis de produção/Clareira. Conferir acesso por clique a minimizar, ferramentas/Mochila e cancelar, sem exigir ausência de toda sobreposição de conteúdo. Objetivos não devem ser movidos/minimizados automaticamente. Cancelar somente um lote que você realmente queira interromper; não editar save nem reativar F10. Registrar tamanho da janela/posição se algum controle ficar coberto.

#### Bloco B — Produção durante viagem

- [ ] **TR-01 — Concluir:** iniciar lote que permita viajar e usar F5 no Bosque ainda em andamento; anotar estoques/resultados antes. F9 deve retornar à vila e retomar o snapshot. Conferir entrega/consumo únicos, inclusive após reabrir/carregar. Mistura usa 2 carvões por unidade e 4 segundos por preparo; quantidade limitada aos recursos reais. Se terminar antes de salvar, caso de retomada em andamento não executado.
- [ ] **TR-02 — Cancelar:** em outro lote, repetir viagem/F5/F9 ainda em andamento e cancelar antes de terminar. Esperado: devolver somente reservas não utilizadas às origens, não devolver ingredientes de resultados já entregues, não duplicar resultado. Não modificar timers nem usar lote concluído como evidência deste cenário.
- [ ] **TR-03 — Fonte renovável:** coletar os 2 carvões da fonte ao lado da Clareira, cronometrar cerca de 45 segundos de sessão e revisitar, incluindo tempo na vila. Esperado: renovação apenas da fonte nova, entrega na Mochila; jogo fechado não conta como tempo de renovação. Se houver recusa por capacidade, ponto preservado e intervalo não iniciado.

#### Bloco C — Capacidade e persistência (somente se o estado surgir naturalmente)

- [ ] **CAP-01 — Captura pendente:** se o espaço disponível mudar durante a sincronia e a captura não couber, fechar popup, salvar/reabrir/carregar, depositar no baú. Esperado: captura integral entregue uma única vez quando inativa e houver espaço; coleção só avança após recebimento, nova pesca não sobrescreve a pendência. Mochila cheia antes de iniciar é outro caso: sincronia não abre, sem captura prometida.
- [ ] **CAP-02 — Resultado bloqueado:** concluir produção sem espaço para o resultado. Esperado: pronto preservado no caldeirão, aviso claro e lote sem descartar reserva/avançar entrega; após save/load e depósito, interagir para recolher/retomar, uma vez. Não transferir automaticamente resultado para Village Storage.
- [ ] **CAP-03 — Cancelamento bloqueado:** se a restituição à Mochila não couber, cancelar, salvar/reabrir/carregar e liberar espaço no baú; tentar cancelar novamente. Esperado: reservas pendentes preservadas e restituição única às origens, sem perda/duplicação. Não confundir com cancelamento comum já aprovado.
- [ ] **SAVE-01 — Estados anteriores/legados:** se existir cópia segura anterior à restauração ou save v3/v4 antigo real, testar separadamente. Conferir culturas, excesso legado sem truncar, marcos, fontes/receitas e ausência de consumo/recompensa repetidos. Persistência da Clareira já restaurada foi aprovada; não substitui este caso. Sem cópia disponível, manter pendente, não reiniciar o save habitual.

Caso adicional de persistência deste checkpoint:

- [ ] **SAVE-02 — Gravação protegida normal:** salvar duas vezes pelo F5 durante uso normal, fechar/reabrir/carregar e conferir quantidades, culturas e progresso. Esperado: mesmo comportamento de retomada, sem erro na gravação comum. Aviso de falha só será conferido se ocorrer naturalmente; nunca interromper gravação ou bloquear arquivos do save habitual. Backup é proteção anterior, não retomada automática de progresso mais antigo.

#### Bloco D — Experiência

- [ ] **EXP-01 — Arte e leitura:** avaliar composição da vila/Bosque, terreno abaixo dos objetos, água/caminhos/obstáculos, legibilidade dos avisos sobre o mapa e conforto de cliques/arraste/rolagem. Registrar captura, resolução, ferramenta selecionada e ação quando houver problema. Renderização técnica não constitui aprovação artística.
- [ ] **EXP-02 — Ritmo e utilidade:** quando for possível observar uma sessão representativa, medir tempo efetivo e avaliar clareza do loop, viagens, renovação e utilidade da Poção de Crescimento. A hipótese de 20–30 minutos não está validada; não repetir descoberta apagando progresso nem alongar timers artificialmente para atingir a meta.

Registro de retorno por ID: **aprovado / falhou / não executado**, resolução, pré-condição, ação, esperado e observado. Um caso aprovado não encerra os outros; informar perda/duplicação/travamento separadamente de preferência estética. Aceite completo de experiência depende destes retornos, não da suíte automática.

### Riscos técnicos auditados — acompanhamento dos checkpoints

| Prioridade | Evidência e limite | Próximo recorte mínimo |
| --- | --- | --- |
| Alta — gravação do save (mitigada neste checkpoint) | Baseline gravava diretamente no principal; agora temporário conferido, backup anterior e erros verificados. Regressão de I/O isolado acrescentada. Sem perda reproduzida no save pessoal nem garantia contra falha física/energia. | Conferência manual normal adiada. Backup não é carregado automaticamente; recuperação assistida quando necessária. Sem sistema novo de slots/cloud/migração. |
| Média — avisos temporários (mitigada neste checkpoint) | Baseline reproduziu texto fora da tela. Avisos do caldeirão agora convertem mundo → tela, quebram linha, mantêm leitura, respeitam resize e procuram espaço quando tocam HUD/painéis. | Conferência manual UI-05 adiada. Falta total de espaço continua no risco de fallback abaixo; sem fila global ou mudança de entrega/refund. |
| Média — falta de espaço na tela (mitigação limitada) | Fallback agora prioriza controles e reduz sobreposição entre candidatas. Fixture reproduz o canto antigo cobrindo região evitável; 28 verificações e renderização técnica. Saturação absoluta ainda implica colisão de conteúdo. | UI-06 manual adiado; não prometer zero colisão/picking aprovado, compactação automática ou suporte irrestrito. |
| Pendente de experiência | Testes por sinais/geometria/JSON não cobrem picking real, saves legados reais, arte, conforto ou duração. | Checklist acima, sem inventar aprovação nem bloquear toda continuidade enquanto autor estiver indisponível. |

## Checkpoint anterior — Coexistência de objetivos, produção e HUD (2026-10-03)

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
