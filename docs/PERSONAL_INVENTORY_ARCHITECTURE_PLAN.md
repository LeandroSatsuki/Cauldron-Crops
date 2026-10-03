# Plano de Arquitetura — Mochila / Inventário Pessoal

## Status

Fases A–C concluídas; D/E implementadas. Em 2026-10-03, o autor aprovou os roteiros manuais de expansão/navegação/transferências/save da Mochila, produção em andamento/retomada/cancelamento do caldeirão e colheita recusada por Mochila cheia, persistida e recuperada após depósito. Permanecem os cenários específicos de captura pendente e entrega/cancelamento do caldeirão bloqueados por capacidade, sem aprovação presumida. Fase E validada automaticamente em 2026-10-01 após autorização explícita para iniciar e finalizar no mesmo ciclo. O autor escolheu expansão por marcos de restauração/exploração: capacidade inicial 12, +4 pelo Herbário e +4 pela primeira coleta no Bosque, até 20 slots; stacks padrão 99. Os relatos históricos abaixo descrevem checkpoints, não o estado atual do limite.

Este marco sucede o fechamento do acesso a recursos da vila. Ele não inclui economia, venda, NPCs, múltiplos baús, filtros avançados, peso, toolbelt separado nem mudança de lore.

Atualização de aceite em 2026-10-03: autor aprovou o roteiro específico de conferir marcos/capacidade até 20 no baú, repetir coleta no Bosque sem ultrapassar o limite, navegar páginas e selecionar/desselecionar semente na segunda página, transferir itens nos dois sentidos e salvar/reabrir/carregar preservando capacidade/quantidades. Esse roteiro de expansão/navegação está concluído; não equivale a aprovação dos cenários de Mochila cheia, captura/colheita recusada ou persistência/cancelamento do caldeirão. Esses itens do checklist abaixo continuam pendentes. Próximo roteiro manual: produção do caldeirão em andamento, retomada e cancelamento.

Aceite seguinte em 2026-10-03: autor aprovou iniciar produção (preferencialmente em lote), salvar em andamento, fechar/reabrir/carregar e conferir resultado/consumo únicos; em outra produção, repetir a retomada e cancelar, devolvendo ingredientes reservados e não utilizados às origens sem duplicação. Esse roteiro do caldeirão está concluído; cenários de bloqueio por falta de espaço, captura/colheita recusada e compatibilidade com saves legados não foram incluídos. Próxima etapa de validação: casos-limite de capacidade/recompensas; não forçar preenchimento via F10 ou edição do save.

## Objetivo

Transformar gradualmente `GlobalInventory.inventario` na representação real da Mochila, limitada por slots e stacks generosos, preservando:

- saves v4 existentes;
- agricultura, pesca, coleta, eventos e alquimia;
- seleção exclusiva entre semente e ferramenta;
- separação entre Mochila e Village Storage;
- recursos externos entrando primeiro na Mochila;
- água fora dos slots, como reserva do poço.

## Baseline encontrado

- `GlobalInventory.inventario` é um `Dictionary` agregado por `item_id`, sem capacidade e sem stack máximo.
- `adicionar_item` não valida argumentos, não pode falhar e não informa quantidade aceita ou restante.
- `remover_item` valida apenas disponibilidade total e mantém chaves com quantidade zero.
- O save v4 persiste o mesmo dicionário em `inventory.inventario`.
- A UI cria um slot somente para cada tipo com quantidade positiva; posições de slot não são estado persistente.
- A barra atual tem aproximadamente 850 pixels úteis. Com slots de 60 pixels e separação de 10, comporta naturalmente 12 slots.
- Água já é excluída da barra e da transferência para o baú.
- Ferramentas usam `ToolManager`; receitas, coleção, lore, habilidades e moeda já possuem estado separado ou caminham nessa direção.
- Village Storage e Mochila já são estoques distintos. Retirada do baú ainda pressupõe que a Mochila sempre aceita o item.
- Existem 29 chamadas de `adicionar_item` no projeto, incluindo gameplay e debug. As entradas reais incluem colheita, pesca, forrageamento, eventos, caldeirão, restauração, requests legados e retirada do baú.
- Alguns testes e o load atribuem o dicionário diretamente. Uma troca imediata para array de slots teria grande superfície de regressão.

