# Farm System V2

## Próximo recorte — semeadura seletiva, proposta aguardando aprovação

**Data:** 2026-10-04. O autor autorizou continuar após o fechamento do tomate. Esta etapa formula o próximo contrato; **não amplia a Decisão 134 nem implementa automação multicultura**. Baseline jogável: fonte `e5846b1`, pacote `Builds/Playtest/TomatoCrop-20261004`, fechamento documental `b0a393e`. Suas 59/59 regressões são evidência anterior, não execução desta consulta. Os **60 casos manuais permanecem pendentes**, sem exigir teste imediato.

### Resultado recomendado e alternativas

Permitir escolher **Trigo OU Tomate** para o mesmo semeador e os mesmos quatro lotes. Fecha o elo de plantio delegado do tomate já acessível, reforçando transporte físico e escolha de produção sem criar espécie, calendário ou nova área. As culturas disputam os mesmos lotes: não são duas fazendas paralelas.

Gameplay e engenharia convergiram nesse recorte após comparar controle sazonal público. `TIME_SYSTEM.md` reserva a direção de um dia real por dia do jogo e sete dias por estação; o TimeManager permanece isolado. Avanço voluntário público mudaria essa experiência e exigiria regras de culturas vivas, bônus, recuperação de inverno e persistência. Outono ainda depende de acesso sazonal; semente de inverno possui fontes RNG, mas nenhum bootstrap público determinístico confirmado. Esses problemas são reais, **não serão resolvidos por esta proposta**.

Lote sazonal alquímico, efeitos de Adubo/Elixir, rotação automática e novas espécies são alternativas maiores, não consequências do tomate. Não reativar Dormir, F10, lojas ou quests ocultas para contornar o contrato.

### Contrato candidato para confirmação integral

1. **Escopo físico:** golem atual, gate da Clareira restaurada, quatro células existentes `(0,0)`, `(1,0)`, `(0,1)`, `(1,1)`, ON/OFF e prioridades atuais. Não arar, ampliar área ou sobrescrever cultura. Rega, colheita, durações, navegação e Aceleradora permanecem iguais.
2. **Escolha exclusiva:** Trigo (`semente_basica`) OU Tomate (`semente_verao`), somente esses dois IDs. Escolher não liga a habilidade, muda prioridade ou interfere na ferramenta/semente pessoal. Sem fallback se faltar a semente escolhida, fila, rodízio ou mistura automática. A escolha só governa novas retiradas, nunca culturas já plantadas.
3. **Custódia:** buscar exclusivamente no Village Storage; retirar uma semente, carregar visivelmente e plantar após revalidar alvo/contexto/estação. A unidade conserva seu próprio `item_id` até ser consumida ou devolvida fisicamente. Sem acesso à Mochila, teleporte, fabricação de sementes ou depósito automático do resultado do caldeirão.
4. **Troca segura:** recusar mudança de cultura durante qualquer tarefa de semente, inclusive ida ao baú antes da retirada, ou enquanto existir cargo de semente, inclusive pausado/em devolução. Bloqueio no domínio e no painel com motivo consultável; não guardar troca futura. OFF continua permitido e conserva a devolução física atual da unidade original. Pausar ou encontrar obstáculo não autoriza apagar, converter ou refundar remotamente a carga.
5. **Validade agrícola:** trigo continua Primavera; tomate, Primavera/Verão. Recusa não gasta semente. Sem modificar bônus sazonais, mortalidade, timers ou estação global. Solo Vivo permanece benefício de trigo; seu lote `(2,2)` continua fora do piloto. Não prometer ciclo autossuficiente: sementes precisam de preparo/reposição pelo jogador, e rega depende do contrato manual/habilidade vigente.
6. **Persistência candidata:** campo opcional `selected_seed_id` no `golem_work`, validado estritamente. Snapshot com esse domínio presente e campo ausente resolve Trigo; completo antigo sem o domínio usa o padrão atual OFF/Trigo; parcial sem o domínio preserva o estado conforme política atual. ON/OFF, prioridades, cargas e gate existentes permanecem. Seleção e cargo são validados independentemente: cargo de tomate com campo ausente continua tomate, mesmo com futura escolha Trigo. Load substitui estado/invalida callbacks, não retira, planta ou deposita novamente. Candidato mantém work v1/save v4 se os testes confirmarem; **compatibilidade do runtime novo com saves antigos, não promessa de downgrade** para runtime que rejeita chave/cargo novos.
7. **Superfície:** seletor no painel atual do golem, sem novo HUD permanente, janela ou estética criada por Codex. Manter painel opaco/rolável, cabeçalho/Fechar fixos e mundo não pausado ao fechar. Comando apenas na vila ativa, fora de viagem/load/cache. Gate continua de habilidade, não recompensa automática por seleção. Antigravity recebe passagem funcional somente se a implementação aprovada afetar apresentação.

### Baseline técnico e plano mínimo após aprovação

Hoje `GolemSeedCargo` fixa trigo na validação, retirada, consumo e devolução; `Golem` fixa estoque, alvo e mensagens; `FarmPlot.try_plant_from_golem_cargo` força trigo. Portanto a mudança **não é apenas um seletor visual**. `GolemWorkState` rejeita campos desconhecidos; a extensão precisa preservar preflight e regras completas/parciais do SaveManager.

- **B, domínio/custódia:** whitelist de dois IDs e escolha para nova retirada; cargo como autoridade de plantio/devolução. Bloquear troca durante tarefa/cargo, manter OFF seguro e revalidar contexto/alvo antes do gasto. Responsável único pelos arquivos Cargo/Golem/FarmPlot; sem refatoração agrícola geral.
- **C, persistência:** campo opcional/default e validação estrita de snapshot/writer; preservar cargos válidos independentemente da escolha futura, legados/parciais/replay/cache e invalidação de callbacks. Nenhuma recompensa de load ou alteração em FarmTileData/GRID por consequência.
- **D, integração funcional:** seletor/status no painel existente, independente das seleções pessoais, sem autorligar. Mensagens para gate, falta de estoque, estação e troca bloqueada. Passagem em ART_HANDOFF descreve apenas o que efetivamente entrar; assets concorrentes não são incorporados automaticamente.
- **E, QA/entrega:** testar ambos os IDs em retirada/plantio/devolução, especialmente tomate não devolvido como trigo; troca antes da retirada, durante transporte/plantio/pausa/devolução; OFF durante espera, baú ausente, alvo ocupado, estoque perdido, estação recusada, whitelist inválida, legados/completo/parcial/replay/reabertura/cache e interação com colheita/Aceleradora. Regressões/pacote limpo só após implementação, com QA independente; acrescentar casos manuais então, sem pedir execução imediata ao autor indisponível.

### Portão de execução

Confirmar integralmente exclusividade Trigo OU Tomate, quatro lotes/gate atuais, ausência de fallback, bloqueio de troca com tarefa/cargo, custódia original e persistência/default acima. **A Decisão 134 conserva o semeador de trigo; esta ampliação precisa de nova aprovação humana antes de B.** Parecer técnico não aprova design, conforto, produtividade ou balanceamento.

Somente documentação: nenhum jogo/suíte/exportação novo, runtime/save/assets alterados ou save pessoal acessado. Não registrar a proposta como conteúdo implementado no ART_HANDOFF. Arte externa e seus trechos concorrentes permanecem intactos e fora da publicação própria.

Fechamento documental: QA independente em leitura guiada não encontrou bloqueador material; não aprovou design nem certificou novamente o pacote anterior. Coordenador conferiu diff sem erros e os 60 textos/ordem do checklist idênticos ao HEAD. Publicação seleciona somente cinco documentos próprios, excluindo o hunk artístico do §71 e demais arquivos externos; próximo portão continua confirmação humana integral.

## Segunda cultura inicial — fechamento técnico, manual pendente

**Data:** 2026-10-04. Autor respondeu “aprovado” ao contrato apresentado após `3153e5d`, incluindo tomate opcional Primavera/Verão e bootstrap padrão 1 trigo + 1 água → 1 semente/2s/0XP. A confirmação autoriza B–D delimitadas; não homologa arte, conforto ou balanceamento.

Domínio implementado: `Database.semente_verao.estacoes_permitidas` inclui Primavera/Verão, preservando `estacao_ideal = Verão` e 5s/base. Helper puro compartilhado governa validação do FarmPlot antes de gastar. Outras culturas mantêm fallback sazonal e o semeador continua trigo. Nova receita `semente_tomate_recuperacao` é padrão/repetível, sem XP/gate, resultado na Mochila; fontes/recibos/capacidade/cancelamento existentes intactos. SaveManager reconcilia receitas padrão depois de aplicar descobertas, sem Livro aberto e sem itens/XP/marcos novos; schema/IDs agrícolas não mudam.

Orientação funcional em descrição da semente, tooltip da Mochila/seleção e receitas do Livro; nenhum painel/HUD/collider/layout ou arte novo. Reinvestimento conserva ingredientes/quantidade/tempo/XP/descoberta. Solo Vivo não concede retenção ao tomate; bônus globais atuais não são alterados ou importados do Verão para Primavera. Não destruir culturas já existentes por estação de plantio.

**B–D fechadas tecnicamente.** Gameplay `a42b86d`, auditor corrigido `e5846b1`; pacote limpo **`Builds/Playtest/TomatoCrop-20261004`**, fonte `e5846b1`: **59/59 regressões, 12 reaberturas em processos novos e seis fixtures** (duas verificações cada, não reaberturas). Dedicado final: 125 verificações por backend headless/OpenGL, fixture2/reabertura8; regressão da Raiz86/fixture2/reabertura8. EXE headless/OpenGL, auditoria isolada do próprio PCK, manifesto/hashes e 85 logs passaram sem ERROR. Controle negativo recusa RenewableRoot antigo pela receita ausente; launcher/instruções/checklist presentes, checkout temporário removido. QA independente conferiu fonte e artefato sem bloqueador material.

Fixtures isolam eventos RNG legados e executam o refresh visual que o mundo congelado não faria; primeiras falhas de preparação preservadas, não contadas como PASS. Export inicial de `a42b86d` rejeitado por inferência de tipo no auditor; correção explícita não altera gameplay, repetição integral de `e5846b1` certifica o pacote. Diagnósticos negativos separados dos 85 logs finais.

Preservados 55 roteiros anteriores, acrescentados cinco TC: **60 manuais pendentes**, sem execução imediata obrigatória. Nenhum save pessoal acessado. Picking físico, conforto, ritmo, balanceamento e arte não homologados. Conteúdo visual registrado em ART_HANDOFF para Antigravity, não produção artística; spritesheets/cena/ícones e respostas artísticas concorrentes preservados fora desta publicação. Próximo recorte exige proposta delimitada e confirmação humana, sem ativar calendário/economia/efeitos reservados por consequência.

## Histórico da proposta de segunda cultura inicial

**Status histórico de `3153e5d`: formulação concluída, contrato ainda aguardava aprovação.** Posteriormente aprovado conforme seção atual acima. O autor autorizara somente a proposta após a Raiz; naquela formulação só mudou documentação. Baseline jogável da proposta: fonte `8d4df8c`, pacote `Builds/Playtest/RenewableRoot-20261004`, fechamento `909b159`; suas 58/58 regressões são evidência anterior, não execução da formulação. Os 55 casos manuais permaneceram pendentes e intactos.

### Resultado recomendado

Ativar o **Tomate do Sol já existente como segunda cultura inicial opcional**, com aquisição determinística da primeira semente e plantio permitido na **Primavera e no Verão**. Não criar espécie, estação automática ou novo tipo de solo. Esta é uma alteração deliberada da exclusividade sazonal atual do tomate e requer confirmação do autor; não está implementada.

Fluxo candidato: colher trigo → fabricar semente no caldeirão → plantar/regar tomate pelos controles atuais → colher → reinvestir quando desejar. Trigo e semeador continuam disponíveis na Primavera; nenhum objetivo de restauração passa a exigir tomate. Não prometer utilidade econômica, ritmo ou conforto já homologados.

### Baseline de aquisição e estação

| Conteúdo | Caminho ativo confirmado | Limite atual |
| --- | --- | --- |
| Trigo | Dez sementes iniciais; carvão + água → uma semente; dois trigos → três sementes | Plantio somente na Primavera; regar evita a morte por sede existente |
| Tomate | Semente básica + tomate → duas sementes de verão | Primeira semente exige o próprio produto; plantio somente no Verão |
| Abóbora | Tomate + Raiz Gélida → uma semente de outono | Dependência do primeiro tomate e de acesso ao Outono, não circularidade independente |
| Raiz Gélida | Coleta renovável no Bosque, uma unidade/45s de sessão | Produto acessível; isso não fornece semente de inverno |
| Semente de inverno | Drop de colheita de 15% e recompensa de quest aleatória | Nenhum caminho determinístico inicial confirmado; mural oculto não é aquisição pública |
| Estação global | Começa na Primavera; Dormir contém avanço legado com moeda | Botão oculto; não há calendário automático nem avanço no fluxo normal atual |

Fontes: `GlobalInventory.gd`, `Database.gd`, `FarmPlot.gd`, `SeasonManager.gd`, `UI.gd`, `Scenes/UI.tscn`, `QuestManager.gd`, `EventDirector.gd` e Resources em `Data/recipes`. Loja, mural oculto, debug/F10 e chamadas diretas de teste não contam como aquisição pública. Eventos atuais concedem XP, escama ou fragmento, não o primeiro tomate. **`agua_tomate_sol.tres` tem nome histórico enganoso: seu conteúdo real é tomate + raiz → semente de outono**, ID `tomate_sol_raiz_gelida`; não resolve o primeiro tomate.

