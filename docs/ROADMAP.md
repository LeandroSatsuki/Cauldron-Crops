# Roadmap

## Fase 0 - Estado Atual
- O projeto já possui sistemas iniciais.
- O golem automático foi desativado temporariamente para estabilizar testes manuais.

## Fase 1 - Loop Mínimo Jogável
- Plantar.
- Colher.
- Inventário.
- Caldeirão.
- Receita descoberta.
- Feedback visual mínimo.

## Fase 2 - Estabilização
- Corrigir a UI do caldeirão.
- Revisar o inventário.
- Revisar a venda.
- Corrigir o golem físico ou mantê-lo desativado.
- Preparar o salvamento.
- Expandir a UI de status para leitura rápida do estado geral.

## Fase 3 - Dados Escaláveis
- Decidir o formato para crops, itens e receitas.
- Avaliar `Resource .tres`, JSON ou CSV.
- Criar um padrão de receitas.
- Documentar a arquitetura futura de tempo real antes de conectar gameplay.
- Criar a base do `TimeManager` sem integrar ao gameplay ainda.
- Documentar o Farm System V2 antes de qualquer migração da fazenda.
- Criar `FarmTileData` como estrutura isolada para o grid futuro.
- Criar `FarmGridManager` como coordenador isolado do grid futuro.

## Fase 4 - Conteúdo
- Novas crops.
- Novas receitas.
- Missões.
- Progressão.
- Upgrades.
- Conceber a futura transição de lotes fixos para grid/tile sem alterar o protótipo atual.

## Fase 5 - Polimento
- Arte final pixel art.
- Áudio.
- Animações.
- Balanceamento.
- UX.
- Refinar a UI de status e os indicadores provisórios.
- Integrar o tempo real apenas quando o protótipo estiver estável.
