# Decisions

## Decisão 122 - Melhoria opcional do Poço com duas aquisições não acumuláveis

- Vila em Reconstrução aprovada: poço físico funcional antes/depois, projeto após Clareira restaurada por 8 trigos + 1 mistura restauradora. Village Storage prioritário, Mochila complementar. Capacidade 10 → 20, sem recarga instantânea, acelerar regeneração ou tempo offline. Preservar capacidades legadas maiores.
- `skill_agua` antiga continua alternativa de 1 ponto, sem exigir Clareira. Ambas levam ao mesmo benefício: não acumular capacidade, gastar novamente ou inventar XP/habilidade/projeto pago. Capacidade já ≥20 recusa ambas as cobranças.
- Incremento 1 implementa contratos/preflight puro, APIs no EconomyManager, SkillTree unificado e campo opcional `poco.melhoria_projeto` no v4, com legado v3/v4 e replay sem novos gastos/prêmios. Projeto depende do marco recebido, não da sessão antiga. Payload inválido é recusado antes de mutação; escrita inconsistente preserva arquivo anterior. Guards impedem reentrada/save/load durante retirada incompleta; rollback conserva fontes.
- Suíte 53/53, 89 verificações do teste novo e reaberturas reais em dois processos (8 + 8), fixture da habilidade (2); reaberturas/fixture anteriores também passaram. QA isolado e save pessoal idêntico por hash/tamanho/data. Falha/reentrada de estoque é fixture sintético, não problema reproduzido no save pessoal.
- Sem objeto físico novo/exportação neste incremento; não afirmar picking/proximidade homologados. Incremento 2 integra objeto/painel/navegação; 3 fecha exportador/pacote/checklist. As 30 pendências manuais permanecem. Não ampliar loja/economia/NPC/mapas/mastery ou criar framework geral de projetos.

## Decisão 121 - Fechamento do ciclo sustentável com auditoria de pacote isolada

- Incremento 3 autorizado e concluído tecnicamente. Exportador executa recuperação/reabertura, fixture de replantio/reabertura imediatamente após o ciclo, antes de outra cena substituir o arquivo QA. Exige PASS com contagem específica dos modos; quatro reaberturas totais (6 + 3 + 8 + 8), fixture adicional (2) separado no manifesto.
- Controle negativo com build antiga revelou possível falso positivo por recursos locais quando a auditoria roda da pasta do projeto. `--path` agora aponta à pasta do pacote; receita ausente é recusada. Auditoria positiva do PCK novo confere duas receitas, ingredientes/resultados, disponibilidade, tempo e XP, além de dependências, exclusões e save separado.
- Fonte é capturada uma vez para checkout e manifesto; HEAD posterior não identifica indevidamente uma build anterior. Primeira passagem preliminar `66b9d4b` passou na suíte, mas foi substituída após estas correções; metadata local corrigida e pacote marcado como preliminar. Entrega definitiva `SustainableFarm-20261004` exporta `8a1bc4a`, com nova suíte 52/52, quatro reaberturas, fixture e startups headless/OpenGL aprovados.
- Checklist mantém 24 casos anteriores intactos e acrescenta seis SC, todos pendentes. Fechamento técnico dos incrementos 1–3 não é aceite manual, artístico, de ritmo ou balanceamento. Autor indisponível não precisa testar agora. Save pessoal idêntico por hash/tamanho/data; build/QA/arte local fora do Git, sem mudar gameplay/schema ou sistemas reservados.
- Próxima construção começa por proposta delimitada de gameplay/progressão. Não iniciar automaticamente economia/NPCs/mapas/mastery ou reabrir a V0 já aprovada.

## Decisão 120 - Orientação de sementes e validação do ciclo com fontes reais

- Incremento 2 autorizado. Explicar receitas nos tooltips existentes/Livro, depósito no estado sem estoque do golem e fontes de plantio no baú, em ambas as direções. Corrigir texto que tratava toda semente como exclusivamente pessoal; apenas trigo serve ao piloto semeador. Sem nova janela/HUD/automação/toggle, schema ou regras de aquisição.
- Nome Semente de Trigo no resultado do Livro reutiliza catálogo apenas para este ID. Captura mostrou descrição longa empurrando Produzir para rolagem; textos encurtados sem remover instrução essencial, controles/rolagem existentes preservados. Custos/quantidades/tempo e lógica agrícola/semear inalterados.
- Teste integrado usa caminhada/coleta reais no Bosque, água regenerada pelo poço, timers de produção/crescimento, plantio/rega/colheita manuais, reinvestimento e depósito seletivo de sementes produzidas. Clareira restaurada é fixture explícito só na integração do golem, não desbloqueio causado pela receita. Bônus RNG não são requisito; eventos de colheita podem conceder XP antigo, por isso teste compara XP antes/depois de cada receita, sem desativar/reformular eventos.
- 77 verificações do ciclo; arquivos reais só em QA, com duas reaberturas de receita em processos separados (8 + 8) e fixture adicional de replantio (2). Retirada física, pausa/cargo/Bosque/save externo/replay/retomada conservam estoques. Suíte 52/52 e retestes após polimento; OpenGL do ciclo e painel do golem, mais reaberturas existentes. Save pessoal idêntico por hash/tamanho/data, arte local/arquivos alheios fora do commit.
- Incrementos 1–2 concluídos tecnicamente, sem exportação ou aceite manual. Os 24 casos anteriores continuam pendentes. Próximo 3 integra reaberturas no exportador, build limpa auditada e checklist ampliado; não ampliar economia/NPCs/mapas/mastery ou fechar experiência automaticamente.

## Decisão 119 - Reposição determinística de sementes de trigo pelo caldeirão

- Ciclo Sustentável da Fazenda aprovado: 1 carvão + 1 água → 1 semente de trigo para recuperação sem trigo/sementes, e 2 trigos → 3 sementes para reinvestimento. Baseline confirmou 10 sementes iniciais e bônus aleatório de colheita; esgotamento é risco, não bloqueio reproduzido no save pessoal. Estoque inicial, RNG, estações, semeador e fontes existentes do Bosque/poço permanecem.
- Incremento 1 adiciona dois RecipeData Resources padrão de categoria semente, sem descoberta obrigatória, marco ou pontos de alquimia. Tempo provisório de 2 segundos por craft; quantidades aprovadas não são balanceamento final. Recuperação pelo Livro usa água da reserva não slotada, sem exigir arraste da Mochila.
- Reutilizar Resolver, manual/lote, VillageResourceAccess e snapshot existentes. Baú prioritário/complemento pessoal, resultado na Mochila e depósito explícito para o golem. Cancelamento devolve só crafts pendentes às origens; capacidade bloqueada conserva resultado integral. Sem scheduler/SaveManager/schema/economia/NPC/mapa/mastery novo.
- SustainableSeedsSmokeTest: 86 verificações de catálogo, padrão/reconciliação legada sem XP/duplicação, ingrediente repetido, manual e botão/quantidade do Livro, lotes, origens/refund, recursos insuficientes, capacidade, replay JSON/nova instância e timer real. Fallback legado do teste de Resolver usa água + água para não colidir com Resource real; nenhuma receita de água + água no catálogo do jogo.
- Importação sem erros, suíte 51/51 e reaberturas existentes do golem em processos separados (6 + 3), QA isolado e save pessoal idêntico por hash/tamanho/data. Sem nova exportação; GolemSower-20261003 ainda não contém este incremento. Os 24 casos manuais permanecem pendentes. Próximos incrementos: orientação/integração coleta → produção → plantio com save/viagem, depois build auditada/checklist; contratos não equivalem a playthrough ou aceite manual.

## Decisão 118 - Fechamento técnico do semeador sem presumir aceite manual

- Fase F fecha A–F tecnicamente, sem novo gameplay/schema/economia/NPC/mapa. Exportação somente da fonte versionada `226bb72`, em checkout limpo; pacote local GolemSower-20261003 preserva a build anterior e permanece fora do Git. Save exclusivo CauldronCropsPlaytest, sem copiar o pessoal; versões de playtest compartilham esse ambiente separado e não apagam progresso anterior.
- Runner executa reabertura em novo processo imediatamente após cada fixture de persistência/UI; registra contagem no manifesto. Suíte 50/50 e reaberturas 6 + 3 passaram; timers/viagem/concorrência cobertos pelas regressões existentes. Inicialização do EXE headless/OpenGL oculta e auditoria do PCK passaram, incluindo scripts/cenas/ícone do piloto e exclusões internas. Não extrapolar startup a gameplay completo aprovado.
- Checklist integrado preserva 16 casos anteriores e acrescenta oito GS, todos pendentes. Autor indisponível: não exigir gate manual agora nem confundir autorização com aceite. Save pessoal idêntico por hash/tamanho/data, arquivos alheios intactos e fora dos commits. Fonte/documentação enviadas ao GitHub; builds/saves/QA não.
- Após este fechamento, planejar próximo recorte antes de ampliar conteúdo; checklist/arte/ritmo continuam como portão de experiência, sem reabrir a V0 já aprovada ou definir sistemas reservados sem autorização.

## Decisão 117 - Ativação opcional do semeador e estados no painel

- Fase E autorizada: Semear trigo no painel do golem existente. Marco GroveExpedition.restored libera a opção sem ativar, conceder nova recompensa/talento ou mudar receitas existentes. OFF por padrão e no legado elegível; somente interação explícita usa API da D. Bloco de save da C não mudou.
- Consulta pura informa motivo de indisponibilidade e estado da carga, sem reservar/consumir estoques ou mudar tarefa/solo/progresso. Atualização/load sincroniza checkbox sem sinal; OFF durante carga conserva devolução física. Não inferir sementes da Mochila. Falta do talento de rega não mascara semeadura nos modos mistos; Só regar continua exigindo talento.
- Fundo opaco, largura local/quebra, diagnósticos redundantes ocultos e tarefa não duplicada quando cargo já a descreve. Preservar arraste durante atualização/resize/cache, controles/caminhos e prioridades existentes. Sem F10, HUD extra ou infraestrutura global de janelas. Geometria testada em 800×600, 800×720 e 1280×720; inspeção não é aprovação estética/picking manual.
- GolemSowerUISmokeTest: 325 verificações, três de reabertura em novo processo, clique bloqueado/ON/OFF, estados/consulta sem mutação, recompensas antigas da Clareira, legado/replay, janela/arraste e cache após Bosque. Importação sem erros, suíte completa 50/50 e inspeção OpenGL; save pessoal intacto. QA/arte local/UIDs alheios fora da publicação. Manual adiado.
- Próxima Fase F fecha auditoria/exportação com save separado e checklist integrado. Não declarar piloto aprovado manualmente ou ampliar escopo por conclusão técnica da UI.

## Decisão 116 - Semeadura física e devolução com custódia

- Fase D autorizada: scheduler no golem existente, trigo/quatro células, fallback depois da colheita/rega elegíveis e fonte exclusiva VillageChest. API de ativação requer Clareira restaurada, mas não há botão novo nesta fase. OFF por padrão/saves antigos; não arar, consumir Mochila, criar golem/cultura/recompensa ou alterar UI/F10.
- Retirada somente ao chegar à aproximação sul do baú, revalidando alvo/estação/saldo. Uma semente em cargo antes de caminhar; nenhuma reserva antes da chegada. Plantio valida novamente alvo vivo no registro, proximidade real, estação/solo/bloqueio/visibilidade/ocupação. Consumir/instalar cultura continua no commit síncrono da B; callback obsoleto não finaliza sobre snapshot reentrante.
- Navegação da semente não aceita mero fim de rota como chegada. Tolerância de sincronização inicial, caminho vazio/fim distante e limite de trajeto conservam cargo em falha; reutiliza desvio legado, sem prometer navegação universal ou reestruturar IA inteira. Ícone acompanha a carga. Colheita/rega mantêm navegação e talento atuais.
- Pausa congela. OFF ou modo exclusivo encaminha devolução física, sem refund remoto; baú ausente, espera interrompida ou caminho impossível mantém semente. Geração protege movimentos/plantio/devolução; load/cache retomam do cargo sem retirada extra. Vila ausente continua sem transporte offline/remoto; saves e schemas da C permanecem.
- GolemSowerPhysicalSmokeTest cobre 107 verificações com rotas/timers reais, conservação, concorrência, pausa/OFF/prioridades, caminho/baú, JSON/replay e viagem/retorno; scheduler recorrente na velocidade padrão usa apenas relógio QA acelerado/culturas longas no fixture. Testes manuais continuam adiados; E entrega disponibilidade/controle no painel existente e F fecha exportação/checklist. Não presumir piloto completo/aprovado manualmente.
- Fechamento técnico: importação sem erros e suíte completa 49/49 em QA isolado, mais retestes físicos/persistência/reabertura. Save pessoal preservado por hash/tamanho/data; arte local e UIDs auxiliares alheios fora da publicação. Sem nova exportação.

## Decisão 115 - Snapshot do trabalho físico do golem

- Fase C autorizada: bloco opcional golem_work interno v1 com flag de semeadura, prioridade e cargas exclusivas de colheita/semente. Preservar save v3/v4, sem serializar rota/posição/referências/callbacks. Totais da colheita são separados do estoque; não inventar carga não registrada por saves antigos.
- Preflight GolemWorkState usa restored do snapshot recebido, não da sessão atual; valida tipos/IDs/inteiros/intenção OFF/devolução e carga dupla antes de mudar região/estoques/progresso/golem. JSON de sementes normalizado. Aplicação substitui sem refund ou retirada; legado completo sem bloco OFF/cargas vazias/default, enquanto contrato parcial sem inventário completo nem bloco preserva runtime.
- Geração invalida callbacks e waits após pause/load/aborto/saída da árvore. Carga e prioridade persistem; rota/tarefa não. HOME cacheada fornece snapshot externo; ausência só avança culturas/caldeirão. Carga de semente restaurada não trabalha enquanto scheduler D ainda não existe. Unlock e UI permanecem E; nenhum save elegível é ativado automaticamente.
- Colheita instala carga antes de sinal de lote vazio, evitando snapshot entre donos; depósito limpa carga antes de feedback. Baú inválido conserva entrega. Gravação com carga inválida/golem indisponível preserva arquivo anterior; durante load, gravação e reentrada são recusadas. Fixtures fora da vila não ganham bloco inventado, mas save normal exige golem físico disponível.
- GolemWorkPersistenceSmokeTest: 148 verificações de domínio/JSON/legado/replay/substituição, esperas obsoletas com mesmo estado, sinais consistentes, pausa/cache, save/load real em QA e nova instância; seis verificações extras de reabertura em outro processo. Recusas sintéticas produzem warnings esperados. Manual segue adiado; proximidade/caminho físico e UI não homologados por estes testes.
- Próxima Fase D integra retirada/transporte/plantio/devolução com esta persistência, preservando canteiro/trigo/fontes/prioridades e sem novos sistemas de economia/mapa/rega automática. Não declarar semeador jogável nesta fase.
- Fechamento técnico: importação sem erros, suíte completa 48/48 em QA isolado, reabertura em segundo processo e save pessoal intacto por hash/tamanho/data. Arte local e UIDs auxiliares não relacionados fora da publicação; sem nova exportação nesta fase.

## Decisão 114 - Commit comum de plantio e domínio isolado de carga

- Fase B autorizada e implementada sem ligar semeadura automática. FarmPlot valida sem mutação antes de consumir fonte explícita; clique manual usa Mochila, entrada de golem usa somente GolemSeedCargo e verifica o alvo no registro vivo. Preserva quatro culturas, estações, aragem, rega e aceleração de verão. Recusas conservam metadados/timer/estoques/seleções/sinais; cultura usa cópia do catálogo.
- Os dois consumidores internos atuais são síncronos e não emitem sinais; estado agrícola/timer/visual ficam completos antes de publicar estado_alterado. Não abrir callback de fonte agregada/externa nem consumir VillageResourceAccess para sementes. Observadores e bridge verificam estoque/carga já consumidos, sem await entre fronteiras de custódia.
- GolemSeedCargo representa uma unidade de trigo, alvo fixo e intenção transportar/devolver, sem referência de nó/rota persistida. Retirada exclusiva do VillageChest, segunda retirada impedida, consumo/devolução únicos. Baú indisponível conserva pendência; capacidade futura do Storage exige rever contrato de depósito, hoje ilimitado/síncrono. Proximidade e exclusão mútua com colheita serão obrigações da integração física, não implementadas neste domínio.
- Payload ausente null; presente exatamente item_id/quantity/target_cell/intent. Preflight estrito aceita números integrais JSON exatos sem coerção de bool/string/frações; cópias profundas e aplicação substitutiva sem refund. É serialização de domínio, não persistência integrada: SaveManager/Golem permanecem intactos até Fase C. Nenhuma carga nova entra nos saves ou é retirada automaticamente nesta etapa.
- GolemSowerDomainSmokeTest: 365 verificações, incluindo quatro culturas/modificadores, recusa sem mutação, quatro células/identidade, alvo ocupado pelo jogador, fonte exclusiva, sinal consistente, JSON/replay/payload inválido e devolução única. Manual permanece adiado. Próxima Fase C trata snapshot/preflight/load de sementes e colheita antes de habilitar scheduler na D; sem ampliar economia/UI/lore por consequência.
- Fechamento técnico: importação sem erros, suíte completa 47/47 em QA isolado e save pessoal intacto por hash/tamanho/data. Sem nova exportação nesta fase; arte local e UIDs auxiliares não relacionados excluídos da publicação.

## Decisão 113 - Piloto do Golem Semeador e custódia de sementes