### Contrato candidato para confirmação integral

1. **Identidade:** manter `semente_verao` e `tomate_sol`, nomes de itens e assets existentes. Não migrar IDs ou inventar lore. Atualizar apenas orientação funcional sobre as duas estações.
2. **Primeira semente e recuperação:** nova receita conhecida desde o início no Livro, **1 trigo + 1 água → 1 Semente de Tomate, 2 segundos, 0 XP**, sem descoberta aleatória, marco, moeda ou gate de restauração. Nome/ID técnico da receita será definido na integração; não é lore nova. Receita repetível, inclusive se todas as sementes/tomates forem usados. Se também acabar o trigo, suas rotas atuais de recuperação/replantio continuam base do ciclo. Estes números são parâmetros candidatos, não balanceamento aprovado.
3. **Fontes e capacidade:** produção manual/Livro preserva o contrato atual: Village Storage prioritário, Mochila completa, água na reserva regenerável existente, recibos/cancelamento sem duplicação e resultado pessoal. Sem coleta automática de água além do fluxo vigente. Resultado sem capacidade permanece pronto no caldeirão; não desviar para o baú. Plantio exige uma semente na Mochila, nunca consumo remoto do Village Storage.
4. **Plantio:** permitir Primavera/Verão somente para tomate. Preservar Verão, não substituí-lo por Primavera. Trigo/outono/inverno mantêm restrições. Aragem, ocupação, bloqueio, distância, seleção exclusiva e guardas de viagem/load continuam válidos; recusa não consome semente. Não alterar estação global ou expor Dormir.
5. **Ciclo:** crescimento base do tomate permanece 5s; rega conserva o fator vigente 0,8. Bônus global atual de Verão só atua no Verão, não é importado para a Primavera. Na Primavera o bônus genérico existente de 20% de devolução da semente passa a alcançar tomate, sem virar requisito para reposição. Sem novo sorteio, rendimento ou mortalidade. Regar evita a morte por sede de 20% existente fora do Inverno; aquisição determinística não promete sucesso de cultura abandonada sem água.
6. **Automação e solo:** semeador exclusivo de trigo e dos quatro lotes atuais, OFF/ON e prioridades inalterados. Rega/colheita de tomate usam somente políticas já existentes do golem. Solo Vivo conserva tratamento, mas tomate descarta umidade herdada e não recebe a retenção destinada ao trigo. Sem novo modificador/solo sazonal.
7. **Reposição e usos:** preservar semente básica + tomate → duas sementes de verão como caminho adicional, com descoberta vigente. Bootstrap conhecido no Livro não depende dessa descoberta. Tomate + trigo → Adubo e tomate + raiz → semente de outono já existem, mas **não ganham novos efeitos ou acesso sazonal**. Não apresentar Adubo/Elixir como funcionalidades operacionais apenas por estarem catalogados. Venda universal permanece direção futura, não loja reativada.
8. **Compatibilidade:** nenhum estado transitório novo, migração de cultura ou benefício no load. Preservar IDs, culturas/timers vivos, rewards pendentes e carga do golem. A princípio não é necessário campo novo no save; conferir por testes antes de concluir. Saves completos/legados devem aprender a receita padrão pelo reconciliador existente sem ganhar itens/XP/marcos; snapshot parcial mantém regras atuais. Tomates já existentes fora das estações de plantio não serão destruídos retroativamente.

### Alternativas não escolhidas para este piloto

| Alternativa | Vantagem | Por que não é o menor recorte agora |
| --- | --- | --- |
| Controle voluntário de estação | Preserva exclusividade e abre estações futuras | Não resolve a primeira semente sozinho; afeta semeador, culturas vivas, quests e save sazonal |
| Lote condicionado alquímico | Mantém simultaneidade e reforça solo/caldeirão | Exige regra local, preparo, aplicação e persistência nova; aquisição ainda precisa ser resolvida |
| Nova cultura de Primavera | Evita mudar identidade sazonal do tomate | Precisa novos IDs, função própria, catálogo e integração artística externa |

Troca global não é um botão isolado: `SeasonManager.avancar_estacao()` limpa/gera quests RNG; FarmPlot calcula duração no plantio, mas consulta estação atual para morte por sede e bônus ao gerar recompensas. Semear trigo só funciona na Primavera. `SaveManager` usa coerção/fallback permissivo para estação/ano, sem preflight sazonal estrito. Calendário futuro exige contrato separado, não reaproveitar Dormir sem análise. Solo/favored_season no tile não prova autoridade local pronta: FarmPlot governa o estado vivo.

### Plano mínimo após aprovação

- **B, domínio e dados:** Resource de bootstrap sem colisão de par/ID, reconciliador de receita padrão, lista opcional de estações permitidas no catálogo com fallback da restrição atual. FarmPlot revalida antes de gastar; manter `estacao_ideal` do tomate como Verão e outras culturas intactas. Sem editar SeasonManager/quests/economia ou ampliar semeadura.
- **C, orientação e integração:** Livro e descrição/seleção de sementes explicam Primavera/Verão e recuperação, sem novo HUD/janela ou uso livre de poção. Reusar controles, assets e crafting existentes; não misturar apresentação com collider/grid. Antigravity recebe nota em ART_HANDOFF somente após implementação com impacto visual; proposta não cria demanda como se estivesse entregue.
- **D, QA e entrega:** testar ciclo desde zero tomate/semente, recuperação sem RNG, manual/Livro, origens/reserva/cancelamento/resultado bloqueado, estações aceitas/recusadas, seleção/input, Solo Vivo não-trigo, golem com crop/cargo/semear trigo, GRID/v3/v4/legado/parcial/replay/cache e reabertura. Pacote limpo depois da implementação e regressões proporcionais, com QA independente. Testes que gravam apenas em QA isolado; nunca save pessoal.

Fora do piloto: calendário, acesso público a Outono/Inverno, aquisição determinística da semente de inverno, novas espécies/animais/golems, mastery, economia, NPCs, mapas, tempo offline, efeitos de Adubo/Elixir e novos solos. **Resolve aquisição e estação do tomate, não a sazonalidade inteira.**

### Revisão e portão de execução

Gameplay e engenharia consultados em leitura explícita dos perfis, sem carregamento nativo alegado, edição pelos especialistas ou consulta artística. Convergiram no recorte local; evitar acoplamento global não homologa valor de gameplay. Documentação separa fato atual, parâmetro candidato e validação futura.

Confirmar com o autor **tomate na Primavera/Verão, receita padrão 1 trigo + 1 água → 1 semente/2s/0XP, bônus sazonais vigentes e exclusões acima** antes de B. Não foi executado jogo/suíte/exportação; build e 55 textos manuais anteriores intactos.

Fechamento documental: QA independente guiado por `cc_qa` não encontrou bloqueador material nos cinco documentos; não aprovou design/arte. Coordenador conferiu diff sem erros e os 55 casos do ROADMAP idênticos ao HEAD, inclusive ordem; QA conferiu roteiros/status sem usar Git. Validador no workspace passou cinco perfis/referências e seis controles negativos, sem descoberta nativa comprovada. Somente documentação própria é selecionada para publicação; hunk artístico concorrente no §71, perfis/equipe e assets externos permanecem fora do incremento. Fonte jogável e pacote não mudam.

## Poção Aceleradora — P3, integração fechada tecnicamente (2026-10-04)

Autor confirmou o contrato completo da P2 com “sim”, incluindo preparo pelo painel sem aproximação e persistência no save. **Integração implementada e fechada tecnicamente:** um frasco pessoal por nova entrega lógica, deslocamento 1,5× somente até o baú; sem alteração de receita/timers/benefícios. A aprovação substitui o portão documental abaixo, não homologa arte, conforto ou valor econômico.

Fonte `f0f68ab`, pacote limpo **`Builds/Playtest/AcceleratorDelivery-20261004`**: suíte **57/57**, dez reaberturas em novos processos (**8 + 8 + 3 + 6 + 8 + 8 + 8 + 4 + 8 + 8**) e quatro fixtures (**2 + 2 + 2 + 2**, separados). Novos modos preparada/ativa exigem oito checks cada; seus produtores exigem dois cada. Domínio passou **191 verificações por backend headless/OpenGL**; UI **154 por backend**, Sower UI **325**. Desvio de produção com collider ativo: percurso 542,951 px, distância mínima por segmento 45,023 ≥ 45,015 px, passo máximo 3,2 px e fallback observado, sem teleporte ou prêmio/custo extra. Timer/callback/guardas antes de off-tree, pausa DEPOSITING, estoque/baú perdidos, snapshots negativos/legados/parciais/replay/cache e arquivo anterior preservado conferidos. Depósito normal recusado por contexto volta IDLE para retry; não fica preso após transição interrompida.

EXE headless/OpenGL e auditoria isolada do PCK passaram; controle negativo recusa LivingSoil-20261004 pela Aceleradora ausente, sem fallback do workspace. Manifesto/hashes/logs/instruções/checklist/launcher acompanham o pacote; checkout temporário removido. Arte/UX revisou nove capturas nas três resoluções; QA independente conferiu fonte/artefato/contagens/hashes sem bloqueador material, por leitura explícita dos perfis. Cinco perfis/seis controles negativos passaram, sem descoberta nativa alegada. Primeira execução de domínio com dois diálogos exclusivos do fixture foi rejeitada apesar do PASS 181; log preservado como negativo, limpeza corrigida apenas no teste, finais 191 sem ERROR. Falhas intermediárias de compilação/resolução de fixture UI não são evidência final.

**50 casos manuais pendentes:** 45 textos anteriores idênticos + cinco AC, sem exigir teste imediato ao autor. APPDATA QA isolado, nenhum save pessoal acessado e oito arquivos locais alheios intactos. Picking/gesto físico completo/arte/conforto/ritmo/balanceamento seguem pendentes; uma rota validada não garante avoidance universal. Sem loja/moeda/NPC/mapa/mastery/tempo offline ou novo benefício por consequência. Próximo recorte de progressão requer proposta delimitada e aprovação.

## Poção Aceleradora — P2, proposta de uso pelo painel (2026-10-04)

**Status histórico no fechamento da P2: formulada, aguardando confirmação do contrato.** Posteriormente confirmado pelo autor na P3 acima. Autor aprovou continuar com a proposta P2 após a P1 publicada em `0473814`. Não autorizou, por consequência, integração de produção, consumo remoto ou save novo. Esta etapa é documental; não altera código/cenas/itens/receitas, não executa o jogo e não fecha teste manual. P1 continua evidência técnica, não homologação de utilidade.

### Utilidade e recomendação

Ganhos P1 ≈0,383/1,783/1,417 s por entrega curta/longa/desvio. O painel reduz atenção, mas não aumenta esse benefício; fabricar um frasco requer dois ingredientes e 2 s, podendo ocorrer antes/em paralelo. Não concluir saldo temporal negativo nem ganho global de produção: o ensaio não incluiu aquisição, fabricação, gesto humano ou frequência das rotas. Recomendar como **conveniência opcional/situacional**, sem objetivo obrigatório, repetição automática, aumento de timers, mudança de receita ou expansão para várias entregas. O autor pode confirmar o piloto ou manter o item sem efeito de produção até revisão posterior; não fabricar valor com sistemas novos.

### Contrato candidato — precisa de aprovação humana

1. **Comando pela interface:** botão fixo Golem → painel existente → `Preparar próxima entrega`. Sem clicar no corpo móvel, perseguir, pausar ou aproximar o personagem. É uma **abstração de comando/preparo remoto dentro da vila**, não transferência física simulada, lore aprovada ou permissão para comandar a vila do Bosque. Usar frasco da Mochila sem aproximação é parte explícita da proposta; não fundir armazenamentos, retirar do baú ou ativar VillageResourceAccess por inferência.
2. **Preparo one-shot:** requer golem da vila ativa, fora de load/viagem, pelo menos um frasco pessoal e nenhum preparo/benefício existente. Armar só registra a ordem; não retira/reserva o item e não seleciona ferramenta/semente. Pode preparar sem carga, durante outro trabalho ou durante uma entrega normal. Não altera prioridade, liga semeadura/rega ou pausa o scheduler.
3. **Próxima entrega lógica, não próxima rota:** uma nova custódia de colheita começa sem entrega iniciada. Sua primeira abertura válida ao baú marca a entrega como iniciada, com ou sem poção. Retry, pausa/retorno/cache/load dessa carga **nunca** tornam a entrega nova. Preparo feito durante uma entrega normal já iniciada espera a próxima custódia; carga ainda não iniciada por falta de baú pode ser beneficiada ao abrir sua primeira rota válida. Não usar somente `state == IDLE` ou uma chamada a `_procurar_bau()` como prova de elegibilidade.
4. **Ponto de consumo:** na primeira abertura da entrega elegível, revalidar vila/geração/carga de colheita/baú/contexto/estoque e consumir **um frasco pessoal**, passando de preparada para ativa sincronamente antes de feedback/sinais. Nenhuma carga de sementes participa. Sem baú antes do gasto, conserva preparo/carga e não cobra. Sem frasco nesse momento, encerra preparo, avisa uma vez e segue entrega normal; não espera reposição para cobrar silenciosamente depois. Rejeição de contexto/rota antes do commit não cobra. A rota pode encontrar obstáculo depois do commit: nesse caso mantém o benefício, não promete caminho sempre alcançável.
5. **Efeito:** deslocamento experimental 1,5× somente em MOVING_TO_CHEST com a carga beneficiada. Uma carga pode conter mais de um tipo de recurso e ainda é **uma entrega**, não uma dose por item. Nada de teleporte, produção/colheita extra, aceleração de depósito/rega/plantio/descanso ou velocidade-base permanentemente alterada.
6. **Cancelamento e término:** `Cancelar preparo` é gratuito antes do commit. Fechar/Escape apenas fecha o painel, não cancela a ordem nem pausa o golem. Depois do gasto não há cancelar/refund do benefício; pausa, travamento, baú ausente e retry preservam carga/condição até depósito efetivo único. Depósito confirmado limpa benefício/marcador; próxima carga volta ao normal. Não permite fila de próxima preparada enquanto ativa, empilhamento ou autorrepetição. Cancelar o preparo não cancela o trabalho.
7. **Persistência deliberada:** preparada ou ativa acompanham save/cache; isto é diferente da mira transitória de Crescimento/Solo Vivo. Nenhuma nova ordem/retirada/movimentação/entrega acontece com a vila fora da árvore, durante transição/load ou offline. Load substitui estado, não consome/refunda; retorno reconstrói rota existente sem renovar benefício. Legado sem campos começa sem poção; cargo legado considera entrega já iniciada, conservadoramente, para impedir retroatividade. O autor precisa aprovar essa ordem persistente e o ponto irreversível do consumo.

