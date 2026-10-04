# Evolução do Projeto

## Etapa atual — Vila em Reconstrução, Poço: incremento 3 em validação (2026-10-04)

Fechamento autorizado, sem novo gameplay. Exportador integra reaberturas do Poço físico/projeto/habilidade imediatamente após cada teste, preservando modos anteriores e distinguindo sete reaberturas de dois fixtures. Auditoria do PCK confere recursos, custo/benefício/alternativa, preflight e instância/posição física sem conceder progresso. Checklist ampliado para **36 pendências**, com os 30 casos anteriores intactos e WL-01–WL-06 novos. Nova exportação limpa e auditoria ainda em execução; não tratar esta preparação como pacote entregue ou aceite manual.

## Checkpoint anterior — Vila em Reconstrução, Poço: incremento 2 (2026-10-04)

Incrementos 1–2 concluídos tecnicamente. Poço físico em `(540, 280)`, acima do limite agrícola e fora dos lotes/trilhas atuais; collider/corpo/obstáculo separados e política de construção. Aproximação existente com destino fora do corpo e confirmação revalidando proximidade/vila ativa. Painel compacto opaco/arrastável apresenta reserva, custo por ícones/quantidades e estados da melhoria. Fechar/Escape/load/viagem/cache liberam contexto; cliques de fundo e atalhos de ferramentas bloqueados enquanto aberto. Mesmos custos/alternativa/benefício, sem recarga instantânea, retirada de água, F10 ou HUD nova.

Suíte **54/54**, teste físico **104 verificações** headless/OpenGL e reabertura específica em outro processo (**4**). Sete reaberturas e dois fixtures totais preservam os modos anteriores. Teste usa arbitragem antes do picking + evento do collider e eventos GUI, não clique físico do autor; câmera liberada/alinhada só no fixture para não controlar o cursor do Windows. Capturas inspecionadas em 800×600/800×720/1280×720; layout ignora resize em cache. Save pessoal idêntico por hash/tamanho/data, arte local preservada fora do commit.