## Riscos confirmados

### Perda de recompensa

Os produtores atuais consomem ou concluem sua fonte antes de adicionar o resultado. Se a capacidade passar a recusar itens sem migrar esses fluxos, o jogador poderá colher, pescar ou concluir um evento e perder a recompensa.

### Transferência não atômica

Hoje a retirada do baú remove primeiro do Village Storage e depois adiciona na Mochila. Com limite ativo, o destino precisa ser validado antes de alterar a origem.

### Resultado de sistemas fixos da vila

O destino definitivo dos resultados do caldeirão e da restauração ainda não foi decidido. A capacidade da Mochila não deve decidir silenciosamente se esses resultados vão para Village Storage, chão, fila pendente ou outro destino.

### Save e stacks físicos

O dicionário v4 preserva quantidades, mas não posições nem múltiplas pilhas do mesmo item. Migrar diretamente para uma lista de slots exigiria novo contrato de save e adaptação de muitos consumidores.

### Capacidade contabilizada incorretamente

Chaves com quantidade zero, água e futuros estados separados não podem ocupar slots. Quantidades acima do stack máximo precisam contar como mais de um slot.

## Decisão recomendada para o piloto

Usar uma camada de compatibilidade sobre o dicionário atual antes de mudar o formato persistido.

- Capacidade inicial do piloto: **12 slots**.
- Stack padrão do piloto: **99 unidades**.
- Água não ocupa slot.
- Ferramentas, moeda, receitas, coleção, lore e habilidades não ocupam slots.
- Um item ocupa `ceil(quantidade / stack_maximo)` slots.
- O catálogo poderá fornecer `stack_maximo` por item no futuro; enquanto ausente, usa 99.
- A UI pode representar pilhas lógicas sem tornar posição de slot parte do save.
- O save permanece v4 durante a fundação; capacidade expansível e posições persistentes só justificam v5 quando houver requisito real.

Esses números são valores de piloto, não balanceamento final.

## Contrato mínimo proposto

Adicionar a `GlobalInventory` uma API explícita sem ativar o limite no primeiro patch:

```text
get_item_quantity(item_id)
get_used_slot_count()
get_free_slot_count()
get_acceptance(item_id, quantity)
try_add_item(item_id, quantity)
can_remove_item(item_id, quantity)
set_inventory_contents(contents)
```

`try_add_item` deve retornar um resultado estruturado:

```text
requested
accepted
remainder
success
reason
```

Regras:

- quantidade inválida não altera estado;
- aceitação parcial é explícita;
- nenhuma origem é consumida antes de conhecer a aceitação do destino;
- `adicionar_item` permanece temporariamente como wrapper compatível enquanto os produtores são migrados;
- seleções de sementes são limpas quando a última unidade sai da Mochila;
- load usa uma função de substituição controlada, sem mesclar estado anterior.

## Fases de implementação

### Fase B — Fundação sem alterar gameplay — concluída

1. adicionar consultas de quantidade, ocupação e aceitação;
2. adicionar resultado estruturado para inserção;
3. validar IDs e quantidades negativas/zero;
4. adicionar testes unitários do contrato;
5. manter capacidade desativada e `adicionar_item` compatível;
6. preservar save v4 e comportamento visual atual.

Gate: todos os smoke tests existentes continuam passando e nenhuma recompensa pode ser recusada ainda.

Resultado: `GlobalInventory` agora expõe quantidade, limite de stack, ocupação, espaço livre, aceitação e inserção estruturada, remoção validada e substituição controlada do conteúdo. O modo de capacidade permanece desligado no gameplay. `PersonalInventoryContractSmokeTest` simula mochila cheia e cobre aceitação parcial, recusa, água fora dos slots, validação e limpeza de seleção. Os 28 smoke tests ativos passaram.

### Fase C — Migrar entradas de itens — concluída

Migrar, uma família por vez, para tratar sucesso, recusa e quantidade restante:

1. retirada do Village Storage — concluída;
2. colheita manual — concluída;
3. forrageamento externo — concluído;
4. pesca — concluída;
5. eventos de mundo — concluídos;
6. resultados de caldeirão e restauração — concluídos;
7. fluxos legados ainda acessíveis — auditados e protegidos conforme seu estado atual.

Cada fonte precisa manter ou restaurar sua recompensa quando a Mochila não aceitar tudo. Nenhum fallback automático para Village Storage fora da vila.

Primeiro incremento concluído: a retirada consulta a aceitação antes de remover do Village Storage. Se a quantidade inteira não couber, nenhum estoque é alterado; se uma alteração inesperada ocorrer durante a operação, a origem é restaurada. A retirada global legada também preserva pilhas que não couberem. A interface distingue falta de espaço de estoque obsoleto, mas o limite continua desligado no gameplay.

Segundo incremento concluído: a colheita manual agrupa todas as recompensas do clique e só conclui o `FarmPlot` quando o lote inteiro cabe. Se faltar espaço, cultivo e inventário permanecem intactos, o jogador recebe feedback e as mesmas recompensas sorteadas ficam pendentes durante a sessão. O golem também reutiliza uma recompensa já pendente antes de concluir a colheita. A capacidade continua desligada no gameplay.

Terceiro incremento concluído: o `ForageNode` tenta inserir a recompensa inteira antes de marcar o ponto como coletado. Se não couber, não existe aceitação parcial, o ponto permanece disponível e um aviso aparece no próprio mundo. Nenhum fallback envia a coleta externa para Village Storage. A capacidade continua desligada no gameplay.

Quarto incremento concluído: antes de abrir a sincronia, a pesca verifica espaço para todos os resultados possíveis. A entrega agrupa Peixe Comum e eventual Escama Brilhante da Maré Cintilante em uma única operação; a coleção só avança após inserção completa. Uma defesa mantém a captura pendente na instância da UI e tenta entregá-la quando a Mochila voltar a ter espaço. A capacidade continua desligada no gameplay.

Quinto incremento concluído: o Fragmento Celestial só remove seu marcador depois da inserção completa na Mochila. Falta de espaço mantém o evento no mundo, mostra feedback e renova a duração daquele marcador para permitir que o jogador libere capacidade. O evento de colheita que concede pontos de alquimia não ocupa slot e permanece inalterado. A capacidade continua desligada no gameplay.

Sexto incremento concluído: resultados do caldeirão continuam destinados à Mochila, mas ficam prontos no próprio caldeirão quando não há espaço. A produção manual pode ser recolhida em uma nova interação; a produção em lote pausa sem avançar o contador nem descartar a reserva do craft atual, retomando após liberar espaço. A restauração valida a recompensa antes de consumir recursos e, como defesa transacional, devolve o recibo se a inserção falhar inesperadamente. Não há fallback automático para Village Storage e a capacidade continua desligada no gameplay.

Sétimo incremento concluído: o `QuestBoard` legado devolve integralmente o pedido e mantém a demanda quando uma recompensa em item não cabe. O rollback de `VillageResourceAccess` valida a devolução à Mochila e só marca o recibo como reembolsado após sucesso integral. Água do poço usa a API explícita, mas continua fora dos slots. Loja, F10 e seus comandos de debug permanecem ocultos/desativados e não foram promovidos a gameplay; o wrapper compatível fica restrito a esses caminhos e a testes. `QuestRewardCapacitySmokeTest` cobre a futura reativação segura das demandas.

### Fase D — Ativar o piloto de 12 × 99

1. ligar a capacidade somente após todas as entradas ativas tratarem recusa e o resultado pendente do caldeirão possuir destino persistente — implementado, aguardando validação manual;
2. renderizar 12 slots fixos e dividir visualmente quantidades maiores que 99 — concluído;
3. mostrar ocupação de forma discreta — concluído;
4. impedir retirada excessiva do baú antes de remover da origem — concluído na Fase C;
5. preservar seleção de sementes e exclusividade com ferramentas — concluído;
6. validar save/load com mochila vazia, cheia e parcialmente ocupada — concluído nos testes automatizados.