### UX mínima proposta

Bloco compacto no painel opaco/arrastável atual: ícone existente, `Aceleradora`/`Mochila: N`, regra `1 frasco · 1 entrega de colheita · deslocamento +50%`, uma linha de estado **da poção** e uma ação contextual. Não duplicar estado operacional do golem, prioridades/semeador, contadores ou painéis. Sem nova faixa permanente/HUD, picking/collider ou arte final. Aviso de falta de estoque usa feedback existente mesmo com painel fechado.

| Estado da Aceleradora | Informação principal | Ação |
| --- | --- | --- |
| Nenhuma | Nenhuma preparada; estoque pessoal consultado | Preparar próxima entrega, recusado sem frasco/contexto |
| Preparada | Nada gasto/reservado; não altera entrega já iniciada | Cancelar preparo |
| Ativa | Um frasco usado nesta carga; conserva em pausa/retry | Sem preparar/cancelar benefício |

Antes de preparar, explicar consumo futuro na primeira entrega nova e preservação após fechar/save. Pode iniciar com painel aberto antes de tentar cancelar: não prometer cancelamento após o commit. Cartão da Mochila apenas orienta `Use pelo painel Golem`, sem `Aplicar` livre nem segundo fluxo de consumo. Consulta ao painel não usa a guarda modal da aplicação física, que bloquearia seu próprio comando; clique GUI/arrasto/foco/Escape não atravessam para movimento/cultivo/pesca. Preservar seleções existentes.

`GolemPanel.gd` limita largura, não altura. Futuro bloco deve caber em 800×600/800×720/1280×720, mantendo controles existentes legíveis; se preciso, rolagem local do conteúdo, sem reduzir fonte ou transformar escopo em reforma geral de HUD. Somente protótipo visual; referências de arte seguem AGENT_TEAM.

### Plano mínimo de integração futura — não iniciado

- **Domínio:** Golem como autoridade de preparo/benefício e fase da custódia; UI só consulta/solicita. Marcador lógico persistido, por exemplo `harvest_delivery_started`, não ID/posição/callback de rota. Receber nova colheita zera fase; primeira abertura válida marca iniciada mesmo sem benefício; retry nunca consome de novo. APIs revalidam golem/vila/contexto/estoque independentemente do modal. Sinais somente após estoque/custódia/flags consistentes; guardas contra reentrada.
- **Persistência:** GolemWorkState hoje exige exatamente cinco campos; extensão explícita, campos opcionais booleanos estritos/chaves conhecidas no save v4, sem migração genérica. Preparada/ativa exclusivas; ativa exige cargo de colheita, entrega iniciada e nenhuma semente; marcador iniciado exige cargo. Preparada não exige estoque contínuo. Completo/legado resolve ausentes sem bônus; payload parcial preserva somente o domínio realmente omitido, nunca herda flags de cargo substituído ou deduz identidade por totais iguais. Writer/preflight/replay/cache devem recusar contradições antes de mutação e preservar arquivo anterior.
- **Interface:** bloco contextual/estoque/estado/ação no GolemPanel/UI; orientação de consulta do item sem Aplicar físico; descrição funcional, sem mudar receita/custo. Não reutilizar diretamente `begin_consumable_application`, que limpa ferramenta/semente. Referência à vila ativa, nunca à UI cacheada.
- **QA/entrega:** testar preparo durante entrega normal seguido de pausa/retry/load (sem retroatividade), ausência de baú antes/depois do gasto, estoque perdido, reaplicação/cancelamento, pausa durante DEPOSITING, callbacks obsoletos, próxima carga normal, semeadura/rega inalteradas, reentrada, snapshots completo/parcial/legado/contraditório e novo processo preparado/ativo. Conferir input/modal/arraste/seleções/geometria, física com obstáculo ativo, regressão proporcional e pacote limpo. Atualizar checklist manual só quando houver funcionalidade testável, preservando os 45 casos atuais e sem exigir execução imediata ao autor.

Gameplay, UX e engenharia revisaram o candidato por leitura explícita dos perfis: risco de microgestão/baixo ganho, estados e altura do painel, diferença de nova entrega versus retry e schema estrito. QA independente conferiu os cinco documentos sem bloqueador material; diff/checklist contra `0473814` manteve os 45 textos manuais idênticos. Validador de cinco perfis/seis controles negativos passou; isso não é execução de gameplay ou descoberta nativa dos agentes. Parecer não aprova abstração remota, persistência ou equilíbrio. Implementação e validações acima permanecem futuras; nenhum novo jogo/suíte/build/save pessoal nesta P2. Portão seguinte: o autor confirmar o conjunto de regras, antes de integrar.

## Poção Aceleradora — P1, protótipo isolado de entrega (2026-10-04)

Autor aprovou iniciar um ensaio, não ativar a poção no jogo principal. Recorte experimental: um frasco pessoal beneficia uma entrega física de colheita do golem ao Village Storage, com deslocamento 1,5×; sem teleporte, produção extra, empilhamento ou aceleração de cultivo/rega/plantio/depósito. Pausa/obstáculo não devem desperdiçar o benefício. Receitas existentes com peixe + trigo ou carvão + trigo permanecem intactas. Valores do ensaio não são balanceamento final.

P1 cria somente cena/scripts em `Scenes/dev` e `Scripts/dev`, reutilizando golem/baú/cenário reais. Comparar trajetos curto/longo/desvio, mesmas origens/cargas/obstáculos e ordem alternada quando possível. Medir frames/tempo de física e distância percorrida, separando movimento de conclusão/depósito; velocidade +50% não promete reduzir duração total em 50% nem em exatamente 33%. Preservar custódia e conferir entrega única, custo, recusa/reaplicação, cancelamento, pausa e retry. Não alongar timers do jogo real ou simular tempo offline.

Nenhum arquivo runtime, receita, save/schema, prioridade ou navegação geral deve mudar nesta P1. O estado do benefício experimental não é persistido; viagem/load e preparação antes de ter carga precisam de contrato aprovado antes da integração. Execução somente com APPDATA isolado sob Builds/QA, sem acessar/copiar/editar save pessoal. O teste não usa nome `SmokeTest`, portanto não altera a suíte/runner de produção. O pacote LivingSoil-20261004 continua sendo a entrega jogável vigente, sem Aceleradora funcional.

Gameplay recomendou logística em vez de timers curtos; engenharia identificou ausência de picking próprio do golem e aproximação da Main vinculada à posição inicial, inadequada para alvo móvel. Arte/UX recomenda estudar botão fixo Golem → painel existente → preparação de uma entrega, não perseguição/pausa obrigatória. Esse parecer ainda não aprova aplicação remota, consumo/refund ou nova interface: consumo, elegibilidade antes/durante entrega e preservação em save/cache continuam decisões de integração. Na P1 a interface é estudo, não implementação de produção nem arte final.

### P1 — fechamento técnico e resultado observado

Protótipo concluído em `Scenes/dev/AcceleratorDeliveryPrototypeTest.tscn` e dois scripts `Scripts/dev/AcceleratorDeliveryPrototype*.gd`; adapter dev estende o Golem original e restaura velocidade exportada/max_speed após cada tick. Fonte de produção permanece `549aa60`, baseline documental `97d9e30`. Não é integração nem novo pacote jogável.

Execução headless e OpenGL Compatibility: **183 verificações por backend**, **18 entregas/9 pares por execução**, três pares alternados em cada trajeto, física a 60 Hz/time_scale 1. Medianas headless do tempo de estado de transporte + depósito:

| Trajeto | Normal | Experimental 1,5× | Ganho observado | Distância normal / acelerada |
| --- | ---: | ---: | ---: | ---: |
| Curto | 1,483 s | 1,100 s | 0,383 s (25,8%) | 151,47 / 150,40 px |
| Longo | 5,700 s | 3,917 s | 1,783 s (31,3%) | 691,21 / 691,20 px |
| Desvio pelo caldeirão | 5,767 s | 4,350 s | 1,417 s (24,6%) | 542,99 / 542,95 px |

Tabela usa a execução headless final após explicitar limites no relatório; ganho é a diferença entre medianas, não a mediana das diferenças de cada par. OpenGL registrou medianas normais 1,500/5,717/5,767 s e aceleradas 1,100/3,917/4,367 s, diferença de até um frame frente ao headless, com conclusão/custódia iguais. `walk_seconds` mede o estado MOVING_TO_CHEST, inclusive espera pelo detector de travamento; não é tempo de movimento contínuo. Depósito de 0,3 s e recuperação de rota não são acelerados. Pequena diferença de distância curta decorre do limiar de chegada/discretização, não de outra rota; esses números não são economia por minuto ou balanceamento final.

Collider real confirmado por consulta à física antes das 18 amostras; mínimo medido por segmentos nos seis desvios ≈45,015 px, soma dos raios do caldeirão/golem, sem atravessamento. Todos exercitaram o fallback real de desvio. Custo pessoal exato, recusa sem frasco/carga, cancelamento/reaplicação, callback obsoleto, pausa em movimento, interrupção de rota, baú ausente/reinserido e entrega seguinte sem bônus passaram. Baú ausente usa controle negativo sintético de chegada: não representa capacidade, pois o Storage atual é ilimitado. **Pausa durante DEPOSITING não foi exercitada**; load/cache/persistência do efeito e UX móvel não fazem parte da P1.

A primeira execução ficou **FAIL**: congelar CauldronUI por PROCESS_MODE_DISABLED retirava seu collider. Corrigido somente o fixture, preservando física; acrescentadas consultas/mínimo por segmentos, sem afrouxar o critério de desvio ou mudar navegação runtime. Resultado inicial preservado em `Builds/QA/AcceleratorDeliveryPrototype/results_initial_invalid_geometry.json`/`Accelerator-P1.log`, não valida os desvios. Evidências finais locais: `results_headless.json`, `results_windows.json`, `Accelerator-P1-final.log`, `Accelerator-P1-OpenGL.stdout.log`/`.stderr.log`. Um aviso esperado de baú inválido acompanha o controle negativo; não afirmar ausência de warnings. QA independente conferiu código, logs/JSON e geometria, sem bloqueador material.

Regressão proporcional nesta P1: GolemLife, GolemWorkPersistence (**148**), PlayerNavigationPolish e LivingSoil (**173**) passaram; GolemWork em processo novo passou **6** verificações. Não é nova execução da suíte completa 55/55, nem reabertura do efeito experimental. Cinco perfis/seis controles negativos passaram. Nenhum save pessoal acessado, asset novo ou produção alterada; exportação Playtest exclui dev, runner conserva 55 testes. Sem nova build ou inspeção/aceite de UX final.

Para reproduzir, configurar APPDATA para uma pasta dentro de `Builds/QA` **antes** de iniciar Godot 4.6.2 e executar a cena dev acima; ela recusa outro user_data_dir antes de instanciar Main. Não executar esse ensaio com progresso pessoal. Logs/resultados/fixtures são locais e ficam fora do Git.

As **45 pendências manuais existentes permanecem intactas**, sem exigir testes imediatos. O efeito técnico existe no ensaio; os ganhos absolutos pequenos ainda não demonstram que um frasco/uma entrega compensa ingredientes, fabricação e atenção do jogador. Revisão de gameplay dos resultados recomenda conveniência opcional/situacional, sem promessa de produção sustentada. Fabricação de 2 s supera os ganhos de cada rota ensaiada, mas pode ocorrer antes/em paralelo: não prova saldo negativo de tempo. Fixture fornece frasco/carga; não mede aquisição/fabricação, interação humana, ida ao lote/colheita, frequência das rotas ou rendimento global. Não alterar receita, alongar timers ou ampliar para múltiplas entregas/consumo automático para justificar o item sem aprovação. Portão seguinte: revisar utilidade/custo e confirmar UX/contrato antes de integrar ao jogo principal. Preparação pelo painel é proposta, não autorização de aplicação remota, repetição automática ou persistência nova.

