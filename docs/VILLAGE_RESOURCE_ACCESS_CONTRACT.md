# Contrato de Acesso a Recursos da Vila

## Status

Fundação técnica da transição entre Mochila e Village Storage. Caldeirão, purificação e restauração foram automatizados e aprovados manualmente como consumidores-piloto. O save e o destino dos resultados permanecem inalterados.

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
- O painel do baú permanece inalterado.
- Requests e comércio ainda não usam o contrato porque seus fluxos permanecem fora da V0 atual.
- Não há capacidade, stacks, peso, filtros, múltiplos baús ou mudança de schema do save.
- O contrato não define o destino dos resultados produzidos pelos sistemas da vila.

## Piloto do caldeirão

- O Livro de Receitas calcula a quantidade fabricável usando Village Storage + Mochila.
- Produção manual e em lote usam reservas transacionais.
- Cada unidade do lote possui recibo próprio; unidades concluídas descartam seu recibo.
- Cancelar o lote devolve somente as unidades pendentes e respeita a origem de cada item.
- Misturas inválidas continuam consumindo os ingredientes, conforme a regra vigente.
- O resultado continua indo para o destino atual até existir uma decisão específica para saídas de produção.
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
- A recompensa continua indo para a Mochila, preservando o comportamento atual.
- Interação, condição de desbloqueio, estado restaurado e schema de save permanecem inalterados.
- Status: validado automaticamente e aprovado manualmente em 2026-09-19.

## Auditoria de fechamento dos consumidores atuais

- O caldeirão, a purificação e o projeto de restauração cobrem os consumidores fixos ativos da vila na V0 atual.
- Plantar sementes e regar continuam consumindo da Mochila por representarem ações físicas do personagem, não consumo remoto da vila.
- Coleta externa continua entrando apenas na Mochila até o jogador retornar e depositar fisicamente.
- `QuestBoard` está oculto e o fluxo de requests ainda não foi retomado; migrá-lo agora anteciparia um sistema fora do escopo atual.
- Venda e comércio permanecem desativados enquanto a economia aguarda contexto narrativo; o `SellMenu` legado não deve governar o próximo passo.
- O caminho normal do Livro de Receitas delega o cálculo ao caldeirão e já enxerga os recursos combinados. O fallback local só é usado quando não existe um caldeirão válido.
- O F10 permanece desativado e suas ações legadas não fazem parte do contrato de gameplay.
- Conclusão: não existe outro consumidor ativo que deva ser migrado nesta etapa.

## Próximo passo recomendado

Fazer uma fase de desenho mínimo para o depósito físico Mochila → Village Storage. Antes de implementar, definir uma interação seletiva que não esconda sementes ou água necessárias às ações pessoais e que não transforme o baú em microgerenciamento constante. Requests e comércio devem aguardar seus próprios sprints.