- Autor aprovou o recorte e o início pela análise técnica. Golem físico existente, trigo e quatro lotes iniciais fixos, habilidade derivada de Clareira restaurada, opcional OFF inclusive em save antigo elegível. Sementes vêm dos caminhos atuais e saem somente do baú quando golem chega; nunca usar Mochila como complemento. FarmPlot permanece autoridade e grid apenas identidade/ponte.
- Baseline: plantio manual acoplado à seleção/consumo pessoal; VillageResourceAccess agrega fontes; SaveManager não registra carga física do golem; finalizador de depósito limpa carga mesmo com baú inválido. Não reutilizar cegamente esses caminhos para sementes. Riscos por leitura, sem perda pessoal reproduzida nem implementação corretiva nesta fase.
- Custódia única baú → carga → cultura ou devolução física; uma semente por vez, carga separada da colheita. Validação live antes da retirada e do commit; sem bloquear ação do jogador, sobrescrever cultura, remover recurso na recusa ou depender apenas de fim de rota. Pausa/cache/load invalidam callbacks sem apagar carga. Vila ausente não simula deslocamento/plantio remoto.
- Bloco opcional aditivo de save v3/v4, ausência OFF/sem carga nova; preflight antes de qualquer mutação, aplicação substitutiva sem refund e rota reconstruída. Incluir tratamento da carga de colheita existente na integração do snapshot. Persistência antecede qualquer retirada viva. Sem mudanças de prioridades somente colher/regar/pausado ou de rega/talento.
- Plano e critérios em FARM_SYSTEM_V2. Fase A só documentação; GolemLife, SaveContract e RegionTravel retestados com QA isolado. Suíte completa anterior 46/46 não repetida; manual anterior continua pendente. Próxima Fase B é domínio/custódia sem scheduler, seguida de persistência, trabalho físico, UI/progressão e fechamento/exportação.

## Decisão 112 - Build de playtest isolada e rastreável

- Recorte autorizado: preparar checkpoint jogável/checklist, sem ampliar conteúdo. Reusar Export-CleanBuild com checkout isolado do commit e preset separado, excluindo testes internos/docs/ferramentas/Builds do PCK. Alterações e arte local não versionadas não entram.
- Transformação somente no projeto temporário define diretório de save `CauldronCropsPlaytest`, inclusive para abertura direta do EXE. Não copiar progresso pessoal automaticamente nem mudar o projeto de desenvolvimento/schema. Launcher escolhe OpenGL de compatibilidade; configuração gráfica fonte permanece intacta.
- Manifesto registra commit, hashes, transformação e execução da suíte; auditoria do pacote confere exclusões, recursos dinâmicos e isolamento. Checklist/manual continuam pendentes; startup/export técnico não são aprovação de gameplay/arte.
- Fechamento: fonte `c43abae`, suíte limpa 46/46, auditoria do PCK, startup headless/OpenGL de 120 frames sem erros e save pessoal intacto. O teste de arquivo recusou corretamente APPDATA fora do QA do checkout temporário; runner corrigido. UI deixou de fazer preload de um teste dev necessário somente à ação explícita no editor; nenhuma reativação de F10/gameplay. Checklist entregue contém somente seus 16 casos, não todo histórico do ROADMAP. Pacote local ignorado pelo Git; próximo recorte é proposta delimitada de gameplay, não autorização automática de sistemas reservados.

## Decisão 111 - Prioridade de controles quando a HUD está saturada

- Autor autorizou o próximo recorte de fallback. Candidatas livres continuam preferidas. Sem espaço livre, minimizar lexicograficamente área sobre controles, sobreposição restante e distância à posição preferida. Proteger botões visíveis/habilitados, slots da Mochila e cancelamento do lote; os três consumidores existentes reutilizam a mesma busca.
- Não mover/minimizar objetivos do jogador nem criar gerenciador global/compactação automática. Escolha entre candidatas, não otimização contínua ou garantia de zero sobreposição em tela saturada. Conteúdo não interativo pode ser coberto no extremo.
- `HUDCrowdedFallbackSmokeTest`: 28 verificações em três resoluções, saturação evitável/inevitável, determinismo, arrastes com lote ativo, minimizar/cancelar e snapshots de domínio invariáveis. OpenGL inspecionado. Picking/conforto manual UI-06 permanecem adiados; produção, estoque, progressão e save intactos.
- Fechamento técnico: suíte 46/46, importação sem erros e save pessoal intacto por hash/tamanho/data. Arquivos locais não relacionados fora do checkpoint. Próximo recorte: preparar checkpoint jogável/checklist, sem ampliar conteúdo automaticamente.

## Decisão 110 - Avisos temporários do caldeirão em coordenadas de tela

- Autor autorizou corrigir avisos existentes; baseline reproduziu aviso fora da tela. Ponto do caldeirão passa por transform com canvas; helper existente recebe quatro segundos de leitura, quebra/contorno/input ignorado. Componente local de Label contém largura/posição durante resize e, se tocar HUD/produção/tracker, reutiliza busca de espaço livre com reserva vertical para animação. Não altera helper global nem cria fila/janelas novas.
- Aviso novo oculta/remove o anterior, inclusive entre sucesso, lote pronto, cancelamento e recusa. Limite de golems conserva mensagem própria; estoque, domínio/receitas, entrega/refund/timers e save não mudam. Sem espaço livre não há garantia absoluta de não sobreposição; não mover/minimizar objetivos do jogador automaticamente.
- `CauldronTemporaryFeedbackSmokeTest`: 33 verificações em quatro resoluções de 800×600 a 1920×1080, três offsets de câmera com scroll atualizado, resize durante aviso, substituição, tempo de leitura/remoção, input/quebra, limite de golems e snapshots invariáveis. Renderização OpenGL conferida. Manual UI-05 adiado; conforto/picking/arte não aprovados por sinais/geometria. Próximo recorte: fallback de falta de espaço, sem ampliar gameplay.
- Suíte 45/45 e retestes finais do aviso, produção (87) e coexistência (305), importação sem erros e save pessoal intacto por hash/tamanho/data. Warnings de refund bloqueado são esperados nos fixtures.

## Decisão 109 - Gravação protegida e backup explícito do save