## Solo Vivo e aplicação pelo mouse — B–E fechadas tecnicamente (2026-10-04)

Autor confirmou receita/parâmetros do piloto e aprovou o fluxo consulta opaca → Aplicar → alvo válido → aproximação → consumo na chegada. B–D implementadas e E concluída tecnicamente. Não é aceite manual nem arte final.

- Mistura Restauradora é ingrediente/projeto; Poção Purificadora Fraca usa o painel do obstáculo. Não recebem aplicação livre ou efeitos inventados.
- Clicar em item não-semente da Mochila consulta nome/ícone/quantidade/função. Somente Crescimento e Solo Vivo oferecem Aplicar. Sementes conservam seleção de plantio existente. Arrasto não arma/consome; baú conserva seu fluxo exclusivo de transferência.
- Aplicar limpa ferramenta/semente e arma intenção transitória. Consulta é modal; orientação/mira não bloqueiam o mundo inteiro. Cancelar visível, botão direito/Escape, outro item/ferramenta/semente, clique em outro controle da UI, outro modal, câmera/viagem/load invalidam intenção/rota. Intenção não é salva. Sucesso encerra; recusa mantém opção de escolher alvo/cancelar, sem fallback de plantio/colheita.
- FarmPlot valida alvo/estado/estoque; Main revalida vila ativa, geração, identidade e distância. Consumo e efeito são síncronos antes dos sinais. Não reservar enquanto caminha nem retirar preparo/frasco remotamente do Village Storage.
- Crescimento: carga legada disponível é usada primeiro. Sem doses, o primeiro alvo válido abre um frasco, gera três e usa uma (restam duas). Consultar/armar/cancelar não abre frasco; planta madura/timer parado/estoque ausente recusam. Clique normal na cultura não gasta mais cargas. Cancelamento conserva doses; campos de save existentes mantidos e quantidades inválidas recusadas antes de mutação.
- Solo Vivo: receita 1 trigo + 1 Mistura → 1 preparo, 2 segundos/0 XP, aprendida após Clareira (reconciliação de saves elegíveis). Lote lógico existente `(2,2)`, centro local `(840,920)`, fora do semeador; somente vazio/arado/não tratado. Aplicar gasta um preparo pessoal, não rega/inicia cultura/timer. Reaplicação/outro alvo sem gasto.
- Tratamento durável separado da umidade herdada e da rega atual. Colheita de trigo regado efetivamente entregue preserva umidade no lote vazio; replantar trigo usa fator existente 0,8, sem multiplicador novo. Outros cultivos continuam válidos, descartam apenas umidade herdada e não recebem o efeito. Morte/limpeza conserva tratamento, limpa água herdada/rega. Recusa de colheita preserva cultura/recompensas/flags; retry não rerrola nem repete entrega. Logística/scheduler do golem não mudam.
- Duas flags booleanas opcionais atravessam FarmPlot → GRID → save v4, inclusive lote vazio/grama após limpeza. Legado completo começa comum; parcial preserva ausentes, recusando contradições. Preflight puro recusa tipos, estado/umidade incompatíveis, tratamento fora do piloto e entradas GRID piloto duplicadas. Load substitui sem aplicação/consumo/recompensa. Vila cacheada conserva estado; aplicação remota recusada.
- Contorno do lote no chão, cartão e faixa transitória são protótipo funcional, não nova direção artística. Sem assets novos, lore/economia/mapas/mastery/tempo offline ou alongamento de timers. Cultivos curtos limitam a utilidade de Crescimento; balanceamento permanece pendente.

Fonte `549aa60` exportada em checkout limpo para `Builds/Playtest/LivingSoil-20261004`: suíte **55/55**, oito reaberturas imediatas em novos processos (**6 + 3 + 8 + 8 + 4 + 8 + 8 + 8**) e dois fixtures adicionais (**2 + 2**, não reaberturas). LivingSoilSmokeTest: **173 verificações**, reabertura **8**; também passou a execução gráfica dedicada com 173/8 e inspeção dos cartões/faixa em 800×600 e 1280×720. Importação, startups do EXE headless/OpenGL e auditoria do PCK sem erros. Controle negativo recusa VillageWell-20261004 por ausência do contrato de Solo Vivo, sem fallback do workspace. Manifesto identifica fonte, hashes e contagens; logs, instruções, checklist e StartPlaytest.cmd acompanham o pacote.

As 36 pendências anteriores permanecem intactas; nove SV/UP acrescentados (**45 pendentes**). Testes somente em APPDATA isolado sob Builds/QA, sem acessar/copiar/editar save pessoal. Revisão independente guiada por QA sem bloqueador material após correções de GRID duplicado, cancelamento GUI/drag, UI cacheada e proteção de doses na gravação. Validador de cinco perfis/seis controles negativos passou; checkout temporário removido e oito arquivos locais alheios preservados fora do commit. Eventos sintéticos/force_drag não homologam cursor físico, gesto de arraste completo, conforto ou balanceamento. Não exigir testes imediatos ao autor indisponível; VillageWell-20261004 permanece histórico.

## Solo Vivo Alquímico — lote retentor, Fase A (2026-10-04)

**Baseline histórico da Fase A:** conceito do piloto aprovado e plano então somente documental. Posteriormente o autor confirmou parâmetros e aprovou a UX pelo mouse/implementação; consultar o checkpoint acima. Essa aprovação não ativa todas as variantes futuras de solo.

### Resultado aprovado e limites

Produzir um preparo no caldeirão, carregá-lo na Mochila e aplicar manualmente no lote piloto. Após a primeira rega e uma colheita de trigo efetivamente entregue, o lote conserva a umidade para replantios de trigo. Tratamento durável, sem reaplicação diária, colheita extra, cultura/estação nova ou ativação automática do golem. FarmPlot continua autoridade; nenhuma migração para FarmGrid.

O bônus atual de plantio com `regado=true` é ×0,8 no tempo de crescimento (`Scripts/FarmPlot.gd`, `_try_plant_seed`). Ele continua aplicável aos próximos plantios já úmidos; não há multiplicador novo nem promessa de tempo invariável. Cultivos atuais de 3–6 segundos e rega do golem sem consumo de água limitam a utilidade observável: o benefício é conforto/localização previsível, não economia global de água ou balanceamento homologado.

### Parâmetros do piloto — confirmados e contratos técnicos adotados

| Parâmetro | Contrato do recorte |
| --- | --- |
| Receita | 1 trigo + 1 Mistura Restauradora → 1 preparo; 2 segundos; 0 pontos de alquimia |
| Aprendizado | Clareira restaurada; `exige_descoberta=true`, reconciliação também para saves já elegíveis, sem novo prêmio ou restauração repetida |
| Lote | Célula lógica `(2,2)`, FarmPlot existente, centro local `(840,920)`; identidade pelo registro da Main, não pelo nome/posição visual isolados |
| Aplicação | 1 preparo da Mochila; lote vazio/arado, vila ativa e proximidade revalidada; aplicar não rega, não inicia timer e não altera cultura existente |
| Repetição | Recusar em lote já tratado ou outro alvo, sem gasto; não empilhar bônus |
| Outros cultivos | Não proibir culturas já válidas; plantar não-trigo descarta somente umidade herdada, segue regras normais e não recebe o efeito; tratamento permanece |
| Morte/limpeza | Tratamento permanece, umidade herdada/rega são limpas; exigir rega normal para reiniciar o ciclo; sem água, item ou refund gerados |
| Interface | Cartão opaco de consulta → Aplicar → alvo/chegada; intenção transitória exclusiva com sementes/ferramenta, cancelamento visível/RMB/Escape/UI/load/viagem, sem gasto; nenhuma ferramenta/HUD permanente nova |

“Preparo” é nome funcional provisório, não lore final. Receita usa duas entradas, compatíveis com os dois slots manuais e com o Livro/lote. `2 trigos + 1 mistura` exigiria três entradas e não cabe na mistura manual atual; não ampliar os slots para este piloto. A combinação recomendada não colide com as 14 receitas resource-first nem com o fallback legado no baseline `58592d1`.

A célula proposta pertence à grade inicial 4×4, fora das quatro células do semeador `(0,0)/(1,0)/(0,1)/(1,1)` e do pocket das colunas 6–7. Mantém FarmOrigin `(680,760)`, espaçamento 80 e os 34 lotes/ordem legados. Não é limite global configurável ou nova área. Confirmado estruturalmente por leitura, não por teste físico de navegação/composição.

### Baseline e contrato técnico proposto

- Consultas guiadas por `cc_gameplay`, `cc_engineering` e parecer artístico anterior; nenhum carregamento nativo do perfil foi comprovado. Principal conferiu os pontos de código abaixo; revisão independente guiada por `cc_qa` não encontrou achado material nos cinco documentos, sem autorizar design. Checklist mantém 36 textos pendentes idênticos ao HEAD; validador dos cinco perfis e seis controles negativos passou. Essas verificações documentais não são testes do Solo Vivo implementado.
- `FarmPlot._concluir_colheita` hoje limpa `regado` e também é usado por reset/load inválido. Preservação de umidade deve ocorrer só no commit da colheita entregue, nunca em toda limpeza. Capacidade recusada mantém cultura, tratamento, rega e `pending_harvest_rewards`; retry não rerrola nem duplica efeito. Golem conserva custódia antes de publicar lote vazio.
- Separar tratamento durável, umidade herdada disponível e rega atual. Plantio recusado não consome condição/seed; aceito utiliza o cálculo existente, sem recomeçar timer ou adicionar bônus. Flags propostas são booleanas, não objetos/rotas/timers.
- `FarmTileData`, Main (`_converter_farm_plot_para_tile_data`) e SaveManager (`_converter_farm_tile_para_plot_save_data`) hoje não conservam flags novas. Campos opcionais devem sobreviver inclusive no lote vazio, GRID v4 prioritário, vila cacheada e reabertura. Defaults completos v3/v4 antigos são solo comum; payload parcial preserva ausente; load substitui sem aplicar item ou entregar prêmio.
- Preflight puro antes de mudar região/recursos/lotes: recusar tipos/estados contraditórios, tratamento fora da célula piloto e umidade herdada incompatível. Não corrigir payload inválido silenciosamente. Um reset real de jogo novo começa comum; não preservar tratamento de outro snapshot.
- Main identifica ação por ferramenta/semente; preparo requer identidade e geração próprias para invalidar callback após troca de seleção/Escape/load/viagem. Commit revalida contexto, alvo e saldo; consumo pessoal síncrono sem retirada remota do Storage. Fabricação mantém baú prioritário, complemento pessoal, resultado na Mochila e recibos/refund existentes.
- Representação provisória discreta no estrato do chão, sem cobrir avatar/golem, mudar hitbox ou roubar clique. Estado também explicado em tooltip/feedback; não apenas cor. Sem paleta/arte final produzida nesta fase.

### Sequência e portões

1. **Fase A — baseline/plano:** concluída documentalmente; confirmar o conjunto proposto acima antes de codificar essas regras.
2. **Fase B — domínio/receita:** após confirmação, implementação pequena da aplicação/ciclo, catálogo/Resource/eligibilidade e testes unitários; sem reescrita de cultivo, economia, calendário ou IA.
3. **Fase C — persistência:** bridge/grid/save, preflight completo/legado/parcial/replay/cache e reabertura em novo processo; não confundir JSON em memória com save integrado.
4. **Fase D — interação/apresentação:** seleção transitória, aproximação, cancelamento/modal e feedback do lote; ferramentas/baú/caldeirão/pesca sem regressão.
5. **Fase E — fechamento:** regressão proporcional/integrada, reaberturas no exportador, pacote auditado e novos casos de checklist; conservar os 36 anteriores palavra por palavra.

QA futuro cobre vários ciclos, primeira rega, reaplicação/recusa, colheita bloqueada/retry, golem, outro cultivo, morte/limpeza, callbacks obsoletos, modais, outros lotes/agricultura livre inalterados, v3/v4/GRID prioritário/parcial/payload inválido, viagem/cache e reabertura. Execuções somente em QA isolado; não acessar/editar save pessoal ou aumentar timers no jogo real para fabricar valor. Arte, picking físico, conforto e balanceamento continuam para observação manual posterior, sem exigir teste imediato. Não houve execução de jogo/suíte/build nesta A.

## Vila em Reconstrução — Poço da Vila, piloto aprovado (2026-10-04)

Autor aprovou um recorte opcional: poço físico funcional antes/depois da melhoria, projeto disponível após a Clareira restaurada. Custo **8 trigos + 1 mistura restauradora**, com Village Storage prioritário e complemento da Mochila. Benefício **capacidade 10 → 20**, sem encher a reserva instantaneamente, acelerar regeneração ou implementar tempo offline. Capacidade legada acima de 20 é preservada.

A habilidade existente `skill_agua` continua como caminho alternativo de **1 ponto de alquimia** para o mesmo benefício, sem exigir Clareira. Não acumular capacidade nem cobrar materiais/ponto novamente de quem já tem capacidade 20 ou maior. Projeto não concede XP/habilidade; habilidade não marca projeto pago. Fora: loja, moeda, NPC, mapas, estações, mastery, outras melhorias e infraestrutura genérica de aquisição.

### Ordem de execução aprovada

