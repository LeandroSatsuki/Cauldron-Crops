# Primeira Região Externa — Plano de Vertical Slice

## Aquisição de Raiz Gélida — fechamento técnico

**Status em 2026-10-04: implementado e fechado tecnicamente, validação manual pendente.** Autor corrigiu a mensagem anterior e confirmou “OK, pode seguir. Aprovado.” ao conjunto uma Raiz/45s/primeira visita/receitas existentes. Não há autorização inferida para novas culturas, animais, golems, estações, economia ou mapa. Gameplay/engenharia da formulação foram reaproveitados sem mudar parâmetros; engenharia implementou arquivos atribuídos e QA revisou independentemente. Arte fica com Antigravity.

Implementado: **uma fonte física determinística e renovável de `raiz_gelida` no Bosque existente**, acessível desde a primeira visita sem depender de purificação ou restauração. Fluxo principal: coletar na Mochila → retornar à vila → combinar com trigo no caldeirão → obter Poção de Crescimento → aplicar numa cultura pelo fluxo existente. Uso secundário já existente: raiz + peixe → Infusão Purificadora → primeira purificação. A nova aquisição não altera a Raiz cultivada no inverno nem exige sua obtenção por RNG.

### Contrato aprovado

- Uma fonte, **uma Raiz por coleta**, renovação em **45 segundos de sessão aberta**, inclusive enquanto o jogador está na vila; sem progresso offline. Quantidade e intervalo aprovados para o piloto, não balanceamento homologado. O carvão atual entrega duas unidades; não copiar essa quantidade por engano.
- Fonte disponível na primeira visita e em saves já existentes, em local alcançável do Bosque, sem mover carvão, portal, curiosidades ou área de restauração. Nó `ForageNodes/RenewableRoot`, posição `(960,630)`, ID persistente `grove_root`; caminhada até alcance conferida pelo QA de API. Picking físico de mouse permanece manual. Sem criar direção visual ou bioma novo.
- Clique segue aproximação física de `ForageNode`; resultado exclusivamente na Mochila. Sem espaço, recusa preserva a fonte e não inicia renovação. Duplo clique/callback antigo/save/replay não entregam duas vezes.
- Renovação segue o relógio global de sessão de `GroveExpedition`, que já conta o carvão fora do Bosque. Não descontar de novo tempo de ausência ao retornar. Salvar conserva tempo restante; reabrir não acrescenta o tempo de jogo fechado.
- Receitas, custos, tempos, resultados e XP atuais permanecem: trigo + raiz → uma Poção de Crescimento, raiz + peixe → uma Infusão Purificadora, dois segundos por craft. Mistura manual continua descobrindo normalmente; primeira coleta não concede receita, XP, slots ou marco novo. Pista funcional curta pode indicar usos sem simular descoberta.
- Arte exclusivamente Antigravity. Codex reutilizou a estrutura disponível/esgotada com geometria mínima e registrou o contrato em `ART_HANDOFF.md`. Nenhum conceito ou asset final produzido nesta etapa.

### Por que não começar apenas com novas sementes

O catálogo já tem quatro culturas. `FarmPlot` recusa fora da estação ideal; o jogo começa na Primavera e o caminho público localizado de avanço sazonal é Dormir legado com moeda. Semente de Verão exige tomate na própria receita, Outono exige tomate + raiz, e Inverno depende de drop de colheita. Adicionar uma receita isolada de semente não resolve simultaneamente a circularidade de aquisição e o acesso à estação.

Este recorte diversifica **exploração e alquimia**, não entrega uma segunda cultura plantável na Primavera. Uma expansão agrícola, animal ou de golem será proposta separadamente com função, aquisição, consumo e persistência explícitos. Elixir Estacional ou adubo catalogados não ganham efeito por existência.

### Implementação e validação

`ForageNode` mantém inserção pessoal com capacidade e aproximação; `GroveExpedition` agora reconhece seis fontes, com `clearing_charcoal` e `grove_root` renováveis explicitamente. Os dois intervalos são independentes; rótulo por item/quantidade evita apresentar carvão na Raiz. Sem framework genérico de aquisição ou alteração do schema v4.

