# Contrato de Acesso a Recursos da Vila

## Status

Fundação técnica da transição entre Mochila e Village Storage. Caldeirão, purificação e restauração foram automatizados e aprovados manualmente como consumidores-piloto. O destino dos resultados permanece inalterado; o save v4 ganhou um campo opcional para produção e reservas do caldeirão, ainda aguardando validação manual.

## Responsabilidades

- `GlobalInventory.inventario` continua representando temporariamente a Mochila.
- `VillageChest.inventory` continua sendo a primeira representação lógica do Village Storage.
- `VillageResourceAccess` consulta os dois armazenamentos sem fundi-los.
- Uma reserva válida consome primeiro do Village Storage e completa pela Mochila.
- Antes de qualquer retirada, todos os requisitos são validados em conjunto.
- Cada consumo bem-sucedido produz um recibo com item, quantidade e origem.
- O recibo permite um único rollback, devolvendo cada item à origem exata.

## Limites desta fase

- Nenhum item é transferido automaticamente.
- Baú e Mochila abrem lado a lado, em grades opacas, com transferência seletiva nos dois sentidos.
- Mochila representa pilhas e ocupação reais (12 posições mínimas, excesso legado rolável); baú permanece agrupado por tipo. Clicar numa pilha pessoal consulta o total do tipo, e `Mover tudo` move todas as suas unidades, não todos os itens da Mochila.
- Requests e comércio ainda não usam o contrato porque seus fluxos permanecem fora da V0 atual.
- O piloto de capacidade está ativo: 12 slots × stacks padrão de 99. Retirada recusada preserva os estoques; excesso legado pode ser depositado sem perda. Filtros, múltiplos baús e posições persistentes continuam fora deste contrato; validação manual do piloto pendente.
- O contrato não define o destino dos resultados produzidos pelos sistemas da vila.

## Piloto do caldeirão

- O Livro de Receitas calcula a quantidade fabricável usando Village Storage + Mochila.
- Produção manual e em lote usam reservas transacionais.
- Cada unidade do lote possui recibo próprio; unidades concluídas descartam seu recibo.
- Cancelar o lote devolve somente as unidades pendentes e respeita a origem de cada item.
- Recibos dos crafts pendentes são serializados junto da produção, sem referências a nodes; a origem é identificada por `village_storage` ou `personal_inventory`.
- Load restaura os estoques e substitui os recibos sem consumo/refund adicional. A referência operacional ao baú é reconstruída no primeiro uso.
- Se um refund não couber na Mochila, somente os recibos ainda não devolvidos permanecem em cancelamento pendente, com timer parado; liberar espaço e cancelar novamente tenta a devolução sem repetir as já concluídas. Esse estado também é persistido.
- Misturas inválidas continuam consumindo os ingredientes, conforme a regra vigente.
- O resultado continua destinado à Mochila. Se a capacidade impedir a inserção, ele permanece pronto no caldeirão; lotes pausam sem confirmar o craft nem descartar sua reserva.
- A mistura experimental por slots ainda exige que o tipo de item esteja visível na Mochila; receitas conhecidas pelo Livro podem usar somente o Village Storage.

## Piloto da purificação

- Status: validado automaticamente e aprovado manualmente em 2026-09-17.
- Entregas individuais e `Entregar tudo disponível` consultam Village Storage + Mochila.
- Cada requisito consome primeiro do Village Storage e completa pela Mochila.
- O progresso parcial, a conclusão e o schema de save permanecem inalterados.
- A entrega é definitiva como antes; não existe rollback após o recurso virar progresso de purificação.
- O painel permanece responsável apenas por apresentar e acionar o contrato do obstáculo.

## Piloto da restauração

- A consulta de requisitos combina Village Storage + Mochila.
- A restauração reserva todos os requisitos em uma única transação, priorizando o Village Storage.
- Recurso insuficiente não causa consumo parcial.
- A recompensa continua indo para a Mochila. A restauração valida o espaço antes do consumo e não conclui o projeto quando a recompensa não cabe.
- Interação, condição de desbloqueio, estado restaurado e schema de save permanecem inalterados.
- Status: validado automaticamente e aprovado manualmente em 2026-09-19.

## Auditoria de fechamento dos consumidores atuais