1. **Incremento 1 — contratos/persistência:** custo, fontes, elegibilidade, cobrança única, compatibilidade e testes isolados; sem objeto novo no mapa.
2. **Incremento 2 — objeto físico/integração:** localização livre de cultivo/trilhas, aproximação real, clique/picking e painel compacto opaco; apresentar reserva/capacidade/projeto sem HUD permanente extra ou F10. Preservar baú/caldeirão/ferramentas/navegação.
3. **Incremento 3 — fechamento:** regressão integrada, reaberturas no exportador, pacote auditado e checklist ampliado mantendo as 30 pendências anteriores.

### Incremento 1 — concluído tecnicamente

VillageWellState concentra constantes e preflight puro; EconomyManager mantém capacidade/flag e duas APIs de aquisição. Consulta não gasta; projeto exige vila ativa e baú live, recusando consumo remoto no Bosque/cache/transição. VillageResourceAccess valida o custo integral, consome baú primeiro e conserva origens em rollback. Guardas recusam reentrada, habilidade e save/load durante consumo incompleto; sinal só depois do estado consistente. SkillTree usa a mesma regra, desabilitando cobrança de benefício já obtido.

Save v4 recebe campo opcional `poco.melhoria_projeto`. Snapshot completo antigo v3/v4 sem flag assume false; parcial conserva estado ausente. Projeto e habilidade derivam capacidade mínima 20, sem reduzir valores maiores ou conceder água/XP/itens no load. Projeto true exige Clareira restaurada no snapshot recebido. Tipos/quantidades inválidos são recusados antes de mudar região/recursos; escritor também recusa estado contraditório preservando arquivo anterior. Aplicação substitui estado, replay não cobra/concede de novo. Excesso de água legado é preservado.

Importação sem erros, suíte **53/53** em APPDATA isolado. VillageWellProgressSmokeTest: **89 verificações** de custos, origens, elegibilidade, alternativas, capacidade legada, rollback/reentrada sintéticos, JSON/replay/legado, preflight e arquivo protegido, viagem/cache/save externo. Regeneração usa delta explícito de QA e a regra existente, não medição de tempo real/offline. Dois processos adicionais reabrem projeto e habilidade (**8 + 8**); preparação do save de habilidade (**2**) é fixture, não reabertura. Também passaram as quatro reaberturas anteriores (**6 + 3 + 8 + 8**) e fixture de replantio (**2**).

Save pessoal idêntico por hash/tamanho/data, arquivos alheios preservados fora do commit. **Sem objeto físico ou nova exportação neste incremento**: SustainableFarm-20261004 permanece o pacote anterior, sem estes contratos. Os **30 casos manuais continuam pendentes**, sem exigir teste imediato nem presumir aprovação. Próximo incremento 2 está dentro do recorte aprovado; validação de clique/proximidade/arte ainda não foi realizada para o poço.

### Incremento 2 — objeto físico e integração (2026-10-04)

VillageWell em `(540, 280)`, acima do limite agrícola e fora dos lotes/trilhas atuais. Formas nativas de pedra/madeira/água seguem a cenografia existente, sem depender de arte local ou canonizar lore; melhoria muda cobertura, água/banda e pequenos detalhes. Área clicável separada do corpo físico e NavigationObstacle2D. Política de solo reconhece construção; não criar/relocalizar culturas, origem, lago ou caminho.

Clique reutiliza Main.request_player_interaction: distância segura considera obstáculo + raio do jogador, destino fora do corpo e callback só ao chegar. Abrir/confirmar revalidam vila ativa, transição/load e proximidade real. Ferramenta permanece selecionada. Painel opaco de 420 pixels, arrastável, contido nas resoluções testadas; água/capacidade, orientação de reserva não slotada, custo por ícone/quantidade, bloqueio/falta/pronto/concluído e confirmação explícita. Sem retirada de água, nova HUD, F10 ou nova habilidade. Benefício antigo/legado mostra concluído sem materiais cobrados.

Shield local e consulta modal existente bloqueiam cliques de fundo/cultivo/movimento; atalhos de ferramentas da UI não mudam seleção enquanto aberto. Escape/Fechar liberam contexto. Transição, saída/cache, distância perdida e load bem-sucedido fecham painel; callback antigo não pode consumir fora da vila ou após fechamento. Resize fora da árvore ignora layout, retorno reposiciona sem erro; centralização inicial aguarda containers, refresh preserva arraste. Custos/schema/regeneração do incremento 1 inalterados.

VillageWellPhysicalSmokeTest: **104 verificações** em headless/OpenGL, aproximação real do PlayerAvatar, evento do collider, arbitragem antes do picking com enxada, confirmação via eventos GUI, recursos combinados/duplicação, alternativa antiga, baú/caldeirão/aragem depois do painel, Escape, load/cache/retorno e geometria opaca em 800×600/800×720/1280×720. **Não é clique físico do autor/end-to-end de cursor:** canvas é alinhado ao cursor existente só no fixture, com limites da câmera temporariamente liberados para janela oculta e depois restaurados. Teste inicial de push_input não atualizava a posição física; corrigir fixture, não navegação para satisfazê-lo. Outra reabertura em processo separado (**4 verificações**) restaura visual/benefício/água/estoques sem cobrança. Capturas de bloqueio/pronto/concluído inspecionadas.

Suíte **54/54**, sete reaberturas (**6 + 3 + 8 + 8 + 4 + 8 + 8**) e dois fixtures adicionais (**2 + 2**) em QA isolado. Save pessoal idêntico por hash/tamanho/data. Incrementos 1–2 concluídos tecnicamente, sem homologar arte/conforto/posição ou gameplay manual. Nenhuma nova exportação; SustainableFarm-20261004 continua anterior. Os **30 casos manuais** permanecem; próximo incremento 3 integra reaberturas no exportador, pacote auditado e casos do Poço sem apagar os anteriores.

### Incremento 3 — fechamento técnico (2026-10-04)

Incrementos **1–3 concluídos tecnicamente**, sem ampliar gameplay/schema neste fechamento. Exportador executa reabertura física (4), projeto (8), fixture da habilidade (2) e reabertura da habilidade (8) imediatamente após suas cenas, antes de outra sobrescrever o arquivo QA. Preserva as quatro reaberturas anteriores e fixture do ciclo; exige PASS com contagem específica, separando sete reaberturas e dois fixtures no manifesto.

Fonte `03e209d` em checkout limpo gerou **`Builds/Playtest/VillageWell-20261004`**: suíte **54/54**, sete reaberturas (6 + 3 + 8 + 8 + 4 + 8 + 8), dois fixtures (2 + 2), startups headless/OpenGL e auditoria isolada do PCK aprovados. Primeira execução interrompida antes da entrega foi refeita integralmente. Auditoria confere cenas/scripts do Poço, constantes de custo/benefício/alternativa, preflight de projeto/marco/legado e instância/posição na Main, sem instanciar objetos/conceder progresso. Build anterior sem Poço é corretamente recusada; raiz da auditoria é a pasta do pacote, não o workspace.

Manifesto/hashes/logs/instruções e checklist acompanham EXE/PCK/StartPlaytest.cmd. **36 casos manuais pendentes**: 30 anteriores intactos + WL-01–WL-06. Save separado não copia/apaga progresso pessoal ou playtest anterior; save pessoal idêntico por hash/tamanho/data. Checkout temporário removido e arte local/builds anteriores preservadas fora do Git. Não presumir aceite de picking/posição/arte/conforto/ritmo/balanceamento nem exigir teste imediato. Próxima construção requer novo recorte delimitado e aprovação; sistemas reservados permanecem fora.

## Ciclo Sustentável da Fazenda — recorte aprovado (2026-10-03)

Autor aprovou duas receitas determinísticas para repor trigo pelo caldeirão: **1 carvão + 1 água → 1 Semente de Trigo**, e **2 trigos → 3 Sementes de Trigo**. Baseline de leitura confirmou 10 sementes iniciais, retorno aleatório de 20% na Primavera e ausência de receita com resultado semente_basica; risco de esgotamento, não bloqueio reproduzido no save pessoal. Não mudar o bônus de colheita, estoque inicial, estações ou semeador.

### Contratos e limites

- Recuperação independe de trigo, semente prévia, restauração, moeda e RNG. Usa carvão dos caminhos existentes do Bosque e água da reserva regenerável do poço. Não alterar renovação nem implementar tempo offline. Acesso ao Livro desde o início evita exigir experimentação com água, que não aparece na grade da Mochila.
- Replantio reinveste dois trigos em três sementes; preserva outra utilização da colheita. Quantidades são as aprovadas, tempo de piloto de 2 segundos por craft (contrato usual de RecipeData), nomes funcionais sem lore definitiva. Ambas disponíveis por padrão, sem pontos de alquimia/recompensa nova ao abrir ou produzir.
- Reutilizar RecipeData/Resolver, produção manual/lote e reservas por origem. Baú prioritário, complemento pessoal, água continua fora dos slots. Sementes produzidas chegam à Mochila; jogador deposita para o golem. Nenhuma entrega automática ao baú, produção pelo golem ou alteração do cargo/scheduler.
- Capacidade insuficiente preserva resultado/reservas no caldeirão. Cancelamento devolve somente crafts não entregues às origens. Save/load substitui o snapshot existente sem novo consumo/refund; não alterar schema para duas receitas declarativas.
- Fora: lojas, moeda/venda, NPCs, mapas/culturas novos, mastery, aragem automática, sazonalidade/tempo real e framework de aquisição. Este recorte não resolve os sistemas futuros nem homologa balanceamento/experiência.

### Ordem de execução

1. **Incremento 1 — contratos/receitas:** adicionar dois Resources, testar disponibilidade sem marco/RNG, quantidades, ingrediente duplicado, produção manual/Livro/lote, origens/refund, recusa/capacidade e reconstrução JSON. Registrar decisão e publicar checkpoint.
2. **Incremento 2 — orientação/integração:** comunicação discreta de como repor/depositar sementes, testar recuperação a partir dos recursos realmente acessíveis, consumo/plantio manual e ciclo físico com golem, save/load/viagem. Sem HUD extra ou alterar automação.
3. **Incremento 3 — fechamento:** regressões, pacote novo auditado, ampliar checklist sem apagar os 24 casos existentes; aceite manual adiado. Build anterior permanece histórica.

Estado: **incrementos 1–3 concluídos tecnicamente**; aceite manual adiado. Checkpoint do incremento 1: importação sem erros, suíte 51/51 e 86 verificações do SustainableSeedsSmokeTest em QA isolado. Testados disponibilidade padrão sem XP, ingredientes duplicados, produção manual, seleção/quantidade/botão do Livro, lote, reservas por origem, cancelamento parcial, recusa por recursos, capacidade sem entrega parcial, reconstrução JSON em nova instância e timer real de 2 segundos.

### Incremento 2 — orientação e ciclo integrado

Orientação no Livro, tooltips da Mochila/baú e estado sem sementes do golem; transferência de trigo distingue Mochila para plantio manual e baú para semeador, nas duas direções. Demais sementes continuam pessoais para plantio manual. Nenhum painel/HUD/toggle novo ou ativação automática. Livro usa o nome canônico Semente de Trigo para este resultado; descrições curtas mantêm Produzir visível na captura, com rolagem existente para telas menores.

SustainableFarmCycleSmokeTest: **77 verificações**. Começa sem trigo/sementes/marco, caminha ao Bosque e coleta três carvões nas fontes existentes, retorna, salva/carrega recursos, regenera água pelo poço, produz duas sementes pelo Livro, ara/planta/rega/colhe dois lotes com timers reais e reinveste dois trigos em três sementes. Bônus aleatórios não são requisito; XP dos eventos de colheita é preservado, receitas não concedem XP. Clareira restaurada é pré-condição explícita de fixture para integrar o golem, não prêmio das receitas nem restauração efetuada neste teste. Toggle explícito, depósito de três via quantidade do baú, retirada física de uma, pausa/viagem/save externo/replay e retomada de caminho/plantio sem duplicação ou consumo pessoal.

Arquivo QA final preserva recuperação em produção; outro processo carrega/recarrega e entrega exatamente uma vez (**8 verificações**). Fixture separado de replantio em produção com trigo de duas origens (**2 verificações**) e outra reabertura (**8 verificações**) conferem três sementes, estoques e XP. Suíte **52/52**; retestes finais de contrato/receitas (86), layout do Livro (141), ciclo e reaberturas após encurtar os textos. Golem UI passou em OpenGL (325) e reabertura específica (3); persistência existente/reabertura (6) também passou. Capturas OpenGL de Livro, depósito/retirada e painel sem estoque inspecionadas. Técnica, não aceite manual ou balanceamento.

Estado ao fim do incremento 2: save pessoal idêntico por hash/tamanho/data; ainda sem nova exportação, com 24 casos manuais pendentes. GolemSower-20261003 não contém estas receitas/orientações. Fechamento posterior abaixo não altera os contratos ou amplia sistemas reservados.

### Incremento 3 — fechamento técnico (2026-10-04)

Fonte `8a1bc4a` exportada em checkout limpo para `Builds/Playtest/SustainableFarm-20261004`. Suíte **52/52**, reaberturas imediatas do golem (6 + 3) e de recuperação/replantio (8 + 8) em processos separados; preparação de arquivo de replantio (2) registrada como um fixture adicional, não quinta reabertura. Importação/validação, EXE headless/OpenGL e auditoria do PCK passaram. Manifesto registra commit capturado, hashes, 52 regressões, quatro reaberturas, um fixture e 30 casos manuais pendentes.