- Autor autorizou o recorte de integridade do save existente. Helper ProtectedSaveFile grava/confere temporário no mesmo diretório, prepara/confere cópia do principal em `.bak.tmp`, promove backup e só então substitui principal. Erros retornam false com mensagem visível. Não abrir principal com WRITE; não substituir backup por principal JSON inválido, não carregar temporário órfão nem fazer recuperação silenciosa. Formato v3/v4, snapshot/preflight/aplicação e gameplay preservados.
- Backup representa conteúdo anterior íntegro como objeto JSON, não nova validação semântica do gameplay. Load continua sujeito ao preflight existente. Novo jogo explicitamente solicitado remove principal/backup/temporários conhecidos; testes nunca executam esse fluxo no save pessoal. Arquivo principal ausente/inválido ou conteúdo recusado informa existência de backup, sem escolher progresso mais antigo pelo jogador.
- `ProtectedSaveFileSmokeTest`: 19 verificações, incluindo primeira gravação/Unicode/v3/v4, substituição/backup, falhas de promoção simuladas, diretório ausente, temporários bloqueados de verdade, órfão incompleto, principal inválido preservando backup e save/load/recusa com aviso/limpeza reais. Recusa execução se user:// não estiver sob Builds/QA. Não simula falha física/queda de energia nem oferece garantia de durabilidade absoluta.
- Fechamento técnico: suíte completa 44/44, importação sem erros, aviso de falha renderizado/inspecionado em OpenGL e save pessoal intacto por hash/tamanho/data. Mensagem da falha sintética é esperada; manual SAVE-02 permanece adiado.
- Referência da substituição: [DirAccess Godot 4.6](https://docs.godotengine.org/en/4.6/classes/class_diraccess.html#class-diraccess-method-rename-absolute). Mesma pasta/volume e backup reduzem risco, sem afirmar transação atômica garantida em todos os sistemas de arquivos. Aceite manual normal continua adiado; nunca provocar falha no save pessoal. Próximo recorte: avisos temporários legados do caldeirão, preservando transações.

## Decisão 108 - Checklist único e priorização dos riscos existentes

- Continuidade autorizada para consolidar pendências e auditar riscos, sem implementar sistemas nesta etapa. ROADMAP passa a reunir IDs de teste, pré-condições, resultados esperados e referência aos aceites já registrados; planos de Mochila/Bosque e README apontam para a fila operacional. Não reabrir V0 nem exigir repetição total de testes aprovados.
- Testes manuais permanecem adiados. Casos de capacidade, estados anteriores à restauração e saves legados reais são condicionais; sem pré-condição segura, marcar não executado. Não editar/apagar save pessoal, reativar F10 ou encher artificialmente a Mochila. A última suíte 43/43 pertence ao checkpoint `3d2240f`, não foi executada novamente nesta revisão documental.
- Auditoria delimitada confirmou gravação direta em SaveManager sem temporário/backup; risco de interrupção/falha é inferido, sem perda reproduzida. Testes dev atuais exercitam snapshots/JSON, não save/load de arquivo. Avisos temporários do caldeirão ainda usam caminho legado sem contenção e busca de layout tem fallback potencialmente sobreposto quando não há espaço livre. Não declarar auditoria exaustiva nem regressão dos cenários já testados.
- Próximo recorte recomendado: proteção da gravação e cópia recuperável, testes de I/O isolados, falhas sem destruir último save válido e erro visível; preservar schema v3/v4 e gameplay. Não implementar slots/cloud/framework de migração ou recuperação silenciosa. Isso é manutenção de integridade do sistema existente, não revogação automática da decisão histórica de adiar arquitetura avançada de persistência. Implementação aguarda continuidade autorizada para esse recorte.

## Decisão 107 - Objetivos e produção respeitam áreas ocupadas da HUD

- Baseline reproduziu colisão entre objetivo da Clareira e aviso persistente do caldeirão. Ajuste restrito à apresentação: busca posições próximas ao canto inferior direito, evitando Mochila, ferramentas, botões visíveis do Caderno e objetivos iniciais. Produção tem prioridade; tracker evita também seu retângulo. Não reposicionar os objetivos arrastados pelo jogador para acomodar estes avisos.
- Reutilizados helpers em HUDLayout, sem framework de janelas ou novos sistemas. O VBox legado possui altura vazia das lojas removidas: só seus filhos visíveis reservam espaço. Altura do tracker segue conteúdo/minimização. Eventos de geometria/visibilidade/resize e refresh existente mantêm layout atualizado. Sem alterar estoques, reservas, produção, timers, progresso ou save.
- Regressão com 305 verificações em 800×720, 1024×768, 1280×720, 1920×1080 e 2560×1440: cinco estados de produção, arraste, minimização, cancelamento contido e snapshots invariáveis. Warnings de restituição bloqueada são esperados no fixture sintético. Testes não acessam o save pessoal.
- Suíte completa 43/43, importação sem erros e inspeção técnica OpenGL/D3D12. Save pessoal intacto por hash/tamanho/data; avisos transitórios de ações continuam fora do escopo da coordenação dos painéis persistentes.
- Manual adiado: conforto no mapa, minimizar/arrastar/redimensionar e clicar em baú/caldeirão com avisos ativos. Busca não promete coexistência quando o jogador ocupa todo o espaço livre ou em resoluções menores não homologadas; picking real e arte não aprovados por geometria/renderização. Próximo recorte: checklist integrado e auditoria das pendências existentes, sem expansão automática de conteúdo.

## Decisão 106 - Próxima ação contextual da expedição

- Autor autorizou orientar o objetivo da Clareira conforme recursos existentes. Texto estático foi substituído por uma próxima ação e contador da Mochila: coletar carvão faltante, preparar apenas misturas faltantes, retirar quantidade necessária do baú, aguardar/recolher produção ou resolver cancelamento pendente. Com carga suficiente, orienta levar ao Bosque ou interagir com a Clareira conforme a região.
- Consulta HOME atual/em cache somente para informação do baú/caldeirão; não transfere recursos nem reconcilia timers. Carvão da vila pode orientar retorno/preparo, mas não é consumido remotamente. Receita/custo piloto de 2 carvões por mistura permanecem; não há nova etapa, automação de produção, recompensa, flag ou schema de save. Sem descoberta/restauração pendente, texto vazio e tracker oculto pelas regras existentes.
- Minimização e ocultação em modais preservadas. `GroveObjectiveGuidanceSmokeTest`: 37 verificações de orientação, consultas invariáveis, produção manual/lote/bloqueio/cancelamento, viagem real com HOME em cache, JSON, minimização e contenção em três resoluções. Suíte 42/42 e importação/renderização OpenGL/D3D12 conferidas; avisos de refund bloqueado são esperados no fixture.
- Manual adiado: conferir cada orientação com estoques reais, produção e depósito/retirada, viagem e minimização. Não afirmar picking, conforto ou layout global aprovado. Próximo incremento recomendado: conferir coexistência dos painéis de objetivos/produção/HUD e corrigir sobreposições concretas, sem novo conteúdo ou sistemas.

## Decisão 105 - Requisitos de restauração e origem dos recursos

- Autor autorizou melhorar comunicação do Herbário e da Clareira existentes. Herbário apresenta disponível/necessário por item somando Storage e Mochila; recusa informa o que falta e consumo prioritário do baú. Falta de espaço na recompensa informa item/quantidade, depósito e nova tentativa, sem consumo do custo. Aviso novo substitui anterior para evitar sobreposição em cliques repetidos.
- Clareira mostra misturas disponíveis/necessárias somente na Mochila e explica que não acessa o Baú da Vila. Recusa orienta preparar as faltantes e preserva carga; antes da descoberta continua apenas “Investigar clareira”. Contadores acompanham recursos runtime, inclusive após load. Conclusão oculta requisitos do Herbário e mantém a Clareira identificada como restaurada.
- Ajuste de texto, contraste, quebra de linha e espaço acima dos objetos. Avisos do Herbário usam conversão mundo → tela e quatro segundos de leitura do helper existente; helper retorna o Label para substituição local, sem fila/framework novo. Custos, purificação, transações, recompensas/marcos, aprendizagem e schema de save não mudam.
- `RestorationFeedbackSmokeTest`: 18 verificações de contadores/origens, consultas sem consumo, recusas/capacidade, substituição de aviso, JSON e restaurações/recompensas únicas; renderização técnica OpenGL/D3D12. Suíte 41/41 e save pessoal intacto. Manual adiado: leitura no mapa, alterar estoques pelo baú, recusas e nova tentativa, visita com misturas no baú versus Mochila. Picking/conforto/arte não aprovados automaticamente.

## Decisão 104 - Avisos de capacidade na pesca e coleta

- Autor autorizou o recorte recomendado, com playtest adiado. Avisos passam a explicar a diferença entre recurso externo não coletado (permanece no ponto; depositar na vila e voltar) e captura já obtida (preservada; entrega automática integral quando houver espaço). Nenhuma nova fila, destino ou mudança de aquisição.
- Coleta informa item/quantidade e mantém o aviso por quatro segundos antes da animação de saída; recompensa e marco só ocorrem na coleta bem-sucedida. Pesca antes da sincronia informa falta de espaço para os resultados possíveis, sem prometer uma captura ainda não obtida. Avisos de capacidade no lago são convertidos do mundo para tela, contidos no viewport e não capturam input.
- Captura preservada lista os itens/quantidades, inclusive recompensa dupla; texto é projeção somente leitura. Painel da pesca opaco, instruções/resultado com quebra de linha e reposicionamento após texto/resize mantêm Fechar acessível. Entrega automática, atomicidade, coleção após entrega, proteção contra sobrescrita e campos de save permanecem intactos. Demais textos flutuantes mantêm duração histórica.
- `CollectionCapacityFeedbackSmokeTest`: 18 verificações de fonte/estoque preservados, duração de leitura, recusa pré-sincronia, captura dupla, layout em 800×600/1024×768/1280×720, JSON, nova tentativa bloqueada e depósito → entrega/coleta únicas. Inspeção OpenGL/D3D12; testes isolados sem I/O do save pessoal. Checklist manual adiado: leitura no Bosque/lago, depósito/retorno, captura bloqueada durante sincronia e retomada após save/load. Picking, conforto e arte não presumidos aprovados.

## Decisão 103 - Feedback persistente dos estados existentes do caldeirão

- Continuidade autorizada com testes manuais adiados. O painel de lote estava em coordenadas do mundo e o resultado manual pronto não tinha aviso persistente de tela. Reutilizado o painel em CanvasLayer, opaco e contido no canto inferior direito, independente da câmera; layout reaplicado ao reanexar HOME em cache.
- Projeção somente leitura apresenta mistura em preparo, resultado pronto, lote ativo, resultado bloqueado por capacidade e cancelamento pendente. Quantidade por preparo não é confundida com número de preparos entregues. Instruções explicam depósito no baú/recolhimento/retomada ou nova tentativa de cancelamento. Capacidade de golems legados não é descrita como espaço na Mochila.
- Botão/callbacks existentes preservados; cancelamento pendente apenas muda o texto para nova tentativa. Nenhum retry automático, nova fila, mudança de destino, consumo, reserva, timers ou persistência. Load reconstrói apresentação a partir do estado existente.
- `CauldronFeedbackSmokeTest`: 87 verificações, três resoluções, câmera/cache, estoques invariáveis durante apresentação, estados carregados por JSON, entrega única e restituição às origens após bloqueio. Suíte 39/39 e renderização OpenGL/D3D12 conferidas. Avisos de restituição bloqueada no cenário sintético são esperados; save pessoal não é acessado pelos testes.
- Checklist manual adiado: legibilidade em jogo, baú para liberar capacidade, recolher/retomar e repetir cancelamento, resize e retorno do Bosque. Sinais/retângulos não validam picking real, conforto, balanceamento ou aprovação artística. Próximo recorte recomendado: avisos de capacidade na pesca/coleta existentes, sem criar sistemas.

## Decisão 102 - Apresentação responsiva do caldeirão e Livro

- Autor autorizou a etapa após a HUD, mantendo testes manuais adiados. O caldeirão tinha fundo placeholder e controles fora da borda; os detalhes do Livro não tinham limite/rolagem para textos longos. Ajuste restrito à apresentação, sem mudanças de produção, recursos, receitas ou save.
- `PopupBackground`, usado somente no caldeirão, preserva captura de cliques/drop e organiza controles existentes com fundo opaco na paleta da HUD. Slots delineados, mistura e Livro separados, botão Fechar dentro do painel. Em janela baixa, altura 320; em janela estreita, posição abaixo da Mochila para permitir arrastar ingredientes. O usuário ainda pode arrastar em runtime; resize/reabertura contém o painel. O placeholder não foi apagado do disco.
- Livro conserva os caminhos de nós/callbacks, mas `RightPanel` passa a ScrollContainer com rolagem vertical e acompanhamento de foco. Títulos/textos quebram linha; selecionar outra receita volta ao início dos detalhes. Tamanho limitado ao viewport, respeitando posição arrastada quando cabe. Root opaco; lista e cabeçalho permanecem acessíveis. Nenhuma infraestrutura genérica de popups ou tema global novo.
- `AlchemyDialogLayoutSmokeTest` tem 131 verificações em 800×600, 800×720, 1024×768, 1280×720 e 1920×1080: geometria, todos os detalhes do catálogo, descrição longa sintética, drop/fundo, estoque invariável durante layout, lote por sinais com quantidade digitada, cancelamento à origem e fechamento dos dois hosts sem ocultar HUD. Renderização OpenGL/D3D12 inspecionada; testes isolados não usam save pessoal. Não afirmar suporte abaixo de 800×600 ou picking/drag do sistema operacional. Aceite manual/estético fica no checklist futuro.

## Decisão 101 - HUD responsiva e continuidade sem gate manual imediato

- O autor não poderá fazer testes agora e autorizou continuar a construção, preparando checklist depois. Publicar incrementos verificados como checkpoints, mantendo aceite manual pendente; não interpretar ausência de teste como aprovação nem autorização irrestrita de sistemas.
- Corrigir a sobreposição conhecida da Mochila/ferramentas com objetivos em janelas menores. `HUDLayout` trata somente apresentação: largura/paginação até 12 slots, empilhamento em janela estreita, ferramentas compactas com tooltip, botão de minimizar acompanhando objetivos e painel contido no viewport. Não reparentar controles nem alterar recursos, seleção exclusiva, capacidade ou save.
- A paginação mantém o primeiro índice visível ao trocar tamanho e permite acessar todo excesso legado. `UI` mantém o modo compacto como fonte de verdade porque seu refresh periódico restaura os rótulos; não esconder ferramentas apenas por clipping. HOME reaplica layout ao entrar na árvore depois de resize fora da vila.
- Objetivos continuam inicialmente no canto superior direito, arrastáveis e opcionais; uma sobreposição deliberada após arrastar não gera reposicionamento forçado. Posições continuam runtime-only. Testado de 800×720 a 2560×1440; não prometer suporte universal a alturas/larguras inferiores.
- Regressão nova tem 230 verificações de geometria/páginas/seleção/estoque/resize/viagem, com baseline que reproduz o conflito. Suíte 37/37, importação e renderização OpenGL/D3D12 conferidas. Testes isolados não alteram save pessoal. Não substituem cliques reais, conforto ou aceite artístico; pendências reunidas no roadmap/contexto §47.

## Decisão 100 - Segunda expedição: restauração no Bosque e receita agrícola

- Após escolher novo conteúdo em vez de polimento visual/infraestrutura, o autor aprovou iniciar a grande fase em 2026-10-03. Recorte: pequena clareira no Bosque existente, um projeto, duas receitas e recompensa com efeito real no cultivo. Sem lore definitiva, lojas, moeda, NPCs, combate, regiões extras, mastery ou rede de armazenamento.
- Descobrir o canteiro ensina `mistura_restauradora_bosque` (2 carvões → 1 `mistura_restauradora`); restaurar exige 2 misturas **na Mochila** e ensina `infusao_clareira` (carvão + mistura → Poção de Crescimento). Usa o efeito existente de 3 aplicações/tempo restante pela metade e mantém a receita sazonal anterior como outra fonte da poção. Novo ingrediente tem uso na restauração e após ela, sem preço econômico aprovado.
- Uma fonte nova entrega 2 carvões e renova em 45 segundos de sessão, oferecendo recuperação determinística após gasto. Recusa por capacidade não esgota. Os quatro pontos antigos mantêm coleta única, agora persistida; não renovar por dia/estação nem contar tempo com o jogo fechado. Tempos/quantidades são piloto, duração alvo não aprovada.
- `GroveRestorationSite` não generaliza o Herbário: projeto externo específico usa transação `VillageResourceAccess(null)` apenas com recursos pessoais. Restauração/recompensa idempotentes, objetivo opaco/minimizável que desaparece ao concluir, arte vetorial de suporte sem assumir estilo final. `RecipeData.exige_descoberta=false` preserva receitas atuais; somente as novas são aprendidas por marcos. Tentativa bloqueada não consome/reserva ingredientes.
- Campos opcionais v4 `grove_expedition` e `home_inactive_seconds` guardam flags/fontes conhecidas e intervalo da sessão. Save completo anterior começa intacto; parcial preserva runtime. Pré-validar novos dados e inventário antes de mudar região/recursos. Não persistir posição externa ou criar save regional genérico.
- Para F5 fora da vila, SaveManager percorre a HOME em cache, sem depender dos grupos da árvore ativa. F9 externo volta à HOME, cancela movimento e só então restaura produtores/recursos e aplica o intervalo salvo uma vez. Snapshot agrícola reconstrói o índice a partir de FarmPlot. Teste novo reproduziu a poção cujo efeito não era espelhado no save; a aplicação agora notifica a mudança. Guarda de cache também verifica instância válida antes de testar tipo de nó liberado.
- Inspeção renderizada reproduziu fechamento do Livro ocultando toda a HUD quando seu host é a UI da vila, em vez do PopupLayer do caldeirão. Correção restrita ao fechamento: ocultar somente o host específico do caldeirão; teste cobre ambos os encaixes, sem refatorar a HUD histórica.
- Teste integrado com 72 verificações cobre Livro/ingredientes duplicados/fechamento, navegação, capacidade, origem, fases, efeito, JSON/cenas novas, save externo de lote/catch-up/cancelamento e inválidos/compatibilidade (incluindo payload parcial que troca a lista do Livro sem apagar marcos/fontes). Renderização OpenGL/D3D12 é inspeção técnica, não aceite artístico/picking manual. Plano e roteiro em `FIRST_EXTERNAL_REGION_VERTICAL_SLICE.md`; fase publicada como checkpoint enquanto playtest está pendente. Não promete 20–30 minutos: crescimento de protótipo permanece curto e precisa de balanceamento em etapa própria.

- Aceite manual parcial em 2026-10-03: autor validou investigar o canteiro/aprender receita, minimizar/expandir objetivo, coletar 4 carvões e produzir duas misturas pelo Livro mantendo a HUD acessível. Descoberta/coleta/preparo aprovados no roteiro proposto; não inclui restauração, efeito agrícola, save/load, renovação cronometrada, recusa por capacidade ou estética. Próximo roteiro: restauração/recompensa, depois persistência; registro documental sem nova suíte ou gameplay.

- Aceite manual seguinte em 2026-10-03: restauração com duas misturas carregadas, consumo/recompensa únicos, mudança visual/objetivo oculto, fabricação da Infusão da Clareira e efeito da poção no cultivo aprovados no roteiro proposto. Não inclui save/load, duração/balanceamento ou estética. Próximo teste: persistência no Bosque restaurado e depois produção em viagem, sem apagar progresso. Registro documental, sem nova suíte/gameplay.

- Aceite manual seguinte em 2026-10-03: F5/F9 no Bosque restaurado, retorno à vila com itens/receita, revisita e reabertura/load preservando canteiro/objetivo, sem recompensa/consumo repetidos, aprovados no roteiro proposto. Não inclui produção em viagem ou save anterior à restauração. Próximo teste: conclusão e cancelamento em lotes separados, usando quantidade suficiente para viajar/salvar em andamento sem alterar timers ou save. Registro somente documental, sem nova suíte/gameplay.

## Decisão 99 - Clique nos objetos tem prioridade sobre enxada em solo livre

- Auditoria de continuidade reproduziu uma falha que os testes por callbacks não cobriam: com enxada ativa, `Main._unhandled_input` consumia o clique no baú antes do physics picking. O estágio de picking ocorre depois de `_unhandled_input`; o manipulador do objeto nunca recebia o evento.
- Correção mínima: reutilizar `_world_position_has_interaction_collider` antes do fallback da enxada. Se há collider, deixar o evento não consumido para o objeto/lote; em solo livre, manter o caminho agrícola existente. Não criar despachante novo nem modificar seleção, sensores, navegação, cultivo, layout ou save.
- `CoreWorldInteractionSmokeTest` alinha câmera/mouse do viewport e chama o estágio real de `_unhandled_input`: baú, collider do caldeirão, lago e lote existente devem preservar o evento, sem iniciar rota agrícola indevida; solo livre deve continuar criando/arando um lote. A regressão falhou no baú antes da correção.
- Limite: este teste verifica a prioridade anterior ao picking, não cliques completos do sistema operacional, hitboxes de Control ou conforto visual. Em 2026-10-03, o autor confirmou sucesso no roteiro manual específico: abrir baú e caldeirão com enxada selecionada, fechar os painéis e arar um lote da grade inicial. Este aceite não inclui o roteiro de resize/save/load, viagem/restauração ou aprovação artística.

## Decisão 98 - Origem agrícola explícita e estável entre resoluções

- Após a auditoria somente leitura, o autor autorizou a implementação em 2026-10-02. O diagnóstico reproduziu deslocamento da grade com viewport 1280×720, 1920×1080, 2560×1440 e 2560×1009; em 1920×1080 havia interseção com o caldeirão e nas janelas maiores com a entrada do Bosque. O piloto também podia tocar a corrupção. Resize na mesma instância não movia a grade; recriar a cena recalculava a origem.
- `Scenes/Main.tscn/FarmOrigin` é um `Marker2D` não interativo em `(680,760)`, abaixo do núcleo da vila. `Main._ready` usa sua posição local, não tamanho de tela. Grade inicial, pocket, Herbário, pedra e piloto seguem a mesma origem. Câmera/resolução só mudam o enquadramento; baú, caldeirão, lago, entradas e obstáculo de purificação permanecem nas posições anteriores. Não ampliar navegação, limites lógicos ou conteúdo.
- Preservar espaçamento 80, os 34 IDs/ordem iniciais, registro canônico, pocket 2×2 e piloto 6×2. Conversões grid/world usam `to_local`/`to_global`, sem confundir a posição local do marcador com posição global do clique. Marcador técnico do piloto continua desligado por padrão.
- A pedra de investigação passa de `visual_position + (54,-36)` para `+(54,-130)`, acima da borda do pocket, sem cruzar a área clicável dos quatro lotes após purificar. Não muda ID, texto, requisitos ou persistência da descoberta. Herbário mantém seu offset `(180,110)`.
- Save v4 e fallback v3 não mudam. Cultura pronta/em crescimento, terra arada, rega, progresso, pocket e recompensas pendentes continuam associados às mesmas coordenadas lógicas. Não cortar, apagar ou reordenar lotes antigos; preservar a exceção transitória da política de solo para plots existentes.
- Limite de compatibilidade: arquivos anteriores não registram origem física nem viewport. Ao abrir com esta versão, os lotes ocupam o layout canônico, que pode diferir da posição visual anterior. Não prometer reconstrução exata nem inferir coordenadas ausentes. Nenhum novo schema/campo de origem ou migração destrutiva.
- `FarmWorldCoordinatesSmokeTest` valida quatro tamanhos reais de viewport em headless, layout/ordem, colliders ativos nos 34 lotes e 12 células piloto antes/depois da purificação, JSON v4/v3, colheita pendente, crescimento, replay sem duplicação, resize/pan/zoom e conversões locais/globais. Não desativar o pai para consultas físicas: isso remove os CollisionObjects. `RegionTravelSmokeTest` muda a janela fora da vila e confere origem/posição do lote no retorno ao cache.
- Validação: importação sem erros, suíte 35/35 aprovada e renderização/captura inspecionada em OpenGL e D3D12/Forward+. Comparação de hash/tamanho/data confirma `savegame.json` pessoal intacto. Arte local e UID não relacionados permanecem fora do incremento.
- Aceite manual atualizado em 2026-10-03: autor aprovou arar/plantar/regar um lote inicial, salvar/carregar após redimensionar e fechar/reabrir em outro tamanho de janela. Também aprovou viagem ao Bosque, resize fora da vila e retorno com grade/culturas preservadas e acesso a baú/caldeirão/pesca, seguido do roteiro purificação → pedra → cultivo dos quatro lotes → Herbário, sem travamento/recompensa duplicada. Aprovou ainda colheita/transporte/depósito do golem com o personagem no caminho, sem perda/duplicação de carga, e criar/plantar/regar um lote livre abaixo do lado direito da grade, sem sobreposição. Roteiros funcionais propostos concluídos; não inferir aprovação de saves legados, todas as células do piloto, roteiro de Mochila/persistência do caldeirão ou estética. Esses itens mantêm seus limites/pendências próprios. Não iniciar economia, NPCs, nova rede de armazenamento ou direção artística final.
- Checkpoint de continuidade: `CoreWorldInteractionSmokeTest` agora percorre purificação, pedra, quatro culturas e Herbário com deslocamento físico, valida consumo/recompensa/marco únicos e reaplica JSON a outra cena/resolução. Apenas teste/documentação; recursos e velocidade são sintéticos, sem save pessoal. Invocar callbacks/sinais não valida picking do mouse ou hitboxes de Control e não substitui o aceite manual.

## Decisão 97 - Paisagismo não interativo e diferenciação dos pontos do mundo

- Pacote visual seguinte autorizado em 2026-10-02. Reutilizar a grama existente e criar SVGs editáveis compatíveis com a representação vetorial atual; não substituir os bitmaps/arquivos locais do autor nem declarar direção artística final aprovada.
- `FarmLandscape` completa o fundo além do enquadramento e desenha trilhas, clareiras e vegetação baixa. Fundo -220, terreno -200, detalhes -160 e solo -90: cultivo cobre a cenografia. Sem colisores, Controls, regiões de navegação, novas restrições de plantio, recursos ou saves. RNG local determinístico não usa o sorteio de recompensas.
- Trilhas ligam baú, caldeirão, chegada, entrada do Bosque e margem do lago, consultando as posições reais desses nós. São pistas visuais, não caminhos obrigatórios ou corredores de navegação. O fundo não expande o território jogável.
- Golem substitui quadrado ciano por pedra/musgo. O nome legado `ColorRect` permanece para o contrato de animação existente, mas o nó é `TextureRect` sem captura de mouse. Sensor, movimento, trabalho, descanso e transporte não mudam.
- Lago recebe margem orgânica, pedras/juncos e água em paleta suave. Área clicável 340×220, obstáculo de navegação e bônus móveis conservam posições/tamanhos/regras; apenas a arte e a espessura do anel mudam.
- Entrada recebe arco de pedra e legenda abaixo. Corrupção usa raízes/pedra/cristal, em vez de anéis semelhantes a portais; polígonos antigos substituídos são removidos. Estados de purificação, colliders, lotes 2×2 e descoberta/restauração não mudam.
- Inspeção visual OpenGL e D3D12/Forward+; teste existente verifica paisagismo sem interação e golem sem bloqueio de mouse. `--capture-landscape` produz vistas geral/lago/golem somente em `user://`. Aceite manual permanece pendente, inclusive do pacote anterior.
- Risco pré-existente registrado: origem agrícola usa `get_viewport_rect().size` em `Main._ready`, mas lago/baú/caldeirão/entradas usam coordenadas fixas. Diferentes resoluções de inicialização deslocam o conjunto agrícola em relação a esses elementos. Estabilizar coordenadas exige etapa própria com análise de compatibilidade/save; este pacote não faz essa migração.
- Validação automatizada: 34/34 smoke tests passaram. Regressões relacionadas reexecutadas após a remoção dos visuais antigos; importação e renderização sem erros. Nenhum save pessoal escrito.

## Decisão 96 - Primeiro pacote de polimento visual pós-Mochila

- Continuidade autorizada para executar o polimento recomendado, sem antecipar economia, NPCs ou novo conteúdo. Esta entrega é uma base de legibilidade, não o aceite da direção artística final.
- Lotes intocados deixam a grama aparecer. O `_process` não sobrescreve mais as camadas absolutas configuradas no início: terreno -200, base -100, terra -90 e rega -80; plantas e partículas preservam profundidade. Corrige tanto solo sobre objetos quanto terra escondida sob o terreno.
- Caldeirão idle reutiliza a folha verde limpa já versionada, com células de 256 px e pé estável; produção continua usando a folha roxa. Não editar/remover bitmaps antigos nem publicar arte local não relacionada.
- Shader exclusivo da grama suaviza contraste/saturação sem modificar textura, navegação ou política de solo. Baú recebe detalhes geométricos não interativos. Mochila/objetivos recebem fundos opacos na paleta do painel de transferência; objetivos continuam minimizáveis/arrastáveis e somem ao concluir. Rodapé técnico substituído por texto voltado ao jogador.
- Preservados posições, colisões, 34 plots, ações, custos, save v4 e transferência lado a lado/quantidade. `WorldLayoutCleanupSmokeTest` verifica as camadas após frames reais e oferece `--capture-world` para inspeção renderizada; capturas ficam em `user://`, fora do Git.
- Aceite visual manual pendente. Golem provisório, geometria do lago/portais, bordas e composição paisagística ainda precisam de próximo pacote próprio; não declarar a arte finalizada.
- Checkpoint validado com importação, 34/34 smoke tests e capturas OpenGL da Fazenda, solo arado e transferência; nenhum save pessoal escrito.

## Decisão 95 - Colheita recusada preserva o sorteio no save

- No fechamento integrado posterior à Fase E, a auditoria encontrou que a recusa por capacidade mantinha recompensas apenas na sessão. Load limpava a pendência e podia sortear outros bônus para a mesma cultura.
- `pending_harvest_rewards` opcional registra totais por ID no `FarmPlot` e em cada `FarmTileData`. O primeiro sorteio notifica o bridge; `farm_grid` continua sendo o contrato v4 e `FarmPlot` a autoridade runtime. Não criar fila global nem alterar probabilidades.
- Load valida tipos, IDs conhecidos, quantidades inteiras positivas e cultura pronta antes de alterar estoques/progresso. Restaura o mesmo lote de itens; textos/cor de feedback são reconstruídos e não persistidos. Colheita manual e golem reutilizam a pendência; conclusão a limpa.
- Campos ausentes em arquivos antigos significam nenhuma recompensa pré-sorteada. Não há informação suficiente para recuperar sorteios de saves anteriores; a cultura permanece pronta e a próxima tentativa segue a regra existente. Fonte agrícola v4/v3 mantém sua prioridade atual.
- Validação: 34/34 testes. `HarvestPersistenceSmokeTest` cobre recusa, raridades, JSON/cena recriada, manual/golem, replay, v3 aditivo/v4 antigo e payload inválido sem mutação. Teste do vertical slice também cobre marco, HUD no retorno, depósito seletivo e replay do save. Validação manual do piloto/caldeirão continua pendente.

## Decisão 94 - Mochila expansível por marcos determinísticos, sem economia

- Autorização explícita para concluir a Fase E e escolha do autor: recompensas por restauração/exploração. O gate anterior de execução foi superado por essa autorização, sem registrar testes manuais pendentes como aprovados.
- Piloto: 12 slots iniciais, +4 por restaurar o primeiro Herbário e +4 pela primeira coleta bem-sucedida no Bosque. Até 20, em qualquer ordem, sem moedas, custo extra, NPC, lore ou RNG. Só ações concluídas concedem o marco; repetição não concede novamente.
- Mantidos stack 99, água fora dos slots, resultados do caldeirão/restauração na Mochila com recusa protegida e golems depositando fisicamente no Village Storage. Nenhum limite especial de categoria adicional nem posições de slots persistidas: não existe necessidade funcional atual.
- Barra paginada em grupos de até 12; todos os slots extras/legados continuam acessíveis. Painel de transferência mostra capacidade real e marcos, preservando estoque por tipo e seleção exclusiva com ferramentas.
- Save v4: campo opcional `inventory.backpack_milestones` guarda IDs conhecidos/únicos, validado antes de mutações. Load substitui, não acumula. Save completo antigo recupera somente o marco do Herbário explicitamente restaurado; o Bosque precisa da próxima coleta porque esse histórico não existia. Payload parcial sem campo preserva runtime. Excesso de itens nunca é truncado.
- Validação: 33/33 smoke tests; novo teste cobre marcos reais/recusas, limites e ordens, UI, transferências, JSON com reconstrução, compatibilidade, replay e payload inválido. Renderização OpenGL conferida. Conforto dos valores 12/16/20, teste manual integrado e persistência manual do caldeirão continuam pendentes. Implementação concluída não significa balanceamento final aprovado.

## Decisão 93 - Painel da Mochila representa pilhas, transferência continua por tipo

- Problema: o painel de transferência agrupava tipos e completava 20 células; a barra contava pilhas com limite 12. Quantidades acima de 99 comunicavam ocupações diferentes.
- Decisão: usar a mesma API de pilhas da barra para a Mochila, com 12 posições mínimas, quatro colunas e contador; água/zero ficam fora e excesso legado continua acessível na grade rolável. Baú mantém agrupamento por tipo e nenhum limite lógico novo.
- Transferência: clicar numa pilha abre o total disponível daquele tipo. `Mover tudo` continua movendo todas as unidades desse tipo, incluindo outras pilhas; texto/tooltip explicam o alcance. Quantidade seletiva e recusa atômica não mudam. Botões removidos pela atualização não podem abrir popup obsoleto.
- Validação: cinco testes relacionados passaram, com cobertura de 99/100, stack personalizado, cheia/excedente, depósitos e callbacks antigos. Teste visual manual deste ajuste e testes anteriores continuam pendentes. Não altera capacidade, destinos, save ou balanceamento.

## Decisão 92 - Piloto ativo preserva excesso legado e captura pendente

- Continuidade autorizada pelo autor em 2026-10-01: ativar 12 slots com stack padrão 99. Água, ferramentas e estados separados continuam fora da capacidade; nenhuma expansão, economia ou destino novo foi implementado.
- Compatibilidade: o load v3/v4 substitui quantidades integralmente mesmo acima de 12 slots. Não cortar itens, transferir automaticamente nem desativar o limite. Completar uma pilha ocupada é permitido; criar um slot excedente novo não é. O painel rolável do baú permite reduzir o excesso por depósito manual.
- Segurança da pesca: a defesa contra inventário cheio não podia desaparecer ao fechar o jogo nem ser sobrescrita pela próxima tentativa. `fishing_pending_capture` opcional no v4 guarda a recompensa exata existente, sem criar infraestrutura de fila. A UI propaga a recusa de abertura; o lago informa a pendência. Coleção avança somente após entrega integral.
- Load valida captura antes de alterar estoques e reinicia o lago sem emitir o fechamento que forçaria a Vara sobre uma semente restaurada. Save antigo completo sem campo limpa pendência do runtime; parcial sem estoque nem campo preserva o estado atual.
- Validação: teste dedicado cobre limite por padrão, estoques, overflow, JSON/recriação, tentativa bloqueada, retry único e carga inválida/legada/parcial. Publicar checkpoint não aprova o piloto manualmente; teste anterior de persistência do caldeirão também permanece pendente.

## Decisão 91 - Cada fechamento de etapa inclui atualização no GitHub

- Direção explícita do autor em 2026-10-01: ao finalizar uma etapa, criar commit e enviar ao GitHub, sem acumular o desenvolvimento somente na máquina local.
- Procedimento: validar proporcionalmente, registrar decisões/pendências, revisar e selecionar arquivos do incremento, verificar remoto/branch, fazer commit e push e confirmar sincronização. A autorização substitui instruções históricas de não fazer commit.
- Validação manual: implementação que passou em testes automáticos, mas ainda aguarda o autor, pode ser publicada como checkpoint com essa pendência explícita; isso não equivale a aprovação nem autoriza iniciar o próximo marco.
- Segurança: preservar mudanças remotas e locais; não usar push forçado, não incluir segredos/saves/builds/caches ou arquivos pessoais de agentes, nem incorporar arte não utilizada por conveniência.
- Recuperação inicial: integrar o histórico local acumulado e a apresentação do README que já existia no remoto. O checkpoint inclui Mochila/Village Storage e persistência do caldeirão; 31 smoke tests aprovados e teste manual da persistência pendente.

## Decisão 90 - Produção e reservas do caldeirão fazem parte do snapshot

- Problema: o save guardava os ingredientes já consumidos, mas não a mistura/lote nem o resultado pronto. Reabrir o jogo podia perder produção; carregar estoques antigos mantendo timers atuais podia duplicar resultados ou refunds.
- Decisão: acrescentar `cauldrons` opcional ao save v4, indexado pelo caminho relativo do caldeirão na cena. O próprio caldeirão serializa/valida/restaura estado, resultado capturado, quantidade, tempo restante e, para lotes, contadores, ingredientes, reservas por origem e flags de espera/cancelamento.
- Transação: o load valida o payload antes de alterar estoques e substitui o produtor sem reembolsar o runtime anterior nem reservar ingredientes novamente. Somente crafts ainda não entregues mantêm recibos. Um refund bloqueado preserva o lote em cancelamento pendente para nova tentativa, inclusive após save/load.
- Tempo: retomar usa o tempo restante salvo; esperar espaço ou cancelamento mantém timers parados. Não há avanço por tempo offline neste incremento. A reconciliação entre regiões já existente permanece funcional.
- Compatibilidade: saves completos antigos sem `cauldrons` carregam o produtor em `IDLE`, sem refund; produção que nunca foi registrada no save antigo não pode ser reconstruída. Payloads parciais sem estoques nem caldeirão preservam o runtime atual.
- Golems: o caminho abstrato legado continua sem spawn físico novo. Contagem e limite existentes passam a acompanhar o snapshot em `economy`, pois também são o destino de um resultado do caldeirão; carregar repetidamente não pode acumular esse resultado fora do save.
- Limite: os caminhos relativos dependem da estrutura atual da cena; renomear/mover o caldeirão exige revisão de compatibilidade. Payloads inválidos ou com identidade desconhecida são recusados antes da aplicação.
- Validação: `CauldronPersistenceSmokeTest` cobre JSON em memória, reconstrução da cena, timers reais, mistura/pronto/lote/espera/cancelamento, origens mistas, loads repetidos, resultado legado de golem, saves v3/v4 antigos e recusa sem mutação. Os 31 smoke tests passaram. Capacidade permanece desligada até aprovação manual e próximo incremento autorizado.

## Decisão 89 - Seleção por tipo de semente, não por pilha visual

- Problema: dividir um item em pilhas visuais exige preservar o modo de plantio quando uma pilha desaparece, sem destacar slots vazios nem selecionar itens já removidos. O load também podia restaurar uma semente sem limpar a ferramenta ativa.
- Decisão: qualquer pilha ocupada da mesma semente seleciona/desseleciona o mesmo tipo; todas as suas pilhas recebem destaque. Consumo e depósito parciais preservam seleção, e a última unidade removida a limpa. Slots vazios nunca recebem destaque e callbacks sem estoque são ignorados.
- Save: somente uma seleção de semente com quantidade positiva é restaurada; nesse caso, a ferramenta ativa é limpa. JSON continua persistindo quantidades agregadas no save v4, sem posições de slots.
- Validação: testes de interface cobrem cliques nas duas pilhas, consumo, depósitos e callback obsoleto; testes de JSON em memória cobrem Mochila vazia, parcial e cheia, seleção inválida e exclusividade com ferramenta.
- Escopo: nenhum limite, sistema econômico ou F10 foi ativado. Persistência do resultado pendente do caldeirão continua sendo o gate antes da capacidade real.

## Decisão 88 - Doze slots visuais antes da capacidade real

- Problema: ativar a recusa e redesenhar a barra ao mesmo tempo dificultaria separar regressões de gameplay de problemas puramente visuais.
- Decisão: renderizar primeiro 12 slots fixos, dividir quantidades pelo limite de stack e mostrar ocupação, mantendo `_personal_capacity_enforced` desligado.
- Motivo: validar leitura, espaço e seleção da Mochila antes de permitir que capacidade afete recompensas reais.
- Regra transitória: se um save ou ferramenta desativada produzir mais de 12 pilhas enquanto o limite está desligado, a barra exibe slots extras em vez de ocultar itens; o indicador recebe cor de atenção.
- Risco: o overflow pode ultrapassar a largura planejada, mas só existe como compatibilidade transitória. Ele deve desaparecer do gameplay normal quando a capacidade for ativada com segurança.

## Decisão 87 - Fechamento da migração distingue gameplay ativo de legado desativado

- Problema: as últimas chamadas compatíveis de inserção misturavam água regenerável, requests ocultos, loja desativada, comandos F10 e testes, sugerindo uma superfície de gameplay maior do que a real.
- Decisão: tratar água como recurso sem slot; proteger transacionalmente a recompensa do `QuestBoard` sem reativá-lo; fortalecer o rollback de recursos; manter loja e F10 ocultos/desativados e não migrar seus comandos como se fossem sistemas vigentes.
- Motivo: fechar a Fase C sem ampliar o escopo nem ressuscitar economia, comércio ou ferramentas de desenvolvimento removidas da experiência normal.
- Regra atual: todas as entradas ativas de gameplay usam a API estruturada. O wrapper `adicionar_item` permanece somente em ferramentas inativas e testes de compatibilidade até sua remoção futura.
- Risco: se loja, F10 ou requests forem reativados, seus contratos completos de UX, economia e capacidade precisam de revisão específica; a presença do código legado não equivale a autorização de uso.

## Decisão 86 - Resultados fixos da vila permanecem no produtor quando bloqueados

- Problema: caldeirão e restauração consumiam recursos antes de inserir recompensas na Mochila; ativar capacidade poderia apagar resultados ou concluir projetos sem recompensa.
- Decisão: manter a Mochila como destino atual, sem fallback automático para Village Storage. A restauração valida o destino antes do consumo; o caldeirão retém o resultado pronto e, no lote, pausa sem confirmar o craft até a inserção integral.
- Motivo: proteger recompensas sem antecipar a decisão futura sobre o destino definitivo de resultados produzidos dentro da vila.
- Regra atual: liberar espaço e interagir novamente entrega o resultado pronto do caldeirão; cancelar um lote pausado devolve as reservas ainda não confirmadas às origens registradas.
- Risco: o estado pronto do caldeirão ainda é operacional e não possui persistência própria. Isso não afeta o gameplay atual porque a capacidade permanece desligada; persistência ou outro destino deve ser decidido antes de ativar o limite em produção.


## Decisão 85 - Fundação compatível da Mochila antes do limite

- Problema: `GlobalInventory.adicionar_item` aceitava tudo e 29 entradas de itens presumiam sucesso. Ativar slots imediatamente poderia apagar recompensas ou consumir a origem antes de descobrir que o destino estava cheio.
- Decisão: preservar temporariamente o dicionário e o save v4, acrescentando uma API de ocupação, aceitação, inserção estruturada, remoção validada e substituição controlada. O piloto usa referência de 12 slots e stack padrão 99, mas a capacidade permanece desligada até as entradas ativas tratarem recusa e quantidade restante.
- Água continua fora dos slots. Ferramentas, moeda, receitas, coleção, lore e habilidades continuam em seus sistemas próprios.
- O wrapper legado `adicionar_item` permanece compatível durante a migração. Cada produtor será migrado antes de o limite ser ligado; a retirada do Village Storage será o primeiro fluxo atômico.
- Primeiro incremento da Fase C: retirada seletiva e retirada global legada consultam a aceitação antes de remover do Village Storage. Quantidades que não cabem são recusadas integralmente, a interface explica falta de espaço e uma defesa de rollback restaura a origem se a inserção mudar inesperadamente.
- Segundo incremento da Fase C: a colheita manual agrupa produto e drops em uma única inserção atômica. Sem espaço, o lote continua pronto e as recompensas sorteadas permanecem pendentes na sessão; liberar espaço permite recolher exatamente o mesmo lote. A capacidade ainda não está ativa no gameplay.
- Terceiro incremento da Fase C: o forrageamento externo só esgota o ponto após a recompensa inteira entrar na Mochila. Recusa por capacidade mantém o ponto disponível, não aceita quantidade parcial e não redireciona o recurso ao Village Storage.
- Quarto incremento da Fase C: a pesca valida os resultados possíveis antes da sincronia e entrega Peixe Comum mais o bônus da Maré Cintilante de forma atômica. A coleção só é atualizada depois da entrega; uma captura inesperadamente recusada permanece pendente na UI até existir espaço.
- Quinto incremento da Fase C: o Fragmento Celestial permanece no mundo quando a Mochila recusa sua recompensa. A tentativa renova a duração do marcador, permitindo liberar espaço; somente uma inserção completa remove o evento e emite sua coleta.
- Save: nenhuma mudança de versão nesta fundação. Posições físicas de slots e capacidade expansível só justificam novo schema quando houver requisito concreto.
- Validação: `PersonalInventoryContractSmokeTest` cobre stacks, ocupação, zero, água, entradas inválidas, compatibilidade ilimitada, aceitação parcial, recusa total e limpeza da última semente. `FarmHarvestCapacitySmokeTest` cobre recusa sem consumir o cultivo, recompensa pendente e nova tentativa após liberar espaço. Os 29 smoke tests ativos passaram.


## Decisão 84 - Direção futura de economia, inventário e aquisição

- Problema: os sistemas atuais usam `GlobalInventory` como inventário amplo, enquanto o Baú da Vila, a venda e as moedas ainda refletem soluções de protótipo. Sem uma direção registrada, futuras melhorias poderiam misturar mochila, logística da vila e progressão econômica ou transformar itens importantes em dependência exclusiva de RNG.
- Decisão: separar conceitualmente o **Inventário Pessoal/Mochila**, voltado a exploração e limitado por slots/stacks generosos, do **Village Storage**, armazenamento lógico compartilhado da vila. O `VillageChest` atual é a primeira representação física desse Village Storage; golems continuam buscando, carregando e depositando fisicamente nele.
- Consumo futuro: sistemas fixos na vila — caldeirão, purificação, construções, requests e comércio/envio — poderão consumir diretamente do Village Storage, sem exigir retirar e recolocar ingredientes. Pontos físicos múltiplos poderão acessar o mesmo armazenamento lógico, sem teleportar visualmente a logística dos golems.
- Exploração: recursos coletados fora da vila devem entrar primeiro na Mochila; o retorno e depósito na vila continuam sendo parte do loop. Moeda, ferramentas, receitas, itens narrativos e coleções podem ganhar representações próprias no futuro, mas não serão separados antes de existir necessidade concreta.
- Economia: haverá uma moeda universal, ainda sem nome/lore definitivo. A implementação e os textos atuais de `Moedas` são provisórios. Todo recurso comum deve possuir uma saída universal de baixo atrito para moeda, mas requests, receitas, restaurações, eventos, coleções e especializações podem oferecer usos mais valiosos.
- Aquisição e RNG: conteúdo não narrativo importante deve ter, quando apropriado, mais de um caminho de aquisição. RNG é permitido como descoberta, atalho ou alternativa, mas nunca como única rota severamente aleatória para progresso obrigatório. A futura Acquisition Matrix será apenas uma ferramenta de controle de conteúdo, não infraestrutura a ser criada agora.
- Conhecimento: especialização recompensa profundidade com informação, receitas, eficiência, qualidade ou possibilidades; ela não deve ser um requisito para a atividade base nem apenas multiplicador infinito de preço de venda. Diversidade recompensa flexibilidade.
- Escopo: não implementar agora capacidade, stacks, rede de baús, moeda final, envio, venda, matriz de aquisição ou novos caminhos de obtenção. Registrar primeiro e retomar somente em sprint autorizado.
- Estado de transição atual: o golem já deposita fisicamente no `VillageChest`, o que está alinhado. Caldeirão, purificação e restauração usam `VillageResourceAccess`: consomem primeiro do Village Storage e completam pela Mochila, com recibo transacional para rollback. O Baú e a Mochila continuam separados e a interface oferece transferência manual seletiva nos dois sentidos; não há mais retirada global visível. O save v4 preserva os dois estoques sem mesclar itens obtidos depois do snapshot. Isto não antecipa capacidade, stacks, rede de baús ou economia final.


## Decisão 83 - Coleção de pesca pequena, visível e opcional

- Problema: a pesca já entregava recompensas, mas não possuía um objetivo de longo prazo que valorizasse repetir e aperfeiçoar a atividade existente.
- Decisão: criar somente a Coleção do Lago, formada por `Peixe Comum` e `Escama Brilhante`; cada ID é contado uma vez e o progresso aparece dentro do popup da pesca.
- Bônus: ao completar os dois registros, `Memória das Marés` amplia em 8 pixels a tolerância de “boa sincronia”. A janela perfeita e a recompensa do lago especial não são alteradas.
- Filosofia: a coleção é casual para completar e oferece conforto de precisão a quem se especializa, sem se tornar requisito para uma pescaria funcional.
- Persistência: os dois campos novos pertencem ao bloco `inventory` do save v4. Ausência dos campos preserva o estado padrão, evitando migração e mantendo saves anteriores carregáveis.
- Validação: `FishingCollectionSmokeTest` valida unicidade, conclusão, efeito do bônus, round-trip de save e payload legado sem os campos.


## Decisão 82 - Vida mínima do Golem separada do trabalho

- Problema: o golem já executava a cadeia física de automação, mas quando não encontrava trabalho permanecia apenas em `IDLE`, sem demonstrar presença de criatura.
- Decisão: adicionar uma camada de vida independente (`LOOKING`, `GOING_TO_REST`, `RESTING`, `REACTING`) sem substituir os estados de navegação e trabalho existentes.
- Ritmo: após ciclos sem tarefa, o golem olha ao redor e periodicamente procura um ponto do grupo `golem_rest_point`; a posição inicial é o fallback seguro.
- Visual: o placeholder atual usa pequenas mudanças de rotação, escala e modulação, evitando exigir arte final ou um novo sistema de animação.
- Clima: como não há clima runtime na V0 atual, `reagir_a_chuva` fica como API explícita para integração futura e não interrompe tarefas em andamento.
- Compatibilidade: prioridade, pausa, colheita, rega, transporte, depósito e save permanecem inalterados; a prioridade ou uma nova tarefa cancela a vida ociosa pendente.
- Validação: `GolemLifeSmokeTest` cobre estados de vida, rótulos da interface, reação a chuva e bloqueio quando pausado.


## Decisão 81 - RecipeData governa a produção do caldeirão

- Problema: o Livro de Receitas exibia quantidade e tempo do `RecipeData`, mas o caldeirão ainda produzia uma unidade em tempo global e concedia `+1` fixo na descoberta.
- Decisão: o `RecipeResolver` entrega o contrato completo e resolve ingredientes; mistura e lote capturam quantidade, tempo e resultado desse contrato no início da operação.
- Descoberta: uma mistura bem-sucedida registra o ID canônico e concede `recompensa_pontos_alquimia` apenas na primeira vez. Receitas com `desbloqueada_por_padrao` entram no livro sem recompensa.
- Cancelamento: ingredientes continuam reservados no início do lote; resultados concluídos permanecem e somente os crafts não concluídos são reembolsados.
- Compatibilidade: `RecipeDatabase`/Resources têm prioridade, mas receitas ausentes ou inválidas ainda podem usar `Database.receitas_alquimia` com defaults explícitos. O schema de save não muda e IDs já descobertos são preservados.
- Golems: o caminho abstrato atual foi mantido por compatibilidade, mas quantidade produzida e limite de capacidade agora são coerentes com a receita. A criação de um golem físico permanece para o sprint próprio.
- Validação: `CauldronRecipeContractSmokeTest` cobre saída 2x, tempo de 2 segundos, recompensa única, ordem, defaults legados e refund parcial após um craft concluído.


## Decisão 80 - Piloto 6x2 de agricultura livre

- Problema: já existia uma criação dinâmica experimental, mas sem região de rollout própria, indicação visual, feedback consistente ou operação verificável de ponta a ponta.
- Decisão: oficializar somente o retângulo 6x2 entre `(4, 5)` e `(9, 6)` como piloto de criação livre; a enxada consulta `SoilValidityPolicy`, verifica identidade, cria um `FarmPlot` quando necessário e tenta ará-lo.
- UX: a área possui marcador runtime e recusas informam limite do piloto ou motivo de solo inválido. O marcador não tem collider nem autoridade sobre o estado agrícola.
- Autoridade: o lote criado entra no mesmo registro canônico, continua sendo a autoridade de gameplay e é espelhado no `FarmGridManager`; nenhuma rota paralela de cultivo foi criada.
- Compatibilidade: plots dinâmicos já existentes dentro do retângulo participam do piloto. Outros plots antigos continuam restauráveis e jogáveis mesmo fora dele.
- Validação: o teste dedicado cria e ara uma célula vazia, impede duplicação e criação fora do piloto, percorre plantar/regar/crescer/colher e confirma dois loads v4 sem trocar identidade.


## Decisão 79 - Política espacial única para arar

- Problema: a criação dinâmica experimental decidia com verificações dispersas (`não há collider` e `tile não bloqueado`), sem limite cultivável nem representação explícita de água, construção, obstáculo e reserva.
- Decisão: `SoilValidityPolicy` responde de forma determinística se uma coordenada pode ser arada e retorna o motivo; `Main` traduz o estado do mundo para esse contrato e tanto terreno vazio quanto `FarmPlot` consultam a mesma regra.
- Limite transitório: o retângulo configurável vai de `(-8, -5)` a `(15, 8)`. Áreas reservadas possuem configuração própria e o blockout visual continua sem autoridade de gameplay.
- Colisões: água, construções e obstáculos físicos permanentes bloqueiam novas células; `FarmPlot` registrados e personagens móveis não são tratados como obstáculos de solo.
- Compatibilidade: plots já registrados, inclusive dinâmicos vindos de saves anteriores e fora do limite atual, continuam jogáveis; corrupção/bloqueio ainda prevalece. O load continua autorizado a restaurá-los e o schema v4 não muda.
- Coerência: desbloquear uma expansão reconstrói imediatamente o snapshot, para que a política observe a purificação na mesma transição.
- Validação: o smoke test cobre fazenda indisponível, limite, corrupção e purificação, água, construção, obstáculo genérico, reserva, célula livre e plot legado fora do limite.


## Decisão 78 - Snapshot isolado no contrato FarmPlot/FarmGrid

- Problema: `Main.obter_farm_grid_manager()` expunha a instância interna mutável, permitindo que um consumidor de leitura alterasse o índice sem alterar o `FarmPlot` correspondente.
- Decisão: manter o manager real privado no `Main` e fazer tanto o novo `obter_farm_grid_snapshot()` quanto o alias legado retornarem cópias profundas; o save usa dados serializados próprios e não escreve diretamente no snapshot interno.
- Autoridade: mudanças runtime nascem no `FarmPlot` e são espelhadas por sinal; somente o bridge explícito do `SaveManager` pode converter dados persistidos e aplicá-los aos plots existentes.
- Escopo: `FarmTileData` continua contendo campos laboratoriais, mas eles não entram no gameplay e podem ser descartados quando um novo snapshot é derivado dos `FarmPlot`.
- Validação: o teste `FarmGridContractSmokeTest` altera e remove tiles de uma cópia, confirma que mundo e snapshots seguintes permanecem intactos, altera um `FarmPlot` e confirma o espelhamento, e exercita o bridge de load sem trocar identidade.


## Decisão 77 - Roteamento explícito do save agrícola por versão

- Problema: `SAVE_VERSION = 4` era gravado, mas o load não lia a versão e tratava `farm_grid` ausente e vazio como o mesmo caso, podendo aplicar silenciosamente o fallback errado.
- Decisão: considerar save sem versão como legado v3; usar `farm_plots` nas versões 1–3; na v4, usar `farm_grid` sempre que a chave existir, inclusive vazia, e recorrer a `farm_plots` apenas quando ela estiver ausente.
- Segurança: versões inválidas/futuras e o payload agrícola selecionado com tipo incorreto são recusados antes de qualquer mutação de estado.
- Compatibilidade: o schema v4 não mudou, `farm_plots` continua sendo gravado como fallback e saves v4 incompletos ainda podem recorrer ao legado quando `farm_grid` estiver ausente.
- Validação: um smoke test dedicado cobre versão explícita, save sem versão, conflito grid/legado, grid vazio versus ausente e formato malformado; os quatro backups v3 e o save v4 real também foram carregados somente em memória.


## Decisão 76 - Purificação é a autoridade do bloqueio da expansão

- Problema: durante reload na mesma sessão, o estado agrícola serializado do pocket 2x2 podia disputar com o estado do obstáculo e produzir uma sobreposição transitória de terra arada sob a área bloqueada.
- Decisão: aplicar purificação antes dos dados agrícolas e não restaurar `expansion_blocked` pelo snapshot do grid nem pelo fallback legado; depois do cultivo, sincronizar novamente a área como guarda final.
- Motivo: separar responsabilidades sem alterar schema: `farm_expansion` governa acesso, visibilidade e input; `farm_grid`/`farm_plots` restauram apenas o cultivo.
- Compatibilidade: saves v3 e v4 continuam aceitos, as identidades dos 34 plots são preservadas e o estado agrícola do 2x2 volta a aparecer quando a mesma área é carregada como purificada.
- Validação: o smoke test alterna o mesmo 2x2 arado entre saves purificado, bloqueado e purificado na mesma instância, verificando bloqueio, visibilidade, input e identidade.


## Decisão 75 - Identidade canônica de FarmPlot por coordenada

- Problema: os `FarmPlot` da expansão participavam do snapshot de `FarmGridManager`, mas não do registro consultado pelo load, permitindo que a mesma coordenada ganhasse uma segunda instância.
- Decisão: manter `FarmPlot` como autoridade do gameplay e usar `farm_plot_registry`, indexado diretamente por `Vector2i`, como lookup canônico de todos os plots, incluindo base, plots dinâmicos e pockets de expansão. O registro recusa colisões, reutiliza a instância existente e remove somente a instância correspondente quando ela sai da árvore.
- Motivo: estabilizar save/load, expansão e seleção de alvos sem migrar a autoridade para `FarmGridManager` nem alterar o schema do save.
- Compatibilidade: `farm_plots` continua como fallback legado e `farm_grid` mantém o formato v4 atual.
- Validação: a cena dev `FarmPlotIdentitySmokeTest.tscn` confirma as 34 identidades iniciais, reaplica saves v4 com expansão bloqueada e purificada, exercita o fallback v3 e valida criação, reutilização, desregistro e recriação de um plot dinâmico.
- Risco: a regra ainda depende do contrato de coordenadas atual; origem, tamanho de célula e coordenadas negativas continuam como decisões futuras.



## Decisão 57 - Layout Pass V1 visual e runtime-only

- Problema: a fazenda e os painéis principais estavam visualmente concentrados demais para a leitura atual do protótipo.

- Decisão: fazer o Layout Pass V1 como ajuste visual leve, mantendo os sistemas centrais intactos e sem criar novo gameplay.

- Motivo: melhorar leitura espacial, destacar melhor o núcleo inicial e reduzir a interferência do blockout e do painel de objetivos.

- Risco: por ser apenas visual, o layout pode precisar de refinamento adicional quando novas áreas forem adicionadas.



## Decisão 58 - Arraste de UI runtime-only sem persistência

- Problema: alguns painéis do jogo precisavam ser reposicionados pelo jogador durante a sessão sem introduzir complexidade de save.
- Decisão: implementar arraste de UI como comportamento runtime-only, com helper reutilizável e sem salvar a posição entre sessões.
- Motivo: permitir organização da tela de forma segura e pequena, sem mexer no `SaveManager` nesta etapa.
- Risco: ao recarregar o jogo, os painéis voltam às posições padrão e o jogador precisa ajustar novamente.

## Decisão 59 - Catálogo de transição documentado antes da migração definitiva

- Problema: o código ainda usa um catálogo legado/provisório enquanto os documentos novos já definem o catálogo definitivo do jogo.
- Decisão: documentar a transição de catálogo antes de migrar IDs e receitas, mantendo compatibilidade temporária e evitando troca prematura de schema.
- Motivo: reduzir drift entre `Database.gd`, `Data/recipes/*.tres`, Livro de Receitas, caldeirão e `receitas_descobertas` salvas.
- Risco: se a migração ocorrer sem alias/compatibilidade, o save e a UI podem divergir rapidamente.

## Decisão 61 - Primeira leva definitiva de receitas sem novos IDs de item

- Problema: a primeira migração do catálogo precisava começar pequena, mas sem criar um novo sistema ou mexer em save/schema.
- Decisão: promover apenas receitas resource-first que pudessem usar IDs já existentes no catálogo atual, adiando `Fritura de Riafin` até o peixe definitivo `Riafin` existir no catálogo de itens.
- Motivo: reduzir risco técnico e validar o fluxo resource-first com o menor número possível de mudanças adjacentes.
- Risco: a leva inicial fica pequena e algumas receitas previstas continuam no backlog até o catálogo de itens se alinhar.

## Decisão 62 - Área inicial cenográfica com caldeirão central e plantio livre

- Problema: a fazenda inicial estava ficando amontoada demais e ainda carregava a ideia de uma casa do jogador que não combina com a proposta idle.
- Decisão: tratar a área inicial como um núcleo cenográfico com o caldeirão no centro visual, praça aberta ao redor, ponto de chegada/abrigo da vila como marco de ambientação e sem zona rígida de plantio.
- Motivo: melhorar a leitura espacial sem criar novo gameplay, permitir que o chão continue plantável em qualquer ponto útil e reservar espaço para expansão adicional.
- Risco: como a decisão é cenográfica e de layout, ela pode pedir refinamento visual posterior sem afetar o loop principal.

## Decisão 60 - RecipeDatabase como fonte principal

- Problema: caldeirão e Livro de Receitas ainda dependiam de caminhos paralelos para resolver receitas, o que aumentava o risco de drift.
- Decisão: tratar `RecipeDatabase`/`Data/recipes` como a fonte principal para receitas, mantendo `Database.receitas_alquimia` apenas como fallback legado temporário durante a transição.
- Motivo: centralizar nomes, ingredientes, resultados e validade em um schema de recurso mais claro e reduzir divergências entre UI e produção.
- Risco: enquanto o fallback existir, qualquer receita nova precisa ser mantida em ambas as fontes ou migrada em lote com compatibilidade.

## Decisão 55 - Golem Irrigador como talento, não como novo golem

- Problema: o golem físico já existente precisava ganhar rega sem quebrar o coletor/depositador nem criar uma segunda entidade paralela.

- Decisão: implementar `skill_golem_irrigador` como talento separado na árvore, com um método público seguro em `FarmPlot` para irrigação e checagem direta no golem físico.

- Motivo: preservar o comportamento de colheita atual, manter o escopo pequeno e evitar inventário próprio, pathfinding novo ou múltiplos golems.

- Risco: como a decisão depende de leitura runtime de `skills_desbloqueadas`, qualquer efeito persistente adicional deve continuar sendo revalidado junto com o save.



## Decisão 56 - Prioridade do golem runtime-only na Interface V0

- Problema: a V0 precisava permitir controle simples do trabalho do golem sem mexer no save.

- Decisão: manter a prioridade de trabalho apenas em runtime, no próprio golem, exposta pela Interface do Golem V0, sem persistir essa escolha em `SaveManager`.

- Motivo: manter o escopo pequeno e validar a ergonomia do painel antes de decidir por persistência.

- Risco: ao reiniciar o jogo, a prioridade volta ao padrão e o jogador precisa reconfigurar.



## Decisão 48 - Feedback visual provisório na finalização da purificação

- Problema: a purificação concluída precisava de uma recompensa visual curta sem mexer na lógica central.

- Decisão: disparar um brilho/mensagem provisórios pela UI quando `finalize_purification()` concluir com sucesso.

- Motivo: reforçar a sensação de conclusão e de desbloqueio sem depender de assets finais ou de mudanças no save.

- Risco: o efeito é simples e pode ser substituído depois por uma animação mais elaborada.



## Decisão 47 - UX do Painel de Purificação separa entrega e finalização

- Problema: o botão `Entregar tudo disponível` podia passar a impressão de que a área seria purificada automaticamente.

- Decisão: reforçar o Painel de Purificação com mensagens de estado mais claras e um destaque visual simples no botão `Purificar Área` quando ele estiver habilitado.

- Motivo: deixar explícito que a entrega só preenche os requisitos e que a purificação continua sendo uma ação final separada.

- Risco: a UI ficou um pouco mais verbal, então pode precisar de ajuste fino de texto se o painel ganhar mais requisitos mais adiante.



## Decisão 49 - Expansão organizada por obstacle_id antes da V1

- Problema: o `Main.gd` ainda estava acoplado a uma única área/pocket, mesmo com o `SaveManager` já preparado para múltiplos obstáculos.

- Decisão: introduzir uma estrutura interna de áreas de expansão por `obstacle_id`, mantendo apenas a V0 cadastrada por enquanto.

- Motivo: preparar a chegada de uma segunda área sem alterar o comportamento visível da V0, sem mexer no schema do save e sem reorganizar os `FarmPlot` existentes.

- Risco: a ordem dos `FarmPlot` continua dependente da criação append-only; qualquer expansão seguinte precisa preservar isso.



## Decisão 50 - Layout macro antes do solo livre

- Problema: a fazenda já funciona, mas o núcleo inicial está concentrado demais e pode ficar amontoado se o mapa crescer sem direção.

- Decisão: não implementar solo livre na Fase 1; primeiro planejar o mapa macro e usar blockout visual como preparação, sem conectar `FarmGrid` ao gameplay.

- Motivo: preservar a Fase 1, evitar retrabalho de layout e dar espaço para zonas reservadas antes da migração sistêmica.

- Risco: o blockout visual precisa continuar sem entrar no grupo `lotes_terra` nem se transformar em uma rota paralela de jogo.



## Decisão 51 - Blockout visual V0 apenas como camada de apresentação

- Problema: a fazenda precisava ganhar leitura espacial sem criar áreas novas de gameplay.

- Decisão: implementar o Blockout Visual V0 como nós visuais runtime-only criados por `Main.gd`, sem `FarmPlot` novos, sem save e sem conexão com `FarmGridPreview`.

- Motivo: reduzir a sensação de núcleo amontoado e preparar a leitura de zonas reservadas sem tocar no loop validado.

- Risco: qualquer marker visual posterior precisa continuar fora de grupos de gameplay e fora do schema de save.



## Decisão 52 - Missão Inicial V0 separada do QuestManager

- Problema: o loop principal precisava de orientação sem transformar o onboarding em um sistema grande de quests.

- Decisão: criar a Missão Inicial V0 como checklist runtime-only dentro da UI, separada do `QuestManager` e sem persistência no save.

- Motivo: guiar o jogador pelo fluxo básico da Fase 1.5 com baixo risco e sem mexer no sistema de demandas genéricas.

- `Colher` permanece runtime-only por design: só conclui quando o mesmo lote foi observado como pronto após o bootstrap e depois ficou vazio; o rastreio é reiniciado em load para evitar falso positivo de inicialização/reload e também não conclui apenas porque o save abriu vazio.

- Risco: etapas dependentes de ações transitórias podem ser heurísticas e precisar de leitura de estado mínima, sem acoplamento maior.



## Decisão 54 - Slots e drag preview do caldeirão usam ícones textuais da base de dados

- Problema: não havia texturas reais de itens no diretório de assets, então o slot do caldeirão e o preview de drag ficavam sem representação visual confiável.

- Decisão: usar os ícones textuais/emoji já expostos por `Database.obter_icone_item()` e os nomes da base de dados para representar os itens no caldeirão e no arrasto.

- Motivo: garantir consistência visual sem criar pipeline nova de arte nem alterar o schema de dados.

- Risco: quando os ícones art finais chegarem, essa camada textual pode ser substituída por textura sem mudar a lógica.



## Decisão 53 - Risco aceitável de falso negativo pós-reload para objetivos runtime-only

- Problema: objetivos runtime-only não podem depender de histórico salvo sem reintroduzir persistência nova.

- Decisão: aceitar que o painel possa recalcular o estado de alguns passos a partir do estado atual após reload, priorizando ausência de falso positivo sobre cobertura perfeita do histórico.

- Motivo: manter a Missão Inicial V0 simples, sem schema novo e sem reescrever o `SaveManager`.

- Risco: a etapa `Colher` pode exigir observação na sessão atual após reload em vez de concluir imediatamente; esse trade-off é aceitável para V0.



## Decisão 1 - Golem automático desativado temporariamente

- Problema: `GolemManager.gd` colhia automaticamente e conflitada com o golem físico.

- Decisão: manter o código, mas desligar a automação com flag.

- Motivo: estabilizar o loop manual.

- Risco: a automação fica inativa até ser reativada.

- Como reativar: trocar `automation_enabled` para `true`.



## Decisão 2 - Não criar sistema de receitas escalável ainda

- Problema: haverá muitas receitas adicionais.

- Decisão: adiar a migração para dados externos até o loop mínimo estar validado.

- Motivo: evitar complexidade prematura.

- Próxima análise: comparar `Resource .tres`, JSON e CSV.



## Decisão 3 - Documentar antes de expandir

- Problema: o projeto já tem muitos sistemas iniciados.

- Decisão: criar documentação mínima antes de implementar novas mecânicas.

- Motivo: manter continuidade e reduzir risco de bagunça.



## Decisão 4 - Fallback de ícone no inventário

- Problema: os slots de inventário e do caldeirão apontavam para `res://Assets/Items/`, mas essa pasta não existe no estado atual do projeto.

- Decisão: aceitar também `res://Assets/` como caminho de fallback para ícones.

- Motivo: evitar falhas visuais e permitir que o protótipo continue funcionando mesmo com estrutura simples.

- Risco: quando os ícones finais forem organizados em outra pasta, vai ser preciso revisar esse fallback.



## Decisão 5 - Salvamento mínimo com SaveManager

- Problema: o protótipo precisava manter continuidade entre sessões sem virar um sistema grande.

- Decisão: criar um `SaveManager` como Autoload e salvar apenas o progresso principal em `user://savegame.json`.

- Motivo: permitir retomar testes do loop principal sem mexer em plantação, golems ou estrutura de dados.

- Dados salvos agora: inventário, receitas descobertas, pontos de alquimia, moedas, estação, ano, água e quests simples.

- Dados adiados: estado de lotes/plantações, golems e qualquer migração de dados para formatos externos.

- Risco: o save atual não preserva o campo inteiro nem a automação completa; isso vai ser tratado depois.



## Decisão 6 - Livro de receitas separado da produção em lote

- Problema: o jogador precisava consultar receitas descobertas sem misturar isso com automação ou produção em série.

- Decisão: criar uma primeira versão do Livro de Receitas apenas para consulta.

- Motivo: manter o fluxo atual simples e preparar a base para produção em lote seguinte.

- Limitação atual: o livro lê o formato existente de `Database.receitas_alquimia` com uma camada adaptadora simples.

- Próxima etapa: adicionar produção em lote, barra de progresso e cancelamento quando o loop de consulta estiver estável.



## Decisão 7 - Livro de receitas como entrada para produção em lote

- Problema: a consulta de receitas precisava virar ação prática sem criar uma segunda interface de produção.

- Decisão: manter o Livro de Receitas como tela principal de consulta e usar ele para disparar produção em lote no caldeirão.

- Motivo: preservar o fluxo mental do jogador e evitar duplicar controles.

- Risco: o livro continua dependendo do formato atual de `Database.receitas_alquimia` e da camada adaptadora simples.



## Decisão 8 - Cancelamento de lote devolve ingredientes restantes

- Problema: o jogador precisava interromper uma produção em andamento sem perder tudo.

- Decisão: permitir cancelamento por clique no caldeirão e devolver apenas os ingredientes que ainda não viraram resultado.

- Motivo: dar controle ao teste manual e reduzir frustração durante prototipagem.

- Risco: a lógica de cancelamento trata apenas o lote atual; estados mais complexos ficam para depois.



## Decisão 9 - Cancelamento visível do lote

- Problema: o cancelamento por clique no caldeirão não era óbvio o suficiente para teste manual.

- Decisão: adicionar um botão `Cancelar producao` dentro do painel de progresso do lote.

- Motivo: deixar a ação explícita e reduzir dependência de interação escondida.

- Risco: a interface continua provisoria e pode precisar de ajuste visual depois.



## Decisão 10 - UI provisoria do caldeirao

- Problema: a imagem antiga do popup apertava os novos campos e deixava a leitura ruim.

- Decisão: substituir a decoração visual por um placeholder temporario e reorganizar o popup com mais folga.

- Motivo: melhorar a usabilidade sem mexer na lógica do lote.

- Risco: a arte final ainda precisa ser desenhada depois.



## Decisão 11 - Fundo de rocha como NinePatchRect

- Problema: o fundo visual precisava preencher o popup com mais consistência e legibilidade.

- Decisão: usar um `NinePatchRect` com placeholder de rocha pixel art para o fundo do popup.

- Motivo: garantir preenchimento estável do painel sem afetar os controles acima.

- Risco: a arte final ainda vai ser substituída depois, mantendo a UI provisória por enquanto.



## Decisão 12 - Fonte pixel art provisoria

- Problema: a UI precisava de uma tipografia mais próxima de um cozy pixel art, sem copiar a identidade de outro jogo.

- Decisão: usar Pixelify Sans com um tema provisório compartilhado pelas principais interfaces.

- Motivo: melhorar a leitura e o clima visual sem alterar lógica.

- Fonte: `res://Assets/fonts/PixelifySans-Regular.ttf`.

- Licença: SIL Open Font License 1.1, registrada em `res://Assets/fonts/OFL.txt`.

- Risco: o tema ainda é provisório e pode receber ajustes de tamanho/espacamento depois.



## Decisão 13 - Receitas documentadas antes da migração

- Problema: o formato atual de receitas funciona, mas não escala bem para um catálogo maior.

- Decisão: documentar o esquema atual e a migração seguinte antes de alterar o código.

- Motivo: evitar mudanças prematuras enquanto o loop principal já está estável.

- Recomendação seguinte: migrar para `Resource .tres` como formato principal, mantendo JSON/CSV apenas como apoio se necessário.

- Risco: a documentação não resolve a limitação estrutural sozinha; ela só prepara a migração seguinte.



## Decisão 14 - Popup da UI precisa ficar visivel ao abrir

- Problema: o clique no caldeirao e a abertura do Livro chegavam aos handlers, mas a camada `PopupLayer` permanecia oculta.

- Decisão: reativar o `PopupLayer` ao abrir o popup do caldeirao e ao abrir o Livro de Receitas.

- Motivo: manter a estrutura atual de UI sem deixar a camada onde os painéis vivem invisivel.

- Risco: o `PopupLayer` continua sendo uma solução provisoria de camada compartilhada.



## Decisão 15 - RecipeData criado sem acoplar ao jogo

- Problema: o projeto precisava de uma base tipada para receitas sem quebrar o fluxo atual.

- Decisão: criar `RecipeData` e receitas `.tres` de teste como camada estrutural paralela.

- Motivo: preparar a migração seguinte enquanto o caldeirao continuava lendo `Database.receitas_alquimia`.

- Risco: dois formatos vivem ao mesmo tempo por enquanto, entao o acoplamento seguinte precisara ser feito com cuidado.



## Decisão 16 - RecipeDatabase apenas de leitura

- Problema: o projeto precisava validar `Resource` de receitas sem trocar a fonte principal ainda.

- Decisão: criar `RecipeDatabase.gd` somente para carregar, validar e comparar receitas.

- Motivo: permitir a migração seguinte de forma segura, sem acoplar o caldeirao nesta etapa.

- Risco: a manutenção temporaria de dois sistemas de receita continua exigindo disciplina na migracao.



## Decisão 17 - Livro de Receitas em paralelo com fallback

- Problema: o Livro de Receitas precisava mostrar dados ricos sem abandonar a fonte antiga.

- Decisão: usar `RecipeDatabase` apenas para leitura e exibição complementar no Livro, mantendo `Database.receitas_alquimia` como fallback obrigatório.

- Motivo: validar o novo formato sem mexer no caldeirao nem na producao em lote.

- Risco: o jogo continuou com dois caminhos de dados ativos até a migracao completa ser validada.



## Decisão 18 - Cobertura completa das receitas legadas

- Problema: ainda faltavam `.tres` para parte do catálogo legado.

- Decisão: criar `RecipeData` para todas as receitas que ainda só existiam em `Database.receitas_alquimia`.

- Motivo: permitir cobertura completa do `RecipeDatabase` sem mexer no fluxo funcional do jogo.

- Risco: a cobertura dos dados estava completa, mas a fonte funcional principal ainda era o sistema legado até a migração final.



## Decisão 19 - Baú da Vila V1 sem UI

- Problema: o golem precisava de um destino físico simples para depositar itens.

- Decisão: criar um Baú da Vila V1 apenas como nó físico com inventário interno e console debug.

- Motivo: validar o ciclo colheita -> transporte -> depósito antes de qualquer interface.

- Risco: o baú ainda não tem UI, salvamento nem interação avançada.



## Decisão 20 - Icones provisorios na barra de ferramentas

- Problema: a Barra de Ferramentas V0 precisava de leitura visual melhor sem alterar gameplay.

- Decisão: aplicar icones provisórios em Enxada, Semente, Regador e Colheita mantendo botões do tipo `Button`.

- Motivo: reforçar a identidade visual da toolbar sem trocar a selecao global nem a logica de ferramentas.

- Risco: os icones sao provisórios e podem ser substituidos depois quando a arte final estiver pronta.



## Decisão 21 - Limpeza de logs do lago

- Problema: os logs temporários de carregamento do Lago da Fazenda V0 já cumpriram seu papel de diagnóstico.

- Decisão: remover apenas esses logs de inicialização, mantendo por enquanto os logs curtos de interação da pesca.

- Motivo: reduzir ruído no console sem perder visibilidade durante os testes do fluxo de lançamento e puxada fake.

- Risco: o lago continua dependendo de logs de interação para depuração rápida até a pesca V0 ser mais madura.



## Decisão 22 - Colheita segura do golem

- Problema: a colheita automática antiga dependia de clique humano e era frágil para IA.

- Decisão: criar `harvest_by_golem()` no `FarmPlot` para colher 1 item básico sem usar `_on_plot_clicked()`.

- Motivo: separar a lógica do golem da lógica de interação manual.

- Risco: bônus extras, sementes bônus e variações sazonais ficam para depois.



## Decisão 23 - Golem físico V1 com depósito

- Problema: o golem físico existia só como placeholder visual.

- Decisão: ligar `Golem.gd` à cena e fazer o golem procurar lote maduro, colher e depositar no Baú da Vila.

- Motivo: validar o loop físico mínimo do coletor antes de upgrades e árvore de talentos.

- Risco: o `GolemManager` segue desligado e o sistema ainda não tem pathfinding nem UI do baú.



## Decisão 24 - UI simples do Baú da Vila

- Problema: os itens depositados pelo golem ficavam invisíveis para o jogador.

- Decisão: criar um painel simples para abrir o baú, listar o conteúdo e permitir `Retirar Tudo` para o inventário global.

- Motivo: manter o baú separado do inventário do jogador e tornar o fluxo claro antes do salvamento.

- Risco: retirada individual e persistência do baú ainda ficam para etapas seguintes.



## Decisão 25 - Botão temporário de smoke test no Debug Panel

- Problema: o `FarmGridManager` e o `FarmTileData` precisavam de uma forma rápida de validação manual sem tocar no gameplay.

- Decisão: adicionar um botão temporário `Testar FarmGrid` no Debug Panel para executar `FarmGridManagerSmokeTest.run()`.

- Motivo: permitir checagem em memória da fundação do grid sem acoplar a cena ou os lotes atuais.

- Risco: a ferramenta é só de desenvolvimento e precisa ser removida ou reorganizada quando o grid entrar de verdade no jogo.



## Decisão 26 - Preview visual isolado do FarmGrid

- Problema: a fundação do grid precisava de uma visualização manual simples sem tocar no `FarmPlot` ativo.

- Decisão: criar `Scenes/dev/FarmGridPreview.tscn` como cena isolada de preview visual para o grid seguinte.

- Motivo: permitir experimentar desenho e interação de tiles sem conectar ao gameplay principal.

- Risco: a cena é só de teste e não deve virar uma rota paralela de jogo.



## Decisão 27 - Preview mostra Solo Vivo Alquimico

- Problema: o preview precisava validar nao só o estado do tile, mas tambem o tipo de solo do Farm System V2.

- Decisão: representar `soil_type` com bordas coloridas e alternancia por clique direito na cena isolada.

- Motivo: facilitar leitura visual do Solo Vivo Alquimico sem assets adicionais.

- Risco: a visualização continua provisória e precisa ser substituída quando a arte final chegar.



## Decisão 28 - Preview testa Enxada e decay diario

- Problema: o preview precisava validar a seguinte regra de arar com ferramenta ativa e o retorno de terra arada sem crop na virada do dia.

- Decisão: usar `Enxada` como ferramenta ativa padrão e simular o `Decay Diario` apenas em memória no preview.

- Motivo: experimentar o comportamento sem criar tempo real nem alterar o `FarmPlot` ativo.

- Risco: a regra ainda é conceitual e pode mudar quando o loop de fazenda em grid existir de verdade.



## Decisão 29 - Preview testa Semente fake

- Problema: o preview precisava validar a regra de que tiles plantados com semente não voltam para grama no decay diário.

- Decisão: adicionar uma ferramenta fake `Semente` que planta um crop de debug em memória (`debug_crop`).

- Motivo: permitir testar plantio e proteção contra decay sem inventário real, sem Database e sem gameplay principal.

- Risco: o crop fake existe só para validação e precisa ser substituído por dados reais quando a fazenda em grid entrar de verdade.



## Decisão 30 - Preview testa Regador fake

- Problema: o preview precisava validar o próximo passo do loop de fazenda em grid, molhando terra arada e plantios de debug.

- Decisão: adicionar uma ferramenta fake `Regador`, selecionada por tecla `3`, que molha tiles `ARADO` e `PLANTADO` em memória.

- Motivo: testar água, umidade e estado molhado sem criar inventário, `PocoManager` ou gameplay principal.

- Risco: a lógica de água continua provisória e pode ser ajustada quando o grid estiver realmente integrado.



## Decisão 31 - Preview testa crescimento fake

- Problema: o preview precisava validar a leitura de crescimento do crop sem criar tempo real, sistema de fases ou gameplay principal.

- Decisão: adicionar a tecla `G` para avançar `remaining_growth_time` apenas em tiles plantados e irrigados, usando marcadores visuais maiores conforme o crop se aproxima da maturidade.

- Motivo: observar a curva de crescimento em memoria com uma regra simples e sem punir o jogador no prototipo.

- Risco: o escalonamento visual e a quantidade de estagios podem mudar quando a fazenda em grid entrar de verdade.



## Decisão 32 - Preview testa colheita fake

- Problema: o preview precisava fechar o loop minimo da fazenda em grid com uma etapa de colheita sem inventario real.

- Decisão: adicionar a tecla `4` para selecionar `Colheita` e colher apenas crops maduras, limpando o tile e devolvendo-o para `ARADO`.

- Motivo: validar a transicao crescimento -> colheita -> preparo para novo plantio sem acoplar o sistema real de itens.

- Risco: a regra de retorno para `ARADO` pode ser ajustada quando o loop de solo e plantio entrar no jogo principal.



## Decisão 33 - Checkpoint do FarmGrid

- Problema: o FarmGrid V2 precisava de um registro oficial do que ja foi validado e do que ainda e fake antes de qualquer integracao.

- Decisão: criar um checkpoint de arquitetura documentando o preview, o loop minimo validado, os riscos e a pendencia de logs globais em cenas dev.

- Motivo: manter o FarmGrid isolado enquanto o `FarmPlot` segue como sistema ativo e confiavel do prototipo.

- Risco: o checkpoint nao resolve os logs globais; ele apenas registra a pendencia para investigacao seguinte.



## Decisão 34 - Presenca fisica do golem

- Problema: o golem parecia sem volume e passava visualmente por baixo de elementos do mundo.

- Decisão: ajustar a ordenacao visual com z_index por Y, mover a interacao para um ponto lateral/abaixo do lote e adicionar um sensor simples de proximidade.

- Motivo: melhorar a leitura espacial sem implementar pathfinding.

- Risco: o movimento continua em linha reta e pode atravessar obstaculos; isso fica para uma etapa seguinte.



## Decisão 35 - Recompensas compartilhadas da colheita

- Problema: a colheita manual já tinha bônus e drops raros, mas o golem ainda colhia só um item básico.

- Decisão: centralizar a geração das recompensas em `FarmPlot` para que a colheita manual e a do golem usem o mesmo conjunto de bônus.

- Motivo: manter paridade de jogo entre o que o jogador colhe na mão e o que o golem entrega ao Baú da Vila.

- Risco: o golem agora pode depositar mais de um tipo de item por viagem, então o balanceamento seguinte precisa considerar esse volume extra.



## Decisão 36 - Navegacao simples do golem

- Problema: o golem ainda atravessava visualmente o caldeirão e não contornava obstáculos.

- Decisão: substituir o Tween direto por navegação simples com `NavigationAgent2D` e rota por waypoints quando a linha cruza o caldeirão.

- Motivo: dar um comportamento físico mais crível sem introduzir um sistema pesado de pathfinding agora.

- Risco: a solução ainda é híbrida e simples; obstáculos mais complexos continuarão exigindo refinamento depois.



## Decisão 37 - Expansão V0 por pocket fixo

- Problema: a primeira expansão purificada precisava nascer compatível com o save por índice e sem acoplar o FarmGrid ao jogo principal.

- Decisão: manter o pocket V0 como 2x2 de `FarmPlot` pré-instanciados, criados depois dos lotes já existentes e liberados apenas pelo estado do obstáculo.

- Motivo: preservar a ordem dos lotes, reduzir risco de save e manter `FarmGridPreview` isolado.

- Risco: qualquer nova expansão precisa continuar append-only para não quebrar saves antigos.



## Decisão 37 - Caldeirão como obstáculo físico

- Problema: o caldeirão precisava bloquear o caminho do golem no mundo.

- Decisão: adicionar um obstáculo físico simples ao caldeirão e uma região de navegação básica na área jogável inicial.

- Motivo: tornar a navegação do protótipo previsível sem mexer na UI do caldeirão.

- Risco: o obstáculo é provisório e a área navegável ainda é ampla demais para um mapa com mais complexidade.



## Decisão 38 - Golem com corpo físico

- Problema: a navegação por `Node2D` ainda permitia leitura estranha e não respeitava colisão de forma confiável.

- Decisão: usar `CharacterBody2D` no golem físico, mantendo `NavigationAgent2D` como guia de rota.

- Motivo: impedir que o golem atravesse o caldeirão sem abrir escopo para pathfinding completo agora.

- Risco: a navegação continua provisória e pode precisar de refinamento quando a fazenda crescer.



## Decisão 39 - Desvio simples ao travar

- Problema: mesmo com colisão física, o golem podia encostar no caldeirão e ficar preso sem reação útil.

- Decisão: detectar travamento e calcular um waypoint de desvio simples ao redor do caldeirão antes de seguir o destino original.

- Motivo: destravar o coletor sem restaurar a rota manual em L nem implementar pathfinding completo ainda.

- Risco: o desvio é heurístico e pode precisar ser revisto quando a fazenda e os obstáculos crescerem.



## Decisão 40 - Terra arada em camada baixa

- Problema: o golem ainda podia parecer escondido pela terra arada e pela base visual dos lotes.

- Decisão: manter a terra/base do lote em camada baixa e dar ao golem um offset visual levemente acima do campo.

- Motivo: preservar a leitura espacial do protótipo sem mexer em coleta, depósito ou navegação.

- Risco: o sistema de camadas ainda é provisório e pode receber refinamento quando a cena crescer.



## Decisão 41 - Terra fora da herança do lote

- Problema: lotes mais abaixo na tela ainda podiam cobrir parcialmente o golem por herança de z do `FarmPlot`.

- Decisão: desligar a herança de z dos visuais de solo do lote e manter planta, VFX e tooltip com camadas próprias.

- Motivo: impedir que o chão de lotes inferiores cubra o golem sem mexer no fluxo do jogo.

- Risco: isso resolve a leitura atual, mas o sistema de camadas ainda continua provisório.



## Decisão 42 - Save mínimo do Baú da Vila

- Problema: o conteúdo do Baú da Vila podia ser perdido ao fechar o jogo antes da retirada.

- Decisão: salvar e restaurar o `inventory` do baú em `village_chest_inventory` dentro do `SaveManager`.

- Motivo: manter o ciclo do golem e do baú persistente sem mexer ainda nos lotes, crops ou no salvamento completo do mundo.

- Risco: o save continua mínimo e ainda não persiste o estado dos lotes/plantações.



## Decisão 43 - Farm Expansion System e purificação da fazenda

- Problema: a fazenda final precisava de um rumo estrutural maior do que apenas crescer sem fim ou virar um grid procedural cedo demais.

- Decisão: definir a fazenda final como um mapa fixo, artesanal e dividido em áreas desbloqueáveis por purificação alquimica.

- Motivo: manter o projeto com identidade forte, avanço narrativo claro e expansão controlada por sistemas já existentes.

- Risco: a expansão agora depende de alinhamento entre caldeirao, itens, pesca e progressao narrativa; a implementacao completa fica para depois.



## Decisão 44 - Obstáculo Mágico V0 com save mínimo

- Problema: a primeira purificação precisava existir como teste pequeno, persistente e sem acoplar o FarmGrid.

- Decisão: criar um obstáculo estático único no mapa principal, usando uma lista provisória de requisitos (`pocao_purificadora_fraca`, `escama_brilhante`, `trigo`) e salvando seu estado em `farm_expansion.purification_obstacles`.

- Motivo: validar o ciclo pesca -> agricultura -> purificação -> persistência antes de abrir áreas maiores.

- Risco: os requisitos ainda são provisórios/debug e a implementação seguinte do caldeirão ainda precisará substituir o método de obtenção dos itens.



## Decisão 45 - Poção Purificadora Fraca V0 no caldeirão

- Problema: a poção provisória precisava sair do botão de debug e entrar no fluxo real do jogo sem mudar a purificação por áreas.

- Decisão: ligar `agua` + `peixe_comum` no caldeirão para produzir `pocao_purificadora_fraca`, e incluir `peixe_comum` em `RECEITA_ITEM_IDS` para o livro e o modo lote reconstruírem a receita.

- Motivo: conectar pesca à alquimia de forma simples e validar o catalisador de purificação com um caminho jogável.

- Risco: a rota V0 ainda é temporária e não substitui o sistema completo de receitas/purificação por áreas que virá depois.



## Decisão 46 - Painel de Requisitos de Purificação V0

- Problema: purificar direto no clique tornava o fluxo abrupto e impedia progresso parcial persistente por obstáculo.

- Decisão: fazer o clique na Área Bloqueada V0 abrir um `PurificationPanel`, permitir entrega parcial dos requisitos e salvar o progresso em `farm_expansion.purification_progress`, mantendo `pocao_purificadora_fraca` como catalisador provisório.

- Motivo: validar a progressão pesca -> caldeirão -> purificação com um loop mais legível, sem criar nova área, novo obstáculo ou mexer no `FarmGridPreview`.

- Risco: o sistema ainda é V0 e depende de uma única área bloqueada; seguintes áreas precisarão repetir o mesmo contrato de save e UI.



## Decisão 43 - Debug Panel V1 temporario

- Problema: os testes do protótipo estavam lentos para itens, receitas, lotes, save e Baú da Vila.

- Decisão: criar um painel de debug oculto na UI principal, aberto por `F10`, com ferramentas temporárias de teste.

- Motivo: acelerar a validação do protótipo sem transformar essas ações em mecânicas reais.

- Risco: o painel precisa continuar claramente temporário para não poluir o fluxo normal do jogo.



## Decisão 33 - Debug Panel nao bloqueia input fechado

- Problema: o painel de debug podia interferir com cliques do mundo quando estava escondido.

- Decisão: manter o `DebugPanel` em `mouse_filter = Ignore` enquanto fechado e só passar para `Stop` quando aberto.

- Motivo: preservar o atalho de debug sem quebrar o clique no caldeirao, no Livro de Receitas ou em outras interacoes normais.

- Risco: a regra de input precisa continuar simples para nao reintroduzir bloqueio quando o painel crescer.



## Decisão 34 - Paineis fechados ignoram mouse

- Problema: painéis modais e temporários da UI podiam continuar no caminho do clique do mundo.

- Decisão: padronizar `mouse_filter = Ignore` quando estão fechados e `Stop` apenas enquanto visíveis.

- Motivo: deixar o caldeirao e o Livro de Receitas clicáveis sem precisar desmontar a UI de protótipo.

- Risco: qualquer novo painel temporário precisa seguir a mesma regra para não voltar a bloquear interação.



## Decisão 35 - Save minimo dos lotes por ordem do grupo

- Problema: os lotes de plantacao podiam perder estado ao fechar o jogo.

- Decisão: salvar cada lote em um array ordenado pela ordem atual do grupo `lotes_terra` e restaurar por índice.

- Motivo: manter a solução simples e estável para o protótipo, sem criar ids novos agora.

- Risco: a estabilidade depende da ordem de instância dos lotes continuar previsível no protótipo.



## Decisão 36 - Status do jogo V1 informativo

- Problema: o protótipo precisava mostrar mais contexto geral durante os testes.

- Decisão: expandir o `StatusPanel` existente para exibir moedas, estação, ano, água, alquimia, golems e estado do Baú da Vila.

- Motivo: dar leitura rápida do estado atual sem criar uma UI nova ou interferir no fluxo do jogo.

- Risco: o painel continua provisório e pode ser refinado ou substituido quando a interface final for desenhada.



## Decisão 37 - Tempo real seguinte com modo debug

- Problema: o jogo final precisa de um modelo de tempo coerente com sessões reais, mas o protótipo ainda depende de testes rápidos.

- Decisão: documentar tempo real como direção final, porém manter o desenvolvimento em modo debug/controlável por enquanto.

- Motivo: permitir um `TimeManager` seguinte sem travar o fluxo de testes do protótipo.

- Risco: o sistema de tempo real pode afetar crops, estações, quests, economia e salvamento se for ativado cedo demais.



## Decisão 38 - TimeManager base sem Autoload

- Problema: o projeto precisava de uma fundação técnica para o tempo seguinte sem acoplar gameplay cedo demais.

- Decisão: criar `Scripts/TimeManager.gd` como script solto, com modo real desligado por padrão e funções de debug internas.

- Motivo: permitir evolução segura da arquitetura de tempo antes de conectar `SeasonManager`, `SaveManager`, plantações e UI.

- Risco: enquanto o `TimeManager` não for integrado, ele serve só como base estrutural e ainda não altera o jogo.



## Decisão 39 - Farm System V2 como evolução documentada

- Problema: o sistema atual de lotes é funcional, mas limitado para a visão final de fazenda viva e alquímica.

- Decisão: documentar o Farm System V2 como evolução seguinte baseada em tiles/grid, sem substituir `FarmPlot` agora.

- Motivo: preservar o protótipo estável enquanto se prepara a transição para Solo Vivo Alquímico, caldeirão expandido e integrações com pesca, fazendinhas e golems.

- Risco: a migração seguinte vai exigir preparo cuidadoso para não quebrar save, UI e fluxos já validados.



## Decisão 40 - FarmTileData como Resource isolado

- Problema: a seguinte fazenda em grid precisa de uma base de dados serializável sem mexer no sistema atual.

- Decisão: criar `Scripts/data/FarmTileData.gd` como `Resource` isolado, sem conectar ao gameplay ainda.

- Motivo: preparar a seguinte serialização do grid e manter o `FarmPlot` como sistema ativo enquanto isso.

- Risco: enquanto o grid não existir, o recurso serve apenas como fundação técnica e documentação executável.



## Decisão 41 - FarmGridManager base sem cena

- Problema: o grid seguinte precisava de um coordenador de dados sem virar parte da cena ou do gameplay cedo demais.

- Decisão: criar `Scripts/data/FarmGridManager.gd` como `RefCounted`, isolado e sem `Autoload`.

- Motivo: permitir montagem, leitura e serialização de grids a partir de `FarmTileData` sem substituir `FarmPlot`.

- Risco: o gerenciador ainda não participa do jogo real e pode precisar de ajustes quando o grid começar a ser usado de verdade.



## Decisão 42 - Smoke test manual do grid

- Problema: a base do grid precisava de uma validação rápida sem acoplar à cena do jogo.

- Decisão: criar `Scripts/dev/FarmGridManagerSmokeTest.gd` como teste manual em memória.

- Motivo: facilitar checagem de criação, alteração e serialização do grid sem mexer no gameplay.

- Risco: o teste depende de execução manual e não substitui testes automatizados seguintes.



## Decisão 43 - PocoManager ignora cenas dev

- Problema: cenas de desenvolvimento, como `FarmGridPreview`, estavam recebendo agua automaticamente pelo `PocoManager` global.

- Decisão: adicionar uma guarda para que o `PocoManager` nao processe geracao automatica de agua quando a cena atual estiver em `res://Scenes/dev/`.

- Motivo: limpar o ruido dos testes isolados sem remover o Autoload nem alterar o comportamento do jogo principal.

- Risco: a filtragem depende do caminho da cena e precisa continuar alinhada com a organizacao das cenas dev.



## Decisão 44 - Ferramenta Ativa V0 no jogo principal

- Problema: o jogo principal ainda nao tinha um estado global simples para a ferramenta ativa, embora o preview ja tivesse validado o conceito em laboratorio.

- Decisão: criar `Scripts/ToolManager.gd` como `Autoload`, com a `Enxada` como primeira ferramenta real apenas para selecao visual/global.

- Motivo: preparar a seguinte ponte entre UI, atalhos e sistemas de fazenda sem alterar o `FarmPlot` agora.

- Risco: se essa base for ligada cedo demais ao clique no mundo, pode quebrar o prototipo atual ou confundir a selecao de ferramenta com gameplay real.



## Decisão 45 - Limpeza tecnica de logs

- Problema: a selecao de ferramenta repetia log quando a mesma opcao era acionada de novo, e o caldeirao ainda tinha um print temporario de debug.

- Decisão: impedir log repetido no `ToolManager` quando a ferramenta ja estiver selecionada e remover o `DEBUG Cauldron: clique recebido`.

- Motivo: reduzir ruído de console sem mudar o comportamento do jogo principal.

- Risco: a limpeza so trata ruído de log; outras mensagens de debug podem continuar existindo por design em outras partes do projeto.



## Decisão 46 - Ferramentas visuais globais expandidas

- Problema: a base de ferramenta ativa precisava deixar de ser apenas `Enxada` e passar a espelhar o conjunto visual validado no preview.

- Decisão: expandir `ToolManager` e a UI principal para `Enxada`, `Semente`, `Regador` e `Colheita`, mantendo tudo sem ação real por enquanto.

- Motivo: preparar a navegação global de ferramentas sem tocar no `FarmPlot` nem no `FarmGrid`.

- Risco: a seleção global ainda não executa ação, então a UI pode sugerir mais capacidade do que o gameplay realmente oferece.



## Decisão 47 - Limpeza tecnica da UI

- Problema: a UI principal ainda exibia um print temporario ao abrir o Livro de Receitas, poluindo o console sem trazer valor de depuracao.

- Decisão: remover apenas `DEBUG UI: botão livro de receitas clicado`, mantendo warnings uteis e o comportamento normal da interface.

- Motivo: reduzir ruído de console sem mexer em fluxo de abertura, receitas ou gameplay.

- Risco: outros prints temporarios podem ainda existir em partes antigas do projeto e precisarem de limpeza separada.



## Decisão 48 - Toolbar principal sem Semente

- Problema: a toolbar principal misturava uma ferramenta de teste com as ferramentas reais do jogo.

- Decisão: manter `Semente` apenas no `FarmGridPreview` e deixar a toolbar principal com Enxada, Regador e Colheita.

- Motivo: alinhar a UI principal ao design atual sem perder a semente fake do laboratório isolado.

- Risco: a separação exige cuidado para não reaparecerem atalhos ou botões de Semente fora do preview.



## Decisão 49 - Agua fora da lista visual do inventario

- Problema: a agua era exibida como item comum na barra visual de inventário, embora já tivesse leitura dedicada no StatusPanel.

- Decisão: manter `GlobalInventory.inventario["agua"]` como fonte real, mas ocultar `agua` da lista visual de itens comuns.

- Motivo: deixar o contador de agua no StatusPanel como referência principal, sem mexer em save, FarmPlot ou PocoManager.

- Risco: qualquer nova UI que liste o inventário precisa lembrar desse filtro para não mostrar a água de novo.



## Decisão 50 - Prioridade da ferramenta ativa no lote

- Problema: com uma semente selecionada no inventário, o clique no lote podia plantar mesmo quando uma ferramenta ativa já havia sido escolhida.

- Decisão: dar prioridade à ferramenta ativa do `ToolManager` sobre a semente selecionada no lote.

- Motivo: evitar plantio acidental quando o jogador quer regar, usar enxada ou preparar a colheita.

- Risco: como Enxada e Colheita ainda não executam ação real no `FarmPlot`, a interação vira bloqueio intencional até o comportamento dessas ferramentas existir de fato.



## Decisão 51 - Separação entre ferramentas, sementes e água

- Problema: ferramentas, sementes e água estavam misturadas demais entre UI, inventário e interação de lote, deixando a leitura do jogo menos clara.

- Decisão: tratar ferramentas como modo de ação global via `ToolManager`, sementes como itens do inventário no jogo principal e água como recurso visual no `StatusPanel` com armazenamento interno em `GlobalInventory.inventario["agua"]`.

- Motivo: manter o protótipo legível sem quebrar o fluxo atual de plantio, rega, save e o laboratório isolado do FarmGrid.

- Risco: qualquer nova UI ou sistema de interação precisa respeitar essa separação para não reintroduzir a mistura entre item, recurso e ferramenta.



## Decisão 52 - Enxada V0 no FarmPlot atual

- Problema: o jogo principal ainda precisava de uma primeira ação real da Enxada sem abrir aragem livre nem migrar para o FarmGrid.

- Decisão: adicionar um flag simples de preparo no `FarmPlot`, permitir arar lote vazio com Enxada e exigir lote arado para plantio seguinte, preservando o estado no save.

- Motivo: introduzir a Enxada como ação real de forma controlada, mantendo `FarmPlot` ativo e o `FarmGrid` isolado.

- Risco: a regra de plantio passa a depender do preparo do lote, então qualquer seguinte mudança no fluxo de sementes precisa respeitar esse estado.



## Decisão 53 - Area Preparavel V0 com lotes potenciais

- Problema: o jogador precisava sentir que novos campos podem ser criados sem instanciar lotes por clique nem migrar para o FarmGrid.

- Decisão: manter os 16 `FarmPlot` originais na mesma ordem e adicionar lotes potenciais extras no final da sequencia, todos iniciando com `arado = false`.

- Motivo: ampliar a area jogavel de forma segura, preservando saves antigos por ordem e evitando criar uma rota livre de instanciacao.

- Risco: a area continua baseada em `FarmPlot` fixo e visual provisório, então seguintes mudanças na grade precisam preservar a ordem append-only.



## Decisão 54 - Visual da Area Preparavel

- Problema: lote nao arado ainda parecia campo pronto demais, o que atrapalhava a leitura da Area Preparavel V0.

- Decisão: usar uma aparencia provisoria mais natural/esverdeada quando o lote estiver vazio e nao arado, mantendo terra arada seca e molhada com as texturas adubadas ja existentes.

- Motivo: deixar claro o estado do solo sem criar asset novo nem mexer em save, golem ou FarmGrid.

- Risco: o visual natural ainda é provisório e pode precisar ser refinado quando a arte final da fazenda for definida.



## Decisão 55 - Decay Diario V0 manual

- Problema: o prototipo precisava validar a limpeza de lotes arados vazios sem conectar tempo real ou migrar para o FarmGrid.

- Decisão: criar um botão manual no Debug Panel que aplica decay apenas em `FarmPlot` vazios e arados, preservando lotes plantados e prontos para colher.

- Motivo: testar a regra de volta ao estado natural de forma controlada, sem mexer no `TimeManager`, no `SaveManager` ou no comportamento automático do jogo principal.

- Risco: como ainda é manual/debug, a seguinte transição para tempo real vai precisar reaproveitar a mesma regra sem duplicar lógica.



## Decisão 56 - Colheita V0 por ferramenta

- Problema: a ferramenta `Colheita` existia na toolbar, mas ainda não acionava a colheita manual do `FarmPlot`.

- Decisão: fazer a ferramenta `Colheita` reutilizar a mesma lógica manual de recompensa quando o lote estiver pronto, sem duplicar geração de drops e sem alterar o golem.

- Motivo: deixar a ferramenta ativa coerente com o fluxo já existente, reaproveitando o caminho manual que já calcula recompensas, bônus e reset do lote.

- Risco: como a Colheita ainda não cobre ações adicionais fora do estado pronto, qualquer expansão seguinte precisa manter o mesmo helper compartilhado.



## Decisão 57 - Checkpoint do loop de ferramentas

- Problema: o loop atual de ferramentas, água e sementes já estava funcional no protótipo, mas sem um checkpoint curto reunindo as regras centrais.

- Decisão: registrar o Loop de Ferramentas V0 como estado atual oficial do jogo principal, com ferramentas globais, sementes como item, água no StatusPanel e Decay Diário ainda manual/debug.

- Motivo: deixar claro o contrato arquitetural antes de novas expansões, evitando misturar ferramenta, item e recurso de novo.

- Risco: seguintes mudanças em UI, plantio ou tempo real precisam respeitar esse checkpoint para não reabrir o acoplamento entre sistemas.



## Decisão 58 - Feedback visual das ferramentas

- Problema: o loop já funcionava, mas parte das respostas das ferramentas e avisos do `FarmPlot` ficava restrita ao console.

- Decisão: reaproveitar o texto flutuante existente da UI para mostrar feedback visual de Enxada, Regador, Colheita e avisos principais do lote.

- Motivo: melhorar a leitura do jogo sem criar popup novo e sem alterar regras de plantio, rega, colheita ou save.

- Risco: o feedback visual precisa continuar leve e consistente para não virar ruído ou sobreposição excessiva de mensagens.



## Decisão 59 - Filtragem de logs de agua

- Problema: os logs de `GlobalInventory` para `agua` geravam ruído constante no console, mesmo com a agua já aparecendo de forma dedicada no StatusPanel.

- Decisão: filtrar logs de adição e remoção quando `item_id == "agua"`, mantendo os demais logs de inventário.

- Motivo: reduzir ruído sem esconder o comportamento real do inventário para outros itens.

- Risco: como o inventário ainda é útil para depuração, qualquer novo caso especial precisa ser revisado para não esconder bugs importantes.



## Decisão 60 - Fishing System - Pesca de Ressonancia

- Problema: o jogo precisava de uma direção clara para pesca sem tratar o sistema como uma cena de laboratório isolada.

- Decisão: registrar a pesca como sistema integrado ao lago real da fazenda, com Vara de Pesca, áreas opcionais de movimento e um minigame de sincronia leve.

- Motivo: manter a pesca acessível, mágica e coerente com o ecossistema alquímico, sem quebrar o loop agrícola já estável.

- Risco: a primeira implementação precisa ser pequena e controlada para não acoplar pesca, inventário, caldeirão e tempo real ao mesmo tempo.



## Decisão 61 - Vara de Pesca como ferramenta visual global

- Problema: a direção de pesca já estava definida, mas faltava uma base visual na toolbar principal para a ferramenta seguinte.

- Decisão: incluir a `Vara de Pesca` como ferramenta visual/global no `ToolManager` e na toolbar do jogo principal, sem acionar pesca real ainda.

- Motivo: preparar a navegação da interface e deixar claro para o jogador onde a pesca seguinte vai entrar, sem mexer no loop agrícola.

- Risco: a presença da ferramenta pode sugerir funcionalidade ainda inexistente, então o feedback visual e a documentação precisam continuar deixando claro que a pesca real ainda não foi implementada.



## Decisão 62 - Lago da Fazenda V0 clicável

- Problema: a pesca precisava sair do papel e ganhar um ponto físico no mundo principal sem virar minigame completo.

- Decisão: criar um `FishingSpot` simples na cena principal que só responde ao clique quando a `Vara de Pesca` está ativa.

- Motivo: validar o ponto físico da pesca com feedback mínimo antes de abrir boia, sincronia, recompensas e áreas especiais.

- Risco: o lago existe apenas como base mínima por enquanto; a pescaria real e os efeitos mais ricos ficam para fases seguintes.



## Decisão 63 - Boia V0 única e reposicionável

- Problema: o lago precisava de um primeiro estado visual da pesca sem multiplicar objetos ou criar fluxo de minigame cedo demais.

- Decisão: representar a pescaria com uma única boia ativa, que é reposicionada quando o jogador clica novamente com a Vara de Pesca.

- Motivo: manter o protótipo simples, legível e fácil de expandir para puxada, timing e recompensa depois.

- Risco: a boia ainda não tem comportamento de jogo além de posição visual, então o sistema real de pesca continua para etapas seguintes.



## Decisão 64 - Puxada Fake V0 por timer

- Problema: a boia precisava evoluir para um segundo estado visual sem abrir ainda o minigame de sincronia.

- Decisão: usar um timer simples para mudar a boia para um estado de puxada fake após alguns segundos e encerrar o teste quando o jogador clicar de novo com a Vara ativa.

- Motivo: validar a leitura da pesca em pequenos passos, mantendo a implementação controlada e sem recompensa.

- Risco: o timer ainda não representa a mecânica final de pesca; ele é apenas a ponte visual para a etapa de sincronia seguinte.



## Decisão 65 - Popup de Sincronia V0 no lago

- Problema: a puxada fake já estava validada, mas faltava um ponto de interação simples para testar a sincronia sem criar um minigame grande.

- Decisão: abrir um popup leve de Pesca de Ressonância diretamente da UI principal quando a puxada fake estiver ativa e o jogador clicar de novo com a Vara de Pesca.

- Motivo: manter a pesca integrada ao lago da fazenda, com feedback claro e sem acoplar recompensa, inventário ou caldeirão nesta fase.

- Risco: o popup precisa continuar pequeno, legível e fácil de fechar para não competir com o loop agrícola.



## Decisão 66 - Popup aceita Espaço e clique em qualquer área

- Problema: o popup de sincronia estava preso ao clique exato na barra e permitia novo lançamento durante a etapa aberta.

- Decisão: fazer o popup aceitar Espaço e clique em qualquer área da janela, e bloquear nova boia enquanto a sincronia estiver ativa.

- Motivo: melhorar a usabilidade e evitar conflito com o FishingSpot sem transformar o protótipo em uma cópia literal de outro minigame.

- Risco: a janela precisa continuar leve e previsível para não competir com o loop agrícola nem com a leitura do lago.



## Decisão 67 - Encerrar pesca preserva a Vara de Pesca

- Problema: o minigame precisava fechar sem quebrar o fluxo de pesca contínua.

- Decisão: ao encerrar a sincronia, forçar a `Vara de Pesca` como ferramenta ativa e deixar apenas o `FishingSpot` voltar para `IDLE`.

- Motivo: permitir uma nova tentativa imediata no lago sem exigir re-seleção da ferramenta e sem depender do toggle de `select_fishing_rod()`.

- Risco: a UI precisa continuar atualizando o status da ferramenta de forma consistente depois do reset do lago.



## Decisão 68 - Recompensa Aquatica V0

- Problema: o popup de sincronia já validava timing e feedback, mas ainda não gerava uma recompensa simples para o jogador.

- Decisão: fazer o resultado do popup entregar `peixe_comum` para `Bom` e `escama_brilhante` para `Perfeito`, mantendo `Errou` sem item.

- Motivo: deixar a pesca com um retorno inicial concreto no inventário sem conectar ainda caldeirão, receitas ou árvore de alquimia.

- Risco: os nomes, o balanceamento e o catálogo de recompensas continuam provisórios e podem ser refinados depois.



## Decisão 69 - Áreas com Movimento V0 da pesca

- Problema: o lago já funcionava, mas ainda faltava um ponto visual especial que favorecesse a sincronia sem obrigar o jogador a pescá-lo.

- Decisão: adicionar uma área com movimento V0 no Lago da Fazenda, com visual sutil e bônus simples no popup quando a boia é lançada dentro dela.

- Motivo: reforçar a leitura de um ponto especial no lago sem transformar a pesca em um minigame punitivo.

- Regra atual: o resultado `GOOD` pode ser promovido para `PERFECT` quando a boia é lançada dentro da área favorecida.

- Risco: a área continua sendo um V0 provisório e pode receber nova arte, variação visual ou regras mais ricas depois.



## Decisão 70 - Visibilidade da área com movimento

- Problema: a área especial existia na lógica, mas ainda podia ficar difícil de enxergar no runtime.

- Decisão: reforçar o desenho da `MovingFishingArea` com anel, brilho e pulso visual mais fortes, sem mudar o boost da pesca.

- Motivo: garantir que o jogador veja claramente onde existe um ponto favorecido no lago.

- Risco: o visual ainda é provisório e pode ser refinado ou substituído depois.



## Decisão 71 - Catálogo de Itens V0

- Problema: itens, crops e recompensas estavam ficando espalhados entre UI, pesca, cultivo e dados legados.

- Decisão: centralizar metadados básicos em `Scripts/Database.gd`, reaproveitando o autoload que o projeto já usa.

- Motivo: preparar nomes, ícones, raridade, venda e tags sem criar um sistema novo desnecessário agora.

- Regra atual: a UI consulta o catálogo primeiro para ícones/emoji, e os IDs da pesca já estão registrados no mesmo catálogo.

- Risco: os valores e descrições continuam provisórios e ainda podem mudar quando venda, receitas e filtros forem refinados.



## Decisão 72 - Area Bloqueada V0 com pocket append-only

- Problema: o Obstáculo Mágico V0 precisava mostrar uma área corrompida real, e não apenas o bloqueio visual isolado.
- Decisão: criar uma Área Bloqueada V0 visível com um pocket 2x2 de `FarmPlot` já reservado, escondendo e revelando esses lotes conforme a purificação.
- Motivo: tornar a expansão legível no mapa, preservar saves por ordem e manter a transição append-only sem criar sistema completo de áreas.
- Regra atual: o estado `first_obstacle_purified` controla tanto o obstáculo quanto a liberação do pocket.
- Risco: o pocket ainda é uma primeira leitura da expansão, então qualquer expansão seguinte precisa respeitar a ordem dos lotes e o save mínimo já adotado.

## Decisão 73 - UI base mínima com padrões godot-ui

- Problema: o inventário básico e a interface do caldeirão precisam nascer corretos sem abrir espaço para polimento demais antes do loop principal ficar sólido.
- Decisão: tratar a skill de UI apenas como orientação para a base dos `Control` nessa etapa, com foco em `anchors`, `size_flags_*` e `mouse_filter`, sem animações, temas customizados ou refino visual extra.
- Motivo: garantir layout e bloqueio de input da UI desde o início sem adicionar escopo novo ao protótipo.
- Risco: a disponibilidade de uma skill de UI pode incentivar polimento prematuro se o escopo não ficar rígido.

## Decisão 74 - Persistência robusta fica para depois

- Problema: uma arquitetura de save mais robusta parece útil, mas não é necessária agora para validar o protótipo.
- Decisão: adiar o sistema de persistência avançado para depois da estabilização do loop; no máximo, manter uma persistência mínima se testes longos exigirem guardar inventário ou estado básico de sessão.
- Motivo: evitar retrabalho em migração/serialização enquanto catálogo, UI e sistemas principais ainda estão amadurecendo.
- Risco: quando a persistência maior entrar, vai ser preciso revalidar compatibilidade e migração com cuidado.
