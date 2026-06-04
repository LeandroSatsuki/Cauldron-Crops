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
- Criar smoke tests manuais para validar a fundação do grid.
- Adicionar um botão temporário no Debug Panel para rodar o smoke test manual.
- Criar uma cena de preview visual isolada para testar o FarmGrid em memória.
- Visualizar tipos de solo alquímico no preview isolado do FarmGrid.
- Testar ferramenta ativa Enxada e decay diario no preview isolado do FarmGrid.
- Testar ferramenta fake Semente para validar plantio e proteção contra decay.
- Testar ferramenta fake Regador para validar molhar terra arada e plantio.
- Testar crescimento fake em tiles irrigados com a tecla `G` e marcadores visuais por estagio.
- Testar ferramenta fake Colheita para fechar o loop minimo no preview isolado do FarmGrid.
- Registrar o checkpoint oficial do FarmGrid e investigar os logs globais em cenas dev.
- Criar a base da Ferramenta Ativa V0 no jogo principal com `ToolManager`.
- Exibir a ferramenta ativa no StatusPanel e selecionar `Enxada` por botão e tecla `1`.
- Expandir a seleção global para `Semente`, `Regador` e `Colheita` sem ações reais.
- Aplicar icones provisorios na Barra de Ferramentas V0 sem alterar a selecao global.

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
