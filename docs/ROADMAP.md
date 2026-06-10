# Roadmap

## Fase 0 - Estado atual

- O projeto já possui o loop principal validado em sua base atual.
- O golem automático foi desativado temporariamente para estabilizar testes manuais.
- A base de receitas entrou em transição para `RecipeDatabase` / `Data/recipes`, com fallback legado temporário.

## Fase 1.5 - Layout macro, helpers runtime-only e preparação da fazenda

### Objetivo

Organizar o mapa e os suportes de UI/ajuda sem criar um novo sistema de gameplay nem mexer em save/schema.

### Já concluído ou em estado estável

- Layout Pass V1 da fazenda com blockout visual leve e leitura espacial melhor.
- Painéis arrastáveis em runtime-only, sem persistência de posição.
- Missão Inicial V0 runtime-only, separada do `QuestManager`.
- UI base do inventário e do caldeirão deve ser feita com escopo mínimo, usando `anchors`, `size_flags_*` e `mouse_filter` corretamente, sem polimento visual antes do loop básico estar estável.
- Golem Irrigador como talento do golem físico existente, sem criar nova entidade.
- Transição inicial do catálogo de receitas com `RecipeResolver`, mantendo `Database.gd` como fallback legado temporário.
- Primeira leva definitiva de receitas resource-first implementada sem novos IDs de item:
  - `Infusão Purificadora`
  - `Saquinho de Semente Mista`

### Ainda em aberto nesta fase

- Documentar o layout macro final da fazenda com mais precisão.
- Fixar e validar o envelope do mapa com a área inicial centrada no caldeirão.
- Reservar visualmente a segunda área corrompida.
- Refinar a leitura das zonas futuras sem transformar isso em novo gameplay.
- Manter a Fase 1 intacta enquanto a fazenda ganha forma maior.

## Fase 2 - Solo livre e expansão sistêmica

### Objetivo

Sair do protótipo em lotes fixos e avançar para um sistema mais livre, com expansão estrutural maior e decisões mais profundas de plataforma.

### Itens para implantar

- Implementar solo livre / `FarmGrid` real.
- Permitir criação e remoção de lotes.
- Tornar a segunda área corrompida funcional.
- Avaliar a migração real para `FarmGrid`, se aprovada.
- Expandir o save apenas se o loop exigir; por enquanto, manter qualquer persistência mínima estritamente no necessário para sessões longas e inventário.
- Revisar a UI do caldeirão.
- Revisar o inventário.
- Revisar a venda.
- Decidir se o golem físico continua ativo ou permanece desativado.
- Preparar a UI de status para leitura rápida do estado geral.

### Observação de escopo

A Fase 2 deve concentrar as mudanças sistêmicas de fato; a Fase 1.5 existe para preparar layout, leitura espacial e compatibilidade runtime-only sem reabrir o save.

## Fase 3 - Dados escaláveis

- Definir o formato final para crops, itens e receitas.
- Avaliar `Resource .tres`, JSON ou CSV.
- Criar um padrão de receitas mais amplo.
- Documentar a arquitetura futura de tempo real antes de conectar gameplay.
- Criar a base do `TimeManager` sem integrar ao gameplay ainda.
- Criar `FarmTileData` como estrutura isolada para o grid futuro.
- Criar `FarmGridManager` como coordenador isolado do grid futuro.
- Criar smoke tests manuais para validar a fundação do grid.

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