A etapa de código ficou em `Scenes/ForagingGroveRegion.tscn`, `Scripts/GroveExpedition.gd`, `Scripts/ForageNode.gd`, descrição funcional de `Database`, testes dev e auditoria/runner de entrega. Engenharia confirmou duas proteções implementadas: `collect()` recusa callback de contexto obsoleto; `SaveManager.save_game()` valida o domínio da expedição antes da gravação, reaproveitando o validador que o load já usa. Schema v4/domínio existente conservados, sem migração genérica. O teste de coleta original seleciona explicitamente seus quatro IDs, sem incluir Raiz ou carvão renovável por engano.

QA dedicado corrigido: **86 verificações por backend headless/OpenGL**, coleta/capacidade, caminhada até alcance, cancelamento pela API de movimento ao chão, substituição de dois pedidos na mesma fonte, callbacks/load/cache, intervalos independentes na vila/Bosque, legado/parcial/replay e rejeição sem mutação. As duas receitas existentes aguardam seus dois segundos reais; Crescimento fabricado aplica seu efeito ao trigo elegível, abrindo um frasco e conservando duas doses. Fixture **2** e reabertura **8** em processo novo passaram, sem descontar tempo offline. Cancelamento/persistência da produção são cobertura das regressões gerais do caldeirão, não atribuídos a esse teste dedicado. Capacidade **18** e restauração **73** passaram; primeira execução Root com erro de formatação no teste foi descartada, mesmo contendo PASS. Runner rejeita ERROR/SCRIPT ERROR, não apenas exit code/texto PASS.

Entrega final: gameplay `b126f34`, auditoria/diagnóstico `8d4df8c`, pacote limpo **`Builds/Playtest/RenewableRoot-20261004`** de `8d4df8cb35fa6927cccccf955420b76fd5b2dee5`. **58/58 regressões**, **11 reaberturas** e **5 fixtures adicionais**, contados separadamente; EXE headless/OpenGL e auditoria isolada do PCK passaram. Manifesto/hashes/82 logs/instruções/checklist/launcher conferidos independentemente pelo QA; checkout temporário removido. Primeira exportação rejeitada por override igual ao padrão omitido pelo export: auditoria corrigida lê a cena base do próprio PCK fora da árvore. A repetição limpa é a entrega certificada. Controle negativo da auditoria atual rejeita Aceleradora anterior sem Raiz. Exportador conserva logs de futuras falhas em `FailedLogs-<commit>-<timestamp>` antes da limpeza.

Engenharia e QA independentes não encontraram bloqueador material, por leitura explícita dos perfis. Os **50 textos anteriores permanecem intactos**; cinco RG acrescentados no ROADMAP, total **55 casos manuais pendentes**, sem exigir execução imediata. Picking/hover com mouse, conforto, ritmo/balanceamento e arte não foram homologados pelos testes de API. Nenhum save pessoal acessado, nenhum arquivo concorrente de arte incluído no commit ou pacote.

Próximo portão: formular separadamente expansão agrícola com acesso determinístico e comportamento sazonal claros, antes de implementar novas culturas/estações. Não ampliar sistemas por consequência do fechamento. Fontes: `Scripts/Database.gd`, `Scripts/FarmPlot.gd`, `Scripts/SeasonManager.gd`, `Scripts/GroveExpedition.gd`, `Scripts/ForageNode.gd`, `Scripts/data/RecipeResolver.gd`, `Data/recipes/pocao_crescimento_basica.tres` e `Data/recipes/raiz_gelida_peixe_comum.tres`. O histórico abaixo conserva seus próprios aceites e números datados.

## Status

Fases A, B, C e D implementadas, automatizadas e aprovadas manualmente. As correções posteriores de continuidade também foram automatizadas e aprovadas manualmente.

Essas fases continuam sendo o baseline histórico. Em 2026-10-03, após escolher novo conteúdo e aprovar o início da grande fase, o autor autorizou o recorte adicional abaixo. A autorização não inclui lore definitiva, economia, NPCs ou ampliação irrestrita do mundo.

## Segunda expedição — Clareira recuperável (2026-10-03)

