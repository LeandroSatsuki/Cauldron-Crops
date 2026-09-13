# Cauldron Crops — Fechamento da V0

Data de aprovação: **13 de setembro de 2026**

Estado: **V0 fechada e validada manualmente**

## O que a V0 prova

- agricultura em lotes fixos e no piloto de cultivo livre;
- save/load v4 com compatibilidade legada e identidade estável dos lotes;
- caldeirão guiado por `RecipeData`, com lote, tempo, recompensa e cancelamento;
- primeira purificação com transformação persistente do mundo;
- golem físico que trabalha, transporta, deposita e possui vida ociosa mínima;
- pesca ativa, coleção pequena, eventos e descoberta opcional;
- primeiro projeto de restauração após a purificação;
- interface da V0 sem lojas provisórias, venda acidental ou acesso normal ao debug.

## Evidências de fechamento

- `V0-RC1` aprovada pelo autor no fluxo manual completo;
- 14 smoke tests aprovados em worktree isolado;
- validação limpa configurada para rejeitar `SCRIPT ERROR`, `ERROR` e falhas explícitas;
- executável Windows exportado a partir de commit isolado;
- alterações locais paralelas não participam da build de release.

## Contratos preservados

- `FarmPlot` continua como autoridade de gameplay; `FarmGridManager` permanece snapshot/ponte.
- O save atual continua na versão 4.
- `RecipeDatabase`/`RecipeData` têm prioridade, com fallback legado temporário.
- O golem físico é a direção vigente; a automação abstrata antiga permanece desativada.
- O baú atual representa o início conceitual do futuro Village Storage, sem antecipar a migração.

## Reservado após a V0

- Inventário Pessoal/Mochila separado do Village Storage.
- Economia universal, saída de excedentes e representação narrativa de comércio.
- Múltiplas rotas de aquisição e futura Acquisition Matrix.
- Expansão definitiva do mundo e navegação entre regiões.
- Catálogo ampliado, NPCs, progressão, arte, áudio e balanceamento final.

Esses itens são direção futura e não fazem parte do contrato funcional da V0.

## Regra de continuidade

A V0 passa a ser o baseline jogável. Mudanças seguintes devem preservar sua build final, tratar novos sistemas como marcos separados e registrar qualquer quebra intencional de compatibilidade.