Primeiro incremento visual concluído: a barra apresenta no mínimo 12 slots, mostra vazios desativados, divide quantidades segundo o limite real de cada item e exibe ocupação `usados/12`. Água continua fora da grade. Enquanto a capacidade estiver desligada, saves ou comandos de desenvolvimento acima de 12 slots geram slots extras temporários com indicador em cor de atenção, evitando esconder itens durante a transição. A representação não muda o dicionário, o save nem ativa recusas.

Segundo incremento concluído em 2026-10-01, após aprovação manual do visual: selecionar qualquer pilha de uma semente seleciona o tipo, com destaque nas suas pilhas ocupadas. Clicar novamente em qualquer uma delas desmarca o plantio. Consumir ou depositar parte preserva a seleção; retirar a última unidade limpa a seleção. Slots vazios não recebem destaque e callbacks obsoletos não selecionam sementes indisponíveis. O load restaura somente uma seleção de semente com estoque positivo e limpa a ferramenta ativa nesse caso, preservando a exclusividade.

`InterfaceInteractionSmokeTest` cobre cliques reais nos slots divididos, desaparecimento de uma pilha após consumo, depósitos parcial/final e callbacks obsoletos. `SaveContractSmokeTest` serializa JSON em memória e restaura Mochilas vazia, parcial e cheia, verificando substituição exata, quantidades das pilhas, ocupação e seleção. O save pessoal não é escrito; o formato continua v4. A ordem das chaves pode mudar na serialização JSON: posições físicas dos slots continuam fora do contrato persistido. Sete smoke tests relacionados passaram; a capacidade segue desligada.

Terceiro incremento concluído em 2026-10-01: a produção/resultado pronto do caldeirão passa a integrar o save v4 por campo opcional. Misturas guardam resultado, quantidade e tempo restante; lotes guardam também contadores e recibos por origem dos crafts não entregues. Load substitui estado sem repetir consumo/refund. Cancelamento bloqueado preserva as reservas e pode ser retomado após liberar espaço. `CauldronPersistenceSmokeTest` reconstrói a cena, valida timers reais e simula estados de capacidade sem ativá-la no gameplay. A suíte completa de 31 smoke tests passou; o gate de persistência está implementado e aguarda validação manual.

Quarto incremento implementado em 2026-10-01: limite ativo por padrão, sem alterar o schema agregado v4 nem persistir o flag de testes. Saves acima de 12 slots são carregados integralmente; slots excedentes permanecem representados, e o painel rolável do Baú permite depositar todo o conteúdo. Não há truncamento, depósito automático nem criação de slots novos enquanto a ocupação exceder 12; completar espaço na pilha já ocupada continua permitido. Depositar reduz naturalmente o excesso.

A auditoria de ativação identificou um risco na defesa da pesca: a captura pendente podia ser sobrescrita por outra tentativa ou perdida ao reabrir o jogo. O campo opcional `fishing_pending_capture` guarda a recompensa capturada e o bônus da Maré Cintilante; uma nova tentativa não pode substituí-la. Load valida antes de alterar estoques, substitui pendência sem entrega imediata e reinicia o lago sem forçar a Vara sobre a seleção restaurada. A coleção só avança após a entrega integral. Saves completos antigos sem o campo limpam o runtime; payloads parciais sem estoques preservam a captura. Isso é proteção de uma recompensa existente, não uma fila genérica ou novo destino.

`PersonalInventoryPilotSmokeTest` verifica o limite de produção sem ligar um flag no teste, retirada atômica, conclusão de pilha, save v3 excedente com 15 slots, depósito sem perda, pesca recusada, captura dupla persistida/recriada, nova tentativa bloqueada, entrega única, payload inválido e carga parcial/legada. Nenhum teste escreve no save pessoal. A validação visual/manual continua pendente.

### Fase E — Balanceamento e expansão por marcos — implementada

Escopo original (resolvido no fechamento abaixo):

- decidir como o jogador expande a capacidade;
- decidir limites especiais por categoria, se necessários;
- decidir destino de resultados de sistemas fixos da vila;
- avaliar se posições físicas de slots precisam persistir;
- avaliar mudança de save apenas se houver benefício concreto.