Próximo **incremento 3 — fechamento**: integrar reaberturas do Poço no exportador, suíte em checkout limpo, pacote auditado e checklist ampliado mantendo **30 pendências** abaixo. **Ainda sem nova exportação**: SustainableFarm-20261004 não contém o Poço físico. Aproximação/contratos testados automaticamente não equivalem a aprovação manual de picking/arte/conforto/balanceamento; não exigir teste imediato ao autor indisponível. Recorte aprovado em [Farm System](FARM_SYSTEM_V2.md#vila-em-reconstrução--poço-da-vila-piloto-aprovado-2026-10-04), sem ampliar sistemas reservados.

## Checkpoint anterior — Vila em Reconstrução, Poço: incremento 1 (2026-10-04)

Recorte aprovado e incremento 1 concluído tecnicamente: projeto opcional após Clareira restaurada, custo 8 trigos + 1 mistura restauradora, baú prioritário/Mochila complementar; capacidade mínima 20 sem recarga instantânea ou regeneração acelerada. Habilidade antiga de 1 ponto é alternativa, não benefício acumulável: nenhuma cobrança adicional se já obtido; capacidades legadas maiores preservadas.

Contratos, APIs e campo opcional no save v4, compatibilidade v3/v4, preflight antes de mutação e guarda de transação. Suíte **53/53**, teste novo **89 verificações**, reaberturas de projeto/habilidade em processos separados (**8 + 8**) e fixture de habilidade (**2**); quatro reaberturas anteriores e fixture de replantio também passaram. QA isolado, save pessoal idêntico por hash/tamanho/data. Ainda **sem poço físico novo, teste de clique/proximidade ou nova exportação**; build SustainableFarm-20261004 não contém este incremento.

Próximo **incremento 2 — objeto físico/integração**, dentro do recorte aprovado: posicionar fora do cultivo/trilhas, aproximação real, picking, painel compacto opaco e estados antes/depois. **Incremento 3** integra regressão/exportador, pacote auditado e novos casos de checklist. Preservar as **30 pendências manuais** abaixo; autor indisponível não precisa testar agora. Sem loja/moeda/NPC/mapa/mastery/tempo offline. Plano em [Farm System](FARM_SYSTEM_V2.md#vila-em-reconstrução--poço-da-vila-piloto-aprovado-2026-10-04).

## Checkpoint anterior — Ciclo Sustentável da Fazenda, fechamento técnico 1–3 (2026-10-04)

Incremento 3 concluído tecnicamente, sem alterar gameplay/schema. Exportação definitiva da fonte `8a1bc4a` em checkout limpo: suíte **52/52**, quatro reaberturas em novos processos (**6 + 3 + 8 + 8 verificações**) e fixture adicional de replantio (**2**, não contado como reabertura). Runner exige a contagem específica de cada modo antes de aceitar PASS.

Pacote local: `Builds/Playtest/SustainableFarm-20261004`, com EXE/PCK, StartPlaytest.cmd, manifesto/hashes, logs, instruções e checklist **30 casos pendentes** (24 anteriores intactos + 6 SC). Startup headless/OpenGL e auditoria isolada do PCK passaram; receitas de recuperação/replantio conferidas por ingredientes, resultado, disponibilidade, tempo e XP. Save separado CauldronCropsPlaytest; não copia/apaga progresso pessoal nem de playtest anterior. Save pessoal idêntico por hash/tamanho/data; binários/QA/arte local fora do Git.

Controle negativo revelou que `--main-pack` executado da pasta do projeto podia aceitar arquivos locais ausentes no PCK. Auditoria agora usa `--path` da pasta de saída; build histórica sem receitas é recusada corretamente. Commit é capturado uma vez e usado no checkout/manifesto, sem ler HEAD mutável no fim. Pacote SustainableFarm-20261003 é preliminar, marcado como substituído; usar o de 20261004.

Recorte fechado tecnicamente, **não aprovado manualmente**. Arte, conforto, ritmo e balanceamento continuam pendentes, sem exigir teste imediato. Próximo passo de construção: propor um novo recorte delimitado de gameplay/progressão antes de implementar sistemas reservados. Plano em [Farm System](FARM_SYSTEM_V2.md#ciclo-sustentável-da-fazenda--recorte-aprovado-2026-10-03).

## Checkpoint anterior — Ciclo Sustentável da Fazenda, incremento 2 (2026-10-03)

Orientação existente do Livro/Mochila/baú/golem explica reposição e distingue plantio manual de semeadura pelo baú. Nome Semente de Trigo consistente no Livro; descrições curtas, sem novo painel/HUD ou regra de gameplay.

Suíte **52/52** e retestes finais; ciclo integrado com **77 verificações**, fontes reais de carvão/água, plantio/rega/colheita, reinvestimento, depósito/retirada físicos e cargo durante Bosque/save/load. Duas reaberturas de receitas em processos separados (**8 + 8**, fixture de replantio **2**), mais as existentes do golem. Capturas OpenGL do Livro/transferência e painel do golem inspecionadas. Marco restaurado é fixture explícito da parte de automação, não concedido pelas receitas. Bônus de colheita/eventos e XP antigos preservados, sem depender deles para repor sementes.

Incrementos 1–2 concluídos tecnicamente; save pessoal intacto, **24 casos manuais** pendentes. **Sem nova exportação:** GolemSower-20261003 ainda sem este ciclo/orientações. Próximo **incremento 3 — fechamento**: exportador executa reaberturas específicas, suíte em checkout limpo, build auditada e checklist ampliado preservando casos anteriores. Sem ampliar economia/conteúdo reservado. Plano em [Farm System — Ciclo Sustentável](FARM_SYSTEM_V2.md#ciclo-sustentável-da-fazenda--recorte-aprovado-2026-10-03).

## Checkpoint anterior — Ciclo Sustentável da Fazenda, incremento 1 (2026-10-03)

Contratos/receitas concluídos tecnicamente: **1 carvão + 1 água → 1 Semente de Trigo** e **2 trigos → 3 Sementes de Trigo**, padrão no Livro, sem RNG/marco/XP. Reusam manual/lote, baú prioritário/complemento pessoal, resultado na Mochila, reservas/refund e snapshot existentes. Água não ocupa slots. Tempo de piloto: 2 segundos por craft; economia, fontes, estações, colheita e golem preservados.

Importação sem erros e suíte **51/51**, com 86 verificações novas de receitas/produção/Livro/origens/cancelamento/capacidade/JSON/timer real. Reaberturas existentes do golem passaram (6 + 3). QA isolado e save pessoal intacto por hash/tamanho/data. Sem nova build: GolemSower-20261003 permanece histórica, ainda sem estas receitas. Os **24 casos manuais** continuam pendentes, sem exigir teste imediato.

Próximo: **incremento 2 — orientação/integração**, comunicação discreta e recursos acessíveis → caldeirão → plantio manual/golem, com save/load/viagem reais em QA. Incremento 3 fecha regressão, exportação auditada e checklist ampliado sem apagar pendências. Plano em [Farm System — Ciclo Sustentável](FARM_SYSTEM_V2.md#ciclo-sustentável-da-fazenda--recorte-aprovado-2026-10-03). Não confundir JSON em memória com reabertura integrada ou aprovação manual.

## Checkpoint anterior — Golem Semeador, fechamento técnico A–F (2026-10-03)

Fase F concluída tecnicamente, sem mudança de gameplay/schema: fonte `226bb72` exportada em checkout limpo, suíte **50/50**, mais duas reaberturas em novos processos (6 + 3 verificações). Startup do EXE headless/OpenGL passou; auditoria do PCK confirmou dependências do semeador, exclusão de conteúdo interno/saves e diretório de save próprio. Não significa aprovação manual de navegação/arte/conforto.

Pacote local: `Builds/Playtest/GolemSower-20261003`, com EXE/PCK, StartPlaytest.cmd, manifesto/hashes, logs, instruções e checklist **24 casos** (16 anteriores + 8 semeador). Fonte versionada e documentos publicados; binários/QA/saves permanecem fora do Git. Pacote anterior preservado. Build usa `%APPDATA%/CauldronCropsPlaytest`, não copia progresso pessoal; save de playtest anterior pode ser retomado nesse ambiente separado. Save pessoal intacto por hash/tamanho/data.

Manual continua adiado, sem exigir teste imediato. Próximo portão de experiência é executar o checklist quando disponível. Para continuar construção antes disso, propor o próximo recorte de gameplay/progressão com resultado, limites e contratos claros; não implementar novos sistemas reservados por consequência do fechamento. Plano em [Farm System — fechamento](FARM_SYSTEM_V2.md#golem-semeador--fechamento-técnico-af-concluído-2026-10-03).

## Checkpoint anterior — Golem Semeador, Fase E implementada (2026-10-03)

Controle Semear trigo integrado ao painel existente, bloqueado até a Clareira restaurada e OFF por padrão/legado. Atualizar/abrir/load não emite toggle nem ativa a habilidade; OFF com semente preserva devolução física da D. Nenhuma nova recompensa/talento/receita, HUD permanente ou F10. Consulta pura descreve estoque exclusivo do baú, terra/estação/canteiro, pausa/prioridades, transporte e devolução sem alterar domínio.

Painel opaco com texto/botões contidos, diagnósticos redundantes ocultos e arraste preservado durante texto/resize/cache. Falta do talento de rega não mascara semeadura nos modos mistos; prioridades/irrigação não alteradas. Plano em [Farm System — Golem Semeador](FARM_SYSTEM_V2.md#golem-semeador--piloto-aprovado-fase-e-concluída-2026-10-03).

GolemSowerUISmokeTest: 325 verificações, três adicionais de reabertura em outro processo, 800×600/800×720/1280×720 e cache/resize após Bosque. Importação sem erros e suíte completa 50/50, mais inspeção OpenGL. Save pessoal idêntico por hash/tamanho/data; arte local, builds/saves/QA e UIDs auxiliares alheios fora do checkpoint. Testes manuais/conforto continuam pendentes; sem exigir teste imediato ou exportar nesta fase.

Próximo incremento: **Fase F — fechamento do piloto**, retestes/auditoria do PCK, nova build de playtest isolada e checklist consolidado. Preservar os 16 casos manuais anteriores e acrescentar semeador; não transformar automático em aprovação do autor nem ampliar conteúdo/economia/mundo.

## Checkpoint anterior — Golem Semeador, Fase D implementada (2026-10-03)

Scheduler físico do piloto de quatro lotes/trigo, fallback de colheita/rega nos modos mistos. ON explícito por API somente com Clareira restaurada; OFF por padrão, UI ainda para E. Golem chega ao baú antes de retirar uma semente, transporta com ícone de carga e planta/devolve perto do alvo. Proximidade real, revalidação de saldo/alvo/estação e geração de tarefa; não complementar na Mochila, reservar sementes durante trajeto ou sobrescrever culturas.

Pausa congela cargo; OFF/modo exclusivo solicita devolução física. Baú ausente/caminho impossível mantém custódia; timer de retorno/plantio cancelado não completa em snapshot novo. Save/load/cache retomam com rota nova, sem nova retirada ou trabalho remoto no Bosque. Navegação de sementes trata sincronização inicial/caminho vazio/fim distante/limite de trajeto, sem reformular navegação da colheita/rega. Plano em [Farm System — Golem Semeador](FARM_SYSTEM_V2.md#golem-semeador--piloto-aprovado-fase-d-concluída-2026-10-03).

Teste físico novo com 107 verificações em QA isolado, incluindo scheduler recorrente a 128 pixels/s com relógio QA acelerado/culturas longas no fixture. Importação sem erros e suíte completa 49/49; retestes finais de persistência/reabertura separados. Save pessoal idêntico por hash/tamanho/data, arte local e arquivos auxiliares alheios excluídos da publicação. Manual anterior e fluxo físico do semeador continuam pendentes, sem exigir teste imediato. Sem nova exportação ou ativação automática de saves elegíveis.

Próximo incremento: **Fase E — progressão/UI**, disponibilidade derivada da Clareira, opção no painel existente e estados de recusa/transporte/devolução legíveis. Sem HUD extra/F10/novas recompensas. Fase F fecha auditoria/exportação/checklist; não equiparar testes automáticos a aceite manual.

## Checkpoint anterior — Golem Semeador, Fase C fechada (2026-10-03)

Persistência aditiva v3/v4 do golem físico: flag de semeadura, prioridade, totais da colheita e carga única de semente. Preflight verifica elegibilidade no marco recebido, tipos/IDs/quantidades e proíbe cargas simultâneas; recusa antes de trocar região/estoques/progresso. Load substitui sem refund, invalida callbacks/esperas e não persiste rotas. Legado completo OFF/sem carga; contrato parcial sem bloco não substitui golem. Save externo lê HOME cacheada, sem trabalho físico remoto. Plano em [Farm System — Golem Semeador](FARM_SYSTEM_V2.md#golem-semeador--piloto-aprovado-fase-d-concluída-2026-10-03).

Colheita é instalada na carga antes do sinal de lote vazio; depósito limpa carga antes de feedback e mantém entrega se baú desaparece. Gravação inválida/golem indisponível preserva arquivo anterior; reentrada/gravação durante aplicação é recusada. Fase C não liga scheduler de semeadura, unlock ou UI: carga restaurada fica preservada até integração física.

Regressão nova: 148 verificações mais seis de reabertura em outro processo, arquivos reais somente em QA. Importação sem erros e suíte completa 48/48. Save pessoal idêntico por hash/tamanho/data; arte local e UIDs auxiliares alheios preservados fora do checkpoint. Compatibilidade com fixtures isolados sem golem preservada após regressão de coleção de pesca. Manuais anteriores continuam pendentes, sem pedir teste imediato; sem nova exportação nesta fase.

Próximo incremento: **Fase D — trabalho físico**, chegada real ao baú/lote, retirar uma semente, transportar/plantar/devolver; revalidar alvo/estação/saldo, exclusão mútua com colheita e tratar pausa/aborto/caminho/cache/rotas retomadas. Sem arar automaticamente, consumir Mochila, novos mapas/economia ou ativar saves por elegibilidade. E entrega unlock/UI; F fecha suíte/exportação/checklist.

## Checkpoint anterior — Golem Semeador, Fase B fechada (2026-10-03)

Domínio comum de plantio implementado: validação sem mutação, fonte pessoal explícita no clique manual e fonte de carga separada com identidade verificada no registro da vila. Preserva culturas/estações/rega/verão e elimina instalação de metadados antes de recusas. Sinal só depois de consumo/cultura/timer consistentes. Nenhuma automação foi ligada.

GolemSeedCargo conserva uma semente entre baú, transporte, cultura ou devolução. Retirada exclusivamente do baú, sem complementar na Mochila; devolução ausente mantém pendência e repetição não duplica. Serialização de domínio tem preflight estrito, cópias profundas e substituição sem refund. Não confundir com save integrado: Golem e SaveManager ainda não haviam sido alterados nesta Fase B. Plano vigente em [Farm System — Golem Semeador](FARM_SYSTEM_V2.md#golem-semeador--piloto-aprovado-fase-d-concluída-2026-10-03).

Novo teste de domínio com 365 verificações em QA isolado, importação sem erros e suíte completa 47/47. Save pessoal idêntico por hash/tamanho/data; arte local e UIDs auxiliares não relacionados fora do checkpoint. Nenhum desbloqueio, scheduler, UI, receita, economia ou novo mapa nesta etapa. Fila manual anterior continua pendente, sem pedir teste imediato ao autor indisponível; sem nova exportação nesta fase.

Próximo incremento: **Fase C — persistência**, snapshot/preflight/load do golem e ambas as cargas, legado OFF/sem carga, replay, substituição sem refund e snapshot da vila cacheada. Não habilitar retirada viva antes deste portão. D permanece trabalho físico; E progressão/UI; F suíte/exportação/checklist.

## Checkpoint anterior — Golem Semeador, Fase A fechada (2026-10-03)

Autor aprovou o piloto e o início por análise/contratos. Plano operacional em [Farm System — Golem Semeador](FARM_SYSTEM_V2.md#golem-semeador--piloto-aprovado-fase-d-concluída-2026-10-03). Nesta fase somente documentação: golem existente, trigo, quatro células iniciais `(0,0)/(1,0)/(0,1)/(1,1)`, marco da Clareira, ativação opcional OFF, retirada exclusivamente física do baú e respeito à estação/aragem/ocupação. Sem novo mapa, aragem, economia, NPCs, mastery ou mudança de rega.

Baseline confirma acoplamento do plantio à Mochila, complemento pessoal no consumo agregado, ausência de carga física no snapshot do golem e callbacks/esperas que precisam ser invalidados. Devolução de semente não reutiliza finalizador que limpa carga com baú inválido. Cargas de colheita/plantio separadas e mutuamente exclusivas no piloto; viagem congela trabalho físico, sem simulação remota. Estes são riscos de integração por leitura, não perda de save pessoal reproduzida.

Validação proporcional: GolemLife, SaveContract e RegionTravel passaram em APPDATA de QA isolado. Sem nova suíte completa: 46/46 continua a evidência do playtest anterior. Nenhuma implementação/teste novo ou alteração no save pessoal nesta Fase A. Dezesseis casos manuais anteriores permanecem pendentes.

Próximo incremento: Fase B, domínio comum de validação/commit de plantio e contrato mínimo de custódia/serialização, ainda sem scheduler vivo. Fase C fecha persistência antes de D habilitar retirada/transporte; E entrega unlock/UI; F verifica/exporta. Não pedir teste imediato ao autor indisponível nem declarar golem semeador pronto.

## Checkpoint anterior — Checkpoint jogável pós-V0 (2026-10-03)

Preparação autorizada de build Windows local, sem novos sistemas ou mudança de gameplay. Exportador existente ganha modo Playtest: checkout do commit isolado, suíte opcional completa, exclusão de testes internos/docs/ferramentas e auditoria do PCK. Transformação somente no projeto temporário configura save `CauldronCropsPlaytest`; executável direto também não usa o progresso habitual. V0 aprovada permanece histórica, não reaberta.

Pacote local `Builds/Playtest/PostV0-20261003`: EXE/PCK, launcher de compatibilidade, instruções, manifesto com commit/hashes, logs e somente o checklist integrado extraído abaixo (16 casos). Todos continuam pendentes conforme sua pré-condição. Este ambiente começa sem progresso anterior; aceites antigos não precisam ser repetidos como condição de aprovação dos ajustes de interface. Não importar/apagar save pessoal.

Fechamento técnico: build de fonte `c43abae`, suíte 46/46 no checkout limpo, importação/validação, startup headless de 120 frames, auditoria do PCK e startup OpenGL de 120 frames sem erros registrados. Auditoria confirma save separado, recursos de regiões/receita e exclusão dos diretórios internos. Corrigida dependência de preload de teste agrícola na UI: ação dev agora carrega somente no editor com debug explicitamente habilitado, sem reativar F10. Primeiro runner foi recusado corretamente pelo guard de save; APPDATA passou a ficar em Builds/QA do próprio checkout temporário. Save pessoal intacto por hash/tamanho/data; binários e arte local fora do Git.

Próximo recorte recomendado: propor um bloco delimitado de gameplay/progressão, com objetivos, caminhos determinísticos de aquisição e critérios de aceite, antes de implementar. Economia/NPCs/lore definitiva continuam reservados; playtest/16 casos não são considerados aprovados pela exportação técnica.

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

#### Bloco E — Golem Semeador (oito casos novos, todos pendentes)

Preferir a nova build de playtest com save separado. Ela não copia o progresso pessoal; se houver save de playtest anterior, preservá-lo. Seguir os caminhos normais de progressão até restaurar a Clareira; não editar saves, usar F10 ou forçar falhas. Anotar sementes do baú, sementes da Mochila e culturas antes/depois. O canteiro piloto são as duas primeiras linhas/colunas da grade: `(0,0)`, `(1,0)`, `(0,1)`, `(1,1)`; lotes precisam estar visíveis, liberados, vazios e arados, na Primavera. Pré-condição indisponível significa não executado.

- [ ] **GS-01 — Marco e ativação:** antes da restauração, conferir Semear trigo bloqueado; depois, disponível mas OFF. Abrir/fechar painel não ativa. Se houver cópia legada segura e elegível, testar separadamente: também OFF, sem repetir recompensa da Clareira.
- [ ] **GS-02 — Fonte e preparo:** ter sementes apenas na Mochila não autoriza retirada pelo golem. Depositar no Baú da Vila, arar os quatro lotes vazios e ativar num modo misto. Esperado: sem aragem automática, sem alterar ferramenta/seleção ou consumir sementes pessoais; estados de falta de preparo/estoque legíveis.
- [ ] **GS-03 — Ciclo físico:** observar ida ao baú, retirada de uma unidade, ícone durante transporte e plantio próximo ao lote. Repetir até preencher os quatro lotes. Esperado: uma semente por cultura, sem semear lotes adicionais, sobrescrever culturas ou teleportar logística. Colheita/rega elegíveis continuam precedendo o plantio nos modos mistos.
- [ ] **GS-04 — Alvo concorrente e devolução:** durante transporte, plantar manualmente no alvo escolhido se for possível identificá-lo. Esperado: cultura manual preservada, semente do golem devolvida fisicamente uma vez ao baú. Caso não consiga produzir a concorrência naturalmente, manter pendente; não apagar nós/editar dados.
- [ ] **GS-05 — Pausa/OFF/prioridade:** pausar com ícone de semente e retomar: cargo preservado. Desativar ou trocar para Só colher/Só regar durante transporte: retorno físico, sem refund à distância; Pausado segura a devolução até retomar. Modos exclusivos não iniciam nova semeadura. Conferir diferenças de estado no painel.
- [ ] **GS-06 — Save/reabertura:** F5 com cargo em transporte ou devolução, fechar/reabrir/F9; anotar estado antes. Esperado: mesma opção/prioridade/cargo, rota retomada sem retirar outra semente. Carregar duas vezes o mesmo snapshot não soma estoque nem gera plantio extra. O tempo jogado após o snapshot pode ser revertido normalmente pelo load.
- [ ] **GS-07 — Viagem com cargo:** viajar ao Bosque com cargo, permanecer fora e voltar. Esperado: golem não transporta/planta à distância, culturas/caldeirão seguem sua regra de tempo. F5 no Bosque/F9 retorna à vila e conserva cargo; retomada cria rota sem retirada duplicada. Não presumir movimentos offline enquanto o jogo está fechado.
- [ ] **GS-08 — Painel e regressões:** em 800×720 e 1280×720, abrir/arrastar/fechar painel, mudar texto por estados disponíveis, redimensionar e viajar/voltar. Esperado: fundo opaco, controles contidos e arraste preservado; painel não provoca clique no mundo. Com enxada, abrir baú/caldeirão, fechar e arar; conferir colheita e rega existentes (rega somente com talento).

#### Bloco F — Ciclo Sustentável da Fazenda (seis casos novos, todos pendentes)

Usar a nova build com save separado e preservar progresso já existente. Anotar saldos da Mochila, baú e água antes/depois; não zerar recursos ou editar timers para fabricar cenários. As receitas levam dois segundos por craft. RNG de bônus de colheita não é necessário para o ciclo; registrar esses ganhos separadamente. Sem pré-condição natural, marcar não executado.

- [ ] **SC-01 — Livro e orientação:** abrir Livro com enxada selecionada, conferir Recuperação e Replantio disponíveis e resultado Semente de Trigo. Ler descrição, tooltips da Mochila/baú e transferência nos dois sentidos. Esperado: custos e destinos claros, Mochila para plantio manual e baú para golem; consultar não consome recursos, concede XP nem ativa semeadura.
- [ ] **SC-02 — Recuperação:** coletar carvão no Bosque, voltar e aguardar água do poço. Produzir uma recuperação pelo Livro. Esperado: consumir um carvão e uma água, entregar uma semente na Mochila, sem exigir trigo, semente anterior, Clareira restaurada ou RNG; água não ocupa slots. Cenário sem trigo/sementes só se ocorrer naturalmente.
- [ ] **SC-03 — Cultivo e reinvestimento:** arar, selecionar semente na Mochila, plantar/regar e colher trigo pelos controles normais; produzir Replantio com dois trigos. Esperado: acrescentar três sementes na Mochila e consumir dois trigos, baú primeiro e complemento pessoal quando disponível. Bônus antigos permanecem; nenhuma das duas receitas concede pontos de alquimia.
- [ ] **SC-04 — Destino do resultado e logística:** depositar sementes produzidas no baú por quantidade digitada; com Clareira restaurada, terreno arado e Primavera, ativar explicitamente o semeador. Esperado: retirada/transporte/plantio físicos com estoque exclusivo do baú; sementes pessoais não são complemento. Reutilizar observações GS-02/GS-03 quando cobrirem o mesmo percurso, sem presumir que produzir sementes restaura a Clareira.
- [ ] **SC-05 — Persistência das receitas:** salvar um lote de Recuperação ou Replantio ainda em andamento, reabrir/carregar e conferir saldos/resultado; recarregar o snapshot para verificar substituição sem soma de estoque. Esperado: quantidade exata por craft, sem cobrança ou entrega duplicada. Se terminar antes de salvar, retomada em andamento não executada; não alongar timers. Não pressupor progresso offline.
- [ ] **SC-06 — Capacidade e cancelamento:** somente se ocorrer naturalmente, conferir resultado de sementes sem espaço ou cancelamento de lote ainda pendente. Esperado: resultado integral preservado, nunca parcialmente entregue ou redirecionado ao baú; cancelamento devolve apenas reservas não usadas às origens. Liberar espaço por depósito normal e salvar/carregar conforme CAP-02/CAP-03; sem fabricar enchimento ou interromper gravação.

#### Bloco G — Poço da Vila (seis casos novos, todos pendentes)

Usar a nova build de playtest com save separado, preservando progresso já existente. Anotar água/capacidade, trigo/mistura na Mochila/baú e pontos antes/depois. Preferir caminhos normais; não editar save, usar F10, acelerar relógio ou fabricar falhas. Alternativa antiga/legado exige estado elegível natural ou cópia segura já disponível; sem pré-condição, registrar não executado. Não presumir progresso offline.

- [ ] **WL-01 — Localização e acesso:** encontrar o Poço acima dos canteiros; com enxada selecionada, clicar de longe e observar aproximação/parada fora do corpo antes de abrir. Antes da Clareira, conferir projeto bloqueado, reserva funcional e painel opaco legível. Esperado: ferramenta preservada, sem andar contra parede nem arar sob construção; abrir não gasta/concede água.
- [ ] **WL-02 — Marco, consulta e materiais:** restaurar a Clareira pelos caminhos normais e abrir o painel. Se faltar trigo/mistura, conferir orientação e confirmação indisponível, sem gasto. Fechar, transferir recursos entre Mochila/baú e reabrir: quantidades/custo refletem estoque atual; consulta não dá XP/benefício nem exige retirar do baú.
- [ ] **WL-03 — Projeto e cobrança única:** com benefício ainda não obtido, reunir 8 trigos + 1 mistura e confirmar. Quando possível, dividir fontes para observar baú primeiro/complemento pessoal. Esperado: custo exato, capacidade 20, visual concluído, reserva sem recarga instantânea e regeneração sem aceleração. Abrir/repetir confirmação não cobra novamente nem concede pontos/habilidade.
- [ ] **WL-04 — Alternativa e legado:** somente com estado elegível, obter o talento antigo por 1 ponto antes do projeto. Esperado: mesmo benefício/capacidade, projeto reconhece concluído sem cobrar materiais; talento não exige Clareira. Depois do projeto, talento não cobra ponto adicional. Capacidade legada maior não diminui nem compra melhoria duplicada. Caminhos incompatíveis no mesmo progresso podem ficar não executados, sem reset do save pessoal.
- [ ] **WL-05 — Persistência e viagem:** após melhoria, F5, fechar/reabrir/F9 e conferir visual/capacidade/estoques/água do snapshot. Recarregar não soma benefício nem repete cobrança. Viajar ao Bosque fecha painel e não permite consumo remoto; F5 fora/F9 retorna à vila e conserva estado. Tempo posterior ao snapshot pode ser revertido normalmente; sem esperar regeneração offline.
- [ ] **WL-06 — Painel e regressões:** em 800×720 e 1280×720, abrir/arrastar/atualizar/redimensionar/fechar por botão e Escape. Esperado: controles contidos, fundo opaco, atualização conserva arraste e clique de fundo/atalhos não alteram mundo/ferramenta enquanto aberto. Depois, com enxada, abrir baú/caldeirão, fechar e arar um lote válido; viajar/voltar não deixa modal travado. Registrar conforto/posição/arte separadamente da integridade dos recursos.

Total integrado: **36 casos pendentes** (30 anteriores preservados + 6 do Poço). Aprovações anteriores permanecem registradas acima; esses casos não foram executados manualmente nesta etapa.

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