Auditoria usa a pasta de saída como raiz, sem mascarar recursos ausentes por arquivos do workspace; controle negativo com GolemSower-20261003 recusa a receita ausente. No PCK novo confere ingredientes, resultado, disponibilidade padrão, tempo de dois segundos e XP zero. Commit capturado antes da criação do checkout também identifica o manifesto, mesmo se HEAD mudar durante a exportação. Primeira passagem gerou SustainableFarm-20261003 antes destas proteções: pacote preliminar marcado como substituído, identificação de fonte corrigida para `66b9d4b`; não é a entrega definitiva.

Checklist conserva os 24 casos anteriores integralmente e adiciona SC-01–SC-06. Aceite manual/arte/conforto/ritmo/balanceamento continuam adiados; não exigir teste imediato nem considerar todo o jogo finalizado. Save pessoal idêntico por hash/tamanho/data e pacotes anteriores preservados; build separada não copia/apaga saves. Nenhuma mudança de gameplay/schema/economia/NPC/mapa/mastery. Próximo recorte de construção requer proposta delimitada e aprovação antes de implementar sistemas reservados.

<a id="golem-semeador--piloto-aprovado-fase-d-concluída-2026-10-03"></a>
<a id="golem-semeador--piloto-aprovado-fase-e-concluída-2026-10-03"></a>

## Golem Semeador — fechamento técnico A–F concluído (2026-10-03)

Esta seção é o plano operacional atual do piloto, não uma migração de Farm System V2. As seções seguintes conservam o histórico/direções do sistema. Fases A–F concluídas tecnicamente: contratos, domínio, persistência, trabalho físico, controle no painel existente e pacote de playtest auditado. Clareira restaurada libera a opção, sempre OFF por padrão/legado; só o jogador a ativa. Aceite manual e conforto permanecem pendentes. Âncoras antigas preservadas para links de checkpoints anteriores; aprovação do recorte não significa aprovação manual da implementação.

### Recorte fechado

- Reutilizar o golem físico existente, sem criar outra entidade. Plantio opcional, desligado por padrão.
- Habilidade disponível quando `GroveExpedition.restored` for true; derivar do marco já persistido, sem RNG, segunda recompensa ou árvore de skills nova. Saves antigos restaurados ficam elegíveis, mas nunca ativados automaticamente.
- Um canteiro fixo de quatro lotes iniciais: células `(0,0)`, `(1,0)`, `(0,1)`, `(1,1)`, resolvidas pelo registro de Main. Somente `semente_basica` (trigo); respeitar a estação atual, aragem, ocupação, visibilidade e bloqueio. Não criar/arar lotes ou limpar culturas existentes.
- Sementes são obtidas pelos caminhos atuais do caldeirão, depositadas pelo jogador no Village Storage e retiradas fisicamente pelo golem. Nunca complementar com Mochila, gerar sementes ou plantar enquanto está no Bosque.
- UI no painel existente do golem. Preservar prioridades atuais: semear é fallback dos modos mistos, depois da colheita/rega já elegíveis. Só colher, Só regar e Pausado não iniciam semeadura. Regar continua dependente do talento existente.
- Fora: novas regiões/culturas, economia/NPCs/lore definitiva, mastery, aragem automática, novas regras de rega, seleção livre de territórios, múltiplos golems e rede de baús.

### Baseline da Fase A e riscos confirmados por leitura

| Evidência atual | Consequência para o piloto |
| --- | --- |
| FarmPlot._on_plot_clicked lê a seleção da Mochila, altera `semente_atual` e remove o item antes de configurar o cultivo. | Extrair validação/commit comum sem dependência da seleção para o golem; recusa deve preservar inclusive metadados do lote. |
| VillageChest.withdraw_item já permite retirada síncrona exclusiva; VillageResourceAccess.consume complementa na Mochila. | Reutilizar retirada do baú, não o consumo agregado atual. Nenhuma mudança global em caldeirão/purificação. |
| Golem.carried_rewards é carga runtime de colheita; SaveManager não a inclui no snapshot. | Carga semeadora exige custódia e persistência próprias; integração também deve preservar/substituir corretamente carga de colheita ao carregar, para não misturar estados antigos com novo estoque. Ausência confirmada por leitura, não perda de save pessoal reproduzida. |
| Golem._chegar_ao_bau limpa carried_rewards mesmo com baú inválido. | Devolução de semente não pode reutilizar cegamente esse finalizador: baú inacessível mantém carga pendente. Não presumir aprovação de todos os extremos do fluxo legado. |
| Movimentação usa callback; colheita/depósito/rega aguardam SceneTreeTimer. Pausa limpa alvo/callback; cache remove a vila da árvore. | Usar geração/token de tarefa e invalidação em pausa/load/saída da árvore; callback antigo não pode consumir/depositar no novo snapshot. |
| Main.advance_inactive_time avança culturas e caldeirão, não deslocamento físico do golem. | Preservar essa regra: vila ausente congela trabalho físico; retomar ao voltar, sem plantar por cálculo de tempo/teleporte. |

Esses pontos são requisitos de integração; não constituem auditoria exaustiva nem regressões reproduzidas de todos os fluxos. Baseline novo: GolemLifeSmokeTest, SaveContractSmokeTest e RegionTravelSmokeTest passaram em APPDATA isolado. Última suíte completa permanece 46/46 do checkpoint anterior; não foi repetida nesta fase documental.

### Contrato de custódia e commit

Para cada semente retirada, exatamente um destino lógico: **baú → carga de plantio → cultivo**, ou **carga → baú** em devolução. Estar disponível no alvo não equivale a já ter consumido. Colheita tem carga separada; não iniciar semeadura com entrega de colheita pendente.

| Estado lógico | Quem possui a semente | Regra de saída |
| --- | --- | --- |
| Procurar alvo / ir ao baú | Baú | Ao chegar, revalidar alvo e saldo; retirada de uma unidade e instalação da carga no mesmo trecho síncrono. |
| Carregar / ir ao lote | Golem | Não retirar segunda unidade nem iniciar colheita; revalidar temporada/alvo ao chegar. |
| Plantar | Golem até commit | Commit síncrono, sem await: validar, consumir a carga, instalar cultura e só então publicar sinais. Recusa não modifica lote nem carga. |
| Devolução pendente | Golem | Desativação, mudança de estação ou alvo ocupado levam à devolução física; se não houver caminho/baú válido, preservar e informar. |
| Pausado / vila inativa | Mesmo dono anterior | Congelar tarefa, invalidar callbacks e manter carga; não devolver remotamente. Retomar com rota nova. |

Não reservar estoque durante o trajeto até o baú; o jogador/caldeirão podem consumir antes da chegada. Lote não fica bloqueado ao jogador enquanto golem caminha: se alguém plantar primeiro, golem não sobrescreve nem consome a semente. Chegada exige proximidade real, não apenas NavigationAgent.is_navigation_finished. Referências de lote/baú são revalidadas; falha de navegação nunca destrói carga.

### Contrato de snapshot/load

- Proposta mínima: bloco opcional `golem_work` com versão interna 1, opção de semeadura, prioridade válida, carga de colheita e carga de plantio ausente ou contendo `semente_basica`, quantidade inteira 1, célula alvo e intenção transportar/devolver. Não persistir Callable, Node, NodePath de instância ou rota do NavigationAgent. Nomes finais podem ser ajustados na implementação, sem mudar estes invariantes.
- Células são identidade lógica por coordenadas, não posição mundial/ordem de nós. Alvo só pode pertencer ao canteiro fixo. Carga de colheita e de plantio não podem coexistir no piloto. Quantidades/IDs/tipos/flags/estados incompatíveis são recusados antes de mutações.
- Manter compatibilidade v3/v4 com campo aditivo: ausência significa semeadura desligada e sem carga persistida. A elegibilidade vem de restored, não do flag de ativação. Não inventar sementes/carga que o save antigo não registrou.
- Preflight completo antes de mudar região, baú, culturas, progresso ou golem, usando o marco do snapshot recebido, não o progresso atual da sessão. Aplicação substitui o estado antigo, não faz refund sobre o novo estoque. Invalidar timers/callbacks anteriores; reconstruir destino com registro da vila e rota nova. Load repetido aplica o mesmo snapshot, sem recompensa/retirada/plantio extra.
- Save na região externa consulta a vila cacheada, incluindo sua carga congelada. Load mantém retorno à vila já existente. Nenhuma simulação offline de transporte/semeadura.
- Persistência deve estar funcional antes de habilitar qualquer retirada viva do baú. Não publicar piloto que apenas preserve carga durante a sessão.

### Ordem mínima de execução

1. **Fase B — domínio:** extrair validação/commit comum de plantio manual + por fonte explícita; testes de recusa sem mutação, estação, bloqueio, lote ocupado e consumo único. Criar contrato mínimo de carga/serialização, ainda sem scheduler vivo.
2. **Fase C — persistência:** preflight/snapshot/load do golem e cargas, legado sem ativação, replay, substituição sem refund e preservação da colheita existente. Fixtures somente em QA.
3. **Fase D — trabalho físico:** ir ao baú, retirar uma semente, caminhar/plantar/devolver; geração de tarefa, pausa, alvo concorrente, falha de caminho e cache/viagem. Reusar golem/navegação sem reestruturar a IA inteira.
4. **Fase E — progressão/UI:** habilitação pelo marco da Clareira, controle no painel existente e estados legíveis (bloqueado, sem sementes no baú, estação inadequada, terra não preparada, transportando, devolução pendente). Não criar HUD permanente extra ou reativar F10.
5. **Fase F — fechamento:** suíte completa, testes com timers/viagem/reabertura isolada, auditoria do PCK e nova build de playtest. Atualizar checklist sem transformar automático em aceite manual; commit/push em cada incremento.

### Portões e testes pendentes do piloto

- Conservação de sementes nas quatro fronteiras: antes/depois da retirada, antes/depois de plantar e antes/depois da devolução. Sucesso consome uma unidade; recusa conserva tudo. Mochila/seleção/ferramentas não mudam por automação.
- Player planta no alvo durante caminhada; estação muda; alvo desaparece/bloqueia; saldo esgota antes da retirada; baú some/caminho falha depois dela. Nenhuma cultura sobrescrita, carga perdida ou depósito repetido.
- Pausar/desativar/viagem/load durante movimento e espera; callbacks antigos não completam após retomada/load novo. Culturas/caldeirão mantêm sua regra de tempo durante ausência; golem não trabalha à distância.
- Save/load da carga de semente e de colheita, dois loads seguidos, save antigo sem bloco e payload inválido sem mutação. Marco já restaurado concede elegibilidade sem nova recompensa, com toggle OFF.
- Colheita/rega/prioridades/vida ociosa e fluxo manual continuam passando. Confirmar geometria/clicks no painel existente em 800×720 e 1280×720. Renderização técnica não aprova conforto.
- Manual futuro: ativar após Clareira, depositar sementes, arar o canteiro, observar retirada/transporte/plantio, interferir num alvo, pausar/retomar e salvar/reabrir. Sem apagar/editar save pessoal, artificialmente encher Mochila ou pedir teste imediato ao autor indisponível.

### Fase B — domínio comum e carga isolada

FarmPlot agora oferece consulta pura `validate_seed_planting` e duas entradas explícitas: `try_plant_from_personal_inventory` e `try_plant_from_golem_cargo`. Clique manual usa a primeira; mantém quatro culturas, estação, terra arada, rega, aceleração de verão e limpeza da última semente selecionada. Recusa não instala `semente_atual`, muda timer/solo/estoque ou publica sinal. Alvo bloqueado, invisível (inclusive ancestral), ocupado ou fora da árvore é recusado. Plantio pela carga confere a identidade do nó no registro vivo da Main, não a posição visual ou um ID fornecido pelo chamador.

Commit interno só usa os dois consumidores síncronos atuais, sem await/sinais: remover uma semente pessoal ou consumir a carga. Configura cultura/timer/visual antes de emitir `estado_alterado`; observadores e bridge já enxergam a fonte consumida. Não é uma API genérica para callbacks externos, nem consumo agregado de VillageResourceAccess. Metadados da cultura são cópia do catálogo.

`GolemSeedCargo` é domínio RefCounted sem rota/Node/Callable armazenados: retirada exclusiva de uma semente do VillageChest, alvo entre as quatro células, intenção transportar/devolver, consumo único e devolução explícita única. Baú ausente/fora da árvore/aguardando exclusão conserva carga. O chamador físico futuro é responsável por proximidade real, validação live do alvo e exclusão mútua com carga de colheita. Não há integração na IA nesta fase.

Serialização da carga ausente é `null`; presente contém exatamente `item_id`, `quantity: 1`, `target_cell: {x,y}` e `intent: transport|return`. Aceita números JSON integrais exatos, não bool/string/fração/coerção, IDs alheios ou células fora do piloto. Snapshot/aplicação fazem cópia profunda; aplicação válida substitui carga sem retirada/refund; payload inválido conserva o estado anterior. Esta é somente serialização de domínio: **SaveManager ainda não grava a carga** e o bloco `golem_work` continua para a Fase C.

Regressão `GolemSowerDomainSmokeTest`: 365 verificações de recusa sem mutação, quatro culturas/rega/verão, clique manual, conservação de fontes, quatro identidades do canteiro, jogador ocupando alvo, observadores consistentes, cópias/round-trip/replay e payloads inválidos/devolução única. Importação sem erros e suíte completa **47/47** em APPDATA de QA isolado; save pessoal idêntico por hash/tamanho/data. Sem alteração de Golem, SaveManager, desbloqueios, receitas ou UI; nenhuma retirada automática habilitada. Os 16 casos manuais anteriores e o playtest físico futuro continuam pendentes. Sem nova exportação nesta fase de domínio.