#### Preparação técnica — somente análise, 2026-10-01

Autorização de continuidade recebida, sem confirmação inequívoca dos testes manuais. Esta preparação não encerra a Fase D nem inicia sistemas de expansão da Fase E. Limite 12 × 99, destinos e save v4 permanecem inalterados.

Baseline confirmado no código:

- `Database.itens` possui 22 IDs. Isso inclui água e resultados especiais/legados; não significa que todos estejam acessíveis ou devam ser carregados simultaneamente. Nenhum item declara `stack_maximo` atualmente: todos usam o padrão 99 quando entram na Mochila.
- As dez sementes iniciais ocupam um slot. Capacidade depende tanto de variedade quanto de quantidade; 12 × 99 não significa poder levar 12 tipos em quantidades ilimitadas. Não há evidência de sessão manual suficiente para aumentar o limite ou ajustar stacks.
- `Scenes/UI.tscn` reserva 850 pixels para a barra, com separação de 10. Aumentar capacidade sem revisar layout pode expandir a barra além da região reservada; upgrades não devem ser apenas uma troca de constante.
- `VillageChestPanel._fill_grid` agrupa por tipo e preenche ambos os painéis até 20 células. Já a barra principal conta pilhas. Assim, 100 unidades de um tipo aparecem como uma célula no painel de transferência, mas ocupam dois slots na barra. As 20 posições visuais não representam capacidade real: há um risco de comunicação, não de alteração do estoque.
- O baú permanece sem limite lógico implementado. Sua grade não deve sugerir que ele compartilha os 12 slots da Mochila.

Menor próximo incremento recomendado: alinhar a representação da Mochila no painel de transferência ao contador/pilhas da barra e mostrar sua ocupação real, sem mudar o painel lógico do baú nem a operação seletiva existente. Deve usar a API atual, preservar acesso ao excesso legado e manter os painéis opacos lado a lado. Não implementar upgrades, filtros, rede de baús, moeda ou posições persistentes nesse ajuste. Esta é uma recomendação registrada, ainda não uma implementação ou decisão de balanceamento.

Validação prevista para o ajuste: Mochila vazia, 99/100 unidades do mesmo tipo, 12/12, excesso legado, depósito/retirada e callbacks obsoletos. Os testes `PersonalInventoryPilotSmokeTest` e `VillageChestTransferSmokeTest` foram reexecutados nesta preparação e passaram; não substituem teste manual nem comprovam uma correção visual ainda não implementada.

Depois da validação manual, escolher com o autor o primeiro foco de balanceamento: conforto do limite inicial ou forma de expansão. Custo, progressão e lore da expansão continuam abertos; não inventar loja/NPC nem consumir moeda provisória para resolvê-los.

#### Incremento visual implementado — 2026-10-01

Após autorização de continuidade, o painel da Mochila ao lado do baú usa `get_personal_slot_entries()`: mesma ordem e divisão por `stack_maximo` da barra, 12 posições mínimas em quatro colunas e contador de ocupação. Água e chaves zeradas não aparecem. Acima de 12 slots, o painel mantém todas as pilhas em sua grade rolável e indica excesso legado. O baú continua agrupado por tipo, sem receber limite de 12 slots.

Clicar em qualquer pilha abre a transferência do tipo de item, como antes. O popup informa `Total do item`; `Mover tudo` transfere todas as unidades desse tipo, incluindo suas outras pilhas, e não a Mochila inteira. Quantidade individual e recusa atômica permanecem iguais. Botões removidos durante reconstrução da grade não podem reabrir a transferência por callback obsoleto.

Cinco testes relacionados passaram: `VillageChestTransferSmokeTest`, `PersonalInventoryPilotSmokeTest`, `InterfaceInteractionSmokeTest`, `SaveContractSmokeTest` e `CauldronPersistenceSmokeTest`. O teste do baú cobre 0/12, água/zero, 99/100, limite personalizado do catálogo, 12/12, excesso de 15 slots, depósito parcial/integral, agrupamento do baú e callbacks antigos. Não houve mudança de limite, estoque, schema, destino, economia ou expansão.