Checklist operacional consolidado em [ROADMAP — Checklist integrado](ROADMAP.md#checklist-integrado--validação-manual-adiada). Os roteiros e aceites abaixo são o histórico detalhado; o checklist separa casos aprovados, ajustes posteriores e cenários condicionais sem exigir apagar progresso.

Atualização de continuidade: o autor não poderá testar agora e autorizou seguir com a construção, reunindo checklist depois. Produção em viagem (conclusão/cancelamento em lotes separados), save anterior à restauração, renovação cronometrada/capacidade e conforto/balanceamento permanecem pendentes; não reiniciar o save pessoal para fabricar cenários. A HUD da vila recebeu adaptação de largura/páginas/ferramentas/objetivos, incluindo resize durante viagem, sem mudar o recorte ou sua persistência. Consultar contexto §47 e Decisão 101; testes automáticos não equivalem a esses aceites manuais.

Estado: percurso implementado; validação automática/renderização técnica concluídas. Descoberta/coleta/preparo, restauração/recompensa agrícola e save/load no Bosque já restaurado aprovados manualmente em 2026-10-03 nos roteiros propostos. Produção em viagem, save anterior à restauração, duração e balanceamento ainda pendentes. Não é uma nova fase da Mochila nem reabre a V0.

### Escopo e percurso

1. Investigar o canteiro seco no fim do caminho principal do Bosque. A descoberta ensina **Mistura Restauradora** no Livro de Receitas; as luzes opcionais continuam atmosféricas e independentes.
2. Reunir carvão e retornar à vila. No caldeirão/Livro, **2 carvões → 1 Mistura Restauradora**, em 4 segundos. Preparar **2 misturas**; a vila mantém consumo preferencial do Storage e complemento da Mochila.
3. Retornar ao canteiro carregando as duas misturas na Mochila. O projeto não consulta o Storage remoto. Restaurar consome exatamente duas e muda visualmente o canteiro seco para plantas verdes.
4. Aprender **Infusão da Clareira**: **carvão + Mistura Restauradora → 1 Poção de Crescimento**, em 4 segundos. Reutiliza o consumível existente: botão **Usar Poção (3 Cargas)** no Caderno da Fazenda; cada clique numa cultura crescendo, sem ferramenta ativa, consome uma carga e reduz pela metade o tempo restante.

Somente uma pequena subárea do mapa existente, um projeto, duas receitas e um item intermediário. O Herbário da vila permanece intacto; o site externo é específico deste recorte e reutiliza `VillageResourceAccess` sem Storage para as transações. Não criar framework genérico de projetos, quests, aquisição ou mastery.

### Aquisição e prevenção de bloqueios

| Conteúdo | Caminho determinístico | Custo/uso | RNG exclusivo? |
| --- | --- | --- | --- |
| Carvão | Quatro pontos originais + nova fonte ao lado da clareira | Fonte nova entrega 2 e renova em 45 segundos de sessão | Não |
| Receita de preparação | Investigar canteiro | Nenhum recurso para aprender | Não |
| Mistura Restauradora | Caldeirão após descoberta | 2 carvões; restauração ou receita agrícola após completar | Não |
| Receita agrícola | Restaurar canteiro com a carga pessoal | 2 misturas; recompensa única | Não |
| Poção de Crescimento | Nova receita ou receita existente `trigo_raiz_gelida` | Alternativa ao caminho sazonal; efeito agrícola já funcional | Não |

A fonte renovável oferece recuperação se materiais forem usados em outra receita. Coleta recusada por capacidade não esgota o ponto nem inicia o intervalo. Os quatro pontos antigos continuam de coleta única, agora persistidos. A fonte nova não deposita no baú, não renova os demais pontos e não estabelece dias/estações ou simulação offline. O intervalo continua durante a sessão, inclusive na vila; ao fechar o jogo, fica congelado e retoma do valor salvo.

Os tempos e quantidades são valores de piloto, não balanceamento final. A hipótese anterior de 20–30 minutos **não foi validada**; os cultivos de protótipo são curtos. Este checkpoint fecha o percurso funcional, não promete essa duração nem acrescenta esperas artificiais. Moeda, lore e saída universal econômica continuam aguardando recorte próprio; a mistura possui dois usos concretos e nenhum preço de venda definido agora.

### Interface e persistência

- Objetivo opaco, minimizável, no canto inferior direito, visível na vila/Bosque após descoberta. Some ao restaurar e fica oculto durante modais da vila. Posição/minimização são runtime-only; contador mostra somente misturas na Mochila.
- `RecipeData.exige_descoberta` é opcional e padrão `false`. Só as duas receitas novas exigem aprendizado; mistura bloqueada não perde ingredientes e lote bloqueado não reserva recursos. Demais receitas mantêm descoberta experimental.
- Save v4 recebe campos opcionais `grove_expedition` e `home_inactive_seconds`; saves completos v3/v4 sem o primeiro iniciam o recorte intacto. Payload parcial sem esses campos preserva o progresso runtime. Flags reconciliam as duas receitas sem duplicá-las.
- `GroveExpedition` guarda somente descoberta/restauração e cinco IDs conhecidos de fonte. Validação rejeita flags contraditórias, tipos/IDs/intervalos inválidos antes de mudar região ou recursos.
- F5 passa a funcionar no Bosque: snapshot lê a Fazenda preservada em cache, incluindo lotes, Storage, purificação, Herbário, caldeirão e captura pendente. Não sobrescrever arquivo se HOME está indisponível ou durante transição.
- F9 fora da vila retoma HOME pela entrada do Bosque, cancela o destino externo e aplica o snapshot. Reabrir continua iniciando a cena HOME; posição externa não é salva. Tempo de ausência já decorrido **na sessão até salvar** avança cultivo/caldeirão uma vez após restaurar recursos/produtores. Não contar tempo com o jogo fechado nem simular logística offline de golems.
- `FarmPlot` continua autoridade: save reconstrói seu snapshot atual e aplicação da poção notifica a alteração. Regressão reproduziu save conservando o tempo anterior à redução e protege a correção.
- Fechar o Livro oculta somente seu painel e, quando vinculado a ele, o PopupLayer do caldeirão. A inspeção reproduziu o encaixe alternativo que ocultava toda a HUD; regressão protege ambos os hosts.

### Verificação e roteiro manual pendente

`GroveRestorationSliceSmokeTest` possui 72 verificações: aproximação real ao site, descoberta, Livro/quantidade com ingrediente duplicado e fechamento nos dois hosts, receita bloqueada, recusa por capacidade, fonte renovável, restauração pessoal/recusa de Storage remoto, recompensa única, efeito real, JSON em HOME/Bosque recriados, save externo de produção, catch-up, repetição/cancelamento e pré-validação/compatibilidade, incluindo retenção de marcos/fontes/receitas em payload parcial. Não faz I/O do save pessoal. Renderizações OpenGL em 1280×720 e D3D12/Forward+ em 1920×1080 conferem canteiro, objetivo expandido/minimizado, ícone, Livro e HUD após fechar; não equivalem a picking manual, aprovação artística ou aferição de duração.

Fechamento automatizado: importação sem erros e suíte completa 36/36 aprovada; save pessoal intacto por hash/tamanho/data. Esses resultados são do checkpoint técnico anterior, não uma nova execução neste aceite documental.

Aceite manual em 2026-10-03: após o roteiro de investigar o canteiro, conferir aprendizado/minimização do objetivo, coletar 4 carvões, voltar à vila e produzir duas misturas pelo Livro mantendo a HUD acessível, o autor respondeu “validado, pode continuar”. Passos 1–3 abaixo aprovados nesse escopo. Não inclui aferição do intervalo renovável, recusa por capacidade, restauração, efeito da poção, save/load ou aprovação artística. Próximo teste: passos 4–5; persistência permanece separada nos passos 6–7.

Aceite manual seguinte em 2026-10-03: autor respondeu “validado pode seguir” ao roteiro de levar duas misturas na Mochila, restaurar com consumo único/canteiro verde/objetivo oculto, repetir o clique sem nova recompensa ou consumo, produzir Infusão da Clareira e aplicar a Poção de Crescimento numa cultura crescendo sem ferramenta. Passos 4–5 aprovados nesse escopo. Persistência, duração/balanceamento e arte não foram incluídos. Próximo teste: salvar no Bosque já restaurado, carregar/reabrir e revisitar; depois produção em viagem (passo 7). Não exigir apagar progresso para repetir a descoberta; o estado anterior à restauração continua sem aceite manual de save/load.

Aceite manual seguinte em 2026-10-03: autor respondeu “aprovado pode seguir” ao roteiro de F5 no Bosque restaurado, F9 retornando à vila com itens/receita preservados, revisita com canteiro verde/objetivo oculto e sem consumo/recompensa repetidos, seguido de fechar/reabrir/carregar e repetir a conferência. Persistência após restauração aprovada nesse escopo. Não inclui save anterior à restauração, produção em viagem, capacidade cheia, duração/balanceamento ou estética. Próximo teste: passo 7, conclusão e cancelamento em lotes separados.

Roteiro:

1. Carregar o jogo existente, visitar o Bosque e investigar o canteiro ao final do caminho principal. Conferir receita aprendida e minimizar/expandir o objetivo.
2. Coletar pelo menos 4 carvões. Se necessário, aguardar/revisitar a fonte renovável; todos devem entrar na Mochila, não no Storage.
3. Na vila, abrir Livro de Receitas, selecionar Mistura Restauradora, digitar quantidade 2 e produzir. Conferir HUD acessível após fechar/iniciar produção. Se depositar as misturas no baú, retirar antes da expedição.
4. Retornar e restaurar carregando as duas; confirmar consumo único, canteiro verde, receita nova e objetivo oculto. Outro clique não concede recompensa nem consome mais itens.
5. Fazer mais uma mistura e combinar com carvão pela Infusão da Clareira. Usar a poção e clicar numa cultura crescendo sem ferramenta; os tempos atuais são curtos, portanto realizar próximo ao lote. Não interpretar utilidade/balanceamento definitivo a partir do teste sintético de 8 segundos.
6. F5 no Bosque antes e depois da restauração; F9 deve retornar à vila. Fechar/reabrir/carregar e revisitar; conferir flags, quantidades, fontes e ausência de recompensa duplicada.
7. Iniciar lote de misturas com quantidade suficiente para viajar ainda em produção (cada unidade leva 4 segundos; aumentar a quantidade somente até o que os recursos disponíveis permitirem). Anotar carvão no baú/Mochila e misturas antes de começar; viajar, salvar no Bosque e carregar. Em um lote, concluir e conferir resultado único/consumo de 2 carvões por mistura. Em outro lote retomado, cancelar antes de terminar e conferir devolução apenas dos ingredientes dos crafts não entregues às origens. Se o lote terminar antes do F5, não validar retomada/cancelamento em andamento com esse caso; não alterar timers, usar F10 ou editar o save para forçar o teste.

Pendências anteriores (captura pendente, entrega/refund do caldeirão bloqueados por capacidade, saves legados reais e arte geral) continuam separadas. Revisar ritmo/legibilidade após este playtest, sem iniciar lojas/NPCs/combate ou novos sistemas automaticamente.

## Baseline histórico das fases A–D

### Entrega da Fase A

- `ForagingGroveRegion` é uma cena nova; o protótipo técnico foi preservado.
- A Fazenda/Vila conduz ao bosque e recebe o familiar por uma entrada correspondente no retorno.
- O shell artesanal possui entrada segura, clareira principal, ramo opcional, clareira inferior e marcos visuais.
- A navegação usa um polígono côncavo triangulado; mata fechada, limites e obstáculos centrais não aceitam movimento direto.
- A câmera respeita os limites de `2560 × 1440` e o retorno permanece disponível.
- Ainda não existem pontos de coleta, recursos, descoberta, lore ou persistência adicional nessa região.
- `ForagingGroveShellSmokeTest` valida identidade, entrada, limites, câmera, marcos, áreas caminháveis/bloqueadas e deslocamento.
- `RegionTravelSmokeTest` valida a viagem real entre Fazenda/Vila e bosque, o retorno e a preservação do estado runtime.

### Entrega da Fase B

- `ForageNode` concentra interação, aproximação, estado disponível/esgotado e feedback visual.
- Quatro pontos físicos oferecem `carvao x1`; é um recurso comum já catalogado com origem de coleta.
- A aquisição é determinística, sem RNG e sem criar item, receita ou regra econômica nova.
- O resultado entra em `GlobalInventory`, usado somente como bridge temporário da Mochila neste slice.
- `VillageChest` não é acessado: coleta externa não teleporta recursos para o armazenamento da vila.
- Cada ponto aceita apenas uma coleta e permanece esgotado enquanto a mesma instância do bosque existir.
- Não houve alteração de `SAVE_VERSION`; ao iniciar outra sessão, os pontos voltam ao estado inicial conforme o contrato temporário.
- `ForagingCollectionSmokeTest` valida aproximação física, ganho exato, rejeição de duplicação, feedback e reentrada na mesma instância.

### Entrega da Fase C

- A ramificação opcional abriga as Luzes do Bosque, uma curiosidade atmosférica sem recompensa material.
- O enxame mantém uma animação discreta e reage à proximidade do familiar com brilho e movimento mais vivos.
- Ao observar as luzes, o familiar se aproxima e recebe apenas uma mensagem local; não há item, receita, moeda, lore persistente ou bloqueio de progresso.
- A curiosidade pode ser revisitada livremente e não altera o save.
- `GroveFireflyCuriositySmokeTest` valida aproximação, reação ambiental, feedback e ausência de alteração na Mochila ou nas descobertas de lore.

## Estado de partida

- A Fazenda/Vila é a região HOME `farm_village`.
- A viagem entre cenas já possui entrada/saída nomeada, fade, bloqueio de input, retorno seguro e cache em memória.
- `PrototypeExternalRegion` valida somente a infraestrutura e não deve ser promovida diretamente a mapa final.
- O estado runtime da Fazenda é preservado durante a viagem, mas regiões externas e a posição do jogador ainda não são persistidas entre sessões.
- Enquanto a Fazenda fica em cache, o tempo decorrido na sessão é aplicado aos cultivos e ao caldeirão quando o jogador retorna; isso não constitui ainda uma simulação offline completa do golem ou da vila.
- `GlobalInventory.inventario` e `VillageChest.inventory` já são armazenamentos tecnicamente separados, embora o primeiro ainda misture responsabilidades de protótipo.

## Recomendação de tema

### Região Externa 01 — Bosque de Forrageamento

Nome apenas funcional; nome final e lore aguardam aprovação.

O bosque é a melhor primeira região porque:

- introduz exploração e coleta com baixo custo técnico e artístico;
- cria contraste claro com a Fazenda sem exigir combate, dungeon ou iluminação especial;
- combina com criaturas, pequenos eventos, segredos e recursos naturais já previstos;
- permite validar caminhos opcionais e landmarks em um mapa artesanal pequeno;
- pode continuar relevante com mudanças de estação, eventos e especialização no futuro.

### Alternativas consideradas

| Opção | Vantagem | Custo/risco | Decisão atual |
| --- | --- | --- | --- |
| Bosque de forrageamento | Melhor ponte entre exploração, recursos e mundo vivo | Precisa de regra de renovação dos pontos de coleta | Recomendada |
| Caverna/mina | Identidade forte e recursos claros | Exige iluminação, obstáculos e linguagem visual novas | Adiar |
| Zona úmida/lago expandido | Reaproveita pesca e recursos aquáticos | Sobrepõe o papel do lago atual e testa menos sistemas novos | Adiar |

## Fantasia funcional do slice

```text
sair da Fazenda/Vila
↓
seguir um caminho artesanal curto
↓
reconhecer landmarks e escolher um desvio opcional
↓
coletar poucos recursos físicos
↓
encontrar uma curiosidade opcional
↓
retornar à Fazenda/Vila com os itens na Mochila
```

Não entram neste slice:

- combate;
- NPC completo;
- quests encadeadas;
- dungeon procedural;
- loja ou moeda nova;
- mastery completa;
- simulação offline da região;
- rede de baús;
- lore central obrigatória.

## Escala e estrutura do mapa

- Mapa finito e artesanal de aproximadamente `2560 × 1440` pixels.
- Duração-alvo da primeira exploração: 5–8 minutos.
- Três espaços legíveis:
  1. entrada segura e retorno;
  2. clareira principal de coleta;
  3. desvio opcional com curiosidade ambiental.
- Um caminho principal sempre legível e um ramo opcional curto.
- Passagens úteis com pelo menos 96 pixels de largura.
- Sem labirinto; orientação deve vir de forma, cor e landmarks, não de placas extensas.
- A saída permanece acessível em todos os estados do mapa.

## Conteúdo mínimo

### Coleta

- Três a cinco pontos físicos de recurso comum.
- Pelo menos uma coleta determinística por visita/sessão; progresso não pode depender apenas de RNG.
- Um recurso incomum pode existir como bônus, descoberta ou atalho, nunca como bloqueio obrigatório exclusivo.
- Itens coletados entram primeiro na Mochila e nunca diretamente no `VillageChest`.

Os IDs dos recursos ainda não estão definidos. Antes de criar item novo, verificar se um item existente pode ganhar outra fonte sem desvalorizar sua função atual. Se um ID novo for necessário, ele deve nascer com uso claro e saída futura prevista — não apenas como loot decorativo.

### Descoberta

- Uma curiosidade atmosférica opcional, sem poder permanente necessário.
- A primeira versão não deve explicar a Guardiã, a corrupção ou o passado da vila.
- A descoberta pode ser apenas reação visual/sonora; recompensa material não é obrigatória.

### Mundo vivo

- Um comportamento ambiental pequeno e barato, como folhas, brilho, criatura distante ou objeto reagindo à aproximação.
- Nenhuma criatura funcional nova antes de a região provar navegação e coleta.

## Contrato temporário de inventário

Para este vertical slice:

- `GlobalInventory.inventario` pode representar temporariamente a Mochila para recursos coletados pelo familiar fora da vila;
- `VillageChest.inventory` continua representando o Village Storage;
- coleta externa não deposita automaticamente no Village Storage;
- caldeirão, purificação e projetos continuarem a ler `GlobalInventory` é dívida de transição já documentada, não arquitetura final;
- não implementar peso, capacidade, slots limitados ou categorias separadas nesta etapa.

Esse bridge permite validar exploração sem antecipar a reforma completa de inventário. O depósito Mochila → Village Storage e o consumo direto pelos sistemas da vila pertencem a um sprint próprio.

## Estado e salvamento do slice

Direção mínima recomendada:

- a região permanece em memória enquanto a sessão está aberta;
- pontos coletados continuam esgotados até encerrar a sessão;
- ao reiniciar o jogo, a região nasce novamente em seu estado inicial;
- itens já levados de volta e salvos na Fazenda permanecem no inventário;
- salvar e carregar continuam sendo ações da Fazenda/Vila durante este slice;
- não aumentar `SAVE_VERSION` apenas para persistir uma região ainda experimental.

Uma regra de renovação por dia/estação só deve ser criada quando o tempo real do jogo estiver conectado ao gameplay.

## Sequência mínima de implementação

### Fase A — shell jogável

- Criar nova cena para a região; não sobrescrever o protótipo técnico.
- Configurar `WorldRegion`, entradas, câmera, navegação e retorno.
- Construir apenas terreno, caminhos, limites e três landmarks em blockout coeso.
- Validar ida, exploração e retorno sem coleta.

Estado: implementada e aprovada.

### Fase B — coleta vertical

- Criar um `ForageNode` reutilizável com estado coletado/não coletado.
- Fazer o familiar aproximar-se antes da coleta.
- Depositar o resultado no bridge atual da Mochila.
- Exibir feedback curto no mundo, sem abrir painel modal.
- Manter coleta determinística e sem respawn arbitrário durante a sessão.

Estado: implementada e aprovada.

### Fase C — descoberta e vida

- Adicionar uma curiosidade opcional.
- Adicionar um único comportamento ambiental barato.
- Evitar recompensa obrigatória ou lore estrutural.

Estado: implementada e aprovada.

### Fase D — validação

- Smoke test de navegação e limites.
- Smoke test de coleta única e destino correto do item.
- Smoke test de ida/retorno e preservação da Fazenda.
- Teste manual de leitura espacial, orientação e sensação de duração.

Estado: validação automatizada e manual concluída; fase aprovada.

`ForagingGroveVerticalSliceSmokeTest` executa, numa mesma sessão, a saída da Fazenda/Vila, uma coleta física, a curiosidade opcional, o retorno pelo portal, a preservação da instância da Fazenda e a separação entre Mochila temporária e Village Storage.

O fechamento manual também confirmou a aproximação segura aos obstáculos interativos da Fazenda/Vila. `CoreWorldInteractionSmokeTest` protege baú, caldeirão, pesca e lote agrícola contra regressões de destino inalcançável ou interação executada dentro da colisão.

## Critérios de aceite

- O jogador entende visualmente como voltar sem texto longo.
- Não existem pontos alcançáveis que prendam o familiar.
- A câmera nunca revela vazio fora dos limites planejados.
- A região oferece uma escolha espacial simples, não apenas um corredor.
- A coleta ocorre no mundo após aproximação física.
- Recursos externos não aparecem diretamente no Village Storage.
- Nenhum conteúdo obrigatório depende exclusivamente de RNG.
- Retornar à Fazenda preserva integralmente seu estado runtime.
- A região pode receber eventos e novos pontos de interesse sem reescrever a transição.

## Decisões de aprovação antes da Fase A

Recomendação padrão:

1. aprovar o bosque de forrageamento como tema funcional;
2. manter nome e lore finais em aberto;
3. usar `GlobalInventory` como bridge temporário da Mochila;
4. manter save/load apenas na Fazenda durante o vertical slice;
5. criar uma cena nova e conservar `PrototypeExternalRegion` como teste técnico até a substituição ser validada.