### Fase C — persistência e invalidação de tarefas

SaveManager registra `golem_work` na vila atual ou cacheada: versão interna 1, `seeding_enabled`, prioridade 0–4, `harvest_cargo` (totais por ID) e `seed_cargo` (contrato da B). Nenhuma rota/posição/Callable/nó ou string de tarefa é persistida. Golem reconstrói colheita em rewards mínimos, substitui carga de semente e fica IDLE para uma rota nova no próximo pensamento. Carga de semente restaurada permanece preservada sem plantar/devolver nesta fase; flag salvo não liga scheduler inexistente.

GolemWorkState prevalida tipos/IDs/quantidades, ausência de carga dupla, intenção de devolução quando OFF e marco da Clareira do **snapshot recebido**, não da sessão atual. Recusa ocorre antes de trocar região/estoques/progresso/golem; bloco exige golem físico disponível na HOME. Save com carga runtime inválida ou golem indisponível preserva o arquivo anterior. Durante aplicação, gravação/reentrada é recusada para não publicar snapshots intermediários de sinais de load.

Saves completos v3/v4 sem bloco limpam runtime sem refund, OFF e prioridade padrão, sem inventar carga antiga. Exceção explícita: payloads parciais de contrato sem inventário completo nem bloco não substituem o golem, preservando testes/bridges agrícolas já existentes. Construção de snapshot fora da vila física não inventa bloco; gravação normal exige HOME/golem. JSON de sementes é normalizado a inteiros após validação. Aplicação repetida substitui, sem retirar, depositar, premiar ou replantar.

Geração de tarefa protege callbacks de movimento e esperas de colheita/rega/depósito. Pausa, load, aborto e saída da árvore invalidam a geração, mantendo cargas. Vila em cache congela trabalho físico; tempo ausente ainda avança somente culturas/caldeirão. Colheita instala a carga antes de publicar lote vazio; depósito limpa carga antes do feedback, e baú inválido não descarta entrega. São proteções necessárias para snapshot consistente, sem reformular prioridades/rega/navegação inteira.

GolemWorkPersistenceSmokeTest: 148 verificações de preflight/recusa sem mutação, JSON, replay, v3/v4, substituição sem refund, carga de colheita, waits com mesmo estado após load, pausa/cache, save/load real em QA e nova instância da vila. Modo `--verify-sower-reopen` confirma seis verificações em outro processo sobre o arquivo QA anterior. Arquivos/saves pessoais nunca usados como fixture. Semeadura viva, proximidade real de chegada, falha de caminho, unlock e controle UI permanecem D/E; portões/manuais anteriores continuam pendentes.

Fechamento técnico da C: importação sem erros e suíte completa 48/48 em APPDATA de QA isolado, mais reabertura em processo separado. Save pessoal idêntico por hash/tamanho/data; arte local e UIDs auxiliares alheios não publicados. Sem nova exportação ou aprovação manual nesta fase.

### Fase D — trabalho físico e retomada da custódia

Golem procura um dos quatro lotes válidos do piloto como fallback dos modos mistos, depois de colheita/rega elegíveis. API `set_seeding_enabled` recusa ON sem o marco da Clareira e não tem botão nesta fase. OFF/legado continuam sem plantio automático. Não arar, consumir Mochila ou complementar por VillageResourceAccess; carga pendente precede outros trabalhos. Reutilizados entidade, registro de Main, NavigationAgent, desvio legado e tokens da C, sem reformular a IA da colheita/rega.

Ida ao baú não reserva estoque. Chegada revalida referência, alvo, estação e saldo; retira uma unidade do VillageChest e instala cargo síncrono. Aproximação sul a 48 pixels do centro evita mirar dentro do obstáculo. Caminhada da semente tem finalização própria com proximidade real até 14 pixels do destino, tolerância inicial para sincronização do NavigationAgent e aborto com carga preservada quando caminho vazio/termina longe ou ultrapassa 30 segundos. Não prometer que o navegador legado resolve todo obstáculo: falha mantém a custódia e permite nova tentativa. Ícone de semente acompanha o golem enquanto há carga, inclusive pausa/devolução.

Lote é revalidado após espera de plantio, com identidade no registro, proximidade, estação, terra arada, bloqueio, visibilidade e ocupação. Recusa vira devolução física, sem sobrescrever cultura do jogador. Pausado congela; OFF ou prioridade exclusiva converte carga em devolução pendente, sem refund remoto. Devolução só deposita perto do baú, após espera protegida pelo token; baú ausente durante trajeto/espera conserva cargo. Load/cache/aborto invalidam tarefa velha; retomada reconstrói rota do cargo persistido, sem retirar outra semente ou transportar fora da vila. Sinal de plantio que carrega outro snapshot não permite o finalizador antigo alterar a nova tarefa.

GolemSowerPhysicalSmokeTest: 107 verificações com navegação/timers reais, quatro células, célula extra recusada, estoque não reservado, saldo esgotado, bloqueio antes da retirada, jogador plantando primeiro, estação/visibilidade, callback distante, caminho impossível, baú ausente e durante depósito, pausa/ON-OFF/prioridade exclusiva, timers obsoletos, JSON/replay/rota pós-load, save QA externo/cache/retorno e precedência de colheita/rega. Inclui scheduler recorrente com quatro sementes/quatro culturas a 128 pixels/s; apenas relógio QA acelerado e crescimento longo no fixture. Fixture preserva o comportamento existente de seleção da Enxada (que limpa a seleção de sementes); isso não é alteração da automação. Warning de caminho impossível é intencional no fixture.

Fechamento técnico: importação sem erros e suíte completa 49/49 em QA isolado, seguida de reteste físico ampliado e persistência/reabertura em processos separados. Save pessoal idêntico por hash/tamanho/data; arte local e UIDs auxiliares alheios excluídos da publicação. Não equiparar automático a aceite manual.

### Fase E — disponibilidade e controle no painel existente

Opção `Semear trigo` no GolemPanel já existente; bloqueada enquanto GroveExpedition.restored for false. Reutiliza API física da D e bloco de save da C, sem novo talento/recompensa/RNG. Restaurar a Clareira só libera o controle, não ativa; save antigo elegível continua OFF. Reconciliador de receitas da Clareira mantém exatamente suas recompensas anteriores; não atribuir isso ao semeador. Atualização/load usa set_pressed_no_signal, evitando ligar/desligar tarefas ou emitir toggle só por abrir/atualizar o painel. OFF com cargo mostra pausa/devolução preservada, sem refund remoto.

Consulta pura get_seeding_status informa bloqueio, OFF, modo exclusivo/pausa, estação, terra não arada, canteiro ocupado/indisponível, baú ausente/sem sementes, pronto, outros trabalhos, busca/transporte/plantio e devolução pendente/em curso. Lê validação live das quatro células e estoque exclusivo do baú; não reserva/consome recursos nem altera golem/lotes/progresso. Falta de talento de rega não mascara semeadura dos modos mistos. Prioridades e irrigação permanecem as mesmas; tooltip diferencia modos mistos de Só regar.

Panel local de 440 pixels com fundo opaco, quebra de texto/botões, tamanho contido e posição arrastada preservada em atualização/resize/cache. Mantém caminhos e controles existentes; oculta os três diagnósticos redundantes (alvo/última ação/contagens) e não repete tarefa enquanto o estado da carga já a explica. Sem HUD extra, F10 ou novo sistema de janelas. Geometria validada em 800×600, 800×720 e 1280×720; não prometer layout universal abaixo dessas janelas ou conforto/picking manual aprovado.

GolemSowerUISmokeTest: 325 verificações de clique no toggle, marco/OFF, recompensas existentes, estados/consulta sem mutação, conflito de prioridade/talento, OFF com cargo, JSON/replay/legado, abertura/fechamento/input, fundo opaco/controles nas três resoluções, recálculo preservando arraste e cache/resize após Bosque. Modo de reabertura confirma três verificações em outro processo a partir de arquivo QA. Importação sem erros, suíte completa 50/50 e inspeção OpenGL; save pessoal idêntico por hash/tamanho/data. Renderização técnica não substitui aceite do autor.

**Fases A–E implementadas; F pendente.** Próximo incremento: auditoria do pacote, nova build de playtest com save separado e checklist consolidado do semeador, preservando os 16 casos manuais anteriores. Não exportado nesta fase de UI; manual anterior e observação/conforto do semeador continuam adiados, sem exigir teste imediato.

### Fase F — fechamento técnico e playtest isolado

Fonte da build: `226bb72`, exportada de checkout limpo em `Builds/Playtest/GolemSower-20261003`. EXE/PCK, StartPlaytest.cmd, LEIA-ME.txt, CHECKLIST.md, manifesto/hashes e logs ficam locais, fora do Git. O pacote anterior PostV0-20261003 foi preservado. Transformação exclusivamente de exportação usa `%APPDATA%/CauldronCropsPlaytest`; não copia/carrega o save pessoal. Builds de playtest compartilham esse ambiente separado: progresso de playtest anterior não é apagado. As verificações automáticas usam ainda outro APPDATA, dentro de Builds/QA do checkout temporário.

Importação/validação sem erros, suíte limpa **50/50**, incluindo domínio 365, persistência 148, trabalho físico 107 e UI 325 verificações. Reabertura executada imediatamente após cada fixture em dois novos processos: persistência 6 e UI 3 verificações, sem outro teste substituir o arquivo entre execução e reabertura. Timers, concorrência, pausa/load, viagem/cache e retomada física cobertos pelos testes; não equivalem a sessão real aprovada.

Startup do EXE passou headless e OpenGL com janela oculta/120 frames. Auditoria do PCK confirmou save separado, cenas/receita necessárias, scripts de cargo/snapshot/painel e ícone de semente; recusou inclusão de testes, docs/tools/Builds/.git e savegame. Manifesto registra fonte, hashes, 50 regressões, dois processos, auditoria/startups e `manual_status: pending`. Save pessoal idêntico por hash/tamanho/data. Checkout temporário removido, arte local/UIDs alheios preservados fora dos commits.

Checklist integrado mantém **16 casos anteriores + GS-01–GS-08 = 24 pendentes**, com aceites anteriores preservados e pré-condições condicionais. Sem exigir teste imediato, editar saves ou reativar F10. Nesta F somente ferramentas de QA/exportação e documentação mudaram; sem novos sistemas/gameplay/schema. Próximo portão de experiência é o checklist quando o autor puder; continuidade de construção pode começar por proposta delimitada do próximo conteúdo, sem implementar economia/NPCs/mapas automaticamente ou presumir aceite deste piloto.

## Visão Geral

O sistema atual de lotes fixos é funcional para o protótipo e continua sendo a base jogável enquanto a fazenda evolui.  
A direção final, porém, é sair de um conjunto fechado de pontos de plantio e caminhar para uma fazenda mais livre, construída sobre tiles/grid.

Essa evolução não é só visual. A intenção é que a fazenda passe a ser um espaço vivo, transformado pela alquimia, pelo clima e pelos sistemas que orbitam o caldeirão.

Nesta documentação, as seções de design descrevem o alvo do sistema; as seções de FarmTile, FarmGridManager, preview e checkpoint registram o estado atual já validado do laboratório.

### Estado atual da Fase 2 técnica

- O `Main` espelha os `FarmPlot` vivos em `FarmGridManager` como snapshot runtime-only.
- O golem físico lê esse snapshot para escolher alvos reais.
- O `SaveManager` já persiste e restaura `farm_grid`.
- `FarmPlot` segue como fonte de verdade runtime enquanto a migração definitiva não é aprovada.

### Colheita recusada por capacidade — fechamento integrado, 2026-10-01

Quando uma colheita não cabe na Mochila, seus itens e bônus já sorteados permanecem no lote. O campo opcional `pending_harvest_rewards` guarda apenas totais por ID no plot e no tile espelhado. O sorteio notifica o bridge imediatamente, e o save v4 persiste a pendência dentro de `farm_grid`; a representação legada também pode transportá-la.

Load restaura os mesmos itens, sem executar RNG novamente. Colheita manual ou golem conclui uma única vez e limpa a pendência. Somente cultura pronta pode carregar recompensas pendentes; formato/quantidades inválidos são recusados antes de alterar o estado global. Feedback é reconstruído, sem persistir cores, offsets ou objetos de UI. Saves antigos sem o campo preservam a cultura, mas não permitem recuperar um sorteio que não foi salvo.

`HarvestPersistenceSmokeTest` valida JSON em memória com cena recriada, retomada manual/golem, raridades, duplicação, compatibilidade e rejeição sem mutação. Suíte de 34 testes aprovada; teste manual integrado ainda pendente. Consultar Decisão 95.

## Objetivo de Design

O jogador deve poder escolher onde arar, organizar sua própria fazenda e moldar o terreno aos poucos.

O foco não é apenas plantar crops.  
O foco é transformar o solo com alquimia, fazendo a fazenda reagir a escolhas, estações, receitas e ferramentas.

## Solo Vivo Alquímico

O centro da ideia é o conceito de Solo Vivo Alquímico.

O solo pode existir em estados e tipos especiais, como:

- Solo Comum
- Solo Encantado
- Solo Sombrio
- Solo Gelado
- Solo Flamejante
- Solo Lunar
- Solo Instável

Cada tipo de solo pode afetar:

- velocidade de crescimento;
- chance de mutação;
- crops permitidas;
- chance de drops raros;
- consumo de água;
- interação com estação;
- interação com golems;
- receitas.

## Limites Suaves

O jogo deve evitar limites duros demais.

O que evitar agora:

- stamina muito curta;
- limite diário rígido de arar;
- punição agressiva por ausência;
- destruir crops demais em tempo real.

O que priorizar:

- qualidade do solo;
- estabilidade mágica;
- alcance do poço;
- capacidade dos golems;
- necessidade de essências alquímicas;
- biomas;
- estação;
- manutenção suave.

## Integração com o Caldeirão

O caldeirão continua sendo o centro da transformação.

Na visão final, ele cria essências e modificadores de solo, como:

- Essência Gelada
- Essência Flamejante
- Pó Lunar
- Fertilizante Sombrio
- Catalisador de Mutação
- Conservante Alquímico

Esses itens podem transformar tiles da fazenda e abrir espaço para novas rotas de progressão.

## Integração com Pesca

A pesca não deve ficar isolada.

Peixes e itens aquáticos podem alimentar outros sistemas, gerando ingredientes para:

- poções;
- iscas;
- fertilizantes;
- essências de solo;
- receitas sazonais;
- alimentos de animais e fazendinhas.

## Integração com Fazendinhas e Animais

Fazendinhas e animais também devem participar do ciclo principal.

Exemplos:

- crops alimentam animais;
- animais produzem ingredientes;
- ingredientes voltam para o caldeirão;
- o caldeirão cria melhorias de solo;
- o solo melhor gera crops especiais.

## Integração com Golems

Na visão final, golems podem trabalhar por área ou função.

Papéis previstos:

- Golem Coletor
- Golem Regador
- Golem de Solo
- Golem Pescador
- Golem Pastor
- Golem Guardião

Esses papéis evoluem com a árvore de alquimia.

## FarmTile

Estrutura atual para representar cada tile da fazenda:

- posição no grid;
- estado do tile;
- tipo de solo;
- crop atual;
- umidade;
- estabilidade mágica;
- modificadores ativos;
- estação favorecida;
- ocupante ou estrutura;
- tempo restante;
- dados de save.

Base técnica inicial:

- `Scripts/data/FarmTileData.gd`
- recurso isolado para representar um tile do grid
- já é usado como contrato de leitura no gameplay e na persistência, mas ainda não substitui `FarmPlot` como autoridade total
- já serve como fundação para o grid e para o save

## FarmGridManager

Gerenciador isolado para controlar a fazenda baseada em grid:

- controlar tiles;
- permitir arar;
- permitir plantar;
- aplicar essências;
- salvar e carregar o grid;
- informar golems;
- validar áreas bloqueadas;
- lidar com expansão da fazenda.

Base técnica inicial:

- `Scripts/data/FarmGridManager.gd`
- gerenciador isolado de dados
- já serve como contrato de leitura para um consumidor real do gameplay (o golem) e para a persistência do save; o `Main` ainda o mantém como snapshot runtime-only espelhado dos plots vivos
- preparado para conversar com `FarmTileData` e já expõe criação, consulta, substituição, remoção e save/load em memória

Teste manual isolado:

- `Scripts/dev/FarmGridManagerSmokeTest.gd`
- valida criação, consulta, remoção, recriação e save/load em memória
- não é gameplay
- não roda automaticamente

Ferramenta temporária no Debug Panel:

- botão `Testar FarmGrid`
- roda o smoke test em memória quando acionado
- serve apenas para desenvolvimento e validação manual
- não altera o `FarmPlot` atual nem o gameplay

Ferramenta Ativa V0 no jogo principal:

- `Scripts/ToolManager.gd`
- registrado como `Autoload`
- ferramentas visuais globais: `Enxada`, `Regador`, `Colheita`, `Vara de Pesca`
- seleção visual/global por botões e teclas `1`, `2`, `3`, `4`
- ainda não altera gameplay
- `FarmPlot` continua ativo
- `FarmGrid` continua isolado
- sementes continuam como itens do inventário e do plantio atual
- `Semente` continua apenas no `FarmGridPreview` como ferramenta fake de teste

Preview visual isolado:

- `Scenes/dev/FarmGridPreview.tscn`
- `Scripts/dev/FarmGridPreview.gd`
- mostra um grid 5x5 desenhado em memória
- testa ferramenta ativa simples, com `Enxada`, `Semente`, `Regador` e `Colheita` fake
- permite alternar estados de tile manualmente
- permite alternar tipos de solo alquimico com clique direito
- permite remover tile do grid com clique do meio
- permite simular crescimento fake em tiles plantados e irrigados com a tecla `G`
- simula o Decay Diario em memoria para limpar tiles arados ou molhados sem crop
- tiles plantados com crop fake nao voltam para grama no decay diario
- tiles plantados podem perder agua no decay diario sem deixar de estar plantados
- permite colher crop fake madura e devolver o tile para `ARADO`
- o crescimento fake usa `remaining_growth_time` e avanca apenas quando o tile esta molhado
- não substitui `FarmPlot`
- não salva no `SaveManager`
- não entra no gameplay principal

Enxada V0 no FarmPlot atual:

- a Enxada ganhou uma primeira ação real nos lotes atuais do jogo principal
- lote vazio pode ser preparado/arado com a ferramenta ativa
- o estado de preparo é salvo como `arado: bool` no `FarmPlot`
- sementes só plantam em lote arado, evitando plantio acidental em terra nao preparada
- isso ainda nao cria aragem livre e nao substitui o `FarmPlot`
- o `FarmGrid` continua isolado e o preview continua sendo o laboratorio visual dessa transicao

Area Preparavel V0:

- a cena principal continua usando `FarmPlot`, mas agora com area ampliada por lotes potenciais preinstanciados
- os 16 lotes originais foram preservados primeiro, na mesma ordem e posicao
- novos lotes foram adicionados no final da ordem, sem instanciacao livre por clique
- todos os lotes novos continuam iniciando com `arado = false`
- o save continua por indice e permanece compativel com saves antigos
- o visual de lote nao arado agora usa uma aparencia provisoria mais natural/esverdeada
- terra arada seca e molhada continuam usando as texturas adubadas ja existentes
- o visual continua provisório e sem novos assets

Decay Diario V0 no FarmPlot atual:

- o jogo principal agora pode simular manualmente a virada do dia via Debug Panel
- lotes vazios e arados voltam ao estado natural quando não há semente plantada
- lotes plantados ou prontos para colher nao sao afetados por esse decay manual
- ainda nao existe tempo real conectado a essa regra; a virada automatica segue sem integração temporal real

## Farm Expansion System - Purificacao da Fazenda (alvo de design):

- a fazenda final é fixa, média/grande e dividida em áreas reservadas
- a expansao nao sera infinita, procedural ou livre no escopo atual
- a progressao abre areas bloqueadas ou corrompidas por meio de alquimia
- o Obstáculo Mágico V0 já introduz uma Área Bloqueada V0 visível com pocket 2x2 de `FarmPlot` append-only
- cada area purificada pode liberar novos lotes, plantas, pesca, criaturas, ruinas ou receitas
- o caldeirao passa a ser o centro da purificacao narrativa e mecanica
- pesca e Catálogo de Itens ja preparam esse eixo com recursos e metadados para desbloqueios
- a implementação completa fica para depois; o Obstáculo Mágico V0 já existe como primeiro teste prático
- ele usa `pocao_purificadora_fraca` e save mínimo de purificação

Colheita V0 por ferramenta no FarmPlot atual:

- a ferramenta `Colheita` do jogo principal agora reaproveita a colheita manual do `FarmPlot`
- o helper compartilhado continua gerando recompensas, bonus e drops raros pelo caminho atual
- o golem permanece usando `harvest_by_golem()` sem alterações nesta etapa
- sementes continuam como itens do inventario e o FarmGrid continua isolado

Checkpoint - Loop de Ferramentas V0:

- `ToolManager` é o controle global de ferramenta ativa do jogo principal
- Enxada prepara lote vazio, Regador rega lote e Colheita colhe lote pronto
- sementes continuam como item do inventário no jogo principal
- água aparece no StatusPanel e continua armazenada em `GlobalInventory.inventario["agua"]`
- a prioridade de clique favorece a ferramenta ativa antes da semente selecionada
- o Decay Diário ainda é manual/debug e só limpa lotes vazios e arados sem semente
- `FarmPlot` continua ativo, `FarmGrid` continua isolado e a Área Preparável V0 continua baseada em lotes pré-instanciados

Feedback visual das ferramentas:

- o `FarmPlot` reaproveita o texto flutuante existente da UI para mostrar respostas de Enxada, Regador, Colheita e avisos principais
- a mudança é só de comunicação visual; as regras de plantio, rega, colheita e save continuam as mesmas
- o console ainda pode receber prints diagnósticos quando fizer sentido, mas o jogador também vê o retorno na tela

Limpeza de logs repetitivos:

- a agua continua no inventario real, mas seus logs foram filtrados para reduzir ruído de debug
- o feedback visual passou a ser o canal principal para ações normais de lote, deixando o console mais útil para diagnostico real

Checkpoint de arquitetura:

- o preview ja validou o loop minimo do FarmGrid em memoria
- as ferramentas continuam fake e isoladas
- o `FarmPlot` continua sendo o sistema ativo do prototipo
- o `Main` mantém um snapshot runtime-only de `FarmGridManager` espelhado dos plots vivos, sincronizado por sinal de mudança de estado
- o golem ja pode consultar o snapshot para escolher alvos de colheita, mas a execução ainda acontece nos `FarmPlot` vivos
- o `Main` também consulta o snapshot para bloquear interação em tiles marcados como bloqueados
- a migracao real nao substituiu o `FarmPlot` ainda
- a pendencia de logs globais em cenas dev continua registrada como item tecnico em aberto


## Migração dos Lotes Atuais

O sistema atual de `FarmPlot` continua ativo por enquanto.

Roteiro sugerido:

### Fase 1
- Documentar o Farm System V2.

### Fase 2
- Ponte runtime-only fechada no `Main`.
- `FarmTileData` e `FarmGridManager` já servem como contrato de leitura/persistência para o golem e para o save.
- `FarmPlot` continua como sistema ativo do protótipo enquanto a migração definitiva não é aprovada.

### Fase 3
- Usar o preview dev e o smoke test para validar remoção, recriação, save/load e comportamento visual.

### Fase 4
- Criar uma área pequena de teste separada no jogo principal apenas quando o contrato do grid estiver estável.
- Criar smoke tests manuais adicionais para validar a fundação antes da integração.

### Fase 5
- Migrar parte da fazenda.

### Fase 6
- Substituir `FarmPlot` apenas quando o grid estiver estável.

## Mecânica Central Única

Cauldron Crops não é apenas um jogo de fazenda com caldeirão.

Ele é um jogo em que o jogador cultiva, transforma e administra ecossistemas alquímicos.

Loop alvo:

pesca -> caldeirão -> solo -> crops -> fazendinhas -> receitas -> golems -> expansão

## Fishing System - Pesca de Ressonancia (alvo de design)

O Fishing System é o caminho alvo para a pesca no jogo principal.

- o Lago da Fazenda V0 já existe como ponto físico/clicável no mapa principal
- a `Vara de Pesca` já existe como ferramenta visual/global na toolbar principal
- a pesca vai acontecer no lago real da fazenda
- o jogador poderá lançar a vara em qualquer área válida do lago
- áreas com ondulação, brilho ou movimento aumentam a chance de recompensas melhores
- essas áreas especiais são opcionais, não obrigatórias
- a primeira implementação alvo é pequena, calma e integrada ao lago da fazenda
- a Boia V0 já é o primeiro estado visual da pescaria no lago, sem minigame ou recompensa ainda
- a Puxada Fake V0 representa o estado visual anterior à sincronia real
- o popup de sincronia V0 já existe como primeiro passo interativo da Pesca de Ressonancia, com barra, marcador, Espaço e clique em qualquer área
- o feedback da sincronia V0 ainda é fake e nao gera recompensa real

### Pesca de Ressonancia

A mecânica alvo é uma sincronia leve e aconchegante:

- a água pulsa
- a boia reage
- o jogador clica no momento certo
- melhores acertos aumentam a qualidade da recompensa

### Recompensas previstas

Possíveis recompensas iniciais previstas:

- `peixe_comum`
- `peixe_luminoso`
- `escama_brilhante`
- `gota_lunar`
- `lodo_de_lago`
- `peixe_sazonal`
- `ingrediente_aquatico_raro`

### Relação com o resto do jogo

- a pesca alimenta caldeirão, receitas, missões e árvore de alquimia dentro da cadeia principal
- a pesca não começa como laboratório isolado no design final
- a primeira implementação de código é pequena e controlada
- a pesca já possui um popup simples de sincronia, mas ainda não tem recompensa real ou integração profunda com sistemas de progressão
- enquanto a sincronia está aberta, o lago bloqueia novo lançamento até o jogador encerrar a pesca atual

## Decisão Atual

- A ideia está aprovada como direção de design.
- Nenhuma integração ao jogo principal agora.
- O sistema atual de lotes continua ativo.
- O Farm System V2 segue em consolidação no laboratório antes de qualquer migração para o jogo principal.