Validação manual deste ajuste: abrir o baú e conferir 12 posições na Mochila e contador coerente com a barra; se houver mais de 99 unidades de um tipo, conferir pilhas divididas, total no popup e transferência parcial/`Mover tudo`; fechar e reabrir os painéis sem bloqueio. Testes manuais do piloto e da persistência do caldeirão também continuam pendentes. Este incremento não encerra a Fase D nem aprova a Fase E.

## Critérios de aceite do piloto

- itens iguais completam a pilha antes de ocupar outro slot;
- itens diferentes ocupam slots distintos;
- água não reduz capacidade;
- mochila cheia nunca apaga recompensa;
- retirada do baú é atômica;
- coleta externa não teleporta item ao Village Storage;
- save/load preserva quantidades exatamente;
- sementes continuam selecionáveis e são desselecionadas ao acabar;
- ferramentas continuam fora da Mochila;
- caldeirão, purificação e restauração continuam consumindo Village Storage primeiro;
- nenhum fluxo de venda ou economia é reativado.

#### Fechamento técnico da Fase E — 2026-10-01

Escolha expressa do autor: **recompensa por marcos de restauração/exploração**. Implementação do piloto, sem lore adicional:

- Restaurar o primeiro Herbário concede +4 slots uma única vez, depois da entrega da recompensa existente. Primeira coleta bem-sucedida em qualquer um dos quatro pontos do Bosque concede outros +4. São independentes e podem ocorrer em qualquer ordem: 12 → 16 → 20.
- Bônus não consome moedas/itens, não exige material raro nem RNG. Coleta recusada, projeto bloqueado, falta de ingredientes ou falta de espaço para a recompensa não concedem progresso. O jogador pode depositar recursos e tentar novamente.
- Não há aumento por coletar mais vezes, revisitar a região ou repetir load. A exploração continua entrando na Mochila, sem depósito automático na vila.
- A barra tem páginas de até 12 slots com setas sem foco de teclado. Mantém a página ao atualizar estoques, limita-a quando o conteúdo diminui e permite alcançar todo excesso legado. O painel do baú acompanha a capacidade e apresenta os dois marcos. Seleção de sementes permanece por tipo e exclusiva com ferramentas.
- Save v4 recebe apenas o campo opcional `inventory.backpack_milestones`, contendo IDs conhecidos e únicos. Ele é validado antes de mutações. Presente, substitui exatamente o progresso; ausente em save completo antigo, começa na base e recupera apenas o Herbário cuja restauração consta no próprio arquivo. Uma coleta antiga não era persistida: o bônus do Bosque é obtido na próxima coleta bem-sucedida, não inferido. Payload parcial sem campo preserva progresso. Redução por load nunca corta conteúdo excedente.

Demais decisões da fase:

1. **Stacks/categorias:** manter 99 e água fora da capacidade; nenhum limite especial adicional. Catálogo já permite override por item, mas não há evidência de playtest para aplicar restrições novas.
2. **Resultados da vila:** manter Mochila como destino do caldeirão e da recompensa de restauração; caldeirão cheio espera no produtor, restauração valida antes do consumo. Village Storage permanece prioridade de ingredientes e destino físico dos golems. Nenhum fallback silencioso.
3. **Posições dos slots:** não persistir. Não há reordenação manual/identidade física de pilha a preservar; contagem e seleção por tipo atendem o comportamento atual.
4. **Versão do save:** manter v4 com campo aditivo validado; não implementar v5/lista física de slots sem necessidade.

Balanceamento verificável: quatro sementes + quatro culturas + carvão + peixe ocupam dez slots, deixando dois para descobertas. Isso é um cenário de variedade, não um kit obrigatório. Com 99 por pilha, o limite teórico homogêneo é 1.188/1.584/1.980 unidades em 12/16/20 slots; não equivale a essa quantidade por tipo. Os +4 mantêm a grade em linhas completas e criam expansão perceptível sem inflar o limite inicial. A duração real e o conforto dessa progressão continuam sujeitos a playtest; não foram declarados balanceamento final.