- O caldeirão, a purificação e o projeto de restauração cobrem os consumidores fixos ativos da vila na V0 atual.
- Plantar sementes e regar continuam consumindo da Mochila por representarem ações físicas do personagem, não consumo remoto da vila.
- Coleta externa continua entrando apenas na Mochila; o jogador retorna, aproxima-se do baú e escolhe os recursos a depositar.
- `QuestBoard` está oculto e o fluxo de requests ainda não foi retomado; migrá-lo agora anteciparia um sistema fora do escopo atual.
- Venda e comércio permanecem desativados enquanto a economia aguarda contexto narrativo; o `SellMenu` legado não deve governar o próximo passo.
- O caminho normal do Livro de Receitas delega o cálculo ao caldeirão e já enxerga os recursos combinados. O fallback local só é usado quando não existe um caldeirão válido.
- O F10 permanece desativado e suas ações legadas não fazem parte do contrato de gameplay.
- O `QuestBoard` segue oculto, mas seu caminho legado já devolve o pedido e mantém a demanda caso uma recompensa em item seja recusada.
- O rollback de `VillageResourceAccess` só marca um recibo como reembolsado depois de confirmar a devolução integral à Mochila; uma tentativa bloqueada pode ser repetida após liberar espaço.
- Conclusão: não existe outro produtor ativo que deva ser migrado nesta etapa; a Fase C da Mochila está fechada.

## Interface de transferência Baú ↔ Mochila

- Status: implementada e aprovada manualmente pelo autor em 2026-09-20; 27 smoke tests aprovados e interface conferida com renderização OpenGL.
- Abrir o baú mostra dois painéis opacos lado a lado: Baú da Vila e Mochila, com ícones e quantidades em grades.
- Clicar em um item de qualquer lado abre um terceiro painel opaco: ícone, nome, origem/destino, quantidade disponível, campo numérico, `Mover`, `Mover tudo` e `Cancelar`.
- `Mover tudo` transfere apenas a pilha selecionada, no sentido indicado; não esvazia todo o inventário.
- Após uma transferência o popup fecha. Duplo clique não repete a operação; a escolha no baú não altera a ferramenta nem seleciona sementes para plantio.
- Escape cancela primeiro a transferência; pressioná-lo novamente fecha os dois painéis. Fechar os painéis também cancela a seleção.
- A interface revalida o estoque no clique, acompanha depósitos do golem e atualiza ambas as grades após transferências e load.
- `VillageChest.deposit_from_personal_inventory` e `withdraw_to_personal_inventory` transferem sincronamente; entradas inválidas/insuficientes não alteram nenhum dos dois estoques.
- Village Storage continua sem limite. A retirada para a Mochila já consulta sua aceitação antes de remover do baú; falta de espaço recusa a quantidade inteira e preserva ambas as origens. A retirada global legada também mantém no baú as pilhas que não couberem.
- Sementes podem ser guardadas por escolha; guardar a última unidade limpa a seleção daquela semente.
- Água continua representando a reserva regenerável do poço, omitida da grade da Mochila.
- O antigo botão global `Retirar Tudo` saiu da interface. O método legado permanece para compatibilidade interna.
- O schema de save v4 permanece igual. Ao carregar um dicionário de inventário completo, ele substitui o inventário atual: mesclar preservava itens adquiridos/retirados depois do save e podia duplicá-los ao restaurar o baú. Payloads parciais sem inventário continuam preservando o estado atual.
- `VillageChestTransferSmokeTest` cobre grades opacas, depósito/retirada parcial, mover pilha, duplo clique, estoque obsoleto, capacidade simulada, atomicidade, sementes, campo numérico, fechamento, Escape e round-trip JSON, inclusive item que só existia no baú ao salvar. Não escreve no save real.

### Validação manual (sem F10)

1. Abrir o baú e conferir os dois painéis opacos lado a lado.
2. Clicar em um item da Mochila, inserir parte da quantidade e usar `Mover`.
3. Clicar no mesmo item no Baú e retirar parte; conferir ícone, direção e quantidades.
4. Usar `Mover tudo` e confirmar que somente aquela pilha foi transferida.
5. Cancelar ou pressionar Escape: nada deve ser transferido. Fechar os painéis deve liberar as interações do mundo.
6. Salvar, transferir um item do baú para a mochila e carregar: os dois estoques devem retornar exatamente às quantidades salvas.

## Fechamento deste sub-sprint

O loop explorar → retornar → guardar → usar recursos da vila está validado no escopo atual. Requests, comércio, capacidade, stacks, filtros e rede de baús permanecem para sprints próprios e não devem ser antecipados.
