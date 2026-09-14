# Contrato de Acesso a Recursos da Vila

## Status

Fundação técnica da transição entre Mochila e Village Storage. Esta fase não altera o gameplay, a interface nem o save.

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
- Caldeirão, purificação, restauração e demais consumidores ainda não usam o novo contrato.
- Não há capacidade, stacks, peso, filtros, múltiplos baús ou mudança de schema do save.
- O contrato não define o destino dos resultados produzidos pelos sistemas da vila.

## Próximo piloto recomendado

Migrar apenas a consulta, reserva e cancelamento de ingredientes do caldeirão para `VillageResourceAccess`. O resultado continua no destino atual até existir uma decisão específica para saídas de produção.

Depois que o piloto estiver automatizado e aprovado, o mesmo contrato poderá ser avaliado separadamente para purificação e projetos de restauração. A transferência manual Mochila → Village Storage só deve entrar quando depositar não tornar recursos inutilizáveis para os sistemas da vila.