Validação: suíte completa 33/33, incluindo `BackpackExpansionSmokeTest`. Cobertura nova: duas ordens de marcos, deduplicação/ID inválido, limites 12/16/20, aceitação parcial/atômica, ações reais recusadas/concluídas, retorno de estoque sem teleporte, páginas/seleção, transferência nos slots extras, refresh sem mudar quantidades, 25 pilhas legadas, JSON em memória com cena recriada, replay, v3/v4 antigos, payload parcial e progresso inválido sem mutação. Interface conferida por renderização OpenGL. Nenhum save pessoal foi alterado.

Fechamento: implementação da Fase E concluída; aceite manual e ajustes finos de conforto pendentes. Economia, NPCs, rede de baús, filtros avançados e nova lore não foram implementados.

## Próximo passo — aceite manual integrado

Fechamento integrado posterior à Fase E, em 2026-10-01: 34/34 testes passaram. O teste da viagem verifica a expansão obtida no Bosque, atualização real do HUD ao retornar, depósito seletivo e dois loads. A auditoria corrigiu a perda do sorteio da colheita recusada no load: `pending_harvest_rewards` acompanha o grid v4, mantém itens/quantidades para retomada manual ou pelo golem e é validado antes de mutações. Essa pendência era restrita à sessão no checkpoint da Fase C. Consultar Decisão 95 e `FARM_SYSTEM_V2.md`. Trata-se de consistência dos fluxos existentes; a aprovação manual abaixo continua pendente.

Regressão completa posterior ao ajuste do painel, em 2026-10-01: 32/32 smoke tests passaram, sem erros de script ou falhas reportadas. Nenhuma alteração de gameplay foi necessária. A aprovação manual abaixo permanece pendente; este resultado não encerra a Fase D.

Validar manualmente o piloto e a expansão antes do aceite de experiência das Fases D/E. Não reativar F10 nem editar o save pessoal para montar cenários; os cenários extremos têm smoke tests próprios.

1. Abrir o save habitual: quantidades e seleção devem ser preservadas; água não ocupa slot. Se houver excesso legado, depositar pelo Baú da Vila, sem perda de itens.
2. Colher, coletar no bosque, pescar e transferir itens nos dois sentidos; a interação usual deve permanecer funcional.
3. **Aprovado no caso de colheita em 2026-10-03:** Mochila cheia, resultado sem espaço nas pilhas, aviso/cultura preservada e retomada após depósito. Não inferir aprovação de todas as fontes ou estados de bloqueio.
4. **Aprovado pelo autor em 2026-10-03 no roteiro proposto:** produzir no caldeirão, salvar em andamento, fechar/reabrir/carregar, conferir resultado/consumo únicos e, em outra produção retomada, cancelar devolvendo ingredientes não utilizados às origens. Não inclui cancelamento/entrega bloqueados por capacidade cheia.
5. Se uma captura ficar pendente por mudança de espaço durante a sincronia, fechar o popup, salvar/reabrir e liberar espaço pelo baú: entrega integral uma única vez e coleção atualizada só depois.

6. Coletar no Bosque e restaurar o Herbário: cada marco concede +4 apenas uma vez, até 20. Se o Herbário já estava restaurado no save antigo, seu bônus deve aparecer ao carregar. Conferir os dois marcos no baú.
7. Usar as setas da barra, selecionar/desselecionar uma semente na segunda página e transferir recursos no baú. Salvar/reabrir: capacidade e estoques devem ser preservados; revisitar/coletar novamente não aumenta além de 20.
8. **Aprovado pelo autor em 2026-10-03:** colheita recusada por falta de espaço → salvar/reabrir/carregar → depositar no baú → colher novamente, sem perda/duplicação.

Depois do aceite, revisar somente pontos concretos de conforto encontrados na sessão. Economia, NPCs e novos destinos continuam exigindo escopo próprio; não são consequência automática do fechamento técnico da Mochila.

Atualização de fechamento em 2026-10-03: o autor aprovou o roteiro de colheita recusada acima. Próxima revisão: aceite visual do estado atual, mantendo captura pendente, bloqueios do caldeirão por capacidade e saves legados como casos separados; não exigir enchimento artificial da Mochila nem reativar F10. Nenhuma fase nova de gameplay definida por esta revisão.
