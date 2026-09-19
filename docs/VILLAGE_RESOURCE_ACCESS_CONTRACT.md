# Contrato de Acesso a Recursos da Vila

## Status

Fundação técnica da transição entre Mochila e Village Storage, com o caldeirão como primeiro consumidor-piloto automatizado e aprovado manualmente. O save e o destino dos resultados permanecem inalterados.

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
- Purificação, restauração e demais consumidores ainda não usam o novo contrato.
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

## Próximo passo recomendado

Depois da validação manual da restauração, revisar o fechamento desta etapa antes de escolher outro consumidor. A transferência manual Mochila → Village Storage só deve entrar quando depositar não tornar recursos inutilizáveis para os sistemas da vila.
